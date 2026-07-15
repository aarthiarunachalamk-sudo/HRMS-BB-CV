import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'number_to_words_service.dart';
import 'payslip_models.dart';
import 'payslip_pdf_service.dart';
import 'payslip_repository.dart';

class PayslipService {
  final PayslipRepository repository;
  final PayslipPdfService pdfService;
  final NumberToWordsService words;

  PayslipService({
    PayslipRepository? repository,
    PayslipPdfService? pdfService,
    NumberToWordsService? words,
  })  : repository = repository ?? PayslipRepository(),
        pdfService = pdfService ?? PayslipPdfService(),
        words = words ?? NumberToWordsService();

  Future<PayslipDraft> calculateDraft({
    required String employeeId,
    required int month,
    required int year,
    required String generatedBy,
  }) async {
    final payroll = await repository.fetchPayrollLock(month, year);
    if (payroll == null || payroll['status'] != 'approved' || payroll['locked'] != true) {
      throw Exception('Payroll must be approved and locked before payslip generation.');
    }

    final employee = await repository.fetchEmployee(employeeId);
    final salary = await repository.fetchSalaryStructure(employeeId);
    if (employee.isEmpty || salary.isEmpty) {
      throw Exception('Employee and salary structure are required.');
    }

    final periodStart = DateTime(year, month, 1);
    final periodEnd = DateTime(year, month + 1, 0);
    final attendance = await repository.fetchAttendance(employeeId: employeeId, start: periodStart, end: periodEnd);
    final leaves = await repository.fetchLeaves(employeeId: employeeId, start: periodStart, end: periodEnd);
    final overtime = await repository.fetchOvertime(employeeId: employeeId, start: periodStart, end: periodEnd);

    final totalDays = periodEnd.day;
    final weekOffDays = _countWeekOffs(periodStart, periodEnd);
    final holidayDays = ((payroll['holidayDays'] as num?) ?? 0).toInt();
    final workingDays = max(totalDays - weekOffDays - holidayDays, 0);
    final presentDays = attendance.where((item) {
      final status = '${item['status'] ?? ''}'.toLowerCase();
      return status.contains('present') || status.contains('late');
    }).length;
    final paidLeaveDays = leaves.where((item) => '${item['leaveType'] ?? ''}'.toUpperCase() != 'LOP').fold<int>(0, (sum, item) => sum + _leaveDays(item, periodStart, periodEnd));
    final explicitLopDays = leaves.where((item) => '${item['leaveType'] ?? ''}'.toUpperCase() == 'LOP').fold<int>(0, (sum, item) => sum + _leaveDays(item, periodStart, periodEnd));
    final payableDays = min(workingDays, presentDays + paidLeaveDays);
    final lopDays = max(workingDays - payableDays, 0) + explicitLopDays;
    final overtimeMinutes = overtime.fold<int>(0, (sum, item) => sum + (((item['minutes'] as num?) ?? 0).toInt()));

    num salaryValue(String key) => (salary[key] as num?) ?? 0;
    final actualComponents = <String, num>{
      'Basic Salary': salaryValue('basicSalary'),
      'HRA': salaryValue('hra'),
      'Conveyance Allowance': salaryValue('conveyanceAllowance'),
      'Medical Allowance': salaryValue('medicalAllowance'),
      'Special Allowance': salaryValue('specialAllowance'),
      'Other Earnings': salaryValue('otherEarnings'),
    };
    final overtimeAmount = (overtimeMinutes / 60) * salaryValue('overtimeRatePerHour');
    actualComponents['Overtime'] = overtimeAmount;
    actualComponents['Bonus'] = salaryValue('bonus');
    actualComponents['Incentive'] = salaryValue('incentive');

    final earnings = actualComponents.entries.map((entry) {
      final earned = entry.key == 'Overtime' || entry.key == 'Bonus' || entry.key == 'Incentive'
          ? entry.value
          : _round(entry.value * (payableDays / max(workingDays, 1)));
      return PayslipComponent(name: entry.key, actualAmount: _round(entry.value), earnedAmount: earned);
    }).toList();

    final actualMonthly = actualComponents.entries
        .where((entry) => !['Overtime', 'Bonus', 'Incentive'].contains(entry.key))
        .fold<num>(0, (sum, entry) => sum + entry.value);
    final lopDeduction = _round((actualMonthly / max(workingDays, 1)) * lopDays);
    final deductions = [
      PayslipDeduction(name: 'PF', amount: salaryValue('pf')),
      PayslipDeduction(name: 'ESI', amount: salaryValue('esi')),
      PayslipDeduction(name: 'Professional Tax', amount: salaryValue('professionalTax')),
      PayslipDeduction(name: 'TDS', amount: salaryValue('tds')),
      PayslipDeduction(name: 'LOP Deduction', amount: lopDeduction),
      PayslipDeduction(name: 'Loan Deduction', amount: salaryValue('loanDeduction')),
      PayslipDeduction(name: 'Salary Advance', amount: salaryValue('salaryAdvance')),
      PayslipDeduction(name: 'Other Deduction', amount: salaryValue('otherDeduction')),
    ];
    final grossEarnings = earnings.fold<num>(0, (sum, item) => sum + item.earnedAmount);
    final totalDeductions = deductions.fold<num>(0, (sum, item) => sum + item.amount);
    final netPay = max(_round(grossEarnings - totalDeductions), 0);
    final version = await repository.nextVersion(employeeId, month, year);
    final payslipId = '$employeeId-$year-${month.toString().padLeft(2, '0')}-v$version';

    return PayslipDraft(
      payslipId: payslipId,
      employeeId: employeeId,
      employeeName: '${employee['name'] ?? ''}',
      department: '${employee['department'] ?? ''}',
      designation: '${employee['designation'] ?? ''}',
      dateOfJoining: '${employee['dateOfJoining'] ?? ''}',
      branch: '${employee['branch'] ?? employee['workLocation'] ?? ''}',
      bankAccountMasked: _mask('${employee['bankAccountNumber'] ?? ''}'),
      paymentMode: '${employee['paymentMode'] ?? 'Bank Transfer'}',
      payrollMonth: month,
      payrollYear: year,
      periodStartDate: periodStart,
      periodEndDate: periodEnd,
      totalDays: totalDays,
      workingDays: workingDays,
      presentDays: presentDays,
      paidLeaveDays: paidLeaveDays,
      lopDays: lopDays,
      weekOffDays: weekOffDays,
      holidayDays: holidayDays,
      payableDays: payableDays,
      earnings: earnings,
      deductions: deductions,
      grossEarnings: _round(grossEarnings),
      totalDeductions: _round(totalDeductions),
      netPay: netPay,
      netPayInWords: words.rupees(netPay),
      paymentDate: DateTime.now(),
      paymentStatus: 'pending',
      status: 'draft',
      generatedBy: generatedBy,
      version: version,
    );
  }

