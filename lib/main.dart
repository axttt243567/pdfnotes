import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScduleME',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Apply the new theme
      home: const HomePage(),
    );
  }
}
