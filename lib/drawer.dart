import 'package:flutter/material.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  TextEditingController smtpHostController=TextEditingController();
  TextEditingController smtpNameController=TextEditingController();
  TextEditingController smtpPasswordController=TextEditingController();
  TextEditingController smtpPortController=TextEditingController();
  TextEditingController smtpUsernameController=TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
children: [
  Text("fack"),

],

      ),
    );
  }
}
