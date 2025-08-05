import 'package:flutter/material.dart';

class LeetCodeProblem {
  final String title;
  final String problemId;
  final String frontendId;
  final String difficulty;
  final String problemSlug;
  final List<String> topics;
  final String description;
  final List<Example> examples;
  final List<String> constraints;
  final List<String> followUps;
  final List<String> hints;
  final Map<String, String> codeSnippets;
  final String? solution;

  LeetCodeProblem({
    required this.title,
    required this.problemId,
    required this.frontendId,
    required this.difficulty,
    required this.problemSlug,
    required this.topics,
    required this.description,
    required this.examples,
    required this.constraints,
    required this.followUps,
    required this.hints,
    required this.codeSnippets,
    this.solution,
  });

  factory LeetCodeProblem.fromJson(Map<String, dynamic> json) {
    return LeetCodeProblem(
      title: json['title'] ?? '',
      problemId: json['problem_id'] ?? '',
      frontendId: json['frontend_id'] ?? '',
      difficulty: json['difficulty'] ?? 'Unknown',
      problemSlug: json['problem_slug'] ?? '',
      topics: List<String>.from(json['topics'] ?? []),
      description: json['description'] ?? '',
      examples: (json['examples'] as List?)
              ?.map((e) => Example.fromJson(e))
              .toList() ??
          [],
      constraints: List<String>.from(json['constraints'] ?? []),
      followUps: List<String>.from(json['follow_ups'] ?? []),
      hints: List<String>.from(json['hints'] ?? []),
      codeSnippets: Map<String, String>.from(json['code_snippets'] ?? {}),
      solution: json['solution'],
    );
  }

  // Helper method to get difficulty color
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF00B8A3);
      case 'medium':
        return const Color(0xFFFFC01E);
      case 'hard':
        return const Color(0xFFFF375F);
      default:
        return Colors.grey;
    }
  }
}

class Example {
  final int exampleNum;
  final String exampleText;
  final List<String> images;

  Example({
    required this.exampleNum,
    required this.exampleText,
    required this.images,
  });

  factory Example.fromJson(Map<String, dynamic> json) {
    return Example(
      exampleNum: json['example_num'] ?? 0,
      exampleText: json['example_text'] ?? '',
      images: List<String>.from(json['images'] ?? []),
    );
  }
}
