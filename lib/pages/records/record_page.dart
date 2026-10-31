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
    final records = context.watch<RecordsViewModel>();
    context.watch<RoutinesViewModel>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: records.loadError != null
            ? _LoadError(onRetry: records.reload)
            : records.isLoading && records.records.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: UserHeaderSection(),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: CalendarSection(),
                    ),
                    DailyRecordsSection(embed: true),
                  ],
                ),
              ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('운동 기록을 불러오지 못했어요.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
