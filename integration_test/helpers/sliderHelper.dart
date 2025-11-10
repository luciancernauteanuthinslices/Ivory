import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';

// Read current slider percent from the Slider widget's value
int _readSliderPercent(PatrolIntegrationTester $, Finder slider) {
  final s = $.tester.widget<Slider>(slider);
  return s.value.round();
}

// Move slider to `targetPercent`. Works for any min/max.
Future<void> setSliderToPercent(
  PatrolIntegrationTester $, {
  required Finder slider,
  required int targetPercent,
  int? min,
  int? max,
}) async {
  await $(slider).scrollTo();

  final sliderWidget = $.tester.widget<Slider>(slider);
  final rect = $.tester.getRect(slider);

  final double sliderMin = (min ?? sliderWidget.min).toDouble();
  final double sliderMax = (max ?? sliderWidget.max).toDouble();

  final int clampedTarget =
      targetPercent.clamp(sliderMin.round(), sliderMax.round());

  int current = _readSliderPercent($, slider);
  if (current == clampedTarget) return;

  final double stepPx = rect.width / (sliderMax - sliderMin);
  final double left = rect.left + 1; // avoid tapping at extreme edges
  final double right = rect.right - 1;

  // First jump directly to the theoretical position
  final double t =
      ((clampedTarget - sliderMin) / (sliderMax - sliderMin)).clamp(0.0, 1.0);
  // Bias slightly to the left to avoid truncation rounding up to next int
  final double initialX =
      (rect.left + rect.width * t - 0.25 * stepPx).clamp(left, right);
  await $.tester.tapAt(Offset(initialX, rect.center.dy));
  await $.pumpAndSettle();

  current = _readSliderPercent($, slider);

  // Refine position using bounded binary search on x until value == target
  double loX, hiX;
  if (current < clampedTarget) {
    loX = initialX;
    hiX = right;
  } else if (current > clampedTarget) {
    loX = left;
    hiX = initialX;
  } else {
    loX = hiX = initialX;
  }

  const int maxSearchIters = 14;
  for (int i = 0; current != clampedTarget && i < maxSearchIters; i++) {
    final double midX = (loX + hiX) / 2.0;
    await $.tester.tapAt(Offset(midX, rect.center.dy));
    await $.pumpAndSettle();
    current = _readSliderPercent($, slider);

    if (current < clampedTarget) {
      loX = (midX + 0.5).clamp(left, right);
    } else if (current > clampedTarget) {
      hiX = (midX - 0.5).clamp(left, right);
    }
  }

  // Small local scan around the target if still off by 1
  if (current != clampedTarget) {
    final double targetX = (rect.left +
            rect.width *
                ((clampedTarget - sliderMin) / (sliderMax - sliderMin)))
        .clamp(left, right);
    // try within +/- 16 pixels with fine granularity
    for (double dx = -16; dx <= 16 && current != clampedTarget; dx += 0.5) {
      final double x = (targetX + dx).clamp(left, right);
      await $.tester.tapAt(Offset(x, rect.center.dy));
      await $.pumpAndSettle();
      current = _readSliderPercent($, slider);
    }
  }

  // Final directional nudges if still off by 1
  if (current != clampedTarget) {
    const int maxNudges = 6;
    int n = 0;
    while (current != clampedTarget && n < maxNudges) {
      final bool goLeft = current > clampedTarget;
      final double nudge = (goLeft ? -0.6 : 0.6) * stepPx;
      final double x = (rect.left +
              rect.width * ((current - sliderMin) / (sliderMax - sliderMin)) +
              nudge)
          .clamp(left, right);
      await $.tester.tapAt(Offset(x, rect.center.dy));
      await $.pumpAndSettle();
      current = _readSliderPercent($, slider);
      n++;
    }
  }

  // Gesture fallback: small drags from the current thumb position
  if (current != clampedTarget) {
    const int maxDrags = 16;
    int k = 0;
    while (current != clampedTarget && k < maxDrags) {
      final bool needLeft = current > clampedTarget;
      final double currentX = (rect.left +
              rect.width * ((current - sliderMin) / (sliderMax - sliderMin)))
          .clamp(left, right);
      final double dragDx = (needLeft ? -1.5 : 1.5) * stepPx;

      await $.tester.dragFrom(
        Offset(currentX, rect.center.dy),
        Offset(dragDx, 0),
      );
      await $.pumpAndSettle();
      current = _readSliderPercent($, slider);
      k++;
    }
  }

  expect(
    current,
    clampedTarget,
    reason: 'Slider value should be $clampedTarget%, but was $current%',
  );
}
