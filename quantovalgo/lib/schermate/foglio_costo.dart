import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../modelli/costo.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/campo_testo.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/pulsante_scelta.dart';
import '../widget/stile_lucido.dart';
import 'foglio_categoria.dart';

/// Foglio per aggiungere o modificare un costo.
/// [mese] è il mese che stai guardando: serve come data di partenza.
Future<void> modificaCosto(
  BuildContext context, {
  required DateTime mese,
  Costo? esistente,
}) {
  return mostraFoglio<void>(
    context,
    titolo: esistente == null ? 'Nuovo costo' : 'Modifica costo',
    costruttore: (_) => _FormCosto(mese: mese, esistente: esistente),
  );
}

class _FormCosto extends StatefulWidget {
  const _FormCosto({required this.mese, this.esistente});

  final DateTime mese;
  final Costo? esistente;

  @override
  State<_FormCosto> createState() => _FormCostoState();
}

class _FormCostoState extends State<_FormCosto> {
  late final _nome = TextEditingController(text: widget.esistente?.nome);
  late final _importo = TextEditingController(
    text: widget.esistente == null
        ? ''
        : numeroPerCampo(widget.esistente!.importo),
  );
  late final _mesi = TextEditingController(
    text: (widget.esistente != null && widget.esistente!.mesi > 1)
        ? '${widget.esistente!.mesi}'
        : '6',
  );

  late TipoCosto _tipo = widget.esistente?.tipo ?? TipoCosto.abbonamento;

  /// Solo una tantum: falso = tutto nel mese, vero = spalmato su più mesi.
  late bool _spalmato = (widget.esistente?.mesi ?? 1) > 1;
  late DateTime _inizio = widget.esistente?.inizio ?? _dataDiPartenza();
  late String? _categoriaId = widget.esistente?.categoriaId;

  /// Solo abbonamento e fisso: se è già finito (disdetto) non è più attivo.
  late bool _attivo = widget.esistente?.fine == null;

  String? _erroreNome;
  String? _erroreImporto;
  String? _erroreMesi;

  /// Se guardi il mese corrente parte da oggi, altrimenti dal primo del mese.
  DateTime _dataDiPartenza() {
    final adesso = DateTime.now();
    return primoDelMese(adesso) == primoDelMese(widget.mese)
        ? adesso
        : primoDelMese(widget.mese);
  }

  @override
  void dispose() {
    _nome.dispose();
    _importo.dispose();
    _mesi.dispose();
    super.dispose();
  }

  Future<void> _scegliData() async {
    final scelta = await showDatePicker(
      context: context,
      initialDate: _inizio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: _tipo == TipoCosto.unaTantum
          ? 'Data dell\'acquisto'
          : 'Primo mese',
    );
    if (scelta != null) setState(() => _inizio = scelta);
  }

