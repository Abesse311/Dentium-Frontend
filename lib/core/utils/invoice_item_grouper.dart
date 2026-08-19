import '../../models/invoice_item_model.dart';
import '../../models/patient_treatment_model.dart';
import '../../models/treatment_model.dart';
import 'date_formatter.dart';

class GroupedInvoiceItem {
  final String title;
  final String? subtitle;
  final double totalAmount;
  final int count;
  final List<int> toothNumbers;
  final String? baseDescription;
  final List<InvoiceItemModel> rawItems;

  const GroupedInvoiceItem({
    required this.title,
    this.subtitle,
    required this.totalAmount,
    required this.count,
    this.toothNumbers = const [],
    this.baseDescription,
    this.rawItems = const [],
  });

  String get formattedTotal => DateFormatter.formatCurrency(totalAmount);
}

class GroupedPatientTreatment {
  final String title;
  final String subtitle;
  final double totalAmount;
  final List<int> treatmentIds;
  final List<PatientTreatmentModel> rawTreatments;

  const GroupedPatientTreatment({
    required this.title,
    required this.subtitle,
    required this.totalAmount,
    required this.treatmentIds,
    required this.rawTreatments,
  });

  String get formattedTotal => DateFormatter.formatCurrency(totalAmount);
}

class InvoiceItemGrouper {
  static const List<int> upperRight = [18, 17, 16, 15, 14, 13, 12, 11];
  static const List<int> upperLeft = [21, 22, 23, 24, 25, 26, 27, 28];
  static const List<int> lowerRight = [48, 47, 46, 45, 44, 43, 42, 41];
  static const List<int> lowerLeft = [31, 32, 33, 34, 35, 36, 37, 38];
  static const List<int> allUpper = [...upperRight, ...upperLeft];
  static const List<int> allLower = [...lowerRight, ...lowerLeft];
  static const List<int> wisdom = [18, 28, 38, 48];

  /// Determine the anatomical arch or tooth description for a group of teeth
  static String describeTeethGroup(List<int> toothNumbers) {
    final teeth = toothNumbers.toSet().toList()..sort();
    final teethSet = teeth.toSet();
    final count = teeth.length;

    if (count == 1) {
      return 'Dent ${teeth.first}';
    }

    if (count == 16 && allUpper.every((t) => teethSet.contains(t))) {
      return 'Maxillaire (Haut • 16 dents)';
    }
    if (count == 16 && allLower.every((t) => teethSet.contains(t))) {
      return 'Mandibule (Bas • 16 dents)';
    }
    if (count == 4 && wisdom.every((t) => teethSet.contains(t))) {
      return 'Dents de sagesse (4 dents : 18, 28, 38, 48)';
    }
    if (count == 8 && upperRight.every((t) => teethSet.contains(t))) {
      return 'Quadrant 1 (Haut Droite • 8 dents)';
    }
    if (count == 8 && upperLeft.every((t) => teethSet.contains(t))) {
      return 'Quadrant 2 (Haut Gauche • 8 dents)';
    }
    if (count == 8 && lowerLeft.every((t) => teethSet.contains(t))) {
      return 'Quadrant 3 (Bas Gauche • 8 dents)';
    }
    if (count == 8 && lowerRight.every((t) => teethSet.contains(t))) {
      return 'Quadrant 4 (Bas Droite • 8 dents)';
    }

    return 'Dents : ${teeth.join(', ')} ($count dents)';
  }

  /// Groups invoice items by base procedure name
  static List<GroupedInvoiceItem> groupInvoiceItems(List<InvoiceItemModel> items) {
    if (items.isEmpty) return [];

    final toothRegex = RegExp(
      r'^(.*?)\s*(?:\(|[-–—])\s*Dent\s*(\d{2})\s*\)?$',
      caseSensitive: false,
    );

    final Map<String, List<_ParsedInvoiceItem>> groups = {};
    final List<GroupedInvoiceItem> result = [];

    for (final item in items) {
      final match = toothRegex.firstMatch(item.description.trim());
      if (match != null) {
        final baseName = match.group(1)?.trim() ?? item.description;
        final toothNum = int.tryParse(match.group(2) ?? '');
        if (toothNum != null) {
          groups.putIfAbsent(baseName, () => []).add(
                _ParsedInvoiceItem(item: item, toothNumber: toothNum),
              );
          continue;
        }
      }

      result.add(GroupedInvoiceItem(
        title: item.description,
        totalAmount: item.amount,
        count: 1,
        rawItems: [item],
      ));
    }

    for (final entry in groups.entries) {
      final baseName = entry.key;
      final parsedList = entry.value;

      if (parsedList.length == 1) {
        final p = parsedList.first;
        result.add(GroupedInvoiceItem(
          title: p.item.description,
          totalAmount: p.item.amount,
          count: 1,
          toothNumbers: [p.toothNumber],
          baseDescription: baseName,
          rawItems: [p.item],
        ));
        continue;
      }

      final teeth = parsedList.map((e) => e.toothNumber).toSet().toList()..sort();
      final totalAmount = parsedList.fold(0.0, (sum, e) => sum + e.item.amount);
      final count = parsedList.length;
      final unitPrice = totalAmount / count;

      final archLabel = describeTeethGroup(teeth);
      final title = '$baseName — $archLabel';
      final subtitle = '$count actes × ${DateFormatter.formatCurrency(unitPrice)}';

      result.add(GroupedInvoiceItem(
        title: title,
        subtitle: subtitle,
        totalAmount: totalAmount,
        count: count,
        toothNumbers: teeth,
        baseDescription: baseName,
        rawItems: parsedList.map((e) => e.item).toList(),
      ));
    }

    return result;
  }

