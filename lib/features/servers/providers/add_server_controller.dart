import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/http_transport.dart';
import '../../../core/opds/opds_client.dart';
import '../../settings/providers/app_preferences_provider.dart';
import '../data/server_repository.dart';

enum AddServerStatus { idle, testing, success, failure, saving, saved }

class AddServerState {
  const AddServerState({
    this.status = AddServerStatus.idle,
    this.detectedVersion,
    this.errorMessage,
  });

  final AddServerStatus status;
  final OpdsVersion? detectedVersion;
  final String? errorMessage;

  AddServerState copyWith({
    AddServerStatus? status,
    OpdsVersion? detectedVersion,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddServerState(
      status: status ?? this.status,
      detectedVersion: detectedVersion ?? this.detectedVersion,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final httpTransportProvider = Provider<HttpTransport>((ref) {
  return DioHttpTransport();
});

final opdsClientProvider = Provider<OpdsClient>((ref) {
  return OpdsClient(transport: ref.watch(httpTransportProvider));
});

final addServerControllerProvider =
    NotifierProvider.autoDispose<AddServerController, AddServerState>(
      AddServerController.new,
    );

class AddServerController extends Notifier<AddServerState> {
  late final OpdsClient _opdsClient;
  late final ServerRepository _repository;
  late final Future<void> Function(int?) _setActiveServerId;

  @override
  AddServerState build() {
    _opdsClient = ref.watch(opdsClientProvider);
    _repository = ref.watch(serverRepositoryProvider);
    _setActiveServerId = ref.watch(appPreferencesProvider.notifier).setActiveServerId;
    return const AddServerState();
  }

  Future<void> testConnection({
    required String name,
    required String url,
    String? username,
    String? password,
  }) async {
    if (name.trim().isEmpty || url.trim().isEmpty) {
      state = state.copyWith(
        status: AddServerStatus.failure,
        errorMessage: 'Server name and URL are required.',
        clearError: false,
      );
      return;
    }

    final uri = Uri.tryParse(url.trim());
    final isValidScheme = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isValidScheme) {
      state = state.copyWith(
        status: AddServerStatus.failure,
        errorMessage: 'Please enter a valid http(s) URL.',
      );
      return;
    }

    state = state.copyWith(status: AddServerStatus.testing, clearError: true);

    try {
      final version = await _opdsClient.detectVersion(
        uri,
        username: username,
        password: password,
      );

      state = state.copyWith(
        status: AddServerStatus.success,
        detectedVersion: version,
        clearError: true,
      );
    } on OpdsConnectionException catch (exception) {
      state = state.copyWith(
        status: AddServerStatus.failure,
        errorMessage: exception.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: AddServerStatus.failure,
        errorMessage: 'Failed to connect to OPDS server.',
      );
    }
  }

  Future<void> saveServer({
    required String name,
    required String url,
    String? username,
    String? password,
  }) async {
    final version = state.detectedVersion ?? OpdsVersion.unknown;
    state = state.copyWith(status: AddServerStatus.saving);
    try {
      final record = await _repository.saveServer(
        name: name.trim(),
        url: url.trim(),
        username: username?.trim().isNotEmpty == true ? username!.trim() : null,
        password: password?.isNotEmpty == true ? password : null,
        opdsVersion: version.name,
      );
      await _setActiveServerId(record.id);
      state = state.copyWith(status: AddServerStatus.saved);
    } catch (_) {
      state = state.copyWith(
        status: AddServerStatus.failure,
        errorMessage: 'Failed to save server.',
      );
    }
  }
}
