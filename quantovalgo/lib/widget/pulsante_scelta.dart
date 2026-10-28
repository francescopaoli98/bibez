import 'package:flutter/material.dart';

import '../tema/colori.dart';
import 'effetto_morbido.dart';
import 'stile_lucido.dart';

/// Pulsante di scelta lucido: bianco se non scelto, colorato se scelto.
/// Serve per tipo di lavoro, relazione col cliente, categorie, ecc.
class PulsanteScelta extends StatelessWidget {
  const PulsanteScelta({
    super.key,
    required this.etichetta,
    required this.selezionato,
    required this.onTap,
    this.sottotitolo,
    this.nomeAccessibile,
    this.stileSelezionato = StileLucido.blu,
    this.altezza = 44,
  });

  final String etichetta;

  /// Seconda riga più piccola (es. "−30%").
  final String? sottotitolo;

  /// Nome per i lettori di schermo se l'etichetta è una sigla (es. "L" → "Lunedì").
  final String? nomeAccessibile;
  final bool selezionato;
  final VoidCallback onTap;

  /// Colore quando è scelto (oro per il tipo di lavoro, blu per il resto).
  final StileLucido stileSelezionato;
  final double altezza;

  static const _celeste = Color(0xFF6FCBEF);

  @override
  Widget build(BuildContext context) {
    final raggio = BorderRadius.circular(altezza < 52 ? 999 : 22);
    final stile = stileSelezionato;
    final testo = selezionato ? stile.testo : ColoriLaguna.testo;
    final testoSotto = selezionato
        ? stile.testo.withValues(alpha: 0.9)
        : ColoriLaguna.testoSecondario;

    return Semantics(
      container: true,
      button: true,
      selected: selezionato,
      label:
          nomeAccessibile ??
          (sottotitolo == null ? etichetta : '$etichetta, $sottotitolo'),
      excludeSemantics: true,
      child: EffettoMorbido(
        scalaPremuto: 0.95,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: raggio,
            boxShadow: [
              BoxShadow(
                color: selezionato ? stile.ombra : const Color(0x40065A78),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: raggio,
            child: Material(
              type: MaterialType.transparency,
              child: Ink(
                height: altezza,
                decoration: BoxDecoration(
                  borderRadius: raggio,
                  border: Border.all(
                    color: selezionato ? stile.bordo : _celeste,
                    width: 2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: selezionato
                        ? stile.sfumatura
                        : const [
                            Color(0xFFFFFFFF),
                            Color(0xFFF2FBFF),
                            Color(0xFFDDF3FB),
                            Color(0xFFEAFAFF),
                          ],
                    stops: StileLucido.stop,
                  ),
                ),
                child: InkWell(
                  onTap: onTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Riflesso a capsula (più tenue se non scelto)
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 3,
                        height: altezza * 0.42,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(
                                    alpha: selezionato ? 0.85 : 0.4,
                                  ),
                                  Colors.white.withValues(alpha: 0.12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              etichetta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: testo,
                                shadows: selezionato
                                    ? [
                                        Shadow(
                                          color: stile.ombraTesto,
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            if (sottotitolo != null)
                              Text(
                                sottotitolo!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: testoSotto,
                                ),
                              ),
                          ],
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
    );
  }
}
