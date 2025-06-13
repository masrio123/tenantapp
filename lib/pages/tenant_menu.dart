import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../models/categories.dart';

class TenantMenu extends StatefulWidget {
  @override
  _TenantMenuState createState() => _TenantMenuState();
}

class _TenantMenuState extends State<TenantMenu> {
  List<String> categories = [];
  Map<String, List<Map<String, dynamic>>> menus = {};

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  List<Category> category = [];

  String? getCategoryNameById(String id) {
    final cat = category.firstWhere(
      (element) => element.id.toString() == id,
      orElse: () => Category(id: 0, name: ''),
    );
    return cat.id != 0 ? cat.name : null;
  }

  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String formatHarga(int harga) => formatter.format(harga);

  void refreshData() async {
    try {
      category = await ApiService.getCategories();
      setState(() {});
      // sementara data disiapkan
      List<String> tempCategories = [];
      Map<String, List<Map<String, dynamic>>> tempMenus = {};

      await ApiService.loadMenus(categories: tempCategories, menus: tempMenus);

      // baru update ke UI
      setState(() {
        categories = tempCategories;
        menus = tempMenus;
      });
    } catch (e) {
      print('Error while refreshing data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat menu: $e')));
    }
  }

  Future<void> confirmDelete({
    required String title,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Hapus',
              style: TextStyle(
                fontFamily: 'Sen',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            content: Text(
              'Yakin ingin menghapus $title?',
              style: TextStyle(
                fontFamily: 'Sen',
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    fontFamily: 'Sen',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  onConfirm();
                  Navigator.pop(context);
                },
                child: Text(
                  'Hapus',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Sen',
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void addCategory() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Tambah Kategori',
              style: TextStyle(
                fontFamily: 'Sen',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Nama Kategori',
                hintStyle: TextStyle(
                  fontFamily: 'Sen',
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
              style: TextStyle(
                fontFamily: 'Sen',
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    fontFamily: 'Sen',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    setState(() {
                      categories.add(name);
                      menus[name] = [];
                    });
                  }
                  Navigator.pop(context);
                },
                child: Text(
                  'Tambah',
                  style: TextStyle(
                    fontFamily: 'Sen',
                    fontSize: 16,
                    color: Color(0xFFFF7622),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void addMenu() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? selectedCategory;
    bool isAvailable = true;

    List<Category> categories = await ApiService.getCategories();

    BuildContext rootContext = context; // ← ini penting!

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Tambah Menu'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(labelText: 'Kategori'),
                      items:
                          categories.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id.toString(),
                              child: Text(c.name),
                            );
                          }).toList(),
                      onChanged:
                          (val) => setState(() => selectedCategory = val),
                    ),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: 'Nama Menu'),
                    ),
                    TextField(
                      controller: priceCtrl,
                      decoration: InputDecoration(labelText: 'Harga'),
                      keyboardType: TextInputType.number,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tersedia'),
                        Switch(
                          value: isAvailable,
                          onChanged: (val) => setState(() => isAvailable = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // tutup form tambah menu
                  },
                  child: Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.trim()) ?? -1;

                    if (selectedCategory == null || name.isEmpty || price < 0) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text('Harap lengkapi data')),
                      );
                      return;
                    }

                    // tampilkan loading
                    showDialog(
                      context: rootContext,
                      barrierDismissible: false,
                      builder:
                          (_) => Center(child: CircularProgressIndicator()),
                    );

                    try {
                      await ApiService.createMenu(
                        name: name,
                        price: price,
                        categoryId: selectedCategory!,
                        tenantId: '2',
                        isAvailable: isAvailable,
                      );

                      Navigator.of(
                        rootContext,
                        rootNavigator: true,
                      ).pop(); // tutup loading
                      Navigator.of(
                        dialogContext,
                        rootNavigator: true,
                      ).pop(); // tutup modal

                      setState(() {
                        final categoryName = getCategoryNameById(
                          selectedCategory!,
                        );
                        if (categoryName != null) {
                          menus[categoryName] ??= [];
                          menus[categoryName]!.add({
                            'name': name,
                            'price': price,
                            'category_id': selectedCategory,
                            'isAvailable': isAvailable,
                          });
                        }
                      });

                      refreshData();

                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text('Menu berhasil ditambahkan')),
                      );
                    } catch (e) {
                      Navigator.of(
                        rootContext,
                        rootNavigator: true,
                      ).pop(); // tutup loading
                      ScaffoldMessenger.of(
                        rootContext,
                      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                    }
                  },
                  child: Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );

    // nameCtrl.dispose();
    // priceCtrl.dispose();
  }

  void editMenu(String category, int index) {
    final item = menus[category]![index];
    final nameCtrl = TextEditingController(text: item['name']);
    final priceCtrl = TextEditingController(text: item['price'].toString());
    bool isAvailable = item['isAvailable'] ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Edit Menu',
                  style: TextStyle(
                    fontFamily: 'Sen',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nama Menu',
                          labelStyle: TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Sen',
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga',
                          labelStyle: TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Sen',
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tersedia', style: TextStyle(fontFamily: 'Sen')),
                          Switch(
                            value: isAvailable,
                            onChanged:
                                (val) => setState(() => isAvailable = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        fontFamily: 'Sen',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text) ?? -1;

                      if (name.isEmpty || price < 0) {
                        Navigator.pop(context); // Tutup dialog sebelum snackbar
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Harap lengkapi semua data dengan benar.',
                            ),
                          ),
                        );
                        return;
                      }

                      // Tampilkan loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        useRootNavigator:
                            true, // penting untuk menghindari context error
                        builder:
                            (_) => Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await ApiService.updateMenu(
                          id: item['id'],
                          name: name,
                          price: price,
                          isAvailable: isAvailable,
                        );

                        // Update state menu
                        setState(() {
                          menus[category]![index] = {
                            ...item,
                            'name': name,
                            'price': price,
                            'isAvailable': isAvailable,
                          };
                        });

                        Navigator.pop(context); // Tutup loading
                        Navigator.pop(context); // Tutup dialog edit
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Menu berhasil diupdate')),
                        );
                      } catch (e) {
                        Navigator.pop(context); // Tutup loading
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Gagal mengupdate menu: $e')),
                        );
                      } finally {
                        // nameCtrl.dispose();
                        // priceCtrl.dispose();
                      }
                    },
                    child: Text(
                      'Simpan',
                      style: TextStyle(
                        fontFamily: 'Sen',
                        fontSize: 16,
                        color: Color(0xFFFF7622),
                      ),
                    ),
                  ),
                ],
              ),
        );
      },
    );
  }

  void deleteMenu(String category, int index) {
    final menu = menus[category]![index];

    confirmDelete(
      title: 'menu "${menu['name']}"',
      onConfirm: () async {
        try {
          final int menuId = menu['id'];

          await ApiService.deleteMenuById(menuId);

          setState(() {
            menus[category]!.removeAt(index);
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Menu berhasil dihapus')));
        } catch (e) {
          print('Gagal menghapus menu: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus menu')));
        }
      },
    );
  }

  void deleteCategory(String category) {
    confirmDelete(
      title: 'kategori "$category"',
      onConfirm: () {
        setState(() {
          categories.remove(category);
          menus.remove(category);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Menu',
                      style: TextStyle(
                        fontFamily: 'Sen',
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 4,
                      margin: EdgeInsets.only(top: 4),
                      color: Color(0xFFFF7622),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Card(
                    color: Colors.grey[300],
                    // Kategori warna grey 300
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                category,
                                style: TextStyle(
                                  fontFamily: 'Sen',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                                onPressed: () => deleteCategory(category),
                              ),
                            ],
                          ),
                          children: [
                            ...(menus[category] ?? []).asMap().entries.map((
                              entry,
                            ) {
                              int i = entry.key;
                              var item = entry.value;
                              return ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: 12,
                                  right: 4,
                                ),
                                title: Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontFamily: 'Sen',
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  formatHarga(item['price']),
                                  style: TextStyle(
                                    fontFamily: 'Sen',
                                    fontSize: 16,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () => editMenu(category, i),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => deleteMenu(category, i),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => addMenu(),
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  size: 30,
                                  color: Color(0xFFFF7622),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFFF7622),
        onPressed: addMenu,
        child: Icon(Icons.add),
      ),
    );
  }
}
