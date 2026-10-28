import 'package:flutter/material.dart';

import '../widget/barra_navigazione.dart';
import '../widget/sfondo_laguna.dart';
import 'costi.dart';
import 'home.dart';
import 'nuovo_lavoro.dart';
import 'preventivi.dart';
import 'progetti.dart';

/// Struttura principale: sfondo Laguna, le 4 schede e la barra in basso.
/// Le schede restano vive (IndexedStack), così non perdono lo stato.
class Guscio extends StatefulWidget {
  const Guscio({super.key});

  @override
  State<Guscio> createState() => _GuscioState();
}

class _GuscioState extends State<Guscio> {
  int _indice = 0;

  void _apriNuovoLavoro() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NuovoLavoroPagina()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SfondoLaguna(
      child: Scaffold(
        body: IndexedStack(
          index: _indice,
          children: const [
            HomePagina(),
            ProgettiPagina(),
            PreventiviPagina(),
            CostiPagina(),
          ],
        ),
        bottomNavigationBar: BarraNavigazione(
          indice: _indice,
          onSelezionato: (i) => setState(() => _indice = i),
          onNuovoLavoro: _apriNuovoLavoro,
        ),
      ),
    );
  }
}
