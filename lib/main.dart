import 'package:flutter/material.dart';
import 'package:tera_gate_app/screens/login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tera_gate_app/service/loginService.dart';
import 'package:tera_gate_app/screens/bluetooth.dart';
import 'package:tera_gate_app/utils/loginStatus.dart';

import 'screens/beacon.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SplashPage(),
    );
  }
}
//testsetergregreg

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () => _checkUser(context));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
          child: Icon(
        Icons.stream,
        size: 80,
        color: Colors.blue,
      )),
    );
  }

  void _checkUser(context) async {
    const flutterSecureStorage = FlutterSecureStorage();
    debugPrint('${await flutterSecureStorage.readAll()}');
    Map<String, String> allStorage = await flutterSecureStorage.readAll();
    String statusUser = '';
    String loginId = '';
    String loginPw = '';
    if (allStorage.isNotEmpty) {
      allStorage.forEach((k, v) {
        debugPrint('k : $k, v : $v');
        if (v == STATUS_LOGIN) statusUser = k;

        if (k == 'LOGIN_ID') loginId = v;
        if (k == 'LOGIN_PW') loginPw = v;
      });
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Login()));
    }
        
    loginCheck(loginId, loginPw).then((data) {
      if (data.success) {
        
        if (statusUser.isNotEmpty) {
        
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const Beacon()));
        } else {
        
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const Login()));
        }
      } else {
        
        showSnackBar(context, data.message);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const Login()));
      }
    });
  }
}
