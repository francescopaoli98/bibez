/// L'utente che ha fatto l'accesso (solo i dati che servono all'app).
class Utente {
  const Utente({required this.uid, this.nome, this.email});

  /// Identificativo unico: tutti i dati dell'utente stanno sotto `utenti/{uid}`.
  final String uid;
  final String? nome;
  final String? email;
}
