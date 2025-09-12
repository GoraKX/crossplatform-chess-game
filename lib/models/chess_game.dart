import 'package:flutter/foundation.dart';

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
    if (_gameStatus != GameStatus.ongoing) return;
    
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
    
    switch (piece.type) {
      case PieceType.pawn:
        _calculatePawnMoves(row, col, piece);
        break;
      case PieceType.rook:
        _calculateRookMoves(row, col, piece);
        break;
      case PieceType.knight:
        _calculateKnightMoves(row, col, piece);
        break;
      case PieceType.bishop:
        _calculateBishopMoves(row, col, piece);
        break;
      case PieceType.queen:
        _calculateQueenMoves(row, col, piece);
        break;
      case PieceType.king:
        _calculateKingMoves(row, col, piece);
        break;
    }
  }

  void _calculatePawnMoves(int row, int col, ChessPiece piece) {
    final direction = piece.color == PieceColor.white ? -1 : 1;
    final startRow = piece.color == PieceColor.white ? 6 : 1;
    
    // Move forward one square
    if (_isValidSquare(row + direction, col) && _board[row + direction][col] == null) {
      _validMoves[row + direction][col] = true;
      
      // Move forward two squares from starting position
      if (row == startRow && _board[row + 2 * direction][col] == null) {
        _validMoves[row + 2 * direction][col] = true;
      }
    }
    
    // Capture diagonally
    for (final dcol in [-1, 1]) {
      final newRow = row + direction;
      final newCol = col + dcol;
      if (_isValidSquare(newRow, newCol) && 
          _board[newRow][newCol] != null && 
          _board[newRow][newCol]!.color != piece.color) {
        _validMoves[newRow][newCol] = true;
      }
    }
  }

  void _calculateRookMoves(int row, int col, ChessPiece piece) {
    // Horizontal and vertical directions
    const directions = [(0, 1), (0, -1), (1, 0), (-1, 0)];
    
    for (final (drow, dcol) in directions) {
      for (int i = 1; i < 8; i++) {
        final newRow = row + drow * i;
        final newCol = col + dcol * i;
        
        if (!_isValidSquare(newRow, newCol)) break;
        
        if (_board[newRow][newCol] == null) {
          _validMoves[newRow][newCol] = true;
        } else {
          if (_board[newRow][newCol]!.color != piece.color) {
            _validMoves[newRow][newCol] = true;
          }
          break;
        }
      }
    }
  }

  void _calculateKnightMoves(int row, int col, ChessPiece piece) {
    const knightMoves = [
      (-2, -1), (-2, 1), (-1, -2), (-1, 2),
      (1, -2), (1, 2), (2, -1), (2, 1)
    ];
    
    for (final (drow, dcol) in knightMoves) {
      final newRow = row + drow;
      final newCol = col + dcol;
      
      if (_isValidSquare(newRow, newCol) && 
          (_board[newRow][newCol] == null || 
           _board[newRow][newCol]!.color != piece.color)) {
        _validMoves[newRow][newCol] = true;
      }
    }
  }

  void _calculateBishopMoves(int row, int col, ChessPiece piece) {
    // Diagonal directions
    const directions = [(1, 1), (1, -1), (-1, 1), (-1, -1)];
    
    for (final (drow, dcol) in directions) {
      for (int i = 1; i < 8; i++) {
        final newRow = row + drow * i;
        final newCol = col + dcol * i;
        
        if (!_isValidSquare(newRow, newCol)) break;
        
        if (_board[newRow][newCol] == null) {
          _validMoves[newRow][newCol] = true;
        } else {
          if (_board[newRow][newCol]!.color != piece.color) {
            _validMoves[newRow][newCol] = true;
          }
          break;
        }
      }
    }
  }

  void _calculateQueenMoves(int row, int col, ChessPiece piece) {
    _calculateRookMoves(row, col, piece);
    _calculateBishopMoves(row, col, piece);
  }

  void _calculateKingMoves(int row, int col, ChessPiece piece) {
    const directions = [
      (-1, -1), (-1, 0), (-1, 1),
      (0, -1),           (0, 1),
      (1, -1),  (1, 0),  (1, 1)
    ];
    
    for (final (drow, dcol) in directions) {
      final newRow = row + drow;
      final newCol = col + dcol;
      
      if (_isValidSquare(newRow, newCol) && 
          (_board[newRow][newCol] == null || 
           _board[newRow][newCol]!.color != piece.color)) {
        _validMoves[newRow][newCol] = true;
      }
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
    notifyListeners();
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
    
    _clearSelection();
    _updateGameStatus();
    notifyListeners();
  }
}
