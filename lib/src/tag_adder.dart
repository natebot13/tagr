import 'package:dart_casing/dart_casing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/generated/tagr.pb.dart';

class TagAdder extends StatelessWidget {
  const TagAdder({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultState = context.watch<VaultCubit>().state;
    final selectionState = context.watch<SelectionCubit>().state;

    if (vaultState is! VaultOpen) {
      throw StateError("TagAdder requires VaultOpen state.");
    }
    final addedTags = vaultState.tags(selectionState.selected);
    final tagsKeySet = addedTags.keys.toSet();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ListView(children: [
        ...vaultState.vault.tagTypes.values.map(
          (tagType) => TagTypeListItem(
            fileIds: selectionState.selected,
            tagType: tagType,
            selected: tagsKeySet.contains(tagType.id),
            onTap: () {
              final cubit = context.read<VaultCubit>();
              if (tagsKeySet.contains(tagType.id)) {
                cubit.removeTag(
                    tagId: tagType.id, from: selectionState.selected);
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
      ]),
    );
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
