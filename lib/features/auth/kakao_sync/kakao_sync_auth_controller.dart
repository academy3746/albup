// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class KakaoSyncAuthController {
  Future<void> sendLoginInfoToServer(Map<String, dynamic> loginInfo) async {
    /// Web Server Endpoint for processing Kakao Sync Authentication
    const String redirectURL = "https://albup.co.kr/plugin/kakao/redirect_kakao.php";

    print("Server Sending Data: $loginInfo");

    /// Send API to Web Server from Client
    var response = await http.post(
      Uri.parse(redirectURL),
      headers: {"Content-Type": "application/json"},
      body: json.encode(loginInfo),
    );

    /// Response from Web Server to Client: Just for Debugging
    try {
      if (response.statusCode == 200) {
        print("POST Succeed: ${response.statusCode}");
      } else {
        print("Post Failed: ${response.statusCode}");
      }
    } catch(e) {
      print("웹 서버 통신 오류: $e");
    }
  }
}
