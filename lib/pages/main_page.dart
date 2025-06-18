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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetraPorter Tenant',
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.orange,
        ).copyWith(secondary: secondaryColor, background: backgroundColor),
        fontFamily: 'Sen',
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Sen',
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(
              fontFamily: 'Sen',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(
              fontFamily: 'Sen',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  String _error = '';
  Tenant? _tenant;
  List<TenantLocation> _locations = [];
  List<OrderNotification> _orders = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  List<OrderNotification> _filterActiveOrders(List<OrderNotification> orders) {
    return orders.where((order) {
      final status = order.orderStatus.trim().toLowerCase();
      final isActive =
          status == 'waiting' ||
          status == 'waiting_for_acceptance' ||
          status == 'received';
      return isActive;
    }).toList();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await Future.wait([
        ApiService.loadTenant(),
        ApiService.getTenantLocations(),
        ApiService.fetchOrderNotifications(),
      ]);

      if (mounted) {
        final allOrders = results[2] as List<OrderNotification>;
        final filteredOrders = _filterActiveOrders(allOrders);

        setState(() {
          _tenant = results[0] as Tenant;
          _locations = results[1] as List<TenantLocation>;
          _orders = filteredOrders;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final allNewOrders = await ApiService.fetchOrderNotifications();
        if (!mounted) return;
        final filteredNewOrders = _filterActiveOrders(allNewOrders);
        final hasChanges = _hasOrderChanges(_orders, filteredNewOrders);
        if (hasChanges) {
          setState(() => _orders = filteredNewOrders);
        }
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  bool _hasOrderChanges(
    List<OrderNotification> currentOrders,
    List<OrderNotification> newOrders,
  ) {
    if (currentOrders.length != newOrders.length) return true;
    final currentMap = {for (var o in currentOrders) o.id: o.orderStatus};
    final newMap = {for (var o in newOrders) o.id: o.orderStatus};
    return !const MapEquality().equals(currentMap, newMap);
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    if (_tenant == null) return;
    final oldStatus = _tenant!.isOpen;
    setState(() => _tenant = _tenant!.copyWith(isOpen: value));
    try {
      await ApiService.toggleTenantIsOpen(_tenant!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Toko berhasil dibuka' : 'Toko berhasil ditutup',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      setState(() => _tenant = _tenant!.copyWith(isOpen: oldStatus));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _navigateToMenuPage() async {
    if (_tenant != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TenantMenu(tenantId: _tenant!.id)),
      );
      _loadInitialData();
    }
  }

  void _showEditProfileDialog() {
    if (_tenant == null) return;
    final nameController = TextEditingController(text: _tenant!.name);
    int? dialogSelectedLocationId;
    try {
      dialogSelectedLocationId =
          _locations
              .firstWhere((loc) => loc.locationName == _tenant!.location)
              .id;
    } catch (e) {
      dialogSelectedLocationId =
          _locations.isNotEmpty ? _locations.first.id : null;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Profil", textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nama Tenant",
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_locations.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: dialogSelectedLocationId,
                        items:
                            _locations
                                .map(
                                  (loc) => DropdownMenuItem(
                                    value: loc.id,
                                    child: Text(loc.locationName),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setDialogState(
                              () => dialogSelectedLocationId = value,
                            ),
                        decoration: const InputDecoration(
                          labelText: "Lokasi Kantin",
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      const Text("Tidak ada data lokasi."),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _handleProfileUpdate(
                      nameController.text,
                      dialogSelectedLocationId,
                    );
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleProfileUpdate(String newName, int? locationId) async {
    if (locationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Harap pilih lokasi."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.updateTenant(
        id: _tenant!.id,
        name: newName,
        tenantLocationId: locationId,
        isOpen: _tenant!.isOpen,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil berhasil diperbarui"),
          backgroundColor: Colors.green,
        ),
      );
      await _loadInitialData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOrderDetailDialog(OrderNotification order) {
    final double totalPrice = order.items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Detail Pesanan', textAlign: TextAlign.center),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      Icons.person_outline,
                      'Pemesan',
                      order.customerName,
                    ),
                    _buildDetailRow(
                      Icons.delivery_dining_outlined,
                      'Porter',
                      order.porterName ?? 'Belum ada',
                    ),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      'Lokasi',
                      order.tenantLocationName,
                    ),
                    const Divider(height: 30, thickness: 1),
                    const Text(
                      'Item Pesanan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      itemBuilder: (context, i) {
                        final item = order.items[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(item.productName)),
                              Text(_priceFormatter.format(item.price)),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 30, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Harga',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _priceFormatter.format(totalPrice),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Tutup"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar dihilangkan untuk menaikkan konten
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
                : _error.isNotEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Terjadi Kesalahan:\n$_error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _loadInitialData,
                  color: primaryColor,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 24), // Spasi disesuaikan
                      Text(
                        'Pesanan Masuk',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildOrderSection(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_tenant == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: const AssetImage('assets/profile.png'),
                    onBackgroundImageError:
                        (e, s) =>
                            const Icon(Icons.storefront_outlined, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tenant!.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tenant!.location,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text("Edit Profil"),
                          onPressed: _showEditProfileDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tombol logout dipindahkan ke sini
                IconButton(
                  icon: const Icon(Icons.logout_outlined),
                  color: Colors.grey[700],
                  tooltip: 'Logout',
                  onPressed: _logout,
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1),
            SwitchListTile(
              title: const Text(
                'Status Toko',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _tenant!.isOpen ? 'Buka (Online)' : 'Tutup (Offline)',
              ),
              value: _tenant!.isOpen,
              onChanged: _toggleOnlineStatus,
              activeColor: Colors.green,
              secondary: Icon(
                _tenant!.isOpen ? Icons.storefront : Icons.no_food,
                color: _tenant!.isOpen ? Colors.green : Colors.red,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text("KELOLA MENU"),
                onPressed: _navigateToMenuPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSection() {
    if (_orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "Belum ada pesanan masuk",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "Saat ada pesanan baru, akan muncul di sini.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildDetailRow(
                  Icons.receipt_long_outlined,
                  'Status',
                  order.orderStatus,
                ),
                _buildDetailRow(
                  Icons.timer_outlined,
                  'Waktu',
                  DateFormat('HH:mm, dd MMM yy').format(order.createdAt),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text("Lihat Detail Pesanan"),
                    onPressed: () => _showOrderDetailDialog(order),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
