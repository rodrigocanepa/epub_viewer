import 'dart:developer';
import 'dart:typed_data';

import 'package:example/page_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:example/chapter_drawer.dart';
import 'package:example/search_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Epub Viewer Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final epubController = EpubController();

  var textSelectionCfi = '';
  var textSelectionText = '';

  String selectedSource = 'Asset';
  String filePath = '';
  late Uint8List file;
  double _currentSliderValue = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: ChapterDrawer(
        controller: epubController,
        onSelect: (chapter) {
          epubController.display(cfi: chapter.href);
        },
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SearchPage(
                            epubController: epubController,
                            onListItemTap: (i) {
                              print(i);
                              epubController.display(cfi: i.cfi);
                            },
                          )));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (String value) async {
              if (value == 'File') {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.any,
                  withData: true,
                );
                if (result != null && result.files.first.path != null) {
                  setState(() {
                    file = result.files.first.bytes!;
                    filePath = result.files.first.path!;
                    selectedSource = value;
                  });
                }
              } else {
                setState(() {
                  selectedSource = value;
                });
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                'URL',
                'Asset',
                'File',
              ].map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: EpubViewer(
                epubSource: selectedSource == 'Asset'
                    ? AssetEpubSource(
                        assetPath: 'assets/sources/9780636158764.epub')
                    : selectedSource == 'File' && filePath.isNotEmpty
                        ? UInt8EpubSource(data: file)
                        : UrlEpubSource(
                            webUrl:
                                'https://s3.amazonaws.com/epubjs/books/alice.epub'),
                epubController: epubController,
                displaySettings: EpubDisplaySettings(
                  flow: EpubFlow.paginated,
                  snap: true,
                  allowScriptedContent: true,
                ),
                selectionContextMenu: ContextMenu(
                  menuItems: [
                    ContextMenuItem(
                      title: "Highlight",
                      id: 1,
                      action: () async {
                        epubController.addHighlight(cfi: textSelectionCfi);
                      },
                    ),
                    ContextMenuItem(
                      title: "Copy",
                      id: 2,
                      action: () async {
                        await Clipboard.setData(
                            ClipboardData(text: textSelectionText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Text copied'),
                          ),
                        );
                      },
                    ),
                    ContextMenuItem(
                      title: "Note",
                      id: 3,
                      action: () async {
                        log(textSelectionCfi);
                        log(textSelectionText);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ready to note!'),
                          ),
                        );
                      },
                    ),
                  ],
                  settings: ContextMenuSettings(
                      hideDefaultSystemContextMenuItems: true),
                ),
                onChaptersLoaded: (chapters) {
                  print('onChaptersLoaded');
                },
                onEpubLoaded: () async {
                  print('Epub loaded');
                },
                onRelocated: (value) {
                  print("Relocated to $value");
                },
                onTextSelected: (epubTextSelection) {
                  textSelectionCfi = epubTextSelection.selectionCfi;
                  textSelectionText = epubTextSelection.selectedText;
                },
              ),
            ),
            if (epubController.pages.isNotEmpty)
              PageSelector(
                  startValue: 0,
                  maxValue: epubController.pages.last.page!,
                  onPageChange: (pageNumber) {
                    final page = epubController.pages.firstWhere((p) => p.page == pageNumber);
                    print(page);
                  }),
          ],
        ),
      ),
    );
  }
}
