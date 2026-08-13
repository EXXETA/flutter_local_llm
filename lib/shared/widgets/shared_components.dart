import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// StaticTextBox — read-only context panel used in Analysis + Embedding tabs
// ---------------------------------------------------------------------------
class StaticTextBox extends StatelessWidget {
  const StaticTextBox({required this.text, this.prompt, super.key});

  final String text;
  final String? prompt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant, width: 0.5),
            ),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (prompt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: Text(
                prompt!,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.outline),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ActionButton — full-width CTA with loading spinner
// ---------------------------------------------------------------------------
class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FilledButton.icon(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OutputSection — collapsible result panel
// ---------------------------------------------------------------------------
class OutputSection extends StatelessWidget {
  const OutputSection({
    required this.output,
    required this.isLoading,
    this.errorMessage,
    super.key,
  });

  final String output;
  final bool isLoading;
  final String? errorMessage;

  bool get _visible => isLoading || output.isNotEmpty || errorMessage != null;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Result',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (isLoading && output.isEmpty)
              Text(
                'Processing…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colors.outline,
                ),
              )
            else if (errorMessage != null)
              Text(
                errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.error),
              )
            else
              SelectableText(
                output,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SectionDivider — labelled horizontal rule between scenarios
// ---------------------------------------------------------------------------
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(),
    );
  }
}

// ---------------------------------------------------------------------------
// SectionTitle — bold scenario heading
// ---------------------------------------------------------------------------
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
