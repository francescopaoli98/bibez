import 'package:flutter/material.dart';

import '../logica/pagamenti.dart';
import '../modelli/lavoro.dart';
import '../modelli/tipi.dart';
import 'pillola_lucida.dart';
import 'stile_lucido.dart';

/// Stato del pagamento in una pillola: Incassato (verde), In ritardo di N
/// giorni (rossa) o Da incassare (oro). Il testo dice sempre lo stato, non
/// solo il colore.
class PillolaPagamento extends StatelessWidget {
  const PillolaPagamento({
    super.key,
    required this.lavoro,
    required this.adesso,
  });

  final Lavoro lavoro;
  final DateTime adesso;

  @override
  Widget build(BuildContext context) {
    if (lavoro.statoPagamento == StatoPagamento.incassato) {
      return const PillolaLucida(testo: 'Incassato', stile: StileLucido.verde);
    }
    final ritardo = giorniRitardo(lavoro, adesso);
    if (ritardo > 0) {
      return PillolaLucida(
        testo: 'In ritardo di $ritardo ${ritardo == 1 ? 'giorno' : 'giorni'}',
        stile: StileLucido.rosso,
      );
    }
    return const PillolaLucida(testo: 'Da incassare', stile: StileLucido.oro);
  }
}
