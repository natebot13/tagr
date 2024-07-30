import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:tagr/cubit/selection_cubit.dart';
import 'package:tagr/cubit/vault_cubit.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/preview_widget.dart';

class VaultWidget extends StatelessWidget {
  final Directory root;
  final Vault vault;
  const VaultWidget(this.root, this.vault, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectionCubit(),
      child: isDesktop() ? _buildDesktopUi() : _buildMobileUi(),
    );
  }

  Widget _buildDesktopUi() {
    return ResizableContainer(
      direction: Axis.horizontal,
      children: [
        ResizableChild(
          child: FileGridWidget(vault: vault, root: root),
        ),
        ResizableChild(child: Builder(builder: (context) {
          final vaultState = context.watch<VaultCubit>().state;
          if (vaultState is! VaultOpen) return const Text('No vault open');

          final selectionState = context.watch<SelectionCubit>().state;

          final tags = vaultState.tags(selectionState.selected);
          return ResizableContainer(
            direction: Axis.vertical,
            children: [
              ResizableChild(
                child: PreviewImage(selectionState.selected, vaultState),
              ),
              ResizableChild(
                child: CustomScrollView(slivers: [PreviewTagsSliver(tags)]),
              )
            ],
          );
        }))
      ],
    );
  }

  Widget _buildMobileUi() {
    return BlocBuilder<SelectionCubit, SelectionState>(
      builder: (context, state) {
        return Stack(
          children: [
            LayoutBuilder(builder: (context, constraints) {
              return SizedBox(
                height:
                    constraints.maxHeight * (state.selected.isEmpty ? 1 : 0.75),
                child: FileGridWidget(vault: vault, root: root),
              );
            }),
            if (state.selected.isNotEmpty)
              DraggableScrollableSheet(
                initialChildSize: 0.25,
                builder: (context, controller) {
                  final vaultState = context.watch<VaultCubit>().state;
                  if (vaultState is! VaultOpen)
                    return const Text('No vault open');

                  final selectionState = context.watch<SelectionCubit>().state;

                  final tags = vaultState.tags(selectionState.selected);
                  return Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: CustomScrollView(
                      primary: false,
                      controller: controller,
                      slivers: [
                        SliverList.list(
                          children: [
                            Center(
                              child: Container(
                                margin:
                                    const EdgeInsets.only(top: 10, bottom: 10),
                                height: 5,
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        PreviewTagsSliver(tags),
                        SliverList.list(
                          children: [
                            PreviewImage(
                              selectionState.selected,
                              vaultState,
                              fit: FlexFit.loose,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              )
          ],
        );
      },
    );
  }
}

class FileGridWidget extends StatelessWidget {
  const FileGridWidget({
    super.key,
    required this.vault,
    required this.root,
  });

  final Vault vault;
  final Directory root;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: vault.files.length,
        itemBuilder: (context, i) => FileGridItem(root, vault.files[i]),
      ),
    );
  }
}

class FileGridItem extends StatelessWidget {
  final VaultFile file;
  final Directory root;
  const FileGridItem(this.root, this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    String id = file.path;
    ImageProvider provider;
    final mimeType = lookupMimeType(file.path);
    if (mimeType?.contains('image') ?? false) {
      provider = FileImage(File(join(root.path, file.path)));
    } else {
      provider = const AssetImage('assets/images/unknown.png');
    }
    provider = ResizeImage.resizeIfNeeded(500, null, provider);
    return GestureDetector(
      onTap: () => BlocProvider.of<SelectionCubit>(context)
          .select(id, multi: HardwareKeyboard.instance.isControlPressed),
      onLongPress: () =>
          BlocProvider.of<SelectionCubit>(context).select(id, multi: true),
      child: BlocBuilder<SelectionCubit, SelectionState>(
        builder: (context, state) {
          BoxBorder? border;
          final selected =
              (state is SelectionSingle && state.selected.contains(id)) ||
                  (state is SelectionMultiple && state.selected.contains(id));
          if (selected) {
            border = Border.all(width: 8, color: Colors.blue);
          }
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              border: border,
              color: Theme.of(context).focusColor,
            ),
            child: Image(image: provider, fit: BoxFit.contain),
          );
        },
      ),
    );
  }
}
