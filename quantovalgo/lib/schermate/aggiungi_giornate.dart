import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/giornate.dart';
import '../logica/mesi.dart';
import '../modelli/giornata.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/calendario_giorni.dart';
import '../widget/campo_testo.dart';
import '../widget/carta_vetro.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/pulsante_scelta.dart';
import '../widget/selettore_mese.dart';
import '../widget/stile_lucido.dart';

/// Aggiunge più giornate in un colpo solo.
///
/// 1. Si sceglie uno schema: giorni della settimana, giorno di partenza e
///    "per N giorni" oppure "fino al…". L'app riempie il calendario.
/// 2. Sul calendario si toccano i singoli giorni per toglierne o aggiungerne
///    (ferie, giorni saltati). Cambiando lo schema il calendario si rigenera.
/// 3. "Aggiungi" salva tutte le giornate scelte con lo stesso importo.
class AggiungiGiornatePagina extends StatefulWidget {
  const AggiungiGiornatePagina({super.key, required this.lavoroId});

  final String lavoroId;

  @override
  State<AggiungiGiornatePagina> createState() => _AggiungiGiornatePaginaState();
}

class _AggiungiGiornatePaginaState extends State<AggiungiGiornatePagina> {
  static const _iniziali = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

  final _importo = TextEditingController();
  final _numero = TextEditingController(text: '10');

  Set<int> _giorniSettimana = {...lunediVenerdi};
  late DateTime _dal;
  late DateTime _fino;
  bool _perNumero = true; // vero: "per N giorni", falso: "fino al…"
  Set<DateTime> _scelti = {};
  late DateTime _mese;
  bool _iniziato = false;

