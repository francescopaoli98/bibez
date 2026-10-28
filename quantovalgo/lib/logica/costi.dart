import '../modelli/costo.dart';
import '../modelli/lavoro.dart';
import '../modelli/tipi.dart';
import 'mesi.dart';

/// Quanto pesa un costo in un certo mese.
///
/// - Abbonamento e fisso: l'importo, dal mese di inizio fino all'eventuale fine.
/// - Una tantum: il prezzo diviso i mesi (90 € ÷ 6 = 15 €/mese), a partire dal
///   mese dell'acquisto. Con 1 mese pesa tutto nel mese in cui l'hai pagato.
double quotaNelMese(Costo costo, DateTime mese) {
  final corrente = primoDelMese(mese);
  final trascorsi = differenzaMesi(primoDelMese(costo.inizio), corrente);
  if (trascorsi < 0) return 0; // non è ancora iniziato

  switch (costo.tipo) {
    case TipoCosto.unaTantum:
      final mesi = costo.mesi < 1 ? 1 : costo.mesi;
      return trascorsi < mesi ? costo.importo / mesi : 0;
    case TipoCosto.abbonamento:
    case TipoCosto.fisso:
      final fine = costo.fine;
      if (fine != null && corrente.isAfter(primoDelMese(fine))) return 0;
      return costo.importo;
  }
}

/// Totale dei costi di un mese.
double totaleCostiDelMese(Iterable<Costo> costi, DateTime mese) =>
    costi.fold<double>(0, (somma, c) => somma + quotaNelMese(c, mese));

/// Progetto con il peso che ha nella divisione di un costo.
class PesoProgetto {
  const PesoProgetto(this.lavoroId, this.ore);

  final String lavoroId;
  final double ore;
}

/// La parte di un costo che tocca a un progetto.
class Quota {
  const Quota({
    required this.lavoroId,
    required this.percentuale,
    required this.importo,
  });

  final String lavoroId;

  /// Da 0 a 100.
  final double percentuale;

  /// In euro, arrotondato ai centesimi.
  final double importo;
}

/// Divide [importo] tra i progetti: in proporzione alle ore lavorate; se
/// nessuno ha ore, in parti uguali. I centesimi avanzati vanno ai progetti
/// con il resto più grande, così la somma fa sempre esattamente [importo].
///
/// Esempio: 20 € con ore 11 / 7 / 2 → 11 € + 7 € + 2 €.
List<Quota> ripartisci(double importo, List<PesoProgetto> progetti) {
  if (progetti.isEmpty) return const [];

  final oreTotali = progetti.fold<double>(0, (s, p) => s + p.ore);
  final pesi = [for (final p in progetti) oreTotali > 0 ? p.ore : 1.0];
  final pesoTotale = pesi.fold<double>(0, (s, p) => s + p);

  final centesimiTotali = (importo * 100).round();
  final esatti = [for (final p in pesi) centesimiTotali * p / pesoTotale];
  final centesimi = [for (final e in esatti) e.floor()];

  // Distribuisce i centesimi mancanti a chi ha la parte decimale più alta.
  var mancanti = centesimiTotali - centesimi.fold<int>(0, (s, c) => s + c);
  final ordine = List.generate(progetti.length, (i) => i)
    ..sort(
      (a, b) => (esatti[b] - centesimi[b]).compareTo(esatti[a] - centesimi[a]),
    );
  for (final i in ordine) {
    if (mancanti <= 0) break;
    centesimi[i]++;
    mancanti--;
  }

  return [
    for (var i = 0; i < progetti.length; i++)
      Quota(
        lavoroId: progetti[i].lavoroId,
        percentuale: pesi[i] / pesoTotale * 100,
        importo: centesimi[i] / 100,
      ),
  ];
}

/// Progetti "attivi" in un mese: già creati e non ancora incassati
/// (oppure incassati proprio in quel mese). Solo loro si dividono i costi.
List<Lavoro> progettiAttivi(Iterable<Lavoro> lavori, DateTime mese) {
  final inizio = primoDelMese(mese);
  final fine = meseSuccessivo(mese);
  return [
    for (final l in lavori)
      if (l.creatoIl.isBefore(fine) &&
          (l.statoPagamento == StatoPagamento.daIncassare ||
              (l.dataIncasso != null && !l.dataIncasso!.isBefore(inizio))))
        l,
  ];
}

/// Costi una tantum ancora da recuperare con i guadagni.
class DaRecuperare {
  const DaRecuperare({required this.totale, required this.recuperato});

  /// Somma dei prezzi pagati per i costi una tantum.
  final double totale;

  /// Quanto ne hanno già coperto i progetti incassati (mai più del totale).
  final double recuperato;

  double get residuo => totale - recuperato;

  /// Da 0 a 1, per la barra di avanzamento.
  double get avanzamento => totale <= 0 ? 0 : recuperato / totale;
}

/// "Da recuperare" = costi una tantum meno l'utile dei progetti incassati
/// (ricavi − costi diretti). Gli abbonamenti e i fissi non contano: si
/// coprono mese per mese con il saldo.
DaRecuperare daRecuperare({
  required Iterable<Costo> costi,
  required double utileIncassato,
}) {
  final totale = costi
      .where((c) => c.tipo == TipoCosto.unaTantum)
      .fold<double>(0, (s, c) => s + c.importo);
  final coperto = utileIncassato < 0 ? 0.0 : utileIncassato;
  return DaRecuperare(
    totale: totale,
    recuperato: coperto > totale ? totale : coperto,
  );
}
