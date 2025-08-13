import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/mascot.dart';
import '../../viewmodels/routine_viewmodel.dart';
import '../../models/routine.dart';
import '../counter/counter_page.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../services/tts_service.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../viewmodels/record_viewmodel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoutineViewModel>();
    final settings = context.read<SettingsViewModel>();
    final records = context.read<RecordViewModel>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Mascot(),
            const SizedBox(height: 16),
            Text('내 루틴', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...vm.sorted.map(
              (r) => Card(
                child: ListTile(
                  title: Text(r.name),
                  subtitle: Text("${r.sets} set · ${r.reps}회"),
                  trailing: IconButton(
                    icon: Icon(r.favorite ? Icons.star : Icons.star_border),
                    onPressed: () => vm.toggleFavorite(r.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider(
                              create: (_) => CounterViewModel(
                                tts: TtsService()
                                  ..init(voice: settings.voiceId),
                                settings: settings,
                                records: records,
                                initialRoutine: r,
                              ),
                            ),
                          ],
                          child: const CounterPage(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
