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

package com.cyanogenmod.settings.device;

import android.content.Context;
import android.os.PowerManager;
import android.os.SystemClock;
import android.view.KeyEvent;

import com.android.internal.os.DeviceKeyHandler;

/*
 * KnockON: the Atmel S336 driver reports KEY_WAKEUP (scancode 143) for a
 * double tap while the screen is off. atmel_s336.kl leaves it unmapped, so
 * the event reaches us instead of waking the device directly, and we wake
 * through PowerManager's proximity check (no wake with the sensor covered).
 */
public class KeyHandler implements DeviceKeyHandler {

    private static final int KEY_KNOCK_ON = 143;    // KEY_WAKEUP

    private final PowerManager mPowerManager;

    public KeyHandler(Context context) {
        mPowerManager = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
    }

    @Override
    public boolean handleKeyEvent(KeyEvent event) {
        if (event.getScanCode() != KEY_KNOCK_ON) {
            return false;
        }
        if (event.getAction() == KeyEvent.ACTION_UP && !mPowerManager.isScreenOn()) {
            mPowerManager.wakeUpWithProximityCheck(SystemClock.uptimeMillis());
        }
        return true;
    }
}
