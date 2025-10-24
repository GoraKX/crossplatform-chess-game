import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'game_settings.dart';

enum PieceType { pawn, rook, knight, bishop, queen, king }
enum PieceColor { white, black }
enum GameStatus { ongoing, check, checkmate, stalemate, draw }

class ChessPiece {
  final PieceType type;
  final PieceColor color;
  bool hasMoved;

  ChessPiece({
    required this.type,
    required this.color,
    this.hasMoved = false,
  });

  String get symbol {
    const symbols = {
      PieceType.pawn: {'white': '♙', 'black': '♟'},
      PieceType.rook: {'white': '♖', 'black': '♜'},
      PieceType.knight: {'white': '♘', 'black': '♞'},
      PieceType.bishop: {'white': '♗', 'black': '♝'},
      PieceType.queen: {'white': '♕', 'black': '♛'},
      PieceType.king: {'white': '♔', 'black': '♚'},
    };
    return symbols[type]![color.name] ?? '';
  }

  ChessPiece copy() {
    return ChessPiece(
      type: type,
      color: color,
      hasMoved: hasMoved,
    );
  }
}

class Move {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final ChessPiece? capturedPiece;
  final bool isEnPassant;
  final bool isCastle;
  final PieceType? promotionType;

  Move({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    this.capturedPiece,
    this.isEnPassant = false,
    this.isCastle = false,
    this.promotionType,
  });
}

class ChessGame extends ChangeNotifier {
  late List<List<ChessPiece?>> _board;
  PieceColor _currentPlayer = PieceColor.white;
  GameStatus _gameStatus = GameStatus.ongoing;
  List<Move> _moveHistory = [];
  int? _selectedRow;
  int? _selectedCol;
  List<List<bool>> _validMoves = List.generate(8, (index) => List.filled(8, false));
  bool _vsAI = true;
  PieceColor _humanColor = PieceColor.white;
  PieceColor _aiColor = PieceColor.black;
  Difficulty _difficulty = Difficulty.medium;
  String _playerName = '';
  String _opponentName = 'AI';
  bool _isAiThinking = false;
  final Random _random = Random();

  ChessGame() {
    _initializeBoard();
  }

  // Getters
  List<List<ChessPiece?>> get board => _board;
  PieceColor get currentPlayer => _currentPlayer;
  GameStatus get gameStatus => _gameStatus;
  List<Move> get moveHistory => _moveHistory;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  List<List<bool>> get validMoves => _validMoves;
  bool get isSinglePlayer => _vsAI;
  PieceColor get humanColor => _humanColor;
  PieceColor get aiColor => _aiColor;
  Difficulty get difficulty => _difficulty;
  String get playerName => _playerName;
  String get opponentName => _opponentName;
  bool get isAiThinking => _isAiThinking;

  String playerNameForColor(PieceColor color) {
    return color == _humanColor ? _playerName : _opponentName;
  }

  void configureGame({
    required bool vsAI,
    required PieceColor humanColor,
    required Difficulty difficulty,
    required String playerName,
    String? opponentName,
  }) {
    _vsAI = vsAI;
    _humanColor = humanColor;
    _aiColor = humanColor == PieceColor.white ? PieceColor.black : PieceColor.white;
    _difficulty = difficulty;
    _playerName = playerName;
    _opponentName = opponentName ?? (vsAI ? 'AI' : 'Player 2');
    resetGame();
  }

  void _initializeBoard() {
    _board = List.generate(8, (index) => List.filled(8, null));
    
    // Initialize pawns
    for (int i = 0; i < 8; i++) {
      _board[1][i] = ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      _board[6][i] = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    }
    
    // Initialize other pieces
    const pieceOrder = [
      PieceType.rook, PieceType.knight, PieceType.bishop, PieceType.queen,
      PieceType.king, PieceType.bishop, PieceType.knight, PieceType.rook
    ];
    
    for (int i = 0; i < 8; i++) {
      _board[0][i] = ChessPiece(type: pieceOrder[i], color: PieceColor.black);
      _board[7][i] = ChessPiece(type: pieceOrder[i], color: PieceColor.white);
    }
  }

