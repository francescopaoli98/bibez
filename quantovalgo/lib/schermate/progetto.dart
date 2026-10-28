import 'package:flutter/material.dart';

import '../logica/calcoli.dart';
import '../logica/formato.dart';
import '../logica/giornate.dart';
import '../logica/mesi.dart';
import '../modelli/lavoro.dart';
import '../modelli/sottoprogetto.dart';
import '../modelli/tipi.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/calendario_giorni.dart';
import '../widget/carta_vetro.dart';
import '../widget/foglio_laguna.dart';
import '../widget/hero_laguna.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pillola_lucida.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/riga_progetto.dart';
import '../widget/selettore_mese.dart';
import '../widget/sfera_lucida.dart';
import '../widget/stato_vuoto.dart';
import '../widget/stile_lucido.dart';
import 'aggiungi_giornate.dart';
import 'foglio_giornata.dart';
import 'foglio_sottoprogetto.dart';
import 'nuovo_lavoro.dart';

/// Un progetto: saldo, sconto regalato e sottoprogetti con ore e utile.
class ProgettoPagina extends StatelessWidget {
  const ProgettoPagina({super.key, required this.lavoroId});

  final String lavoroId;

  static Future<void> _elimina(BuildContext context, Lavoro lavoro) async {
    final navigatore = Navigator.of(context);
    final dati = DatiScope.leggi(context);
    final conferma = await chiediConferma(
      context,
      titolo: 'Eliminare il progetto?',
      testo: '"${lavoro.nome}" e tutti i suoi sottoprogetti spariranno.',
      etichettaConferma: 'Elimina',
    );
    if (!conferma) return;
    navigatore.pop();
    dati.eliminaLavoro(lavoro.id);
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final lavoro = dati.lavoro(lavoroId);

    // Il progetto è appena stato eliminato: la pagina si sta chiudendo.
    if (lavoro == null) return const PaginaSecondaria(titolo: '', figli: []);

    // I lavori a giornata hanno una pagina tutta loro: giornate e calendario
    if (lavoro.tipo == TipoLavoro.aGiornata) {
      return _ProgettoGiornate(lavoro: lavoro);
    }

    final numeri = dati.riepilogoDi(lavoro.id);
    final sottoprogetti = dati.sottoprogettiDi(lavoro.id);
    final cliente = dati.cliente(lavoro.clienteId);
    final sconto = dati.parametri.sconto(lavoro.relazione);
    final regalato = scontoRegalato(lavoro.prezzoPieno, lavoro.prezzoFinale);
    final tema = Theme.of(context).textTheme;
    final meseAttuale = primoDelMese(DateTime.now());
    final quotaCosti = dati.quotaCostiDelLavoro(lavoro.id, meseAttuale);

    return PaginaSecondaria(
      titolo: lavoro.nome,
      sottotitolo: [
        lavoro.tipo.etichetta,
        cliente?.nome ?? 'senza cliente',
        lavoro.relazione.breve,
      ].join(' · '),
      destra: SferaLucida(
        icona: Icons.edit_rounded,
        etichetta: 'Modifica lavoro',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NuovoLavoroPagina(esistente: lavoro),
          ),
        ),
      ),
      figli: [
        _HeroProgetto(numeri: numeri),
        if (lavoro.prezzoPieno > 0) ...[
          const SizedBox(height: 12),
          CartaVetro(
            colori: const [Color(0xFFFFF6C4), Color(0xFFFFE98F)],
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prezzo pieno ${euro(lavoro.prezzoPieno)} · applicato ${euro(lavoro.prezzoFinale)}',
                        style: tema.labelMedium?.copyWith(fontSize: 14),
                      ),
                      Text(
                        sconto == 0
                            ? 'Nessuno sconto'
                            : 'Sconto ${lavoro.relazione.breve} −$sconto%',
                        style: tema.labelLarge,
                      ),
                    ],
                  ),
                ),
                if (regalato > 0) ...[
                  const SizedBox(width: 8),
                  _EtichettaRegalo(testo: 'Regali ${euro(regalato)}'),
                ],
              ],
            ),
          ),
        ],
        // Parte di abbonamenti e acquisti che tocca a questo progetto
        if (quotaCosti > 0) ...[
          const SizedBox(height: 12),
          CartaVetro(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Costi condivisi di ${nomeMese(meseAttuale)}: ${euro(quotaCosti)}',
                        style: tema.labelMedium?.copyWith(fontSize: 14),
                      ),
                      Text(
                        'Utile dopo i costi condivisi',
                        style: tema.labelMedium?.copyWith(
                          color: ColoriLaguna.testoSecondario,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  euro(numeri.utile - quotaCosti, conSegno: true),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: coloreImporto(numeri.utile - quotaCosti),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Sottoprogetti', style: tema.titleLarge),
              ),
            ),
            PulsanteLucido(
              etichetta: '+ Aggiungi',
              onPressed: () =>
                  modificaSottoprogetto(context, lavoroId: lavoro.id),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sottoprogetti.isEmpty)
          const StatoVuoto(
            icona: Icons.account_tree_outlined,
            titolo: 'Nessun sottoprogetto',
            testo: 'Dividi il lavoro in parti (es. registrazione, montaggio).',
          )
        else
          for (final s in sottoprogetti) ...[
            _RigaSottoprogetto(sottoprogetto: s, lavoroId: lavoro.id),
            const SizedBox(height: 8),
          ],
        // Avviso se le parti non sommano al prezzo concordato
        if (lavoro.prezzoFinale > 0 &&
            sottoprogetti.isNotEmpty &&
            (numeri.ricavi - lavoro.prezzoFinale).abs() >= 0.5) ...[
          const SizedBox(height: 4),
          CartaVetro(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: ColoriLaguna.testoSecondario,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'I ricavi dei sottoprogetti (${euro(numeri.ricavi)}) non sono '
                    'uguali al prezzo finale (${euro(lavoro.prezzoFinale)}).',
                    style: tema.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        PulsanteLucido(
          etichetta: 'Elimina progetto',
          icona: Icons.delete_outline_rounded,
          stile: StileLucido.rosso,
          onPressed: () => _elimina(context, lavoro),
        ),
      ],
    );
  }
}

