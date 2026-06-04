import 'package:flutter/material.dart';
import 'package:civilhelp/features/labour/data/models/labour_model.dart';
import 'package:civilhelp/features/sites/models/site_model.dart';
import '../models/attendance_model.dart';

class AttendanceForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<SiteModel> sites;
  final List<LabourModel> labour;
  final AttendanceModel? initialAttendance;
  final void Function(
    String siteId,
    String siteName,
    String labourId,
    String labourName,
    DateTime date,
    String status,
    double hoursWorked,
  ) onSubmit;
  final String submitLabel;
  final bool isLoading;
  final String? inlineError;
  final VoidCallback? onChanged;

  const AttendanceForm({
    super.key,
    required this.formKey,
    required this.sites,
    required this.labour,
    this.initialAttendance,
    required this.onSubmit,
    this.submitLabel = 'Save',
    this.isLoading = false,
    this.inlineError,
    this.onChanged,
  });

  @override
  State<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends State<AttendanceForm> {
  late DateTime selectedDate;
  late String selectedStatus;
  late String? selectedSiteId;
  late String? selectedLabourId;
  late double hoursWorked;
  late String hoursWorkedText;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.initialAttendance != null) {
      final att = widget.initialAttendance!;
      selectedDate = att.date;
      selectedStatus = att.status;
      selectedSiteId = att.siteId;
      selectedLabourId = att.labourId;
      hoursWorked = att.hoursWorked;
      hoursWorkedText = att.hoursWorked.toStringAsFixed(1);
    } else {
      selectedDate = DateTime.now();
      selectedStatus = 'Present';
      selectedSiteId = null;
      selectedLabourId = null;
      hoursWorked = 8.0;
      hoursWorkedText = '8.0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Site dropdown
            DropdownButtonFormField<String>(
              initialValue: selectedSiteId,
              decoration: const InputDecoration(
                labelText: 'Site',
                isDense: true,
              ),
              items: widget.sites
                  .map(
                    (site) => DropdownMenuItem(
                      value: site.id,
                      child: Text(site.name),
                    ),
                  )
                  .toList(),
              onChanged: widget.initialAttendance != null
                  ? null
                  : (value) {
                      setState(() {
                        selectedSiteId = value;
                      });
                    },
              disabledHint: widget.initialAttendance != null
                  ? const Text('Site (locked)')
                  : null,
              validator: (value) => value == null ? 'Select a site' : null,
            ),
            const SizedBox(height: 12),

            // Labour dropdown (filtered by selected site)
            DropdownButtonFormField<String>(
              initialValue: selectedLabourId,
              decoration: const InputDecoration(
                labelText: 'Labour',
                isDense: true,
              ),
              items: () {
                if (selectedSiteId == null) {
                  return <DropdownMenuItem<String>>[];
                }

                final filtered = widget.labour
                    .where((l) => l.assignedSiteId == selectedSiteId)
                    .toList();

                return filtered
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.id,
                        child: Text(entry.fullName),
                      ),
                    )
                    .toList();
              }(),
              onChanged: (selectedSiteId == null || widget.initialAttendance != null)
                  ? null
                  : (value) {
                      setState(() {
                        selectedLabourId = value;
                      });
                    },
              disabledHint: widget.initialAttendance != null
                  ? const Text('Labour (locked)')
                  : const Text('Select a site first'),
              validator: (value) => value == null ? 'Select a labour' : null,
            ),
            const SizedBox(height: 12),

            // Status dropdown
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'Present', child: Text('Present')),
                DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                DropdownMenuItem(value: 'Half Day', child: Text('Half Day')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedStatus = value;
                  });
                  widget.onChanged?.call();
                }
              },
            ),
            const SizedBox(height: 12),

            // Hours worked field
            TextFormField(
              initialValue: hoursWorkedText,
              decoration: const InputDecoration(
                labelText: 'Hours Worked',
                helperText: 'Between 0 and 24 hours',
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Hours worked is required';
                }
                final hours = double.tryParse(value);
                if (hours == null) {
                  return 'Enter a valid number';
                }
                if (hours < 0 || hours > 24) {
                  return 'Hours must be between 0 and 24';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  hoursWorkedText = value;
                  hoursWorked = double.tryParse(value) ?? 8.0;
                });
                widget.onChanged?.call();
              },
            ),
            const SizedBox(height: 12),

            // Date picker button
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(
                    const Duration(days: 365),
                  ),
                  lastDate: DateTime.now().add(
                    const Duration(days: 365),
                  ),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    widget.onChanged?.call();
                  });
                }
              },
              child: Text(
                'Date: ${selectedDate.toLocal().toShortDateString()}',
              ),
            ),
            const SizedBox(height: 20),

            if (widget.inlineError != null) ...[
              Text(
                widget.inlineError!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],

            // Submit button
            FilledButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              child: widget.isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Saving...'),
                      ],
                    )
                  : Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!widget.formKey.currentState!.validate()) {
      return;
    }

    final selectedSite =
        widget.sites.firstWhere((site) => site.id == selectedSiteId);
    final selectedLabour =
        widget.labour.firstWhere((labour) => labour.id == selectedLabourId);
    widget.onChanged?.call();
    widget.onSubmit(
      selectedSiteId!,
      selectedSite.name,
      selectedLabourId!,
      selectedLabour.fullName,
      selectedDate,
      selectedStatus,
      hoursWorked,
    );
  }
}

extension on DateTime {
  String toShortDateString() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year.toString()}';
  }
}
