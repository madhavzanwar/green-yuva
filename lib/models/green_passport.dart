import 'package:flutter/material.dart';

class GreenPassportActionRecord {
  final String title;
  final String category; // 'YuvaSwap', 'GreenRush', 'Stewardship', 'Clean Air'
  final String impactMetric; // e.g. '+2.8 kg CO2e avoided'
  final DateTime timestamp;
  final String verificationType; // 'Sub-50m GPS & AI Vision', 'Peer Handover'
  final IconData icon;

  const GreenPassportActionRecord({
    required this.title,
    required this.category,
    required this.impactMetric,
    required this.timestamp,
    required this.verificationType,
    required this.icon,
  });
}

class GreenPassport {
  final String userId;
  final String studentName;
  final String campusName;
  final String studentCode;
  final int totalKarma;
  final int verifiedActionsCount;
  final double wasteDivertedKg;
  final double co2MitigatedKg;
  final double methaneAvoidedGrams;
  final int treesNurtured;
  final double treeSurvivalRatePct;
  final int cleanAirHours;
  final int canteenPerksRedeemed;
  final int naacScore;
  final String naacGrade;
  final String verificationHash;
  final DateTime issuedAt;
  final String verificationUrl;
  final List<GreenPassportActionRecord> recentLedger;

  const GreenPassport({
    required this.userId,
    required this.studentName,
    required this.campusName,
    required this.studentCode,
    required this.totalKarma,
    required this.verifiedActionsCount,
    required this.wasteDivertedKg,
    required this.co2MitigatedKg,
    required this.methaneAvoidedGrams,
    required this.treesNurtured,
    required this.treeSurvivalRatePct,
    required this.cleanAirHours,
    required this.canteenPerksRedeemed,
    required this.naacScore,
    required this.naacGrade,
    required this.verificationHash,
    required this.issuedAt,
    required this.verificationUrl,
    required this.recentLedger,
  });
}
