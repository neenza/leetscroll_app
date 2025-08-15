import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:markdown/markdown.dart' as md;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leetcode_problem.dart';

// Custom builder for syntax-highlighted code blocks (C++)
class CodeElementBuilder extends MarkdownElementBuilder {
  // Helper to clone a theme and set background to transparent
  Map<String, TextStyle> _transparentBgTheme(Map<String, TextStyle> baseTheme) {
    final newTheme = Map<String, TextStyle>.from(baseTheme);
    newTheme['root'] = (baseTheme['root'] ?? const TextStyle()).copyWith(backgroundColor: Colors.transparent);
    return newTheme;
  }

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    String language = 'cpp';
    if (element.attributes['class'] != null) {
      final classAttr = element.attributes['class'] as String;
      if (classAttr.startsWith('language-')) {
        language = classAttr.substring(9);
      }
    }
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        // Blend secondaryContainer with surface for a lighter, more elegant code block background
        final codeBgColor = Color.alphaBlend(
          colorScheme.surface.withOpacity(0.5),
          colorScheme.secondaryContainer,
        );
        final highlightTheme = isDark ? atomOneDarkTheme : atomOneLightTheme;
        final transparentTheme = _transparentBgTheme(highlightTheme);
        return Container(
          decoration: BoxDecoration(
            color: codeBgColor,
          ),
          child: HighlightView(
            element.textContent,
            language: language,
            theme: transparentTheme,
            padding: const EdgeInsets.all(2),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
            ),
          ),
        );
      },
    );
  }
}


// Simple chat message model
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  _ChatMessage({required this.text, required this.isUser, required this.timestamp});
}


class FlippableProblemCard extends StatefulWidget {
  final LeetCodeProblem problem;
  final VoidCallback? onScrollToNext;
  final ValueChanged<bool>? onSolvedChanged;
  final ValueChanged<bool>? onCardSideChanged;

  const FlippableProblemCard({
    super.key,
    required this.problem,
    this.onScrollToNext,
    this.onSolvedChanged,
    this.onCardSideChanged,
  });

  @override
  State<FlippableProblemCard> createState() => _FlippableProblemCardState();
}

class _FlippableProblemCardState extends State<FlippableProblemCard> with SingleTickerProviderStateMixin {
  List<_ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  String? _userApiKey;
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  late ScrollController _scrollController;
  bool _isShowingSolution = false;
  bool _hasReachedBottom = false;
  String _selectedModel = "2.5-flash";

