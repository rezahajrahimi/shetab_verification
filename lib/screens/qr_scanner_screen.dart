import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with WidgetsBindingObserver {
  late final MobileScannerController controller;
  bool _hasScanned = false; // برای جلوگیری از اسکن مجدد

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    WidgetsBinding.instance.addObserver(this);
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_hasScanned) return; // اگر قبلاً اسکن شده، برگرد

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        debugPrint('QR Code detected: ${barcode.rawValue}');
        
        setState(() {
          _hasScanned = true; // علامت‌گذاری که اسکن انجام شده
        });

        // توقف اسکنر
        controller.stop();
        
        // برگشت با تاخیر کوتاه
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop(barcode.rawValue);
          }
        });
        
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope( // برای مدیریت دکمه برگشت
      onPopInvokedWithResult: (didPop, result) {
        controller.stop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اسکن QR Code'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await controller.stop();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, state, child) {
                  return Icon(
                    Icons.flash_on,
                  );
                },
              ),
              onPressed: () => controller.toggleTorch(),
            ),
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, state, child) {
                  return Icon(
                   Icons.camera_front
                  );
                },
              ),
              onPressed: () => controller.switchCamera(),
            ),
          ],
        ),
        body: MobileScanner(
          controller: controller,
          onDetect: _handleBarcode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_hasScanned) {
          controller.start();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller.stop();
        break;
    }
  }
} 