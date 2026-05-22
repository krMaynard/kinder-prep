import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/image_review_screen.dart';
import 'screens/story_review_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const StoryGeneratorApp(),
    ),
  );
}

class StoryGeneratorApp extends StatelessWidget {
  const StoryGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B7FA6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/story': (_) => const StoryReviewScreen(),
        '/images': (_) => const ImageReviewScreen(),
      },
    );
  }
}
