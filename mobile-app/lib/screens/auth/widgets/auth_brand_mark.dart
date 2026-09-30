import 'package:flutter/material.dart';

/// The QSPOT mark, centred. The asset carries ~20% transparent margin on
/// each side, so [size] is the box, not the visible mark.
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key, this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/icons/qspot-mark.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
