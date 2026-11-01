import 'package:flutter/material.dart';

import '../widget/banda_cronometro.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/sfondo_laguna.dart';
import '../widget/stile_lucido.dart';
import 'home.dart';
import 'nuovo_lavoro.dart';

/// Struttura principale: sfondo Laguna, la Home e il pulsante verde
/// "Nuovo lavoro" che galleggia in basso. Niente barra di schede: il resto
/// dell'app si apre da "Altro".
class Guscio extends StatelessWidget {
  const Guscio({super.key});

  void _apriNuovoLavoro(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NuovoLavoroPagina()));
  }

  @override
  Widget build(BuildContext context) {
    return SfondoLaguna(
      child: Scaffold(
        body: const HomePagina(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: 300,
          child: PulsanteLucido(
            etichetta: 'Nuovo lavoro',
            icona: Icons.add_rounded,
            stile: StileLucido.verde,
            altezza: 64,
            onPressed: () => _apriNuovoLavoro(context),
          ),
        ),
        // Visibile solo se c'è un cronometro acceso
        bottomNavigationBar: const BandaCronometro(),
      ),
    );
  }
}
