import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:omer_mailer/static_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MySmtpService {
  static void sendSmtpEmails(
      {required final String from,
      required final String name,
      required final String to,
      required final String subject,
      required final String body,
      final String? signature,
      required TextEditingController logController,
      required final List<String?> filepath}) async {
    await saveEmailFeilds(
        from: from,
        name: name,
        to: to,
        subject: subject,
        body: body,
        signature: signature);
    SharedPreferences shared = await SharedPreferences.getInstance();
    final smtpName = shared.getString(StaticInfo.smtpName) ?? '';
    final smtpUsername = shared.getString(
          StaticInfo.smtpUsername,
        ) ??
        '';

    final smtpHost = shared.getString(
          StaticInfo.smtpHost,
        ) ??
        '';

    final smtpPassword = shared.getString(
          StaticInfo.smtpPassword,
        ) ??
        '';

    final smtpPort = shared.getString(
          StaticInfo.smtpPort,
        ) ??
        '';
    final enableSSL = shared.getBool(StaticInfo.smtpEnableSSL) ?? true;
    final allowInsceure = shared.getBool(StaticInfo.smtpAllowInsecure) ?? false;
    final ignoreBadCertificate =
        shared.getBool(StaticInfo.smtpIgnoreBadCertificate) ?? false;
    SmtpServer server = SmtpServer(smtpHost,
        name: smtpName,
        password: smtpPassword,
        port: int.parse(smtpPort),
        ssl: enableSSL,
        ignoreBadCertificate: ignoreBadCertificate,
        allowInsecure: allowInsceure,
        username: smtpUsername);
    var connection =
        PersistentConnection(server, timeout: const Duration(seconds: 20));
    try {
      for (int i = 0; i < filepath.length; i++) {
        logController.text =
            logController.text + '\nNow sending Email ${i + 1}';
        final message = Message()
          ..from = Address(from, name)
          ..recipients.addAll(toAd([to]))
          ..text = body
          ..html = signature
          ..attachments.addAll(toAt([filepath[i]]))
          ..subject = subject;
        final sendReport = await connection.send(message);
        logController.text =
            logController.text + '\nMessage sent: ' + sendReport.toString();
      }
    } on MailerException catch (e) {
      logController.text =
          logController.text + e.message + '\nMessage not sent.';

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

  static saveEmailFeilds({
    required final String from,
    required final String name,
    required final String to,
    required final String subject,
    required final String body,
    final String? signature,
  }) async {
    SharedPreferences shared = await SharedPreferences.getInstance();
    shared.setString(
      StaticInfo.mailFrom,
      from,
    );
    shared.setString(StaticInfo.mailName, name);
    shared.setString(StaticInfo.mailTo, to);
    shared.setString(StaticInfo.mailSubject, subject);
    shared.setString(StaticInfo.mailBody, body);
    if (signature != null) {
      shared.setString(StaticInfo.mailSignature, signature);
    } else {
      shared.remove(StaticInfo.mailSignature);
    }
  }

  static Iterable<Address> toAd(Iterable<String>? addresses) =>
      (addresses ?? []).map((a) => Address(a));
  static Iterable<Attachment> toAt(List<String?>? attachments) =>
      (attachments ?? []).map((a) => FileAttachment(File(a!)));
}
