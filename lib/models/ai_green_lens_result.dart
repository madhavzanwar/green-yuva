class AIGreenLensResult {
  final bool isAuthentic; // Anti-spoofing check
  final String spoofingDetails;
  final bool isActionValid; // Action classification check
  final String classification;
  final double confidence; // 0.0 to 1.0 (e.g. 0.94)
  final List<String> detectedObjects;
  final String rationale;
  final bool isProvisionalApproved; // True if confidence >= 0.80 & authentic
  final int karmaAwarded;
  final DateTime auditedAt;
  final String engineUsed;

  const AIGreenLensResult({
    required this.isAuthentic,
    required this.spoofingDetails,
    required this.isActionValid,
    required this.classification,
    required this.confidence,
    required this.detectedObjects,
    required this.rationale,
    required this.isProvisionalApproved,
    required this.karmaAwarded,
    required this.auditedAt,
    required this.engineUsed,
  });

  int get confidencePercentage => (confidence * 100).round();

  Map<String, dynamic> toMap() {
    return {
      'isAuthentic': isAuthentic,
      'spoofingDetails': spoofingDetails,
      'isActionValid': isActionValid,
      'classification': classification,
      'confidence': confidence,
      'detectedObjects': detectedObjects,
      'rationale': rationale,
      'isProvisionalApproved': isProvisionalApproved,
      'karmaAwarded': karmaAwarded,
      'auditedAt': auditedAt.toIso8601String(),
      'engineUsed': engineUsed,
    };
  }

  factory AIGreenLensResult.fromMap(Map<String, dynamic> map) {
    return AIGreenLensResult(
      isAuthentic: map['isAuthentic'] ?? true,
      spoofingDetails: map['spoofingDetails'] ?? 'Live capture verified',
      isActionValid: map['isActionValid'] ?? true,
      classification: map['classification'] ?? 'Action detected',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.85,
      detectedObjects: List<String>.from(map['detectedObjects'] ?? []),
      rationale: map['rationale'] ?? '',
      isProvisionalApproved: map['isProvisionalApproved'] ?? true,
      karmaAwarded: (map['karmaAwarded'] as num?)?.toInt() ?? 50,
      auditedAt: map['auditedAt'] != null
          ? DateTime.tryParse(map['auditedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      engineUsed: map['engineUsed'] ?? 'Gemini 1.5 Pro Vision',
    );
  }
}
