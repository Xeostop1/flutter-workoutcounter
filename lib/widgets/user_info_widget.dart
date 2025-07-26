import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoWidget extends StatefulWidget {
  const UserInfoWidget({super.key});

  @override
  State<UserInfoWidget> createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  User? user;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((newUser) {
      setState(() {
        user = newUser;
      });
    });
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Text('로그인되지 않음');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user!.photoURL != null)
          CircleAvatar(
            backgroundImage: NetworkImage(user!.photoURL!),
            radius: 30,
          ),
        const SizedBox(height: 8),
        Text('이름: ${user!.displayName ?? '이름 없음'}'),
        Text('이메일: ${user!.email ?? '이메일 없음'}'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('로그아웃되었습니다')),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('로그아웃'),
        ),
      ],
    );
  }
}
