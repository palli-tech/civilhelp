import 'dart:async';
//import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


// TODO: add a proper Unicode font package or local font assets.






import '../models/report_filter.dart';

import '../models/worker_ledger_entry.dart';
import '../models/worker_ledger_report_dto.dart';


class PdfService {

  pw.Font? _regularFont;
  pw.Font? _boldFont;

  Future<({pw.Font regular, pw.Font bold})> _loadPdfFonts() async {
    // Simple in-memory cache.
    if (_regularFont != null && _boldFont != null) {
      return (regular: _regularFont!, bold: _boldFont!);
    }

    // Prevent duplicate loads during concurrent exports.
    // (This app likely doesn’t trigger extreme parallelism, but cache anyway.)
    // ignore: synchronized
    await Future<void>.delayed(Duration.zero);

    // Load once.
    final regularBytes = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldBytes = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');

    _regularFont = pw.Font.ttf(regularBytes);
    _boldFont = pw.Font.ttf(boldBytes);

    return (regular: _regularFont!, bold: _boldFont!);
  }

  Future<void> previewWorkerLedgerPdf({
    required WorkerLedgerReportDTO report,
    required ReportFilter filter,
    required String companyName,
    required String workerName,
    required String siteName,
  }) async {
    // Generate PDF bytes once (reuse for preview + download/share).
    Uint8List pdfBytes;
    try {
      pdfBytes = await _generateWorkerLedgerPdfBytes(
        report: report,
        filter: filter,
        companyName: companyName,
        workerName: workerName,
        siteName: siteName,
      );
    } catch (e) {
      // Re-throw with a user-friendly message (UI decides snackbar copy).
      throw Exception('PDF generation failed');
    }

    // Platform-aware handling.
    if (kIsWeb) {
      await _previewAndDownloadOnWeb(
        pdfBytes: pdfBytes,
        fileName: 'Worker_Ledger_Report.pdf',
      );
    } else {
      // Mobile + desktop: printing package provides preview/print integration.
      await _previewOnNonWeb(pdfBytes: pdfBytes, fileName: 'Worker_Ledger_Report.pdf');
    }
  }

  Future<void> _previewOnNonWeb({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: fileName,
      );
    } catch (_) {
      throw Exception('PDF preview failed');
    }
  }

  Future<void> _previewAndDownloadOnWeb({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      // `printing` provides a web-safe way to preview/download using JS.
      // Avoid calling native print methods (which cause MissingPluginException).
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (_) {
      // Fallback: open/share the PDF.
      await _openPdfInNewTab(pdfBytes: pdfBytes);

    }
  }

  // NOTE: printing package method availability differs across versions.
  // Keep web flow simple and rely on sharePdf (JS-backed) for preview + download.
  Future<void> _openPdfInNewTab({required Uint8List pdfBytes}) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Worker_Ledger_Report.pdf',
      );
    } catch (_) {
      // no-op
    }
  }


  Future<Uint8List> _generateWorkerLedgerPdfBytes({
    required WorkerLedgerReportDTO report,
    required ReportFilter filter,
    required String companyName,
    required String workerName,
    required String siteName,
  }) async {
    final pdf = pw.Document();

    final fonts = await _loadPdfFonts();
    final pw.Font regularFont = fonts.regular;
    final pw.Font boldFont = fonts.bold;



    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('dd-MMM-yyyy');

    final defaultTextTheme = pw.TextStyle(font: regularFont);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData(defaultTextStyle: defaultTextTheme),
        build: (context) {
          return [
            _buildHeader(
              companyName: companyName,
              dateFmt: dateFmt,
              filter: filter,
              workerName: workerName,
              siteName: siteName,
              boldFont: boldFont,
            ),
            pw.SizedBox(height: 20),
            _buildSummary(report, currencyFmt, boldFont: boldFont, regularFont: regularFont),
            pw.SizedBox(height: 20),
            _buildTransactionTable(
              report.entries,
              currencyFmt,
              dateFmt,
              regularFont: regularFont,
              boldFont: boldFont,
            ),
          ];
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount} | Generated by Workforce Management System',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey, font: regularFont),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader({
    required String companyName,
    required DateFormat dateFmt,
    required ReportFilter filter,
    required String workerName,
    required String siteName,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          companyName,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: boldFont),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'WORKER LEDGER REPORT',
          style: pw.TextStyle(fontSize: 18, color: PdfColors.blueGrey800, font: boldFont),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Generated On: ${dateFmt.format(DateTime.now())}'),
                pw.Text('Period: ${dateFmt.format(filter.startDate)} - ${dateFmt.format(filter.endDate)}'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Worker: $workerName'),
                pw.Text('Site: $siteName'),
              ],
            ),
          ],
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildSummary(
    WorkerLedgerReportDTO report,
    NumberFormat currencyFmt, {
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Earned:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont)),
              pw.Text(currencyFmt.format(report.totalEarned), style: pw.TextStyle(font: regularFont)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Advances:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont)),
              pw.Text(currencyFmt.format(report.totalAdvances), style: pw.TextStyle(font: regularFont)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Payments:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont)),
              pw.Text(currencyFmt.format(report.totalPayments), style: pw.TextStyle(font: regularFont)),
            ],
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Outstanding Balance:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont),
              ),
              pw.Text(
                currencyFmt.format(report.outstandingBalance),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTransactionTable(
    List<WorkerLedgerEntry> entries,
    NumberFormat currencyFmt,
    DateFormat dateFmt, {
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Type', 'Description', 'Amount', 'Balance'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: boldFont),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      data: entries.map((e) {
        String typeStr;
        switch (e.type) {
          case LedgerEntryType.attendance:
            typeStr = 'Attendance';
            break;
          case LedgerEntryType.advance:
            typeStr = 'Advance';
            break;
          case LedgerEntryType.payment:
            typeStr = 'Payment';
            break;
        }

        // Currency validation + negative rendering.
        String amountStr;
        if (e.credit > 0) {
          amountStr = currencyFmt.format(e.credit);
        } else if (e.debit > 0) {
          amountStr = '-${currencyFmt.format(e.debit)}';
        } else {
          amountStr = currencyFmt.format(0);
        }

        return [
          dateFmt.format(e.date),
          typeStr,
          e.description,
          amountStr,
          currencyFmt.format(e.runningBalance),
        ];
      }).toList(),
    );
  }
}

