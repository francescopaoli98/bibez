import 'package:flutter/material.dart';

import '../tema/colori.dart';

/// Riquadro grande in alto (Home, Progetto, Obiettivo): sfumatura blu-verde
/// con riflesso sulla metà alta. Il testo va in [child], di solito bianco.
class HeroLaguna extends StatelessWidget {
  const HeroLaguna({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColoriLaguna.heroInizio, ColoriLaguna.heroFine],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6604466E),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          children: [
            // Riflesso sulla metà alta
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 70,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.elliptical(200, 22),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
