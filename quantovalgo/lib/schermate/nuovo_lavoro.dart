import 'package:flutter/material.dart';

import '../widget/pagina_secondaria.dart';
import '../widget/stato_vuoto.dart';

/// Pagina "Nuovo lavoro" (per ora vuota).
class NuovoLavoroPagina extends StatelessWidget {
  const NuovoLavoroPagina({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaginaSecondaria(
      titolo: 'Nuovo lavoro',
      figli: [
        StatoVuoto(
          icona: Icons.add_task_rounded,
          titolo: 'Presto qui',
          testo: 'Qui inserirai nome, tipo e cliente del lavoro.',
        ),
      ],
    );
  }
}
