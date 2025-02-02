// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:pretty_bytes/pretty_bytes.dart';

class FileStatsSliver extends StatelessWidget {
  final Directory root;
  final Set<String> selected;
  const FileStatsSliver(this.root, this.selected, {super.key});

  @override
  Widget build(BuildContext context) {
    final first = selected.firstOrNull;
    if (first == null) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }
    final file = File(path.join(root.path, first));
    return SliverList.list(children: [
      Center(child: SelectableText(selected.join('\n'))),
      const Divider(),
      if (selected.length == 1)
        FutureBuilder(
          future: file.stat(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text("Reading...");
            final stat = snapshot.data!;
            return Column(
              children: [
                Text(prettyBytes(stat.size.toDouble())),
                if (Platform.isWindows)
                  Text(
                    '${Platform.isWindows ? 'Created:' : 'Changed:'} ${stat.changed}',
                  ),
                if (stat.modified != stat.changed)
                  Text('Modified: ${stat.modified}'),
              ],
            );
          },
        ),
      if (selected.length == 1) const Divider()
    ]);
  }
}
