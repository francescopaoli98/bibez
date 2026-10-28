import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../logica/promemoria.dart';
import 'promemoria_servizio.dart';

/// Promemoria veri: notifiche locali di Android, programmate sul telefono
/// (funzionano anche con l'app chiusa e senza internet).
class PromemoriaLocali implements ServizioPromemoria {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pronto = false;

  static const _dettagli = NotificationDetails(
    android: AndroidNotificationDetails(
      'pagamenti',
      'Pagamenti',
      channelDescription: 'Promemoria dei pagamenti da incassare',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Da chiamare una volta all'avvio, prima di programmare.
  Future<void> inizializza() async {
    tz.initializeTimeZones();
    // L'app è in italiano e per l'Italia: i promemoria arrivano alle 9 di Roma.
    tz.setLocalLocation(tz.getLocation('Europe/Rome'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _pronto = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> chiediPermesso() async {
    if (!_pronto) return false;
    try {
      final android = _android;
      if (await android?.areNotificationsEnabled() ?? false) return true;
      return await android?.requestNotificationsPermission() ?? false;
    } catch (e) {
      debugPrint('Permesso notifiche non chiesto: $e');
      return false;
    }
  }

  @override
  Future<void> programma(List<Promemoria> promemoria) async {
    if (!_pronto) return;
    try {
      // Si toglie tutto e si riprogramma: più semplice che aggiornare una per una
      await _plugin.cancelAllPendingNotifications();
      for (final p in promemoria) {
        final q = p.quando;
        await _plugin.zonedSchedule(
          id: p.id,
          title: p.titolo,
          body: p.testo,
          // Ora "a muro" di Roma: le 9 del mattino sono le 9 del mattino
          scheduledDate: tz.TZDateTime(
            tz.local,
            q.year,
            q.month,
            q.day,
            q.hour,
            q.minute,
          ),
          notificationDetails: _dettagli,
          // Inesatto: non serve il permesso delle sveglie esatte, e a un
          // promemoria delle 9 non importa se arriva dopo qualche minuto.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Promemoria non programmati: $e');
    }
  }
}
