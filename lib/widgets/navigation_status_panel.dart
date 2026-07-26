import 'package:flutter/material.dart';

import '../utils/consts.dart';
import 'navigation_phase.dart';

class NavigationStatusPanel extends StatelessWidget {
  const NavigationStatusPanel({
    super.key,
    required this.phase,
    required this.profile,
    required this.onPatientReached,
  });

  final NavigationPhase phase;
  final DemoIncidentProfile profile;
  final VoidCallback onPatientReached;

  @override
  Widget build(BuildContext context) {
    switch (phase) {
      case NavigationPhase.paved:
        return _PavedStatus(profile: profile);
      case NavigationPhase.offroad:
        return _OffroadStatus(profile: profile);
      case NavigationPhase.walking:
        return _WalkingStatus(
          profile: profile,
          onPatientReached: onPatientReached,
        );
    }
  }
}

class _BasePanel extends StatelessWidget {
  const _BasePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xE012151A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3038)),
      ),
      child: child,
    );
  }
}

class _PavedStatus extends StatelessWidget {
  const _PavedStatus({required this.profile});

  final DemoIncidentProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _BasePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _monoLabel(theme, 'CURRENT SPEED'),
              const Spacer(),
              Text(
                profile.pavedSurfaceStatus,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1E3B1B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                profile.pavedCurrentSpeed,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: const Color(0xFFC8CCCC),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MPH',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFC8CCCC),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _monoLabel(theme, 'ROAD ETA'),
                  Text(
                    profile.pavedRoadEta,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFC8CCCC),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _monoLabel(theme, 'ROUTE PROGRESS'),
              const Spacer(),
              Text(
                profile.pavedRouteProgress,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFDCE3EC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OffroadStatus extends StatelessWidget {
  const _OffroadStatus({required this.profile});

  final DemoIncidentProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _BasePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _monoLabel(theme, 'HEADING BEARING'),
              const Spacer(),
              Text(
                profile.offroadFieldAccessLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFD4A017),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                profile.offroadHeading,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: const Color(0xFFD4A017),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                profile.offroadDistToExit,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFFDCE3EC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            profile.offroadAlignHint,
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFFDCE3EC),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _monoLabel(theme, 'CURRENT SPEED'),
              const Spacer(),
              Text(
                profile.offroadCurrentSpeed,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFD4A017),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalkingStatus extends StatelessWidget {
  const _WalkingStatus({required this.profile, required this.onPatientReached});

  final DemoIncidentProfile profile;
  final VoidCallback onPatientReached;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _BasePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _monoLabel(theme, profile.walkingTelemetryTitle),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  profile.walkingCriticalLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF24090B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _vitalCard(
                  theme,
                  'HEART RATE',
                  profile.walkingHeartRate,
                  const Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _vitalCard(
                  theme,
                  'SPO2',
                  profile.walkingSpo2,
                  const Color(0xFFD4A017),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _vitalCard(
                  theme,
                  'RESP',
                  profile.walkingResp,
                  const Color(0xFFC8CCCC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onPatientReached,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: const Color(0xFFC8CCCC),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'PATIENT REACHED',
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

  Widget _vitalCard(
    ThemeData theme,
    String label,
    String value,
    Color valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFAAB4C1),
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Text _monoLabel(ThemeData theme, String text) {
  return Text(
    text,
    style: theme.textTheme.labelLarge?.copyWith(
      color: const Color(0xFFAAB4C1),
      fontFamily: 'monospace',
      letterSpacing: 0.4,
    ),
  );
}
