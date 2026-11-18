import 'api_generation_source.dart';
import 'generation_controller.dart';

/// Instância única usada pelo app. As telas aceitam injeção para testes.
final ApiGenerationSource generationSource = ApiGenerationSource();

/// Controlador compartilhado entre Início, Imagens, Galeria e Perfil.
final GenerationController generationController = GenerationController(
  credits: generationSource,
  generations: generationSource,
);
