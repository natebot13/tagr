/// Annotation for classes that should generate plugin implementations.
/// The interface methods should only take parameters that can be json encoded,
/// and should only return types or futures of types that can be json decoded.
class PluginInterface {
  const PluginInterface();
}
