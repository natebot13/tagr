import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:tagr/cubit/selection_cubit.dart';
import 'package:tagr/cubit/vault_cubit.dart';
import 'package:tagr/src/generated/tagr.pb.dart';

class PreviewWidget extends StatelessWidget {
  const PreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultState = context.watch<VaultCubit>().state;
    if (vaultState is! VaultOpen) return const Text('No vault open');

    final selectionState = context.watch<SelectionCubit>().state;

    final ImageProvider provider = switch (selectionState) {
      SelectionNone() => vaultState.defaultImage(),
      SelectionSingle(selected: final i) => vaultState.imageProvider(i),
      SelectionMultiple(selected: final s) => s.length == 1
          ? vaultState.imageProvider(s.single)
          : vaultState.defaultImage(),
    };

    final List<VaultTagValue> tags = switch (selectionState) {
      SelectionNone() => [],
      SelectionSingle() => vaultState.tags({selectionState.selected}),
      SelectionMultiple() => vaultState.tags(selectionState.selected),
    };

    return ResizableContainer(
      direction: Axis.vertical,
      children: [
        ResizableChild(child: Image(image: provider)),
        ResizableChild(child: Text(tags.toYaml())),
      ],
    );
  }
}

class PreviewImage extends StatelessWidget {
  final ImageProvider provider;
  const PreviewImage(this.provider, {super.key});

  @override
  Widget build(BuildContext context) {
    return Image(
      image: provider,
    );
  }
}
