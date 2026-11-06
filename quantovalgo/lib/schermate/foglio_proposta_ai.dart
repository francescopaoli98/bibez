import 'package:flutter/material.dart';

import '../logica/migliora_testo.dart';
import '../tema/colori.dart';
import '../widget/carta_vetro.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/stile_lucido.dart';

/// Mostra la proposta dell'AI accanto al testo di ora e chiede cosa fare.
/// Restituisce vero per "Usa questa", falso (o chiudendo il foglio) per
/// "Tieni la mia": senza una scelta esplicita il testo non cambia mai.
Future<bool> scegliProposta(
  BuildContext context, {
  required TestiDaMigliorare prima,
  required TestiMigliorati dopo,
}) async {
  final scelta = await mostraFoglio<bool>(
    context,
    titolo: 'Ecco la proposta',
    costruttore: (contesto) => _Proposta(prima: prima, dopo: dopo),
  );
  return scelta ?? false;
}

class _Proposta extends StatelessWidget {
  const _Proposta({required this.prima, required this.dopo});

  final TestiDaMigliorare prima;
  final TestiMigliorati dopo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _Blocco(
                  chiave: const Key('proposta-dopo'),
                  titolo: 'Con l\'AI',
                  evidenziato: true,
                  progetto: dopo.progetto,
                  fasi: dopo.fasi,
                  benefit: dopo.benefit,
                ),
                const SizedBox(height: 10),
                _Blocco(
                  chiave: const Key('proposta-prima'),
                  titolo: 'Il tuo testo',
                  progetto: prima.progetto,
                  fasi: prima.fasi,
                  benefit: prima.benefit,
                ),
                const SizedBox(height: 8),
                Text(
                  'Controlla che sia tutto giusto: l\'AI può sbagliare.',
                  style: tema.bodyMedium?.copyWith(
                    color: ColoriLaguna.testoSecondario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PulsanteLucido(
            key: const Key('usa-proposta'),
            etichetta: 'Usa questa',
            icona: Icons.check_rounded,
            stile: StileLucido.verde,
            altezza: 56,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          PulsanteLucido(
            key: const Key('tieni-la-mia'),
            etichetta: 'Tieni la mia',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

/// Un testo completo (frase, fasi, vantaggi) dentro una carta.
class _Blocco extends StatelessWidget {
  const _Blocco({
    required this.chiave,
    required this.titolo,
    required this.progetto,
    required this.fasi,
    required this.benefit,
    this.evidenziato = false,
  });

  final Key chiave;
  final String titolo;
  final String progetto;
  final List<String> fasi;
  final List<String> benefit;
  final bool evidenziato;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return CartaVetro(
      key: chiave,
      colori: evidenziato
          ? const [Color(0xFFFFFBE0), Color(0xFFFFF1B8)]
          : const [Color(0xF2FFFFFF), Color(0xD9EEFCFC)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titolo,
            style: tema.labelLarge?.copyWith(
              color: ColoriLaguna.testoSecondario,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(progetto, style: tema.titleMedium),
          const SizedBox(height: 8),
          for (final f in fasi) Text('• $f', style: tema.bodyMedium),
          const SizedBox(height: 6),
          for (final b in benefit) Text('✓ $b', style: tema.bodyMedium),
        ],
      ),
    );
  }
}
