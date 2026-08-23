import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? resolveApiBaseUrl();

  final String baseUrl;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> _headers({bool jsonBody = false, bool auth = true}) {
    final headers = <String, String>{};
    if (jsonBody) headers['Content-Type'] = 'application/json';
    if (auth && _token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  Future<dynamic> _handle(http.Response res) async {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String detail = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['detail'] != null) {
        detail = body['detail'].toString();
      }
    } catch (_) {}
    throw ApiException(detail);
  }

  Future<User> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers(jsonBody: true, auth: false),
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'password': password,
      }),
    );
    final data = await _handle(res) as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<String> login({required String email, required String password}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    final data = await _handle(res) as Map<String, dynamic>;
    return data['access_token'] as String;
  }

  Future<User> me() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers(),
    );
    return User.fromJson(await _handle(res) as Map<String, dynamic>);
  }

  Future<List<Membership>> listOrgs() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/organizations'),
      headers: _headers(),
    );
    final data = await _handle(res) as List<dynamic>;
    return data
        .map((e) => Membership.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Organization> createOrg({
    required String name,
    required String slug,
    String description = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/organizations'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({
        'name': name,
        'slug': slug,
        'description': description,
      }),
    );
    return Organization.fromJson(await _handle(res) as Map<String, dynamic>);
  }

  Future<Organization> getOrg(int orgId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/organizations/$orgId'),
      headers: _headers(),
    );
    return Organization.fromJson(await _handle(res) as Map<String, dynamic>);
  }

  Future<List<QueueInfo>> listQueues(int orgId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/organizations/$orgId/queues'),
      headers: _headers(),
    );
    final data = await _handle(res) as List<dynamic>;
    return data
        .map((e) => QueueInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QueueInfo> createQueue({
    required int orgId,
    required String name,
    required String slug,
    String description = '',
    String ticketPrefix = 'A',
    int avgServiceMinutes = 5,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/organizations/$orgId/queues'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({
        'name': name,
        'slug': slug,
        'description': description,
        'ticket_prefix': ticketPrefix,
        'avg_service_minutes': avgServiceMinutes,
      }),
    );
    return QueueInfo.fromJson(await _handle(res) as Map<String, dynamic>);
  }

  Future<QueueInfo> getQueue(int queueId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/queues/$queueId'),
      headers: _headers(auth: false),
    );
    return QueueInfo.fromJson(await _handle(res) as Map<String, dynamic>);
  }

  Future<QueueInfo> updateQueue(int queueId, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/queues/$queueId'),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body),
    );
    return QueueInfo.fromJson(await _handle(res) as Map<String, dynamic>);
  }

  Future<QueueInfo> getPublicQueue(String orgSlug, String queueSlug) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/public/$orgSlug/$queueSlug'),
      headers: _headers(auth: false),
    );
    return QueueInfo.fromJson(await _handle(res) as Map<String, dynamic>);
  }

  Future<Ticket> joinQueue({
    required String orgSlug,
    required String queueSlug,
    required String customerName,
    String customerPhone = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/public/$orgSlug/$queueSlug/join'),
      headers: _headers(jsonBody: true, auth: false),
      body: jsonEncode({
        'customer_name': customerName,
        'customer_phone': customerPhone,
      }),
    );
    return Ticket.fromJson(await _handle(res) as Map<String, dynamic>);
  }

  Future<List<Ticket>> listTickets(int queueId, {String? statusFilter}) async {
    final query = statusFilter != null ? '?status_filter=$statusFilter' : '';
    final res = await http.get(
      Uri.parse('$baseUrl/api/queues/$queueId/tickets$query'),
      headers: _headers(),
    );
    final data = await _handle(res) as List<dynamic>;
    return data.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Ticket> callNext(int queueId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/queues/$queueId/call-next'),
      headers: _headers(),
    );
    return Ticket.fromJson(await _handle(res) as Map<String, dynamic>);
  }

  Future<Ticket> updateTicketStatus(int ticketId, String status) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/tickets/$ticketId/status'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({'status': status}),
    );
    return Ticket.fromJson(await _handle(res) as Map<String, dynamic>);
  }

  Future<Ticket> getTicket(int ticketId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/tickets/$ticketId'),
      headers: _headers(auth: false),
    );
    return Ticket.fromJson(await _handle(res) as Map<String, dynamic>);
  }

  Future<DashboardStats> insights(int queueId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/queues/$queueId/insights'),
      headers: _headers(),
    );
    return DashboardStats.fromJson(await _handle(res) as Map<String, dynamic>);
  }
}
