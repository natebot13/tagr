import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/generated/tagr.pb.dart';

class TagSelectionPopupRoute<T> extends PopupRoute<T> {
  final VaultCubit vaultCubit;

  TagSelectionPopupRoute({
    required this.vaultCubit,
  });

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 100);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: vaultCubit),
      ],
      child: Material(
        child: Container(
          color: Theme.of(context).cardColor,
          child: const TagSelectionWidget(),
        ),
      ),
    );
  }
}

class TagSelectionWidget extends StatefulWidget {
  const TagSelectionWidget({super.key});

  @override
  State<TagSelectionWidget> createState() => _TagSelectionWidgetState();
}

class _TagSelectionWidgetState extends State<TagSelectionWidget> {
  List<TagType> filtered = [];

  @override
  void initState() {
    // filtered.addAll(widget.items);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(onChanged: _search),
        SizedBox(
          height: 350,
          child: ListView.builder(
            shrinkWrap: true,
            prototypeItem: const ListTile(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(filtered[index].name),
                trailing: const Icon(Icons.check_box_outline_blank),
              );
            },
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          label: const Text("New Property"),
          icon: const Icon(Icons.add),
        )
      ],
    );
  }

  void _search(String value) {
    setState(() {
      // filtered = widget.items
      //     .where(
      //       (tagType) => tagType.name.toLowerCase().contains(
      //             value.toLowerCase(),
      //           ),
      //     )
      //     .toList();
    });
  }
}
