import 'package:flutter/material.dart';

class ResetButton extends StatelessWidget {
  final VoidCallback? onPressed;

  ResetButton({
    super.key,
    this.onPressed
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            side: BorderSide(color: Colors.black),
          ),
        child:
        Text(
          "Reset",
          style: TextStyle(
            color: Colors.black
          ),
        ),
    );
  }
}
