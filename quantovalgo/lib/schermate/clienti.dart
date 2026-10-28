import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../modelli/cliente.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/riga_progetto.dart';
import '../widget/sfera_lucida.dart';
import '../widget/stato_vuoto.dart';
import 'foglio_cliente.dart';

/// Clienti: elenco con relazione, numero di lavori e totale dei lavori.
/// (Giorni medi di pagamento, migliori e ritardatari arrivano nel passo 7.)
class ClientiPagina extends StatelessWidget {
  const ClientiPagina({super.key});

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;

    return PaginaSecondaria(
      titolo: 'Clienti',
      sottotitolo: 'Chi ti porta di più e chi paga tardi',
      figli: [
        Row(
          children: [
            Expanded(
              child: _Numero(
                etichetta: 'Clienti',
                valore: '${dati.clienti.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Numero(
                etichetta: 'Progetti',
                valore: '${dati.lavori.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text('Tutti i clienti', style: tema.titleLarge)),
            PulsanteLucido(
              etichetta: '+ Nuovo',
              onPressed: () => modificaCliente(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (dati.clienti.isEmpty)
          const StatoVuoto(
            icona: Icons.people_alt_rounded,
            titolo: 'Nessun cliente',
            testo: 'Si creano da soli con un nuovo lavoro, o con "+ Nuovo".',
          )
        else
          for (final c in dati.clienti) ...[
            _RigaCliente(cliente: c, dati: dati),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.etichetta, required this.valore});

  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) {
    return CartaVetro(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etichetta,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ColoriLaguna.testoSecondario,
            ),
          ),
          Text(
            valore,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RigaCliente extends StatelessWidget {
  const _RigaCliente({required this.cliente, required this.dati});

  final Cliente cliente;
  final StatoDati dati;

  @override
  Widget build(BuildContext context) {
    final lavori = dati.lavoriDelCliente(cliente.id);
    final totale = lavori.fold<double>(0, (somma, l) => somma + l.prezzoFinale);
    final sconto = dati.parametri.sconto(cliente.relazione);
    final tema = Theme.of(context).textTheme;

    return CartaVetro(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => modificaCliente(context, esistente: cliente),
      child: Row(
        children: [
          const IconaSfera(icona: Icons.person_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.titleMedium,
                ),
                Text(
                  '${sconto == 0 ? cliente.relazione.breve : '${cliente.relazione.breve} −$sconto%'}'
                  ' · ${lavori.length} ${lavori.length == 1 ? 'lavoro' : 'lavori'}',
                  style: tema.labelMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (totale > 0) ...[
            const SizedBox(width: 8),
            Text(
              euro(totale),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: coloreImporto(totale),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