  void _showModelDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    _apiKeyController.text = _userApiKey ?? '';
    showDialog(
      context: context,
      builder: (context) => _buildModelDialog(theme, colorScheme),
    );
  }

  Widget _buildModelDialog(ThemeData theme, ColorScheme colorScheme) {
    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.memory, color: colorScheme.secondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Select Model',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildModelOption('2.5-flash', 'Fast, lower cost, good for most use cases'),
            SizedBox(height: 12),
            _buildModelOption('2.5-pro', 'Higher quality, more capable, higher cost'),
            SizedBox(height: 20),
            Text('Gemini API Key:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Paste your Gemini API key here',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final key = _apiKeyController.text.trim();
                    setState(() {
                      _userApiKey = key.isEmpty ? null : key;
                    });
                    final prefs = await SharedPreferences.getInstance();
                    if (key.isNotEmpty) {
                      await prefs.setString('gemini_api_key', key);
                    } else {
                      await prefs.remove('gemini_api_key');
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
                SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelOption(String model, String description) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedModel == model;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedModel = model;
        });
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.secondaryContainer : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.secondary : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? colorScheme.secondary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ...existing methods (copy all other methods and build functions here)...


  void _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add(_ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _chatController.clear();

    // Add a loading message
    setState(() {
      _chatMessages.add(_ChatMessage(
        text: '[AI is typing...]',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });

    try {
      // Use user-provided API key if available, else .env
      final apiKey = (_userApiKey != null && _userApiKey!.isNotEmpty)
          ? _userApiKey
          : dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found. Please paste your API key in the model dialog or set GEMINI_API_KEY in your .env file.');
      }

      // Prepare the context: problem JSON
      final problemJson = _problemToJson(widget.problem);

      // Build the full chat history for Gemini
      List<Map<String, dynamic>> contents = [];
      // Add system prompt as the very first message (if you want to always include problem context)
      contents.add({
        "role": "user",
        "parts": [
          {"text": "You are an expert coding assistant. Here is a LeetCode problem in JSON format: $problemJson. The user will now ask a question about this problem. Please answer as helpfully as possible."}
        ]
      });
      // Add all previous chat messages (except the loading message)
      // Only keep the last 20 exchanges for context window safety
      final history = _chatMessages.where((msg) => msg.text != '[AI is typing...]').toList();
      final maxHistory = 20;
      final startIdx = history.length > maxHistory ? history.length - maxHistory : 0;
      for (var msg in history.sublist(startIdx)) {
        contents.add({
          "role": msg.isUser ? "user" : "model",
          "parts": [
            {"text": msg.text}
          ]
        });
      }
      // Add the new user message as the last entry
      // (already added above, so no need to add again)

      // Use selected model in endpoint
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-${_selectedModel}:generateContent?key=$apiKey');

      final requestBody = {
        "contents": contents
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      String aiText = 'Sorry, no response from Gemini.';
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["candidates"] != null && data["candidates"].isNotEmpty) {
          final parts = data["candidates"][0]["content"]["parts"];
          if (parts != null && parts.isNotEmpty && parts[0]["text"] != null) {
            aiText = parts[0]["text"];
          }
        } else if (data["promptFeedback"] != null && data["promptFeedback"]["blockReason"] != null) {
          aiText = 'Gemini blocked this prompt: ' + data["promptFeedback"]["blockReason"];
        }
      } else {
        aiText = 'Gemini API error: \\${response.statusCode} \\${response.reasonPhrase}';
      }

      setState(() {
        // Remove the loading message
        _chatMessages.removeWhere((msg) => msg.text == '[AI is typing...]' && !msg.isUser);
        _chatMessages.add(_ChatMessage(
          text: aiText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _chatMessages.removeWhere((msg) => msg.text == '[AI is typing...]' && !msg.isUser);
        _chatMessages.add(_ChatMessage(
          text: 'Error: \\${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  // Helper to convert LeetCodeProblem to JSON string
  String _problemToJson(LeetCodeProblem problem) {
    try {
      return jsonEncode({
        'frontendId': problem.frontendId,
        'title': problem.title,
        'difficulty': problem.difficulty,
        'description': problem.description,
        'examples': problem.examples.map((e) => {
          'exampleText': e.exampleText,
          'images': e.images,
        }).toList(),
        'constraints': problem.constraints,
        'topics': problem.topics,
        'hints': problem.hints,
        'isSolved': problem.isSolved,
      });
    } catch (e) {
      return '{}';
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _scrollController = ScrollController();
    // Load API key from SharedPreferences
    _loadApiKey();
    // Notify parent of initial side (front)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCardSideChanged?.call(true);
    });
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('gemini_api_key');
    if (key != null && key.isNotEmpty) {
      setState(() {
        _userApiKey = key;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isShowingSolution) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isShowingSolution = !_isShowingSolution;
      widget.onCardSideChanged?.call(!_isShowingSolution);
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    // Only handle scroll notifications when showing the problem side
    if (_isShowingSolution) return false;
    
    // Use a small threshold to account for floating point precision
    final threshold = 1.0;
    final isAtBottom = _scrollController.position.pixels >= 
        (_scrollController.position.maxScrollExtent - threshold);
    
    if (notification is ScrollEndNotification) {
      // User has finished scrolling
      if (isAtBottom) {
        // Mark that user has reached bottom and finished scrolling
        _hasReachedBottom = true;
        print('DEBUG: User reached bottom, _hasReachedBottom = true');
      }
      return false; // Don't consume the event
    }
    
    if (notification is ScrollUpdateNotification) {
      final isScrollingDown = notification.scrollDelta != null && notification.scrollDelta! > 0;
      
      print('DEBUG: ScrollUpdate - isAtBottom: $isAtBottom, isScrollingDown: $isScrollingDown, _hasReachedBottom: $_hasReachedBottom, scrollDelta: ${notification.scrollDelta}');
      
      if (isAtBottom && _hasReachedBottom) {
        // User is at bottom and has previously reached bottom
        // Any scroll attempt (even if delta is 0) should trigger next card
        if (notification.scrollDelta != null && notification.scrollDelta! >= 0) {
          print('DEBUG: Triggering next card');
          widget.onScrollToNext?.call();
          _hasReachedBottom = false; // Reset for next time
          return true; // Consume the event
        }
      }
      
      if (!isAtBottom) {
        // Reset if user scrolls away from bottom
        if (_hasReachedBottom) {
          print('DEBUG: User scrolled away from bottom, resetting flag');
        }
        _hasReachedBottom = false;
      }
    }
    
    // Also check for OverscrollNotification - this fires when trying to scroll beyond bounds
    if (notification is OverscrollNotification) {
      final isScrollingDown = notification.overscroll > 0;
      print('DEBUG: Overscroll detected - overscroll: ${notification.overscroll}, _hasReachedBottom: $_hasReachedBottom');
      
      if (isScrollingDown && _hasReachedBottom) {
        print('DEBUG: Triggering next card via overscroll');
        widget.onScrollToNext?.call();
        _hasReachedBottom = false; // Reset for next time
        return true; // Consume the event
      }
    }
    
    return false; // Don't consume the event
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Only flip if swipe is significant
        if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 200) {
          _flip();
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final isShowingFront = _flipAnimation.value < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimation.value * 3.14159),
              child: isShowingFront
                  ? _buildProblemSide()
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.14159),
                      child: _buildSolutionSide(),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProblemSide() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
        ? colorScheme.primary.withOpacity(0.18)
        : Colors.black.withOpacity(0.12);
    final shadowColorTop = isDark
        ? colorScheme.primary.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, 6),
              blurRadius: 16,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: shadowColorTop,
              offset: Offset(0, -6),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    '#${widget.problem.frontendId}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  backgroundColor: colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),

                SizedBox(width: 12),
                Chip(
                  label: Text(
                    widget.problem.difficulty,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: LeetCodeProblem.getDifficultyColor(widget.problem.difficulty),
                    ),
                  ),
                  backgroundColor: LeetCodeProblem.getDifficultyColor(widget.problem.difficulty).withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                SizedBox(width: 12),
                FilterChip(
                  label: Text(
                    widget.problem.isSolved ? 'Solved' : 'Not Solved',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.problem.isSolved
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  selected: widget.problem.isSolved,
                  onSelected: (bool value) async {
                    widget.onSolvedChanged?.call(value);
                  },
                  showCheckmark: widget.problem.isSolved,
                  checkmarkColor: colorScheme.primary,
                  backgroundColor: widget.problem.isSolved
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  disabledColor: widget.problem.isSolved
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceVariant,
                ),

                Spacer(),
                IconButton(
                  onPressed: () {
                    if (widget.problem.hints.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(Icons.lightbulb, color: colorScheme.secondary),
                              const SizedBox(width: 8),
                              Text('Hints', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.problem.hints
                                  .asMap()
                                  .entries
                                  .map((entry) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: colorScheme.tertiary,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${entry.key + 1}',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: colorScheme.onTertiary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                entry.value,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: colorScheme.onSurface.withOpacity(0.8),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(Icons.lightbulb, color: colorScheme.secondary),
                              const SizedBox(width: 8),
                              Text('Hints', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          content: Text('Hints are not available for this question.', style: theme.textTheme.bodyMedium),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.lightbulb, color: colorScheme.secondary),
                  tooltip: 'Show hints',
                ),
                // Flip button removed; flip by swipe/tap
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.problem.title,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),


            // Problem description
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Problem Description:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Remove unwanted lines from description
                    ...widget.problem.description
                        .split('\n')
                        .where((line) =>
                          !line.trim().startsWith('Example 1:') &&
                          !line.trim().startsWith('Example 2:') &&
                          !line.trim().startsWith('Example 3:') &&
                          !line.trim().startsWith('Constraints:'))
                        .map((line) => Text(
                              line,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            )),
                    const SizedBox(height: 16),

                    // Examples
                    if (widget.problem.examples.isNotEmpty) ...[
                      Text(
                        'Examples:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ...widget.problem.examples.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final example = entry.value;
                      final filteredExample = example.exampleText
                          .split('\n')
                          .where((line) =>
                            !line.trim().startsWith('Example 1:') &&
                            !line.trim().startsWith('Example 2:') &&
                            !line.trim().startsWith('Example 3:') &&
                            !line.trim().startsWith('Constraints:'))
                          .join('\n');
                      // Get images from example 1
                      final example1Images = widget.problem.examples.isNotEmpty
                          ? widget.problem.examples[0].images
                          : <String>[];
                      // Only show images not present in example 1 (unless this is example 1)
                      final imagesToShow = idx == 0
                          ? example.images
                          : example.images.where((img) => !example1Images.contains(img)).toList();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              filteredExample,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                            if (imagesToShow.isNotEmpty)
                              ...imagesToShow.map((imgUrl) => Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imgUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey.shade200,
                                      height: 120,
                                      child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                    ),
                                  ),
                                ),
                              ))
                          ],
                        ),
                      );
                    }).toList(),
                    ],

                    // Constraints
                    if (widget.problem.constraints.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Constraints:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.problem.constraints.map((constraint) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $constraint',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        );
                      }).toList(),
                    ],

                    const SizedBox(height: 16),
                    if (widget.problem.topics.isNotEmpty) ...[
                      Text(
                        'Topics:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: widget.problem.topics.map((topic) {
                          return Chip(
                            label: Text(
                              topic,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 12,
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: colorScheme.secondaryContainer,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionSide() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
        ? colorScheme.primary.withOpacity(0.12)
        : Colors.black.withOpacity(0.12);
    final shadowColorTop = isDark
        ? colorScheme.primary.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, 6),
              blurRadius: 16,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: shadowColorTop,
              offset: Offset(0, -6),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Chat header
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Ask AI',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                // Model chip
                GestureDetector(
                  onTap: _showModelDialog,
                  child: Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Model', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Text(_selectedModel, style: theme.textTheme.labelSmall?.copyWith(fontSize: 11, color: colorScheme.secondary)),
                      ],
                    ),
                    backgroundColor: colorScheme.secondaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            // Chat messages
            Expanded(
              child: _chatMessages.isEmpty
                  ? Center(
                      child: Text(
                        'Ask anything about this problem!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      reverse: false,
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, idx) {
                        final msg = _chatMessages[idx];
                        return Align(
                          alignment: msg.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: msg.isUser
                                  ? colorScheme.primary.withOpacity(0.15)
                                  : colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: msg.isUser
                                ? Text(
                                    msg.text,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  )
                                : MarkdownBody(
                                    data: msg.text,
                                    styleSheet: MarkdownStyleSheet(
                                      p: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                    builders: {
                                      'code': CodeElementBuilder(),
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
            ),
            // Input field
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type your question...'
                      ),
                      onSubmitted: (_) => _sendChatMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: colorScheme.primary),
                    onPressed: _sendChatMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
