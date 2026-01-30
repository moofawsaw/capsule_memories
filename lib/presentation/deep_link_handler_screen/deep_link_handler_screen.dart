import '../../core/app_export.dart';
import '../../core/services/deep_link_service.dart';

class DeepLinkHandlerScreen extends ConsumerStatefulWidget {
  final String type;
  final String code;

  const DeepLinkHandlerScreen({
    Key? key,
    required this.type,
    required this.code,
  }) : super(key: key);

  @override
  DeepLinkHandlerScreenState createState() => DeepLinkHandlerScreenState();
}

class DeepLinkHandlerScreenState extends ConsumerState<DeepLinkHandlerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
    _processDeepLink();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processDeepLink() async {
    try {
      // ✅ Do not auto-accept invites when the link is clicked.
      // Forward to DeepLinkService, which routes to the correct confirmation UI.
      await DeepLinkService().handleExternalDeepLink(
        '/join/${widget.type}/${widget.code}',
      );
    } catch (_) {
      // If something goes wrong, just pop back silently.
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: SafeArea(
        child: Center(
          child: Container(
            padding: EdgeInsets.all(32.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final delay = index * 0.3;
                        final opacity =
                            (((_animationController.value + delay) % 1.0) * 2 -
                                    1)
                                .abs();
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 4.h),
                          width: 12.h,
                          height: 12.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appTheme.deep_purple_A100.withOpacity(opacity),
                          ),
                        );
                      }),
                    );
                  },
                ),
                SizedBox(height: 16.h),
                Text(
                  _isProcessing ? 'Opening…' : 'Redirecting…',
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
