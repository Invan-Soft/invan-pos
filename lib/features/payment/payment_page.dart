// ignore_for_file: deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/components/logo_widget.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/bottom_layer_of_home_page.dart';
import 'package:invan2/features/payment/right/dilogs/add_client/bloc/addclient_bloc.dart';
import 'package:invan2/features/payment/right/dilogs/add_client/create_client_dialog.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/alice_pincode.dart';
import 'package:provider/provider.dart';
import 'right/right.dart';
import 'left/left.dart';

// ignore: must_be_immutable
class PaymentPage extends StatefulWidget {
  BuildContext con;

  PaymentPage(this.con, {super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late BlBloc blBloc;

  @override
  void initState() {
    super.initState();
    blBloc = BlocProvider.of(context);
    blBloc.add(
      BlStatusChangedEvent(
        status: BLStatus.other,
        where: "lib/features/payment/payment_page.dart build",
      ),
    );

    Log.d('init state ishga tushdi', name: 'PaymentPage');
  }

  @override
  Widget build(BuildContext context) {
    final bool ofd = Pref.getBool(PrefKeys.withOFD, false);
    AddClientBloc addClientBloc = BlocProvider.of(context);
    return WillPopScope(
      onWillPop: () {
        blBloc.add(
          BlStatusChangedEvent(
              status: BLStatus.home,
              where: "lib/features/payment/payment_page.dart willPopScope"),
        );
        return Future.value(true);
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton:
            Pref.getBool(PrefKeys.isDevAlice, false) && kDebugMode
                ? FloatingActionButton(
                    heroTag: null,
                    backgroundColor: Theme.of(context).primaryColor,
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => AlicePincodePage());
                    },
                    child: const Icon(
                      Icons.http_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  )
                : const SizedBox(),
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 4,
          leadingWidth: SizeConfig.h * 16,
          automaticallyImplyLeading: false,
          toolbarHeight: SizeConfig.v * 7.37,
          backgroundColor: Theme.of(context).colorScheme.background,
          leading: _leading(context),
          actions: _actions(context, addClientBloc, ofd),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Stack(
          children: [
            Column(
              children: [
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Left(),
                    SizedBox(width: SizeConfig.h * 1.46),
                    Right(widget.con),
                  ],
                ),
                const Spacer(),
                SizedBox(
                    height: SizeConfig.v * 3,
                    child: const BottomLayerOfHomePage()),
              ],
            ),
            context.watch<OrderingProvider4>().getPaymentInProgress
                ? Positioned.fill(
                    child: Container(
                      color: Colors.transparent,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                    ),
                  )
                : const SizedBox()
          ],
        ),
      ),
    );
  }

  MaterialButton _leading(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      height: double.infinity,
      minWidth: SizeConfig.h * 10,
      color: Theme.of(context).colorScheme.background,
      elevation: 0,
      onPressed: context.watch<OrderingProvider4>().getPaymentInProgress
          ? null
          : () {
              AppNavigation.pop();
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back_ios_outlined,
            size: SizeConfig.v * 4,
            color: Theme.of(context).canvasColor,
          ),
          SizedBox(width: SizeConfig.h),
          LogoInvanWidget(width: SizeConfig.h * 9.77),
        ],
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    AddClientBloc addClientBloc,
    bool ofd,
  ) {
    final bool paymentInProgress =
        context.watch<OrderingProvider4>().getPaymentInProgress;
    final bool supplierSelected =
        context.watch<OrderingProvider4>().getSelectedSupplier != null;

    return [
      TextButton(
        focusNode: FocusNode(skipTraversal: true),
        onPressed: paymentInProgress
            ? null
            : () async {
                addClientBloc.add(AddClientCallInitialEvent());
                await showDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: MaterialLocalizations.of(context)
                      .modalBarrierDismissLabel,
                  barrierColor: Colors.transparent,
                  builder: (_) {
                    return const AlertDialog(
                        alignment: Alignment.topRight,
                        backgroundColor: Colors.transparent,
                        content: ClientCreateDialog());
                  },
                );
              },
        style: TextButton.styleFrom(
          fixedSize: Size(SizeConfig.h * 5, SizeConfig.v * 7.37),
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.background,
        ),
        child: Icon(
          Icons.add_circle_outline_rounded,
          color: Theme.of(context).canvasColor,
          size: 35,
        ),
      ),

      // Izoh qo'shish
      TextButton(
        focusNode: FocusNode(skipTraversal: true),
        onPressed: () {
          if (paymentInProgress) return;
          Provider.of<OrderingProvider4>(context, listen: false)
              .onAddComments(widget.con);
        },
        style: TextButton.styleFrom(
          fixedSize: Size(SizeConfig.h * 5, SizeConfig.v * 7.37),
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.background,
        ),
        child: Icon(
          Icons.insert_comment,
          color: Theme.of(context).canvasColor,
          size: 35,
        ),
      ),

      // Client search
      TextButton(
        focusNode: FocusNode(skipTraversal: true),
        onPressed: () {
          if (paymentInProgress) return;
          Provider.of<OrderingProvider4>(context, listen: false)
              .onClientSearchButtonPressed(widget.con, WherePath.paymentScreen);
        },
        style: TextButton.styleFrom(
          fixedSize: Size(SizeConfig.h * 5, SizeConfig.v * 7.37),
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.background,
        ),
        child: Icon(
          Icons.person_search_outlined,
          size: SizeConfig.v * 4.2,
          color: Theme.of(context).canvasColor,
        ),
      ),

      // Supplier search
      TextButton(
        focusNode: FocusNode(skipTraversal: true),
        onPressed: () {
          if (paymentInProgress) return;
          Provider.of<OrderingProvider4>(context, listen: false)
              .onSupplierSearchButtonPressed(context);
        },
        style: TextButton.styleFrom(
          fixedSize: Size(SizeConfig.h * 5, SizeConfig.v * 7.37),
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.background,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.manage_search_rounded,
              size: SizeConfig.v * 4.2,
              color: Theme.of(context).canvasColor,
            ),
          ],
        ),
      ),

      SizedBox(width: SizeConfig.h * 0.1),
    ];
  }
}
