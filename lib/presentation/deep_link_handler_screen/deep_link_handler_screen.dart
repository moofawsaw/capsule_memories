import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

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
  String _message = '';
  bool _isError = false;
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
      final client = SupabaseService.instance.client;
      if (client == null) {
        throw Exception('Supabase not initialized');
      }
      // Stories don't need authentication or edge function - just navigate directly
      if (widget.type == 'story') {
        setState(() {
          _message = 'Opening story...';
          _isProcessing = false;
        });
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          NavigatorService.pushNamedAndRemoveUntil(
            AppRoutes.appStoryView,  // or whatever your story screen route is
            arguments: {'storyId': widget.code},
          );
        }
        return;
      }
      // Check authentication
      final user = client.auth.currentUser;
      if (user == null) {
        // Store pending action and redirect to login
        setState(() {
          _message = 'Please login to continue';
          _isError = false;
          _isProcessing = false;
        });
        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          NavigatorService.pushNamedAndRemoveUntil(
            AppRoutes.authLogin,
            arguments: {'pendingType': widget.type, 'pendingCode': widget.code},
          );
        }
        return;
      }

      // Process the invitation
      setState(() {
        _message = _getProcessingMessage(widget.type);
      });

      final response = await client.functions.invoke(
        'handle-qr-scan',
        body: {
          'type': widget.type,
          'code': widget.code,
        },
      );

      if (response.status == 200) {
        setState(() {
          _message = _getSuccessMessage(widget.type);
          _isError = false;
          _isProcessing = false;
        });

        await Future.delayed(Duration(seconds: 2));

        if (mounted) {
          _navigateToDestination(widget.type);
        }
      } else {
        throw Exception(response.data['error'] ?? 'Failed to process link');
      }
    } catch (e) {
      setState(() {
        _message = _getErrorMessage(e.toString());
        _isError = true;
        _isProcessing = false;
      });

      await Future.delayed(Duration(seconds: 3));

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  String _getProcessingMessage(String type) {
    switch (type) {
      case 'story':
        return 'Opening story...';
      case 'friend':
        return 'Processing friend invitation...';
      case 'group':
        return 'Connecting to group...';
      case 'memory':
        return 'Joining memory...';
      default:
        return 'Processing invitation...';
    }
  }

  String _getSuccessMessage(String type) {
    switch (type) {
      case 'friend':
        return 'Friend request sent!';
      case 'group':
        return 'Successfully joined group!';
      case 'memory':
        return 'Added to memory!';
      default:
        return 'Success!';
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('expired')) {
      return 'This invitation has expired';
    } else if (error.contains('invalid')) {
      return 'Invalid invitation link';
    } else if (error.contains('already')) {
      return 'You are already connected';
    } else {
      return 'Failed to process invitation';
    }
  }

  void _navigateToDestination(String type) {
    switch (type) {
      case 'friend':
        NavigatorService.pushNamedAndRemoveUntil(AppRoutes.appFriends);
        break;
      case 'group':
        NavigatorService.pushNamedAndRemoveUntil(AppRoutes.appGroups);
        break;
      case 'memory':
        NavigatorService.pushNamedAndRemoveUntil(AppRoutes.appMemories);
        break;
      default:
        NavigatorService.pushNamedAndRemoveUntil(AppRoutes.appFeed);
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
                // Logo
                Container(
                  width: 80.h,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: appTheme.deep_purple_A100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.link,
                    size: 40.h,
                    color: appTheme.white_A700,
                  ),
                ),
                SizedBox(height: 32.h),

                // Loading or status indicator
                if (_isProcessing)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final delay = index * 0.3;
                          final opacity =
                              (((_animationController.value + delay) % 1.0) *
                                          2 -
                                      1)
                                  .abs();
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4.h),
                            width: 12.h,
                            height: 12.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appTheme.deep_purple_A100
                                  .withOpacity(opacity),
                            ),
                          );
                        }),
                      );
                    },
                  ),

                if (!_isProcessing)
                  Icon(
                    _isError ? Icons.error_outline : Icons.check_circle_outline,
                    size: 60.h,
                    color: _isError ? Colors.red : Colors.green,
                  ),

                SizedBox(height: 24.h),

                // Message
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                      .copyWith(color: appTheme.white_A700),
                ),

                if (_isError) ...[
                  SizedBox(height: 32.h),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Return to app',
                      style: TextStyleHelper
                          .instance.body14RegularPlusJakartaSans
                          .copyWith(color: appTheme.deep_purple_A100),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
