import 'package:flutter/material.dart';

/// Un pezzo della barra: colore e peso (qualsiasi unità, conta la proporzione).
class SegmentoBarra {
  const SegmentoBarra(this.colore, this.peso);

  final Color colore;
  final double peso;
}

/// Barra a pillola divisa in pezzi colorati, come nel mockup dei Costi.
/// È solo un'immagine: le stesse informazioni stanno scritte nella legenda.
class BarraQuote extends StatelessWidget {
  const BarraQuote({super.key, required this.segmenti, this.altezza = 12});

  final List<SegmentoBarra> segmenti;
  final double altezza;

  @override
  Widget build(BuildContext context) {
    final visibili = segmenti.where((s) => s.peso > 0).toList();

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: altezza,
          color: const Color(0xFFD6EEF2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in visibili)
                Expanded(
                  // flex deve essere intero: 1 come minimo, così un pezzo
                  // piccolo non sparisce.
                  flex: (s.peso * 1000).round().clamp(1, 1 << 30),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(s.colore, Colors.white, 0.45)!,
                          s.colore,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pallino colorato + testo per le legende delle barre.
class VoceLegenda extends StatelessWidget {
  const VoceLegenda({super.key, required this.colore, required this.testo});

  final Color colore;
  final String testo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colore),
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            testo,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
