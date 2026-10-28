import 'dart:async';

import 'package:flutter/material.dart';

import '../logica/formato.dart';

/// Tempo trascorso da [inizio], come `00:12:34`, che si aggiorna ogni secondo.
/// Ridisegna solo quando il testo cambia davvero.
class TestoCronometro extends StatefulWidget {
  const TestoCronometro({
    super.key,
    required this.inizio,
    required this.adesso,
    this.stile,
  });

  final DateTime inizio;

  /// L'orologio dell'app (`StatoDati.adesso`).
  final DateTime Function() adesso;
  final TextStyle? stile;

  @override
  State<TestoCronometro> createState() => _TestoCronometroState();
}

class _TestoCronometroState extends State<TestoCronometro> {
  Timer? _timer;
  late String _testo = _calcola();

  String _calcola() => cronometro(widget.adesso().difference(widget.inizio));

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final nuovo = _calcola();
      if (nuovo != _testo && mounted) setState(() => _testo = nuovo);
    });
  }

  @override
  void didUpdateWidget(TestoCronometro vecchio) {
    super.didUpdateWidget(vecchio);
    if (vecchio.inizio != widget.inizio) _testo = _calcola();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tempo trascorso $_testo',
      excludeSemantics: true,
      child: Text(
        _testo,
        style: (widget.stile ?? const TextStyle()).copyWith(
          // Cifre tutte larghe uguali: il numero non "balla" mentre corre
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
