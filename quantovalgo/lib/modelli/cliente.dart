import 'tipi.dart';

/// Un cliente. Salvato in `utenti/{uid}/clienti/{id}`.
class Cliente {
  const Cliente({
    required this.id,
    required this.nome,
    required this.relazione,
    required this.creatoIl,
  });

  /// Vuoto per un cliente nuovo: l'archivio ne assegna uno al salvataggio.
  final String id;
  final String nome;
  final Relazione relazione;
  final DateTime creatoIl;

  Cliente copyWith({String? nome, Relazione? relazione}) => Cliente(
    id: id,
    nome: nome ?? this.nome,
    relazione: relazione ?? this.relazione,
    creatoIl: creatoIl,
  );

  Map<String, Object?> toMap() => {
    'nome': nome,
    'relazione': relazione.name,
    'creatoIl': creatoIl,
  };

  factory Cliente.fromMap(String id, Map<String, Object?> dati) => Cliente(
    id: id,
    nome: dati['nome'] as String? ?? '',
    relazione: Relazione.da(dati['relazione']),
    creatoIl:
        leggiData(dati['creatoIl']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
