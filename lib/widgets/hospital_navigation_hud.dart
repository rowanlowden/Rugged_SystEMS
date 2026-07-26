import 'package:flutter/material.dart';

import '../utils/consts.dart';

class HospitalNavigationHud extends StatelessWidget {
  const HospitalNavigationHud({super.key, required this.profile});

  final DemoIncidentProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          child: const Column(
            children: [
              Row(
                children: [
                  _CompletedSegmentBar(),
                  SizedBox(width: 6),
                  _CompletedSegmentBar(),
                  SizedBox(width: 6),
                  _CompletedSegmentBar(),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  _CompletedSegmentLabel(text: 'PAVED'),
                  _CompletedSegmentLabel(text: 'OFFROAD'),
                  _CompletedSegmentLabel(text: 'WALK'),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3B1B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFC8CCCC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF1A9F4B),
                  size: 30,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.patientSecuredTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFFC8CCCC),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      profile.patientSecuredDetails,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFC8CCCC),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompletedSegmentBar extends StatelessWidget {
  const _CompletedSegmentBar();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFF1E3B1B),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _CompletedSegmentLabel extends StatelessWidget {
  const _CompletedSegmentLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        '✓ $text',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF1E3B1B),
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
