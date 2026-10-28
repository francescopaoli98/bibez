import 'package:flutter/material.dart';

import '../tema/colori.dart';

/// Sfondo Laguna: sfumatura turchese, sole in alto a destra, onde in basso.
/// Il contenuto della schermata va passato come [child].
class SfondoLaguna extends StatelessWidget {
  const SfondoLaguna({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Sfumatura verticale
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: ColoriLaguna.sfondo,
              stops: ColoriLaguna.sfondoStop,
            ),
          ),
        ),
        // Sole (puro decoro, escluso dall'accessibilità)
        const Positioned(
          top: -100,
          right: -60,
          width: 250,
          height: 250,
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xF2FFFFE6),
                    Color(0x80FFFAAA),
                    Color(0x00FFFAAA),
                  ],
                  stops: [0.0, 0.38, 0.7],
                ),
              ),
            ),
          ),
        ),
        // Onde
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 170,
          child: ExcludeSemantics(
            child: CustomPaint(painter: _PittoreOnde()),
          ),
        ),
        child,
      ],
    );
  }
}

/// Disegna le tre onde del mockup (viewBox 390×170, allungato in larghezza).
class _PittoreOnde extends CustomPainter {
  const _PittoreOnde();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 390, size.height / 170);

    // Onda bianca trasparente
    final bianca = Path()
      ..moveTo(0, 70)
      ..cubicTo(40, 50, 80, 50, 120, 70)
      ..cubicTo(160, 90, 200, 90, 240, 70)
      ..cubicTo(280, 50, 320, 50, 390, 70)
      ..lineTo(390, 170)
      ..lineTo(0, 170)
      ..close();
    canvas.drawPath(bianca, Paint()..color = ColoriLaguna.ondaBianca);

    // Onda turchese
    final turchese = Path()
      ..moveTo(0, 100)
      ..cubicTo(50, 80, 100, 80, 150, 100)
      ..cubicTo(200, 120, 250, 120, 300, 100)
      ..cubicTo(350, 80, 360, 85, 390, 95)
      ..lineTo(390, 170)
      ..lineTo(0, 170)
      ..close();
    canvas.drawPath(turchese, Paint()..color = ColoriLaguna.ondaTurchese);

    // Isola verde in basso a destra
    final verde = Path()
      ..moveTo(250, 170)
      ..cubicTo(275, 130, 330, 115, 390, 135)
      ..lineTo(390, 170)
      ..close();
    canvas.drawPath(verde, Paint()..color = ColoriLaguna.ondaVerde);
  }

  @override
  bool shouldRepaint(covariant CustomPainter vecchio) => false;
}
