// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

class AppVersionCheck {
  final BuildContext context;

  AppVersionCheck(this.context);

  Future<void> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    print("User Device App Version: $version");

    /// Version Management (Manually)
    const String androidVersion = "1.0.2";
    const String iosVersion = "1.0.1";

    if ((Platform.isAndroid && version != androidVersion) ||
        (Platform.isIOS && version != iosVersion)) {
      _showUpdateDialog();
    }
  }

  void _showUpdateDialog() {
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
                  final Uri appStoreUri =
                      Uri.parse("https://apps.apple.com/app/알법/id6465881850");
                  if (await canLaunchUrl(appStoreUri)) {
                    await launchUrl(appStoreUri);
                  } else {
                    throw "Can not launch $appStoreUri";
                  }
                }

                if (!context.mounted) return;
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
