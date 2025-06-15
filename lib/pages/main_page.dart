import 'package:flutter/material.dart';
import 'package:petraporter_tenant/pages/tenant_menu.dart';
import '../models/tenant_location.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petraporter_tenant/login/login.dart';

void main() {
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ========================== DASHBOARD PAGE ==========================

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextStyle commonTextStyle = TextStyle(fontFamily: 'Sen');
  bool isOnline = true;

  int tenantId = 0;
  String tenantName = "";
  String canteenLocation = "";

  List<TenantLocation> tenantLocations = [];
  int? selectedLocationId;

  late Future<List<OrderNotification>> _orderFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchTenantLocations();

    _orderFuture = ApiService.fetchOrderNotifications(); // pertama kali

    Future.wait([
          ApiService.loadTenant().then((tenant) {
            tenantName = tenant.name;
            canteenLocation = tenant.location;
            isOnline = tenant.isOpen;
            tenantId = tenant.id;
          }),
        ])
        .then((_) {
          setState(() {});
        })
        .catchError((error) {
          print('Error: $error');
        });

    // polling setiap 10 detik
    _timer = Timer.periodic(Duration(seconds: 10), (_) {
      setState(() {
        _orderFuture = ApiService.fetchOrderNotifications();
      });
    });
  }

  Future<void> fetchTenantLocations() async {
    final locations = await ApiService.getTenantLocations();
    setState(() {
      tenantLocations = locations;
      selectedLocationId =
          locations
              .firstWhere(
                (loc) => loc.locationName == canteenLocation,
                orElse: () => locations.first,
              )
              .id;
    });
  }

  void _showEditProfileDialog() {
    TextEditingController nameController = TextEditingController(
      text: tenantName,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Edit Profil",
              style: TextStyle(fontFamily: 'Sen', fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(fontFamily: 'Sen'),
                  decoration: InputDecoration(
                    labelText: "Nama Tenant",
                    labelStyle: TextStyle(fontFamily: 'Sen'),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedLocationId,
                  decoration: InputDecoration(
                    labelText: "Lokasi Kantin",
                    labelStyle: TextStyle(fontFamily: 'Sen'),
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(fontFamily: 'Sen', color: Colors.black),
                  items:
                      tenantLocations.map((TenantLocation location) {
                        return DropdownMenuItem<int>(
                          value: location.id,
                          child: Text(
                            location.locationName,
                            style: TextStyle(fontFamily: 'Sen'),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedLocationId = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text("Batal", style: TextStyle(fontFamily: 'Sen')),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF7622),
                ),
                onPressed: () async {
                  final updated = await ApiService.updateTenant(
                    id: tenantId,
                    name: nameController.text,
                    tenantLocationId: selectedLocationId!,
                    isOpen: isOnline,
                  );

                  if (updated) {
                    setState(() {
                      tenantName = nameController.text;
                      canteenLocation =
                          tenantLocations
                              .firstWhere(
                                (loc) => loc.id == selectedLocationId,
                                orElse: () => tenantLocations.first,
                              )
                              .locationName;
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Profil tenant berhasil diperbarui"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Gagal memperbarui profil tenant"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(
                  "Simpan",
                  style: TextStyle(fontFamily: 'Sen', color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return; // Pastikan widget masih hidup

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.black),
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.location_pin, color: Colors.red, size: 50),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "LOKASI KANTIN",
                        style: commonTextStyle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        canteenLocation,
                        style: commonTextStyle.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20),
                ClipOval(
                  child: Image.asset(
                    'assets/profile.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.fill,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenantName,
                      style: commonTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF7622),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                      ),
                      onPressed: _showEditProfileDialog,
                      child: Text(
                        "Edit Profil",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Sen',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Switch(
                  value: isOnline,
                  activeColor: Colors.green,
                  onChanged: (val) async {
                    final success = await ApiService.toggleTenantIsOpen(
                      tenantId,
                    );
                    if (success) {
                      setState(() {
                        isOnline = val;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            val
                                ? 'Tenant sekarang online'
                                : 'Tenant sekarang offline',
                            textAlign: TextAlign.center,
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gagal mengubah status tenant',
                            textAlign: TextAlign.center,
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                SizedBox(width: 23),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF7622),
                  minimumSize: Size.fromHeight(50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TenantMenu()),
                  );
                },
                icon: Icon(Icons.menu, color: Colors.white, size: 22),
                label: Text(
                  "EDIT MENU",
                  style: commonTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    fontFamily: 'Sen',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<OrderNotification>>(
                future: _orderFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Gagal memuat order.',
                        style: commonTextStyle.copyWith(color: Colors.red),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 27,
                      ),
                      padding: EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "NO INCOMING ORDER",
                        style: commonTextStyle.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  final orders = snapshot.data!;

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(order.customerName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Status: ${order.orderStatus}"),
                              Text("Lokasi: ${order.tenantLocationName}"),
                              Text("Waktu: ${order.createdAt}"),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text(
                                      "Detail Order - ${order.customerName}",
                                    ),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: order.items.length,
                                        itemBuilder: (context, i) {
                                          final item = order.items[i];
                                          return ListTile(
                                            dense: true,
                                            title: Text(item.productName),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text("Qty: ${item.quantity}"),
                                                Text(
                                                  "Harga: Rp ${item.price.toStringAsFixed(0)}",
                                                ),
                                                Text(
                                                  "Total: Rp ${item.totalPrice.toStringAsFixed(0)}",
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: Text("Tutup"),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
