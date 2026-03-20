import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/database.dart';

import '../../settings/providers/app_preferences_provider.dart';
import '../data/server_repository.dart';

class EditServerScreen extends ConsumerStatefulWidget {
  const EditServerScreen({required this.serverId, super.key});

  final int serverId;

  @override
  ConsumerState<EditServerScreen> createState() => _EditServerScreenState();
}

class _EditServerScreenState extends ConsumerState<EditServerScreen> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSaving = false;
  bool _initializedFromServer = false;
  ReadingDirectionPreference _readingDirection =
      ReadingDirectionPreference.ltr;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save(ServerRecord server) async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final newPassword = _passwordController.text;

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server name and URL are required.')),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    final isValidScheme = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    if (!isValidScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid http(s) URL.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(serverRepositoryProvider).updateServerConnection(
            serverId: server.id,
            name: name,
            url: url,
            username: username.isEmpty ? null : username,
            password: newPassword.isEmpty ? null : newPassword,
            opdsVersion: server.opdsVersion,
          );
      await ref
          .read(appPreferencesProvider.notifier)
          .setServerReadingDirection(server.id, _readingDirection);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated ${server.name}.')),
      );
      context.go('/settings');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update server: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appPreferences = ref.watch(appPreferencesProvider);
    final serversAsync = ref.watch(savedServersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Server')),
      body: serversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (servers) {
          final server = servers.where((s) => s.id == widget.serverId).firstOrNull;
          if (server == null) {
            return const Center(child: Text('Server not found.'));
          }

          if (!_initializedFromServer) {
            _nameController.text = server.name;
            _urlController.text = server.url;
            _usernameController.text = server.username ?? '';
            _readingDirection = appPreferences.serverReadingDirections[server.id] ??
                appPreferences.readingDirection;
            _initializedFromServer = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Server name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (leave blank to keep current)',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reading direction',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<ReadingDirectionPreference>(
                segments: const [
                  ButtonSegment(
                    value: ReadingDirectionPreference.ltr,
                    icon: Icon(Icons.format_textdirection_l_to_r),
                    label: Text('LTR'),
                  ),
                  ButtonSegment(
                    value: ReadingDirectionPreference.rtl,
                    icon: Icon(Icons.format_textdirection_r_to_l),
                    label: Text('RTL'),
                  ),
                ],
                selected: {_readingDirection},
                onSelectionChanged: (selection) {
                  setState(() {
                    _readingDirection = selection.first;
                  });
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : () => _save(server),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}