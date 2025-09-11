import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/chess_game.dart';
import 'screens/chess_board_screen.dart';

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChessGame(),
      child: MaterialApp(
        title: 'Cross-Platform Chess Game',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B4513),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF8B4513),
            foregroundColor: Colors.white,
            elevation: 4,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B4513),
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF654321),
            foregroundColor: Colors.white,
            elevation: 4,
          ),
          useMaterial3: true,
        ),
        home: const ChessBoardScreen(),
      ),
    );
  }
}
