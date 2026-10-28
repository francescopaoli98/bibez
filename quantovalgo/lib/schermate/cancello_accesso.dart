import 'dart:async';

import 'package:flutter/material.dart';

import '../servizi/servizi_app.dart';
import '../servizi/utente.dart';
import '../widget/logo_sole.dart';
import '../widget/sfondo_laguna.dart';
import 'guscio.dart';
import 'login.dart';

/// Decide cosa mostrare: attesa, login oppure l'app vera.
/// Quando un utente compare, crea/aggiorna il suo profilo nel cloud.
class CancelloAccesso extends StatefulWidget {
  const CancelloAccesso({super.key});

  @override
  State<CancelloAccesso> createState() => _CancelloAccessoState();
}

class _CancelloAccessoState extends State<CancelloAccesso> {
  StreamSubscription<Utente?>? _ascolto;
  bool _pronto = false; // vero dopo la prima risposta (utente oppure nessuno)
  Utente? _utente;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ascolto != null) return; // parte una volta sola
    final servizi = ServiziApp.di(context);
    _ascolto = servizi.accesso.utente.listen((utente) {
      if (utente != null && utente.uid != _utente?.uid) {
        servizi.archivio.assicuraProfilo(utente);
      }
      if (mounted) {
        setState(() {
          _utente = utente;
          _pronto = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _ascolto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_pronto) return const _Attesa();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _utente == null
          ? const LoginPagina(key: ValueKey('login'))
          : const Guscio(key: ValueKey('app')),
    );
  }
}

/// Schermata brevissima mostrata mentre si legge l'utente salvato.
class _Attesa extends StatelessWidget {
  const _Attesa();

  @override
  Widget build(BuildContext context) {
    return const SfondoLaguna(
      child: Scaffold(body: Center(child: LogoSole(dimensione: 88))),
    );
  }
}
