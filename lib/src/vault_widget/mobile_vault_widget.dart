import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/vault_widget/file_grid_widget.dart';
import 'package:tagr/src/vault_widget/file_info_sliver.dart';

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
                  const borderRadius = BorderRadius.vertical(
                    top: Radius.circular(16),
                  );
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: MobileFileInfoScrollView(
                      borderRadius: borderRadius,
                      controller: controller,
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

class MobileFileInfoScrollView extends StatelessWidget {
  const MobileFileInfoScrollView({
    super.key,
    required this.borderRadius,
    required this.controller,
  });

  final BorderRadius borderRadius;
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
        const FileInfoSliver()
      ],
    );
  }
}
