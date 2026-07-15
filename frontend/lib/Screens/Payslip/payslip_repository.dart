import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

import 'payslip_models.dart';

class PayslipRepository {
  final FirebaseFirestore firestore;

  PayslipRepository({
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> fetchPayrollLock(int month, int year) async {
    final id = _payrollId(month, year);
    final doc = await firestore.collection('payrolls').doc(id).get();
    return doc.data();
  }

  Future<void> approveAndLockPayroll({
    required int month,
    required int year,
    required String actorId,
  }) async {
    final id = _payrollId(month, year);
    await firestore.collection('payrolls').doc(id).set({
      'payrollId': id,
      'payrollMonth': month,
      'payrollYear': year,
      'status': 'approved',
      'locked': true,
      'approvedBy': actorId,
      'approvedAt': FieldValue.serverTimestamp(),
      'lockedBy': actorId,
      'lockedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await audit(id, 'payroll_approved_locked', actorId);
  }

  Future<Map<String, dynamic>> fetchEmployee(String employeeId) async {
    final doc = await firestore.collection('employees').doc(employeeId).get();
    return doc.data() ?? {};
  }

  Future<Map<String, dynamic>> fetchSalaryStructure(String employeeId) async {
    final doc = await firestore.collection('salaryStructures').doc(employeeId).get();
    return doc.data() ?? {};
  }

  Future<List<Map<String, dynamic>>> fetchAttendance({
    required String employeeId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await firestore
        .collection('attendance')
        .where('employeeId', isEqualTo: employeeId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> fetchLeaves({
    required String employeeId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await firestore
        .collection('leaves')
        .where('employeeId', isEqualTo: employeeId)
        .where('status', isEqualTo: 'approved')
        .where('fromDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return snapshot.docs
        .map((doc) => doc.data())
        .where((data) {
          final toDate = _date(data['toDate']);
          return toDate == null || !toDate.isBefore(start);
        })
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchOvertime({
    required String employeeId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await firestore
        .collection('overtime')
        .where('employeeId', isEqualTo: employeeId)
        .where('status', isEqualTo: 'approved')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<int> nextVersion(String employeeId, int month, int year) async {
    final snapshot = await firestore
        .collection('payslips')
        .where('employeeId', isEqualTo: employeeId)
        .where('payrollMonth', isEqualTo: month)
        .where('payrollYear', isEqualTo: year)
        .orderBy('version', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return 1;
    return ((snapshot.docs.first.data()['version'] as num?)?.toInt() ?? 0) + 1;
  }

  Future<String> uploadPdf({
    required String employeeId,
    required int month,
    required int year,
    required int version,
    required Uint8List bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      ApiConfig.uri('/hr/payslip-pdf/upload/'),
    );
    request.fields.addAll({
      'employee_id': employeeId,
      'month': '$month',
      'year': '$year',
      'version': '$version',
    });
    request.files.add(
      http.MultipartFile.fromBytes(
        'pdf',
        bytes,
        filename: '$employeeId-$year-${month.toString().padLeft(2, '0')}-v$version.pdf',
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['pdf_url'] != null) {
        return '${decoded['pdf_url']}';
      }
    }
    throw Exception('Payslip PDF upload failed with status ${response.statusCode}.');
  }

  Future<void> saveGeneratedPayslip(PayslipDraft draft, String pdfUrl) async {
    final status = draft.version > 1 ? 'revised' : 'generated';
    await firestore.collection('payslips').doc(draft.payslipId).set(
          draft.toMap(pdfUrl: pdfUrl, statusOverride: status),
        );
    await audit(draft.payslipId, status, draft.generatedBy);
  }

  Future<void> releasePayslip(String payslipId, String actorId) async {
    await firestore.collection('payslips').doc(payslipId).update({
      'status': 'released',
      'releasedAt': FieldValue.serverTimestamp(),
    });
    await audit(payslipId, 'released', actorId);
  }

  Future<void> cancelPayslip(String payslipId, String actorId) async {
    await firestore.collection('payslips').doc(payslipId).update({'status': 'cancelled'});
    await audit(payslipId, 'cancelled', actorId);
  }

  Future<void> audit(String payslipId, String action, String actorId) {
    return firestore.collection('payslipAuditLogs').add({
      'payslipId': payslipId,
      'action': action,
      'actorId': actorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> releasedPayslipsForEmployee(String employeeId) {
    return firestore
        .collection('payslips')
        .where('employeeId', isEqualTo: employeeId)
        .where('status', whereIn: ['released', 'paid'])
        .orderBy('payrollYear', descending: true)
        .orderBy('payrollMonth', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> generatedPayslips(int month, int year) {
    return firestore
        .collection('payslips')
        .where('payrollMonth', isEqualTo: month)
        .where('payrollYear', isEqualTo: year)
        .orderBy('employeeName')
        .snapshots();
  }

  String _payrollId(int month, int year) => '$year-${month.toString().padLeft(2, '0')}';

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
