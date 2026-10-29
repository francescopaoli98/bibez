import 'package:flutter/material.dart';

import '../logica/apprendimento.dart';
import '../logica/calcoli.dart';
import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../logica/prezzi_web.dart';
import '../modelli/cliente.dart';
import '../modelli/lavoro.dart';
import '../modelli/sottoprogetto.dart';
import '../modelli/tipi.dart';
import '../servizi/servizi_app.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/campo_testo.dart';
import '../widget/hero_laguna.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/pulsante_scelta.dart';
import '../widget/selettore_livello.dart';
import '../widget/selettore_relazione.dart';
import '../widget/stile_lucido.dart';
import 'foglio_categoria.dart';
import 'foglio_forbice.dart';
import 'foglio_ricerca.dart';
import 'progetto.dart';

/// Modulo "Nuovo lavoro". Con [esistente] diventa "Modifica lavoro".
///
/// Mostra la forbice di mercato (inserita a mano) e il prezzo suggerito:
/// forbice × fattore competenza × (1 − sconto della relazione).
class NuovoLavoroPagina extends StatefulWidget {
  const NuovoLavoroPagina({super.key, this.esistente});

  final Lavoro? esistente;

  @override
  State<NuovoLavoroPagina> createState() => _NuovoLavoroPaginaState();
}

class _NuovoLavoroPaginaState extends State<NuovoLavoroPagina> {
  final _nome = TextEditingController();
  final _cliente = TextEditingController();
  final _pieno = TextEditingController();
  final _finale = TextEditingController();
  final _tariffa = TextEditingController(text: '30');

  /// Cosa cercare sul web per il prezzo (modificabile; parte da quella del tipo).
  final _domanda = TextEditingController();
  bool _domandaModificata = false; // se l'hai scritta tu, il tipo non la cambia
  String? _erroreDomanda;

  TipoLavoro _tipo = TipoLavoro.doppiaggio;
  int _livello = 3;
  Relazione _relazione = Relazione.nuovo;

  /// Falso finché il prezzo finale si calcola da solo; vero se l'hai scritto tu.
  bool _finaleScrittoAMano = false;
  bool _iniziato = false;
  bool _salvato = false; // evita doppio tocco su "Salva"
  bool _staCercando = false; // ricerca prezzi sul web in corso

  /// Categoria del progetto (la stessa lista dei costi). Finché non la scegli
  /// tu, segue il tipo di lavoro (se una categoria lo ha come "da soli").
  String? _categoriaId;
  bool _categoriaScelta = false;

  /// Cosa si salva: l'id scelto; se hai scelto "Nessuna" di proposito, un testo
  /// vuoto (così non torna la categoria del tipo); se non hai scelto, niente.
  String? get _categoriaPerSalvare =>
      _categoriaId ?? (_categoriaScelta ? '' : null);

  /// La domanda si salva solo se è diversa da quella di partenza del tipo.
  String? get _domandaPerSalvare {
    final testo = _domanda.text.trim();
    return testo.isEmpty || testo == domandaPredefinita[_tipo] ? null : testo;
  }

