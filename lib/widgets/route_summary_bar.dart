import 'package:flutter/material.dart';

class RouteSummaryBar extends StatelessWidget {
  const RouteSummaryBar({
    super.key,
    required this.totalResponseTime,
    required this.totalDistance,
  });

  final String totalResponseTime;
  final String totalDistance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      decoration: BoxDecoration(
        color: const Color(0xE01D2229),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3038)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _MetricColumn(
              label: 'TOTAL RESP TIME',
              value: totalResponseTime,
              valueColor: const Color(0xFF1E3B1B),
              alignEnd: false,
              theme: theme,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: _MetricColumn(
              label: 'TOTAL DISTANCE',
              value: totalDistance,
              valueColor: const Color(0xFFC8CCCC),
              alignEnd: true,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.alignEnd,
    required this.theme,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.right : TextAlign.left;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: theme.textTheme.labelMedium?.copyWith(
            color: const Color(0xFF8D96A3),
            fontFamily: 'monospace',
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: textAlign,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
