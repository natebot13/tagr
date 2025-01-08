import 'dart:io';

import 'package:collection/collection.dart';
import 'package:eval_ex/expression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:path/path.dart';
import 'package:tagr/src/cubit/search_cubit.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/tag_filter_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/vault_widget/file_grid_item.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/vault_widget/preview_widget.dart';

class VaultWidget extends StatelessWidget {
  final VaultOpen vaultOpen;
  const VaultWidget(this.vaultOpen, {super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SelectionCubit()),
        BlocProvider(create: (context) => SearchCubit(vaultOpen)),
      ],
      child: isDesktop() ? _buildDesktopUi() : _buildMobileUi(),
    );
  }

  Widget _buildDesktopUi() {
    return ResizableContainer(
      direction: Axis.horizontal,
      children: [
        ResizableChild(
          child: FileGridWidget(vault: vaultOpen.vault, root: vaultOpen.root),
        ),
        ResizableChild(child: Builder(builder: (context) {
          final vaultState = context.watch<VaultCubit>().state;
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
                  provider: vaultState.imageProvider(firstId),
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
                                key: ValueKey(selectionState.selected.first),
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
              return FileGridWidget(
                  vault: vaultOpen.vault,
                  root: vaultOpen.root,
                  bottomPadding: state.selected.isNotEmpty
                      ? constraints.maxHeight * 0.15
                      : 0);
            }),
            if (state is SelectionMultiple)
              DraggableScrollableSheet(
                minChildSize: 0.15,
                initialChildSize: 0.15,
                builder: (context, controller) {
                  final vaultState = context.watch<VaultCubit>().state;
                  if (vaultState is! VaultOpen) {
                    throw StateError("VaultWidget requires VaultOpen state.");
                  }

                  final selectionState = context.watch<SelectionCubit>().state;

                  final tags = vaultState.tags(selectionState.selected);
                  const borderRadius = BorderRadius.vertical(
                    top: Radius.circular(16),
                  );
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: BlocProvider(
                      create: (context) => TagFilterCubit(),
                      child: MobileTagScrollView(
                        borderRadius: borderRadius,
                        tags: tags,
                        selectionState: selectionState,
                        controller: controller,
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class MobileTagScrollView extends StatelessWidget {
  const MobileTagScrollView({
    super.key,
    required this.borderRadius,
    required this.tags,
    required this.selectionState,
    required this.controller,
  });

  final BorderRadius borderRadius;
  final Map<int, TagTypeValuePair> tags;
  final SelectionState selectionState;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      primary: false,
      controller: controller,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            alignment: Alignment.center,
            // clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).focusColor,
              borderRadius: borderRadius,
            ),
            child: Container(
              margin: const EdgeInsets.only(
                top: 10,
                bottom: 10,
              ),
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
        ),
        PreviewTagsSliver(tags, selectionState.selected),
        const SliverToBoxAdapter(
          child: Divider(),
        ),
        EditPropertiesButtonSliver(selectionState.selected),
        TagsSearch(selectionState.selected),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverList.list(children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: 8),
              child: const Text(
                'Selected Files',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
              child: SelectableText(
                selectionState.selected.join('\n'),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class NoImplicitScrollPhysics extends AlwaysScrollableScrollPhysics {
  const NoImplicitScrollPhysics({super.parent});

  @override
  bool get allowImplicitScrolling => false;

  @override
  NoImplicitScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return NoImplicitScrollPhysics(parent: buildParent(ancestor));
  }
}

class FileGridWidget extends StatelessWidget {
  const FileGridWidget({
    super.key,
    required this.vault,
    required this.root,
    this.bottomPadding = 0,
  });

  final Vault vault;
  final Directory root;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final selectionState = context.watch<SelectionCubit>().state;
    final numSelected = selectionState.selected.length;
    final multiSelect = selectionState is SelectionMultiple;
    final searchState = context.watch<SearchCubit>().state;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: CustomScrollView(
        physics: const NoImplicitScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: multiSelect,
            automaticallyImplyLeading: true,
            leading: multiSelect
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: context.read<SelectionCubit>().unselect,
                  )
                : null,
            title: Row(
              children: [
                if (!multiSelect) Text(basename(root.path)),
                if (multiSelect) Text('$numSelected Selected'),
                const Spacer(),
                Expanded(
                  child: TextField(
                    onChanged: context.read<SearchCubit>().search,
                    decoration: const InputDecoration(hintText: 'Search'),
                  ),
                ),
              ],
            ),
            // actions: [TextField()],

            // pinned: true,
            primary: true,
          ),
          if (searchState is SearchResults)
            SliverGrid.builder(
              itemCount: searchState.results.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, i) => FileGridItem(
                root,
                searchState.results[i],
              ),
            ),
          SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding)),
        ],
      ),
    );
  }
}
