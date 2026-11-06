import '../logica/migliora_testo.dart';

/// Esito del miglioramento del testo con l'AI.
sealed class EsitoMiglioramento {
  const EsitoMiglioramento();
}

/// L'AI ha scritto una proposta valida.
class MiglioramentoRiuscito extends EsitoMiglioramento {
  const MiglioramentoRiuscito(this.testi);

  final TestiMigliorati testi;
}

/// Qualcosa non ha funzionato: [messaggio] spiega cosa, in italiano.
class MiglioramentoFallito extends EsitoMiglioramento {
  const MiglioramentoFallito(this.messaggio, {this.serveChiave = false});

  final String messaggio;

  /// Vero se la chiave manca o non è valida: conviene riaprire il foglio chiave.
  final bool serveChiave;
}

/// Chi sa riscrivere meglio i testi del preventivo. Parte solo quando
/// l'utente preme il pulsante, mai da solo.
abstract interface class MiglioraTesto {
  Future<EsitoMiglioramento> migliora(
    TestiDaMigliorare testi, {
    required String chiave,
  });
}
