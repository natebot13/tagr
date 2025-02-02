import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/widgets/file_viewer/file_viewer.dart';

class FileGridItem extends StatelessWidget {
  final VaultFile file;
  final VaultOpen vaultOpen;
  const FileGridItem(this.vaultOpen, this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<SelectionCubit>().select(
            file.path,
            multi: HardwareKeyboard.instance.isControlPressed,
          ),
      onLongPress: isDesktop()
          ? null
          : () => context.read<SelectionCubit>().select(file.path, multi: true),
      child: BlocBuilder<SelectionCubit, SelectionState>(
        builder: (context, state) {
          final selected = state.selected.contains(file.path);
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
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey[900]!, Colors.grey[800]!]),
                    borderRadius:
                        BorderRadius.all(Radius.circular(selected ? 16 : 0))),
                child: FileViewer(
                  vaultOpen: vaultOpen,
                  id: file.path,
                  resize: 300,
                  fit: BoxFit.cover,
                  preview: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
