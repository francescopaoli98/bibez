import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../modelli/lavoro.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import 'aspetto_tipo.dart';
import 'carta_vetro.dart';
import 'sfera_lucida.dart';
import 'stato_vuoto.dart';
import '../schermate/progetto.dart';

/// Colore di un importo: verde se positivo, rosso se negativo.
Color coloreImporto(double valore) => valore > 0
    ? ColoriLaguna.positivo
    : valore < 0
    ? ColoriLaguna.negativo
    : ColoriLaguna.testo;

/// Una riga dell'elenco progetti: sfera del tipo, nome, dettagli e utile.
class RigaProgetto extends StatelessWidget {
  const RigaProgetto({super.key, required this.lavoro, required this.dati});

  final Lavoro lavoro;
  final StatoDati dati;

  @override
  Widget build(BuildContext context) {
    final utile = dati.riepilogoDi(lavoro.id).utile;
    final sconto = dati.parametri.sconto(lavoro.relazione);
    final cliente = dati.cliente(lavoro.clienteId);

    // "Doppiaggio · Luca · Amico −30%"
    final dettagli = [
      lavoro.tipo.etichetta,
      ?cliente?.nome,
      sconto == 0
          ? lavoro.relazione.breve
          : '${lavoro.relazione.breve} −$sconto%',
    ].join(' · ');

    return CartaVetro(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProgettoPagina(lavoroId: lavoro.id),
        ),
      ),
      child: Row(
        children: [
          IconaSfera(icona: lavoro.tipo.icona, stile: lavoro.tipo.stile),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lavoro.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  dettagli,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            euro(utile, conSegno: true),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: coloreImporto(utile),
            ),
          ),
        ],
      ),
    );
  }
}

/// Elenco di tutti i progetti (Home e scheda Progetti).
class ElencoProgetti extends StatelessWidget {
  const ElencoProgetti({super.key, required this.dati});

  final StatoDati dati;

  @override
  Widget build(BuildContext context) {
    if (!dati.caricato) return const SizedBox.shrink();
    if (dati.lavori.isEmpty) {
      return const StatoVuoto(
        icona: Icons.work_outline_rounded,
        titolo: 'Ancora nessun progetto',
        testo: 'Premi il + verde per registrare il primo lavoro.',
      );
    }
    return Column(
      children: [
        for (final lavoro in dati.lavori) ...[
          RigaProgetto(lavoro: lavoro, dati: dati),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
