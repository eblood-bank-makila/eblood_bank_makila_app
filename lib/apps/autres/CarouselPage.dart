import 'package:flutter/material.dart';
import 'dart:async';

class CarouselPage extends StatefulWidget {
  @override
  _CarouselPageState createState() => _CarouselPageState();
}

class _CarouselPageState extends State<CarouselPage> {
  final List<String> images = [
    'assets/images/baniere1.webp',
    'assets/images/baniere.webp',
    'assets/images/baniere2.webp',
  ];

  final PageController _pageController = PageController();
  late Timer _timer;
  int _currentPage = 0;
  bool _isForward = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_isForward) {
        if (_currentPage < images.length - 1) {
          _currentPage++;
        } else {
          _currentPage--;
          _isForward = false;
        }
      } else {
        if (_currentPage > 0) {
          _currentPage--;
        } else {
          _currentPage++;
          _isForward = true;
        }
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 155,
      child: PageView.builder(
        controller: _pageController,
        itemCount: images.length,
        itemBuilder: (BuildContext context, int index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              images[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
