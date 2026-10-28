/// Scrive un importo all'italiana: `1.240 €`, `12,50 €`, `−35 €`.
/// Con [conSegno] i positivi hanno il `+` (saldi e utili: `+520 €`).
String euro(double valore, {bool conSegno = false}) {
  final arrotondato = (valore * 100).round() / 100;
  final assoluto = arrotondato.abs();
  final intero = assoluto.truncate();
  final centesimi = ((assoluto - intero) * 100).round();

  var testo = _conPunti(intero);
  if (centesimi != 0) testo += ',${centesimi.toString().padLeft(2, '0')}';

  final segno = arrotondato < 0
      ? '−'
      : (conSegno && arrotondato > 0 ? '+' : '');
  return '$segno$testo €';
}

/// Forbice scritta a interi: `56 – 84 €`.
String euroForbice(double minimo, double massimo) =>
    '${_conPunti(minimo.round())} – ${_conPunti(massimo.round())} €';

/// Ore all'italiana: `9 h`, `7,5 h`.
String ore(double valore) {
  final arrotondato = (valore * 10).round() / 10;
  final testo = arrotondato == arrotondato.truncate()
      ? arrotondato.truncate().toString()
      : arrotondato.toString().replaceAll('.', ',');
  return '$testo h';
}

/// Legge un numero scritto a mano ("12,5", "12.5", "1 000", "20 €").
/// Restituisce null se vuoto, non valido o negativo.
double? leggiNumero(String testo) {
  final pulito = testo
      .replaceAll('€', '')
      .replaceAll(RegExp(r'\s'), '')
      .replaceAll(',', '.');
  final valore = double.tryParse(pulito);
  return (valore == null || valore < 0 || valore.isNaN || valore.isInfinite)
      ? null
      : valore;
}

/// Numero da mettere in un campo di testo: `700`, `12,5`.
String numeroPerCampo(double valore) {
  final arrotondato = (valore * 100).round() / 100;
  if (arrotondato == arrotondato.truncate()) {
    return arrotondato.truncate().toString();
  }
  return arrotondato.toString().replaceAll('.', ',');
}

String _conPunti(int intero) {
  final cifre = intero.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < cifre.length; i++) {
    if (i > 0 && (cifre.length - i) % 3 == 0) buffer.write('.');
    buffer.write(cifre[i]);
  }
  return buffer.toString();
}

/// Quantità di giornate scritta bene: `mezza giornata`, `1 giornata`, `2,5 giornate`.
/// (Una mezza giornata conta 0,5.)
String testoGiornate(double quante) {
  if (quante == 0.5) return 'mezza giornata';
  final testo = numeroPerCampo(quante);
  return quante == 1 ? '1 giornata' : '$testo giornate';
}

/// Durata in minuti scritta bene: `45 min`, `2 h`, `1 h 30 min`.
String durata(int minuti) {
  final m = minuti < 0 ? 0 : minuti;
  final ore = m ~/ 60;
  final resto = m % 60;
  if (ore == 0) return '$resto min';
  if (resto == 0) return '$ore h';
  return '$ore h $resto min';
}

/// Tempo del cronometro: `00:12:34`.
String cronometro(Duration tempo) {
  final secondi = tempo.isNegative ? 0 : tempo.inSeconds;
  String due(int n) => n.toString().padLeft(2, '0');
  return '${due(secondi ~/ 3600)}:${due((secondi % 3600) ~/ 60)}:${due(secondi % 60)}';
}

/// Ora del giorno: `14:05`.
String oraDelGiorno(DateTime data) =>
    '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
