import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/sparepart.dart';
import '../services/storage_service.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalAmount => _items.fold(0, (sum, item) => sum + item.totalPrice);

  Future<void> loadCart() async {
    final cartData = await StorageService.getCart();
    _items.clear();
    for (var item in cartData) {
      _items.add(CartItem(
        sparepart: Sparepart.fromJson(item['sparepart']),
        quantity: item['quantity'],
      ));
    }
    notifyListeners();
  }

  Future<void> addItem(Sparepart sparepart) async {
    final existingIndex = _items.indexWhere((item) => item.sparepart.id == sparepart.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(sparepart: sparepart));
    }
    
    await _saveCart();
    notifyListeners();
  }

  Future<void> removeItem(int sparepartId) async {
    _items.removeWhere((item) => item.sparepart.id == sparepartId);
    await _saveCart();
    notifyListeners();
  }

  Future<void> updateQuantity(int sparepartId, int quantity) async {
    final index = _items.indexWhere((item) => item.sparepart.id == sparepartId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      await _saveCart();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    final cartData = _items.map((item) => {
      'sparepart': item.sparepart.toJson()..['id'] = item.sparepart.id,
      'quantity': item.quantity,
    }).toList();
    await StorageService.saveCart(cartData);
  }
}
