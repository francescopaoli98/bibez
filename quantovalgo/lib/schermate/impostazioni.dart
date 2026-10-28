import 'package:flutter/material.dart';

import '../widget/pagina_secondaria.dart';
import '../widget/stato_vuoto.dart';

/// Pagina "Impostazioni" (per ora vuota).
class ImpostazioniPagina extends StatelessWidget {
  const ImpostazioniPagina({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaginaSecondaria(
      titolo: 'Impostazioni',
      figli: [
        StatoVuoto(
          icona: Icons.settings_rounded,
          titolo: 'Impostazioni',
          testo: 'Qui regolerai sconti, tasse e promemoria.',
        ),
      ],
    );
  }
}
