// lib/services/settings_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class SettingsService {
  static const String _selectedFolderKey = 'selected_folder_path';

  // Получаем папку по умолчанию (Pictures)
  static Future<String> getDefaultFolder() async {
    final directory = await getExternalStorageDirectory();
    return '${directory?.path}/Pictures/MyCam';
  }

  // Сохраняем выбранную папку
  static Future<void> saveSelectedFolder(String folderPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedFolderKey, folderPath);
  }

  // Получаем сохраненную папку или папку по умолчанию
  static Future<String> getSelectedFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFolder = prefs.getString(_selectedFolderKey);
    
    if (savedFolder != null && savedFolder.isNotEmpty) {
      return savedFolder;
    }
    
    return getDefaultFolder();
  }
}