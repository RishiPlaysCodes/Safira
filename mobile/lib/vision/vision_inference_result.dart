class VisionInferenceResult {
  const VisionInferenceResult({
    required this.type,
    required this.label,
    required this.confidence,
    this.modelName = 'manual',
  });

  final String type;
  final String label;
  final double confidence;
  final String modelName;
}
