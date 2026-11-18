import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/auth/auth_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restaura a sessão persistida antes de montar o roteador, evitando um
  // flashes de tela de login para usuários já autenticados.
  await authRepository.restore();
  runApp(const ProviderScope(child: MinhaIaApp()));
}
