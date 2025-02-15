import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/extensions.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/vault_widget/desktop_vault_widget.dart';
import 'package:tagr/src/vault_widget/mobile_vault_widget.dart';
import 'package:tagr/src/vault_widget/preview_dismissible_page.dart';

/// The primary vault UI. It is assumed that the current state is VaultOpen,
/// which this widget will retrieve from a provider in the context.
class VaultWidget extends StatelessWidget {
  const VaultWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EventListeners(
      child:
          isDesktop() ? const DesktopVaultWidget() : const MobileVaultWidget(),
    );
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
        listener: (context, state) async {
          if (state is SelectionSingle) {
            if (isMobile()) {
              await context.pushTransparentRoute(
                Material(
                  color: Colors.transparent,
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: context.read<VaultCubit>()),
                      BlocProvider.value(value: context.read<SelectionCubit>()),
                    ],
                    child: PreviewDismissiblePage(file: state.selected.single),
                  ),
                ),
              );
              if (context.mounted) context.read<SelectionCubit>().unselect();
            }
          } else if (state is SelectionChosen) {
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
