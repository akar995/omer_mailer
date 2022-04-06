import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';
import "package:http/http.dart" as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:omer_mailer/drawer.dart';
import 'package:omer_mailer/my_smtp_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _textControllerSubject.dispose();
    _textControllerBody.dispose();
    _textControllerSignature.dispose();
    super.dispose();
  }

  final List<File> files = [];
  final List<String?> filepath = [];
  AccessCredentials? _credentials;

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
                            hintText: "Enter email body",
                            labelText: "Body",
                            filled: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: TextField(
                          controller: _textControllerSignature,
                          maxLines: 10,
                          decoration: const InputDecoration(
                            hintText: "Enter email body",
                            labelText: "Body",
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                _loginWindowsDesktop();
                              },
                              child: const Text("GET CREDENTIALS")),
                          const SizedBox(
                            width: 10,
                          ),
                          ElevatedButton(
                              onPressed: () {
                                // sendWithGmailMail();
                                MySmtpService.sendSmtpEmails(
                                    from: _textControllerFrom.text,
                                    name: _textControllerFromName.text,
                                    to: _textControllerTo.text,
                                    subject: _textControllerSubject.text,
                                    body: _textControllerBody.text,
                                    logController: _textController,
                                    filepath: filepath);
                              },
                              child: const Text("Send Email"))
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          _credentials == null
                              ? const Text("you are not login")
                              : const Text("you are login")
                        ],
                      ),
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
                    child: Text("${index + 1}" + name),
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
                _textController.text = _textController.text +
                    "\nFile can not be loaded file size is $size \nfile size is more then 25MB\n${element.path}\n";
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

  _loginWindowsDesktop() async {
    var id = ClientId('SecretInfo.identifier', 'SecretInfo.secret');
    List<String> scopes = [
      // 'https://www.googleapis.com/auth/userinfo.email'
      'https://mail.google.com/'
    ];

    var client = http.Client();

    await obtainAccessCredentialsViaUserConsent(
            id, scopes, client, (url) => _lauchAuthInBrowser(url))
        .then((AccessCredentials credentials) {
      _credentials = credentials;
      _textController.text =
          _textController.text + "\nUser credentials gained successfully";
      client.close();
    }).onError((error, stackTrace) {
      print(error);
      _textController.text =
          _textController.text + "\nUser credentials gained failed $error";
    });
  }

  sendWithGmailMail() async {
    SmtpServer smtpServer = gmailSaslXoauth2(
        _textControllerFrom.text, _credentials!.accessToken.data);
    var connection =
        PersistentConnection(smtpServer, timeout: const Duration(seconds: 15));

    // Send multiple mails on one connection:
    try {
      final String from = _textControllerFrom.text;
      final String name = _textControllerFromName.text;
      final String to = _textControllerTo.text;
      final String subject = _textControllerSubject.text;
      final String body = _textControllerBody.text;

      for (int i = 0; i < filepath.length; i++) {
        _textController.text =
            _textController.text + '\nNow sending Email ${i + 1}';

        final message = Message()
          ..from = Address(from, name)
          ..recipients.addAll(MySmtpService.toAd([to]))
          ..text = body
          ..attachments.addAll(MySmtpService.toAt([filepath[i]]));

        message.subject = subject;
        final sendReport = await connection.send(message);
        _textController.text =
            _textController.text + '\nMessage sent: ' + sendReport.toString();
      }
    } on MailerException catch (e) {
      _textController.text = _textController.text + '\nMessage not sent.';

      print('Message not sent.');
      for (var p in e.problems) {
        _textController.text =
            _textController.text + '\nProblem: ${p.code}: ${p.msg}';
      }
    } catch (e) {
      _textController.text = _textController.text + '\nOther exception: $e';
    } finally {
      _textController.text = _textController.text + '\n Task Completed';

      await connection.close();
    }
  }

  void _lauchAuthInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _textController.text = _textController.text + '\nCould not lauch $url';
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
