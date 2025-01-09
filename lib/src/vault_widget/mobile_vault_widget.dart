import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/tag_filter_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/vault_widget/file_grid_widget.dart';
import 'package:tagr/src/vault_widget/preview_widget.dart';

class MobileVaultWidget extends StatelessWidget {
  const MobileVaultWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectionCubit, SelectionState>(
      builder: (context, state) {
        return Stack(
          children: [
            LayoutBuilder(builder: (context, constraints) {
              return FileGridWidget(
                  bottomPadding: state.selected.isNotEmpty
                      ? constraints.maxHeight * 0.15
                      : 0);
            }),
            if (state is SelectionMultiple)
              DraggableScrollableSheet(
                minChildSize: 0.15,
                initialChildSize: 0.15,
                builder: (context, controller) {
                  final selectionState = context.watch<SelectionCubit>().state;
                  final vaultState = context.watch<VaultCubit>().state;
                  if (vaultState is! VaultOpen) {
                    throw StateError("Requires an open vault");
                  }
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
