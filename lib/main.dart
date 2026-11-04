import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/activation_service.dart';
import 'services/notification_service.dart';
import 'views/activation/activation_screen.dart';
import 'views/home_screen.dart';

void main() async {
  // التأكد من تهيئة بيئة تشغيل فلاتر قبل استدعاء الخدمات
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة خدمة التنبيهات الدقيقة والمناطق الزمنية
  await NotificationService().init();

  // فحص حالة التفعيل للجهاز الحالي
  final bool isActivated = await ActivationService.isAppActivated();

  runApp(SchoolApp(isActivated: isActivated));
}

class SchoolApp extends StatelessWidget {
  final bool isActivated;

  const SchoolApp({super.key, required this.isActivated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدير مهام المدرسة',
      debugShowCheckedModeBanner: false,

      // دعم اللغة العربية والمحاذاة من اليمين لليسار (RTL)
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ثيم التطبيق
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // كحلي إداري رسمي
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF0D9488),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
      ),

      // توجيه المستخدم لشاشة التفعيل إذا لم يكن الجهاز مفعلاً، أو للشاشة الرئيسية إن كان مفعلاً
      home: isActivated ? const HomeScreen() : const ActivationScreen(),
    );
  }
}
