import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Casca compartilhada por login, cadastro e recuperação de senha.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                label: 'MINHA IA — Sua imaginação, sem limites',
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: AppColors.action,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome,
                          size: 38, color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'MINHA IA',
                      style: AppTypography.title.copyWith(
                        letterSpacing: 3,
                        color: AppColors.glow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(title, style: AppTypography.display),
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle, style: AppTypography.body),
              const SizedBox(height: AppSpacing.xl),
              ...children,
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.xl),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de texto com rótulo e dicas de acessibilidade padronizadas.
class AuthField extends StatelessWidget {
  const AuthField({
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.autofillHints = const <String>[],
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.suffixIcon,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<String> autofillHints;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        validator: validator,
        style: AppTypography.subtitle,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.cardLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.cardLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.glow, width: 2),
          ),
          errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}
