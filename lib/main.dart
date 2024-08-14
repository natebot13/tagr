import 'package:collection/collection.dart';
import 'package:dart_casing/dart_casing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                    child: const SingleChildScrollView(child: TagTypesEditor()),
                  );
                },
              );
            },
            title: const Text('Manage Tags'),
          ),
        ],
      ),
    );
  }
}

class TagTypesEditor extends StatelessWidget {
  const TagTypesEditor({super.key});

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
              return TagTypeEditorHeaderTile(
                tagType: tagType,
                isExpanded: isExpanded,
              );
            },
            body: TagTypeEditorBodyTile(tagType: tagType),
          );
        },
      ).toList(),
    );
  }
}

class TagTypeEditorBodyTile extends StatelessWidget {
  final TagType tagType;
  const TagTypeEditorBodyTile({
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
                const Text('Default value:'),
                const SizedBox(width: 8),
                TagTypeValueEditor(
                  key: ValueKey(
                    '${tagType.id}:${tagType.defaultValue.whichValue()}',
                  ),
                  tagType: tagType,
                  context: context,
                ),
              ],
            )
        ],
      ),
    );
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

class TagTypeValueEditor extends StatefulWidget {
  const TagTypeValueEditor({
    super.key,
    required this.tagType,
    required this.context,
  });

  final TagType tagType;
  final BuildContext context;

  @override
  State<TagTypeValueEditor> createState() => _TagTypeValueEditorState();
}

class _TagTypeValueEditorState extends State<TagTypeValueEditor> {
  final controller = TextEditingController();
  String? errorText;

  @override
  void initState() {
    final defaultValue = widget.tagType.defaultValue;
    controller.text = switch (defaultValue.whichValue()) {
      TagValue_Value.stringValue => defaultValue.stringValue,
      TagValue_Value.intValue => defaultValue.intValue.toString(),
      TagValue_Value.floatValue => defaultValue.floatValue.toString(),
      _ => 'not implemented',
    };
    super.initState();
  }

  /// Validates the text input controller. Sets [errorText] to non-null if the
  /// text is invalid. Returns true if the text is valid.
  bool validateText() {
    final text = controller.text;
    setState(() {
      errorText = switch (widget.tagType.defaultValue.whichValue()) {
        TagValue_Value.boolValue => null,
        TagValue_Value.stringValue => null,
        TagValue_Value.intValue =>
          int.tryParse(text) == null ? 'Invalid int' : null,
        TagValue_Value.floatValue =>
          double.tryParse(text) == null ? 'Invalid float' : null,
        TagValue_Value.listValue => null,
        TagValue_Value.mapValue => null,
        TagValue_Value.notSet => null,
      };
    });
    return errorText == null;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void updater(TagValue value) {
      context.read<VaultCubit>().updateTagType(
            widget.tagType.id,
            TagType(defaultValue: value),
          );
    }

    return switch (widget.tagType.defaultValue.whichValue()) {
      TagValue_Value.boolValue => Checkbox(
          value: widget.tagType.defaultValue.boolValue,
          onChanged: (value) => updater(TagValue(boolValue: value)),
        ),
      TagValue_Value.stringValue => Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.text,
            onChanged: (value) => updater(TagValue(stringValue: value)),
          ),
        ),
      TagValue_Value.intValue => Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: false,
            ),
            decoration: InputDecoration(errorText: errorText),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[-0-9]')),
            ],
            onChanged: (value) {
              if (validateText()) {
                updater(TagValue(intValue: int.parse(value)));
              }
            },
          ),
        ),
      TagValue_Value.floatValue => Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: InputDecoration(errorText: errorText),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[-0-9\.]')),
            ],
            onChanged: (value) {
              if (validateText()) {
                updater(TagValue(floatValue: double.parse(value)));
              }
            },
          ),
        ),

      // TODO: something  more complicated
      TagValue_Value.listValue => Expanded(
          child: TextField(controller: controller),
        ),
      TagValue_Value.mapValue => Expanded(
          child: TextField(controller: controller),
        ),
      TagValue_Value.notSet => throw UnimplementedError('notSet aint valid'),
    };
  }
}

class TagTypeEditorHeaderTile extends StatefulWidget {
  final TagType tagType;
  final bool isExpanded;
  const TagTypeEditorHeaderTile({
    super.key,
    this.isExpanded = false,
    required this.tagType,
  });

  @override
  State<TagTypeEditorHeaderTile> createState() =>
      _TagTypeEditorHeaderTileState();
}

class _TagTypeEditorHeaderTileState extends State<TagTypeEditorHeaderTile> {
  final controller = TextEditingController();

  @override
  void initState() {
    controller.text = widget.tagType.name;
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
