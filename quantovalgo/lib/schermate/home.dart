import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logica/apprendimento.dart';
import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../logica/pagamenti.dart';
import '../logica/saldo.dart';
import '../modelli/lavoro.dart';
import '../servizi/servizi_app.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/effetto_morbido.dart';
import '../widget/foglio_laguna.dart';
import '../widget/sfera_lucida.dart';
import '../widget/stile_lucido.dart';
import 'foglio_forbice.dart';
import 'lavoro.dart';
import 'menu.dart';
import 'obiettivo.dart';
import 'pagamenti.dart';

/// Home: una sola cifra grande dentro un anello che si riempie verso
/// l'obiettivo, e sotto chi ti deve dei soldi. Tutto il resto sta in "Altro".
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

  /// Foglio con gli ultimi 12 mesi, per tornare indietro nel tempo.
  Future<void> _scegliMese(DateTime corrente, DateTime scelto) async {
    final mesi = [
      for (var i = 0; i < 12; i++) DateTime(corrente.year, corrente.month - i),
    ];
    final nuovo = await mostraFoglio<DateTime>(
      context,
      titolo: 'Che mese vuoi vedere?',
      costruttore: (contesto) => Column(
        children: [
          for (final m in mesi)
            InkWell(
              key: Key('mese-${m.year}-${m.month}'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(contesto).pop(m),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        nomeMeseAnno(m),
                        style: Theme.of(contesto).textTheme.titleMedium,
                      ),
                    ),
                    if (m == scelto)
                      const Icon(
                        Icons.check_rounded,
                        color: ColoriLaguna.positivo,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (nuovo != null && mounted) {
      setState(() => _mese = nuovo == corrente ? null : nuovo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final corrente = primoDelMese(dati.adesso());
    final mese = _mese ?? corrente;
    final saldo = dati.saldoDelMese(mese);
    final piano = dati.pianoObiettivo(mese);
    final tema = Theme.of(context).textTheme;
    final nome = (ServiziApp.di(context).accesso.utenteCorrente?.nome ?? '')
        .trim()
        .split(' ')
        .first;

    return SafeArea(
      bottom: false,
      child: ListView(
        // In basso resta posto per il pulsante verde che galleggia
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome.isEmpty ? 'Ciao' : 'Ciao $nome',
                      style: tema.titleMedium?.copyWith(
                        color: ColoriLaguna.testoSecondario,
                      ),
                    ),
                    InkWell(
                      key: const Key('scegli-mese'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _scegliMese(corrente, mese),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nomeMeseAnno(mese),
                              style: tema.headlineMedium,
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SferaLucida(
                icona: Icons.grid_view_rounded,
                etichetta: 'Altro',
                dimensione: 48,
                onPressed: () => _apri(const AltroPagina()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: _AnelloMese(
              saldo: saldo.saldo,
              avanzamento: piano.avanzamento,
              onTap: () => _apri(const ObiettivoPagina()),
            ),
          ),
          const SizedBox(height: 14),
          _ChipSoldi(saldo: saldo),
          const SizedBox(height: 16),
          _TiDevono(dati: dati),
          // Avviso: incassi molto più (o meno) del prezzo di mercato
          for (final c in dati.correzioniDaAvvisare) ...[
            const SizedBox(height: 12),
            _AvvisoScarto(correzione: c),
          ],
        ],
      ),
    );
  }
}

/// Il disco blu con l'anello: quanto ti resta e a che punto sei con l'obiettivo.
class _AnelloMese extends StatelessWidget {
  const _AnelloMese({
    required this.saldo,
    required this.avanzamento,
    required this.onTap,
  });

  final double saldo;

  /// 0..1 (oltre 1 = obiettivo superato); vuoto se non hai un obiettivo.
  final double? avanzamento;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = avanzamento == null ? null : (avanzamento! * 100).round();

    return Semantics(
      button: true,
      label: 'Il tuo mese, tocca per i dettagli',
      excludeSemantics: true,
      child: EffettoMorbido(
        scalaPremuto: 0.97,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x6B053C64),
                blurRadius: 34,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.circle,
            clipBehavior: Clip.antiAlias,
            color: Colors.transparent,
            child: Ink(
              width: 262,
              height: 262,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x59FFFFFF), width: 3),
                gradient: const RadialGradient(
                  center: Alignment(0, -0.45),
                  radius: 0.95,
                  colors: [
                    Color(0xFF1F82C0),
                    Color(0xFF0A4C86),
                    Color(0xFF083A6B),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: CustomPaint(
                  painter: _AnelloPainter((avanzamento ?? 0).clamp(0, 1)),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Questo mese ti resta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ColoriLaguna.testoChiaro,
                          ),
                        ),
                        Text(
                          euro(saldo, conSegno: true),
                          style: const TextStyle(
                            fontSize: 52,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: ColoriLaguna.cifraHero,
                          ),
                        ),
                        Text(
                          pct == null
                              ? 'Il mese in dettaglio'
                              : '$pct% del tuo obiettivo',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ColoriLaguna.testoChiaro,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Disegna la pista e l'arco colorato dell'anello (da 12 in punto, in senso orario).
class _AnelloPainter extends CustomPainter {
  _AnelloPainter(this.valore);

  final double valore;

  @override
  void paint(Canvas canvas, Size size) {
    final rettangolo = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 20,
    );
    final pista = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..color = const Color(0x38FFFFFF);
    canvas.drawArc(rettangolo, 0, 2 * math.pi, false, pista);

    if (valore <= 0) return;
    final arco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0xFFF6FFB0), Color(0xFF7FE05A)],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rettangolo);
    canvas.drawArc(rettangolo, -math.pi / 2, 2 * math.pi * valore, false, arco);
  }

  @override
  bool shouldRepaint(_AnelloPainter vecchio) => vecchio.valore != valore;
}

/// "Incassato 790 €" e "Spese 120 €" sotto l'anello.
class _ChipSoldi extends StatelessWidget {
  const _ChipSoldi({required this.saldo});

  final SaldoMese saldo;

  @override
  Widget build(BuildContext context) {
    Widget chip(String testo) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        testo,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        chip('Incassato ${euro(saldo.incassato)}'),
        chip('Spese ${euro(saldo.costi)}'),
      ],
    );
  }
}

/// "Ti devono 1.250 €": i primi lavori da incassare, con un segno di spunta
/// grande per dire "mi ha pagato".
class _TiDevono extends StatelessWidget {
  const _TiDevono({required this.dati});

  final StatoDati dati;

  @override
  Widget build(BuildContext context) {
    final lavori = dati.lavoriDaIncassare;
    final tema = Theme.of(context).textTheme;

    if (lavori.isEmpty) {
      return CartaVetro(
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: ColoriLaguna.positivo,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Nessuno ti deve soldi', style: tema.titleMedium),
            ),
          ],
        ),
      );
    }

    return CartaVetro(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('ti-devono'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PagamentiPagina()),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text('Ti devono', style: tema.titleLarge)),
                  Text(
                    euro(dati.totaleDaIncassare),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          for (final l in lavori.take(3)) _RigaDevono(lavoro: l, dati: dati),
          if (lavori.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'e altri ${lavori.length - 3}: tocca "Ti devono"',
                style: tema.bodyMedium?.copyWith(
                  color: ColoriLaguna.testoSecondario,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Una persona che ti deve dei soldi, con il segno di spunta per incassare.
class _RigaDevono extends StatelessWidget {
  const _RigaDevono({required this.lavoro, required this.dati});

  final Lavoro lavoro;
  final StatoDati dati;

  static const _colori = [
    Color(0xFF0F72A8),
    Color(0xFFC44A22),
    Color(0xFF5A8F2A),
    Color(0xFF6B5B95),
    Color(0xFFB36B00),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final oggi = dati.adesso();
    final chi = dati.cliente(lavoro.clienteId)?.nome ?? lavoro.nome;
    final ritardo = giorniRitardo(lavoro, oggi);
    final scadenza = lavoro.scadenza;

    final (stato, colore) = ritardo > 0
        ? (
            'In ritardo di $ritardo ${ritardo == 1 ? 'giorno' : 'giorni'}',
            ColoriLaguna.negativo,
          )
        : (
            scadenza == null
                ? 'Senza scadenza'
                : 'Entro il ${dataLunga(scadenza)}',
            ColoriLaguna.testoSecondario,
          );

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFD3E6EC))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: Key('devono-${lavoro.id}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => apriLavoro(context, lavoro),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _colori[chi.hashCode.abs() % _colori.length],
                    ),
                    child: Text(
                      chi.isEmpty ? '?' : chi.characters.first.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$chi · ${euro(dati.importoDi(lavoro))}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.titleMedium,
                        ),
                        Text(
                          stato,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.labelMedium?.copyWith(
                            fontSize: 14,
                            color: colore,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SferaLucida(
            icona: Icons.check_rounded,
            etichetta: 'Segna incassato ${lavoro.nome}',
            stile: StileLucido.verde,
            dimensione: 48,
            onPressed: () => segnaIncassatoConAnnulla(context, lavoro),
          ),
        ],
      ),
    );
  }
}

/// Avviso: in un tipo di lavoro incassi molto più (o meno) del prezzo di
/// mercato. Toccandolo si apre la forbice di quel tipo.
class _AvvisoScarto extends StatelessWidget {
  const _AvvisoScarto({required this.correzione});

  final CorrezioneTipo correzione;

  @override
  Widget build(BuildContext context) {
    final scarto = (correzione.scartoMedio.abs() * 100).round();
    final piu = correzione.scartoMedio > 0;
    return CartaVetro(
      key: Key('avviso-scarto-${correzione.tipo.name}'),
      colori: const [Color(0xFFFFF6C4), Color(0xFFFFE98F)],
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => modificaForbice(context, correzione.tipo),
      child: Row(
        children: [
          Icon(
            piu ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: const Color(0xFF6B2A10),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${correzione.tipo.etichetta}: incassi in media il $scarto% '
              '${piu ? 'in più' : 'in meno'} del prezzo di mercato. '
              'Tocca per rivedere la forbice.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
