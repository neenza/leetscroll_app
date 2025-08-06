import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/leetcode_problem.dart';
import '../services/problems_service.dart';
import '../widgets/flippable_problem_card.dart';
import '../widgets/filter_widget.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onToggleTheme;

  const HomeScreen({
    super.key,
    this.isDarkMode = false,
    this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController _pageController = PageController();
  List<LeetCodeProblem> _problems = [];
  List<LeetCodeProblem> _filteredProblems = [];
  bool _isLoading = true;
  String _selectedDifficulty = 'All';
  String _selectedTopic = 'All';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProblems();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProblems() async {
    setState(() {
      _isLoading = true;
    });

    await ProblemsService.loadProblems();
    
    setState(() {
      _problems = ProblemsService.getAllProblems();
      _filteredProblems = _problems;
      _isLoading = false;
    });
  }

  void _applyFilters(String difficulty, String topic) {
    setState(() {
      _selectedDifficulty = difficulty;
      _selectedTopic = topic;
      _filteredProblems = ProblemsService.getFilteredProblems(
        difficulty: difficulty == 'All' ? null : difficulty,
        topic: topic == 'All' ? null : topic,
      );
      _currentIndex = 0;
    });
    
    // Jump to first problem after filtering
    if (_filteredProblems.isNotEmpty) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterWidget(
        selectedDifficulty: _selectedDifficulty,
        selectedTopic: _selectedTopic,
        onFiltersChanged: _applyFilters,
      ),
    );
  }

  void _navigateToNextProblem() {
    if (_currentIndex < _filteredProblems.length - 1) {
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AppBar(
              backgroundColor: colorScheme.surface.withOpacity(0.2),
              elevation: 0,
              centerTitle: false,
              titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: 1.2,
              ),
              title: Row(
                children: [
                  const Text('LeetScroll', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round, color: colorScheme.onSurface),
                    tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    onPressed: widget.onToggleTheme,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _filteredProblems.isEmpty
              ? _buildEmptyState()
              : _buildProblemsView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterBottomSheet,
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.filter_list, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading LeetCode Problems...',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onBackground.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No problems found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 14,
              color: colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _applyFilters('All', 'All');
            },
            icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
            label: const Text('Reset Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemsView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Stack(
      children: [
        // Main problems view without top padding or SafeArea
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: _filteredProblems.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(top: 84),
              child: FlippableProblemCard(
                problem: _filteredProblems[index],
                onScrollToNext: _navigateToNextProblem,
              ),
            );
          },
        ),

        // Current filters indicator
        if (_selectedDifficulty != 'All' || _selectedTopic != 'All')
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, color: colorScheme.onPrimary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filters: ${_selectedDifficulty != 'All' ? _selectedDifficulty : ''}${_selectedDifficulty != 'All' && _selectedTopic != 'All' ? ' • ' : ''}${_selectedTopic != 'All' ? _selectedTopic : ''}',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _applyFilters('All', 'All'),
                    child: Icon(Icons.close, color: colorScheme.onPrimary, size: 16),
                  ),
                ],
              ),
            ),
          ),

        // Navigation hints
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Row(
            children: [
              // ...existing code...
            ],
          ),
        ),
      ],
    );
  }
}
