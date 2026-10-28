import 'package:flutter/material.dart';

import '../modelli/categoria.dart';
import '../modelli/tipi.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../tema/palette_categorie.dart';
import '../widget/campo_testo.dart';
import '../widget/carta_vetro.dart';
import '../widget/chip_categoria.dart';
import '../widget/effetto_morbido.dart';
import '../widget/foglio_laguna.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/pulsante_scelta.dart';
import '../widget/stile_lucido.dart';

/// Foglio per creare o modificare una categoria.
/// Restituisce l'id della categoria salvata (null se chiuso senza salvare).
Future<String?> modificaCategoria(
  BuildContext context, {
  Categoria? esistente,
}) {
  return mostraFoglio<String>(
    context,
    titolo: esistente == null ? 'Nuova categoria' : 'Modifica categoria',
    costruttore: (_) => _FormCategoria(esistente: esistente),
  );
}

/// Foglio con l'elenco delle categorie: da qui si creano e si modificano.
Future<void> gestisciCategorie(BuildContext context) {
  return mostraFoglio<void>(
    context,
    titolo: 'Categorie dei costi',
    costruttore: (_) => const _ElencoCategorie(),
  );
}

/// Categorie proposte con un tocco: nome e posizione del colore.
const _categorieDiPartenza = [
  ('Doppiaggio', 6, TipoLavoro.doppiaggio), // rosso, come il microfono
  ('Codice', 1, TipoLavoro.codice), // blu
  ('Claude', 8, TipoLavoro.claude), // viola
];

/// "2 costi · 1 progetto": quanto è usata una categoria.
String descriviUsoCategoria(int costi, int progetti) =>
    '$costi ${costi == 1 ? 'costo' : 'costi'} · '
    '$progetti ${progetti == 1 ? 'progetto' : 'progetti'}';

class _FormCategoria extends StatefulWidget {
  const _FormCategoria({this.esistente});

  final Categoria? esistente;

  @override
  State<_FormCategoria> createState() => _FormCategoriaState();
}

class _FormCategoriaState extends State<_FormCategoria> {
  late final _nome = TextEditingController(text: widget.esistente?.nome);
  late int _colore = widget.esistente?.colore ?? 0;
  late TipoLavoro? _tipoLavoro = widget.esistente?.tipoLavoro;
  String? _erroreNome;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _salva() {
    final nome = _nome.text.trim();
    final dati = DatiScope.leggi(context);
    final omonima = dati.categorie
        .where((c) => c.nome.trim().toLowerCase() == nome.toLowerCase())
        .firstOrNull;
    final errore = nome.isEmpty
        ? 'Scrivi il nome'
        : (omonima != null && omonima.id != widget.esistente?.id
              ? 'Esiste già una categoria con questo nome'
              : null);
    setState(() => _erroreNome = errore);
    if (errore != null) return;

    final vecchia = widget.esistente;
    final id = dati.salvaCategoria(
      Categoria(
        id: vecchia?.id ?? '',
        nome: nome,
        colore: _colore,
        tipoLavoro: _tipoLavoro,
        creatoIl: vecchia?.creatoIl ?? DateTime.now(),
      ),
    );
    Navigator.of(context).pop(id);
  }

  Future<void> _elimina() async {
    final navigatore = Navigator.of(context);
    final dati = DatiScope.leggi(context);
    final conferma = await chiediConferma(
      context,
      titolo: 'Eliminare la categoria?',
      testo: 'I costi che la usano restano, ma senza categoria.',
      etichettaConferma: 'Elimina',
    );
    if (!conferma) return;
    dati.eliminaCategoria(widget.esistente!.id);
    navigatore.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTesto(
          key: const Key('campo-nome-categoria'),
          controller: _nome,
          etichetta: 'Nome',
          suggerimento: 'Es. Doppiaggio',
          errore: _erroreNome,
          maiuscole: TextCapitalization.words,
          azioneTastiera: TextInputAction.done,
        ),
        const SizedBox(height: 14),
        const Text(
          'Colore',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < paletteCategorie.length; i++)
              _Campione(
                nome: paletteCategorie[i].nome,
                colore: paletteCategorie[i].colore,
                selezionato: i == _colore,
                onTap: () => setState(() => _colore = i),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Progetti che ne fanno parte da soli',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PulsanteScelta(
              etichetta: 'Nessuno',
              selezionato: _tipoLavoro == null,
              onTap: () => setState(() => _tipoLavoro = null),
            ),
            // I lavori "A giornata" hanno un guadagno netto fisso: non portano costi
            for (final t in TipoLavoro.values)
              if (t != TipoLavoro.aGiornata)
                PulsanteScelta(
                  etichetta: t.etichetta,
                  selezionato: _tipoLavoro == t,
                  onTap: () => setState(() => _tipoLavoro = t),
                ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _tipoLavoro == null
              ? 'La categoria si sceglie progetto per progetto.'
              : 'I progetti ${_tipoLavoro!.etichetta} ne fanno parte, se non scegli un\'altra categoria. '
                    'I costi di questa categoria si recuperano solo con i suoi progetti.',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: ColoriLaguna.testoSecondario),
        ),
        const SizedBox(height: 16),
        PulsanteLucido(
          etichetta: 'Salva',
          stile: StileLucido.verde,
          altezza: 56,
          onPressed: _salva,
        ),
        if (widget.esistente != null) ...[
          const SizedBox(height: 10),
          PulsanteLucido(
            etichetta: 'Elimina',
            icona: Icons.delete_outline_rounded,
            stile: StileLucido.rosso,
            onPressed: _elimina,
          ),
        ],
      ],
    );
  }
}

