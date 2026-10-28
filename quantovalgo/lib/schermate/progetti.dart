import 'package:flutter/material.dart';

import '../widget/stato_vuoto.dart';
import 'scheda.dart';

/// Scheda "Progetti" (per ora vuota).
class ProgettiPagina extends StatelessWidget {
  const ProgettiPagina({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scheda(
      titolo: 'Progetti',
      figli: [
        StatoVuoto(
          icona: Icons.work_outline_rounded,
          titolo: 'Nessun progetto',
          testo: 'Qui vedrai tutti i tuoi lavori e quanto rendono.',
        ),
      ],
    );
  }
}
