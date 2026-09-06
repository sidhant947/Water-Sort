import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:watersort/data/repositories/progress_repository.dart';
import 'package:watersort/domain/models/user_progress.dart';
import 'package:watersort/domain/models/user_profile.dart';
import 'package:watersort/ui/core/theme/app_colors.dart';

class HomeViewModelState {
  const HomeViewModelState({
    this.progress,
    this.activeProfile,
    this.profiles = const [],
    this.isLoading = false,
    this.isTimerEnabled = true,
    this.isSuperHardModeEnabled = false,
    this.isBlurSolvedTubesEnabled = false,
    this.isInstantPouringEnabled = false,
    this.isHintHelperEnabled = false,
    this.isSoundEffectsEnabled = true,
    this.tubeSize = 'medium',
    this.levelStars = const {},
    this.activeTheme = ThemePack.midnight,
    this.areThemesUnlocked = false,
  });

  final UserProgress? progress;
  final UserProfile? activeProfile;
  final List<UserProfile> profiles;
  final bool isLoading;
  final bool isTimerEnabled;
  final bool isSuperHardModeEnabled;
  final bool isBlurSolvedTubesEnabled;
  final bool isInstantPouringEnabled;
  final bool isHintHelperEnabled;
  final bool isSoundEffectsEnabled;
  final String tubeSize;
  final Map<dynamic, dynamic> levelStars;
  final ThemePack activeTheme;
  final bool areThemesUnlocked;

