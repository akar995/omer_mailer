import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omer_mailer/excel_helper.dart';
import 'package:omer_mailer/segment_mock.dart';
import 'package:excel/excel.dart' as ex;

import 'package:printing/printing.dart';

import 'pdf_tab.dart'
    show InvoiceHotelData, InvoiceSegmentData; // reuse existing models
import 'pdf_generator_v2.dart';

class PDFTabV2 extends StatefulWidget {
  const PDFTabV2({super.key});

  @override
  State<PDFTabV2> createState() => _PDFTabV2State();
}

class _PDFTabV2State extends State<PDFTabV2> {
  // Reuse your existing patterns but add the new fields:
  final invoices = <InvoiceSegmentData>[];
  Future<Uint8List>? pdf;
  ex.Excel? invoiceExcel;
  ex.Excel? segmentationExcel;
  int finalDes = 1;

  // existing
  final _invoiceTextController = TextEditingController();
  final _dateTextController = TextEditingController();
  final _dateOfSupplyTextController = TextEditingController();
  final _costCenterTextController = TextEditingController(text: '1425');
  final _employeeIdTextController = TextEditingController();
  final _businessUnitTextController =
      TextEditingController(text: "Kentech Gulf Holdings Limited Iraq Branch");
  final _bookedByTextController = TextEditingController(text: "NEMAT");
  final _bookNumberTextController = TextEditingController();
  final _firstPriceTextController = TextEditingController(); // fare (ex VAT)
  final _approverTextController = TextEditingController();
  final _passengerNameTextController = TextEditingController();
  final _commissionTextController = TextEditingController(); // was "tax"
  final _ticketNumberController = TextEditingController();

  // NEW fields
  final _airlineCarrierTaxController = TextEditingController();
  final _serviceFeeController = TextEditingController();
  final _co2eController = TextEditingController();
  final _travelTypeController = TextEditingController();
  final _tripReasonController = TextEditingController(text: 'Rotation');
  final _projectCodeController = TextEditingController(text: '1425-GCMC');

  // toggles
  bool changeInvoiceText = false; // same behavior as v1
  bool useNewCompanyAddress = false; // NEW
  bool useAltCustomerBlock = false; // NEW

  InvoiceHotelData? hotelInvoice; // keep your hotel option
  bool isLoading = false;
  Timer? _debounce;
  void _onTextChange(_) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
    _commissionTextController.dispose();
    _ticketNumberController.dispose();
    _airlineCarrierTaxController.dispose();
    _serviceFeeController.dispose();
    _co2eController.dispose();
    _travelTypeController.dispose();
    _tripReasonController.dispose();
    _projectCodeController.dispose();

    super.dispose();
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
      // final String pdfName = "invoices/pdf/INV ${_invoiceTextController.text}";
      final String pdfName = "INV_${_invoiceTextController.text}";
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

  InputDecoration _dec(String label) => InputDecoration(labelText: label);
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

