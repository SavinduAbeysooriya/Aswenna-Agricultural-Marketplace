import 'package:flutter/material.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/theme/app_theme.dart';

class CropPickerScreen extends StatefulWidget {
  final Set<int> initialSelectedIds;
  final String title;

  const CropPickerScreen({
    super.key,
    required this.initialSelectedIds,
    this.title = 'Select Crops',
  });

  @override
  State<CropPickerScreen> createState() => _CropPickerScreenState();
}

class _CropPickerScreenState extends State<CropPickerScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String _error = '';
  List<Map<String, dynamic>> _crops = [];
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<int>.from(widget.initialSelectedIds);
    _loadCrops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCrops() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final result = await ApiService.getApprovedCrops();
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _crops = List<Map<String, dynamic>>.from(
          (result['crops'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
        );
      } else {
        _error = result['message'] ?? 'Failed to load crops.';
        _crops = [];
      }
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _crops;
    return _crops.where((c) {
      final name = (c['cropname'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selectedIds),
            child: const Text(
              'Done',
              style: TextStyle(
                color: AppTheme.deepLeafGreen,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search crops...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.deepLeafGreen),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.softGray,
              ),
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _error,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? const Center(child: Text('No crops found.'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final crop = _filtered[index];
                              final id = int.tryParse(crop['id']?.toString() ?? '');
                              if (id == null) return const SizedBox.shrink();
                              final name = (crop['cropname'] ?? '-').toString();
                              final imageUrl = ApiService.fileUrl(crop['image_path']);
                              final selected = _selectedIds.contains(id);

                              return Material(
                                color: AppTheme.pureWhite,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    setState(() {
                                      if (selected) {
                                        _selectedIds.remove(id);
                                      } else {
                                        _selectedIds.add(id);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            height: 44,
                                            width: 44,
                                            color: const Color(0xFFF1F5F9),
                                            child: imageUrl == null
                                                ? const Icon(Icons.local_florist_outlined, color: Color(0xFF64748B))
                                                : Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(
                                                      Icons.local_florist_outlined,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              color: AppTheme.darkGreen,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        Checkbox(
                                          value: selected,
                                          activeColor: AppTheme.deepLeafGreen,
                                          onChanged: (v) {
                                            setState(() {
                                              if (v == true) {
                                                _selectedIds.add(id);
                                              } else {
                                                _selectedIds.remove(id);
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