  void _salva() {
    final importo = leggiNumero(_importo.text);
    final mesi = int.tryParse(_mesi.text.trim());
    final spalmaSuPiuMesi = _tipo == TipoCosto.unaTantum && _spalmato;
    setState(() {
      _erroreNome = _nome.text.trim().isEmpty ? 'Scrivi un nome' : null;
      _erroreImporto = (importo == null || importo <= 0)
          ? 'Scrivi un importo'
          : null;
      _erroreMesi = spalmaSuPiuMesi && (mesi == null || mesi < 2 || mesi > 120)
          ? 'Scrivi da 2 a 120 mesi'
          : null;
    });
    if (_erroreNome != null || _erroreImporto != null || _erroreMesi != null) {
      return;
    }

    final vecchio = widget.esistente;
    final ricorrente = _tipo != TipoCosto.unaTantum;
    // Un costo ricorrente disdetto smette alla fine del mese in cui lo disdici.
    final fine = ricorrente && !_attivo
        ? (vecchio?.fine ?? primoDelMese(DateTime.now()))
        : null;

    DatiScope.leggi(context).salvaCosto(
      Costo(
        id: vecchio?.id ?? '',
        nome: _nome.text.trim(),
        tipo: _tipo,
        importo: importo!,
        mesi: spalmaSuPiuMesi ? mesi! : 1,
        inizio: _inizio,
        fine: fine,
        categoriaId: _categoriaId,
        creatoIl: vecchio?.creatoIl ?? DateTime.now(),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _elimina() async {
    final navigatore = Navigator.of(context);
    final dati = DatiScope.leggi(context);
    final conferma = await chiediConferma(
      context,
      titolo: 'Eliminare il costo?',
      testo: '"${widget.esistente!.nome}" sparirà anche dai mesi passati.',
      etichettaConferma: 'Elimina',
    );
    if (!conferma) return;
    dati.eliminaCosto(widget.esistente!.id);
    navigatore.pop();
  }

  @override
  Widget build(BuildContext context) {
    final unaTantum = _tipo == TipoCosto.unaTantum;
    final ricorrente = !unaTantum;
    final importo = leggiNumero(_importo.text);
    final mesi = int.tryParse(_mesi.text.trim());
    final tema = Theme.of(context).textTheme;

    final etichettaData = unaTantum
        ? 'Acquistato il ${_inizio.day} ${nomeMeseAnno(_inizio)}'
        : 'Dal mese di ${nomeMeseAnno(_inizio)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTesto(
          key: const Key('campo-nome'),
          controller: _nome,
          etichetta: 'Nome',
          suggerimento: 'Es. Microfono',
          errore: _erroreNome,
        ),
        const SizedBox(height: 14),
        const Text(
          'Che tipo di costo è?',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in TipoCosto.values)
              PulsanteScelta(
                etichetta: t.etichetta,
                selezionato: t == _tipo,
                onTap: () => setState(() => _tipo = t),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          switch (_tipo) {
            TipoCosto.abbonamento =>
              'Si paga ogni mese e si divide tra i progetti.',
            TipoCosto.unaTantum => 'Si paga una volta (es. attrezzatura) e si divide tra i progetti.',
            TipoCosto.fisso =>
              'Si paga ogni mese e non si divide (es. internet).',
          },
          style: tema.labelMedium?.copyWith(
            color: ColoriLaguna.testoSecondario,
          ),
        ),
        const SizedBox(height: 14),
        CampoTesto(
          key: const Key('campo-importo'),
          controller: _importo,
          etichetta: unaTantum ? 'Prezzo totale (€)' : 'Importo al mese (€)',
          suggerimento: unaTantum ? 'Es. 90' : 'Es. 20',
          numerico: true,
          errore: _erroreImporto,
          onChanged: (_) => setState(() {}),
        ),
        if (unaTantum) ...[
          const SizedBox(height: 14),
          const Text(
            'Come lo conti?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: PulsanteScelta(
                  etichetta: 'Tutto nel mese',
                  selezionato: !_spalmato,
                  onTap: () => setState(() => _spalmato = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PulsanteScelta(
                  etichetta: 'Su più mesi',
                  selezionato: _spalmato,
                  onTap: () => setState(() => _spalmato = true),
                ),
              ),
            ],
          ),
          if (_spalmato) ...[
            const SizedBox(height: 12),
            CampoTesto(
              key: const Key('campo-mesi'),
              controller: _mesi,
              etichetta: 'Su quanti mesi',
              suggerimento: 'Es. 6',
              numerico: true,
              errore: _erroreMesi,
              onChanged: (_) => setState(() {}),
            ),
            if (importo != null && importo > 0 && mesi != null && mesi >= 2)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Pesa ${euro(importo / mesi)} al mese per $mesi mesi',
                  style: tema.labelMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ],
        const SizedBox(height: 14),
        PulsanteLucido(
          etichetta: etichettaData,
          icona: Icons.calendar_month_rounded,
          onPressed: _scegliData,
        ),
        const SizedBox(height: 14),
        SelettoreCategoria(
          scelta: _categoriaId,
          onCambia: (id) => setState(() => _categoriaId = id),
        ),
        // Vale per ogni categoria: si recupera solo con i suoi progetti
        if (DatiScope.di(context).categoria(_categoriaId)
            case final categoria?) ...[
          const SizedBox(height: 6),
          Text(
            'Pesa e si recupera solo con i progetti della categoria «${categoria.nome}».',
            style: tema.labelMedium?.copyWith(
              color: ColoriLaguna.testoSecondario,
              fontSize: 14,
            ),
          ),
        ],
        if (ricorrente && widget.esistente != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ancora attivo', style: tema.titleMedium),
                    Text(
                      'Se lo disdici smette dal mese dopo',
                      style: tema.labelMedium?.copyWith(
                        color: ColoriLaguna.testoSecondario,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Ancora attivo',
                child: Switch(
                  value: _attivo,
                  onChanged: (v) => setState(() => _attivo = v),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        PulsanteLucido(
          etichetta: 'Salva',
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: _salva,
        ),
        if (widget.esistente != null) ...[
          const SizedBox(height: 10),
          PulsanteLucido(
            etichetta: 'Elimina',
            icona: Icons.delete_outline_rounded,
            stile: StileLucido.rosso,
            onPressed: _elimina,
          ),
        ],
      ],
    );
  }
}
