// Yagona yuklash shkalasi (0–100%) testlari.
//
// Ikki asosiy talab:
//   1. Foiz butun startup bo'ylab BITTA shkala — har bosqich o'z ulushini
//      to'ldiradi (xodimlar 0–10, yuklash 20–85, yozish 85–100).
//   2. Foiz faqat haqiqiy ma'lumotdan chiqadi va hech qachon ortga ketmaydi.

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/startup_progress.dart';

void main() {
  setUp(StartupProgress.reset);

  test('boshlang\'ich holat — faol emas, 0%', () {
    expect(StartupProgress.value.isActive, isFalse);
    expect(StartupProgress.value.percent, 0);
  });

  test('bosqichlar ketma-ket ulushlarni to\'ldiradi', () {
    StartupProgress.set(StartupPhase.employees);
    expect(StartupProgress.value.percent, 0);

    StartupProgress.set(StartupPhase.packageCode);
    expect(StartupProgress.value.percent, 10);

    StartupProgress.set(StartupPhase.productsRequest);
    expect(StartupProgress.value.percent, 15);

    StartupProgress.set(StartupPhase.productsDownload);
    expect(StartupProgress.value.percent, 20);

    StartupProgress.saving(0);
    expect(StartupProgress.value.percent, 85);

    StartupProgress.done();
    expect(StartupProgress.value.percent, 100);
  });

  test('yuklab olish 20–85 oralig\'ida siljiydi', () {
    StartupProgress.download(0, 100);
    expect(StartupProgress.value.percent, 20);

    StartupProgress.download(50, 100);
    expect(StartupProgress.value.percent, 53); // 20 + 65*0.5

    StartupProgress.download(100, 100);
    expect(StartupProgress.value.percent, 85);
  });

  test('yozish 85–100 oralig\'ida siljiydi', () {
    StartupProgress.saving(0);
    expect(StartupProgress.value.percent, 85);

    StartupProgress.saving(.5);
    expect(StartupProgress.value.percent, 93); // 85 + 15*0.5

    StartupProgress.saving(1);
    expect(StartupProgress.value.percent, 100);
  });

  test('Content-Length noma\'lum bo\'lsa foiz bosqich boshida qoladi', () {
    StartupProgress.download(5000, -1);

    expect(StartupProgress.value.phase, StartupPhase.productsDownload);
    expect(StartupProgress.value.percent, 20);
  });

  test('foiz ortga ketmaydi', () {
    StartupProgress.download(80, 100);
    final int reached = StartupProgress.value.percent;

    // Server noto'g'ri qiymat bersa ham shkala orqaga sakramaydi.
    StartupProgress.download(10, 100);
    expect(StartupProgress.value.percent, reached);
  });

  test('foiz 0..100 oralig\'idan chiqmaydi', () {
    StartupProgress.download(150, 100);
    expect(StartupProgress.value.percent, 100 - 15); // 85 = yuklash oxiri
  });

  test('bir xil foizda UI qayta chizilmaydi', () {
    StartupProgress.download(100, 1000);

    int notifications = 0;
    void listener() => notifications++;
    StartupProgress.notifier.addListener(listener);

    // Bir xil butun foizga tushadigan chunklar.
    StartupProgress.download(101, 1000);
    StartupProgress.download(103, 1000);
    expect(notifications, 0);

    // Foiz o'zgargach — bitta xabar.
    StartupProgress.download(130, 1000);
    expect(notifications, 1);

    StartupProgress.notifier.removeListener(listener);
  });

  test('reset holatni tozalaydi', () {
    StartupProgress.download(50, 100);
    StartupProgress.reset();

    expect(StartupProgress.value.isActive, isFalse);
    expect(StartupProgress.value.percent, 0);
  });
}
