import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

Future<void> generateInvoice({
  required BuildContext context,
  required Map<String, dynamic> userData,
  required List<dynamic> products,
  required Map<String, dynamic> courier,
  required Map<String, dynamic> shipping,
  required double totalPrice,
  required String orderStatus,
  required String paymentMethod,
  required String formattedOrderDate,
}) async {
  final pdf = pw.Document();

  // Load logo image from assets
  final Uint8List logoBytes = await rootBundle.load('assets/images/main.png').then((data) => data.buffer.asUint8List());

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.openSansRegular(),
          bold: await PdfGoogleFonts.openSansBold(),
        ),
      ),
      build: (context) => [
        // Header with logo
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Image(pw.MemoryImage(logoBytes), height: 60),
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 16),

        // Order Info
        pw.Text('Order Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Customer: ${userData['UserName']}'),
        pw.Text('Email: ${userData['email']}'),
        pw.Text('Order Date: $formattedOrderDate'),
        pw.Text('Status: $orderStatus'),
        pw.Text('Payment Method: $paymentMethod'),
        pw.Text('Total Amount: Rs. $totalPrice'),
        pw.SizedBox(height: 10),

        // Courier Info
        pw.Text('Courier Info', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Agent Name: ${courier['agentName']}'),
        pw.SizedBox(height: 10),

        // Shipping Info
        pw.Text('Shipping Info', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Address: ${shipping['address']}'),
        pw.Text('Contact No: ${shipping['contactno']}'),
        pw.SizedBox(height: 16),

        // Products Table
        pw.Text('Products', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: ['Title', 'Qty', 'Price (PKR)'],
          data: products.map((product) {
            return [
              product['title'],
              product['quantity'].toString(),
              product['price'].toString(),
            ];
          }).toList(),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        ),
      ],
    ),
  );

  // Preview and print PDF
  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}
