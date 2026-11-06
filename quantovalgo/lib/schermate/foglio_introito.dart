import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/giornate.dart';
import '../logica/mesi.dart';
import '../modelli/introito.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/campo_testo.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/pulsante_scelta.dart';
import '../widget/stile_lucido.dart';

/// Foglio "Guadagno veloce": soldi entrati senza creare un lavoro.
/// Due cose da scrivere: quanto e (se vuoi) da dove. Il giorno di partenza è
/// oggi. Con [esistente] modifica o toglie un guadagno già registrato.
Future<void> modificaIntroito(BuildContext context, {Introito? esistente}) {
  return mostraFoglio<void>(
    context,
    titolo: esistente == null ? 'Guadagno veloce' : 'Modifica guadagno',
    costruttore: (_) => _FormIntroito(esistente: esistente),
  );
}

class _FormIntroito extends StatefulWidget {
  const _FormIntroito({this.esistente});

  final Introito? esistente;

  @override
  State<_FormIntroito> createState() => _FormIntroitoState();
}

class _FormIntroitoState extends State<_FormIntroito> {
  late final _importo = TextEditingController(
    text: widget.esistente == null
        ? ''
        : numeroPerCampo(widget.esistente!.importo),
  );
  late final _nota = TextEditingController(text: widget.esistente?.nota ?? '');
  DateTime? _giorno;
  String? _erroreImporto;

  @override
  void dispose() {
    _importo.dispose();
    _nota.dispose();
    super.dispose();
  }

  /// Il giorno scelto; finché non scegli niente è quello del guadagno
  /// esistente oppure oggi.
  DateTime _giornoScelto(StatoDati dati) =>
      _giorno ?? widget.esistente?.data ?? soloData(dati.adesso());

  Future<void> _scegliGiorno(StatoDati dati) async {
    final scelto = await showDatePicker(
      context: context,
      initialDate: _giornoScelto(dati),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Quando sono entrati?',
    );
    if (scelto != null) setState(() => _giorno = soloData(scelto));
  }

  void _salva() {
    final importo = leggiNumero(_importo.text);
    final valido = importo != null && importo > 0;
    setState(() => _erroreImporto = valido ? null : 'Scrivi quanto hai preso');
    if (!valido) return;

    final dati = DatiScope.leggi(context);
    final vecchio = widget.esistente;
    dati.salvaIntroito(
      Introito(
        id: vecchio?.id ?? '',
        importo: importo,
        data: _giornoScelto(dati),
        nota: _nota.text.trim(),
        creatoIl: vecchio?.creatoIl ?? dati.adesso(),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _elimina() async {
    final navigatore = Navigator.of(context);
    final dati = DatiScope.leggi(context);
    final conferma = await chiediConferma(
      context,
      titolo: 'Togliere questo guadagno?',
      testo: 'Non conterà più nei conti del mese.',
      etichettaConferma: 'Togli',
    );
    if (!conferma) return;
    dati.eliminaIntroito(widget.esistente!.id);
    navigatore.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;
    final oggi = soloData(dati.adesso());
    final ieri = oggi.subtract(const Duration(days: 1));
    final giorno = _giornoScelto(dati);
    final eOggi = giorno == oggi;
    final eIeri = giorno == ieri;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Soldi entrati senza un lavoro: contano subito nel mese.',
          style: tema.bodyMedium?.copyWith(color: ColoriLaguna.testoSecondario),
        ),
        const SizedBox(height: 12),
        CampoTesto(
          key: const Key('campo-importo-introito'),
          controller: _importo,
          etichetta: 'Quanto hai preso? (€)',
          suggerimento: 'Es. 50',
          numerico: true,
          errore: _erroreImporto,
          onChanged: (_) {
            if (_erroreImporto != null) setState(() => _erroreImporto = null);
          },
        ),
        const SizedBox(height: 12),
        CampoTesto(
          key: const Key('campo-nota-introito'),
          controller: _nota,
          etichetta: 'Da dove? (facoltativo)',
          suggerimento: 'Es. Vendita usato',
          azioneTastiera: TextInputAction.done,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PulsanteScelta(
                etichetta: 'Oggi',
                selezionato: eOggi,
                onTap: () => setState(() => _giorno = oggi),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PulsanteScelta(
                etichetta: 'Ieri',
                selezionato: eIeri,
                onTap: () => setState(() => _giorno = ieri),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PulsanteScelta(
                etichetta: eOggi || eIeri
                    ? 'Altro giorno'
                    : '${giorno.day} ${nomeMese(giorno)}',
                selezionato: !eOggi && !eIeri,
                onTap: () => _scegliGiorno(dati),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PulsanteLucido(
          key: const Key('salva-introito'),
          etichetta: widget.esistente == null ? 'Aggiungi' : 'Salva',
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: _salva,
        ),
        if (widget.esistente != null) ...[
          const SizedBox(height: 10),
          PulsanteLucido(
            etichetta: 'Togli questo guadagno',
            icona: Icons.delete_outline_rounded,
            stile: StileLucido.rosso,
            onPressed: _elimina,
          ),
        ],
      ],
    );
  }
}
