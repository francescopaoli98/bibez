import 'package:flutter/material.dart';

/// Riga in alto di ogni schermata: titolo a sinistra, eventuale pulsante a destra.
class Intestazione extends StatelessWidget {
  const Intestazione({
    super.key,
    required this.titolo,
    this.sinistra,
    this.destra,
  });

  final String titolo;

  /// Elemento prima del titolo (es. il pulsante "Indietro" o il logo).
  final Widget? sinistra;

  /// Elemento a fine riga (es. l'icona delle impostazioni).
  final Widget? destra;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (sinistra != null) ...[sinistra!, const SizedBox(width: 10)],
        Expanded(
          child: Semantics(
            container: true,
            header: true,
            child: Text(
              titolo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
        ?destra,
      ],
    );
  }
}
