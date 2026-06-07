import 'package:flutter/material.dart';
import 'package:civilhelp/features/labour/data/models/labour_model.dart';
import 'package:civilhelp/features/sites/models/site_model.dart';

class BulkAttendanceForm extends StatefulWidget {
  final List<SiteModel> sites;
  final List<LabourModel> labour;
  final bool isLoading;
  final String? error;
  final void Function(
    String siteId,
    String siteName,
    DateTime date,
    List<({String labourId, String labourName, String status, double hoursWorked, double musterQuantity})> records,
  ) onSubmit;
  final VoidCallback? onCancel;

  const BulkAttendanceForm({
    super.key,
    required this.sites,
    required this.labour,
    this.isLoading = false,
    this.error,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<BulkAttendanceForm> createState() => _BulkAttendanceFormState();
}

class _BulkAttendanceFormState extends State<BulkAttendanceForm> {
  String? _selectedSiteId;
  DateTime _selectedDate = DateTime.now();
  
  final Map<String, bool> _isSelected = {};
  final Map<String, String> _statuses = {};
  final Map<String, double> _musters = {};
  final Map<String, TextEditingController> _hoursControllers = {};

  List<LabourModel> get _siteLabour {
    if (_selectedSiteId == null) return [];
    return widget.labour.where((l) => l.assignedSiteId == _selectedSiteId).toList();
  }

  bool get _allSelected {
    final labour = _siteLabour;
    if (labour.isEmpty) return false;
    return labour.every((l) => _isSelected[l.id] ?? false);
  }

  void _onSiteChanged(String? siteId) {
    setState(() {
      _selectedSiteId = siteId;
      _isSelected.clear();
      _statuses.clear();
      _musters.clear();
      
      for (final controller in _hoursControllers.values) {
        controller.dispose();
      }
      _hoursControllers.clear();

      for (final l in _siteLabour) {
        _isSelected[l.id] = true; // Default select all when site chosen
        _statuses[l.id] = 'Present';
        _musters[l.id] = 1.0;
        _hoursControllers[l.id] = TextEditingController(text: '8.0');
      }
    });
  }

  void _applyBulkStatus(String status) {
    setState(() {
      for (final l in _siteLabour) {
        if (_isSelected[l.id] == true) {
          _statuses[l.id] = status;
          if (status == 'Absent') {
            _hoursControllers[l.id]?.text = '0.0';
            _musters[l.id] = 0.0;
          } else if (status == 'Half Day') {
            _hoursControllers[l.id]?.text = '4.0';
            _musters[l.id] = 0.5;
          } else {
            _hoursControllers[l.id]?.text = '8.0';
            _musters[l.id] = 1.0;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _hoursControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final siteLabour = _siteLabour;

    // Calculate Summary Totals
    int presentCount = 0;
    int halfDayCount = 0;
    int absentCount = 0;
    double totalMuster = 0.0;

    if (_selectedSiteId != null) {
      for (final l in siteLabour) {
        if (_isSelected[l.id] == true) {
          final status = _statuses[l.id];
          if (status == 'Present') {
            presentCount++;
          } else if (status == 'Half Day') {
            halfDayCount++;
          } else if (status == 'Absent') {
            absentCount++;
          }
          
          totalMuster += _musters[l.id] ?? 0.0;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Section: Site and Date
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Select Site',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSiteId,
                    isExpanded: true,
                    items: widget.sites
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: widget.isLoading ? null : _onSiteChanged,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                onPressed: widget.isLoading ? null : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ],
          ),
        ),

        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),

        if (_selectedSiteId != null) ...[
          const Divider(),
          
          // Bulk Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Checkbox(
                  value: _allSelected,
                  onChanged: (val) {
                    setState(() {
                      for (final l in siteLabour) {
                        _isSelected[l.id] = val ?? false;
                      }
                    });
                  },
                ),
                const Text('Select All'),
                const Spacer(),
                DropdownButton<String>(
                  hint: const Text('Mark Selected As...'),
                  items: const [
                    DropdownMenuItem(value: 'Present', child: Text('Present')),
                    DropdownMenuItem(value: 'Half Day', child: Text('Half Day')),
                    DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                  ],
                  onChanged: (val) {
                    if (val != null) _applyBulkStatus(val);
                  },
                ),
              ],
            ),
          ),
          
          const Divider(),

          // Labour List
          Expanded(
            child: siteLabour.isEmpty
                ? const Center(child: Text('No labour assigned to this site.'))
                : ListView.builder(
                    itemCount: siteLabour.length,
                    itemBuilder: (context, index) {
                      final l = siteLabour[index];
                      final isSelected = _isSelected[l.id] ?? false;
                      final status = _statuses[l.id] ?? 'Present';
                      final muster = _musters[l.id] ?? 1.0;
                      final isAbsent = status == 'Absent';

                      return ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() => _isSelected[l.id] = val ?? false);
                          },
                        ),
                        title: Text(l.fullName),
                        subtitle: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              DropdownButton<String>(
                                value: status,
                                items: const [
                                  DropdownMenuItem(value: 'Present', child: Text('Present')),
                                  DropdownMenuItem(value: 'Half Day', child: Text('Half Day')),
                                  DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                                ],
                                onChanged: !isSelected
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          setState(() {
                                            _statuses[l.id] = val;
                                            if (val == 'Absent') {
                                              _hoursControllers[l.id]?.text = '0.0';
                                              _musters[l.id] = 0.0;
                                            } else if (val == 'Half Day') {
                                              _hoursControllers[l.id]?.text = '4.0';
                                              _musters[l.id] = 0.5;
                                            } else {
                                              _hoursControllers[l.id]?.text = '8.0';
                                              _musters[l.id] = 1.0;
                                            }
                                          });
                                        }
                                      },
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<double>(
                                value: muster,
                                items: const [
                                  DropdownMenuItem(value: 0.0, child: Text('0.0')),
                                  DropdownMenuItem(value: 0.5, child: Text('0.5')),
                                  DropdownMenuItem(value: 0.75, child: Text('0.75')),
                                  DropdownMenuItem(value: 1.0, child: Text('1.0')),
                                  DropdownMenuItem(value: 1.25, child: Text('1.25')),
                                  DropdownMenuItem(value: 1.5, child: Text('1.5')),
                                  DropdownMenuItem(value: 2.0, child: Text('2.0')),
                                ],
                                onChanged: !isSelected || isAbsent
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          setState(() {
                                            _musters[l.id] = val;
                                          });
                                        }
                                      },
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 70,
                                child: TextField(
                                  controller: _hoursControllers[l.id],
                                  decoration: const InputDecoration(
                                    labelText: 'Hrs',
                                    isDense: true,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  enabled: isSelected && !isAbsent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Summary Panel
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('P: $presentCount | HD: $halfDayCount | A: $absentCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Total Muster: $totalMuster', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Bottom Actions
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.isLoading ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: widget.isLoading || _selectedSiteId == null
                    ? null
                    : () {
                        final selectedRecords = <({String labourId, String labourName, String status, double hoursWorked, double musterQuantity})>[];
                        for (final l in siteLabour) {
                          if (_isSelected[l.id] == true) {
                            final hrsStr = _hoursControllers[l.id]?.text ?? '0';
                            final hrs = double.tryParse(hrsStr) ?? 0.0;
                            selectedRecords.add((
                              labourId: l.id,
                              labourName: l.fullName,
                              status: _statuses[l.id] ?? 'Present',
                              hoursWorked: hrs,
                              musterQuantity: _musters[l.id] ?? 0.0,
                            ));
                          }
                        }

                        if (selectedRecords.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Select at least one labour to mark attendance')),
                          );
                          return;
                        }

                        final site = widget.sites.firstWhere((s) => s.id == _selectedSiteId);
                        widget.onSubmit(site.id, site.name, _selectedDate, selectedRecords);
                      },
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Attendance'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
