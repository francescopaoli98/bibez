import '../logica/promemoria.dart';

/// Notifiche programmate sul telefono. Un'interfaccia sola, così i test usano
/// una versione finta e l'app vera usa le notifiche di Android.
abstract interface class ServizioPromemoria {
  /// Chiede il permesso di mostrare notifiche (Android 13 e successivi).
  /// Restituisce vero se si possono mostrare.
  Future<bool> chiediPermesso();

  /// Sostituisce **tutte** le notifiche programmate con queste.
  Future<void> programma(List<Promemoria> promemoria);
}
