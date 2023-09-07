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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../firebase/msg_controller.dart';

class WebviewController extends StatefulWidget {
  const WebviewController({Key? key}) : super(key: key);

  @override
  State<WebviewController> createState() => _WebviewControllerState();
}

class _WebviewControllerState extends State<WebviewController> {
  /// URL 초기화
  final String url = "https://albup.co.kr/";

  final MsgController _msgController = Get.put(MsgController());

  /// 인덱스 페이지 초기화
  bool isInMainPage = true;

  /// 웹뷰 컨트롤러 초기화
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

  WebViewController? _viewController;

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

  /// 쿠키 획득
  Future<String> _getCookies(WebViewController controller) async {
    final String cookies =
    await controller.runJavascriptReturningResult('document.cookie;');
    return cookies;
  }

  /// 쿠키 설정
  Future<void> _setCookies(WebViewController controller, String cookies) async {
    await controller
        .runJavascriptReturningResult('document.cookie="$cookies";');
  }

  /// 쿠키 저장
  Future<void> _saveCookies(String cookies) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cookies', cookies);
  }

  /// 쿠키 로드
  Future<String?> _loadCookies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('cookies');
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
    const String iosVersion = "1.0.0";

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
                    final Uri marketUri =
                        Uri.parse("market://details?id=kr.sogeum.albup");
                    if (await canLaunchUrl(marketUri)) {
                      await launchUrl(marketUri);
                    } else {
                      throw "Can not launch $marketUri";
                    }
                  } else if (Platform.isIOS) {
                    // 추후 개발자 계정 생성 시 올바른 앱 이름과 id 번호 기입할 것
                    // "https://apps.apple.com/app/알법/id0000000000"
                    final Uri appStoreUri = Uri.parse(
                        "https://youtube.com");
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
          return SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: WillPopScope(
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

                    if (url.contains(
                        "${url}login.php") &&
                        _viewController != null) {
                      final cookies = await _getCookies(_viewController!);
                      await _saveCookies(cookies);
                    } else {
                      final cookies = await _loadCookies();

                      if (cookies != null) {
                        await _setCookies(_viewController!, cookies);
                      }
                    }
                  },
                  geolocationEnabled: true,
                  zoomEnabled: false,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                    Factory<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                    ),
                  ].toSet(),
                  gestureNavigationEnabled: true, // IOS Only
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}