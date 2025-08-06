import 'package:flutter/material.dart';
import '../services/problems_service.dart';

class FilterWidget extends StatefulWidget {
  final String selectedDifficulty;
  final String selectedTopic;
  final Function(String difficulty, String topic) onFiltersChanged;

  const FilterWidget({
    super.key,
    required this.selectedDifficulty,
    required this.selectedTopic,
    required this.onFiltersChanged,
  });

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
late String _selectedDifficulty;
late Set<String> _selectedTopics;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.selectedDifficulty;
    if (widget.selectedTopic == 'All' || widget.selectedTopic.isEmpty) {
      _selectedTopics = <String>{};
    } else {
      _selectedTopics = widget.selectedTopic.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Filter title
          Row(
            children: [
              Icon(Icons.filter_list, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Filter Problems',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Difficulty filter
          Text(
            'Difficulty',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ProblemsService.getAllDifficulties().map((difficulty) {
                final isSelected = _selectedDifficulty == difficulty;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDifficulty = difficulty;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(
                        difficulty,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isSelected 
                              ? _getDifficultyColor(difficulty)
                              : colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: isSelected
                          ? _getDifficultyColor(difficulty).withOpacity(0.2)
                          : colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _getDifficultyColor(difficulty)),
                      ),
                      elevation: 0,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Topic filter
          Text(
            'Topics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  // All Topics chip
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTopics.clear();
                      });
                    },
                    child: Chip(
                      label: Text(
                        'All Topics',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: _selectedTopics.isEmpty ? colorScheme.secondary : colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: _selectedTopics.isEmpty ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: _selectedTopics.isEmpty
                          ? colorScheme.secondaryContainer
                          : colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _selectedTopics.isEmpty ? colorScheme.secondary : colorScheme.outline.withOpacity(0.5)),
                      ),
                      elevation: 0,
                    ),
                  ),
                  // Individual topic chips (excluding any 'All' or 'All Topics')
                  ...ProblemsService.getAllTopics()
                    .where((topic) => topic.toLowerCase() != 'all' && topic.toLowerCase() != 'all topics')
                    .map((topic) {
                      final isSelected = _selectedTopics.contains(topic);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTopics.remove(topic);
                            } else {
                              _selectedTopics.add(topic);
                            }
                          });
                        },
                        child: Chip(
                          label: Text(
                            topic,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              color: isSelected ? colorScheme.secondary : colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          backgroundColor: isSelected
                              ? colorScheme.secondaryContainer
                              : colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSelected ? colorScheme.secondary : colorScheme.outline.withOpacity(0.5)),
                          ),
                          elevation: 0,
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Apply filters button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final topicsStr = _selectedTopics.isEmpty ? 'All' : _selectedTopics.join(',');
                widget.onFiltersChanged(_selectedDifficulty, topicsStr);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Apply Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Reset filters button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedDifficulty = 'All';
                  _selectedTopics.clear();
                });
                widget.onFiltersChanged('All', 'All');
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filters'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF00B8A3);
      case 'medium':
        return const Color(0xFFFFC01E);
      case 'hard':
        return const Color(0xFFFF375F);
      default:
        return Colors.blue;
    }
  }
}
