import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_image_view.dart';
import 'notifier/login_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ✅ IMPORTANT:
  // Replace these with your real SVG asset paths (and add them to pubspec.yaml).
  // Use official, flat marks (no circle badge for Facebook).
  static final String _googleIconAsset = ImageConstant.imgImage5;
  static final String _facebookIconAsset = ImageConstant.imgSocialMedia;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Container(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 36.h),
                      _buildLogoSection(),
                      SizedBox(height: 24.h),
                      _buildLoginTitle(),
                      SizedBox(height: 68.h),
                      _buildLoginForm(),
                      SizedBox(height: 50.h),
                      _buildForgotPasswordLink(),
                      SizedBox(height: 14.h),
                      _buildSignUpSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Logo Section
  Widget _buildLogoSection() {
    return GestureDetector(
      onTap: () {
        NavigatorService.pushNamed(AppRoutes.appFeed);
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.38,
        child: CustomImageView(
          imagePath: ImageConstant.imgLogo,
          height: 26.h,
          width: 130.h,
        ),
      ),
    );
  }

  /// Login Title
  Widget _buildLoginTitle() {
    return Text(
      'login to your account',
      style: TextStyleHelper.instance.title16RegularPlusJakartaSans
          .copyWith(color: appTheme.gray_50),
    );
  }

  /// Login Form Section
  Widget _buildLoginForm() {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(loginNotifier);

        // Listen for state changes
        ref.listen(
          loginNotifier,
              (previous, current) {
            if (current.isSuccess ?? false) {
              TextInput.finishAutofillContext();
              _clearForm();
              NavigatorService.pushNamedAndRemoveUntil(AppRoutes.appFeed);
            }
            if (current.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(current.errorMessage!)),
              );
            }
          },
        );

        return Column(
          children: [
            CustomEditText(
              controller: state.emailController,
              hintText: 'Email',
              prefixIcon: ImageConstant.imgMail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: [AutofillHints.email],
              validator: (value) {
                return ref.read(loginNotifier.notifier).validateEmail(value);
              },
            ),
            SizedBox(height: 18.h),
            CustomEditText(
              controller: state.passwordController,
              hintText: 'Password',
              prefixIcon: ImageConstant.imgIcon,
              isPassword: true,
              autofillHints: [AutofillHints.password],
              validator: (value) {
                return ref.read(loginNotifier.notifier).validatePassword(value);
              },
            ),
            SizedBox(height: 28.h),
            CustomButton(
              text: 'Log in',
              width: double.infinity,
              onPressed: state.isLoading ?? false ? null : () => _onLoginTap(),
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            ),
            SizedBox(height: 36.h),
            _buildOrDivider(),
            SizedBox(height: 32.h),

            // ✅ REPLACED: Use normalized SVG icons with proper sizing
            _SocialAuthButton(
              text: 'Log in with Google',
              iconAssetPath: _googleIconAsset,
              onPressed: state.isLoading ?? false ? null : () => _onGoogleLoginTap(),
              isDisabled: state.isLoading ?? false,
            ),
            SizedBox(height: 20.h),
            _SocialAuthButton(
              text: 'Log in with Facebook',
              iconAssetPath: _facebookIconAsset,
              onPressed: state.isLoading ?? false ? null : () => _onFacebookLoginTap(),
              isDisabled: state.isLoading ?? false,
            ),
          ],
        );
      },
    );
  }

  /// OR Divider Section
  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 2.h,
            color: appTheme.gray_900_01,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.h),
          child: Text(
            'OR',
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
        ),
        Expanded(
          child: Container(
            height: 2.h,
            color: appTheme.gray_900_01,
          ),
        ),
      ],
    );
  }

  /// Forgot Password Link
  Widget _buildForgotPasswordLink() {
    return GestureDetector(
      onTap: () => _onForgotPasswordTap(),
      child: Text(
        'forgot password?',
        style: TextStyleHelper.instance.title16RegularPlusJakartaSans
            .copyWith(color: appTheme.deep_purple_A100),
      ),
    );
  }

  /// Sign Up Section
  Widget _buildSignUpSection() {
    return GestureDetector(
      onTap: () => _onSignUpTap(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Don\'t have an account?',
            style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          SizedBox(width: 8.h),
          Text(
            'Sign up',
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.deep_purple_A100),
          ),
        ],
      ),
    );
  }

  /// Handle login button tap
  void _onLoginTap() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(loginNotifier.notifier).login();
    }
  }

  /// Handle Google login tap
  void _onGoogleLoginTap() {
    ref.read(loginNotifier.notifier).loginWithGoogle();
  }

  /// Handle Facebook login tap
  void _onFacebookLoginTap() {
    ref.read(loginNotifier.notifier).loginWithFacebook();
  }

  /// Handle forgot password tap
  void _onForgotPasswordTap() {
    NavigatorService.pushNamed(AppRoutes.authReset);
  }

  /// Handle sign up tap
  void _onSignUpTap() {
    NavigatorService.pushNamed(AppRoutes.authRegister);
  }

  /// Clear form after successful login
  void _clearForm() {
    final state = ref.read(loginNotifier);
    state.emailController?.clear();
    state.passwordController?.clear();
  }
}

///
/// Social auth button that matches your existing outline style
/// while using normalized SVG icons (same visual size).
///
class _SocialAuthButton extends StatelessWidget {
  final String text;
  final String iconAssetPath;
  final VoidCallback? onPressed;
  final bool isDisabled;

  const _SocialAuthButton({
    required this.text,
    required this.iconAssetPath,
    required this.onPressed,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final double height = 48.h;
    final BorderRadius radius = BorderRadius.circular(12.h);

    final Color borderColor = appTheme.blue_gray_300.withAlpha(70);
    final Color bgColor = Colors.transparent;

    final TextStyle textStyle = TextStyleHelper.instance
        .body14MediumPlusJakartaSans
        .copyWith(color: appTheme.blue_gray_300);

    return Opacity(
      opacity: isDisabled ? 0.55 : 1.0,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: radius,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NormalizedProviderIcon(assetPath: iconAssetPath),
              SizedBox(width: 12.h),
              Text(text, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _NormalizedProviderIcon extends StatelessWidget {
  final String assetPath;

  const _NormalizedProviderIcon({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    final bool isSvg = assetPath.toLowerCase().endsWith('.svg');

    return SizedBox(
      width: 24.h,
      height: 24.h,
      child: Center(
        child: isSvg
            ? SvgPicture.asset(
          assetPath,
          width: 18.h,
          height: 18.h,
          fit: BoxFit.contain,
        )
            : Image.asset(
          assetPath,
          width: 18.h,
          height: 18.h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}


///
/// Forces all provider icons into the same visual box so they match.
/// - Outer box: 24x24
/// - Inner icon: 18x18 (centered)
///
class _NormalizedSvgIcon extends StatelessWidget {
  final String svgAssetPath;

  const _NormalizedSvgIcon({
    required this.svgAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24.h,
      height: 24.h,
      child: Center(
        child: SvgPicture.asset(
          svgAssetPath,
          width: 18.h,
          height: 18.h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
