import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_image_view.dart';
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
    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 68.h),
                  _buildLogoSection(),
                  SizedBox(height: 24.h),
                  _buildForgotPasswordTitle(),
                  SizedBox(height: 68.h),
                  _buildResetPasswordForm(),
                  SizedBox(height: 50.h),
                  _buildSignInLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Logo Section
  Widget _buildLogoSection() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final logoPath =
        isLight ? ImageConstant.imgLogoLight : ImageConstant.imgLogo;

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.38,
        child: CustomImageView(
          imagePath: logoPath,
          height: 32.h,
          width: 160.h,
        ),
      ),
    );
  }

  /// Forgot Password Title
  Widget _buildForgotPasswordTitle() {
    return Center(
      child: Text(
        'forgot password?',
        style: TextStyleHelper.instance.title16RegularPlusJakartaSans
            .copyWith(color: appTheme.gray_50),
      ),
    );
  }

  /// Reset Password Form Section
  Widget _buildResetPasswordForm() {
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
                  content: Text('Reset email sent!'),
                ),
              );
              // Navigate back to login after 2 seconds
              Future.delayed(Duration(seconds: 2), () {
                Navigator.pop(context);
              });
            }
            if (current.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(current.errorMessage!),
                ),
              );
            }
          },
        );

        return Column(
          children: [
            CustomEditText(
              controller: state.emailController,
              hintText: 'Email',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value!)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 28.h),
            CustomButton(
              text: 'Reset Password',
              width: double.infinity,
              onPressed:
                  (state.isLoading ?? false) ? null : () => _onSendResetLink(),
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            ),
          ],
        );
      },
    );
  }

  /// Sign In Link Section
  Widget _buildSignInLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Remember your password? ',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
            Text(
              'Sign in',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.deep_purple_A100),
            ),
          ],
        ),
      ),
    );
  }

  void _onSendResetLink() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(passwordResetNotifier.notifier).requestPasswordReset();
    }
  }
}
