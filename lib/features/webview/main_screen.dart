// ignore_for_file: prefer_collection_literals, avoid_print
import 'dart:async';
import 'dart:io';
import 'package:albup/features/auth/kakao_sync/kakao_login_process.dart';
import 'package:albup/features/webview/widgets/app_cookie_manager.dart';
import 'package:albup/features/webview/widgets/app_version_checker.dart';
import 'package:albup/features/webview/widgets/back_action_handler.dart';
import 'package:albup/features/webview/widgets/permission_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../firebase/fcm_controller.dart';

/// Kakao Sync TAG
List<String> serviceTerms = ['service_20230810'];

class MainScreen extends StatefulWidget {
  static String routeName = "/main";

  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// URL 초기화
  final String url = "https://albup.co.kr/";

  /// Push Setting 초기화
  final MsgController msgController = Get.put(MsgController());

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

  /// Import KaKao Sync Login Process
  final LoginProcess loginProcess = LoginProcess();

  /// Import Back Action Handler
  late final BackActionHandler backActionHandler;

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) WebView.platform = AndroidWebView();

    _getPushToken();

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

  /// Get User Token
  Future<String?> _getPushToken() async {
    return await msgController.getToken();
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
              return WillPopScope(
                onWillPop: () => backActionHandler.onWillPop(),
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
                      if (Platform.isAndroid) {
                        if (url.contains(url) && _viewController != null) {
                          await _viewController!.runJavascript("""
                            (function() {
                              function scrollToFocusedInput(event) {
                                const focusedElement = document.activeElement;
                                if (focusedElement.tagName.toLowerCase() === 'input' || focusedElement.tagName.toLowerCase() === 'textarea') {
                                  setTimeout(() => {
                                    focusedElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
                                  }, 500);
                                  
                                  window.scrollBy(0, 350);
                                }
                              }
                              document.addEventListener('focus', scrollToFocusedInput, true);
                            })();
                    """);
                        }
                      }
                    },
                    navigationDelegate: (NavigationRequest request) async {
                      if (request.url.contains(
                          "https://kauth.kakao.com/oauth/authorize")) {
                        if (await isKakaoTalkInstalled()) {
                          OAuthToken token = await UserApi.instance
                              .loginWithKakaoTalk(serviceTerms: serviceTerms);
                          //print("카카오톡으로 로그인: $token");

                          loginProcess.onLoginSuccess({
                            "access_token": token.accessToken,
                            "refresh_token": token.refreshToken,
                            "scopes": token.scopes,
                            "id_token": token.idToken,
                          });
                        } else {
                          AuthCodeClient.instance.authorize(
                            redirectUri:
                                "https://albup.co.kr/plugin/kakao/redirect_kakao.php",
                          );
                          print("카카오 계정으로 로그인");
                        }
                        return NavigationDecision.prevent;
                      }

                      return NavigationDecision.navigate;
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