  /// Groups unbilled patient treatments for the invoice creation dialog
  static List<GroupedPatientTreatment> groupPatientTreatments(
    List<PatientTreatmentModel> treatments,
  ) {
    if (treatments.isEmpty) return [];

    final Map<String, List<PatientTreatmentModel>> groups = {};

    for (final t in treatments) {
      // Group by procedure name + date
      final key = '${t.displayName}__${t.treatmentDate}';
      groups.putIfAbsent(key, () => []).add(t);
    }

    final List<GroupedPatientTreatment> result = [];

    for (final entry in groups.entries) {
      final list = entry.value;
      if (list.length == 1) {
        final t = list.first;
        result.add(GroupedPatientTreatment(
          title: t.displayName,
          subtitle: '${t.toothLabel} • ${t.formattedDate}',
          totalAmount: t.price,
          treatmentIds: [t.id],
          rawTreatments: [t],
        ));
      } else {
        final teeth = list
            .where((t) => t.toothNumber != null)
            .map((t) => t.toothNumber!)
            .toSet()
            .toList()
          ..sort();

        final totalAmount = list.fold(0.0, (sum, e) => sum + e.price);
        final count = list.length;
        final date = list.first.formattedDate;

        String archLabel = '';
        if (teeth.isNotEmpty) {
          archLabel = describeTeethGroup(teeth);
        } else {
          archLabel = '$count actes';
        }

        final title = '${list.first.displayName} — $archLabel';
        final subtitle = '$count actes • $date';

        result.add(GroupedPatientTreatment(
          title: title,
          subtitle: subtitle,
          totalAmount: totalAmount,
          treatmentIds: list.map((t) => t.id).toList(),
          rawTreatments: list,
        ));
      }
    }

    return result;
  }
}

class _ParsedInvoiceItem {
  final InvoiceItemModel item;
  final int toothNumber;
  _ParsedInvoiceItem({required this.item, required this.toothNumber});
}

// ---------------------------------------------------------------------------
// Patient history grouping  (Patients → Traitements Réalisés tab)
// ---------------------------------------------------------------------------

/// A row in the grouped patient history: represents one procedure applied to
/// one or more teeth on the same date with the same status.
class GroupedHistoryTreatment {
  final String procedureName;
  final String archLabel;   // e.g. 'Maxillaire (Haut • 16 dents)' or 'Dent 15'
  final String dateLabel;
  final String status;
  final double totalAmount;
  final int count;
  final List<int> toothNumbers;
  final List<PatientTreatmentModel> rawTreatments;

  const GroupedHistoryTreatment({
    required this.procedureName,
    required this.archLabel,
    required this.dateLabel,
    required this.status,
    required this.totalAmount,
    required this.count,
    required this.toothNumbers,
    required this.rawTreatments,
  });

  String get formattedTotal => DateFormatter.formatCurrency(totalAmount);

  /// Subtitle shown below the procedure name
  String get subtitle {
    if (count <= 1) return dateLabel;
    final unit = DateFormatter.formatCurrency(totalAmount / count);
    return '$count actes × $unit • $dateLabel';
  }
}

