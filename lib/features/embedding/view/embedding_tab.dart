import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../shared/widgets/shared_components.dart';
import '../bloc/embedding_bloc.dart';
import '../bloc/embedding_event.dart';
import '../bloc/embedding_state.dart';

const _kReferenceText =
    'Planets orbit stars in vast solar systems, held in place by gravity across '
    'immense stretches of space. From rocky terrestrial worlds to massive gas '
    'giants, each planet tells a unique story about the forces that shaped our '
    'universe.';

const _kGoodMatch =
    'Stars are surrounded by orbiting celestial bodies, ranging from small '
    'rocky planets to enormous gas giants, all bound together by gravitational '
    'forces.';

const _kBadMatch =
    'The chef carefully chopped the vegetables and seasoned the soup before '
    'serving it to the guests.';

class EmbeddingTab extends HookWidget {
  const EmbeddingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final simController = useTextEditingController();

    return BlocConsumer<EmbeddingBloc, EmbeddingState>(
      listenWhen: (prev, curr) => prev.similarityInput != curr.similarityInput,
      listener: (context, state) {
        if (simController.text != state.similarityInput) {
          simController.value = TextEditingValue(
            text: state.similarityInput,
            selection: TextSelection.collapsed(
              offset: state.similarityInput.length,
            ),
          );
        }
      },
      builder: (context, state) {
        if (!state.isModelReady) {
          return _ModelSetupBody(state: state);
        }
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // ---- Scenario 5: Embed reference text ----
              const SectionTitle('Scenario 5 — Text Embeddings'),
              const SizedBox(height: 12),
              const StaticTextBox(text: _kReferenceText),
              const SizedBox(height: 12),
              ActionButton(
                label: 'Embed Reference Text',
                icon: Icons.spoke_outlined,
                isLoading: state.status == EmbeddingStatus.embeddingReference,
                onPressed: () => context.read<EmbeddingBloc>().add(
                  const EmbeddingEmbedReferenceRequested(),
                ),
              ),
              if (state.hasReference) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _VectorInfo(dimensions: state.referenceDimensions!),
                ),
              ],
              const SizedBox(height: 20),
              const SectionDivider(),
              const SizedBox(height: 16),

              // ---- Similarity section ----
              const SectionTitle('Similarity Matcher'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Enter a sentence to compare against the reference text above.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: simController,
                    maxLines: 3,
                    minLines: 3,
                    onChanged: (v) => context.read<EmbeddingBloc>().add(
                      EmbeddingSimilarityInputChanged(v),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Type your sentence here…',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _MatchChip(
                        label: 'Good Match',
                        icon: Icons.check_circle,
                        color: Colors.green,
                        onTap: () => context.read<EmbeddingBloc>().add(
                          const EmbeddingSimilarityQuickFill(_kGoodMatch),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MatchChip(
                        label: 'Bad Match',
                        icon: Icons.cancel,
                        color: Colors.red,
                        onTap: () => context.read<EmbeddingBloc>().add(
                          const EmbeddingSimilarityQuickFill(_kBadMatch),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ActionButton(
                label: 'Compare Similarity',
                icon: Icons.compare_arrows,
                isEnabled: state.canCompare,
                isLoading: state.status == EmbeddingStatus.comparing,
                onPressed: () => context.read<EmbeddingBloc>().add(
                  const EmbeddingCompareRequested(),
                ),
              ),
              if (state.similarityScore != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SimilarityResultCard(score: state.similarityScore!),
                ),
              ],
              if (state.status == EmbeddingStatus.error &&
                  state.errorMessage != null) ...[
                const SizedBox(height: 16),
                OutputSection(
                  output: '',
                  isLoading: false,
                  errorMessage: state.errorMessage,
                ),
              ],
              const SizedBox(height: 64),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _ModelSetupBody extends StatelessWidget {
  const _ModelSetupBody({required this.state});

  final EmbeddingState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isInstalling = state.status == EmbeddingStatus.installingModel;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.scatter_plot_outlined, size: 64, color: colors.primary),
          const SizedBox(height: 24),
          Text(
            'Embedding Model Required',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'The Embedding tab requires the Gecko 256 embedding model (~114 MB).\n'
            'This is a public model — no HuggingFace token required.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.outline),
          ),
          if (isInstalling) ...[
            const SizedBox(height: 24),
            LinearProgressIndicator(value: state.installProgress / 100),
            const SizedBox(height: 8),
            Text(
              '${state.installProgress}%',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: colors.primary),
            ),
          ] else ...[
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.read<EmbeddingBloc>().add(
                const EmbeddingInstallModelRequested(),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Download Embedding Model'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
          if (state.status == EmbeddingStatus.error &&
              state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _VectorInfo extends StatelessWidget {
  const _VectorInfo({required this.dimensions});

  final int dimensions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            'Embedded  ·  $dimensions dimensions',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchChip extends StatelessWidget {
  const _MatchChip({
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
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        backgroundColor: color.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}

class _SimilarityResultCard extends StatelessWidget {
  const _SimilarityResultCard({required this.score});

  final double score;

  String get _label {
    if (score >= 0.85) return 'Very High';
    if (score >= 0.65) return 'High';
    if (score >= 0.45) return 'Moderate';
    if (score >= 0.25) return 'Low';
    return 'Very Low';
  }

  Color _color(BuildContext context) {
    if (score >= 0.85) return Colors.green;
    if (score >= 0.65) return Colors.teal;
    if (score >= 0.45) return Colors.amber;
    if (score >= 0.25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Similarity Score',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colors.outline),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score.clamp(0.0, 1.0),
              minHeight: 10,
              color: color,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score.toStringAsFixed(4),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
