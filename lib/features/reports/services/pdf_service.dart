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
              'Page ${context.pageNumber} of ${context.pagesCount} | Generated by CivilHelp Workforce Management System',
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

  // --- Worker Payroll Statement ---
  Future<void> previewWorkerPayrollStatementPdf({
    required String workerName,
    required String periodName,
    required int presentDays,
    required double wageRate,
    required double grossEarnings,
    required double deductions,
    required double netPayable,
    required List<Map<String, dynamic>> attendanceDetails,
    required String companyName,
  }) async {
    final pdf = pw.Document();
    final fonts = await _loadPdfFonts();
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: fonts.regular)),
        build: (context) => [
          pw.Text(companyName.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, font: fonts.bold, color: PdfColors.blueGrey900)),
          pw.Text('WORKER PAYROLL STATEMENT', style: pw.TextStyle(fontSize: 14, font: fonts.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Worker: $workerName', style: pw.TextStyle(fontSize: 12, font: fonts.bold)),
              pw.Text('Period: $periodName', style: pw.TextStyle(fontSize: 12, font: fonts.bold)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfSummaryCol('Present Days', '$presentDays', fonts.bold),
                _buildPdfSummaryCol('Wage Rate', currencyFmt.format(wageRate), fonts.bold),
                _buildPdfSummaryCol('Gross Earnings', currencyFmt.format(grossEarnings), fonts.bold),
                _buildPdfSummaryCol('Deductions', currencyFmt.format(deductions), fonts.bold),
                _buildPdfSummaryCol('Net Payable', currencyFmt.format(netPayable), fonts.bold, color: PdfColors.green700),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('MUSTER & ATTENDANCE RECORDS', style: pw.TextStyle(fontSize: 12, font: fonts.bold, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Site', 'Status', 'Muster Qty', 'Earnings'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: fonts.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellHeight: 25,
            data: attendanceDetails.map((a) {
              return [
                a['date'] != null ? DateFormat('dd-MMM-yyyy').format(a['date'] as DateTime) : '',
                a['siteName'] ?? '',
                a['status'] ?? '',
                '${a['musterQuantity'] ?? 0.0}',
                currencyFmt.format(a['earningsSnapshot'] ?? 0.0),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    if (kIsWeb) {
      await _previewAndDownloadOnWeb(pdfBytes: pdfBytes, fileName: 'Worker_Payroll_Statement.pdf');
    } else {
      await _previewOnNonWeb(pdfBytes: pdfBytes, fileName: 'Worker_Payroll_Statement.pdf');
    }
  }

  // --- Site Payroll Summary ---
  Future<void> previewSitePayrollSummaryPdf({
    required String periodName,
    required List<Map<String, dynamic>> siteSummaries,
    required double totalGross,
    required double totalDeductions,
    required double totalNet,
    required String companyName,
  }) async {
    final pdf = pw.Document();
    final fonts = await _loadPdfFonts();
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: fonts.regular)),
        build: (context) => [
          pw.Text(companyName.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, font: fonts.bold, color: PdfColors.blueGrey900)),
          pw.Text('SITE PAYROLL SUMMARY', style: pw.TextStyle(fontSize: 14, font: fonts.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('Period: $periodName', style: pw.TextStyle(fontSize: 12, font: fonts.bold)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Site Name', 'Workers Count', 'Muster Days', 'Gross Cost', 'Deductions', 'Net Payout'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: fonts.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellHeight: 25,
            data: siteSummaries.map((s) {
              return [
                s['siteName'] ?? '',
                '${s['workerCount'] ?? 0}',
                '${s['attendanceDays'] ?? 0}',
                currencyFmt.format(s['totalGross'] ?? 0.0),
                currencyFmt.format(s['totalDeductions'] ?? 0.0),
                currencyFmt.format(s['totalNet'] ?? 0.0),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Total Gross: ${currencyFmt.format(totalGross)}', style: pw.TextStyle(font: fonts.bold)),
                  pw.Text('Total Deductions: ${currencyFmt.format(totalDeductions)}', style: pw.TextStyle(font: fonts.bold)),
                  pw.Text('Total Net Paid: ${currencyFmt.format(totalNet)}', style: pw.TextStyle(font: fonts.bold, color: PdfColors.green700, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    if (kIsWeb) {
      await _previewAndDownloadOnWeb(pdfBytes: pdfBytes, fileName: 'Site_Payroll_Summary.pdf');
    } else {
      await _previewOnNonWeb(pdfBytes: pdfBytes, fileName: 'Site_Payroll_Summary.pdf');
    }
  }

  // --- Outstanding Liabilities Report ---
  Future<void> previewOutstandingLiabilitiesPdf({
    required List<Map<String, dynamic>> workerLiabilities,
    required double totalUnpaidAttendance,
    required double totalOutstandingAdvances,
    required String companyName,
  }) async {
    final pdf = pw.Document();
    final fonts = await _loadPdfFonts();
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: fonts.regular)),
        build: (context) => [
          pw.Text(companyName.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, font: fonts.bold, color: PdfColors.blueGrey900)),
          pw.Text('OUTSTANDING LIABILITIES REPORT', style: pw.TextStyle(fontSize: 14, font: fonts.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                color: PdfColors.grey100,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Unpaid Attendance', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(currencyFmt.format(totalUnpaidAttendance), style: pw.TextStyle(fontSize: 16, font: fonts.bold, color: PdfColors.red700)),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                color: PdfColors.grey100,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Outstanding Advances', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(currencyFmt.format(totalOutstandingAdvances), style: pw.TextStyle(fontSize: 16, font: fonts.bold, color: PdfColors.orange700)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('WORKER BALANCE LIABILITIES', style: pw.TextStyle(fontSize: 12, font: fonts.bold, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Worker Name', 'Unpaid Attendance', 'Outstanding Advances', 'Net Liability'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: fonts.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellHeight: 25,
            data: workerLiabilities.map((l) {
              return [
                l['workerName'] ?? '',
                currencyFmt.format(l['unpaidAttendance'] ?? 0.0),
                currencyFmt.format(l['outstandingAdvances'] ?? 0.0),
                currencyFmt.format((l['unpaidAttendance'] ?? 0.0) - (l['outstandingAdvances'] ?? 0.0)),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    if (kIsWeb) {
      await _previewAndDownloadOnWeb(pdfBytes: pdfBytes, fileName: 'Outstanding_Liabilities_Report.pdf');
    } else {
      await _previewOnNonWeb(pdfBytes: pdfBytes, fileName: 'Outstanding_Liabilities_Report.pdf');
    }
  }

  // --- Worker Ledger Report ---
  Future<void> previewWorkerLedgerReportPdf({
    required String workerName,
    required double openingBalance,
    required double totalAdvances,
    required double totalRecoveries,
    required double closingBalance,
    required List<Map<String, dynamic>> transactions,
    required String companyName,
  }) async {
    final pdf = pw.Document();
    final fonts = await _loadPdfFonts();
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: fonts.regular)),
        build: (context) => [
          pw.Text(companyName.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, font: fonts.bold, color: PdfColors.blueGrey900)),
          pw.Text('WORKER LEDGER REPORT', style: pw.TextStyle(fontSize: 14, font: fonts.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('Worker: $workerName', style: pw.TextStyle(fontSize: 12, font: fonts.bold)),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfSummaryCol('Opening Bal', currencyFmt.format(openingBalance), fonts.bold),
                _buildPdfSummaryCol('+ Advances', currencyFmt.format(totalAdvances), fonts.bold),
                _buildPdfSummaryCol('- Recoveries', currencyFmt.format(totalRecoveries), fonts.bold),
                _buildPdfSummaryCol('= Closing Bal', currencyFmt.format(closingBalance), fonts.bold, color: PdfColors.blue700),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('TRANSACTION HISTORY', style: pw.TextStyle(fontSize: 12, font: fonts.bold, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Type', 'Description', 'Amount', 'Balance'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: fonts.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellHeight: 25,
            data: transactions.map((t) {
              return [
                t['date'] != null ? DateFormat('dd-MMM-yyyy').format(t['date'] as DateTime) : '',
                t['type'] ?? '',
                t['description'] ?? '',
                currencyFmt.format(t['amount'] ?? 0.0),
                currencyFmt.format(t['runningBalance'] ?? 0.0),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    if (kIsWeb) {
      await _previewAndDownloadOnWeb(pdfBytes: pdfBytes, fileName: 'Worker_Ledger_Report.pdf');
    } else {
      await _previewOnNonWeb(pdfBytes: pdfBytes, fileName: 'Worker_Ledger_Report.pdf');
    }
  }

  static pw.Widget _buildPdfSummaryCol(String label, String val, pw.Font font, {PdfColor? color}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(val, style: pw.TextStyle(fontSize: 13, font: font, color: color ?? PdfColors.black)),
      ],
    );
  }
}

