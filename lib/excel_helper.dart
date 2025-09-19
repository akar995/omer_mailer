import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';

class ExcelHelper {
  Uint8List? insertInvoiceExcel(Excel excel) {
    return null;
  }
}

const predefinedVendorCode = {
  "QR": "QATAR AIRWAYS",
  "TK": "TURKISH AIRLINE",
  "EK": "EMIRATE AIRWAYS",
  "IA": "IRAQ AIRWAYS",
  "6E": "INDEGO",
  "FZ": "FLY DUBAI",
  "G8": "GO FIRST",
  "G9": "AIR ARABIA",
  "SG": "SPICE JET",
  "UK": "VISTARA",
  "AV": "AVIANCA",
  "ME": "MIDDLE EAST AIRLINE",
};

class InvoiceStructure {
  final String recordKey;
  final List<dynamic> row = [];
  final List<dynamic> row2 = [];
  static const int sequentNumber = 1;
  static const int clientId = 2947;
  static const String clientName = 'KENTECH GULF HOLDING LIMITED IRAQ BRANCH';
  final String invoiceDate;
  final String bookedDate;
  static const String voidInd = 'N';
  final String salutation;
  final String passengerName;
  final String bookingType;
  final String documentNumber;
  final String recordLocatorPNR;
  final String vendorCode;
  final String outBoundDate;
  final String departTime;
  final String arrivalDate;
  final String arrivalTime;
  final String serviceCategory;
  static const String currency = 'USD';
  final String lskFee;
  final String baseFare;
  final int taxAmount;
  final bool shouldEnterTaxAmount;
  final int totalAmountLondonSky;
  static const exchangeIndicator = 'N';
  String bookingNumber = '';
  static const refoundIndicator = 'N';
  static const bookingAgentId = 'LONDON SKY';
  static const formOfPayment = 'AR';
  late final String originCode;
  final String destinationCode;
  final String passengerID;
  final String flightNumber;
  final String co2e;
  final String tripReason;
  // final String tripReason2;
  final String travelType;
  static const constCenter = '1425';

  ///segment
  final int segmentLeg;
  final String airCode;

  /// index+1;
  final List<dynamic> segment = [];

  InvoiceStructure({
    this.travelType = "ROTATION",
    required this.recordKey,
    required this.invoiceDate,
    required this.bookedDate,
    required this.salutation,
    required this.passengerName,
    required this.bookingType,
    required this.documentNumber,
    required this.recordLocatorPNR,
    required this.vendorCode,
    required this.outBoundDate,
    required this.departTime,
    required this.arrivalDate,
    required this.arrivalTime,
    required this.serviceCategory,
    required this.totalAmountLondonSky,
    required this.destinationCode,
    required this.passengerID,
    required this.co2e,
    required this.lskFee,
    required this.tripReason,
    required this.baseFare,
    required this.taxAmount,
    required this.segmentLeg,
    required this.airCode,
    required this.originCode,
    required this.flightNumber,
    this.shouldEnterTaxAmount = true,
  }) {
    //// segment
    ///
    _addRowToOldOnes(
        recordKey: recordKey,
        invoiceDate: invoiceDate,
        bookedDate: bookedDate,
        salutation: salutation,
        passengerName: passengerName,
        bookingType: bookingType,
        documentNumber: documentNumber,
        recordLocatorPNR: recordLocatorPNR,
        vendorCode: vendorCode,
        outBoundDate: outBoundDate,
        departTime: departTime,
        arrivalDate: arrivalDate,
        arrivalTime: arrivalTime,
        serviceCategory: serviceCategory,
        totalAmountLondonSky: totalAmountLondonSky,
        destinationCode: destinationCode,
        passengerID: passengerID,
        lskFee: lskFee,
        baseFare: baseFare,
        taxAmount: taxAmount,
        segmentLeg: segmentLeg,
        airCode: airCode,
        originCode: originCode,
        flightNumber: flightNumber,
        shouldEnterTaxAmount: shouldEnterTaxAmount);
    _addRowToNewOne(
        recordKey: recordKey,
        invoiceDate: invoiceDate,
        bookedDate: bookedDate,
        salutation: salutation,
        passengerName: passengerName,
        bookingType: bookingType,
        documentNumber: documentNumber,
        recordLocatorPNR: recordLocatorPNR,
        vendorCode: vendorCode,
        outBoundDate: outBoundDate,
        departTime: departTime,
        arrivalDate: arrivalDate,
        arrivalTime: arrivalTime,
        serviceCategory: serviceCategory,
        totalAmountLondonSky: totalAmountLondonSky,
        destinationCode: destinationCode,
        passengerID: passengerID,
        lskFee: lskFee,
        baseFare: baseFare,
        taxAmount: taxAmount,
        segmentLeg: segmentLeg,
        airCode: airCode,
        originCode: originCode,
        flightNumber: flightNumber,
        shouldEnterTaxAmount: shouldEnterTaxAmount);
    if (bookingType == "AIR") {
      segment.add(recordKey);
      segment.add(1);
      segment.add(segmentLeg);
      segment.add(flightNumber.substring(0, 2).trim());
      segment.add(originCode);
      segment.add(outBoundDate);
      segment.add(departTime);
      segment.add(flightNumber.substring(2, flightNumber.length).trim());
      segment.add(destinationCode);
      segment.add(arrivalDate);
      segment.add(arrivalTime);
      segment.add(serviceCategory);
    }
  }

