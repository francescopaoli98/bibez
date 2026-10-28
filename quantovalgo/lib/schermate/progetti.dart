import 'package:flutter/material.dart';

import '../servizi/stato_dati.dart';
import '../widget/riga_progetto.dart';
import 'scheda.dart';

/// Scheda "Progetti": tutti i lavori, dal più recente.
class ProgettiPagina extends StatelessWidget {
  const ProgettiPagina({super.key});

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    return Scheda(
      titolo: 'Progetti',
      figli: [ElencoProgetti(dati: dati)],
    );
  }
}
