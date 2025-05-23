import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../services/api_service.dart';

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
    ApiService.loadMenus(categories: categories, menus: menus)
        .then((_) {
          setState(() {});
        })
        .catchError((error) {
          print('Error: $error');
        });
  }

  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String formatHarga(int harga) => formatter.format(harga);

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

  void addMenu(String category) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Tambah Menu',
              style: TextStyle(
                fontFamily: 'Sen',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            content: Column(
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
              ],
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
                  final name = nameCtrl.text;
                  final price = int.tryParse(priceCtrl.text) ?? 0;
                  setState(() {
                    menus[category]!.add({'name': name, 'price': price});
                  });
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

  void editMenu(String category, int index) {
    final item = menus[category]![index];
    final nameCtrl = TextEditingController(text: item['name']);
    final priceCtrl = TextEditingController(text: item['price'].toString());
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
            content: Column(
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
              ],
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
                  final name = nameCtrl.text;
                  final price = int.tryParse(priceCtrl.text) ?? 0;
                  setState(() {
                    menus[category]![index] = {'name': name, 'price': price};
                  });
                  Navigator.pop(context);
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
                                  fontSize: 22,
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
                                onPressed: () => addMenu(category),
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
        onPressed: addCategory,
        child: Icon(Icons.add),
      ),
    );
  }
}
