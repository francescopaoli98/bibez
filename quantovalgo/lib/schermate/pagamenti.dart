import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../modelli/lavoro.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pillola_pagamento.dart';
import '../widget/riga_progetto.dart';
import '../widget/riquadro_da_incassare.dart';
import '../widget/sfera_lucida.dart';
import '../widget/stato_vuoto.dart';
import '../widget/stile_lucido.dart';
import 'progetto.dart';

/// Tutti i progetti ancora da incassare: prima i più in ritardo.
/// Da qui si segna "incassato" con un tocco.
class PagamentiPagina extends StatelessWidget {
  const PagamentiPagina({super.key});

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final lavori = dati.lavoriDaIncassare;

    return PaginaSecondaria(
      titolo: 'Da incassare',
      sottotitolo: 'Prima quelli in ritardo',
      figli: [
        RiquadroDaIncassare(dati: dati, apribile: false),
        const SizedBox(height: 12),
        if (lavori.isEmpty)
          const StatoVuoto(
            icona: Icons.check_circle_outline_rounded,
            titolo: 'Tutto incassato',
            testo: 'Non aspetti nessun pagamento.',
          )
        else
          for (final l in lavori) ...[
            _RigaPagamento(lavoro: l, dati: dati),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

/// Segna come incassato oggi e offre "Annulla" per un errore di tocco.
void segnaIncassatoConAnnulla(BuildContext context, Lavoro lavoro) {
  final dati = DatiScope.leggi(context);
  final messaggi = ScaffoldMessenger.of(context);
  dati.segnaIncassato(lavoro, dati.adesso());
  messaggi
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('"${lavoro.nome}" segnato come incassato'),
        action: SnackBarAction(
          label: 'Annulla',
          onPressed: () =>
              dati.riapriPagamento(dati.lavoro(lavoro.id) ?? lavoro),
        ),
      ),
    );
}

class _RigaPagamento extends StatelessWidget {
  const _RigaPagamento({required this.lavoro, required this.dati});

  final Lavoro lavoro;
  final StatoDati dati;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final cliente = dati.cliente(lavoro.clienteId)?.nome;
    final scadenza = lavoro.scadenza;
    final dettaglio = [
      ?cliente,
      scadenza == null ? 'senza scadenza' : 'scade il ${dataLunga(scadenza)}',
    ].join(' · ');

    return CartaVetro(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProgettoPagina(lavoroId: lavoro.id),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lavoro.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.titleMedium,
                ),
                Text(
                  dettaglio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.labelMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                PillolaPagamento(lavoro: lavoro, adesso: dati.adesso()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                euro(dati.importoDi(lavoro)),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: coloreImporto(dati.importoDi(lavoro)),
                ),
              ),
              const SizedBox(height: 6),
              SferaLucida(
                icona: Icons.check_rounded,
                etichetta: 'Segna incassato ${lavoro.nome}',
                stile: StileLucido.verde,
                onPressed: () => segnaIncassatoConAnnulla(context, lavoro),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
