import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';
import "package:http/http.dart" as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:omer_mailer/my_smtp_service.dart';
import 'package:omer_mailer/static_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MyGamilMailServer {
  static loginWindowsDesktop({
    required TextEditingController logController,
  }) async {
    var id = ClientId('SecretInfo.identifier', 'SecretInfo.secret');
    List<String> scopes = [
      // 'https://www.googleapis.com/auth/userinfo.email'
      'https://mail.google.com/'
    ];

    var client = http.Client();

    await obtainAccessCredentialsViaUserConsent(id, scopes, client,
            (url) => lauchAuthInBrowser(url, logController: logController))
        .then((AccessCredentials credentials) async {
      logController.text =
          logController.text + "\nUser credentials gained successfully";
      client.close();
      SharedPreferences shared = await SharedPreferences.getInstance();
      shared.setString(
          StaticInfo.gmailAccessTokenData, credentials.accessToken.data);
      shared.setString(StaticInfo.gmailAccessTokenExpire,
          credentials.accessToken.expiry.toString());
      shared.setString(StaticInfo.gmailIdToken, credentials.idToken ?? '');
      shared.setString(
          StaticInfo.gmailRefreshToken, credentials.refreshToken ?? '');
      credentials.accessToken;
      credentials.idToken;
      credentials.refreshToken;
      // return credentials;
    }).onError((error, stackTrace) {
      logController.text =
          logController.text + "\nUser credentials gained failed $error";
    });
  }

  static void lauchAuthInBrowser(String url,
      {required final TextEditingController logController}) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      logController.text = logController.text + '\nCould not lauch $url';
    }
  }

  static sendWithGmailMail(
      {required final String from,
      required final String name,
      required final String to,
      required final String subject,
      required final String body,
      final String? signature,
      required TextEditingController logController,
      required final List<String?> filepath}) async {
    SharedPreferences shared = await SharedPreferences.getInstance();
    SmtpServer smtpServer = gmailSaslXoauth2(
        from, shared.getString(StaticInfo.gmailAccessTokenData) ?? '');
    var connection =
        PersistentConnection(smtpServer, timeout: const Duration(seconds: 15));

    // Send multiple mails on one connection:
    try {
      for (int i = 0; i < filepath.length; i++) {
        logController.text =
            logController.text + '\nNow sending Email ${i + 1}';

        final message = Message()
          ..from = Address(from, name)
          ..recipients.addAll(MySmtpService.toAd([to]))
          ..text = body
          ..attachments.addAll(MySmtpService.toAt([filepath[i]]));

        message.subject = subject;
        final sendReport = await connection.send(message);
        logController.text =
            logController.text + '\nMessage sent: ' + sendReport.toString();
      }
    } on MailerException catch (e) {
      logController.text = logController.text + '\nMessage not sent.';
      for (var p in e.problems) {
        logController.text =
            logController.text + '\nProblem: ${p.code}: ${p.msg}';
      }
    } catch (e) {
      logController.text = logController.text + '\nOther exception: $e';
    } finally {
      logController.text = logController.text + '\n Task Completed';

      await connection.close();
    }
  }
}
