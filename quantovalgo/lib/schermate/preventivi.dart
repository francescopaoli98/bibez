import 'package:flutter/material.dart';

import '../widget/stato_vuoto.dart';
import 'scheda.dart';

/// Scheda "Preventivi" (per ora vuota).
class PreventiviPagina extends StatelessWidget {
  const PreventiviPagina({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scheda(
      titolo: 'Preventivi',
      figli: [
        StatoVuoto(
          icona: Icons.description_outlined,
          titolo: 'Nessun preventivo',
          testo: 'Qui costruirai i preventivi da condividere.',
        ),
      ],
    );
  }
}
