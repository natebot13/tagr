import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/widgets/tag_types_editor.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  onTap: () {
                    Scaffold.of(context).closeDrawer();
                    final vaultCubit = context.read<VaultCubit>();
                    showModalBottomSheet(
                      context: context,
                      clipBehavior: Clip.antiAlias,
                      builder: (context) {
                        return BlocProvider.value(
                          value: vaultCubit,
                          child: const SingleChildScrollView(
                              child: TagTypesEditor()),
                        );
                      },
                    );
                  },
                  title: const Text('Manage Tags'),
                ),
                ListTile(
                  title: const Text("Gallery View"),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text("Table View"),
                  onTap: () {},
                ),
              ],
            ),
          ),
          ListTile(
            onTap: () {
              context.read<VaultCubit>().refreshFilesInVault();
              Scaffold.of(context).closeDrawer();
            },
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh vault'),
          ),
          ListTile(
            onTap: () {
              Scaffold.of(context).closeDrawer();
              context.read<VaultCubit>().closeVault();
            },
            title: const Text("Close vault"),
            leading: const Icon(Icons.logout),
          )
        ],
      ),
    );
  }
}
