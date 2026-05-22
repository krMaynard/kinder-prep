import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/story.dart';
import '../providers/app_state.dart';

class ImageReviewScreen extends StatelessWidget {
  const ImageReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final story = state.story;

    if (story == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Images')),
        body: const Center(child: Text('No story generated yet.')),
      );
    }

    final busy = state.status == GenerationStatus.generatingImages;

    return Scaffold(
      appBar: AppBar(
        title: Text(story.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: busy ? null : () => _exportStory(context, state, story),
            tooltip: 'Export story',
          ),
        ],
      ),
      body: Column(
        children: [
          if (busy)
            LinearProgressIndicator(
              value: state.totalPages > 0
                  ? state.imagesGenerated / state.totalPages
                  : null,
            ),
          if (busy)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(state.statusMessage,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: story.pages.length,
              itemBuilder: (ctx, i) {
                final page = story.pages[i];
                final imgBytes = state.pageImages[page.page];
                return _PageImageCard(
                  page: page,
                  imageBytes: imgBytes != null ? Uint8List.fromList(imgBytes) : null,
                  onRegenerate: busy
                      ? null
                      : () => state.regeneratePageImage(page.page, page.text),
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
            onPressed: busy ? null : () => _exportStory(context, state, story),
            icon: const Icon(Icons.ios_share),
            label: const Text('Export Story'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportStory(
    BuildContext context,
    AppState state,
    Story story,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final slug = story.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '-');
      final storyDir = Directory('${dir.path}/$slug');
      await storyDir.create(recursive: true);

      // Write story.json
      final pages = <Map<String, dynamic>>[];
      final xFiles = <XFile>[];

      for (final page in story.pages) {
        final imgBytes = state.pageImages[page.page];
        final imgFilename = 'page-${page.page.toString().padLeft(2, '0')}.png';
        final imgPath = '${storyDir.path}/$imgFilename';
        if (imgBytes != null) {
          await File(imgPath).writeAsBytes(imgBytes);
          xFiles.add(XFile(imgPath, mimeType: 'image/png'));
        }
        pages.add({'page': page.page, 'text': page.text, 'image': imgFilename});
      }

      final storyJsonPath = '${storyDir.path}/story.json';
      // Write a minimal JSON representation
      final jsonContent = '{\n'
          '  "title": "${story.title}",\n'
          '  "slug": "$slug",\n'
          '  "pages": ${pages.map((p) => '{"page":${p["page"]},"text":"${p["text"]}","image":"${p["image"]}"}'  ).toList()}\n'
          '}';
      final storyJsonFile = await File(storyJsonPath).writeAsString(jsonContent);
      xFiles.insert(0, XFile(storyJsonFile.path, mimeType: 'application/json'));

      await SharePlus.instance.share(
        ShareParams(
          files: xFiles,
          subject: story.title,
          text: 'Story: ${story.title}',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Image card
// ---------------------------------------------------------------------------

class _PageImageCard extends StatelessWidget {
  final StoryPage page;
  final Uint8List? imageBytes;
  final VoidCallback? onRegenerate;

  const _PageImageCard({
    required this.page,
    required this.imageBytes,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFFA8C4E0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image, size: 36, color: Colors.white54),
                        const SizedBox(height: 4),
                        Text('Page ${page.page}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              page.text,
              style: const TextStyle(fontSize: 11),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onRegenerate,
            child: Text('Regenerate ${page.page}',
                style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
