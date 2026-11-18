import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/effects/effects_screen.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/image/image_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/video/animate_photo_screen.dart';
import '../screens/video/video_screen.dart';
import '../services/auth/auth_locator.dart';
import '../services/auth/auth_repository.dart';
import '../widgets/main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Caminhos acessíveis sem sessão. Todo o restante exige autenticação.
const Set<String> publicPaths = <String>{
  '/login',
  '/registrar',
  '/esqueci-senha',
};

bool _isPublic(String location) {
  final path = location.split('?').first;
  return publicPaths.contains(path);
}

/// Roteador principal. Cada aba tem sua própria pilha de navegação,
/// preservando o estado ao alternar entre elas.
///
/// [auth] é injetável para que os testes possam simular sessão sem persistência.
GoRouter createAppRouter({
  AuthRepository? auth,
  String initialLocation = '/',
}) {
  final authRepositoryForRouter = auth ?? authRepository;

  String? redirect(BuildContext context, GoRouterState state) {
    final location = state.uri.toString();
    final authenticated =
        authRepositoryForRouter.status == AuthStatus.authenticated;

    if (!authenticated) {
      if (_isPublic(location)) return null;
      final encoded = Uri.encodeComponent(location);
      return '/login?from=$encoded';
    }

    if (!_isPublic(location)) return null;

    final from = state.uri.queryParameters['from'];
    if (from != null && from.startsWith('/') && !_isPublic(from)) {
      return from;
    }
    return '/';
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: false,
    refreshListenable: authRepositoryForRouter,
    redirect: redirect,
    routes: [
      // Fora do shell: telas de autenticação ocupam a tela inteira.
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(auth: authRepositoryForRouter),
      ),
      GoRoute(
        path: '/registrar',
        name: 'register',
        builder: (context, state) => RegisterScreen(auth: authRepositoryForRouter),
      ),
      GoRoute(
        path: '/esqueci-senha',
        name: 'forgotPassword',
        builder: (context, state) =>
            ForgotPasswordScreen(auth: authRepositoryForRouter),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // 0 — Início
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // 1 — Criar (vídeo e animar foto)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/criar',
                name: 'create',
                builder: (context, state) => const VideoScreen(),
                routes: [
                  GoRoute(
                    path: 'video',
                    name: 'createVideo',
                    builder: (context, state) => const VideoScreen(),
                  ),
                  GoRoute(
                    path: 'animar-foto',
                    name: 'animatePhoto',
                    builder: (context, state) => const AnimatePhotoScreen(),
                  ),
                ],
              ),
            ],
          ),

          // 2 — Imagens (criação de imagem e efeitos)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/imagens',
                name: 'images',
                builder: (context, state) => const ImageScreen(),
                routes: [
                  GoRoute(
                    path: 'efeitos',
                    name: 'effects',
                    builder: (context, state) => const EffectsScreen(),
                  ),
                ],
              ),
            ],
          ),

          // 3 — Galeria
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/galeria',
                name: 'gallery',
                builder: (context, state) => const GalleryScreen(),
              ),
            ],
          ),

          // 4 — Perfil (e planos)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/perfil',
                name: 'profile',
                builder: (context, state) =>
                    ProfileScreen(auth: authRepositoryForRouter),
                routes: [
                  GoRoute(
                    path: 'planos',
                    name: 'plans',
                    builder: (context, state) => const SubscriptionScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Não encontramos esta tela: ${state.uri}'),
        ),
      ),
    ),
  );
}

/// Instância padrão usada pelo app em produção.
final GoRouter appRouter = createAppRouter();
