import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddFoodTrackerUI extends StatefulWidget {
  const AddFoodTrackerUI({super.key});

  @override
  State<AddFoodTrackerUI> createState() => _AddFoodTrackerUIState();
}

class _AddFoodTrackerUIState extends State<AddFoodTrackerUI> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _personController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _supabaseService = SupabaseService();

  static const Map<String, String> _meals = {
    'breakfast': 'เช้า',
    'lunch': 'กลางวัน',
    'dinner': 'เย็น',
    'snack': 'ว่าง',
  };

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String _selectedMeal = 'breakfast';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _foodNameController.dispose();
    _priceController.dispose();
    _personController.dispose();
    super.dispose();
  }

  Future<void> _showImageOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('ถ่ายภาพ'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('เลือกรูปจากอัลบั้ม'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (!mounted) {
      return;
    }
    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) {
        return;
      }

      final imageBytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = imageBytes;
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('เปิดรูปภาพไม่สำเร็จ: ${error.message ?? error.code}');
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _foodNameController.clear();
    _priceController.clear();
    _personController.clear();
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedMeal = 'breakfast';
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    String? imagePath;

    try {
      final image = _selectedImage;
      if (image != null) {
        imagePath = await _supabaseService.uploadImageFile(image);
      }

      await _supabaseService.insertFood(
        Food(
          foodName: _foodNameController.text.trim(),
          foodMeal: _selectedMeal,
          foodPrice: double.parse(_priceController.text.trim()),
          foodPerson: int.parse(_personController.text.trim()),
          foodData: _selectedDate.toIso8601String().split('T').first,
          foodImageUrl: imagePath == null
              ? null
              : _supabaseService.getImageUrl(imagePath),
        ),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลอาหารเรียบร้อย')),
      );
      Navigator.of(context).pop(true);
    } on StorageException catch (error) {
      if (mounted) {
        _showMessage('อัปโหลดรูปไม่สำเร็จ: ${error.message}');
      }
    } on PostgrestException catch (error) {
      var message = 'บันทึกข้อมูลไม่สำเร็จ: ${error.message}';
      if (imagePath != null) {
        try {
          await _supabaseService.deleteImageFile(imagePath);
        } on StorageException catch (cleanupError) {
          message =
              '$message และลบรูปที่อัปโหลดแล้วไม่สำเร็จ: ${cleanupError.message}';
        }
      }
      if (mounted) {
        _showMessage(message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
        title: const Text('Food Tracker (เพิ่ม)'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: InkWell(
                    onTap: _showImageOptions,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 180,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_selectedImageBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(
                                _selectedImageBytes!,
                                width: 180,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: Colors.grey.shade500,
                              size: 76,
                            ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFFF44336),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('กินอะไร'),
                _buildTextField(
                  controller: _foodNameController,
                  hintText: 'เช่น KFC, Pizza',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'กรุณากรอกชื่ออาหาร'
                      : null,
                ),
                const SizedBox(height: 12),
                _buildLabel('กินมื้อไหน'),
                Wrap(
                  spacing: 8,
                  children: _meals.entries.map((meal) {
                    final selected = _selectedMeal == meal.key;
                    return ChoiceChip(
                      label: Text(meal.value),
                      selected: selected,
                      selectedColor: const Color(0xFF4CAF50),
                      backgroundColor: Colors.grey.shade400,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedMeal = meal.key);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _buildLabel('กินไปเท่าไหร่'),
                _buildTextField(
                  controller: _priceController,
                  hintText: 'เช่น 299.50',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final price = double.tryParse(value?.trim() ?? '');
                    if (price == null || price <= 0) {
                      return 'กรุณากรอกตัวเลขมากกว่า 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildLabel('กินกี่คน'),
                _buildTextField(
                  controller: _personController,
                  hintText: 'เช่น 3',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final person = int.tryParse(value?.trim() ?? '');
                    if (person == null || person <= 0) {
                      return 'กรุณากรอกจำนวนคนเป็นจำนวนเต็มมากกว่า 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildLabel('กินไปวันไหน'),
                OutlinedButton(
                  onPressed: _selectDate,
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedDate.toIso8601String().split('T').first),
                      const Icon(Icons.calendar_today_outlined, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveFood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'บันทึก',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _clearForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
    );
  }
}
