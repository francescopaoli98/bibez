import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../logica/obiettivo.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/dato_hero.dart';
import '../widget/hero_laguna.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pillola_lucida.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/selettore_mese.dart';
import '../widget/stile_lucido.dart';
import 'impostazioni.dart';

/// Obiettivo mensile (netto), punto di pareggio, tariffa minima oraria e
/// netto dopo le tasse. Si guarda mese per mese, come la Home.
class ObiettivoPagina extends StatefulWidget {
  const ObiettivoPagina({super.key});

  @override
  State<ObiettivoPagina> createState() => _ObiettivoPaginaState();
}

class _ObiettivoPaginaState extends State<ObiettivoPagina> {
  /// Mese mostrato; vuoto = il mese corrente.
  DateTime? _mese;

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final corrente = primoDelMese(dati.adesso());
    final mese = _mese ?? corrente;
    final piano = dati.pianoObiettivo(mese);

    return PaginaSecondaria(
      titolo: 'Obiettivo',
      sottotitolo: 'Quanto vuoi guadagnare, netto, al mese',
      figli: [
        SelettoreMese(
          mese: mese,
          ultimo: corrente,
          onCambia: (m) => setState(() => _mese = m == corrente ? null : m),
        ),
        const SizedBox(height: 12),
        _HeroObiettivo(piano: piano),
        const SizedBox(height: 12),
        PulsanteLucido(
          key: const Key('cambia-obiettivo'),
          etichetta: piano.haObiettivo
              ? 'Cambia obiettivo'
              : 'Imposta obiettivo',
          icona: Icons.flag_rounded,
          onPressed: () => modificaObiettivo(context),
        ),
        const SizedBox(height: 16),
        _CartaPareggio(piano: piano),
        const SizedBox(height: 12),
        _CartaTariffa(piano: piano),
      ],
    );
  }
}

/// Riquadro grande: quanto dell'obiettivo netto è raggiunto.
class _HeroObiettivo extends StatelessWidget {
  const _HeroObiettivo({required this.piano});

  final PianoObiettivo piano;

  @override
  Widget build(BuildContext context) {
    final avanzamento = piano.avanzamento;
    final raggiunto = avanzamento != null && avanzamento >= 1;

    return HeroLaguna(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Avanzamento obiettivo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColoriLaguna.testoChiaro,
                ),
              ),
              if (raggiunto)
                const PillolaLucida(
                  testo: 'Raggiunto',
                  stile: StileLucido.verde,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            avanzamento == null ? '—' : '${(avanzamento * 100).round()}%',
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
          const SizedBox(height: 4),
          Text(
            avanzamento == null
                ? "Imposta l'obiettivo per vedere a che punto sei"
                : 'Netto ${euro(piano.nettoDopoTasse)} su ${euro(piano.obiettivoNetto)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ColoriLaguna.testoChiaro,
            ),
          ),
          if (avanzamento != null) ...[
            const SizedBox(height: 10),
            Semantics(
              label: 'Avanzamento ${(avanzamento * 100).round()} per cento',
              excludeSemantics: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: avanzamento.clamp(0, 1).toDouble(),
                  minHeight: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(
                    ColoriLaguna.cifraHero,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DatoHero(
                  etichetta: 'Saldo',
                  valore: euro(piano.saldo, conSegno: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DatoHero(
                  etichetta: 'Tasse ${percentuale(piano.tasse)}',
                  valore: euro(piano.importoTasse),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DatoHero(
                  etichetta: 'Netto',
                  valore: euro(piano.nettoDopoTasse, conSegno: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Punto di pareggio: i costi del mese, e quanto manca per coprirli.
class _CartaPareggio extends StatelessWidget {
  const _CartaPareggio({required this.piano});

  final PianoObiettivo piano;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final coperto = piano.manca == 0;

    return CartaVetro(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('Punto di pareggio', style: tema.titleLarge),
          ),
          Text(
            euro(piano.pareggio),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            piano.pareggio == 0
                ? 'Nessun costo questo mese.'
                : coperto
                ? 'Costi coperti: sei sopra il pareggio di '
                      '${euro(piano.saldoMese.incassato - piano.pareggio)}.'
                : 'Ti mancano ${euro(piano.manca)} di incassi per non andare in negativo.',
            style: tema.bodyMedium?.copyWith(
              color: coperto ? ColoriLaguna.positivo : ColoriLaguna.negativo,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Sono i costi del mese: condivisi e diretti dei progetti incassati.',
            style: tema.bodyMedium?.copyWith(
              color: ColoriLaguna.testoSecondario,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tariffa minima oraria per arrivare all'obiettivo netto.
class _CartaTariffa extends StatelessWidget {
  const _CartaTariffa({required this.piano});

  final PianoObiettivo piano;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final tariffa = piano.tariffaMinima;
    final grigio = tema.bodyMedium?.copyWith(
      color: ColoriLaguna.testoSecondario,
    );

    return CartaVetro(
      colori: const [Color(0xFFFFF6C4), Color(0xFFFFE98F)],
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('Tariffa minima oraria', style: tema.titleLarge),
          ),
          Text(
            tariffa == null ? '—' : '${euro(tariffa)}/h',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          if (!piano.haObiettivo)
            Text("Imposta l'obiettivo mensile per calcolarla.", style: grigio)
          else if (tariffa == null)
            Text(
              'Registra le ore del mese (cronometro o a mano) per calcolarla.',
              style: grigio,
            )
          else
            Text(
              'Per ${euro(piano.obiettivoNetto)} netti servono '
              '${euro(piano.saldoNecessario)} di saldo (tasse ${percentuale(piano.tasse)}) '
              'più ${euro(piano.pareggio)} di costi: '
              '${euro(piano.incassoNecessario)} da incassare in '
              '${ore(piano.oreMese)}.',
              style: grigio,
            ),
        ],
      ),
    );
  }
}