/// Riquadro grande: saldo del progetto con ricavi, costi e guadagno all'ora.
class _HeroProgetto extends StatelessWidget {
  const _HeroProgetto({required this.numeri});

  final RiepilogoLavoro numeri;

  @override
  Widget build(BuildContext context) {
    final utile = numeri.utile;
    final (testoStato, stileStato) = utile > 0
        ? ('In positivo', StileLucido.verde)
        : utile < 0
        ? ('In negativo', StileLucido.rosso)
        : ('In pari', StileLucido.blu);
    final ora = numeri.guadagnoOra;

    return HeroLaguna(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo del progetto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColoriLaguna.testoChiaro,
                ),
              ),
              PillolaLucida(testo: testoStato, stile: stileStato),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            euro(utile, conSegno: true),
            style: const TextStyle(
              fontSize: 46,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Dato(etichetta: 'Ricavi', valore: euro(numeri.ricavi)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Dato(etichetta: 'Costi', valore: euro(numeri.costi)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Dato(
                  etichetta: "All'ora",
                  valore: ora == null ? '—' : '${euro(ora)}/h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Casella trasparente dentro il riquadro grande.
class _Dato extends StatelessWidget {
  const _Dato({required this.etichetta, required this.valore});

  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etichetta,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ColoriLaguna.testoChiaro,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valore,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Regali 300 €" in una pillola bianca con bordo dorato.
class _EtichettaRegalo extends StatelessWidget {
  const _EtichettaRegalo({required this.testo});

  final String testo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF0C36A)),
      ),
      child: Text(
        testo,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF6B2A10),
        ),
      ),
    );
  }
}

/// Riga di un sottoprogetto: nome, ore, ricavo, costi e utile.
class _RigaSottoprogetto extends StatelessWidget {
  const _RigaSottoprogetto({
    required this.sottoprogetto,
    required this.lavoroId,
  });

  final Sottoprogetto sottoprogetto;
  final String lavoroId;

