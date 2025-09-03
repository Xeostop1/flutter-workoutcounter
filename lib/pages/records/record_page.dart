import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/records_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';

import 'sections/user_header_section.dart';
import 'sections/calendar_section.dart';
import 'sections/daily_records_section.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 세 가지 프로바이더를 “읽기만” 해서 존재 보장 (섹션 위젯에서 select/consume)
    context.watch<AuthViewModel>();
    context.watch<RecordsViewModel>();
    context.watch<RoutinesViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('기록'), centerTitle: true),
      body: const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) 사용자 헤더
            UserHeaderSection(),
            SizedBox(height: 16),

            // 2sections) 캘린더
            CalendarSection(),
            SizedBox(height: 16),

            // 3) 선택한 날짜의 기록 리스트
            Expanded(child: DailyRecordsSection()),
          ],
        ),
      ),
    );
  }
}
