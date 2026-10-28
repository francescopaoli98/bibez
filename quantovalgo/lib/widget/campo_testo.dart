import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tema/colori.dart';

/// Campo di testo Laguna: etichetta sopra, casella bianca con bordo celeste.
/// Per i numeri usa [numerico]: tastiera con virgola e solo cifre.
class CampoTesto extends StatelessWidget {
  const CampoTesto({
    super.key,
    required this.controller,
    required this.etichetta,
    this.suggerimento,
    this.numerico = false,
    this.errore,
    this.onChanged,
    this.azioneTastiera = TextInputAction.next,
    this.maiuscole = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String etichetta;

  /// Testo grigio quando il campo è vuoto.
  final String? suggerimento;
  final bool numerico;

  /// Messaggio rosso sotto il campo.
  final String? errore;
  final ValueChanged<String>? onChanged;
  final TextInputAction azioneTastiera;
  final TextCapitalization maiuscole;

  static const _celeste = Color(0xFF6FCBEF);

  @override
  Widget build(BuildContext context) {
    final bordo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: _celeste, width: 2),
    );

    // Etichetta e campo letti insieme dal lettore di schermo.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etichetta,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: azioneTastiera,
            textCapitalization: numerico ? TextCapitalization.none : maiuscole,
            keyboardType: numerico
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: numerico
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                : null,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: ColoriLaguna.testo,
            ),
            decoration: InputDecoration(
              hintText: suggerimento,
              hintStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F7482),
              ),
              errorText: errore,
              errorStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: ColoriLaguna.negativo,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: bordo,
              focusedBorder: bordo.copyWith(
                borderSide: const BorderSide(
                  color: Color(0xFF0F72A8),
                  width: 2.5,
                ),
              ),
              errorBorder: bordo.copyWith(
                borderSide: const BorderSide(
                  color: ColoriLaguna.negativo,
                  width: 2,
                ),
              ),
              focusedErrorBorder: bordo.copyWith(
                borderSide: const BorderSide(
                  color: ColoriLaguna.negativo,
                  width: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
