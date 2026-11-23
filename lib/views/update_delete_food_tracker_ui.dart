import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateDeleteFoodTrackerUI extends StatefulWidget {
  final Food food;

  const UpdateDeleteFoodTrackerUI({super.key, required this.food});

  @override
  State<UpdateDeleteFoodTrackerUI> createState() =>
      _UpdateDeleteFoodTrackerUIState();
}

class _UpdateDeleteFoodTrackerUIState extends State<UpdateDeleteFoodTrackerUI> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _supabaseService = SupabaseService();
  late final TextEditingController _foodNameController;
  late final TextEditingController _priceController;
  late final TextEditingController _personController;

  static const Map<String, String> _meals = {
    'breakfast': 'เช้า',
    'lunch': 'กลางวัน',
    'dinner': 'เย็น',
    'snack': 'ว่าง',
  };

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  late String? _imageUrl;
  late String _selectedMeal;
  late DateTime _selectedDate;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _foodNameController = TextEditingController(
      text: widget.food.foodName ?? '',
    );
    _priceController = TextEditingController(
      text: widget.food.foodPrice?.toString() ?? '',
    );
    _personController = TextEditingController(
      text: widget.food.foodPerson?.toString() ?? '',
    );
    _imageUrl = widget.food.foodImageUrl;
    _selectedMeal = widget.food.foodMeal ?? 'breakfast';
    _selectedDate =
        DateTime.tryParse(widget.food.foodData ?? '') ?? DateTime.now();
  }

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
      if (mounted) {
        _showMessage('เปิดรูปภาพไม่สำเร็จ: ${error.message ?? error.code}');
      }
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isBusy = true);
    String? newImagePath;

    try {
      final image = _selectedImage;
      if (image != null) {
        newImagePath = await _supabaseService.uploadImageFile(image);
      }

      final oldImageUrl = _imageUrl;
      final updatedFood = Food(
        id: widget.food.id,
        created_at: widget.food.created_at,
        foodData: _selectedDate.toIso8601String().split('T').first,
        foodMeal: _selectedMeal,
        foodName: _foodNameController.text.trim(),
        foodPrice: double.parse(_priceController.text.trim()),
        foodPerson: int.parse(_personController.text.trim()),
        foodImageUrl: newImagePath == null
            ? oldImageUrl
            : _supabaseService.getImageUrl(newImagePath),
      );

      await _supabaseService.updateFood(updatedFood);

      var message = 'บันทึกการแก้ไขเรียบร้อย';
      if (newImagePath != null && oldImageUrl != null) {
        try {
          await _supabaseService.deleteImageByUrl(oldImageUrl);
        } on StorageException catch (error) {
          message = 'บันทึกแล้ว แต่ลบรูปเดิมไม่สำเร็จ: ${error.message}';
        }
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
    } on StorageException catch (error) {
      if (mounted) {
        _showMessage('อัปโหลดรูปไม่สำเร็จ: ${error.message}');
      }
    } on PostgrestException catch (error) {
      var message = 'บันทึกการแก้ไขไม่สำเร็จ: ${error.message}';
      if (newImagePath != null) {
        try {
          await _supabaseService.deleteImageFile(newImagePath);
        } on StorageException catch (cleanupError) {
          message =
              '$message และลบรูปที่อัปโหลดแล้วไม่สำเร็จ: ${cleanupError.message}';
        }
      }
      if (mounted) {
        _showMessage(message);
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        _showMessage('แก้ไขข้อมูลไม่ได้: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _deleteFood() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('ต้องการลบรายการอาหารนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final id = widget.food.id;
    if (id == null) {
      _showMessage('ไม่พบรหัสรายการอาหาร จึงลบข้อมูลไม่ได้');
      return;
    }

    setState(() => _isBusy = true);
    try {
      await _supabaseService.deleteFood(id);

      var message = 'ลบรายการอาหารเรียบร้อย';
      try {
        await _supabaseService.deleteImageByUrl(widget.food.foodImageUrl);
      } on StorageException catch (error) {
        message = 'ลบข้อมูลแล้ว แต่ลบรูปไม่สำเร็จ: ${error.message}';
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      if (mounted) {
        _showMessage('ลบข้อมูลไม่สำเร็จ: ${error.message}');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
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
    Widget foodImage;

    if (_selectedImageBytes != null) {
      foodImage = Image.memory(_selectedImageBytes!, fit: BoxFit.cover);
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      foodImage = Image.network(
        _imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_outlined, size: 76),
      );
    } else {
      foodImage = const Icon(Icons.add_a_photo_outlined, size: 76);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
        title: const Text('Food Tracker (แก้ไข/ลบ)'),
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
                    onTap: _isBusy ? null : _showImageOptions,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 180,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: foodImage,
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
                      onSelected: _isBusy
                          ? null
                          : (_) => setState(() => _selectedMeal = meal.key),
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
                  onPressed: _isBusy ? null : _selectDate,
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
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('บันทึกแก้ไข'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _deleteFood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('ลบข้อมูล'),
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
