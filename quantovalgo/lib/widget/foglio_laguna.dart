import 'package:flutter/material.dart';

import '../tema/colori.dart';

/// Apre un foglio che sale dal basso (per moduli veloci), con lo stile Laguna.
/// Si alza da solo sopra la tastiera. [costruttore] riceve il context del foglio.
Future<T?> mostraFoglio<T>(
  BuildContext context, {
  required String titolo,
  required Widget Function(BuildContext) costruttore,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (contesto) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(contesto).bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.white, width: 2)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FDFC), Color(0xFFD5F7F1)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x4D065A78),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Maniglia
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: ColoriLaguna.testoSecondario.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  header: true,
                  child: Text(
                    titolo,
                    style: Theme.of(contesto).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 14),
                costruttore(contesto),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Chiede conferma prima di un'azione che cancella dati. Vero se confermata.
Future<bool> chiediConferma(
  BuildContext context, {
  required String titolo,
  required String testo,
  required String etichettaConferma,
}) async {
  final risposta = await showDialog<bool>(
    context: context,
    builder: (contesto) => AlertDialog(
      title: Text(titolo),
      content: Text(testo),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contesto).pop(false),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.of(contesto).pop(true),
          child: Text(
            etichettaConferma,
            style: const TextStyle(
              color: ColoriLaguna.negativo,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
  return risposta ?? false;
}
