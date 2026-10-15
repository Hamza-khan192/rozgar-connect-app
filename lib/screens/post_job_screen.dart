import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';

/// Posts a new job. If [laborId] is given the laborer is preselected,
/// otherwise the customer picks one from a dropdown.
class PostJobScreen extends StatefulWidget {
  final int? laborId;

  const PostJobScreen({super.key, this.laborId});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  int? _selectedLaborId;
  String? _selectedSkillName;
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selectedLaborId = widget.laborId;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final data = context.read<DataProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final laborId = _selectedLaborId;
    final description = _descCtrl.text.trim();
    final budget = double.tryParse(_budgetCtrl.text.trim());
    if (laborId == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Please select a laborer')));
      return;
    }
    if (description.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Please describe the work')));
      return;
    }
    if (budget == null || budget <= 0) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Please enter a valid budget')));
      return;
    }
    setState(() => _busy = true);
    try {
      await data.createJob(
          laborId: laborId, description: description, budget: budget);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Job posted! The laborer has been notified.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Post a job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _selectedLaborId,
              decoration: const InputDecoration(
                labelText: 'Laborer',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in data.laborers)
                  DropdownMenuItem(
                    value: p.laborId,
                    child: Text(data.laborerName(p)),
                  ),
              ],
              onChanged: (v) => setState(() => _selectedLaborId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedSkillName,
              decoration: const InputDecoration(
                labelText: 'Related skill (informational)',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final s in data.skills)
                  DropdownMenuItem(
                    value: s.skillName,
                    child: Text(s.skillName),
                  ),
              ],
              onChanged: (v) => setState(() => _selectedSkillName = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Work description',
                hintText: 'e.g. Boundary wall construction, 100 ft',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget (Rs)',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post Job'),
            ),
          ],
        ),
      ),
    );
  }
}
