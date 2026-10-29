import 'package:flutter/material.dart';

import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/campo_testo.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/stile_lucido.dart';

/// Foglio per inserire (o togliere) la chiave gratuita di Tavily.
Future<void> modificaChiaveTavily(BuildContext context) {
  return mostraFoglio<void>(
    context,
    titolo: 'Chiave di Tavily',
    costruttore: (_) => const _FormChiave(),
  );
}

class _FormChiave extends StatefulWidget {
  const _FormChiave();

  @override
  State<_FormChiave> createState() => _FormChiaveState();
}

class _FormChiaveState extends State<_FormChiave> {
  final _campo = TextEditingController();
  String? _errore;
  bool _iniziato = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniziato) return;
    _iniziato = true;
    _campo.text = DatiScope.leggi(context).impostazioni.chiaveTavily;
  }

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _salva() {
    // Incollando si portano dietro spazi e a capo: si tolgono
    final chiave = _campo.text.replaceAll(RegExp(r'\s'), '');
    if (!chiave.startsWith('tvly-') || chiave.length < 12) {
      setState(() => _errore = 'La chiave di Tavily inizia con tvly-');
      return;
    }
    final dati = DatiScope.leggi(context);
    dati.salvaImpostazioni(dati.impostazioni.copyWith(chiaveTavily: chiave));
    Navigator.of(context).pop();
  }

  void _togli() {
    final dati = DatiScope.leggi(context);
    // Senza chiave anche l'aggiornamento settimanale si spegne
    dati.salvaImpostazioni(
      dati.impostazioni.copyWith(chiaveTavily: '', aggiornaPrezzi: false),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final c = DatiScope.leggi(context).impostazioni.chiaveTavily.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTesto(
          key: const Key('campo-chiave'),
          controller: _campo,
          etichetta: 'Chiave',
          suggerimento: 'tvly-…',
          errore: _errore,
          maiuscole: TextCapitalization.none,
          azioneTastiera: TextInputAction.done,
        ),
        const SizedBox(height: 8),
        Text(
          'Si crea gratis su tavily.com (1.000 ricerche al mese, senza carta). '
          'La chiave resta nel tuo cloud privato: la vedi solo tu.',
          style: tema.bodyMedium?.copyWith(color: ColoriLaguna.testoSecondario),
        ),
        const SizedBox(height: 16),
        PulsanteLucido(
          etichetta: 'Salva chiave',
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: _salva,
        ),
        if (c) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: _togli,
            style: TextButton.styleFrom(foregroundColor: ColoriLaguna.negativo),
            child: const Text('Togli la chiave'),
          ),
        ],
      ],
    );
  }
}
