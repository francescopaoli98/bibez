import 'package:flutter/material.dart';

/// Pallino giallo "sole" del logo (puro decoro).
class LogoSole extends StatelessWidget {
  const LogoSole({super.key, this.dimensione = 36});

  final double dimensione;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: dimensione,
        height: dimensione,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: dimensione / 18),
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFFFFF6B0), Color(0xFFFFC93C), Color(0xFFF08A18)],
            stops: [0.0, 0.45, 1.0],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66C86400),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}
