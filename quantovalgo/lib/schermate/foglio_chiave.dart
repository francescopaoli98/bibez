import 'package:flutter/material.dart';

import '../modelli/impostazioni.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/campo_testo.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/stile_lucido.dart';

/// Le due chiavi che l'app può usare, ognuna con il suo servizio.
enum ServizioChiave {
  /// Ricerca dei prezzi sul web (gratis).
  tavily(
    titolo: 'Chiave di Tavily',
    prefisso: 'tvly-',
    spiegazione:
        'Si crea gratis su tavily.com (1.000 ricerche al mese, senza carta). '
        'La chiave resta nel tuo cloud privato: la vedi solo tu.',
  ),

  /// Miglioramento dei testi con l'AI (a consumo, frazioni di centesimo).
  claude(
    titolo: 'Chiave di Claude',
    prefisso: 'sk-ant-',
    spiegazione:
        'Si crea su console.anthropic.com (serve un po\' di credito, '
        'bastano 5 \$ per migliaia di testi). Ogni miglioramento costa meno '
        'di un centesimo e parte solo quando premi il pulsante. '
        'La chiave resta nel tuo cloud privato: la vedi solo tu.',
  );

  const ServizioChiave({
    required this.titolo,
    required this.prefisso,
    required this.spiegazione,
  });

  final String titolo;

  /// Come inizia ogni chiave di questo servizio.
  final String prefisso;
  final String spiegazione;

  /// La chiave salvata ora (vuota se non c'è).
  String attuale(Impostazioni i) => switch (this) {
    ServizioChiave.tavily => i.chiaveTavily,
    ServizioChiave.claude => i.chiaveClaude,
  };

  /// Impostazioni con la chiave cambiata. Senza chiave di Tavily anche
  /// l'aggiornamento settimanale dei prezzi si spegne.
  Impostazioni conChiave(Impostazioni i, String chiave) => switch (this) {
    ServizioChiave.tavily => i.copyWith(
      chiaveTavily: chiave,
      aggiornaPrezzi: chiave.isEmpty ? false : i.aggiornaPrezzi,
    ),
    ServizioChiave.claude => i.copyWith(chiaveClaude: chiave),
  };
}

/// Foglio per inserire (o togliere) la chiave gratuita di Tavily.
Future<void> modificaChiaveTavily(BuildContext context) =>
    modificaChiave(context, ServizioChiave.tavily);

/// Foglio per inserire (o togliere) la chiave di Claude per l'AI.
Future<void> modificaChiaveClaude(BuildContext context) =>
    modificaChiave(context, ServizioChiave.claude);

/// Foglio per inserire (o togliere) la chiave di un [servizio].
Future<void> modificaChiave(BuildContext context, ServizioChiave servizio) {
  return mostraFoglio<void>(
    context,
    titolo: servizio.titolo,
    costruttore: (_) => _FormChiave(servizio: servizio),
  );
}

class _FormChiave extends StatefulWidget {
  const _FormChiave({required this.servizio});

  final ServizioChiave servizio;

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
    _campo.text = widget.servizio.attuale(
      DatiScope.leggi(context).impostazioni,
    );
  }

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _salva() {
    // Incollando si portano dietro spazi e a capo: si tolgono
    final chiave = _campo.text.replaceAll(RegExp(r'\s'), '');
    final prefisso = widget.servizio.prefisso;
    if (!chiave.startsWith(prefisso) || chiave.length < 12) {
      setState(() {
        final nome = widget.servizio.titolo.replaceFirst('Chiave', 'chiave');
        _errore = 'La $nome inizia con $prefisso';
      });
      return;
    }
    final dati = DatiScope.leggi(context);
    dati.salvaImpostazioni(
      widget.servizio.conChiave(dati.impostazioni, chiave),
    );
    Navigator.of(context).pop();
  }

  void _togli() {
    final dati = DatiScope.leggi(context);
    dati.salvaImpostazioni(widget.servizio.conChiave(dati.impostazioni, ''));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final c = widget.servizio
        .attuale(DatiScope.leggi(context).impostazioni)
        .isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTesto(
          key: const Key('campo-chiave'),
          controller: _campo,
          etichetta: 'Chiave',
          suggerimento: '${widget.servizio.prefisso}…',
          errore: _errore,
          maiuscole: TextCapitalization.none,
          azioneTastiera: TextInputAction.done,
        ),
        const SizedBox(height: 8),
        Text(
          widget.servizio.spiegazione,
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
