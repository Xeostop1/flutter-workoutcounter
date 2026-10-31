import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/auth_viewmodel.dart';

class UserHeaderSection extends StatelessWidget {
  const UserHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, auth, _) {
        final target = auth.weeklyTarget ?? 3;

        return SizedBox(
          height: 108,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                child: Image.asset(
                  'assets/images/dumbbell.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: 0,
                child: Image.asset(
                  'assets/images/exercise_mascots.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(
                width: 215,
                height: 55,
                child: FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '주 $target회 운동하기',
                    style: const TextStyle(
                      color: Color(0xFFFF6B35),
                      fontWeight: FontWeight.w700,
                      fontSize: 21,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
