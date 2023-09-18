// ignore_for_file: avoid_print, prefer_collection_literals

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';

class KakaoSinkScreen extends StatefulWidget {
  static String routeName = "/kakao";
  const KakaoSinkScreen({super.key});

  @override
  State<KakaoSinkScreen> createState() => _KakaoSinkScreenState();
}

class _KakaoSinkScreenState extends State<KakaoSinkScreen> {
  final String url = "https://albup.co.kr/bbs/login_new.php";

  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SafeArea(
            child: WebView(
              initialUrl: url,
              javascriptMode: JavascriptMode.unrestricted,
              onWebResourceError: (error) {
                print("Error Code: ${error.errorCode}");
                print("Error Description: ${error.description}");
              },
              onWebViewCreated:
                  (WebViewController webviewController) async {
                _controller.complete(webviewController);
              },
              onPageStarted: (String url) async {
                print("Current Page: $url");
              },
              geolocationEnabled: true,
              zoomEnabled: false,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                Factory<EagerGestureRecognizer>(
                        () => EagerGestureRecognizer())
              ].toSet(),
              gestureNavigationEnabled: true, // IOS Only
              //userAgent: "Mozilla/5.0 (iPad; CPU OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1",
            ),
          );
        },
      ),
    );
  }
}
