import 'package:flutter/material.dart';
import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';

class ThemeShowcaseScreen extends StatefulWidget {
  const ThemeShowcaseScreen({super.key});

  @override
  State<ThemeShowcaseScreen> createState() => _ThemeShowcaseScreenState();
}

class _ThemeShowcaseScreenState extends State<ThemeShowcaseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _switchVal = true;
  double _sliderVal = 0.6;
  String? _dropdownVal = 'Option 1';

  @override
  Widget build(BuildContext context) {
    // Convenient theme context extension getters are imported automatically via app/theme.dart
    final colors = context.colors;
    final text = context.text;
    final customColors = context.customColors;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Theme Showcase & Debug'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Typography Scale', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.listGap),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Display Large', style: text.displayLarge),
                    const Divider(),
                    Text('Headline Medium', style: text.headlineMedium),
                    const Divider(),
                    Text('Title Large (NotoSans Bold)', style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('Body Medium', style: text.bodyMedium),
                    const Divider(),
                    Text('Label Small', style: text.labelSmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            Text('Semantic Domain Colors (ThemeExtension)', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.listGap),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildColorBox('Attendance', customColors.attendance, colors.onPrimary),
                _buildColorBox('Payroll', customColors.payroll, colors.onPrimary),
                _buildColorBox('Advance', customColors.advance, colors.onPrimary),
                _buildColorBox('Worker', customColors.worker, colors.onPrimary),
                _buildColorBox('Site', customColors.site, colors.onPrimary),
                _buildColorBox('Success', customColors.success, customColors.onSuccess),
                _buildColorBox('Warning', customColors.warning, customColors.onWarning),
                _buildColorBox('Error', customColors.error, customColors.onError),
                _buildColorBox('Info', customColors.info, customColors.onInfo),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            Text('Material 3 Surfaces', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.listGap),
            Column(
              children: [
                _buildSurfaceContainer('Surface (Default)', colors.surface, colors.onSurface),
                const SizedBox(height: AppSpacing.sm),
                _buildSurfaceContainer('Surface Variant', colors.surfaceVariant, colors.onSurfaceVariant),
                const SizedBox(height: AppSpacing.sm),
                _buildSurfaceContainer(
                  'Surface Container',
                  context.isDarkMode ? ColorTokens.darkSurfaceContainer : ColorTokens.lightSurfaceContainer,
                  colors.onSurface,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSurfaceContainer(
                  'Surface Container High',
                  context.isDarkMode ? ColorTokens.darkSurfaceContainerHigh : ColorTokens.lightSurfaceContainerHigh,
                  colors.onSurface,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            Text('Buttons & Interactive Components', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.listGap),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Elevated Button'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Outlined Button'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Text Button'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.star),
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            Text('Chips & Badges', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.listGap),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                const Chip(label: Text('Default Chip')),
                InputChip(
                  label: const Text('Input Chip'),
                  selected: _switchVal,
                  onSelected: (val) => setState(() => _switchVal = val),
                ),
                ChoiceChip(
                  label: const Text('Choice Selected'),
                  selected: true,
                  onSelected: (_) {},
                ),
                ActionChip(
                  label: const Text('Open Dialog'),
                  onPressed: _showTestDialog,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            Text('Form Controls', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.listGap),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Sample Text Field',
                          hintText: 'Enter text here',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        value: _dropdownVal,
                        decoration: const InputDecoration(
                          labelText: 'Select Option',
                        ),
                        items: ['Option 1', 'Option 2', 'Option 3']
                            .map((label) => DropdownMenuItem(
                                  value: label,
                                  child: Text(label),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _dropdownVal = val),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SwitchListTile(
                        title: const Text('Toggle switch setting'),
                        value: _switchVal,
                        onChanged: (val) => setState(() => _switchVal = val),
                      ),
                      Slider(
                        value: _sliderVal,
                        onChanged: (val) => setState(() => _sliderVal = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            Text('Table Representation', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.listGap),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Table(
                  border: TableBorder.all(color: colors.outline.withValues(alpha: 0.3), width: 1, borderRadius: BorderRadius.circular(4)),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: colors.surfaceVariant),
                      children: const [
                        Padding(padding: EdgeInsets.all(8.0), child: Text('Site ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('Site Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('Workers', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8.0), child: Text('S001')),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('Metro Extension Phase 4')),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('42')),
                      ],
                    ),
                    const TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8.0), child: Text('S002')),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('City Mall Revamp')),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('18')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            Text('Metric Cards & Status UI', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.listGap),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard('Success State', '₹4,52,000', customColors.success, customColors.successContainer),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricCard('Warning State', '3 Pending', customColors.warning, customColors.warningContainer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorBox(String label, Color bg, Color text) {
    return Container(
      width: 100,
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSurfaceContainer(String label, Color bg, Color fg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.outline.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, Color containerColor) {
    return Card(
      color: containerColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showTestDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Theme Check'),
        content: const Text('This is a test dialog that checks typography and layout spacing in the modal overlay.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
