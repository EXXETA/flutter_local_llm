import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../shared/widgets/shared_components.dart';
import '../bloc/rag_bloc.dart';
import '../bloc/rag_event.dart';
import '../bloc/rag_state.dart';

const _kQuickQueries = [
  'How do vaccines train the immune system?',
  'How is sourdough bread made?',
  'When did the Cold War end?',
];

class RagTab extends HookWidget {
  const RagTab({super.key});

  @override
  Widget build(BuildContext context) {
    final queryController = useTextEditingController();

    return BlocConsumer<RagBloc, RagState>(
      listenWhen: (prev, curr) => prev.searchQuery != curr.searchQuery,
      listener: (context, state) {
        if (queryController.text != state.searchQuery) {
          queryController.value = TextEditingValue(
            text: state.searchQuery,
            selection: TextSelection.collapsed(
              offset: state.searchQuery.length,
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
              // ---- Scenario 6: Index a knowledge base ----
              const SectionTitle('Scenario 6 — Index a Knowledge Base'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '7 short documents across science, cooking, and history. '
                  'Each is embedded on-device and stored in a local '
                  'sqlite-vec vector store.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ActionButton(
                label: state.isIndexed
                    ? 'Re-index Documents'
                    : 'Index Documents',
                icon: Icons.upload_file_outlined,
                isEnabled: state.canIndex,
                isLoading: state.status == RagStatus.indexing,
                onPressed: () => context.read<RagBloc>().add(
                  const RagIndexDocumentsRequested(),
                ),
              ),
              if (state.isIndexed) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _IndexedBadge(count: state.indexedCount),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => context.read<RagBloc>().add(
                          const RagClearIndexRequested(),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const SectionDivider(),
              const SizedBox(height: 16),

              // ---- Scenario 7: Filtered semantic search ----
              const SectionTitle('Scenario 7 — Filtered Semantic Search'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'The query is embedded and matched by cosine similarity. '
                  'Topic and year are declared filterable via '
                  'FilterSchema/FilterField at startup, so filters run '
                  'inside sqlite-vec, not in Dart.',
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
                    controller: queryController,
                    onChanged: (v) => context.read<RagBloc>().add(
                      RagSearchInputChanged(v),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ask a question…',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kQuickQueries
                      .map(
                        (q) => ActionChip(
                          label: Text(q, style: const TextStyle(fontSize: 11)),
                          onPressed: () => context.read<RagBloc>().add(
                            RagSearchInputChanged(q),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Filter (FilterSchema fields)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final topic in [kAllTopics, ...kRagTopics])
                      ChoiceChip(
                        label: Text(
                          topic == kAllTopics ? 'All topics' : topic,
                        ),
                        selected: state.topicFilter == topic,
                        onSelected: (_) => context.read<RagBloc>().add(
                          RagTopicFilterChanged(topic),
                        ),
                      ),
                    FilterChip(
                      label: const Text('2020 or later'),
                      selected: state.recentOnly,
                      onSelected: (v) => context.read<RagBloc>().add(
                        RagRecentOnlyFilterChanged(v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ActionButton(
                label: 'Search',
                icon: Icons.search,
                isEnabled: state.canSearch,
                isLoading: state.status == RagStatus.searching,
                onPressed: () => context.read<RagBloc>().add(
                  const RagSearchRequested(),
                ),
              ),
              if (state.hasSearched) ...[
                const SizedBox(height: 16),
                _ResultsList(results: state.results),
              ],
              if (state.status == RagStatus.error &&
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

  final RagState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isInstalling = state.status == RagStatus.installingModel;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.travel_explore_outlined, size: 64, color: colors.primary),
          const SizedBox(height: 24),
          Text(
            'Embedding Model Required',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'The RAG tab embeds documents and queries on-device using the '
            'same Gecko 256 embedding model (~114 MB) as the Embedding tab.\n'
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
              onPressed: () => context.read<RagBloc>().add(
                const RagInstallModelRequested(),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Download Embedding Model'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
          if (state.status == RagStatus.error &&
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

class _IndexedBadge extends StatelessWidget {
  const _IndexedBadge({required this.count});

  final int count;

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
            'Indexed  ·  $count documents',
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

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results});

  final List<RetrievalResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No matches for this query and filter combination.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final result in results)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _ResultCard(result: result),
          ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final RetrievalResult result;

  Map<String, dynamic>? get _metadata {
    final raw = result.metadata;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Color _color(BuildContext context) {
    if (result.similarity >= 0.7) return Colors.green;
    if (result.similarity >= 0.5) return Colors.teal;
    if (result.similarity >= 0.3) return Colors.amber;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final colors = Theme.of(context).colorScheme;
    final metadata = _metadata;

    return Container(
      padding: const EdgeInsets.all(14),
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
              if (metadata?['topic'] != null) _Badge(text: metadata!['topic']),
              if (metadata?['year'] != null) ...[
                const SizedBox(width: 6),
                _Badge(text: '${metadata!['year']}'),
              ],
              const Spacer(),
              Text(
                result.similarity.toStringAsFixed(3),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(result.content, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: result.similarity.clamp(0.0, 1.0),
              minHeight: 6,
              color: color,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.outline,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
