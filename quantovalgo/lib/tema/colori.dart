import 'package:flutter/material.dart';

/// Palette del tema "Laguna", presa dal mockup.
abstract final class ColoriLaguna {
  // Testi
  static const testo = Color(0xFF032A3B);
  static const testoSecondario = Color(0xFF1F4A5A);
  static const testoChiaro = Color(0xFFE3F9FF);

  // Sfondo a sfumatura verticale
  static const sfondo = [
    Color(0xFF4CC6E6),
    Color(0xFF8FE6EC),
    Color(0xFFD5F7F1),
    Color(0xFFA5E4C6),
  ];
  static const sfondoStop = [0.0, 0.26, 0.58, 1.0];

  // Onde in basso
  static const ondaBianca = Color(0x80FFFFFF);
  static const ondaTurchese = Color(0xFF35C0C8);
  static const ondaVerde = Color(0xFF5DB43C);

  // Hero (Home, Progetto, Obiettivo)
  static const heroInizio = Color(0xFF0A4C86);
  static const heroFine = Color(0xFF0A7C8A);
  static const cifraHero = Color(0xFFE6FF9A);

  // Saldo positivo / negativo
  static const positivo = Color(0xFF0F6B2E);
  static const negativo = Color(0xFFA8301A);
}
