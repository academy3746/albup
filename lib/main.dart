// ignore_for_file: avoid_print
import 'dart:async';
import 'package:albup/features/webview/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'features/onboarding/on_boarding_screen.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runZonedGuarded(() async {}, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  });

  KakaoSdk.init(
    nativeAppKey: "665da4cfe7a96bdb5eb9e7208537b800",
    javaScriptAppKey: "03a6b3234b675b3c84c2b515d6f6cfbb",
  );

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F81FC)),
        primaryColor: const Color(0xFF37BBFF),
        useMaterial3: false,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        MainScreen.routeName: (context) => const MainScreen(),
        OnBoardingScreen.routeName: (context) => const OnBoardingScreen(),
      },
    );
  }
}