import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/add_server_controller.dart';

class AddServerScreen extends ConsumerStatefulWidget {
  const AddServerScreen({super.key});

  @override
  ConsumerState<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends ConsumerState<AddServerScreen> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addServerControllerProvider);
    final controller = ref.read(addServerControllerProvider.notifier);
    final isTesting = state.status == AddServerStatus.testing;
    final isSaving = state.status == AddServerStatus.saving;
    final isBusy = isTesting || isSaving;

    ref.listen<AddServerState>(addServerControllerProvider, (_, next) {
      if (next.status == AddServerStatus.saved) {
        context.go('/library');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Add Server')),
      body: ListView(
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
            decoration: const InputDecoration(labelText: 'Password (optional)'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isBusy
                ? null
                : () {
                    controller.testConnection(
                      name: _nameController.text,
                      url: _urlController.text,
                      username: _usernameController.text,
                      password: _passwordController.text,
                    );
                  },
            child: Text(isTesting ? 'Testing...' : 'Test Connection'),
          ),
          const SizedBox(height: 16),
          if (state.status == AddServerStatus.success) ...[
            Text(
              'Connected. Detected ${state.detectedVersion?.name}.',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isBusy
                  ? null
                  : () {
                      controller.saveServer(
                        name: _nameController.text,
                        url: _urlController.text,
                        username: _usernameController.text,
                        password: _passwordController.text,
                      );
                    },
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isSaving ? 'Saving...' : 'Save Server'),
            ),
          ] else if (state.errorMessage != null)
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
