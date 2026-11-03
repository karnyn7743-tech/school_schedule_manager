import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/notification_service.dart';
import 'views/home_screen.dart';

void main() async {
  // التأكد من تهيئة بيئة تشغيل فلاتر قبل استدعاء الخدمات
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة خدمة التنبيهات الدقيقة والمناطق الزمنية
  await NotificationService().init();

  runApp(const SchoolApp());
}

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدير دوام المدرسة',
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

      // الشاشة الرئيسية
      home: const HomeScreen(),
    );
  }
}
