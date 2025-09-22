import 'package:flutter/material.dart';

class CharacterRoomPage extends StatelessWidget {
  const CharacterRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('나라의 불씨')),
      body: Center(
        child: Image.asset(
          'assets/images/charactor-room_1.png',
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      ),
    );
  }
}
