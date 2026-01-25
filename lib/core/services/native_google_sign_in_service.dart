import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Native Google Sign-In (mobile-first) for Supabase auth.
///
/// Flow:
/// - Use native Google Sign-In to get an ID token (and optionally access token)
/// - Exchange with Supabase via `signInWithIdToken`
///
/// This avoids the browser-based OAuth redirect flow and feels much more seamless.
class NativeGoogleSignInService {
  NativeGoogleSignInService._();

  static Future<void>? _init;
  static String? _rawNonce;
  static String? _hashedNonce;

  /// IMPORTANT:
  /// Supabase validates the Google ID token audience (`aud`) against the
  /// Google **Web** client id configured in Supabase Auth → Providers → Google.
  ///
  /// For native (mobile-first) sign-in, we must pass that web client id as
  /// `serverClientId` so Google issues an ID token with the correct audience.
  ///
  /// Provide it at runtime:
  /// `--dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com`
  static const String _googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  static Future<void> _ensureInitialized() {
    // If no web client id is provided, native sign-in will produce an ID token
    // with an audience Supabase won't accept. Signal a config error so callers
    // can fall back to browser OAuth.
    if (_googleWebClientId.trim().isEmpty) {
      return Future.error(
        const AuthException(
          'Missing GOOGLE_WEB_CLIENT_ID for native Google sign-in.',
          code: 'providerConfigurationError',
        ),
      );
    }

    // Google Sign-In on iOS can include a `nonce` claim in the returned ID token.
    // Supabase will validate this nonce by hashing the raw nonce you provide in
    // `signInWithIdToken` and comparing it to the token claim.
    //
    // Per Supabase docs: provide a hashed nonce to Google, and the raw nonce to
    // Supabase. The google_sign_in plugin currently configures nonce via
    // `initialize(...)`, and it documents that initialize should be called once.
    // We therefore generate one nonce per app run for compatibility.
    _rawNonce ??= _generateRawNonce();
    _hashedNonce ??= _sha256Hex(_rawNonce!);

    return _init ??= GoogleSignIn.instance
        .initialize(
          serverClientId: _googleWebClientId.trim(),
          nonce: _hashedNonce,
        )
        .catchError((e) {
      // Allow retry if initialization fails.
      _init = null;
      throw e;
    });
  }

  static Future<void> signIn(SupabaseClient client) async {
    try {
      await _ensureInitialized();

      // NOTE: google_sign_in v7 uses a singleton + `authenticate()` instead of `signIn()`.
      // This triggers the native Google Sign-In flow.
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile', 'openid'],
      );

      final auth = account.authentication;
      final idToken = (auth.idToken ?? '').trim();
      if (idToken.isEmpty) {
        throw const AuthException('Missing Google ID token.');
      }

      // Some ID tokens include an `at_hash` claim; in that case Supabase expects
      // the access token as well. Try to fetch one, but don't hard-fail if the
      // platform doesn't provide it.
      String? accessToken;
      try {
        final authorization = await account.authorizationClient
            .authorizationForScopes(const ['openid', 'email', 'profile']);
        accessToken = authorization?.accessToken;
      } catch (_) {
        accessToken = null;
      }
      if ((accessToken ?? '').trim().isEmpty) {
        // Supabase requires the Google access token when signing in with an ID token.
        throw const AuthException(
          'Missing Google access token.',
          code: 'clientConfigurationError',
        );
      }

      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
        // Raw nonce for Supabase validation (see `_ensureInitialized`).
        nonce: _rawNonce,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('User cancelled Google sign-in.');
      }

      // Android-specific: when the app's package name + SHA certs aren't wired
      // to an Android OAuth client in Google Cloud/Firebase, native sign-in often
      // fails with a "failed to retrieve an ID token [28404]" style message.
      // Treat this as a configuration error so callers can fall back to browser OAuth.
      final code = e.code.name.trim();
      final description = (e.description ?? '').trim();
      final bool looksLikeMissingAndroidOAuthClient =
          code == 'failedToRetrieveAuthToken' ||
          description.contains('Failed to retrieve an ID token') ||
          description.contains('[28404]');
      if (looksLikeMissingAndroidOAuthClient) {
        throw const AuthException(
          'Native Google sign-in is not configured for this Android build yet.',
          code: 'providerConfigurationError',
        );
      }

      throw AuthException(
        e.description ?? 'Google sign-in failed.',
        code: code,
      );
    } on UnsupportedError catch (e) {
      // Some platforms/build variants can throw UnsupportedError if the native
      // SDK isn't available or isn't configured.
      throw AuthException(
        e.message ?? 'Google sign-in is not supported on this build.',
        code: GoogleSignInExceptionCode.providerConfigurationError.name,
      );
    } catch (e) {
      // Normalize any other unexpected failures into an AuthException so callers
      // can decide whether to fall back to browser OAuth.
      throw AuthException(
        e.toString(),
        code: GoogleSignInExceptionCode.unknownError.name,
      );
    }
  }

  static Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // ignore
    }
  }

  static String _generateRawNonce({int lengthBytes = 32}) {
    final rng = Random.secure();
    final bytes = List<int>.generate(lengthBytes, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

