import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/filter_cubit.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/vault_widget/desktop_vault_widget.dart';
import 'package:tagr/src/vault_widget/mobile_vault_widget.dart';

/// The primary vault UI. It is assumed that the current state is VaultOpen,
/// which this widget will retrieve from a provider in the context.
class VaultWidget extends StatelessWidget {
  const VaultWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // You're not supposed to use 'read' from build, but this is just for
    // pre-warming the filtering cubit. I'm not relying on it for state changes.
    final momentaryStateAccess = context.read<VaultCubit>().state;
    if (momentaryStateAccess is! VaultOpen) throw StateError("Vault not open");

    // Provide SelectionCubit and FilterCubit
    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => SelectionCubit()),
          BlocProvider(
            create: (context) =>
                FilterCubit()..filter('', momentaryStateAccess),
          ),
        ],
        child: EventListeners(
          child: isDesktop()
              ? const DesktopVaultWidget()
              : const MobileVaultWidget(),
        ));
  }
}

class EventListeners extends StatelessWidget {
  final Widget child;
  const EventListeners({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<VaultCubit, VaultState>(
      listener: (context, state) {},
      child: BlocListener<SelectionCubit, SelectionState>(
        listener: (context, state) {
          if (state is SelectionChosen) {
            final files = state.selected.toSet();
            files.remove(state.chosen);
            context.read<VaultCubit>().updateTag(
                  files,
                  state.tagTypeId,
                  TagValue(stringValue: state.chosen),
                );
          }
        },
        child: child,
      ),
    );
  }
}
