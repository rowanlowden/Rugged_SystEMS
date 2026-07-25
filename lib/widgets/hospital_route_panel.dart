import 'package:flutter/material.dart';

import '../utils/consts.dart';

class HospitalRoutePanel extends StatelessWidget {
  const HospitalRoutePanel({
    super.key,
    required this.profile,
    required this.onStartHospitalRoute,
  });

  final DemoIncidentProfile profile;
  final VoidCallback onStartHospitalRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xE012151A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A3038)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'DESTINATION HOSPITAL',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFAAB4C1),
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B8CF7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRIMARY TRAUMA',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFC8CCCC),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile.hospitalName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: const Color(0xFFC8CCCC),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile.hospitalAddress,
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFFC1CAD6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C2128),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: _MetricCell(
                    label: 'DISTANCE',
                    value: profile.hospitalDistance,
                    valueColor: const Color(0xFF4B8CF7),
                  ),
                ),
                Expanded(
                  child: _MetricCell(
                    label: 'EST. TIME',
                    value: profile.hospitalEta,
                    valueColor: const Color(0xFF4B8CF7),
                  ),
                ),
                Expanded(
                  child: _MetricCell(
                    label: 'ROUTE TYPE',
                    value: profile.hospitalRouteType.replaceAll(' ', '\n'),
                    valueColor: const Color(0xFFC8CCCC),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onStartHospitalRoute,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: const Color(0xFF4B8CF7),
              foregroundColor: const Color(0xFFC8CCCC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'START HOSPITAL ROUTE',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: const Color(0xFFAAB4C1),
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
