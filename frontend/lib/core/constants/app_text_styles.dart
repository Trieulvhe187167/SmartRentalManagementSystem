import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system based on Lumina Resident design tokens
/// Font family: Inter across all sizes
class AppTextStyles {
  AppTextStyles._();

  // ─── Headline ────────────────────────────────────────────
  static TextStyle get headlineLg => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.02 * 32,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
      );

  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
      );

  static TextStyle get headlineSm => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      );

  // ─── Title ───────────────────────────────────────────────
  static TextStyle get titleLg => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
      );

  static TextStyle get titleMd => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
      );

  static TextStyle get titleSm => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
      );

  // ─── Body ────────────────────────────────────────────────
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
      );

  // ─── Label ───────────────────────────────────────────────
  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 16 / 11,
        letterSpacing: 0.05 * 11,
      );

  // ─── Display (for amounts/numbers) ───────────────────────
  static TextStyle get displayMd => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 44 / 36,
        letterSpacing: -0.02 * 36,
      );

  static TextStyle get displaySm => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
      );
}
