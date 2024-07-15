import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter/material.dart';

class ChapterDrawer extends StatefulWidget {
  const ChapterDrawer({super.key, required this.controller, this.onSelect});

  final EpubController controller;
  final Function(EpubChapter chapter)? onSelect;

  @override
  State<ChapterDrawer> createState() => _ChapterDrawerState();
}

class _ChapterDrawerState extends State<ChapterDrawer> {
  late List<EpubChapter> chapters;

  @override
  void initState() {
    chapters = widget.controller.getChapters();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: _buildChapterList(chapters, 0),
      ),
    );
  }

  List<Widget> _buildChapterList(List<EpubChapter> chapters, int depth) {
    List<Widget> chapterWidgets = [];
    for (var chapter in chapters) {
      chapterWidgets.add(Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: depth * 16.0),
            child: ListTile(
              title: Text(chapter.title),
              onTap: () {
                if (widget.onSelect != null) {
                  widget.onSelect!(chapter);
                }
                Navigator.pop(context);
              },
            ),
          ),
          if (depth == 0) const Divider(),
        ],
      ));
      if (chapter.subitems.isNotEmpty) {
        chapterWidgets.addAll(_buildChapterList(chapter.subitems, depth + 1));
      }
    }
    return chapterWidgets;
  }
}
