// ignore_for_file: dead_code
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/features/checks/features/check_view/bloc/re_update_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/my_snackbar.dart';
import '../../../../changes/bloc/network/network_bloc.dart';
import '../../../../utils/l10n/app_localizations.dart';
import '../../../home/features/operation_on_product/delete_item/input_alert_dialog.dart';
import 'bloc/pre_ofd/preofd_bloc.dart';
import 'check_view_inner_content.dart';
import '../../return_page/return_page.dart';
import 'pre_ofd_dialog.dart';

class CheckViewContent extends StatefulWidget {
  const CheckViewContent({super.key});

  @override
  State<CheckViewContent> createState() => _CheckViewContentState();
}

class _CheckViewContentState extends State<CheckViewContent> {
  bool _isPrinting = false;

  Future<void> _handlePrint() async {
    if (_isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      final receipt = BlocProvider.of<CheckFBloc>(context).selectedCheck;
      if (receipt == null) return;

      if (Pref.getBool(PrefKeys.withOFD, false)) {
        await PrintingMethods.printCheck(
          receipt,
          receipt.sdacha,
          incomInfo: receipt.refundInfo != null && receipt.refundInfo != 'null'
              ? Info.fromJson(jsonDecode(receipt.refundInfo!))
              : null,
          isCopy: true,
        );
      } else {
        await PrintingMethods.printCheck(
          receipt,
          receipt.sdacha,
          incomInfo: null,
          isCopy: true,
        );
      }
    } finally {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    CheckFBloc checkFBloc = BlocProvider.of(context);

    return BlocBuilder<CheckFBloc, CheckFState>(
      builder: (context, state) {
        PreOfdBloc returnBloc = BlocProvider.of(context);
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SizeConfig.v * .7),
            color: Theme.of(context).dialogBackgroundColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: SizeConfig.v * 3,
                  right: SizeConfig.h * 2,
                  left: SizeConfig.h * 2,
                  bottom: SizeConfig.v,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    checkFBloc.selectedCheck != null &&
                            (checkFBloc.selectedCheck!.url == null ||
                                checkFBloc.selectedCheck!.url!.isEmpty) &&
                            !checkFBloc.selectedCheck!.isRefund
                        ? BlocListener<PreOfdBloc, PreOfdState>(
                            listener: (context, state) async {
                              if (state is PreOfdSuccedState) {
                                final receipt = state.receiptModel4;
                                if (Pref.getBool(PrefKeys.withOFD, false)) {
                                  await PrintingMethods.printCheck(
                                      receipt, receipt.sdacha,
                                      incomInfo: receipt.refundInfo != null &&
                                              receipt.refundInfo != 'null'
                                          ? Info.fromJson(
                                              jsonDecode(receipt.refundInfo!))
                                          : null);
                                } else {
                                  await PrintingMethods.printCheck(
                                    receipt,
                                    receipt.sdacha,
                                    incomInfo: null,
                                  );
                                }
                              }
                            },
                            child: Pref.getBool(PrefKeys.withOFD, false)
                                ? OutlinedButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (checkFBloc.selectedCheck != null) {
                                        returnBloc.add(
                                          SetPreOfdEvent(
                                            isRetry: false,
                                            clientNumber: checkFBloc
                                                    .selectedCheck
                                                    ?.clientPhone ??
                                                "",
                                            receiptModel4:
                                                checkFBloc.selectedCheck!,
                                            loc: loc,
                                          ),
                                        );
                                        await showGeneralDialog(
                                          context: context,
                                          pageBuilder: (context, x, y) {
                                            return PreOfdDialog(
                                              clientNumber: checkFBloc
                                                      .selectedCheck
                                                      ?.clientPhone ??
                                                  "",
                                              receiptModel4:
                                                  checkFBloc.selectedCheck!,
                                            );
                                          },
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(SizeConfig.v * 1.5),
                                      child: Text(
                                        loc.ha == 'Ha' ? 'To\'lov' : 'Оплата',
                                        style: MyThemes.txtStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).canvasColor,
                                          fontSize: 2.3,
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox.shrink(),
                          )
                        : const SizedBox.shrink(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Builder(
                          builder: (context) {
                            if (checkFBloc.selectedCheck != null) {
                              if (checkFBloc.selectedCheck!.isRefund) {
                                return const SizedBox(width: 0, height: 0);
                              } else {
                                return MaterialButton(
                                  focusNode: FocusNode(skipTraversal: true),
                                  onPressed: () async {
                                    if (!Pref.getBool(
                                        PrefKeys.companyActive, false)) {
                                      return;
                                    }

                                    NetworkBloc networkBloc =
                                        BlocProvider.of(context, listen: false);
                                    bool refund = HiveBoxes.getCurrentEmployee
                                            ?.access?.refund ??
                                        false;
                                    if (refund) {
                                      if (networkBloc.internet) {
                                        BlocProvider.of<ReUpdateBloc>(context)
                                            .add(
                                          GetReUpdateEvent(
                                              receiptModel4:
                                                  checkFBloc.selectedCheck!),
                                        );
                                      }
                                    } else {
                                      await showDialog(
                                        context: context,
                                        builder: (_) => InputAlertDialog(
                                          onValueEntered: (employee) {
                                            AppNavigation.pop();
                                            if (employee.access?.refund ??
                                                false) {
                                              if (networkBloc.internet) {
                                                checkFBloc.selectedCheck = ggg(
                                                    checkFBloc.selectedCheck!,
                                                    employee);
                                                BlocProvider.of<ReUpdateBloc>(
                                                        context)
                                                    .add(
                                                  GetReUpdateEvent(
                                                      receiptModel4: checkFBloc
                                                          .selectedCheck!),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      );
                                    }
                                  },
                                  color: Colors.red.withOpacity(.8),
                                  minWidth: SizeConfig.h * 7,
                                  height: SizeConfig.v * 6,
                                  child:
                                      BlocConsumer<ReUpdateBloc, ReUpdateState>(
                                    listener: (context, state) {
                                      if (state is ReUpdateSuccesState) {
                                        AppNavigation.push(
                                          ReturnPage(
                                              receiptModel4:
                                                  state.receiptModel4),
                                        ).then(
                                          (value) => checkFBloc.add(
                                            CheckFCallInitialEvent(),
                                          ),
                                        );
                                      }
                                    },
                                    builder: (context, state) {
                                      if (state is ReUpdateProccesState) {
                                        return const CircularProgressIndicator(
                                          color: Colors.white,
                                        );
                                      } else {
                                        return Text(
                                          loc.qaytarish,
                                          style: MyThemes.txtStyle(
                                            color: Colors.white,
                                            fontSize: 2.3,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              }
                            } else {
                              return const SizedBox(width: 0, height: 0);
                            }
                          },
                        ),
                        SizedBox(width: SizeConfig.h * 3),
                        OutlinedButton(
                          focusNode: FocusNode(skipTraversal: true),
                          style:  OutlinedButton.styleFrom(
                            backgroundColor: _isPrinting? Theme.of(context).primaryColor.withOpacity(0.4):Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                          ),
                          onPressed: _isPrinting ? null : _handlePrint,
                          child: Padding(
                            padding: EdgeInsets.all(SizeConfig.v),
                            child: Icon(
                              Icons.print,
                              color: Theme.of(context).canvasColor,
                              size: SizeConfig.v * 5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const CheckViewInnerContent(),
            ],
          ),
        );
      },
    );
  }

  ReceiptModel4 ggg(ReceiptModel4 rec, Employee employee) {
    return ReceiptModel4(
      createdDate: rec.createdDate,
      orderId: rec.orderId,
      cashboxId: rec.cashboxId,
      externalId: rec.externalId,
      orderType: rec.orderType,
      shopId: rec.shopId,
      userId: rec.userId,
      discountVat: rec.discountVat,
      discountID: rec.discountID,
      newid: rec.newid,
      supplierId: rec.supplierId,
      cashierId: employee.user?.id ?? '',
      cashierName: employee.user?.firstName ?? '',
      date: rec.date,
      isRefund: rec.isRefund,
      totalPrice: rec.totalPrice,
      uploaded: rec.uploaded,
      rejected: rec.rejected,
      clientName: rec.clientName,
      clientPhone: rec.clientPhone,
      clientId: rec.clientId,
      cashback: rec.cashback,
      sdacha: rec.sdacha,
      returnForCheck: rec.returnForCheck,
      posName: rec.posName,
      isDonate: rec.isDonate,
      url: rec.url,
      comment: rec.comment,
      commissionTIN: rec.commissionTIN,
      dateTimeOFD: rec.dateTimeOFD,
      fiscalSign: rec.fiscalSign,
      hasClick: rec.hasClick,
      hasPayme: rec.hasPayme,
      hasUzum: rec.hasUzum,
      isShow: rec.isShow,
      receiptSeq: rec.receiptSeq,
      refundInfo: rec.refundInfo,
      terminalId: rec.terminalId,
      zdachiToCashback: rec.zdachiToCashback,
    );
  }
}