/// Un colore della tavolozza da toccare (area di 48 px, con nome per i lettori).
class _Campione extends StatelessWidget {
  const _Campione({
    required this.nome,
    required this.colore,
    required this.selezionato,
    required this.onTap,
  });

  final String nome;
  final Color colore;
  final bool selezionato;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selezionato,
      label: nome,
      excludeSemantics: true,
      child: EffettoMorbido(
        scalaPremuto: 0.88,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: selezionato ? 44 : 38,
                height: selezionato ? 44 : 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(colore, Colors.white, 0.4)!, colore],
                  ),
                  border: Border.all(
                    color: selezionato ? ColoriLaguna.testo : Colors.white,
                    width: selezionato ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colore.withValues(alpha: 0.45),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: selezionato
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 22,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ElencoCategorie extends StatelessWidget {
  const _ElencoCategorie();

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dati.categorie.isEmpty) ...[
          Text(
            'Le categorie servono a riconoscere i costi a colpo d\'occhio '
            '(es. il microfono è "Doppiaggio").',
            style: tema.bodyMedium?.copyWith(
              color: ColoriLaguna.testoSecondario,
            ),
          ),
          const SizedBox(height: 12),
          PulsanteLucido(
            etichetta: 'Aggiungi quelle di partenza',
            icona: Icons.auto_awesome_rounded,
            stile: StileLucido.oro,
            onPressed: () {
              final adesso = DateTime.now();
              for (final (nome, colore, tipo) in _categorieDiPartenza) {
                dati.salvaCategoria(
                  Categoria(
                    id: '',
                    nome: nome,
                    colore: colore,
                    tipoLavoro: tipo,
                    creatoIl: adesso,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
        ] else
          for (final c in dati.categorie) ...[
            CartaVetro(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              onTap: () => modificaCategoria(context, esistente: c),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: coloreDellaPalette(c.colore).colore,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.nome, style: tema.titleMedium),
                          Text(
                            '${coloreDellaPalette(c.colore).nome} · ${descriviUsoCategoria(dati.costiDellaCategoria(c.id), dati.lavoriDellaCategoria(c.id))}',
                            style: tema.labelMedium?.copyWith(
                              color: ColoriLaguna.testoSecondario,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit_rounded,
                    color: ColoriLaguna.testoSecondario,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        PulsanteLucido(
          etichetta: '+ Nuova categoria',
          onPressed: () => modificaCategoria(context),
        ),
      ],
    );
  }
}

/// Scelta della categoria dentro il modulo di un costo.
/// "Nessuna" e le categorie esistenti, più "+ Nuova" per crearne una al volo.
class SelettoreCategoria extends StatelessWidget {
  const SelettoreCategoria({
    super.key,
    required this.scelta,
    required this.onCambia,
    this.etichetta = 'Categoria',
  });

  final String? scelta;
  final ValueChanged<String?> onCambia;

  /// Titolo sopra le pillole (es. "Categoria dei costi" per un progetto).
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etichetta,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChipCategoria(
              etichetta: 'Nessuna',
              colore: null,
              selezionata: scelta == null,
              onTap: () => onCambia(null),
            ),
            for (final c in dati.categorie)
              ChipCategoria(
                etichetta: c.nome,
                colore: coloreDellaPalette(c.colore).colore,
                selezionata: c.id == scelta,
                onTap: () => onCambia(c.id),
              ),
            ActionChipNuova(
              onTap: () async {
                final id = await modificaCategoria(context);
                if (id != null) onCambia(id); // la nuova si sceglie da sola
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Pillola "+ Nuova" accanto alle categorie.
class ActionChipNuova extends StatelessWidget {
  const ActionChipNuova({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChipCategoria(
      etichetta: '+ Nuova',
      colore: null,
      selezionata: false,
      onTap: onTap,
    );
  }
}
