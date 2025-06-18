import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'screens/home_page.dart';

class ChatSupportApp extends StatelessWidget {
  const ChatSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Support',
      theme: ThemeData(
        primaryColor: AppColors.primaryApp,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryApp,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
