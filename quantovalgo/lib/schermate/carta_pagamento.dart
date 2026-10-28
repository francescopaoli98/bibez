import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../logica/pagamenti.dart';
import '../modelli/lavoro.dart';
import '../modelli/tipi.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pillola_pagamento.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/pulsante_scelta.dart';
import '../widget/stile_lucido.dart';
import 'pagamenti.dart';

/// Scheda "Pagamento" di un progetto: stato, importo e un'azione sola
/// ("Segna incassato"). La scadenza si cambia toccando la sua riga.
class CartaPagamento extends StatelessWidget {
  const CartaPagamento({super.key, required this.lavoro});

  final Lavoro lavoro;

  static Future<DateTime?> _scegliData(
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
    final grigio = tema.bodyMedium?.copyWith(
      color: ColoriLaguna.testoSecondario,
    );

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
              style: grigio,
            ),
          const SizedBox(height: 12),
          if (incassato)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => dati.riapriPagamento(lavoro),
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Riporta a da incassare'),
              ),
            )
          else ...[
            PulsanteLucido(
              etichetta: 'Segna incassato',
              icona: Icons.check_rounded,
              stile: StileLucido.verde,
              onPressed: () => segnaIncassatoConAnnulla(context, lavoro),
            ),
            const SizedBox(height: 4),
            // Una riga sola: toccandola si sceglie la scadenza
            InkWell(
              key: const Key('scadenza-riga'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => mostraFoglio<void>(
                context,
                titolo: 'Scadenza del pagamento',
                costruttore: (_) => _ScelteScadenza(lavoroId: lavoro.id),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_rounded,
                      color: ColoriLaguna.testoSecondario,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        scadenza == null
                            ? 'Nessuna scadenza'
                            : 'Scadenza: ${dataLunga(scadenza)}',
                        style: tema.titleMedium,
                      ),
                    ),
                    Text(
                      'Cambia',
                      style: tema.labelLarge?.copyWith(
                        color: const Color(0xFF2A6A92),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Da quando si contano i giorni impiegati a pagare
          Row(
            children: [
              Expanded(
                child: Text(
                  'Richiesto il ${dataLunga(inizioPagamento(lavoro))}',
                  style: grigio,
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

/// Dentro il foglio: scorciatoie per la scadenza, data a scelta o nessuna.
class _ScelteScadenza extends StatelessWidget {
  const _ScelteScadenza({required this.lavoroId});

  final String lavoroId;

  /// Giorni scelti con i pulsanti rapidi della scadenza.
  static const _scorciatoie = [7, 15, 30];

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.leggi(context);
    final adesso = dati.adesso();
    final lavoro = dati.lavoro(lavoroId);
    if (lavoro == null) return const SizedBox.shrink();
    final scadenza = lavoro.scadenza;

    // Scelta fatta: si salva e il foglio si chiude
    void scegli(DateTime? data) {
      dati.impostaScadenza(lavoro, data);
      Navigator.of(context).pop();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final n in _scorciatoie)
          PulsanteScelta(
            key: Key('scadenza-$n'),
            etichetta: 'Tra $n giorni',
            selezionato:
                scadenza != null && scadenza == scadenzaDopo(adesso, n),
            onTap: () => scegli(scadenzaDopo(adesso, n)),
          ),
        PulsanteScelta(
          key: const Key('scadenza-data'),
          etichetta: 'Scegli data',
          selezionato: false,
          onTap: () async {
            final data = await CartaPagamento._scegliData(
              context,
              scadenza ?? scadenzaDopo(adesso, 30),
              'Scadenza del pagamento',
            );
            if (data != null && context.mounted) scegli(data);
          },
        ),
        if (scadenza != null)
          PulsanteScelta(
            key: const Key('scadenza-nessuna'),
            etichetta: 'Nessuna scadenza',
            selezionato: false,
            onTap: () => scegli(null),
          ),
      ],
    );
  }
}
