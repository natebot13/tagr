import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:tagr/cubit/selection_cubit.dart';
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
      child: ResizableContainer(
        direction: Axis.horizontal,
        children: [
          ResizableChild(
            child: Padding(
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
            ),
          ),
          const ResizableChild(child: PreviewWidget())
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
    provider = ResizeImage.resizeIfNeeded(500, null, provider);
    return GestureDetector(
      onTap: () => BlocProvider.of<SelectionCubit>(context).select(id),
      onLongPress: () =>
          BlocProvider.of<SelectionCubit>(context).longSelect(id),
      child: BlocBuilder<SelectionCubit, SelectionState>(
        builder: (context, state) {
          BoxBorder? border;
          final selected = (state is SelectionSingle && state.selected == id) ||
              (state is SelectionMultiple && state.selected.contains(id));
          if (selected) {
            border = Border.all(width: 8, color: Colors.blue);
          }
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              border: border,
            ),
            child: Image(image: provider, fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
