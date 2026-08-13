enum AiMood {
  professional,
  casual,
  concise,
  analytical;

  String get label {
    return switch (this) {
      AiMood.professional => 'Professional',
      AiMood.casual => 'Casual',
      AiMood.concise => 'Concise',
      AiMood.analytical => 'Analytical',
    };
  }

  String get icon {
    return switch (this) {
      AiMood.professional => '💼',
      AiMood.casual => '💬',
      AiMood.concise => '⚡',
      AiMood.analytical => '📊',
    };
  }
}
