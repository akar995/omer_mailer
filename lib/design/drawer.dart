import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omer_mailer/static_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  final TextEditingController smtpHostController = TextEditingController();
  final TextEditingController smtpNameController = TextEditingController();
  final TextEditingController smtpPasswordController = TextEditingController();
  final TextEditingController smtpPortController = TextEditingController();
  final TextEditingController smtpUsernameController = TextEditingController();
  final TextEditingController delayTimerInMillisecond = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey();
  bool enableSSL = false;
  bool allowInsecure = false;
  bool ignoreBadCertificate = false;
  @override
  void dispose() {
    smtpHostController.dispose();
    smtpNameController.dispose();
    smtpPasswordController.dispose();
    smtpPortController.dispose();
    smtpUsernameController.dispose();
    delayTimerInMillisecond.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((shared) {
      smtpNameController.text = shared.getString(StaticInfo.smtpName) ?? '';
      smtpUsernameController.text = shared.getString(
            StaticInfo.smtpUsername,
          ) ??
          '';

      smtpHostController.text = shared.getString(
            StaticInfo.smtpHost,
          ) ??
          '';

      smtpPasswordController.text = shared.getString(
            StaticInfo.smtpPassword,
          ) ??
          '';

      smtpPortController.text = shared.getString(
            StaticInfo.smtpPort,
          ) ??
          '';
      enableSSL = shared.getBool(StaticInfo.smtpEnableSSL) ?? true;
      allowInsecure = shared.getBool(StaticInfo.smtpAllowInsecure) ?? false;
      ignoreBadCertificate =
          shared.getBool(StaticInfo.smtpAllowInsecure) ?? false;
      delayTimerInMillisecond.text =
          shared.getString(StaticInfo.delayTimerInMillisecond) ?? '';
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("SMTP Restored"),
        behavior: SnackBarBehavior.floating,
        width: 140,
        duration: Duration(milliseconds: 1000),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Drawer(
        child: Scaffold(
          body: Form(
            key: _key,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextFormField(
                    controller: smtpNameController,
                    validator: (name) {
                      if (name == null || name.isEmpty) {
                        return 'Please Enter your name';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: "Name",
                      hintText: "Ex: Akar Imdad",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextFormField(
                    controller: smtpUsernameController,
                    validator: (email) {
                      if (email == null || email.isEmpty) {
                        return 'Please Enter your Email';
                      } else {
                        bool emailValid = RegExp(
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                            .hasMatch(email);
                        if (!emailValid) {
                          return "Please Enter a valid Email";
                        }
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: "Email",
                      hintText: "Ex: omar@email.com",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextFormField(
                    controller: smtpHostController,
                    validator: (host) {
                      if (host == null || host.isEmpty) {
                        return 'Please enter host name';
                      } else {
                        if (host.length < 5 || !host.contains('.')) {
                          return 'please enter the valid hostname';
                        }
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: "Host Name",
                      hintText: "Ex: host.com",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextFormField(
                    controller: smtpPasswordController,
                    validator: (pass) {
                      if (pass == null || pass.isEmpty) {
                        return "Please enter the password";
                      } else {
                        if (pass.length < 3) return "Password is too short";
                      }
                      return null;
                    },
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      hintText: "Enter Password",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextFormField(
                    controller: smtpPortController,
                    validator: (port) {
                      if (port == null || port.isEmpty) {
                        return "Please enter the Port";
                      } else {
                        final int? portNumber = int.tryParse(port);
                        if (portNumber == null) {
                          return "Port is number Please Enter correct port number";
                        }
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: "Port",
                      hintText: "Ex 948",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextFormField(
                    controller: delayTimerInMillisecond,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (port) {
                      if (port == null || port.isEmpty) {
                        return "Please enter 0 for no delay";
                      } else {
                        final int? portNumber = int.tryParse(port);
                        if (portNumber == null) {
                          return "timer is number Please Enter correct number";
                        }
                        if (portNumber < 0) {
                          return "timer can't be negative";
                        }
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: "Delay Timer in Millisecond",
                      hintText: "Ex 500 or 1000",
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      Checkbox(
                          value: enableSSL,
                          onChanged: (value) {
                            setState(() {
                              enableSSL = value!;
                            });
                          }),
                      const SizedBox(
                        width: 10,
                      ),
                      const Text("Enable SSL"),
                      const SizedBox(
                        width: 10,
                      ),
                      Checkbox(
                          value: allowInsecure,
                          onChanged: (value) {
                            setState(() {
                              allowInsecure = value!;
                            });
                          }),
                      const SizedBox(
                        width: 10,
                      ),
                      const Text("Allow insecure"),
                    ],
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      Checkbox(
                          value: ignoreBadCertificate,
                          onChanged: (value) {
                            setState(() {
                              ignoreBadCertificate = value!;
                            });
                          }),
                      const SizedBox(
                        width: 10,
                      ),
                      const Text("Ignore Bad Certificate"),
                      const SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton(
                    child: const Text("SAVE"),
                    onPressed: () async {
                      if (_key.currentState?.validate() ?? false) {
                        await SharedPreferences.getInstance().then((shared) {
                          shared.setString(
                              StaticInfo.smtpName, smtpNameController.text);
                          shared.setString(StaticInfo.smtpUsername,
                              smtpUsernameController.text);
                          shared.setString(
                              StaticInfo.smtpHost, smtpHostController.text);
                          shared.setString(StaticInfo.smtpPassword,
                              smtpPasswordController.text);
                          shared.setString(
                              StaticInfo.smtpPort, smtpPortController.text);
                          shared.setString(StaticInfo.delayTimerInMillisecond,
                              delayTimerInMillisecond.text);

                          shared.setBool(
                              StaticInfo.smtpAllowInsecure, allowInsecure);

                          shared.setBool(StaticInfo.smtpEnableSSL, enableSSL);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text("SMTP saved"),
                            behavior: SnackBarBehavior.floating,
                            width: 140,
                          ));
                        });
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
