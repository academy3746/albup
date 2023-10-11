import 'dart:io';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class AppCookieManager {
  final WebviewCookieManager _cookieManager = WebviewCookieManager();
  final String _cookieValue = "cookieValue";
  final String _domain = "albup.co.kr";
  final String _cookieName = "cookieName";

  /// Getter
  String get cookieValue => _cookieValue;
  String get domain => _domain;
  String get cookieName => _cookieName;

  Future<void> setCookies(String cookieValue, String domain, String cookieName) async {
    await _cookieManager.getCookies(null);

    await _cookieManager.setCookies([
      Cookie(cookieName, cookieValue)
        ..domain = domain
        ..expires = DateTime.now().add(
          const Duration(
            days: 90,
          ),
        )
        ..httpOnly = false
    ]);
  }
}