  HomeViewModelState copyWith({
    UserProgress? progress,
    UserProfile? Function()? activeProfile,
    List<UserProfile>? profiles,
    bool? isLoading,
    bool? isTimerEnabled,
    bool? isSuperHardModeEnabled,
    bool? isBlurSolvedTubesEnabled,
    bool? isInstantPouringEnabled,
    bool? isHintHelperEnabled,
    bool? isSoundEffectsEnabled,
    String? tubeSize,
    Map<dynamic, dynamic>? levelStars,
    ThemePack? activeTheme,
    bool? areThemesUnlocked,
  }) {
    return HomeViewModelState(
      progress: progress ?? this.progress,
      activeProfile: activeProfile != null ? activeProfile() : this.activeProfile,
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
      isTimerEnabled: isTimerEnabled ?? this.isTimerEnabled,
      isSuperHardModeEnabled: isSuperHardModeEnabled ?? this.isSuperHardModeEnabled,
      isBlurSolvedTubesEnabled: isBlurSolvedTubesEnabled ?? this.isBlurSolvedTubesEnabled,
      isInstantPouringEnabled: isInstantPouringEnabled ?? this.isInstantPouringEnabled,
      isHintHelperEnabled: isHintHelperEnabled ?? this.isHintHelperEnabled,
      isSoundEffectsEnabled: isSoundEffectsEnabled ?? this.isSoundEffectsEnabled,
      tubeSize: tubeSize ?? this.tubeSize,
      levelStars: levelStars ?? this.levelStars,
      activeTheme: activeTheme ?? this.activeTheme,
      areThemesUnlocked: areThemesUnlocked ?? this.areThemesUnlocked,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeViewModelState> {
  HomeViewModel({required this._progressRepository})
      : super(const HomeViewModelState());

  final ProgressRepository _progressRepository;

  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true);
    try {
      final progress = await _progressRepository.getProgress();
      final activeProfile = await _progressRepository.getActiveProfile();
      final profiles = await _progressRepository.getProfiles();
      final isTimerEnabled = _progressRepository.isTimerEnabled();
      final isSuperHardModeEnabled = _progressRepository.isSuperHardModeEnabled();
      final isBlurSolvedTubesEnabled = _progressRepository.isBlurSolvedTubesEnabled();
      final isInstantPouringEnabled = _progressRepository.isInstantPouringEnabled();
      final isHintHelperEnabled = _progressRepository.isHintHelperEnabled();
      final isSoundEffectsEnabled = _progressRepository.isSoundEffectsEnabled();
      final tubeSize = _progressRepository.getTubeSize();
      final levelStars = _progressRepository.getAllLevelStars();
      final themeName = _progressRepository.getThemePack();
      final areThemesUnlocked = _progressRepository.areThemesUnlocked();
      final theme = ThemePack.values.firstWhere(
        (t) => t.name == themeName,
        orElse: () => ThemePack.midnight,
      );
      AppColors.setTheme(theme);
      state = state.copyWith(
        progress: progress,
        activeProfile: () => activeProfile,
        profiles: profiles,
        isTimerEnabled: isTimerEnabled,
        isSuperHardModeEnabled: isSuperHardModeEnabled,
        isBlurSolvedTubesEnabled: isBlurSolvedTubesEnabled,
        isInstantPouringEnabled: isInstantPouringEnabled,
        isHintHelperEnabled: isHintHelperEnabled,
        isSoundEffectsEnabled: isSoundEffectsEnabled,
        tubeSize: tubeSize,
        levelStars: levelStars,
        activeTheme: theme,
        areThemesUnlocked: areThemesUnlocked,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleTimer() async {
    final newValue = !state.isTimerEnabled;
    await _progressRepository.setTimerEnabled(newValue);
    state = state.copyWith(isTimerEnabled: newValue);
  }

  Future<void> toggleSuperHardMode() async {
    final newValue = !state.isSuperHardModeEnabled;
    await _progressRepository.setSuperHardModeEnabled(newValue);
    state = state.copyWith(isSuperHardModeEnabled: newValue);
  }

  Future<void> toggleBlurSolvedTubes() async {
    final newValue = !state.isBlurSolvedTubesEnabled;
    await _progressRepository.setBlurSolvedTubesEnabled(newValue);
    state = state.copyWith(isBlurSolvedTubesEnabled: newValue);
  }

  Future<void> toggleInstantPouring() async {
    final newValue = !state.isInstantPouringEnabled;
    await _progressRepository.setInstantPouringEnabled(newValue);
    state = state.copyWith(isInstantPouringEnabled: newValue);
  }

  Future<void> toggleHintHelper() async {
    final newValue = !state.isHintHelperEnabled;
    await _progressRepository.setHintHelperEnabled(newValue);
    state = state.copyWith(isHintHelperEnabled: newValue);
  }

  Future<void> toggleSoundEffects() async {
    final newValue = !state.isSoundEffectsEnabled;
    await _progressRepository.setSoundEffectsEnabled(newValue);
    state = state.copyWith(isSoundEffectsEnabled: newValue);
  }

  Future<void> setTubeSize(String size) async {
    await _progressRepository.setTubeSize(size);
    state = state.copyWith(tubeSize: size);
  }

  Future<void> setThemePack(ThemePack theme) async {
    await _progressRepository.setThemePack(theme.name);
    AppColors.setTheme(theme);
    state = state.copyWith(activeTheme: theme);
  }

  Future<bool> unlockThemesWithCode(String inputCode) async {
    final cleanCode = inputCode.replaceAll(' ', '').trim().toUpperCase();
    if (cleanCode == 'THANKYOU') {
      await _progressRepository.setThemesUnlocked(true);
      state = state.copyWith(areThemesUnlocked: true);
      return true;
    }
    return false;
  }

  Future<void> resetProgress() async {
    await _progressRepository.resetProgress();
    await loadProgress();
  }

  Future<void> createProfile(String name, String emoji) async {
    state = state.copyWith(isLoading: true);
    await _progressRepository.createProfile(name, emoji);
    await loadProgress();
  }

  Future<void> switchProfile(String profileId) async {
    state = state.copyWith(isLoading: true);
    await _progressRepository.switchProfile(profileId);
    await loadProgress();
  }

  Future<void> deleteProfile(String profileId) async {
    state = state.copyWith(isLoading: true);
    await _progressRepository.deleteProfile(profileId);
    await loadProgress();
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true);
    await _progressRepository.updateProfile(profile);
    await loadProgress();
  }
}
