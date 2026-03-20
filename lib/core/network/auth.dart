import 'dart:convert';

Map<String, String> buildBasicAuthHeaders({
  String? username,
  String? password,
}) {
  if (username == null || username.isEmpty) return const {};
  final credentials = base64Encode(utf8.encode('$username:${password ?? ''}'));
  return {'Authorization': 'Basic $credentials'};
}
