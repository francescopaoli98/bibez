import 'package:flutter/material.dart';

import '../logica/costi.dart';
import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../modelli/costo.dart';
import '../modelli/tipi.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../tema/palette_categorie.dart';
import '../widget/barra_quote.dart';
import '../widget/carta_vetro.dart';
import '../widget/hero_laguna.dart';
import '../widget/pillola_lucida.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/selettore_mese.dart';
import '../widget/stato_vuoto.dart';
import '../widget/stile_lucido.dart';
import 'foglio_categoria.dart';
import 'foglio_costo.dart';
import 'scheda.dart';

/// Scheda Costi: i costi di un mese, divisi tra i progetti e per categoria.
class CostiPagina extends StatefulWidget {
  const CostiPagina({super.key});

  @override
  State<CostiPagina> createState() => _CostiPaginaState();
}

class _CostiPaginaState extends State<CostiPagina> {
  /// Mese mostrato; finché non si cambia è quello di oggi.
  DateTime? _meseScelto;

  void _vaiA(DateTime mese) => setState(() => _meseScelto = mese);

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;
    final mese = _meseScelto ?? primoDelMese(dati.adesso());

    // Costi che pesano nel mese scelto e costi che in questo mese non pesano
    final delMese = [
      for (final c in dati.costi)
        if (quotaNelMese(c, mese) > 0) c,
    ];
    final altri = [
      for (final c in dati.costi)
        if (quotaNelMese(c, mese) <= 0) c,
    ];
    final totale = dati.costiDelMese(mese);
    final gruppi = dati.gruppiDaRecuperare();

    return Scheda(
      titolo: 'Costi',
      sottotitolo: 'Abbonamenti e spese, divisi sui progetti',
      figli: [
        SelettoreMese(mese: mese, onCambia: _vaiA),
        const SizedBox(height: 12),
        _HeroCosti(
          dati: dati,
          mese: mese,
          costiDelMese: delMese,
          totale: totale,
        ),
        if (gruppi.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CartaDaRecuperare(gruppi: gruppi),
        ],
        if (delMese.any(
          (c) => c.categoriaId != null && dati.categoria(c.categoriaId) != null,
        )) ...[
          const SizedBox(height: 12),
          _CartaCategorie(dati: dati, mese: mese, costi: delMese),
        ],
        const SizedBox(height: 12),
        if (delMese.isEmpty)
          StatoVuoto(
            icona: Icons.euro_rounded,
            titolo: dati.costi.isEmpty
                ? 'Nessun costo'
                : 'Nessun costo a ${nomeMese(mese)}',
            testo: 'Aggiungi abbonamenti, attrezzatura e spese fisse.',
          )
        else
          for (final c in delMese) ...[
            _CartaCosto(dati: dati, costo: c, mese: mese),
            const SizedBox(height: 12),
          ],
        if (altri.isNotEmpty) ...[
          Semantics(
            header: true,
            child: Text('Non in questo mese', style: tema.titleLarge),
          ),
          const SizedBox(height: 8),
          for (final c in altri) ...[
            _RigaAltroCosto(costo: c, mese: mese),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 4),
        PulsanteLucido(
          etichetta: 'Aggiungi costo',
          icona: Icons.add_rounded,
          altezza: 54,
          onPressed: () => modificaCosto(context, mese: mese),
        ),
        const SizedBox(height: 10),
        PulsanteLucido(
          etichetta: 'Gestisci categorie',
          icona: Icons.palette_rounded,
          onPressed: () => gestisciCategorie(context),
        ),
      ],
    );
  }
}

/// Riquadro grande: costi del mese.
class _HeroCosti extends StatelessWidget {
  const _HeroCosti({
    required this.dati,
    required this.mese,
    required this.costiDelMese,
    required this.totale,
  });

  final StatoDati dati;
  final DateTime mese;
  final List<Costo> costiDelMese;
  final double totale;

