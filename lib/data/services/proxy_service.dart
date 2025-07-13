import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ProxyService {
  static const String proxyHost = '56.228.11.165';
  static const int proxyPort = 3001;
  static const String proxyBaseUrl = 'http://$proxyHost:$proxyPort';
  
  final http.Client _client;
  final Logger _logger = Logger();

  ProxyService({http.Client? client}) : _client = client ?? http.Client();

  /// Make a GET request through the AWS EC2 proxy for PlanAPI
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      // Build the proxy URL
      final proxyUrl = Uri.parse('$proxyBaseUrl/api/planapi$endpoint');
      
      // Add query parameters if provided
      final finalUrl = queryParameters != null 
          ? proxyUrl.replace(queryParameters: queryParameters)
          : proxyUrl;

      _logger.d('Making proxy request to: $finalUrl');

      // Default headers
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Merge with provided headers
      final finalHeaders = {...defaultHeaders, ...?headers};

      // Make the request through proxy
      final response = await _client.get(
        finalUrl,
        headers: finalHeaders,
      ).timeout(timeout);

      _logger.d('Proxy response status: ${response.statusCode}');
      _logger.d('Proxy response body: ${response.body}');

      return response;
    } catch (e) {
      _logger.e('Proxy request failed: $e');
      rethrow;
    }
  }

  /// Make a GET request through the AWS EC2 proxy for Robotics Exchange API
  Future<http.Response> getRoboticsExchange(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      // Build the proxy URL for Robotics Exchange
      final proxyUrl = Uri.parse('$proxyBaseUrl/api/robotics$endpoint');
      
      // Add query parameters if provided
      final finalUrl = queryParameters != null 
          ? proxyUrl.replace(queryParameters: queryParameters)
          : proxyUrl;

      _logger.d('Making Robotics Exchange proxy request to: $finalUrl');

      // Default headers
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Merge with provided headers
      final finalHeaders = {...defaultHeaders, ...?headers};

      // Make the request through proxy
      final response = await _client.get(
        finalUrl,
        headers: finalHeaders,
      ).timeout(timeout);

      _logger.d('Robotics Exchange proxy response status: ${response.statusCode}');
      _logger.d('Robotics Exchange proxy response body: ${response.body}');

      return response;
    } catch (e) {
      _logger.e('Robotics Exchange proxy request failed: $e');
      rethrow;
    }
  }

  /// Test the proxy connection
  Future<bool> testConnection() async {
    try {
      final response = await _client.get(
        Uri.parse('$proxyBaseUrl/health'),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Proxy connection test failed: $e');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
} 