import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/payment/right/dilogs/transfer/set_driver/set_driver_bloc.dart';

import '../../../../get_employees/model/employees_find_response.dart';
import '../../../../hive_repository/hive_boxes.dart';

class SearchDriver extends StatelessWidget {
  final List<Employee> employee;
  final _scrollController = ScrollController();

  SearchDriver({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: employee.length,
      itemBuilder: ((context, index) {
        Employee onlyEmployee = employee[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 10, left: 10),
          child: ElevatedButton(
            onPressed: () {
              BlocProvider.of<SetDriverBloc>(context).add(SetStartDriverName(
                employee[index].user?.firstName ?? "",
                employee[index].user?.passCode.toString() ?? '',
              ));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    onlyEmployee.user?.firstName ?? "",
                    textAlign: TextAlign.left,
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class SearchClass {
  static List<Employee> box =
      HiveBoxes.getEmployees().values.toList().cast<Employee>();

  static Future<List<Employee>> searchEmployee(String query) async {
    query = query.trim().toLowerCase();
    return box.where((employee) {
      String name = employee.user?.firstName?.toString().toLowerCase() ?? '';
      return (name.contains(query));
    }).toList();
  }
}

class SearchWithPasswordClass {
  static List<Employee> box =
      HiveBoxes.getEmployees().values.toList().cast<Employee>();

  static Future<List<Employee>> searchPassword(String query) async {
    query = query.trim().toLowerCase();

    return box.where((employee) {
      String password = employee.user?.passCode?.toString().toLowerCase() ?? '';
      return (password.contains(query));
    }).toList();
  }
}
