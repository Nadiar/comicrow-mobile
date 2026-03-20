import '../network/http_transport.dart';
import 'models.dart';
import 'opds1_parser.dart';
import 'opds2_parser.dart';

enum OpdsVersion { opds1, opds2, unknown }

class OpdsConnectionException implements Exception {
  const OpdsConnectionException(this.message);

  final String message;

  @override
  String toString() => 'OpdsConnectionException: $message';
}

class OpdsClient {
  OpdsClient({required HttpTransport transport}) : _transport = transport;

  final HttpTransport _transport;
  final Opds1Parser _opds1Parser = const Opds1Parser();
  final Opds2Parser _opds2Parser = const Opds2Parser();

  static const _acceptHeader = {
    'Accept': 'application/opds+json, application/atom+xml, application/xml;q=0.9, */*;q=0.8',
  };

  Future<OpdsVersion> detectVersion(
    Uri baseUri, {
    String? username,
    String? password,
  }) async {
    final response = await _transport.get(
      baseUri,
      username: username,
      password: password,
      headers: _acceptHeader,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpdsConnectionException(
        'Connection failed with status ${response.statusCode}.',
      );
    }

    return _detectVersionFromResponse(response);
  }

  Future<OpdsFeed> fetchFeed(
    Uri feedUri, {
    String? username,
    String? password,
  }) async {
    final response = await _transport.get(
      feedUri,
      username: username,
      password: password,
      headers: _acceptHeader,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpdsConnectionException(
        'Connection failed with status ${response.statusCode}.',
      );
    }

    final version = _detectVersionFromResponse(response);
    switch (version) {
      case OpdsVersion.opds1:
        return _opds1Parser.parseFeed(response.body);
      case OpdsVersion.opds2:
        return _opds2Parser.parseFeed(response.body);
      case OpdsVersion.unknown:
        throw const OpdsConnectionException('Could not detect OPDS feed format.');
    }
  }

  Future<OpdsFeed> fetchRootFeed(
    Uri baseUri, {
    String? username,
    String? password,
  }) {
    return fetchFeed(baseUri, username: username, password: password);
  }

  Future<OpdsFeed> fetchSearch(
    Uri searchUri,
    String query, {
    String? username,
    String? password,
  }) {
    final resolvedUri = resolveSearchUri(searchUri, query);
    return fetchFeed(resolvedUri, username: username, password: password);
  }

  static Uri resolveSearchUri(Uri searchUri, String query) {
    final href = searchUri.toString();
    if (href.contains('{searchTerms}')) {
      final encoded = Uri.encodeQueryComponent(query);
      final resolved = href
          .replaceAll('{?searchTerms}', '?q=$encoded')
          .replaceAll('{searchTerms}', encoded);
      return Uri.parse(resolved);
    }

    final parameters = Map<String, String>.from(searchUri.queryParameters);
    parameters['q'] = query;
    return searchUri.replace(queryParameters: parameters);
  }

  OpdsVersion _detectVersionFromResponse(HttpTextResponse response) {
    final contentType = response.contentType?.toLowerCase() ?? '';
    if (contentType.contains('application/opds+json') ||
        contentType.contains('application/json')) {
      return OpdsVersion.opds2;
    }

    if (contentType.contains('application/atom+xml') ||
        contentType.contains('application/xml') ||
        contentType.contains('text/xml')) {
      return OpdsVersion.opds1;
    }

    final trimmedBody = response.body.trimLeft();
    if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
      return OpdsVersion.opds2;
    }

    if (trimmedBody.startsWith('<')) {
      return OpdsVersion.opds1;
    }

    return OpdsVersion.unknown;
  }
}
