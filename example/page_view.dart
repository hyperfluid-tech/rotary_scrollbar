import 'package:flutter/material.dart';
import 'package:rotary_scrollbar/rotary_scrollbar.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: const WatchScreen(),
    );
  }
}

class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  final pageController = PageController();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RotaryScrollbar(
        controller: pageController,
        child: PageView(
          scrollDirection: Axis.vertical,
          controller: pageController,
          children: [
            Container(),
            Container(),
            Container(),
          ],
        ),
      ),
    );
  }
}
