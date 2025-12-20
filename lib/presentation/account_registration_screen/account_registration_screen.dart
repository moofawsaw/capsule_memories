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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Form(
          key: _formKey,
          child: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Container(
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
        margin: EdgeInsets.only(top: 26.h),
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
      margin: EdgeInsets.only(top: 26.h),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Account created successfully!'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
              // Clear form fields after successful registration
              ref.read(accountRegistrationNotifier.notifier).clearForm();
              // Navigate to feed screen after successful signup
              NavigatorService.pushNamed(AppRoutes.appFeed);
            }
            if (current.hasError ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(current.errorMessage ?? 'Registration failed'),
                  backgroundColor: appTheme.colorFFD81E,
                ),
              );
            }
          },
        );

        return Container(
          margin: EdgeInsets.only(top: 52.h),
          child: Column(
            children: [
              // Name Field
              CustomEditText(
                controller: state.nameController,
                hintText: 'Name',
                prefixIcon: ImageConstant.imgIcon,
                keyboardType: TextInputType.name,
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
                onPressed: (state.isLoading ?? false)
                    ? null
                    : () {
                        onTapSignUp(context);
                      },
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                margin: EdgeInsets.only(top: 28.h),
                isDisabled: state.isLoading ?? false,
              ),

              // OR Divider
              _buildOrDivider(context),

              // Google Login Button
              CustomButton(
                text: 'Log in with Google',
                width: double.infinity,
                leftIcon: ImageConstant.imgImage5,
                onPressed: () {
                  onTapGoogleLogin(context);
                },
                buttonStyle: CustomButtonStyle.outlineDark,
                buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
                padding: EdgeInsets.symmetric(horizontal: 30.h, vertical: 10.h),
                margin: EdgeInsets.only(top: 28.h),
              ),

              // Facebook Login Button
              CustomButton(
                text: 'Log in with Facebook',
                width: double.infinity,
                leftIcon: ImageConstant.imgSocialMedia,
                onPressed: () {
                  onTapFacebookLogin(context);
                },
                buttonStyle: CustomButtonStyle.outlineDark,
                buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
                padding: EdgeInsets.symmetric(horizontal: 30.h, vertical: 10.h),
                margin: EdgeInsets.only(top: 20.h),
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
      margin: EdgeInsets.only(top: 30.h),
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
      margin: EdgeInsets.only(top: 34.h),
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

  /// Handles Google login button tap
  void onTapGoogleLogin(BuildContext context) {
    ref.read(accountRegistrationNotifier.notifier).signUpWithGoogle();
  }

  /// Handles Facebook login button tap
  void onTapFacebookLogin(BuildContext context) {
    ref.read(accountRegistrationNotifier.notifier).signUpWithFacebook();
  }

  /// Navigates to login screen
  void onTapSignInLink(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.authLogin);
  }
}
