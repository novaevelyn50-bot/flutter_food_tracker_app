import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:flutter_food_tracker_app/views/add_food_tracker_ui.dart';
import 'package:flutter_food_tracker_app/views/update_delete_food_tracker_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShowAllFoodTrackerUI extends StatefulWidget {
  const ShowAllFoodTrackerUI({super.key});

  @override
  State<ShowAllFoodTrackerUI> createState() => _ShowAllFoodTrackerUIState();
}

class _ShowAllFoodTrackerUIState extends State<ShowAllFoodTrackerUI> {
  final _supabaseService = SupabaseService();
  List<Food> _foods = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final foods = await _supabaseService.getAllFoods();
      if (!mounted) {
        return;
      }
      setState(() => _foods = foods);
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loadError = error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openAddFood() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddFoodTrackerUI()),
    );
    if (changed == true) {
      await _loadFoods();
    }
  }

  Future<void> _openFood(Food food) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => UpdateDeleteFoodTrackerUI(food: food),
      ),
    );
    if (changed == true) {
      await _loadFoods();
    }
  }

  String _mealName(String? meal) {
    const mealNames = {
      'breakfast': 'เช้า',
      'lunch': 'กลางวัน',
      'dinner': 'เย็น',
      'snack': 'ว่าง',
    };
    return mealNames[meal] ?? meal ?? '';
  }

  Widget _buildFoodList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('โหลดข้อมูลไม่สำเร็จ: $_loadError'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadFoods,
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    Widget foodList;
    if (_foods.isEmpty) {
      foodList = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 240,
            child: Center(child: Text('ยังไม่มีรายการอาหาร')),
          ),
        ],
      );
    } else {
      foodList = ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _foods.length,
        itemBuilder: (context, index) => _buildFoodTile(_foods[index], index),
      );
    }

    return RefreshIndicator(onRefresh: _loadFoods, child: foodList);
  }

  Widget _buildFoodTile(Food food, int index) {
    final imageUrl = food.foodImageUrl;
    final backgroundColor = index.isEven
        ? const Color(0xFFE6F4E8)
        : const Color(0xFFEEEEEE);
    Widget foodImage;
    if (imageUrl == null || imageUrl.isEmpty) {
      foodImage = Image.asset('assets/images/Food.png', fit: BoxFit.cover);
    } else {
      foodImage = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_outlined),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _openFood(food),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(width: 72, height: 72, child: foodImage),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'กิน: ${food.foodName ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'วันที่: ${food.foodData ?? ''} มื้อ: ${_mealName(food.foodMeal)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFF44336),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Food Tracker'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Image.asset(
              'assets/images/Food.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: const Color(0xFFF2F2F2),
              child: _buildFoodList(),
            ),
          ),
          const SizedBox(height: 116),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        onPressed: _openAddFood,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
