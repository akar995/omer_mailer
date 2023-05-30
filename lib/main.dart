import 'package:flutter/material.dart';
import 'package:omer_mailer/design/drawer.dart';
import 'package:omer_mailer/email_tab.dart';
import 'package:omer_mailer/pdf_tab.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late final TabController _tabController;
  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Omar Custom Mailer"),
      ),
      drawer: MyDrawer(tabController: _tabController),
      body: TabBarView(
        controller: _tabController,
        children: const [EmailTab(), PDFTab()],
      ),
    );
  }
}
