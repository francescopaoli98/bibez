import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../schermate/pagamenti.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import 'carta_vetro.dart';

/// "Da incassare 450 € · 2 lavori · 1 in ritardo": tutta la scheda si tocca e
/// porta alla lista. Sta nella Home e in Clienti.
/// Con [apribile] falso (dentro la lista stessa) non è toccabile.
class RiquadroDaIncassare extends StatelessWidget {
  const RiquadroDaIncassare({
    super.key,
    required this.dati,
    this.apribile = true,
  });

  final StatoDati dati;
  final bool apribile;

  @override
  Widget build(BuildContext context) {
    final lavori = dati.lavoriDaIncassare.length;
    final ritardo = dati.numeroInRitardo;
    final tema = Theme.of(context).textTheme;
    final tocca = apribile && lavori > 0;

    final dettaglio = lavori == 0
        ? 'Tutto incassato'
        : [
            '$lavori ${lavori == 1 ? 'lavoro' : 'lavori'}',
            if (ritardo > 0) '$ritardo in ritardo',
          ].join(' · ');

    return CartaVetro(
      colori: const [Color(0xFFFFF6C4), Color(0xFFFFE98F)],
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      onTap: tocca
          ? () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PagamentiPagina()),
            )
          : null,
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
                    fontSize: 26,
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
          if (tocca) ...[
            const Text(
              'Vedi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ],
      ),
    );
  }
}
