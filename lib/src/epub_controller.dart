import 'dart:async';

import 'package:flutter_epub_viewer/src/helper.dart';
import 'package:flutter_epub_viewer/src/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class EpubController {
  InAppWebViewController? webViewController;

  ///List of chapters from epub
  List<EpubChapter> chapters = [];

  setWebViewController(InAppWebViewController controller) {
    webViewController = controller;
  }

  ///Move epub view to specific area using Cfi string or chapter href
  display({
    ///Cfi String of the desired location, also accepts chapter href
    required String cfi,
  }) {
    checkEpubLoaded();
    webViewController?.evaluateJavascript(source: 'toCfi("$cfi")');
  }

  ///Moves to next page in epub view
  next() {
    checkEpubLoaded();
    webViewController?.evaluateJavascript(source: 'next()');
  }

  ///Moves to previous page in epub view
  prev() {
    checkEpubLoaded();
    webViewController?.evaluateJavascript(source: 'previous()');
  }

  ///Returns current location of epub viewer
  Future<EpubLocation> getCurrentLocation() async {
    checkEpubLoaded();
    final result = await webViewController?.evaluateJavascript(
        source: 'getCurrentLocation()');

    if (result == null) {
      throw Exception("Epub locations not loaded");
    }

    Map<String, dynamic> specificMap = Map<String, dynamic>.from(result);

    return EpubLocation.fromJson(specificMap);
  }

  ///Returns list of [EpubChapter] from epub,
  /// should be called after onChaptersLoaded callback, otherwise returns empty list
  List<EpubChapter> getChapters() {
    checkEpubLoaded();
    return chapters;
  }

  ///Parsing chapters list form epub
  Future<List<EpubChapter>> parseChapters() async {
    if (chapters.isNotEmpty) return chapters;
    checkEpubLoaded();
    try{
      final result = await webViewController!.evaluateJavascript(source: 'getChapters()');
      // Asumimos que result es una lista directa de mapas
      List<dynamic> jsonResponse = result as List<dynamic>;

      // Convertir cada objeto en `jsonResponse` a un `Map<String, dynamic>`
      List<Map<String, dynamic>> convertedResponse = jsonResponse.map((e) {
        if (e is Map<Object?, Object?>) {
          // Convertir el mapa genérico a Map<String, dynamic>
          return Map<String, dynamic>.from(e);
        } else {
          throw Exception('Expected a Map but got ${e.runtimeType}');
        }
      }).toList();

      // Convertir la lista de mapas a una lista de objetos EpubChapter
      chapters = List<EpubChapter>.from(
          convertedResponse.map((e) => EpubChapter.fromJson(e))
      );
      return chapters;
    } catch(e){
      var error = e;
      print(e);
      return [];
    }

  }


  Completer searchResultCompleter = Completer<List<EpubSearchResult>>();

  ///Search in epub using query string
  ///Returns a list of [EpubSearchResult]
  Future<List<EpubSearchResult>> search({
    ///Search query string
    required String query,
    // bool optimized = false,
  }) async {
    searchResultCompleter = Completer<List<EpubSearchResult>>();
    if (query.isEmpty) return [];
    checkEpubLoaded();
    await webViewController?.evaluateJavascript(
        source: 'searchInBook("$query")');
    return await searchResultCompleter.future;
  }

  ///Adds a highlight to epub viewer
  addHighlight({
    ///Cfi string of the desired location
    required String cfi,

    ///Color of the highlight
    Color color = Colors.yellow,

    ///Opacity of the highlight
    double opacity = 0.3,
  }) {
    var colorHex = color.toHex();
    var opacityString = opacity.toString();
    checkEpubLoaded();
    webViewController?.evaluateJavascript(
        source: 'addHighlight("$cfi", "$colorHex", "$opacityString")');
  }

    ///Adds a note to epub viewer
  addNote({
    ///Cfi string of the desired location
    required String cfi,

    ///Color of the highlight
    Color color = Colors.blue,

    ///Opacity of the highlight
    double opacity = 0.3,
  }) {
    var colorHex = color.toHex();
    var opacityString = opacity.toString();
    checkEpubLoaded();
    webViewController?.evaluateJavascript(
        source: 'addHighlight("$cfi", "$colorHex", "$opacityString")');
  }

  ///Removes a highlight from epub viewer
  removeHighlight({required String cfi}) {
    checkEpubLoaded();
    webViewController?.evaluateJavascript(source: 'removeHighlight("$cfi")');
  }

  ///Set [EpubSpread] value
  setSpread({required EpubSpread spread}) async {
    await webViewController?.evaluateJavascript(source: 'setSpread("$spread")');
  }

  ///Set [EpubFlow] value
  setFlow({required EpubFlow flow}) async {
    await webViewController?.evaluateJavascript(source: 'setFlow("$flow")');
  }

  moveInitialScroll(int pixels) async {
    await webViewController?.evaluateJavascript(source: 'scrollByTenPixels("$pixels")');
  }

  ///Set [EpubManager] value
  setManager({required EpubManager manager}) async {
    await webViewController?.evaluateJavascript(
        source: 'setManager("$manager")');
  }

  ///Adjust font size in epub viewer
  setFontSize({required int fontSize, required String background, required String colorText}) async {
    await webViewController?.evaluateJavascript(
        source: 'setFontSize("$fontSize", "$background", "$colorText")');
  }

  setTheme({required String background, required String colorText}) {
    checkEpubLoaded();
    webViewController?.evaluateJavascript(source: 'setBackgroundColor("$background", "$colorText")');
  }

  checkEpubLoaded() {
    if (webViewController == null) {
      throw Exception(
          "Epub viewer is not loaded, wait for onEpubLoaded callback");
    }
  }
}

class LocalServerController {
  final InAppLocalhostServer _localhostServer = InAppLocalhostServer(
      documentRoot: 'packages/flutter_epub_viewer/lib/assets/webpage');

  Future<void> initServer() async {
    if (_localhostServer.isRunning()) return;
    await _localhostServer.start();
  }

  Future<void> disposeServer() async {
    if (!_localhostServer.isRunning()) return;
    await _localhostServer.close();
  }
}
