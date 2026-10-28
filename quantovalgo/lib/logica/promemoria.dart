import '../modelli/lavoro.dart';
import 'formato.dart';
import 'pagamenti.dart';

/// Una notifica da far comparire sul telefono a una certa ora.
class Promemoria {
  const Promemoria({
    required this.id,
    required this.quando,
    required this.titolo,
    required this.testo,
  });

  final int id;
  final DateTime quando;
  final String titolo;
  final String testo;
}

/// A che ora del giorno arrivano i promemoria.
const oraPromemoria = 9;

/// Giorni, rispetto alla scadenza, in cui arriva un promemoria:
/// il giorno prima, il giorno stesso, e poi ogni 3 giorni di ritardo (5 volte).
const _scostamenti = [-1, 0, 3, 6, 9, 12, 15];

/// I promemoria dei pagamenti ancora da incassare, da qui in avanti.
///
/// Servono solo i lavori con una scadenza. Si tengono i [massimo] più vicini nel
/// tempo (Android non vuole migliaia di notifiche in coda). Chi incassa un
/// lavoro lo toglie da qui: basta ricalcolare e ripianificare tutto.
List<Promemoria> promemoriaPagamenti({
  required Iterable<Lavoro> lavori,
  required double Function(Lavoro) importo,
  required String Function(Lavoro) cliente,
  required DateTime adesso,
  int massimo = 60,
}) {
  final tutti = <({DateTime quando, String titolo, String testo})>[];

  for (final l in lavori) {
    final scadenza = l.scadenza;
    if (!daIncassare(l) || scadenza == null) continue;

    final nomeCliente = cliente(l);
    final chi = nomeCliente.isEmpty ? '' : ' ($nomeCliente)';
    final cosa = '«${l.nome}»$chi: ${euro(importo(l))}';

    for (final giorni in _scostamenti) {
      final quando = DateTime(
        scadenza.year,
        scadenza.month,
        scadenza.day + giorni,
        oraPromemoria,
      );
      if (!quando.isAfter(adesso)) continue;

      final (titolo, testo) = switch (giorni) {
        < 0 => ('Domani scade un pagamento', cosa),
        0 => ('Oggi scade un pagamento', cosa),
        _ => ('Pagamento in ritardo', '$cosa · ritardo di $giorni giorni'),
      };
      tutti.add((quando: quando, titolo: titolo, testo: testo));
    }
  }

  tutti.sort((a, b) => a.quando.compareTo(b.quando));
  return [
    for (var i = 0; i < tutti.length && i < massimo; i++)
      Promemoria(
        id: i + 1, // si cancella tutto prima di ripianificare: bastano numeri di fila
        quando: tutti[i].quando,
        titolo: tutti[i].titolo,
        testo: tutti[i].testo,
      ),
  ];
}
