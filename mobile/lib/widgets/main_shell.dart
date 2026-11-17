import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Casca principal com as 5 abas do PRD: Início, Criar, Imagens, Galeria, Perfil.
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
    BottomNavigationBarItem(icon: Icon(Icons.movie_creation_outlined), label: 'Criar'),
    BottomNavigationBarItem(icon: Icon(Icons.add_photo_alternate_outlined), label: 'Imagens'),
    BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined), label: 'Galeria'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Toca na aba atual volta ao início daquela pilha.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardLight, width: 0.5)),
        ),
        child: BottomNavigationBar(
          items: _destinations,
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}
