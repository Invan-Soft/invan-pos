import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:invan2/changes/components/form_validator.dart';
import 'package:invan2/widgets/default_button.dart';
import 'package:invan2/widgets/inputs/app_text_field.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../utils/utils.dart';

class LocationEditHandleDialog extends StatefulWidget {
  const LocationEditHandleDialog({Key? key}) : super(key: key);

  @override
  State<LocationEditHandleDialog> createState() =>
      _LocationEditHandleDialogState();
}

class _LocationEditHandleDialogState extends State<LocationEditHandleDialog> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController latController = TextEditingController();
  final TextEditingController longController = TextEditingController();
  late bool locationSwitch;

  @override
  void initState() {
    super.initState();

    latController.text =
        Pref.getDouble(PrefKeys.latLocal, 41.311081).toString();
    longController.text =
        Pref.getDouble(PrefKeys.longLocal, 69.240562).toString();
  }

  @override
  Widget build(BuildContext context) {
    locationSwitch = Pref.getBool(PrefKeys.locationSwitch, false);

    return Card(
      shadowColor: Colors.white,
      // elevation: 3,
      color: Theme.of(context).colorScheme.background,
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).primaryColor,
            ),
            borderRadius: BorderRadius.circular(12)),
        height: MediaQuery.of(context).size.height * 0.7,
        width: 800,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.3,
                      color: Colors.white,
                      child: FlutterMap(
                        options: MapOptions(
                          maxZoom: 18,
                          onMapEvent: (position) {
                            latController.text =
                                (position.camera.center.latitude).toString();
                            longController.text =
                                (position.camera.center.longitude).toString();
                            setState(() {});
                          },
                          initialCenter: LatLng(
                            double.parse(latController.text != ""
                                ? latController.text
                                : "0"),
                            double.parse(longController.text != ""
                                ? longController.text
                                : "0"),
                          ),

                          // zoom: 12,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'in2.uz.invan2',
                            maxZoom: 18,
                            maxNativeZoom: 100,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.location_on_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    )
                  ],
                ),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.h * .5,
                    vertical: SizeConfig.v * 1,
                  ),
                  onTap: () {},
                  title: Padding(
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.v),
                    child: Text(
                      "Edit Location lat long value by handle.",
                      style: MyThemes.txtStyle(
                          fontSize: 2, color: Theme.of(context).canvasColor),
                    ),
                  ),
                  trailing: ClipRRect(
                    child: CupertinoSwitch(
                        value: locationSwitch,
                        onChanged: (v) {
                          Pref.setBool(PrefKeys.locationSwitch, v);
                          setState(() {});
                        }),
                  ),
                ),
                AppTextFormField(
                  enabled: locationSwitch,
                  controller: latController,
                  title: "Latitude ",
                  hint: "Enter Latitude",
                  validator: FormValidator.general,
                ),
                AppTextFormField(
                  enabled: locationSwitch,
                  controller: longController,
                  title: "Longitude ",
                  hint: "Enter Longitude ",
                  validator: FormValidator.general,
                ),
                DefaultButton(
                    text: 'Create',
                    isButtonEnabled: true,
                    onPress: () async {
                      await Pref.setDouble(
                        PrefKeys.latLocal,
                        double.parse(latController.text != ""
                            ? latController.text
                            : "0"),
                      );

                      await Pref.setDouble(
                        PrefKeys.longLocal,
                        double.parse(longController.text != ""
                            ? longController.text
                            : "0"),
                      );
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
