import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watersort/ui/core/theme/app_colors.dart';
import 'package:watersort/ui/providers.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  static const Set<ThemePack> _defaultUnlockedThemes = {
    ThemePack.midnight,
    ThemePack.cyberpunk,
    ThemePack.forest,
    ThemePack.space,
  };

  static const Map<ThemePack, _ThemeSpec> _themeSpecs = {
    ThemePack.midnight: _ThemeSpec(
      name: 'MIDNIGHT',
      bg: Color(0xFF121212),
      accent: Color(0xFF86EF4D),
    ),
    ThemePack.cyberpunk: _ThemeSpec(
      name: 'CYBERPUNK',
      bg: Color(0xFF0F0B1E),
      accent: Color(0xFFFF007F),
    ),
    ThemePack.forest: _ThemeSpec(
      name: 'FOREST',
      bg: Color(0xFF0D140F),
      accent: Color(0xFF50C878),
    ),
    ThemePack.space: _ThemeSpec(
      name: 'SPACE',
      bg: Color(0xFF090A15),
      accent: Color(0xFFBD93F9),
    ),
    ThemePack.retro: _ThemeSpec(
      name: 'RETRO',
      bg: Color(0xFF17130E),
      accent: Color(0xFFFFB86C),
    ),
    ThemePack.sunset: _ThemeSpec(
      name: 'SUNSET',
      bg: Color(0xFF1E0E25),
      accent: Color(0xFFF9844A),
    ),
    ThemePack.neon: _ThemeSpec(
      name: 'NEON',
      bg: Color(0xFF050505),
      accent: Color(0xFF39FF14),
    ),
    ThemePack.ocean: _ThemeSpec(
      name: 'OCEAN',
      bg: Color(0xFF0A192F),
      accent: Color(0xFF00D2FF),
    ),
    ThemePack.volcano: _ThemeSpec(
      name: 'VOLCANO',
      bg: Color(0xFF1A0A0A),
      accent: Color(0xFFFF4500),
    ),
    ThemePack.aurora: _ThemeSpec(
      name: 'AURORA',
      bg: Color(0xFF0B1B1E),
      accent: Color(0xFF00FFCC),
    ),
    ThemePack.lavender: _ThemeSpec(
      name: 'LAVENDER',
      bg: Color(0xFF15101F),
      accent: Color(0xFFE0B0FF),
    ),
    ThemePack.desert: _ThemeSpec(
      name: 'DESERT',
      bg: Color(0xFF221A0F),
      accent: Color(0xFFE6C229),
    ),
    ThemePack.glitch: _ThemeSpec(
      name: 'GLITCH',
      bg: Color(0xFF0D0208),
      accent: Color(0xFF00FF00),
    ),
    ThemePack.sakura: _ThemeSpec(
      name: 'SAKURA',
      bg: Color(0xFF261820),
      accent: Color(0xFFFFB7C5),
    ),
    ThemePack.monochrome: _ThemeSpec(
      name: 'MONOCHROME',
      bg: Color(0xFF1A1A1A),
      accent: Color(0xFFE0E0E0),
    ),
    ThemePack.aquamarine: _ThemeSpec(
      name: 'AQUAMARINE',
      bg: Color(0xFF081C15),
      accent: Color(0xFF7FFFD4),
    ),
    ThemePack.solar: _ThemeSpec(
      name: 'SOLAR',
      bg: Color(0xFF200F00),
      accent: Color(0xFFFFCC00),
    ),
  };

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  void _showResetConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF181818),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A2A34), width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'RESET PROGRESS?',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.headingWhite,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will erase all completed levels, stars, and saved state for this profile. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.subtext,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF333340)),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 15,
                          color: AppColors.subtext,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await ref.read(homeViewModelProvider.notifier).resetProgress();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Progress has been reset.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'RESET',
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeUnlockDialog(BuildContext context, WidgetRef ref, ThemePack tappedTheme) {
    final TextEditingController codeController = TextEditingController();
    String? errorMessage;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xFF22252A),
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'UNLOCK THEME & SKINS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'UNLOCK ALL CUSTOM THEMES AND PREMIUM\nSTYLING OPTIONS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 16,
                      color: Color(0xFF8E95A5),
                      height: 1.25,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _launchExternalUrl('https://buymeacoffee.com/sidhant947/e/572225');
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD000),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_cafe_rounded,
                            color: Colors.black,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'GET UNLOCK CODE',
                            style: TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3038),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'ENTER UNLOCK CODE',
                        hintStyle: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 18,
                          color: Color(0xFF5E6674),
                          letterSpacing: 0.8,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) {
                        if (errorMessage != null) {
                          setState(() {
                            errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(dialogContext),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 18,
                              color: Color(0xFF8E95A5),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isSubmitting
                            ? null
                            : () async {
                                final code = codeController.text;
                                if (code.trim().isEmpty) {
                                  setState(() {
                                    errorMessage = 'Please enter an unlock code.';
                                  });
                                  return;
                                }

                                setState(() {
                                  isSubmitting = true;
                                  errorMessage = null;
                                });

                                final success = await ref
                                    .read(homeViewModelProvider.notifier)
                                    .unlockThemesWithCode(code);

                                if (success) {
                                  HapticFeedback.mediumImpact();
                                  await ref
                                      .read(homeViewModelProvider.notifier)
                                      .setThemePack(tappedTheme);
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('All themes unlocked successfully!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } else {
                                  HapticFeedback.vibrate();
                                  setState(() {
                                    isSubmitting = false;
                                    errorMessage = 'Invalid unlock code. Please try again.';
                                  });
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6EFE00),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isSubmitting ? 'UNLOCKING...' : 'UNLOCK NOW',
                            style: const TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final activeSpec = _themeSpecs[state.activeTheme] ?? _themeSpecs[ThemePack.midnight]!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF282834),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SETTINGS',
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.headingWhite,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 24,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  _buildSectionHeader(
                    icon: Icons.sports_esports_rounded,
                    title: 'GAMEPLAY & RULES',
                  ),
                  _buildCardGroup(
                    children: [
                      _buildSettingRow(
                        icon: Icons.timer_rounded,
                        iconColor: const Color(0xFF38BDF8),
                        title: 'GAMEPLAY TIMER',
                        description: 'Add countdown timer to levels for an extra challenge, or keep it off to play relaxed.',
                        value: state.isTimerEnabled,
                        onTap: () => ref.read(homeViewModelProvider.notifier).toggleTimer(),
                      ),
                      _buildDivider(),
                      _buildSettingRow(
                        icon: Icons.lightbulb_rounded,
                        iconColor: const Color(0xFFFFB300),
                        title: 'HINT HELPER',
                        description: 'Show a hint button during gameplay to highlight the next optimal move.',
                        value: state.isHintHelperEnabled,
                        onTap: () => ref.read(homeViewModelProvider.notifier).toggleHintHelper(),
                      ),
                      _buildDivider(),
                      _buildSettingRow(
                        icon: Icons.visibility_off_rounded,
                        iconColor: const Color(0xFFA855F7),
                        title: 'SUPER HARD DIFFICULTY',
                        description: 'Only reveal the topmost color; all hidden liquid segments beneath are pure white.',
                        value: state.isSuperHardModeEnabled,
                        onTap: () => ref.read(homeViewModelProvider.notifier).toggleSuperHardMode(),
                      ),
                    ],
                  ),
                  _buildSectionHeader(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AUDIO & VISUALS',
                  ),
                  _buildCardGroup(
                    children: [
                      _buildSettingRow(
                        icon: state.isSoundEffectsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        iconColor: const Color(0xFF34D399),
                        title: 'SOUND EFFECTS',
                        description: 'Liquid pouring sounds, tube completion chimes, and victory fanfare.',
                        value: state.isSoundEffectsEnabled,
                        isEnabled: !state.isInstantPouringEnabled,
                        onTap: () => ref.read(homeViewModelProvider.notifier).toggleSoundEffects(),
                      ),
                      _buildDivider(),
                      _buildSettingRow(
                        icon: Icons.motion_photos_off_rounded,
                        iconColor: const Color(0xFFF87171),
                        title: 'TURN OFF ANIMATIONS',
                        description: 'Instant gameplay mode. Disables pouring physics, ripples, waves, and all sound effects.',
                        value: state.isInstantPouringEnabled,
                        onTap: () => ref.read(homeViewModelProvider.notifier).toggleInstantPouring(),
                      ),
                      _buildDivider(),
                      _buildSettingRow(
                        icon: Icons.blur_on_rounded,
                        iconColor: const Color(0xFF2DD4BF),
                        title: 'FROST SOLVED TUBES',
                        description: 'Apply an icy glass frosting effect to completed tubes to easily focus on active ones.',
                        value: state.isBlurSolvedTubesEnabled,
                        onTap: () => ref.read(homeViewModelProvider.notifier).toggleBlurSolvedTubes(),
                      ),
                    ],
                  ),
                  _buildSectionHeader(
                    icon: Icons.palette_rounded,
                    title: 'THEME PALETTES',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: activeSpec.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: activeSpec.accent.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: activeSpec.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            activeSpec.name,
                            style: TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 13,
                              color: activeSpec.accent,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF22222B),
                        width: 1.0,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double itemWidth = (constraints.maxWidth - 10) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: ThemePack.values.map((theme) {
                            final spec = _themeSpecs[theme]!;
                            final isSelected = state.activeTheme == theme;
                            final isUnlocked = state.areThemesUnlocked || _defaultUnlockedThemes.contains(theme);

                            return GestureDetector(
                              onTap: () {
                                if (isUnlocked) {
                                  HapticFeedback.selectionClick();
                                  ref.read(homeViewModelProvider.notifier).setThemePack(theme);
                                } else {
                                  HapticFeedback.lightImpact();
                                  _showThemeUnlockDialog(context, ref, theme);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: itemWidth,
                                height: 46,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? spec.accent.withValues(alpha: 0.12)
                                      : const Color(0xFF121216),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? spec.accent
                                        : (isUnlocked ? const Color(0xFF262632) : const Color(0xFF22222B)),
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: spec.accent.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        spreadRadius: 0.5,
                                      ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: spec.bg,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? spec.accent
                                              : (isUnlocked
                                                  ? const Color(0xFF383848)
                                                  : const Color(0xFF2E2E38)),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: spec.accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        spec.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'BebasNeue',
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                          color: isSelected
                                              ? spec.accent
                                              : (isUnlocked ? AppColors.headingWhite : const Color(0xFF888899)),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: spec.accent,
                                      )
                                    else if (!isUnlocked)
                                      const Icon(
                                        Icons.lock_rounded,
                                        size: 14,
                                        color: Color(0xFF7E7E90),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  _buildSectionHeader(
                    icon: Icons.help_outline_rounded,
                    title: 'SUPPORT & ABOUT',
                  ),
                  _buildCardGroup(
                    children: [
                      _buildActionRow(
                        icon: Icons.bug_report_rounded,
                        iconColor: const Color(0xFFEF4444),
                        title: 'REPORT BUGS / SUGGESTIONS',
                        description: 'Open GitHub to submit bug reports or propose new features.',
                        onTap: () => _launchExternalUrl('https://github.com/sidhant947/water-sort'),
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          color: Color(0xFF7E7E90),
                          size: 16,
                        ),
                      ),
                      _buildDivider(),
                      _buildActionRow(
                        icon: Icons.coffee_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'BUY ME A COFFEE',
                        description: 'Support independent development and future game updates.',
                        onTap: () => _launchExternalUrl('https://ko-fi.com/sidhant947'),
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          color: Color(0xFF7E7E90),
                          size: 16,
                        ),
                      ),
                      _buildDivider(),
                      _buildActionRow(
                        icon: Icons.restart_alt_rounded,
                        iconColor: Colors.redAccent,
                        title: 'RESET ALL PROGRESS',
                        description: 'Clear all solved level records, stars, and saved states.',
                        onTap: () => _showResetConfirmationDialog(context, ref),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF7E7E90),
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10, top: 22),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.subtext,
              letterSpacing: 1.2,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildCardGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16161B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF22222B),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFF1F1F27),
      indent: 68,
      endIndent: 16,
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool value,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return InkWell(
      onTap: isEnabled
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      splashColor: AppColors.accent.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.38,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (value && isEnabled)
                      ? iconColor.withValues(alpha: 0.16)
                      : const Color(0xFF1F1F26),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: (value && isEnabled)
                        ? iconColor.withValues(alpha: 0.35)
                        : const Color(0xFF2B2B36),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  icon,
                  color: (value && isEnabled) ? iconColor : AppColors.subtext,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 16,
                        color: AppColors.headingWhite,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.subtext,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _PremiumSwitch(
                value: isEnabled ? value : false,
                onTap: isEnabled
                    ? () {
                        HapticFeedback.selectionClick();
                        onTap();
                      }
                    : () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.accent.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 16,
                      color: AppColors.headingWhite,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtext,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF7E7E90),
                  size: 14,
                ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSpec {
  final String name;
  final Color bg;
  final Color accent;
  const _ThemeSpec({
    required this.name,
    required this.bg,
    required this.accent,
  });
}

class _PremiumSwitch extends StatelessWidget {
  const _PremiumSwitch({
    required this.value,
    required this.onTap,
  });

  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? AppColors.accent.withValues(alpha: 0.18) : const Color(0xFF1E1E24),
          border: Border.all(
            color: value ? AppColors.accent : const Color(0xFF33333C),
            width: 1.5,
          ),
          boxShadow: [
            if (value)
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.32),
                blurRadius: 8,
                spreadRadius: 0.8,
              ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? AppColors.accent : const Color(0xFF888896),
                    boxShadow: [
                      if (value)
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
