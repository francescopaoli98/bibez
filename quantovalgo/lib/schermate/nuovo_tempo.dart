import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/passo_guidato.dart';
import '../widget/pulsante_scelta.dart';
import '../widget/sfera_lucida.dart';
import 'bozza_lavoro.dart';
import 'foglio_numero.dart';
import 'nuovo_lavoro.dart';
import 'nuovo_risultato.dart';

/// Passo 3 di "Nuovo lavoro": quanto tempo ci metti? Un numero grande da
/// cambiare con + e −, e un interruttore per la trasferta.
class PassoTempo extends StatefulWidget {
  const PassoTempo({super.key, required this.bozza});

  final BozzaLavoro bozza;

  @override
  State<PassoTempo> createState() => _PassoTempoState();
}

class _PassoTempoState extends State<PassoTempo> {
  static const _scatto = 15; // minuti per ogni tocco su + e −
  static const _massimo = 24 * 60;

  late int _minuti = widget.bozza.minuti;
  late bool _trasferta = widget.bozza.conTrasferta;
  late double _km = widget.bozza.km;

  /// `45 min`, `2 h`, `5 h 45`: corto, per stare tra i pulsanti + e −.
  static String _testoTempo(int minuti) {
    final ore = minuti ~/ 60;
    final resto = minuti % 60;
    if (ore == 0) return '$resto min';
    return resto == 0 ? '$ore h' : '$ore h ${resto.toString().padLeft(2, '0')}';
  }

  void _cambia(int delta) =>
      setState(() => _minuti = (_minuti + delta).clamp(_scatto, _massimo));

  BozzaLavoro get _bozza =>
      widget.bozza.copyWith(minuti: _minuti, conTrasferta: _trasferta, km: _km);

  Future<void> _cambiaKm() async {
    final nuovi = await chiediNumero(
      context,
      titolo: 'Trasferta',
      etichetta: 'Quanti km in tutto, andata e ritorno',
      iniziale: _km,
      massimo: 2000,
    );
    if (nuovi != null) setState(() => _km = nuovi);
  }

  /// Per chi non sa quanto tempo ci metterà: il modulo completo, con i
  /// prezzi di mercato. Si lascia il percorso e si torna alla Home.
  void _modulo() {
    final dati = DatiScope.leggi(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => NuovoLavoroPagina(
          tipoIniziale: widget.bozza.tipo,
          clienteIniziale: dati.cliente(widget.bozza.clienteId),
          relazioneIniziale: widget.bozza.relazione,
        ),
      ),
      (r) => r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;
    final rimborso = dati.impostazioni.rimborsoKm;

    return PassoGuidato(
      titolo: 'Quanto tempo ci metti?',
      sottotitolo: 'Anche a occhio: lo puoi cambiare dopo.',
      passo: 3,
      azione: 'Quanto chiedo?',
      onAzione: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PassoRisultato(bozza: _bozza)),
      ),
      figli: [
        CartaVetro(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Row(
            children: [
              SferaLucida(
                icona: Icons.remove_rounded,
                etichetta: 'Meno tempo',
                dimensione: 64,
                onPressed: () => _cambia(-_scatto),
              ),
              Expanded(
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _testoTempo(_minuti),
                        key: const Key('tempo-scelto'),
                        style: const TextStyle(
                          fontSize: 54,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: ColoriLaguna.testo,
                        ),
                      ),
                    ),
                    Text(
                      'in totale',
                      style: tema.labelMedium?.copyWith(
                        fontSize: 15,
                        color: ColoriLaguna.testoSecondario,
                      ),
                    ),
                  ],
                ),
              ),
              SferaLucida(
                icona: Icons.add_rounded,
                etichetta: 'Più tempo',
                dimensione: 64,
                onPressed: () => _cambia(_scatto),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (etichetta, minuti) in const [
              ('1 ora', 60),
              ('Mezza giornata', 240),
              ('Giornata', 480),
            ])
              PulsanteScelta(
                etichetta: etichetta,
                selezionato: _minuti == minuti,
                onTap: () => setState(() => _minuti = minuti),
              ),
          ],
        ),
        const SizedBox(height: 14),
        CartaVetro(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const Key('km-trasferta'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: _cambiaKm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trasferta', style: tema.titleLarge),
                        Text(
                          '${numeroPerCampo(_km)} km andata e ritorno · ${euro(_km * rimborso)}',
                          style: tema.labelMedium?.copyWith(
                            fontSize: 15,
                            color: ColoriLaguna.testoSecondario,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Switch(
                key: const Key('interruttore-trasferta'),
                value: _trasferta,
                onChanged: (acceso) => setState(() => _trasferta = acceso),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CartaVetro(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          onTap: _modulo,
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF0F5C8C)),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Non lo so: guarda i prezzi di mercato',
                    style: tema.titleMedium?.copyWith(
                      color: const Color(0xFF0F5C8C),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
