import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/payment/right/dilogs/transfer/search_driver.dart';
import 'package:invan2/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../features/features.dart';
import '../../../../features/payment/right/dilogs/transfer/set_driver/set_driver_bloc.dart';

class SelectEmplyeeWithPassDialog extends StatefulWidget {
  const SelectEmplyeeWithPassDialog({super.key});

  @override
  State<SelectEmplyeeWithPassDialog> createState() => _DriverSelectState();
}

class _DriverSelectState extends State<SelectEmplyeeWithPassDialog> {
  String searchController = "";

  @override
  Widget build(BuildContext context) {
    List<Employee> employee = [];
    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: VisibilityDetector(
        onVisibilityChanged: (VisibilityInfo info) {},
        key: const Key('SearchEmployeePage'),
        child: RawKeyboardListener(
          key: const Key("SearchEmployeePage"),
          focusNode: FocusNode(),
          autofocus: false,
          onKey: (event) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (employee.length == 1) {
                BlocProvider.of<SetDriverBloc>(context).add(SetStartDriverName(
                  employee.first.user?.firstName ?? "",
                  employee.first.user?.passCode?.toString() ?? '',
                ));
                Navigator.pop(context);
              }
            }
          },
          child: Container(
            height: SizeConfig.v * 44,
            width: SizeConfig.h * 45,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).canvasColor,
                  blurRadius: 5,
                ),
              ],
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(
                SizeConfig.v,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.blue,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: "Поиск",
                      hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                      contentPadding: EdgeInsets.all(10.0),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF2B5278),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      searchController = value;
                    },
                  ),
                ),
                SizedBox(
                  height: SizeConfig.v * 35,
                  child: FutureBuilder<List<Employee>>(
                    initialData: [].cast<Employee>(),
                    future: SearchWithPasswordClass.searchPassword(
                        searchController),
                    builder: (context, AsyncSnapshot<List<Employee>> snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {}
                      employee = snapshot.requireData;
                      return SearchDriver(
                        employee: employee,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
