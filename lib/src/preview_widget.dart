import 'package:collection/collection.dart';
import 'package:dart_casing/dart_casing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:tagr/cubit/selection_cubit.dart';
import 'package:tagr/cubit/vault_cubit.dart';
import 'package:tagr/src/generated/tagr.pb.dart';

class PreviewWidget extends StatelessWidget {
  const PreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultState = context.watch<VaultCubit>().state;
    if (vaultState is! VaultOpen) return const Text('No vault open');

    final selectionState = context.watch<SelectionCubit>().state;

    final tags = vaultState.tags(selectionState.selected);

    return ResizableContainer(
      direction: Axis.vertical,
      children: [
        ResizableChild(
            child: PreviewImage(selectionState.selected, vaultState)),
        ResizableChild(child: PreviewTags(tags))
      ],
    );
  }
}

class PreviewImage extends StatelessWidget {
  final Set<String> ids;
  final VaultOpen vaultState;
  const PreviewImage(this.ids, this.vaultState, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Image(image: vaultState.imageProvider(ids.singleOrNull)),
        ),
        SelectableText(ids.join(', ')),
      ],
    );
  }
}

class PreviewTags extends StatelessWidget {
  final Map<int, TagTypeValuePair> tags;
  const PreviewTags(this.tags, {super.key});

  @override
  Widget build(BuildContext context) {
    final categorized = groupBy(
      tags.entries.sorted(
          (a, b) => a.value.tagType.name.compareTo(b.value.tagType.name)),
      (entry) => entry.value.tagType.category,
    );
    final categories = categorized.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: categorized.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final flags = groupBy(
                  categorized[category]!,
                  (entry) => entry.value.tagType.isFlag,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                        child: Text(
                          Casing.titleCase(category),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (flags.containsKey(true))
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8,
                        runSpacing: 8,
                        children: flags[true]!
                            .map(
                              (entry) => Chip(
                                key: ValueKey(entry.key),
                                label: Text(entry.value.tagType.name),
                                onDeleted: () =>
                                    context.read<VaultCubit>().removeTag(
                                          tagId: entry.key,
                                          from: entry.value.fileIds,
                                        ),
                                deleteButtonTooltipMessage: '',
                              ),
                            )
                            .toList(),
                      ),
                    if (flags.containsKey(false))
                      ...flags[false]!
                          .map((entry) => TagValueEditor(entry.value)),
                  ],
                );
              },
            ),
          ),
          IconButton(
            onPressed: () => _openTagAdder(context),
            icon: const Icon(Icons.new_label),
          )
        ],
      ),
    );
  }

  void _openTagAdder(BuildContext outerContext) {
    showModalBottomSheet(
      context: outerContext,
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: outerContext.read<VaultCubit>()),
            BlocProvider.value(value: outerContext.read<SelectionCubit>()),
          ],
          child: const TagAdder(),
        );
      },
    );
  }
}

class TagAdder extends StatelessWidget {
  const TagAdder({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultState = context.watch<VaultCubit>().state;
    final selectionState = context.watch<SelectionCubit>().state;

    if (vaultState is! VaultOpen) return const Text('Vault not open');
    final addedTags = vaultState.tags(selectionState.selected);
    final tagsKeySet = addedTags.keys.toSet();

    return ListView(children: [
      ...vaultState.vault.tagTypes.values.map(
        (tagType) => TagTypeListItem(
          fileIds: selectionState.selected,
          tagType: tagType,
          selected: tagsKeySet.contains(tagType.id),
          onTap: () {
            final cubit = context.read<VaultCubit>();
            if (tagsKeySet.contains(tagType.id)) {
              cubit.removeTag(tagId: tagType.id, from: selectionState.selected);
            } else {
              cubit.updateTag(selectionState.selected, tagType.id);
            }
          },
        ),
      ),
      ListTile(
        title: const Text("Create tag"),
        onTap: () => context.read<VaultCubit>().createTag(),
      ),
    ]);
  }
}

class TagTypeListItem extends StatefulWidget {
  final Set<String> fileIds;
  final TagType tagType;
  final bool selected;
  final void Function()? onTap;

  const TagTypeListItem({
    super.key,
    required this.tagType,
    required this.fileIds,
    this.selected = false,
    this.onTap,
  });

  @override
  State<TagTypeListItem> createState() => _TagTypeListItemState();
}

class _TagTypeListItemState extends State<TagTypeListItem> {
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  bool isEditing = false;
  TagType get tagType => widget.tagType;

