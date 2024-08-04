import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tagr/src/cubit/vault_cubit.dart';
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
          ),
        ),
      ),
    );
  }
}
