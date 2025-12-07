import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/sparepart.dart';
import '../services/supabase_service.dart';

class SparepartProvider with ChangeNotifier {
  final _supabase = SupabaseService();
  List<Sparepart> _spareparts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Sparepart> get spareparts => _spareparts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSpareparts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.client
          .from('spareparts')
          .select()
          .order('id', ascending: false);
      
      _spareparts = (response as List)
          .map((json) => Sparepart.fromJson(json))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSparepart(Sparepart sparepart) async {
    try {
      await _supabase.client.from('spareparts').insert(sparepart.toJson());
      await fetchSpareparts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSparepart(int id, Sparepart sparepart) async {
    try {
      await _supabase.client
          .from('spareparts')
          .update(sparepart.toJson())
          .eq('id', id);
      await fetchSpareparts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSparepart(int id) async {
    try {
      await _supabase.client.from('spareparts').delete().eq('id', id);
      await fetchSpareparts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadImage(String filePath, List<int> fileBytes) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      await _supabase.client.storage
          .from('spareparts')
          .uploadBinary(fileName, Uint8List.fromList(fileBytes));
      
      final imageUrl = _supabase.client.storage
          .from('spareparts')
          .getPublicUrl(fileName);
      
      return imageUrl;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
