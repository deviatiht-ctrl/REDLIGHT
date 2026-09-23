import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';

/// Premye ekran lè premye lanse — chwazi lang app la.
/// Logo a an gwo, 4 lang, bouton an chanje ak lang seleksyone a.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              ClipOval(
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              const Icon(
                LucideIcons.languages,
                size: 26,
                color: AppColors.red,
              ),
              const SizedBox(height: 14),
              // Tit la nan 4 lang yo ansanm
              for (final t in const [
                'Choisissez votre langue',
                'Chwazi lang ou',
                'Choose your language',
                'Elige tu idioma',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    t,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t == s.t('choose_language')
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              // 4 lang yo
              for (final (code, name, _) in languageOptions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LanguageTile(
                    name: name,
                    selected: locale.languageCode == code,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(localeProvider.notifier).setLocale(code);
                    },
                  ),
                ),
              const Spacer(flex: 2),
              PrimaryButton(
                label: s.t('continue'),
                icon: LucideIcons.chevronRight,
                onPressed: () => context.go('/onboarding'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile lang — itilize nan ekran lang + sheet pwofil la.
class LanguageTile extends StatelessWidget {
  const LanguageTile({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.red : Theme.of(context).colorScheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.globe,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                size: 20,
                color: selected ? AppColors.red : Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
