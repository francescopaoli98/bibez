import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../modelli/sottoprogetto.dart';
import '../servizi/stato_dati.dart';
import '../widget/campo_testo.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/stile_lucido.dart';

/// Apre il foglio per aggiungere o modificare un sottoprogetto.
Future<void> modificaSottoprogetto(
  BuildContext context, {
  required String lavoroId,
  Sottoprogetto? esistente,
}) {
  return mostraFoglio<void>(
    context,
    titolo: esistente == null
        ? 'Nuovo sottoprogetto'
        : 'Modifica sottoprogetto',
    costruttore: (_) =>
        _FormSottoprogetto(lavoroId: lavoroId, esistente: esistente),
  );
}

class _FormSottoprogetto extends StatefulWidget {
  const _FormSottoprogetto({required this.lavoroId, this.esistente});

  final String lavoroId;
  final Sottoprogetto? esistente;

  @override
  State<_FormSottoprogetto> createState() => _FormSottoprogettoState();
}

class _FormSottoprogettoState extends State<_FormSottoprogetto> {
  late final _nome = TextEditingController(text: widget.esistente?.nome);
  late final _ricavo = TextEditingController(
    text: widget.esistente == null
        ? ''
        : numeroPerCampo(widget.esistente!.ricavo),
  );
  late final _costi = TextEditingController(
    text: widget.esistente == null
        ? ''
        : numeroPerCampo(widget.esistente!.costiDiretti),
  );
  late final _ore = TextEditingController(
    text: widget.esistente == null ? '' : numeroPerCampo(widget.esistente!.ore),
  );
  String? _erroreNome;
  String? _erroreRicavo;
  String? _erroreCosti;
  String? _erroreOre;

  @override
  void dispose() {
    _nome.dispose();
    _ricavo.dispose();
    _costi.dispose();
    _ore.dispose();
    super.dispose();
  }

  /// Campo vuoto = 0; scritto male = null (errore).
  static double? _numeroOZero(String testo) =>
      testo.trim().isEmpty ? 0 : leggiNumero(testo);

  void _salva() {
    final ricavo = _numeroOZero(_ricavo.text);
    final costi = _numeroOZero(_costi.text);
    final ore = _numeroOZero(_ore.text);
    setState(() {
      _erroreNome = _nome.text.trim().isEmpty ? 'Scrivi un nome' : null;
      _erroreRicavo = ricavo == null ? 'Numero non valido' : null;
      _erroreCosti = costi == null ? 'Numero non valido' : null;
      _erroreOre = ore == null ? 'Numero non valido' : null;
    });
    if ([
      _erroreNome,
      _erroreRicavo,
      _erroreCosti,
      _erroreOre,
    ].any((e) => e != null)) {
      return;
    }

    final esistente = widget.esistente;
    DatiScope.leggi(context).salvaSottoprogetto(
      Sottoprogetto(
        id: esistente?.id ?? '',
        lavoroId: widget.lavoroId,
        nome: _nome.text.trim(),
        ricavo: ricavo!,
        costiDiretti: costi!,
        ore: ore!,
        creatoIl: esistente?.creatoIl ?? DateTime.now(),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _elimina() async {
    final navigatore = Navigator.of(context);
    final dati = DatiScope.leggi(context);
    final conferma = await chiediConferma(
      context,
      titolo: 'Eliminare il sottoprogetto?',
      testo: '"${widget.esistente!.nome}" sparirà dal progetto.',
      etichettaConferma: 'Elimina',
    );
    if (!conferma) return;
    dati.eliminaSottoprogetto(widget.esistente!.id);
    navigatore.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTesto(
          key: const Key('campo-nome'),
          controller: _nome,
          etichetta: 'Nome',
          suggerimento: 'Es. Registrazione',
          errore: _erroreNome,
        ),
        const SizedBox(height: 12),
        CampoTesto(
          key: const Key('campo-ricavo'),
          controller: _ricavo,
          etichetta: 'Quanto incassi (€)',
          suggerimento: '0',
          numerico: true,
          errore: _erroreRicavo,
        ),
        const SizedBox(height: 12),
        CampoTesto(
          key: const Key('campo-costi'),
          controller: _costi,
          etichetta: 'Costi di questa parte (€)',
          suggerimento: '0',
          numerico: true,
          errore: _erroreCosti,
        ),
        const SizedBox(height: 12),
        CampoTesto(
          key: const Key('campo-ore'),
          controller: _ore,
          etichetta: 'Ore lavorate',
          suggerimento: '0',
          numerico: true,
          errore: _erroreOre,
          azioneTastiera: TextInputAction.done,
        ),
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
