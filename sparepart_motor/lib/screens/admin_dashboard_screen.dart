import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sparepart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/theme_provider.dart';
import '../models/sparepart.dart';
import '../models/order.dart';
import 'order_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SparepartProvider>().fetchSpareparts();
      context.read<OrderProvider>().fetchAllOrders();
      context.read<AuthProvider>().reloadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, theme, _) {
              return IconButton(
                icon: Icon(
                  theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => theme.toggleTheme(),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Kelola Produk', icon: Icon(Icons.inventory)),
            Tab(text: 'Kelola Pesanan', icon: Icon(Icons.receipt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductTab(),
          _buildOrderTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showSparepartDialog(context, null),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProductTab() {
    return Consumer<SparepartProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchSpareparts(),
          child: ListView.builder(
            itemCount: provider.spareparts.length,
            itemBuilder: (context, index) {
              final sparepart = provider.spareparts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(sparepart.name),
                  subtitle: Text('Rp ${sparepart.price.toStringAsFixed(0)} - Stok: ${sparepart.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showSparepartDialog(context, sparepart),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSparepart(context, sparepart),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchOrdersWithUserEmail(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final ordersWithEmail = snapshot.data ?? [];
        
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            itemCount: ordersWithEmail.length,
            itemBuilder: (context, index) {
              final orderData = ordersWithEmail[index];
              final order = Order.fromJson(orderData);
              final userEmail = orderData['user_email'] ?? 'Unknown User';
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  title: Text('Order #${order.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer: $userEmail'),
                      Text('Total: Rp ${order.total.toStringAsFixed(0)}'),
                      Text('Tanggal: ${order.createdAt.toString().split(' ')[0]}'),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      order.status,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: _getStatusColor(order.status),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (order.status == 'pending')
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateOrderStatusDirect(order.id),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Setujui'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateOrderStatusDirect(order.id, 'cancelled'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Tolak'),
                                  ),
                                ),
                              ],
                            ),
                          if (order.status == 'approved')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _updateOrderStatusDirect(order.id, 'shipped'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                child: const Text('Kirim'),
                              ),
                            ),
                          if (order.status == 'shipped')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _updateOrderStatusDirect(order.id, 'completed'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                child: const Text('Selesai'),
                              ),
                            ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailScreen(order: order),
                                ),
                              );
                              if (result == true) {
                                setState(() {});
                              }
                            },
                            child: const Text('Lihat Detail'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<String> _getUserEmail(String userId) async {
    try {
      print('Fetching email for user ID: $userId');
      
      final response = await SupabaseService().client
          .from('user_profiles')
          .select('email')
          .eq('id', userId)
          .maybeSingle();
      
      final email = response?['email'] ?? 'Unknown User';
      print('Found email: $email for user ID: $userId');
      
      return email;
    } catch (e) {
      print('Error fetching email for user $userId: $e');
      return 'Unknown User';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'shipped':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showSparepartDialog(BuildContext context, Sparepart? sparepart) {
    final nameController = TextEditingController(text: sparepart?.name);
    final descController = TextEditingController(text: sparepart?.description);
    final priceController = TextEditingController(text: sparepart?.price.toString());
    final stockController = TextEditingController(text: sparepart?.stock.toString());
    String? imageUrl = sparepart?.imageUrl;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sparepart == null ? 'Tambah Sparepart' : 'Edit Sparepart'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    final provider = context.read<SparepartProvider>();
                    imageUrl = await provider.uploadImage(image.path, bytes);
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text('Pilih Gambar'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final provider = context.read<SparepartProvider>();
              final newSparepart = Sparepart(
                id: sparepart?.id ?? 0,
                name: nameController.text,
                description: descController.text,
                price: double.tryParse(priceController.text) ?? 0,
                stock: int.tryParse(stockController.text) ?? 0,
                imageUrl: imageUrl,
              );

              bool success;
              if (sparepart == null) {
                success = await provider.addSparepart(newSparepart);
              } else {
                success = await provider.updateSparepart(sparepart.id, newSparepart);
              }

              if (success && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchOrdersWithUserEmail() async {
    try {
      print('Fetching orders with user emails...');
      
      final response = await SupabaseService().client
          .from('orders')
          .select('*, user_profiles(email)')
          .order('created_at', ascending: false);
      
      print('Raw response: $response');
      
      return (response as List).map<Map<String, dynamic>>((order) {
        final orderMap = Map<String, dynamic>.from(order);
        final userProfile = orderMap['user_profiles'];
        final userEmail = userProfile != null ? userProfile['email'] : 'Unknown User';
        
        print('Order ${orderMap['id']}: User ID ${orderMap['user_id']} -> Email: $userEmail');
        
        return {
          ...orderMap,
          'user_email': userEmail,
        };
      }).toList();
    } catch (e) {
      print('Error fetching orders with emails: $e');
      return [];
    }
  }

  Future<void> _updateOrderStatusDirect(int orderId, [String newStatus = 'approved']) async {
    try {
      await SupabaseService().client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      
      setState(() {}); // Refresh UI
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status berhasil diubah ke $newStatus'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
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

  Future<void> _deleteSparepart(BuildContext context, Sparepart sparepart) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Sparepart'),
        content: Text('Yakin ingin menghapus ${sparepart.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<SparepartProvider>().deleteSparepart(sparepart.id);
    }
  }


}