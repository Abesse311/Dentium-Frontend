import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_application_1/core/utils/date_formatter.dart';
import 'package:flutter_application_1/core/utils/invoice_item_grouper.dart';
import 'package:flutter_application_1/models/invoice_item_model.dart';
import 'package:flutter_application_1/models/invoice_model.dart';
import 'package:flutter_application_1/models/patient_model.dart';
import 'package:flutter_application_1/models/patient_treatment_model.dart';
import 'package:flutter_application_1/models/treatment_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  group('DateFormatter Tests', () {
    test('formatCurrency correctly formats DZD amounts with thousands separators', () {
      expect(DateFormatter.formatCurrency(0), '0 DA');
      // Normalize space / non-breaking space for locale comparison
      final f2500 = DateFormatter.formatCurrency(2500).replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');
      expect(f2500, '2 500 DA');

      final f12500 = DateFormatter.formatCurrency(12500).replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');
      expect(f12500, '12 500 DA');

      final f1m = DateFormatter.formatCurrency(1000000).replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');
      expect(f1m, '1 000 000 DA');

      expect(DateFormatter.formatCurrency(null), '0 DA');
    });

    test('fromApiString correctly parses YYYY-MM-DD and ISO strings', () {
      final parsed1 = DateFormatter.fromApiString('2026-08-21');
      expect(parsed1, isNotNull);
      expect(parsed1!.year, 2026);
      expect(parsed1.month, 8);
      expect(parsed1.day, 21);

      final parsed2 = DateFormatter.fromApiString('2026-01-05T14:30:00Z');
      expect(parsed2, isNotNull);
      expect(parsed2!.year, 2026);
      expect(parsed2.month, 1);
      expect(parsed2.day, 5);

      expect(DateFormatter.fromApiString(null), isNull);
      expect(DateFormatter.fromApiString(''), isNull);
      expect(DateFormatter.fromApiString('invalid-date'), isNull);
    });

    test('toApiString produces YYYY-MM-DD format', () {
      final dt = DateTime(2026, 3, 9);
      expect(DateFormatter.toApiString(dt), '2026-03-09');
    });
  });

  group('InvoiceItemGrouper Tests', () {
    test('describeTeethGroup describes single teeth, arches, wisdom teeth, and sets', () {
      expect(InvoiceItemGrouper.describeTeethGroup([15]), 'Dent 15');
      expect(
        InvoiceItemGrouper.describeTeethGroup([18, 28, 38, 48]),
        'Dents de sagesse (4 dents : 18, 28, 38, 48)',
      );
      expect(
        InvoiceItemGrouper.describeTeethGroup([
          18, 17, 16, 15, 14, 13, 12, 11,
          21, 22, 23, 24, 25, 26, 27, 28,
        ]),
        'Maxillaire (Haut • 16 dents)',
      );
      expect(
        InvoiceItemGrouper.describeTeethGroup([
          48, 47, 46, 45, 44, 43, 42, 41,
          31, 32, 33, 34, 35, 36, 37, 38,
        ]),
        'Mandibule (Bas • 16 dents)',
      );
      expect(
        InvoiceItemGrouper.describeTeethGroup([11, 12, 13]),
        'Dents : 11, 12, 13 (3 dents)',
      );
    });

    test('groupInvoiceItems groups tooth items by procedure', () {
      final items = [
        const InvoiceItemModel(
          id: 1,
          invoiceId: 10,
          description: 'Extraction simple (Dent 18)',
          amount: 2500,
        ),
        const InvoiceItemModel(
          id: 2,
          invoiceId: 10,
          description: 'Extraction simple (Dent 28)',
          amount: 2500,
        ),
        const InvoiceItemModel(
          id: 3,
          invoiceId: 10,
          description: 'Détartrage complet',
          amount: 3000,
        ),
      ];

      final grouped = InvoiceItemGrouper.groupInvoiceItems(items);
      expect(grouped.length, 2);

      final extractions = grouped.firstWhere((g) => g.title.contains('Extraction simple'));
      expect(extractions.count, 2);
      expect(extractions.totalAmount, 5000);
      expect(extractions.toothNumbers, [18, 28]);

      final detartrage = grouped.firstWhere((g) => g.title.contains('Détartrage complet'));
      expect(detartrage.count, 1);
      expect(detartrage.totalAmount, 3000);
    });

    test('groupPatientTreatments groups multi-tooth treatments on the same date', () {
      final treatments = [
        const PatientTreatmentModel(
          id: 1,
          patientId: 5,
          treatmentTypeId: 2,
          treatmentTypeName: 'Plombage composite',
          toothNumber: 14,
          price: 3500,
          treatmentDate: '2026-08-21',
        ),
        const PatientTreatmentModel(
          id: 2,
          patientId: 5,
          treatmentTypeId: 2,
          treatmentTypeName: 'Plombage composite',
          toothNumber: 15,
          price: 3500,
          treatmentDate: '2026-08-21',
        ),
      ];

      final grouped = InvoiceItemGrouper.groupPatientTreatments(treatments);
      expect(grouped.length, 1);
      expect(grouped.first.totalAmount, 7000);
      expect(grouped.first.treatmentIds, [1, 2]);
    });
  });

  group('PatientModel Tests', () {
    test('JSON serialization, initials, and age computation', () {
      final patient = PatientModel(
        id: 10,
        fullName: 'Amine Kaci',
        phone: '0550123456',
        birthDate: '2000-05-15',
        gender: 'male',
      );

      expect(patient.initials, 'AK');
      expect(patient.age, isNotNull);
      expect(patient.age, greaterThanOrEqualTo(25));

      final json = patient.toJson();
      expect(json['full_name'], 'Amine Kaci');
      expect(json['birth_date'], '2000-05-15');

      final fromJson = PatientModel.fromJson(json);
      expect(fromJson.id, 10);
      expect(fromJson.fullName, 'Amine Kaci');
      expect(fromJson.gender, 'male');
    });

    test('PatientModel handles null or missing optional fields gracefully', () {
      final patient = PatientModel.fromJson({
        'id': 99,
        'full_name': 'Sarah',
      });

      expect(patient.id, 99);
      expect(patient.fullName, 'Sarah');
      expect(patient.phone, isNull);
      expect(patient.birthDate, isNull);
      expect(patient.age, isNull);
      expect(patient.initials, 'S');
    });
  });

  group('InvoiceModel Tests', () {
    test('Invoice status and balance calculations', () {
      final invUnpaid = InvoiceModel(
        id: 1,
        patientId: 5,
        invoiceNumber: 'FAC-2026-0001',
        invoiceDate: '2026-08-21',
        totalAmount: 10000,
        paidAmount: 0,
        status: 'unpaid',
      );

      expect(invUnpaid.remainingAmount, 10000);
      expect(invUnpaid.isUnpaid, isTrue);
      expect(invUnpaid.isPaid, isFalse);
      expect(invUnpaid.isPartiallyPaid, isFalse);

      final invPart = invUnpaid.copyWith(
        paidAmount: 4000,
        status: 'partially_paid',
      );
      expect(invPart.remainingAmount, 6000);
      expect(invPart.isPartiallyPaid, isTrue);

      final invPaid = invUnpaid.copyWith(
        paidAmount: 10000,
        status: 'paid',
      );
      expect(invPaid.remainingAmount, 0);
      expect(invPaid.isPaid, isTrue);
    });

    test('InvoiceModel JSON roundtrip with line items and payments', () {
      final inv = InvoiceModel.fromJson({
        'id': 42,
        'patient_id': 12,
        'invoice_number': 'FAC-2026-0042',
        'invoice_date': '2026-08-21',
        'total_amount': 25000,
        'paid_amount': 15000,
        'status': 'partially_paid',
        'patient_name': 'Mustapha Dahleb',
        'items': [
          {'id': 101, 'invoice_id': 42, 'description': 'Couronne céramique', 'amount': 25000}
        ],
        'payments': [
          {'id': 201, 'invoice_id': 42, 'amount': 15000, 'payment_date': '2026-08-21', 'payment_method': 'cash'}
        ]
      });

      expect(inv.id, 42);
      expect(inv.patientName, 'Mustapha Dahleb');
      expect(inv.items.length, 1);
      expect(inv.payments.length, 1);
      expect(inv.remainingAmount, 10000);
    });
  });

  group('TreatmentModel Tests', () {
    test('Treatment classification and FDI tooth labeling', () {
      final generalTreatment = TreatmentModel(
        id: 1,
        patientId: 3,
        treatmentTypeId: 1,
        price: 1500,
      );
      expect(generalTreatment.isGeneral, isTrue);
      expect(generalTreatment.isPerTooth, isFalse);
      expect(generalTreatment.toothLabel, 'Soin Général');

      final toothTreatment = TreatmentModel(
        id: 2,
        patientId: 3,
        treatmentTypeId: 4,
        toothNumber: 24,
        price: 4500,
      );
      expect(toothTreatment.isGeneral, isFalse);
      expect(toothTreatment.isPerTooth, isTrue);
      expect(toothTreatment.toothLabel, 'Dent 24');
    });
  });
}
