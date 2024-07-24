import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';
import 'package:tagr/cubit/selection_cubit.dart';
import 'package:tagr/cubit/vault_cubit.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: BlocProvider(
        create: (context) => VaultCubit(),
        child: const Scaffold(
          body: HomeWidget(),
        ),
      ),
    );
  }
}

class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VaultCubit, VaultState>(builder: (context, state) {
      return switch (state) {
        VaultInitial() => Center(
            child: OutlinedButton(
              onPressed: () => openVault(context),
              child: const Text('Open Vault'),
            ),
          ),
        VaultLoading() => const CircularProgressIndicator(),
        VaultOpen() => BlocProvider(
            create: (context) => SelectionCubit(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: state.files.length,
                itemBuilder: (context, i) => FileGridItem(i, state.files[i]),
              ),
            ),
          ),
      };
    });
  }

  void openVault(BuildContext context) async {
    final path = await FilePicker.platform.getDirectoryPath();
    // final path = await FilesystemPicker.openBottomSheet(
    //   context: context,
    //   fsType: FilesystemType.folder,
    //   rootDirectory: Directory.current,
    // );
    if (path == null) return;
    if (!context.mounted) return;
    if (path == '/') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("I'd recommend not picking the root directory"),
      ));
    }
    BlocProvider.of<VaultCubit>(context).openVault(path);
  }
}

class FileGridItem extends StatelessWidget {
  final int index;
  final File file;
  const FileGridItem(this.index, this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    final ImageProvider provider;
    final mimeType = lookupMimeType(file.path);
    if (mimeType?.contains('image') ?? false) {
      provider = FileImage(file);
    } else {
      provider = const AssetImage('assets/images/unknown.png');
    }
    return GestureDetector(
      onTap: () => BlocProvider.of<SelectionCubit>(context).select(index),
      onLongPress: () =>
          BlocProvider.of<SelectionCubit>(context).longSelect(index),
      child: BlocBuilder<SelectionCubit, SelectionState>(
        builder: (context, state) {
          BoxBorder? border;
          final selected = (state is SelectionSingle &&
                  state.selected == index) ||
              (state is SelectionMultiple && state.selected.contains(index));
          if (selected) {
            border = Border.all(width: 8, color: Colors.blue);
          }
          return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: border,
              ),
              child: Image(image: provider, fit: BoxFit.cover));
        },
      ),
    );
  }
}
