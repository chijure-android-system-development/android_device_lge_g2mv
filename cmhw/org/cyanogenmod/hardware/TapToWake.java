/*
 * Copyright (C) 2026 The CyanogenMod Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.cyanogenmod.hardware;

import android.os.SystemProperties;

import org.cyanogenmod.hardware.util.FileUtils;

import java.io.File;

/*
 * KnockON (double tap to wake) on the D625 Atmel S336 touch panel.
 *
 * The driver uses LG's LPWG interface: "1 1" selects double tap, "1 0"
 * turns gestures off. The node is write-only, so the state is kept in a
 * property; Settings restores it on every boot, which syncs the driver.
 */
public class TapToWake {

    private static final String CONTROL_PATH =
            "/sys/devices/virtual/input/lge_touch/lpwg_notify";
    private static final String STATE_PROP = "persist.sys.tap_to_wake";

    public static boolean isSupported() {
        return new File(CONTROL_PATH).exists();
    }

    public static boolean isEnabled() {
        return SystemProperties.getBoolean(STATE_PROP, false);
    }

    public static boolean setEnabled(boolean state) {
        if (!FileUtils.writeLine(CONTROL_PATH, state ? "1 1" : "1 0")) {
            return false;
        }
        SystemProperties.set(STATE_PROP, state ? "1" : "0");
        return true;
    }
}
