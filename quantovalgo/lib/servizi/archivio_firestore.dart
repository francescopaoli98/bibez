import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../modelli/cliente.dart';
import '../modelli/lavoro.dart';
import '../modelli/prezzo_mercato.dart';
import '../modelli/sottoprogetto.dart';
import 'accesso.dart';
import 'archivio.dart';
import 'utente.dart';

/// Archivio vero su Cloud Firestore (piano gratuito Spark).
///
/// Struttura: tutto sta sotto `utenti/{uid}`, così le regole di sicurezza
/// possono permettere a ognuno di vedere solo i propri dati:
/// `lavori`, `sottoprogetti`, `clienti`, `prezziMercato`.
class ArchivioFirestore implements Archivio {
  ArchivioFirestore({required this._accesso, FirebaseFirestore? db})
    : _dbIniettato = db;

  final ServizioAccesso _accesso;
  final FirebaseFirestore? _dbIniettato;
  FirebaseFirestore get _db => _dbIniettato ?? FirebaseFirestore.instance;

  /// Da chiamare una volta, subito dopo `Firebase.initializeApp()`.
  /// La cache offline tiene i dati sul telefono (massimo 50 MB).
  static void configura() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 50 * 1024 * 1024,
    );
  }

  // --- Percorsi ---

  DocumentReference<Map<String, dynamic>> _profilo(String uid) =>
      _db.collection('utenti').doc(uid);

  /// Raccolta dell'utente connesso. Se nessuno è connesso è un errore di
  /// programmazione: le schermate dei dati esistono solo dopo l'accesso.
  CollectionReference<Map<String, dynamic>> _raccolta(String nome) {
    final uid = _accesso.utenteCorrente?.uid;
    if (uid == null) throw StateError('Nessun utente connesso');
    return _profilo(uid).collection(nome);
  }

  /// Le date arrivano come `Timestamp`: i modelli vogliono `DateTime`.
  static Map<String, Object?> _normalizza(Map<String, dynamic> dati) => {
    for (final voce in dati.entries)
      voce.key: voce.value is Timestamp
          ? (voce.value as Timestamp).toDate()
          : voce.value,
  };

  // --- Profilo e sincronizzazione ---

  @override
  void assicuraProfilo(Utente utente) {
    // Niente await: senza internet la scrittura non "finisce" finché non
    // torna la rete, e non vogliamo bloccare l'app ad aspettarla.
    unawaited(
      _profilo(utente.uid)
          .set({
            'nome': utente.nome,
            'email': utente.email,
            'ultimoAccesso': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .catchError((Object e) {
            debugPrint('Profilo non salvato: $e');
          }),
    );
  }

  @override
  Stream<StatoSincronizzazione> statoSincronizzazione(String uid) async* {
    try {
      await for (final s in _profilo(
        uid,
      ).snapshots(includeMetadataChanges: true)) {
        final dalTelefono =
            s.metadata.isFromCache || s.metadata.hasPendingWrites;
        yield dalTelefono
            ? StatoSincronizzazione.inAttesa
            : StatoSincronizzazione.sincronizzato;
      }
    } on FirebaseException catch (e) {
      // Per esempio permission-denied: regole non pubblicate.
      debugPrint('Firestore rifiuta la lettura: ${e.code}');
      yield StatoSincronizzazione.problema;
    }
  }

  // --- Lettura ---

  Stream<List<T>> _ascolta<T>(
    String raccolta,
    T Function(String id, Map<String, Object?> dati) leggi,
  ) {
    if (_accesso.utenteCorrente == null) return Stream.value(<T>[]);
    return _raccolta(raccolta).snapshots().map(
      (q) => [for (final d in q.docs) leggi(d.id, _normalizza(d.data()))],
    );
  }

  @override
  Stream<List<Lavoro>> lavori() => _ascolta('lavori', Lavoro.fromMap);

  @override
  Stream<List<Sottoprogetto>> sottoprogetti() =>
      _ascolta('sottoprogetti', Sottoprogetto.fromMap);

  @override
  Stream<List<Cliente>> clienti() => _ascolta('clienti', Cliente.fromMap);

  @override
  Stream<List<PrezzoMercato>> prezziMercato() =>
      _ascolta('prezziMercato', PrezzoMercato.fromMap);

  // --- Scrittura (senza aspettare il cloud) ---

  String _salva(String raccolta, String id, Map<String, Object?> dati) {
    final riferimento = id.isEmpty
        ? _raccolta(raccolta).doc()
        : _raccolta(raccolta).doc(id);
    unawaited(
      riferimento.set(dati).catchError((Object e) {
        debugPrint('Salvataggio in $raccolta non riuscito: $e');
      }),
    );
    return riferimento.id;
  }

  void _elimina(String raccolta, String id) {
    unawaited(
      _raccolta(raccolta).doc(id).delete().catchError((Object e) {
        debugPrint('Eliminazione da $raccolta non riuscita: $e');
      }),
    );
  }

  @override
  String salvaLavoro(Lavoro lavoro) =>
      _salva('lavori', lavoro.id, lavoro.toMap());

  @override
  void eliminaLavoro(String id, {required List<String> idSottoprogetti}) {
    // Un solo "pacchetto": o spariscono tutti insieme o nessuno.
    final pacchetto = _db.batch();
    pacchetto.delete(_raccolta('lavori').doc(id));
    for (final idSotto in idSottoprogetti) {
      pacchetto.delete(_raccolta('sottoprogetti').doc(idSotto));
    }
    unawaited(
      pacchetto.commit().catchError((Object e) {
        debugPrint('Eliminazione del lavoro non riuscita: $e');
      }),
    );
  }

  @override
  String salvaSottoprogetto(Sottoprogetto s) =>
      _salva('sottoprogetti', s.id, s.toMap());

  @override
  void eliminaSottoprogetto(String id) => _elimina('sottoprogetti', id);

  @override
  String salvaCliente(Cliente cliente) =>
      _salva('clienti', cliente.id, cliente.toMap());

  @override
  void eliminaCliente(String id) => _elimina('clienti', id);

  @override
  void salvaPrezzoMercato(PrezzoMercato prezzo) =>
      _salva('prezziMercato', prezzo.id, prezzo.toMap());
}
