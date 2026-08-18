# Flutter Local LLM

A small Flutter demo for running language models entirely on-device with
[`flutter_gemma`](https://pub.dev/packages/flutter_gemma). This app was built as a part of my Medium article about [Flutter Gemma: The hidden gem of cross-platform local AI](https://medium.com/@mobileatexxeta/cffdaaf007de).

## Features

- Text generation and chat with Qwen3 0.6B
- Prompt and response analysis
- Local text embeddings
- Retrieval-augmented generation (RAG) with a SQLite vector store
- MediaPipe and LiteRT-LM inference engines

## Getting started

Install Flutter with Dart 3.12 or newer, then run:

```sh
cp sample.env .env
flutter pub get
flutter run
```

The default models are public, so no API key is required. A Hugging Face token
can be added to `.env` when using gated models.

On first launch, the app downloads the Qwen3 0.6B model (about 586 MB). The
model and application data remain on the device, and inference works offline
after the download completes.
