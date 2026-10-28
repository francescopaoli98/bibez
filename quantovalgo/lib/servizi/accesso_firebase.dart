import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'accesso.dart';
import 'utente.dart';

/// Accesso vero: Google Sign-In + Firebase Authentication.
class AccessoFirebase implements ServizioAccesso {
  AccessoFirebase({FirebaseAuth? auth, GoogleSignIn? google})
    : _authIniettato = auth,
      _googleIniettato = google;

  // Presi solo quando servono: così creare l'oggetto non fallisce
  // se Firebase non è (ancora) configurato.
  final FirebaseAuth? _authIniettato;
  final GoogleSignIn? _googleIniettato;
  FirebaseAuth get _auth => _authIniettato ?? FirebaseAuth.instance;
  GoogleSignIn get _google => _googleIniettato ?? GoogleSignIn.instance;

  Future<void>? _inizializzazione;

  /// google_sign_in 7 vuole un solo `initialize()`. Su Android usa da solo
  /// il client ID del file google-services.json.
  Future<void> _preparaGoogle() => _inizializzazione ??= _google.initialize();

  static Utente? _converti(User? u) => u == null
      ? null
      : Utente(uid: u.uid, nome: u.displayName, email: u.email);

  @override
  Stream<Utente?> get utente => _auth.authStateChanges().map(_converti);

  @override
  Utente? get utenteCorrente => _converti(_auth.currentUser);

  @override
  Future<void> accediConGoogle() async {
    try {
      await _preparaGoogle();
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const ErroreAccesso(
          'Google non ha restituito il token di accesso. Riprova.',
        );
      }
      final credenziali = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credenziali);
    } on GoogleSignInException catch (e) {
      throw _traduci(e);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const ErroreAccesso('Serve internet per il primo accesso.');
      }
      throw ErroreAccesso(
        'Accesso non riuscito.',
        dettagli: '${e.code}: ${e.message}',
      );
    }
  }

  /// Trasforma gli errori di Google in frasi comprensibili.
  ErroreAccesso _traduci(GoogleSignInException e) {
    final dettagli = '${e.code.name}: ${e.description ?? '-'}';
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        // Con una configurazione sbagliata Android segnala spesso "annullato".
        return ErroreAccesso(
          'Accesso annullato. Se non l\'hai annullato tu, controlla che l\'impronta '
          'SHA-1 sia registrata su Firebase.',
          dettagli: dettagli,
        );
      case GoogleSignInExceptionCode.interrupted:
        return ErroreAccesso(
          'Accesso interrotto. Riprova.',
          dettagli: dettagli,
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return ErroreAccesso(
          'Configurazione di Google non corretta. Registra l\'impronta SHA-1 su '
          'Firebase e scarica di nuovo google-services.json.',
          dettagli: dettagli,
        );
      default:
        return ErroreAccesso('Accesso non riuscito.', dettagli: dettagli);
    }
  }

  @override
  Future<void> esci() async {
    await _preparaGoogle();
    await _google.signOut();
    await _auth.signOut();
  }
}
