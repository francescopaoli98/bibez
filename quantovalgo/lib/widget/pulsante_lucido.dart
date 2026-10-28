import 'package:flutter/material.dart';

import 'effetto_morbido.dart';
import 'stile_lucido.dart';

/// Pulsante a pillola lucido (44-56 px), con riflesso a capsula sulla metà alta.
/// Con [onPressed] nullo il pulsante è spento (mezza opacità, non cliccabile).
class PulsanteLucido extends StatelessWidget {
  const PulsanteLucido({
    super.key,
    required this.etichetta,
    required this.onPressed,
    this.stile = StileLucido.blu,
    this.icona,
    this.altezza = 48,
  });

  final String etichetta;
  final VoidCallback? onPressed;
  final StileLucido stile;
  final IconData? icona;
  final double altezza;

  @override
  Widget build(BuildContext context) {
    final attivo = onPressed != null;
    final raggio = BorderRadius.circular(altezza);

    return EffettoMorbido(
      attivo: attivo,
      child: Opacity(
        opacity: attivo ? 1 : 0.5,
        child: DecoratedBox(
          // L'ombra sta fuori dal ritaglio, altrimenti verrebbe tagliata.
          decoration: BoxDecoration(
            borderRadius: raggio,
            boxShadow: [
              BoxShadow(
                color: stile.ombra,
                blurRadius: 12,
                offset: const Offset(0, 5),
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
                  border: Border.all(color: stile.bordo, width: 2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: stile.sfumatura,
                    stops: StileLucido.stop,
                  ),
                ),
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: raggio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Luce interna chiara in basso
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 8,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  stile.luceBasso.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Riflesso a capsula sulla metà alta
                      Positioned(
                        left: 10,
                        right: 10,
                        top: 3,
                        height: altezza * 0.44,
                        child: const IgnorePointer(child: _RiflessoCapsula()),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icona != null) ...[
                              Icon(icona, size: 22, color: stile.testo),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                etichetta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: stile.testo,
                                  shadows: [
                                    Shadow(
                                      color: stile.ombraTesto,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
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

/// Capsula bianca: 85% in alto che sfuma al 12% in basso.
class _RiflessoCapsula extends StatelessWidget {
  const _RiflessoCapsula();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.12),
          ],
        ),
      ),
    );
  }
}
