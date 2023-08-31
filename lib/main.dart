// ignore_for_file: avoid_print
import 'dart:async';
import 'package:albup/features/webview/webview_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> fetchData() async {
  bool data = false;

  await Future.delayed(const Duration(milliseconds: 300), () {
    data = true;
  });

  return data;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  bool data = await fetchData();
  print(data);

  runZonedGuarded(() async {}, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  });

  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AlbupApp());
}

class AlbupApp extends StatelessWidget {
  const AlbupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '알법',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2f81fc)),
        primaryColor: const Color(0xff2f81fc),
        useMaterial3: false,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const WebviewController(),
    );
  }
}
