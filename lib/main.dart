import 'package:flutter/material.dart';
import 'screens/phone_input_screen.dart';

void main() {
  runApp(PhoneVerificationApp());
}

class PhoneVerificationApp extends StatelessWidget {
  const PhoneVerificationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Verification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const PhoneInputScreen(),
      debugShowCheckedModeBanner: true, //false
    );
  }
}