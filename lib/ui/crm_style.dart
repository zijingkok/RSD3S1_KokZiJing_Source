import 'package:flutter/material.dart';
import '../../Models/work_order.dart';



// ===== Colors (match teammate’s palette)
class CrmColors {
  static const bg       = Color(0xFFF5F7FA);
  static const surface  = Color(0xFFF1F4F8);
  static const ink      = Color(0xFF1D2A32);
  static const muted    = Color(0xFF6A7A88);
  static const primary  = Color(0xFF1E88E5);
  static const primaryDark = Color(0xFF1565C0);
  static const success  = Color(0xFF2EB872);
  static const danger   = Color(0xFFE53935);
}

// ===== Card look (keep your existing padding around it)
final crmCardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
final crmCardDecoration = BoxDecoration(
  color: CrmColors.surface,
  borderRadius: BorderRadius.circular(16),
);

// ===== Text styles (don’t change your layout; just swap the styles)
const crmTitleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CrmColors.ink);
const crmLabelStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CrmColors.muted, letterSpacing: .2);
const crmValueStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: CrmColors.ink);

// ===== Section title widget (drop-in replacement for your headers)
class CrmSectionTitle extends StatelessWidget {
  final String title;
  const CrmSectionTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // keep spacing tiny & local
      child: Text(title, style: crmTitleStyle),
    );
  }
}

// ===== Chips (status / priority) – colors map to your enums
Widget statusChip(WorkOrderStatus s) {
  final data = switch (s) {
    WorkOrderStatus.scheduled   => (label: 'Scheduled',  bg: Color(0xFFE3F2FD), fg: CrmColors.primaryDark),
    WorkOrderStatus.inProgress => (label: 'In Progress', bg: Color(0xFFBBDEFB), fg: CrmColors.primaryDark),
    WorkOrderStatus.onHold     => (label: 'On Hold',   bg: Color(0xFFF3F4F6), fg: CrmColors.muted),
    WorkOrderStatus.completed  => (label: 'Completed', bg: Color(0xFFDFF5E7), fg: CrmColors.success),
    WorkOrderStatus.unassigned => (label: 'Unassigned',bg: Color(0xFFF3F4F6), fg: CrmColors.muted),
  };
  return Chip(
    label: Text(data.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    backgroundColor: data.bg,
    labelStyle: TextStyle(color: data.fg),
    visualDensity: VisualDensity.compact,
    shape: StadiumBorder(side: BorderSide(color: data.fg.withOpacity(.08))),
  );
}

Widget priorityChip(WorkOrderPriority p) {
  final data = switch (p) {
    WorkOrderPriority.low     => (label: 'Low',     bg: Color(0xFFF8FAFC), fg: CrmColors.muted),
    WorkOrderPriority.normal  => (label: 'Normal',  bg: Color(0xFFF3F4F6), fg: CrmColors.ink),
    WorkOrderPriority.high    => (label: 'High',    bg: Color(0xFFFFEBEE), fg: CrmColors.danger),
    WorkOrderPriority.urgent  => (label: 'Urgent',  bg: Color(0xFFFFE6E9), fg: CrmColors.danger),
  };
  return Chip(
    label: Text(data.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    backgroundColor: data.bg,
    labelStyle: TextStyle(color: data.fg),
    visualDensity: VisualDensity.compact,
    shape: StadiumBorder(side: BorderSide(color: data.fg.withOpacity(.10))),
  );
}

// ===== Simple key:value row that respects your existing spacing
class CrmKV extends StatelessWidget {
  final String k;
  final String v;
  const CrmKV(this.k, this.v, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(k, style: crmLabelStyle)),
        const SizedBox(width: 8),
        Expanded(child: Text(v, style: crmValueStyle)),
      ],
    );
  }
}
