import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBK OCR',
      theme: ThemeData.dark(),
      home: const OCRWebView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class OCRWebView extends StatefulWidget {
  const OCRWebView({super.key});
  @override
  State<OCRWebView> createState() => _OCRWebViewState();
}

class _OCRWebViewState extends State<OCRWebView> {
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BBK OCR — UAT')),
      body: SafeArea(
        child: InAppWebView(
          initialFile: 'assets/bbk_ocr_strict_uat.html',
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            transparentBackground: true,
            allowsInlineMediaPlayback: true,
            useOnDownloadStart: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            supportZoom: true,
            builtInZoomControls: true,
            displayZoomControls: false,
            domStorageEnabled: true,
            cacheEnabled: true,
          ),
          onWebViewCreated: (c) => _controller = c,
          androidOnPermissionRequest: (controller, origin, resources) async {
            return PermissionRequestResponse(
              resources: resources,
              action: PermissionRequestResponseAction.GRANT,
            );
          },
          onConsoleMessage: (c, msg) {
            // ignore: avoid_print
            print("[WEB] ${msg.messageLevel.name}: ${msg.message}");
          },
        ),
      ),
    );
  }
}
