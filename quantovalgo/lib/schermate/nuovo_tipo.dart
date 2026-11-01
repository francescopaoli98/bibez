import 'package:flutter/material.dart';

import '../modelli/tipi.dart';
import '../tema/colori.dart';
import '../widget/aspetto_tipo.dart';
import '../widget/carta_vetro.dart';
import '../widget/passo_guidato.dart';
import '../widget/sfera_lucida.dart';
import 'bozza_lavoro.dart';
import 'nuovo_chi.dart';
import 'nuovo_lavoro.dart';

/// Passo 1 di "Nuovo lavoro": che lavoro è? Cinque grandi tasselli.
class PassoTipo extends StatelessWidget {
  const PassoTipo({super.key});

  static const _sotto = {
    TipoLavoro.doppiaggio: 'voce, audiolibri',
    TipoLavoro.codice: 'siti e programmi',
    TipoLavoro.claude: 'lavori con l\'AI',
    TipoLavoro.aGiornata: 'tipo il negozio',
    TipoLavoro.altro: 'assistenza, aiuto a qualcuno, qualsiasi cosa',
  };

  void _scegli(BuildContext context, TipoLavoro tipo) {
    if (tipo == TipoLavoro.aGiornata) {
      // Un lavoro a giornata ha solo nome e guadagno al giorno: basta il modulo
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              const NuovoLavoroPagina(tipoIniziale: TipoLavoro.aGiornata),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PassoChi(bozza: BozzaLavoro(tipo: tipo)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget tassello(TipoLavoro t, {bool largo = false}) {
      final tema = Theme.of(context).textTheme;
      return CartaVetro(
        padding: const EdgeInsets.all(16),
        onTap: () => _scegli(context, t),
        // I tasselli quadrati hanno altezza fissa (la sferetta sta in alto e il
        // testo in basso); quello largo si adatta al testo.
        child: ConstrainedBox(
          constraints: largo
              ? const BoxConstraints(minHeight: 60)
              : const BoxConstraints.tightFor(height: 116),
          child: largo
              ? Row(
                  children: [
                    IconaSfera(icona: t.icona, stile: t.stile, dimensione: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Testi(t: t, sotto: _sotto[t]!, tema: tema),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconaSfera(icona: t.icona, stile: t.stile, dimensione: 56),
                    const Spacer(),
                    _Testi(t: t, sotto: _sotto[t]!, tema: tema),
                  ],
                ),
        ),
      );
    }

    return PassoGuidato(
      titolo: 'Che lavoro è?',
      sottotitolo: 'Tocca quello che somiglia di più.',
      passo: 1,
      chiudi: true,
      figli: [
        Row(
          children: [
            Expanded(child: tassello(TipoLavoro.doppiaggio)),
            const SizedBox(width: 12),
            Expanded(child: tassello(TipoLavoro.codice)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: tassello(TipoLavoro.claude)),
            const SizedBox(width: 12),
            Expanded(child: tassello(TipoLavoro.aGiornata)),
          ],
        ),
        const SizedBox(height: 12),
        tassello(TipoLavoro.altro, largo: true),
      ],
    );
  }
}

class _Testi extends StatelessWidget {
  const _Testi({required this.t, required this.sotto, required this.tema});

  final TipoLavoro t;
  final String sotto;
  final TextTheme tema;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.etichetta, style: tema.titleLarge),
        Text(
          sotto,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tema.labelMedium?.copyWith(
            fontSize: 14,
            color: ColoriLaguna.testoSecondario,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
