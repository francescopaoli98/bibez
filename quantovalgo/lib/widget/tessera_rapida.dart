import 'package:flutter/material.dart';

import '../tema/colori.dart';
import 'carta_vetro.dart';
import 'sfera_lucida.dart';

/// Scorciatoia leggera: sferetta con icona e nome, tutta toccabile.
/// Sta nella Home per Clienti e Obiettivo (meno rumore dei pulsanti grandi).
class TesseraRapida extends StatelessWidget {
  const TesseraRapida({
    super.key,
    required this.icona,
    required this.etichetta,
    required this.onTap,
  });

  final IconData icona;
  final String etichetta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: etichetta,
      excludeSemantics: true,
      child: CartaVetro(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: onTap,
        child: Row(
          children: [
            IconaSfera(icona: icona, dimensione: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                etichetta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ColoriLaguna.testo,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: ColoriLaguna.testoSecondario,
            ),
          ],
        ),
      ),
    );
  }
}
