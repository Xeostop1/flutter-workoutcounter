// lib/pages/records/record_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/records_viewmodel.dart';

import 'sections/calendar_section.dart';
import 'sections/daily_records_section.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RecordsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 기록'),
        centerTitle: false,
        toolbarHeight: 48,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Pretendard',
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: records.loadError != null
            ? _LoadError(onRetry: records.reload)
            : records.isLoading && records.records.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width < 340 ? 6 : 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CalendarSection(),
                    const SizedBox(height: 8),
                    const DailyRecordsSection(embed: true),
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
