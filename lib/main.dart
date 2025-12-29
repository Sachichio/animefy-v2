import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'screens/home_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_manage_users_screen.dart';
import 'screens/admin/admin_manage_comments_screen.dart';
import 'screens/admin/admin_profile_screen.dart';
import 'screens/user/user_dashboard_screen.dart';
import 'screens/user/user_manage_comments_screen.dart';
import 'screens/user/user_profile_screen.dart';
import 'screens/menu/anime_popular_screen.dart';
import 'screens/menu/anime_ongoing_screen.dart';
import 'screens/menu/anime_completed_screen.dart';
import 'screens/menu/anime_upcoming_screen.dart';
import 'screens/menu/anime_genre_screen.dart';
import 'screens/menu/anime_studio_screen.dart';
import 'screens/menu/anime_season_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animefy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,

      initialRoute: '/home',

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => HomeScreen(toggleTheme: toggleTheme),

        // Route Admin
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/admin/users': (context) => const AdminManageUsersScreen(),
        '/admin/comments': (context) => const AdminManageCommentsScreen(),
        '/admin/profile': (context) => const AdminProfileScreen(),
        // Route User
        '/user/dashboard': (context) => const UserDashboardScreen(),
        '/user/comments': (context) => const UserManageCommentsScreen(),
        '/user/profile': (context) => const UserProfileScreen(),
        // Menu Lainnya
        '/anime/popular': (context) => const AnimePopularScreen(),
        '/anime/ongoing': (context) => const AnimeOngoingScreen(),
        '/anime/completed': (context) => const AnimeCompletedScreen(),
        '/anime/upcoming': (context) => const AnimeUpcomingScreen(),
        '/anime/genre': (context) => const AnimeGenreScreen(),
        '/anime/studio': (context) => const AnimeStudioScreen(),
        '/anime/season': (context) => const AnimeSeasonScreen(),
        '/anime/detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return DetailScreen(
            anime: args?['anime'],
            userId: args?['userId'],
          );
        },
      },
    );
  }
}