import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/sparepart_provider.dart';
import '../providers/cart_provider.dart';
import 'sparepart_detail_screen.dart';

class SparepartListScreen extends StatelessWidget {
  const SparepartListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SparepartProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.spareparts.isEmpty) {
          return const Center(child: Text('Belum ada sparepart'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchSpareparts(),
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: provider.spareparts.length,
            itemBuilder: (context, index) {
              final sparepart = provider.spareparts[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SparepartDetailScreen(sparepart: sparepart),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: sparepart.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: sparepart.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                ),
                              )
                            : const Icon(Icons.image_not_supported, size: 50),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sparepart.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${sparepart.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Stok: ${sparepart.stock}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: sparepart.stock > 0
                                    ? () {
                                        context.read<CartProvider>().addItem(sparepart);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Ditambahkan ke keranjang'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.add_shopping_cart, size: 16),
                                label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
