part of 'vault_cubit.dart';

@immutable
sealed class VaultState {}

final class VaultInitial extends VaultState {}

final class VaultLoading extends VaultState {}

final class VaultOpen extends VaultState {
  final List<File> files;
  VaultOpen(this.files);
}
