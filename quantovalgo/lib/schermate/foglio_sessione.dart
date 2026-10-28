import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/mesi.dart';
import '../logica/ore.dart';
import '../modelli/sessione_ore.dart';
import '../modelli/sottoprogetto.dart';
import '../servizi/stato_dati.dart';
import '../widget/campo_testo.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/stile_lucido.dart';

/// Foglio per inserire a mano le ore di un giorno, o per correggere o togliere
/// una sessione già registrata.
Future<void> modificaSessione(
  BuildContext context, {
  required Sottoprogetto sottoprogetto,
  SessioneOre? esistente,
}) {
  return mostraFoglio<void>(
    context,
    titolo: esistente == null ? 'Aggiungi ore a mano' : 'Modifica sessione',
    costruttore: (_) =>
        _FormSessione(sottoprogetto: sottoprogetto, esistente: esistente),
  );
}

class _FormSessione extends StatefulWidget {
  const _FormSessione({required this.sottoprogetto, this.esistente});

  final Sottoprogetto sottoprogetto;
  final SessioneOre? esistente;

  @override
  State<_FormSessione> createState() => _FormSessioneState();
}

class _FormSessioneState extends State<_FormSessione> {
  late final _ore = TextEditingController(
    text: widget.esistente == null || widget.esistente!.minuti < 60
        ? ''
        : '${widget.esistente!.minuti ~/ 60}',
  );
  late final _minuti = TextEditingController(
    text: widget.esistente == null || widget.esistente!.minuti % 60 == 0
        ? ''
        : '${widget.esistente!.minuti % 60}',
  );
  DateTime? _giorno;
  String? _erroreDurata;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Di partenza: il giorno della sessione, oppure oggi
    _giorno ??= soloGiorno(
      widget.esistente?.inizio ?? DatiScope.leggi(context).adesso(),
    );
  }

  @override
  void dispose() {
    _ore.dispose();
    _minuti.dispose();
    super.dispose();
  }

  static DateTime soloGiorno(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Campo vuoto = 0; scritto male = null.
  static double? _numeroOZero(String testo) =>
      testo.trim().isEmpty ? 0 : leggiNumero(testo);

  Future<void> _scegliGiorno() async {
    final scelto = await showDatePicker(
      context: context,
      initialDate: _giorno!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Giorno di lavoro',
    );
    if (scelto != null) setState(() => _giorno = soloGiorno(scelto));
  }

  void _salva() {
    final ore = _numeroOZero(_ore.text);
    final minuti = _numeroOZero(_minuti.text);
    String? errore;
    int? totale;
    if (ore == null || minuti == null) {
      errore = 'Numero non valido';
    } else {
      totale = (ore * 60).round() + minuti.round();
      if (totale < 1) {
        errore = 'Scrivi almeno 1 minuto';
      } else if (totale > maxMinutiSessione) {
        errore = 'Al massimo 24 ore in una sessione';
      }
    }
    setState(() => _erroreDurata = errore);
    if (errore != null) return;

    final vecchia = widget.esistente;
    // Le ore a mano non hanno un orario: parto da mezzogiorno. Correggendo una
    // sessione del cronometro tengo il suo orario di inizio.
    final inizio = DateTime(
      _giorno!.year,
      _giorno!.month,
      _giorno!.day,
      vecchia?.inizio.hour ?? 12,
      vecchia?.inizio.minute ?? 0,
    );
    DatiScope.leggi(context).salvaSessione(
      SessioneOre(
        id: vecchia?.id ?? '',
        sottoprogettoId: widget.sottoprogetto.id,
        lavoroId: widget.sottoprogetto.lavoroId,
        inizio: inizio,
        fine: inizio.add(Duration(minutes: totale!)),
        minuti: totale,
        manuale: vecchia?.manuale ?? true,
        creatoIl: vecchia?.creatoIl ?? DateTime.now(),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _elimina() async {
    final navigatore = Navigator.of(context);
    final dati = DatiScope.leggi(context);
    final conferma = await chiediConferma(
      context,
      titolo: 'Togliere la sessione?',
      testo: 'Le ore di ${descrizioneGiorno(_giorno!)} non conteranno più.',
      etichettaConferma: 'Togli',
    );
    if (!conferma) return;
    dati.eliminaSessione(widget.esistente!.id);
    navigatore.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PulsanteLucido(
          etichetta: descrizioneGiorno(_giorno!),
          icona: Icons.calendar_month_rounded,
          onPressed: _scegliGiorno,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoTesto(
                key: const Key('campo-ore-sessione'),
                controller: _ore,
                etichetta: 'Ore',
                suggerimento: '0',
                numerico: true,
                errore: _erroreDurata,
                onChanged: (_) => setState(() => _erroreDurata = null),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CampoTesto(
                key: const Key('campo-minuti-sessione'),
                controller: _minuti,
                etichetta: 'Minuti',
                suggerimento: '0',
                numerico: true,
                azioneTastiera: TextInputAction.done,
                onChanged: (_) => setState(() => _erroreDurata = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PulsanteLucido(
          etichetta: widget.esistente == null ? 'Aggiungi' : 'Salva',
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: _salva,
        ),
        if (widget.esistente != null) ...[
          const SizedBox(height: 10),
          PulsanteLucido(
            etichetta: 'Togli questa sessione',
            icona: Icons.delete_outline_rounded,
            stile: StileLucido.rosso,
            onPressed: _elimina,
          ),
        ],
      ],
    );
  }
}
