// import 'package:flutter/material.dart';
// import 'package:invan2/changes/providers/ordering_provider_4.dart';
// import 'package:invan2/utils/helpers/helpers.dart';
// import 'package:invan2/utils/themes.dart';
// import 'package:provider/provider.dart';
//
// class HumoCardButton extends StatefulWidget {
//   const HumoCardButton({Key? key}) : super(key: key);
//   @override
//   State<HumoCardButton> createState() => _HumoCardButtonState();
// }
//
// class _HumoCardButtonState extends State<HumoCardButton> {
//   @override
//   Widget build(BuildContext context) {
//     // bool isEnabled = Prefs.getBool(PrefKeys.isHumoEnabled, false);
//     // bool cardEnabled = Prefs.getBool(PrefKeys.cardEnabled, false);
//     return Padding(
//       padding: EdgeInsets.only(
//         bottom: SizeConfig.v * 1.78,
//       ),
//       child: SizedBox(
//         width: SizeConfig.h * 18.77,
//         height: SizeConfig.v * 9.68,
//         child: RawMaterialButton(
//           focusNode: FocusNode(skipTraversal: true),
//           disabledElevation: 0,
//           elevation: 0,
//           fillColor: Theme.of(context).dialogBackgroundColor,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(
//               SizeConfig.v * 1.1,
//             ),
//           ),
//           onPressed: () =>
//               Provider.of<OrderingProvider4>(context, listen: false)
//                   .typeHumo(context),
//           child: Text(
//             "HUMO",
//             style: MyThemes.txtStyle(
//               fontWeight: FontWeight.w700,
//               color: Theme.of(context).canvasColor,
//               fontSize: 3,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
