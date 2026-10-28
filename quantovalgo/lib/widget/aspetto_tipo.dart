import 'package:flutter/material.dart';

import '../modelli/tipi.dart';
import 'stile_lucido.dart';

/// Icona e colore della sfera di ogni tipo di lavoro.
extension AspettoTipo on TipoLavoro {
  IconData get icona => switch (this) {
    TipoLavoro.doppiaggio => Icons.mic_rounded,
    TipoLavoro.codice => Icons.code_rounded,
    TipoLavoro.claude => Icons.auto_awesome_rounded,
    TipoLavoro.aGiornata => Icons.storefront_rounded,
    TipoLavoro.altro => Icons.work_outline_rounded,
  };

  /// Rosso per il doppiaggio (come nel mockup), verde per le giornate, blu per gli altri.
  StileLucido get stile => switch (this) {
    TipoLavoro.doppiaggio => StileLucido.rosso,
    TipoLavoro.aGiornata => StileLucido.verde,
    _ => StileLucido.blu,
  };
}