  insertInvoiceRow() {
    if (finalDes > invoices.length - 1) {
      throw ErrorHint("Pick a correct final destination");
    }
    for (var table in invoiceExcel!.tables.keys) {
      for (int i = 0; i < invoices.length; i++) {
        final element = invoices[i];

        final int totalAmount =
            (int.tryParse(_firstPriceTextController.text) ?? 0) +
                (int.tryParse(_airlineCarrierTaxController.text) ?? 0);
        final int taxAmount =
            totalAmount - (int.tryParse(_firstPriceTextController.text) ?? 0);
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
            destinationCode: invoices[finalDes].destinationCode.text,
            passengerID: _employeeIdTextController.text,
            lskFee: _airlineCarrierTaxController.text,
            baseFare: _firstPriceTextController.text,
            taxAmount: taxAmount,
            segmentLeg: i + 1,
            airCode: element.originCode.text,
            originCode: element.originCode.text,
            flightNumber: element.code.text);

        if (i == 0) {
          final List<ex.CellValue> test = [];
          for (var element in invoice.row) {
            test.add(ex.TextCellValue(element.toString()));
          }
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
                (int.tryParse(_airlineCarrierTaxController.text) ?? 0);
        final int taxAmount =
            totalAmount - (int.tryParse(_firstPriceTextController.text) ?? 0);
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
          lskFee: _airlineCarrierTaxController.text,
          baseFare: _firstPriceTextController.text,
          taxAmount: taxAmount,
          segmentLeg: i + 1,
          airCode: element.originCode.text,
          originCode: element.originCode.text,
          flightNumber: element.code.text,
        );
        final List<ex.CellValue> test = [];
        for (var element in invoice.segment) {
          test.add(ex.TextCellValue(element.toString()));
        }
        segmentationExcel?.appendRow(table, test);
      }
    }
  }

  insertInvoiceHotelRow() {
    for (var table in invoiceExcel!.tables.keys) {
      // for (int i = 0; i < invoices.length; i++) {

      final int totalAmount =
          (int.tryParse(_firstPriceTextController.text) ?? 0) +
              (int.tryParse(_airlineCarrierTaxController.text) ?? 0);
      final int taxAmount =
          totalAmount - (int.tryParse(_firstPriceTextController.text) ?? 0);

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
          lskFee: _airlineCarrierTaxController.text,
          baseFare: _firstPriceTextController.text,
          taxAmount: taxAmount,
          segmentLeg: 1,
          airCode: '',
          originCode: '',
          flightNumber: '');
      final List<ex.CellValue> test = [];
      for (var element in invoice.row) {
        test.add(ex.TextCellValue(element.toString()));
      }
      invoiceExcel?.appendRow(table, test);
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
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      } else {
                                        File(result.files[0].path!)
                                            .readAsBytes()
                                            .then((value) {
                                          final ex.Excel invoice =
                                              ex.Excel.decodeBytes(value);
                                          setState(() {
                                            invoiceExcel = invoice;
                                          });
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        });
                                      }
                                    }
                                  });
                                },
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(4))),
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
                                      if (kIsWeb) {
                                        final ex.Excel invoice =
                                            ex.Excel.decodeBytes(result
                                                .files[0].bytes!
                                                .toList());
                                        setState(() {
                                          segmentationExcel = invoice;
                                        });
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      } else {
                                        try {
                                          File(result.files[0].path!)
                                              .readAsBytes()
                                              .then((value) {
                                            final ex.Excel invoice =
                                                ex.Excel.decodeBytes(value);
                                            setState(() {
                                              segmentationExcel = invoice;
                                            });
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                            }
                                          });
                                        } catch (e) {
                                          print(e);
                                        }
                                      }
                                    }
                                  });
                                },
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(4))),
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
      appBar: AppBar(
        title: const Text('PDF v2'),
        actions: [
          Row(children: [
            const Text("Credit Note?"),
            Switch(
              value: changeInvoiceText,
              onChanged: (v) => setState(() => changeInvoiceText = v),
            ),
            const SizedBox(width: 12),
            const Text("New Company Address"),
            Switch(
              value: useNewCompanyAddress,
              onChanged: (v) => setState(() => useNewCompanyAddress = v),
            ),
            const SizedBox(width: 12),
            const Text("Alt Customer Block"),
            Switch(
              value: useAltCustomerBlock,
              onChanged: (v) => setState(() => useAltCustomerBlock = v),
            ),
            const SizedBox(width: 8),
          ])
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _invoiceTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Invoice Number'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _dateTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Date'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _dateOfSupplyTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Date of Supply'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _costCenterTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Cost Center'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _employeeIdTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Employee ID'),
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _businessUnitTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Business Unit'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _passengerNameTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Passenger Name'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _bookedByTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Booked By'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _bookNumberTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Booked No'),
                      ),
                    ),

                    // Fare / Commission / Airline Taxes / Service Fee / Ticket No
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _firstPriceTextController,
                        onChanged: _onTextChange,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))
                        ],
                        decoration: _dec('Fare (Ex VAT)'),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _commissionTextController,
                        onChanged: _onTextChange,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))
                        ],
                        decoration: _dec('Commission'),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: TextField(
                        controller: _airlineCarrierTaxController,
                        onChanged: _onTextChange,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))
                        ],
                        decoration: _dec('Airline Carrier Taxes'),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _serviceFeeController,
                        onChanged: _onTextChange,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))
                        ],
                        decoration: _dec('Service Fee'),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _ticketNumberController,
                        onChanged: _onTextChange,
                        decoration: _dec('Ticket Number'),
                      ),
                    ),

                    // NEW: Travel Type, CO2e
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _travelTypeController,
                        onChanged: _onTextChange,
                        decoration: _dec('Travel Type'),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _co2eController,
                        onChanged: _onTextChange,
                        decoration: _dec('CO2e'),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _tripReasonController,
                        onChanged: _onTextChange,
                        decoration: _dec('Trip Reason'),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _projectCodeController,
                        onChanged: _onTextChange,
                        decoration: _dec('Project Code'),
                      ),
                    ),

                    // Approver
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _approverTextController,
                        onChanged: _onTextChange,
                        decoration: _dec('Approver Line Manager Name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
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
                            destinationCode: TextEditingController(),
                            originCode: TextEditingController(),
                          ));
                        });
                      },
                      child: const Text("Add Segment"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (hotelInvoice == null) {
                          setState(() {
                            hotelInvoice = InvoiceHotelData(
                              hotelName: TextEditingController(),
                              location: TextEditingController(),
                              numberOfNights: TextEditingController(),
                              checkIn: TextEditingController(),
                              checkOut: TextEditingController(),
                              hotelDestination: TextEditingController(),
                            );
                          });
                        } else {
                          hotelInvoice!.hotelName.dispose();
                          hotelInvoice!.location.dispose();
                          hotelInvoice!.numberOfNights.dispose();
                          hotelInvoice!.checkIn.dispose();
                          hotelInvoice!.checkOut.dispose();
                          hotelInvoice!.hotelDestination.dispose();
                          setState(() => hotelInvoice = null);
                        }
                      },
                      child: Text(
                          hotelInvoice == null ? "Add Hotel" : "Remove Hotel"),
                    ),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            invoices.add(
                              SegmentMock.nextMockSegment(
                                invoices,
                                startAirport: 'EBL', // optional
                                finalAirport: 'DOH', // optional hint
                                startDate: DateTime.now(), // optional
                              ),
                            );
                          });
                        },
                        child: const Text("add Mock Dataaaa")),
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
                                                  child: const Text('NO')),
                                              ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(
                                                        context, true);
                                                  },
                                                  child: const Text('YES'))
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
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Data inserted"),
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
                                  });

                                  setState(() {
                                    isLoading = false;
                                  });
                                } catch (e) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  if (context.mounted) {
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
                                }
                              })),
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
                                                  child: const Text('NO')),
                                              ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(
                                                        context, true);
                                                  },
                                                  child: const Text('YES'))
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

                                  saveFiles(saveInvoice: false, savePdf: true)
                                      .then((c) async {
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Data inserted"),
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
                                  });

                                  setState(() {
                                    isLoading = false;
                                  });
                                } catch (e) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  if (context.mounted) {
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
                                }
                              })),
                    )
                  ],
                ),
                if (hotelInvoice != null && invoices.isEmpty) ...[
                  const SizedBox(height: 12),
                  _hotelInputs(hotelInvoice!),
                ],
                for (int i = 0; i < invoices.length; i++) ...[
                  const Divider(),
                  _segmentInputs(i),
                ],
              ],
            ),
          ),

          // PDF preview
          Expanded(
            child: PdfPreview(
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1),
              ),
              build: (pageFormat) {
                pdf = generateInvoicePdfV2(
                    hotelData: hotelInvoice,
                    format: pageFormat,
                    invoices: invoices,
                    invoiceNo: _invoiceTextController.text.isNotEmpty
                        ? _invoiceTextController.text
                        : '.',
                    date: _dateTextController.text.isNotEmpty
                        ? _dateTextController.text
                        : '.',
                    dateOfSupply: _dateOfSupplyTextController.text.isNotEmpty
                        ? _dateOfSupplyTextController.text
                        : '.',
                    costCenter: _costCenterTextController.text.isNotEmpty
                        ? _costCenterTextController.text
                        : '.',
                    employeeId: _employeeIdTextController.text.isNotEmpty
                        ? _employeeIdTextController.text
                        : '.',
                    businessUnit: _businessUnitTextController.text.isNotEmpty
                        ? _businessUnitTextController.text
                        : '.',
                    bookedBy: _bookedByTextController.text.isNotEmpty
                        ? _bookedByTextController.text
                        : '.',
                    bookedNo: _bookNumberTextController.text.isNotEmpty
                        ? _bookNumberTextController.text
                        : '.',
                    firstPrice: _firstPriceTextController.text.isNotEmpty
                        ? _firstPriceTextController.text
                        : '0',
                    commission: _commissionTextController.text.isNotEmpty
                        ? _commissionTextController.text
                        : '0',
                    airlineCarrierTaxes:
                        _airlineCarrierTaxController.text.isNotEmpty
                            ? _airlineCarrierTaxController.text
                            : '0',
                    serviceFee: _serviceFeeController.text.isNotEmpty
                        ? _serviceFeeController.text
                        : '0',
                    passengerName: _passengerNameTextController.text,
                    approver: _approverTextController.text,
                    total: '0', // recalculated inside generator
                    ticketNumber: _ticketNumberController.text,
                    co2e: _co2eController.text,
                    travelType: _travelTypeController.text,
                    changeInvoiceText: changeInvoiceText,
                    useNewCompanyAddress: useNewCompanyAddress,
                    useAltCustomerBlock: useAltCustomerBlock,
                    projectCode: _projectCodeController.text,
                    tripReason: _tripReasonController.text);
                return pdf!;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentInputs(int i) {
    final s = invoices[i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text('Segment ${i + 1}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold))),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              s.routeName.dispose();
              s.className.dispose();
              s.code.dispose();
              s.departDate.dispose();
              s.departTime.dispose();
              s.arrivalDate.dispose();
              s.arrivalTime.dispose();
              s.classCode.dispose();
              s.originCode.dispose();
              s.destinationCode.dispose();
              setState(() => invoices.removeAt(i));
            },
          ),
        ]),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
                width: 150,
                child: TextField(
                    controller: s.code,
                    onChanged: _onTextChange,
                    decoration: _dec('Route Code'))),
            SizedBox(
                width: 220,
                child: TextField(
                    controller: s.routeName,
                    onChanged: _onTextChange,
                    decoration: _dec('Route Name'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.className,
                    onChanged: _onTextChange,
                    decoration: _dec('Class'))),
            SizedBox(
                width: 80,
                child: TextField(
                    controller: s.classCode,
                    onChanged: _onTextChange,
                    decoration: _dec('C.Code'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.departDate,
                    onChanged: _onTextChange,
                    decoration: _dec('Depart Date'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.departTime,
                    onChanged: _onTextChange,
                    decoration: _dec('Depart Time'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.arrivalDate,
                    onChanged: _onTextChange,
                    decoration: _dec('Arrival Date'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.arrivalTime,
                    onChanged: _onTextChange,
                    decoration: _dec('Arrival Time'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.originCode,
                    onChanged: _onTextChange,
                    decoration: _dec('Origin Code'))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: s.destinationCode,
                    onChanged: _onTextChange,
                    decoration: _dec('Destination Code'))),
          ],
        ),
      ],
    );
  }

  Widget _hotelInputs(InvoiceHotelData h) {
    return Column(children: [
      TextField(
          controller: h.hotelName,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Hotel Name", border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: h.location,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Location", border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: h.numberOfNights,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Number of Nights", border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: h.checkIn,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Check In", border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: h.checkOut,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Check Out", border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: h.hotelDestination,
          onChanged: _onTextChange,
          decoration: const InputDecoration(
              labelText: "Destination", border: OutlineInputBorder())),
    ]);
  }
}
