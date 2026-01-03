import 'package:flutter/services.dart';

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
            CustomButton(
              text: 'Log in with Google',
              width: double.infinity,
              leftIcon: ImageConstant.imgImage5,
              onPressed: () => _onGoogleLoginTap(),
              buttonStyle: CustomButtonStyle.outlineDark,
              buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
            ),
            SizedBox(height: 20.h),
            CustomButton(
              text: 'Log in with Facebook',
              width: double.infinity,
              leftIcon: ImageConstant.imgSocialMedia,
              onPressed: () => _onFacebookLoginTap(),
              buttonStyle: CustomButtonStyle.outlineDark,
              buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
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
