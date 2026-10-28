import 'package:flutter/material.dart';

import 'stile_lucido.dart';

/// Pulsante tondo a sfera lucida, con luce in alto.
/// [etichetta] è il nome per i lettori di schermo: obbligatorio perché
/// il pulsante ha solo l'icona.
class SferaLucida extends StatelessWidget {
  const SferaLucida({
    super.key,
    required this.icona,
    required this.etichetta,
    required this.onPressed,
    this.stile = StileLucido.blu,
    this.dimensione = 44,
  });

  final IconData icona;
  final String etichetta;
  final VoidCallback? onPressed;
  final StileLucido stile;

  /// Diametro in px (almeno 44 per l'area toccabile).
  final double dimensione;

  @override
  Widget build(BuildContext context) {
    // Riflesso a goccia sulla metà alta della sfera
    final larghezzaRiflesso = dimensione * 0.72;
    final altezzaRiflesso = dimensione * 0.46;

    return Semantics(
      container: true, // resta un elemento a sé, non si fonde col titolo
      button: true,
      label: etichetta,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: stile.ombra, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipOval(
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              width: dimensione,
              height: dimensione,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: stile.bordo, width: 2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // Per le sfere bastano 3 colori: il taglio al 50% non serve.
                  colors: [stile.sfumatura[0], stile.sfumatura[1], stile.sfumatura[3]],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: InkWell(
                onTap: onPressed,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 3,
                      width: larghezzaRiflesso,
                      height: altezzaRiflesso,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.elliptical(larghezzaRiflesso * 0.5, altezzaRiflesso * 0.8),
                              topRight: Radius.elliptical(larghezzaRiflesso * 0.5, altezzaRiflesso * 0.8),
                              bottomLeft: Radius.elliptical(larghezzaRiflesso * 0.4, altezzaRiflesso * 0.25),
                              bottomRight: Radius.elliptical(larghezzaRiflesso * 0.4, altezzaRiflesso * 0.25),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.9),
                                Colors.white.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      icona,
                      size: dimensione * 0.5,
                      color: stile.testo,
                      shadows: [
                        Shadow(color: stile.ombraTesto, blurRadius: 1, offset: const Offset(0, 1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
