import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/leetcode_problem.dart';

class ProblemsService {
  static List<LeetCodeProblem> _allProblems = [];
  static bool _isLoaded = false;

  // Load problems from JSON file
  static Future<void> loadProblems() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('lib/merged_problems.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> questionsJson = jsonData['questions'] ?? [];
      _allProblems = questionsJson
          .map((json) => LeetCodeProblem.fromJson(json))
          .where((problem) => problem.title.isNotEmpty) // Filter out empty problems
          .toList();
      
      _isLoaded = true;
    } catch (e) {
      print('Error loading problems: $e');
      _allProblems = [];
    }
  }

  // Get all problems
  static List<LeetCodeProblem> getAllProblems() {
    return _allProblems;
  }

  // Filter problems by difficulty
  static List<LeetCodeProblem> getByDifficulty(String difficulty) {
    return _allProblems
        .where((problem) => problem.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }

  // Filter problems by topic
  static List<LeetCodeProblem> getByTopic(String topic) {
    return _allProblems
        .where((problem) => problem.topics
            .any((t) => t.toLowerCase().contains(topic.toLowerCase())))
        .toList();
  }

  // Filter problems by both difficulty and topic
  static List<LeetCodeProblem> getFilteredProblems({
    String? difficulty,
    String? topic,
  }) {
    List<LeetCodeProblem> filtered = _allProblems;

    if (difficulty != null && difficulty != 'All') {
      filtered = filtered
          .where((problem) => problem.difficulty.toLowerCase() == difficulty.toLowerCase())
          .toList();
    }

    if (topic != null && topic != 'All') {
      // Multi-topic AND filtering: only include problems that contain ALL selected topics
      final topicList = topic.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      if (topicList.isNotEmpty) {
        filtered = filtered.where((problem) => topicList.every((t) => problem.topics.map((pt) => pt.toLowerCase()).contains(t.toLowerCase()))).toList();
      }
    }

    return filtered;
  }

  // Get all unique topics
  static List<String> getAllTopics() {
    final Set<String> topicsSet = {};
    for (final problem in _allProblems) {
      topicsSet.addAll(problem.topics);
    }
    final topics = topicsSet.toList()..sort();
    return ['All', ...topics];
  }

  // Get all difficulties
  static List<String> getAllDifficulties() {
    final Set<String> difficultiesSet = _allProblems
        .map((problem) => problem.difficulty)
        .where((difficulty) => difficulty.isNotEmpty)
        .toSet();
    return ['All', ...difficultiesSet.toList()];
  }
}
