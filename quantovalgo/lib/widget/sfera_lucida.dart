import 'package:flutter/material.dart';

import 'effetto_morbido.dart';
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
    return Semantics(
      container: true, // resta un elemento a sé, non si fonde col titolo
      button: true,
      label: etichetta,
      excludeSemantics: true,
      child: EffettoMorbido(
        attivo: onPressed != null,
        scalaPremuto: 0.88,
        child: DecoratedBox(
          decoration: _ombraSfera(stile),
          child: ClipOval(
            child: Material(
              type: MaterialType.transparency,
              child: Ink(
                width: dimensione,
                height: dimensione,
                decoration: _corpoSfera(stile),
                child: InkWell(
                  onTap: onPressed,
                  child: _ContenutoSfera(
                    icona: icona,
                    stile: stile,
                    dimensione: dimensione,
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

/// Sfera lucida solo decorativa (non si tocca): per le righe degli elenchi.
class IconaSfera extends StatelessWidget {
  const IconaSfera({
    super.key,
    required this.icona,
    this.stile = StileLucido.blu,
    this.dimensione = 44,
  });

  final IconData icona;
  final StileLucido stile;
  final double dimensione;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: _ombraSfera(stile),
        child: Container(
          width: dimensione,
          height: dimensione,
          decoration: _corpoSfera(stile),
          child: _ContenutoSfera(
            icona: icona,
            stile: stile,
            dimensione: dimensione,
          ),
        ),
      ),
    );
  }
}

BoxDecoration _ombraSfera(StileLucido stile) => BoxDecoration(
  shape: BoxShape.circle,
  boxShadow: [
    BoxShadow(color: stile.ombra, blurRadius: 10, offset: const Offset(0, 4)),
  ],
);

BoxDecoration _corpoSfera(StileLucido stile) => BoxDecoration(
  shape: BoxShape.circle,
  border: Border.all(color: stile.bordo, width: 2),
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    // Per le sfere bastano 3 colori: il taglio al 50% non serve.
    colors: [stile.sfumatura[0], stile.sfumatura[1], stile.sfumatura[3]],
    stops: const [0.0, 0.5, 1.0],
  ),
);

/// Riflesso a goccia in alto e icona al centro.
class _ContenutoSfera extends StatelessWidget {
  const _ContenutoSfera({
    required this.icona,
    required this.stile,
    required this.dimensione,
  });

  final IconData icona;
  final StileLucido stile;
  final double dimensione;

  @override
  Widget build(BuildContext context) {
    final larghezza = dimensione * 0.72;
    final altezza = dimensione * 0.46;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 3,
          width: larghezza,
          height: altezza,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(larghezza * 0.5, altezza * 0.8),
                  topRight: Radius.elliptical(larghezza * 0.5, altezza * 0.8),
                  bottomLeft: Radius.elliptical(
                    larghezza * 0.4,
                    altezza * 0.25,
                  ),
                  bottomRight: Radius.elliptical(
                    larghezza * 0.4,
                    altezza * 0.25,
                  ),
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
            Shadow(
              color: stile.ombraTesto,
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ],
    );
  }
}
