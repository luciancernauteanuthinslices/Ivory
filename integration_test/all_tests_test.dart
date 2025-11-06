// Import all test files here and call their registerTests() functions
import 'cardCanBeFrozenOrUnfreeze_test.dart' as cardCanBeFrozenOrUnfreeze;
import 'repaymentRateIsSaved_test.dart' as repaymentRateIsSaved;
// Add more test file imports as needed

void main() {
  // Register all test groups
  cardCanBeFrozenOrUnfreeze.registerTests();
  repaymentRateIsSaved.registerTests();

}
