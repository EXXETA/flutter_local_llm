import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../core/constants/model_constants.dart';
import 'analysis_event.dart';
import 'analysis_state.dart';

// Static context texts — mirrored from iOS AnalysisTab.swift
const _kScenario3Text =
    'User feedback email regarding billing dispute: Clara Higgins claims '
    'double-charging on Account #INV-2026-07A. Threatens full cancellation if '
    "subscription credit of \$30.00 isn't processed.";

const _kScenario4Text =
    'Server log context: Fatal Database Connection error reported on '
    '10.0.4.12:5432 affecting Authentication API endpoints. '
    '14,000 users disconnected instantly.';

class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  AnalysisBloc() : super(const AnalysisState()) {
    on<AnalysisClassifyRequested>(_onClassify);
    on<AnalysisExtractEntitiesRequested>(_onExtract);
  }

  Future<void> _onClassify(
    AnalysisClassifyRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AnalysisStatus.loading,
        output: '',
        errorMessage: null,
      ),
    );
    const prompt =
        'Classify this content and respond with valid JSON only — '
        'no markdown, no explanation:\n'
        '$_kScenario3Text\n\n'
        'JSON format:\n'
        '{"category":"...","priority":"...","labels":["...","..."]}';
    final raw = await _runModel(prompt, emit);
    if (raw == null) return;
    emit(
      state.copyWith(
        status: AnalysisStatus.success,
        output: _formatClassification(raw),
      ),
    );
  }

  Future<void> _onExtract(
    AnalysisExtractEntitiesRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AnalysisStatus.loading,
        output: '',
        errorMessage: null,
      ),
    );
    const prompt =
        'Extract entities from this log and respond with valid JSON '
        'only — no markdown, no explanation:\n'
        '$_kScenario4Text\n\n'
        'JSON format:\n'
        '{"ipAddress":"...","port":5432,"affectedSystem":"...","impactNumber":0}';
    final raw = await _runModel(prompt, emit);
    if (raw == null) return;
    emit(
      state.copyWith(
        status: AnalysisStatus.success,
        output: _formatExtraction(raw),
      ),
    );
  }

  Future<String?> _runModel(String prompt, Emitter<AnalysisState> emit) async {
    try {
      final model = await FlutterGemma.getActiveModel(
        maxTokens: ModelConstants.maxTokens,
      );
      try {
        final chat = await model.createChat();
        await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
        final response = await chat.generateChatResponse();
        if (response is TextResponse) return response.token;
        return null;
      } finally {
        await model.close();
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AnalysisStatus.error,
          errorMessage: 'Failed to run model: $e',
        ),
      );
      return null;
    }
  }

  String _formatClassification(String raw) {
    try {
      final json = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;
      final category = json['category'] ?? '—';
      final priority = json['priority'] ?? '—';
      final labels = (json['labels'] as List?)?.join(', ') ?? '—';
      return '📋 CLASSIFICATION REPORT\n'
          'Category: $category\n'
          'Priority: $priority\n'
          'Tags: $labels';
    } catch (_) {
      return raw.trim();
    }
  }

  String _formatExtraction(String raw) {
    try {
      final json = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;
      final ip = json['ipAddress'] ?? 'N/A';
      final port = json['port']?.toString() ?? 'N/A';
      final system = json['affectedSystem'] ?? '—';
      final impact = json['impactNumber']?.toString() ?? '—';
      return '🔍 EXTRACTED LOG ENTITIES\n'
          '• Affected System: $system\n'
          '• Impacted Users: $impact\n'
          '• Host: $ip:$port';
    } catch (_) {
      return raw.trim();
    }
  }

  String _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1) return raw;
    return raw.substring(start, end + 1);
  }
}
