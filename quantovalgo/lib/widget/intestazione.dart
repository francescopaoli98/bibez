import 'package:flutter/material.dart';

import '../tema/colori.dart';

/// Riga in alto di ogni schermata: titolo a sinistra, eventuale pulsante a destra.
class Intestazione extends StatelessWidget {
  const Intestazione({
    super.key,
    required this.titolo,
    this.sottotitolo,
    this.sinistra,
    this.destra,
  });

  final String titolo;

  /// Riga più piccola sotto il titolo.
  final String? sottotitolo;

  /// Elemento prima del titolo (es. il pulsante "Indietro" o il logo).
  final Widget? sinistra;

  /// Elemento a fine riga (es. l'icona delle impostazioni).
  final Widget? destra;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Row(
      children: [
        if (sinistra != null) ...[sinistra!, const SizedBox(width: 10)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                container: true,
                header: true,
                child: Text(
                  titolo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.headlineMedium,
                ),
              ),
              if (sottotitolo != null)
                Text(
                  sottotitolo!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.labelMedium?.copyWith(
                    fontSize: 14,
                    color: ColoriLaguna.testoSecondario,
                  ),
                ),
            ],
          ),
        ),
        ?destra,
      ],
    );
  }
}
