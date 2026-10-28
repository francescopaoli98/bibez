import 'package:flutter/material.dart';

import '../logica/calcoli.dart';
import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../modelli/lavoro.dart';
import '../modelli/sottoprogetto.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/foglio_laguna.dart';
import '../widget/hero_laguna.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pillola_lucida.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/riga_progetto.dart';
import '../widget/sfera_lucida.dart';
import '../widget/stato_vuoto.dart';
import '../widget/stile_lucido.dart';
import 'foglio_sottoprogetto.dart';
import 'nuovo_lavoro.dart';

/// Un progetto: saldo, sconto regalato e sottoprogetti con ore e utile.
class ProgettoPagina extends StatelessWidget {
  const ProgettoPagina({super.key, required this.lavoroId});

  final String lavoroId;

  Future<void> _elimina(BuildContext context, Lavoro lavoro) async {
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
