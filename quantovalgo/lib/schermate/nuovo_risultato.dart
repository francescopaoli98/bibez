import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logica/formato.dart';
import '../logica/prezzo_da_ore.dart';
import '../modelli/lavoro.dart';
import '../modelli/sottoprogetto.dart';
import '../modelli/tipi.dart';
import '../servizi/stato_dati.dart';
import '../tema/colori.dart';
import '../widget/campo_testo.dart';
import '../widget/carta_vetro.dart';
import '../widget/hero_laguna.dart';
import '../widget/passo_guidato.dart';
import '../widget/pillola_lucida.dart';
import '../widget/pulsante_lucido.dart';
import '../widget/stile_lucido.dart';
import 'bozza_lavoro.dart';
import 'foglio_numero.dart';
import 'lavoro.dart';

/// Ultimo passo di "Nuovo lavoro": quanto chiedere. Una cifra enorme, quattro
/// righe di conto e un solo pulsante per creare il lavoro.
class PassoRisultato extends StatefulWidget {
  const PassoRisultato({super.key, required this.bozza});

  final BozzaLavoro bozza;

  @override
  State<PassoRisultato> createState() => _PassoRisultatoState();
}

class _PassoRisultatoState extends State<PassoRisultato> {
  final _nome = TextEditingController();

  /// Cifra scelta da te con "Cambia la cifra"; vuota = quella consigliata.
  double? _prezzo;
  bool _iniziato = false;
  bool _creato = false; // evita doppio tocco

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniziato) return;
    _iniziato = true;
    final dati = DatiScope.leggi(context);
    final b = widget.bozza;
    final base = b.tipo == TipoLavoro.altro ? 'Lavoro' : b.tipo.etichetta;
    final cliente = dati.cliente(b.clienteId)?.nome;
    _nome.text = cliente == null ? base : '$base per $cliente';
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  PrezzoDaOre _calcolo(StatoDati dati) {
    final b = widget.bozza;
    return PrezzoDaOre(
      minuti: b.minuti,
      tariffaOraria: dati.impostazioni.tariffaOraria,
      scontoPercento: dati.parametri.sconto(b.relazione),
      km: b.conTrasferta ? b.km : 0,
      rimborsoKm: dati.impostazioni.rimborsoKm,
    );
  }

  Future<void> _cambiaCifra(double attuale) async {
    final nuova = await chiediNumero(
      context,
      titolo: 'Quanto chiedi',
      etichetta: 'La cifra che vuoi chiedere (€)',
      iniziale: attuale,
      massimo: 1000000,
    );
    if (nuova != null) setState(() => _prezzo = nuova);
  }

  /// Salva il lavoro con un'unica parte "Lavoro intero" (ore e trasferta
  /// già dentro) e apre la sua pagina.
  void _crea() {
    if (_creato) return;
    _creato = true;
    final dati = DatiScope.leggi(context);
    final b = widget.bozza;
    final calcolo = _calcolo(dati);
    final prezzo = _prezzo ?? calcolo.consigliato;
    final ora = dati.adesso();
    final nome = _nome.text.trim().isEmpty ? 'Lavoro' : _nome.text.trim();

    final id = dati.salvaLavoro(
      Lavoro(
        id: '',
        nome: nome,
        tipo: b.tipo,
        clienteId: b.clienteId,
        categoriaId: dati.categoriaPredefinita(b.tipo)?.id,
        relazione: b.relazione,
        livello: 3,
        // Il prezzo senza sconto: serve a contare quanto regali
        prezzoPieno: math.max(calcolo.prezzoPieno.roundToDouble(), prezzo),
        prezzoFinale: prezzo,
        creatoIl: ora,
      ),
    );
    dati.salvaSottoprogetto(
      Sottoprogetto(
        id: '',
        lavoroId: id,
        nome: 'Lavoro intero',
        ricavo: prezzo,
        // La trasferta è una spesa vera: non è guadagno
        costiDiretti: calcolo.trasferta,
        ore: calcolo.ore,
        creatoIl: ora,
      ),
    );

    // Si lascia il percorso: Indietro dalla pagina del lavoro torna alla Home
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LavoroPagina(lavoroId: id)),
      (r) => r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dati = DatiScope.di(context);
    final tema = Theme.of(context).textTheme;
    final b = widget.bozza;
    final calcolo = _calcolo(dati);
    final prezzo = _prezzo ?? calcolo.consigliato;
    final righe = calcolo.righe(prezzo);
    final resta = calcolo.restaAllOra(prezzo);
    final cliente = dati.cliente(b.clienteId)?.nome;
    final sconto = dati.parametri.sconto(b.relazione);
    final tariffa = euro(dati.impostazioni.tariffaOraria);

    Widget riga(String nome, String? sotto, String valore, {Color? colore}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: tema.titleMedium),
                    if (sotto != null)
                      Text(
                        sotto,
                        style: tema.labelMedium?.copyWith(
                          fontSize: 14,
                          color: ColoriLaguna.testoSecondario,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                valore,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: colore,
                ),
              ),
            ],
          ),
        );

    final righeConto = <Widget>[
      riga(
        'Il tuo tempo',
        '${durata(b.minuti)} × $tariffa l\'ora',
        euro(righe.tempo),
      ),
      if (sconto > 0)
        riga(
          'Sconto ${b.relazione.breve.toLowerCase()}',
          '$sconto% sul tuo tempo',
          euro(-righe.sconto),
          colore: ColoriLaguna.negativo,
        ),
      if (b.conTrasferta && b.km > 0)
        riga(
          'Trasferta',
          '${numeroPerCampo(b.km)} km, senza sconto',
          euro(righe.trasferta, conSegno: true),
          colore: ColoriLaguna.positivo,
        ),
      if (righe.arrotondamento != 0)
        riga(
          _prezzo == null ? 'Arrotondo' : 'Cifra scelta da te',
          null,
          euro(righe.arrotondamento, conSegno: true),
          colore: righe.arrotondamento < 0
              ? ColoriLaguna.negativo
              : ColoriLaguna.positivo,
        ),
    ];

    return PassoGuidato(
      titolo: 'Il prezzo giusto',
      passo: null,
      azione: 'Va bene, crea il lavoro',
      onAzione: _crea,
      figli: [
        HeroLaguna(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  cliente == null ? 'Chiedi' : 'Per $cliente chiedi',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColoriLaguna.testoChiaro,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    euro(prezzo),
                    key: const Key('prezzo-giusto'),
                    style: const TextStyle(
                      fontSize: 96,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -3,
                      color: ColoriLaguna.cifraHero,
                    ),
                  ),
                ),
                if (resta != null && resta > 0)
                  PillolaLucida(
                    testo:
                        'A te restano circa ${euro(resta.roundToDouble())} all\'ora',
                    stile: StileLucido.blu,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        CartaVetro(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < righeConto.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                righeConto[i],
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        PulsanteLucido(
          key: const Key('cambia-cifra'),
          etichetta: 'Cambia la cifra',
          icona: Icons.edit_rounded,
          onPressed: () => _cambiaCifra(prezzo),
        ),
        const SizedBox(height: 14),
        CampoTesto(
          key: const Key('campo-nome'),
          controller: _nome,
          etichetta: 'Come lo chiami?',
          azioneTastiera: TextInputAction.done,
        ),
      ],
    );
  }
}
