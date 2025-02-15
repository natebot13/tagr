// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/plugin_cubit.dart';

class TagImportDialog extends StatefulWidget {
  final Set<String> fileIds;
  const TagImportDialog(
    this.fileIds, {
    super.key,
  });

  @override
  State<TagImportDialog> createState() => _TagImportDialogState();
}

class _TagImportDialogState extends State<TagImportDialog> {
  final files = <String, bool>{};
  final tags = <String, bool>{};
  bool loading = false;

  @override
  void initState() {
    for (final id in widget.fileIds) {
      files[id] = true;
    }
    super.initState();
  }

  Future<void> lookupTags(PluginsLoaded pluginState) async {
    setState(() {
      loading = true;
    });

    final picked = files.keys.where((file) => files[file]!).toSet();
    final fileTags = <String, Set<String>>{};
    for (final plugin in pluginState.plugins.values) {
      for (final file in picked) {
        fileTags[file] = await plugin.searchTags(file);
      }
    }

    final overlapping = fileTags.values.fold(
      fileTags.values.firstOrNull ?? {},
      (result, s) => result.intersection(s),
    );

    setState(() {
      loading = false;
      for (final tag in overlapping) {
        tags[tag] ??= false;
      }
    });
  }

  void enableFile(String name, bool value) {
    setState(() {
      files[name] = value;
    });
  }

  void enableTag(String name, bool value) {
    setState(() {
      tags[name] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: NamedCheckboxes(
                      picked: files,
                      onChanged: enableFile,
                    ),
                  ),
                  BlocBuilder<PluginCubit, PluginState>(
                    builder: (context, state) {
                      return FilledButton(
                        onPressed: state is! PluginsLoaded || loading
                            ? null
                            : () => lookupTags(state),
                        child: const Text("Search"),
                      );
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: Column(children: [
                Expanded(
                  child: NamedCheckboxes(
                    picked: tags,
                    onChanged: enableTag,
                  ),
                ),
                FilledButton(
                  onPressed: () {},
                  child: const Text("Import"),
                )
              ]),
            )
          ],
        ),
      ),
    );
  }
}

class NamedCheckboxes extends StatelessWidget {
  final Map<String, bool> picked;
  final void Function(String, bool) onChanged;
  const NamedCheckboxes({
    super.key,
    required this.picked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: picked.keys
          .map((id) => Row(
                children: [
                  Expanded(child: Text(id)),
                  Checkbox(
                    value: picked[id],
                    onChanged: (value) => onChanged(id, value!),
                  )
                ],
              ))
          .toList(),
    );
  }
}
