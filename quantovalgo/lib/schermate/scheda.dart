import 'package:flutter/material.dart';

import '../widget/intestazione.dart';

/// Scheletro comune delle 4 schede principali: area sicura, titolo e lista che scorre.
class Scheda extends StatelessWidget {
  const Scheda({
    super.key,
    required this.titolo,
    required this.figli,
    this.sottotitolo,
    this.sinistra,
    this.destra,
  });

  final String titolo;
  final String? sottotitolo;
  final List<Widget> figli;
  final Widget? sinistra;
  final Widget? destra;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false, // in basso c'è la barra di navigazione
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Intestazione(
            titolo: titolo,
            sottotitolo: sottotitolo,
            sinistra: sinistra,
            destra: destra,
          ),
          const SizedBox(height: 16),
          ...figli,
        ],
      ),
    );
  }
}
