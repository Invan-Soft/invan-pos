part of 'check_f_bloc.dart';

abstract class CheckFEvent {}

class CheckFSearchWhenOnChangeEvent extends CheckFEvent {
  final String pattern;
  CheckFSearchWhenOnChangeEvent(this.pattern);
}

class CheckFSelectCheckEvent extends CheckFEvent {
  final int selected;
  CheckFSelectCheckEvent(this.selected);
}

class CheckFSearchGlobalEvent extends CheckFEvent {
  int page;
  final String pattern;
  bool isRetry;
  bool fromSubmit;
  CheckFSearchGlobalEvent(this.pattern,
      {this.isRetry = false, this.fromSubmit = false, required this.page});
}

class CheckFDateChangedEvent extends CheckFEvent {
  final List<ReceiptModel4> data;
  final int unsents;
  CheckFDateChangedEvent(this.data, this.unsents);
}

class CheckFCallInitialEvent extends CheckFEvent {}

/// ObjectBox o'zgarganda (masalan chek orqa fonda yuborilib uploaded=true
/// bo'lganda) cheklar ro'yxatini jonli yangilaydi. Tanlangan chek va qidiruv
/// holatini buzmaydi.
class CheckFRefreshEvent extends CheckFEvent {
  final List<ReceiptModel4> data;
  final bool isSearching;
  CheckFRefreshEvent(this.data, {this.isSearching = false});
}
