// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/tag_filter_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/generated/tagr.pb.dart';

class TagsSearchSliver extends StatelessWidget {
  final Set<String> fileIds;

  const TagsSearchSliver(this.fileIds, {super.key});

  @override
  Widget build(BuildContext context) {
    final searchState = context.watch<TagFilterCubit>().state;
    final vaultState = context.watch<VaultCubit>().state;
    if (vaultState is! VaultOpen) {
      throw StateError("Vault must be open for TagSearch");
    }
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
      leading: Icon(icon),
      title: Text(entry.value.name),
      onTap: fn,
    );
  }
}
