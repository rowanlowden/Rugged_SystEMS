import 'package:flutter/material.dart';

import '../utils/consts.dart';

class PatientRouteSheet extends StatelessWidget {
  const PatientRouteSheet({
    super.key,
    required this.scrollController,
    required this.onStartNavigation,
    required this.routeSegments,
  });

  final ScrollController scrollController;
  final VoidCallback onStartNavigation;
  final List<RouteSegmentDemo> routeSegments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE8101317),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2229),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A3038)),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROUTE SEGMENT ANALYTICS',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFC8CCCC),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < routeSegments.length; i++) ...[
                        _RouteSegmentRow(
                          color: routeSegments[i].color,
                          routeName: routeSegments[i].name,
                          distance: routeSegments[i].distance,
                          eta: routeSegments[i].eta,
                        ),
                        if (i < routeSegments.length - 1)
                          const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: onStartNavigation,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3B1B),
                          foregroundColor: const Color(0xFFC8CCCC),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'START ROAD NAVIGATION',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSegmentRow extends StatelessWidget {
  const _RouteSegmentRow({
    required this.color,
    required this.routeName,
    required this.distance,
    required this.eta,
  });

  final Color color;
  final String routeName;
  final String distance;
  final String eta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  routeName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFC8CCCC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            distance,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFB3BDC9),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            eta,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFB3BDC9),
            ),
          ),
        ),
      ],
    );
  }
}
