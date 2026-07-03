import 'package:flutter/material.dart';

void main() {
  runApp(const HokHelperBootstrap());
}

class HokHelperBootstrap extends StatelessWidget {
  const HokHelperBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF070A12),
        body: Center(
          child: Text(
            'HOK Helper Mobile',
            style: TextStyle(color: Color(0xFFF5D06F), fontSize: 24),
          ),
        ),
      ),
    );
  }
}
