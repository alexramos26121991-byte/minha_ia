import 'package:material_ui/material_ui.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/generation_tile.dart';

/// Tela 5 — Minha galeria.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const _filters = ['Vídeos', 'Imagens criadas', 'Downloads', 'Projetos'];
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha galeria'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Downloads',
            onPressed: () => setState(() => _selected = 2),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm,
            ),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => ChoiceChip(
                  label: Text(_filters[index]),
                  selected: _selected == index,
                  onSelected: (_) => setState(() => _selected = index),
                ),
              ),
            ),
          ),
          Expanded(
            child: _selected == 1
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      children: const [
                        GenerationTile(
                          title: 'Galáxia colorida',
                          type: 'Hoje · 5 créditos',
                          onTap: null,
                        ),
                        GenerationTile(
                          title: 'Cidade futurista',
                          type: 'Ontem · 9 créditos',
                          onTap: null,
                        ),
                      ],
                    ),
                  )
                : EmptyState(
                    icon: _selected == 0
                        ? Icons.movie_outlined
                        : _selected == 2
                            ? Icons.download_outlined
                            : Icons.folder_outlined,
                    title: 'Nada por aqui ainda',
                    message: _selected == 0
                        ? 'Seus vídeos gerados aparecerão nesta aba.'
                        : 'Crie algo e acompanhe seus resultados aqui.',
                    action: AppCard(
                      child: Text(
                        'Use a aba Imagens para começar',
                        style: AppTypography.caption,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