extension InvoiceItemGrouperHistory on InvoiceItemGrouper {
  /// Groups [PatientTreatmentModel] list by (procedureName + date + status),
  /// then collapses multi-tooth groups into named arches.
  static List<GroupedHistoryTreatment> groupHistoryTreatments(
    List<PatientTreatmentModel> treatments,
  ) {
    if (treatments.isEmpty) return [];

    // Key: "procedureName__date__status"
    final Map<String, List<PatientTreatmentModel>> buckets = {};

    for (final t in treatments) {
      // General treatments (no tooth) are never grouped with tooth treatments
      final key =
          '${t.displayName}__${t.treatmentDate ?? ''}__${t.status}__${t.toothNumber == null ? 'general' : 'tooth'}';
      buckets.putIfAbsent(key, () => []).add(t);
    }

    final List<GroupedHistoryTreatment> result = [];

    for (final entry in buckets.entries) {
      final list = entry.value;

      if (list.length == 1) {
        final t = list.first;
        result.add(GroupedHistoryTreatment(
          procedureName: t.displayName,
          archLabel: t.toothLabel,
          dateLabel: t.formattedDate,
          status: t.status,
          totalAmount: t.price,
          count: 1,
          toothNumbers: t.toothNumber != null ? [t.toothNumber!] : [],
          rawTreatments: [t],
        ));
        continue;
      }

      // Multiple treatments with the same procedure+date+status
      final teeth = list
          .where((t) => t.toothNumber != null)
          .map((t) => t.toothNumber!)
          .toSet()
          .toList()
        ..sort();

      final totalAmount = list.fold(0.0, (s, t) => s + t.price);
      final archLabel = teeth.isNotEmpty
          ? InvoiceItemGrouper.describeTeethGroup(teeth)
          : '${list.length} actes';

      result.add(GroupedHistoryTreatment(
        procedureName: list.first.displayName,
        archLabel: archLabel,
        dateLabel: list.first.formattedDate,
        status: list.first.status,
        totalAmount: totalAmount,
        count: list.length,
        toothNumbers: teeth,
        rawTreatments: list,
      ));
    }

    return result;
  }
}

// ---------------------------------------------------------------------------
// TreatmentModel grouping (Traitements → Mode Multi-Dents panel)
// ---------------------------------------------------------------------------

class GroupedTreatmentModel {
  final String procedureName;
  final String archLabel;
  final String dateLabel;
  final String status;
  final double totalAmount;
  final int count;
  final List<int> toothNumbers;
  final List<TreatmentModel> rawTreatments;

  const GroupedTreatmentModel({
    required this.procedureName,
    required this.archLabel,
    required this.dateLabel,
    required this.status,
    required this.totalAmount,
    required this.count,
    required this.toothNumbers,
    required this.rawTreatments,
  });

  String get formattedTotal => DateFormatter.formatCurrency(totalAmount);

  String get subtitle {
    if (count <= 1) return dateLabel;
    final unit = DateFormatter.formatCurrency(totalAmount / count);
    return '$count actes × $unit • $dateLabel';
  }
}

extension InvoiceItemGrouperTreatments on InvoiceItemGrouper {
  /// Groups [TreatmentModel] list by (procedureName + date + status)
  static List<GroupedTreatmentModel> groupTreatments(
    List<TreatmentModel> treatments,
  ) {
    if (treatments.isEmpty) return [];

    final Map<String, List<TreatmentModel>> buckets = {};

    for (final t in treatments) {
      final key =
          '${t.displayName}__${t.treatmentDate ?? ''}__${t.status}__${t.toothNumber == null ? 'general' : 'tooth'}';
      buckets.putIfAbsent(key, () => []).add(t);
    }

    final List<GroupedTreatmentModel> result = [];

    for (final entry in buckets.entries) {
      final list = entry.value;

      if (list.length == 1) {
        final t = list.first;
        result.add(GroupedTreatmentModel(
          procedureName: t.displayName,
          archLabel: t.toothLabel,
          dateLabel: t.formattedDate,
          status: t.status,
          totalAmount: t.price,
          count: 1,
          toothNumbers: t.toothNumber != null ? [t.toothNumber!] : [],
          rawTreatments: [t],
        ));
        continue;
      }

      final teeth = list
          .where((t) => t.toothNumber != null)
          .map((t) => t.toothNumber!)
          .toSet()
          .toList()
        ..sort();

      final totalAmount = list.fold(0.0, (s, t) => s + t.price);
      final archLabel = teeth.isNotEmpty
          ? InvoiceItemGrouper.describeTeethGroup(teeth)
          : '${list.length} actes';

      result.add(GroupedTreatmentModel(
        procedureName: list.first.displayName,
        archLabel: archLabel,
        dateLabel: list.first.formattedDate,
        status: list.first.status,
        totalAmount: totalAmount,
        count: list.length,
        toothNumbers: teeth,
        rawTreatments: list,
      ));
    }

    return result;
  }
}

