import 'package:flutter/material.dart';

class SiteForm extends StatefulWidget {
  final String? siteName;
  final String? location;
  final String? client;
  final DateTime? startDate;
  final String? status;
  final VoidCallback onSubmit;

  const SiteForm({
    super.key,
    this.siteName,
    this.location,
    this.client,
    this.startDate,
    this.status,
    required this.onSubmit,
  });

  @override
  State<SiteForm> createState() => _SiteFormState();
}

class _SiteFormState extends State<SiteForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _clientController;
  late DateTime _selectedDate;
  late String _selectedStatus;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.siteName ?? '');
    _locationController = TextEditingController(text: widget.location ?? '');
    _clientController = TextEditingController(text: widget.client ?? '');
    _selectedDate = widget.startDate ?? DateTime.now();
    _selectedStatus = widget.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Site Name',
              hintText: 'Enter site name',
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Site name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location',
              hintText: 'Enter site location',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Location is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _clientController,
            decoration: InputDecoration(
              labelText: 'Client',
              hintText: 'Enter client name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Client name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Start Date',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status',
              prefixIcon: const Icon(Icons.info),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
              DropdownMenuItem(value: 'paused', child: Text('Paused')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStatus = value;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  widget.onSubmit();
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Save Site',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get siteName => _nameController.text;
  String get location => _locationController.text;
  String get client => _clientController.text;
  DateTime get startDate => _selectedDate;
  String get status => _selectedStatus;
}
