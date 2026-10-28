import 'package:flutter/material.dart';

/// Un colore della tavolozza delle categorie, con il suo nome
/// (il colore da solo non basta: chi non distingue i colori legge il nome).
class ColoreCategoria {
  const ColoreCategoria(this.nome, this.colore);

  final String nome;
  final Color colore;
}

/// Tavolozza di 10 colori. Si salva la posizione, quindi l'ordine non va
/// cambiato: si possono solo aggiungere colori in fondo.
const paletteCategorie = [
  ColoreCategoria('Turchese', Color(0xFF1E9CB0)),
  ColoreCategoria('Blu', Color(0xFF1B63C4)),
  ColoreCategoria('Verde', Color(0xFF1A8F2E)),
  ColoreCategoria('Lime', Color(0xFF7DB82A)),
  ColoreCategoria('Oro', Color(0xFFE0A000)),
  ColoreCategoria('Arancio', Color(0xFFE8741C)),
  ColoreCategoria('Rosso', Color(0xFFC0391B)),
  ColoreCategoria('Rosa', Color(0xFFD9467E)),
  ColoreCategoria('Viola', Color(0xFF7A4FC8)),
  ColoreCategoria('Grigio', Color(0xFF5C7A88)),
];

/// Colore alla posizione [indice] (se fuori tavolozza, il primo).
ColoreCategoria coloreDellaPalette(int indice) =>
    paletteCategorie[(indice >= 0 && indice < paletteCategorie.length)
        ? indice
        : 0];
