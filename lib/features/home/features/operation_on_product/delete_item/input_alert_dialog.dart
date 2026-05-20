/*
    @author Suxrob Sattorov, 12/9/2024, 12:10 PM
*/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../../app_navigation.dart';
import '../../../../../utils/utils.dart';
import '../../../../features.dart';
import '../../../../hive_repository/hive_boxes.dart';
import '../../../bloc/barcode_listener_bloc/bl_bloc.dart';

class InputAlertDialog extends StatefulWidget {
  final ValueChanged<Employee> onValueEntered;
  final VoidCallback? onUniversalPinEntered;

  const InputAlertDialog(
      {super.key, required this.onValueEntered, this.onUniversalPinEntered});

  @override
  State<InputAlertDialog> createState() => _InputAlertDialogState();
}

class _InputAlertDialogState extends State<InputAlertDialog> {
  late TextEditingController controller = TextEditingController();

  // late BlBloc blBloc;

  @override
  Widget build(BuildContext context) {
    // blBloc = BlocProvider.of(context, listen: false);
    // blBloc.add(BlStatusChangedEvent(
    //     status: BLStatus.magneticStripe,
    //     where:
    //         "lib/features/lock/lock/view/lock_buttons_with_shortcuts.dart build"));
    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        width: SizeConfig.h * 38.96,
        height: SizeConfig.v * 42.18,
        decoration: BoxDecoration(
          color: Pref.getBool(PrefKeys.isDarkMode, true)
              ? Theme.of(context).dialogBackgroundColor
              : MyThemes.lightGreyColorr,
          borderRadius: BorderRadius.circular(
            SizeConfig.v * 1.1,
          ),
        ),
        child: VisibilityDetector(
          onVisibilityChanged: (VisibilityInfo v) {
            // blBloc.add(BlVisibilityChangedEvent(v.visibleFraction > 0));
          },
          key: const Key('magnetic_stripe_listener'),
          child: MyBarcodeListener(
            bufferDuration: const Duration(milliseconds: 300),
            onBarcodeScannedMagnetic: (value) {
              if (value.length > 5) {
                controller.text = value.substring(0, 5);
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
                value = value.substring(0, 5);
              }

              if (value.length == 4 || value.length == 5) {
                List<Employee> employeeList =
                    HiveBoxes.getEmployees().values.toList().cast<Employee>();
                Employee? employee;

                if (value == "4615@") {
                  employee = HiveBoxes.getCurrentEmployee;
                  if (employee != null) {
                    widget.onValueEntered(employee);
                    return;
                  } else {
                    return;
                  }
                }

                for (Employee e in employeeList) {
                  if (e.user?.passCode == value) {
                    employee = e;
                    break;
                  }
                }

                if (employee != null) {
                  if (employee.access?.deletePrice == true || value == '4615') {
                    widget.onValueEntered(employee);
                  } else {}
                } else {
                  // Noto'g'ri PIN
                  setState(() {
                    controller.clear();
                  });
                }
              }
            },
            onBarcodeScanned: (value) {},
            onBarcodeScannedClick: (v) {},
            onBarcodeScannedPayme: (v) {},
            onDelPressed: () {},
            onF12Pressed: () {},
            onF5pressed: () {},
            onShiftDeletePressed: () {},
            onF1pressed: () {},
            onF2pressed: () {},
            onF3pressed: () {},
            onDownPressed: () {},
            onUpPressed: () {},
            onBarcodeScannedClient: (s) {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Pin Code Scan',
                        style: MyThemes.txtStyle(
                          color: Theme.of(context).canvasColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.h * 4),
                      child: TextField(
                        controller: controller,
                        maxLength: 5,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        autofocus: true,
                        decoration: InputDecoration(
                          suffix: InkWell(
                            onTap: () {
                              setState(() {
                                controller = TextEditingController();
                              });
                            },
                            child: const Icon(
                              Icons.clear,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 20),
                        ),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          if (value.length > 5) {
                            controller.text = value.substring(0, 5);
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                            value = value.substring(0, 5);
                          }

                          if (value.length == 4 || value.length == 5) {
                            if (value == "4615@") {
                              Employee? employee = HiveBoxes.getCurrentEmployee;
                              if (employee != null) {
                                widget.onValueEntered(employee);
                                return;
                              } else {
                                return;
                              }
                            }

                            List<Employee> employeeList =
                                HiveBoxes.getEmployees()
                                    .values
                                    .toList()
                                    .cast<Employee>();
                            Employee? employee;

                            for (Employee e in employeeList) {
                              if (e.user?.passCode == value) {
                                employee = e;
                                break;
                              }
                            }

                            if (employee != null) {
                              if (employee.access?.deletePrice == true) {
                                widget.onValueEntered(employee);
                              } else {}
                            } else {
                              setState(() {
                                controller.clear();
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
