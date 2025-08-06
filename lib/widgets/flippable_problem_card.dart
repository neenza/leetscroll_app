import 'package:flutter/material.dart';
import '../models/leetcode_problem.dart';

class FlippableProblemCard extends StatefulWidget {
  final LeetCodeProblem problem;
  final VoidCallback? onScrollToNext;

  const FlippableProblemCard({
    super.key,
    required this.problem,
    this.onScrollToNext,
  });

  @override
  State<FlippableProblemCard> createState() => _FlippableProblemCardState();
}

class _FlippableProblemCardState extends State<FlippableProblemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  late ScrollController _scrollController;
  bool _isShowingSolution = false;
  bool _hasReachedBottom = false;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
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
      onTap: _flip,
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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    '#${widget.problem.frontendId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  backgroundColor: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                SizedBox(width: 12),
                Chip(
                  label: Text(
                    widget.problem.difficulty,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: LeetCodeProblem.getDifficultyColor(widget.problem.difficulty),
                    ),
                  ),
                  backgroundColor: LeetCodeProblem.getDifficultyColor(widget.problem.difficulty).withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                Spacer(),
                IconButton(
                  onPressed: _flip,
                  icon: Icon(Icons.flip_to_back),
                  tooltip: 'Flip to see solution',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.problem.title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: Colors.grey.shade600,
                              ),
                            )),
                    const SizedBox(height: 16),

                    // Examples
                    if (widget.problem.examples.isNotEmpty) ...[
                      Text(
                        'Examples:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.problem.examples.map((example) {
                        // Remove unwanted lines from example text
                        final filteredExample = example.exampleText
                            .split('\n')
                            .where((line) =>
                              !line.trim().startsWith('Example 1:') &&
                              !line.trim().startsWith('Example 2:') &&
                              !line.trim().startsWith('Example 3:') &&
                              !line.trim().startsWith('Constraints:'))
                            .join('\n');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            filteredExample,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ],

                    // Constraints
                    if (widget.problem.constraints.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Constraints:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.problem.constraints.map((constraint) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $constraint',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      }).toList(),
                    ],

                    const SizedBox(height: 16),
                    if (widget.problem.topics.isNotEmpty) ...[
                      Text(
                        'Topics:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: widget.problem.topics.map((topic) {
                          return Chip(
                            label: Text(
                              topic,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.purple.shade50,
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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Solution',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _flip,
                  icon: const Icon(Icons.flip_to_front),
                  tooltip: 'Flip to see problem',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Solution content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.problem.solution != null) ...[
                      Text(
                        widget.problem.solution!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Hints
                    if (widget.problem.hints.isNotEmpty) ...[
                      Text(
                        'Hints:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.problem.hints.asMap().entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 20),
                    ],

                    // Code snippets
                    if (widget.problem.codeSnippets.isNotEmpty) ...[
                      Text(
                        'Code Templates:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.problem.codeSnippets.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  entry.key.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),

            // Tap to flip back hint
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to see problem',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
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
}
