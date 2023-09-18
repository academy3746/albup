// ignore_for_file: avoid_print
import 'dart:async';
import 'package:albup/features/webview/kakao_sink_screen.dart';
import 'package:albup/features/webview/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/onboarding/on_boarding_screen.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  /*bool data = await fetchData();
  print(data);*/

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF37BBFF)),
        primaryColor: const Color(0xFF37BBFF),
        useMaterial3: false,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      //home: const MainScreen(),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        MainScreen.routeName: (context) => const MainScreen(),
        OnBoardingScreen.routeName: (context) => const OnBoardingScreen(),
        KakaoSinkScreen.routeName: (context) => const KakaoSinkScreen(),
      },
    );
  }
}

// Old Splash Screen
/*
Future<bool> fetchData() async {
  bool data = false;

  await Future.delayed(
      const Duration(
        seconds: 1,
      ), () {
    data = true;
  });

  return data;
}*/
