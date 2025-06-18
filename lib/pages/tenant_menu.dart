import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petraporter_tenant/login/login.dart';
import 'package:petraporter_tenant/pages/tenant_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

import '../models/order.dart';
import '../models/tenant.dart';
import '../models/tenant_location.dart';
import '../services/api_service.dart';
import '../models/category.dart';
import '../models/product.dart';

// --- STYLING CONSTANTS ---
const primaryColor = Color(0xFFFF7622);
const secondaryColor = Color(0xFFFFC529);
const backgroundColor = Color(0xFFF8F9FA);
const textColor = Color(0xFF333333);

final _priceFormatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class TenantMenu extends StatefulWidget {
  final int tenantId;

  const TenantMenu({Key? key, required this.tenantId}) : super(key: key);

  @override
  _TenantMenuState createState() => _TenantMenuState();
}

class _TenantMenuState extends State<TenantMenu> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Category> _categories = [];
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getProductsByTenantId(widget.tenantId),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _products = results[1] as List<Product>;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Category? _getCategoryById(int id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (_) {
      return null;
    }
  }

  void _showAddEditMenuDialog({Product? product}) {
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    int? selectedCategoryId = product?.categoryId;
    bool isAvailable = product?.isAvailable ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEditing ? 'Edit Menu' : 'Tambah Menu',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isEditing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DropdownButtonFormField<int>(
                          value: selectedCategoryId,
                          hint: const Text('Pilih Kategori'),
                          isExpanded: true,
                          items:
                              _categories
                                  .map(
                                    (c) => DropdownMenuItem<int>(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setDialogState(
                                () => selectedCategoryId = val,
                              ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Menu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Harga',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Tersedia'),
                      value: isAvailable,
                      onChanged:
                          (val) => setDialogState(() => isAvailable = val),
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed:
                      () => _submitMenuForm(
                        isEditing: isEditing,
                        product: product,
                        name: nameCtrl.text,
                        priceText: priceCtrl.text,
                        categoryId: selectedCategoryId,
                        isAvailable: isAvailable,
                        dialogContext: dialogContext,
                      ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitMenuForm({
    required bool isEditing,
    Product? product,
    required String name,
    required String priceText,
    required int? categoryId,
    required bool isAvailable,
    required BuildContext dialogContext,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final price = int.tryParse(priceText);
    if (name.trim().isEmpty ||
        price == null ||
        (!isEditing && categoryId == null)) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Harap lengkapi semua data'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    Navigator.pop(dialogContext);

    try {
      if (isEditing) {
        await ApiService.updateMenu(
          id: product!.id,
          name: name,
          price: price,
          isAvailable: isAvailable,
        );
      } else {
        await ApiService.createMenu(
          name: name,
          price: price,
          categoryId: categoryId!,
          tenantId: widget.tenantId,
          isAvailable: isAvailable,
        );
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Menu berhasil disimpan'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      await _refreshData();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _confirmAndDelete(Product product) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Hapus Menu'),
            content: Text('Yakin ingin menghapus "${product.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(dialogContext);
                  navigator.pop();

                  try {
                    await ApiService.deleteMenuById(product.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Menu berhasil dihapus'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      await _refreshData();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menghapus: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<Category, List<Product>> groupedMenus = {};
    if (!_isLoading && _errorMessage.isEmpty) {
      for (var product in _products) {
        final category = _getCategoryById(product.categoryId);
        if (category != null) {
          groupedMenus.putIfAbsent(category, () => []);
          groupedMenus[category]!.add(product);
        }
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: const Text('Kelola Menu')),
      body: _buildBody(groupedMenus),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditMenuDialog(),
        label: const Text('Tambah Menu'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(Map<Category, List<Product>> groupedMenus) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_products.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "Belum ada menu",
              style: TextStyle(fontSize: 18, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              "Tambahkan menu pertama Anda sekarang!",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedMenus.keys.length,
        itemBuilder: (context, index) {
          Category category = groupedMenus.keys.elementAt(index);
          List<Product> productsInCategory = groupedMenus[category]!;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.05),
            child: ExpansionTile(
              key: PageStorageKey(category.id),
              title: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              initiallyExpanded: true,
              children:
                  productsInCategory
                      .map((product) => _buildProductTile(product))
                      .toList(),
              childrenPadding: const EdgeInsets.only(bottom: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductTile(Product product) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            product.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
        child: Icon(
          product.isAvailable
              ? Icons.check_circle_outline
              : Icons.highlight_off,
          size: 24,
          color:
              product.isAvailable ? Colors.green.shade800 : Colors.red.shade800,
        ),
      ),
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(_priceFormatter.format(product.price)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.orange.shade700),
            onPressed: () => _showAddEditMenuDialog(product: product),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
            onPressed: () => _confirmAndDelete(product),
          ),
        ],
      ),
    );
  }
}
