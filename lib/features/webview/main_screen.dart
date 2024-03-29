// ignore_for_file: avoid_print, prefer_collection_literals, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:albup/features/firebase/fcm_controller.dart';
import 'package:albup/features/webview/widgets/app_cookie_manager.dart';
import 'package:albup/features/webview/widgets/app_version_checker.dart';
import 'package:albup/features/webview/widgets/back_action_handler.dart';
import 'package:albup/features/webview/widgets/permission_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatefulWidget {
  static const String routeName = "/main";

  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// URL 초기화
  final String url = "https://albup.co.kr/";

  /// Push Setting 초기화
  MsgController msgController = Get.put(MsgController());

  /// 인덱스 페이지 초기화 (앱 종료)
  bool isInMainPage = true;

  /// Page Loading Indicator 초기화
  bool isLoading = true;

  /// 웹뷰 컨트롤러 초기화
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  WebViewController? _viewController;

  /// Import Cookie Manager
  AppCookieManager? cookieManager;

  /// Import Back Action Handler
  late final BackActionHandler backActionHandler;

  /// App ~ Web Server Communication
  JavascriptChannel _flutterWebviewProJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
      name: 'flutter_webview_pro',
      onMessageReceived: (JavascriptMessage message) async {
        Map<String, dynamic> jsonData = jsonDecode(message.message);
        if (jsonData['handler'] == 'webviewJavaScriptHandler') {
          if (jsonData['action'] == 'setUserId') {
            String userId = jsonData['data']['userId'];

            GetStorage().write('userId', userId);

            print("Communication Succeed: ${message.message}");

            String? token = await msgController.getToken();

            if (token != null) {
              _viewController?.runJavascript('tokenUpdate("$token")');
            } else {
              print("Fail to send token to server: ${message.message}");
            }
          }
        }
        setState(() {});
      },
    );
  }

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    /// 저장매체 접근 권한
    StoragePermissionManager permissionManager =
        StoragePermissionManager(context);
    permissionManager.requestStoragePermission();

    /// App Version Check
    AppVersionCheck appVersionCheck = AppVersionCheck(context);
    appVersionCheck.getAppVersion();

    /// Initialize Cookies
    cookieManager = AppCookieManager(url, url);
  }

  /// Download PDF File in App
  Future<void> _downloadFile(String url) async {
    final dio = Dio();

    final dir = await getExternalStorageDirectory();

    final path = "${dir?.path}/$url.pdf";

    await dio.download(url, path);

    await OpenFile.open(path);
  }

  /// Manipulate User Agent for Kakao Login
  Future<String> _getUserAgent() async {
    var userAgent = "undefined";

    userAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone 0S 10_3_1 like Mac OS X) AppLeWebKit/603.1.30 (KHM, Like Gecko) Version/10.0 Mobile/14304 Safari/602.1";

    return userAgent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return FutureBuilder<String>(
                future: _getUserAgent(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return WillPopScope(
                      onWillPop: () => backActionHandler.onWillPop(),
                      child: SizedBox(
                        height: constraints.maxHeight,
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

                              /// Back Gesture when Webview resources created
                              backActionHandler = BackActionHandler(
                                context,
                                _viewController,
                                url,
                              );

                              /// Application exit or not
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

                              /// Cookie Management
                              await cookieManager?.setCookies(
                                cookieManager!.cookieValue,
                                cookieManager!.domain,
                                cookieManager!.cookieValue,
                                cookieManager!.url,
                              );
                            },
                            onPageStarted: (String url) async {
                              setState(() {
                                isLoading = true;
                              });
                              print("Current Page: $url");
                            },
                            onPageFinished: (String url) async {
                              setState(() {
                                isLoading = false;
                              });

                              /// Android Soft Keyboard 가림 현상 조치
                              /// window.scrollBy(0, 350);
                              if (Platform.isAndroid) {
                                if (url.contains(url) &&
                                    _viewController != null) {
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
                              }
                            },
                            navigationDelegate:
                                (NavigationRequest request) async {
                              if (request.url.startsWith("kakaotalk://")) {
                                /// 카카오톡 로그인 Request
                                if (await isKakaoTalkInstalled()) {
                                  try {
                                    await launchUrl(Uri.parse(request.url));

                                    print("Request Kakao Talk Login");
                                  } catch (e) {
                                    print("카카오톡 로그인 요청 실패: $e");

                                    /// 사용자에 의한 취소 처리 Handling
                                    if (e is PlatformException &&
                                        e.code == 'CANCELED') {
                                      print("카카오톡 로그인 요청 취소");

                                      return NavigationDecision.prevent;
                                    }

                                    /// 카카오톡 미설치 시, 카카오 계정으로 로그인
                                    try {
                                      print("카카오 계정으로 로그인");

                                      await UserApi.instance
                                          .loginWithKakaoAccount();
                                    } catch (e) {
                                      print("카카오 계정 로그인 실패: $e");
                                    }
                                  }
                                } else {
                                  /// 카카오톡 미설치 시, 카카오 계정으로 로그인
                                  try {
                                    print("카카오 계정으로 로그인");

                                    await UserApi.instance
                                        .loginWithKakaoAccount();
                                  } catch (e) {
                                    print("카카오 계정 로그인 실패: $e");
                                  }
                                }
                                return NavigationDecision.prevent;
                              }

                              if (request.url
                                  .contains("/data/judgment_pdf_drunk/")) {
                                await _downloadFile(request.url);

                                return NavigationDecision.prevent;
                              }

                              return NavigationDecision.navigate;
                            },
                            zoomEnabled: false,
                            gestureRecognizers: Set()
                              ..add(
                                Factory<EagerGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              ),
                            gestureNavigationEnabled: true,
                            userAgent: snapshot.data,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const CircularProgressIndicator.adaptive();
                  }
                },
              );
            },
          ),
          isLoading
              ? const Center(
                  child: CircularProgressIndicator.adaptive(),
                )
              : Container(),
        ],
      ),
    );
  }
}
