/*
    "Oflayn rejim" belgisi — server javob bermayotganini kassirga bildiradi.

    Nima uchun kerak: server yiqilganda kassa ishlashda davom etadi (sotuv,
    qaytarish, smena — hammasi lokal ketadi va navbatga tushadi). Lekin bu
    jimgina sodir bo'lsa kassir hech narsani sezmaydi va cheklar serverda
    yo'qligini faqat kun oxirida biladi. Bu belgi holatni ko'rsatib turadi:
    "kassa ishlayapti, lekin server bilan aloqa yo'q va N ta hujjat navbatda".
*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/objectbox.g.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';
import 'package:invan2/utils/utils.dart';

class OfflineModeBadge extends StatefulWidget {
  const OfflineModeBadge({super.key});

  @override
  State<OfflineModeBadge> createState() => _OfflineModeBadgeState();
}

class _OfflineModeBadgeState extends State<OfflineModeBadge> {
  Timer? _timer;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    BackendHealth.status.addListener(_onStatusChanged);
    if (BackendHealth.isDown) _startCounting();
  }

  @override
  void dispose() {
    BackendHealth.status.removeListener(_onStatusChanged);
    _timer?.cancel();
    super.dispose();
  }

  void _onStatusChanged() {
    if (!mounted) return;
    if (BackendHealth.isDown) {
      _startCounting();
    } else {
      _timer?.cancel();
      _timer = null;
    }
    setState(() {});
  }

  /// Navbat sonini faqat oflayn holatda sanaymiz — onlayn ishlashga
  /// keraksiz yuk qo'shmaslik uchun.
  void _startCounting() {
    _count();
    _timer ??= Timer.periodic(const Duration(seconds: 10), (_) => _count());
  }

  void _count() {
    if (!mounted) return;
    int total = 0;
    try {
      // Qaytarishlar ham `ReceiptModel4` — shu bitta so'rov sotuv va
      // qaytarish navbatini birga sanaydi.
      final query = MyObjectbox.saleStore
          .box<ReceiptModel4>()
          .query(ReceiptModel4_.uploaded.equals(false) &
              ReceiptModel4_.rejected.equals(false))
          .build();
      total = query.count();
      query.close();
      if (ShiftSyncQueue.hasPending) total++;
    } catch (_) {
      // Sanoq ixtiyoriy — xato bo'lsa belgi baribir ko'rsatiladi.
    }
    if (mounted && total != _pending) setState(() => _pending = total);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BackendStatus>(
      valueListenable: BackendHealth.status,
      builder: (context, status, _) {
        if (status == BackendStatus.up) return const SizedBox.shrink();

        final AppLocalizations? loc = AppLocalizations.of(context);
        final bool isUz = loc == null || loc.ha.toLowerCase() == 'ha';
        final String title =
            isUz ? 'Oflayn rejim' : 'Автономный режим';
        final String queued = _pending > 0
            ? (isUz ? ' • navbatda $_pending' : ' • в очереди $_pending')
            : '';

        return Tooltip(
          message: isUz
              ? 'Server bilan aloqa yo\'q. Sotuv, qaytarish va smena lokal '
                  'ishlayapti — aloqa tiklangach hammasi avtomatik yuboriladi.'
              : 'Нет связи с сервером. Продажа, возврат и смена работают '
                  'локально — после восстановления связи всё отправится '
                  'автоматически.',
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: SizeConfig.h * 0.6),
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.h * 0.8, vertical: SizeConfig.v * 0.6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(SizeConfig.h * 0.6),
              border: Border.all(color: const Color(0xFFFFA726)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: SizeConfig.v * 2.4, color: const Color(0xFFE65100)),
                SizedBox(width: SizeConfig.h * 0.5),
                Text(
                  '$title$queued',
                  style: MyThemes.txtStyle(
                      fontSize: 1.8, color: const Color(0xFFE65100)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
