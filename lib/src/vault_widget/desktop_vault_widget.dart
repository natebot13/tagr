import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/tag_filter_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/helpers.dart';
import 'package:tagr/src/vault_widget/file_grid_widget.dart';
import 'package:tagr/src/vault_widget/preview_widget.dart';

class DesktopVaultWidget extends StatelessWidget {
  const DesktopVaultWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ResizableContainer(
      direction: Axis.horizontal,
      children: [
        const ResizableChild(
          child: FileGridWidget(),
        ),
        ResizableChild(
          child: BlocBuilder<VaultCubit, VaultState>(
            builder: (context, vaultState) {
              if (vaultState is! VaultOpen) {
                throw StateError("VaultWidget requires VaultOpen state.");
              }

              final selectionState = context.watch<SelectionCubit>().state;

              final tags = vaultState.tags(selectionState.selected);
              final firstId = selectionState.selected.firstOrNull;
              return ResizableContainer(
                direction: Axis.vertical,
                children: [
                  ResizableChild(
                    child: PreviewImage(
                      id: firstId,
                      provider: imageProvider(vaultState.root, firstId),
                    ),
                  ),
                  if (selectionState.selected.isNotEmpty)
                    ResizableChild(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SelectableText(selectionState.selected.join('\n')),
                          Expanded(
                            child: BlocProvider(
                              create: (context) => TagFilterCubit(),
                              child: CustomScrollView(
                                slivers: [
                                  PreviewTagsSliver(
                                    tags,
                                    selectionState.selected,
                                    key:
                                        ValueKey(selectionState.selected.first),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.all(0),
                                    sliver: EditPropertiesButtonSliver(
                                      selectionState.selected,
                                    ),
                                  ),
                                  TagsSearch(selectionState.selected),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                ],
              );
            },
          ),
        )
      ],
    );
  }
}
