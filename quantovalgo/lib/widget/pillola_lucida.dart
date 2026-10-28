import 'package:flutter/material.dart';

import 'stile_lucido.dart';

/// Etichetta lucida a pillola (non cliccabile): "In positivo", "Regali 300 €".
class PillolaLucida extends StatelessWidget {
  const PillolaLucida({
    super.key,
    required this.testo,
    this.stile = StileLucido.verde,
  });

  final String testo;
  final StileLucido stile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: stile.bordo, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: stile.sfumatura,
          stops: StileLucido.stop,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            right: 8,
            top: 2,
            height: 10,
            child: DecoratedBox(
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text(
              testo,
              style: TextStyle(
                fontSize: 14,
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
    );
  }
}
