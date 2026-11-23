import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/views/show_all_food_tracker_ui.dart';

class SplashScreenUI extends StatefulWidget {
  const SplashScreenUI({super.key});

  @override
  State<SplashScreenUI> createState() => _SplashScreenUIState();
}

class _SplashScreenUIState extends State<SplashScreenUI> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _goToHomePage();
  }

  Future<void> _goToHomePage() async {
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ShowAllFoodTrackerUI()),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF44336),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/Food.png',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              const Text(
                'Food Tracker',
                style: TextStyle(
                  color: Color(0xFFFFEB3B),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fastfood_rounded,
                    color: Color(0xFFFFEB3B),
                    size: 30,
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.restaurant_rounded,
                    color: Color(0xFFFFEB3B),
                    size: 30,
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.lunch_dining_rounded,
                    color: Color(0xFFFFEB3B),
                    size: 30,
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.local_pizza_rounded,
                    color: Color(0xFFFFEB3B),
                    size: 30,
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.icecream_rounded,
                    color: Color(0xFFFFEB3B),
                    size: 30,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFEB3B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
