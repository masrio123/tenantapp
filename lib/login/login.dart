import 'package:flutter/material.dart';
import '../pages/main_page.dart';
import '../services/login_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  bool _isLoading = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Logika untuk menangani proses login, tidak ada perubahan di sini.
  Future<void> handleLogin() async {
    setState(() => _isLoading = true);
    final auth = AuthService();
    final result = await auth.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      final user = result['user'];
      print('Login berhasil! Selamat datang, ${user['nama']}');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false,
      );
    } else {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Login Gagal'),
              content: Text(result['message']),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- UI DIUBAH TOTAL MENGIKUTI DESAIN BARU ---
    return Scaffold(
      body: Stack(
        children: [
          // Latar belakang biru
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1A2F4A),
          ),

          // Konten yang bisa di-scroll
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewportConstraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewportConstraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // KONTEN BAGIAN ATAS (BIRU)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 40, bottom: 20),
                          child: Column(
                            children: [
                              // Ganti dengan path logo Anda jika berbeda
                              Image.asset('assets/logo.png', height: 280),
                              const SizedBox(height: 45),

                              // --- PERMINTAAN ANDA: Menambahkan teks "PORTER APP" ---
                              const Text(
                                'TENANT APP',
                                style: TextStyle(
                                  fontFamily: 'Sen',
                                  fontSize: 30,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // KONTEN BAGIAN BAWAH (PUTIH)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 40,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(35),
                              topRight: Radius.circular(35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EMAIL',
                                style: TextStyle(
                                  fontFamily: 'Sen',
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  fontFamily: 'Sen',
                                  fontSize: 16,
                                ),
                                decoration: _buildInputDecoration(
                                  hintText: 'example@gmail.com',
                                ),
                              ),
                              const SizedBox(height: 25),
                              const Text(
                                'PASSWORD',
                                style: TextStyle(
                                  fontFamily: 'Sen',
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: passwordController,
                                obscureText: _obscureText,
                                style: const TextStyle(
                                  fontFamily: 'Sen',
                                  fontSize: 16,
                                ),
                                decoration: _buildInputDecoration(
                                  hintText: '••••••••',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF7622),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                          : const Text(
                                            'LOG IN',
                                            style: TextStyle(
                                              fontFamily: 'Sen',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
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
          ),
        ],
      ),
    );
  }

  // Helper method untuk styling TextField agar tidak berulang
  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontFamily: 'Sen', color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF6F6F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFFF7622), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: suffixIcon,
    );
  }
}
