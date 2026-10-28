import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Effetto "morbido" al tocco: il pulsante si schiaccia piano e poi torna su
/// con un piccolo rimbalzo, accompagnato da un leggero tick di vibrazione.
///
/// Usa solo [AnimatedScale] (animazione leggera, nessun controller da gestire).
/// Non intercetta i tocchi: il clic vero resta all'InkWell sotto.
class EffettoMorbido extends StatefulWidget {
  const EffettoMorbido({
    super.key,
    required this.child,
    this.attivo = true,
    this.scalaPremuto = 0.93,
  });

  final Widget child;

  /// Se falso (pulsante spento) non c'è né animazione né vibrazione.
  final bool attivo;

  /// Quanto si rimpicciolisce quando è premuto (1 = per niente).
  final double scalaPremuto;

  @override
  State<EffettoMorbido> createState() => _EffettoMorbidoState();
}

class _EffettoMorbidoState extends State<EffettoMorbido> {
  bool _premuto = false;

  void _imposta(bool premuto) {
    if (_premuto != premuto) setState(() => _premuto = premuto);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.attivo) return widget.child;

    return Listener(
      onPointerDown: (_) {
        // Tick leggero (non il "colpo" forte), tipo bottone di gomma
        HapticFeedback.selectionClick();
        _imposta(true);
      },
      onPointerUp: (_) => _imposta(false),
      onPointerCancel: (_) => _imposta(false),
      child: AnimatedScale(
        scale: _premuto ? widget.scalaPremuto : 1,
        // Giù veloce e dolce, su più lento con un filo di rimbalzo
        duration: Duration(milliseconds: _premuto ? 90 : 260),
        curve: _premuto ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
