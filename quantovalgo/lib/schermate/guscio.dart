import 'package:flutter/material.dart';

import '../widget/banda_cronometro.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/sfera_lucida.dart';
import '../widget/sfondo_laguna.dart';
import '../widget/stile_lucido.dart';
import 'foglio_introito.dart';
import 'home.dart';
import 'nuovo_tipo.dart';

/// Struttura principale: sfondo Laguna, la Home e il pulsante verde
/// "Nuovo lavoro" che galleggia in basso, con accanto la sfera dorata per
/// registrare al volo un guadagno senza lavoro. Niente barra di schede: il resto
/// dell'app si apre da "Altro".
class Guscio extends StatelessWidget {
  const Guscio({super.key});

  void _apriNuovoLavoro(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const PassoTipo()));
  }

  @override
  Widget build(BuildContext context) {
    return SfondoLaguna(
      child: Scaffold(
        body: const HomePagina(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: 340,
          child: Row(
            children: [
              Expanded(
                child: PulsanteLucido(
                  etichetta: 'Nuovo lavoro',
                  icona: Icons.add_rounded,
                  stile: StileLucido.verde,
                  altezza: 64,
                  onPressed: () => _apriNuovoLavoro(context),
                ),
              ),
              const SizedBox(width: 12),
              // Soldi entrati senza un lavoro: importo, giorno, fatto
              SferaLucida(
                key: const Key('guadagno-veloce'),
                icona: Icons.savings_rounded,
                etichetta: 'Guadagno veloce',
                stile: StileLucido.oro,
                dimensione: 64,
                onPressed: () => modificaIntroito(context),
              ),
            ],
          ),
        ),
        // Visibile solo se c'è un cronometro acceso
        bottomNavigationBar: const BandaCronometro(),
      ),
    );
  }
}
