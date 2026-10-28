import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../schermate/pagamenti.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import 'carta_vetro.dart';
import 'pulsante_lucido.dart';

/// "Da incassare 450 € · 2 lavori · 1 in ritardo" con il pulsante "Vedi".
/// Sta nella Home e in Clienti.
class RiquadroDaIncassare extends StatelessWidget {
  const RiquadroDaIncassare({super.key, required this.dati});

  final StatoDati dati;

  @override
  Widget build(BuildContext context) {
    final lavori = dati.lavoriDaIncassare.length;
    final ritardo = dati.numeroInRitardo;
    final tema = Theme.of(context).textTheme;

    final dettaglio = lavori == 0
        ? 'Tutto incassato'
        : [
            '$lavori ${lavori == 1 ? 'lavoro' : 'lavori'}',
            if (ritardo > 0) '$ritardo in ritardo',
          ].join(' · ');

    return CartaVetro(
      colori: const [Color(0xFFFFF6C4), Color(0xFFFFE98F)],
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Da incassare',
                  style: tema.labelMedium?.copyWith(
                    fontSize: 14,
                    color: ColoriLaguna.testoSecondario,
                  ),
                ),
                Text(
                  euro(dati.totaleDaIncassare),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  dettaglio,
                  style: tema.labelMedium?.copyWith(
                    fontSize: 14,
                    color: ritardo > 0
                        ? ColoriLaguna.negativo
                        : ColoriLaguna.testoSecondario,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (lavori > 0)
            PulsanteLucido(
              etichetta: 'Vedi',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PagamentiPagina(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
