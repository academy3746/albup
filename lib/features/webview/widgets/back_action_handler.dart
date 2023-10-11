// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';

class BackActionHandler {
  final BuildContext context;
  final WebViewController? _viewController;
  final String url;

  BackActionHandler(
    this.context,
    this._viewController,
    this.url,
  );

  Future<bool> onWillPop() async {
    if (_viewController == null) {
      return false;
    }

    final currentUrl = await _viewController?.currentUrl();

    if (currentUrl == url) {
      return await _showExitDialog();
    } else if (await _viewController!.canGoBack()) {
      await _viewController!.goBack();
      print("이전 페이지로 이동하였습니다.");
      return false;
    }
    return false;
  }

  Future<bool> _showExitDialog() {
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
  }
}
