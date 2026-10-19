import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'core/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Env.useFake) {
    assert(
      Env.supabaseUrl.isNotEmpty,
      'Thiếu --dart-define-from-file=env.json',
    );
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseKey,
    );
  }
  setupDependencies(); // mọi chỗ khác: Supabase.instance.client
  runApp(const MiniTrelloApp());
}
