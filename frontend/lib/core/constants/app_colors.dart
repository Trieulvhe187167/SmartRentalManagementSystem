import 'package:flutter/material.dart';

/// Design tokens based on Lumina Resident design system (Stitch project 994744061219810473)
/// Color mode: LIGHT · Primary: #2563EB · Font: Inter
class AppColors {
  AppColors._();

  // ─── Primary Blue ─────────────────────────────────────────
  static const Color primary = Color(0xFF004AC6);
  static const Color primaryContainer = Color(0xFF2563EB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFEEEFFF);
  static const Color primaryFixed = Color(0xFFDBE1FF);
  static const Color primaryFixedDim = Color(0xFFB4C5FF);
  static const Color onPrimaryFixed = Color(0xFF00174B);
  static const Color onPrimaryFixedVariant = Color(0xFF003EA8);
  static const Color inversePrimary = Color(0xFFB4C5FF);

  // ─── Secondary Emerald ────────────────────────────────────
  static const Color secondary = Color(0xFF006C4A);
  static const Color secondaryContainer = Color(0xFF82F5C1);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF00714E);
  static const Color secondaryFixed = Color(0xFF85F8C4);
  static const Color secondaryFixedDim = Color(0xFF68DBA9);

  // ─── Tertiary Amber ───────────────────────────────────────
  static const Color tertiary = Color(0xFF784B00);
  static const Color tertiaryContainer = Color(0xFF996100);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFEEDD);

  // ─── Error ───────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ─── Surface / Background ────────────────────────────────
  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF0B1C30);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFCBDBF5);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF434655);
  static const Color surfaceVariant = Color(0xFFD3E4FE);
  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);

  // Surface containers
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);

  // ─── Outline ─────────────────────────────────────────────
  static const Color outline = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C6D7);

  // ─── Status colors (functional) ──────────────────────────
  static const Color success = Color(0xFF006C4A);          // Green - Paid, Available
  static const Color successLight = Color(0xFFE8FBF3);
  static const Color warning = Color(0xFFF59E0B);          // Amber - Pending, Due soon
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color danger = Color(0xFFBA1A1A);           // Red - Overdue, Expired
  static const Color dangerLight = Color(0xFFFFDAD6);
  static const Color neutral = Color(0xFF64748B);          // Gray - Inactive
  static const Color neutralLight = Color(0xFFF1F5F9);

  // ─── Status chip colors ──────────────────────────────────
  // Invoice / Payment status
  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'ACTIVE':
      case 'RESOLVED':
        return success;
      case 'ISSUED':
      case 'PENDING':
      case 'OPEN':
      case 'IN_PROGRESS':
      case 'RECEIVED':
        return primaryContainer;
      case 'OVERDUE':
      case 'REJECTED':
      case 'CANCELLED':
      case 'EXPIRED':
        return danger;
      case 'DRAFT':
      case 'PARTIALLY_PAID':
      case 'PENDING_APPROVAL':
        return warning;
      case 'AVAILABLE':
        return success;
      case 'OCCUPIED':
        return primaryContainer;
      default:
        return neutral;
    }
  }

  static Color statusLightColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'ACTIVE':
      case 'RESOLVED':
      case 'AVAILABLE':
        return successLight;
      case 'OVERDUE':
      case 'REJECTED':
      case 'CANCELLED':
      case 'EXPIRED':
        return dangerLight;
      case 'DRAFT':
      case 'PARTIALLY_PAID':
      case 'PENDING_APPROVAL':
        return warningLight;
      case 'ISSUED':
      case 'PENDING':
      case 'OPEN':
      case 'IN_PROGRESS':
      case 'RECEIVED':
      case 'OCCUPIED':
        return primaryFixed;
      default:
        return neutralLight;
    }
  }
}
