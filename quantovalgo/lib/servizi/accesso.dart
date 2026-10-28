import 'utente.dart';

/// Accesso all'app (login Google). Un'interfaccia sola, così i test usano
/// una versione finta e l'app vera usa Firebase.
abstract interface class ServizioAccesso {
  /// Utente attuale. Emette subito il valore corrente (null = non connesso).
  /// Dopo il primo accesso l'utente resta salvato sul telefono, quindi l'app
  /// si apre già connessa anche senza internet.
  Stream<Utente?> get utente;

  Utente? get utenteCorrente;

  /// Apre la scelta dell'account Google. Se l'utente annulla, non succede nulla.
  /// Per qualsiasi altro problema lancia [ErroreAccesso].
  Future<void> accediConGoogle();

  Future<void> esci();
}

/// Problema di accesso, con un messaggio già in italiano da mostrare.
class ErroreAccesso implements Exception {
  const ErroreAccesso(this.messaggio, {this.dettagli});

  final String messaggio;

  /// Testo tecnico (utile per capire cosa non va nella configurazione).
  final String? dettagli;

  @override
  String toString() => messaggio;
}
