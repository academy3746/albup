// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class KakaoSyncAuthController {
  Future<void> sendLoginInfoToServer(Map<String, dynamic> loginInfo) async {
    /// Web Server Endpoint for processing Kakao Sync Authentication
    const String webServerEndPoint = "https://albup.co.kr/plugin/kakao/redirect_kakao.php";

    /// Send API to Web Server from Client
    final response = await http.post(
      Uri.parse(webServerEndPoint),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(loginInfo),
    );

    /// Response from Web Server to Client
    if (response.statusCode == 200) {
      //print("POST Succeed: ${jsonDecode(response.body)}");
      print("POST Succeed: ${response.body}");
    } else {
      //print("POST Failed: ${jsonDecode(response.body)}");
      print("POST Failed: ${response.body}");
    }
  }
}
