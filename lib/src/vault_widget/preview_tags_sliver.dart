// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:collection/collection.dart';
import 'package:dart_casing/dart_casing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/widgets/tag_value_editor.dart';

class PreviewTagsSliver extends StatelessWidget {
  final Set<String> selected;
  final Map<int, TagTypeValuePair> tags;
  const PreviewTagsSliver(this.tags, this.selected, {super.key});

  @override
  Widget build(BuildContext context) {
    final categorized = groupBy(
      tags.entries.sorted(
          (a, b) => a.value.tagType.name.compareTo(b.value.tagType.name)),
      (entry) => entry.value.tagType.category,
    );
    final categories = categorized.keys.toList()..sort();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: _previewTagsSliver(categorized, categories),
    );
  }

  Widget _previewTagsSliver(
      Map<String, List<MapEntry<int, TagTypeValuePair>>> categorized,
      List<String> categories) {
    return SliverList.separated(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final flags = groupBy(
          categorized[category]!,
          (entry) => entry.value.tagType.isFlag,
        );
        return _previewTagItem(
            category, flags[true] ?? [], flags[false] ?? [], context);
      },
      separatorBuilder: (context, index) => const Divider(),
    );
  }

  Column _previewTagItem(
      String category,
      List<MapEntry<int, TagTypeValuePair>> flags,
      List<MapEntry<int, TagTypeValuePair>> valueTags,
      BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              Casing.titleCase(category),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (flags.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 8,
            runSpacing: 8,
            children: flags
                .map(
                  (entry) => Opacity(
                    opacity: entry.value.partial ? 0.5 : 1,
                    child: RawChip(
                      visualDensity: VisualDensity.compact,
                      key: ValueKey(entry.key),
                      label: Text(entry.value.tagType.name),
                      onDeleted: () => context.read<VaultCubit>().removeTag(
                            tagId: entry.key,
                            from: selected,
                          ),
                      deleteButtonTooltipMessage: '',
                    ),
                  ),
                )
                .toList(),
          ),
        ...valueTags.map(
          (entry) => TagValueEditor(
            entry.value,
            key: ValueKey(
              Object.hashAll([
                entry.value.tagType,
                entry.value.partial,
                entry.value.tagValue?.whichValue(),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
