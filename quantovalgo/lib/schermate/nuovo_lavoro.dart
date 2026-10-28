import 'package:flutter/material.dart';

import '../logica/calcoli.dart';
import '../logica/formato.dart';
import '../modelli/cliente.dart';
import '../modelli/lavoro.dart';
import '../modelli/sottoprogetto.dart';
import '../modelli/tipi.dart';
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
import 'foglio_forbice.dart';
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

  TipoLavoro _tipo = TipoLavoro.doppiaggio;
  int _livello = 3;
  Relazione _relazione = Relazione.nuovo;

  /// Falso finché il prezzo finale si calcola da solo; vero se l'hai scritto tu.
  bool _finaleScrittoAMano = false;
  bool _iniziato = false;
  bool _salvato = false; // evita doppio tocco su "Salva"

  String? _erroreNome;
  String? _errorePieno;
  String? _erroreFinale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniziato) return;
    _iniziato = true;

    final l = widget.esistente;
    if (l == null) return;
    final dati = DatiScope.leggi(context);
    _nome.text = l.nome;
    _tipo = l.tipo;
    _livello = l.livello;
    _relazione = l.relazione;
    _cliente.text = dati.cliente(l.clienteId)?.nome ?? '';
    _pieno.text = l.prezzoPieno == 0 ? '' : numeroPerCampo(l.prezzoPieno);
    _finale.text = l.prezzoFinale == 0 ? '' : numeroPerCampo(l.prezzoFinale);
    _finaleScrittoAMano = true; // in modifica non si tocca da solo
  }

  @override
  void dispose() {
    _nome.dispose();
    _cliente.dispose();
    _pieno.dispose();
    _finale.dispose();
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

  void _salva() {
    if (_salvato) return;

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
      relazione: _relazione,
      livello: _livello,
      prezzoPieno: pieno!,
      prezzoFinale: finale!,
      statoPagamento: vecchio?.statoPagamento ?? StatoPagamento.daIncassare,
      scadenza: vecchio?.scadenza,
      dataIncasso: vecchio?.dataIncasso,
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
    final mercato = dati.mercatoPer(_tipo);
    final sconto = dati.parametri.sconto(_relazione);

    // Prezzo suggerito con lo sconto e, per il "regalo", senza sconto.
    Forbice? suggerito;
    Forbice? senzaSconto;
    if (mercato != null) {
      final forbice = Forbice(mercato.minimo, mercato.massimo);
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
            for (final t in TipoLavoro.values)
              PulsanteScelta(
                etichetta: t.etichetta,
                selezionato: t == _tipo,
                stileSelezionato: StileLucido.oro,
                onTap: () => setState(() => _tipo = t),
              ),
          ],
        ),
        const SizedBox(height: 12),
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
        _RiquadroPrezzo(
          mercato: mercato == null
              ? null
              : Forbice(mercato.minimo, mercato.massimo),
          manuale: mercato?.manuale ?? true,
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
    required this.suggerito,
    required this.senzaSconto,
    required this.sconto,
    required this.relazione,
    required this.onModifica,
  });

  final Forbice? mercato;
  final bool manuale;
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
              // La ricerca sul web arriva nel passo 9: per ora spenta.
              const PulsanteLucido(
                etichetta: 'Cerca prezzi',
                icona: Icons.search_rounded,
                stile: StileLucido.oro,
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mercato == null
                ? 'Inserisci la forbice a mano. La ricerca sul web arriverà più avanti.'
                : manuale
                ? 'Inserita a mano · la cambi quando vuoi'
                : 'Da ricerca web · la aggiorni quando vuoi',
            style: chiaro,
          ),
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
