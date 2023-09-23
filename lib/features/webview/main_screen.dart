// ignore_for_file: prefer_collection_literals, avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info/package_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import '../firebase/msg_controller.dart';

class MainScreen extends StatefulWidget {
  static String routeName = "/main";
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// URL 초기화
  final String url = "https://albup.co.kr/";

  final MsgController _msgController = Get.put(MsgController());

  /// 인덱스 페이지 초기화
  bool isInMainPage = true;

  /// 웹뷰 컨트롤러 초기화
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

  WebViewController? _viewController;

  /// Import Cookie Manager
  final WebviewCookieManager cookieManager = WebviewCookieManager();
  final String cookieValue = "cookieValue";
  final String domain = "albup.co.kr";
  final String cookieName = "cookieName";

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) WebView.platform = AndroidWebView();
    _requestStoragePermission();
    _getAppVersion(context);
  }

  /// 저장매체 접근 권한 요청
  void _requestStoragePermission() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      PermissionStatus result =
      await Permission.manageExternalStorage.request();
      if (!result.isGranted) {
        print('Permission denied by user');
      } else {
        print('Permission has submitted.');
      }
    }
  }

  /// Set JavaScript Channel
  JavascriptChannel _flutterWebviewProJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
      name: 'flutter_webview_pro',
      onMessageReceived: (JavascriptMessage message) async {
        Map<String, dynamic> jsonData = jsonDecode(message.message);
        if (jsonData['handler'] == 'webviewJavaScriptHandler') {
          if (jsonData['action'] == 'setUserId') {
            String userId = jsonData['data']['userId'];
            GetStorage().write('userId', userId);

            print('@addJavaScriptHandler userId $userId');

            String? token = await _getPushToken();
            _viewController?.runJavascript('tokenUpdate("$token")');
          }
        }
        setState(() {});
      },
    );
  }

  /// Get User Token
  Future<String?> _getPushToken() async {
    return await _msgController.getToken();
  }

  /// 뒤로 가기 Action
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

  /// Store Direction
  void _getAppVersion(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    print("User Device App Version: $version");

    /// Version Management (Hard Coded)
    const String androidVersion = "1.0.2";
    const String iosVersion = "1.0.1";

    if ((Platform.isAndroid && version != androidVersion) ||
        (Platform.isIOS && version != iosVersion)) {

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("앱 업데이트 정보"),
            content: const Text("앱 버전이 최신이 아닙니다.\n업데이트를 위해 마켓으로 이동하시겠습니까?"),
            actions: [
              TextButton(
                onPressed: () async {
                  if (Platform.isAndroid) {
                    final Uri playStoreUri =
                        Uri.parse("market://details?id=kr.sogeum.albup");
                    if (await canLaunchUrl(playStoreUri)) {
                      await launchUrl(playStoreUri);
                    } else {
                      throw "Can not launch $playStoreUri";
                    }
                  } else if (Platform.isIOS) {
                    // 해당 다이렉션은 정식 출시 기준으로 제대로 작동함
                    final Uri appStoreUri = Uri.parse(
                        "https://apps.apple.com/app/알법/id6465881850");
                    if (await canLaunchUrl(appStoreUri)) {
                      await launchUrl(appStoreUri);
                    } else {
                      throw "Can not launch $appStoreUri";
                    }
                  }

                  if (!mounted) return;

                  Navigator.of(context).pop();
                },
                child: const Text("확인"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("취소"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return WillPopScope(
            onWillPop: _onWillPop,
            child: SafeArea(
              child: WebView(
                initialUrl: url,
                javascriptMode: JavascriptMode.unrestricted,
                javascriptChannels: <JavascriptChannel>[
                  _flutterWebviewProJavascriptChannel(context),
                ].toSet(),
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

                  await cookieManager.getCookies(null);

                  await cookieManager.setCookies([
                    Cookie(cookieName, cookieValue)
                      ..domain = domain
                      ..expires = DateTime.now().add(
                        const Duration(
                          days: 90,
                        ),
                      )
                      ..httpOnly = false
                  ]);
                },
                onPageStarted: (String url) async {
                  print("Current Page: $url");
                },
                onPageFinished: (String url) async {
                  /// Android Soft Keyboard 가림 현상 조치
                  if (url.contains(url) && _viewController != null) {
                    await _viewController!.runJavascript("""
                      (function() {
                        function scrollToFocusedInput(event) {
                          const focusedElement = document.activeElement;
                          if (focusedElement.tagName.toLowerCase() === 'input' || focusedElement.tagName.toLowerCase() === 'textarea') {
                            setTimeout(() => {
                              focusedElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
                            }, 500);
                          }
                        }
                        document.addEventListener('focus', scrollToFocusedInput, true);
                      })();
                    """);
                  }
                },
                zoomEnabled: false,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                  Factory<EagerGestureRecognizer>(
                      () => EagerGestureRecognizer())
                ].toSet(),
                gestureNavigationEnabled: true,
              ),
            ),
          );
        },
      ),
    );
  }
}