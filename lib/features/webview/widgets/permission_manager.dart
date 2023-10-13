// ignore_for_file: avoid_print

import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

class StoragePermissionManager {
  final BuildContext context;

  StoragePermissionManager(this.context);

  void requestStoragePermission() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;
    if (status.isGranted) {
      PermissionStatus result =
      await Permission.manageExternalStorage.request();

      if (!result.isGranted) {
        print('Permission denied by user.');
      } else {
        print('Permission has submitted.');
      }
    }
  }
}