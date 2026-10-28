import 'package:flutter/material.dart';

/// Scheda "vetro": bianco leggero, bordo bianco, ombra morbida.
class CartaVetro extends StatelessWidget {
  const CartaVetro({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF2FFFFFF), Color(0xD9EEFCFC)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x38065A78), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }
}
