import 'package:flutter/material.dart';

import '../widget/stato_vuoto.dart';
import 'scheda.dart';

/// Scheda "Costi" (per ora vuota).
class CostiPagina extends StatelessWidget {
  const CostiPagina({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scheda(
      titolo: 'Costi',
      figli: [
        StatoVuoto(
          icona: Icons.euro_rounded,
          titolo: 'Nessun costo',
          testo: 'Qui metterai abbonamenti, attrezzatura e costi fissi.',
        ),
      ],
    );
  }
}
