import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

abstract class EpubSource {
  EpubSource();
  Future<Uint8List> getData();
}

class UrlEpubSource extends EpubSource {
  final String webUrl;
  final Map<String, String>? headers;

  UrlEpubSource({required this.webUrl, this.headers});

  Future<Response<List<int>>> _fetchFile() async {
    try {
      Dio dio = Dio();
      return await dio.get<List<int>>(
        webUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
        ),
      );
    } catch (e) {
      throw Exception('Failed to fetch file: $e');
    }
  }

  @override
  Future<Uint8List> getData() async {
    final response = await _fetchFile();
    return UInt8EpubSource(
      data: Uint8List.fromList(response.data!),
    ).getData();
  }

  String getHeaders() {
    return jsonEncode(headers ?? {});
  }
}

class UInt8EpubSource extends EpubSource {
  final Uint8List data;

  UInt8EpubSource({required this.data});

  @override
  Future<Uint8List> getData() async {
    return data;
  }
}

class AssetEpubSource extends EpubSource {
  final String assetPath;
  late UInt8EpubSource source;

  AssetEpubSource({required this.assetPath});

  @override
  Future<Uint8List> getData() async {
    final byteData = await rootBundle.load(assetPath);
    source = UInt8EpubSource(data: byteData.buffer.asUint8List());
    return await source.getData();
  }
}
