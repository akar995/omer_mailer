import 'dart:async';
import 'dart:io';

import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omer_mailer/ExcelHelper.dart';
import 'package:omer_mailer/pdf_generator.dart';

import 'package:printing/printing.dart';

class PDFTab extends StatefulWidget {
  const PDFTab({super.key});

  @override
  State<PDFTab> createState() => _PDFTabState();
}

class _PDFTabState extends State<PDFTab> {
  List<InvoiceSegmentData> invoices = [];
  Future<Uint8List>? pdf;

  InvoiceHotelData? hotelInvoice;
  ex.Excel? invoiceExcel;
  ex.Excel? segmentationExcel;
  bool showPdfSide = true;
  bool changeInvoiceText = false;
  late final TextEditingController _invoiceTextController;
  late final TextEditingController _dateTextController;
  late final TextEditingController _dateOfSupplyTextController;
  late final TextEditingController _costCenterTextController;
  late final TextEditingController _employeeIdTextController;
  late final TextEditingController _businessUnitTextController;
  late final TextEditingController _bookedByTextController;
  late final TextEditingController _bookNumberTextController;
  late final TextEditingController _firstPriceTextController;
  late final TextEditingController _approverTextController;
  late final TextEditingController _passengerNameTextController;
  late final TextEditingController _taxTextController;
  late final TextEditingController _ticketNumberController;
  late final TextEditingController _ticketBaseFareController;
  // late final TextEditingController _ticketClassCodeController;

  @override
  initState() {
    super.initState();

    _invoiceTextController = TextEditingController();
    _dateTextController = TextEditingController();
    _dateOfSupplyTextController = TextEditingController();
    _costCenterTextController = TextEditingController(text: '1425');
    _employeeIdTextController = TextEditingController();
    _businessUnitTextController =
        TextEditingController(text: "IRQ - SNC Lavalin UK Limited-Iraq Branch");
    _bookedByTextController = TextEditingController(text: "NEMAT");
    _bookNumberTextController = TextEditingController();
    _firstPriceTextController = TextEditingController();
    _approverTextController = TextEditingController();
    _passengerNameTextController = TextEditingController();
    _taxTextController = TextEditingController();
    _ticketNumberController = TextEditingController();
    _ticketBaseFareController = TextEditingController();
    // _ticketClassCodeController = TextEditingController();
  }

  bool isLoading = false;
  @override
  void dispose() {
    _invoiceTextController.dispose();
    _dateTextController.dispose();
    _dateOfSupplyTextController.dispose();
    _costCenterTextController.dispose();
    _employeeIdTextController.dispose();
    _businessUnitTextController.dispose();
    _bookedByTextController.dispose();
    _bookNumberTextController.dispose();
    _firstPriceTextController.dispose();
    _approverTextController.dispose();
    _passengerNameTextController.dispose();
    _taxTextController.dispose();
    _ticketNumberController.dispose();
    _ticketBaseFareController.dispose();

    super.dispose();
  }

  Timer? _debounce;

