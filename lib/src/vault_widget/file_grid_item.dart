import 'dart:io';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/helpers.dart';
import 'package:tagr/src/vault_widget/preview_widget.dart';

class FileGridItem extends StatelessWidget {
  final VaultFile file;
  final Directory root;
  const FileGridItem(this.root, this.file, {super.key});

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
      child: BlocConsumer<SelectionCubit, SelectionState>(
        listener: (context, state) async {
          if (state is SelectionSingle && state.selected.contains(file.path)) {
            if (isMobile()) {
              await context.pushTransparentRoute(
                Material(
                  color: Colors.transparent,
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: context.read<VaultCubit>()),
                      BlocProvider.value(value: context.read<SelectionCubit>()),
                    ],
                    child: PreviewPage(file: file.path),
                  ),
                ),
              );
              if (context.mounted) context.read<SelectionCubit>().unselect();
            }
          }
        },
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
                child: previewWidget(
                  root,
                  file.path,
                  resize: 300,
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
