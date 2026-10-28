import 'package:flutter/material.dart';

import '../logica/calcoli.dart';
import '../modelli/tipi.dart';
import 'pulsante_scelta.dart';

/// "Chi è il cliente?": quattro pulsanti con lo sconto di ciascuna relazione.
class SelettoreRelazione extends StatelessWidget {
  const SelettoreRelazione({
    super.key,
    required this.valore,
    required this.onCambia,
    this.parametri = ParametriPrezzo.predefiniti,
  });

  final Relazione valore;
  final ValueChanged<Relazione> onCambia;
  final ParametriPrezzo parametri;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi è il cliente?',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: 60,
          padding: EdgeInsets.zero,
          children: [
            for (final r in Relazione.values)
              PulsanteScelta(
                etichetta: r.etichetta,
                sottotitolo: parametri.sconto(r) == 0
                    ? 'prezzo pieno'
                    : '−${parametri.sconto(r)}%',
                selezionato: r == valore,
                altezza: 60,
                onTap: () => onCambia(r),
              ),
          ],
        ),
      ],
    );
  }
}
