import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application state management for UI panels and settings
class AppState with ChangeNotifier {
  // Panel visibility states
  bool _isTopPanelVisible = true;
  bool _isLeftSidebarVisible = true;
  bool _isRightSidebarVisible = true;
  bool _isAiAssistantVisible = false;

  // Theme state
  ThemeMode _themeMode = ThemeMode.dark;

  // Panel sizes
  double _leftSidebarWidth = 280.0;
  double _rightSidebarWidth = 350.0;
  double _topPanelHeight = 60.0;

  // Preferences key constants
  static const String _keyTopPanelVisible = 'top_panel_visible';
  static const String _keyLeftSidebarVisible = 'left_sidebar_visible';
  static const String _keyRightSidebarVisible = 'right_sidebar_visible';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLeftSidebarWidth = 'left_sidebar_width';
  static const String _keyRightSidebarWidth = 'right_sidebar_width';

  AppState() {
    _loadPreferences();
  }

  // Getters
  bool get isTopPanelVisible => _isTopPanelVisible;
  bool get isLeftSidebarVisible => _isLeftSidebarVisible;
  bool get isRightSidebarVisible => _isRightSidebarVisible;
  bool get isAiAssistantVisible => _isAiAssistantVisible;
  ThemeMode get themeMode => _themeMode;
  double get leftSidebarWidth => _leftSidebarWidth;
  double get rightSidebarWidth => _rightSidebarWidth;
  double get topPanelHeight => _topPanelHeight;

  /// Toggle top panel visibility
  void toggleTopPanel() {
    _isTopPanelVisible = !_isTopPanelVisible;
    _savePreference(_keyTopPanelVisible, _isTopPanelVisible);
    notifyListeners();
  }

  /// Toggle left sidebar visibility
  void toggleLeftSidebar() {
    _isLeftSidebarVisible = !_isLeftSidebarVisible;
    _savePreference(_keyLeftSidebarVisible, _isLeftSidebarVisible);
    notifyListeners();
  }

  /// Toggle right sidebar visibility
  void toggleRightSidebar() {
    _isRightSidebarVisible = !_isRightSidebarVisible;
    _savePreference(_keyRightSidebarVisible, _isRightSidebarVisible);
    notifyListeners();
  }

  /// Toggle AI assistant visibility
  void toggleAiAssistant() {
    _isAiAssistantVisible = !_isAiAssistantVisible;
    // Also open right sidebar if AI assistant is being shown
    if (_isAiAssistantVisible && !_isRightSidebarVisible) {
      _isRightSidebarVisible = true;
      _savePreference(_keyRightSidebarVisible, _isRightSidebarVisible);
    }
    notifyListeners();
  }

  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _savePreference(_keyThemeMode, mode.index);
    notifyListeners();
  }

  /// Toggle between light and dark theme
  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  /// Set left sidebar width
  void setLeftSidebarWidth(double width) {
    _leftSidebarWidth = width.clamp(200.0, 400.0);
    _savePreference(_keyLeftSidebarWidth, _leftSidebarWidth);
    notifyListeners();
  }

  /// Set right sidebar width
  void setRightSidebarWidth(double width) {
    _rightSidebarWidth = width.clamp(300.0, 500.0);
    _savePreference(_keyRightSidebarWidth, _rightSidebarWidth);
    notifyListeners();
  }

  /// Hide all panels
  void hideAllPanels() {
    _isTopPanelVisible = false;
    _isLeftSidebarVisible = false;
    _isRightSidebarVisible = false;
    _savePreference(_keyTopPanelVisible, false);
    _savePreference(_keyLeftSidebarVisible, false);
    _savePreference(_keyRightSidebarVisible, false);
    notifyListeners();
  }

  /// Show all panels
  void showAllPanels() {
    _isTopPanelVisible = true;
    _isLeftSidebarVisible = true;
    _isRightSidebarVisible = true;
    _savePreference(_keyTopPanelVisible, true);
    _savePreference(_keyLeftSidebarVisible, true);
    _savePreference(_keyRightSidebarVisible, true);
    notifyListeners();
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isTopPanelVisible = prefs.getBool(_keyTopPanelVisible) ?? true;
      _isLeftSidebarVisible = prefs.getBool(_keyLeftSidebarVisible) ?? true;
      _isRightSidebarVisible = prefs.getBool(_keyRightSidebarVisible) ?? true;

      final themeModeIndex = prefs.getInt(_keyThemeMode) ?? ThemeMode.dark.index;
      _themeMode = ThemeMode.values[themeModeIndex];

      _leftSidebarWidth = prefs.getDouble(_keyLeftSidebarWidth) ?? 280.0;
      _rightSidebarWidth = prefs.getDouble(_keyRightSidebarWidth) ?? 350.0;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  /// Save a preference to storage
  Future<void> _savePreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      debugPrint('Error saving preference: $e');
    }
  }
}
