import 'package:collection/collection.dart';
import 'package:dart_casing/dart_casing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:protobuf/protobuf.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/generated/tagr.pb.dart';
import 'package:tagr/src/home_widget.dart';
import 'package:tagr/src/repository/vault_repository.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => VaultRepository(),
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: BlocProvider(
          create: (context) => VaultCubit(context.read<VaultRepository>()),
          child: const Scaffold(
            body: HomeWidget(),
            drawer: DrawerWidget(),
          ),
        ),
      ),
    );
  }
}

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                    child: const SingleChildScrollView(child: TagEditor()),
                  );
                },
              );
            },
            title: Text('Manage Tags'),
          ),
        ],
      ),
    );
  }
}

class TagEditor extends StatelessWidget {
  const TagEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultState = context.watch<VaultCubit>().state;
    if (vaultState is! VaultOpen) throw StateError("Bad State");
    final entries = vaultState.tagMap.entries.sorted(
      (a, b) => a.key.compareTo(b.key),
    );

    return ExpansionPanelList.radio(
      children: entries.map(
        (entry) {
          final tagType = vaultState.vault.tagTypes[entry.value]!;
          return ExpansionPanelRadio(
            canTapOnHeader: true,
            value: entry.value,
            headerBuilder: (context, isExpanded) {
              return TagEditorHeaderTile(
                tagType: tagType,
                isExpanded: isExpanded,
              );
            },
            body: TagEditorBodyTile(tagType: tagType),
          );
        },
      ).toList(),
    );
  }
}

class TagEditorBodyTile extends StatelessWidget {
  final TagType tagType;
  const TagEditorBodyTile({
    super.key,
    required this.tagType,
  });

  @override
  Widget build(BuildContext context) {
    final types = [
      'flag',
      ...TagValue_Value.values.where(
        (type) => type != TagValue_Value.notSet,
      )
    ];
    return ListTile(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: types.map<ChoiceChip>((type) {
              return switch (type) {
                'flag' => ChoiceChip(
                    label: const Text('Flag'),
                    selected: tagType.isFlag,
                    onSelected: (value) => context
                        .read<VaultCubit>()
                        .updateTagType(tagType.id, TagType(isFlag: true)),
                  ),
                TagValue_Value() => ChoiceChip(
                    label: Text(Casing.titleCase(type.name).split(' ').first),
                    selected: !tagType.isFlag &&
                        tagType.defaultValue.whichValue() == type,
                    onSelected: (value) => context
                        .read<VaultCubit>()
                        .updateTagType(
                            tagType.id,
                            TagType(
                                isFlag: false, defaultValue: changeType(type))),
                  ),
                _ => throw UnsupportedError('Missing match case for $type'),
              };
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (!tagType.isFlag)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Default value:'),
                _buildTypeAppropriateWidget(context),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildTypeAppropriateWidget(BuildContext context) {
    return switch (tagType.defaultValue.whichValue()) {
      TagValue_Value.boolValue => Checkbox(
          value: tagType.defaultValue.boolValue,
          onChanged: (value) => context.read<VaultCubit>().updateTagType(
                tagType.id,
                TagType(defaultValue: TagValue(boolValue: value)),
              ),
        ),
      TagValue_Value.stringValue => const Expanded(child: TextField()),
      TagValue_Value.intValue => const Expanded(child: TextField()),
      TagValue_Value.floatValue => const Expanded(child: TextField()),
      // TODO: something  more complicated
      TagValue_Value.listValue => const Expanded(child: TextField()),
      TagValue_Value.mapValue => const Expanded(child: TextField()),
      TagValue_Value.notSet => throw UnimplementedError('notSet aint valid'),
    };
  }

  TagValue changeType(TagValue_Value type) {
    final update = TagValue();
    return switch (type) {
      TagValue_Value.boolValue => update
        ..boolValue = tagType.defaultValue.boolValue,
      TagValue_Value.stringValue => update
        ..stringValue = tagType.defaultValue.stringValue,
      TagValue_Value.intValue => update
        ..intValue = tagType.defaultValue.intValue,
      TagValue_Value.floatValue => update
        ..floatValue = tagType.defaultValue.floatValue,
      TagValue_Value.listValue => update
        ..listValue = tagType.defaultValue.listValue,
      TagValue_Value.mapValue => update
        ..mapValue = tagType.defaultValue.mapValue,
      TagValue_Value.notSet =>
        throw StateError('Cannot set tag value to notSet'),
    };
  }
}

class TagEditorHeaderTile extends StatefulWidget {
  final TagType tagType;
  final bool isExpanded;
  const TagEditorHeaderTile({
    super.key,
    this.isExpanded = false,
    required this.tagType,
  });

  @override
  State<TagEditorHeaderTile> createState() => _TagEditorHeaderTileState();
}

class _TagEditorHeaderTileState extends State<TagEditorHeaderTile> {
  final controller = TextEditingController();

  @override
  void initState() {
    controller.text = widget.tagType.name;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: widget.isExpanded
          ? TextField(
              controller: controller,
              onSubmitted: (value) {
                context
                    .read<VaultCubit>()
                    .updateTagType(widget.tagType.id, TagType(name: value));
              },
            )
          : Text(widget.tagType.name),
    );
  }
}
