import 'package:albup/constants/sizes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../webview/main_screen.dart';

class OnBoardingScreen extends StatefulWidget {
  static const String routeName = "/onboard";

  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  int _idx = 0;
  final PageController _pageController = PageController();

  final List<String> _images = [
    "assets/images/onboarding1.png",
    "assets/images/onboarding2.png",
    "assets/images/onboarding3.png"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              child: CupertinoButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    MainScreen.routeName
                  );
                },
                child: Icon(
                  Icons.close,
                  color: Colors.grey.shade700,
                  size: Sizes.size30,
                ),
              ),
            ),
            Positioned(
              top: Sizes.size42,
              left: MediaQuery.of(context).size.width * 0.42,
              child: Row(
                children: List.generate(
                  _images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: Sizes.size5,
                    ),
                    height: Sizes.size10,
                    width: _idx == index
                        ? Sizes.size24 + Sizes.size1
                        : Sizes.size10,
                    decoration: BoxDecoration(
                      color: _idx == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(
                        Sizes.size5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: Sizes.size42,
                vertical: Sizes.size80 + Sizes.size24,
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (int page) {
                  setState(() {
                    _idx = page;
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  return Image.asset(
                    _images[index],
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 0.7,
        child: Padding(
          padding: const EdgeInsets.only(
            top: Sizes.size8,
            bottom: Sizes.size8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CupertinoButton(
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  if (_idx == _images.length - 1) {
                    Navigator.pushNamed(
                      context,
                      MainScreen.routeName
                    );
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(
                        milliseconds: 300,
                      ),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(
                  _idx == _images.length - 1 ? "확인" : "다음",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
