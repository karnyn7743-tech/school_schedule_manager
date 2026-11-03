import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // دوال الاستيراد والتصدير (سنربطها لاحقاً بـ ExcelService مباشرة)
  void _onImportExcelPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جارٍ فتح منتقي ملفات Excel للاستيراد...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onExportExcelPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جارٍ تجهيز ملف Excel للتصدير والمشاركة...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مدير دوام المدرسة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'استيراد جدول من Excel',
            onPressed: _onImportExcelPressed,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'تصدير الجدول إلى Excel',
            onPressed: _onExportExcelPressed,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.notifications_active_outlined),
              text: 'أجراس الحصص',
            ),
            Tab(
              icon: Icon(Icons.assignment_outlined),
              text: 'جدول الأعمال والمهام',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // الواجهة الأولى: تبويب الحصص
          Center(
            child: Text(
              'تبويب أجراس الحصص والفترات الدراسية',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          // الواجهة الثانية: تبويب المهام
          Center(
            child: Text(
              'تبويب جدول الأعمال والمهام الإدارية',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // فتح نافذة الإضافة بحسب التبويب النشط
          if (_tabController.index == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('إضافة حصة / فترة جديدة')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('إضافة مهمة جديدة لجدول الأعمال')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'إضافة حصة' : 'إضافة مهمة'),
      ),
    );
  }
}

