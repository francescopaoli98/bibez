import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/prezzi_web.dart';
import '../modelli/tipi.dart';
import '../servizi/ricerca_prezzi.dart';
import '../servizi/servizi_app.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/stile_lucido.dart';
import 'foglio_forbice.dart';
import 'impostazioni.dart';

/// Cerca sul web il prezzo di mercato di [tipo] e mostra cosa ha trovato.
/// [inCorso] avvisa la pagina quando la ricerca parte e quando finisce
/// (per far girare il pulsante). Non salva nulla senza il tuo "Usa questa".
Future<void> cercaPrezziWeb(
  BuildContext context,
  TipoLavoro tipo, {
  required ValueChanged<bool> inCorso,
  String? domanda,
}) async {
  final dati = DatiScope.leggi(context);
  final ricerca = ServiziApp.di(context).ricerca;
  if (ricerca == null) return;

  if (dati.impostazioni.chiaveTavily.isEmpty) {
    await mostraFoglio<void>(
      context,
      titolo: 'Serve la chiave di Tavily',
      costruttore: (_) => const _Messaggio(
        testo:
            'Per cercare i prezzi sul web serve una chiave gratuita di Tavily '
            '(tavily.com, 1.000 ricerche al mese). Creala e incollala in '
            'Impostazioni → Ricerca prezzi.',
        vaiInImpostazioni: true,
      ),
    );
    return;
  }
  if (!dati.puoCercare) {
    await mostraFoglio<void>(
      context,
      titolo: 'Limite del mese raggiunto',
      costruttore: (_) => const _Messaggio(
        testo:
            'Hai fatto ${StatoDati.limiteRicercheMese} ricerche questo mese: '
            'è il freno di sicurezza di QuantoValgo per non finire i crediti. '
            'Torna il mese prossimo, o scrivi la forbice a mano.',
      ),
    );
    return;
  }

  inCorso(true);
  final RisultatoRicerca esito;
  try {
    esito = await ricerca.cerca(
      tipo,
      chiave: dati.impostazioni.chiaveTavily,
      domanda: domanda,
    );
  } finally {
    inCorso(false);
  }
  // Se la ricerca ha toccato Tavily, il credito è speso: si conta
  if (esito.consumaCredito) dati.registraRicerca();
  if (!context.mounted) return;

  switch (esito) {
    case RicercaTrovata(:final trovata):
      await mostraFoglio<void>(
        context,
        titolo: 'Prezzi trovati · ${tipo.etichetta}',
        costruttore: (_) => _Trovata(tipo: tipo, trovata: trovata),
      );
    case RicercaNonAffidabile():
      final scrivi = await mostraFoglio<bool>(
        context,
        titolo: 'Numeri non affidabili',
        costruttore: (_) => const _Messaggio(
          testo:
              'Ho cercato, ma i prezzi trovati sono pochi o troppo diversi '
              'tra loro per fidarmi. Meglio scrivere la forbice a mano.',
          pulsanteScrivi: true,
        ),
      );
      if (scrivi == true && context.mounted) {
        await modificaForbice(context, tipo);
      }
    case RicercaFallita(:final messaggio, :final serveChiave):
      await mostraFoglio<void>(
        context,
        titolo: 'Ricerca non riuscita',
        costruttore: (_) =>
            _Messaggio(testo: messaggio, vaiInImpostazioni: serveChiave),
      );
  }
}

/// Testo semplice con, se serve, la scorciatoia verso Impostazioni o la forbice a mano.
class _Messaggio extends StatelessWidget {
  const _Messaggio({
    required this.testo,
    this.vaiInImpostazioni = false,
    this.pulsanteScrivi = false,
  });

  final String testo;
  final bool vaiInImpostazioni;
  final bool pulsanteScrivi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(testo, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        if (vaiInImpostazioni)
          PulsanteLucido(
            etichetta: 'Vai a Impostazioni',
            icona: Icons.settings_rounded,
            onPressed: () {
              final navigatore = Navigator.of(context);
              navigatore.pop();
              navigatore.push(
                MaterialPageRoute<void>(
                  builder: (_) => const ImpostazioniPagina(),
                ),
              );
            },
          )
        else if (pulsanteScrivi)
          PulsanteLucido(
            etichetta: 'Scrivi la forbice',
            icona: Icons.edit_rounded,
            onPressed: () => Navigator.of(context).pop(true),
          )
        else
          PulsanteLucido(
            etichetta: 'Ok',
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }
}

/// Forbice trovata: si salva solo se scegli "Usa questa forbice".
class _Trovata extends StatelessWidget {
  const _Trovata({required this.tipo, required this.trovata});

  final TipoLavoro tipo;
  final ForbiceTrovata trovata;

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.leggi(context);
    final tema = Theme.of(context).textTheme;
    final attuale = dati.mercatoPer(tipo);
    final siti = trovata.fonti.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          euroForbice(trovata.forbice.minimo, trovata.forbice.massimo),
          key: const Key('forbice-trovata'),
          style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Da $siti ${siti == 1 ? 'sito' : 'siti'} (${trovata.importi} prezzi): '
          '${trovata.fonti.join(', ')}',
          style: tema.bodyMedium?.copyWith(color: ColoriLaguna.testoSecondario),
        ),
        if (trovata.domanda.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Cercato: «${trovata.domanda}»',
            key: const Key('domanda-cercata'),
            style: tema.bodyMedium,
          ),
        ],
        if (attuale != null) ...[
          const SizedBox(height: 6),
          Text(
            attuale.manuale
                ? 'Sostituisce la forbice scritta a mano '
                      '(${euroForbice(attuale.minimo, attuale.massimo)}).'
                : 'Sostituisce quella trovata in precedenza '
                      '(${euroForbice(attuale.minimo, attuale.massimo)}).',
            style: tema.bodyMedium,
          ),
        ],
        const SizedBox(height: 16),
        PulsanteLucido(
          etichetta: 'Usa questa forbice',
          icona: Icons.check_rounded,
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: () {
            dati.salvaForbiceDaRicerca(tipo, trovata);
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Non usarla'),
        ),
      ],
    );
  }
}
