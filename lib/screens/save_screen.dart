// lib/screens/save_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/settings_service.dart';

class SaveScreen extends StatefulWidget {
  const SaveScreen({Key? key}) : super(key: key);

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  
  bool _isListening = false;
  bool _isProcessing = false;
  bool _showClearButton = false;
  String _currentFolder = '';
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    // Слушаем изменения текста для отображения кнопки очистки
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _showClearButton = _textController.text.isNotEmpty;
    });
  }

  void _initializeScreen() async {
    // Получаем аргументы
    final arguments = ModalRoute.of(context)!.settings.arguments;
    if (arguments is File) {
      setState(() {
        _imageFile = arguments;
      });
    }

    // Загружаем текущую папку
    final folder = await SettingsService.getSelectedFolder();
    setState(() {
      _currentFolder = folder;
    });

    // Автоматически фокусируемся на поле ввода и запускаем распознавание
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.requestFocus();
      _startListening();
    });
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Status: $status');
      },
      onError: (error) {
        print('Error: $error');
        setState(() {
          _isListening = false;
        });
      },
    );

    if (available && mounted) {
      setState(() {
        _isListening = true;
      });

      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          }
        },
        listenFor: const Duration(seconds: 10),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _clearTextField() {
    setState(() {
      _textController.clear();
      _showClearButton = false;
    });
    // Обеспечиваем что поле остается в фокусе после очистки
    _textFocusNode.requestFocus();
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
        }
      } catch (e) {
        print('Ошибка выбора папки: $e');
      }
    }
  }

  void _saveImage() async {
    if (_textController.text.isEmpty || _imageFile == null) {
      _showError('Введите название файла');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Создаем папку если ее нет
      final directory = Directory(_currentFolder);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Очищаем имя файла - РАЗРЕШАЕМ КИРИЛЛИЦУ и другие символы
      String cleanFileName = _textController.text.trim();
      
      // Заменяем только запрещенные символы в именах файлов
      cleanFileName = cleanFileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      
      // Заменяем множественные пробелы на один
      cleanFileName = cleanFileName.replaceAll(RegExp(r'\s+'), ' ');
      
      // Убираем пробелы в начале и конце
      cleanFileName = cleanFileName.trim();
      
      // Если после очистки имя пустое, используем временную метку
      if (cleanFileName.isEmpty) {
        cleanFileName = 'фото_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Полный путь с расширением .jpg
      String newPath = '$_currentFolder/$cleanFileName.jpg';

      // Копируем файл
      await _imageFile!.copy(newPath);

      if (mounted) {
        _showSuccess('Фото "$cleanFileName" сохранено!');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка сохранения: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _deleteImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3D),
        title: const Text(
          'Удалить фото?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Это действие нельзя отменить',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      appBar: AppBar(
        title: const Text('Название фото'),
        backgroundColor: const Color(0xFF1A1F3D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFFF7B00),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Сохранение...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Поле ввода ПЕРВЫМ (над фото)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Название файла:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _textController,
                        focusNode: _textFocusNode,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Произнесите или введите название...',
                          hintStyle: const TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF6C40E2),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF7B00),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF6C40E2),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          // Кнопка очистки (крестик)
                          suffixIcon: _showClearButton
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    icon: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.clear,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    onPressed: _clearTextField,
                                  ),
                                )
                              : null,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveImage(),
                      ),
                      const SizedBox(height: 12),
                      // Индикатор записи голоса
                      if (_isListening) 
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'ЗАПИСЬ... ГОВОРИТЕ СЕЙЧАС',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Превью фото ПОСЛЕ поля ввода
                if (_imageFile != null) ...[
                  Container(
                    height: 220,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF6C40E2).withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Кнопки Сохранить и Удалить
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Кнопка Удалить
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: _deleteImage,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'УДАЛИТЬ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Кнопка Сохранить
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _saveImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF7B00),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    shadowColor: const Color(0xFFFF7B00).withOpacity(0.5),
                                  ),
                                  child: const Text(
                                    'СОХРАНИТЬ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Подсказка под кнопками
                        const Text(
                          'Фото будет сохранено в формате JPG с высоким качеством',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
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
                        'Сохранить в папку:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _selectFolder,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1F3D),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF6C40E2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7B00).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.folder_open,
                                  color: Color(0xFFFF7B00),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentFolder.split('/').last,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currentFolder,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white54,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Нажмите чтобы изменить папку сохранения',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }
}