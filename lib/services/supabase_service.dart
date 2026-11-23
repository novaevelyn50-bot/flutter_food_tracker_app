import 'package:image_picker/image_picker.dart';
import 'package:flutter_food_tracker_app/models/food.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  static const String _foodTable = 'food_tracker_tb';
  static const String _foodBucket = 'food_tracker_bk';

  Future<String> uploadImageFile(XFile image) async {
    final fileName = '${DateTime.now().microsecondsSinceEpoch}_${image.name}';

    await supabase.storage
        .from(_foodBucket)
        .uploadBinary(
          fileName,
          await image.readAsBytes(),
          fileOptions: FileOptions(contentType: image.mimeType ?? 'image/jpeg'),
        );

    return fileName;
  }

  String getImageUrl(String fileName) {
    return supabase.storage.from(_foodBucket).getPublicUrl(fileName);
  }

  Future<void> insertFood(Food food) async {
    await supabase.from(_foodTable).insert(food.toJson());
  }

  Future<List<Food>> getAllFoods() async {
    final response = await supabase
        .from(_foodTable)
        .select()
        .order('created_at', ascending: false);
    return response
        .map((food) => Food.fromJson(Map<String, dynamic>.from(food)))
        .toList();
  }

  Future<void> updateFood(Food food) async {
    final id = food.id;
    if (id == null) {
      throw ArgumentError('Food id is required to update a food record.');
    }

    await supabase.from(_foodTable).update(food.toJson()).eq('id', id);
  }

  Future<void> deleteFood(String id) async {
    await supabase.from(_foodTable).delete().eq('id', id);
  }

  Future<void> deleteImageFile(String fileName) async {
    await supabase.storage.from(_foodBucket).remove([fileName]);
  }

  Future<void> deleteImageByUrl(String? imageUrl) async {
    if (imageUrl == null) {
      return;
    }

    final path = Uri.tryParse(imageUrl)?.path;
    final bucketMarker = '/object/public/$_foodBucket/';
    final pathStart = path?.indexOf(bucketMarker) ?? -1;
    if (pathStart < 0) {
      return;
    }

    final fileName = Uri.decodeComponent(
      path!.substring(pathStart + bucketMarker.length),
    );
    await deleteImageFile(fileName);
  }
}
