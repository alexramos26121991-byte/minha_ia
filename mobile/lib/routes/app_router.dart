import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../screens/effects/effects_screen.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/image/image_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/video/animate_photo_screen.dart';
import '../screens/video/video_screen.dart';
import '../widgets/main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Roteador principal. Cada aba tem sua própria pilha de navegação,
/// preservando o estado ao alternar entre elas.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
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
              builder: (context, state) => const ProfileScreen(),
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
