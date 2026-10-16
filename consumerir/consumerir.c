/*
 * Copyright (C) 2013 The Android Open Source Project
 * Copyright (C) 2026 The LineageOS Project
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

/*
 * ConsumerIr HAL for the UEI MXQ616 IR blaster of the LG D625 (g2mv).
 *
 * The chip sits on UART ttyHS3; the kernel uei_irrc driver only drives its
 * reset and LED LDO GPIOs. LG's libcir_driver.so (G2/G3 blob) turns a raw
 * ConsumerIr pattern into UEI's learner buffer and writes it to the UART.
 */

#define LOG_TAG "ConsumerIrHal"

#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include <cutils/log.h>
#include <hardware/consumerir.h>
#include <hardware/hardware.h>

#define UEI_DEVICE "/dev/ttyHS3"
#define UEI_BAUD   230400

/* From libcir_driver.so: returns 0 on success. */
extern int transmitIr(const char *dev, int baud, int carrier_freq,
        const int pattern[], int pattern_len);

static const consumerir_freq_range_t consumerir_freqs[] = {
    { .min = 30000, .max = 60000 },
};

static int consumerir_transmit(struct consumerir_device *dev __unused,
        int carrier_freq, const int pattern[], int pattern_len)
{
    int ret;

    if (pattern_len <= 0)
        return -EINVAL;

    ret = transmitIr(UEI_DEVICE, UEI_BAUD, carrier_freq, pattern, pattern_len);
    if (ret != 0) {
        ALOGE("transmitIr(freq=%d, len=%d) failed: %d", carrier_freq,
                pattern_len, ret);
        return -EIO;
    }
    return 0;
}

static int consumerir_get_num_carrier_freqs(struct consumerir_device *dev __unused)
{
    return sizeof(consumerir_freqs) / sizeof(consumerir_freqs[0]);
}

static int consumerir_get_carrier_freqs(struct consumerir_device *dev __unused,
        size_t len, consumerir_freq_range_t *ranges)
{
    size_t to_copy = sizeof(consumerir_freqs) / sizeof(consumerir_freqs[0]);

    if (len < to_copy)
        to_copy = len;
    memcpy(ranges, consumerir_freqs, to_copy * sizeof(consumerir_freq_range_t));
    return to_copy;
}

static int consumerir_close(hw_device_t *dev)
{
    free(dev);
    return 0;
}

static int consumerir_open(const hw_module_t *module, const char *name,
        hw_device_t **device)
{
    consumerir_device_t *dev;

    if (strcmp(name, CONSUMERIR_TRANSMITTER) != 0)
        return -EINVAL;
    if (device == NULL) {
        ALOGE("NULL device on open");
        return -EINVAL;
    }

    dev = calloc(1, sizeof(consumerir_device_t));
    if (dev == NULL)
        return -ENOMEM;

    dev->common.tag = HARDWARE_DEVICE_TAG;
    dev->common.version = 0;
    dev->common.module = (struct hw_module_t *) module;
    dev->common.close = consumerir_close;

    dev->transmit = consumerir_transmit;
    dev->get_num_carrier_freqs = consumerir_get_num_carrier_freqs;
    dev->get_carrier_freqs = consumerir_get_carrier_freqs;

    *device = (hw_device_t *) dev;
    return 0;
}

static struct hw_module_methods_t consumerir_module_methods = {
    .open = consumerir_open,
};

consumerir_module_t HAL_MODULE_INFO_SYM = {
    .common = {
        .tag                = HARDWARE_MODULE_TAG,
        .module_api_version = CONSUMERIR_MODULE_API_VERSION_1_0,
        .hal_api_version    = HARDWARE_HAL_API_VERSION,
        .id                 = CONSUMERIR_HARDWARE_MODULE_ID,
        .name               = "g2mv UEI IR blaster HAL",
        .author             = "The LineageOS Project",
        .methods            = &consumerir_module_methods,
    },
};
