
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/bloc/network/network_bloc.dart';
import 'package:invan2/changes/dialogs/no_access_dialog/no_access_dialog.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/home/bloc/home_bloc/home_bloc.dart';
import 'package:invan2/features/home/bloc/invoice/invoice_bloc.dart';
import 'package:invan2/features/home/build_content.dart';
import 'package:invan2/features/home/components/sync_button_home.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart';
import 'package:invan2/features/home/features/home_orders/clients_part/clients_part.dart';
import 'package:invan2/features/lock/access_level/bloc/access/access_bloc.dart';
import 'package:invan2/features/lock/access_level/view/access_level_page.dart';
import 'package:invan2/widgets/alice_pincode.dart';
import 'package:invan2/widgets/app_bar/app_bar_drawer_button.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:invan2/utils/utils.dart';
import '../../changes/dialogs/invoice_search_dialog.dart';
import '../checks/checks_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late HomeBloc homeBloc;
  int leftFlex = 2;
  int rightFlex = 1;
  late AccessBloc accessBloc;
  late NetworkBloc networkBloc;
  late bool isReturnState;
  late BlBloc blBlocc;

  @override
  void initState() {
    isReturnState =
        Provider.of<ReturnProvider>(context, listen: false).isReturningState;
    homeBloc = BlocProvider.of(context);
    networkBloc = BlocProvider.of(context);
    blBlocc = BlocProvider.of(context, listen: false);
    blBlocc.add(
      BlStatusChangedEvent(
        status: BLStatus.home,
        where: 'Home',
      ),
    );
    blBlocc.add(BlVisibilityChangedEvent(true));
    accessBloc = BlocProvider.of(context, listen: false);
    // connect();
    super.initState();
  }

  bool deleteTicketAccess = Pref.getDeleteItem('delete_ticket');

  @override
  Widget build(BuildContext context) {
    final OrderingProvider4 productsGridviewProvider =
        Provider.of<OrderingProvider4>(context);
    final LocalCategoryProvider localCategoryProvider =
        Provider.of<LocalCategoryProvider>(context);
    final currentSelectedCategoryButton =
        localCategoryProvider.getCurrentSelectedCategoryButton;
    return WillPopScope(
      onWillPop: () async => false,
      child: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) async {
          if (state is HomeSyncState) {
            if (currentSelectedCategoryButton < 0) {
              productsGridviewProvider.pressAllPath();
            } else {
              localCategoryProvider
                  .pressBarchasiButtonWhenCategorySelected(context);
              productsGridviewProvider.clearPathList();
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            floatingActionButtonLocation:
                FloatingActionButtonLocation.startFloat,
            floatingActionButton:
                Pref.getBool(PrefKeys.isDevAlice, false) && kDebugMode
                    ? FloatingActionButton(
                        focusNode: FocusNode(skipTraversal: true),
                        heroTag: null,
                        backgroundColor: Theme.of(context).primaryColor,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlicePincodePage(),
                          );
                        },
                        child: const Icon(
                          Icons.http_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      )
                    : const SizedBox(),
            appBar: AppBar(
              titleSpacing: 0.0,
              elevation: 2,
              toolbarHeight: SizeConfig.v * 9.2,
              backgroundColor: Theme.of(context).colorScheme.background,
              leadingWidth: SizeConfig.h * 13,
              leading: Row(
                children: [
                  SizedBox(width: SizeConfig.h),
                  const SyncButtonHome(),
                ],
              ),
              title: const ClientsPart(),
              actions: [
                TextButton(
                  focusNode: FocusNode(skipTraversal: true),
                  onPressed: () async {
                    final orderingProvider =
                        Provider.of<OrderingProvider4>(context, listen: false);
                    final pageContext = context;
                    // setState(() {
                    //   isInvoiceDialogOpen = true;
                    // });
                    blBlocc.add(BlVisibilityChangedEvent(false));

                    await showDialog(
                      context: context,
                      builder: (dialogContext) => BlocProvider.value(
                        value: BlocProvider.of<InvoiceBloc>(context),
                        child: InvoiceSearchDialog(
                          onSearch: (invoiceId) {
                            orderingProvider.loadInvoiceByBarcodeWithBloc(
                              barcode: invoiceId,
                              context: pageContext,
                            );
                          },
                        ),
                      ),
                    );
                    blBlocc.add(BlVisibilityChangedEvent(true));
                    // setState(() {
                    //   isInvoiceDialogOpen = false;
                    // });
                  },
                  style: TextButton.styleFrom(
                    fixedSize: Size(SizeConfig.h * 2, SizeConfig.v * 2),
                    elevation: 0,
                    foregroundColor: Theme.of(context).colorScheme.background,
                  ),
                  child: ImageIcon(
                    AssetImage("assets/images/invoice.png"),
                    size: SizeConfig.v * 3.2,
                    color: Theme.of(context).canvasColor,
                  ),
                ),
                  SizedBox(width: SizeConfig.h),
           
                SearchButtons(
                  context,
                  onLockButtonPressed: () {
                    accessBloc.add(AccessSwitchToAccessEvent());
                    AppNavigation.pushAndRemoveUntil(const AccessLevelPage());
                  },
                ),
                TextButton(
                  focusNode: FocusNode(skipTraversal: true),
                  onPressed: () => AppNavigation.push(const ChecksPage()),
                  style: TextButton.styleFrom(
                    fixedSize: Size(SizeConfig.h * 2, SizeConfig.v * 2),
                    elevation: 0,
                    foregroundColor: Theme.of(context).colorScheme.background,
                  ),
                  child: Icon(
                    Icons.insert_drive_file,
                    size: SizeConfig.v * 3.2,
                    color: Theme.of(context).canvasColor,
                  ),
                ),
                VisibilityDetector(
                  onVisibilityChanged: (VisibilityInfo info) {
                    if (info.visibleFraction > 0) {
                      blBlocc.add(
                        BlStatusChangedEvent(
                          status: BLStatus.home,
                          where:
                              "lib/features/home/home_page.dart visibilityDetector",
                        ),
                      );
                    }
                    blBlocc.add(BlVisibilityChangedEvent(true));
                  },
                  key: const Key('home_app_bar_visibility_detector_key'),
                  child: MyBarcodeListener(
                    onBarcodeScannedClick: (v) {},
                    onBarcodeScannedPayme: (v) {},
                    onShiftDeletePressed: () async {
                      if (blBlocc.isVisible) {
                        // ignore: unused_local_variable
                        bool result = Provider.of<OrderingProvider4>(
                          context,
                          listen: false,
                        ).cancelOrdering(deleteTicketAccess);
                        if (!result) {
                          blBlocc.add(
                            BlStatusChangedEvent(
                              status: BLStatus.other,
                              where:
                                  "lib/features/home/home_page.dart shiftDelete",
                            ),
                          );
                          bool access = await showDialog(
                              barrierDismissible: false,
                              barrierColor: Colors.black.withOpacity(.5),
                              context: context,
                              builder: (context) => const NoAccessDialog());
                          blBlocc.add(BlStatusChangedEvent(
                              status: BLStatus.home,
                              where:
                                  "lib/features/home/home_page.dart sihftdelet"));
                          if (access) {
                            // ignore: use_build_context_synchronously
                            Provider.of<OrderingProvider4>(context,
                                    listen: false)
                                .cancelOrdering(access);
                          }
                        }
                      }
                    },
                    onBarcodeScannedMagnetic: (v) {},
                    onDelPressed: () async {
                      if (blBlocc.isVisible) {
                        bool result = Provider.of<OrderingProvider4>(
                          context,
                          listen: false,
                        ).cancelOrdering(deleteTicketAccess);
                        if (!result) {
                          blBlocc.add(BlStatusChangedEvent(
                            status: BLStatus.other,
                            where: "lib/features/home/home_page.dart backspace",
                          ));
                          bool access = await showDialog(
                            barrierDismissible: false,
                            barrierColor: Colors.black.withValues(alpha: .5),
                            context: context,
                            builder: (context) => const NoAccessDialog(),
                          );
                          blBlocc.add(BlStatusChangedEvent(
                            status: BLStatus.home,
                            where: "lib/features/home/home_page.dart backspace",
                          ));
                          if (access) {
                            // ignore: use_build_context_synchronously
                            Provider.of<OrderingProvider4>(context, listen: false)
                                .cancelOrdering(access);
                          }
                        }
                      }
                    },
                    onF12Pressed: () async {},
                    onF5pressed: () {
                      if (Pref.getBool(PrefKeys.withOFD, false) == false) {
                        Provider.of<OrderingProvider4>(context, listen: false)
                            .goToPaymentPage(context);
                      }
                    },
                    key: const Key("Home Page Scanner"),
                    onF1pressed: () async {},
                    onF2pressed: () {},
                    onF3pressed: () {},
                    onBarcodeScanned: (String barcode) {
                      Log.d(barcode, name: "HomePage");
                      Provider.of<OrderingProvider4>(context, listen: false)
                          .onBarcodeScanned(barcode, _scaffoldKey);
                    },
                    bufferDuration: const Duration(milliseconds: 300),
                    onDownPressed: () {},
                    onUpPressed: () {},
                    onBarcodeScannedClient: (s) {},
                    child: AppBarDrawerButton(
                      onPress: () => _scaffoldKey.currentState!.openEndDrawer(),
                      color: isReturnState
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.background,
                    ),
                  ),
                )
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.background,
            key: _scaffoldKey,
            endDrawer: MyDrawer(scaffoldKey: _scaffoldKey),
            body: BuildContentOfHomePage(
              leftFlex: leftFlex,
              rightFlex: rightFlex,
              scaffoldKey: _scaffoldKey,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    Log.d('dispose method was worked', name: 'HomePage');
  }

  Widget _bg(Widget child) {
    return Expanded(
      flex: 5,
      child: Container(
        height: double.infinity,
        width: double.infinity,
        color: Theme.of(context).dialogBackgroundColor,
        child: child,
      ),
    );
  }
}
