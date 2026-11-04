import 'package:flutter/material.dart';

import '../logica/preventivo.dart';
import '../modelli/preventivo.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/campo_testo.dart';
import '../widget/passo_guidato.dart';
import '../widget/pulsante_scelta.dart';
import '../widget/sfera_lucida.dart';
import 'preventivo_anteprima.dart';

/// Le domande a scelta rapida per costruire il preventivo di un lavoro:
/// cosa fai, come lavori, in quanto tempo, cosa ci guadagna il cliente.
/// Il testo lo compone l'app da modelli (gratis, senza internet).
class PreventivoDomande extends StatefulWidget {
  const PreventivoDomande({super.key, required this.lavoroId, this.esistente});

  final String lavoroId;

  /// Per rivedere un preventivo già fatto: si parte dalle sue risposte.
  final Preventivo? esistente;

  @override
  State<PreventivoDomande> createState() => _PreventivoDomandeState();
}

class _PreventivoDomandeState extends State<PreventivoDomande> {
  final _progetto = TextEditingController();
  final _consegna = TextEditingController();
  final _nuovaFase = TextEditingController();
  final _nuovoBenefit = TextEditingController();

  /// Tutte le voci tra cui scegliere (quelle pronte più quelle aggiunte) e
  /// quali sono toccate.
  List<String> _fasi = [];
  final _fasiScelte = <String>{};
  List<String> _benefit = [];
  final _benefitScelti = <String>{};
  bool _iniziato = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniziato) return;
    _iniziato = true;
    final dati = DatiScope.leggi(context);
    final lavoro = dati.lavoro(widget.lavoroId);
    final tipo = lavoro?.tipo;
    final pronteFasi = tipo == null ? <String>[] : fasiDi(tipo);
    final pronteBenefit = tipo == null ? <String>[] : benefitDi(tipo);
    final e = widget.esistente;

    if (e == null) {
      _progetto.text = lavoro?.nome ?? '';
      _consegna.text = '1 settimana';
      _fasi = [...pronteFasi];
      _fasiScelte.addAll(pronteFasi); // di partenza sono tutte scelte
      _benefit = [...pronteBenefit];
      _benefitScelti.addAll(pronteBenefit.take(2));
    } else {
      _progetto.text = e.progetto;
      _consegna.text = e.consegna;
      // Le voci già usate restano, anche se aggiunte a mano
      _fasi = [
        ...pronteFasi,
        for (final f in e.fasi)
          if (!pronteFasi.contains(f)) f,
      ];
      _fasiScelte.addAll(e.fasi);
      _benefit = [
        ...pronteBenefit,
        for (final b in e.benefit)
          if (!pronteBenefit.contains(b)) b,
      ];
      _benefitScelti.addAll(e.benefit);
    }
  }

  @override
  void dispose() {
    _progetto.dispose();
    _consegna.dispose();
    _nuovaFase.dispose();
    _nuovoBenefit.dispose();
    super.dispose();
  }

  void _aggiungi(
    TextEditingController campo,
    List<String> voci,
    Set<String> scelte,
  ) {
    final testo = campo.text.trim();
    if (testo.isEmpty) return;
    setState(() {
      if (!voci.contains(testo)) voci.add(testo);
      scelte.add(testo);
      campo.clear();
    });
  }

  void _avanti() {
    final dati = DatiScope.leggi(context);
    final lavoro = dati.lavoro(widget.lavoroId);
    if (lavoro == null) return;
    final bozza = Preventivo(
      id: widget.esistente?.id ?? '',
      lavoroId: lavoro.id,
      cliente: dati.cliente(lavoro.clienteId)?.nome,
      progetto: _progetto.text.trim().isEmpty
          ? lavoro.nome
          : _progetto.text.trim(),
      // Nell'ordine in cui sono mostrate, non in quello dei tocchi
      fasi: [
        for (final f in _fasi)
          if (_fasiScelte.contains(f)) f,
      ],
      consegna: _consegna.text.trim(),
      benefit: [
        for (final b in _benefit)
          if (_benefitScelti.contains(b)) b,
      ],
      stile: widget.esistente?.stile ?? StilePreventivo.app,
      // Il prezzo che chiedi adesso per questo lavoro
      prezzoPieno: lavoro.prezzoPieno,
      prezzoFinale: lavoro.prezzoFinale > 0
          ? lavoro.prezzoFinale
          : dati.importoDi(lavoro),
      creatoIl: widget.esistente?.creatoIl ?? dati.adesso(),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PreventivoAnteprima(bozza: bozza),
      ),
    );
  }

  Widget _titolo(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(t, style: Theme.of(context).textTheme.titleLarge),
    ),
  );

  Widget _scelte({
    required List<String> voci,
    required Set<String> scelte,
    required String prefisso,
  }) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in voci)
        PulsanteScelta(
          key: Key('$prefisso-$v'),
          etichetta: v,
          selezionato: scelte.contains(v),
          onTap: () => setState(
            () => scelte.contains(v) ? scelte.remove(v) : scelte.add(v),
          ),
        ),
    ],
  );

  Widget _aggiungiVoce({
    required TextEditingController campo,
    required String etichetta,
    required String nomeAzione,
    required Key chiaveCampo,
    required VoidCallback onAggiungi,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: CampoTesto(
          key: chiaveCampo,
          controller: campo,
          etichetta: etichetta,
          azioneTastiera: TextInputAction.done,
        ),
      ),
      const SizedBox(width: 10),
      Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: SferaLucida(
          icona: Icons.add_rounded,
          etichetta: nomeAzione,
          onPressed: onAggiungi,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return PassoGuidato(
      titolo: 'Cosa scrivo?',
      sottotitolo: 'Tocca quello che vale per te: il testo lo preparo io.',
      azione: 'Vedi il preventivo',
      onAzione: _avanti,
      figli: [
        _titolo('Il progetto'),
        CampoTesto(
          key: const Key('campo-progetto'),
          controller: _progetto,
          etichetta: 'Cosa fai, in poche parole',
          azioneTastiera: TextInputAction.next,
        ),
        _titolo('Come lavori'),
        _scelte(voci: _fasi, scelte: _fasiScelte, prefisso: 'fase'),
        const SizedBox(height: 10),
        _aggiungiVoce(
          campo: _nuovaFase,
          etichetta: 'Un\'altra fase',
          nomeAzione: 'Aggiungi fase',
          chiaveCampo: const Key('campo-nuova-fase'),
          onAggiungi: () => _aggiungi(_nuovaFase, _fasi, _fasiScelte),
        ),
        _titolo('Consegni in'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in consegnePreset)
              PulsanteScelta(
                key: Key('consegna-$c'),
                etichetta: c,
                selezionato: _consegna.text.trim() == c,
                onTap: () => setState(() => _consegna.text = c),
              ),
          ],
        ),
        const SizedBox(height: 10),
        CampoTesto(
          key: const Key('campo-consegna'),
          controller: _consegna,
          etichetta: 'Oppure scrivi tu',
          onChanged: (_) => setState(() {}),
          azioneTastiera: TextInputAction.done,
        ),
        _titolo('Cosa ci guadagna il cliente'),
        _scelte(voci: _benefit, scelte: _benefitScelti, prefisso: 'benefit'),
        const SizedBox(height: 10),
        _aggiungiVoce(
          campo: _nuovoBenefit,
          etichetta: 'Un altro vantaggio',
          nomeAzione: 'Aggiungi vantaggio',
          chiaveCampo: const Key('campo-nuovo-benefit'),
          onAggiungi: () => _aggiungi(_nuovoBenefit, _benefit, _benefitScelti),
        ),
        const SizedBox(height: 8),
        Text(
          'Poi scegli lo stile e salvi l\'immagine.',
          style: tema.bodyMedium?.copyWith(color: ColoriLaguna.testoSecondario),
        ),
      ],
    );
  }
}
