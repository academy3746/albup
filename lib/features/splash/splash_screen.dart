import 'dart:async';
import 'package:albup/features/webview/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/on_boarding_screen.dart';

class SplashScreen extends StatefulWidget {
  static String routeName = "/splash";

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    /// Direct to WebView widget or OnBoarding Screen after 3 seconds
    Timer(
      const Duration(seconds: 2),
      _navigateBasedOnFirstLaunch,
    );
  }

  /// 앱을 처음 설치한 유저 판별
  void _navigateBasedOnFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    if (seenOnboarding) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
    } else {
      await prefs.setBool('seen_onboarding', true);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(OnBoardingScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF37BBFF),
      body: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/splash_new.png"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
