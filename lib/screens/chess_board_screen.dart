import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chess_game.dart';
import '../models/game_settings.dart';

class ChessBoardScreen extends StatefulWidget {
  final String? welcomeMessage;

  const ChessBoardScreen({super.key, this.welcomeMessage});

  @override
  State<ChessBoardScreen> createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  bool _is3DView = false;
  bool _hasShownWelcome = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasShownWelcome && widget.welcomeMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.welcomeMessage!),
            duration: const Duration(seconds: 3),
          ),
        );
      });
      _hasShownWelcome = true;
    }
  }

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
          IconButton(
            tooltip: _is3DView ? 'Switch to top-down view' : 'Switch to 3D view',
            icon: Icon(_is3DView ? Icons.grid_view : Icons.view_in_ar),
            onPressed: () => setState(() => _is3DView = !_is3DView),
          ),
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
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'undo',
                  child: Row(
                    children: [
                      Icon(Icons.undo),
                      SizedBox(width: 8),
                      Text('Undo Move'),
                    ],
                  ),
                ),
                PopupMenuItem(
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
          Consumer<ChessGame>(
            builder: (context, game, child) {
              if (!game.isAiThinking) {
                return const SizedBox(height: 4);
              }
              return LinearProgressIndicator(
                minHeight: 4,
                color: Theme.of(context).colorScheme.secondary,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              );
            },
          ),
          // Game Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Consumer<ChessGame>(
              builder: (context, game, child) {
                final playerColor = game.currentPlayer == PieceColor.white
                    ? Colors.white
                    : Colors.black;
                final textColor = game.currentPlayer == PieceColor.white
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${game.currentPlayer.name.toUpperCase()} TO MOVE',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            if (game.isSinglePlayer && game.isAiThinking)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'AI is calculating...',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                              ),
                          ],
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
                  final is3D = _is3DView;
                  return AspectRatio(
                    aspectRatio: 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.all(16),
                      transform: is3D
                          ? (Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateX(math.pi / 9))
                          : Matrix4.identity(),
                      transformAlignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: is3D
                            ? null
                            : Theme.of(context).colorScheme.surface,
                        gradient: is3D
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF4E342E),
                                  Color(0xFF3E2723),
                                ],
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(is3D ? 0.45 : 0.3),
                            blurRadius: is3D ? 20 : 10,
                            offset: is3D ? const Offset(0, 18) : const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            AbsorbPointer(
                              absorbing: game.isSinglePlayer && game.isAiThinking,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 8,
                                ),
                                itemCount: 64,
                                itemBuilder: (context, index) {
                                  final row = index ~/ 8;
                                  final col = index % 8;
                                  final piece = game.board[row][col];
                                  final isSelected = game.selectedRow == row &&
                                      game.selectedCol == col;
                                  final isValidMove = game.validMoves[row][col];

                                  final bool isLightSquare = (row + col) % 2 == 0;
                                  Color squareColor;
                                  if (isSelected) {
                                    squareColor = Colors.yellow.withOpacity(0.8);
                                  } else if (isValidMove) {
                                    squareColor = Colors.green.withOpacity(0.6);
                                  } else if (is3D) {
                                    squareColor = isLightSquare
                                        ? const Color(0xFFE2C49A)
                                        : const Color(0xFF8C5E3C);
                                  } else {
                                    squareColor = isLightSquare
                                        ? const Color(0xFFF0D9B5)
                                        : const Color(0xFFB58863);
                                  }

                                  final coordinateColor = isLightSquare
                                      ? Colors.black
                                          .withOpacity(is3D ? 0.55 : 0.6)
                                      : Colors.white
                                          .withOpacity(is3D ? 0.85 : 0.7);

                                  return GestureDetector(
                                    onTap: () => game.selectSquare(row, col),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: squareColor,
                                        border: Border.all(
                                          color: Colors.black.withOpacity(0.08),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          if (col == 0)
                                            Positioned(
                                              top: 2,
                                              left: 4,
                                              child: Text(
                                                '${8 - row}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: coordinateColor,
                                                ),
                                              ),
                                            ),
                                          if (row == 7)
                                            Positioned(
                                              bottom: 2,
                                              right: 4,
                                              child: Text(
                                                String.fromCharCode(97 + col),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: coordinateColor,
                                                ),
                                              ),
                                            ),
                                          if (piece != null)
                                            Center(
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                child: Text(
                                                  piece.symbol,
                                                  style: TextStyle(
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.08,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black
                                                            .withOpacity(0.45),
                                                        blurRadius: 2,
                                                        offset: const Offset(1, 1),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (isValidMove && piece == null)
                                            Center(
                                              child: Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.75),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
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
                            if (game.isSinglePlayer && game.isAiThinking)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.08),
                                  ),
                                ),
                              ),
                          ],
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPlayersCard(context, game),
                    const SizedBox(height: 12),
                    _buildStatsCard(context, game),
                    const SizedBox(height: 8),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildPlayersCard(BuildContext context, ChessGame game) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildPlayerBadge(context, game, PieceColor.white),
                _buildModeChip(context, game),
                _buildPlayerBadge(context, game, PieceColor.black),
              ],
            ),
            if (game.isSinglePlayer && game.isAiThinking)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI thinking...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerBadge(
    BuildContext context,
    ChessGame game,
    PieceColor color,
  ) {
    final isCurrentTurn = game.currentPlayer == color;
    final name = game.playerNameForColor(color);
    final baseColor = color == PieceColor.white
        ? Colors.white
        : const Color(0xFF2F2F2F);
    final textColor = color == PieceColor.white
        ? Colors.black87
        : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentTurn
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                color == PieceColor.white ? Icons.circle_outlined : Icons.circle,
                color: textColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                color == PieceColor.white ? 'White' : 'Black',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name.isNotEmpty ? name : (color == PieceColor.white ? 'Player 1' : 'Player 2'),
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(BuildContext context, ChessGame game) {
    if (game.isSinglePlayer) {
      return Chip(
        avatar: const Icon(Icons.smart_toy, size: 18),
        label: Text('${game.difficulty.label} AI'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Chip(
      avatar: const Icon(Icons.people, size: 18),
      label: const Text('Local Match'),
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onTertiaryContainer,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, ChessGame game) {
    return Card(
      elevation: 2,
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
    );
  }
}
