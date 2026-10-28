import '../modelli/categoria.dart';
import '../modelli/cliente.dart';
import '../modelli/costo.dart';
import '../modelli/lavoro.dart';
import '../modelli/prezzo_mercato.dart';
import '../modelli/sottoprogetto.dart';
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

/// Database cloud dell'app.
///
/// Le scritture NON aspettano il cloud: senza internet restano in coda e
/// partono da sole, intanto i flussi (`Stream`) mostrano già la modifica.
/// Per questo i metodi di scrittura restituiscono subito.
abstract interface class Archivio {
  /// Crea o aggiorna il profilo dell'utente.
  void assicuraProfilo(Utente utente);

  Stream<StatoSincronizzazione> statoSincronizzazione(String uid);

  // --- Lettura: ogni flusso emette subito l'elenco attuale e poi i cambi ---
  Stream<List<Lavoro>> lavori();
  Stream<List<Sottoprogetto>> sottoprogetti();
  Stream<List<Cliente>> clienti();
  Stream<List<PrezzoMercato>> prezziMercato();
  Stream<List<Costo>> costi();
  Stream<List<Categoria>> categorie();

  // --- Scrittura. Con id vuoto si crea; il metodo restituisce l'id. ---
  String salvaLavoro(Lavoro lavoro);

  /// Elimina il lavoro e, nello stesso colpo, i suoi sottoprogetti.
  void eliminaLavoro(String id, {required List<String> idSottoprogetti});

  String salvaSottoprogetto(Sottoprogetto sottoprogetto);
  void eliminaSottoprogetto(String id);

  String salvaCliente(Cliente cliente);
  void eliminaCliente(String id);

  void salvaPrezzoMercato(PrezzoMercato prezzo);

  String salvaCosto(Costo costo);
  void eliminaCosto(String id);

  String salvaCategoria(Categoria categoria);
  void eliminaCategoria(String id);
}
