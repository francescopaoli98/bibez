import 'package:flutter/material.dart';

import 'colori.dart';

/// Tema unico dell'app: Laguna, con carattere Nunito.
ThemeData creaTemaLaguna() {
  final schema = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F72A8),
    brightness: Brightness.light,
  ).copyWith(
    onSurface: ColoriLaguna.testo,
    onSurfaceVariant: ColoriLaguna.testoSecondario,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: schema,
    fontFamily: 'Nunito',
    // Lo sfondo lo disegna SfondoLaguna, quindi lo Scaffold è trasparente.
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: Typography.blackMountainView
        .apply(
          fontFamily: 'Nunito',
          bodyColor: ColoriLaguna.testo,
          displayColor: ColoriLaguna.testo,
        )
        .copyWith(
          // Titoli grandi e secchi, testo mai sotto i 13 px.
          headlineMedium: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          labelMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
  );
}
