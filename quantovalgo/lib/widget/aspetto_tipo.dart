import 'package:flutter/material.dart';

import '../modelli/tipi.dart';
import 'stile_lucido.dart';

/// Icona e colore della sfera di ogni tipo di lavoro.
extension AspettoTipo on TipoLavoro {
  IconData get icona => switch (this) {
    TipoLavoro.doppiaggio => Icons.mic_rounded,
    TipoLavoro.codice => Icons.code_rounded,
    TipoLavoro.claude => Icons.auto_awesome_rounded,
    TipoLavoro.altro => Icons.work_outline_rounded,
  };

  /// Rosso per il doppiaggio (come nel mockup), blu per gli altri.
  StileLucido get stile =>
      this == TipoLavoro.doppiaggio ? StileLucido.rosso : StileLucido.blu;
}
