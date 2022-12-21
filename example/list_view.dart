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
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RotaryScrollWrapper(
        rotaryScrollbar: RotaryScrollbar(
          controller: scrollController,
        ),
        child: ListView.builder(
          controller: scrollController,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 10,
              ),
              child: Container(
                color: Colors.blue.withRed(((255 / 29) * index).toInt()),
                width: 50,
                height: 50,
                child: Center(child: Text('box $index')),
              ),
            );
          },
          itemCount: 30,
        ),
      ),
    );
  }
}
