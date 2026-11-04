import 'dart:typed_data';

/// Cosa si può fare con l'immagine di un preventivo. Un'interfaccia sola, così
/// i test usano una versione finta e l'app usa la galleria e la condivisione
/// di Android.
abstract interface class ServizioEsportazione {
  /// Salva il PNG nella galleria. Vero se è stato salvato (falso se manca il
  /// permesso o qualcosa è andato storto).
  Future<bool> salvaInGalleria(Uint8List png, String nome);

  /// Apre il foglio di condivisione di Android con l'immagine.
  Future<void> condividi(Uint8List png, String nome, {String? testo});
}
