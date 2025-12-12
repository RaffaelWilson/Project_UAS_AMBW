import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/supabase_service.dart';

class OrderProvider with ChangeNotifier {
  final _supabase = SupabaseService();
  List<Order> _orders = [];
  List<Order> _allOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get orders => _orders;
  List<Order> get allOrders => _allOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = _supabase.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase.client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      _orders = (response as List)
          .map((json) => Order.fromJson(json))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder(double total, List<Map<String, dynamic>> items) async {
    try {
      final userId = _supabase.currentUser?.id;
      if (userId == null) return false;

      final orderResponse = await _supabase.client
          .from('orders')
          .insert({
            'user_id': userId,
            'total': total,
            'status': 'pending',
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      for (var item in items) {
        await _supabase.client.from('order_items').insert({
          'order_id': orderId,
          'sparepart_id': item['sparepart_id'],
          'quantity': item['quantity'],
        });
      }

      await fetchOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAllOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.client
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      
      _allOrders = (response as List)
          .map((json) => Order.fromJson(json))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      await _supabase.client
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
      await fetchOrders();
      await fetchAllOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
