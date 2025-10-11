import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:tagr/src/cubit/filter_cubit.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/vault_widget/file_grid_item.dart';

class FileGridWidget extends StatelessWidget {
  const FileGridWidget({
    super.key,
    this.bottomPadding = 0,
  });

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: CustomScrollView(
        physics: const NoImplicitScrollPhysics(),
        slivers: [
          const VaultSliverAppBar(),
          const FilteredGrid(),
          SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding)),
        ],
      ),
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

class VaultSliverAppBar extends StatelessWidget {
  const VaultSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final selectionState = context.watch<SelectionCubit>().state;
    final multiSelect = selectionState is SelectionMultiple;
    final numSelected = selectionState.selected.length;
    final isChoosing = selectionState is SelectionChoosing;

    return SliverAppBar(
      floating: true,
      pinned: multiSelect || isChoosing,
      automaticallyImplyLeading: true,
      leading: multiSelect || isChoosing
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: context.read<SelectionCubit>().unselect,
            )
          : null,
      title: Builder(builder: (context) {
        final vaultState = context.watch<VaultCubit>().state;
        if (vaultState is! VaultOpen) {
          throw StateError('Vault not open');
        }
        final filterState = context.watch<FilterCubit>().state;

        return Row(
          children: [
            if (!multiSelect && !isChoosing)
              Text(path.basename(vaultState.root.path)),
            if (multiSelect) Text('$numSelected Selected'),
            if (isChoosing) const Text('Pick a file'),
            const Spacer(),
            if (filterState is FilterResults)
              Expanded(
                child: FilterField(vaultState, filterState.query),
              ),
          ],
        );
      }),
      // actions: [TextField()],

      // pinned: true,
      primary: true,
    );
  }
}

class FilterField extends StatefulWidget {
  final VaultOpen vaultState;
  final String initialText;

  const FilterField(
    this.vaultState,
    this.initialText, {
    super.key,
  });

  @override
  State<FilterField> createState() => _FilterFieldState();
}

class _FilterFieldState extends State<FilterField> {
  final controller = TextEditingController();

  @override
  void initState() {
    controller.text = widget.initialText;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) =>
          context.read<FilterCubit>().filter(value, widget.vaultState),
      decoration: const InputDecoration(hintText: 'Search'),
      controller: controller,
    );
  }
}

class FilteredGrid extends StatelessWidget {
  const FilteredGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterCubit, FilterState>(
      builder: (context, filterState) {
        if (filterState is! FilterResults) {
          return const SliverToBoxAdapter(
            child: Text("Loading files..."),
          );
        }

        // Listen for vault changes so we can perform a fresh filter.
        return BlocListener<VaultCubit, VaultState>(
          listener: (context, vaultState) {
            if (vaultState is! VaultOpen) return;
            context.read<FilterCubit>().filter(filterState.query, vaultState);
          },
          child: VaultFileSliverGrid(filterState.results),
        );
      },
    );
  }
}

class VaultFileSliverGrid extends StatelessWidget {
  final List<VaultFile> vaultFiles;
  const VaultFileSliverGrid(
    this.vaultFiles, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      itemCount: vaultFiles.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) => BlocBuilder<VaultCubit, VaultState>(
        builder: (context, vaultState) {
          if (vaultState is! VaultOpen) {
            throw StateError("Vault not open");
          }
          return FileGridItem(
            vaultState,
            vaultFiles[i],
          );
        },
      ),
    );
  }
}
