import 'package:flutter/material.dart';

import '../tema/colori.dart';

/// Casella trasparente dentro il riquadro grande (Home e Progetto).
class DatoHero extends StatelessWidget {
  const DatoHero({super.key, required this.etichetta, required this.valore});

  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etichetta,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ColoriLaguna.testoChiaro,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valore,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
