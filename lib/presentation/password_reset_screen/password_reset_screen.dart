import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
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
        appBar: AppBar(
          backgroundColor: appTheme.gray_900_02,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: appTheme.gray_50),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Reset Password',
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.all(24.h),
            child: Consumer(
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
                          backgroundColor: appTheme.colorFF52D1,
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
                          backgroundColor: appTheme.colorFFD81E,
                        ),
                      );
                    }
                  },
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      'Forgot your password?',
                      style: TextStyleHelper.instance.title20BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      style: TextStyleHelper
                          .instance.title16RegularPlusJakartaSans
                          .copyWith(color: appTheme.blue_gray_300),
                    ),
                    SizedBox(height: 40.h),
                    CustomEditText(
                      controller: state.emailController,
                      hintText: 'Email',
                      prefixIcon: ImageConstant.imgMail,
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
                      text: 'Send Reset Link',
                      width: double.infinity,
                      onPressed: (state.isLoading ?? false)
                          ? null
                          : () => _onSendResetLink(),
                      buttonStyle: CustomButtonStyle.fillPrimary,
                      buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                    ),
                    SizedBox(height: 20.h),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Back to login',
                          style: TextStyleHelper
                              .instance.title16RegularPlusJakartaSans
                              .copyWith(color: appTheme.deep_purple_A100),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
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