  String? _erroreNumero;
  String? _erroreImporto;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniziato) return;
    _iniziato = true;

    final dati = DatiScope.leggi(context);
    final oggi = soloData(dati.adesso());
    final tariffa = dati.lavoro(widget.lavoroId)?.tariffaGiornaliera;
    _importo.text = tariffa == null ? '' : numeroPerCampo(tariffa);
    _dal = oggi;
    _fino = DateTime(oggi.year, oggi.month, oggi.day + 14);
    _mese = primoDelMese(oggi);
    _rigenera();
  }

  @override
  void dispose() {
    _importo.dispose();
    _numero.dispose();
    super.dispose();
  }

  /// Giorni in cui questo lavoro ha già una giornata (non si duplicano).
  Set<DateTime> _esistenti() => {
    for (final g in DatiScope.leggi(context).giornateDi(widget.lavoroId))
      g.data,
  };

  /// Ricalcola i giorni scelti dallo schema (buttando le modifiche a mano).
  void _rigenera() {
    final numero = int.tryParse(_numero.text.trim());
    final numeroValido =
        numero != null && numero >= 1 && numero <= maxGiorniSchema;
    _erroreNumero = _perNumero && !numeroValido
        ? 'Scrivi da 1 a $maxGiorniSchema'
        : null;

    // I giorni già registrati si saltano e non contano nel numero
    _scelti = giorniDelloSchema(
      dal: _dal,
      giorniSettimana: _giorniSettimana,
      numeroGiorni: _perNumero && numeroValido ? numero : null,
      fino: _perNumero ? null : _fino,
      esclusi: _esistenti(),
    ).toSet();
    if (_scelti.isNotEmpty) {
      _mese = primoDelMese(_scelti.reduce((a, b) => a.isBefore(b) ? a : b));
    }
  }

  void _cambiaSchema(VoidCallback modifica) => setState(() {
    modifica();
    _rigenera();
  });

  Future<DateTime?> _scegliData(DateTime iniziale, String titolo) =>
      showDatePicker(
        context: context,
        initialDate: iniziale,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        helpText: titolo,
      );

  void _toccaGiorno(DateTime giorno) {
    // Già presente: si modifica dalla pagina del progetto
    if (_esistenti().contains(giorno)) return;
    setState(() {
      if (!_scelti.remove(giorno)) _scelti.add(giorno);
    });
  }

  void _salva() {
    final importo = leggiNumero(_importo.text);
    setState(() {
      _erroreImporto = (importo == null || importo <= 0)
          ? 'Scrivi un importo'
          : null;
    });
    if (importo == null || importo <= 0 || _scelti.isEmpty) return;

    final adesso = DateTime.now();
    final giorni = _scelti.toList()..sort();
    DatiScope.leggi(context).salvaGiornate([
      for (final g in giorni)
        Giornata(
          id: '',
          lavoroId: widget.lavoroId,
          data: g,
          importo: importo,
          creatoIl: adesso,
        ),
    ]);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final oggi = soloData(dati.adesso());
    final tema = Theme.of(context).textTheme;
    final importo = leggiNumero(_importo.text);
    final n = _scelti.length;
    final ordinati = _scelti.toList()..sort();
    final esistenti = _esistenti();

    String riepilogo;
    if (n == 0) {
      riepilogo = 'Nessuna giornata scelta';
    } else {
      final totale = importo == null ? '' : ' · ${euro(n * importo)}';
      final primo = ordinati.first;
      final ultimo = ordinati.last;
      final periodo = n == 1
          ? descrizioneGiorno(primo)
          : 'dal ${primo.day} ${nomeMese(primo)} al ${ultimo.day} ${nomeMese(ultimo)}';
      riepilogo = '$n ${n == 1 ? 'giornata' : 'giornate'}$totale\n$periodo';
    }

    return PaginaSecondaria(
      titolo: 'Aggiungi giornate',
      sottotitolo: dati.lavoro(widget.lavoroId)?.nome,
      figli: [
        CampoTesto(
          key: const Key('campo-importo-giornate'),
          controller: _importo,
          etichetta: 'Guadagno netto al giorno (€)',
          suggerimento: 'Es. 30',
          numerico: true,
          errore: _erroreImporto,
          onChanged: (_) => setState(() => _erroreImporto = null),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text('Quali giorni?', style: tema.titleLarge),
        ),
        const SizedBox(height: 8),
        // Scorciatoie
        Row(
          children: [
            for (final (nome, giorni) in const [
              ('Lun–Ven', lunediVenerdi),
              ('Lun–Sab', lunediSabato),
              ('Tutti', tuttiIGiorni),
            ]) ...[
              Expanded(
                child: PulsanteScelta(
                  etichetta: nome,
                  selezionato:
                      _giorniSettimana.length == giorni.length &&
                      _giorniSettimana.containsAll(giorni),
                  onTap: () =>
                      _cambiaSchema(() => _giorniSettimana = {...giorni}),
                ),
              ),
              if (nome != 'Tutti') const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Un pulsante per ogni giorno della settimana
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              Expanded(
                child: PulsanteScelta(
                  etichetta: _iniziali[i],
                  nomeAccessibile: nomeGiorno(i + 1),
                  selezionato: _giorniSettimana.contains(i + 1),
                  onTap: () => _cambiaSchema(() {
                    final giorno = i + 1;
                    _giorniSettimana = {..._giorniSettimana};
                    if (!_giorniSettimana.remove(giorno)) {
                      _giorniSettimana.add(giorno);
                    }
                  }),
                ),
              ),
              if (i < 6) const SizedBox(width: 4),
            ],
          ],
        ),
        const SizedBox(height: 12),
        PulsanteLucido(
          etichetta: 'Dal ${_dal.day} ${nomeMeseAnno(_dal)}',
          icona: Icons.calendar_month_rounded,
          onPressed: () async {
            final scelta = await _scegliData(_dal, 'Primo giorno');
            if (scelta != null) _cambiaSchema(() => _dal = soloData(scelta));
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PulsanteScelta(
                etichetta: 'Per N giorni',
                selezionato: _perNumero,
                onTap: () => _cambiaSchema(() => _perNumero = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PulsanteScelta(
                etichetta: 'Fino al',
                selezionato: !_perNumero,
                onTap: () => _cambiaSchema(() => _perNumero = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_perNumero)
          CampoTesto(
            key: const Key('campo-numero-giorni'),
            controller: _numero,
            etichetta: 'Quanti giorni lavorati',
            suggerimento: 'Es. 10',
            numerico: true,
            errore: _erroreNumero,
            onChanged: (_) => _cambiaSchema(() {}),
          )
        else
          PulsanteLucido(
            etichetta: 'Fino al ${_fino.day} ${nomeMeseAnno(_fino)}',
            icona: Icons.event_rounded,
            onPressed: () async {
              final scelta = await _scegliData(_fino, 'Ultimo giorno');
              if (scelta != null) _cambiaSchema(() => _fino = soloData(scelta));
            },
          ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text('Calendario', style: tema.titleLarge),
        ),
        Text(
          'Tocca un giorno per toglierlo o aggiungerlo. Se cambi lo schema il calendario si rifà da capo.',
          style: tema.labelMedium?.copyWith(
            color: ColoriLaguna.testoSecondario,
          ),
        ),
        const SizedBox(height: 8),
        SelettoreMese(mese: _mese, onCambia: (m) => setState(() => _mese = m)),
        const SizedBox(height: 8),
        CalendarioGiorni(
          mese: _mese,
          oggi: oggi,
          verdi: _scelti,
          blu: esistenti,
          onTapGiorno: _toccaGiorno,
          etichettaGiorno: (g, stato) {
            final nome = descrizioneGiorno(g);
            return switch (stato) {
              StatoGiorno.verde => '$nome, scelto',
              StatoGiorno.blu => '$nome, già registrato',
              StatoGiorno.normale => nome,
            };
          },
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            _Legenda(colore: Color(0xFF1A8F2E), testo: 'Scelti'),
            SizedBox(width: 16),
            _Legenda(colore: Color(0xFF0F72A8), testo: 'Già registrati'),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: CartaVetro(
            colori: const [Color(0xFFFFF6C4), Color(0xFFFFE98F)],
            child: Text(riepilogo, style: tema.titleMedium),
          ),
        ),
        const SizedBox(height: 12),
        PulsanteLucido(
          etichetta: n == 0
              ? 'Aggiungi'
              : 'Aggiungi $n ${n == 1 ? 'giornata' : 'giornate'}',
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: n == 0 ? null : _salva,
        ),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.colore, required this.testo});

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
