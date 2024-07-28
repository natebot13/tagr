import 'package:dart_casing/dart_casing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:grouped_list/grouped_list.dart';
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

    final selection = switch (selectionState) {
      SelectionNone() => <String>{},
      SelectionSingle() => {selectionState.selected},
      SelectionMultiple() => selectionState.selected,
    };

    final tags = vaultState.tags(selection);

    return ResizableContainer(
      direction: Axis.vertical,
      children: [
        ResizableChild(child: PreviewImage(selection, vaultState)),
        ResizableChild(child: PreviewTags(selection, tags))
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
        SelectableText(ids.join(', '))
      ],
    );
  }
}

class PreviewTags extends StatelessWidget {
  final Set<String> ids;
  final Map<int, TagTypeValuePair> tags;
  final Map<String, Map<int, TagTypeValuePair>> categories;
  PreviewTags(this.ids, this.tags, {super.key})
      : categories = _buildCategories(tags);

  @override
  Widget build(BuildContext context) {
    return GroupedListView(
      elements: tags.entries.toList(),
      groupBy: (entry) => entry.value.tagType.category,
      groupHeaderBuilder: (element) => Center(
          child: Text(
        Casing.titleCase(element.value.tagType.category),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      )),
      groupItemBuilder: (context, entry, groupStart, groupEnd) {
        return Dismissible(
          key: ValueKey(entry.key),
          child: TagEditor(entry.value),
          onDismissed: (direction) => context
              .read<VaultCubit>()
              .removeTag(entry.value.fileIds, entry.key),
        );
      },
    );
  }

  void _openTagAdder(BuildContext outerContext) {
    showModalBottomSheet(
      context: outerContext,
      builder: (context) {
        return BlocProvider.value(
          value: outerContext.read<VaultCubit>(),
          child: BlocBuilder<VaultCubit, VaultState>(
            builder: (context, state) {
              final tagKeySet = tags.keys.toSet();
              if (state is! VaultOpen) return const Text('Vault not open');
              return ListView(children: [
                ...state.vault.tagTypes.values.map(
                  (tagType) => ListTile(
                    title: Text(tagType.name),
                    trailing: tagKeySet.contains(tagType.id)
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => context
                        .read<VaultCubit>()
                        .updateTag(ids, tagType.id, tagType.defaultValue),
                  ),
                ),
                ListTile(
                  title: const Text("Create tag"),
                  onTap: () => context.read<VaultCubit>().createTag(),
                ),
              ]);
            },
          ),
        );
      },
    );
  }

  static _buildCategories(Map<int, TagTypeValuePair> tags) {
    final categories = <String, Map<int, TagTypeValuePair>>{};
    for (final tagEntry in tags.entries) {
      final category = tagEntry.value.tagType.category;
      categories[category] ??= {};
      categories[category]!.addEntries([tagEntry]);
    }
    return categories;
  }
}

class TagEditor extends StatelessWidget {
  final TagTypeValuePair typeValuePair;
  const TagEditor(this.typeValuePair, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(typeValuePair.tagType.name),
        Expanded(child: _buildEditor(context)),
      ],
    );
  }

  Widget _buildEditor(BuildContext context) {
    return switch (typeValuePair.tagType.defaultValue.whichValue()) {
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      TagValue_Value.floatValue => TextField(
          keyboardType: const TextInputType.numberWithOptions(
              signed: true, decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
          ],
        ),
      TagValue_Value.listValue => throw UnimplementedError(),
      TagValue_Value.mapValue => throw UnimplementedError(),
      _ => throw UnimplementedError(),
    };
  }
}
