// lib/pages/records/record_page.dart
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
    // 존재 보장
    context.watch<AuthViewModel>();
    context.watch<RecordsViewModel>();
    context.watch<RoutinesViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('기록'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserHeaderSection(),
              SizedBox(height: 16),
              CalendarSection(),
              SizedBox(height: 16),
              // ↓ 리스트도 부모 스크롤에 종속
              DailyRecordsSection(embed: true),
            ],
          ),
        ),
      ),
    );
  }
}
