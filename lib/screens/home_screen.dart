// lib/screens/home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import '../services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentFolder = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentFolder();
  }

  void _loadCurrentFolder() async {
    final folder = await SettingsService.getSelectedFolder();
    setState(() {
      _currentFolder = folder;
    });
  }

  void _selectFolder() async {
    final status = await Permission.manageExternalStorage.request();
    
    if (status.isGranted) {
      try {
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
        
        if (selectedDirectory != null) {
          await SettingsService.saveSelectedFolder(selectedDirectory);
          setState(() {
            _currentFolder = selectedDirectory;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Папка изменена: $selectedDirectory'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Ошибка выбора папки: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final permissionStatus = await Permission.camera.request();
      
      if (permissionStatus != PermissionStatus.granted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );

      if (pickedImage != null && mounted) {
        Navigator.pushNamed(
          context,
          '/save',
          arguments: File(pickedImage.path),
        );
      }
    } catch (e) {
      debugPrint('Ошибка при съемке: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      body: SafeArea(
        child: Column(
          children: [
            // Шапка
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Логотип и название
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C40E2), Color(0xFF8E6AFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.photo_camera,
                          size: 60,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'MyCam',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Быстрая съемка товаров',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Основной контент
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Кнопка съемки
                    _isLoading
                        ? const Column(
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFFFF7B00),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Загрузка камеры...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: _takePicture,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF7B00), Color(0xFFFF9E40)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(60),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF7B00).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.photo_camera,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    Text(
                      _isLoading ? 'Загрузка...' : 'Сделать фото',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isLoading
                          ? 'Открываю камеру...'
                          : 'Нажмите для начала съемки',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Панель с путем к папке
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Фото сохраняются в:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectFolder,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F3D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6C40E2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.folder,
                            color: Color(0xFFFF7B00),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentFolder,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Нажмите на путь чтобы изменить папку',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}