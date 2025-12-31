import '../../core/app_export.dart';
import '../../shared/widgets/qr_scanner_overlay.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QRScannerOverlay(
      scanType: 'friend',
      onSuccess: () {
        Navigator.pop(context);
      },
    );
  }
}
