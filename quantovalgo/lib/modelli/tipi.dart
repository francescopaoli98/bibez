/// Tipo di lavoro. Le chiavi (`name`) finiscono nel database: non rinominarle.
enum TipoLavoro {
  doppiaggio('Doppiaggio'),
  codice('Codice'),
  claude('Claude'),

  /// Guadagno netto fisso per ogni giornata lavorata (es. il negozio).
  aGiornata('A giornata'),
  altro('Altro');

  const TipoLavoro(this.etichetta);
  final String etichetta;

  /// Legge la chiave salvata; se sconosciuta ripiega su "Altro".
  static TipoLavoro da(Object? chiave) => values.firstWhere(
    (t) => t.name == chiave,
    orElse: () => TipoLavoro.altro,
  );
}

/// Relazione con il cliente: decide lo sconto di partenza.
enum Relazione {
  nuovo('Persona nuova', 'Nuovo'),
  consigliato('Consigliato', 'Consigliato'),
  amico('Amico', 'Amico'),
  famiglia('Famiglia', 'Famiglia');

  const Relazione(this.etichetta, this.breve);

  /// Nome completo (pulsanti di scelta).
  final String etichetta;

  /// Nome corto (righe di elenco).
  final String breve;

  static Relazione da(Object? chiave) =>
      values.firstWhere((r) => r.name == chiave, orElse: () => Relazione.nuovo);
}

/// Stato del pagamento. "In ritardo" non si salva: si calcola dalla scadenza.
enum StatoPagamento {
  daIncassare,
  incassato;

  static StatoPagamento da(Object? chiave) => values.firstWhere(
    (s) => s.name == chiave,
    orElse: () => StatoPagamento.daIncassare,
  );
}

/// Legge un numero dal database (può arrivare come int o double).
double leggiDouble(Object? valore) => (valore as num?)?.toDouble() ?? 0;

/// Legge una data dal database (già convertita in DateTime dall'archivio).
DateTime? leggiData(Object? valore) => valore is DateTime ? valore : null;
