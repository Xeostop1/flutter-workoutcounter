import 'package:flutter/material.dart';

class SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const SaveButton({
    super.key,
    this.onPressed
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          "Save",
          style: TextStyle(color: Colors.white),
        )
    );
  }
}
