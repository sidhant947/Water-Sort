import 'package:hive_flutter/hive_flutter.dart';
import 'package:watersort/domain/models/user_progress.dart';
import 'package:watersort/domain/models/user_profile.dart';
import 'user_progress_adapter.dart';
import 'user_profile_adapter.dart';

class HiveService {
  static const String _progressBoxName = 'user_progress';
  static const String _profilesBoxName = 'user_profiles';
  static const String _settingsBoxName = 'game_settings';
  static const String _activeProfileKey = 'active_profile_id';
  static const String _legacyProgressKey = 'progress';

  late Box<UserProgress> _progressBox;
  late Box<UserProfile> _profilesBox;
  late Box<dynamic> _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProgressAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserProfileAdapter());
    }

    _progressBox = await Hive.openBox<UserProgress>(_progressBoxName);
    _profilesBox = await Hive.openBox<UserProfile>(_profilesBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

    // Migration / Initialization of default profile
    if (_profilesBox.isEmpty) {
      const defaultProfileId = 'default_profile';
      final defaultProfile = UserProfile(
        id: defaultProfileId,
        name: 'Player 1',
        createdAt: DateTime.now(),
        avatarEmoji: '🧪',
      );
      await _profilesBox.put(defaultProfileId, defaultProfile);

      final legacyProgress = _progressBox.get(_legacyProgressKey);
      if (legacyProgress != null) {
        await _progressBox.put('progress_$defaultProfileId', legacyProgress);
        await _progressBox.delete(_legacyProgressKey);
      }
      
      await _settingsBox.put(_activeProfileKey, defaultProfileId);
    }
  }

  Future<List<UserProfile>> getProfiles() async {
    return _profilesBox.values.toList();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _profilesBox.put(profile.id, profile);
  }

  Future<void> deleteProfile(String profileId) async {
    await _profilesBox.delete(profileId);
    await _progressBox.delete('progress_$profileId');
    
    final activeId = await getActiveProfileId();
    if (activeId == profileId) {
      final remains = await getProfiles();
      if (remains.isNotEmpty) {
        await setActiveProfileId(remains.first.id);
      } else {
        await _settingsBox.delete(_activeProfileKey);
      }
    }
  }

  Future<String?> getActiveProfileId() async {
    return _settingsBox.get(_activeProfileKey) as String?;
  }

  Future<void> setActiveProfileId(String profileId) async {
    await _settingsBox.put(_activeProfileKey, profileId);
  }

  Future<UserProgress> getProgress(String profileId) async {
    return _progressBox.get('progress_$profileId') ?? const UserProgress();
  }

  Future<void> saveProgress(String profileId, UserProgress progress) async {
    await _progressBox.put('progress_$profileId', progress);
  }

  Future<void> clearProgress(String profileId) async {
    await _progressBox.delete('progress_$profileId');
  }

  String _getActiveProfileIdSync() {
    return _settingsBox.get(_activeProfileKey)?.toString() ?? 'default_profile';
  }

  bool isTimerEnabled() {
    final profileId = _getActiveProfileIdSync();
    final val = _settingsBox.get('${profileId}_timer_enabled');
    return val == null ? true : val == true;
  }

  Future<void> setTimerEnabled(bool enabled) async {
    final profileId = _getActiveProfileIdSync();
    await _settingsBox.put('${profileId}_timer_enabled', enabled);
  }

  bool isSuperHardModeEnabled() {
    final profileId = _getActiveProfileIdSync();
    final val = _settingsBox.get('${profileId}_super_hard_mode');
    return val == true;
  }

  Future<void> setSuperHardModeEnabled(bool enabled) async {
    final profileId = _getActiveProfileIdSync();
    await _settingsBox.put('${profileId}_super_hard_mode', enabled);
  }

  bool isBlurSolvedTubesEnabled() {
    final profileId = _getActiveProfileIdSync();
    final val = _settingsBox.get('${profileId}_blur_solved_tubes');
    return val == true;
  }

  Future<void> setBlurSolvedTubesEnabled(bool enabled) async {
    final profileId = _getActiveProfileIdSync();
    await _settingsBox.put('${profileId}_blur_solved_tubes', enabled);
  }

  bool isInstantPouringEnabled() {
    final profileId = _getActiveProfileIdSync();
    final val = _settingsBox.get('${profileId}_instant_pouring');
    return val == true;
  }

  Future<void> setInstantPouringEnabled(bool enabled) async {
    final profileId = _getActiveProfileIdSync();
    await _settingsBox.put('${profileId}_instant_pouring', enabled);
  }

  bool isHintHelperEnabled() {
    final profileId = _getActiveProfileIdSync();
    final val = _settingsBox.get('${profileId}_hint_helper');
    return val == true;
  }

  Future<void> setHintHelperEnabled(bool enabled) async {
    final profileId = _getActiveProfileIdSync();
    await _settingsBox.put('${profileId}_hint_helper', enabled);
  }

  bool isSoundEffectsEnabled() {
    final profileId = _getActiveProfileIdSync();
    final val = _settingsBox.get('${profileId}_sound_effects');
    return val == null ? true : val == true;
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    final profileId = _getActiveProfileIdSync();
    await _settingsBox.put('${profileId}_sound_effects', enabled);
  }

  String getTubeSize() {
    final profileId = _getActiveProfileIdSync();
    return _settingsBox.get('${profileId}_tube_size')?.toString() ?? 'medium';
  }

  Future<void> setTubeSize(String size) async {
    final profileId = _getActiveProfileIdSync();
    await _settingsBox.put('${profileId}_tube_size', size);
  }

  Map<dynamic, dynamic>? getSavedLevelState() {
    final profileId = _getActiveProfileIdSync();
    final raw = _settingsBox.get('${profileId}_saved_level_state');
    if (raw is Map) {
      return Map<dynamic, dynamic>.from(raw);
    }
    return null;
  }

  Future<void> saveActiveLevelState(Map<dynamic, dynamic> stateMap) async {
    final profileId = _getActiveProfileIdSync();
    await _settingsBox.put('${profileId}_saved_level_state', stateMap);
  }

  Future<void> clearActiveLevelState() async {
    final profileId = _getActiveProfileIdSync();
    await _settingsBox.delete('${profileId}_saved_level_state');
  }

  Map<dynamic, dynamic> getAllLevelStars() {
    final profileId = _getActiveProfileIdSync();
    final raw = _settingsBox.get('${profileId}_level_stars');
    if (raw is Map) {
      return Map<dynamic, dynamic>.from(raw);
    }
    return <dynamic, dynamic>{};
  }

  Future<void> saveLevelStars(int levelNumber, int stars) async {
    final profileId = _getActiveProfileIdSync();
    final starsMap = Map<dynamic, dynamic>.from(getAllLevelStars());
    starsMap[levelNumber] = stars;
    await _settingsBox.put('${profileId}_level_stars', starsMap);
  }

  String getThemePack() {
    final profileId = _getActiveProfileIdSync();
    return _settingsBox.get('${profileId}_theme_pack')?.toString() ?? 'midnight';
  }

  Future<void> setThemePack(String themeName) async {
    final profileId = _getActiveProfileIdSync();
    await _settingsBox.put('${profileId}_theme_pack', themeName);
  }

  bool areThemesUnlocked() {
    final profileId = _getActiveProfileIdSync();
    final val = _settingsBox.get('themes_unlocked') ?? _settingsBox.get('${profileId}_themes_unlocked');
    return val == true;
  }

  Future<void> setThemesUnlocked(bool unlocked) async {
    final profileId = _getActiveProfileIdSync();
    await _settingsBox.put('themes_unlocked', unlocked);
    await _settingsBox.put('${profileId}_themes_unlocked', unlocked);
  }
}
