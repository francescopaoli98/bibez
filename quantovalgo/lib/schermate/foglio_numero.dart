import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../widget/campo_testo.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/stile_lucido.dart';

/// Foglio con un solo numero da scrivere (una percentuale, un obiettivo...).
/// Restituisce il numero salvato, oppure null se chiudi senza salvare.
/// Con [intero] i decimali non sono ammessi.
Future<double?> chiediNumero(
  BuildContext context, {
  required String titolo,
  required String etichetta,
  required double iniziale,
  double minimo = 0,
  double massimo = 100000,
  bool intero = false,
  String? aiuto,
}) {
  return mostraFoglio<double>(
    context,
    titolo: titolo,
    costruttore: (_) => _FormNumero(
      etichetta: etichetta,
      iniziale: iniziale,
      minimo: minimo,
      massimo: massimo,
      intero: intero,
      aiuto: aiuto,
    ),
  );
}

class _FormNumero extends StatefulWidget {
  const _FormNumero({
    required this.etichetta,
    required this.iniziale,
    required this.minimo,
    required this.massimo,
    required this.intero,
    required this.aiuto,
  });

  final String etichetta;
  final double iniziale;
  final double minimo;
  final double massimo;
  final bool intero;
  final String? aiuto;

  @override
  State<_FormNumero> createState() => _FormNumeroState();
}

class _FormNumeroState extends State<_FormNumero> {
  late final _campo = TextEditingController(
    text: numeroPerCampo(widget.iniziale),
  );
  String? _errore;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _salva() {
    final numero = leggiNumero(_campo.text, negativi: widget.minimo < 0);
    final valido =
        numero != null &&
        numero >= widget.minimo &&
        numero <= widget.massimo &&
        (!widget.intero || numero == numero.roundToDouble());
    if (!valido) {
      setState(
        () => _errore =
            'Scrivi un numero ${widget.intero ? 'intero ' : ''}'
            'da ${numeroPerCampo(widget.minimo)} a ${numeroPerCampo(widget.massimo)}',
      );
      return;
    }
    Navigator.of(context).pop(numero);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTesto(
          key: const Key('campo-numero'),
          controller: _campo,
          etichetta: widget.etichetta,
          numerico: true,
          negativo: widget.minimo < 0,
          errore: _errore,
          azioneTastiera: TextInputAction.done,
        ),
        if (widget.aiuto != null) ...[
          const SizedBox(height: 8),
          Text(widget.aiuto!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        PulsanteLucido(
          etichetta: 'Salva',
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: _salva,
        ),
      ],
    );
  }
}
