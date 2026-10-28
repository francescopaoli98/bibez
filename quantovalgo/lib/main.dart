import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'servizi/accesso_firebase.dart';
import 'servizi/archivio_firestore.dart';
import 'servizi/promemoria_locali.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Barre di sistema trasparenti con icone scure: lo sfondo Laguna arriva ai bordi.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Avvio di Firebase: legge android/app/google-services.json.
  // Se fallisce l'app si apre lo stesso e spiega il problema.
  String? erroreAvvio;
  try {
    await Firebase.initializeApp();
    ArchivioFirestore.configura();
  } catch (e) {
    erroreAvvio = e.toString();
  }

  // Notifiche dei promemoria: se non partono l'app funziona lo stesso
  final promemoria = PromemoriaLocali();
  var notificheAttive = true;
  try {
    await promemoria.inizializza();
  } catch (e) {
    notificheAttive = false;
  }

  final accesso = AccessoFirebase();
  runApp(
    QuantoValgoApp(
      accesso: accesso,
      archivio: ArchivioFirestore(accesso: accesso),
      erroreAvvio: erroreAvvio,
      promemoria: notificheAttive ? promemoria : null,
    ),
  );
}
