import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

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

  void _onDetect(BarcodeCapture capture) {
    if (isScanned) return;
    final Barcode barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null) {
      setState(() {
        isScanned = true;
        scanResult = code;
      }); 
      print('Scanned QR Code: $code');
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
