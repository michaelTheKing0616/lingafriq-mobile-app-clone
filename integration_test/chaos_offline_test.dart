// P12-019: chaos and offline resilience (CI + device lab entry).
import 'package:integration_test/integration_test.dart';

import '../test/chaos/p12_019_resilience_test.dart' as resilience;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  resilience.main();
}
