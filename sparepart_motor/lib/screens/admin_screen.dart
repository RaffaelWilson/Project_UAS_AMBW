import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sparepart_provider.dart';
import '../models/sparepart.dart';
import 'package:image_picker/image_picker.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Consumer<SparepartProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
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
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Sparepart'),
                              content: const Text('Yakin ingin menghapus?'),
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
                            await provider.deleteSparepart(sparepart.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSparepartDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
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
}
