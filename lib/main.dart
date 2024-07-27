import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/cubit/vault_cubit.dart';
import 'package:tagr/src/home_widget.dart';

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
