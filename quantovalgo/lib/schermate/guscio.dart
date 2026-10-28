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

class _GuscioState extends State<Guscio> with SingleTickerProviderStateMixin {
  int _indice = 0;

  // Dissolvenza breve quando si cambia scheda (leggera: un solo controller)
  late final AnimationController _transizione = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final Animation<double> _curva = CurvedAnimation(
    parent: _transizione,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _scivola = Tween(
    begin: const Offset(0, 0.02),
    end: Offset.zero,
  ).animate(_curva);

  @override
  void dispose() {
    _transizione.dispose();
    super.dispose();
  }

  void _selezionaScheda(int i) {
    if (i == _indice) return;
    setState(() => _indice = i);
    _transizione.forward(from: 0);
  }

  void _apriNuovoLavoro() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NuovoLavoroPagina()));
  }

  @override
  Widget build(BuildContext context) {
    return SfondoLaguna(
      child: Scaffold(
        body: FadeTransition(
          opacity: _curva,
          child: SlideTransition(
            position: _scivola,
            child: IndexedStack(
              index: _indice,
              children: const [
                HomePagina(),
                ProgettiPagina(),
                PreventiviPagina(),
                CostiPagina(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BarraNavigazione(
          indice: _indice,
          onSelezionato: _selezionaScheda,
          onNuovoLavoro: _apriNuovoLavoro,
        ),
      ),
    );
  }
}
