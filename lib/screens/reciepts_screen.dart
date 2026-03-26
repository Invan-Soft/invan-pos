import 'package:flutter/material.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';

class ReceiptsScreenMyy extends StatelessWidget {
  ReceiptsScreenMyy({Key? key}) : super(key: key);
  final List<ReceiptModel4> v =
      MyObjectbox.saleStore.box<ReceiptModel4>().getAll();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ListView.separated(
          padding: const EdgeInsets.only(right: 200.0),
          reverse: true,
          itemBuilder: (_, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(" $__"),
                Text("cashierId  =>  ${v[__].cashierId}"),
                Text("cashierName  =>  ${v[__].cashierName}"),
                Text("clientId  =>  ${v[__].clientId}"),
                Text("clientName  =>  ${v[__].clientName}"),
                Text("posName  =>  ${v[__].posName}"),
                Text("receiptNo  =>  ${v[__].externalId}"),
                Text("receiptNo  =>  ${v[__].externalId}"),
                Text("returnForCheck  =>  ${v[__].returnForCheck}"),
                Text("cashback  =>  ${v[__].cashback}"),
                Text(
                    "date  =>  ${DateTime.fromMillisecondsSinceEpoch(v[__].date)}"),
                Text("id  =>  ${v[__].id}"),
                Text("isRefund  =>  ${v[__].isRefund}"),
                Text("payment  =>  ${v[__].payment}"),
                Text("sdacha  =>  ${v[__].sdacha}"),
                Text("totalPrice  =>  ${v[__].totalPrice}"),
                Text("uploaded  =>  ${v[__].uploaded}"),
                ExpansionTile(
                  title: const Text("Sold Items"),
                  children: List.generate(v[__].soldItemList.length, (i) {
                    List<ReceiptModelSoldItem4> vv = v[__].soldItemList;

                    return Column(
                      children: [
                        Text("productName  =>  ${vv[i].productName}"),
                        Text("discountPercent  =>  ${vv[i].discountPercent}"),
                        Text("price  =>  ${vv[i].price}"),
                        // Text("pricePosition" +
                        //     "  =>  " +
                        //     vv[i].pricePosition.toString()),
                        const Divider(
                          color: Colors.amber,
                        )
                      ],
                    );
                  }),
                )
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
