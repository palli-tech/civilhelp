import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layouts/app_scaffold.dart';
import '../providers/site_provider.dart';
import '../widgets/site_form.dart';

class AddSiteScreen extends ConsumerStatefulWidget {
  const AddSiteScreen({super.key});

  @override
  ConsumerState<AddSiteScreen> createState() => _AddSiteScreenState();
}

class _AddSiteScreenState extends ConsumerState<AddSiteScreen> {
  late GlobalKey<SiteFormState> _formKey;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<_SiteFormState>();
  }

  Future<void> _handleSubmit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(
        createSiteProvider((
          formState.siteName,
          formState.location,
          formState.client,
          formState.startDate,
          formState.status,
        )).future,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site created successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating site: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Add Site'),
        elevation: 0,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SiteForm(
              key: _formKey,
              onSubmit: _isLoading ? () {} : _handleSubmit,
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 48,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
