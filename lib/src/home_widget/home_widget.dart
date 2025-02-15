import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/filter_cubit.dart';
import 'package:tagr/src/cubit/plugin_cubit.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/repository/vault_repository.dart';
import 'package:tagr/src/vault_widget/vault_widget.dart';

class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VaultCubit, VaultState>(builder: (context, state) {
      return switch (state) {
        VaultClosed() => Center(
            child: OutlinedButton(
              onPressed: context.read<VaultCubit>().pickVault,
              child: const Text('Open Vault'),
            ),
          ),
        VaultLoading() => const CircularProgressIndicator(),
        VaultLoadFailure() => Center(
            child: Text(state.message),
          ),
        VaultOpen() => MultiBlocProvider(providers: [
            BlocProvider(
                create: (context) =>
                    SelectionCubit(context.read<VaultRepository>())),
            BlocProvider(create: (context) => FilterCubit()..filter('', state)),
            BlocProvider(
              lazy: false,
              create: (context) => PluginCubit(state.root),
            ),
          ], child: const VaultWidget()),
      };
    });
  }
}