  void debounceSetState() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      setState(() {});
    });
  }

  onTextChange(value) {
    debounceSetState();
  }

  filesCanNotSave() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('File failed Save'),
              content: const Text(
                  'Please make sure you have a folder named "invoices" in your downloads folder\n'
                  'and that you have pdf and excel folders in it'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'))
              ],
            ));
  }

  Future saveFiles({
    final bool savePdf = false,
    final bool saveInvoice = false,
    final bool saveSegment = false,
  }) async {
    FileSaver instance = FileSaver.instance;

    if (savePdf && pdf != null) {
      final String pdfName = "invoices/pdf/INV ${_invoiceTextController.text}";
      String pdfPath = await instance.saveFile(
        name: pdfName,
        ext: 'pdf',
        bytes: await pdf,
      );
      if (pdfPath.contains("Something went wrong")) {
        filesCanNotSave();
        throw Exception("Something went wrong");
      }
    }
    if (saveInvoice && invoiceExcel != null) {
      String invoicePath = await instance.saveFile(
        name: 'invoices/excel/invoiceExcel',
        ext: 'xlsx',
        bytes: Uint8List.fromList(invoiceExcel!.encode()!),
      );
      if (invoicePath.contains("Something went wrong")) {
        filesCanNotSave();
        throw Exception("Something went wrong");
      }
    }
    if (saveSegment && segmentationExcel != null) {
      String segmentPath = await instance.saveFile(
        name: 'invoices/excel/segmentationExcel',
        ext: 'xlsx',
        bytes: Uint8List.fromList(segmentationExcel!.encode()!),
      );
      if (segmentPath.contains("Something went wrong")) {
        filesCanNotSave();
        throw Exception("Something went wrong");
      }
    }
  }

  bool checkForDuplicatedTicketNumber() {
    bool isTicketNumberDuplicated = false;
    for (var table in invoiceExcel!.tables.keys) {
      for (var row in invoiceExcel!.tables[table]!.rows) {
        if (row[0]?.value.toString().trim() ==
            _invoiceTextController.text.trim()) {
          isTicketNumberDuplicated = true;
          break;
        }
      }
      if (isTicketNumberDuplicated) {
        break;
      }
    }

    return isTicketNumberDuplicated;
  }

  insertInvoiceHotelRow() {
    for (var table in invoiceExcel!.tables.keys) {
      // for (int i = 0; i < invoices.length; i++) {

      final int totalAmount =
          (int.tryParse(_firstPriceTextController.text) ?? 0) +
              (int.tryParse(_taxTextController.text) ?? 0);
      final int taxAmount =
          totalAmount - (int.tryParse(_ticketBaseFareController.text) ?? 0);

      final InvoiceStructure invoice = InvoiceStructure(
          recordKey: _invoiceTextController.text,
          invoiceDate: _dateTextController.text,
          bookedDate: _dateOfSupplyTextController.text,
          salutation: _approverTextController.text,
          passengerName: _passengerNameTextController.text,
          bookingType: "HTL",
          documentNumber: _bookNumberTextController.text,
          recordLocatorPNR: _bookNumberTextController.text,
          vendorCode: hotelInvoice!.hotelName.text,
          outBoundDate: hotelInvoice!.checkIn.text,
          departTime: '',
          arrivalDate: hotelInvoice!.checkOut.text,
          arrivalTime: '',
          serviceCategory: '',
          totalAmountLondonSky: totalAmount,
          destinationCode: hotelInvoice!.hotelDestination.text,
          passengerID: _employeeIdTextController.text,
          lskFee: _taxTextController.text,
          baseFare: _ticketBaseFareController.text,
          taxAmount: taxAmount,
          segmentLeg: 1,
          airCode: '',
          originCode: '',
          flightNumber: '');
      final List<ex.CellValue> test = [];
      invoice.row.forEach((element) {
        test.add(ex.TextCellValue(element.toString()));
      });
      invoiceExcel?.appendRow(table, test);
    }
  }

  insertInvoiceRow() {
    for (var table in invoiceExcel!.tables.keys) {
      for (int i = 0; i < invoices.length; i++) {
        final element = invoices[i];

        final int totalAmount =
            (int.tryParse(_firstPriceTextController.text) ?? 0) +
                (int.tryParse(_taxTextController.text) ?? 0);
        final int taxAmount =
            totalAmount - (int.tryParse(_ticketBaseFareController.text) ?? 0);
        final InvoiceStructure invoice = InvoiceStructure(
            recordKey: _invoiceTextController.text,
            invoiceDate: _dateTextController.text,
            bookedDate: _dateOfSupplyTextController.text,
            salutation: _approverTextController.text,
            passengerName: _passengerNameTextController.text,
            bookingType: "AIR",
            documentNumber: _ticketNumberController.text,
            recordLocatorPNR: _bookNumberTextController.text,
            vendorCode: element.code.text,
            outBoundDate: element.departDate.text,
            departTime: element.departTime.text,
            arrivalDate: invoices[invoices.length - 1].arrivalDate.text,
            arrivalTime: invoices[invoices.length - 1].arrivalTime.text,
            serviceCategory: element.classCode.text,
            totalAmountLondonSky: totalAmount,
            destinationCode: element.destinationCode.text,
            passengerID: _employeeIdTextController.text,
            lskFee: _taxTextController.text,
            baseFare: _ticketBaseFareController.text,
            taxAmount: taxAmount,
            segmentLeg: i + 1,
            airCode: element.originCode.text,
            originCode: element.originCode.text,
            flightNumber: element.code.text);

        if (i == 0) {
          final List<ex.CellValue> test = [];
          invoice.row.forEach((element) {
            test.add(ex.TextCellValue(element.toString()));
          });
          invoiceExcel?.appendRow(table, test);
        }
      }
    }
  }

  insertSegmentationRow() {
    for (var table in segmentationExcel!.tables.keys) {
      for (int i = 0; i < invoices.length; i++) {
        final element = invoices[i];

        final int totalAmount =
            (int.tryParse(_firstPriceTextController.text) ?? 0) +
                (int.tryParse(_taxTextController.text) ?? 0);
        final int taxAmount =
            totalAmount - (int.tryParse(_ticketBaseFareController.text) ?? 0);
        final InvoiceStructure invoice = InvoiceStructure(
          recordKey: _invoiceTextController.text,
          invoiceDate: _dateTextController.text,
          bookedDate: _dateOfSupplyTextController.text,
          salutation: _approverTextController.text,
          passengerName: _passengerNameTextController.text,
          bookingType: "AIR",
          documentNumber: _ticketNumberController.text,
          recordLocatorPNR: _bookNumberTextController.text,
          vendorCode: element.routeName.text,
          outBoundDate: element.departDate.text,
          departTime: element.departTime.text,
          arrivalDate: element.arrivalDate.text,
          arrivalTime: element.arrivalTime.text,
          serviceCategory: element.classCode.text,
          totalAmountLondonSky: totalAmount,
          destinationCode: element.destinationCode.text,
          passengerID: _employeeIdTextController.text,
          lskFee: _taxTextController.text,
          baseFare: _ticketBaseFareController.text,
          taxAmount: taxAmount,
          segmentLeg: i + 1,
          airCode: element.originCode.text,
          originCode: element.originCode.text,
          flightNumber: element.code.text,
        );
        final List<ex.CellValue> test = [];
        invoice.segment.forEach((element) {
          test.add(ex.TextCellValue(element.toString()));
        });
        segmentationExcel?.appendRow(table, test);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () async {
                saveFiles(saveInvoice: true, saveSegment: true);
              },
              child: const Icon(Icons.save_alt_outlined),
            ),
            const SizedBox(
              height: 10,
            ),
            FloatingActionButton(
              onPressed: () async {
                setState(() {
                  changeInvoiceText = !changeInvoiceText;
                });
              },
              child: const Icon(Icons.fingerprint),
            ),
            const SizedBox(
              height: 10,
            ),
            FloatingActionButton(
              onPressed: () async {
                setState(() {
                  showPdfSide = !showPdfSide;
                });
              },
              child:
                  Icon(showPdfSide ? Icons.visibility : Icons.visibility_off),
            ),
            const SizedBox(
              height: 10,
            ),
            FloatingActionButton(
              onPressed: () async {
                showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        child: SizedBox(
                          width: 400,
                          height: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: () {
                                    print('dasd');
                                    FilePicker.platform
                                        .pickFiles(
                                      allowMultiple: false,
                                    )
                                        .then((result) {
                                      if (result != null) {
                                        if (kIsWeb) {
                                          final ex.Excel invoice =
                                              ex.Excel.decodeBytes(
                                                  Uint8List.fromList(
                                                      result.files[0].bytes!));
                                          setState(() {
                                            invoiceExcel = invoice;
                                          });
                                          Navigator.pop(context);
                                        } else {
                                          File(result.files[0].path!)
                                              .readAsBytes()
                                              .then((value) {
                                            final ex.Excel invoice =
                                                ex.Excel.decodeBytes(value);
                                            setState(() {
                                              invoiceExcel = invoice;
                                            });
                                            Navigator.pop(context);
                                          });
                                        }
                                      }
                                    });
                                  },
                                  child: DecoratedBox(
                                    decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(4))),
                                    child: SizedBox(
                                      width: 120,
                                      height: 30,
                                      child: Center(
                                        child: Text(
                                          invoiceExcel == null
                                              ? "Choose invoice"
                                              : 'Invoice picked',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: () {
                                    FilePicker.platform
                                        .pickFiles(
                                      allowMultiple: false,
                                    )
                                        .then((result) {
                                      if (result != null) {
                                        print(kIsWeb);
                                        if (kIsWeb) {
                                          final ex.Excel invoice =
                                              ex.Excel.decodeBytes(result
                                                  .files[0].bytes!
                                                  .toList());
                                          setState(() {
                                            segmentationExcel = invoice;
                                          });
                                          Navigator.pop(context);
                                        } else {
                                          File(result.files[0].path!)
                                              .readAsBytes()
                                              .then((value) {
                                            final ex.Excel invoice =
                                                ex.Excel.decodeBytes(value);
                                            setState(() {
                                              segmentationExcel = invoice;
                                            });
                                            Navigator.pop(context);
                                          });
                                        }
                                      }
                                    });
                                  },
                                  child: DecoratedBox(
                                    decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(4))),
                                    child: SizedBox(
                                      width: 160,
                                      height: 30,
                                      child: Center(
                                        child: Text(
                                          segmentationExcel == null
                                              ? "Choose Segmentation"
                                              : 'Segmentation picked',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                // final excel = ex.Excel.createExcel();
                // excel.setDefaultSheet('Sheet1');
                // insertRow(excel);
                // final bytes = excel.save();
                // final blob = html.Blob([bytes], 'application/vnd.ms-excel');
                // final url = html.Url.createObjectUrlFromBlob(blob);
                // html.window.open(url, "_blank");
                // html.Url.revokeObjectUrl(url);
              },
              child: const Icon(Icons.save),
            ),
          ],
        ),
        body: Row(
          children: [
            Expanded(
                child: ListView(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 200,
                        child: TextField(
                          onChanged: onTextChange,
                          controller: _invoiceTextController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Number',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 200,
                        child: TextField(
                          onChanged: onTextChange,
                          controller: _dateTextController,
                          decoration: const InputDecoration(
                            labelText: 'Date',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 200,
                        child: TextField(
                          onChanged: onTextChange,
                          controller: _dateOfSupplyTextController,
                          decoration: const InputDecoration(
                            labelText: 'Date of Supply',
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 200,
                        child: TextField(
                          onChanged: onTextChange,
                          controller: _costCenterTextController,
                          decoration: const InputDecoration(
                            labelText: 'Cost Center',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 200,
                        child: TextField(
                          onChanged: onTextChange,
                          controller: _employeeIdTextController,
                          decoration: const InputDecoration(
                            labelText: 'Employee ID',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 200,
                        child: TextField(
                          onChanged: onTextChange,
                          controller: _businessUnitTextController,
                          decoration: const InputDecoration(
                            labelText: 'Business Unit',
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 200,
                        child: TextField(
                          onChanged: onTextChange,
                          controller: _passengerNameTextController,
                          decoration: const InputDecoration(
                            labelText: 'Passenger Name',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 200,
                        child: TextField(
                          onChanged: onTextChange,
                          controller: _bookedByTextController,
                          decoration: const InputDecoration(
                            labelText: 'Booked By',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 200,
                        child: TextField(
                          onChanged: onTextChange,
                          controller: _bookNumberTextController,
                          decoration: const InputDecoration(
                            labelText: 'Booked No',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        onChanged: onTextChange,
                        controller: _firstPriceTextController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'-?[0-9]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'First Price',
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        onChanged: onTextChange,
                        controller: _taxTextController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'-?[0-9]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Tax',
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        onChanged: onTextChange,
                        controller: _ticketNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Ticket Number',
                        ),
                      ),
                    ),
                  ),
                ]),
                Row(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        onChanged: onTextChange,
                        controller: _approverTextController,
                        decoration: const InputDecoration(
                          labelText: 'Approver',
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        onChanged: onTextChange,
                        controller: _ticketBaseFareController,
                        decoration: const InputDecoration(
                          labelText: 'Base Fare',
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                                width: 100,
                                child: ElevatedButton(
                                  child: const Text("Add segment"),
                                  onPressed: () {
                                    setState(() {
                                      invoices.add(InvoiceSegmentData(
                                        arrivalDate: TextEditingController(),
                                        arrivalTime: TextEditingController(),
                                        className: TextEditingController(),
                                        code: TextEditingController(),
                                        departDate: TextEditingController(),
                                        departTime: TextEditingController(),
                                        routeName: TextEditingController(),
                                        classCode: TextEditingController(),
                                        destinationCode:
                                            TextEditingController(),
                                        originCode: TextEditingController(),
                                      ));
                                    });
                                  },
                                )),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                                width: 100,
                                child: ElevatedButton(
                                    child: const Text("SAVE hotel"),
                                    onPressed: () async {
                                      try {
                                        if (isLoading) return;
                                        setState(() {
                                          isLoading = true;
                                        });
                                        if (invoiceExcel == null) {
                                          throw ErrorHint(
                                              "Invoice Excel is not pickeddd");
                                        }
                                        bool isDuplicated =
                                            checkForDuplicatedTicketNumber();
                                        bool? shouldSave;
                                        if (isDuplicated) {
                                          shouldSave = await showDialog(
                                              context: context,
                                              builder: (con) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      "Duplicated ticket number"),
                                                  content: const Text(
                                                      'do you want to insert it'),
                                                  actions: [
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context, false);
                                                        },
                                                        child:
                                                            const Text('NO')),
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context, true);
                                                        },
                                                        child:
                                                            const Text('YES'))
                                                  ],
                                                );
                                              });
                                        } else {
                                          shouldSave = true;
                                        }
                                        if (shouldSave != true) {
                                          setState(() {
                                            isLoading = false;
                                          });
                                          return;
                                        }
                                        await insertInvoiceHotelRow();

                                        saveFiles(
                                                saveInvoice: false,
                                                savePdf: true)
                                            .then((c) async {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => AlertDialog(
                                              title:
                                                  const Text("Data inserted"),
                                              actions: [
                                                ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text("Close"))
                                              ],
                                            ),
                                          );
                                        });

                                        setState(() {
                                          isLoading = false;
                                        });
                                      } catch (e) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        print(e);
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Error"),
                                            content: Text(e.toString()),
                                            actions: [
                                              ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text("Close"))
                                            ],
                                          ),
                                        );
                                      }
                                    })),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                                width: 100,
                                child: ElevatedButton(
                                  child: Text(hotelInvoice == null
                                      ? "Add Hotel"
                                      : "Remove Hotel"),
                                  onPressed: () {
                                    if (hotelInvoice == null) {
                                      setState(() {
                                        hotelInvoice = InvoiceHotelData(
                                            hotelName: TextEditingController(),
                                            location: TextEditingController(),
                                            numberOfNights:
                                                TextEditingController(),
                                            checkIn: TextEditingController(),
                                            checkOut: TextEditingController(),
                                            hotelDestination:
                                                TextEditingController());
                                      });
                                    } else {
                                      hotelInvoice?.hotelName.dispose();
                                      hotelInvoice?.location.dispose();
                                      hotelInvoice?.numberOfNights.dispose();
                                      hotelInvoice?.checkIn.dispose();
                                      hotelInvoice?.checkOut.dispose();
                                      hotelInvoice?.hotelDestination.dispose();

                                      setState(() {
                                        hotelInvoice = null;
                                      });
                                    }
                                  },
                                )),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                                width: 100,
                                child: ElevatedButton(
                                    child: const Text("SAVE Invoice"),
                                    onPressed: () async {
                                      try {
                                        if (isLoading) return;
                                        setState(() {
                                          isLoading = true;
                                        });
                                        if (invoiceExcel == null) {
                                          throw ErrorHint(
                                              "Invoice Excel is not picked");
                                        }
                                        if (segmentationExcel == null) {
                                          throw ErrorHint(
                                              "Segmentation Excel is not picked");
                                        }

                                        bool isDuplicated =
                                            checkForDuplicatedTicketNumber();

                                        bool? shouldSave;
                                        if (isDuplicated) {
                                          shouldSave = await showDialog(
                                              context: context,
                                              builder: (con) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      "duplicated ticket number"),
                                                  content: const Text(
                                                      'do you want to insert it'),
                                                  actions: [
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context, false);
                                                        },
                                                        child:
                                                            const Text('NO')),
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context, true);
                                                        },
                                                        child:
                                                            const Text('YES'))
                                                  ],
                                                );
                                              });
                                        } else {
                                          shouldSave = true;
                                        }
                                        if (shouldSave != true) {
                                          setState(() {
                                            isLoading = false;
                                          });
                                          return;
                                        }

                                        await insertInvoiceRow();
                                        await insertSegmentationRow();

                                        saveFiles(
                                                saveInvoice: false,
                                                savePdf: true,
                                                saveSegment: false)
                                            .then((c) {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => AlertDialog(
                                              title:
                                                  const Text("Data inserted"),
                                              actions: [
                                                ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text("Close"))
                                              ],
                                            ),
                                          );
                                        });

                                        setState(() {
                                          isLoading = false;
                                        });
                                      } catch (e) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Error"),
                                            content: Text(e.toString()),
                                            actions: [
                                              ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text("Close"))
                                            ],
                                          ),
                                        );
                                      }
                                    })),
                          )
                        ],
                      )
                    ],
                  )
                ]),
                if (invoices.isEmpty && hotelInvoice != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: hotelInvoice!.hotelName,
                          onChanged: onTextChange,
                          decoration: const InputDecoration(
                              labelText: "Hotel Name",
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: hotelInvoice!.location,
                          onChanged: onTextChange,
                          decoration: const InputDecoration(
                              labelText: "Location",
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: hotelInvoice!.numberOfNights,
                          onChanged: onTextChange,
                          decoration: const InputDecoration(
                              labelText: "Number of Nights",
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: hotelInvoice!.checkIn,
                          onChanged: onTextChange,
                          decoration: const InputDecoration(
                              labelText: "Check In",
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: hotelInvoice!.checkOut,
                          onChanged: onTextChange,
                          decoration: const InputDecoration(
                              labelText: "Check Out",
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: hotelInvoice!.hotelDestination,
                          onChanged: onTextChange,
                          decoration: const InputDecoration(
                              labelText: "Destination",
                              border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                for (int i = 0; i < invoices.length; i++)
                  Column(
                    children: [
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Segment ${i + 1}',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Spacer(),
                          IconButton(
                              onPressed: () {
                                String sortValue = "";
                                showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Cancel')),
                                            TextButton(
                                                onPressed: () {
                                                  int sortInt = (int.tryParse(
                                                          sortValue) ??
                                                      0);
                                                  sortInt = sortInt - 1;
                                                  if (sortInt != i &&
                                                      sortInt >= 0 &&
                                                      sortInt <
                                                          invoices.length) {
                                                    InvoiceSegmentData temp =
                                                        invoices[i];
                                                    invoices[i] =
                                                        invoices[sortInt];
                                                    invoices[sortInt] = temp;
                                                    setState(() {});
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                child: const Text('Sort'))
                                          ],
                                          content: TextField(
                                            decoration: InputDecoration(
                                              hintText:
                                                  "Sort must be greater than zero",
                                              label: Text("Sort Value"),
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly
                                            ],
                                            onChanged: (value) {
                                              sortValue = value;
                                            },
                                          ),
                                        ));
                              },
                              icon: const Icon(Icons.sort_by_alpha)),
                          IconButton(
                              onPressed: () {
                                invoices[i].routeName.dispose();
                                invoices[i].className.dispose();
                                invoices[i].code.dispose();
                                invoices[i].departDate.dispose();
                                invoices[i].departTime.dispose();
                                invoices[i].arrivalDate.dispose();
                                invoices[i].arrivalTime.dispose();
                                invoices[i].classCode.dispose();
                                invoices[i].originCode.dispose();
                                invoices[i].destinationCode.dispose();

                                setState(() {
                                  invoices.removeAt(i);
                                });
                              },
                              icon: const Icon(Icons.delete, color: Colors.red))
                        ],
                      ),
                      Row(
                        children: [
                          //               routeName; className; code; departDate; departTime; arrivalDate; arrivalTime;
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 180,
                              child: TextField(
                                onChanged: onTextChange,
                                controller: invoices[i].code,
                                decoration: InputDecoration(
                                  labelText: 'Route Code ${i + 1}',
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 180,
                              child: TextField(
                                onChanged: onTextChange,
                                controller: invoices[i].routeName,
                                decoration: InputDecoration(
                                  labelText: 'Route Name ${i + 1}',
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 180,
                              child: TextField(
                                onChanged: onTextChange,
                                controller: invoices[i].className,
                                decoration: InputDecoration(
                                  labelText: 'Class ${i + 1}',
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 50,
                              child: TextField(
                                onChanged: onTextChange,
                                controller: invoices[i].classCode,
                                decoration: InputDecoration(
                                  labelText: 'C.Code ${i + 1}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 150,
                              child: TextField(
                                onChanged: onTextChange,
                                controller: invoices[i].departDate,
                                decoration: InputDecoration(
                                  labelText: 'Depart Date ${i + 1}',
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 150,
                              child: TextField(
                                onChanged: onTextChange,
                                controller: invoices[i].departTime,
                                decoration: InputDecoration(
                                  labelText: 'Depart Time ${i + 1}',
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 150,
                              child: TextField(
                                onChanged: onTextChange,
                                controller: invoices[i].arrivalDate,
                                decoration: InputDecoration(
                                  labelText: 'Arrival Date ${i + 1}',
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 150,
                              child: TextField(
                                onChanged: onTextChange,
                                controller: invoices[i].arrivalTime,
                                decoration: InputDecoration(
                                  labelText: 'Arrival Time ${i + 1}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 150,
                              child: TextField(
                                onChanged: onTextChange,
                                controller: invoices[i].originCode,
                                decoration: InputDecoration(
                                  labelText: 'Origin Code ${i + 1}',
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 150,
                              child: TextField(
                                onChanged: onTextChange,
                                controller: invoices[i].destinationCode,
                                decoration: InputDecoration(
                                  labelText: 'Destination Code ${i + 1}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            )),
            if (showPdfSide)
              Expanded(
                child: PdfPreview(
                    pdfPreviewPageDecoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                    build: (format) {
                      pdf = generateInvoicePdf(
                          hotelData: hotelInvoice,
                          format: format,
                          invoices: invoices,
                          invoiceNo: _invoiceTextController.text != ''
                              ? _invoiceTextController.text
                              : '.',
                          date: _dateTextController.text != ''
                              ? _dateTextController.text
                              : '.',
                          dateOfSupply: _dateOfSupplyTextController.text != ''
                              ? _dateOfSupplyTextController.text
                              : '.',
                          costCenter: _costCenterTextController.text != ''
                              ? _costCenterTextController.text
                              : '.',
                          employeeId: _employeeIdTextController.text != ''
                              ? _employeeIdTextController.text
                              : '.',
                          businessUnit: _businessUnitTextController.text != ''
                              ? _businessUnitTextController.text
                              : '.',
                          bookedBy: _bookedByTextController.text != ''
                              ? _bookedByTextController.text
                              : '.',
                          bookedNo: _bookNumberTextController.text != ''
                              ? _bookNumberTextController.text
                              : '.',
                          firstPrice: _firstPriceTextController.text != ''
                              ? _firstPriceTextController.text
                              : '00.00',
                          passengerName: _passengerNameTextController.text != ''
                              ? _passengerNameTextController.text
                              : '',
                          approver: _approverTextController.text != ''
                              ? _approverTextController.text
                              : '',
                          tax: _taxTextController.text != ''
                              ? '${_taxTextController.text}.00'
                              : '00.00',
                          total: ((int.tryParse(_taxTextController.text) ?? 0) +
                                  (int.tryParse(
                                          _firstPriceTextController.text) ??
                                      0))
                              .toString(),
                          ticketNumber: _ticketNumberController.text,
                          changeInvoiceText: changeInvoiceText);
                      return pdf!;
                    }),
              ),
          ],
        ));
  }
}

class InvoiceSegmentData {
  final TextEditingController routeName;
  final TextEditingController className;
  final TextEditingController code;
  final TextEditingController departDate;
  final TextEditingController departTime;
  final TextEditingController arrivalDate;
  final TextEditingController arrivalTime;
  final TextEditingController classCode;
  final TextEditingController originCode;
  final TextEditingController destinationCode;

  InvoiceSegmentData({
    required this.routeName,
    required this.className,
    required this.code,
    required this.departDate,
    required this.departTime,
    required this.arrivalDate,
    required this.arrivalTime,
    required this.classCode,
    required this.originCode,
    required this.destinationCode,
  });
}

class InvoiceHotelData {
  final TextEditingController hotelName;
  final TextEditingController location;
  final TextEditingController numberOfNights;
  final TextEditingController checkIn;
  final TextEditingController checkOut;
  final TextEditingController hotelDestination;

  InvoiceHotelData({
    required this.hotelName,
    required this.location,
    required this.numberOfNights,
    required this.checkIn,
    required this.checkOut,
    required this.hotelDestination,
  });
}