  _addRowToOldOnes(
      {required String recordKey,
      required String invoiceDate,
      required String bookedDate,
      required String salutation,
      required String passengerName,
      required String bookingType,
      required String documentNumber,
      required String recordLocatorPNR,
      required String vendorCode,
      required String outBoundDate,
      required String departTime,
      required String arrivalDate,
      required String arrivalTime,
      required String serviceCategory,
      required int totalAmountLondonSky,
      required String destinationCode,
      required String passengerID,
      required String lskFee,
      required String baseFare,
      required int taxAmount,
      required int segmentLeg,
      required String airCode,
      required String originCode,
      required String flightNumber,
      required bool shouldEnterTaxAmount}) {
    bookingNumber = recordLocatorPNR;
    final lastName =
        passengerName.substring(0, passengerName.indexOf('/')).trim();
    final firstName = passengerName
        .substring(
          passengerName.indexOf('/') + 1,
          passengerName.lastIndexOf(' '),
        )
        .trim();
    final sol = passengerName
        .substring(passengerName.lastIndexOf(' ') + 1, passengerName.length)
        .trim();
    row.add(recordKey);
    row.add(sequentNumber);
    row.add(clientId);
    row.add(clientName);
    row.add(invoiceDate);
    row.add(bookedDate);
    row.add(voidInd);
    row.add(sol);
    row.add(firstName);
    row.add(lastName);

    row.add(bookingType);
    row.add(documentNumber);
    row.add(recordLocatorPNR);
    if (bookingType == "AIR") {
      final countryCode = flightNumber.substring(0, 2);

      final String? countryName = predefinedVendorCode[countryCode];

      if (countryCode.isEmpty) {
        throw ErrorHint("Vendor code is not available");
      }
      row.add(countryCode); //vender code
      row.add(countryName); //vender code
    } else {
      row.add('HTL'); //vender code
      row.add(vendorCode); //vender name
    }

    row.add(outBoundDate);
    row.add(departTime);
    row.add(arrivalDate);
    row.add(arrivalTime);
    row.add(serviceCategory);
    row.add(currency);
    row.add(lskFee);
    row.add(baseFare);
    if (shouldEnterTaxAmount) {
      row.add(taxAmount);
    }
    row.add(totalAmountLondonSky);
    row.add(exchangeIndicator);
    row.add(bookingType == "AIR" ? documentNumber : bookingNumber);
    row.add(refoundIndicator);
    row.add(bookingAgentId);
    row.add(formOfPayment);
    row.add(originCode);
    row.add(destinationCode);
    row.add(passengerID);
    row.add(travelType);
    row.add(constCenter);

    /// static rows

    row.add("1425-GCMC");
    row.add("N/A");
    row.add("N/A	");
    row.add("joe.golden@kentplc.com	");
    row.add("nemat.talibmarymalik@kentplc.com	");
    row.add("Joy Golden	");
    row.add("IRQ - Kentech Gulf Holdings Limited Iraq Branch");
    row.add("Nemat");
  }

  _addRowToNewOne(
      {required String recordKey,
      required String invoiceDate,
      required String bookedDate,
      required String salutation,
      required String passengerName,
      required String bookingType,
      required String documentNumber,
      required String recordLocatorPNR,
      required String vendorCode,
      required String outBoundDate,
      required String departTime,
      required String arrivalDate,
      required String arrivalTime,
      required String serviceCategory,
      required int totalAmountLondonSky,
      required String destinationCode,
      required String passengerID,
      required String lskFee,
      required String baseFare,
      required int taxAmount,
      required int segmentLeg,
      required String airCode,
      required String originCode,
      required String flightNumber,
      required bool shouldEnterTaxAmount}) {
    bookingNumber = recordLocatorPNR;
    final lastName =
        passengerName.substring(0, passengerName.indexOf('/')).trim();
    final firstName = passengerName
        .substring(
          passengerName.indexOf('/') + 1,
          passengerName.lastIndexOf(' '),
        )
        .trim();
    final sol = passengerName
        .substring(passengerName.lastIndexOf(' ') + 1, passengerName.length)
        .trim();
    row2.add(recordKey);
    row2.add(sequentNumber);
    row2.add(clientId);
    row2.add(clientName);
    row2.add(invoiceDate);
    row2.add(bookedDate);
    row2.add(voidInd);
    row2.add(sol);
    row2.add(firstName);
    row2.add(lastName);

    row2.add(bookingType);
    row2.add(documentNumber);
    row2.add(recordLocatorPNR);
    if (bookingType == "AIR") {
      final countryCode = flightNumber.substring(0, 2);

      final String? countryName = predefinedVendorCode[countryCode];

      if (countryCode.isEmpty) {
        throw ErrorHint("Vendor code is not available");
      }
      row2.add(countryCode); //vender code
      row2.add(countryName); //vender code
    } else {
      row2.add('HTL'); //vender code
      row2.add(vendorCode); //vender name
    }

    row2.add(outBoundDate);
    row2.add(departTime);
    row2.add(arrivalDate);
    row2.add(arrivalTime);
    row2.add(serviceCategory);
    row2.add(currency);
    row2.add(lskFee);
    row2.add(baseFare);
    row2.add(taxAmount);

    row2.add(totalAmountLondonSky);
    row2.add(exchangeIndicator);
    row2.add(bookingType == "AIR" ? documentNumber : bookingNumber);
    row2.add(refoundIndicator);
    row2.add(bookingAgentId);
    row2.add(formOfPayment);
    row2.add(originCode);
    row2.add(destinationCode);
    row2.add(passengerID);
    row2.add(co2e);
    row2.add(tripReason);
    row2.add(travelType);
    row2.add(constCenter);

    /// static rows

    row2.add("1425-GCMC");
    row2.add("N/A");
    row2.add("N/A	");
    row2.add("joe.golden@kentplc.com	");
    row2.add("nemat.talibmarymalik@kentplc.com	");
    row2.add("Joy Golden	");
    row2.add("IRQ - Kentech Gulf Holdings Limited Iraq Branch");
    row2.add("Nemat");
  }
}
