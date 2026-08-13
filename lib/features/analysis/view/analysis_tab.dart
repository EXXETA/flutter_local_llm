import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/shared_components.dart';
import '../bloc/analysis_bloc.dart';
import '../bloc/analysis_event.dart';
import '../bloc/analysis_state.dart';

const _kScenario3Display =
    'User feedback email regarding billing dispute: Clara Higgins claims '
    'double-charging on Account #INV-2026-07A. Threatens full cancellation if '
    "subscription credit of \$30.00 isn't processed.";

const _kScenario4Display =
    'Server log context: Fatal Database Connection error reported on '
    '10.0.4.12:5432 affecting Authentication API endpoints. '
    '14,000 users disconnected instantly.';

class AnalysisTab extends StatelessWidget {
  const AnalysisTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalysisBloc, AnalysisState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // ---- Scenario 3: Classify content ----
            const SectionTitle('Scenario 3 — Classify Content (Static)'),
            const SizedBox(height: 12),
            const StaticTextBox(
              text: _kScenario3Display,
              prompt: 'Prompt: "Classify this content: …"',
            ),
            const SizedBox(height: 12),
            ActionButton(
              label: 'Classify Content',
              icon: Icons.label_outline,
              isLoading: state.isLoading,
              onPressed: () => context.read<AnalysisBloc>().add(
                const AnalysisClassifyRequested(),
              ),
            ),
            const SizedBox(height: 20),
            const SectionDivider(),
            const SizedBox(height: 16),

            // ---- Scenario 4: Extract entities ----
            const SectionTitle('Scenario 4 — Extract Entities (Static)'),
            const SizedBox(height: 12),
            const StaticTextBox(
              text: _kScenario4Display,
              prompt: 'Prompt: "Extract entities from this log: …"',
            ),
            const SizedBox(height: 12),
            ActionButton(
              label: 'Extract Entities',
              icon: Icons.data_object,
              isLoading: state.isLoading,
              onPressed: () => context.read<AnalysisBloc>().add(
                const AnalysisExtractEntitiesRequested(),
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
        );
      },
    );
  }
}
