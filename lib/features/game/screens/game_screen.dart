import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/socket_service.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _betController = TextEditingController(
    text: '10',
  );
  late AnimationController _shakeController;
  Timer? _simulationTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _betController.dispose();
    _shakeController.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    final socketService = ref.read(socketServiceProvider.notifier);
    socketService.connect('https://api.cryptopulse.game');
    socketService.joinRoom('main_room');

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      final state = ref.read(socketServiceProvider);
      if (state.gameStatus == GameStatus.playing) {
        final newMultiplier = state.multiplier + (_random.nextDouble() * 0.05);
        socketService.updateMultiplier(
          double.parse(newMultiplier.toStringAsFixed(2)),
        );

        if (_random.nextDouble() < 0.02) {
          _crashGame();
        }
      }
    });
  }

  void _crashGame() {
    _simulationTimer?.cancel();
    _shakeController.forward(from: 0);
    final socketService = ref.read(socketServiceProvider.notifier);
    socketService.updateGameStatus(GameStatus.crashed);

    Future.delayed(const Duration(seconds: 3), () {
      final socketService = ref.read(socketServiceProvider.notifier);
      socketService.resetGame();
    });
  }

  void _placeBet() {
    final amount = double.tryParse(_betController.text) ?? 0;
    if (amount > 0) {
      final socketService = ref.read(socketServiceProvider.notifier);
      socketService.placeBet(amount);
      socketService.updateGameStatus(GameStatus.playing);
    }
  }

  void _cashOut() {
    ref.read(socketServiceProvider.notifier).cashOut();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(socketServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildStatusBar(gameState),
            const Spacer(),
            _buildMultiplierDisplay(gameState),
            const Spacer(),
            _buildBettingPanel(gameState),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(SocketServiceState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isConnected
                      ? AppColors.primary
                      : AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                state.isConnected ? 'Connected' : 'Disconnected',
                style: GoogleFonts.robotoMono(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Room: ${state.roomId ?? "main"}',
              style: GoogleFonts.robotoMono(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierDisplay(SocketServiceState state) {
    Color multiplierColor;
    switch (state.gameStatus) {
      case GameStatus.playing:
        multiplierColor = AppColors.primary;
        break;
      case GameStatus.crashed:
        multiplierColor = AppColors.error;
        break;
      default:
        multiplierColor = AppColors.textSecondary;
    }

    Widget multiplierText = Text(
      '${state.multiplier.toStringAsFixed(2)}x',
      style: GoogleFonts.robotoMono(
        fontSize: 72,
        fontWeight: FontWeight.bold,
        color: multiplierColor,
      ),
    );

    if (state.gameStatus == GameStatus.crashed) {
      multiplierText = AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final offset = sin(_shakeController.value * pi * 8) * 10;
          return Transform.translate(offset: Offset(offset, 0), child: child);
        },
        child: multiplierText,
      );
    }

    return Column(
      children: [
        multiplierText
            .animate(target: state.gameStatus == GameStatus.playing ? 1 : 0)
            .shimmer(
              duration: const Duration(seconds: 2),
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
        const SizedBox(height: 16),
        Text(
          state.gameStatus == GameStatus.waiting
              ? 'PLACE YOUR BET'
              : state.gameStatus == GameStatus.playing
              ? 'CASH OUT NOW!'
              : 'CRASHED!',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: multiplierColor,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildBettingPanel(SocketServiceState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Column(
        children: [
          TextField(
            controller: _betController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.robotoMono(
              color: AppColors.textPrimary,
              fontSize: 24,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.monetization_on_outlined,
                color: AppColors.warning,
              ),
              prefixStyle: GoogleFonts.robotoMono(
                color: AppColors.warning,
                fontSize: 24,
              ),
              hintText: '0.00',
              hintStyle: GoogleFonts.robotoMono(color: AppColors.textTertiary),
              suffixText: 'USDT',
              suffixStyle: GoogleFonts.robotoMono(
                color: AppColors.textSecondary,
              ),
            ),
            enabled: state.gameStatus == GameStatus.waiting,
          ),
          const SizedBox(height: 20),
          if (state.gameStatus == GameStatus.waiting)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  _startSimulation();
                  _placeBet();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                ),
                child: Text(
                  'JOIN PULSE',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          else if (state.gameStatus == GameStatus.playing)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _cashOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.textPrimary,
                ),
                child: Text(
                  'CASH OUT',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  foregroundColor: AppColors.textTertiary,
                ),
                child: Text(
                  'WAITING...',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          if (state.currentBet != null) ...[
            const SizedBox(height: 12),
            Text(
              'Current bet: ${state.currentBet!.toStringAsFixed(2)} USDT',
              style: GoogleFonts.robotoMono(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
