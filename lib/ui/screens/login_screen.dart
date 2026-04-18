import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/login_profile_model.dart';
import '../../providers/login_profiles_provider.dart';
import '../../providers/mikrotik_provider.dart';
import 'dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileNameCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '8728');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  bool _isLoading = false;
  LoginProfile? _selectedProfile;

  @override
  void dispose() {
    _profileNameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _loadProfileData(LoginProfile profile) {
    setState(() {
      _selectedProfile = profile;
      _profileNameCtrl.text = profile.profileName;
      _hostCtrl.text = profile.host;
      _portCtrl.text = profile.port.toString();
      _userCtrl.text = profile.username;
      _passCtrl.text = profile.password;
    });
  }

  void _clearForm() {
    setState(() {
      _selectedProfile = null;
      _profileNameCtrl.clear();
      _hostCtrl.clear();
      _portCtrl.text = '8728';
      _userCtrl.clear();
      _passCtrl.clear();
    });
  }

  Future<void> _handleDeleteProfile() async {
    if (_selectedProfile != null && _selectedProfile!.id != null) {
      await ref.read(loginProfilesProvider.notifier).deleteProfile(_selectedProfile!.id!);
      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile deleted')),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final profile = LoginProfile(
      id: _selectedProfile?.id,
      profileName: _profileNameCtrl.text.isEmpty ? 'Saved Profile' : _profileNameCtrl.text,
      host: _hostCtrl.text,
      port: int.tryParse(_portCtrl.text) ?? 8728,
      username: _userCtrl.text,
      password: _passCtrl.text,
    );

    // Default save if selectedProfile was null but we clicked connect
    if (_selectedProfile == null) {
      await ref.read(loginProfilesProvider.notifier).addProfile(profile);
    } else {
      await ref.read(loginProfilesProvider.notifier).updateProfile(profile);
    }

    final success = await ref.read(connectionStateProvider.notifier).connect(profile);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to router')),
      );
    }
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1E40AF), // subtle blue
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: type,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF93C5FD), width: 1.5),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2.0),
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(loginProfilesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _WavePainter(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Illustration Header Area Placeholder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LOGIN',
                        style: TextStyle(
                          color: Color(0xFF1D4ED8), // Dark blue like REGISTER
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      // Top Right Illustration approximation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            )
                          ],
                        ),
                        child: const Icon(Icons.router, color: Color(0xFF3B82F6), size: 40),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  if (profiles.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<LoginProfile>(
                                isExpanded: true,
                                hint: const Text('Select Saved Profile'),
                                style: const TextStyle(color: Colors.black, fontSize: 14),
                                value: _selectedProfile,
                                items: profiles.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text('${p.profileName} (${p.host})', style: const TextStyle(fontSize: 14, color: Colors.black)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) _loadProfileData(val);
                                },
                              ),
                            ),
                          ),
                          if (_selectedProfile != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: _handleDeleteProfile,
                              tooltip: 'Delete Profile',
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: _profileNameCtrl,
                            label: 'Profile Name',
                            hint: 'e.g. My Home Router',
                          ),
                          _buildTextField(
                            controller: _hostCtrl,
                            label: 'Host IP/URL',
                            hint: '192.168.88.1',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          _buildTextField(
                            controller: _portCtrl,
                            label: 'Port API',
                            hint: '8728',
                            type: TextInputType.number,
                          ),
                          _buildTextField(
                            controller: _userCtrl,
                            label: 'Username',
                            hint: 'admin',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          _buildTextField(
                            controller: _passCtrl,
                            label: 'Password',
                            hint: '••••••••',
                            obscure: true,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316), // Orange
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                    )
                                  : const Text(
                                      'CONNECT',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: _clearForm,
                              child: const Text(
                                'Clear Form / Add New',
                                style: TextStyle(
                                  color: Color(0xFF1D4ED8), // Blue Text
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50), // bottom padding for waves
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Top light blue wave
    paint.color = const Color(0xFFE0E7FF); 
    var path1 = Path()
      ..lineTo(0, size.height * 0.15)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.20, size.width * 0.5, size.height * 0.12)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.05, size.width, size.height * 0.3)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path1, paint);

    // Top purple blob
    paint.color = const Color(0xFF7C3AED); // Purple
    var path2 = Path()
      ..moveTo(size.width * 0.45, 0)
      ..lineTo(size.width * 0.45, size.height * 0.05)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.28, size.width * 0.85, size.height * 0.25)
      ..quadraticBezierTo(size.width * 1.0, size.height * 0.22, size.width, size.height * 0.0)
      ..close();
    canvas.drawPath(path2, paint);

    // Bottom left blue wave
    paint.color = const Color(0xFF60A5FA); // Blue
    var path3 = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.65, size.width * 0.45, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.95, size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