  void selectSquare(int row, int col) {
    if (_gameStatus != GameStatus.ongoing || _isAiThinking) return;

    if (_vsAI && _currentPlayer == _aiColor) return;

    // If no piece is selected or clicking on a different piece of the same color
    if (_selectedRow == null || _selectedCol == null ||
        (_board[row][col] != null && _board[row][col]!.color == _currentPlayer)) {
      // Only select if the piece belongs to the current player
      if (_board[row][col] != null && _board[row][col]!.color == _currentPlayer) {
        _selectedRow = row;
        _selectedCol = col;
        _calculateValidMoves(row, col);
      } else {
        _clearSelection();
      }
      notifyListeners();
    } else {
      // Try to move the selected piece
      if (_validMoves[row][col]) {
        _makeMove(_selectedRow!, _selectedCol!, row, col);
      } else {
        _clearSelection();
        notifyListeners();
      }
    }
  }

  void _clearSelection() {
    _selectedRow = null;
    _selectedCol = null;
    _validMoves = List.generate(8, (index) => List.filled(8, false));
  }

  void _calculateValidMoves(int row, int col) {
    _validMoves = List.generate(8, (index) => List.filled(8, false));

    final piece = _board[row][col];
    if (piece == null) return;

    final destinations = _getDestinationsForPiece(_board, row, col);
    for (final (newRow, newCol) in destinations) {
      _validMoves[newRow][newCol] = true;
    }
  }

