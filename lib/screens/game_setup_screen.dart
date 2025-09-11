import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chess_game.dart';
import 'chess_board_screen.dart';

enum Difficulty { easy, medium, hard }

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isPlayerWhite = true;
  Difficulty _selectedDifficulty = Difficulty.medium;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Setup'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Player Name Input
                _buildSectionCard(
                  title: 'Enter Your Name',
                  icon: Icons.person,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Your name...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_circle),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Piece Color Selection
                _buildSectionCard(
                  title: 'Choose Your Pieces',
                  icon: Icons.palette,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildColorOption(
                          color: Colors.white,
                          label: 'White',
                          isSelected: _isPlayerWhite,
                          onTap: () => setState(() => _isPlayerWhite = true),
                          textColor: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildColorOption(
                          color: Colors.black87,
                          label: 'Black',
                          isSelected: !_isPlayerWhite,
                          onTap: () => setState(() => _isPlayerWhite = false),
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Difficulty Selection
                _buildSectionCard(
                  title: 'Select Difficulty',
                  icon: Icons.psychology,
                  child: Column(
                    children: [
                      _buildDifficultyOption(
                        difficulty: Difficulty.easy,
                        title: 'Easy',
                        description: 'Perfect for beginners',
                        icon: Icons.sentiment_satisfied,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildDifficultyOption(
                        difficulty: Difficulty.medium,
                        title: 'Medium',
                        description: 'Balanced challenge',
                        icon: Icons.sentiment_neutral,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildDifficultyOption(
                        difficulty: Difficulty.hard,
                        title: 'Hard',
                        description: 'For experienced players',
                        icon: Icons.sentiment_very_dissatisfied,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Start Game Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ElevatedButton(
                    onPressed: _nameController.text.trim().isNotEmpty
                        ? () => _startGame(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Start Game',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption({
    required Color color,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.circle,
              size: 40,
              color: color == Colors.white ? Colors.black26 : Colors.white70,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption({
    required Difficulty difficulty,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedDifficulty == difficulty;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = difficulty),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? color.withOpacity(0.8) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context) {
    final chessGame = Provider.of<ChessGame>(context, listen: false);
    
    // Set up the game with user preferences
    // Note: This assumes the ChessGame model has methods to set player preferences
    // You may need to update the ChessGame model to include these features
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const ChessBoardScreen(),
      ),
      (route) => false, // Remove all previous routes
    );
    
    // Show a welcome message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Welcome ${_nameController.text}! You are playing as ${_isPlayerWhite ? "White" : "Black"} on ${_selectedDifficulty.name} difficulty.',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
