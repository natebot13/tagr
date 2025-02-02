import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/tag_filter_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/vault_widget/edit_properties_button_sliver.dart';
import 'package:tagr/src/vault_widget/file_stats_sliver.dart';
import 'package:tagr/src/vault_widget/preview_tags_sliver.dart';
import 'package:tagr/src/vault_widget/tags_search.dart';

class FileInfoSliver extends StatelessWidget {
  const FileInfoSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TagFilterCubit(),
      child: BlocBuilder<VaultCubit, VaultState>(
        builder: (context, vaultState) {
          if (vaultState is! VaultOpen) throw StateError("Bad State");
          return BlocBuilder<SelectionCubit, SelectionState>(
            builder: (context, selectionState) {
              final tags = vaultState.tags(selectionState.selected);
              return SliverMainAxisGroup(slivers: [
                FileStatsSliver(vaultState.root, selectionState.selected),
                PreviewTagsSliver(
                  tags,
                  selectionState.selected,
                  key: ValueKey(selectionState.selected.firstOrNull),
                ),
                EditPropertiesButtonSliver(selectionState.selected),
                TagsSearchSliver(selectionState.selected),
              ]);
            },
          );
        },
      ),
    );
  }
}
