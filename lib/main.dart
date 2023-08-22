// ignore_for_file: avoid_print

import 'package:albup/features/webview/webview_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void launchURL() async {
  const url = "albup://kr.sogeum.albup";

  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    throw "Can't launch $url";
  }
}

Future<bool> fetchData() async {
  bool data = false;

  await Future.delayed(
      const Duration(
        milliseconds: 300,
      ), () {
    data = true;
  });

  return data;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool data = await fetchData();
  print(data);

  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
