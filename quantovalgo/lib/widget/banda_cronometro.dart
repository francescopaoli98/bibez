import 'package:flutter/material.dart';

import '../schermate/cronometro_azioni.dart';
import '../schermate/ore_sottoprogetto.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import 'carta_vetro.dart';
import 'pulsante_lucido.dart';
import 'stile_lucido.dart';
import 'testo_cronometro.dart';

/// Striscia sopra la barra in basso, visibile quando c'è un cronometro acceso:
/// dice su cosa stai lavorando, da quanto, e permette di fermarlo.
/// Sta lì anche riaprendo l'app: il cronometro continua a correre.
class BandaCronometro extends StatelessWidget {
  const BandaCronometro({super.key});

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final acceso = dati.sessioneInCorso;
    if (acceso == null) return const SizedBox.shrink();

    final sotto = dati.sottoprogetto(acceso.sottoprogettoId);
    final lavoro = dati.lavoro(acceso.lavoroId);
    final tema = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: CartaVetro(
        colori: const [Color(0xFFFFF6C4), Color(0xFFFFE98F)],
        padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
        onTap: sotto == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      OreSottoprogettoPagina(sottoprogettoId: sotto.id),
                ),
              ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sotto?.nome ?? 'Cronometro acceso',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.titleMedium,
                  ),
                  Text(
                    lavoro?.nome ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.labelMedium?.copyWith(
                      color: ColoriLaguna.testoSecondario,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TestoCronometro(
              inizio: acceso.inizio,
              adesso: dati.adesso,
              stile: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ColoriLaguna.testo,
              ),
            ),
            const SizedBox(width: 8),
            PulsanteLucido(
              etichetta: 'Ferma',
              icona: Icons.stop_rounded,
              stile: StileLucido.rosso,
              onPressed: () => fermaCronometro(context, dati),
            ),
          ],
        ),
      ),
    );
  }
}
