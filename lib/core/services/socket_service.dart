import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

enum GameStatus { waiting, playing, crashed }

class SocketServiceState {
  final bool isConnected;
  final double multiplier;
  final GameStatus gameStatus;
  final String? roomId;
  final double? currentBet;
  final bool? hasCashedOut;

  const SocketServiceState({
    this.isConnected = false,
    this.multiplier = 1.00,
    this.gameStatus = GameStatus.waiting,
    this.roomId,
    this.currentBet,
    this.hasCashedOut,
  });

  SocketServiceState copyWith({
    bool? isConnected,
    double? multiplier,
    GameStatus? gameStatus,
    String? roomId,
    double? currentBet,
    bool? hasCashedOut,
  }) {
    return SocketServiceState(
      isConnected: isConnected ?? this.isConnected,
      multiplier: multiplier ?? this.multiplier,
      gameStatus: gameStatus ?? this.gameStatus,
      roomId: roomId ?? this.roomId,
      currentBet: currentBet ?? this.currentBet,
      hasCashedOut: hasCashedOut ?? this.hasCashedOut,
    );
  }
}

class SocketService extends StateNotifier<SocketServiceState> {
  io.Socket? _socket;

  SocketService() : super(const SocketServiceState());

  void connect(String serverUrl) {
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      state = state.copyWith(isConnected: true);
    });

    _socket!.onDisconnect((_) {
      state = state.copyWith(isConnected: false);
    });

    _socket!.on('game_state', (data) {
      _handleGameState(data);
    });

    _socket!.on('multiplier_update', (data) {
      _handleMultiplierUpdate(data);
    });

    _socket!.on('game_crashed', (data) {
      _handleGameCrashed(data);
    });

    _socket!.connect();
  }

  void _handleGameState(Map<String, dynamic> data) {
    final statusStr = data['status'] as String?;
    GameStatus status;
    switch (statusStr) {
      case 'playing':
        status = GameStatus.playing;
        break;
      case 'crashed':
        status = GameStatus.crashed;
        break;
      default:
        status = GameStatus.waiting;
    }

    state = state.copyWith(
      gameStatus: status,
      multiplier: (data['multiplier'] as num?)?.toDouble() ?? 1.00,
    );
  }

  void _handleMultiplierUpdate(Map<String, dynamic> data) {
    final multiplier = (data['multiplier'] as num?)?.toDouble() ?? 1.00;
    state = state.copyWith(
      multiplier: multiplier,
      gameStatus: GameStatus.playing,
    );
  }

  void _handleGameCrashed(Map<String, dynamic> data) {
    final crashPoint = (data['crashPoint'] as num?)?.toDouble() ?? 0.0;
    state = state.copyWith(
      multiplier: crashPoint,
      gameStatus: GameStatus.crashed,
    );
  }

  void joinRoom(String roomId) {
    _socket?.emit('join_room', roomId);
    state = state.copyWith(roomId: roomId);
  }

  void placeBet(double amount) {
    _socket?.emit('place_bet', {'amount': amount, 'roomId': state.roomId});
    state = state.copyWith(currentBet: amount, hasCashedOut: false);
  }

  void cashOut() {
    _socket?.emit('cash_out', {'roomId': state.roomId});
    state = state.copyWith(hasCashedOut: true);
  }

  void updateMultiplier(double multiplier) {
    state = state.copyWith(multiplier: multiplier);
  }

  void updateGameStatus(GameStatus status) {
    state = state.copyWith(gameStatus: status);
  }

  void resetGame() {
    state = state.copyWith(
      gameStatus: GameStatus.waiting,
      multiplier: 1.00,
      hasCashedOut: false,
      currentBet: null,
    );
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    state = const SocketServiceState();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

final socketServiceProvider =
    StateNotifierProvider<SocketService, SocketServiceState>((ref) {
  return SocketService();
});
