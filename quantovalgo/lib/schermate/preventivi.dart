import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../modelli/preventivo.dart';
import '../modelli/tipi.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/sfera_lucida.dart';
import '../widget/stato_vuoto.dart';
import '../widget/stile_lucido.dart';
import 'preventivo_anteprima.dart';
import 'preventivo_domande.dart';

/// I preventivi fatti: le immagini da mandare ai clienti, dalla più recente.
/// Da qui se ne fa uno nuovo scegliendo il lavoro.
class PreventiviPagina extends StatelessWidget {
  const PreventiviPagina({super.key});

  /// Foglio con i lavori per cui si può fare un preventivo.
  Future<void> _nuovo(BuildContext context) async {
    final dati = DatiScope.leggi(context);
    // "A giornata" non ha un prezzo da proporre: niente preventivo
    final lavori = [
      for (final l in dati.lavori)
        if (l.tipo != TipoLavoro.aGiornata) l,
    ];
    final scelto = await mostraFoglio<String>(
      context,
      titolo: 'Per quale lavoro?',
      costruttore: (contesto) {
        final tema = Theme.of(contesto).textTheme;
        if (lavori.isEmpty) {
          return Text(
            'Prima crea un lavoro: il preventivo parte da lì.',
            style: tema.bodyLarge,
          );
        }
        return Column(
          children: [
            for (final l in lavori)
              InkWell(
                key: Key('per-lavoro-${l.nome}'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(contesto).pop(l.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.nome, style: tema.titleMedium),
                            Text(
                              dati.cliente(l.clienteId)?.nome ??
                                  l.tipo.etichetta,
                              style: tema.bodyMedium?.copyWith(
                                color: ColoriLaguna.testoSecondario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        euro(
                          l.prezzoFinale > 0
                              ? l.prezzoFinale
                              : dati.importoDi(l),
                        ),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (scelto != null && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PreventivoDomande(lavoroId: scelto),
        ),
      );
    }
  }

  Future<void> _elimina(BuildContext context, Preventivo p) async {
    final dati = DatiScope.leggi(context);
    final conferma = await chiediConferma(
      context,
      titolo: 'Eliminare il preventivo?',
      testo:
          'L\'elenco perde «${p.progetto}». Le immagini già salvate restano.',
      etichettaConferma: 'Elimina',
    );
    if (conferma) dati.eliminaPreventivo(p.id);
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;
    final lista = dati.preventivi;

    return PaginaSecondaria(
      titolo: 'Preventivi',
      sottotitolo: 'Le immagini da mandare ai clienti',
      figli: [
        PulsanteLucido(
          key: const Key('nuovo-preventivo'),
          etichetta: 'Nuovo preventivo',
          icona: Icons.add_rounded,
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: () => _nuovo(context),
        ),
        const SizedBox(height: 14),
        if (lista.isEmpty)
          const StatoVuoto(
            icona: Icons.description_outlined,
            titolo: 'Nessun preventivo',
            testo: 'Scegli un lavoro, rispondi a poche domande e salvi l\'immagine.',
          )
        else
          for (final p in lista) ...[
            CartaVetro(
              key: Key('preventivo-${p.id}'),
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PreventivoAnteprima(bozza: p),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dati.lavoro(p.lavoroId)?.nome ?? p.progetto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.titleMedium,
                        ),
                        Text(
                          [
                            p.cliente ?? 'senza cliente',
                            euro(p.prezzoFinale),
                            dataLunga(p.creatoIl),
                            p.stile.etichetta,
                          ].join(' · '),
                          style: tema.labelMedium?.copyWith(
                            fontSize: 14,
                            color: ColoriLaguna.testoSecondario,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SferaLucida(
                    icona: Icons.delete_outline_rounded,
                    etichetta: 'Elimina il preventivo ${p.progetto}',
                    stile: StileLucido.rosso,
                    onPressed: () => _elimina(context, p),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}
