import 'package:flutter/material.dart';

class MapHeaderBar extends StatelessWidget {
  const MapHeaderBar({
    super.key,
    required this.coordinatesLabel,
    required this.username,
    this.showCurrentDispatch = false,
    this.onOpenCurrentDispatch,
    this.onLogout,
    this.systemOn = true,
  });

  final String coordinatesLabel;
  final String username;
  final bool showCurrentDispatch;
  final VoidCallback? onOpenCurrentDispatch;
  final VoidCallback? onLogout;
  final bool systemOn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: systemOn
                        ? const Color(0xFF1E3B1B)
                        : const Color(0xFF6D737D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    systemOn ? 'SYS ON' : 'SYS OFF',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFC8CCCC),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  username.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/icons/RS_logo.png',
                    height: 58,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              if (showCurrentDispatch)
                FilledButton.tonal(
                  onPressed: onOpenCurrentDispatch,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF273243),
                    foregroundColor: const Color(0xFFC8CCCC),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Current Dispatch'),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Logout',
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Coordinates: $coordinatesLabel',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
