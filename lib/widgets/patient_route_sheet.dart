import 'package:flutter/material.dart';

class PatientRouteSheet extends StatelessWidget {
  const PatientRouteSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.97),
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
              children: const [
                _InfoRow(label: 'Patient Status', value: 'Stable, conscious'),
                SizedBox(height: 8),
                _InfoRow(label: 'Type of Accident', value: 'ATV rollover'),
                SizedBox(height: 16),
                _RouteTableHeader(),
                SizedBox(height: 10),
                _RouteRow(
                  color: Colors.black,
                  routeName: 'Paved',
                  distance: '8.6 mi',
                  etaMinutes: '14 min',
                ),
                SizedBox(height: 8),
                _RouteRow(
                  color: Colors.blue,
                  routeName: 'Offroad',
                  distance: '3.2 mi',
                  etaMinutes: '11 min',
                ),
                SizedBox(height: 8),
                _RouteRow(
                  color: Colors.red,
                  routeName: 'Walking',
                  distance: '0.4 mi',
                  etaMinutes: '7 min',
                ),
                SizedBox(height: 14),
                Divider(height: 1),
                SizedBox(height: 12),
                _TotalTimeRow(totalMinutes: '32 min total'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 136,
          child: Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteTableHeader extends StatelessWidget {
  const _RouteTableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        Expanded(flex: 4, child: Text('Route Key', style: textStyle)),
        Expanded(flex: 2, child: Text('Distance', style: textStyle)),
        Expanded(flex: 2, child: Text('ETA', style: textStyle)),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.color,
    required this.routeName,
    required this.distance,
    required this.etaMinutes,
  });

  final Color color;
  final String routeName;
  final String distance;
  final String etaMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                routeName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(distance, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          flex: 2,
          child: Text(etaMinutes, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _TotalTimeRow extends StatelessWidget {
  const _TotalTimeRow({required this.totalMinutes});

  final String totalMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Time',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          totalMinutes,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
