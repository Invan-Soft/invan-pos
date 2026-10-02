import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/patch_updater.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() {
  group('PatchUpdater.isUpdateInProgress', () {
    test('avtomatik yuklovchi bilan poyga — xato emas (kanalga yuborilmaydi)',
        () {
      // Mac sinovidagi aynan shu xabar (Flutter 3.41.3 dvigateli).
      const UpdateException error = UpdateException(
        message: 'Update already in progress',
        reason: UpdateFailureReason.unknown,
      );
      expect(PatchUpdater.isUpdateInProgress(error), isTrue);
    });

    test('haqiqiy yuklash/o\'rnatish xatosi — xato', () {
      expect(
        PatchUpdater.isUpdateInProgress(const UpdateException(
          message: 'Failed to download patch',
          reason: UpdateFailureReason.downloadFailed,
        )),
        isFalse,
      );
      expect(
        PatchUpdater.isUpdateInProgress(const UpdateException(
          message: 'Patch failed to install',
          reason: UpdateFailureReason.installFailed,
        )),
        isFalse,
      );
    });

    test('UpdateException bo\'lmagan xato — matni mos bo\'lsa ham xato', () {
      expect(
        PatchUpdater.isUpdateInProgress(
            Exception('Update already in progress')),
        isFalse,
      );
    });
  });
}
