import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../logica/preventivo.dart';
import '../modelli/preventivo.dart';

/// Tutto quello che serve per disegnare un preventivo.
class DatiFoglio {
  const DatiFoglio({
    required this.titolo,
    required this.testi,
    required this.conto,
    required this.data,
    this.cliente,
  });

  /// Nome del lavoro.
  final String titolo;
  final String? cliente;
  final TestiPreventivo testi;
  final ContoPrezzo conto;
  final DateTime data;
}

/// Larghezza del foglio: 360 punti, esportato a 3× (= 1080 pixel).
const larghezzaFoglio = 360.0;

/// Il foglio del preventivo nello stile scelto. È quello che finisce nel PNG.
class FoglioPreventivo extends StatelessWidget {
  const FoglioPreventivo({super.key, required this.stile, required this.dati});

  final StilePreventivo stile;
  final DatiFoglio dati;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: larghezzaFoglio,
      child: switch (stile) {
        StilePreventivo.app => _FoglioApp(dati: dati),
        StilePreventivo.professionale => _FoglioProfessionale(dati: dati),
        StilePreventivo.informatico => _FoglioInformatico(dati: dati),
        StilePreventivo.gaming => _FoglioGaming(dati: dati),
      },
    );
  }
}

String _sconto(ContoPrezzo c) => '−${c.scontoPercento}%';

// ---------------------------------------------------------------------------
// App: tema Laguna, turchese e lucido
// ---------------------------------------------------------------------------
class _FoglioApp extends StatelessWidget {
  const _FoglioApp({required this.dati});

  final DatiFoglio dati;

  static const _testo = Color(0xFF032A3B);
  static const _secondario = Color(0xFF1F4A5A);

