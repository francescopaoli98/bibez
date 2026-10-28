import 'package:flutter/material.dart';

import '../logica/mesi.dart';
import 'sfera_lucida.dart';

/// ‹ ottobre 2026 › : due frecce e il mese in mezzo.
class SelettoreMese extends StatelessWidget {
  const SelettoreMese({super.key, required this.mese, required this.onCambia});

  /// Primo giorno del mese mostrato.
  final DateTime mese;
  final ValueChanged<DateTime> onCambia;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SferaLucida(
          icona: Icons.chevron_left_rounded,
          etichetta: 'Mese precedente',
          onPressed: () => onCambia(mesePrecedente(mese)),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              nomeMeseAnno(mese),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        SferaLucida(
          icona: Icons.chevron_right_rounded,
          etichetta: 'Mese successivo',
          onPressed: () => onCambia(meseSuccessivo(mese)),
        ),
      ],
    );
  }
}
