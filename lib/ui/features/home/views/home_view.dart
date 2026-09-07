import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:watersort/ui/core/theme/app_colors.dart';
import 'package:watersort/ui/core/widgets/tangible_button.dart';
import 'package:watersort/ui/features/game/views/game_view.dart';
import 'package:watersort/ui/features/how_to_play/views/how_to_play_view.dart';
import 'package:watersort/ui/features/level_select/views/level_select_view.dart';
import 'package:watersort/ui/providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watersort/domain/models/user_profile.dart';
import 'package:watersort/ui/features/home/views/settings_view.dart';
import 'package:watersort/ui/features/multiplayer/views/multiplayer_view.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(homeViewModelProvider.notifier).loadProgress());
  }



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (state.activeProfile != null)
                    GestureDetector(
                      onTap: () => _showProfileSwitcherDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.3),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.activeProfile!.avatarEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.activeProfile!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final Uri url = Uri.parse('https://ko-fi.com/sidhant947');
                      try {
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          await launchUrl(url, mode: LaunchMode.platformDefault);
                        }
                      } catch (_) {
                        try {
                          await launchUrl(url, mode: LaunchMode.platformDefault);
                        } catch (_) {}
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF222222),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 3),


              // Game Title
              Text(
                'WATER SORT',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: AppColors.headingWhite,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A COZY COLOR SORTING GAME',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.subtext,
                  letterSpacing: 1.2,
                ),
              ),

              const Spacer(flex: 2),

              // Single line Level Panel (Pill style)
              if (state.progress != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    'Level ${state.progress!.currentLevel}',
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
              ] else ...[
                const Spacer(flex: 5),
              ],

              // Play Button (Primary CTA)
              TangibleButton(
                text: state.progress == null || state.progress!.currentLevel <= 1 ? 'Start Game' : 'Continue',
                onPressed: state.isLoading
                    ? null
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameView(levelNumber: state.progress?.currentLevel ?? 1),
                          ),
                        );
                        ref.read(homeViewModelProvider.notifier).loadProgress();
                      },
              ),

              const SizedBox(height: 12),

              // Level Select Button
              TangibleButton(
                text: 'Select Level',
                isSecondary: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LevelSelectView(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Random Puzzle Button
              TangibleButton(
                text: 'Random Puzzle',
                isSecondary: true,
                onPressed: () => _showDifficultyDialog(context),
              ),

              const SizedBox(height: 12),

              // Multiplayer Button
              TangibleButton(
                text: 'Multiplayer',
                isSecondary: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MultiplayerView(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // How to Play Button (Secondary Button)
              TangibleButton(
                text: 'How to Play',
                isSecondary: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HowToPlayView(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TangibleButton(
                text: 'Settings',
                isSecondary: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsView(),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedDifficulty = 'Easy';
        int selectedCapacity = 4;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF181818),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: Color(0xFF222222),
                  width: 1.0,
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      ...[
                        {'label': 'EASY', 'value': 'Easy', 'defaultCap': 4},
                        {'label': 'MEDIUM', 'value': 'Medium', 'defaultCap': 4},
                        {'label': 'HARD', 'value': 'Hard', 'defaultCap': 5},
                        {'label': 'EXPERT', 'value': 'Super Hard', 'defaultCap': 5},
                        {'label': 'EXTREME', 'value': 'Super Duper Hard', 'defaultCap': 6},
                      ].map((diff) {
                        final isSelected = selectedDifficulty == diff['value'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TangibleButton(
                            text: diff['label'] as String,
                            isSecondary: !isSelected,
                            onPressed: () {
                              setState(() {
                                selectedDifficulty = diff['value'] as String;
                                selectedCapacity = diff['defaultCap'] as int;
                              });
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TUBE CAPACITY',
                            style: TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.headingWhite,
                            ),
                          ),
                          Text(
                            '$selectedCapacity',
                            style: TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: selectedCapacity.toDouble(),
                        min: 4,
                        max: 6,
                        divisions: 2,
                        activeColor: AppColors.accent,
                        inactiveColor: const Color(0xFF222222),
                        onChanged: (val) {
                          setState(() {
                            selectedCapacity = val.round();
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      TangibleButton(
                        text: 'PLAY PUZZLE',
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameView(
                                levelNumber: 0,
                                isRandom: true,
                                randomDifficulty: selectedDifficulty,
                                randomCapacity: selectedCapacity,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            fontFamily: 'BebasNeue',
                            color: AppColors.subtext,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProfileSwitcherDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(homeViewModelProvider);
            return Dialog(
              backgroundColor: const Color(0xFF181818),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: Color(0xFF222222),
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SELECT PROFILE',
                      style: TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.headingWhite,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: SingleChildScrollView(
                        child: Column(
                          children: state.profiles.map((profile) {
                            final isActive = state.activeProfile?.id == profile.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: InkWell(
                                onTap: () {
                                  ref.read(homeViewModelProvider.notifier).switchProfile(profile.id);
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.accent.withOpacity(0.08)
                                        : const Color(0xFF1E1E24),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isActive
                                          ? AppColors.accent.withOpacity(0.5)
                                          : const Color(0xFF2C2C35),
                                      width: isActive ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF121216),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          profile.avatarEmoji,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          profile.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white54,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _showEditProfileDialog(context, profile);
                                        },
                                      ),
                                      if (isActive)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.accent,
                                          size: 20,
                                        )
                                      else if (state.profiles.length > 1)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            ref.read(homeViewModelProvider.notifier).deleteProfile(profile.id);
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TangibleButton(
                      text: '+ CREATE NEW PROFILE',
                      onPressed: () {
                        Navigator.pop(context);
                        _showCreateProfileDialog(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          color: AppColors.subtext,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateProfileDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedEmoji = '🧪';
    final emojis = ['🧪', '🧬', '💧', '🎨', '🔮', '🌟', '🔥', '🏆', '👾', '🚀'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF181818),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: Color(0xFF222222),
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CREATE PROFILE',
                      style: TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.headingWhite,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter profile name',
                        hintStyle: const TextStyle(color: Color(0xFF666666)),
                        filled: true,
                        fillColor: const Color(0xFF1C1C22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF2C2C35)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.accent),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SELECT AVATAR EMOJI',
                        style: TextStyle(
                          color: AppColors.subtext,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: emojis.map((emoji) {
                        final isSelected = selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () => setState(() => selectedEmoji = emoji),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withOpacity(0.12)
                                  : const Color(0xFF1C1C22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.accent : const Color(0xFF2C2C35),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    TangibleButton(
                      text: 'CREATE',
                      onPressed: nameController.text.trim().isEmpty
                          ? null
                          : () {
                              ref.read(homeViewModelProvider.notifier).createProfile(
                                    nameController.text.trim(),
                                    selectedEmoji,
                                  );
                              Navigator.pop(context);
                            },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          color: AppColors.subtext,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    String selectedEmoji = profile.avatarEmoji;
    final emojis = ['🧪', '🧬', '💧', '🎨', '🔮', '🌟', '🔥', '🏆', '👾', '🚀'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF181818),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: Color(0xFF222222),
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EDIT PROFILE',
                      style: TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.headingWhite,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter profile name',
                        hintStyle: const TextStyle(color: Color(0xFF666666)),
                        filled: true,
                        fillColor: const Color(0xFF1C1C22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF2C2C35)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.accent),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SELECT AVATAR EMOJI',
                        style: TextStyle(
                          color: AppColors.subtext,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: emojis.map((emoji) {
                        final isSelected = selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () => setState(() => selectedEmoji = emoji),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withOpacity(0.12)
                                  : const Color(0xFF1C1C22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.accent : const Color(0xFF2C2C35),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    TangibleButton(
                      text: 'SAVE CHANGES',
                      onPressed: nameController.text.trim().isEmpty
                          ? null
                          : () {
                              final updated = profile.copyWith(
                                name: nameController.text.trim(),
                                avatarEmoji: selectedEmoji,
                              );
                              ref.read(homeViewModelProvider.notifier).updateProfile(updated);
                              Navigator.pop(context);
                            },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showProfileSwitcherDialog(context);
                      },
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          color: AppColors.subtext,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