  @override
  Widget build(BuildContext context) {
    final s = sottoprogetto;
    final tema = Theme.of(context).textTheme;
    return CartaVetro(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () =>
          modificaSottoprogetto(context, lavoroId: lavoroId, esistente: s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nome, style: tema.titleMedium),
                Text(
                  '${ore(s.ore)} · incasso ${euro(s.ricavo)} · costi ${euro(s.costiDiretti)}',
                  style: tema.labelMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            euro(s.utile, conSegno: true),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: coloreImporto(s.utile),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pagina di un lavoro "A giornata": guadagno, giornate fatte e in programma,
/// calendario del mese da toccare per aggiungere, cambiare o togliere un giorno.
class _ProgettoGiornate extends StatefulWidget {
  const _ProgettoGiornate({required this.lavoro});

  final Lavoro lavoro;

  @override
  State<_ProgettoGiornate> createState() => _ProgettoGiornateState();
}

class _ProgettoGiornateState extends State<_ProgettoGiornate> {
  DateTime? _mese; // mese mostrato nel calendario (all'inizio: quello di oggi)

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final lavoro = widget.lavoro;
    final tema = Theme.of(context).textTheme;
    final oggi = soloData(dati.adesso());
    final mese = _mese ?? primoDelMese(oggi);
    final tariffa = lavoro.tariffaGiornaliera ?? 0;

    final fatte = dati.giornateFatte(lavoro.id);
    final inProgramma = dati.giornateInProgramma(lavoro.id);
    final tutte = dati.giornateDi(lavoro.id);
    final delMese = [
      for (final g in tutte)
        if (primoDelMese(g.data) == mese) g,
    ];

    return PaginaSecondaria(
      titolo: lavoro.nome,
      sottotitolo: 'A giornata · ${euro(tariffa)} al giorno',
      destra: SferaLucida(
        icona: Icons.edit_rounded,
        etichetta: 'Modifica lavoro',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NuovoLavoroPagina(esistente: lavoro),
          ),
        ),
      ),
      figli: [
        HeroLaguna(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Guadagno netto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColoriLaguna.testoChiaro,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                euro(totaleGiornate(fatte), conSegno: true),
                style: const TextStyle(
                  fontSize: 46,
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Dato(
                      etichetta: 'Giornate',
                      valore: numeroPerCampo(numeroGiornate(fatte)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Dato(
                      etichetta: 'In programma',
                      valore: numeroPerCampo(numeroGiornate(inProgramma)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Dato(etichetta: 'Al giorno', valore: euro(tariffa)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Giornate', style: tema.titleLarge),
              ),
            ),
            PulsanteLucido(
              etichetta: '+ Aggiungi',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AggiungiGiornatePagina(lavoroId: lavoro.id),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SelettoreMese(mese: mese, onCambia: (m) => setState(() => _mese = m)),
        const SizedBox(height: 8),
        CalendarioGiorni(
          mese: mese,
          oggi: oggi,
          verdi: {for (final g in fatte) g.data},
          blu: {for (final g in inProgramma) g.data},
          mezze: {
            for (final g in tutte)
              if (g.mezza) g.data,
          },
          onTapGiorno: (giorno) {
            final esistente = tutte.where((g) => g.data == giorno).firstOrNull;
            modificaGiornata(
              context,
              lavoroId: lavoro.id,
              data: giorno,
              tariffa: tariffa,
              esistente: esistente,
            );
          },
          etichettaGiorno: (giorno, stato) {
            final nome = descrizioneGiorno(giorno);
            final g = tutte.where((g) => g.data == giorno).firstOrNull;
            return switch (stato) {
              StatoGiorno.normale => '$nome, libero: tocca per aggiungere',
              _ =>
                '$nome, ${g?.mezza == true ? 'mezza giornata, ' : ''}${euro(g?.importo ?? 0)}: tocca per modificare',
            };
          },
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            _LegendaGiorno(colore: Color(0xFF1A8F2E), testo: 'Fatte'),
            SizedBox(width: 16),
            _LegendaGiorno(colore: Color(0xFF0F72A8), testo: 'In programma'),
          ],
        ),
        const SizedBox(height: 12),
        CartaVetro(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  delMese.isEmpty
                      ? 'Nessuna giornata a ${nomeMese(mese)}'
                      : '${testoGiornate(numeroGiornate(delMese))} a ${nomeMese(mese)}',
                  style: tema.titleMedium,
                ),
              ),
              Text(
                euro(totaleGiornate(delMese), conSegno: true),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: coloreImporto(totaleGiornate(delMese)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PulsanteLucido(
          etichetta: 'Elimina progetto',
          icona: Icons.delete_outline_rounded,
          stile: StileLucido.rosso,
          onPressed: () => ProgettoPagina._elimina(context, lavoro),
        ),
      ],
    );
  }
}

class _LegendaGiorno extends StatelessWidget {
  const _LegendaGiorno({required this.colore, required this.testo});

  final Color colore;
  final String testo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colore),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          testo,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
