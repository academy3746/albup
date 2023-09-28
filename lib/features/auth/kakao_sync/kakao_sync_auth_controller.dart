// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class KakaoSyncAuthController {
  Future<void> sendLoginInfoToServer(Map<String, dynamic> loginInfo) async {
    /// Kakao Sync Endpoint
    const String webServerEndPoint = "https://albup.co.kr/plugin/kakao/redirect_kakao.php";

    final response = await http.post(
      Uri.parse(webServerEndPoint),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(loginInfo),
    );

    if (response.statusCode == 200) {
      print("POST Succeed: ${jsonDecode(response.body)}");
    } else {
      print("POST Failed: ${jsonDecode(response.body)}");
    }
  }
}
