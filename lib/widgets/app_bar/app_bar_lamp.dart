import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/bloc/network/network_bloc.dart';
import 'package:invan2/utils/utils.dart';

import '../../changes/services/web_socket_service/web_socket_options/bloc/connect_bloc.dart';

class AppBarLamp extends StatefulWidget {
  bool? min;
  bool? isWebsocket;

  AppBarLamp({
    Key? key,
    this.min,
    this.isWebsocket,
  }) : super(key: key);

  @override
  State<AppBarLamp> createState() => _AppBarLampState();
}

class _AppBarLampState extends State<AppBarLamp> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: _lamp(context),
    );
  }

  Row _lamp(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        widget.isWebsocket != null && widget.isWebsocket!
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BlocBuilder<ConnectBloc, ConnectState>(
                    builder: (context, state) {
                      return InkWell(
                        onTap: () =>
                            context.read<ConnectBloc>().add(ConnectRequestEvent(
                                  context,
                                  mounted,
                                  () {
                                    context
                                        .read<ConnectBloc>()
                                        .add(DisconnectEvent());
                                  },
                                )),
                        child: Container(
                          width: SizeConfig.v *
                              (widget.min != null && widget.min! ? 1.8 : 2.53),
                          height: SizeConfig.v *
                              (widget.min != null && widget.min! ? 1.8 : 2.53),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: state is ConnectSuccessState
                                ? Colors.deepPurple
                                : Colors.orange,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                ],
              )
            : const SizedBox.shrink(),
        BlocBuilder<NetworkBloc, NetworkState>(
          builder: (context, state) {
            return Container(
              width: SizeConfig.v *
                  (widget.min != null && widget.min! ? 1.8 : 2.53),
              height: SizeConfig.v *
                  (widget.min != null && widget.min! ? 1.8 : 2.53),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state is NetworkSuccess
                    ? const Color(0xff00ff00)
                    : Colors.red,
              ),
            );
          },
        ),
      ],
    );
  }
}