  String? _erroreNome;
  String? _errorePieno;
  String? _erroreFinale;
  String? _erroreTariffa;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniziato) return;
    _iniziato = true;

    final l = widget.esistente;
    final dati = DatiScope.leggi(context);
    if (l == null) {
      _categoriaId = dati.categoriaPredefinita(_tipo)?.id;
      _domanda.text = domandaPredefinita[_tipo] ?? '';
      return;
    }
    // In modifica si parte dalla categoria che il progetto ha davvero
    _categoriaId = dati.categoriaDelLavoro(l)?.id;
    _categoriaScelta = true;
    _nome.text = l.nome;
    _tipo = l.tipo;
    _livello = l.livello;
    _relazione = l.relazione;
    _cliente.text = dati.cliente(l.clienteId)?.nome ?? '';
    _pieno.text = l.prezzoPieno == 0 ? '' : numeroPerCampo(l.prezzoPieno);
    _finale.text = l.prezzoFinale == 0 ? '' : numeroPerCampo(l.prezzoFinale);
    _finaleScrittoAMano = true; // in modifica non si tocca da solo
    _domandaModificata = l.domandaRicerca != null;
    _domanda.text = l.domandaRicerca ?? domandaPredefinita[l.tipo] ?? '';
    if (l.tariffaGiornaliera != null) {
      _tariffa.text = numeroPerCampo(l.tariffaGiornaliera!);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _cliente.dispose();
    _pieno.dispose();
    _finale.dispose();
    _tariffa.dispose();
    _domanda.dispose();
    super.dispose();
  }

  /// Ricalcola il prezzo finale dal prezzo pieno e dallo sconto.
  void _ricalcolaFinale() {
    if (_finaleScrittoAMano) return;
    final pieno = leggiNumero(_pieno.text);
    final parametri = DatiScope.leggi(context).parametri;
    _finale.text = pieno == null
        ? ''
        : numeroPerCampo(prezzoConSconto(pieno, _relazione, parametri));
  }

  void _scegliCliente(Cliente c) {
    setState(() {
      _cliente.text = c.nome;
      _relazione = c.relazione;
      _ricalcolaFinale();
    });
  }

  /// Lavoro "A giornata": bastano nome e guadagno netto al giorno. I giorni
  /// si aggiungono poi dalla pagina del progetto.
  void _salvaAGiornata() {
    final tariffa = leggiNumero(_tariffa.text);
    setState(() {
      _erroreNome = _nome.text.trim().isEmpty
          ? 'Scrivi il nome del lavoro'
          : null;
      _erroreTariffa = (tariffa == null || tariffa <= 0)
          ? 'Scrivi un importo'
          : null;
    });
    if (_erroreNome != null || _erroreTariffa != null) return;
    _salvato = true;

    final dati = DatiScope.leggi(context);
    final vecchio = widget.esistente;
    final id = dati.salvaLavoro(
      Lavoro(
        id: vecchio?.id ?? '',
        nome: _nome.text.trim(),
        tipo: TipoLavoro.aGiornata,
        categoriaId: _categoriaPerSalvare,
        relazione: vecchio?.relazione ?? Relazione.nuovo,
        livello: vecchio?.livello ?? 3,
        prezzoPieno: 0,
        prezzoFinale: 0,
        tariffaGiornaliera: tariffa,
        creatoIl: vecchio?.creatoIl ?? DateTime.now(),
      ),
    );

    if (vecchio != null) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ProgettoPagina(lavoroId: id)),
      );
    }
  }

  void _salva() {
    if (_salvato) return;
    if (_tipo == TipoLavoro.aGiornata) {
      _salvaAGiornata();
      return;
    }

    final pieno = _pieno.text.trim().isEmpty ? 0.0 : leggiNumero(_pieno.text);
    final finale = _finale.text.trim().isEmpty
        ? 0.0
        : leggiNumero(_finale.text);
    setState(() {
      _erroreNome = _nome.text.trim().isEmpty
          ? 'Scrivi il nome del lavoro'
          : null;
      _errorePieno = pieno == null ? 'Numero non valido' : null;
      _erroreFinale = finale == null ? 'Numero non valido' : null;
    });
    if (_erroreNome != null || _errorePieno != null || _erroreFinale != null) {
      return;
    }
    _salvato = true;

    final dati = DatiScope.leggi(context);
    final vecchio = widget.esistente;

    // Cliente: se il nome esiste già lo riuso, altrimenti lo creo.
    String? clienteId;
    final nomeCliente = _cliente.text.trim();
    if (nomeCliente.isNotEmpty) {
      clienteId =
          dati.clientePerNome(nomeCliente)?.id ??
          dati.salvaCliente(
            Cliente(
              id: '',
              nome: nomeCliente,
              relazione: _relazione,
              creatoIl: DateTime.now(),
            ),
          );
    }

    final lavoro = Lavoro(
      id: vecchio?.id ?? '',
      nome: _nome.text.trim(),
      tipo: _tipo,
      clienteId: clienteId,
      categoriaId: _categoriaPerSalvare,
      relazione: _relazione,
      livello: _livello,
      prezzoPieno: pieno!,
      prezzoFinale: finale!,
      statoPagamento: vecchio?.statoPagamento ?? StatoPagamento.daIncassare,
      scadenza: vecchio?.scadenza,
      dataIncasso: vecchio?.dataIncasso,
      richiestoIl: vecchio?.richiestoIl,
      domandaRicerca: _domandaPerSalvare,
      creatoIl: vecchio?.creatoIl ?? DateTime.now(),
    );
    final id = dati.salvaLavoro(lavoro);

    if (vecchio != null) {
      Navigator.of(context).pop();
      return;
    }

    // Lavoro nuovo con un prezzo: parte con un sottoprogetto "Lavoro intero"
    // che incassa tutto il prezzo, da dividere poi in parti più piccole.
    if (finale > 0) {
      dati.salvaSottoprogetto(
        Sottoprogetto(
          id: '',
          lavoroId: id,
          nome: 'Lavoro intero',
          ricavo: finale,
          costiDiretti: 0,
          ore: 0,
          creatoIl: DateTime.now(),
        ),
      );
    }
    // Si apre subito il progetto appena creato
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ProgettoPagina(lavoroId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final modifica = widget.esistente != null;
    final aGiornata = _tipo == TipoLavoro.aGiornata;
    // Modificando non si passa da "A giornata" a un altro tipo (e viceversa):
    // i dati sono fatti in modo diverso.
    final tipiScelta = [
      for (final t in TipoLavoro.values)
        if (!modifica ||
            (t == TipoLavoro.aGiornata) ==
                (widget.esistente!.tipo == TipoLavoro.aGiornata))
          t,
    ];
    final mercato = dati.mercatoPer(_tipo);
    final sconto = dati.parametri.sconto(_relazione);

    // Prezzo suggerito con lo sconto e, per il "regalo", senza sconto.
    Forbice? suggerito;
    Forbice? senzaSconto;
    if (mercato != null) {
      // La forbice di mercato spostata dalla correzione dei tuoi lavori incassati
      final forbice = dati.forbiceCorretta(_tipo)!;
      suggerito = prezzoSuggerito(
        mercato: forbice,
        livello: _livello,
        relazione: _relazione,
        parametri: dati.parametri,
      );
      senzaSconto = prezzoSuggerito(
        mercato: forbice,
        livello: _livello,
        relazione: Relazione.nuovo,
        parametri: dati.parametri,
      );
    }

    return PaginaSecondaria(
      titolo: modifica ? 'Modifica lavoro' : 'Nuovo lavoro',
      figli: [
        CampoTesto(
          key: const Key('campo-nome'),
          controller: _nome,
          etichetta: 'Nome del lavoro',
          suggerimento: 'Es. Audiolibro «Il bosco»',
          errore: _erroreNome,
          onChanged: (_) {
            if (_erroreNome != null) setState(() => _erroreNome = null);
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'Tipo di lavoro',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in tipiScelta)
              PulsanteScelta(
                etichetta: t.etichetta,
                selezionato: t == _tipo,
                stileSelezionato: StileLucido.oro,
                onTap: () => setState(() {
                  _tipo = t;
                  _erroreDomanda = null;
                  if (!_domandaModificata) {
                    _domanda.text = domandaPredefinita[t] ?? '';
                  }
                  if (!_categoriaScelta) {
                    _categoriaId = DatiScope.leggi(context)
                        .categoriaPredefinita(t)
                        ?.id;
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SelettoreCategoria(
          etichetta: 'Categoria dei costi',
          scelta: _categoriaId,
          onCambia: (id) => setState(() {
            _categoriaId = id;
            _categoriaScelta = true;
          }),
        ),
        const SizedBox(height: 4),
        Text(
          switch ((DatiScope.di(context).categoria(_categoriaId), aGiornata)) {
            (final categoria?, _) =>
              'I costi della categoria «${categoria.nome}» si recuperano con questo progetto.',
            (null, true) =>
              'Senza categoria: il lavoro a giornata non prende costi.',
            (null, false) => 'Senza categoria: prende una parte dei costi generali (quelli senza categoria).',
          },
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: ColoriLaguna.testoSecondario, fontSize: 14),
        ),
        const SizedBox(height: 12),
        if (aGiornata) ...[
          CampoTesto(
            key: const Key('campo-tariffa'),
            controller: _tariffa,
            etichetta: 'Guadagno netto al giorno (€)',
            suggerimento: 'Es. 30',
            numerico: true,
            errore: _erroreTariffa,
            azioneTastiera: TextInputAction.done,
          ),
          const SizedBox(height: 6),
          Text(
            modifica
                ? 'Cambia solo le giornate che aggiungerai da ora: quelle già inserite restano come sono.'
                : 'Dopo il salvataggio scegli i giorni: anche tanti insieme, con lo schema della settimana.',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: ColoriLaguna.testoSecondario, fontSize: 14),
          ),
          const SizedBox(height: 16),
        ] else ...[
          SelettoreLivello(
            livello: _livello,
            onCambia: (n) => setState(() => _livello = n),
          ),
          const SizedBox(height: 12),
          CampoTesto(
            key: const Key('campo-cliente'),
            controller: _cliente,
            etichetta: 'Cliente (facoltativo)',
            suggerimento: 'Es. Luca',
            onChanged: (_) => setState(() {}),
            maiuscole: TextCapitalization.words,
          ),
          if (dati.clienti.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in dati.clienti)
                  PulsanteScelta(
                    etichetta: c.nome,
                    selezionato:
                        c.nome.trim().toLowerCase() ==
                        _cliente.text.trim().toLowerCase(),
                    onTap: () => _scegliCliente(c),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SelettoreRelazione(
            valore: _relazione,
            parametri: dati.parametri,
            onCambia: (r) => setState(() {
              _relazione = r;
              _ricalcolaFinale();
            }),
          ),
          const SizedBox(height: 12),
          _RicercaPersonalizzata(
            controller: _domanda,
            tipo: _tipo,
            errore: _erroreDomanda,
            onCambia: (_) => setState(() {
              _domandaModificata = true;
              _erroreDomanda = null;
            }),
            onSuggerimento: (testo) => setState(() {
              _domanda.text = testo;
              _domandaModificata = true;
              _erroreDomanda = null;
            }),
          ),
          const SizedBox(height: 12),
          _RiquadroPrezzo(
            mercato: mercato == null
                ? null
                : Forbice(mercato.minimo, mercato.massimo),
            manuale: mercato?.manuale ?? true,
            fonti: mercato?.fonti.length ?? 0,
            aggiornato: mercato?.aggiornato,
            correzione: dati.correzioneDi(_tipo),
            staCercando: _staCercando,
            // Senza servizio di ricerca (o per "A giornata") il pulsante è spento
            riferimenti: mercato?.riferimenti.length ?? 0,
            onVediRiferimenti: mercato == null || mercato.riferimenti.isEmpty
                ? null
                : () => mostraRiferimenti(context, mercato),
            onCerca:
                ServiziApp.di(context).ricerca == null || !tipoCercabile(_tipo)
                ? null
                : () {
                    final testo = _domanda.text.trim();
                    // "Altro" non ha una domanda di partenza: la scrivi tu
                    if (testo.isEmpty &&
                        !domandaPredefinita.containsKey(_tipo)) {
                      setState(
                        () => _erroreDomanda = 'Scrivi cosa vuoi cercare',
                      );
                      return;
                    }
                    setState(() => _erroreDomanda = null);
                    cercaPrezziWeb(
                      context,
                      _tipo,
                      domanda: testo,
                      inCorso: (v) {
                        if (mounted) setState(() => _staCercando = v);
                      },
                    );
                  },
            suggerito: suggerito,
            senzaSconto: senzaSconto,
            sconto: sconto,
            relazione: _relazione,
            onModifica: () => modificaForbice(context, _tipo),
          ),
          const SizedBox(height: 12),
          CampoTesto(
            key: const Key('campo-pieno'),
            controller: _pieno,
            etichetta: 'Prezzo pieno (€)',
            suggerimento: 'Es. 1000',
            numerico: true,
            errore: _errorePieno,
            onChanged: (_) => setState(_ricalcolaFinale),
          ),
          const SizedBox(height: 12),
          CampoTesto(
            key: const Key('campo-finale'),
            controller: _finale,
            etichetta: 'Prezzo finale, già scontato (€)',
            suggerimento: _finaleScrittoAMano
                ? 'Es. 700'
                : 'Si calcola dallo sconto',
            numerico: true,
            errore: _erroreFinale,
            azioneTastiera: TextInputAction.done,
            onChanged: (testo) {
              // Se lo svuoti, torna automatico
              _finaleScrittoAMano = testo.trim().isNotEmpty;
              if (!_finaleScrittoAMano) setState(_ricalcolaFinale);
            },
          ),
          const SizedBox(height: 16),
        ],
        PulsanteLucido(
          etichetta: modifica ? 'Salva modifiche' : 'Salva lavoro',
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: _salva,
        ),
      ],
    );
  }
}

/// Riquadro blu: forbice di mercato, prezzo suggerito e sconto regalato.
class _RiquadroPrezzo extends StatelessWidget {
  const _RiquadroPrezzo({
    required this.mercato,
    required this.manuale,
    required this.fonti,
    required this.aggiornato,
    required this.correzione,
    required this.staCercando,
    required this.onCerca,
    required this.riferimenti,
    required this.onVediRiferimenti,
    required this.suggerito,
    required this.senzaSconto,
    required this.sconto,
    required this.relazione,
    required this.onModifica,
  });

  final Forbice? mercato;
  final bool manuale;
  final int fonti;
  final DateTime? aggiornato;
  final CorrezioneTipo? correzione;
  final bool staCercando;

  /// Vuoto: la ricerca non c'è per questo tipo e il pulsante è spento.
  final VoidCallback? onCerca;

  /// Quanti prezzi di riferimento ha la forbice trovata sul web.
  final int riferimenti;
  final VoidCallback? onVediRiferimenti;
  final Forbice? suggerito;
  final Forbice? senzaSconto;
  final int sconto;
  final Relazione relazione;
  final VoidCallback onModifica;

  @override
  Widget build(BuildContext context) {
    const chiaro = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: ColoriLaguna.testoChiaro,
    );
    final suggerimento = suggerito;
    final pieno = senzaSconto;

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
                    const Text(
                      'Prezzo di mercato',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ColoriLaguna.testoChiaro,
                      ),
                    ),
                    Text(
                      mercato == null
                          ? 'Da inserire'
                          : euroForbice(mercato!.minimo, mercato!.massimo),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              PulsanteLucido(
                etichetta: staCercando ? 'Cerco…' : 'Cerca prezzi',
                icona: Icons.search_rounded,
                stile: StileLucido.oro,
                onPressed: staCercando ? null : onCerca,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mercato == null
                ? (onCerca == null
                      ? 'Scrivi la forbice a mano.'
                      : 'Cerca i prezzi sul web o scrivi la forbice a mano.')
                : manuale
                ? 'Inserita a mano · la cambi quando vuoi'
                : 'Da ricerca web ($fonti ${fonti == 1 ? 'sito' : 'siti'})'
                      '${aggiornato == null ? '' : ' · ${dataLunga(aggiornato!)}'}',
            style: chiaro,
          ),
          if (correzione != null && correzione!.correzione != 0) ...[
            const SizedBox(height: 4),
            Text(
              'Corretta del ${percentuale((correzione!.correzione * 100).round(), conSegno: true)} '
              'sui tuoi ultimi ${correzione!.lavori} lavori incassati',
              style: chiaro.copyWith(color: ColoriLaguna.cifraHero),
            ),
          ],
          if (onVediRiferimenti != null) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              key: const Key('vedi-riferimenti'),
              onPressed: onVediRiferimenti,
              icon: const Icon(Icons.fact_check_outlined),
              label: Text('Vedi i prezzi di riferimento ($riferimenti)'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ],
          const SizedBox(height: 10),
          PulsanteLucido(
            etichetta: mercato == null
                ? 'Inserisci forbice'
                : 'Modifica forbice',
            icona: Icons.edit_rounded,
            onPressed: onModifica,
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            sconto == 0
                ? 'Nessuno sconto: chiedi la forbice piena'
                : 'Con sconto ${relazione.etichetta.toLowerCase()} (−$sconto%) chiedi',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            suggerimento == null
                ? '—'
                : euroForbice(suggerimento.minimo, suggerimento.massimo),
            style: const TextStyle(
              fontSize: 44,
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
          const SizedBox(height: 6),
          if (suggerimento != null && pieno != null)
            Text(
              sconto == 0
                  ? 'Non regali nulla'
                  : 'Regali circa ${euroForbice(pieno.minimo - suggerimento.minimo, pieno.massimo - suggerimento.massimo)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

/// "Cosa vuoi cercare?": la domanda per il prezzo di mercato, con idee da
/// toccare e l'anteprima di quello che verrà cercato davvero.
class _RicercaPersonalizzata extends StatelessWidget {
  const _RicercaPersonalizzata({
    required this.controller,
    required this.tipo,
    required this.errore,
    required this.onCambia,
    required this.onSuggerimento,
  });

  final TextEditingController controller;
  final TipoLavoro tipo;
  final String? errore;
  final ValueChanged<String> onCambia;
  final ValueChanged<String> onSuggerimento;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final grigio = tema.labelMedium?.copyWith(
      color: ColoriLaguna.testoSecondario,
      fontWeight: FontWeight.w600,
    );
    final testo = controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampoTesto(
          key: const Key('campo-domanda'),
          controller: controller,
          etichetta: 'Cosa vuoi cercare? (prezzo di mercato)',
          suggerimento: 'Es. servizio installazione e configurazione tablet',
          maiuscole: TextCapitalization.none,
          errore: errore,
          onChanged: onCambia,
        ),
        const SizedBox(height: 6),
        Text(
          'Cerca il prezzo del servizio intero (a intervento o a lavoro), non '
          'le tariffe orarie né i prodotti. Aggiungo io "Italia", "prezzo" ed "euro".',
          style: grigio,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final idea in suggerimentiPerTipo[tipo] ?? const <String>[])
              _Idea(
                testo: idea,
                scelta: testo == idea,
                onTap: () => onSuggerimento(idea),
              ),
          ],
        ),
        if (testo.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Cercherò: «${costruisciQuery(testo)}»',
            key: const Key('anteprima-domanda'),
            style: grigio,
          ),
        ],
      ],
    );
  }
}

/// Un'idea di ricerca da toccare: il testo va a capo, non si taglia.
class _Idea extends StatelessWidget {
  const _Idea({required this.testo, required this.scelta, required this.onTap});

  final String testo;
  final bool scelta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scelta ? const Color(0xFFFFE98F) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: scelta ? const Color(0xFFD9A400) : const Color(0xFF6FCBEF),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            testo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: ColoriLaguna.testo,
            ),
          ),
        ),
      ),
    );
  }
}
