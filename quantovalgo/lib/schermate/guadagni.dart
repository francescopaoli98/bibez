import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/introiti.dart';
import '../logica/mesi.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/selettore_mese.dart';
import '../widget/stato_vuoto.dart';
import 'foglio_introito.dart';

/// "Guadagni veloci": l'elenco dei soldi entrati senza un lavoro, mese per
/// mese. Toccane uno per correggerlo o toglierlo.
class GuadagniPagina extends StatefulWidget {
  const GuadagniPagina({super.key});

  @override
  State<GuadagniPagina> createState() => _GuadagniPaginaState();
}

class _GuadagniPaginaState extends State<GuadagniPagina> {
  /// Mese mostrato; finché non si cambia è quello di oggi.
  DateTime? _meseScelto;

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;
    final mese = _meseScelto ?? primoDelMese(dati.adesso());
    final delMese = dati.introitiDelMese(mese);

    return PaginaSecondaria(
      titolo: 'Guadagni veloci',
      sottotitolo: 'Soldi entrati senza un lavoro',
      figli: [
        SelettoreMese(
          mese: mese,
          onCambia: (m) => setState(() => _meseScelto = m),
        ),
        const SizedBox(height: 12),
        CartaVetro(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Totale di ${nomeMese(mese)}',
                  style: tema.titleMedium,
                ),
              ),
              Text(
                euro(totaleIntroiti(delMese)),
                key: const Key('totale-introiti'),
                style: tema.titleLarge?.copyWith(color: ColoriLaguna.positivo),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (delMese.isEmpty)
          const StatoVuoto(
            icona: Icons.savings_outlined,
            titolo: 'Nessun guadagno veloce',
            testo:
                'Aggiungi i soldi che entrano senza un lavoro vero e proprio.',
          )
        else
          for (final i in delMese) ...[
            CartaVetro(
              onTap: () => modificaIntroito(context, esistente: i),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.nota.isEmpty ? 'Guadagno' : i.nota,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.titleMedium,
                        ),
                        Text(
                          descrizioneGiorno(i.data),
                          style: tema.bodyMedium?.copyWith(
                            color: ColoriLaguna.testoSecondario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    euro(i.importo, conSegno: true),
                    style: tema.titleMedium?.copyWith(
                      color: ColoriLaguna.positivo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 4),
        PulsanteLucido(
          key: const Key('aggiungi-introito'),
          etichetta: 'Aggiungi guadagno',
          icona: Icons.add_rounded,
          altezza: 54,
          onPressed: () => modificaIntroito(context),
        ),
      ],
    );
  }
}
