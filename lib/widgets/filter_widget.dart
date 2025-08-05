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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Filter title
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'Filter Problems',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Difficulty filter
          Text(
            'Difficulty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ProblemsService.getAllDifficulties().map((difficulty) {
                final isSelected = widget.selectedDifficulty == difficulty;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(difficulty),
                    selected: isSelected,
                    onSelected: (selected) {
                      widget.onFiltersChanged(difficulty, widget.selectedTopic);
                    },
                    backgroundColor: Colors.transparent,
                    selectedColor: _getDifficultyColor(difficulty).withOpacity(0.2),
                    side: BorderSide(color: _getDifficultyColor(difficulty)),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? _getDifficultyColor(difficulty)
                          : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: ProblemsService.getAllTopics().map((topic) {
                  final isSelected = widget.selectedTopic == topic;
                  return FilterChip(
                    label: Text(
                      topic,
                      style: TextStyle(fontSize: 12),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      widget.onFiltersChanged(widget.selectedDifficulty, topic);
                    },
                    backgroundColor: Colors.transparent,
                    selectedColor: Colors.purple.shade100,
                    side: BorderSide(
                      color: isSelected ? Colors.purple.shade400 : Colors.grey.shade400,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.purple.shade700 : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Apply filters button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Apply Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
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
