import 'package:collection/collection.dart';
import 'package:dart_casing/dart_casing.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/tag_filter_cubit.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/generated/tagr.pb.dart';

class PreviewPage extends StatelessWidget {
  final String file;
  const PreviewPage({required this.file, super.key});

  @override
  Widget build(BuildContext context) {
    final vaultState = context.watch<VaultCubit>().state;
    if (vaultState is! VaultOpen) {
      throw StateError('PreviewPage requires VaultOpen state');
    }
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: CustomScrollView(slivers: [
        SliverSafeArea(
          sliver: SliverToBoxAdapter(
            child: DismissiblePage(
                onDismissed: Navigator.of(context).pop,
                child: PreviewImage(id: file, vaultState: vaultState)),
          ),
        ),
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: EditPropertiesButtonSliver({file}),
        )),
        PreviewTagsSliver(vaultState.tags({file}), {file}),
      ]),
    );
  }
}

class PreviewImage extends StatelessWidget {
  final String? id;
  final VaultOpen vaultState;
  const PreviewImage({
    this.id,
    required this.vaultState,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: (MediaQuery.of(context).size.height * .8) -
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Hero(
        tag: id ?? 'none',
        child: Image(image: vaultState.imageProvider(id)),
      ),
    );
  }
}

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

class EditPropertiesButtonSliver extends StatefulWidget {
  final Set<String> fileIds;
  const EditPropertiesButtonSliver(this.fileIds, {super.key});

  @override
  State<EditPropertiesButtonSliver> createState() =>
      _EditPropertiesButtonSliverState();
}

class _EditPropertiesButtonSliverState
    extends State<EditPropertiesButtonSliver> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = context.watch<VaultCubit>().state;
    final searchState = context.watch<TagFilterCubit>().state;
    if (vaultState is! VaultOpen) throw StateError('Wrong state');
    if (searchState is FilteringTags) {
      return SliverAppBar(
        title: _searchField(vaultState, context),
        pinned: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: context.read<TagFilterCubit>().done,
            icon: const Icon(Icons.close),
          )
        ],
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.all(8),
        sliver: SliverToBoxAdapter(
          child: OutlinedButton.icon(
            label: const Text('Add Property'),
            icon: const Icon(Icons.add),
            onPressed: context.read<TagFilterCubit>().search,
          ),
        ),
      );
    }
  }

  TextField _searchField(VaultOpen vaultState, BuildContext context) {
    return TextField(
      decoration: const InputDecoration(hintText: 'Filter tags'),
      controller: controller,
      onChanged: (value) => context.read<TagFilterCubit>().search(value),
      onSubmitted: (value) async {
        value = value.trim();
        if (vaultState.tagMap.containsKey(value.toLowerCase())) {
          final tagId = vaultState.tagMap[value]!;
          context.read<VaultCubit>().updateTag(widget.fileIds, tagId);
        } else {
          await context.read<VaultCubit>().createTag(
                name: value,
                fileIds: widget.fileIds,
              );
        }
        controller.clear();
        if (context.mounted) context.read<TagFilterCubit>().search();
      },
    );
  }
}

class TagsSearch extends StatelessWidget {
  final Set<String> fileIds;

  const TagsSearch(this.fileIds, {super.key});

  @override
  Widget build(BuildContext context) {
    final searchState = context.watch<TagFilterCubit>().state;
    final vaultState = context.watch<VaultCubit>().state;
    if (vaultState is! VaultOpen) throw StateError('Wrong state');
    final tags = vaultState.tags(fileIds);
    final filtered = vaultState.vault.tagTypes.entries
        .where((entry) => entry.value.name.contains(searchState.query))
        .sorted((a, b) => a.value.name.compareTo(b.value.name));
    if (searchState is TagFilterDone) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }
    return SliverList.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildTagTypeEntry(tags, filtered[index], context);
      },
    );
  }

  ListTile _buildTagTypeEntry(
    Map<int, TagTypeValuePair> tags,
    MapEntry<int, TagType> entry,
    BuildContext context,
  ) {
    bool? value = tags.containsKey(entry.key);
    if (value && tags[entry.key]!.partial) {
      value = null;
    }

    fn() {
      if (value == true) {
        context
            .read<VaultCubit>()
            .removeTag(from: fileIds, tagId: entry.value.id);
      } else {
        context.read<VaultCubit>().updateTag(fileIds, entry.value.id);
      }
    }

    final icon = value == null
        ? Icons.indeterminate_check_box
        : value
            ? Icons.check_box
            : Icons.check_box_outline_blank;
    return ListTile(
      title: Text(entry.value.name),
      onTap: fn,
      trailing: Icon(icon),
    );
  }
}

