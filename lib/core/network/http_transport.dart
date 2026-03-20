import 'package:dio/dio.dart';

import 'auth.dart';

class HttpTextResponse {
  const HttpTextResponse({
    required this.statusCode,
    required this.body,
    this.contentType,
  });

  final int statusCode;
  final String body;
  final String? contentType;
}

abstract class HttpTransport {
  Future<HttpTextResponse> get(
    Uri uri, {
    String? username,
    String? password,
    Map<String, String>? headers,
  });
}

class DioHttpTransport implements HttpTransport {
  DioHttpTransport({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<HttpTextResponse> get(
    Uri uri, {
    String? username,
    String? password,
    Map<String, String>? headers,
  }) async {
    final merged = <String, String>{
      ...buildBasicAuthHeaders(username: username, password: password),
      ...?headers,
    };

    final response = await _dio.getUri<String>(
      uri,
      options: Options(
        headers: merged,
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    return HttpTextResponse(
      statusCode: response.statusCode ?? 500,
      body: response.data ?? '',
      contentType: response.headers.value('content-type'),
    );
  }
}
