import 'package:cloud_firestore/cloud_firestore.dart';

class PayslipComponent {
  final String name;
  final num actualAmount;
  final num earnedAmount;

  const PayslipComponent({
    required this.name,
    required this.actualAmount,
    required this.earnedAmount,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'actualAmount': actualAmount,
        'earnedAmount': earnedAmount,
      };
}

class PayslipDeduction {
  final String name;
  final num amount;

  const PayslipDeduction({required this.name, required this.amount});

  Map<String, dynamic> toMap() => {'name': name, 'amount': amount};
}

class PayslipDraft {
  final String payslipId;
  final String employeeId;
  final String employeeName;
  final String department;
  final String designation;
  final String dateOfJoining;
  final String branch;
  final String bankAccountMasked;
  final String paymentMode;
  final int payrollMonth;
  final int payrollYear;
  final DateTime periodStartDate;
  final DateTime periodEndDate;
  final int totalDays;
  final int workingDays;
  final int presentDays;
  final int paidLeaveDays;
  final int lopDays;
  final int weekOffDays;
  final int holidayDays;
  final int payableDays;
  final List<PayslipComponent> earnings;
  final List<PayslipDeduction> deductions;
  final num grossEarnings;
  final num totalDeductions;
  final num netPay;
  final String netPayInWords;
  final DateTime paymentDate;
  final String paymentStatus;
  final String status;
  final String generatedBy;
  final int version;

  const PayslipDraft({
    required this.payslipId,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.designation,
    required this.dateOfJoining,
    required this.branch,
    required this.bankAccountMasked,
    required this.paymentMode,
    required this.payrollMonth,
    required this.payrollYear,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.totalDays,
    required this.workingDays,
    required this.presentDays,
    required this.paidLeaveDays,
    required this.lopDays,
    required this.weekOffDays,
    required this.holidayDays,
    required this.payableDays,
    required this.earnings,
    required this.deductions,
    required this.grossEarnings,
    required this.totalDeductions,
    required this.netPay,
    required this.netPayInWords,
    required this.paymentDate,
    required this.paymentStatus,
    required this.status,
    required this.generatedBy,
    required this.version,
  });

  Map<String, dynamic> toMap({String pdfUrl = '', String? statusOverride}) => {
        'payslipId': payslipId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'payrollMonth': payrollMonth,
        'payrollYear': payrollYear,
        'periodStartDate': Timestamp.fromDate(periodStartDate),
        'periodEndDate': Timestamp.fromDate(periodEndDate),
        'totalDays': totalDays,
        'workingDays': workingDays,
        'presentDays': presentDays,
        'paidLeaveDays': paidLeaveDays,
        'lopDays': lopDays,
        'weekOffDays': weekOffDays,
        'holidayDays': holidayDays,
        'payableDays': payableDays,
        'employee': {
          'department': department,
          'designation': designation,
          'dateOfJoining': dateOfJoining,
          'branch': branch,
          'bankAccountMasked': bankAccountMasked,
          'paymentMode': paymentMode,
        },
        'earnings': earnings.map((item) => item.toMap()).toList(),
        'deductions': deductions.map((item) => item.toMap()).toList(),
        'grossEarnings': grossEarnings,
        'totalDeductions': totalDeductions,
        'netPay': netPay,
        'netPayInWords': netPayInWords,
        'paymentDate': Timestamp.fromDate(paymentDate),
        'paymentStatus': paymentStatus,
        'pdfUrl': pdfUrl,
        'status': statusOverride ?? status,
        'generatedBy': generatedBy,
        'generatedAt': FieldValue.serverTimestamp(),
        'releasedAt': null,
        'version': version,
      };
}
