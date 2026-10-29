import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logica/formato.dart';
import '../logica/prezzi_web.dart';
import '../tema/colori.dart';

/// Come si apre davvero un indirizzo nel browser. Sostituibile nei test, dove il
/// plugin del telefono non c'è.
@visibleForTesting
Future<bool> Function(Uri indirizzo) lanciaUrl = (uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Apre un link nel browser. Solo indirizzi web (http/https). Se il telefono
/// non riesce, copia il link negli appunti. Dice se è riuscito ad aprirlo.
Future<bool> apriLink(String indirizzo) async {
  final uri = Uri.tryParse(indirizzo);
  if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
    try {
      if (await lanciaUrl(uri)) {
        return true;
      }
    } catch (_) {
      // si ripiega sulla copia del link
    }
  }
  await Clipboard.setData(ClipboardData(text: indirizzo));
  return false;
}

/// Una pagina web con i prezzi che vi sono scritti.
class _Pagina {
  _Pagina(this.sito, this.url, this.titolo);

  final String sito;
  final String url;
  final String titolo;
  final prezzi = <double>[];

  double get minimo => prezzi.reduce((a, b) => a < b ? a : b);
}

/// I prezzi di riferimento trovati sul web, una riga per pagina: sito, titolo,
/// prezzi trovati e link da toccare per controllare di persona.
class ListaPrezzi extends StatefulWidget {
  const ListaPrezzi({super.key, required this.prezzi, this.righeIniziali = 8});

  final List<PrezzoTrovato> prezzi;

  /// Quante pagine mostrare prima di "Mostra tutte".
  final int righeIniziali;

  @override
  State<ListaPrezzi> createState() => _ListaPrezziState();
}

class _ListaPrezziState extends State<ListaPrezzi> {
  bool _tutte = false;
  String? _avviso;

  /// Raggruppa per pagina (stesso link), dalla più economica.
  List<_Pagina> get _pagine {
    final perPagina = <String, _Pagina>{};
    for (final p in widget.prezzi) {
      final chiave = p.url.isEmpty ? p.sito : p.url;
      perPagina
          .putIfAbsent(chiave, () => _Pagina(p.sito, p.url, p.titolo))
          .prezzi
          .add(p.importo);
    }
    return perPagina.values.toList()
      ..sort((a, b) => a.minimo.compareTo(b.minimo));
  }

  Future<void> _apri(_Pagina pagina) async {
    final indirizzo = pagina.url.isEmpty
        ? 'https://${pagina.sito}'
        : pagina.url;
    final aperto = await apriLink(indirizzo);
    if (!mounted || aperto) return;
    setState(() => _avviso = 'Non riesco ad aprire il browser: link copiato.');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final pagine = _pagine;
    if (pagine.isEmpty) return const SizedBox.shrink();
    final visibili = _tutte
        ? pagine
        : pagine.take(widget.righeIniziali).toList();
    final nPrezzi = widget.prezzi.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Prezzi di riferimento · $nPrezzi ${nPrezzi == 1 ? 'prezzo' : 'prezzi'} '
            'da ${pagine.length} ${pagine.length == 1 ? 'pagina' : 'pagine'}',
            style: tema.titleMedium,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tocca una riga per aprire la pagina e controllare di persona.',
          style: tema.bodyMedium?.copyWith(color: ColoriLaguna.testoSecondario),
        ),
        const SizedBox(height: 8),
        for (final p in visibili)
          InkWell(
            key: Key('riferimento-${p.sito}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => _apri(p),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.sito,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F5C8C),
                          ),
                        ),
                        if (p.titolo.isNotEmpty)
                          Text(
                            p.titolo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: tema.bodyMedium?.copyWith(
                              color: ColoriLaguna.testoSecondario,
                            ),
                          ),
                        Text(
                          (p.prezzi..sort()).map(euro).join(' · '),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 8, top: 2),
                    child: Icon(
                      Icons.open_in_new_rounded,
                      size: 20,
                      color: Color(0xFF0F5C8C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!_tutte && pagine.length > widget.righeIniziali)
          TextButton(
            key: const Key('mostra-tutte-le-pagine'),
            onPressed: () => setState(() => _tutte = true),
            child: Text('Mostra tutte le ${pagine.length} pagine'),
          ),
        if (_avviso != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _avviso!,
              key: const Key('avviso-link'),
              style: tema.bodyMedium?.copyWith(
                color: ColoriLaguna.negativo,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
