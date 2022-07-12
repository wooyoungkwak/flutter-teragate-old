import 'package:flutter/material.dart';
import 'package:tera_gate_app/screens/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'teragate',
      initialRoute: '/',
      routes: {
        '/': (context) => const Login(),
      },
    );
  }
}
