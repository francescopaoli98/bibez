import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../logica/pagamenti.dart';
import '../modelli/lavoro.dart';
import '../modelli/tipi.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/pillola_pagamento.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/pulsante_scelta.dart';
import '../widget/stile_lucido.dart';
import 'pagamenti.dart';

/// Scheda "Pagamento" di un progetto: stato, importo, scadenza e giorni
/// impiegati dal cliente a pagare.
class CartaPagamento extends StatelessWidget {
  const CartaPagamento({super.key, required this.lavoro});

  final Lavoro lavoro;

  /// Giorni scelti con i pulsanti rapidi della scadenza.
  static const _scorciatoie = [7, 15, 30];

  Future<DateTime?> _scegliData(
    BuildContext context,
    DateTime iniziale,
    String aiuto,
  ) {
    return showDatePicker(
      context: context,
      initialDate: iniziale,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: aiuto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;
    final adesso = dati.adesso();
    final incassato = lavoro.statoPagamento == StatoPagamento.incassato;
    final scadenza = lavoro.scadenza;
    final giorni = giorniPerPagare(lavoro);

    return CartaVetro(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Pagamento', style: tema.titleLarge),
                ),
              ),
              PillolaPagamento(lavoro: lavoro, adesso: adesso),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            euro(dati.importoDi(lavoro)),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          if (incassato && lavoro.dataIncasso != null)
            Text(
              'Incassato il ${dataLunga(lavoro.dataIncasso!)}'
              '${giorni == null ? '' : ' · pagato dopo $giorni ${giorni == 1 ? 'giorno' : 'giorni'}'}',
              style: tema.bodyMedium?.copyWith(
                color: ColoriLaguna.testoSecondario,
              ),
            ),
          const SizedBox(height: 12),
          if (incassato)
            PulsanteLucido(
              etichetta: 'Riporta a da incassare',
              icona: Icons.undo_rounded,
              onPressed: () => dati.riapriPagamento(lavoro),
            )
          else
            PulsanteLucido(
              etichetta: 'Segna incassato',
              icona: Icons.check_rounded,
              stile: StileLucido.verde,
              onPressed: () => segnaIncassatoConAnnulla(context, lavoro),
            ),
          if (!incassato) ...[
            const SizedBox(height: 14),
            Text(
              scadenza == null
                  ? 'Nessuna scadenza'
                  : 'Scadenza: ${dataLunga(scadenza)}',
              style: tema.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in _scorciatoie)
                  PulsanteScelta(
                    key: Key('scadenza-$n'),
                    etichetta: '$n giorni',
                    // Scelto se la scadenza è esattamente tra n giorni da oggi
                    selezionato:
                        scadenza != null && scadenza == scadenzaDopo(adesso, n),
                    onTap: () =>
                        dati.impostaScadenza(lavoro, scadenzaDopo(adesso, n)),
                  ),
                PulsanteScelta(
                  key: const Key('scadenza-data'),
                  etichetta: 'Scegli data',
                  selezionato: false,
                  onTap: () async {
                    final data = await _scegliData(
                      context,
                      scadenza ?? scadenzaDopo(adesso, 30),
                      'Scadenza del pagamento',
                    );
                    if (data != null) dati.impostaScadenza(lavoro, data);
                  },
                ),
                if (scadenza != null)
                  PulsanteScelta(
                    key: const Key('scadenza-nessuna'),
                    etichetta: 'Nessuna',
                    selezionato: false,
                    onTap: () => dati.impostaScadenza(lavoro, null),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          // Da quando si contano i giorni impiegati a pagare
          Row(
            children: [
              Expanded(
                child: Text(
                  'Richiesto il ${dataLunga(inizioPagamento(lavoro))}',
                  style: tema.bodyMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                  ),
                ),
              ),
              TextButton(
                key: const Key('richiesto-cambia'),
                onPressed: () async {
                  final data = await _scegliData(
                    context,
                    inizioPagamento(lavoro),
                    'Quando hai chiesto il pagamento',
                  );
                  if (data != null) dati.impostaRichiesta(lavoro, data);
                },
                child: const Text('Cambia'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
