# LG D625 (g2mv) device tree

This tree is the CyanogenMod 11 bring-up target `cm_g2mv`. It builds the
LG/NVIDIA D625 kernel from `kernel/lge/d625` and uses proprietary files
extracted from stock D62510c. TWRP for this device lives in a separate
tree (`twrp-4.4/device/lge/g2mv`), including the twrpTar fork patch.

Vendor blobs live in
[android_vendor_lge_g2mv](https://github.com/chijure-android-system-development/android_vendor_lge_g2mv)
(`vendor/lge/g2mv`, branch `cm-11.0`). Add that project to a local manifest
(or clone it there) before building. To re-extract from a connected stock ROM:

```bash
device/lge/g2mv/extract-files.sh
```

Then configure the CM build with:

```bash
source build/envsetup.sh
lunch cm_g2mv-userdebug
make -j$(nproc) bacon
```

The CM port is initial bring-up work and must be tested through a temporary
boot/recovery workflow before any permanent installation. Back up every
LG/Icera partition listed below first.

## CyanogenMod 11 first boot (2026-10-14)

The `cm_g2mv-userdebug` target completed its first successful boot to the CM 11
launcher on real LG-D625 hardware. The validated bring-up configuration uses:

- the CM 11 Android 4.4.4 userspace built from this tree;
- the D625 source kernel from `kernel/lge/d625` (validated `3.4.65-g53190f9`)
  with the CM 11 ramdisk; stock `3.4.65-g2ebb907` remains as `prebuilt/kernel`;
- proprietary files extracted from the D62510c stock-system backup;
- CM's `audio_policy.default` with `configs/audio_policy.conf`; and
- `qemu.hw.mainkeys=0` for the on-screen navigation bar.

The stock `audio_policy.tegra.so` must not be installed. It was built against
LG's Android 4.4.2 media ABI and crashes in
`AudioPolicyManagerBase::getStreamVolumeIndex()`, killing `mediaserver` (Camera
reports "Media server died"). Use only CM `audio_policy.default`. `device.mk`
deletes stale `audio_policy.tegra.so` from `out/` and the vendor proprietary
tree on each build so incremental bacon cannot repackage it. On a live device,
rename it to `audio_policy.tegra.so.disabled` under `/system/lib/hw/`. The stock
NVIDIA primary audio HAL then opens successfully as output 2 at 48 kHz, and
speaker routing works.

### CM 11 bring-up status

Rows were first validated before the kernel baseline was pinned, so some mixed
the stock and source kernels. From 2026-10-15 every result names its kernel; see
[Kernel validation workflow](#kernel-validation-workflow). "Stock kernel" means
`3.4.65-g2ebb907` from D62510c; source kernel commits are from
`android_kernel_lge_d625`.

| Component | Status | Notes |
|---|---|---|
| Boot to launcher | Works | `sys.boot_completed=1` |
| Dalvik heap | Fixed | Stock 1 GB props (`growthlimit=96m`, `heapsize=256m`); stops SystemUI/Camera OOM |
| Display and EGL | Works | Source kernel validated on-device: RT8542 `lcd-backlight` only (PWM_PRISM off) |
| Touch and on-screen navigation | Works | Navigation bar forced with `qemu.hw.mainkeys=0` |
| ADB | Works | Available during boot and from TWRP |
| Primary audio and speaker routing | Works, experimental | Uses CM policy plus the stock NVIDIA primary HAL |
| Wi-Fi | Works | Source kernel + matching `bcmdhd.ko`; `insmod` on boot |
| Auto-brightness / ALS | Works | APDS9930 `TYPE_LIGHT` + framework overlay curves |
| Cellular / SIM | Works, calls unreliable while asleep | Icera `productConfig`/`deviceConfig`; Claro PE on HSPA. Calls work while awake; incoming calls while the AP is in LP0 can be missed (see [Known issues](#known-issues-2026-10-15)) |
| Camera / Video | Partial | Stills, flash and recording work. The NV AVC encoder outputs ~170-180 kbps instead of the requested 4 Mbps (heavily pixelated). mediaserver heap corruption traced to CM's CVE-2017-13154 `freeNode` use-after-free; fix installed, validation pending (see [Known issues](#known-issues-2026-10-15)) |
| Flash / Torch | Works (stock and source kernel `a205a37`) | `RT8542-fled` + Torch overlay (127 = torch, 255 = strobe); sysfs `chmod 0666`. Source kernel: torch, photo flash and video torch validated, no resets; LED switches off when the camera closes |
| Vibrator | Works | max77660 haptic via `BOARD_HAS_VIBRATOR_IMPLEMENTATION` |
| NFC | Partial | PN547 polls; CORE_RESET_NTF after discovery recovered (skip NCI version check on NTF + `libnfc-nxp.conf` FW/standby). Tag read still needs a field test. `com.android.nfc` aborts in `applyRouting` (`libnfc_nci_jni`) on screen on/off |
| Bluetooth (BCM4334) | Works | BlueDroid + `libbt-vendor`; UART `ttyHS2`; FW patch loads; scan + classic bond OK (`LPM_SLEEP_MODE=FALSE` in `vnd_g2mv.txt`) |
| GPS (BCM4752 / glgps) | Stack up | `glgps`+`agpsd`+`gps.tegra`; UART `ttyHS1` @ 921600; nSTDBY gpio63; AGPS cell-ID OK (Claro PE). Outdoor TTFF still to confirm (0 sats indoors) |
| Suspend / wake | Works | Screen off/on + Tegra LP0 validated on stock and source kernels; baseband wakes the AP (`WAKE59, tegra_bb0`). USB holds `vbus-tegra-otg` and blocks LP0 while plugged, so sleep tests must be unplugged |
| Proximity + ALS (APDS9930) | Works | Patched `sensors.g2mv.so`. Source kernel binds `apds993x` for ALS; proximity needs kernel `8e1429c` (stock PS tuning: 16 pulses, 50 mA, gain 2x). Without it the screen never blanks in calls |
| Offline charge (chargerlogo) | Works | Stock `/sbin/chargerlogo` + init `chargerlogo` trigger; RT8542 backlight |
| KnockON (double tap to wake) | Works (source kernel `6945ca8`) | Settings > Display toggle (CMHW `TapToWake`); wakes from LP0 (`WAKE6, atmel_s336`); proximity check blocks it in a pocket. See [KnockON](#knockon-double-tap-to-wake). Stock kernel: detection only, never wakes the screen |
| IR blaster (UEI MXQ616) | Works | Stock QuicksetSDK + LGQRemote; UART `ttyHS3` @ 230400, `ttyAS1` symlink; blaster FW version read OK |

### Offline charge (chargerlogo)

With the phone powered off, the D625 bootloader boots the kernel with
`androidboot.mode=chargerlogo`. Stock LG ships `/sbin/chargerlogo` in the
ramdisk and a patched `init` that runs the `on chargerlogo` trigger (after
mounting `/system` for `vendor/etc/chargerimages`) before `early-boot`/`boot`.

CM's AOSP `init` only treated `mode=charger`, so the phone booted the full
framework instead of the charge animation. This tree:

- packages stock `prebuilt/chargerlogo` into the ramdisk (string-patched to
  use `/sys/class/leds/lcd-backlight/brightness` for RT8542);
- keeps `on chargerlogo` in `init.grey.rc`;
- requires `patches/init-chargerlogo.patch` applied under `system/core`.

```bash
patch -p1 -d system/core < device/lge/g2mv/patches/init-chargerlogo.patch
```

### Infrared (IR)

The D625 has **two** IR-related blocks. Proximity/ALS use the Avago APDS9930;
the UEI IR blaster uses the stock Quick Remote stack (path A).

| Hardware | Role | CM 11 status |
|---|---|---|
| APDS9930 | Proximity + ambient light | Works (`TYPE_PROXIMITY` + `TYPE_LIGHT`) |
| UEI MXQ616 (`uei_irrc`) | IR blaster / Quick Remote | Stock QuicksetSDK + LGQRemote over UART `ttyHS3` @ 230400 |

Kernel `uei_irrc` only toggles reset + LED LDO GPIOs. The protocol runs on
UART HS3. This tree ships stock blobs under `prebuilt/uei/`:

- `QuicksetSDK.apk` — resigned with the platform cert (`sharedUserId=android.uid.system`)
- `LGQRemote.apk` — Quick Remote UI (dex-patched; do not full-apktool-rebuild on KK):
  - stub `LEDHandler` (stock needs missing `com.lge.systemservice.core.LGContext`)
  - forces Quickset `selectRegion(8)` (China lite DB) so TCL codesets exist
  - featured TV list uses China brands (Konka/Changhong/TCL/Haier/Hisense/Skyworth)
- `UnifiedEULA` (`uei-eula-stub/`) — CM stub; stock EULA crashes without LG telephony.
  Provider always reports `agreement=1` so Quick Remote can open
- `ro.build.target_region=SCA` / `target_country=PE` / `target_operator=OPEN`
  (carrier props); IR codesets come from the forced China region above, not LatAm
- `qremote_conf.xml` — keep `lite_db=true` for D625 (full DB path OOMs/crashes Quickset)
- `com.uei.control.jar` + permissions XML, `librctransport.so`
- `serialport.txt` → `TRUE,/dev/ttyHS3,230400`
- `init.grey.rc` symlink `/dev/ttyAS1` → `/dev/ttyHS3` (hardcoded in `librctransport`)

Known limit: AOC is not in the shipped Quickset lite brand list (China/USA/Asia
searches return empty). TCL setup works (codeset test). For AOC, try compatible
brands from **Otros** if present, or path B ConsumerIr later.

No `android.hardware.consumerir` HAL yet. Qualcomm `g2m` SwIRRC is not
applicable on Tegra.

#### Path B: consumerir (research 2026-10-16, not implemented)

How other LG ports did it:

| Device | IR hardware | CM/Lineage approach |
|---|---|---|
| G2 (msm8974), G3, G4, V10, G5 | UEI chip on UART `/dev/ttyHSL1` @ 115200, kernel `lge_uei_irrc` (reset GPIO + LDOs only, like our `uei_irrc`) | `consumerir.<board>.so` calling LG's `libcir_driver.so` (G2 [f2360a69](https://github.com/CyanogenMod/android_device_lge_g2-common/commit/f2360a69e6419fa4d3866796d658bb9e8c704f9a), G3 [68df0c18](https://github.com/CyanogenMod/android_device_lge_g3-common/commit/68df0c182b2cdce03fb35a4943cef29f96e335cd); open wrapper in [LineageOS lge common](https://github.com/LineageOS/android_device_lge_common/blob/master/consumerir/ConsumerIr.cpp)) |
| G2 Mini D620, L70, L90 (msm8226), G Pad 7 | Audio-codec PWM, no UEI | [Audio IRRC HAL](https://github.com/LineageOS/android_device_lge_msm8226-common/blob/cm-14.1/consumerir/consumerir.c); not applicable |
| G3 KitKat ROMs | UEI | Stock `LGQRemote` + `QuicksetSDK` (what this tree does), `chmod 666` on the UART, fake `target_country`/`operator` props |
| LeEco msm8996 | UEI | HAL relays to the stock UEI QuickSet service (`com.uei.control.IControl`) |

`libcir_driver.so` (taken from LG G3 Lollipop blobs) exports
`transmitIr(const char *dev, int baud, int freq, int pattern[], int len)`.
It converts a raw ConsumerIr pattern into UEI's "learner buffer" (frequency,
timing table, data table, checksum), wakes the chip, writes the buffer and
reads the reply. It accepts exactly **115200 or 230400** baud (B115200/B230400
in its literal pool), takes the device path as a parameter, and depends only
on `liblog`/`libc`/`libm`/`libdl`/`libstdc++`, so it should load on KitKat.
The two Lineage wrappers disagree on `len` (element count in the C HAL, bytes
in HIDL), so test both.

Plan for the D625:

1. Write a small `consumerir.g2mv.so` that calls `transmitIr("/dev/ttyHS3",
   230400, freq, pattern, len)`, with `uei_irrc` raising reset and the LED LDO,
   and `android.hardware.consumerir.xml`. Any ConsumerIrManager app would
   then work, without LG's EULA stub or the dex-patched QuickRemote.
2. If the chip rejects that framing, use a LeEco-style bridge to our working
   QuicksetSDK service instead. LG's `IControl` uses `sendIRPattern` =
   transaction 16 and `getLastResultCode` = 13, after
   `ISetup.getSession()`/`activateQuicksetService(token)`.

No public documentation of the UEI UART protocol was found; the framing lives
in `libcir_driver.so`.

### GPS

Broadcom **BCM4752** via UART `ttyHS1` @ 921600, userspace `glgps` + HAL
`gps.tegra.so`, AGPS assist through Icera `agpsd` (`/dev/ttySHM3` / `at_pal`).

Validated on CM11:

- `init.svc.gps-daemon` / `agps-daemon` running; `gpsEnabled=true`
- Session opens `/dev/ttyHS1` and drives nSTDBY `gpio63` high
- Cell-ID aiding works (`AT%IECELLID`, MCC/MNC 716/10 Claro PE)
- LTO file updates under `/data/gps/lto2.dat`

Device-tree tweaks vs stock:

- `ueventd`: `/dev/ttyHS1` owned `gps:system`
- `init.grey.rc`: `gpio63/value` owned `gps:system` mode `0660` (glgps must write nSTDBY)
- `configs/gps.conf` overlay: `NTP_SERVER=south-america.pool.ntp.org`

Do **not** load `gps_drv.ko` (TI shared-transport driver; wrong stack).
Outdoor TTFF / satellite lock still needs a sky-view check.

### Bluetooth

Broadcom **BCM4334B0** over UART `ttyHS2`, BlueDroid + `libbt-vendor`, firmware
`BCM4334B0_002.001.013.1675.1765_RC.hcd`. Runtime UART/FW:
`configs/bt_vendor.conf`. Compile-time vendor flags:
`bluetooth/vnd_g2mv.txt` via `BOARD_BLUEDROID_VENDOR_CONF`.

LGE `bluedroid_pm` exposes `/proc/bluetooth/sleep/{btwake,proto}` (not AOSP
bluesleep `lpm`/`btwrite`). With stock `LPM_SLEEP_MODE=1` and no matching wake
path, the controller slept mid-HCI and bonding failed (`HCI Cmd tout` → BT
process restart) while inquiry still worked. `vnd_g2mv.txt` sets
`LPM_SLEEP_MODE=FALSE` until wake is wired to those proc nodes.

Validated on CM11: adapter on, local name `LG G2 mini`, FW patch load OK,
inquiry + classic bond (Mac Pro LinkKey stored). BDADDR from `btmacwriter` →
`persist.service.bdroid.bdaddr` (locally administered); stock `bdaddr_loader`
stays disabled unless a factory address path is wired.

### Source kernel (CM11 backlight)

`BoardConfig.mk` builds from `kernel/lge/d625` (`pda_android_defconfig`). The
stock prebuilt remains at `prebuilt/kernel` as fallback if that tree is missing.

Black-panel root cause on earlier source builds was **not** DTB (this board uses
platform panel data; `dsi dt support not available` is expected). The GPL panel
timings for TIANMA asked for DSI HS 225500 while `pll_d_out0` locks at
~222.3 MHz, so `tegradc` logged `can't divide … to 37507000` and called
`dsi_l_540p_4_7_disable`. Fixes in the kernel tree:

- TIANMA/TOVIS `tegra_dc_mode` timings matched to the shipping D62510c zImage
  (HS clock 222500; no divide failure)
- `# CONFIG_BACKLIGHT_PWM_PRISM is not set` + `rt8542_bl_enable(true)` so CM
  drives RT8542 `leds/lcd-backlight`
- host `dtc` fix (`extern YYLTYPE yylloc`) for modern flex/bison
- TLK/zram options aligned with the shipping D625 kernel

### Wi-Fi

Source builds pack `bcmdhd.ko` with the same vermagic as the kernel.
`BoardConfig.mk` sets `WIFI_DRIVER_MODULE_PATH` and `init.grey.rc` `insmod`s
the module on boot. Validated on-device (STA to a WPA2 AP).

Do **not** load a `bcmdhd.ko` built for a different kernel revision —
mismatched modules caused timer-list corruption and a panic in
`kernel/timer.c:1089`.

### Ambient light / auto-brightness

Stock board code bound APDS9130 (PS only) on newer revs, so CM never saw
`light_sensor`. The kernel now always registers `apds993x` (ALS+PS). Userspace
needs:

- `prebuilt/sensors.g2mv.so` — patched stock HAL: exposes `TYPE_LIGHT`, uses
  `/sys/class/input/input0/device/{enable,poll_delay}`, runtime name fixup
- overlay `config_automatic_brightness_available` + LUX/backlight arrays
- kernel: accept HAL `poll_delay` in nanoseconds; force ABS_MISC updates when
  lux is unchanged so `input_report_abs` keeps delivering samples
- `init.grey.rc` chown/chmod on ALS/PS sysfs nodes for `system`

### Cellular / Icera SIM

Without stock Icera config blobs the modem stays at `AT+CFUN=0`, reports
`%ICFG: productConfig: not present` / `deviceConfig: not present`, and every
`AT+CLCC` fails (framework `gsm.sim.state=UNKNOWN`). This tree ships them under
`prebuilt/icera/` (also listed in `proprietary-files.txt`):

- `productConfig.bin` + `default_calibration.bin` →
  `/system/vendor/firmware/data/config/` (RFS symlink)
- `deviceConfig.bin` → `/system/vendor/firmware/data/factory/`, seeded onto
  MDM `/mnt/modem/data/factory/` when missing (`init.icera_g2mv.rc`)

Validated on-device: `gsm.sim.state=READY`, operator Claro (`71610`), `HSPA`.

### Known issues (2026-10-15)

Logs for everything below are in the build tree under `device-logs/`
(`stepA-*`, `stock-g2ebb907-*`, `video-reset-*`, `reboot-loop-*`).

#### mediaserver heap corruption

`mediaserver` aborted with `heap corruption detected by dlmalloc/dlfree/
tmalloc_large`, on both kernels. The abort site is only where the damage is
*noticed* (`~OMXCodec`, `~MemoryDealer`, `OMX::allocateNode`,
`MediaCodecList`, `AString`, `~CallbackDispatcher`). In every case it is the
first heap operation after an OMX node is destroyed.

**Root cause, fix pending device validation (2026-10-16):** CM 11's backport of
CVE-2017-13154 (`frameworks/av` commit `9745c8f66`, "use a lock around
OMX::freeNode") puts a function-scope `Mutex::Autolock _l(mLock)` in
`OMXNodeInstance::freeNode`. KitKat's `freeNode` ends in `delete this`, so the
lock's destructor unlocks `mLock` inside the already freed instance. `mLock` is
the instance's first member, so the unlock's atomic decrement writes 0 over
dlmalloc's free-chunk `fd` link. The next malloc or free that walks that bin
aborts. This is a CM bug, not an NVIDIA one:

- It hits software codecs too (UI sounds, `OMX.google.*` thumbnails).
- It is intermittent: it depends on whether the freed chunk coalesced.
- `libc.debug.malloc` hides it, because the heap layout changes.
- The old "skip freeNode for the NVIDIA encoder" workaround only helped
  because it avoided this path for one node.
- LG's stock `libstagefright_omx` has no lock there. CM's own follow-up
  (`BOARD_SKIP_CVE_2017_13154`) notes that the change "breaks playback on some
  devices".

Fix in `patches/frameworks-av-omx-node-instance.patch`: keep the lock around
`destroyComponentInstance()` (what the CVE needs), but end its scope before
`delete this`. It is installed on the device; the recording, playback and
sound test is pending. Once that test passes, drop the workarounds that only
masked this bug: NV encoder freeNode skip + `MemoryDealer` leak, mediaserver
recycle in `CameraService`, `persist.camera.skip_video_thumb`, and the
thumbnail NV skips below. Then recheck the encoder bitrate.

Found by elimination. Each of these was ruled out on the device first:

| Hypothesis | Result |
|---|---|
| UI sounds / FFmpeg extractor | Not the cause. Malloc debug blamed `libavutil`, a false positive (KK `posix_memalign` bypasses the tracker) |
| `BufferMeta` copy overflow | Bounds checks added, never fired (`useBuffer` path) |
| `requires-allocate-*` quirks for `OMX.Nvidia.*` | No effect; reverted |
| Late NVIDIA buffer callbacks after free | Guard in `OMXNodeInstance::onMessage` (validates against `mActiveBuffers` under `mLock`), zero hits |
| Blob ABI mismatch (audio/camera/OMX structs, vtables) | Audited against LG's 4.4.2 framework libs: compatible. Only `libaudioavp` → `IMediaPlayerService` vtable slot 19 (NVIDIA-added; lands on CM's `updateProxyConfig`) differs, and only on ULP/offload paths this tree does not enable |
| `persist.camera.disable_meta=0` (metadata buffers) | Crashes unchanged; video still pixelated |

Changes kept from the hunt (all in the two `frameworks-av-*` patches):

- `OMXCodec::Create` skips `OMX.Nvidia.*` decoders for
  `kClientNeedsFramebuffer`, so thumbnails use software.
  `StagefrightMetadataRetriever::isYUV420PlanarSupported` no longer
  instantiates the NVIDIA decoder just to read its color formats.
- `OMX::allocateNode` logs failures with `ALOGW` and the error code (was
  `ALOGV`).
- The `onMessage` late-callback guard and the copy bounds checks stay as
  hardening.

LG's own `OMXCodec::configureCodec` additionally sets
`OMX.Nvidia.index.config.waitOnFence` (flag 0x200) and
`OMX.Nvidia.index.config.thumbnailMode` (flag 0x400, `OMX.Nvidia.*` only), with
a 12-byte `{nSize, nVersion 1.0.0.0, bEnabled}` struct. CM does neither. That
is not needed for the crash, but it is a reference if NVIDIA decoders
misbehave.

NVIDIA has not published source for `libnvomx`/`libnvmm*`. `libnvomx.so` only
talks OpenMAX IL plus the five KitKat extensions (`enableAndroidNativeBuffers`,
`useAndroidNativeBuffer`, `getAndroidNativeBufferUsage`,
`storeMetaDataInBuffers`, `prependSPSPPSToIDRFrames`).

#### Abort deadlock (fixed)

When `dlfree` found corruption it called `abort()` with the malloc lock held.
`raise()` went through `pthread_kill()`, which takes `gThreadListLock`; a thread
holding that lock while waiting for malloc deadlocked the process. mediaserver
then hung forever instead of restarting. `Ringer.ring()`, `ToneGenerator` and
the in-call UI blocked on audio binder calls, so **incoming calls rang on the
caller's side but never showed on the phone**.
`patches/bionic-raise-tgkill.patch` makes `raise()` call `tgkill()` directly
(the upstream Lollipop fix). Validated: later corruptions killed mediaserver and
it restarted in about a second.

#### Incoming calls while asleep

There are two separate causes:

1. The mediaserver hang above (fixed by the bionic patch).
2. The modem sometimes drops registration (`+CREG: 2` then `0`) while the AP is
   in LP0, and the network never pages it. Claro then sends a "Te llamé" SMS.
   In the test spot 2G RSSI was about 5 (-103 dBm, emergency only) and 3G was
   marginal, so coverage is a likely factor. One outgoing call failed with
   `+CEER: There was a mobility management failure`. Not yet compared with the
   LG stock ROM in the same spot.

The baseband wake path works on both kernels: the AP resumes on
`WAKE59, tegra_bb0` and `RING` is delivered when the modem gets the page.

#### Video bitrate

`MPEG4Writer` asks for 4096 kbps (profile 480p is 2.5 Mbps video), but recorded
files measure about 171 kbps of video. I-frames are about 2.6 KB at 720x480.
`OMXCodec::setupBitRate` sets `OMX_Video_ControlRateVariable` and the component
accepts it without error. Unchanged with metadata buffers
(`persist.camera.disable_meta=0`), 2026-10-16. Next: once the freeNode fix
lets the encoder tear down cleanly, read back `OMX_IndexParamVideoBitrate`
and both port definitions after `setupBitRate` (check `xFramerate`; tiny
I-frames suggest a bogus frame rate in the bits-per-frame budget), then try
`OMX_IndexConfigVideoBitrate` after `OMX_StateExecuting`, or CBR.

#### Unexplained hardware reset

One hard reset happened while recording video, with mediaserver malloc debug on
(`pda.bootreason=coldboot`, `lge.bootreason=0xffffffff`). The phone came back
in `chargerlogo` mode with the full framework running. It did not reproduce in
later recordings with `/proc/kmsg` streamed to the host. `ram_console` is
configured but its region is empty (`00000000-00000000 : ram_console`), so
`/proc/last_kmsg` is unavailable. Reserving it is a pending kernel task.

**Device**: LG G2 Mini LTE / LG-D625  
**Codename**: g2mv  
**SoC**: NVIDIA Tegra 4i  
**CPU**: ARM Cortex-A9  
**Display**: 540x960, 32 bpp  
**Recovery base**: TWRP 3.1.1 / Android 4.4

This device tree builds a bootable TWRP recovery for the LG D625. It has been
tested on a D625 with firmware D62510c, both through `fastboot boot` and
installed to the recovery partition (SOS).

The stock bootloader rejects unsigned recovery images. The D625 needs the
patched EBT from
[lg-d625-tegra-bootloader-patch](https://github.com/chijure-android-system-development/lg-d625-tegra-bootloader-patch).
Prebuilt images are published in that repository's releases.

| Feature | Status |
|---|---|
| Display, touch, brightness, battery | Works (EMC floor fixes lines without USB) |
| ADB | Works |
| Internal storage (`/data/media`) | Works |
| Backup of System, Data and Boot (1945 MB, split archive) | Works, MD5 verified |
| Backup of LG/Icera partitions (MDM, CST, MPT, ...) | Works, matches raw `dd` dumps |
| Restore of Boot, System (split archive) and Data | Works, Android boots |
| Recovery via hardware keys (Vol- + Power taps) | Works |
| MicroSD (vfat): mount, read/write, backup to card | Works |
| MTP, exFAT, `/data` decryption | Not included |

## Entering recovery

### From Android or TWRP

```bash
adb reboot recovery
```

`adb reboot bootloader` (or TWRP's Reboot → Bootloader) opens fastboot. The
bootloader contains an NVIDIA menu for that mode ("Press <Volume Down> to
select, <Volume Up> for selection move", with a "Recovery mode" entry); this
path has not been tested yet. There is no key combination that enters
fastboot from power-off.

### With the keys (phone off)

The well-known LG combo ("release Power at the logo and press it again") does
not work on the D625. Tested sequence:

1. Power off and **unplug the USB cable**. The combo is ignored with USB.
2. Hold **Vol-** and keep it held until TWRP appears.
3. Hold **Power** until the LG logo appears.
4. **Release Power** as soon as the logo appears.
5. Immediately **tap Power 2-3 times**: press about 0.3 s, release about
   0.3 s. Very quick taps are not counted.
6. The "Factory Reset" screen appears and is confirmed by the held Vol-.
   TWRP starts.

This build sets `TW_IGNORE_MISC_WIPE_DATA`, so **no data is wiped** even though
the screen says "Factory Reset". Do not use this combo with stock recovery or
with a TWRP build without that flag: the bootloader writes
`recovery\n--wipe_data` to MSC and stock recovery will wipe `/data`.

Vol+ with USB connected enters LG download (LAF) mode instead.

### Why this sequence

Reverse-engineered from the D62510c bootloader (`LgeBootMain`, EBT offset
`0xc9d8`) and the D625 kernel (`arch/arm/mach-tegra/lge/board-pda-kbc.c`).
The power key is the MAX77660 `EN0` input; its interrupt register `GLBINT1`
(`0x07`) clears on read: press = `EN0_F` (`0x40`), release = `EN0_R` (`0x80`),
held 1 s = `EN0_1SEC` (`0x20`).

| Bootloader step | Requires | Window |
|---|---|---|
| Power-on check | Power held for at least 1 s | — |
| Boot-mode check | Vol- held, no USB cable (cable type `0xc`) | instant |
| Phase 1 | any new Power event (the release) | 0.75 s |
| Phase 2 | a read equal to `0x80` (a clean release) | 2.25 s |
| Phase 3 | another clean release while Vol- is held | 2.25 s |
| Factory Reset screen | Vol- confirms; Vol+ cancels and reboots | 10 s |

The register is polled every 150 ms, so a press and release inside the same
poll read as `0xc0` and are ignored. That is why taps must be slow.

## Important display settings

The Tegra framebuffer has padding at the end of each row. These settings are
required to avoid a stretched or slanted interface:

```make
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"
DEVICE_RESOLUTION := 540x960
RECOVERY_GRAPHICS_FORCE_USE_LINELENGTH := true
RECOVERY_GRAPHICS_FORCE_SINGLE_BUFFER := true
TW_THEME := portrait_hdpi
```

### Display glitches without USB

Without USB nothing in recovery requests memory bandwidth, and EMC drops to
25.5 MHz. The display controller then cannot fetch the 540x960x32bpp
framebuffer (about 124 MB/s at 60 Hz) and short white horizontal lines appear.
With USB connected the UDC keeps EMC at 102 MHz or more, which hides it.

`recovery/root/init.recovery.g2mv.rc` mounts debugfs and sets the shared
`floor.emc` clock to 102 MHz on boot. Measured unplugged: before, EMC spent
seconds at 25.5 MHz with visible lines; after, it never went below 102 MHz and
no lines appeared.

`portrait_hdpi` has a 9:16 reference resolution and therefore scales evenly to
the D625 panel. The recovery header displays `3.1.1-1 by chijure` through
`TW_DEVICE_VERSION` and `TW_BUILD_AUTHOR`.

The file `recovery/graphics.c` is retained as a historical Tegra 4i reference
from the NVIDIA S8515/Wiko Wax device tree. It is not compiled by this tree;
the validated build uses TWRP's standard fbdev backend with the two settings
above.

## Boot image layout

The values were read from the original LG recovery image. The partition size
comes from the kernel GPT; nvflash reports 16 MiB for SOS, but the last 4 MiB
belong to the following DTB partition.

| Field | Value |
|---|---:|
| Kernel address | `0x10008000` |
| Ramdisk address | `0x11000000` |
| Second address | `0x10f00000` |
| Tags address | `0x10000100` |
| Page size | `2048` |
| Command line | `androidboot.hardware=g2mv vmalloc=440M` |
| Recovery/boot partition size | `12582912` bytes |

## Kernel

Default CM builds use sources at
[android_kernel_lge_d625](https://github.com/chijure-android-system-development/android_kernel_lge_d625)
(`TARGET_KERNEL_SOURCE := kernel/lge/d625`). `prebuilt/kernel` is the unmodified
stock LG kernel from firmware D62510c (SHA-256 below) kept as a known-good
fallback. The recovery (SOS) image may still use the stock prebuilt until the
source kernel is validated on-device. Its SHA-256 is:

```text
7273a61c75b31d6c5e620bb2ea6dd4cea53a8326e71438b43600acf8b8b67b38
```

To regenerate it from your own stock boot image, stock recovery image or a
TWRP `boot.emmc.win` backup:

```bash
device/lge/g2mv/extract-kernel.py boot.emmc.win
```

The script refuses any kernel with a different SHA-256.

### KnockON (double tap to wake)

The Atmel S336 already detects the double tap in hardware (LPWG object T93);
LG's framework armed it through `lge_touch/lpwg_notify` and woke the screen
on the `TOUCH_GESTURE_WAKEUP` uevent. CM has neither, so it is wired the
CyanogenMod way (as `android_kernel_lge_msm8226` does for the same driver)
with a proximity check on top:

| Layer | Piece |
|---|---|
| Kernel `atmel_s336` | On T93 (and T24) while suspended, report `KEY_WAKEUP`. 1.5 s later, if still suspended, re-arm gesture mode; otherwise a declined wake left the chip in active mode and KnockON dead |
| Kernel `apds993x` | On PS enable: arm "far" thresholds, measure the first valid cycle (STATUS.PVALID), and report it 40 ms later from a delayed work, always as a fresh event |
| `sensors.g2mv.so` | `setInitialState()` no longer queues its hardcoded 5.0 (far) event (binary patch at 0x3078) |
| `keylayout/atmel_s336.kl` | Leaves scancode 143 unmapped (`Generic.kl` maps it to `POWER`, which wakes without any check) |
| `keyhandler/` | `com.cyanogenmod.keyhandler` `DeviceKeyHandler`: scancode 143 → `PowerManager.wakeUpWithProximityCheck()` |
| `cmhw/TapToWake` | Settings toggle: writes `1 1` / `1 0` to `lpwg_notify`, state in `persist.sys.tap_to_wake` |
| Overlay | `config_proximityCheckOnWake=true`, `config_deviceKeyHandlerLib/Class` |

Why the proximity path needed three fixes: CM's check enables the sensor
after the tap and takes the *first* event within 250 ms. The HAL invented a
"far" first event, the input core dropped an unchanged ABS value, and an
event raised inside the enable call reached KitKat's `SystemSensorManager`
before the listener had registered the sensor, so it was discarded and the
timeout woke the screen.

LG's stock ROM instead keeps the proximity sensor on for as long as the
screen is off (visible on the stock ROM) and gates the uevent itself. The CM
design only powers the IR LED for about 50 ms per tap.

Measured wake latency: about 0.6 s from tap to `mxt_fb_resume`. After boot,
`glgps` holds the `GPSD` wakelock for about 5 minutes while it initialises
the chip, so LP0 (and an LP0 KnockON test) only starts after that.

### Performance (2026-10-16)

The GPU benchmark is QApp ROM Tester's "GPU benchmark (uncapped)". It renders
offscreen into an FBO, timed with `glFinish()`, so the 60 Hz vsync does not cap
it. The on-screen OpenGL test always reads 60 because the panel refreshes at
60.000 Hz.

| Run | Fill Mpix/s | ALU Mpix/s | Texture Mtexel/s | Geometry Mtri/s | Scene 1280x720 FPS |
|---|---|---|---|---|---|
| Other D625, LG stock D62510c (kernel `g95972ac`) | 452.8 | 15.5 | 520.7 | 47.8 | 78.6 |
| This D625, CM 11, source kernel `a205a37` | 308-353 | 13.7-15.1 | 466-500 | 41-47 | 71-74 |
| This D625, CM 11, stock kernel `g2ebb907` | 356.0 | 14.1 | 467.6 | 40.2 | 73.2 |

Both ROMs use the same GLES driver (`OpenGL ES 2.0 17.01342`). Ruled out on
this unit as causes of the gap:

- the CPU governor;
- the NVIDIA power stack (now running);
- the kernel (stock and source give the same results);
- clocks: GPU 595.2 MHz and EMC 518.4 MHz (the top of the EMC table) are
  reached during the run, with no thermal throttling at 42-49 C;
- SurfaceFlinger composition: all layers go to HWC overlays.

The fill-rate gap is the most memory-bound test and points to unit-to-unit
variation. Confirming that needs both ROMs on the same unit.

NVIDIA power stack: `ussrd` loads the `libgov_*` governors and `powerservice`
uses `libpowerservice_client.so`, with the profile table `/system/etc/power.g2mv.rc`.
The first extract was missing all of these, so `ussrd` exited every 5 s and
`powerservice` crash-looped. `vendor/lge/g2mv` now ships them.

On the source kernel, cpu0 stayed on the `conservative` governor because the
`interactive` switch in `on boot` does not stick there.
`init.grey.rc` re-applies LG's interactive setup on `sys.boot_completed=1`.

### Kernel validation workflow

The flashed `boot` partition keeps the **stock kernel** (`3.4.65-g2ebb907`) as
the daily baseline. Source kernels are only tried in RAM, one commit at a time,
until they pass the full hardware matrix:

```bash
adb reboot bootloader
fastboot boot boot-<commit>.img   # a reboot falls back to the flashed stock kernel
```

- Commit every kernel change before building, so `uname -r` carries a clean
  hash (no `-dirty`) and each image maps to exactly one commit.
- The source kernel compares module vermagic with `strcmp`, and the vermagic
  includes the git hash. `/system/lib/modules/bcmdhd.ko` must come from the same
  build as the kernel under test, or Wi-Fi will not load. The stock kernel
  accepts any vermagic. (Pending: ship `bcmdhd.ko` in each boot image's ramdisk.)
- Any failure is A/B tested on the stock kernel before blaming the source
  kernel. Today that ruled out the kernel for calls and mediaserver crashes.

Source kernel status (`cm-11.0` branch):

| Commit | Change | Status |
|---|---|---|
| `79897f0` | Panel timings, RT8542 backlight, `apds993x` ALS | Boots (screen ready in 12.8 s); Wi-Fi, SIM, sensors OK. Proximity regressed |
| `8e1429c` | `apds993x` stock PS tuning (16 pulses, 50 mA, gain 2x) | Calls blank the screen (ear ~990-1023, far ~110-160, thresholds 900/800) |
| `0b46c6a`..`6945ca8` | KnockON wake key, apds993x real initial PS state, re-arm after a declined wake | Validated: toggle, pocket, re-arm, wake from LP0, in-call proximity (first event at 40 ms, screen off ~200 ms after near) |
| `4ed1762`, `08b479a`, `a205a37` | RT8542 flash: never change mode with the strobe GPIO high (it lights the LED in torch *and* flash mode, so it must be raised for torch too), ignore same-mode rewrites, switch off on NVC release | Validated (step C): Torch app, photo flash, video torch, LED off when the camera closes without PWR_WR off. No PMIC reset in these tests |


When the image is built in the Docker Desktop container, the VM file share can
serve stale inodes after a host-side `git commit`. The container then sees the
old ref and index and stamps the kernel `-<old hash>-dirty`. Resync from inside
the container (`git update-ref` + `git reset -q`) and check `vermagic` before
using the image.

## Partitions

The recovery uses the Tegra by-name paths exposed by the stock kernel:

| Mount point | Type | Partition |
|---|---|---|
| `/recovery` | emmc | `SOS` |
| `/boot` | emmc | `LNX` |
| `/system` | ext4 | `APP` |
| `/cache` | ext4 | `CAC` |
| `/data` | ext4 | `UDA` |
| `/misc` | emmc | `MSC` |
| `/staging` | emmc | `USP` |
| `/encrypt` | emmc | `MDA` |
| `/external_sd` | auto | external microSD partition 1 |

The data crypto footer lives in `MDA`, as in the stock fstab. This build does
not include decryption support, so an encrypted `/data` cannot be backed up.

These LG/Icera partitions are offered as optional raw-image backups. Back them
up once before installing any ROM:

| Mount point | Partition | Size |
|---|---|---:|
| `/modem` | `MDM` (Icera modem, ext4) | 16 MiB |
| `/cust` | `CST` (carrier customization, ext4) | 50 MiB |
| `/mpt` | `MPT` | 16 MiB |
| `/pst` | `PST` | 8 MiB |
| `/sns` | `SNS` | 8 MiB |
| `/rct` | `RCT` | 2 MiB |
| `/drm` | `DRM` | 8 MiB |
| `/sep` | `SEP` | 2 MiB |

## Build (CM 11)

```bash
source build/envsetup.sh
lunch cm_g2mv-userdebug
make -j$(nproc) bacon
```

For TWRP recovery builds and the twrpTar fork patch, use the dedicated
`twrp-4.4/device/lge/g2mv` tree instead of this CM 11 device tree.

### Patches outside this tree

Changes to LineageOS projects live in `patches/` and must be applied before
building:

| Patch | Apply in | Purpose |
|---|---|---|
| `init-chargerlogo.patch` | `system/core` | `androidboot.mode=chargerlogo` offline charging |
| `libnfc-nci-reset-ntf-version.patch` | `external/libnfc-nci` | PN547 CORE_RESET_NTF recovery |
| `bionic-raise-tgkill.patch` | `bionic` | `raise()` uses `tgkill`; fixes the abort deadlock that hung mediaserver |
| `frameworks-av-nv-camera-encoder-workarounds.patch` | `frameworks/av` | Camera YUV path switch, NV encoder leak, mediaserver recycle, software decoders for thumbnails, no NVIDIA color-format probe |
| `frameworks-av-omx-node-instance.patch` | `frameworks/av` | **`freeNode` use-after-free fix** (CVE-2017-13154 lock scope), late-callback guard, OMX copy bounds, `allocateNode` failure logging |
| `camera2-nv-video-workarounds.patch` | `packages/apps/Camera2` | EIS off, skip video thumbnails, 480p default |

```bash
patch -p1 -d system/core < device/lge/g2mv/patches/init-chargerlogo.patch
patch -p1 -d external/libnfc-nci < device/lge/g2mv/patches/libnfc-nci-reset-ntf-version.patch
git -C bionic am ../device/lge/g2mv/patches/bionic-raise-tgkill.patch
git -C frameworks/av apply ../../device/lge/g2mv/patches/frameworks-av-nv-camera-encoder-workarounds.patch
git -C frameworks/av apply ../../device/lge/g2mv/patches/frameworks-av-omx-node-instance.patch
git -C packages/apps/Camera2 apply ../../../device/lge/g2mv/patches/camera2-nv-video-workarounds.patch
```

