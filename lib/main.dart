import 'package:flutter/material.dart';
import 'package:omer_mailer/design/drawer.dart';
import 'package:omer_mailer/email_tab.dart';
import 'package:omer_mailer/pdf_tab.dart';
import 'package:omer_mailer/pdf_tab_v2.dart'; // NEW

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omar Mailer',
      theme: ThemeData(),
      home: const MyHomePage(title: 'Omar Mailer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this); // 3 tabs now
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose(); // good hygiene
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Omar Custom Mailer")),
      drawer: MyDrawer(tabController: _tabController),
      body: TabBarView(
        controller: _tabController,
        children: const [
          EmailTab(),
          PDFTab(),
          PDFTabV2(), // NEW tab
        ],
      ),
    );
  }
}
