import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import '../../labour/data/models/labour_model.dart';
import '../models/attendance_model.dart';
import '../providers/attendance_register_provider.dart';

class AttendanceExportService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  Future<({pw.Font regular, pw.Font bold})> _loadPdfFonts() async {
    if (_regularFont != null && _boldFont != null) {
      return (regular: _regularFont!, bold: _boldFont!);
    }
    // Simple delay to yield
    await Future<void>.delayed(Duration.zero);
    final regularBytes = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldBytes = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    _regularFont = pw.Font.ttf(regularBytes);
    _boldFont = pw.Font.ttf(boldBytes);
    return (regular: _regularFont!, bold: _boldFont!);
  }

  Future<void> exportAttendancePdf({
    required String siteName,
    required List<DateTime> dates,
    required List<LabourModel> workers,
    required Map<String, Map<String, AttendanceModel>> grid,
    required Map<String, int> dailyPresentCount,
    required Map<String, int> dailyHalfDayCount,
    required Map<String, int> dailyAbsentCount,
    required Map<String, double> dailyOvertimeHours,
    required Map<String, WorkerTotals> workerTotals,
  }) async {
    final pdf = pw.Document();
    final fonts = await _loadPdfFonts();
    final dateStr = "${DateFormat('dd/MM/yyyy').format(dates.first)} - ${DateFormat('dd/MM/yyyy').format(dates.last)}";

    // Build columns
    final headers = ["S.No", "Worker Name"];
    for (final d in dates) {
      headers.add("${d.day}");
    }
    headers.addAll(["Pres", "HD", "Abs", "OT", "Earned"]);

    // Calculate font sizes and padding based on number of columns to fit landscape page
    final double fontSize = dates.length > 7 ? 6.0 : 8.0;
    final double paddingValue = dates.length > 7 ? 1.5 : 3.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(
          base: fonts.regular,
          bold: fonts.bold,
        ),
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "MUSTER ROLL REGISTER",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text("Site: $siteName", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Period: $dateStr", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}",
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(20), // S.No
                1: const pw.FlexColumnWidth(3.5), // Worker Name
                for (int i = 0; i < dates.length; i++) i + 2: const pw.FixedColumnWidth(16),
                for (int i = 0; i < 5; i++) dates.length + 2 + i: const pw.FixedColumnWidth(24),
              },
              children: [
                // Header TableRow
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: headers.map((h) {
                    return pw.Padding(
                      padding: pw.EdgeInsets.symmetric(vertical: paddingValue, horizontal: 1),
                      child: pw.Center(
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Data TableRows
                ...List.generate(workers.length, (index) {
                  final worker = workers[index];
                  final totals = workerTotals[worker.id];
                  
                  final cells = <pw.Widget>[
                    pw.Center(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Text("${index + 1}", style: pw.TextStyle(fontSize: fontSize)),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 3, top: 2, bottom: 2),
                      child: pw.Text(
                        worker.fullName,
                        style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ];

                  for (final d in dates) {
                    final dateKey = formatDateKey(d);
                    final log = grid[worker.id]?[dateKey];
                    String status = "-";
                    PdfColor color = PdfColors.black;
                    
                    if (log != null) {
                      final statusLower = log.status.toLowerCase();
                      if (statusLower == 'present') {
                        status = "P";
                        color = PdfColors.green800;
                      } else if (statusLower == 'half day' || statusLower == 'half-day') {
                        status = "HD";
                        color = PdfColors.orange800;
                      } else if (statusLower == 'absent') {
                        status = "A";
                        color = PdfColors.red800;
                      }
                      
                      final normalH = (statusLower == 'present') ? 8.0 : (statusLower.contains('half') ? 4.0 : 0.0);
                      if (log.hoursWorked > normalH) {
                        final otH = log.hoursWorked - normalH;
                        status += "\n+${otH.toStringAsFixed(0)}";
                      }
                    }

                    cells.add(
                      pw.Center(
                        child: pw.Text(
                          status,
                          style: pw.TextStyle(fontSize: fontSize - 1, color: color),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    );
                  }

                  cells.addAll([
                    pw.Center(child: pw.Text("${totals?.presentCount ?? 0}", style: pw.TextStyle(fontSize: fontSize))),
                    pw.Center(child: pw.Text("${totals?.halfDayCount ?? 0}", style: pw.TextStyle(fontSize: fontSize))),
                    pw.Center(child: pw.Text("${totals?.absentCount ?? 0}", style: pw.TextStyle(fontSize: fontSize))),
                    pw.Center(child: pw.Text(totals != null ? totals.overtimeHours.toStringAsFixed(1) : "0.0", style: pw.TextStyle(fontSize: fontSize))),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 2),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          totals != null ? "Rs.${totals.totalEarned.toStringAsFixed(0)}" : "0",
                          style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ]);

                  return pw.TableRow(children: cells);
                }),
                // Footer Summary TableRow
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Text(""),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 3, top: 4, bottom: 4),
                      child: pw.Text(
                        "Daily Presence",
                        style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    for (final d in dates) ...[
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(1),
                        child: pw.Center(
                          child: pw.Text(
                            "P:${dailyPresentCount[formatDateKey(d)]}\nHD:${dailyHalfDayCount[formatDateKey(d)]}\nA:${dailyAbsentCount[formatDateKey(d)]}\nOT:${dailyOvertimeHours[formatDateKey(d)]?.toStringAsFixed(0)}",
                            style: pw.TextStyle(fontSize: fontSize - 2.2, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    pw.Text(""),
                    pw.Text(""),
                    pw.Text(""),
                    pw.Text(""),
                    pw.Text(""),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final fileName = "Muster_Roll_${siteName.replaceAll(' ', '_')}_${dates.length == 7 ? 'Weekly' : 'Monthly'}.pdf";

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }

  Future<void> exportAttendanceXlsx({
    required String siteName,
    required List<DateTime> dates,
    required List<LabourModel> workers,
    required Map<String, Map<String, AttendanceModel>> grid,
    required Map<String, int> dailyPresentCount,
    required Map<String, int> dailyHalfDayCount,
    required Map<String, int> dailyAbsentCount,
    required Map<String, double> dailyOvertimeHours,
    required Map<String, WorkerTotals> workerTotals,
  }) async {
    final excelObj = Excel.createExcel();
    final sheetName = excelObj.getDefaultSheet() ?? 'Sheet1';
    final Sheet sheet = excelObj[sheetName];

    // Style helper (using string values for excel styling properties)
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.indigo900,
    );
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.grey200,
    );
    final boldStyle = CellStyle(
      bold: true,
    );

    // Title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue("Attendance Muster Roll Register")
      ..cellStyle = titleStyle;

    final dateStr = "${DateFormat('dd/MM/yyyy').format(dates.first)} to ${DateFormat('dd/MM/yyyy').format(dates.last)}";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
      ..value = TextCellValue("Site: $siteName | Period: $dateStr")
      ..cellStyle = boldStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
      ..value = TextCellValue("Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}");

    // Table Header Row (Row index 4)
    final headers = ["S.No", "Worker Name"];
    for (final d in dates) {
      headers.add("${d.day}/${d.month}");
    }
    headers.addAll(["Present Days", "Half Days", "Absent Days", "OT Hours", "Total Earned"]);

    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 4))
        ..value = TextCellValue(headers[col])
        ..cellStyle = headerStyle;
    }

    // Data rows
    int rowIndex = 5;
    for (int index = 0; index < workers.length; index++) {
      final worker = workers[index];
      final totals = workerTotals[worker.id];

      // S.No
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        ..value = IntCellValue(index + 1);

      // Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        ..value = TextCellValue(worker.fullName)
        ..cellStyle = boldStyle;

      // Dates status
      for (int i = 0; i < dates.length; i++) {
        final d = dates[i];
        final dateKey = formatDateKey(d);
        final log = grid[worker.id]?[dateKey];
        String val = "-";
        
        if (log != null) {
          val = log.status;
          final normalH = (log.status.toLowerCase() == 'present') ? 8.0 : (log.status.toLowerCase().contains('half') ? 4.0 : 0.0);
          if (log.hoursWorked > normalH) {
            final otVal = log.hoursWorked - normalH;
            val += " (+${otVal.toStringAsFixed(1)}h OT)";
          }
        }

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: rowIndex))
          ..value = TextCellValue(val);
      }

      // Totals
      final startColIndex = dates.length + 2;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: startColIndex, rowIndex: rowIndex))
        ..value = IntCellValue(totals?.presentCount ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: startColIndex + 1, rowIndex: rowIndex))
        ..value = IntCellValue(totals?.halfDayCount ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: startColIndex + 2, rowIndex: rowIndex))
        ..value = IntCellValue(totals?.absentCount ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: startColIndex + 3, rowIndex: rowIndex))
        ..value = DoubleCellValue(totals?.overtimeHours ?? 0.0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: startColIndex + 4, rowIndex: rowIndex))
        ..value = DoubleCellValue(totals?.totalEarned ?? 0.0)
        ..cellStyle = boldStyle;

      rowIndex++;
    }

    // Daily Summary Row
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
      ..value = TextCellValue("Daily Presence")
      ..cellStyle = boldStyle;

    for (int i = 0; i < dates.length; i++) {
      final d = dates[i];
      final dateKey = formatDateKey(d);
      final p = dailyPresentCount[dateKey] ?? 0;
      final hd = dailyHalfDayCount[dateKey] ?? 0;
      final a = dailyAbsentCount[dateKey] ?? 0;
      final ot = dailyOvertimeHours[dateKey] ?? 0.0;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: rowIndex))
        ..value = TextCellValue("P:$p\nHD:$hd\nA:$a\nOT:${ot.toStringAsFixed(1)}")
        ..cellStyle = CellStyle(fontSize: 9, bold: true);
    }

    // Save as bytes
    final excelBytes = excelObj.save();
    if (excelBytes == null) {
      throw Exception("Failed to generate Excel file bytes");
    }

    final bytesList = Uint8List.fromList(excelBytes);
    final fileName = "Muster_Roll_${siteName.replaceAll(' ', '_')}_${dates.length == 7 ? 'Weekly' : 'Monthly'}.xlsx";

    await Printing.sharePdf(
      bytes: bytesList,
      filename: fileName,
    );
  }
}

final attendanceExportServiceProvider = Provider<AttendanceExportService>((ref) {
  return AttendanceExportService();
});
