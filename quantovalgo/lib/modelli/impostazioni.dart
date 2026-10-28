/// Impostazioni dell'utente. Salvate in `utenti/{uid}/impostazioni/generali`
/// (un solo documento). Altri valori (sconti, tasse, obiettivo) arrivano nel
/// passo 8.
class Impostazioni {
  const Impostazioni({this.promemoria = true});

  /// Promemoria dei pagamenti con notifiche sul telefono.
  final bool promemoria;

  Impostazioni copyWith({bool? promemoria}) =>
      Impostazioni(promemoria: promemoria ?? this.promemoria);

  Map<String, Object?> toMap() => {'promemoria': promemoria};

  /// Un valore mancante vale quello di partenza (vale anche per i dati vecchi).
  factory Impostazioni.fromMap(Map<String, Object?> dati) =>
      Impostazioni(promemoria: dati['promemoria'] as bool? ?? true);
}
