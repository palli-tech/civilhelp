import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layouts/app_scaffold.dart';
import '../providers/site_provider.dart';
import '../widgets/site_form.dart';

class EditSiteScreen extends ConsumerStatefulWidget {
  final String siteId;

  const EditSiteScreen({
    super.key,
    required this.siteId,
  });

  @override
  ConsumerState<EditSiteScreen> createState() => _EditSiteScreenState();
}

class _EditSiteScreenState extends ConsumerState<EditSiteScreen> {
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
        updateSiteProvider((
          widget.siteId,
          formState.siteName,
          formState.location,
          formState.client,
          formState.startDate,
          formState.status,
        )).future,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating site: ${e.toString()}'),
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
    final siteAsync = ref.watch(siteByIdProvider(widget.siteId));

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Edit Site'),
        elevation: 0,
      ),
      child: siteAsync.when(
        data: (site) {
          if (site == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  const Text('Site not found'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SiteForm(
                  key: _formKey,
                  siteName: site.name,
                  location: site.location,
                  client: site.client,
                  startDate: site.startDate,
                  status: site.status,
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
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading site: ${error.toString()}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
