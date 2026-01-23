// lib/presentation/account_registration_screen/account_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_image_view.dart';
import 'notifier/account_registration_notifier.dart';

class AccountRegistrationScreen extends ConsumerStatefulWidget {
  AccountRegistrationScreen({Key? key}) : super(key: key);

  @override
  AccountRegistrationScreenState createState() =>
      AccountRegistrationScreenState();
}

class AccountRegistrationScreenState
    extends ConsumerState<AccountRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ✅ Font Awesome brand icons
  static const IconData _googleIcon = FontAwesomeIcons.google;
  static const IconData _facebookIcon = FontAwesomeIcons.facebookF;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: Form(
        key: _formKey,
        child: AutofillGroup(
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(context),
                    _buildCreateAccountText(context),
                    _buildRegistrationForm(context),
                    _buildSignInLink(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget - Logo
  Widget _buildLogo(BuildContext context) {
    return GestureDetector(
      onTap: () {
        NavigatorService.pushNamed(AppRoutes.appFeed);
      },
      child: Container(
        margin: EdgeInsets.only(top: 16.h),
        width: SizeUtils.width * 0.38,
        child: CustomImageView(
          imagePath: ImageConstant.imgLogo,
          height: 26.h,
          width: 130.h,
        ),
      ),
    );
  }

  /// Section Widget - Create Account Text
  Widget _buildCreateAccountText(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      child: Text(
        'create your account',
        style: TextStyleHelper.instance.title16RegularPlusJakartaSans
            .copyWith(color: appTheme.gray_50, height: 1.31),
      ),
    );
  }

  /// Section Widget - Registration Form
  Widget _buildRegistrationForm(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(accountRegistrationNotifier);

        ref.listen(
          accountRegistrationNotifier,
              (previous, current) {
            if (current.isSuccess ?? false) {
              TextInput.finishAutofillContext();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Account created successfully!'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
              ref.read(accountRegistrationNotifier.notifier).clearForm();
              NavigatorService.pushNamed(AppRoutes.appFeed);
            }
            if (current.hasError ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                  Text(current.errorMessage ?? 'Registration failed'),
                  backgroundColor: appTheme.colorFFD81E,
                ),
              );
            }
          },
        );

        final bool isBusy = state.isLoading ?? false;

        return Container(
          margin: EdgeInsets.only(top: 34.h),
          child: Column(
            children: [
              // Name Field
              CustomEditText(
                controller: state.nameController,
                hintText: 'Name',
                prefixIcon: ImageConstant.imgIcon,
                keyboardType: TextInputType.name,
                autofillHints: const [AutofillHints.name],
                validator: (value) => ref
                    .read(accountRegistrationNotifier.notifier)
                    .validateName(value),
                fillColor: appTheme.gray_900,
                borderRadius: 8.h,
                textStyle: TextStyleHelper
                    .instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 18.h),

              // Email Field
              CustomEditText(
                controller: state.emailController,
                hintText: 'Email',
                prefixIcon: ImageConstant.imgMail,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: (value) => ref
                    .read(accountRegistrationNotifier.notifier)
                    .validateEmail(value),
                fillColor: appTheme.gray_900,
                borderRadius: 8.h,
                textStyle: TextStyleHelper
                    .instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 18.h),

              // Password Field
              CustomEditText(
                controller: state.passwordController,
                hintText: 'Password',
                prefixIcon: ImageConstant.imgIcon,
                isPassword: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => ref
                    .read(accountRegistrationNotifier.notifier)
                    .validatePassword(value),
                fillColor: appTheme.gray_900,
                borderRadius: 8.h,
                textStyle: TextStyleHelper
                    .instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
                contentPadding: EdgeInsets.only(
                  top: 14.h,
                  right: 16.h,
                  bottom: 14.h,
                  left: 36.h,
                ),
              ),
              SizedBox(height: 18.h),

              // Confirm Password Field
              CustomEditText(
                controller: state.confirmPasswordController,
                hintText: 'Password',
                prefixIcon: ImageConstant.imgIcon,
                isPassword: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => ref
                    .read(accountRegistrationNotifier.notifier)
                    .validateConfirmPassword(value),
                fillColor: appTheme.gray_900,
                borderRadius: 8.h,
                textStyle: TextStyleHelper
                    .instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
                contentPadding: EdgeInsets.only(
                  top: 14.h,
                  right: 16.h,
                  bottom: 14.h,
                  left: 36.h,
                ),
              ),

              // Sign Up Button
              CustomButton(
                text: 'Sign up',
                width: double.infinity,
                height: 60.h,
                onPressed: isBusy ? null : () => onTapSignUp(context),
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                margin: EdgeInsets.only(top: 28.h),
                isDisabled: isBusy,
              ),

              // OR Divider
              _buildOrDivider(context),
              SizedBox(height: 24.h),

              // ✅ Social signup buttons (Font Awesome)
              _SocialAuthButton(
                text: 'Sign up with Google',
                iconData: _googleIcon,
                onPressed: isBusy ? null : () => onTapGoogleLogin(context),
                isDisabled: isBusy,
              ),
              SizedBox(height: 20.h),
              _SocialAuthButton(
                text: 'Sign up with Facebook',
                iconData: _facebookIcon,
                onPressed: isBusy ? null : () => onTapFacebookLogin(context),
                isDisabled: isBusy,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Section Widget - OR Divider
  Widget _buildOrDivider(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: SizeUtils.width * 0.36,
            height: 2.h,
            decoration: BoxDecoration(
              color: appTheme.gray_900_01,
            ),
          ),
          Text(
            'OR',
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          Container(
            width: SizeUtils.width * 0.36,
            height: 2.h,
            decoration: BoxDecoration(
              color: appTheme.gray_900_01,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget - Sign In Link
  Widget _buildSignInLink(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 24.h),
      child: GestureDetector(
        onTap: () {
          onTapSignInLink(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Have an account? ',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
            Text(
              'Sign in',
              style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                  .copyWith(color: appTheme.deep_purple_A100),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles sign up button tap
  void onTapSignUp(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(accountRegistrationNotifier.notifier).signUp();
    }
  }

  /// Handles Google signup button tap
  void onTapGoogleLogin(BuildContext context) {
    ref.read(accountRegistrationNotifier.notifier).signUpWithGoogle();
  }

  /// Handles Facebook signup button tap
  void onTapFacebookLogin(BuildContext context) {
    ref.read(accountRegistrationNotifier.notifier).signUpWithFacebook();
  }

  /// Navigates to login screen
  void onTapSignInLink(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.authLogin);
  }
}

///
/// Social auth button that matches your existing style.
/// Supports iconData (Font Awesome / Material / etc).
///
class _SocialAuthButton extends StatelessWidget {
  final String text;
  final IconData iconData;
  final VoidCallback? onPressed;
  final bool isDisabled;

  const _SocialAuthButton({
    required this.text,
    required this.iconData,
    required this.onPressed,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final double height = 48.h;
    final BorderRadius radius = BorderRadius.circular(12.h);

    final Color borderColor = appTheme.blue_gray_300.withAlpha(70);
    final Color bgColor = Colors.transparent;

    final TextStyle textStyle = TextStyleHelper.instance.body14MediumPlusJakartaSans
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
              _NormalizedProviderIcon(iconData: iconData),
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
  final IconData iconData;

  const _NormalizedProviderIcon({required this.iconData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24.h,
      height: 24.h,
      child: Center(
        child: Icon(
          iconData,
          // Font Awesome brands often look smaller at the same size as Material.
          // 20.h generally matches your button text better.
          size: 20.h,
          color: appTheme.blue_gray_300,
        ),
      ),
    );
  }
}