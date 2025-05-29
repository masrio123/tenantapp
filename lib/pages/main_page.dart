import 'package:flutter/material.dart';
import 'package:petraporter_tenant/pages/tenant_menu.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();

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
  }

  void _showEditProfileDialog() {
    TextEditingController nameController = TextEditingController(
      text: tenantName,
    );
    String selectedLocation = canteenLocation;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            DropdownButtonFormField<String>(
              value: selectedLocation,
              decoration: InputDecoration(
                labelText: "Lokasi Kantin",
                labelStyle: TextStyle(fontFamily: 'Sen'),
                border: OutlineInputBorder(),
              ),
              style: TextStyle(fontFamily: 'Sen', color: Colors.black),
              items: ["Gedung P", "Gedung W", "Gedung Q", "Gedung T"]
                  .map((String location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(
                    location,
                    style: TextStyle(fontFamily: 'Sen'),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                selectedLocation = value!;
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
                tenantLocation: selectedLocation,
                isOpen: isOnline,
              );

              if (updated) {
                setState(() {
                  tenantName = nameController.text;
                  canteenLocation = selectedLocation;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
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
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 26, vertical: 27),
                padding: EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  "NO INCOMING ORDER",
                  style: commonTextStyle.copyWith(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
