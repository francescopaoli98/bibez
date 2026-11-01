import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../logica/pagamenti.dart';
import '../modelli/lavoro.dart';
import '../modelli/tipi.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/hero_laguna.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pillola_pagamento.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/riga_progetto.dart';
import '../widget/stile_lucido.dart';
import 'carta_pagamento.dart';
import 'cronometro_azioni.dart';
import 'pagamenti.dart';
import 'progetto.dart';

/// Apre un lavoro: la pagina semplice, oppure (per "A giornata") il calendario
/// delle giornate. Da qui parte ogni tocco su un lavoro.
void apriLavoro(BuildContext context, Lavoro lavoro) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => lavoro.tipo == TipoLavoro.aGiornata
          ? ProgettoPagina(lavoroId: lavoro.id)
          : LavoroPagina(lavoroId: lavoro.id),
    ),
  );
}

/// Un lavoro in una sola vista: quanto ti devono, un pulsante per dire "mi
/// hanno pagato", le ore e quanto ti resta. Il resto sta in "Tutti i dettagli".
class LavoroPagina extends StatelessWidget {
  const LavoroPagina({super.key, required this.lavoroId});

  final String lavoroId;

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final lavoro = dati.lavoro(lavoroId);

    // Il lavoro è stato eliminato (dai dettagli): questa pagina non ha più
    // niente da mostrare e si chiude da sola.
    if (lavoro == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const PaginaSecondaria(titolo: '', figli: []);
    }

    final tema = Theme.of(context).textTheme;
    final adesso = dati.adesso();
    final incassato = lavoro.statoPagamento == StatoPagamento.incassato;
    final cliente = dati.cliente(lavoro.clienteId)?.nome;
    final numeri = dati.riepilogoDi(lavoro.id);
    final ritardo = giorniRitardo(lavoro, adesso);
    final scadenza = lavoro.scadenza;
    final giorni = giorniPerPagare(lavoro);

    final String riga;
    if (incassato) {
      riga =
          'Incassato il ${dataLunga(lavoro.dataIncasso ?? adesso)}'
          '${giorni == null ? '' : ' · pagato dopo $giorni ${giorni == 1 ? 'giorno' : 'giorni'}'}';
    } else if (scadenza == null) {
      riga = 'Senza scadenza';
    } else {
      riga = '${ritardo > 0 ? 'Scadeva' : 'Scade'} il ${dataLunga(scadenza)}';
    }

    return PaginaSecondaria(
      titolo: lavoro.nome,
      sottotitolo: [
        if (cliente != null) 'per $cliente',
        lavoro.tipo.etichetta,
      ].join(' · '),
      figli: [
        HeroLaguna(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    incassato ? 'Incassato' : 'Ti devono',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ColoriLaguna.testoChiaro,
                    ),
                  ),
                  if (incassato || ritardo > 0)
                    PillolaPagamento(lavoro: lavoro, adesso: adesso),
                ],
              ),
              Text(
                euro(dati.importoDi(lavoro)),
                style: const TextStyle(
                  fontSize: 64,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  color: ColoriLaguna.cifraHero,
                ),
              ),
              Text(
                riga,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ColoriLaguna.testoChiaro,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (incassato)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => dati.riapriPagamento(lavoro),
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Riporta a da incassare'),
            ),
          )
        else
          PulsanteLucido(
            etichetta: 'Mi hanno pagato',
            icona: Icons.check_rounded,
            stile: StileLucido.verde,
            altezza: 66,
            onPressed: () => segnaIncassatoConAnnulla(context, lavoro),
          ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CartaOre(lavoro: lavoro, dati: dati),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CartaVetro(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ti resta',
                        style: tema.labelMedium?.copyWith(
                          fontSize: 14,
                          color: ColoriLaguna.testoSecondario,
                        ),
                      ),
                      Text(
                        euro(numeri.utile, conSegno: true),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: coloreImporto(numeri.utile),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        numeri.guadagnoOra == null
                            ? 'senza ore registrate'
                            : 'circa ${euro(numeri.guadagnoOra!.roundToDouble())} all\'ora',
                        style: tema.labelMedium?.copyWith(
                          fontSize: 14,
                          color: ColoriLaguna.testoSecondario,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CartaVetro(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  if (!incassato) ...[
                    _Riga(
                      chiave: const Key('cambia-scadenza'),
                      titolo: 'Cambia la scadenza',
                      onTap: () => cambiaScadenza(context, lavoro.id),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                  _Riga(
                    chiave: const Key('tutti-i-dettagli'),
                    titolo: 'Tutti i dettagli',
                    sotto: 'Parti, ore, prezzo pieno, sconti, spese',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProgettoPagina(lavoroId: lavoro.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Una riga della lista in fondo: titolo, riga piccola e freccia.
class _Riga extends StatelessWidget {
  const _Riga({
    required this.chiave,
    required this.titolo,
    required this.onTap,
    this.sotto,
  });

  final Key chiave;
  final String titolo;
  final String? sotto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return InkWell(
      key: chiave,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titolo, style: tema.titleMedium),
                  if (sotto != null)
                    Text(
                      sotto!,
                      style: tema.bodyMedium?.copyWith(
                        color: ColoriLaguna.testoSecondario,
                      ),
                    ),
                ],
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

/// Ore lavorate e un pulsante per avviare o fermare il cronometro.
class _CartaOre extends StatelessWidget {
  const _CartaOre({required this.lavoro, required this.dati});

  final Lavoro lavoro;
  final StatoDati dati;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final minuti = (dati.riepilogoDi(lavoro.id).ore * 60).round();
    final parti = dati.sottoprogettiDi(lavoro.id);
    final acceso = dati.sessioneInCorso;
    final qui = acceso != null && acceso.lavoroId == lavoro.id;

    void dettagli() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProgettoPagina(lavoroId: lavoro.id),
      ),
    );

    final (etichetta, icona, azione) = qui
        ? ('Ferma', Icons.stop_rounded, () => fermaCronometro(context, dati))
        : parti.length == 1
        ? (
            'Avvia',
            Icons.play_arrow_rounded,
            () => avviaCronometro(context, dati, parti.first),
          )
        : (
            parti.isEmpty ? 'Aggiungi' : 'Scegli la parte',
            Icons.play_arrow_rounded,
            dettagli,
          );

    return CartaVetro(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ore lavorate',
            style: tema.labelMedium?.copyWith(
              fontSize: 14,
              color: ColoriLaguna.testoSecondario,
            ),
          ),
          Text(
            minuti == 0 ? '0 h' : durata(minuti),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          PulsanteLucido(
            etichetta: etichetta,
            icona: icona,
            altezza: 44,
            stile: qui ? StileLucido.rosso : StileLucido.blu,
            onPressed: azione,
          ),
        ],
      ),
    );
  }
}
