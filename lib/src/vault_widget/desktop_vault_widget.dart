import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/vault_widget/file_grid_widget.dart';
import 'package:tagr/src/vault_widget/file_info_sliver.dart';
import 'package:tagr/src/widgets/file_viewer/file_viewer.dart';

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
              final firstId = selectionState.selected.firstOrNull;
              final selectionList = selectionState.selected.toList();
              return ResizableContainer(
                direction: Axis.vertical,
                children: [
                  // Big picture view
                  ResizableChild(
                    child: selectionState.selected.length <= 1
                        ? FileViewer(vaultOpen: vaultState, id: firstId)
                        : GridView.builder(
                            itemCount: selectionState.selected.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        min(selectionState.selected.length, 3)),
                            itemBuilder: (context, index) {
                              return FileViewer(
                                vaultOpen: vaultState,
                                id: selectionList[index],
                                preview: true,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                  ),
                  // File details view
                  if (selectionState.selected.isNotEmpty)
                    const ResizableChild(
                      child: CustomScrollView(
                        slivers: [FileInfoSliver()],
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
