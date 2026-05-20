import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import 'six_clients_add_button.dart';
import 'six_clients_button.dart';

class ClientsPart extends StatefulWidget {
  const ClientsPart({super.key});

  @override
  ClientsPartState createState() => ClientsPartState();
}

class ClientsPartState extends State<ClientsPart> {
  final ScrollController _controller = ScrollController();
  @override
  Widget build(BuildContext context) {
    final orderingProvider = Provider.of<OrderingProvider4>(context);
    final sixClient4List = orderingProvider.getSixClient4List;
    final selectedClientIndex = orderingProvider.getSelectedIndex;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h),
      height: SizeConfig.v * 7.5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          sixClient4List.isEmpty
              ? const SizedBox(width: 0, height: 0)
              : ListView.builder(
                itemCount: sixClient4List.length,
                shrinkWrap: true,
                controller: _controller,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final client = sixClient4List[index];
                  return SixClientsButton(
                    isSelected: selectedClientIndex == index,
                    clientNumber: client.clientNumber,
                    onPressed: () {
                      orderingProvider.selectClient(index);
                    },
                  );
                },
              ),
          Center(
            child: orderingProvider.getSixClient4List.length > 3
                ? const SizedBox(width: 0, height: 0)
                : SixClientsAddButton(
                    color: orderingProvider.getSixClient4List.isNotEmpty
                        ? Theme.of(context).dialogBackgroundColor
                        : Theme.of(context).primaryColor,
                    onPressed: () {
                      orderingProvider.addClient();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
