import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../services/firebase_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<OrderItem> orderItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderItems();
  }

  Future<void> _loadOrderItems() async {
    try {
      final response = await SupabaseService().client
          .from('order_items')
          .select('*, spareparts(name, price)')
          .eq('order_id', widget.order.id);

      setState(() {
        orderItems = (response as List).map((item) {
          final sparepart = item['spareparts'];
          return OrderItem(
            orderId: item['order_id'] ?? 0,
            sparepartId: item['sparepart_id'] ?? 0,
            quantity: item['quantity'] ?? 0,
            sparepartName: sparepart != null ? sparepart['name'] : 'Unknown',
            sparepartPrice: sparepart != null ? (sparepart['price'] as num?)?.toDouble() : 0.0,
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading order items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      final response = await SupabaseService().client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', widget.order.id)
          .select();

      if (response.isNotEmpty) {
        await _sendNotification(newStatus);
        
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status berhasil diubah ke $newStatus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Gagal mengupdate status pesanan');
      }
    } catch (e) {
      print('Error updating order status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendNotification(String status) async {
    try {
      final userResponse = await SupabaseService().client
          .from('user_profiles')
          .select('fcm_token')
          .eq('id', widget.order.userId)
          .maybeSingle();

      if (userResponse != null) {
        final fcmToken = userResponse['fcm_token'];
        if (fcmToken != null && fcmToken.toString().isNotEmpty) {
          String title = 'Update Pesanan';
          String body = '';
          
          switch (status) {
            case 'approved':
              body = 'Pesanan #${widget.order.id} telah disetujui';
              break;
            case 'shipped':
              body = 'Pesanan #${widget.order.id} sedang dikirim';
              break;
            case 'completed':
              body = 'Pesanan #${widget.order.id} telah selesai';
              break;
            case 'cancelled':
              body = 'Pesanan #${widget.order.id} telah dibatalkan';
              break;
          }

          if (body.isNotEmpty) {
            await FirebaseService.sendNotification(fcmToken, title, body);
          }
        }
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order.id}'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order ID: ${widget.order.id}'),
                        Text('Total: Rp ${widget.order.total.toStringAsFixed(0)}'),
                        Text('Status: ${widget.order.status}'),
                        Text('Tanggal: ${widget.order.createdAt.toString().split('.')[0]}'),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Item Pesanan:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: orderItems.length,
                    itemBuilder: (context, index) {
                      final item = orderItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(item.sparepartName ?? 'Unknown'),
                          subtitle: Text('Rp ${item.sparepartPrice?.toStringAsFixed(0) ?? '0'}'),
                          trailing: Text('${item.quantity}x'),
                        ),
                      );
                    },
                  ),
                ),
                if (isAdmin && widget.order.status == 'pending')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateOrderStatus('approved'),
                            child: const Text('Setujui'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateOrderStatus('cancelled'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Tolak'),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isAdmin && widget.order.status == 'approved')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus('shipped'),
                        child: const Text('Kirim'),
                      ),
                    ),
                  ),
                if (isAdmin && widget.order.status == 'shipped')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus('completed'),
                        child: const Text('Selesai'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}