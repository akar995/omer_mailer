import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:omer_mailer/design/drawer.dart';
import 'package:omer_mailer/design/is_login.dart';
import 'package:omer_mailer/my_gmail_mail_server.dart';
import 'package:omer_mailer/my_smtp_service.dart';
import 'package:omer_mailer/static_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _textControllerFrom = TextEditingController();
  final TextEditingController _textControllerFromName = TextEditingController();
  final TextEditingController _textControllerTo = TextEditingController();
  final TextEditingController _textControllerCC = TextEditingController();
  final TextEditingController _textControllerSubject = TextEditingController();
  final TextEditingController _textControllerBody = TextEditingController();
  final TextEditingController _textControllerSignature =
      TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _textControllerFrom.dispose();
    _textControllerFromName.dispose();
    _textControllerTo.dispose();
    _textControllerCC.dispose();
    _textControllerSubject.dispose();
    _textControllerBody.dispose();
    _textControllerSignature.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      _textControllerFrom.text = value.getString(StaticInfo.mailFrom) ?? "";
      _textControllerFromName.text = value.getString(StaticInfo.mailName) ?? "";
      _textControllerTo.text = value.getString(StaticInfo.mailTo) ?? "";
      _textControllerCC.text = value.getString(StaticInfo.mailCc) ?? "";
      _textControllerSubject.text =
          value.getString(StaticInfo.mailSubject) ?? "";
      _textControllerBody.text = value.getString(StaticInfo.mailBody) ?? "";
      _textControllerSignature.text =
          value.getString(StaticInfo.mailSignature) ?? "";
    });
  }

  final List<File> files = [];
  final List<String?> filepath = [];

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Omar Custom Mailer"),
      ),
      drawer: const MyDrawer(),
      body: ListView(
        children: [
          SizedBox(
            height: height - 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: width / 2 - 20,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        children: [
                          Flexible(
                            flex: 7,
                            child: TextField(
                              controller: _textControllerFrom,
                              decoration: const InputDecoration(
                                hintText: "Enter sender email address",
                                labelText: "From",
                                filled: true,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Flexible(
                            flex: 3,
                            child: TextField(
                              controller: _textControllerFromName,
                              decoration: const InputDecoration(
                                hintText: "Enter Your Name",
                                labelText: "Name",
                                filled: true,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: _textControllerTo,
                        decoration: const InputDecoration(
                          hintText: "Enter recipient email address",
                          labelText: "To",
                          filled: true,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: _textControllerCC,
                        decoration: const InputDecoration(
                          hintText: "Enter CC email address",
                          labelText: "CC",
                          filled: true,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: _textControllerSubject,
                        decoration: const InputDecoration(
                          hintText: "Enter email Subject",
                          labelText: "Subject",
                          filled: true,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 120,
                        child: TextField(
                          controller: _textControllerBody,
                          maxLines: 10,
                          decoration: const InputDecoration(
                            hintText: "Enter email body with Plan Text",
                            labelText: "Body Plain Text",
                            filled: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: TextField(
                          controller: _textControllerSignature,
                          maxLines: 10000,
                          decoration: const InputDecoration(
                            hintText:
                                "Enter Email body with HTML note: only one type of body can be used at the some time, and HTML will overwrite plain text",
                            labelText: "Body HTML",
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            ElevatedButton(
                                onPressed: () {
                                  MyGmailMailServer.loginWindowsDesktop(
                                      logController: _textController);
                                },
                                child: const Text("GET CREDENTIALS")),
                            const SizedBox(
                              width: 10,
                            ),
                            ElevatedButton(
                                onPressed: () {
                                  if (_textControllerSignature.text
                                      .contains("get omar signature")) {
                                    _textControllerSignature.text =
                                        StaticInfo.omerSignature;
                                  }
                                  MySmtpService.sendSmtpEmails(
                                      from: _textControllerFrom.text,
                                      name: _textControllerFromName.text,
                                      to: _textControllerTo.text,
                                      cc: _textControllerCC.text,
                                      subject: _textControllerSubject.text,
                                      body: _textControllerBody.text,
                                      logController: _textController,
                                      signature: _textControllerSignature.text,
                                      filepath: filepath);
                                },
                                child: const Text("Send Email with SMTP host")),
                            const SizedBox(
                              width: 10,
                            ),
                            ElevatedButton(
                                onPressed: () {
                                  if (_textControllerSignature.text
                                      .contains("get omar signature")) {
                                    _textControllerSignature.text =
                                        StaticInfo.omerSignature;
                                  }
                                  MyGmailMailServer.sendWithGmailMail(
                                    from: _textControllerFrom.text,
                                    name: _textControllerFromName.text,
                                    to: _textControllerTo.text,
                                    subject: _textControllerSubject.text,
                                    body: _textControllerBody.text,
                                    logController: _textController,
                                    cc: _textControllerCC.text,
                                    signature: _textControllerSignature.text,
                                    filepath: filepath,
                                  );
                                },
                                child: const Text("Send Email with Gmail"))
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const IsLogin()
                    ],
                  ),
                ),
                SizedBox(
                  width: width / 2 - 20,
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.onBackground,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ElevatedButton(
                              child: const Text("Clear Log"),
                              onPressed: () {
                                _textController.clear();
                              },
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            const Text("Omar Mailer console Log"),
                          ],
                        ),
                        Expanded(
                          child: ListView(
                            reverse: true,
                            children: [
                              TextField(
                                readOnly: true,
                                controller: _textController,
                                maxLines: null,
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: files.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final String path = files[index].path;
                final String name = path.substring(path.lastIndexOf("\\") + 1);
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text("${index + 1}$name"),
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
          );

          if (result != null) {
            filepath.clear();
            files.clear();
            files.addAll(result.paths.map((path) => File(path!)).toList());

            files.removeWhere((element) {
              double size = element.lengthSync() / (1024 * 1024);

              if (size > 25) {
                _textController.text =
                    "${_textController.text}\nFile can not be loaded file size is $size \nfile size is more then 25MB\n${element.path}\n";
                return true;
              }
              return false;
            });
            for (var element in files) {
              filepath.add(element.path);
            }
            setState(() {});
          } else {
            // User canceled the picker
          }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
