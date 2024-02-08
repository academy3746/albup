# Introduction
1. 법률 상담 플랫폼, 알법
2. Service Scope: <a href="https://albup.co.kr" target="_blank">Web</a> / <a href="https://play.google.com/store/apps/details?id=kr.sogeum.albup&pli=1" target="_blank">Android</a> / <a href="https://apps.apple.com/app/알법/id6465881850" target="_blank">IOS</a>
3. Application Developing Tool: Flutter / Android Studio / X-Code
4. Server Configuration: Ubuntu / AWS
5. BackEnd Developing Tool: PHP / 그누보드 (CMS)

# External Plugin List (pubspec.yaml)
1. cupertino_icons: ^1.0.2
2. permission_handler: ^10.4.3
3. shared_preferences: ^2.2.0
4. flutter_webview_pro: ^3.0.1+4
5. url_launcher: ^6.1.12
6. firebase_core: ^2.15.1
7. firebase_crashlytics: ^3.3.5
8. firebase_analytics: ^10.4.5
9. firebase_messaging: ^14.6.6
10. flutter_local_notifications: ^9.1.5
11. get: ^4.6.5
12. get_storage: ^2.1.1
13. package_info: ^2.0.2
14. webview_cookie_manager: ^2.0.6
15. flutter_native_splash: ^2.3.2
16. kakao_flutter_sdk_user: ^1.5.0
17. http: ^1.1.0
18. open_file: ^3.3.2
19. dio: ^5.3.4
20. path_provider: ^2.1.1

# Issue01
Android 앱의 경우, 시스템의 소프트 키보드가 Input 입력필드를 가려버리는 현상 발생
- <a href="https://github.com/academy3746/albup/blob/main/lib/features/webview/main_screen.dart#L201">[lib/features/webview/main_screen.dart]</a> 201 Line
- 사용자의 입력필드 터치 인식, 해당 영역으로 자동 Focus 되도록 JavaScript 작성

# Issue02
웹 앱에서 제공하는 PDF 파일 다운로드 or 열람 지원 요청
- <a href="https://github.com/academy3746/albup/blob/main/lib/features/webview/main_screen.dart#L105">[lib/features/webview/main_screen.dart]</a> 105 Line '_downloadFile()'
- dio / path_provider / url_launcher 플러그인을 활용
- <a href="https://github.com/academy3746/albup/blob/main/lib/features/webview/main_screen.dart#L264">[lib/features/webview/main_screen.dart]</a> 264 Line URL 처리

# Issue03
1. 카카오톡 간편 로그인 기능 추가 요청
2. 문제점
- 알법 앱은 Web / Android / IOS 동시에 서비스 중인 Hybrid Application
- Chrome / Safari 기반의 WebViw 앱은 보안 이슈 때문에 '카카오 계정 로그인' 만 지원 (공식)
- 유저들은 본인의 카카오 계정을 대체로 기억 하지 못하는 것을 전제로 해야 함
- 최신 UX / UI 트랜드를 반영, '카카오톡 간편 로그인' 유저 편의성 패치 진행
3. kakao_flutter_sdk_user / url_launcher 플러그인 활용
4. <a href="https://github.com/academy3746/albup/blob/main/android/app/src/main/AndroidManifest.xml#L72">[app/src/main/AndroidManifest.xml]</a> 72 Line 설정 확인 (Android)
5. <a href="https://github.com/academy3746/albup/blob/main/ios/Runner/Info.plist#L26">[ios/Runner/Info.plist]</a> 26 Line 설정 확인 (IOS)
6. <a href="https://github.com/academy3746/albup/blob/main/lib/main.dart#L21">[lib/main.dart]</a> 21 Line KakaoSdk 초기화
7. <a href="https://github.com/academy3746/albup/blob/main/lib/features/webview/main_screen.dart#L118">[lib/features/webview/main_screen.dart]</a> 118 Line '_getUserAgent()'
- Android 및 IOS WebView에서는 '카카오 로그인' 새 창이 열리지 않을 수 있음
- 'getUserAgent()' 함수에서 UserAgent를 Chrome or Safari 브라우저 상수 값으로 조작할 필요가 있음
- 'WebView()' 위젯을 'FutureBuilder()' 위젯으로 Wrapping
- 새로운 UserAgent 값이 페이지 전체로 적용 되도록 snapShot으로 뿌려줌
- <a href="https://github.com/academy3746/albup/blob/main/lib/features/webview/main_screen.dart#L222">[lib/features/webview/main_screen.dart]</a> 222 Line URL 처리

# Issue04
앱 버전 체크 & 스토어 Direction 기능 추가 요청
- 공식 배포된 앱 버전과 사용자의 기기에 설치된 앱 버전을 체크
- 버전 불일치 (구 버전): 최신 버전 유지를 위해 스토어로 다이렉션 (Android / IOS 구분)
- package_info / url_launcher 플러그인 활용
- <a href="https://github.com/academy3746/albup/blob/main/lib/features/webview/widgets/app_version_checker.dart">[lib/features/webview/widgets/app_version_checker.dart]</a>
- <a href="https://github.com/academy3746/albup/blob/main/lib/features/webview/main_screen.dart#L97">[lib/features/webview/main_screen.dart]</a> 97 Line