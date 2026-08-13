// Model URLs — update if HuggingFace paths change.
//
// Inference model: Qwen3 0.6B (.litertlm, public — no token needed)
// Embedding model: Gecko 256 (.tflite, public — no token needed)
//   Alternative: EmbeddingGemma 512 (gated — needs HUGGING_FACE_API_KEY)

abstract final class ModelConstants {
  static const inferenceModelName = 'Qwen3-0.6B.litertlm';

  // --- Inference model (used by Generation + Analysis tabs) ---
  // Qwen3 0.6B: ~586 MB, public, supports function calling + thinking
  static const inferenceModelUrl =
      'https://huggingface.co/litert-community/Qwen3-0.6B'
      '/resolve/main/Qwen3-0.6B.litertlm';

  // Context window: total budget for input + output. Min 1024 for .litertlm.
  static const maxTokens = 2048;

  // --- Embedding model (used by Embedding + RAG tabs) ---
  // Gecko 256 quant: ~28 MB, public (no token), 256-token context
  static const embeddingModelUrl =
      'https://huggingface.co/litert-community/Gecko-110m-en'
      '/resolve/main/Gecko_256_quant.tflite';

  // SentencePiece tokenizer required by installEmbedder()
  static const embeddingTokenizerUrl =
      'https://huggingface.co/litert-community/Gecko-110m-en'
      '/resolve/main/sentencepiece.model';

  // EmbeddingGemma 512 (higher accuracy, gated — needs HF token):
  // static const embeddingModelUrl =
  //     'https://huggingface.co/litert-community/embeddinggemma-300m'
  //     '/resolve/main/embeddinggemma_512.tflite';
}
