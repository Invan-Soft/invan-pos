import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/bloc/client_search/client_search_bloc.dart';
import 'package:invan2/changes/components/form_validator.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/payment/right/dilogs/add_client/bloc/addclient_bloc.dart';
import 'package:invan2/features/payment/right/dilogs/add_client/model/client_group.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/buttons/radio_button.dart';
import 'package:invan2/widgets/default_button.dart';
import 'package:invan2/widgets/inputs/app_text_field.dart';

import '../../../../../widgets/my_snackbar.dart';
import 'group_type_bloc/group_type_bloc.dart';

// ignore: must_be_immutable
class ClientCreateDialog extends StatefulWidget {
  const ClientCreateDialog({Key? key}) : super(key: key);

  @override
  State<ClientCreateDialog> createState() => _ClientCreateDialogState();
}

class _ClientCreateDialogState extends State<ClientCreateDialog> {
  GlobalKey<FormState> formKey = GlobalKey();
  TextEditingController nameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController cardNumberController = TextEditingController();
  String groupName = "No Selected";
  String groupId = "";
  List<ClientGroupType> groups = [];
  bool idf = true;
  late AppLocalizations loc;

  @override
  void initState() {
    BlocProvider.of<GroupTypeBloc>(context).add(
      GetGroupTypeEvent(),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ClientBloc clientBloc = BlocProvider.of(context);
    AddClientBloc addClientBloc = BlocProvider.of(context);
    phoneController.text = '+998';
    loc = AppLocalizations.of(context)!;
    return Card(
      shadowColor: Colors.white,
      elevation: 3,
      color: Theme
          .of(context)
          .colorScheme
          .background,
      child: SizedBox(
        height: 750,
        width: 800,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: BlocConsumer<AddClientBloc, AddClientState>(
            listener: (context, state) {
              if (state is AddclientInitial) {
                formKey = GlobalKey();
                nameController.dispose();
                lastnameController.dispose();
                phoneController.dispose();
                cardNumberController.dispose();
                nameController = TextEditingController();
                lastnameController = TextEditingController();
                phoneController = TextEditingController();
                cardNumberController = TextEditingController();
                phoneController.text = '+998';
              }
              if (state is AddClientSuccedState) {
                clientBloc.controller.text = state.number;
                clientBloc.add(ClientSearchEvent(false));

                ScaffoldMessenger.of(context).showSnackBar(
                  mySnackBar(context, msg: "Client Succesfully Created."),
                );
              }
            },
            builder: (context, state) {
              if (state is AddClientSuccedState) {
                return _bg([
                  Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: _setText(
                            loc.mijoz_qoshish_muvaffaqiyatli_amalga_oshirildi,
                            context),
                      )),
                  DefaultButton(
                    text: "Ok",
                    isButtonEnabled: true,
                    onPress: () => AppNavigation.pop(),
                  )
                ]);
              }
              if (state is AddClientFailedState) {
                return _bg([
                  _setText(loc.mijoz_qoshish_oxshamadi, context),
                  const Spacer(),
                  _setText("ERROR: ${state.result.getError}", context),
                  const Spacer(),
                  DefaultButton(
                    text: loc.qayta_urinish,
                    isButtonEnabled: true,
                    onPress: () =>
                        addClientBloc.add(
                          AddClientAddEvent(info: state.info),
                        ),
                  ),
                ]);
              }
              if (state is AddClientLoadingState) {
                return _bg([
                  // const Spacer(),
                  CupertinoActivityIndicator(
                    radius: SizeConfig.v * 2,
                  ),
                  SizedBox(height: SizeConfig.h * 2),
                  _setText(
                    state.message == "internet"
                        ? loc.internet_tekshirilmoqda
                        : loc.mijoz_qoshilmoqda,
                    context,
                  ),
                  // const Spacer(),
                ]);
              }
              if (state is AddClientNoInternetState) {
                return _bg([
                  Expanded(
                      child: Align(
                          alignment: Alignment.center,
                          child: _setText(loc.internet_yoq, context))),
                  DefaultButton(
                    text: loc.qayta_urinish,
                    isButtonEnabled: true,
                    onPress: () {
                      addClientBloc.add(
                        AddClientAddEvent(info: state.info),
                      );
                    },
                  )
                ]);
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        AppTextFormField(
                          controller: phoneController,
                          title: loc.telefonNomer,
                          hint: loc.xaridorning_telefon_raqamini_kiriting,
                          validator: FormValidator.phonee,
                          formatters: [FormValidator.phoneFormatter2],
                        ), // NAME FORM FIELD
                        AppTextFormField(
                          controller: nameController,
                          title: loc.ism,
                          hint: loc.xaridornig_ismini_kiriting,
                          validator: FormValidator.general,
                        ),
                      ],
                    ),
                  ),
                  AppTextFormField(
                    controller: lastnameController,
                    title: loc.familiya,
                    hint: loc.xaridorning_sharifini_kiriting,
                  ),
                  AppTextFormField(
                    controller: cardNumberController,
                    title: 'Card Id',
                    hint: 'Card Id',
                  ),
                  // Group
                  Text(
                    "Group",
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Theme
                        .of(context)
                        .canvasColor),
                  ),
                  const SizedBox(height: 10),
                  _groupType(),
                  //Gender
                  const SizedBox(height: 10),
                  Text(
                    "Gender",
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Theme
                        .of(context)
                        .canvasColor),
                  ),
                  StatefulBuilder(builder: (context, state) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: SizeConfig.v),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Theme
                                          .of(context)
                                          .dialogBackgroundColor,
                                      borderRadius: BorderRadius.circular(12)),
                                  height: SizeConfig.h * 3.3,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AppRadioButton(
                                        value: true,
                                        group: idf,
                                        onChanged: (v) =>
                                            state.call(() => idf = v!),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            height: SizeConfig.h * 3.3,
                            decoration: BoxDecoration(
                                color: Theme
                                    .of(context)
                                    .dialogBackgroundColor,
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppRadioButton(
                                  value: false,
                                  group: idf,
                                  onChanged: (v) => state.call(() => idf = v!),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // CREATE BUTTON
                  DefaultButton(
                    text: 'Create',
                    isButtonEnabled: true,
                    onPress: () {
                      _addClient(addClientBloc);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Padding _bg(List<Widget> v) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.h * 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: v,
      ),
    );
  }

  _addClient(AddClientBloc bloc,) {
    if (formKey.currentState?.validate() ?? false) {
      String name = nameController.text.trim();
      String lastName = lastnameController.text.trim();
      String cardNumber = cardNumberController.text.replaceAll(' ', '').trim();
      String phone = phoneController.text
          .replaceFirst('(', '')
          .replaceFirst(')', '')
          .replaceAll('-', '')
          .replaceAll(' ', '')
          .replaceAll('+998', '');

      phone = '998$phone';
      bloc.add(
        AddClientAddEvent(
          info: AddClientInfo(
            cardNumber: cardNumber,
            idf: idf,
            lastname: lastName,
            name: name,
            phone: phone,
            groupId: groupId,
          ),
        ),
      );
    }
  }

  _groupType() {
    return BlocConsumer<GroupTypeBloc, GroupTypeState>(
      listener: (context, state) {
        if (state is GroupTypeSuccesState) {
          groups = state.types;

          ClientGroupType e = state.defaultType;
          groupId = e.id ?? "";
          groupName = e.name ?? "";
          setState(() {});
        }
      },
      builder: (context, state) {
        return PopupMenuButton(
          color: Theme
              .of(context)
              .dialogBackgroundColor,
          padding: const EdgeInsets.all(5),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme
                .of(context)
                .primaryColor, width: 2),
            borderRadius: BorderRadius.circular(SizeConfig.v),
          ),
          // clipBehavior: Clip.antiAlias,
          tooltip: '',
          child: Container(
            height: SizeConfig.v * 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .dialogBackgroundColor,
              border: Border.all(color: Colors.transparent, width: 2),
              borderRadius: BorderRadius.circular(SizeConfig.v),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.v),
                  child: Text(
                    groupName,
                    style: TextStyle(
                      color: Theme
                          .of(context)
                          .canvasColor
                          .withOpacity(0.5),
                      fontWeight: FontWeight.w300,
                      fontSize: SizeConfig.v * 1.7,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                  size: SizeConfig.v * 5,
                ),
              ],
            ),
          ),
          onSelected: (type) {
            if (state is GroupTypeSuccesState) {
              ClientGroupType e = type as ClientGroupType;
              groupId = e.id ?? "";
              groupName = e.name ?? "";
              setState(() {});
            }
          },
          itemBuilder: (_) {
            if (groups.isNotEmpty) {
              return [
                ...groups.map(
                      (e) =>
                      PopupMenuItem(
                        value: e,
                        child: SizedBox(
                          width: SizeConfig.h * 30,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.name ?? "",
                                style: MyThemes.txtStyle(
                                  fontSize: 2,
                                  color: Theme
                                      .of(context)
                                      .canvasColor
                                      .withOpacity(0.5),
                                ),
                              ),
                              Text(
                                '',
                                style: MyThemes.txtStyle(
                                  fontSize: 2,
                                  color: Theme
                                      .of(context)
                                      .canvasColor
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                )
              ];
            } else {
              return [
                const PopupMenuItem(
                  child: CircularProgressIndicator(),
                ),
              ];
            }
          },
        );
      },
    );
  }

  Text _setText(String v, BuildContext context) {
    return Text(
      v,
      textAlign: TextAlign.center,
      style: MyThemes.txtStyle(color: Theme
          .of(context)
          .canvasColor),
    );
  }
}
