import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';

class BuildCheck extends StatelessWidget {
  const BuildCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: SizeConfig.h * 15),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: SizeConfig.h * 10,
              height: SizeConfig.v * 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:  BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight:  Radius.circular(6),
                ),
              ),
              child: Center(
                child: InkWell(
                  onTap: () {
                    // ClientSingleton8.storeClientsFromApi();
                  },
                  child: Text(
                    loc.chek,
                    style: MyThemes.txtStyle(fontSize: 3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
