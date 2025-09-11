import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chess_game.dart';

class ChessBoardScreen extends StatelessWidget {
  const ChessBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Chess Game',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        actions: [
          Consumer<ChessGame>(
            builder: (context, game, child) => PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'reset':
                    game.resetGame();
                    break;
                  case 'undo':
                    game.undoMove();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'undo',
                  child: Row(
                    children: [
                      Icon(Icons.undo),
                      SizedBox(width: 8),
                      Text('Undo Move'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('New Game'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Game Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Consumer<ChessGame>(
              builder: (context, game, child) {
                Color playerColor = game.currentPlayer == PieceColor.white 
                    ? Colors.white 
                    : Colors.black;
                Color textColor = game.currentPlayer == PieceColor.white 
                    ? Colors.black 
                    : Colors.white;
                
                return Card(
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: playerColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${game.currentPlayer.name.toUpperCase()} TO MOVE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (game.gameStatus != GameStatus.ongoing)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              game.gameStatus.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Chess Board
          Expanded(
            child: Center(
              child: Consumer<ChessGame>(
                builder: (context, game, child) {
                  return AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                          ),
                          itemCount: 64,
                          itemBuilder: (context, index) {
                            final row = index ~/ 8;
                            final col = index % 8;
                            final piece = game.board[row][col];
                            final isSelected = game.selectedRow == row && game.selectedCol == col;
                            final isValidMove = game.validMoves[row][col];
                            
                            // Determine square color
                            final bool isLightSquare = (row + col) % 2 == 0;
                            Color squareColor;
                            
                            if (isSelected) {
                              squareColor = Colors.yellow.withOpacity(0.8);
                            } else if (isValidMove) {
                              squareColor = Colors.green.withOpacity(0.6);
                            } else if (isLightSquare) {
                              squareColor = const Color(0xFFF0D9B5); // Light brown
                            } else {
                              squareColor = const Color(0xFFB58863); // Dark brown
                            }
                            
                            return GestureDetector(
                              onTap: () => game.selectSquare(row, col),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: squareColor,
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.1),
                                    width: 0.5,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Square coordinate labels
                                    if (col == 0)
                                      Positioned(
                                        top: 2,
                                        left: 2,
                                        child: Text(
                                          '${8 - row}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isLightSquare 
                                                ? Colors.black54 
                                                : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    if (row == 7)
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: Text(
                                          String.fromCharCode(97 + col), // a-h
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isLightSquare 
                                                ? Colors.black54 
                                                : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    
                                    // Chess piece
                                    if (piece != null)
                                      Center(
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          child: Text(
                                            piece.symbol,
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width * 0.08,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withOpacity(0.5),
                                                  blurRadius: 2,
                                                  offset: const Offset(1, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    
                                    // Valid move indicator
                                    if (isValidMove && piece == null)
                                      Center(
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.8),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    
                                    // Capture indicator
                                    if (isValidMove && piece != null)
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Game Controls and Information
          Container(
            padding: const EdgeInsets.all(16),
            child: Consumer<ChessGame>(
              builder: (context, game, child) {
                return Column(
                  children: [
                    // Move Counter
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.history),
                                const SizedBox(height: 4),
                                Text(
                                  'Moves: ${game.moveHistory.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  game.gameStatus == GameStatus.ongoing 
                                      ? Icons.play_circle 
                                      : Icons.stop_circle,
                                  color: game.gameStatus == GameStatus.ongoing 
                                      ? Colors.green 
                                      : Colors.red,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  game.gameStatus.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: game.moveHistory.isNotEmpty 
                                ? () => game.undoMove() 
                                : null,
                            icon: const Icon(Icons.undo),
                            label: const Text('Undo'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => game.resetGame(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('New Game'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
