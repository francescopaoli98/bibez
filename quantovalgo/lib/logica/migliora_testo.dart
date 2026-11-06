import 'dart:convert';

import '../modelli/tipi.dart';

/// Il miglioramento del testo del preventivo con l'AI (Claude).
///
/// Qui c'è solo la parte "pura": cosa si manda e come si legge la risposta.
/// Niente rete, così si prova nei test. La chiamata vera sta in
/// `servizi/migliora_testo_claude.dart`.
///
/// Costo: si usa il modello piccolo e veloce (Haiku 5.5, 0,10 $ ogni milione
/// di parole in ingresso e 0,50 $ in uscita), quindi un miglioramento costa
/// una frazione di centesimo. Parte solo se premi il pulsante.
const modelloAi = 'claude-haiku-5-5';

/// Versione dell'API di Anthropic che l'app sa parlare.
const versioneApiAi = '2026-10-21';

/// Limiti di lunghezza: il foglio del preventivo ha poco spazio.
const maxCaratteriProgetto = 160;
const maxCaratteriRiga = 70;
const maxRighe = 6;

/// I testi che l'utente ha scelto, così come sono ora.
class TestiDaMigliorare {
  const TestiDaMigliorare({
    required this.tipo,
    required this.progetto,
    required this.fasi,
    required this.benefit,
    required this.consegna,
  });

  final TipoLavoro tipo;

  /// Cosa fai, in poche parole.
  final String progetto;
  final List<String> fasi;
  final List<String> benefit;

  /// Solo per contesto: non si riscrive.
  final String consegna;
}

/// La proposta dell'AI: gli stessi tre testi, scritti meglio.
class TestiMigliorati {
  const TestiMigliorati({
    required this.progetto,
    required this.fasi,
    required this.benefit,
  });

  final String progetto;
  final List<String> fasi;
  final List<String> benefit;
}

const _istruzioni =
    'Sei un assistente che aiuta un freelance italiano a rendere più chiaro e '
    'convincente il testo di un preventivo. Scrivi in italiano semplice, '
    'caldo e professionale, dando del tu o in forma neutra come nel testo '
    'originale. Regole: mantieni gli stessi fatti e lo stesso significato; '
    'non inventare prezzi, date, numeri, nomi, garanzie o servizi che non '
    'sono nel testo; non nominare il cliente; non parlare della consegna '
    '(viene aggiunta a parte). Rispetta le lunghezze: "progetto" è una sola '
    'frase di al massimo $maxCaratteriProgetto caratteri; ogni voce di "fasi" '
    'e "benefit" al massimo $maxCaratteriRiga caratteri, senza elenchi '
    'puntati né numeri. Restituisci lo stesso numero di voci ricevute in '
    '"fasi" e in "benefit".';

/// Come deve essere fatta la risposta (JSON con tre campi).
const _schema = {
  'type': 'object',
  'properties': {
    'progetto': {'type': 'string'},
    'fasi': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'benefit': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['progetto', 'fasi', 'benefit'],
  'additionalProperties': false,
};

/// Il corpo della richiesta all'API (sempre lo stesso per gli stessi testi).
Map<String, Object?> corpoRichiesta(TestiDaMigliorare t) => {
  'model': modelloAi,
  'max_tokens': 1500,
  'system': _istruzioni,
  // Poca riflessione: è una riscrittura breve, non serve ragionare a lungo
  'output_config': {
    'effort': 'low',
    'format': {'type': 'json_schema', 'schema': _schema},
  },
  'messages': [
    {
      'role': 'user',
      'content': jsonEncode({
        'tipo_di_lavoro': t.tipo.etichetta,
        'progetto': t.progetto,
        'fasi': t.fasi,
        'benefit': t.benefit,
        'consegna_non_da_riscrivere': t.consegna,
      }),
    },
  ],
};

/// Legge la risposta dell'API (già decodificata) e controlla che sia usabile.
/// Restituisce null se il testo non è valido: meglio nessuna proposta che una
/// proposta rotta.
TestiMigliorati? leggiRisposta(
  Map<String, Object?> risposta, {
  required TestiDaMigliorare originali,
}) {
  // L'AI si è rifiutata di rispondere
  if (risposta['stop_reason'] == 'refusal') return null;

  final contenuto = risposta['content'];
  if (contenuto is! List) return null;
  // Il testo sta nei blocchi di tipo "text" (gli altri sono la riflessione)
  final testo = contenuto
      .whereType<Map<Object?, Object?>>()
      .where((b) => b['type'] == 'text')
      .map((b) => b['text'])
      .whereType<String>()
      .join();
  if (testo.trim().isEmpty) return null;

  final Object? dati;
  try {
    dati = jsonDecode(_senzaRecinto(testo));
  } on FormatException {
    return null;
  }
  if (dati is! Map) return null;

  final progetto = dati['progetto'];
  if (progetto is! String) return null;
  final fasi = _righe(dati['fasi']);
  final benefit = _righe(dati['benefit']);
  if (fasi == null || benefit == null) return null;

  final p = _pulisci(progetto);
  if (p.isEmpty || p.length > maxCaratteriProgetto + 40) return null;

  // Stesso numero di voci di prima (o poche di più): niente righe sparite
  if (fasi.length < originali.fasi.length ||
      benefit.length < originali.benefit.length) {
    return null;
  }
  if (fasi.length > maxRighe || benefit.length > maxRighe) return null;
  if ([...fasi, ...benefit].any((r) => r.length > maxCaratteriRiga + 30)) {
    return null;
  }

  return TestiMigliorati(progetto: p, fasi: fasi, benefit: benefit);
}

/// Toglie il recinto ```json ... ``` se il modello lo ha messo comunque.
String _senzaRecinto(String testo) {
  final t = testo.trim();
  if (!t.startsWith('```')) return t;
  final inizio = t.indexOf('\n');
  final fine = t.lastIndexOf('```');
  if (inizio == -1 || fine <= inizio) return t;
  return t.substring(inizio + 1, fine).trim();
}

String _pulisci(String testo) => testo.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Righe pulite, senza vuoti né pallini davanti. Null se non è un elenco di testi.
List<String>? _righe(Object? v) {
  if (v is! List || v.any((e) => e is! String)) return null;
  final righe = [
    for (final e in v.cast<String>())
      _pulisci(e)
          .replaceFirst(RegExp(r'^[-•*\d.)\s]+(?=\p{L})', unicode: true), ''),
  ].where((r) => r.isNotEmpty).toList();
  return righe.isEmpty ? null : righe;
}
