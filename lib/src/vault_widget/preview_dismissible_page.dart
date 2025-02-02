import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/vault_widget/file_info_sliver.dart';
import 'package:tagr/src/widgets/file_viewer/file_viewer.dart';

import 'package:tagr/src/cubit/vault_cubit.dart';

class PreviewDismissiblePage extends StatelessWidget {
  final String file;
  const PreviewDismissiblePage({required this.file, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VaultCubit, VaultState>(builder: (context, state) {
      if (state is VaultOpen) {
        return _PreviewPage(vaultOpen: state, file: file);
      }
      return const Text("Vault needs to be open");
    });
  }
}

class _PreviewPage extends StatelessWidget {
  final String file;
  final VaultOpen vaultOpen;
  const _PreviewPage({
    required this.file,
    required this.vaultOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: CustomScrollView(slivers: [
        SliverSafeArea(
          sliver: SliverToBoxAdapter(
            child: DismissiblePage(
              onDismissed: Navigator.of(context).pop,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (MediaQuery.of(context).size.height * .8) -
                      MediaQuery.of(context).viewInsets.bottom,
                ),
                child: FileViewer(vaultOpen: vaultOpen, id: file),
              ),
            ),
          ),
        ),
        const FileInfoSliver(),
      ]),
    );
  }
}
