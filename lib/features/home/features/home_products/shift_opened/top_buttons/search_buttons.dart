import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/dialogs/virtual_keyboard/app_virtual_keyboard.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/product_search/dialog/bloc/serch_dialog_bloc.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/top_buttons/button_widgets/client_search_button.dart.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/top_buttons/button_widgets/product_search_button.dart';
import 'package:invan2/widgets/app_bar/app_bar_lock_button.dart';
import 'package:provider/provider.dart';
import '../../../../../../changes/dialogs/mxik/mxik_error_message.dart';
import '../../../../../../changes/dialogs/printer_not_selected_dialog.dart';
import '../../../../../../changes/models/ofd/incom_response_model.dart';
import '../../../../../../changes/providers/product_search_provider.dart';
import '../../../../../../utils/utils.dart';
import '../../../../../hive_repository/hive_boxes.dart';
import '../product_search/dialog/search_dialog.dart';

class SearchButtons extends StatelessWidget {
  final BuildContext contact;
  final VoidCallback onLockButtonPressed;

  const SearchButtons(this.contact,
      {required this.onLockButtonPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final SDbloc searchDialogBloc = BlocProvider.of(context);

    final BlBloc blBloc = BlocProvider.of(context, listen: false);
    return MyBarcodeListener(
      bufferDuration: const Duration(milliseconds: 300),
      onBarcodeScannedMagnetic: (String s) {},
      onF1pressed: () async {
        searchDialogBloc
            .add(SDinitializeSearchTypeEnumEvent(SearchTypeEnum.byProductName));
        blBloc.add(BlStatusChangedEvent(
            status: BLStatus.other,
            where:
                "lib/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart  nameSearch"));
        await searchDialog(context, SearchTypeEnum.byProductName);
        blBloc.add(BlStatusChangedEvent(
            status: BLStatus.home,
            where:
                "lib/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart  nameSearch"));
      },
      onBarcodeScanned: (String s) {},
      onBarcodeScannedClick: (s) {},
      onBarcodeScannedPayme: (s) {},
      onDelPressed: () {},
      onF12Pressed: () {},
      onF2pressed: () async {
        searchDialogBloc
            .add(SDinitializeSearchTypeEnumEvent(SearchTypeEnum.byBarcode));
        blBloc.add(BlStatusChangedEvent(
            status: BLStatus.other,
            where:
                "lib/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart  qrSearch"));

        await searchDialog(context, SearchTypeEnum.byBarcode);

        blBloc.add(BlStatusChangedEvent(
            status: BLStatus.home,
            where:
                "lib/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart  qrSearch"));
      },
      onF3pressed: () async {
        searchDialogBloc
            .add(SDinitializeSearchTypeEnumEvent(SearchTypeEnum.bySKU));
        blBloc.add(BlStatusChangedEvent(
            status: BLStatus.other,
            where:
                "lib/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart  skuSearch"));
        await searchDialog(context, SearchTypeEnum.bySKU);
        blBloc.add(BlStatusChangedEvent(
            status: BLStatus.home,
            where:
                "lib/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart  skuSearch"));
      },
      onF5pressed: () async {
        Object? mxikError;
        bool printerSelected = HiveBoxes.getPrinters().values.isNotEmpty;
        bool printerRequired = Pref.getBool(PrefKeys.printerRequired, false);
        bool mxikDialogError = false;
        List<NoMxikItem>? errorMxikList;

        if (printerRequired && !printerSelected) {
          showCupertinoDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return const PrinterNotSelectedDialog(
                text: 'Принтер не выбран ',
              );
            },
          );
        } else {
          if (mxikDialogError == false) {
            blBloc.add(BlStatusChangedEvent(
                status: BLStatus.other,
                where:
                    "lib/features/home/features/home_orders/calculation_part/calculation_part.dart total"));

            mxikError = await Provider.of<OrderingProvider4>(
              context,
              listen: false,
            ).goToPaymentPage(context);

            blBloc.add(
              BlStatusChangedEvent(
                status: BLStatus.home,
                where:
                    "lib/features/home/features/home_orders/calculation_part/calculation_part.dart total",
              ),
            );

            if (mxikError is MxikError) {
              MxikError m = mxikError;
              List<NoMxikItem> items = m.message!;

              showGeneralDialog(
                context: context,
                pageBuilder: (context, animation, secondaryAnimation) {
                  // mxik feko
                  // return MxikErrorDialog(
                  //   items: items,
                  // );
                  return MxikErrorMessageDialog(
                    items: items,
                  );
                },
              );
            }
          } else {
            showGeneralDialog(
              context: context,
              pageBuilder: (context, animation, secondaryAnimation) {
                return MxikErrorMessageDialog(
                  items: errorMxikList ?? [],
                );
              },
            );
          }
        }
      },
      onShiftDeletePressed: () {},
      onDownPressed: () {},
      onUpPressed: () {},
      onBarcodeScannedClient: (s) {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClientSearchButton(onPressed: () async {
            blBloc.add(BlStatusChangedEvent(
                status: BLStatus.other,
                where:
                    "lib/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart  clientSearch"));
            await Provider.of<OrderingProvider4>(context, listen: false)
                .onClientSearchButtonPressed(contact, WherePath.homeScreen);
            if (kDebugMode) {
              // virtualKeyboardShow(context);
            }
            blBloc.add(BlStatusChangedEvent(
                status: BLStatus.home,
                where:
                    "lib/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart  clientSearch"));
          }),
          SizedBox(width: SizeConfig.h),
     
          ProductSearchButton(
            onPressed: () async {
              searchDialogBloc.add(
                  SDinitializeSearchTypeEnumEvent(SearchTypeEnum.byBarcode));
              blBloc.add(BlStatusChangedEvent(
                  status: BLStatus.other,
                  where:
                      "lib/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart  nameSearch"));
              await searchDialog(context, SearchTypeEnum.byBarcode);
              blBloc.add(BlStatusChangedEvent(
                  status: BLStatus.home,
                  where:
                      "lib/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart  nameSearch"));
            },
          ),
          SizedBox(width: SizeConfig.h),
          AppBarLockButton(
            color: Theme.of(context).colorScheme.background,
            onPress: onLockButtonPressed,
          ),
        ],
      ),
    );
  }

  Future<void> searchDialog(context, SearchTypeEnum searchTypeEnum) async {
    final ItemModel? product = await showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return SearchDialog(searchTypeEnum: searchTypeEnum);
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 100),
    );

    if (product != null) {
      Provider.of<OrderingProvider4>(context, listen: false)
          .pressProduct(context, product, "Buttons / SearchDialog");
    } else {
      return;
    }
    return;
  }

  Future<void> virtualKeyboardShow(context) async {
    final ItemModel? product = await showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const AppVirtualKeyboardDialog(
            searchTypeEnum: SearchTypeEnum.byBarcode);
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 100),
    );

    if (product != null) {
      Provider.of<OrderingProvider4>(context, listen: false)
          .pressProduct(context, product, "Buttons / SearchDialog");
    } else {
      return;
    }
    return;
  }
}
