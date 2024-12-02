import 'package:client/Screens/home/MainPageState.dart';
import 'package:client/Screens/identity/LoginPageState.dart';
import 'package:client/Screens/identity/RegisterPageState.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'PackDelivery',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        // fontFamily: 'Work Sans',
      ),
      home: AuthCheck(),

      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => MainPage(),
      },
    );
  }
}
