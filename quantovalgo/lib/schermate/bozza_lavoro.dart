import '../modelli/tipi.dart';

/// Quello che si è deciso finora nel percorso "Nuovo lavoro" in tre domande.
/// Passa da un passo al successivo, senza salvare niente fino alla fine.
class BozzaLavoro {
  const BozzaLavoro({
    required this.tipo,
    this.clienteId,
    this.relazione = Relazione.nuovo,
    this.minuti = 60,
    this.conTrasferta = false,
    this.km = 20,
  });

  final TipoLavoro tipo;

  /// Vuoto = lavoro senza cliente.
  final String? clienteId;
  final Relazione relazione;

  /// Il tempo che ci metti, in minuti.
  final int minuti;

  /// Se c'è uno spostamento, e quanti km (andata e ritorno insieme).
  final bool conTrasferta;
  final double km;

  BozzaLavoro copyWith({
    String? Function()? clienteId,
    Relazione? relazione,
    int? minuti,
    bool? conTrasferta,
    double? km,
  }) => BozzaLavoro(
    tipo: tipo,
    clienteId: clienteId != null ? clienteId() : this.clienteId,
    relazione: relazione ?? this.relazione,
    minuti: minuti ?? this.minuti,
    conTrasferta: conTrasferta ?? this.conTrasferta,
    km: km ?? this.km,
  );
}
