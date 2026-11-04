import 'package:flutter/widgets.dart';

import 'accesso.dart';
import 'archivio.dart';
import 'esportazione.dart';
import 'ricerca_prezzi.dart';

/// Rende disponibili accesso e archivio a tutte le schermate, senza
/// librerie esterne: `ServiziApp.di(context).accesso`.
class ServiziApp extends InheritedWidget {
  const ServiziApp({
    super.key,
    required this.accesso,
    required this.archivio,
    this.ricerca,
    this.esportazione,
    required super.child,
  });

  final ServizioAccesso accesso;
  final Archivio archivio;

  /// Ricerca dei prezzi sul web (vuota: il pulsante "Cerca prezzi" è spento).
  final RicercaPrezzi? ricerca;

  /// Salvataggio e condivisione dell'immagine del preventivo.
  final ServizioEsportazione? esportazione;

  static ServiziApp di(BuildContext context) {
    final servizi = context.dependOnInheritedWidgetOfExactType<ServiziApp>();
    assert(servizi != null, 'ServiziApp non trovato sopra questo widget');
    return servizi!;
  }

  @override
  bool updateShouldNotify(ServiziApp vecchio) =>
      accesso != vecchio.accesso ||
      archivio != vecchio.archivio ||
      ricerca != vecchio.ricerca ||
      esportazione != vecchio.esportazione;
}
