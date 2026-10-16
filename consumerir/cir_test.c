/*
 * cir_test: send one NEC frame through the UEI blaster for bring-up.
 * usage: cir_test [address] [command]   (defaults: 0x04 0x08, LG TV power)
 */

#include <stdio.h>
#include <stdlib.h>

extern int transmitIr(const char *dev, int baud, int carrier_freq,
        const int pattern[], int pattern_len);

int main(int argc, char **argv)
{
    unsigned addr = argc > 1 ? strtoul(argv[1], NULL, 0) : 0x04;
    unsigned cmd = argc > 2 ? strtoul(argv[2], NULL, 0) : 0x08;
    unsigned bytes[4] = { addr & 0xff, ~addr & 0xff, cmd & 0xff, ~cmd & 0xff };
    int pattern[2 + 64 + 1];
    int n = 0, i, b, ret;

    pattern[n++] = 9000;
    pattern[n++] = 4500;
    for (i = 0; i < 4; i++) {
        for (b = 0; b < 8; b++) {
            pattern[n++] = 560;
            pattern[n++] = (bytes[i] >> b) & 1 ? 1690 : 560;
        }
    }
    pattern[n++] = 560;

    ret = transmitIr("/dev/ttyHS3", 230400, 38000, pattern, n);
    printf("transmitIr(addr=0x%02x cmd=0x%02x, %d entries) = %d\n", addr, cmd,
            n, ret);
    return ret;
}
