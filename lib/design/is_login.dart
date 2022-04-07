import 'package:flutter/material.dart';
import 'package:omer_mailer/static_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IsLogin extends StatefulWidget {
  const IsLogin({Key? key}) : super(key: key);

  @override
  State<IsLogin> createState() => _IsLoginState();
}

class _IsLoginState extends State<IsLogin> {
  bool isLogin = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((value) {
      String? token = value.getString(StaticInfo.gmailAccessTokenData);
      if (token != null && token.isNotEmpty) {
        setState(() {
          isLogin = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLogin
        ? const Text(
            "Gmail credential is available",
            style: TextStyle(color: Colors.green),
          )
        : const Text(
            "Gmail credential is not available",
            style: TextStyle(color: Colors.red),
          );
  }
}
