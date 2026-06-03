import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/oria_app.dart';
import 'core/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR');

  const config = SupabaseRuntimeConfig.fromEnvironment();

  if (config.isMissing) {
    runApp(const MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: config.url,
    anonKey: config.anonKey,
  );

  runApp(const OriaApp());
}

class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFEFF6FF),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Configuracao pendente',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Informe SUPABASE_URL e SUPABASE_ANON_KEY usando --dart-define para iniciar o Oria.',
                    ),
                    SizedBox(height: 12),
                    SelectableText(
                      'flutter run -d chrome --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co --dart-define=SUPABASE_ANON_KEY=sua_anon_key',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
