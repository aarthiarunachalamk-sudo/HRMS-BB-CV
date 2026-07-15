import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'payslip_models.dart';

class PayslipPdfService {
  static const _primary = PdfColor.fromInt(0xFF031121);
  static const _secondary = PdfColor.fromInt(0xFF0A2A5E);
  static const _accent = PdfColor.fromInt(0xFF00B4D8);
  static const _background = PdfColor.fromInt(0xFFF8FAFC);
  static const _text = PdfColor.fromInt(0xFF1B2230);

  Future<Uint8List> buildPayslipPdf(PayslipDraft draft) async {
    final doc = pw.Document();
    final logoBytes = await rootBundle.load('assets/logo.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(),
        ),
        build: (_) => [
          _header(logo, draft),
          pw.SizedBox(height: 18),
          _sectionTitle('Employee Details'),
          _grid([
            ['Employee Name', draft.employeeName],
            ['Employee ID', draft.employeeId],
            ['Department', draft.department],
            ['Designation', draft.designation],
            ['Date of Joining', draft.dateOfJoining],
            ['Branch / Location', draft.branch],
            ['Bank Account', draft.bankAccountMasked],
            ['Payment Mode', draft.paymentMode],
          ]),
          pw.SizedBox(height: 14),
          _sectionTitle('Attendance Details'),
          _grid([
            ['Total Days', '${draft.totalDays}'],
            ['Working Days', '${draft.workingDays}'],
            ['Present Days', '${draft.presentDays}'],
            ['Paid Leave Days', '${draft.paidLeaveDays}'],
            ['LOP Days', '${draft.lopDays}'],
            ['Week-Off Days', '${draft.weekOffDays}'],
            ['Holiday Days', '${draft.holidayDays}'],
            ['Payable Days', '${draft.payableDays}'],
          ]),
          pw.SizedBox(height: 14),
          _sectionTitle('Earnings'),
          _earningsTable(draft),
          pw.SizedBox(height: 14),
          _sectionTitle('Deductions'),
          _deductionsTable(draft),
          pw.SizedBox(height: 16),
          _summary(draft),
          pw.SizedBox(height: 18),
          pw.Text(
            'This is a computer-generated payslip and does not require a signature.',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _header(pw.ImageProvider logo, PayslipDraft draft) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 54,
            height: 54,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Bit Byte Technologies', style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Subbarayan Nagar, Jagir Ammapalayam, Salem, Tamil Nadu 636302', style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                pw.SizedBox(height: 10),
                pw.Text('Payslip ${draft.payrollMonth.toString().padLeft(2, '0')}/${draft.payrollYear}', style: pw.TextStyle(color: _accent, fontSize: 13, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String value) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      decoration: pw.BoxDecoration(color: _secondary, borderRadius: pw.BorderRadius.circular(5)),
      child: pw.Text(value, style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _grid(List<List<String>> rows) {
    return pw.Container(
      color: _background,
      padding: const pw.EdgeInsets.all(8),
      child: pw.Wrap(
        spacing: 12,
        runSpacing: 8,
        children: rows
            .map(
              (row) => pw.SizedBox(
                width: 245,
                child: pw.Row(
                  children: [
                    pw.Expanded(child: pw.Text(row[0], style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9))),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: pw.Text(row[1], style: pw.TextStyle(color: _text, fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _earningsTable(PayslipDraft draft) {
    return pw.TableHelper.fromTextArray(
      headerDecoration: const pw.BoxDecoration(color: _background),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _text),
      cellStyle: const pw.TextStyle(fontSize: 9, color: _text),
      headers: const ['Component Name', 'Actual Amount', 'Earned Amount'],
      data: draft.earnings
          .map((item) => [item.name, _currency(item.actualAmount), _currency(item.earnedAmount)])
          .toList(),
    );
  }

  pw.Widget _deductionsTable(PayslipDraft draft) {
    return pw.TableHelper.fromTextArray(
      headerDecoration: const pw.BoxDecoration(color: _background),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _text),
      cellStyle: const pw.TextStyle(fontSize: 9, color: _text),
      headers: const ['Component Name', 'Amount'],
      data: draft.deductions.map((item) => [item.name, _currency(item.amount)]).toList(),
    );
  }

  pw.Widget _summary(PayslipDraft draft) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _accent, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _summaryRow('Gross Earnings', _currency(draft.grossEarnings)),
          _summaryRow('Total Deductions', _currency(draft.totalDeductions)),
          pw.Divider(color: PdfColors.grey300),
          _summaryRow('Net Pay', _currency(draft.netPay), bold: true),
          pw.SizedBox(height: 5),
          pw.Text('Net Pay in Words: ${draft.netPayInWords}', style: pw.TextStyle(color: _text, fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(color: _text, fontSize: bold ? 12 : 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text(value, style: style)],
      ),
    );
  }

  String _currency(num value) => 'Rs ${value.toStringAsFixed(2)}';
}
