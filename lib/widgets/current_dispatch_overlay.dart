import 'package:flutter/material.dart';

import '../utils/consts.dart';

class CurrentDispatchOverlay extends StatelessWidget {
  const CurrentDispatchOverlay({
    super.key,
    required this.profile,
    required this.coordinatesLabel,
    required this.onClose,
  });

  final DemoIncidentProfile profile;
  final String coordinatesLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: const Color(0xF512151A),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Text(
                    'Current Dispatch',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFC8CCCC),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3B4452)),
                      foregroundColor: const Color(0xFFD8E0EC),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Exit'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label(text: 'PATIENT IDENTITY'),
                          const SizedBox(height: 4),
                          Text(
                            profile.patientIdentity,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFFC8CCCC),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFF30353D)),
                          const SizedBox(height: 10),
                          _Label(text: 'REPORTED EVENT'),
                          const SizedBox(height: 4),
                          Text(
                            profile.reportedEvent,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFFE53935),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _Card(
                            child: _Metric(
                              label: 'COORDINATES',
                              value: coordinatesLabel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Card(
                            child: _Metric(
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
                          child: _Card(
                            child: _Metric(
                              label: 'TOTAL RESP TIME',
                              value: profile.totalResponseTime,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Card(
                            child: _Metric(
                              label: 'TOTAL DISTANCE',
                              value: profile.totalDistance,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label(text: 'RESPONDERS ON DUTY'),
                          const SizedBox(height: 8),
                          for (final responder in profile.respondersOnDuty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '• $responder',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFFC8CCCC),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Card(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_shipping,
                            color: Color(0xFF4B8CF7),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label(text: 'AMBULANCE INFO'),
                                const SizedBox(height: 4),
                                Text(
                                  'Unit ${profile.ambulanceId}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: const Color(0xFFC8CCCC),
                                        fontWeight: FontWeight.w800,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D2229),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3038)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: const Color(0xFF8D96A3),
        letterSpacing: 1.0,
        fontFamily: 'monospace',
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(text: label),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFFC8CCCC),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
