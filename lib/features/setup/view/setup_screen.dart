import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../bloc/setup_bloc.dart';
import '../bloc/setup_event.dart';
import '../bloc/setup_state.dart';

@RoutePage()
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SetupBloc()..add(const SetupCheckRequested()),
      child: const _SetupView(),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SetupBloc, SetupState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == SetupStatus.ready) {
          // Replace the entire stack so Back doesn't return to setup.
          context.router.replaceAll([const HomeRoute()]);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<SetupBloc, SetupState>(
            builder: (context, state) {
              return switch (state.status) {
                SetupStatus.checking => const _CheckingBody(),
                SetupStatus.notInstalled => const _InstallBody(),
                SetupStatus.downloading => _DownloadingBody(
                  progress: state.downloadProgress,
                ),
                SetupStatus.ready =>
                  const _CheckingBody(), // briefly shown before nav
                SetupStatus.error => _ErrorBody(message: state.errorMessage),
              };
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CheckingBody extends StatelessWidget {
  const _CheckingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Checking model…'),
        ],
      ),
    );
  }
}

class _InstallBody extends StatelessWidget {
  const _InstallBody();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined, size: 72, color: colors.primary),
          const SizedBox(height: 24),
          Text(
            'Local LLM Demo',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Download the on-device model to get started.\n'
            'Qwen3 0.6B · ~586 MB · no internet needed after download.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.outline),
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: () =>
                context.read<SetupBloc>().add(const SetupInstallRequested()),
            icon: const Icon(Icons.download),
            label: const Text(
              'Download Model',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Model is stored on-device. No data is sent to any server.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.outline),
          ),
        ],
      ),
    );
  }
}

class _DownloadingBody extends StatelessWidget {
  const _DownloadingBody({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_download_outlined, size: 64, color: colors.primary),
          const SizedBox(height: 32),
          Text(
            'Downloading model…',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: progress / 100),
          const SizedBox(height: 8),
          Text(
            '$progress%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Keep the app open. This happens only once.',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.outline),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.error),
          const SizedBox(height: 24),
          Text(
            'Download failed',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colors.error),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.outline),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () =>
                context.read<SetupBloc>().add(const SetupInstallRequested()),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}
