// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/selection_cubit.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
import 'package:tagr/src/generated/tagr.pb.dart';

class TagValueEditor extends StatelessWidget {
  final TagTypeValuePair typeValuePair;
  const TagValueEditor(this.typeValuePair, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('${typeValuePair.tagType.name}:'),
      const SizedBox(width: 8),
      if (!typeValuePair.tagType.isReference) _TagValueEditor(typeValuePair),
      if (typeValuePair.tagType.isReference) _ReferenceTagValue(typeValuePair),
    ]);
  }
}

class _ReferenceTagValue extends StatelessWidget {
  final TagTypeValuePair typeValuePair;
  const _ReferenceTagValue(this.typeValuePair, {super.key});

  @override
  Widget build(BuildContext context) {
    final refValue = typeValuePair.tagValue?.stringValue;
    return Row(children: [
      if (refValue == null) const Text('assorted'),
      if (refValue != null && refValue.isEmpty) const Text('Unlinked'),
      if (refValue != null && refValue.isNotEmpty)
        TextButton(
          onPressed: () => context
              .read<SelectionCubit>()
              .select(refValue, forceSingle: true),
          child: Text(refValue),
        ),
      IconButton(
          onPressed: () => context
              .read<SelectionCubit>()
              .startChoosing(typeValuePair.tagType.id),
          icon: const Icon(Icons.add_link)),
      if (refValue != null && refValue.isNotEmpty)
        BlocBuilder<SelectionCubit, SelectionState>(
          builder: (context, state) {
            return IconButton(
                onPressed: () => context.read<VaultCubit>().updateTag(
                      state.selected,
                      typeValuePair.tagType.id,
                      TagValue(),
                    ),
                icon: const Icon(Icons.link_off));
          },
        ),
    ]);
  }
}

class _TagValueEditor extends StatefulWidget {
  final TagTypeValuePair typeValuePair;
  const _TagValueEditor(this.typeValuePair, {super.key});

  @override
  State<_TagValueEditor> createState() => _TagValueEditorState();
}

class _TagValueEditorState extends State<_TagValueEditor> {
  final controller = TextEditingController();
  String? errorText;
  TagTypeValuePair get typeValuePair => widget.typeValuePair;

  @override
  void initState() {
    print("initState for TagValueEditor");
    if (typeValuePair.partial) {
      setControllerText(TagValue());
    } else {
      if (typeValuePair.tagValue?.whichValue() == TagValue_Value.notSet) {
        setControllerText(typeValuePair.tagType.defaultValue);
      } else {
        setControllerText(typeValuePair.tagValue);
      }
    }
    super.initState();
  }

  void setControllerText(TagValue? value) {
    controller.text = switch (value?.whichValue()) {
      null => '',
      TagValue_Value.stringValue => value!.stringValue,
      TagValue_Value.intValue => value!.intValue.toString(),
      TagValue_Value.floatValue => value!.floatValue.toString(),
      TagValue_Value.notSet => '',
      _ => 'not implemented',
    };
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool validateText() {
    final text = controller.text;
    setState(() {
      errorText = switch (typeValuePair.tagType.defaultValue.whichValue()) {
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
  Widget build(BuildContext context) {
    return BlocBuilder<SelectionCubit, SelectionState>(
      builder: (context, state) {
        return Expanded(
          child: Row(
            children: [
              _buildEditor(context, state.selected),
              if (typeValuePair.tagValue?.whichValue() != TagValue_Value.notSet)
                IconButton(
                    onPressed: () async {
                      await context.read<VaultCubit>().updateTag(
                            state.selected,
                            typeValuePair.tagType.id,
                            TagValue(),
                          );
                      setControllerText(typeValuePair.tagType.defaultValue);
                    },
                    icon: const Icon(Icons.refresh))
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditor(BuildContext context, Set<String> selected) {
    final style = typeValuePair.tagValue?.whichValue() == TagValue_Value.notSet
        ? null
        : const TextStyle(fontWeight: FontWeight.bold);
    final decoration = InputDecoration(
      contentPadding: const EdgeInsets.all(8),
      border: InputBorder.none,
      // hoverColor: Colors.grey[300],
      fillColor: Colors.transparent,
      filled: true,
      errorText: errorText,
    );

    void updater(TagValue value) {
      context.read<VaultCubit>().updateTag(
            selected,
            typeValuePair.tagType.id,
            value,
          );
    }

    return switch (typeValuePair.tagType.defaultValue.whichValue()) {
      TagValue_Value.boolValue => Checkbox(
          value: typeValuePair.tagValue?.boolValue,
          onChanged: (value) => updater(TagValue(boolValue: value)),
          tristate: typeValuePair.tagValue?.boolValue == null,
        ),
      TagValue_Value.stringValue => Expanded(
          child: TextField(
            controller: controller,
            style: style,
            onChanged: (value) => updater(TagValue(stringValue: value)),
            decoration: decoration,
          ),
        ),
      TagValue_Value.intValue => Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: false,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9-]')),
            ],
            style: style,
            decoration: decoration,
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
            decoration: decoration,
            style: style,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
            ],
            onChanged: (value) {
              if (validateText()) {
                updater(TagValue(floatValue: double.parse(value)));
              }
            },
          ),
        ),
      TagValue_Value.listValue =>
        Text(typeValuePair.tagValue?.listValue.toString() ?? '[]'),
      TagValue_Value.mapValue =>
        Text(typeValuePair.tagValue?.mapValue.toString() ?? '{}'),
      TagValue_Value.notSet => throw UnimplementedError(),
    };
  }
}
