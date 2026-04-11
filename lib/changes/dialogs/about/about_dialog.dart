import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

import '../../services/app_constants.dart';

// ignore: must_be_immutable
class AboutAppDialog extends StatelessWidget {
  AboutAppDialog({
    Key? key,
  }) : super(key: key);
  TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.v),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      content: Container(
        width: SizeConfig.h * 37,
        height: SizeConfig.v * 60,
        padding: EdgeInsets.all(SizeConfig.v * 2.5),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "О программе Invan Soft",
                    textAlign: TextAlign.center,
                    style: MyThemes.txtStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.v * 2),
              Text(
                """Invan Soft — это универсальная платформа,
          которая позволяет ритейлерам и ресторанам в
          Центральной Азии автоматизировать и
          развивать свой бизнес.
          
          Наша платформа предоставляет экосистему
          решений, начиная от облачной POS-системы и
          заканчивая заказом столов на основе QR,
          лояльностью, привлечением клиентов и
          многим другим.""",
                style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
              ),
              SizedBox(height: SizeConfig.v * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    """Программное обеспечение виртуальной
          кассы «INVAN POS»  (версия ${AppConstants.version}).
          ООО "Invan Soft", Республика Узбекистан""",
                    style: MyThemes.txtStyle(
                      // fontStyle: FontStyle.italic,
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                
                ],
              ),
              SizedBox(height: SizeConfig.v * 5),
              Text(
                "Контакты: +998994364615",
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