  @override
  void initState() {
    nameController.text = tagType.name;
    categoryController.text = tagType.category;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: isEditing
                ? TextField(
                    controller: nameController,
                    onSubmitted: (value) {
                      context.read<VaultCubit>().updateTagType(
                            tagType.id,
                            TagType(name: value),
                          );
                      setState(() {
                        isEditing = false;
                      });
                    },
                  )
                : Text(tagType.name),
          ),
          Expanded(
            child: isEditing
                ? TextField(controller: categoryController)
                : Text('Category: ${tagType.category}'),
          ),
          if (isEditing)
            DropdownButton(
              value:
                  tagType.isFlag ? 'flag' : tagType.defaultValue.whichValue(),
              onChanged: (value) {
                if (value is TagValue_Value) {
                  final update =
                      TagType(isFlag: false, defaultValue: TagValue());
                  switch (value) {
                    case TagValue_Value.boolValue:
                      update.defaultValue.boolValue =
                          tagType.defaultValue.boolValue;
                      break;
                    case TagValue_Value.stringValue:
                      update.defaultValue.stringValue =
                          tagType.defaultValue.stringValue;
                      break;
                    case TagValue_Value.intValue:
                      update.defaultValue.intValue =
                          tagType.defaultValue.intValue;
                      break;
                    case TagValue_Value.floatValue:
                      update.defaultValue.floatValue =
                          tagType.defaultValue.floatValue;
                      break;
                    case TagValue_Value.listValue:
                      update.defaultValue.listValue =
                          tagType.defaultValue.listValue;
                      break;
                    case TagValue_Value.mapValue:
                      update.defaultValue.mapValue =
                          tagType.defaultValue.mapValue;
                      break;
                    case TagValue_Value.notSet:
                      break;
                  }
                  context.read<VaultCubit>().updateTagType(
                        tagType.id,
                        update,
                      );
                } else if (value is String && value == 'flag') {
                  context.read<VaultCubit>().updateTagType(
                        tagType.id,
                        TagType(isFlag: true),
                      );
                }
              },
              items: [
                const DropdownMenuItem(value: 'flag', child: Icon(Icons.flag)),
                ...TagValue_Value.values
                    .where((value) => value != TagValue_Value.notSet)
                    .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                            Casing.titleCase(value.name).split(' ').first)))
              ],
            )
        ],
      ),
      trailing: widget.selected
          ? const Icon(Icons.check_box)
          : const Icon(Icons.check_box_outline_blank),
      onLongPress: () => setState(() {
        isEditing = true;
      }),
      onTap: widget.onTap,
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
  final intTextController = TextEditingController();
  TagTypeValuePair get typeValuePair => widget.typeValuePair;

  @override
  void initState() {
    switch (typeValuePair.tagType.defaultValue.whichValue()) {
      case TagValue_Value.stringValue:
        break;
      case TagValue_Value.intValue:
        intTextController.text =
            typeValuePair.tagValue?.intValue.toString() ?? '';
        break;
      case TagValue_Value.floatValue:
        break;
      case TagValue_Value.listValue:
        break;
      case TagValue_Value.mapValue:
        break;
      case TagValue_Value.boolValue:
      case TagValue_Value.notSet:
        break;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('${typeValuePair.tagType.name}:'),
        const SizedBox(width: 16),
        Expanded(child: _buildEditor(context)),
      ],
    );
  }

  Widget _buildEditor(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: switch (typeValuePair.tagType.defaultValue.whichValue()) {
        TagValue_Value.boolValue => Checkbox(
            value: typeValuePair.tagValue?.boolValue,
            onChanged: (value) => context.read<VaultCubit>().updateTag(
                  typeValuePair.fileIds,
                  typeValuePair.tagType.id,
                  TagValue(boolValue: value),
                ),
            tristate: typeValuePair.tagValue?.boolValue == null,
          ),
        TagValue_Value.stringValue => const TextField(),
        TagValue_Value.intValue => TextField(
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            controller: intTextController,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(8),
              border: InputBorder.none,
              // hoverColor: Colors.grey[300],
              fillColor: Colors.transparent,
              filled: true,
            ),
            onSubmitted: (value) => context.read<VaultCubit>().updateTag(
                  typeValuePair.fileIds,
                  typeValuePair.tagType.id,
                  TagValue(intValue: int.parse(value)),
                ),
          ),
        TagValue_Value.floatValue => TextField(
            keyboardType: const TextInputType.numberWithOptions(
                signed: true, decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
            ],
          ),
        TagValue_Value.listValue => throw UnimplementedError(),
        TagValue_Value.mapValue =>
          Text(typeValuePair.tagValue?.mapValue.toString() ?? '{}'),
        _ => throw UnimplementedError(),
      },
    );
  }
}
