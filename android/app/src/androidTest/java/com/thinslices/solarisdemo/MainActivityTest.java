package com.thinslices.solarisdemo; // replace "com.example.myapp" with your app's package

import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.Rule;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import io.qameta.allure.android.rules.ScreenshotRule;
import io.qameta.allure.android.rules.WindowHierarchyRule;
import pl.leancode.patrol.PatrolJUnitRunner;

@RunWith(Parameterized.class)
public class MainActivityTest {
    @Rule
    public ScreenshotRule screenshotRule = new ScreenshotRule(ScreenshotRule.Mode.END, "ss_end");
    @Rule
    public WindowHierarchyRule windowHierarchyRule = new WindowHierarchyRule();
    @Rule
    public AllureEnrichmentRule allureEnrichmentRule = new AllureEnrichmentRule();
    @Rule
    public FilteredLogcatRule filteredLogcatRule = new FilteredLogcatRule();
    @Parameters(name = "{0}")
    public static Object[] testCases() {
        PatrolJUnitRunner instrumentation = (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        // replace "MainActivity.class" with "io.flutter.embedding.android.FlutterActivity.class"
        // if in AndroidManifest.xml in manifest/application/activity you have
        //     android:name="io.flutter.embedding.android.FlutterActivity"
        instrumentation.setUp(MainActivity.class);
        instrumentation.waitForPatrolAppService();
        return instrumentation.listDartTests();
    }

    public MainActivityTest(String dartTestName) {
        this.dartTestName = dartTestName;
    }

    private final String dartTestName;

    @Test
    public void runDartTest() {
        PatrolJUnitRunner instrumentation = (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.runDartTest(dartTestName);
    }
}
