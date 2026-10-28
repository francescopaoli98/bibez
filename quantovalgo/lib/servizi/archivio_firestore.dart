import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'archivio.dart';
import 'utente.dart';

/// Archivio vero su Cloud Firestore (piano gratuito Spark).
///
/// Struttura: tutto sta sotto `utenti/{uid}`, così le regole di sicurezza
/// possono permettere a ognuno di vedere solo i propri dati.
class ArchivioFirestore implements Archivio {
  ArchivioFirestore({FirebaseFirestore? db}) : _dbIniettato = db;

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

  DocumentReference<Map<String, dynamic>> _profilo(String uid) =>
      _db.collection('utenti').doc(uid);

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
}
