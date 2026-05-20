import 'package:flutter/material.dart';

class ClientScreen extends StatelessWidget {
  const ClientScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        focusNode: FocusNode(skipTraversal: true),
        onPressed: () async {},
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [],
      ),
    );
  }
}
