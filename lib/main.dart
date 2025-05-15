import 'package:flutter/material.dart';
import 'package:my_clima_app/screens/clima_homepage.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Clima App',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Mi Clima App',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey,
            ),
          ),
        ),
        body: ClimaHomepage(),
      ),
    );
  }
}
