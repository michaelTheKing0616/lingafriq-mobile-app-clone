/// Designated copyright agent (17 USC 512(c)(2)).
///
/// Left empty until the agent is registered with the U.S. Copyright Office;
/// set at build time, e.g.
/// `--dart-define=COPYRIGHT_AGENT_NAME=... --dart-define=COPYRIGHT_AGENT_EMAIL=...
///  --dart-define=COPYRIGHT_AGENT_ADDRESS=...`.
class CopyrightAgent {
  const CopyrightAgent({this.name = '', this.email = '', this.address = ''});

  static const fromEnvironment = CopyrightAgent(
    name: String.fromEnvironment('COPYRIGHT_AGENT_NAME'),
    email: String.fromEnvironment('COPYRIGHT_AGENT_EMAIL'),
    address: String.fromEnvironment('COPYRIGHT_AGENT_ADDRESS'),
  );

  final String name;
  final String email;
  final String address;

  bool get isRegistered => name.isNotEmpty && email.isNotEmpty;
}
