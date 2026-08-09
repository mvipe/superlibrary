import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_colors.dart';

/// Full-screen QR/barcode scanner. Pops with the first scanned raw value.
///
/// Uses mobile_scanner 7.x, where the [MobileScanner] widget starts the camera
/// itself (after init, avoiding the start-during-build race that caused
/// genericError on 5.x) and manages the app lifecycle via useAppLifecycleState.
class ScanScreen extends StatefulWidget {
  final String title;
  const ScanScreen({super.key, this.title = 'Scan QR Code'});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _handled = false;
  PermissionStatus? _perm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      _controller ??= MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    }
    setState(() => _perm = status);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_perm != null && !_perm!.isGranted)) {
      _init(); // returned from Settings after (maybe) granting
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;
    _handled = true;
    Navigator.pop(context, code);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final granted = _perm?.isGranted ?? false;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title,
            style: GoogleFonts.lexend(
                color: Colors.white, fontWeight: FontWeight.w700)),
        actions: granted && _controller != null
            ? [
                IconButton(
                  icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                  onPressed: () => _controller!.toggleTorch(),
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch_rounded,
                      color: Colors.white),
                  onPressed: () => _controller!.switchCamera(),
                ),
              ]
            : null,
      ),
      body: _perm == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : granted && _controller != null
              ? _scannerView()
              : _permissionView(),
    );
  }

  Widget _scannerView() {
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: _controller!,
          onDetect: _onDetect,
          errorBuilder: (context, error) => _errorView(error),
        ),
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 3),
            borderRadius: BorderRadius.circular(AppColors.rXl),
          ),
        ),
        Positioned(
          bottom: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppColors.rMd),
            ),
            child: Text('Align the QR code within the frame',
                style: GoogleFonts.lexend(color: Colors.white, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _errorView(MobileScannerException error) {
    return _message(
      Icons.videocam_off_rounded,
      'Camera could not start',
      'Please try again.\n(${error.errorCode.name})',
      actionLabel: 'Retry',
      onAction: () async {
        await _controller?.dispose();
        _controller = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
        );
        if (mounted) setState(() {});
      },
    );
  }

  Widget _permissionView() {
    final permanentlyDenied = _perm?.isPermanentlyDenied ?? false;
    return _message(
      Icons.no_photography_rounded,
      'Camera permission needed',
      permanentlyDenied
          ? 'Camera access is blocked. Open Settings and allow the Camera permission for SuperLibrary, then come back.'
          : 'We need your camera to scan QR / barcodes. Please allow access.',
      actionLabel: permanentlyDenied ? 'Open Settings' : 'Allow Camera',
      onAction: () async {
        if (permanentlyDenied) {
          await openAppSettings();
        } else {
          await _init();
        }
      },
    );
  }

  Widget _message(IconData icon, String title, String body,
      {required String actionLabel, required VoidCallback onAction}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                    color: Colors.white70, fontSize: 13.5, height: 1.4)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
