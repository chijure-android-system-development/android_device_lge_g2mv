package com.lge.eula;

import android.app.Activity;
import android.os.Bundle;
import android.os.SystemProperties;

/**
 * Minimal stand-in for stock LG UnifiedEULA. Quick Remote starts this when
 * agreement is missing; we accept immediately so the app can stay open on CM.
 */
public class UnifiedEula extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        SystemProperties.set("persist.sys.lge.eula_agreement", "true");
        setResult(RESULT_OK);
        finish();
    }
}
