import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:omer_mailer/pdf_generator_control_risk.dart';
import 'package:omer_mailer/static_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------- TOP-LEVEL EXTENSION (must NOT be inside a class) ----------
extension ExcelRowSafeAt on List<ex.Data?> {
  ex.Data? safeAt(int? i) {
    if (i == null || i < 0 || i >= length) return null;
    return this[i];
  }
}

class MyDrawer extends StatefulWidget {
  const MyDrawer({
    required this.tabController,
    super.key,
  });
  final TabController tabController;

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
      smtpUsernameController.text =
          shared.getString(StaticInfo.smtpUsername) ?? '';
      smtpHostController.text = shared.getString(StaticInfo.smtpHost) ?? '';
      smtpPasswordController.text =
          shared.getString(StaticInfo.smtpPassword) ?? '';
      smtpPortController.text = shared.getString(StaticInfo.smtpPort) ?? '';
      enableSSL = shared.getBool(StaticInfo.smtpEnableSSL) ?? true;
      allowInsecure = shared.getBool(StaticInfo.smtpAllowInsecure) ?? false;
      ignoreBadCertificate =
          shared.getBool(StaticInfo.smtpIgnoreBadCertificate) ?? false;
      delayTimerInMillisecond.text =
          shared.getString(StaticInfo.delayTimerInMillisecond) ?? '';
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("SMTP Restored"),
          behavior: SnackBarBehavior.floating,
          width: 140,
          duration: Duration(milliseconds: 1000),
        ));
      }
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
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          enableFeedback: false,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: widget.tabController.index == 0
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              "Email Tab",
                              style: TextStyle(
                                fontWeight: widget.tabController.index == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          onTap: () {
                            widget.tabController.animateTo(0);
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          enableFeedback: false,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: widget.tabController.index == 1
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              "PDF Tab",
                              style: TextStyle(
                                fontWeight: widget.tabController.index == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          onTap: () {
                            widget.tabController.animateTo(1);
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          enableFeedback: false,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: widget.tabController.index == 2
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              "PDF Tab 2",
                              style: TextStyle(
                                fontWeight: widget.tabController.index == 2
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          onTap: () {
                            widget.tabController.animateTo(2);
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // SMTP Fields
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
                                r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$")
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
                        if (pass.length < 3) {
                          return "Password is too short";
                        }
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
                      const SizedBox(width: 10),
                      Checkbox(
                          value: enableSSL,
                          onChanged: (value) {
                            setState(() {
                              enableSSL = value!;
                            });
                          }),
                      const SizedBox(width: 10),
                      const Text("Enable SSL"),
                      const SizedBox(width: 10),
                      Checkbox(
                          value: allowInsecure,
                          onChanged: (value) {
                            setState(() {
                              allowInsecure = value!;
                            });
                          }),
                      const SizedBox(width: 10),
                      const Text("Allow insecure"),
                    ],
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 10),
                      Checkbox(
                          value: ignoreBadCertificate,
                          onChanged: (value) {
                            setState(() {
                              ignoreBadCertificate = value!;
                            });
                          }),
                      const SizedBox(width: 10),
                      const Text("Ignore Bad Certificate"),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),

                // ======= NEW: Bulk PDF from Excel (Control Risk) =======
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Bulk PDF (Control Risk)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Generate PDFs from Excel"),
                    onPressed: _openExcelAndGenerateControlRiskPdfs,
                  ),
                ),
                // =======================================================

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
                          shared.setBool(StaticInfo.smtpIgnoreBadCertificate,
                              ignoreBadCertificate);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text("SMTP saved"),
                              behavior: SnackBarBehavior.floating,
                              width: 140,
                            ));
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =================== Bulk PDF Helpers ===================

  int getHeaderRow(List<List<ex.Data?>> rows) {
    for (int headerIndexAt = 0; headerIndexAt < 14; headerIndexAt++) {
      final headerRow = rows[headerIndexAt];

      if (headerRow[0]?.value?.toString().trim() == 'Product' &&
          headerRow[1]?.value?.toString().trim() == 'Airline/Hotel/Visa/Car' &&
          headerRow[2]?.value?.toString().trim() == 'Ticket No / Voucher No') {
        return headerIndexAt;
      }
    }
    return -1;
  }

  Future<void> _openExcelAndGenerateControlRiskPdfs() async {
    try {
      // 1) Pick the Excel file
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result == null) return;

      Uint8List bytes;
      if (kIsWeb) {
        if (result.files.single.bytes == null) {
          _toast('No file bytes received.');
          return;
        }
        bytes = Uint8List.fromList(result.files.single.bytes!);
      } else {
        final path = result.files.single.path;
        if (path == null) {
          _toast('Invalid file path.');
          return;
        }
        bytes = await File(path).readAsBytes();
      }

      // 2) Decode Excel safely (catch numFmt errors)
      ex.Excel book;
      try {
        book = ex.Excel.decodeBytes(bytes);
      } catch (e) {
        _errorDialog(
          title: 'Excel Styles Error',
          message: "Couldn't open the workbook (styles error).\n"
              "Open it in Excel/LibreOffice and Save As a new .xlsx, then try again.\n\n"
              "Details: $e",
        );
        return;
      }

      if (book.tables.isEmpty) {
        _toast('No sheets found.');
        return;
      }
      // Take first sheet
      final sheetName = book.tables.keys.first;
      final sheet = book.tables[sheetName]!;
      if (sheet.rows.isEmpty) {
        _toast('Sheet "$sheetName" is empty.');
        return;
      }
      int headerStartAt = getHeaderRow(sheet.rows);
      // 3) Build header map (normalize)
      final headerRow = sheet.rows[headerStartAt];
      final headerIndex = <String, int>{};
      for (int i = 0; i < headerRow.length; i++) {
        final label = _cellString(headerRow[i]);
        if (label.isNotEmpty) {
          headerIndex[_norm(label)] = i;
        }
      }

      // Required columns (normalized keys with synonyms)
      int? col(String key, List<String> aliases) {
        for (final k in [key, ...aliases]) {
          final idx = headerIndex[_norm(k)];
          if (idx != null) return idx;
        }
        return null;
      }

      final idxProduct = col('Product', []);
      final idxSupplier =
          col('Airline/Hotel/Visa/Car', ['Airline Hotel Visa Car']);
      final idxTicket =
          col('Ticket No / Voucher No', ['Ticket No', 'Voucher No']);
      final idxIssuedDate = col(
          'Ticket issued date', ['Issue Date', 'Ticket Date', 'Invoice Date']);
      final idxPNR = col('Airline PNR', ['PNR']);
      final idxPax = col('Passenger Name', ['Passenger']);
      final idxInvNo =
          col('Invoiceno.', ['Invoice No', 'Invoice Number', 'Invoiceno']);
      final idxAmount = col('Invoiceamount', ['Invoice Amount', 'Amount']);
      final idxClass = col('CLASS', ['Class']);
      final idxDepDate = col('Departure Date', ['Depart Date']);
      final idxRetDate = col('RETURN DATE', ['Return Date']);
      final idxRouting = col('Routing', ['Route']);
      final idxCheckIn = col('Check-in', ['Check In']);
      final idxCheckOut = col('Check-out', ['Check Out']);
      final idxBookedBy = col('Booked by', ['Booked By']);
      final idxProjCode = col('Project Code', []);
      final idxLocCode = col('Location Code', []);
      final idxResType = col('Reservation Type', []);
      final idxReason =
          col('Reason for travel', ['Reason For Travel', 'Reason']);

      final missing = <String>[];
      void req(String name, int? idx) {
        if (idx == null) missing.add(name);
      }

      req('Product', idxProduct);
      req('Airline/Hotel/Visa/Car', idxSupplier);
      req('Ticket No / Voucher No', idxTicket);
      req('Ticket issued date', idxIssuedDate);
      req('Passenger Name', idxPax);
      req('Invoiceno.', idxInvNo);
      req('Invoiceamount', idxAmount);

      if (missing.isNotEmpty) {
        _errorDialog(
          title: 'Missing Columns',
          message:
              'These required columns were not found:\n• ${missing.join('\n• ')}\n\n'
              'Please ensure the header names match the sample.',
        );
        return;
      }

      // 4) Ask for output directory (desktop) or use Save dialog per file (web/mobile)
      String? outDir;
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        outDir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Choose folder to save PDFs',
        );
        if (outDir == null) {
          _toast('No folder selected.');
          return;
        }
      }

      // 5) Process rows
      int created = 0;
      for (int r = headerStartAt; r < sheet.rows.length; r++) {
        try {
          final row = sheet.rows[r];

          String invoiceNo = _cellString(row.safeAt(idxInvNo!));
          if (invoiceNo.isEmpty) {
            // skip empty rows
            continue;
          }

          // Values
          final product = _cellString(row.safeAt(idxProduct!));
          final supplier = _cellString(row.safeAt(idxSupplier!));
          final ticket = _cellString(row.safeAt(idxTicket!));
          final issuedDate = _cellString(row.safeAt(idxIssuedDate!));
          final pnr = _cellString(row.safeAt(idxPNR ?? -1));
          final pax = _cellString(row.safeAt(idxPax!));
          final amountStr = _cellString(row.safeAt(idxAmount!));
          final cls = _cellString(row.safeAt(idxClass ?? -1));
          final depDate = _cellString(row.safeAt(idxDepDate ?? -1));
          final retDate = _cellString(row.safeAt(idxRetDate ?? -1));
          final routing = _cellString(row.safeAt(idxRouting ?? -1));
          final checkIn = _cellString(row.safeAt(idxCheckIn ?? -1));
          final checkOut = _cellString(row.safeAt(idxCheckOut ?? -1));
          final bookedBy = _cellString(row.safeAt(idxBookedBy ?? -1));
          final projCode = _cellString(row.safeAt(idxProjCode ?? -1));
          final locCode = _cellString(row.safeAt(idxLocCode ?? -1));
          final resType = _cellString(row.safeAt(idxResType ?? -1));
          final reason = _cellString(row.safeAt(idxReason ?? -1));

          // Amount parse (tolerant)
          final amt = _parseAmount(amountStr);

          // Invoice date and label
          final invDateStr = issuedDate.isNotEmpty ? issuedDate : '';
          final invDateLabel = _monthLabelFromDateLike(invDateStr) ?? '---';

          // 6) Generate PDF bytes
          final bytes = await generateControlRiskInvoicePdf(
            invoiceDate: invDateStr.isNotEmpty ? invDateStr : '—',
            invoiceNo: invoiceNo,
            product: product,
            supplierName: supplier,
            ticketOrVoucherNo: ticket,
            ticketIssuedDate: issuedDate,
            airlinePNR: pnr,
            passengerName: pax,
            internalInvoiceNo: invoiceNo,
            className: cls,
            departureDate: depDate,
            returnDate: retDate,
            routing: routing,
            checkIn: checkIn,
            checkOut: checkOut,
            bookedBy: bookedBy,
            projectCode: projCode,
            locationCode: locCode,
            reservationType: resType,
            reasonForTravel: reason,
            amountNumeric: amt,
            amountCurrency: 'USD',
            billTo: 'CONTROL RISK',
            invoiceMonthLabel: invDateLabel,
          );

          // 7) Save
          final safeName =
              'INV_${invoiceNo.replaceAll(RegExp(r"[^A-Za-z0-9._-]"), "_")}';
          if (outDir != null) {
            final file = File('$outDir/$safeName.pdf');
            await file.writeAsBytes(bytes, flush: true);
          } else {
            // web / mobile -> show Save As per file
            await FileSaver.instance.saveFile(
              name: safeName,
              ext: 'pdf',
              bytes: bytes,
            );
          }
          created++;
        } catch (e) {
          print(e);
        }
      }

      _toast('Generated $created PDF(s).');
    } catch (e) {
      _errorDialog(title: 'Error', message: e.toString());
    }
  }

  // Normalize header text
  String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Convert any excel cell to a trimmed string.
  /// Works around typed CellValue wrappers by using toString() + cleaning.
  String _cellString(ex.Data? c) {
    if (c == null || c.value == null) return '';
    final raw = c.value!;
    final s = raw.toString();

    // Try to detect date-like strings and format as yyyy-mm-dd
    final m = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(s);
    if (m != null) {
      final y = m.group(1)!.padLeft(4, '0');
      final mm = m.group(2)!.padLeft(2, '0');
      final dd = m.group(3)!.padLeft(2, '0');
      return '$y-$mm-$dd';
    }
    return s.trim();
  }

  num _parseAmount(String s) {
    final cleaned = s.replaceAll(',', '');
    final m = RegExp(r'[-+]?\d+(\.\d+)?').firstMatch(cleaned);
    if (m == null) return 0;
    return num.tryParse(m.group(0)!) ?? 0;
  }

  String? _monthLabelFromDateLike(String s) {
    // accept yyyy-mm-dd or dd/mm/yyyy etc
    final m1 =
        RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$').firstMatch(s.trim());
    if (m1 != null) {
      final y = int.tryParse(m1.group(1)!);
      final mo = int.tryParse(m1.group(2)!);
      if (y != null && mo != null && mo >= 1 && mo <= 12) {
        const months = [
          'JAN',
          'FEB',
          'MAR',
          'APR',
          'MAY',
          'JUN',
          'JUL',
          'AUG',
          'SEP',
          'OCT',
          'NOV',
          'DEC'
        ];
        return '${months[mo - 1]}-$y';
      }
    }
    // try dd/mm/yyyy
    final m2 =
        RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(s.trim());
    if (m2 != null) {
      final mo = int.tryParse(m2.group(2)!);
      final y = int.tryParse(m2.group(3)!);
      if (y != null && mo != null && mo >= 1 && mo <= 12) {
        const months = [
          'JAN',
          'FEB',
          'MAR',
          'APR',
          'MAY',
          'JUN',
          'JUL',
          'AUG',
          'SEP',
          'OCT',
          'NOV',
          'DEC'
        ];
        return '${months[mo - 1]}-$y';
      }
    }
    return null;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _errorDialog({required String title, required String message}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))
        ],
      ),
    );
  }
}
