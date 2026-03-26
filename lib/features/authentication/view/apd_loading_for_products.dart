// ignore_for_file: must_be_immutable

/*
    @author Suxrob Sattorov, 11/6/2024, 3:07 PM
*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../utils/utils.dart';

class ApdLoadingForProducts extends StatefulWidget {
  int length;
  int total;

  ApdLoadingForProducts({super.key, required this.length, required this.total});

  @override
  State<ApdLoadingForProducts> createState() => _ApdLoadingForProductsState();
}

class _ApdLoadingForProductsState extends State<ApdLoadingForProducts> {
  double progress = 0.0;
  double oldProgress = 0.0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 300), (Timer timer) {
      if (mounted) {
        setState(() {
          if (progress < 1.0) {
            if (widget.length / widget.total > oldProgress) {
              progress = widget.length / widget.total;
              oldProgress = progress;
            }
            progress = progress.clamp(0.0, 1.0);
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${(progress * 100).toStringAsFixed(0)}%",
            style: const TextStyle(
              fontSize: 40.0,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          LinearPercentIndicator(
            barRadius: const Radius.circular(20),
            width: MediaQuery.of(context).size.width * 0.4 - 15,
            lineHeight: 20.0,
            percent: progress,
            progressColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.blue.shade100,
            linearStrokeCap: LinearStrokeCap.roundAll,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
