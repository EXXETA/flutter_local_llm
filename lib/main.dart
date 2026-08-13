import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_embeddings/flutter_gemma_embeddings.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_gemma_rag_sqlite/flutter_gemma_rag_sqlite.dart';
import 'package:flutter_local_llm/core/constants/model_constants.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env (tracked: sample.env only — .env is gitignored).
  await dotenv.load(fileName: '.env');

  // Register flutter_gemma opt-in engines.
  // Both MediaPipe (.task) and LiteRT-LM (.litertlm) are registered so the
  // registry routes any model format to the correct native engine.
  await FlutterGemma.initialize(
    inferenceEngines: const [
      LiteRtLmEngine(), // .litertlm — Android, iOS, Desktop
      MediaPipeEngine(), // .task / .bin — Android, iOS, Web
    ],
    embeddingBackends: const [
      LiteRtEmbeddingBackend(), // flutter_gemma_embeddings
    ],
    // sqlite-vec vector store for the RAG tab — bundles the vec0 extension
    // via a Native Assets build hook, no manual native setup required.
    vectorStore: kIsWeb ? WebSqliteVectorStore() : SqliteVectorStore(),
    // Declares which RAG document metadata fields are filterable, so the
    // RAG tab's topic/year filters push down to typed vec0 columns.
    filterSchema: const FilterSchema(
      fields: [
        FilterField(name: 'topic', type: FilterFieldType.string),
        FilterField(name: 'year', type: FilterFieldType.number),
      ],
    ),
    // Pass the HF token globally so installs of gated models work without
    // passing it per-call. Qwen3 0.6B (default inference model) is public.
    huggingFaceToken: dotenv.env['HUGGING_FACE_API_KEY'],
  );

  // Check if inference model is actually installed (async check)
  final isModelInstalled = await FlutterGemma.isModelInstalled(
    ModelConstants.inferenceModelName,
  );

  runApp(App(isModelInstalled: isModelInstalled));
}
