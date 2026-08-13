import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../shared/models/ai_mood.dart';
import '../../../shared/widgets/shared_components.dart';
import '../bloc/generation_bloc.dart';
import '../bloc/generation_event.dart';
import '../bloc/generation_state.dart';

// Quick-fill sample texts (mirrored from iOS)
const _kScenario1 =
    'CRITICAL DELAY ALERT. Outbound shipment #TRK-99281-X '
    'carrying industrial medical components is stuck at the Leipzig Hub. '
    'The carrier reports that Customs paperwork missing filed under Form E-12. '
    'Original departure was June 14, 2026, but it has been stationary for 48 hours. '
    'Expected delivery was June 16, 2026, to St. Jude Hospital. '
    'Dr. Aris Thorne (Head of Logistics, phone: +49-172-555-0192) has escalated '
    'this twice. Total valuation of cargo is \$145,000. Re-routing or manual '
    'clearance must happen immediately or the contract penalty applies.';

const _kScenario2 =
    'Timestamp: 2026-07-08T08:14:22Z | Level: FATAL | '
    'Module: AuthService | Message: Connection dropped unexpectedly by database '
    'peer 10.0.4.12:5432. Pool size 50 exhausted within 1200ms. Failed attempts '
    'to reconnect auto-throttled. System memory usage spikes to 94.2%. '
    'Affected service: User Authentication Endpoint (/api/v2/auth/login). '
    'Critical impact: 14,000 active sessions terminated. System Administrator '
    'Marcus Vance notified via PagerDuty. Incident token: #ERR-AUTH-8821. '
    'Temporary rollback suggested.';

const _kScenario3 =
    'Hello, I am writing regarding my monthly subscription '
    'invoice #INV-2026-07A for account user Clara Higgins (clara.h@webspace.com). '
    'I was double-charged \$49.99 on July 2nd for the Enterprise tier, even though '
    'I submitted a downgrade request to Pro (\$19.99) on June 28th. I have attached '
    'the confirmation email screenshot from my original request. Please credit the '
    'difference of \$30.00 back to my Visa ending in 4112. If this is not resolved '
    'before the next billing cycle on August 1st, I will cancel my subscription '
    'entirely. Thank you.';

class GenerationTab extends HookWidget {
  const GenerationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final inputController = useTextEditingController();

    return BlocConsumer<GenerationBloc, GenerationState>(
      // Sync controller when state.inputText changes (quick-fill)
      listenWhen: (prev, curr) => prev.inputText != curr.inputText,
      listener: (context, state) {
        if (inputController.text != state.inputText) {
          inputController.value = TextEditingValue(
            text: state.inputText,
            selection: TextSelection.collapsed(offset: state.inputText.length),
          );
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // ---- Input ----
              _InputSection(controller: inputController),
              const SizedBox(height: 12),
              _QuickFillBar(hasInput: state.inputText.isNotEmpty),
              const SizedBox(height: 20),
              const SectionDivider(),
              const SizedBox(height: 16),

              // ---- Scenario 1: Rewrite with tone ----
              const SectionTitle('Scenario 1 — Rewrite with Tone'),
              const SizedBox(height: 12),
              _ToneSelector(selected: state.selectedMood),
              const SizedBox(height: 12),
              ActionButton(
                label: 'Rewrite Text',
                icon: Icons.auto_fix_high,
                isEnabled: state.hasInput,
                isLoading: state.isLoading,
                onPressed: () => context.read<GenerationBloc>().add(
                  GenerationRewriteRequested(state.selectedMood),
                ),
              ),
              const SizedBox(height: 20),
              const SectionDivider(),
              const SizedBox(height: 16),

              // ---- Scenario 2: Summarize ----
              const SectionTitle('Scenario 2 — Summarize'),
              const SizedBox(height: 12),
              ActionButton(
                label: 'Summarize',
                icon: Icons.summarize,
                isEnabled: state.hasInput,
                isLoading: state.isLoading,
                onPressed: () => context.read<GenerationBloc>().add(
                  const GenerationSummarizeRequested(),
                ),
              ),
              const SizedBox(height: 20),
              const SectionDivider(),
              const SizedBox(height: 16),

              // ---- Output ----
              const SectionTitle('Output'),
              const SizedBox(height: 12),
              OutputSection(
                output: state.output,
                isLoading: state.isLoading,
                errorMessage: state.errorMessage,
              ),
              const SizedBox(height: 64),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _InputSection extends StatelessWidget {
  const _InputSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          onChanged: (v) =>
              context.read<GenerationBloc>().add(GenerationInputChanged(v)),
          maxLines: null,
          minLines: 6,
          decoration: const InputDecoration(
            hintText: 'Paste your text here…',
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(14),
          ),
        ),
      ),
    );
  }
}

class _QuickFillBar extends StatelessWidget {
  const _QuickFillBar({required this.hasInput});

  final bool hasInput;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Fill Templates',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _QuickFillChip(
                label: 'S1',
                icon: Icons.local_shipping,
                color: Colors.orange,
                onTap: () => context.read<GenerationBloc>().add(
                  const GenerationQuickFillSelected(_kScenario1),
                ),
              ),
              const SizedBox(width: 8),
              _QuickFillChip(
                label: 'S2',
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
                onTap: () => context.read<GenerationBloc>().add(
                  const GenerationQuickFillSelected(_kScenario2),
                ),
              ),
              const SizedBox(width: 8),
              _QuickFillChip(
                label: 'S3',
                icon: Icons.person,
                color: Colors.blue,
                onTap: () => context.read<GenerationBloc>().add(
                  const GenerationQuickFillSelected(_kScenario3),
                ),
              ),
              const Spacer(),
              if (hasInput)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () => context.read<GenerationBloc>().add(
                    const GenerationQuickFillSelected(''),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickFillChip extends StatelessWidget {
  const _QuickFillChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: FilledButton.styleFrom(backgroundColor: color),
    );
  }
}

class _ToneSelector extends StatelessWidget {
  const _ToneSelector({required this.selected});

  final AiMood selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Output Tone', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
            children: AiMood.values.map((mood) {
              final isSelected = mood == selected;
              final colors = Theme.of(context).colorScheme;
              return GestureDetector(
                onTap: () => context.read<GenerationBloc>().add(
                  GenerationMoodChanged(mood),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : colors.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(mood.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        mood.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
