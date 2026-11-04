import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/activation_service.dart';
import '../home_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController _keyController = TextEditingController();
  String _deviceId = "جاري القراءة...";
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await ActivationService.getDeviceId();
    setState(() {
      _deviceId = id;
    });
  }

  Future<void> _verifyAndActivate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final bool success =
        await ActivationService.activateWithKey(_keyController.text);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = "مفتاح التفعيل غير صحيح لهذا الجهاز!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفعيل التطبيق'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.security, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'نسخة غير مفعلة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'يرجى نسخ رمز هذا الجهاز وإرساله للمسؤول للحصول على مفتاح التفعيل الدائم الخاص بك.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // بطاقة عرض معرّف الجهاز
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Text(
                      'رمز الجهاز الخاص بك (Device ID):',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _deviceId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _deviceId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ رمز الجهاز بنجاح!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('نسخ الرمز'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        elevation: 0,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // حقل إدخال مفتاح التفعيل
              TextField(
                controller: _keyController,
                textAlign: TextAlign.center,
                style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'أدخل مفتاح التفعيل المستلم',
                  hintText: 'XXXX-XXXX-XXXX-XXXX',
                  errorText: _errorMessage,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : _verifyAndActivate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('تأكيد وتفعيل', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
