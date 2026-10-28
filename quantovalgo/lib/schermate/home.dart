import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../logica/saldo.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/dato_hero.dart';
import '../widget/hero_laguna.dart';
import '../widget/logo_sole.dart';
import '../widget/pillola_lucida.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/riga_progetto.dart';
import '../widget/riquadro_da_incassare.dart';
import '../widget/selettore_mese.dart';
import '../widget/sfera_lucida.dart';
import '../widget/stile_lucido.dart';
import 'clienti.dart';
import 'impostazioni.dart';
import 'obiettivo.dart';
import 'scheda.dart';

/// Home: saldo del mese (incassi meno costi) con le frecce per i mesi passati,
/// guadagno all'ora, sconti regalati, quanto resta da incassare e i progetti.
class HomePagina extends StatefulWidget {
  const HomePagina({super.key});

  @override
  State<HomePagina> createState() => _HomePaginaState();
}

class _HomePaginaState extends State<HomePagina> {
  /// Mese mostrato; vuoto = il mese corrente (segue il passare del tempo).
  DateTime? _mese;

  void _apri(Widget pagina) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina));
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final corrente = primoDelMese(dati.adesso());
    final mese = _mese ?? corrente;
    final saldo = dati.saldoDelMese(mese);
    final tema = Theme.of(context).textTheme;

    return Scheda(
      titolo: 'QuantoValgo',
      // Pallino sole accanto al nome, come nel mockup
      sinistra: const LogoSole(),
      destra: SferaLucida(
        icona: Icons.settings_rounded,
        etichetta: 'Impostazioni',
        onPressed: () => _apri(const ImpostazioniPagina()),
      ),
      figli: [
        // Il mese corrente è l'ultimo: non si va nel futuro
        SelettoreMese(
          mese: mese,
          ultimo: corrente,
          onCambia: (m) => setState(() => _mese = m == corrente ? null : m),
        ),
        const SizedBox(height: 12),
        _HeroSaldo(saldo: saldo.saldo, dati: saldo),
        if (saldo.regalato > 0) ...[
          const SizedBox(height: 12),
          _RigaRegali(regalato: saldo.regalato, mese: mese),
        ],
        const SizedBox(height: 12),
        RiquadroDaIncassare(dati: dati),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PulsanteLucido(
                etichetta: 'Clienti',
                icona: Icons.people_alt_rounded,
                onPressed: () => _apri(const ClientiPagina()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PulsanteLucido(
                etichetta: 'Obiettivo',
                icona: Icons.flag_rounded,
                onPressed: () => _apri(const ObiettivoPagina()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text('Progetti', style: tema.titleLarge),
        ),
        const SizedBox(height: 8),
        ElencoProgetti(dati: dati),
      ],
    );
  }
}

/// Riquadro grande: saldo del mese, se è in positivo o in negativo, e sotto
/// incassato, costi e guadagno all'ora.
class _HeroSaldo extends StatelessWidget {
  const _HeroSaldo({required this.saldo, required this.dati});

  final double saldo;
  final SaldoMese dati;

  @override
  Widget build(BuildContext context) {
    final (testoStato, stileStato) = saldo > 0
        ? ('In positivo', StileLucido.verde)
        : saldo < 0
        ? ('In negativo', StileLucido.rosso)
        : ('In pari', StileLucido.blu);
    final ora = dati.guadagnoOra;

    return HeroLaguna(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo del mese',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColoriLaguna.testoChiaro,
                ),
              ),
              PillolaLucida(testo: testoStato, stile: stileStato),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            euro(saldo, conSegno: true),
            style: const TextStyle(
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: ColoriLaguna.cifraHero,
              shadows: [
                Shadow(
                  color: Color(0x73002838),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DatoHero(
                  etichetta: 'Incassato',
                  valore: euro(dati.incassato),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DatoHero(etichetta: 'Costi', valore: euro(dati.costi)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DatoHero(
                  etichetta: "All'ora",
                  valore: ora == null ? '—' : '${euro(ora)}/h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Sconti regalati in ottobre: 300 €" (progetti creati in quel mese).
class _RigaRegali extends StatelessWidget {
  const _RigaRegali({required this.regalato, required this.mese});

  final double regalato;
  final DateTime mese;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0C36A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Color(0xFF6B2A10)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sconti regalati in ${nomeMese(mese)}: ${euro(regalato)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B2A10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
