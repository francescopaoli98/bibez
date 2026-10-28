import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../modelli/sottoprogetto.dart';
import '../servizi/stato_dati.dart';

/// Avvia il cronometro su un sottoprogetto e avvisa con un messaggio se ne
/// ha dovuto fermare un altro.
void avviaCronometro(
  BuildContext context,
  StatoDati dati,
  Sottoprogetto sottoprogetto,
) {
  final fermata = dati.avviaCronometro(sottoprogetto);
  if (fermata == null) return;
  final altro = dati.sottoprogetto(fermata.sessione.sottoprogettoId);
  _messaggio(
    context,
    fermata.salvata
        ? 'Fermato "${altro?.nome ?? 'il precedente'}": salvati ${durata(fermata.sessione.minuti)}'
        : 'Fermato "${altro?.nome ?? 'il precedente'}": meno di un minuto, non salvato',
  );
}

/// Ferma il cronometro acceso e dice quanto è stato salvato.
void fermaCronometro(BuildContext context, StatoDati dati) {
  final esito = dati.fermaCronometro();
  if (esito == null) return;
  final sotto = dati.sottoprogetto(esito.sessione.sottoprogettoId);
  _messaggio(
    context,
    esito.salvata
        ? 'Salvati ${durata(esito.sessione.minuti)} su "${sotto?.nome ?? 'sottoprogetto'}"'
        : 'Meno di un minuto: non salvato',
  );
}

void _messaggio(BuildContext context, String testo) {
  final messaggi = ScaffoldMessenger.maybeOf(context);
  messaggi
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(testo)));
}
