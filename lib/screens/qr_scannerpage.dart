import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_app_tt/utils/error_mapper.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/file_scan_service.dart';

class QRScannerPage extends StatefulWidget {
  final String departmentId;
  final String eventType;

  const QRScannerPage({
    super.key,
    required this.departmentId,
    required this.eventType,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  late final MobileScannerController cameraController;
  bool isScanned = false;
  String? scanResult;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
    cameraController.start();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (isScanned) return;
    final Barcode barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null) {
      setState(() {
        isScanned = true;
        scanResult = code;
      });
      try {
        await FileScanService.instance.recordScan(
          fileId: code,
          departmentId: widget.departmentId,
          eventType: widget.eventType,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Scan recorded')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to record scan: ${mapSupabaseError(e)}')));
        }
      }
      // Never log scanned file identifiers to the system console in release
      // builds — device logs are readable by other apps / MDM tooling.
      if (kDebugMode) {
        debugPrint('Scanned QR Code: $code');
      }
    }
  }

  void _rescan() {
    setState(() {
      isScanned = false;
      scanResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan File QR'),
        actions: [
          IconButton(
            onPressed: () async {
              await cameraController.toggleTorch();
              setState(() {});
            },
            icon: Icon(
              cameraController.value.torchState == TorchState.off
                  ? Icons.flash_off
                  : Icons.flash_on,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: _onDetect,
                ),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (scanResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Scanned: $scanResult',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _rescan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Rescan'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
