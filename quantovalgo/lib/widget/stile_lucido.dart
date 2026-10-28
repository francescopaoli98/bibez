import 'package:flutter/material.dart';

/// Colori di un pulsante lucido (stile Windows Vista/XP) del tema Laguna.
class StileLucido {
  const StileLucido({
    required this.sfumatura,
    required this.bordo,
    required this.testo,
    required this.ombra,
    required this.luceBasso,
    required this.ombraTesto,
  });

  /// Quattro colori: la sfumatura ha un taglio netto al 50%.
  final List<Color> sfumatura;
  final Color bordo;
  final Color testo;
  final Color ombra;

  /// Colore della luce interna chiara in basso.
  final Color luceBasso;
  final Color ombraTesto;

  /// Posizioni dei 4 colori: taglio netto a metà (50% → 51%).
  static const stop = [0.0, 0.5, 0.51, 1.0];

  /// Blu: azioni normali.
  static const blu = StileLucido(
    sfumatura: [Color(0xFF0A4F82), Color(0xFF0F72A8), Color(0xFF0C5F8F), Color(0xFF3CC4EE)],
    bordo: Color(0xFF0A4A7A),
    testo: Colors.white,
    ombra: Color(0x73053C64),
    luceBasso: Color(0xCC96EBFF),
    ombraTesto: Color(0xB3001E3C),
  );

  /// Verde: azione principale (es. "+" nuovo lavoro).
  static const verde = StileLucido(
    sfumatura: [Color(0xFF0F5F1F), Color(0xFF1A7F2A), Color(0xFF146B24), Color(0xFF6CE04A)],
    bordo: Color(0xFF0E5A1C),
    testo: Colors.white,
    ombra: Color(0x800A5014),
    luceBasso: Color(0xCCB4FF96),
    ombraTesto: Color(0xB3003C00),
  );

  /// Oro: "Cerca prezzi", "Migliora testo". Testo scuro sul giallo.
  static const oro = StileLucido(
    sfumatura: [Color(0xFFB87800), Color(0xFFF2A90C), Color(0xFFDE9400), Color(0xFFFFE27A)],
    bordo: Color(0xFF8A5A00),
    testo: Color(0xFF3A2400),
    ombra: Color(0x66965F00),
    luceBasso: Color(0xCCFFF0B4),
    ombraTesto: Color(0x66FFF0B4),
  );

  /// Rosso: usato per l'icona del microfono nei progetti di doppiaggio.
  static const rosso = StileLucido(
    sfumatura: [Color(0xFF7A1808), Color(0xFFC0391B), Color(0xFFA32D14), Color(0xFFFF8A5C)],
    bordo: Color(0xFF6E1608),
    testo: Colors.white,
    ombra: Color(0x73781E0A),
    luceBasso: Color(0xB3FFBE96),
    ombraTesto: Color(0x993C0A00),
  );
}
