import '../modelli/introito.dart';

/// Somma dei guadagni veloci dati (ignora gli importi negativi o nulli).
double totaleIntroiti(Iterable<Introito> introiti) => introiti.fold<double>(
  0,
  (somma, i) => i.importo > 0 ? somma + i.importo : somma,
);
