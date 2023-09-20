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
  //final String url = "https://albup.co.kr/bbs/login.php";

  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

   WebViewController? _viewController;

   bool isInMainPage = true;

   Future<bool> _onWillPop() async {
     if (_viewController == null) {
       return false;
     }

     final currentUrl = await _viewController?.currentUrl();

     if (currentUrl == url) {
       if (!mounted) return false;
       return showDialog<bool>(
         context: context,
         builder: (context) {
           return AlertDialog(
             title: const Text("앱을 종료하시겠습니까?"),
             actions: <Widget>[
               TextButton(
                 onPressed: () {
                   Navigator.of(context).pop(true);
                   print("앱이 포그라운드에서 종료되었습니다.");
                 },
                 child: const Text("확인"),
               ),
               TextButton(
                 onPressed: () {
                   Navigator.of(context).pop(false);
                   print("앱이 종료되지 않았습니다.");
                 },
                 child: const Text("취소"),
               ),
             ],
           );
         },
       ).then((value) => value ?? false);
     } else if (await _viewController!.canGoBack() && _viewController != null) {
       _viewController!.goBack();
       print("이전 페이지로 이동하였습니다.");

       isInMainPage = false;
       return false;
     }
     return false;
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return WillPopScope(
            onWillPop: _onWillPop,
            child: SafeArea(
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
                  _viewController = webviewController;

                  webviewController.currentUrl().then((url) {
                    if (url == "$url") {
                      setState(() {
                        isInMainPage = true;
                      });
                    } else {
                      setState(() {
                        isInMainPage = false;
                      });
                    }
                  });
                },
                onPageStarted: (String url) async {
                  print("Current Page: $url");
                },
                zoomEnabled: false,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                  Factory<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer())
                ].toSet(),
                gestureNavigationEnabled: false,
                //userAgent: "Mozilla/5.0 (iPad; CPU OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1",
              ),
            ),
          );
        },
      ),
    );
  }
}
