import 'utente.dart';

/// Stato dei dati rispetto al cloud.
enum StatoSincronizzazione {
  /// Tutto allineato con il cloud.
  sincronizzato,

  /// Offline, oppure modifiche fatte sul telefono non ancora inviate.
  inAttesa,

  /// Il cloud rifiuta l'accesso (di solito: regole di Firestore non
  /// pubblicate o database non creato).
  problema,
}

/// Database cloud dell'app (per ora solo profilo e stato di sincronizzazione;
/// lavori, costi e il resto arrivano nei passi successivi).
abstract interface class Archivio {
  /// Crea o aggiorna il profilo dell'utente. Non aspetta il cloud: offline
  /// la scrittura resta in coda e parte da sola quando torna internet.
  void assicuraProfilo(Utente utente);

  Stream<StatoSincronizzazione> statoSincronizzazione(String uid);
}
