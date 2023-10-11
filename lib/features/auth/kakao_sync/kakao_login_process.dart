// ignore_for_file: avoid_print
import 'package:albup/features/auth/kakao_sync/kakao_sync_auth_controller.dart';

/// KakaoSync 토큰 요청 (Application ~ Web Server 통신)
/// Android: ^1.0.3 버전 적용 예정
/// IOS: ^1.0.2 버전 적용 예정
class LoginProcess {
  void onLoginSuccess(Map<String, dynamic> kakaoLoginData) {
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
}