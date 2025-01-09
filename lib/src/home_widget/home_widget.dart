import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
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
        VaultOpen() => const VaultWidget(),
      };
    });
  }
}