  @override
  Widget build(BuildContext context) {
    // "Tutto assegnato" se ogni costo da dividere ha almeno un progetto attivo
    final daDividere = costiDelMese
        .where((c) => c.siDivideTraProgetti)
        .toList();
    final tuttoAssegnato = daDividere.every(
      (c) => dati.quoteDelCosto(c, mese).isNotEmpty,
    );

    return HeroLaguna(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Costi di ${nomeMese(mese)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ColoriLaguna.testoChiaro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        euro(totale),
                        style: const TextStyle(
                          fontSize: 42,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: ColoriLaguna.cifraHero,
                          shadows: [
                            Shadow(
                              color: Color(0x73002838),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (daDividere.isNotEmpty)
                PillolaLucida(
                  testo: tuttoAssegnato ? 'Tutto assegnato' : 'Da assegnare',
                  stile: tuttoAssegnato ? StileLucido.verde : StileLucido.oro,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Barra "Per categoria" con legenda.
class _CartaCategorie extends StatelessWidget {
  const _CartaCategorie({
    required this.dati,
    required this.mese,
    required this.costi,
  });

  final StatoDati dati;
  final DateTime mese;
  final List<Costo> costi;

  @override
  Widget build(BuildContext context) {
    // Somma per categoria; chi non ne ha (o l'ha cancellata) va in "Senza categoria"
    final somme = <String?, double>{};
    for (final c in costi) {
      final id = dati.categoria(c.categoriaId)?.id;
      somme[id] = (somme[id] ?? 0) + quotaNelMese(c, mese);
    }
    final voci = somme.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Color colore(String? id) => id == null
        ? const Color(0xFF9DB5BF)
        : coloreDellaPalette(dati.categoria(id)!.colore).colore;
    String nome(String? id) =>
        id == null ? 'Senza categoria' : dati.categoria(id)!.nome;

    return CartaVetro(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Per categoria', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          BarraQuote(
            segmenti: [
              for (final v in voci) SegmentoBarra(colore(v.key), v.value),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final v in voci)
                VoceLegenda(
                  colore: colore(v.key),
                  testo: '${nome(v.key)} ${euro(v.value)}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Un costo del mese: nome, importo, come è diviso tra i progetti.
class _CartaCosto extends StatelessWidget {
  const _CartaCosto({
    required this.dati,
    required this.costo,
    required this.mese,
  });

  final StatoDati dati;
  final Costo costo;
  final DateTime mese;

  String _descrizione(List<Quota> quote, TipoLavoro? tipoLegato) {
    // "Claude": solo i progetti di quel tipo dividono il costo
    final di = tipoLegato == null ? '' : ' ${tipoLegato.etichetta}';
    final nessuno = tipoLegato == null
        ? 'nessun progetto attivo'
        : 'nessun progetto$di attivo: si accumula da recuperare';
    switch (costo.tipo) {
      case TipoCosto.abbonamento:
        return quote.isEmpty
            ? 'Abbonamento · $nessuno'
            : 'Abbonamento · usato su ${quote.length} ${quote.length == 1 ? 'progetto' : 'progetti'}$di';
      case TipoCosto.unaTantum:
        final progetti = quote.isEmpty ? ' · $nessuno' : '';
        if (costo.mesi <= 1) {
          return 'Acquisto da ${euro(costo.importo)}, tutto in questo mese$progetti';
        }
        final k = differenzaMesi(primoDelMese(costo.inizio), mese) + 1;
        return 'Acquisto da ${euro(costo.importo)}, spalmato su ${costo.mesi} mesi (mese $k di ${costo.mesi})$progetti';
      case TipoCosto.fisso:
        return 'Costo fisso · non si divide tra i progetti';
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = dati.quoteDelCosto(costo, mese);
    final categoria = dati.categoria(costo.categoriaId);
    final tema = Theme.of(context).textTheme;
    final ricorrente = costo.tipo != TipoCosto.unaTantum || costo.mesi > 1;

    return CartaVetro(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onTap: () => modificaCosto(context, mese: mese, esistente: costo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  costo.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.titleMedium?.copyWith(fontSize: 17),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${euro(quotaNelMese(costo, mese))}${ricorrente ? '/mese' : ''}',
                style: tema.titleMedium?.copyWith(fontSize: 17),
              ),
            ],
          ),
          Text(
            _descrizione(quote, dati.tipoDelCosto(costo)),
            style: tema.labelMedium?.copyWith(
              color: ColoriLaguna.testoSecondario,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (categoria != null) ...[
            const SizedBox(height: 6),
            VoceLegenda(
              colore: coloreDellaPalette(categoria.colore).colore,
              testo: categoria.nome,
            ),
          ],
          if (quote.isNotEmpty) ...[
            const SizedBox(height: 8),
            BarraQuote(
              segmenti: [
                for (final q in quote)
                  SegmentoBarra(
                    coloreDellaPalette(dati.indiceColoreProgetto(q.lavoroId))
                        .colore,
                    q.importo,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final q in quote)
                  VoceLegenda(
                    colore: coloreDellaPalette(
                      dati.indiceColoreProgetto(q.lavoroId),
                    ).colore,
                    testo:
                        '${dati.lavoro(q.lavoroId)?.nome ?? 'Progetto'} ${euro(q.importo)}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Costo che nel mese scelto non pesa (finito, disdetto o non ancora iniziato).
class _RigaAltroCosto extends StatelessWidget {
  const _RigaAltroCosto({required this.costo, required this.mese});

  final Costo costo;
  final DateTime mese;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final iniziato = differenzaMesi(primoDelMese(costo.inizio), mese) >= 0;
    final motivo = iniziato
        ? (costo.tipo == TipoCosto.unaTantum ? 'finito' : 'disdetto')
        : 'inizia a ${nomeMeseAnno(costo.inizio)}';

    return CartaVetro(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => modificaCosto(context, mese: mese, esistente: costo),
      child: Row(
        children: [
          Expanded(
            child: Text(
              costo.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.titleMedium,
            ),
          ),
          Text(
            '${costo.tipo.etichetta} · $motivo',
            style: tema.labelMedium?.copyWith(
              color: ColoriLaguna.testoSecondario,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Da recuperare" diviso per tipo di lavoro: ogni riga si copre con l'utile
/// dei progetti incassati di quel tipo (Claude con i progetti Claude…).
class _CartaDaRecuperare extends StatelessWidget {
  const _CartaDaRecuperare({required this.gruppi});

  final List<GruppoRecupero> gruppi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return CartaVetro(
      colori: const [Color(0xFFFFF6C4), Color(0xFFFFE98F)],
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('Da recuperare', style: tema.titleMedium),
          ),
          for (final g in gruppi) ...[
            const SizedBox(height: 10),
            Text(
              g.tipo == null ? 'Altri costi' : g.tipo!.etichetta,
              style: tema.labelLarge,
            ),
            Text(
              'Da recuperare ${euro(g.residuo)} di ${euro(g.totale)}',
              style: tema.bodyMedium,
            ),
            const SizedBox(height: 4),
            Semantics(
              label: 'Recuperato il ${(g.avanzamento * 100).round()} per cento',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: g.avanzamento,
                  minHeight: 12,
                  backgroundColor: const Color(0x40795500),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF1A8F2E)),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              g.tipo == null
                  ? 'Si copre con l\'utile che avanza dagli altri progetti incassati'
                  : 'Si copre solo con l\'utile dei progetti ${g.tipo!.etichetta} incassati',
              style: tema.labelMedium?.copyWith(
                color: ColoriLaguna.testoSecondario,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
