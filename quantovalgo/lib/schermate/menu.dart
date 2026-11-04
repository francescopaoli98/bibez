import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/sfera_lucida.dart';
import '../widget/stile_lucido.dart';
import 'clienti.dart';
import 'costi.dart';
import 'impostazioni.dart';
import 'obiettivo.dart';
import 'preventivi.dart';
import 'progetti.dart';

/// "Cosa cerchi?": sei grandi tasselli per tutto quello che non sta in Home.
/// Ognuno mostra già un numero vivo, così spesso non serve nemmeno aprirlo.
class AltroPagina extends StatelessWidget {
  const AltroPagina({super.key});

  void _apri(BuildContext context, Widget pagina) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina));
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final mese = primoDelMese(dati.adesso());
    final media = dati.giorniMediPerPagare;
    final avanzamento = dati.pianoObiettivo(mese).avanzamento;
    final nLavori = dati.lavori.length;

    final tasselli = <Widget>[
      _Tassello(
        icona: Icons.work_outline_rounded,
        stile: StileLucido.blu,
        titolo: 'Lavori',
        sotto: nLavori == 0 ? 'ancora nessuno' : '$nLavori in tutto',
        onTap: () => _apri(context, const ProgettiPagina()),
      ),
      _Tassello(
        icona: Icons.euro_rounded,
        stile: StileLucido.rosso,
        titolo: 'Spese',
        sotto: '${euro(dati.costiDelMese(mese))} questo mese',
        onTap: () => _apri(context, const CostiPagina()),
      ),
      _Tassello(
        icona: Icons.people_alt_rounded,
        stile: StileLucido.verde,
        titolo: 'Clienti',
        sotto: media == null
            ? '${dati.clienti.length} in tutto'
            : 'pagano in ${media.round()} giorni',
        onTap: () => _apri(context, const ClientiPagina()),
      ),
      _Tassello(
        icona: Icons.flag_rounded,
        stile: StileLucido.oro,
        titolo: 'Obiettivo',
        sotto: avanzamento == null
            ? 'da impostare'
            : '${(avanzamento * 100).round()}% raggiunto',
        onTap: () => _apri(context, const ObiettivoPagina()),
      ),
      _Tassello(
        icona: Icons.description_outlined,
        stile: StileLucido.blu,
        titolo: 'Preventivi',
        sotto: dati.preventivi.isEmpty
            ? 'crea un\'immagine'
            : '${dati.preventivi.length} fatti',
        onTap: () => _apri(context, const PreventiviPagina()),
      ),
      _Tassello(
        icona: Icons.tune_rounded,
        stile: StileLucido.blu,
        titolo: 'Impostazioni',
        sotto: 'tasse e sconti',
        onTap: () => _apri(context, const ImpostazioniPagina()),
      ),
    ];

    return PaginaSecondaria(
      titolo: 'Cosa cerchi?',
      figli: [
        for (var i = 0; i < tasselli.length; i += 2) ...[
          Row(
            children: [
              Expanded(child: tasselli[i]),
              const SizedBox(width: 12),
              Expanded(child: tasselli[i + 1]),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Un tassello grande: sferetta con icona, titolo e una riga viva.
class _Tassello extends StatelessWidget {
  const _Tassello({
    required this.icona,
    required this.stile,
    required this.titolo,
    required this.sotto,
    required this.onTap,
  });

  final IconData icona;
  final StileLucido stile;
  final String titolo;
  final String sotto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return CartaVetro(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: SizedBox(
        height: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconaSfera(icona: icona, stile: stile, dimensione: 48),
            const Spacer(),
            Text(titolo, style: tema.titleLarge),
            Text(
              sotto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.labelMedium?.copyWith(
                fontSize: 14,
                color: ColoriLaguna.testoSecondario,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
