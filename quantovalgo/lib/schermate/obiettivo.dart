import 'package:flutter/material.dart';

import '../widget/pagina_secondaria.dart';
import '../widget/stato_vuoto.dart';

/// Pagina "Obiettivo" (per ora vuota).
class ObiettivoPagina extends StatelessWidget {
  const ObiettivoPagina({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaginaSecondaria(
      titolo: 'Obiettivo',
      figli: [
        StatoVuoto(
          icona: Icons.flag_rounded,
          titolo: 'Nessun obiettivo',
          testo: 'Qui imposterai obiettivo mensile e pareggio.',
        ),
      ],
    );
  }
}
