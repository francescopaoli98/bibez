import '../modelli/cliente.dart';
import '../modelli/lavoro.dart';
import '../modelli/tipi.dart';
import 'giornate.dart';

/// Giorni di calendario tra due date (senza guardare l'ora, né il cambio d'ora).
int giorniTra(DateTime da, DateTime a) => DateTime.utc(
  a.year,
  a.month,
  a.day,
).difference(DateTime.utc(da.year, da.month, da.day)).inDays;

/// Quanto aspettarsi da un progetto: la somma dei ricavi dei sottoprogetti;
/// se non ce ne sono, il prezzo finale scritto nel lavoro.
double importoDaIncassare(double ricavi, double prezzoFinale) =>
    ricavi > 0 ? ricavi : prezzoFinale;

/// Giorno da cui si contano i giorni di pagamento: quando hai chiesto di
/// essere pagato, oppure quando hai creato il lavoro.
DateTime inizioPagamento(Lavoro lavoro) =>
    soloData(lavoro.richiestoIl ?? lavoro.creatoIl);

/// I lavori "A giornata" si incassano giorno per giorno: non hanno pagamenti.
bool haPagamento(Lavoro lavoro) => lavoro.tipo != TipoLavoro.aGiornata;

/// Non ancora incassato.
bool daIncassare(Lavoro lavoro) =>
    haPagamento(lavoro) && lavoro.statoPagamento == StatoPagamento.daIncassare;

/// In ritardo = scadenza superata e non incassato. Il giorno della scadenza
/// non è ancora ritardo.
bool inRitardo(Lavoro lavoro, DateTime adesso) =>
    daIncassare(lavoro) &&
    lavoro.scadenza != null &&
    soloData(lavoro.scadenza!).isBefore(soloData(adesso));

/// Giorni di ritardo (0 se non è in ritardo).
int giorniRitardo(Lavoro lavoro, DateTime adesso) =>
    inRitardo(lavoro, adesso) ? giorniTra(lavoro.scadenza!, adesso) : 0;

/// Giorni che il cliente ha impiegato a pagare (solo per i lavori incassati).
int? giorniPerPagare(Lavoro lavoro) {
  final incasso = lavoro.dataIncasso;
  if (!haPagamento(lavoro) ||
      lavoro.statoPagamento != StatoPagamento.incassato ||
      incasso == null) {
    return null;
  }
  final giorni = giorniTra(inizioPagamento(lavoro), incasso);
  return giorni < 0 ? 0 : giorni;
}

/// Media dei giorni per pagare (null se nessun lavoro è stato incassato).
double? mediaGiorniPerPagare(Iterable<Lavoro> lavori) {
  final giorni = [for (final l in lavori) ?giorniPerPagare(l)];
  if (giorni.isEmpty) return null;
  return giorni.fold<int>(0, (a, b) => a + b) / giorni.length;
}

/// Scadenza a "+N giorni" dal giorno [da].
DateTime scadenzaDopo(DateTime da, int giorni) {
  final d = soloData(da);
  return DateTime(d.year, d.month, d.day + giorni);
}

/// Come un cliente paga: quanto ha già dato, in quanto tempo, e se è in ritardo.
class StatisticheCliente {
  const StatisticheCliente({
    required this.cliente,
    required this.lavori,
    required this.incassato,
    required this.giorniMedi,
    required this.lavoriInRitardo,
    required this.importoInRitardo,
    required this.maxGiorniRitardo,
  });

  final Cliente cliente;

  /// Lavori del cliente con un pagamento (esclusi quelli a giornata).
  final int lavori;

  /// Somma degli importi già incassati.
  final double incassato;

  /// Giorni medi che impiega a pagare (vuoto se non ha ancora pagato nulla).
  final double? giorniMedi;

  final int lavoriInRitardo;
  final double importoInRitardo;
  final int maxGiorniRitardo;

  bool get ritardatario => lavoriInRitardo > 0;
}

/// Una riga di statistiche per ogni cliente.
List<StatisticheCliente> statisticheClienti({
  required Iterable<Cliente> clienti,
  required Iterable<Lavoro> lavori,
  required double Function(Lavoro) importo,
  required DateTime adesso,
}) {
  return [
    for (final cliente in clienti)
      () {
        final suoi = [
          for (final l in lavori)
            if (l.clienteId == cliente.id && haPagamento(l)) l,
        ];
        final ritardo = [
          for (final l in suoi)
            if (inRitardo(l, adesso)) l,
        ];
        return StatisticheCliente(
          cliente: cliente,
          lavori: suoi.length,
          incassato: suoi
              .where((l) => l.statoPagamento == StatoPagamento.incassato)
              .fold<double>(0, (somma, l) => somma + importo(l)),
          giorniMedi: mediaGiorniPerPagare(suoi),
          lavoriInRitardo: ritardo.length,
          importoInRitardo: ritardo.fold<double>(0, (s, l) => s + importo(l)),
          maxGiorniRitardo: ritardo.fold<int>(
            0,
            (max, l) =>
                giorniRitardo(l, adesso) > max ? giorniRitardo(l, adesso) : max,
          ),
        );
      }(),
  ];
}
