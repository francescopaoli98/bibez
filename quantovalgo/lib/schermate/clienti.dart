import 'package:flutter/material.dart';

import '../widget/pagina_secondaria.dart';
import '../widget/stato_vuoto.dart';

/// Pagina "Clienti" (per ora vuota).
class ClientiPagina extends StatelessWidget {
  const ClientiPagina({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaginaSecondaria(
      titolo: 'Clienti',
      figli: [
        StatoVuoto(
          icona: Icons.people_alt_rounded,
          titolo: 'Nessun cliente',
          testo: 'Qui vedrai i tuoi clienti e come pagano.',
        ),
      ],
    );
  }
}
