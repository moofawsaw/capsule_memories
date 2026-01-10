import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

import '../core/app_export.dart';

class JoinHandlerPage extends StatefulWidget {
  final String type;
  final String code;

  const JoinHandlerPage({
    Key? key,
    required this.type,
    required this.code,
  }) : super(key: key);

  @override
  State<JoinHandlerPage> createState() => _JoinHandlerPageState();
}

class _JoinHandlerPageState extends State<JoinHandlerPage> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processJoinRequest();
  }

  Future<void> _processJoinRequest() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'handle-qr-scan',
        body: {
          'type': widget.type,
          'code': widget.code,
        },
      );

      if (response.status == 200) {
        // SUCCESS: Trigger vibration
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 200);
        }

        // Show dynamic success confirmation dialog
        await _showSuccessDialog();

        // Navigate based on type
        if (mounted) {
          if (widget.type == 'friend') {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.appFriends,
            );
          } else if (widget.type == 'memory') {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.appMemories,
            );
          } else if (widget.type == 'group') {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.appGroups,
            );
            // Show toast after navigation to groups
            _showSuccessToast();
          } else {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.app,
            );
          }
        }
      } else {
        throw Exception(response.data?['error'] ?? 'Failed to process request');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  Future<void> _showSuccessDialog() async {
    String entityType = '';
    switch (widget.type) {
      case 'friend':
        entityType = 'friend';
        break;
      case 'memory':
        entityType = 'memory';
        break;
      case 'group':
        entityType = 'group';
        break;
      default:
        entityType = widget.type;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: appTheme.gray_900_02,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Congratulations!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have successfully joined: $entityType',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(204),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(color: appTheme.deep_purple_A100),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessToast() {
    Fluttertoast.showToast(
      msg: 'Successfully joined group!',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Processing your request...',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 24),
                    Text(
                      'Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage ?? 'Unknown error occurred',
                      style: TextStyle(
                        color: Colors.white.withAlpha(204),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.app,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Go to Home',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
