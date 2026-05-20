import 'package:flutter/material.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import '../features/hive_repository/tiin/singletons/api/receipt/model/receipt_model_8.dart';

// ignore: must_be_immutable
class ReceiptsScreenMy18 extends StatelessWidget {
   ReceiptsScreenMy18({Key? key}) : super(key: key);
  List<ReceiptModel8> v = MyObjectbox.saleStore.box<ReceiptModel8>().getAll();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ListView.separated(
          padding:const EdgeInsets.only(right: 200.0),
          reverse: true,
          itemBuilder: (_, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(" $__"),
                Text("client  =>  ${v[__].client}"),
                Text("createdDate  =>  ${v[__].createdDate}"),
                Text("name  =>  ${v[__].name}"),
                Text("cashback  =>  ${v[__].cashback}"),
                Text("id  =>  ${v[__].id}"),
                Text("type  =>  ${v[__].type}"),
                Text("uploaded  =>  ${v[__].uploaded}"),
                ExpansionTile(title: const Text("Items"), children: [
                  ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (_, i) {
                      List<ReceiptModelItem8> vv = v[__].items;
                      return Column(
                        children: [
                          Text("name  =>  ${vv[i].name}"),
                          Text("id  =>  ${vv[i].id}"),
                          Text("pricePosition  =>  ${vv[i].pricePosition}"),
                          Text("qty  =>  ${vv[i].qty}"),
                          Text("sku  =>  ${vv[i].sku}"),
                          Text("value  =>  ${vv[i].value}"),
                        ],
                      );
                    },
                    separatorBuilder: (context, i) {
                      return const Divider(
                        color: Colors.amber,
                        thickness: 3,
                      );
                    },
                    itemCount:v[__].items.length,
                  )
                ])
              ],
            );
          },
          separatorBuilder: (context, index) {
            return const Divider(
              color: Colors.cyan,
              thickness: 3,
            );
          },
          itemCount: v.length,
        ),
      ),
    );
  }
}
