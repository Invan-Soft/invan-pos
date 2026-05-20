import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';

enum _MarkingSyncStep { fetching, comparing, done, error }

class MarkingSyncDialog extends StatefulWidget {
  final Future<void> Function() onFetch;
  final Future<void> Function() onCompare;

  const MarkingSyncDialog({
    super.key,
    required this.onFetch,
    required this.onCompare,
  });

  @override
  State<MarkingSyncDialog> createState() => _MarkingSyncDialogState();
}

class _MarkingSyncDialogState extends State<MarkingSyncDialog> {
  _MarkingSyncStep _step = _MarkingSyncStep.fetching;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _runSync();
  }

  Future<void> _runSync() async {
    try {
      if (mounted) setState(() => _step = _MarkingSyncStep.fetching);
      await widget.onFetch();

      if (mounted) setState(() => _step = _MarkingSyncStep.comparing);
      await widget.onCompare();

      if (mounted) setState(() => _step = _MarkingSyncStep.done);

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _MarkingSyncStep.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  bool get _isUz {
    final loc = AppLocalizations.of(context);
    return loc != null && loc.ha.toLowerCase() == 'ha';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.v * 1.5),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox(
        width: SizeConfig.h * 40,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.h * 5,
            vertical: SizeConfig.v * 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(context),
              SizedBox(height: SizeConfig.v * 2.5),
              _buildTitle(context),
              SizedBox(height: SizeConfig.v * 1.2),
              _buildSubtitle(context),
              if (_step == _MarkingSyncStep.error) ...[
                SizedBox(height: SizeConfig.v * 2),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    _isUz ? 'Yopish' : 'Закрыть',
                    style: MyThemes.txtStyle(
                      fontSize: 2.5,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    switch (_step) {
      case _MarkingSyncStep.fetching:
      case _MarkingSyncStep.comparing:
        return SpinKitCircle(
          color: Theme.of(context).primaryColor,
          size: SizeConfig.v * 6,
        );
      case _MarkingSyncStep.done:
        return Icon(
          Icons.check_circle_outline_rounded,
          color: Colors.green,
          size: SizeConfig.v * 6,
        );
      case _MarkingSyncStep.error:
        return Icon(
          Icons.error_outline_rounded,
          color: Colors.redAccent,
          size: SizeConfig.v * 6,
        );
    }
  }

  Widget _buildTitle(BuildContext context) {
    String text;
    switch (_step) {
      case _MarkingSyncStep.fetching:
        text = _isUz
            ? 'Soliqdan ma\'lumotlar olinmoqda...'
            : 'Загрузка данных из Солика...';
        break;
      case _MarkingSyncStep.comparing:
        text = _isUz
            ? 'Mahsulotlar taqqoslanmoqda...'
            : 'Сравнение товаров...';
        break;
      case _MarkingSyncStep.done:
        text = _isUz ? 'Muvaffaqiyatli!' : 'Успешно!';
        break;
      case _MarkingSyncStep.error:
        text = _isUz ? 'Xatolik yuz berdi' : 'Произошла ошибка';
        break;
      default:
        text = '';
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: MyThemes.txtStyle(
        fontSize: 3,
        color: Theme.of(context).canvasColor,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    String text;
    Color color;
    switch (_step) {
      case _MarkingSyncStep.fetching:
        text = _isUz
            ? 'Soliq tizimidan markirovkali mahsulotlar ro\'yxati olib kelinmoqda'
            : 'Загружается список маркированных товаров из системы Солик';
        color = Theme.of(context).hintColor;
        break;
      case _MarkingSyncStep.comparing:
        text = _isUz
            ? 'Mahsulotlar bir-biriga solishtirilmoqda va marking holati yangilanmoqda'
            : 'Товары сравниваются и статус маркировки обновляется';
        color = Theme.of(context).hintColor;
        break;
      case _MarkingSyncStep.done:
        text = _isUz
            ? 'Barcha mahsulotlarning marking holati muvaffaqiyatli yangilandi'
            : 'Статус маркировки всех товаров успешно обновлён';
        color = Colors.green.withOpacity(0.8);
        break;
      case _MarkingSyncStep.error:
        text = _errorMessage.isNotEmpty
            ? _errorMessage
            : (_isUz ? 'Qayta urinib ko\'ring' : 'Попробуйте снова');
        color = Colors.redAccent.withOpacity(0.8);
        break;
      default:
        text = '';
        color = Theme.of(context).hintColor;
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: MyThemes.txtStyle(
        fontSize: 2.3,
        color: color,
      ),
    );
  }
}