import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/profile.dart';
import '../models/style_template.dart';
import '../providers/app_state.dart';
import '../services/vocab_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _childNameCtrl;
  late TextEditingController _favCharCtrl;
  late TextEditingController _themeCtrl;
  late TextEditingController _storyCharCtrl;
  late TextEditingController _sightWordsCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _styleGuideCtrl;
  late TextEditingController _templateNameCtrl;

  bool _apiKeyObscured = true;
  String _selectedTemplate = 'Watercolor';

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _childNameCtrl = TextEditingController(text: state.profile.childName);
    _favCharCtrl = TextEditingController(text: state.profile.favoriteCharacter);
    _themeCtrl = TextEditingController(text: state.theme);
    _storyCharCtrl = TextEditingController(text: state.storyCharacterOverride);
    _sightWordsCtrl = TextEditingController(text: state.sightWordsRaw);
    _apiKeyCtrl = TextEditingController(text: state.apiKey);
    _styleGuideCtrl = TextEditingController(text: state.styleGuide);
    _templateNameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in [
      _childNameCtrl, _favCharCtrl, _themeCtrl, _storyCharCtrl,
      _sightWordsCtrl, _apiKeyCtrl, _styleGuideCtrl, _templateNameCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
    final state = context.read<AppState>();

    // Flush text field values into state
    state.profile = state.profile.copyWith(
      childName: _childNameCtrl.text.trim(),
      favoriteCharacter: _favCharCtrl.text.trim(),
    );
    state.theme = _themeCtrl.text.trim();
    state.storyCharacterOverride = _storyCharCtrl.text.trim();
    state.sightWordsRaw = _sightWordsCtrl.text;
    await state.updateApiKey(
      _apiKeyCtrl.text.trim(),
      remember: state.rememberKey,
    );
    await state.saveStyleGuide(_styleGuideCtrl.text.trim());

    await state.generateStory();

    if (!mounted) return;
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pushNamed(context, '/story');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final busy = state.status == GenerationStatus.generatingText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Generator'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              title: 'Profile',
              children: [
                _field('Child\'s name', _childNameCtrl),
                _field('Favorite characters', _favCharCtrl),
                const SizedBox(height: 8),
                Text('Phonics level', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: state.profile.phonicsLevel,
                  items: kPhonicsLevels
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      state.profile = state.profile.copyWith(phonicsLevel: v);
                    }
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: () => state.saveProfile(state.profile.copyWith(
                      childName: _childNameCtrl.text.trim(),
                      favoriteCharacter: _favCharCtrl.text.trim(),
                    )),
                    child: const Text('Save Profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Story Spec',
              children: [
                _field('Theme / topic', _themeCtrl),
                _field('Character in story', _storyCharCtrl,
                    hint: 'Default: profile favorite'),
                _field('Sight words (comma-separated)', _sightWordsCtrl),
                const SizedBox(height: 8),
                Text('Page count: ${state.pageCount}',
                    style: Theme.of(context).textTheme.labelLarge),
                Slider(
                  value: state.pageCount.toDouble(),
                  min: 4,
                  max: 8,
                  divisions: 4,
                  label: '${state.pageCount}',
                  onChanged: (v) => state.pageCount = v.round(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'API Key',
              children: [
                TextField(
                  controller: _apiKeyCtrl,
                  obscureText: _apiKeyObscured,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_apiKeyObscured
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _apiKeyObscured = !_apiKeyObscured),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Remember key (Keystore)'),
                  value: state.rememberKey,
                  onChanged: (v) => state.updateApiKey(
                    _apiKeyCtrl.text.trim(),
                    remember: v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StyleGuideCard(
              styleGuideCtrl: _styleGuideCtrl,
              templateNameCtrl: _templateNameCtrl,
              selectedTemplate: _selectedTemplate,
              onTemplateSelected: (name) {
                final text = state.styleTemplates[name];
                if (text != null) {
                  setState(() {
                    _selectedTemplate = name;
                    _styleGuideCtrl.text = text;
                    _templateNameCtrl.text = name;
                  });
                }
              },
              onSaveTemplate: (name, text) => state.saveUserTemplate(name, text),
              onDeleteTemplate: (name) => state.deleteUserTemplate(name),
              templates: state.styleTemplates,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: busy ? null : _generate,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_stories),
              label: Text(busy ? state.statusMessage : 'Generate Story'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Style Guide card with template support
// ---------------------------------------------------------------------------

class _StyleGuideCard extends StatelessWidget {
  final TextEditingController styleGuideCtrl;
  final TextEditingController templateNameCtrl;
  final String selectedTemplate;
  final ValueChanged<String> onTemplateSelected;
  final Future<void> Function(String name, String text) onSaveTemplate;
  final Future<void> Function(String name) onDeleteTemplate;
  final Map<String, String> templates;

  const _StyleGuideCard({
    required this.styleGuideCtrl,
    required this.templateNameCtrl,
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.onSaveTemplate,
    required this.onDeleteTemplate,
    required this.templates,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Image Style Guide',
      children: [
        // Template selector
        Text('Template', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: templates.containsKey(selectedTemplate)
                    ? selectedTemplate
                    : templates.keys.firstOrNull,
                items: templates.keys
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) { if (v != null) onTemplateSelected(v); },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: styleGuideCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Style description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        // Save-as template row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: templateNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Save as template…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () {
                final name = templateNameCtrl.text.trim();
                final text = styleGuideCtrl.text.trim();
                if (name.isEmpty || text.isEmpty) return;
                onSaveTemplate(name, text);
              },
              child: const Text('Save'),
            ),
            const SizedBox(width: 4),
            OutlinedButton(
              onPressed: () {
                final name = templateNameCtrl.text.trim();
                if (name.isEmpty || kBuiltinTemplates.containsKey(name)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(name.isEmpty
                          ? 'Enter a template name.'
                          : '"$name" is a built-in and cannot be deleted.'),
                    ),
                  );
                  return;
                }
                onDeleteTemplate(name);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable section card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}
