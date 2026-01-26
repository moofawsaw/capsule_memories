import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Native Facebook Sign-In (mobile-first) for Supabase auth.
///
/// Flow:
/// - Use native Facebook SDK to get an access token
/// - Exchange with Supabase via `signInWithIdToken(provider: facebook, idToken: <accessToken>)`
///
/// Supabase docs: `signInWithIdToken` supports native Facebook sign-in when paired
/// with `flutter_facebook_auth`.
class NativeFacebookSignInService {
  NativeFacebookSignInService._();

  static Future<void> signIn(SupabaseClient client) async {
    if (kIsWeb) {
      throw const AuthException(
        'Native Facebook sign-in is not supported on web.',
        code: 'uiUnavailable',
      );
    }

    try {
      // For iOS, Facebook may return Limited Login tokens (especially iOS 17+ without ATT),
      // which are longer and JWT-like. Supabase accepts these reliably in practice.
      // On Android, classic access tokens sometimes fail Supabase validation in some setups,
      // so we prefer requesting Limited Login when supported.
      final prefersLimitedLogin = defaultTargetPlatform == TargetPlatform.android;
      final nonce = _generateNonce();

      // Keep permissions minimal + compatible with Supabase social login.
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
        loginTracking:
            prefersLimitedLogin ? LoginTracking.limited : LoginTracking.enabled,
        // Required by the plugin for Limited Login flows.
        nonce: nonce,
      );

      switch (result.status) {
        case LoginStatus.success:
          final accessToken = result.accessToken;
          final token = (accessToken?.tokenString ?? '').trim();
          if (token.isEmpty) {
            throw const AuthException(
              'Missing Facebook access token.',
              code: 'clientConfigurationError',
            );
          }

          // Best-effort sanity check: ensure token can call Graph API.
          // This helps distinguish "token invalid" vs "Supabase/provider config".
          try {
            await FacebookAuth.instance.getUserData(
              fields: "id,name,email",
            );
          } catch (_) {
            // ignore (still attempt Supabase exchange)
          }

          if (kDebugMode) {
            // Never log the full token; just type + length for debugging.
            debugPrint(
              '🔐 FB token type=${accessToken?.type} len=${token.length}',
            );
          }

          // Supabase expects a token to exchange for a session.
          // For Facebook, Supabase docs commonly pass the FB access token via `idToken`.
          // Some configurations accept it via `accessToken` as well, so we provide both.
          try {
            await client.auth.signInWithIdToken(
              provider: OAuthProvider.facebook,
              idToken: token,
              accessToken: token,
            );
          } on AuthException catch (e) {
            final msg = e.message.toLowerCase();
            if (msg.contains('bad id token') || msg.contains('bad_id_token')) {
              throw AuthException(e.message, code: 'bad_id_token');
            }
            rethrow;
          }
          return;

        case LoginStatus.cancelled:
          throw const AuthException('User cancelled Facebook sign-in.');

        case LoginStatus.failed:
          throw AuthException(
            result.message ?? 'Facebook sign-in failed.',
            code: 'unknownError',
          );

        case LoginStatus.operationInProgress:
          throw const AuthException(
            'Facebook sign-in is already in progress.',
            code: 'operationInProgress',
          );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      // Normalize any other unexpected failures into an AuthException so callers
      // can decide whether to fall back to browser OAuth.
      throw AuthException(
        e.toString(),
        code: 'unknownError',
      );
    }
  }

  static Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // ignore
    }
  }

  static String _generateNonce({int lengthBytes = 32}) {
    final rng = Random.secure();
    final bytes = List<int>.generate(lengthBytes, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes);
  }
}

