part of 'serch_dialog_bloc.dart';

// SD means SearchDialog
abstract class SDevent {}

class SDtypedEvent extends SDevent {
  final String character;
  SDtypedEvent(this.character);
}

class SDinitializeSearchTypeEnumEvent extends SDevent {
  final SearchTypeEnum searchTypeEnum;
  SDinitializeSearchTypeEnumEvent(this.searchTypeEnum);
}

class SDtypeFromVirtualKeyboardEvent extends SDevent {
  final String v;
  SDtypeFromVirtualKeyboardEvent(this.v);
}

class SDbackSpacePressedEvent extends SDevent {}

class SDcapsLockEvent extends SDevent {}

class SDshiftEvent extends SDevent {}

class SDarrowEvent extends SDevent {
  final ArrowTo arrowTo;
  SDarrowEvent(this.arrowTo);
}
    class  SDreturnEvent  extends SDevent  {

}