  bool _isValidSquare(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  void _makeMove(int fromRow, int fromCol, int toRow, int toCol) {
    final piece = _board[fromRow][fromCol];
    final capturedPiece = _board[toRow][toCol];
    
    if (piece == null) return;
    
    // Create move record
    final move = Move(
      fromRow: fromRow,
      fromCol: fromCol,
      toRow: toRow,
      toCol: toCol,
      capturedPiece: capturedPiece,
    );
    
    _moveHistory.add(move);
    
    // Make the move
    _board[toRow][toCol] = piece;
    _board[fromRow][fromCol] = null;
    piece.hasMoved = true;
    
    // Switch players
    _currentPlayer = _currentPlayer == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;

    // Check for game ending conditions
    _updateGameStatus();

    // Clear selection and notify listeners
    _clearSelection();
    notifyListeners();

    _scheduleAiTurnIfNeeded();
  }

  void _updateGameStatus() {
    // Basic implementation - can be expanded with proper check/checkmate detection
    _gameStatus = GameStatus.ongoing;
  }

  void resetGame() {
    _initializeBoard();
    _currentPlayer = PieceColor.white;
    _gameStatus = GameStatus.ongoing;
    _moveHistory.clear();
    _clearSelection();
    _isAiThinking = false;
    notifyListeners();

    _scheduleAiTurnIfNeeded();
  }

  void undoMove() {
    if (_moveHistory.isEmpty) return;

    final lastMove = _moveHistory.removeLast();

    // Restore the piece to its original position
    final piece = _board[lastMove.toRow][lastMove.toCol];
    _board[lastMove.fromRow][lastMove.fromCol] = piece;
    _board[lastMove.toRow][lastMove.toCol] = lastMove.capturedPiece;

    // Restore hasMoved flag (simplified - doesn't track original state)
    if (piece != null && _moveHistory.where((m) =>
        m.fromRow == lastMove.fromRow && m.fromCol == lastMove.fromCol).isEmpty) {
      piece.hasMoved = false;
    }

    // Switch players back
    _currentPlayer = _currentPlayer == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;

    _isAiThinking = false;
    _clearSelection();
    _updateGameStatus();
    notifyListeners();

    _scheduleAiTurnIfNeeded();
  }

  void _scheduleAiTurnIfNeeded() {
    if (!_vsAI || _gameStatus != GameStatus.ongoing ||
        _currentPlayer != _aiColor || _isAiThinking) {
      return;
    }

    _isAiThinking = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (_gameStatus != GameStatus.ongoing) {
        _isAiThinking = false;
        notifyListeners();
        return;
      }

      final move = _chooseAiMove();
      if (move != null) {
        _makeMove(move.fromRow, move.fromCol, move.toRow, move.toCol);
      }

      _isAiThinking = false;
      notifyListeners();
    });
  }

  Move? _chooseAiMove() {
    final possibleMoves = _getAllMovesForColor(_board, _aiColor);
    if (possibleMoves.isEmpty) return null;

    switch (_difficulty) {
      case Difficulty.easy:
        return possibleMoves[_random.nextInt(possibleMoves.length)];
      case Difficulty.medium:
        final capturingMoves =
            possibleMoves.where((move) => move.capturedPiece != null).toList();
        if (capturingMoves.isNotEmpty) {
          final bestValue = capturingMoves
              .map((move) => _pieceValue(move.capturedPiece!.type))
              .reduce(max);
          final bestCaptures = capturingMoves
              .where((move) => _pieceValue(move.capturedPiece!.type) == bestValue)
              .toList();
          return bestCaptures[_random.nextInt(bestCaptures.length)];
        }
        return possibleMoves[_random.nextInt(possibleMoves.length)];
      case Difficulty.hard:
        final move = _chooseBestMoveWithMinimax(possibleMoves);
        return move ?? possibleMoves[_random.nextInt(possibleMoves.length)];
    }
  }

  Move? _chooseBestMoveWithMinimax(List<Move> moves) {
    Move? bestMove;
    int bestScore = -1000000;

    for (final move in moves) {
      final boardCopy = _cloneBoard(_board);
      _applyMoveOnBoard(boardCopy, move);
      final score = _minimax(boardCopy, 2, false, -1000000, 1000000);
      if (bestMove == null || score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove ?? (moves.isNotEmpty
        ? moves[_random.nextInt(moves.length)]
        : null);
  }

  int _minimax(
    List<List<ChessPiece?>> board,
    int depth,
    bool maximizingPlayer,
    int alpha,
    int beta,
  ) {
    if (depth == 0) {
      return _evaluateBoard(board);
    }

    final currentColor = maximizingPlayer ? _aiColor : _humanColor;
    final moves = _getAllMovesForColor(board, currentColor);
    if (moves.isEmpty) {
      return _evaluateBoard(board);
    }

    if (maximizingPlayer) {
      var value = -1000000;
      for (final move in moves) {
        final newBoard = _cloneBoard(board);
        _applyMoveOnBoard(newBoard, move);
        value = max(value, _minimax(newBoard, depth - 1, false, alpha, beta));
        alpha = max(alpha, value);
        if (beta <= alpha) break;
      }
      return value;
    } else {
      var value = 1000000;
      for (final move in moves) {
        final newBoard = _cloneBoard(board);
        _applyMoveOnBoard(newBoard, move);
        value = min(value, _minimax(newBoard, depth - 1, true, alpha, beta));
        beta = min(beta, value);
        if (beta <= alpha) break;
      }
      return value;
    }
  }

  int _evaluateBoard(List<List<ChessPiece?>> board) {
    int score = 0;
    for (final row in board) {
      for (final piece in row) {
        if (piece == null) continue;
        final value = _pieceValue(piece.type);
        if (piece.color == _aiColor) {
          score += value;
        } else {
          score -= value;
        }
      }
    }
    return score;
  }

  int _pieceValue(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return 100;
      case PieceType.knight:
        return 320;
      case PieceType.bishop:
        return 330;
      case PieceType.rook:
        return 500;
      case PieceType.queen:
        return 900;
      case PieceType.king:
        return 20000;
    }
  }

  List<Move> _getAllMovesForColor(
    List<List<ChessPiece?>> board,
    PieceColor color,
  ) {
    final moves = <Move>[];

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece == null || piece.color != color) continue;

        final destinations = _getDestinationsForPiece(board, row, col);
        for (final (newRow, newCol) in destinations) {
          moves.add(
            Move(
              fromRow: row,
              fromCol: col,
              toRow: newRow,
              toCol: newCol,
              capturedPiece: board[newRow][newCol]?.copy(),
            ),
          );
        }
      }
    }

    return moves;
  }

  List<List<ChessPiece?>> _cloneBoard(List<List<ChessPiece?>> board) {
    return List.generate(
      8,
      (row) => List.generate(8, (col) => board[row][col]?.copy()),
    );
  }

  void _applyMoveOnBoard(List<List<ChessPiece?>> board, Move move) {
    final piece = board[move.fromRow][move.fromCol];
    if (piece == null) return;

    board[move.toRow][move.toCol] = piece;
    board[move.fromRow][move.fromCol] = null;
    piece.hasMoved = true;
  }

  List<(int, int)> _getDestinationsForPiece(
    List<List<ChessPiece?>> board,
    int row,
    int col,
  ) {
    final piece = board[row][col];
    if (piece == null) return const <(int, int)>[];

    switch (piece.type) {
      case PieceType.pawn:
        return _getPawnMoves(board, row, col, piece);
      case PieceType.rook:
        return _collectLinearMoves(
          board,
          row,
          col,
          piece,
          const [(0, 1), (0, -1), (1, 0), (-1, 0)],
        );
      case PieceType.knight:
        return _getKnightMoves(board, row, col, piece);
      case PieceType.bishop:
        return _collectLinearMoves(
          board,
          row,
          col,
          piece,
          const [(1, 1), (1, -1), (-1, 1), (-1, -1)],
        );
      case PieceType.queen:
        final rookMoves = _collectLinearMoves(
          board,
          row,
          col,
          piece,
          const [(0, 1), (0, -1), (1, 0), (-1, 0)],
        );
        final bishopMoves = _collectLinearMoves(
          board,
          row,
          col,
          piece,
          const [(1, 1), (1, -1), (-1, 1), (-1, -1)],
        );
        return [...rookMoves, ...bishopMoves];
      case PieceType.king:
        return _getKingMoves(board, row, col, piece);
    }
  }

  List<(int, int)> _getPawnMoves(
    List<List<ChessPiece?>> board,
    int row,
    int col,
    ChessPiece piece,
  ) {
    final moves = <(int, int)>[];
    final direction = piece.color == PieceColor.white ? -1 : 1;
    final startRow = piece.color == PieceColor.white ? 6 : 1;
    final oneStepRow = row + direction;

    if (_isValidSquare(oneStepRow, col) && board[oneStepRow][col] == null) {
      moves.add((oneStepRow, col));

      final twoStepRow = row + 2 * direction;
      if (row == startRow && _isValidSquare(twoStepRow, col) &&
          board[twoStepRow][col] == null) {
        moves.add((twoStepRow, col));
      }
    }

    for (final dcol in [-1, 1]) {
      final captureRow = row + direction;
      final captureCol = col + dcol;
      if (_isValidSquare(captureRow, captureCol)) {
        final target = board[captureRow][captureCol];
        if (target != null && target.color != piece.color) {
          moves.add((captureRow, captureCol));
        }
      }
    }

    return moves;
  }

  List<(int, int)> _collectLinearMoves(
    List<List<ChessPiece?>> board,
    int row,
    int col,
    ChessPiece piece,
    List<(int, int)> directions,
  ) {
    final moves = <(int, int)>[];

    for (final (drow, dcol) in directions) {
      for (int i = 1; i < 8; i++) {
        final newRow = row + drow * i;
        final newCol = col + dcol * i;

        if (!_isValidSquare(newRow, newCol)) break;

        final target = board[newRow][newCol];
        if (target == null) {
          moves.add((newRow, newCol));
        } else {
          if (target.color != piece.color) {
            moves.add((newRow, newCol));
          }
          break;
        }
      }
    }

    return moves;
  }

  List<(int, int)> _getKnightMoves(
    List<List<ChessPiece?>> board,
    int row,
    int col,
    ChessPiece piece,
  ) {
    const knightMoves = [
      (-2, -1),
      (-2, 1),
      (-1, -2),
      (-1, 2),
      (1, -2),
      (1, 2),
      (2, -1),
      (2, 1),
    ];

    final moves = <(int, int)>[];

    for (final (drow, dcol) in knightMoves) {
      final newRow = row + drow;
      final newCol = col + dcol;
      if (_isValidSquare(newRow, newCol)) {
        final target = board[newRow][newCol];
        if (target == null || target.color != piece.color) {
          moves.add((newRow, newCol));
        }
      }
    }

    return moves;
  }

  List<(int, int)> _getKingMoves(
    List<List<ChessPiece?>> board,
    int row,
    int col,
    ChessPiece piece,
  ) {
    const directions = [
      (-1, -1),
      (-1, 0),
      (-1, 1),
      (0, -1),
      (0, 1),
      (1, -1),
      (1, 0),
      (1, 1),
    ];

    final moves = <(int, int)>[];

    for (final (drow, dcol) in directions) {
      final newRow = row + drow;
      final newCol = col + dcol;
      if (_isValidSquare(newRow, newCol)) {
        final target = board[newRow][newCol];
        if (target == null || target.color != piece.color) {
          moves.add((newRow, newCol));
        }
      }
    }

    return moves;
  }
}