class TagValueEditor extends StatefulWidget {
  final TagTypeValuePair typeValuePair;
  const TagValueEditor(this.typeValuePair, {super.key});

  @override
  State<TagValueEditor> createState() => _TagValueEditorState();
}

class _TagValueEditorState extends State<TagValueEditor> {
  final controller = TextEditingController();
  String? errorText;
  TagTypeValuePair get typeValuePair => widget.typeValuePair;

  @override
  void initState() {
    print("initState for TagValueEditor");
    if (typeValuePair.partial) {
      setControllerText(TagValue());
    } else {
      if (typeValuePair.tagValue?.whichValue() == TagValue_Value.notSet) {
        setControllerText(typeValuePair.tagType.defaultValue);
      } else {
        setControllerText(typeValuePair.tagValue);
      }
    }
    super.initState();
  }

  void setControllerText(TagValue? value) {
    controller.text = switch (value?.whichValue()) {
      null => '',
      TagValue_Value.stringValue => value!.stringValue,
      TagValue_Value.intValue => value!.intValue.toString(),
      TagValue_Value.floatValue => value!.floatValue.toString(),
      TagValue_Value.notSet => '',
      _ => 'not implemented',
    };
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool validateText() {
    final text = controller.text;
    setState(() {
      errorText = switch (typeValuePair.tagType.defaultValue.whichValue()) {
        TagValue_Value.boolValue => null,
        TagValue_Value.stringValue => null,
        TagValue_Value.intValue =>
          int.tryParse(text) == null ? 'Invalid int' : null,
        TagValue_Value.floatValue =>
          double.tryParse(text) == null ? 'Invalid float' : null,
        TagValue_Value.listValue => null,
        TagValue_Value.mapValue => null,
        TagValue_Value.notSet => null,
      };
    });
    return errorText == null;
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = context.watch<SelectionCubit>().state;
    return Row(
      children: [
        Text('${typeValuePair.tagType.name}:'),
        const SizedBox(width: 8),
        _buildEditor(context, selectionState.selected),
        if (typeValuePair.tagValue?.whichValue() != TagValue_Value.notSet)
          IconButton(
              onPressed: () async {
                await context.read<VaultCubit>().updateTag(
                      selectionState.selected,
                      typeValuePair.tagType.id,
                      TagValue(),
                    );
                setControllerText(typeValuePair.tagType.defaultValue);
              },
              icon: const Icon(Icons.refresh))
      ],
    );
  }

  Widget _buildEditor(BuildContext context, Set<String> selected) {
    final style = typeValuePair.tagValue?.whichValue() == TagValue_Value.notSet
        ? null
        : const TextStyle(fontWeight: FontWeight.bold);
    final decoration = InputDecoration(
      contentPadding: const EdgeInsets.all(8),
      border: InputBorder.none,
      // hoverColor: Colors.grey[300],
      fillColor: Colors.transparent,
      filled: true,
      errorText: errorText,
    );

    void updater(TagValue value) {
      context.read<VaultCubit>().updateTag(
            selected,
            typeValuePair.tagType.id,
            value,
          );
    }

    return switch (typeValuePair.tagType.defaultValue.whichValue()) {
      TagValue_Value.boolValue => Checkbox(
          value: typeValuePair.tagValue?.boolValue,
          onChanged: (value) => updater(TagValue(boolValue: value)),
          tristate: typeValuePair.tagValue?.boolValue == null,
        ),
      TagValue_Value.stringValue => Expanded(
          child: TextField(
            controller: controller,
            style: style,
            onChanged: (value) => updater(TagValue(stringValue: value)),
            decoration: decoration,
          ),
        ),
      TagValue_Value.intValue => Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: false,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9-]')),
            ],
            style: style,
            decoration: decoration,
            onChanged: (value) {
              if (validateText()) {
                updater(TagValue(intValue: int.parse(value)));
              }
            },
          ),
        ),
      TagValue_Value.floatValue => Expanded(
          child: TextField(
            controller: controller,
            decoration: decoration,
            style: style,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
            ],
            onChanged: (value) {
              if (validateText()) {
                updater(TagValue(floatValue: double.parse(value)));
              }
            },
          ),
        ),
      TagValue_Value.listValue =>
        Text(typeValuePair.tagValue?.listValue.toString() ?? '[]'),
      TagValue_Value.mapValue =>
        Text(typeValuePair.tagValue?.mapValue.toString() ?? '{}'),
      TagValue_Value.notSet => throw UnimplementedError(),
    };
  }
}
