import 'package:flutter/material.dart';

import 'navigation_phase.dart';
import '../utils/consts.dart';

class NavigationPhaseHud extends StatelessWidget {
  const NavigationPhaseHud({
    super.key,
    required this.phase,
    required this.routeSegments,
    required this.pavedInstructionDistance,
    required this.pavedInstructionText,
    required this.offroadAdvisoryTitle,
    required this.offroadAdvisoryDetails,
    required this.walkingAdvisoryTitle,
    required this.walkingAdvisoryDetails,
  });

  final NavigationPhase phase;
  final List<RouteSegmentDemo> routeSegments;
  final String pavedInstructionDistance;
  final String pavedInstructionText;
  final String offroadAdvisoryTitle;
  final String offroadAdvisoryDetails;
  final String walkingAdvisoryTitle;
  final String walkingAdvisoryDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xE012151A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A3038)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _SegmentBar(
                    active: phase == NavigationPhase.paved,
                    color: const Color(0xFF1E3B1B),
                  ),
                  const SizedBox(width: 6),
                  _SegmentBar(
                    active: phase == NavigationPhase.offroad,
                    color: const Color(0xFFD4A017),
                  ),
                  const SizedBox(width: 6),
                  _SegmentBar(
                    active: phase == NavigationPhase.walking,
                    color: const Color(0xFFE53935),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SegmentLabel(text: _labelFor(routeSegments, 0, 'PAVED')),
                  _SegmentLabel(text: _labelFor(routeSegments, 1, 'OFFROAD')),
                  _SegmentLabel(text: _labelFor(routeSegments, 2, 'WALK')),
                ],
              ),
            ],
          ),
        ),
        _PhaseInstructionBanner(
          phase: phase,
          pavedInstructionDistance: pavedInstructionDistance,
          pavedInstructionText: pavedInstructionText,
          offroadAdvisoryTitle: offroadAdvisoryTitle,
          offroadAdvisoryDetails: offroadAdvisoryDetails,
          walkingAdvisoryTitle: walkingAdvisoryTitle,
          walkingAdvisoryDetails: walkingAdvisoryDetails,
        ),
      ],
    );
  }

  String _labelFor(
    List<RouteSegmentDemo> segments,
    int index,
    String fallback,
  ) {
    if (segments.length <= index) {
      return fallback;
    }

    final segment = segments[index];
    return segment.name.toUpperCase().split(' ').first;
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: active ? color : const Color(0xFF3A4250),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFFAAB4C1),
          fontFamily: 'monospace',
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PhaseInstructionBanner extends StatelessWidget {
  const _PhaseInstructionBanner({
    required this.phase,
    required this.pavedInstructionDistance,
    required this.pavedInstructionText,
    required this.offroadAdvisoryTitle,
    required this.offroadAdvisoryDetails,
    required this.walkingAdvisoryTitle,
    required this.walkingAdvisoryDetails,
  });

  final NavigationPhase phase;
  final String pavedInstructionDistance;
  final String pavedInstructionText;
  final String offroadAdvisoryTitle;
  final String offroadAdvisoryDetails;
  final String walkingAdvisoryTitle;
  final String walkingAdvisoryDetails;

  @override
  Widget build(BuildContext context) {
    switch (phase) {
      case NavigationPhase.paved:
        return const SizedBox.shrink();
      case NavigationPhase.offroad:
        return _OffroadAdvisory(
          title: offroadAdvisoryTitle,
          details: offroadAdvisoryDetails,
        );
      case NavigationPhase.walking:
        return _WalkingAdvisory(
          title: walkingAdvisoryTitle,
          details: walkingAdvisoryDetails,
        );
    }
  }
}

class _OffroadAdvisory extends StatelessWidget {
  const _OffroadAdvisory({required this.title, required this.details});

  final String title;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A017),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1D1A00),
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            details,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF2B2500),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkingAdvisory extends StatelessWidget {
  const _WalkingAdvisory({required this.title, required this.details});

  final String title;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xE012151A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE53935)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFE53935),
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            details,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFE53935),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
