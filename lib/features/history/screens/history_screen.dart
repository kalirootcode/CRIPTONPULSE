import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = _generateMockHistory();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Game History',
                style: GoogleFonts.montserrat(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Past ${history.length} rounds',
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _buildStatsRow(history),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryItem(history[index], index == 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_HistoryItem> _generateMockHistory() {
    return [
      _HistoryItem(
        multiplier: 2.34,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      _HistoryItem(
        multiplier: 1.12,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      _HistoryItem(
        multiplier: 5.67,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      _HistoryItem(
        multiplier: 1.01,
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      _HistoryItem(
        multiplier: 3.21,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      _HistoryItem(
        multiplier: 1.55,
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      _HistoryItem(
        multiplier: 8.90,
        timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
      ),
      _HistoryItem(
        multiplier: 1.00,
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      _HistoryItem(
        multiplier: 2.10,
        timestamp: DateTime.now().subtract(const Duration(minutes: 28)),
      ),
      _HistoryItem(
        multiplier: 4.50,
        timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
      ),
    ];
  }

  Widget _buildStatsRow(List<_HistoryItem> history) {
    final avgMultiplier =
        history.map((e) => e.multiplier).reduce((a, b) => a + b) /
            history.length;
    final maxMultiplier =
        history.map((e) => e.multiplier).reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        _StatCard(
          label: 'Avg',
          value: '${avgMultiplier.toStringAsFixed(2)}x',
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Max',
          value: '${maxMultiplier.toStringAsFixed(2)}x',
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Rounds',
          value: '${history.length}',
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildHistoryItem(_HistoryItem item, bool isLatest) {
    final isCrash = item.multiplier < 2.0;
    final color = isCrash ? AppColors.error : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isLatest
            ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                isCrash ? 'CRASH' : 'CASH',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Text(
            '${item.multiplier.toStringAsFixed(2)}x',
            style: GoogleFonts.robotoMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            _formatTime(item.timestamp),
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    return '${diff.inMinutes}m ago';
  }
}

class _HistoryItem {
  final double multiplier;
  final DateTime timestamp;

  _HistoryItem({required this.multiplier, required this.timestamp});
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
