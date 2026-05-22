import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class StoryReviewScreen extends StatelessWidget {
  const StoryReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final story = state.story;

    if (story == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Story')),
        body: const Center(child: Text('No story generated yet.')),
      );
    }

    final allViolations = story.pages.expand((p) => p.vocabViolations).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(story.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (allViolations.isNotEmpty)
            _VocabWarningBanner(violations: allViolations),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: story.pages.length,
              itemBuilder: (ctx, i) {
                final page = story.pages[i];
                return _PageTextCard(
                  page: page.page,
                  text: page.text,
                  violations: page.vocabViolations,
                  onEdit: () => _showEditDialog(context, state, page.page, page.text),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () {
              state.generateAllImages();
              Navigator.pushNamed(context, '/images');
            },
            icon: const Icon(Icons.image),
            label: const Text('Generate Images'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    AppState state,
    int pageNum,
    String currentText,
  ) async {
    final ctrl = TextEditingController(text: currentText);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Page $pageNum'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != null && saved.isNotEmpty) {
      state.updatePageText(pageNum, saved);
    }
    ctrl.dispose();
  }
}

// ---------------------------------------------------------------------------
// Vocab warning banner
// ---------------------------------------------------------------------------

class _VocabWarningBanner extends StatelessWidget {
  final List<String> violations;

  const _VocabWarningBanner({required this.violations});

  @override
  Widget build(BuildContext context) {
    final unique = violations.toSet().take(8).join(', ');
    final more = violations.toSet().length > 8 ? ' …and more.' : '.';
    return Material(
      color: const Color(0xFFFDECEA),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber, color: Color(0xFFC0392B), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${violations.length} word(s) may exceed the phonics level: $unique$more',
                style: const TextStyle(color: Color(0xFFC0392B), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-page card
// ---------------------------------------------------------------------------

class _PageTextCard extends StatelessWidget {
  final int page;
  final String text;
  final List<String> violations;
  final VoidCallback onEdit;

  const _PageTextCard({
    required this.page,
    required this.text,
    required this.violations,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Page $page',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )),
                const Spacer(),
                if (violations.isNotEmpty)
                  Tooltip(
                    message: violations.join(', '),
                    child: const Icon(Icons.warning_amber,
                        size: 18, color: Color(0xFFC0392B)),
                  ),
                const SizedBox(width: 4),
                TextButton(onPressed: onEdit, child: const Text('Edit')),
              ],
            ),
            const SizedBox(height: 6),
            _HighlightedText(text: text, violations: violations),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Text widget that highlights violated words in red
// ---------------------------------------------------------------------------

class _HighlightedText extends StatelessWidget {
  final String text;
  final List<String> violations;

  const _HighlightedText({required this.text, required this.violations});

  @override
  Widget build(BuildContext context) {
    if (violations.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 16));
    }

    final violSet = violations.map((v) => v.toLowerCase()).toSet();
    final words = text.split(RegExp(r'\s+'));
    final spans = <TextSpan>[];

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final clean = word.toLowerCase().replaceAll(RegExp(r"[^a-z']"), '');
      final isViolation = violSet.contains(clean);
      spans.add(TextSpan(
        text: i < words.length - 1 ? '$word ' : word,
        style: TextStyle(
          fontSize: 16,
          color: isViolation ? const Color(0xFFC0392B) : null,
          decoration: isViolation ? TextDecoration.underline : null,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
