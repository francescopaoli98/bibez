import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../logica/formato.dart';
import '../logica/preventivo.dart';
import '../modelli/preventivo.dart';
import '../servizi/servizi_app.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/foglio_preventivo.dart';
import '../widget/pagina_secondaria.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/pulsante_scelta.dart';
import '../widget/stile_lucido.dart';
import 'preventivo_domande.dart';

/// Come si trasforma il foglio in un'immagine PNG (3×, cioè 1080 pixel di
/// larghezza). Sostituibile nei test, dove l'immagine vera non si può fare.
@visibleForTesting
Future<Uint8List> Function(RenderRepaintBoundary foglio) catturaPng =
    _catturaVera;

Future<Uint8List> _catturaVera(RenderRepaintBoundary foglio) async {
  final immagine = await foglio.toImage(pixelRatio: 3);
  final dati = await immagine.toByteData(format: ui.ImageByteFormat.png);
  if (dati == null) throw StateError('Immagine non creata');
  return dati.buffer.asUint8List();
}

/// L'anteprima del preventivo: si sceglie lo stile e si salva come immagine
/// PNG o si condivide.
class PreventivoAnteprima extends StatefulWidget {
  const PreventivoAnteprima({super.key, required this.bozza});

  final Preventivo bozza;

  @override
  State<PreventivoAnteprima> createState() => _PreventivoAnteprimaState();
}

class _PreventivoAnteprimaState extends State<PreventivoAnteprima> {
  final _chiaveFoglio = GlobalKey();
  late StilePreventivo _stile = widget.bozza.stile;

  /// Dopo il primo salvataggio il preventivo ha un id: salvando ancora si
  /// aggiorna lo stesso, senza farne un doppione.
  late String? _idSalvato = widget.bozza.id.isEmpty ? null : widget.bozza.id;
  bool _inCorso = false;

  Preventivo get _attuale =>
      widget.bozza.copyWith(id: _idSalvato ?? '', stile: _stile);

  /// Un nome di file semplice: `preventivo-sito-vetrina-2026-11-04`.
  String _nomeFile(String titolo, DateTime data) {
    final pulito = titolo
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final giorno =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
    return 'preventivo-${pulito.isEmpty ? 'lavoro' : pulito}-$giorno';
  }

  void _messaggio(String testo) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(testo)));
  }

  Future<void> _esporta({required bool salva, required String titolo}) async {
    final servizio = ServiziApp.di(context).esportazione;
    final dati = DatiScope.leggi(context);
    final contesto = _chiaveFoglio.currentContext;
    if (servizio == null || contesto == null || _inCorso) return;
    final foglio = contesto.findRenderObject() as RenderRepaintBoundary;
    final nome = _nomeFile(titolo, dati.adesso());

    setState(() => _inCorso = true);
    try {
      final png = await catturaPng(foglio);
      if (salva) {
        final fatto = await servizio.salvaInGalleria(png, nome);
        if (!fatto) {
          if (mounted) {
            _messaggio(
              'Non sono riuscito a salvarlo: controlla che l\'app possa '
              'salvare le foto.',
            );
          }
          return;
        }
        if (mounted) _messaggio('Salvato nella galleria');
      } else {
        await servizio.condividi(
          png,
          nome,
          testo: 'Preventivo «$titolo»: ${euro(widget.bozza.prezzoFinale)}',
        );
      }
      // Salvato o condiviso: il preventivo entra nell'elenco
      _idSalvato = dati.salvaPreventivo(_attuale);
    } catch (e) {
      if (mounted) _messaggio('Qualcosa non ha funzionato: riprova.');
    } finally {
      if (mounted) setState(() => _inCorso = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final b = widget.bozza;
    final titolo = dati.lavoro(b.lavoroId)?.nome ?? b.progetto;
    final tema = Theme.of(context).textTheme;
    final puoEsportare = ServiziApp.di(context).esportazione != null;

    final foglio = DatiFoglio(
      titolo: titolo,
      cliente: b.cliente,
      testi: componiTesti(
        progetto: b.progetto,
        cliente: b.cliente,
        fasi: b.fasi,
        consegna: b.consegna,
        benefit: b.benefit,
      ),
      conto: contoPrezzo(
        prezzoPieno: b.prezzoPieno,
        prezzoFinale: b.prezzoFinale,
      ),
      data: _idSalvato == null ? dati.adesso() : b.creatoIl,
    );

    return PaginaSecondaria(
      titolo: 'Il preventivo',
      sottotitolo: 'Scegli lo stile, poi salvalo o mandalo.',
      figli: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in StilePreventivo.values)
              PulsanteScelta(
                key: Key('stile-${s.name}'),
                etichetta: s.etichetta,
                selezionato: s == _stile,
                onTap: () => setState(() => _stile = s),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Il foglio sta in una scatola da 360 punti; sugli schermi stretti si
        // rimpicciolisce a video, ma l'immagine esce sempre a 1080 pixel
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: RepaintBoundary(
              key: _chiaveFoglio,
              child: FoglioPreventivo(stile: _stile, dati: foglio),
            ),
          ),
        ),
        const SizedBox(height: 20),
        PulsanteLucido(
          etichetta: _inCorso ? 'Un attimo…' : 'Salva PNG',
          icona: Icons.download_rounded,
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: puoEsportare && !_inCorso
              ? () => _esporta(salva: true, titolo: titolo)
              : null,
        ),
        const SizedBox(height: 10),
        PulsanteLucido(
          etichetta: 'Condividi',
          icona: Icons.share_rounded,
          onPressed: puoEsportare && !_inCorso
              ? () => _esporta(salva: false, titolo: titolo)
              : null,
        ),
        const SizedBox(height: 10),
        // Il miglioramento con l'AI parte solo su tuo comando e per ora è spento
        const PulsanteLucido(
          etichetta: 'Migliora il testo con l\'AI',
          icona: Icons.auto_awesome_rounded,
          stile: StileLucido.oro,
          onPressed: null,
        ),
        const SizedBox(height: 6),
        Text(
          'Arriverà più avanti. Non parte mai da solo: solo se lo premi.',
          style: tema.bodyMedium?.copyWith(color: ColoriLaguna.testoSecondario),
        ),
        const SizedBox(height: 10),
        Align(
          child: TextButton(
            key: const Key('cambia-risposte'),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => PreventivoDomande(
                  lavoroId: b.lavoroId,
                  esistente: _attuale,
                ),
              ),
            ),
            child: const Text('Cambia le risposte'),
          ),
        ),
      ],
    );
  }
}
