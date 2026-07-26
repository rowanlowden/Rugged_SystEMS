import 'package:flutter/material.dart';

import '../utils/consts.dart';

class DispatchCallPanel extends StatelessWidget {
  const DispatchCallPanel({
    super.key,
    required this.profile,
    required this.onAcceptNavigate,
  });

  final DemoIncidentProfile profile;
  final VoidCallback onAcceptNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xEE101317),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'INCOMING DISPATCH',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF190A0B),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HudCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(text: 'PATIENT IDENTITY'),
                const SizedBox(height: 4),
                Text(
                  profile.patientIdentity,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC8CCCC),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFF30353D)),
                const SizedBox(height: 10),
                _SectionLabel(text: 'REPORTED EVENT'),
                const SizedBox(height: 4),
                Text(
                  profile.reportedEvent,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFE53935),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HudCard(
                  child: _MetricTile(
                    label: 'COORDINATES',
                    value: profile.incidentCoordinates,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HudCard(
                  child: _MetricTile(
                    label: 'LOCATION EST.',
                    value: profile.locationEstimate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HudCard(
                  child: _MetricTile(
                    label: 'EST. DISTANCE',
                    value: profile.estimatedDistance,
                    emphasize: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HudCard(
                  child: _MetricTile(
                    label: 'EST. RESPONSE TIME',
                    value: profile.estimatedResponseTime,
                    emphasize: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onAcceptNavigate,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3B1B),
              foregroundColor: const Color(0xFFC8CCCC),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'ACCEPT & NAVIGATE',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudCard extends StatelessWidget {
  const _HudCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D2229),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3038)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: const Color(0xFF8D96A3),
        letterSpacing: 1.1,
        fontFamily: 'monospace',
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(text: label),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: emphasize
                ? const Color(0xFFC8CCCC)
                : const Color(0xFFC8CCCC),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
