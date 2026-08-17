import 'package:flutter/material.dart';
import 'package:invan2/changes/services/shift/shift_diagnostics.dart';
import 'package:invan2/utils/utils.dart';

/// Kassir dialogda tanlagan harakat.
enum ShiftWarningAction {
  /// Hech narsa qilinmasin.
  cancel,

  /// Ogohlantirishga qaramay davom etilsin (smena yopilsin).
  continueAnyway,

  /// Ketmagan cheklar hozir yuborilsin.
  sendReceipts,

  /// Serverga yetmagan smena yopilishi hozir yuborilsin.
  sendPendingClose,
}

/// Smena bilan bog'liq muammolarni kassirga **sabab bilan** ko'rsatadi.
///
/// Ilgari kassir faqat "Невозможно закрыть смену" yoki "Pos is open on the web"
/// degan matnni ko'rardi va nima qilishni bilmasdi. Bu dialog har bir muammoni
/// alohida sarlavha + tushuntirish bilan chiqaradi va tuzatish tugmasini beradi.
/// [infoOnly] — amal allaqachon hal bo'lgan, dialog faqat xabar beradi
/// ("Baribir yopish" tugmasi ko'rsatilmaydi).
///
/// [succeeded] — amal bajarildimi. `infoOnly` dialogda sarlavha shunga qarab
/// tanlanadi. Ilgari sarlavha har doim "Smena yopildi, lekin e'tibor bering"
/// edi va smena yopilmagan holatda ham shu chiqardi — kassir smenani yopilgan
/// deb o'ylardi (2026-08-17 hodisasi).
Future<ShiftWarningAction> showShiftWarningDialog(
  BuildContext context, {
  required List<ShiftIssue> issues,
  required ShiftSnapshot snapshot,
  required bool isUz,
  required ShiftAction action,
  bool infoOnly = false,
  bool succeeded = true,
}) async {
  if (issues.isEmpty) return ShiftWarningAction.continueAnyway;

  final ShiftWarningAction? result = await showDialog<ShiftWarningAction>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _ShiftWarningDialog(
      issues: issues,
      snapshot: snapshot,
      isUz: isUz,
      action: action,
      infoOnly: infoOnly,
      succeeded: succeeded,
    ),
  );

  return result ?? ShiftWarningAction.cancel;
}

class _ShiftWarningDialog extends StatelessWidget {
  const _ShiftWarningDialog({
    required this.issues,
    required this.snapshot,
    required this.isUz,
    required this.action,
    required this.infoOnly,
    required this.succeeded,
  });

  final List<ShiftIssue> issues;
  final ShiftSnapshot snapshot;
  final bool isUz;
  final ShiftAction action;
  final bool infoOnly;
  final bool succeeded;

  bool get _canSendReceipts =>
      snapshot.internet && snapshot.unsentReceipts > 0;

  bool get _canSendPendingClose =>
      snapshot.internet && snapshot.hasPendingClose;

  @override
  Widget build(BuildContext context) {
    final Color bg = Pref.getBool(PrefKeys.isDarkMode, true)
        ? Theme.of(context).dialogBackgroundColor
        : Colors.white;

    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        width: SizeConfig.h * 50,
        constraints: BoxConstraints(maxHeight: SizeConfig.v * 80),
        padding: EdgeInsets.all(SizeConfig.v * 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(SizeConfig.v),
          boxShadow: [
            BoxShadow(color: Theme.of(context).canvasColor, blurRadius: 4),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            SizedBox(height: SizeConfig.v * 2),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final issue in issues) _issueBlock(context, issue),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.v * 2),
            _buttons(context),
          ],
        ),
      ),
    );
  }

  /// Sarlavha amalning **haqiqiy natijasiga** qarab tanlanadi.
  String _headerText() {
    if (action == ShiftAction.open) {
      return isUz ? 'Smena ochilmadi' : 'Смена не открыта';
    }
    if (!infoOnly) {
      return isUz ? 'Smenani yopishdan oldin' : 'Перед закрытием смены';
    }
    return succeeded
        ? (isUz
            ? 'Smena yopildi, lekin e\'tibor bering'
            : 'Смена закрыта, но обратите внимание')
        : (isUz ? 'Smena yopilmadi' : 'Смена не закрыта');
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: SizeConfig.v * 5,
        ),
        SizedBox(width: SizeConfig.h),
        Expanded(
          child: Text(
            _headerText(),
            style: MyThemes.txtStyle(
              fontSize: 2.8,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).canvasColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _issueBlock(BuildContext context, ShiftIssue issue) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.v * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ${ShiftDiagnostics.title(issue, isUz: isUz)}',
            style: MyThemes.txtStyle(
              fontSize: 2.4,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).canvasColor,
            ),
          ),
          SizedBox(height: SizeConfig.v * .5),
          Text(
            ShiftDiagnostics.explain(
              issue,
              snapshot,
              isUz: isUz,
              action: action,
            ),
            style: MyThemes.txtStyle(
              fontSize: 2.1,
              color: Theme.of(context).canvasColor.withOpacity(.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    final List<Widget> buttons = [];

    if (_canSendPendingClose) {
      buttons.add(_button(
        context,
        label: isUz ? 'Yopishni yuborish' : 'Отправить закрытие',
        value: ShiftWarningAction.sendPendingClose,
        color: Theme.of(context).primaryColor,
        textColor: Colors.white,
      ));
    }

    if (_canSendReceipts) {
      buttons.add(_button(
        context,
        label: isUz ? 'Cheklarni yuborish' : 'Отправить чеки',
        value: ShiftWarningAction.sendReceipts,
        color: Theme.of(context).primaryColor,
        textColor: Colors.white,
      ));
    }

    if (action == ShiftAction.close && !infoOnly) {
      buttons.add(_button(
        context,
        label: isUz ? 'Baribir yopish' : 'Всё равно закрыть',
        value: ShiftWarningAction.continueAnyway,
        color: Colors.orange,
        textColor: Colors.white,
      ));
    }

    buttons.add(_button(
      context,
      label: infoOnly
          ? (isUz ? 'Tushunarli' : 'Понятно')
          : (isUz ? 'Bekor qilish' : 'Отмена'),
      value: ShiftWarningAction.cancel,
      color: Colors.grey.shade400,
      textColor: Colors.black87,
    ));

    return Column(
      children: [
        for (final b in buttons)
          Padding(
            padding: EdgeInsets.only(bottom: SizeConfig.v),
            child: b,
          ),
      ],
    );
  }

  Widget _button(
    BuildContext context, {
    required String label,
    required ShiftWarningAction value,
    required Color color,
    required Color textColor,
  }) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      onPressed: () => Navigator.of(context).pop(value),
      color: color,
      minWidth: double.infinity,
      height: SizeConfig.v * 7,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.v),
      ),
      child: Text(
        label,
        style: MyThemes.txtStyle(fontSize: 2.4, color: textColor),
      ),
    );
  }
}
