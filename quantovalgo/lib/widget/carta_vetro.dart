import 'package:flutter/material.dart';

import 'effetto_morbido.dart';

/// Scheda "vetro": bianco leggero, bordo bianco, ombra morbida.
/// Con [onTap] diventa toccabile (effetto morbido e onda al tocco).
class CartaVetro extends StatelessWidget {
  const CartaVetro({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.colori = const [Color(0xF2FFFFFF), Color(0xD9EEFCFC)],
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Sfumatura dall'alto al basso (gialla per le segnalazioni).
  final List<Color> colori;

  static const _ombra = [
    BoxShadow(color: Color(0x38065A78), blurRadius: 14, offset: Offset(0, 5)),
  ];

  @override
  Widget build(BuildContext context) {
    final raggio = BorderRadius.circular(22);
    final sfumatura = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colori,
    );

    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: raggio,
          border: Border.all(color: Colors.white),
          gradient: sfumatura,
          boxShadow: _ombra,
        ),
        child: child,
      );
    }

    return EffettoMorbido(
      scalaPremuto: 0.97,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: raggio, boxShadow: _ombra),
        child: ClipRRect(
          borderRadius: raggio,
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: raggio,
                border: Border.all(color: Colors.white),
                gradient: sfumatura,
              ),
              child: InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
