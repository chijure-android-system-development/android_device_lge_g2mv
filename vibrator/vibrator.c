/*
 * max77660 haptic vibrator for LG D625 (g2mv).
 *
 * The stock kernel exposes a millisecond timeout via vibrator_enable
 * (same semantics as timed_output), not /sys/class/timed_output/vibrator.
 */
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

static const char * const kEnablePaths[] = {
    "/sys/class/input/event1/device/device/vibrator_enable",
    "/sys/devices/platform/tegra14-i2c.4/i2c-4/4-0023/max77660-vibrator/vibrator_enable",
};

static int open_vibrator(void)
{
    unsigned i;
    int fd;

    for (i = 0; i < sizeof(kEnablePaths) / sizeof(kEnablePaths[0]); i++) {
        fd = open(kEnablePaths[i], O_RDWR);
        if (fd >= 0)
            return fd;
    }
    return -1;
}

/* Required when USE_ALTERNATIVE_VIBRATOR hides AOSP vibrator_exists(). */
int vibrator_exists(void)
{
    int fd = open_vibrator();
    if (fd < 0)
        return 0;
    close(fd);
    return 1;
}

int sendit(int timeout_ms)
{
    int fd, nwr, ret;
    char value[20];

    fd = open_vibrator();
    if (fd < 0)
        return errno;

    nwr = sprintf(value, "%d\n", timeout_ms);
    ret = write(fd, value, nwr);
    close(fd);

    return (ret == nwr) ? 0 : -1;
}
