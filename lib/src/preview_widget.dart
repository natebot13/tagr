import 'package:collection/collection.dart';
import 'package:dart_casing/dart_casing.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import 'package:tagr/cubit/selection_cubit.dart';
import 'package:tagr/cubit/vault_cubit.dart';
import 'package:tagr/src/generated/tagr.pb.dart';

// ignore: implementation_imports
import 'package:dropdown_search/src/widgets/selection_widget.dart';
// ignore: implementation_imports
import 'package:dropdown_search/src/widgets/popup_menu.dart';

class PreviewImage extends StatelessWidget {
  final Set<String> ids;
  final VaultOpen vaultState;
  final FlexFit fit;
  const PreviewImage(
    this.ids,
    this.vaultState, {
    super.key,
    this.fit = FlexFit.tight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: fit == FlexFit.loose ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (ids.length == 1)
          Flexible(
            fit: fit,
            child: Image(image: vaultState.imageProvider(ids.singleOrNull)),
          ),
        SelectableText(ids.join(', ')),
      ],
    );
  }
}

class PreviewTagsSliver extends StatefulWidget {
  final Map<int, TagTypeValuePair> tags;
  const PreviewTagsSliver(this.tags, {super.key});

  @override
  State<PreviewTagsSliver> createState() => _PreviewTagsSliverState();
}

class _PreviewTagsSliverState extends State<PreviewTagsSliver> {
  bool isEditing = false;
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final categorized = groupBy(
      widget.tags.entries.sorted(
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
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: categories.length + 1,
        (context, index) {
          if (index == categories.length) {
            final vaultState = context.watch<VaultCubit>().state;
            if (vaultState is! VaultOpen) return const Text("Vault not open");
            return const AddPropertyButton();
          }
          final category = categories[index];
          final flags = groupBy(
            categorized[category]!,
            (entry) => entry.value.tagType.isFlag,
          );
          return _previewTagItem(category, flags, context);
        },
      ),
    );
  }

  Column _previewTagItem(
      String category,
      Map<bool, List<MapEntry<int, TagTypeValuePair>>> flags,
      BuildContext context) {
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
                    onDeleted: () => context.read<VaultCubit>().removeTag(
                          tagId: entry.key,
                          from: entry.value.fileIds,
                        ),
                    deleteButtonTooltipMessage: '',
                  ),
                )
                .toList(),
          ),
        if (flags.containsKey(false))
          ...flags[false]!.map((entry) => TagValueEditor(
                entry.value,
                key: ValueKey('TagValueEditor${entry.key}'),
              )),
      ],
    );
  }
}

class AddPropertyButton extends StatelessWidget {
  const AddPropertyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      label: const Text('Add Property'),
      icon: const Icon(Icons.add),
      onPressed: () {
        // Here we get the render object of our physical button, later to get its size & position
        final popupButtonObject = context.findRenderObject() as RenderBox;
        // Get the render object of the overlay used in `Navigator` / `MaterialApp`, i.e. screen size reference
        var overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        showCustomMenu(
            menuModeProps: const MenuProps(),
            context: context,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<VaultCubit>()),
                BlocProvider.value(value: context.read<SelectionCubit>()),
              ],
              child: Builder(builder: (context) {
                final vaultState = context.watch<VaultCubit>().state;
                if (vaultState is! VaultOpen) {
                  return const Text("Vault not open");
                }
                final selectionState = context.watch<SelectionCubit>().state;
                final tags = vaultState.tags(selectionState.selected);
                return SelectionWidget(
                  isMultiSelectionMode: true,
                  items: vaultState.vault.tagTypes.values.toList(),
                  defaultSelectedItems:
                      tags.values.map((pair) => pair.tagType).toList(),
                  // filterFn: ,
                  itemAsString: (item) => item.name,
                  popupProps: PopupPropsMultiSelection<TagType>.menu(
                    showSearchBox: true,
                    searchDelay: const Duration(),
                    showSelectedItems: true,
                    onItemAdded: (items, added) => context
                        .read<VaultCubit>()
                        .updateTag(selectionState.selected, added.id),
                    onItemRemoved: (items, removed) =>
                        context.read<VaultCubit>().removeTag(
                              from: selectionState.selected,
                              tagId: removed.id,
                            ),
                  ),
                  // selectedItems:
                  //     widget.tags.values.map((pair) => pair.tagType).toList(),
                );
              }),
            ),
            position: _position(popupButtonObject, overlay));
      },
    );
  }

  RelativeRect _position(RenderBox popupButtonObject, RenderBox overlay) {
    // Calculate the show-up area for the dropdown using button's size & position based on the `overlay` used as the coordinate space.
    return RelativeRect.fromSize(
      Rect.fromPoints(
        popupButtonObject.localToGlobal(
            popupButtonObject.size.topLeft(Offset.zero),
            ancestor: overlay),
        popupButtonObject.localToGlobal(
            popupButtonObject.size.topRight(Offset.zero),
            ancestor: overlay),
      ),
      Size(overlay.size.width, overlay.size.height),
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
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(8),
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
