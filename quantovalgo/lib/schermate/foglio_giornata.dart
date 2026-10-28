import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/giornate.dart';
import '../logica/mesi.dart';
import '../modelli/giornata.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/campo_testo.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/stile_lucido.dart';

/// Foglio per aggiungere, modificare o togliere la giornata di un giorno.
/// Con [esistente] modifica; senza, aggiunge una giornata nuova a [data].
Future<void> modificaGiornata(
  BuildContext context, {
  required String lavoroId,
  required DateTime data,
  required double tariffa,
  Giornata? esistente,
}) {
  return mostraFoglio<void>(
    context,
    titolo: esistente == null ? 'Aggiungi giornata' : 'Modifica giornata',
    costruttore: (_) => _FormGiornata(
      lavoroId: lavoroId,
      data: soloData(data),
      tariffa: tariffa,
      esistente: esistente,
    ),
  );
}

class _FormGiornata extends StatefulWidget {
  const _FormGiornata({
    required this.lavoroId,
    required this.data,
    required this.tariffa,
    this.esistente,
  });

  final String lavoroId;
  final DateTime data;
  final double tariffa;
  final Giornata? esistente;

  @override
  State<_FormGiornata> createState() => _FormGiornataState();
}

class _FormGiornataState extends State<_FormGiornata> {
  late final _importo = TextEditingController(
    text: numeroPerCampo(widget.esistente?.importo ?? widget.tariffa),
  );
  String? _erroreImporto;

  @override
  void dispose() {
    _importo.dispose();
    super.dispose();
  }

  void _salva() {
    final importo = leggiNumero(_importo.text);
    setState(() {
      _erroreImporto = importo == null ? 'Scrivi un importo' : null;
    });
    if (importo == null) return;

    final dati = DatiScope.leggi(context);
    final vecchia = widget.esistente;
    dati.salvaGiornata(
      Giornata(
        id: vecchia?.id ?? '',
        lavoroId: widget.lavoroId,
        data: widget.data,
        importo: importo,
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
      titolo: 'Togliere la giornata?',
      testo: 'Il ${descrizioneGiorno(widget.data)} non conterà più.',
      etichettaConferma: 'Togli',
    );
    if (!conferma) return;
    dati.eliminaGiornata(widget.esistente!.id);
    navigatore.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          descrizioneGiorno(widget.data),
          style: tema.titleMedium?.copyWith(
            color: ColoriLaguna.testoSecondario,
          ),
        ),
        const SizedBox(height: 12),
        CampoTesto(
          key: const Key('campo-importo-giornata'),
          controller: _importo,
          etichetta: 'Guadagno netto del giorno (€)',
          suggerimento: 'Es. 30',
          numerico: true,
          errore: _erroreImporto,
          azioneTastiera: TextInputAction.done,
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
            etichetta: 'Togli questa giornata',
            icona: Icons.delete_outline_rounded,
            stile: StileLucido.rosso,
            onPressed: _elimina,
          ),
        ],
      ],
    );
  }
}
