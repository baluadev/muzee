import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:muzee/core/utils.dart';
import 'package:muzee/models/user.dart';

class ApiNetwork {
  static final ApiNetwork instance = ApiNetwork._init();

  ApiNetwork._init();

  Dio? _dio;

  User? user;

  Dio get dio {
    if (_dio != null) return _dio!;
    return _dio = Dio();
  }

  void updateHeader() {
    // if (user != null) {
    //   dio.options.headers.addAll({
    //     'Authorization': 'Bearer ${user?.accessToken}',
    //   });
    // } else {
    //   dio.options.headers.remove('Authorization');
    // }

    dio.options.headers.addAll({'Content-Type': 'application/json'});
    // dio.options.headers.addAll({'x-app': 'upbeat'});
  }

  Future _handleResponse(Response response) async {
    // debugPrint('respones ${response.data}');
    if (response.statusCode == 200) {
      return response.data;
    }
    Utils.showToast('Error');
    return null;
  }

  Future get(
    String url, {
    Map<String, dynamic>? queries,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    updateHeader();
    debugPrint('$url, body $queries ${instance.dio.options.headers}');
    final response = await instance.dio.get(
      url,
      queryParameters: queries,
    );
    return await _handleResponse(response);
  }

  Future post(
    String url, {
    dynamic body,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    updateHeader();
    debugPrint('$url, $body');
    final response = await instance.dio.post(
      url,
      data: body,
      onSendProgress: onSendProgress,
      onReceiveProgress: onSendProgress,
    );
    return await _handleResponse(response);
  }

  Future put(
    String url, {
    dynamic body,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    updateHeader();
    debugPrint('$url, body $body');

    final response = await instance.dio.put(
      url,
      data: body,
      onSendProgress: onSendProgress,
      onReceiveProgress: onSendProgress,
    );
    return await _handleResponse(response);
  }

  Future delete(String url, {Map<String, dynamic>? body}) async {
    updateHeader();
    debugPrint('$url, body $body');
    final response = await instance.dio.delete(url, data: body);
    return await _handleResponse(response);
  }

  Future getIp() async {
    final data = await get('https://api.ipify.org/');
    debugPrint('getIp : $data');
    return data;
  }
}