  Widget _sezione(String titolo, Widget corpo) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33065A78),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titolo,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: Color(0xFF0A4C86),
          ),
        ),
        const SizedBox(height: 6),
        corpo,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = dati.conto;
    const corpo = TextStyle(
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: _testo,
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4CC6E6), Color(0xFF8FE6EC), Color(0xFFD5F7F1)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A4C86), Color(0xFF0A7C8A)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PREVENTIVO',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Color(0xFFE3F9FF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dati.titolo,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (dati.cliente != null) 'per ${dati.cliente}',
                    dataLunga(dati.data),
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE6FF9A),
                  ),
                ),
              ],
            ),
          ),
          _sezione('PROGETTO', Text(dati.testi.progetto, style: corpo)),
          if (dati.testi.comeLavoro.isNotEmpty)
            _sezione(
              'COME LAVORO',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < dati.testi.comeLavoro.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(right: 10, top: 1),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF0A4C86),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(dati.testi.comeLavoro[i], style: corpo),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (dati.testi.benefit.isNotEmpty)
            _sezione(
              'COSA CI GUADAGNI',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final b in dati.testi.benefit)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 8, top: 1),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 22,
                              color: Color(0xFF1F8A32),
                            ),
                          ),
                          Expanded(child: Text(b, style: corpo)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A4C86), Color(0xFF0A7C8A)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (c.haSconto) ...[
                  _riga('Prezzo pieno', euro(c.pieno), const Color(0xFFE3F9FF)),
                  _riga(
                    'Sconto ${_sconto(c)}',
                    euro(-c.scontoImporto),
                    const Color(0xFFE3F9FF),
                  ),
                  const SizedBox(height: 6),
                ],
                const Text(
                  'Totale',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE3F9FF),
                  ),
                ),
                Text(
                  euro(c.totale),
                  style: const TextStyle(
                    fontSize: 48,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: Color(0xFFE6FF9A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'fatto con QuantoValgo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _secondario,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riga(String nome, String valore, Color colore) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            nome,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colore,
            ),
          ),
        ),
        Text(
          valore,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colore,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Professionale: foglio bianco, carattere con le grazie, blu navy
// ---------------------------------------------------------------------------
class _FoglioProfessionale extends StatelessWidget {
  const _FoglioProfessionale({required this.dati});

  final DatiFoglio dati;

  static const _navy = Color(0xFF14274E);
  static const _grigio = Color(0xFF4A5470);
  static const _serif = 'serif';

  Widget _titolo(String t) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t,
          style: const TextStyle(
            fontFamily: _serif,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 1, color: const Color(0xFFB8C0D4)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = dati.conto;
    const corpo = TextStyle(
      fontFamily: _serif,
      fontSize: 15,
      height: 1.45,
      color: Color(0xFF1B2540),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC9CFDF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PREVENTIVO',
            style: TextStyle(
              fontFamily: _serif,
              fontSize: 13,
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
              color: _grigio,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 3, color: _navy),
          const SizedBox(height: 14),
          Text(
            dati.titolo,
            style: const TextStyle(
              fontFamily: _serif,
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (dati.cliente != null) 'Per ${dati.cliente}',
              dataLunga(dati.data),
            ].join(' · '),
            style: const TextStyle(
              fontFamily: _serif,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: _grigio,
            ),
          ),
          _titolo('Progetto'),
          Text(dati.testi.progetto, style: corpo),
          if (dati.testi.comeLavoro.isNotEmpty) ...[
            _titolo('Modalità di lavoro'),
            for (var i = 0; i < dati.testi.comeLavoro.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 26, child: Text('${i + 1}.', style: corpo)),
                    Expanded(
                      child: Text(dati.testi.comeLavoro[i], style: corpo),
                    ),
                  ],
                ),
              ),
          ],
          if (dati.testi.benefit.isNotEmpty) ...[
            _titolo('Vantaggi per te'),
            for (final b in dati.testi.benefit)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 26, child: Text('–', style: corpo)),
                    Expanded(child: Text(b, style: corpo)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _navy, width: 2)),
            ),
            child: Column(
              children: [
                if (c.haSconto) ...[
                  _riga('Prezzo pieno', euro(c.pieno), corpo),
                  _riga('Sconto ${_sconto(c)}', euro(-c.scontoImporto), corpo),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Totale',
                        style: TextStyle(
                          fontFamily: _serif,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                    ),
                    Text(
                      euro(c.totale),
                      style: const TextStyle(
                        fontFamily: _serif,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _riga(String nome, String valore, TextStyle stile) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        Expanded(child: Text(nome, style: stile)),
        Text(valore, style: stile),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Informatico: sfondo scuro, carattere da terminale, verde
// ---------------------------------------------------------------------------
class _FoglioInformatico extends StatelessWidget {
  const _FoglioInformatico({required this.dati});

  final DatiFoglio dati;

  static const _verde = Color(0xFF3DDC84);
  static const _testo = Color(0xFFC9D1D9);
  static const _commento = Color(0xFF7EA88B);
  static const _mono = 'monospace';

  @override
  Widget build(BuildContext context) {
    final c = dati.conto;
    const corpo = TextStyle(
      fontFamily: _mono,
      fontSize: 13.5,
      height: 1.5,
      color: _testo,
    );
    const commento = TextStyle(
      fontFamily: _mono,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: _commento,
    );

    Widget titolo(String t) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 4),
      child: Text(t, style: commento),
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F6F43), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$ preventivo${dati.cliente == null ? '' : ' --per "${dati.cliente}"'}',
            style: const TextStyle(
              fontFamily: _mono,
              fontSize: 13,
              color: _commento,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '# ${dati.titolo}',
            style: const TextStyle(
              fontFamily: _mono,
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: _verde,
            ),
          ),
          const SizedBox(height: 4),
          Text(dataLunga(dati.data), style: commento),
          titolo('// progetto'),
          Text(dati.testi.progetto, style: corpo),
          if (dati.testi.comeLavoro.isNotEmpty) ...[
            titolo('// metodo'),
            for (var i = 0; i < dati.testi.comeLavoro.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${(i + 1).toString().padLeft(2, '0')} › ${dati.testi.comeLavoro[i]}',
                  style: corpo,
                ),
              ),
          ],
          if (dati.testi.benefit.isNotEmpty) ...[
            titolo('// benefit'),
            for (final b in dati.testi.benefit)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('+ $b', style: corpo),
              ),
          ],
          const SizedBox(height: 18),
          Container(height: 1, color: const Color(0xFF1F6F43)),
          const SizedBox(height: 12),
          if (c.haSconto) ...[
            Text('pieno  = ${euro(c.pieno)}', style: corpo),
            Text('sconto = ${_sconto(c)}', style: corpo),
            const SizedBox(height: 6),
          ],
          Text(
            'total = ${euro(c.totale)}',
            style: const TextStyle(
              fontFamily: _mono,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _verde,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gaming: viola scuro, bordi neon magenta e azzurro
// ---------------------------------------------------------------------------
class _FoglioGaming extends StatelessWidget {
  const _FoglioGaming({required this.dati});

  final DatiFoglio dati;

  static const _magenta = Color(0xFFFF2BD6);
  static const _azzurro = Color(0xFF29E7FF);
  static const _testo = Color(0xFFEDE7FF);

  @override
  Widget build(BuildContext context) {
    final c = dati.conto;
    const corpo = TextStyle(
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: _testo,
    );

    Widget titolo(String t) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: _azzurro,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 44, height: 3, color: _magenta),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _magenta, width: 3),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B0B3A), Color(0xFF2D1060)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x9929E7FF), blurRadius: 14, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NUOVA MISSIONE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: _azzurro,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dati.titolo.toUpperCase(),
            style: const TextStyle(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [Shadow(color: _magenta, blurRadius: 10)],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (dati.cliente != null) 'Giocatore: ${dati.cliente}',
              dataLunga(dati.data),
            ].join(' · '),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFD6F6),
            ),
          ),
          titolo('MISSIONE'),
          Text(dati.testi.progetto, style: corpo),
          if (dati.testi.comeLavoro.isNotEmpty) ...[
            titolo('STRATEGIA'),
            for (var i = 0; i < dati.testi.comeLavoro.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        'LV ${i + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _magenta,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(dati.testi.comeLavoro[i], style: corpo),
                    ),
                  ],
                ),
              ),
          ],
          if (dati.testi.benefit.isNotEmpty) ...[
            titolo('BOTTINO'),
            for (final b in dati.testi.benefit)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8, top: 1),
                      child: Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: Color(0xFFFFD84A),
                      ),
                    ),
                    Expanded(child: Text(b, style: corpo)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _azzurro, width: 2),
              color: const Color(0x33000000),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.haSconto) ...[
                  Text('PREZZO PIENO  ${euro(c.pieno)}', style: corpo),
                  Text(
                    'SCONTO  ${_sconto(c)}',
                    style: corpo.copyWith(color: _azzurro),
                  ),
                  const SizedBox(height: 6),
                ],
                const Text(
                  'PREZZO FINALE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: _azzurro,
                  ),
                ),
                Text(
                  euro(c.totale),
                  style: const TextStyle(
                    fontSize: 46,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFE04A),
                    shadows: [Shadow(color: _magenta, blurRadius: 12)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
