import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_button.dart';
import 'notifier/password_reset_notifier.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  PasswordResetScreen({Key? key}) : super(key: key);

  @override
  PasswordResetScreenState createState() => PasswordResetScreenState();
}

class PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    ref.read(passwordResetNotifier.notifier).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Form(
          key: _formKey,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.only(
              top: 98.h,
              left: 24.h,
              right: 24.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogoSection(),
                SizedBox(height: 24.h),
                _buildForgotPasswordTitle(),
                SizedBox(height: 68.h),
                _buildFormSection(),
                SizedBox(height: 50.h),
                _buildSignInSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget - Logo
  Widget _buildLogoSection() {
    return Container(
      width: 130.h,
      child: CustomImageView(
        imagePath: ImageConstant.imgLogo,
        height: 26.h,
        width: 130.h,
      ),
    );
  }

  /// Section Widget - Forgot Password Title
  Widget _buildForgotPasswordTitle() {
    return Text(
      'forgot password?',
      style: TextStyleHelper.instance.title16RegularPlusJakartaSans
          .copyWith(color: appTheme.gray_50, height: 1.31),
    );
  }

  /// Section Widget - Form Section
  Widget _buildFormSection() {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(passwordResetNotifier);

        // Listen for state changes
        ref.listen(
          passwordResetNotifier,
          (previous, current) {
            if (current.isSuccess ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password reset email sent successfully!'),
                  backgroundColor: appTheme.deep_purple_A100,
                ),
              );
            }
            if (current.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(current.errorMessage!),
                  backgroundColor: appTheme.redCustom,
                ),
              );
            }
          },
        );

        return Column(
          spacing: 28.h,
          children: [
            // Email Input Field
            CustomEditText(
              controller: state.emailController,
              hintText: 'Email',
              prefixIcon: ImageConstant.imgMail,
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  ref.read(passwordResetNotifier.notifier).validateEmail(value),
              textStyle: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
              fillColor: appTheme.gray_900,
              borderRadius: 8.h,
            ),
            // Reset Password Button
            CustomButton(
              text: 'Reset Password',
              width: double.infinity,
              onPressed:
                  state.isLoading ?? false ? null : () => onTapResetPassword(),
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            ),
          ],
        );
      },
    );
  }

  /// Section Widget - Sign In Section
  Widget _buildSignInSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8.h,
      children: [
        Text(
          'Remember your password?',
          style: TextStyleHelper.instance.title16RegularPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        GestureDetector(
          onTap: () => onTapSignIn(),
          child: Text(
            'Sign in',
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.deep_purple_A100),
          ),
        ),
      ],
    );
  }

  /// Handle Reset Password Button Press
  void onTapResetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(passwordResetNotifier.notifier).resetPassword();
    }
  }

  /// Navigate to Sign In Screen
  void onTapSignIn() {
    NavigatorService.pushNamed(AppRoutes.loginScreen);
  }
}
