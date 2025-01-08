import 'dart:io';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/vault_widget/preview_widget.dart';

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
                child: PreviewImage(
                  id: id,
                  provider: provider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
