import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../modelli/prezzo_mercato.dart';
import '../modelli/tipi.dart';
import '../servizi/stato_dati.dart';
import '../widget/campo_testo.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/stile_lucido.dart';

/// Apre il foglio per inserire a mano la forbice di mercato di un tipo di lavoro.
Future<void> modificaForbice(BuildContext context, TipoLavoro tipo) {
  return mostraFoglio<void>(
    context,
    titolo: 'Prezzo di mercato · ${tipo.etichetta}',
    costruttore: (_) => _FormForbice(tipo: tipo),
  );
}

class _FormForbice extends StatefulWidget {
  const _FormForbice({required this.tipo});

  final TipoLavoro tipo;

  @override
  State<_FormForbice> createState() => _FormForbiceState();
}

class _FormForbiceState extends State<_FormForbice> {
  final _minimo = TextEditingController();
  final _massimo = TextEditingController();
  String? _erroreMinimo;
  String? _erroreMassimo;
  bool _iniziato = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniziato) return;
    _iniziato = true;
    final attuale = DatiScope.leggi(context).mercatoPer(widget.tipo);
    if (attuale != null) {
      _minimo.text = numeroPerCampo(attuale.minimo);
      _massimo.text = numeroPerCampo(attuale.massimo);
    }
  }

  @override
  void dispose() {
    _minimo.dispose();
    _massimo.dispose();
    super.dispose();
  }

  void _salva() {
    final minimo = leggiNumero(_minimo.text);
    final massimo = leggiNumero(_massimo.text);
    setState(() {
      _erroreMinimo = minimo == null || minimo <= 0
          ? 'Scrivi un importo'
          : null;
      _erroreMassimo = massimo == null || massimo <= 0
          ? 'Scrivi un importo'
          : (minimo != null && massimo < minimo
                ? 'Deve essere almeno il minimo'
                : null);
    });
    if (_erroreMinimo != null || _erroreMassimo != null) return;

    DatiScope.leggi(context).salvaPrezzoMercato(
      PrezzoMercato(
        tipo: widget.tipo,
        minimo: minimo!,
        massimo: massimo!,
        aggiornato: DateTime.now(),
        manuale: true,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTesto(
          key: const Key('campo-minimo'),
          controller: _minimo,
          etichetta: 'Prezzo minimo (€)',
          suggerimento: 'Es. 80',
          numerico: true,
          errore: _erroreMinimo,
        ),
        const SizedBox(height: 12),
        CampoTesto(
          key: const Key('campo-massimo'),
          controller: _massimo,
          etichetta: 'Prezzo massimo (€)',
          suggerimento: 'Es. 120',
          numerico: true,
          errore: _erroreMassimo,
          azioneTastiera: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        PulsanteLucido(
          etichetta: 'Salva forbice',
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: _salva,
        ),
      ],
    );
  }
}