  Future<Map<String, dynamic>> generatePayslip({
    required String employeeId,
    required int month,
    required int year,
    required String generatedBy,
  }) async {
    final draft = await calculateDraft(employeeId: employeeId, month: month, year: year, generatedBy: generatedBy);
    final bytes = await pdfService.buildPayslipPdf(draft);
    final url = await repository.uploadPdf(
      employeeId: employeeId,
      month: month,
      year: year,
      version: draft.version,
      bytes: bytes,
    );
    await repository.saveGeneratedPayslip(draft, url);
    return draft.toMap(
      pdfUrl: url,
      statusOverride: draft.version > 1 ? 'revised' : 'generated',
    );
  }

  int _countWeekOffs(DateTime start, DateTime end) {
    var count = 0;
    var current = start;
    while (!current.isAfter(end)) {
      if (current.weekday == DateTime.saturday || current.weekday == DateTime.sunday) count++;
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  int _leaveDays(Map<String, dynamic> item, DateTime start, DateTime end) {
    final from = _date(item['fromDate']) ?? start;
    final to = _date(item['toDate']) ?? from;
    final overlapStart = from.isBefore(start) ? start : from;
    final overlapEnd = to.isAfter(end) ? end : to;
    return overlapEnd.difference(overlapStart).inDays + 1;
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  num _round(num value) => (value * 100).round() / 100;

  String _mask(String account) {
    if (account.length <= 4) return account;
    return '${List.filled(account.length - 4, '*').join()}${account.substring(account.length - 4)}';
  }
}
