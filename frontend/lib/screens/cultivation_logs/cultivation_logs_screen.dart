import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
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

  // Lands & AI prediction state
  bool _isLoadingLands = false;
  List<dynamic> _lands = [];
  int? _selectedLandId; // null means 'All Lands'
  bool _isLoadingAi = false;
  String _aiPrediction = '';
  String _aiError = '';

  // Big Data Handling & Pagination State
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All'; // 'All', 'Healthy', 'Disease', 'Pest', 'Pesticide'
  bool _sortByNewest = true;
  int _visibleCount = 15;
  final int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final filteredCount = _getFilteredLogs().length;
      if (_visibleCount < filteredCount) {
        setState(() {
          _visibleCount = (_visibleCount + _pageSize).clamp(0, filteredCount);
        });
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _isLoadingLands = true;
      _error = '';
    });
    final logsResult = await ApiService.getCultivationLogs();
    final landsResult = await ApiService.getFarmerLands();
    if (!mounted) return;
    setState(() {
      _logs = logsResult['success'] == true ? List<dynamic>.from(logsResult['logs'] ?? []) : [];
      _error = logsResult['success'] == true ? '' : (logsResult['message'] ?? 'Failed to load logs.');
      _isLoading = false;
      _visibleCount = _pageSize; // Reset visible count on reload
      
      _lands = landsResult['success'] == true ? List<dynamic>.from(landsResult['lands'] ?? []) : [];
      _isLoadingLands = false;
    });

    if (_selectedLandId != null) {
      _fetchAiPrediction();
    }
  }

  Future<void> _fetchAiPrediction() async {
    if (_selectedLandId == null) {
      setState(() {
        _aiPrediction = '';
        _aiError = '';
      });
      return;
    }
    
    setState(() {
      _isLoadingAi = true;
      _aiPrediction = '';
      _aiError = '';
    });

    final landLogs = _logs.where((l) => int.tryParse(l['land_id']?.toString() ?? '') == _selectedLandId).toList();
    if (landLogs.isEmpty) {
      setState(() {
        _aiPrediction = 'No logs available for this land yet. Please add a cultivation log to generate predictions.';
        _isLoadingAi = false;
      });
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln("Land Logs History:");
    for (final log in landLogs) {
      buffer.writeln("- Date: ${log['log_date']}");
      buffer.writeln("  Stage: ${log['growth_stage_name']}");
      if (log['leaf_appearance'] != null) buffer.writeln("  Leaf: ${log['leaf_appearance']}");
      if (log['disease_detected'] == true) {
        buffer.writeln("  Disease: ${log['disease_name_and_damage']}");
      }
      if (log['pest_detected'] == true) {
        buffer.writeln("  Pest: ${log['pest_name_and_damage']}");
      }
      if (log['pesticide_applied'] == true) {
        buffer.writeln("  Pesticide: ${log['pesticide_name']} (${log['pesticide_type']})");
      }
      if (log['notes'] != null) buffer.writeln("  Notes: ${log['notes']}");
    }

    final prompt = """
You are an expert Agricultural AI assistant specializing in Sri Lankan paddy and crop cultivation. 
Analyze the following logsheet history for a specific piece of land and provide:
1. **Predicted Growth & Harvest**: Estimated growth progression, timeline for next stages, and harvest prediction window.
2. **Current Health Status & Disease/Pest Analysis**: Assessment of current issues, threats, or treatments applied.
3. **Recommended Immediate Action & Treatment Plan**: Specific recommendations (organic or standard fertilizers/pesticides) based on issues logged.

Logs Data:
${buffer.toString()}

Keep the response practical, direct, and structured with bullet points. Limit to 3 short paragraphs max.
""";

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer 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',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        setState(() {
          _aiPrediction = content ?? 'No prediction generated.';
          _isLoadingAi = false;
        });
      } else {
        setState(() {
          _aiError = 'Failed to load AI advice. Status: ${response.statusCode}';
          _isLoadingAi = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = 'Network error: Could not contact advisor.';
        _isLoadingAi = false;
      });
    }
  }

  List<dynamic> _getFilteredLogs() {
    var list = List<dynamic>.from(_logs);
    
    // Land selector Filter
    if (_selectedLandId != null) {
      list = list.where((log) => int.tryParse(log['land_id']?.toString() ?? '') == _selectedLandId).toList();
    }
    
    // 1. Search Query Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((log) {
        final notes = (log['notes'] ?? '').toString().toLowerCase();
        final stage = (log['growth_stage_name'] ?? '').toString().toLowerCase();
        final landReg = (log['land_registration_number'] ?? '').toString().toLowerCase();
        final pesticide = (log['pesticide_name'] ?? '').toString().toLowerCase();
        final dateStr = (log['log_date'] ?? '').toString().toLowerCase();
        final disease = (log['disease_name_and_damage'] ?? '').toString().toLowerCase();
        final pest = (log['pest_name_and_damage'] ?? '').toString().toLowerCase();
        return notes.contains(query) ||
            stage.contains(query) ||
            landReg.contains(query) ||
            pesticide.contains(query) ||
            dateStr.contains(query) ||
            disease.contains(query) ||
            pest.contains(query);
      }).toList();
    }

    // 2. Chip Category Filter
    if (_activeFilter == 'Healthy') {
      list = list.where((log) => log['disease_detected'] != true && log['pest_detected'] != true).toList();
    } else if (_activeFilter == 'Disease') {
      list = list.where((log) => log['disease_detected'] == true).toList();
    } else if (_activeFilter == 'Pest') {
      list = list.where((log) => log['pest_detected'] == true).toList();
    } else if (_activeFilter == 'Pesticide') {
      list = list.where((log) => log['pesticide_applied'] == true).toList();
    }

    // 3. Sorting
    list.sort((a, b) {
      final dateA = DateTime.tryParse((a['log_date'] ?? '').toString()) ?? DateTime(2000);
      final dateB = DateTime.tryParse((b['log_date'] ?? '').toString()) ?? DateTime(2000);
      final comp = dateA.compareTo(dateB);
      return _sortByNewest ? -comp : comp;
    });

    return list;
  }

  void _updateFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _visibleCount = _pageSize;
    });
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
      _visibleCount = _pageSize;
    });
  }

  void _toggleSort() {
    setState(() {
      _sortByNewest = !_sortByNewest;
      _visibleCount = _pageSize;
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

  Future<void> _viewDetails(Map<String, dynamic> log) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => CultivationLogDetailsScreen(log: log),
      ),
    );
    if (result == 'deleted' || result == true) {
      _load();
    }
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

  Widget _buildStatusIndicator(bool disease, bool pest) {
    Color bgColor;
    Color iconColor;
    IconData iconData;
    
    if (disease || pest) {
      bgColor = const Color(0xFFFEF2F2); // soft red
      iconColor = const Color(0xFFEF4444);
      iconData = disease ? Icons.warning_amber_rounded : Icons.bug_report_outlined;
    } else {
      bgColor = AppTheme.lightMint;
      iconColor = AppTheme.deepLeafGreen;
      iconData = Icons.eco_outlined;
    }
    
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppTheme.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Search & Sort row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _updateSearch,
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _updateSearch('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: AppTheme.softGray,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.freshGreen, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.softGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: _sortByNewest ? 'Newest first' : 'Oldest first',
                  onPressed: _toggleSort,
                  icon: Icon(
                    _sortByNewest ? Icons.south_rounded : Icons.north_rounded,
                    color: AppTheme.deepLeafGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter chips list
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'All Logs'),
                _buildFilterChip('Healthy', 'Healthy'),
                _buildFilterChip('Disease', 'Diseases'),
                _buildFilterChip('Pest', 'Pests'),
                _buildFilterChip('Pesticide', 'Pesticides'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _activeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.pureWhite : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        checkmarkColor: AppTheme.pureWhite,
        backgroundColor: AppTheme.softGray,
        selectedColor: AppTheme.deepLeafGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.deepLeafGreen : Colors.transparent,
          ),
        ),
        onSelected: (selected) {
          if (selected) {
            _updateFilter(value);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();
    
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Cultivation Logs'),
        actions: [
          IconButton(
            tooltip: 'Add Log',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.deepLeafGreen),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildLandSelector(),
          _buildAiPredictionsCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error)))
                    : filteredLogs.isEmpty
                        ? const Center(child: Text('No logs found matching criteria.'))
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            itemCount: _visibleCount < filteredLogs.length ? _visibleCount + 1 : filteredLogs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              if (index == _visibleCount && index < filteredLogs.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.deepLeafGreen),
                                    ),
                                  ),
                                );
                              }

                              final log = Map<String, dynamic>.from(filteredLogs[index] as Map);
                              final id = int.tryParse(log['id']?.toString() ?? '');
                              final dateStr = (log['log_date'] ?? '').toString();
                              final stage = (log['growth_stage_name'] ?? '').toString();
                              final landReg = (log['land_registration_number'] ?? '').toString();
                              final disease = log['disease_detected'] == true;
                              final pest = log['pest_detected'] == true;
                              final pesticideApplied = log['pesticide_applied'] == true;

                              String diseaseText = 'Disease';
                              final rawDisease = (log['disease_name_and_damage'] ?? '').toString();
                              if (rawDisease.isNotEmpty) {
                                try {
                                  final decoded = jsonDecode(rawDisease) as Map<String, dynamic>;
                                  final name = decoded['name'] ?? '';
                                  if (name.isNotEmpty) {
                                    diseaseText = 'Disease: $name';
                                  }
                                } catch (_) {
                                  diseaseText = 'Disease: $rawDisease';
                                }
                              }

                              String pestText = 'Pest';
                              final rawPest = (log['pest_name_and_damage'] ?? '').toString();
                              if (rawPest.isNotEmpty) {
                                try {
                                  final decoded = jsonDecode(rawPest) as Map<String, dynamic>;
                                  final name = decoded['name'] ?? '';
                                  if (name.isNotEmpty) {
                                    pestText = 'Pest: $name';
                                  }
                                } catch (_) {
                                  pestText = 'Pest: $rawPest';
                                }
                              }

                              final subtitle = <String>[
                                if (landReg.isNotEmpty && landReg != 'null') 'Land: $landReg',
                                if (stage.isNotEmpty) 'Stage: $stage',
                                if (disease) diseaseText,
                                if (pest) pestText,
                              ].join(' • ');

                              return Card(
                                elevation: 0,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: AppTheme.deepLeafGreen.withOpacity(0.08),
                                    width: 1.5,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _viewDetails(log),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        _buildStatusIndicator(disease, pest),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    dateStr.isEmpty
                                                        ? 'Log'
                                                        : DateFormat('MMMM dd, yyyy').format(DateTime.parse(dateStr)),
                                                    style: const TextStyle(
                                                      color: AppTheme.darkGreen,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  if (pesticideApplied)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.lightMint,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.science_outlined, size: 10, color: AppTheme.deepLeafGreen),
                                                          SizedBox(width: 2),
                                                          Text(
                                                            'Pesticide',
                                                            style: TextStyle(
                                                              color: AppTheme.deepLeafGreen,
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                subtitle.isEmpty ? 'Tap to view details' : subtitle,
                                                style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 12,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                                          onSelected: (value) {
                                            if (value == 'view') {
                                              _viewDetails(log);
                                            } else if (value == 'edit') {
                                              _openEditor(log: log);
                                            } else if (value == 'delete') {
                                              if (id != null) _deleteLog(id);
                                            }
                                          },
                                          itemBuilder: (BuildContext context) => [
                                            const PopupMenuItem(
                                              value: 'view',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.visibility_outlined, size: 20, color: Colors.blue),
                                                  SizedBox(width: 10),
                                                  Text('View Details'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 20, color: AppTheme.deepLeafGreen),
                                                  SizedBox(width: 10),
                                                  Text('Edit Log'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                                  SizedBox(width: 10),
                                                  Text('Delete Log'),
                                                ],
                                              ),
                                            ),
                                          ],
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

  Widget _buildLandSelector() {
    if (_isLoadingLands) {
      return const SizedBox(
        height: 90,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _lands.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll
              ? _selectedLandId == null
              : _selectedLandId == int.tryParse(_lands[index - 1]['id']?.toString() ?? '');
          
          final String label = isAll
              ? 'All Lands'
              : (_lands[index - 1]['registration_number']?.toString().isNotEmpty == true &&
                      _lands[index - 1]['registration_number']?.toString() != 'null')
                  ? 'Reg: ${_lands[index - 1]['registration_number']}'
                  : 'Size: ${_lands[index - 1]['size']} Perches';
                  
          return GestureDetector(
             onTap: () {
               setState(() {
                 _selectedLandId = isAll ? null : int.tryParse(_lands[index - 1]['id']?.toString() ?? '');
               });
               _fetchAiPrediction();
             },
             child: Container(
               margin: const EdgeInsets.only(right: 12),
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               decoration: BoxDecoration(
                 color: isSelected ? AppTheme.deepLeafGreen : Colors.white,
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(
                   color: isSelected ? AppTheme.deepLeafGreen : Colors.grey[200] ?? Colors.grey,
                   width: 1.5,
                 ),
                 boxShadow: [
                   BoxShadow(
                     color: isSelected ? AppTheme.deepLeafGreen.withOpacity(0.15) : Colors.black.withOpacity(0.02),
                     blurRadius: 10,
                     offset: const Offset(0, 4),
                   ),
                 ],
               ),
               child: Row(
                 children: [
                   Icon(
                     isAll ? Icons.grid_view_rounded : Icons.landscape_rounded,
                     color: isSelected ? Colors.white : AppTheme.deepLeafGreen,
                     size: 20,
                   ),
                   const SizedBox(width: 8),
                   Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         label,
                         style: TextStyle(
                           color: isSelected ? Colors.white : const Color(0xFF0F172A),
                           fontWeight: FontWeight.bold,
                           fontSize: 13,
                         ),
                       ),
                       if (!isAll)
                         Text(
                           'Land Logsheet',
                           style: TextStyle(
                             color: isSelected ? Colors.white70 : Colors.grey,
                             fontSize: 10,
                           ),
                         ),
                     ],
                   ),
                 ],
               ),
             ),
           );
        },
      ),
    );
  }

  Widget _buildAiPredictionsCard() {
    if (_selectedLandId == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.deepLeafGreen.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AppTheme.deepLeafGreen.withOpacity(0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy_rounded, color: AppTheme.deepLeafGreen, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Grok AI Land Advisor',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkGreen,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoadingAi)
                    IconButton(
                      icon: const Icon(Icons.psychology_outlined, size: 18, color: AppTheme.deepLeafGreen),
                      onPressed: _fetchAiPrediction,
                      tooltip: 'Re-analyze Logs',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: _isLoadingAi
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            CircularProgressIndicator(strokeWidth: 2, color: AppTheme.deepLeafGreen),
                            const SizedBox(height: 12),
                            Text(
                              'Grok is analyzing logsheets...',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _aiError.isNotEmpty
                      ? Center(
                          child: Column(
                            children: [
                              Text(_aiError, style: const TextStyle(color: Colors.red, fontSize: 12)),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _fetchAiPrediction,
                                icon: const Icon(Icons.refresh_rounded, size: 14),
                                label: const Text('Try Again', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.deepLeafGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              _aiPrediction,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w600,
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

class CultivationLogDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> log;

  const CultivationLogDetailsScreen({super.key, required this.log});

  @override
  State<CultivationLogDetailsScreen> createState() => _CultivationLogDetailsScreenState();
}

class _CultivationLogDetailsScreenState extends State<CultivationLogDetailsScreen> {
  late Map<String, dynamic> _currentLog;
  bool _isDeleting = false;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _currentLog = widget.log;
  }

  Future<void> _editLog() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CultivationLogEditorScreen(existing: _currentLog),
      ),
    );
    if (saved == true) {
      setState(() => _isDeleting = true);
      final result = await ApiService.getCultivationLogs();
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        if (result['success'] == true) {
          final list = List<dynamic>.from(result['logs'] ?? []);
          final updatedLog = list.firstWhere(
            (item) => item['id']?.toString() == _currentLog['id']?.toString(),
            orElse: () => null,
          );
          if (updatedLog != null) {
            _currentLog = Map<String, dynamic>.from(updatedLog as Map);
            _hasChanged = true;
          }
        }
      });
    }
  }

  Future<void> _deleteLog() async {
    final id = int.tryParse(_currentLog['id']?.toString() ?? '');
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log?'),
        content: const Text(
          'This cultivation log will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _isDeleting = true);
    final result = await ApiService.deleteCultivationLog(id);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (result['success'] == true) {
      Navigator.of(context).pop('deleted');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to delete cultivation log.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = (_currentLog['log_date'] ?? '').toString();
    final formattedDate = dateStr.isNotEmpty
        ? DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.parse(dateStr))
        : 'N/A';

    final landReg = (_currentLog['land_registration_number'] ?? '').toString();
    final landSize = (_currentLog['land_size'] ?? '').toString();
    final stageName = (_currentLog['growth_stage_name'] ?? '').toString();
    final leafAppearance = (_currentLog['leaf_appearance'] ?? '').toString();
    
    final diseaseDetected = _currentLog['disease_detected'] == true;
    String diseaseName = '';
    String diseaseDamage = '';
    final rawDisease = (_currentLog['disease_name_and_damage'] ?? '').toString();
    if (rawDisease.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDisease) as Map<String, dynamic>;
        diseaseName = decoded['name'] ?? '';
        diseaseDamage = decoded['damage'] ?? '';
      } catch (_) {
        diseaseName = rawDisease;
      }
    }
    
    final pestDetected = _currentLog['pest_detected'] == true;
    String pestName = '';
    String pestDamage = '';
    final rawPest = (_currentLog['pest_name_and_damage'] ?? '').toString();
    if (rawPest.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPest) as Map<String, dynamic>;
        pestName = decoded['name'] ?? '';
        pestDamage = decoded['damage'] ?? '';
      } catch (_) {
        pestName = rawPest;
      }
    }
    
    final pesticideApplied = _currentLog['pesticide_applied'] == true;
    final pesticideName = (_currentLog['pesticide_name'] ?? '').toString();
    final pesticideType = (_currentLog['pesticide_type'] ?? '').toString();
    
    final notes = (_currentLog['notes'] ?? '').toString();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanged);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.softGray,
        appBar: AppBar(
          title: const Text('Log Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editLog,
              tooltip: 'Edit Log',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _deleteLog,
              tooltip: 'Delete Log',
            ),
          ],
        ),
        body: _isDeleting
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header section
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppTheme.deepLeafGreen.withOpacity(0.1), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightMint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.calendar_month_rounded, color: AppTheme.deepLeafGreen),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Logging Date',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: AppTheme.darkGreen,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 30, thickness: 1),
                          // Land registration details
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.terrain_rounded, color: Color(0xFF475569)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Land Information',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      landReg.isNotEmpty && landReg != 'null'
                                          ? 'Reg No: $landReg'
                                          : 'Size: $landSize Perches',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Growth Stage Section
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.analytics_outlined, color: Colors.orange),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Growth Stage',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  stageName.isNotEmpty ? stageName : 'Unknown Stage',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Leaf Appearance (if available)
                  if (leafAppearance.isNotEmpty)
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.teal.withOpacity(0.1)),
                              ),
                              child: const Icon(Icons.eco_outlined, color: Colors.teal),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Leaf Appearance',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    leafAppearance,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Disease and Pest status (Visually stunning Cards)
                  _buildHealthStatusCard(
                    diseaseDetected: diseaseDetected,
                    diseaseName: diseaseName,
                    diseaseDamage: diseaseDamage,
                    pestDetected: pestDetected,
                    pestName: pestName,
                    pestDamage: pestDamage,
                  ),

                  // Pesticide Info
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: pesticideApplied ? Colors.purple.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.science_outlined,
                                  color: pesticideApplied ? Colors.purple : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pesticide Application',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      pesticideApplied ? 'Pesticide Applied' : 'No Pesticide Applied',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: pesticideApplied ? Colors.purple : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (pesticideApplied) ...[
                            const Divider(height: 24, thickness: 1),
                            _buildDetailRow('Name', pesticideName),
                            const SizedBox(height: 8),
                            _buildDetailRow('Type', pesticideType),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Notes Box
                  if (notes.isNotEmpty)
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 24),
                      color: AppTheme.pureWhite,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.notes_rounded, color: AppTheme.deepLeafGreen, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Notes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.softGray,
                                borderRadius: BorderRadius.circular(12),
                                border: Border(
                                  left: BorderSide(color: AppTheme.deepLeafGreen.withOpacity(0.5), width: 4),
                                ),
                              ),
                              child: Text(
                                notes,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Bottom Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _deleteLog,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _editLog,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                            foregroundColor: AppTheme.pureWhite,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthStatusCard({
    required bool diseaseDetected,
    required String diseaseName,
    required String diseaseDamage,
    required bool pestDetected,
    required String pestName,
    required String pestDamage,
  }) {
    if (!diseaseDetected && !pestDetected) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        color: const Color(0xFFECFDF5), // soft green
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crop Health Status',
                      style: TextStyle(color: Color(0xFF047857), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Healthy (No issues detected)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFFFFBEB), // soft warning yellow
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crop Health Alert',
                        style: TextStyle(color: Colors.brown, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Threats Detected',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFFDE68A)),
            if (diseaseDetected) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle_notifications_outlined, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diseaseName.isNotEmpty ? 'Disease: $diseaseName' : 'Disease Diagnostics',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          diseaseDamage.isNotEmpty ? diseaseDamage : 'No disease damage/symptom details specified.',
                          style: TextStyle(fontSize: 13, color: Colors.brown.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (pestDetected) const SizedBox(height: 16),
            ],
            if (pestDetected) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bug_report_outlined, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pestName.isNotEmpty ? 'Pest: $pestName' : 'Pest Diagnostics',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pestDamage.isNotEmpty ? pestDamage : 'No pest damage/symptom details specified.',
                          style: TextStyle(fontSize: 13, color: Colors.brown.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
  final _diseaseNameController = TextEditingController();
  final _diseaseDamageController = TextEditingController();
  final _pestNameController = TextEditingController();
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

    final rawDisease = (e['disease_name_and_damage'] ?? '').toString();
    if (rawDisease.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDisease) as Map<String, dynamic>;
        _diseaseNameController.text = decoded['name'] ?? '';
        _diseaseDamageController.text = decoded['damage'] ?? '';
      } catch (_) {
        _diseaseNameController.text = rawDisease;
        _diseaseDamageController.text = '';
      }
    } else {
      _diseaseNameController.text = '';
      _diseaseDamageController.text = '';
    }

    final rawPest = (e['pest_name_and_damage'] ?? '').toString();
    if (rawPest.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPest) as Map<String, dynamic>;
        _pestNameController.text = decoded['name'] ?? '';
        _pestDamageController.text = decoded['damage'] ?? '';
      } catch (_) {
        _pestNameController.text = rawPest;
        _pestDamageController.text = '';
      }
    } else {
      _pestNameController.text = '';
      _pestDamageController.text = '';
    }

    _pesticideApplied = e['pesticide_applied'] == true;
    _pesticideNameController.text = (e['pesticide_name'] ?? '').toString();
    _pesticideTypeController.text = (e['pesticide_type'] ?? '').toString();
    _notesController.text = (e['notes'] ?? '').toString();
  }

  @override
  void dispose() {
    _leafController.dispose();
    _diseaseNameController.dispose();
    _diseaseDamageController.dispose();
    _pestNameController.dispose();
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
      'disease_name_and_damage': _diseaseDetected
          ? jsonEncode({
              'name': _diseaseNameController.text.trim(),
              'damage': _diseaseDamageController.text.trim(),
            })
          : null,
      'pest_name_and_damage': _pestDetected
          ? jsonEncode({
              'name': _pestNameController.text.trim(),
              'damage': _pestDamageController.text.trim(),
            })
          : null,
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
                            if (_diseaseDetected) ...[
                              TextFormField(
                                controller: _diseaseNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Disease name (optional)',
                                  prefixIcon: Icon(Icons.warning_amber_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _diseaseDamageController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Disease damage / symptoms (optional)',
                                  prefixIcon: Icon(Icons.description_outlined),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            SwitchListTile.adaptive(
                              value: _pestDetected,
                              onChanged: (v) => setState(() => _pestDetected = v),
                              title: const Text('Pest detected'),
                              activeColor: AppTheme.deepLeafGreen,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (_pestDetected) ...[
                              TextFormField(
                                controller: _pestNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Pest name (optional)',
                                  prefixIcon: Icon(Icons.bug_report_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _pestDamageController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Pest damage / symptoms (optional)',
                                  prefixIcon: Icon(Icons.description_outlined),
                                ),
                              ),
                            ],
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
