import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';

class CultivationLogsScreen extends StatefulWidget {
  const CultivationLogsScreen({super.key});

  @override
  State<CultivationLogsScreen> createState() => _CultivationLogsScreenState();
}

class _CultivationLogsScreenState extends State<CultivationLogsScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final result = await ApiService.getCultivationLogs();
    if (!mounted) return;
    setState(() {
      _logs = result['success'] == true ? List<dynamic>.from(result['logs'] ?? []) : [];
      _error = result['success'] == true ? '' : (result['message'] ?? 'Failed to load logs.');
      _isLoading = false;
    });
  }

  Future<void> _openEditor({Map<String, dynamic>? log}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CultivationLogEditorScreen(existing: log),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _deleteLog(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete log?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    final result = await ApiService.deleteCultivationLog(id);
    if (!mounted) return;
    if (result['success'] == true) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to delete.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Cultivation Logs'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.deepLeafGreen,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Log'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error)))
              : _logs.isEmpty
                  ? const Center(child: Text('No logs yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final log = Map<String, dynamic>.from(_logs[index] as Map);
                        final id = int.tryParse(log['id']?.toString() ?? '');
                        final dateStr = (log['log_date'] ?? '').toString();
                        final stage = (log['growth_stage_name'] ?? '').toString();
                        final landReg = (log['land_registration_number'] ?? '').toString();
                        final disease = log['disease_detected'] == true;
                        final pest = log['pest_detected'] == true;

                        final subtitle = <String>[
                          if (landReg.isNotEmpty && landReg != 'null') 'Land: $landReg',
                          if (stage.isNotEmpty) 'Stage: $stage',
                          if (disease) 'Disease',
                          if (pest) 'Pest',
                        ].join(' • ');

                        return Material(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _openEditor(log: log),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    height: 44,
                                    width: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightMint,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.note_alt_outlined, color: AppTheme.deepLeafGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateStr.isEmpty
                                              ? 'Log'
                                              : DateFormat('yyyy-MM-dd').format(DateTime.parse(dateStr)),
                                          style: const TextStyle(
                                            color: AppTheme.darkGreen,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          subtitle.isEmpty ? 'Tap to view/edit' : subtitle,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 11,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (id != null)
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteLog(id),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class CultivationLogEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const CultivationLogEditorScreen({super.key, this.existing});

  @override
  State<CultivationLogEditorScreen> createState() => _CultivationLogEditorScreenState();
}

class _CultivationLogEditorScreenState extends State<CultivationLogEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoadingRefs = true;
  String _refsError = '';
  List<dynamic> _lands = [];
  List<dynamic> _stages = [];

  int? _landId;
  int? _stageId;
  DateTime _logDate = DateTime.now();

  final _leafController = TextEditingController();
  final _diseaseDamageController = TextEditingController();
  final _pestDamageController = TextEditingController();
  final _pesticideNameController = TextEditingController();
  final _pesticideTypeController = TextEditingController();
  final _notesController = TextEditingController();

  bool _diseaseDetected = false;
  bool _pestDetected = false;
  bool _pesticideApplied = false;

  bool _isSaving = false;
  String _error = '';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _hydrateExisting();
    _loadRefs();
  }

  void _hydrateExisting() {
    final e = widget.existing;
    if (e == null) return;
    _landId = int.tryParse(e['land_id']?.toString() ?? '');
    _stageId = int.tryParse(e['growth_stage_id']?.toString() ?? '');
    final dateStr = (e['log_date'] ?? '').toString();
    if (dateStr.isNotEmpty) _logDate = DateTime.parse(dateStr);
    _leafController.text = (e['leaf_appearance'] ?? '').toString();
    _diseaseDetected = e['disease_detected'] == true;
    _pestDetected = e['pest_detected'] == true;
    _diseaseDamageController.text = (e['disease_name_and_damage'] ?? '').toString();
    _pestDamageController.text = (e['pest_name_and_damage'] ?? '').toString();
    _pesticideApplied = e['pesticide_applied'] == true;
    _pesticideNameController.text = (e['pesticide_name'] ?? '').toString();
    _pesticideTypeController.text = (e['pesticide_type'] ?? '').toString();
    _notesController.text = (e['notes'] ?? '').toString();
  }

  @override
  void dispose() {
    _leafController.dispose();
    _diseaseDamageController.dispose();
    _pestDamageController.dispose();
    _pesticideNameController.dispose();
    _pesticideTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRefs() async {
    setState(() {
      _isLoadingRefs = true;
      _refsError = '';
    });
    final landsResult = await ApiService.getFarmerLands();
    final stagesResult = await ApiService.getCropGrowthStages();
    if (!mounted) return;

    setState(() {
      _lands = landsResult['success'] == true ? List<dynamic>.from(landsResult['lands'] ?? []) : [];
      _stages = stagesResult['success'] == true ? List<dynamic>.from(stagesResult['stages'] ?? []) : [];
      if (landsResult['success'] != true) _refsError = landsResult['message'] ?? 'Failed to load lands.';
      if (stagesResult['success'] != true) _refsError = stagesResult['message'] ?? 'Failed to load growth stages.';
      _isLoadingRefs = false;

      _landId ??= _lands.isNotEmpty ? int.tryParse((_lands.first as Map)['id'].toString()) : null;
      _stageId ??= _stages.isNotEmpty ? int.tryParse((_stages.first as Map)['id'].toString()) : null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _logDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _logDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_landId == null || _stageId == null) return;

    setState(() {
      _isSaving = true;
      _error = '';
    });

    final payload = <String, dynamic>{
      'land_id': _landId,
      'growth_stage_id': _stageId,
      'log_date': DateFormat('yyyy-MM-dd').format(_logDate),
      'leaf_appearance': _leafController.text.trim().isEmpty ? null : _leafController.text.trim(),
      'disease_detected': _diseaseDetected,
      'pest_detected': _pestDetected,
      'disease_name_and_damage':
          _diseaseDamageController.text.trim().isEmpty ? null : _diseaseDamageController.text.trim(),
      'pest_name_and_damage':
          _pestDamageController.text.trim().isEmpty ? null : _pestDamageController.text.trim(),
      'pesticide_applied': _pesticideApplied,
      'pesticide_name':
          _pesticideNameController.text.trim().isEmpty ? null : _pesticideNameController.text.trim(),
      'pesticide_type':
          _pesticideTypeController.text.trim().isEmpty ? null : _pesticideTypeController.text.trim(),
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    final result = _isEdit
        ? await ApiService.updateCultivationLog(
            int.parse(widget.existing!['id'].toString()),
            payload,
          )
        : await ApiService.addCultivationLog(payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = result['message'] ?? 'Failed to save.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(title: Text(_isEdit ? 'Edit Log' : 'Add Log')),
      body: _isLoadingRefs
          ? const Center(child: CircularProgressIndicator())
          : _refsError.isNotEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_refsError)))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error, style: const TextStyle(color: Colors.red)),
                        ),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: AppTheme.deepLeafGreen),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Date: ${DateFormat('yyyy-MM-dd').format(_logDate)}',
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                TextButton(onPressed: _pickDate, child: const Text('Change')),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              value: _landId,
                              items: _lands.map((e) {
                                final m = Map<String, dynamic>.from(e as Map);
                                final id = int.parse(m['id'].toString());
                                final reg = (m['registration_number'] ?? '').toString();
                                final label = reg.isEmpty || reg == 'null'
                                    ? '${m['size']} Perches'
                                    : 'Reg: $reg';
                                return DropdownMenuItem(value: id, child: Text(label));
                              }).toList(),
                              onChanged: (v) => setState(() => _landId = v),
                              decoration: const InputDecoration(
                                labelText: 'Land',
                                prefixIcon: Icon(Icons.terrain_rounded),
                              ),
                              validator: (v) => v == null ? 'Land is required.' : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              value: _stageId,
                              items: _stages.map((e) {
                                final m = Map<String, dynamic>.from(e as Map);
                                final id = int.parse(m['id'].toString());
                                final name = (m['name'] ?? '-').toString();
                                return DropdownMenuItem(value: id, child: Text(name));
                              }).toList(),
                              onChanged: (v) => setState(() => _stageId = v),
                              decoration: const InputDecoration(
                                labelText: 'Growth Stage',
                                prefixIcon: Icon(Icons.timeline_rounded),
                              ),
                              validator: (v) => v == null ? 'Growth stage is required.' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _leafController,
                              decoration: const InputDecoration(
                                labelText: 'Leaf appearance (optional)',
                                prefixIcon: Icon(Icons.eco_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile.adaptive(
                              value: _diseaseDetected,
                              onChanged: (v) => setState(() => _diseaseDetected = v),
                              title: const Text('Disease detected'),
                              activeColor: AppTheme.deepLeafGreen,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (_diseaseDetected)
                              TextFormField(
                                controller: _diseaseDamageController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Disease name & damage (optional)',
                                  prefixIcon: Icon(Icons.warning_amber_rounded),
                                ),
                              ),
                            const SizedBox(height: 8),
                            SwitchListTile.adaptive(
                              value: _pestDetected,
                              onChanged: (v) => setState(() => _pestDetected = v),
                              title: const Text('Pest detected'),
                              activeColor: AppTheme.deepLeafGreen,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (_pestDetected)
                              TextFormField(
                                controller: _pestDamageController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Pest name & damage (optional)',
                                  prefixIcon: Icon(Icons.bug_report_outlined),
                                ),
                              ),
                            const SizedBox(height: 8),
                            SwitchListTile.adaptive(
                              value: _pesticideApplied,
                              onChanged: (v) => setState(() => _pesticideApplied = v),
                              title: const Text('Pesticide applied'),
                              activeColor: AppTheme.deepLeafGreen,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (_pesticideApplied) ...[
                              TextFormField(
                                controller: _pesticideNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Pesticide name (optional)',
                                  prefixIcon: Icon(Icons.science_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _pesticideTypeController,
                                decoration: const InputDecoration(
                                  labelText: 'Pesticide type (optional)',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Notes (optional)',
                                prefixIcon: Icon(Icons.notes_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_isSaving ? 'Saving...' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

