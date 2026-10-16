/*
 * cir_test: send IR frames through the UEI blaster for bring-up.
 *   cir_test [address] [command]          one NEC frame (default 0x04 0x08,
 *                                         LG TV power)
 *   cir_test -r freq mark space ...       raw pattern in microseconds
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_ENTRIES 512

extern int transmitIr(const char *dev, int baud, int carrier_freq,
        const int pattern[], int pattern_len);

static int send(int freq, const int pattern[], int n)
{
    int ret = transmitIr("/dev/ttyHS3", 230400, freq, pattern, n);
    printf("transmitIr(freq=%d, %d entries) = %d\n", freq, n, ret);
    return ret;
}

int main(int argc, char **argv)
{
    int pattern[MAX_ENTRIES];
    int n = 0, i, b;

    if (argc > 2 && strcmp(argv[1], "-r") == 0) {
        for (i = 3; i < argc && n < MAX_ENTRIES; i++)
            pattern[n++] = atoi(argv[i]);
        return send(atoi(argv[2]), pattern, n);
    } else {
        unsigned addr = argc > 1 ? strtoul(argv[1], NULL, 0) : 0x04;
        unsigned cmd = argc > 2 ? strtoul(argv[2], NULL, 0) : 0x08;
        unsigned bytes[4] = { addr & 0xff, ~addr & 0xff, cmd & 0xff, ~cmd & 0xff };

        pattern[n++] = 9000;
        pattern[n++] = 4500;
        for (i = 0; i < 4; i++) {
            for (b = 0; b < 8; b++) {
                pattern[n++] = 560;
                pattern[n++] = (bytes[i] >> b) & 1 ? 1690 : 560;
            }
        }
        pattern[n++] = 560;
        return send(38000, pattern, n);
    }
}
