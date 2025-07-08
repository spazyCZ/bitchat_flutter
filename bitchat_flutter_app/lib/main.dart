import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/ui/screens/home_screen.dart';

void main() {
  runApp(const BitchatApp());
}

class BitchatApp extends StatelessWidget {
  const BitchatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bitchat*',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.green,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'monospace', color: Colors.green),
          bodyMedium: TextStyle(fontFamily: 'monospace', color: Colors.green),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}