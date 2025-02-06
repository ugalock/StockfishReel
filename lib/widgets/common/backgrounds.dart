import 'package:flutter/material.dart';

BoxDecoration createBoxDecoration() {
  return const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.blue, Colors.black, Color.fromARGB(0, 0, 0, 0)],
      stops: [0.4, 0.7, 1.0],
    ),
  );
}
