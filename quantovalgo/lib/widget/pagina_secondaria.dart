import 'package:flutter/material.dart';

import 'intestazione.dart';
import 'sfera_lucida.dart';
import 'sfondo_laguna.dart';

/// Schermata aperta sopra le altre (Clienti, Obiettivo, Impostazioni,
/// Nuovo lavoro): sfondo Laguna, titolo e pulsante "Indietro".
class PaginaSecondaria extends StatelessWidget {
  const PaginaSecondaria({
    super.key,
    required this.titolo,
    required this.figli,
  });

  final String titolo;

  /// Contenuto della pagina, in una lista che scorre.
  final List<Widget> figli;

  @override
  Widget build(BuildContext context) {
    return SfondoLaguna(
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Intestazione(
                titolo: titolo,
                sinistra: SferaLucida(
                  icona: Icons.arrow_back_rounded,
                  etichetta: 'Indietro',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: 16),
              ...figli,
            ],
          ),
        ),
      ),
    );
  }
}
