// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/plugin_cubit.dart';
import 'package:tagr/src/cubit/tag_filter_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/vault_widget/tag_import_dialog.dart';

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
            label: Row(
              children: [
                const Expanded(child: Text('Add Property')),
                PopupMenuButton(
                  tooltip: null,
                  itemBuilder: (outerContext) {
                    return [
                      PopupMenuItem(
                        child: const Text('Import'),
                        onTap: () {
                          showDialog(
                              context: outerContext,
                              builder: (context) {
                                return BlocProvider.value(
                                  value: outerContext.read<PluginCubit>(),
                                  child: TagImportDialog(widget.fileIds),
                                );
                              });
                        },
                      ),
                    ];
                  },
                )
              ],
            ),
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
