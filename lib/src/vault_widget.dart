import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:eval_ex/expression.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:tagr/src/cubit/search_cubit.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/tag_filter_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/preview_widget.dart';
import 'package:transparent_image/transparent_image.dart';

class VaultWidget extends StatelessWidget {
  final Directory root;
  final Vault vault;
  const VaultWidget(this.root, this.vault, {super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SelectionCubit()),
        BlocProvider(create: (context) => SearchCubit()),
      ],
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
          if (vaultState is! VaultOpen) {
            throw StateError("VaultWidget requires VaultOpen state.");
          }

          final selectionState = context.watch<SelectionCubit>().state;

          final tags = vaultState.tags(selectionState.selected);
          return ResizableContainer(
            direction: Axis.vertical,
            children: [
              ResizableChild(
                child: PreviewImage(
                  id: selectionState.selected.firstOrNull,
                  vaultState: vaultState,
                ),
              ),
              if (selectionState.selected.isNotEmpty)
                ResizableChild(
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
                  vault: vault,
                  root: root,
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

extension on SearchTerm {
  /// To be used from an "every" context
  bool matches(List<TagTypeValuePair> typeValuePairs) {
    final matchedPair = typeValuePairs.firstWhereOrNull(
      (typeValuePair) => typeValuePair.tagType.name.toLowerCase() == term,
    );
    if (matchedPair == null && isPositive) return false;
    if (matchedPair != null && isNegative) return false;
    if (isNegative) return true;

    // Being here means we have a nameMatch and we're positive

    // Flags are always matches
    if (matchedPair!.tagType.isFlag) return true;

    // If the param is null or empty, it's a match
    if (param == null || param!.isEmpty) return true;

    // Check the param
    var tagValue = matchedPair.tagValue!;
    if (tagValue.whichValue() == TagValue_Value.notSet) {
      tagValue = matchedPair.tagType.defaultValue;
    }
    final valueString = tagValue.asStringValue();
    final exp = Expression('$valueString$param');

    try {
      return exp.eval().toString() == '1';
    } on ExpressionException catch (e) {
      return false;
    }
  }
}

bool filterFunction(List<SearchTerm> searchTerms, VaultFile file, Vault vault) {
  final nameValues = file.tags.values.entries
      .map(
        (entry) => TagTypeValuePair(
            tagType: vault.tagTypes[entry.key]!, tagValue: entry.value),
      )
      .toList();

  return searchTerms.every((searchTerm) => searchTerm.matches(nameValues));
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
    final filtered = vault.files
        .where((file) => filterFunction(searchState.searchTerms, file, vault))
        .toList();
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
          SliverGrid.builder(
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, i) => FileGridItem(root, filtered[i]),
          ),
          SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding)),
        ],
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
    provider = ResizeImage.resizeIfNeeded(300, null, provider);
    return GestureDetector(
      onTap: () => context.read<SelectionCubit>().select(
            id,
            multi: HardwareKeyboard.instance.isControlPressed,
          ),
      onLongPress: isDesktop()
          ? null
          : () => context.read<SelectionCubit>().select(id, multi: true),
      child: BlocConsumer<SelectionCubit, SelectionState>(
        listener: (context, state) async {
          if (state is SelectionSingle && state.selected.contains(id)) {
            if (isMobile()) {
              await context.pushTransparentRoute(
                Material(
                  color: Colors.transparent,
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: context.read<VaultCubit>()),
                      BlocProvider.value(value: context.read<SelectionCubit>()),
                    ],
                    child: PreviewPage(file: id),
                  ),
                ),
              );
              if (context.mounted) context.read<SelectionCubit>().unselect();
            }
          }
        },
        builder: (context, state) {
          final selected =
              (state is SelectionSingle && state.selected.contains(id)) ||
                  (state is SelectionMultiple && state.selected.contains(id));
          return Container(
            color: Theme.of(context).focusColor,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 80),
              padding:
                  selected ? const EdgeInsets.all(8) : const EdgeInsets.all(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.all(Radius.circular(selected ? 16 : 0))),
                child: Hero(
                  tag: id,
                  child: FadeInImage(
                    placeholder: MemoryImage(kTransparentImage),
                    fadeInDuration: const Duration(milliseconds: 300),
                    image: provider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
