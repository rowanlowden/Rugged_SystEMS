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
                  color: const Color(0xFFC8CCCC),
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
    final offroadSpeedValue = _offroadSpeedValue(profile.offroadCurrentSpeed);
    final offroadSpeedUnit = _offroadSpeedUnit(profile.offroadCurrentSpeed);

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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                offroadSpeedValue,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: const Color(0xFFD4A017),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                offroadSpeedUnit,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFD4A017),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _monoLabel(theme, 'ROAD ETA'),
                  Text(
                    _offroadRoadEta(profile),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFD4A017),
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
                _offroadRouteProgress(profile),
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

String _offroadSpeedValue(String speedText) {
  final parts = speedText.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '--';
  }
  return parts.first;
}

String _offroadSpeedUnit(String speedText) {
  final parts = speedText.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) {
    return 'MPH';
  }
  return parts.sublist(1).join(' ');
}

String _offroadRoadEta(DemoIncidentProfile profile) {
  if (profile.routeSegments.length < 2) {
    return '--';
  }
  return profile.routeSegments[1].eta.toUpperCase();
}

String _offroadRouteProgress(DemoIncidentProfile profile) {
  if (profile.routeSegments.length < 2) {
    return _trimOffroadExitPrefix(profile.offroadDistToExit);
  }

  final totalMiles = _extractMiles(profile.routeSegments[1].distance);
  final remainingMiles = _extractMiles(profile.offroadDistToExit);
  if (totalMiles == null || remainingMiles == null) {
    return _trimOffroadExitPrefix(profile.offroadDistToExit);
  }

  final progressedMiles = totalMiles > remainingMiles
      ? totalMiles - remainingMiles
      : 0.0;
  return '${_formatMiles(progressedMiles)} / ${_formatMiles(totalMiles)}';
}

String _trimOffroadExitPrefix(String value) {
  return value.replaceFirst('DIST TO OFFROAD EXIT ', '');
}

double? _extractMiles(String value) {
  final match = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:MI|MILES|mi|miles)',
  ).firstMatch(value);
  if (match == null) {
    return null;
  }
  return double.tryParse(match.group(1)!);
}

String _formatMiles(double miles) {
  return '${miles.toStringAsFixed(1)} MI';
}

class _WalkingStatus extends StatelessWidget {
  const _WalkingStatus({required this.profile, required this.onPatientReached});

  final DemoIncidentProfile profile;
  final VoidCallback onPatientReached;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceToPatient = _walkingDistanceToPatient(profile);

    return _BasePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _monoLabel(theme, 'DISTANCE TO PATIENT'),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                distanceToPatient,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: const Color(0xFFC8CCCC),
                  fontWeight: FontWeight.w900,
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
}

String _walkingDistanceToPatient(DemoIncidentProfile profile) {
  if (profile.routeSegments.length < 3) {
    return '340 M';
  }

  final walkingDistance = profile.routeSegments[2].distance;
  final numericMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(walkingDistance);
  if (numericMatch != null) {
    final rawValue = double.tryParse(numericMatch.group(1)!);
    if (rawValue != null) {
      final meters = rawValue.round();
      return '$meters M';
    }
  }

  return '340 M';
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
