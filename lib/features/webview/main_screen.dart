// ignore_for_file: prefer_collection_literals, avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:albup/features/auth/kakao_sync/kakao_sync_auth_controller.dart';
import 'package:albup/features/webview/widgets/app_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:package_info/package_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final MsgController _msgController = Get.put(MsgController());

  /// 인덱스 페이지 초기화 (뒤로가기 / 앱 종료)
  bool isInMainPage = true;

  /// Page Loading Indicator 초기화
  bool isLoading = true;

  /// 웹뷰 컨트롤러 초기화
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  late WebViewController? _viewController;

  /// Import Cookie Manager
  final AppCookieManager cookieManager = AppCookieManager();

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) WebView.platform = AndroidWebView();
    _getPushToken();
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

  /// GET userId & Firebase token (Web Server ~ Application 통신)
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

    /// Version Management (Manually)
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
                    final Uri appStoreUri =
                        Uri.parse("https://apps.apple.com/app/알법/id6465881850");
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

  /// KakaoSync 토큰 요청 (Application ~ Web Server 통신)
  /// Android: ^1.0.3 버전 적용 예정
  /// IOS: ^1.0.2 버전 적용 예정
  void _onLoginSuccess(Map<String, dynamic> kakaoLoginData) {
    KakaoSyncAuthController authController = KakaoSyncAuthController();

    Map<String, dynamic> loginInfo = {
      "access_token": kakaoLoginData["access_token"],
      "refresh_token": kakaoLoginData["refresh_token"],
      "scopes": kakaoLoginData["scopes"],
      "id_token": kakaoLoginData['id_token'],
    };

    print("Kakao Sync Login Data: $kakaoLoginData");

    authController.sendLoginInfoToServer(loginInfo);
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

                      /// Cookie Management
                      await cookieManager.setCookies(
                        cookieManager.cookieValue,
                        cookieManager.domain,
                        cookieManager.cookieValue,
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
                          OAuthToken token = await UserApi.instance.loginWithKakaoTalk(serviceTerms: serviceTerms);
                          //print("카카오톡으로 로그인: $token");

                          _onLoginSuccess({
                            "access_token": token.accessToken,
                            "refresh_token": token.refreshToken,
                            "scopes": token.scopes,
                            "id_token": token.idToken,
                          });
                        } else {
                          AuthCodeClient.instance.authorize(
                            redirectUri: "https://albup.co.kr/plugin/kakao/redirect_kakao.php",
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
