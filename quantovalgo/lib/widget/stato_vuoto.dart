import 'package:flutter/material.dart';

import '../tema/colori.dart';
import 'carta_vetro.dart';

/// Messaggio mostrato dove non ci sono ancora dati.
class StatoVuoto extends StatelessWidget {
  const StatoVuoto({
    super.key,
    required this.icona,
    required this.titolo,
    required this.testo,
  });

  final IconData icona;
  final String titolo;
  final String testo;

  @override
  Widget build(BuildContext context) {
    return CartaVetro(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icona, size: 44, color: ColoriLaguna.heroFine),
          const SizedBox(height: 12),
          Text(
            titolo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            testo,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: ColoriLaguna.testoSecondario),
          ),
        ],
      ),
    );
  }
}
