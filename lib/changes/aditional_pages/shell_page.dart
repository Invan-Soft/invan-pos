import 'package:flutter/material.dart';
import 'package:shell/shell.dart';
// ignore: depend_on_referenced_packages
import 'package:file/local.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({Key? key}) : super(key: key);

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  String _result = '';
  final fss = const LocalFileSystem();
  final shell = Shell();
  @override
  Widget build(BuildContext context) {
    // _readFile();
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_result),
              _setButton(
                'LS',
                command: 'ls',
                arguments: [],
              ),
              const SizedBox(height: 10),
              _setButton(
                'NODE',
                command: 'node',
                arguments: ['../../../Node/examples/memory.js'],
              ),
              const SizedBox(height: 10),
              _setButton(
                'PWD',
                command: 'pwd',
                arguments: [],
              ),
              const SizedBox(height: 10),
              _setButton('DART RUN', command: 'dart', arguments: [
                'run',
                '.\\shelltestmy\\bin\\shelltestmy.dart',
              ]),
              const SizedBox(height: 10),
              _setButton('DART',
                  command: 'dart', arguments: ["create", 'shelltestmy']),
              const SizedBox(height: 10),
              _setButton("PURCHASE",
                  command: 'C:/Arcus2/CommandLineTool/bin/CommandLineTool.exe',
                  arguments: ['/o1', '/a48000', '/c860']),
              const SizedBox(height: 10),
              _setButton('C++',
                  command: 'C:/Arcus2/CommandLineTool/bin/CommandLineTool.exe',
                  arguments: ["TEST_PING", '1', '-1']),
              const SizedBox(height: 10),
              _setButton('Mac Address', command: 'ipconfig', arguments: []),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  ElevatedButton _setButton(
    String label, {
    required String command,
    required List<String> arguments,
  }) =>
      ElevatedButton(
        child: Text(label),
        onPressed: () async {
          var result = await shell.startAndReadAsString(
            command,
            arguments: arguments,
          );

       

          setState(() => _result = result.toString());
        },
      );
}
