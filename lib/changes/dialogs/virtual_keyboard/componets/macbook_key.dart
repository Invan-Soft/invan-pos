import 'package:flutter/material.dart';

class MacbookKey extends StatefulWidget {
  final double? width;
  final double? height;
  final Widget? child;
  final Alignment? alignment;
  final VoidCallback onPressed;
  final Color? color;

  const MacbookKey({
    Key? key,
    this.color,
    this.width,
    this.height,
    this.child,
    this.alignment,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<MacbookKey> createState() => _MacbookKeyState();
}

class _MacbookKeyState extends State<MacbookKey> {
  bool release = true;
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (v) {
        release = false;
        _checkWhile();
      },
      onPointerUp: (v) {
        release = true;
      },
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context).style.copyWith(color: Colors.white),
        child: Container(
          alignment: widget.alignment,
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: widget.color,
            gradient: widget.color == null
                ? const LinearGradient(
                    colors: [
                      Color(0xFF23272D),
                      Color(0xFF1C1B1E),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(5),
          ),
          child: widget.child,
        ),
      ),
    );
  }

  _checkWhile() async {
    setState(() {});
    widget.onPressed();
    await Future.delayed(const Duration(milliseconds: 400));
    if (release) {
      return;
    }
    while (!release && mounted) {
      widget.onPressed();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
