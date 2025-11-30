import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  final lightTheme = ThemeData.light().copyWith(
    primaryColor: Colors.indigo,
    colorScheme: ColorScheme.light(primary: Colors.indigo),
    scaffoldBackgroundColor: Colors.white,
  );

  final darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.deepPurple,
    colorScheme: ColorScheme.dark(primary: Colors.deepPurple),
    scaffoldBackgroundColor: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animefy',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: HomeScreen(
          key: ValueKey(_themeMode), // Trigger rebuild saat tema berubah
          toggleTheme: toggleTheme,
        ),
      ),
    );
  }
}
