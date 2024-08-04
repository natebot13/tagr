import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/vault_widget.dart';

class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VaultCubit, VaultState>(builder: (context, state) {
      return switch (state) {
        VaultClosed() => Center(
            child: OutlinedButton(
              onPressed: () => openVault(context),
              child: const Text('Open Vault'),
            ),
          ),
        VaultLoading() => const CircularProgressIndicator(),
        VaultLoadFailure() => Center(
            child: Text(state.message),
          ),
        VaultOpen() => VaultWidget(state.root, state.vault),
      };
    });
  }

  void openVault(BuildContext context) async {
    final selectedPath = await FilePicker.platform.getDirectoryPath();

    // Valid path checking
    if (selectedPath == null) return;

    final storagePerms = await Permission.manageExternalStorage.request();

    if (!context.mounted) return;

    if (storagePerms.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Storage permissions are needed"),
      ));
      return;
    }

    if (selectedPath == '/' || selectedPath == 'C:\\') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("I'd recommend not picking the root directory"),
      ));
      return;
    }

    BlocProvider.of<VaultCubit>(context).openVault(selectedPath);
  }
}
