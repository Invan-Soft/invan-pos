import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/bloc/client_search/client_search_bloc.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/inputs/app_text_field.dart';
import 'package:provider/provider.dart';
import '../../../features/features.dart';
import '../../../features/hive_repository/hive_boxes.dart';
import '../../../features/home/features/home_orders/calculation_part/total_price_dialog/bloc/tp_bloc.dart';
import '../../../widgets/my_snackbar.dart';
import '../../components/form_validator.dart';
import '../../providers/ordering_provider_4.dart';
import 'bloc/get_mxik_from_soliq_bloc.dart';
import 'model/created_product_model.dart';
import 'model/from_soliq_model.dart';
import 'model/mes_vat_unit_model/mes_unit.dart';

class CreateProductDialog extends StatefulWidget {
  final String barcode;

  const CreateProductDialog({
    super.key,
    required this.barcode,
  });

  @override
  State<CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<CreateProductDialog> {
  bool isWaiting = false;
  bool isOkButtonPressed = false;
  late ClientBloc clientBloc;
  late TpBloc tpBloc;
  List<Packages> packages = [];
  List<MesUnitModel> mesUnits = [];
  List<VatUnitModel> vatUnits = [];

  Packages selectedPackage = Packages(code: 0, nameUz: "Select Package code");
  MesUnitModel selectedMes = MesUnitModel(id: "", longName: "Select Unit type");
  VatUnitModel selectedVat =
      VatUnitModel(id: "", name: "Select Vat type", percentage: 0);
  TextEditingController nameCon = TextEditingController();
  TextEditingController barcodeCon = TextEditingController();
  TextEditingController mxikCon = TextEditingController();
  TextEditingController priceCon = TextEditingController();
  TextEditingController valueCon = TextEditingController();

  @override
  void initState() {
    clientBloc = BlocProvider.of(context, listen: false);
    if (widget.barcode != "") {
      barcodeCon.text = widget.barcode;
      BlocProvider.of<GetMxikFromSoliqBloc>(
        context,
      ).add(GetFromSoliq(barcode: barcodeCon.text));
    }
    final Box<VatUnitModel> vatUnitModel = HiveBoxes.vatUnitBox();
    vatUnits = vatUnitModel.values.toList();
    final Box<MesUnitModel> mesModel = HiveBoxes.mesUnitBox();
    mesUnits = mesModel.values.toList();
    if (vatUnits.isNotEmpty) {
      selectedVat = vatUnits.where((x) => x.isDefault == true).toList().first;
    }
    if (mesUnits.isNotEmpty) {
      selectedMes = mesUnits.first;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        width: SizeConfig.h * 45,
        height: SizeConfig.v * 55,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: MyThemes.textWhiteColor,
              blurRadius: 3,
            ),
          ],
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(
            SizeConfig.v * 1.1,
          ),
        ),
        child: BlocConsumer<GetMxikFromSoliqBloc, GetMxikFromSoliqState>(
          listener: (context, state) {
            if (state is CreatToInvan2SuccesState) {
              Provider.of<OrderingProvider4>(context, listen: false)
                  .pressAllPath();

              for (int i = 0; i < state.value; i++) {
                Provider.of<OrderingProvider4>(context, listen: false)
                    .addProduct(
                        context: context,
                        value: 1,
                        product: state.item,
                        where: "SEARCH LIST ITEM / ");
              }

              AppNavigation.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                mySnackBar(context, msg: "Succes"),
              );
            }
            if (state is GetMxikFromSoliqSuccesState) {
              nameCon.text = (state.fromSoliq.name ?? "").split(": ").last;
              barcodeCon.text = state.fromSoliq.internalCode ?? "";
              mxikCon.text = state.fromSoliq.mxik ?? "";
              packages = state.fromSoliq.packages ?? [];
            }
          },
          builder: (context, state) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.v * 2,
                  horizontal: SizeConfig.v * 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextFormField(
                      controller: nameCon,
                      autofocus: true,
                      title: "Наименование товара",
                      hint: "Наименование товара",
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 50,
                          child: AppTextFormField(
                            title: "Штрих-код",
                            autofocus: true,
                            controller: barcodeCon,
                            hint: "Штрих-код",
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: state is GetMxikFromSoliqProccesState
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ],
                                )
                              : IconButton(
                                  onPressed: () {
                                    BlocProvider.of<GetMxikFromSoliqBloc>(
                                      context,
                                    ).add(
                                        GetFromSoliq(barcode: barcodeCon.text));
                                  },
                                  icon: Icon(
                                    Icons.get_app_rounded,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Выберите тип продукта",
                                style: TextStyle(
                                    color: Theme.of(context).canvasColor),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(SizeConfig.v),
                                child: PopupMenuButton(
                                  padding: const EdgeInsets.all(5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(SizeConfig.v),
                                  ),
                                  tooltip: '',
                                  child: Container(
                                    color:
                                        Theme.of(context).dialogBackgroundColor,
                                    width: double.infinity,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: SizeConfig.v,
                                          vertical: SizeConfig.h * 0.8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            selectedMes.longName ?? "",
                                            style: MyThemes.txtStyle(
                                                fontSize: 1.8,
                                                color: Theme.of(context)
                                                    .canvasColor),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down_sharp,
                                            color:
                                                Theme.of(context).canvasColor,
                                            size: SizeConfig.v * 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  onSelected: (mes) {
                                    selectedMes = mes;
                                    setState(() {});
                                  },
                                  itemBuilder: (_) {
                                    return mesUnits.map(
                                      (e) {
                                        return PopupMenuItem(
                                          value: e,
                                          child: SizedBox(
                                            width: SizeConfig.h * 30,
                                            child: Column(
                                              children: [
                                                Text(
                                                  e.longName.toString(),
                                                  style: MyThemes.txtStyle(
                                                      fontSize: 2,
                                                      color: Theme.of(context)
                                                          .canvasColor),
                                                ),
                                                Divider(
                                                  height: 1,
                                                  color: Theme.of(context)
                                                      .canvasColor,
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ).toList();
                                  },
                                ),
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                        SizedBox(width: SizeConfig.h),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Выберите тип НДС",
                                style: TextStyle(
                                    color: Theme.of(context).canvasColor),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(SizeConfig.v),
                                child: PopupMenuButton(
                                  padding: const EdgeInsets.all(5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(SizeConfig.v),
                                  ),
                                  tooltip: '',
                                  child: Container(
                                    color:
                                        Theme.of(context).dialogBackgroundColor,
                                    width: double.infinity,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: SizeConfig.v,
                                          vertical: SizeConfig.h * 0.8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "${selectedVat.name} ${selectedVat.percentage}%",
                                            style: MyThemes.txtStyle(
                                                fontSize: 1.8,
                                                color: Theme.of(context)
                                                    .canvasColor),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down_sharp,
                                            color:
                                                Theme.of(context).canvasColor,
                                            size: SizeConfig.v * 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  onSelected: (vat) {
                                    selectedVat = vat;
                                    setState(() {});
                                  },
                                  itemBuilder: (_) {
                                    return vatUnits.map(
                                      (e) {
                                        return PopupMenuItem(
                                          value: e,
                                          child: SizedBox(
                                            width: SizeConfig.h * 30,
                                            child: Column(
                                              children: [
                                                Text(
                                                  e.name.toString(),
                                                  style: MyThemes.txtStyle(
                                                      fontSize: 2,
                                                      color: Theme.of(context)
                                                          .canvasColor),
                                                ),
                                                Divider(
                                                  height: 1,
                                                  color: Theme.of(context)
                                                      .canvasColor,
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ).toList();
                                  },
                                ),
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextFormField(
                            title: "Цена",
                            autofocus: true,
                            hint: "Цена",
                            controller: priceCon,
                            formatters: [FormValidator.price],
                          ),
                        ),
                        SizedBox(
                          width: SizeConfig.h,
                        ),
                        Expanded(
                          child: AppTextFormField(
                            title: "Количество",
                            hint: "Количество",
                            controller: valueCon,
                            formatters: [
                              selectedMes.shortName == 'шт'
                                  ? FormValidator.shtuka
                                  : FormValidator.kg
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.h * 0.8),
                    MaterialButton(
                      focusNode: FocusNode(skipTraversal: true),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(SizeConfig.v)),
                      color: Theme.of(context).primaryColor,
                      disabledColor:
                          Theme.of(context).primaryColor.withOpacity(.5),
                      minWidth: double.infinity,
                      height: SizeConfig.v * 6,
                      textColor: Colors.white,
                      disabledTextColor: Colors.white.withOpacity(.8),
                      child: state is CreatToInvan2ProccesState
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              loc.saqlash,
                              style: MyThemes.txtStyle(
                                  fontSize: 2.2, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                      onPressed: () {
                        CreatProductToInvanModel item =
                            CreatProductToInvanModel(
                          barcode: [barcodeCon.text],
                          description: "",
                          isActive: true,
                          isMarking: false,
                          mxikCode: mxikCon.text,
                          name: nameCon.text,
                          packageCode: selectedPackage.code.toString(),
                          packageName: selectedPackage.nameUz,
                          packageType: selectedPackage.packageType,
                          productTypeId: "8b0bf29c-58e8-4310-8bb1-a1b9771f9c47",
                          shopPrices: [
                            ShopPricesToInvan2Model(
                              maxPrice: 0,
                              minPrice: 0,
                              retailPrice: double.parse(
                                priceCon.text.replaceAll(',', ''),
                              ),
                              shopId: Pref.getString(PrefKeys.storeId, ""),
                              supplyPrice: 0,
                              wholeSalePrice: 0,
                              shopPriceTiers: [
                                ShopPriceTiers(
                                  minQuantity: 1,
                                  retailPrice: double.parse(
                                    priceCon.text.replaceAll(',', ''),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          sku: "",
                          brandId: "",
                          categoryId: "",
                          categoryIds: [],
                          customFields: [],
                          images: [],
                          measurementUnitId: selectedMes.id,
                          measurementValues: [
                            MeasurementValuesToInvan2Model(
                              amount: 0,
                              hasTrigger: true,
                              isAvailable: true,
                              smallLeft: 0,
                              title: "",
                              shopId: Pref.getString(PrefKeys.storeId, ""),
                            ),
                          ],
                          noLoyalty: false,
                          tags: [],
                          vatId: selectedVat.id,
                        );
                        if (selectedVat.id != null &&
                            selectedVat.id!.isNotEmpty) {
                          BlocProvider.of<GetMxikFromSoliqBloc>(
                            context,
                          ).add(
                            CreatToInvan2Event(
                              item: item,
                              value: double.parse(valueCon.text),
                            ),
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
