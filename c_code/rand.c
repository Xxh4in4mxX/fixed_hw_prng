#include <stdio.h>
#include <stdlib.h> // Required for rand() and srand()
#include <time.h>   // Required for time()

int main() {
    // 1. Seed the random number generator using the current time
    srand(time(NULL));

    // 2. Generate a random number in a specific range: [min, max]
    int min = 0;
    int max = 255;
    
    // Formula: rand() % (max - min + 1) + min
    unsigned char ranged_random = rand() % (max - min + 1) + min;
    printf("Random number between %d and %d: %d\n", min, max, ranged_random);

    return 0;
}
