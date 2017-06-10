#include <limits.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

long asmb2(long a, long b[], long c[], size_t n)
{
    size_t i;
    for (i=0; i<n; i++)
        a = ((__int128)a*b[i])/c[i];
    return a;
}

long asmb(long a, long b[], long c[], size_t n);

long randlong(void)
{
    long r = 0;
    long i;
    for (i = 0; i < sizeof(long); ++i) {
        r |= ((long) rand() & 0xff) << (i * 8);
    }
    return r;
}


#define N 1
long a;
long b[N];
long c[N];

int main(void)
{
    size_t i;
    srand(time(NULL) ^ getpid());
    a = -10000000000;
    for (i = 0; i < N; ++i) {
        b[i] = -10000000000;
        long x = -1048576; //randlong() >> 32;
        c[i] = x == 0 ? 1 : x;
    }
    
    long x = asmb(a, b, c, N);
    long y = asmb2(a, b, c, N);
    printf("%li %li\n", x, y);
    return 0;
}
