#include <stdio.h>

#define N 8
#define TOTAL_PERMUTATIONS 40320
#define TOTAL_DERANGEMENT  14833
#define SBOX_SIZE          256

// Khai báo mảng toàn cục chứa toàn bộ hoán vị
unsigned char return_permute_arr  [TOTAL_PERMUTATIONS]  [N]; // Value ranging from 0~7
// Khai báo mảng toàn cục chứa toàn bộ DER.
unsigned char return_der_arr      [TOTAL_DERANGEMENT]   [N];    // Value ranging from 0~7
// Khai báo mảng toàn cục chứa toàn bộ ánh xạ [0-255] sang Sbox
unsigned char return_sbox_arr     [TOTAL_DERANGEMENT]   [SBOX_SIZE]; // Value ranging from 0~255

// Hàm đảo ngược mảng hỗ trợ thuật toán sinh thứ tự từ điển
void reverse(int *arr, int start, int end) {
    while (start < end) {
        int temp = arr[start];
        arr[start] = arr[end];
        arr[end] = temp;
        start++;
        end--;
    }
}

// Hàm sinh toàn bộ 40.320 hoán vị theo thứ tự từ điển
void generate_all_permutations() {
    int arr[N] = {0, 1, 2, 3, 4, 5, 6, 7};
    int count = 0;

    // Lưu hoán vị khởi tạo đầu tiên
    for (int i = 0; i < N; i++) {
        return_permute_arr[count][i] = arr[i];
    }
    count++;

    while (1) {
        // Bước 1: Tìm chỉ số k lớn nhất sao cho arr[k] < arr[k + 1]
        int k = -1;
        for (int i = N - 2; i >= 0; i--) {
            if (arr[i] < arr[i + 1]) {
                k = i;
                break;
            }
        }

        // Nếu k == -1, mảng đã đạt trạng thái nghịch đảo lớn nhất {7,6,5,4,3,2,1,0}
        if (k == -1) {
            break;
        }

        // Bước 2: Tìm chỉ số l lớn nhất lớn hơn k sao cho arr[k] < arr[l]
        int l = -1;
        for (int i = N - 1; i > k; i--) {
            if (arr[k] < arr[i]) {
                l = i;
                break;
            }
        }

        // Bước 3: Tráo đổi arr[k] và arr[l]
        int temp = arr[k];
        arr[k] = arr[l];
        arr[l] = temp;

        // Bước 4: Đảo ngược phân đoạn từ k + 1 đến cuối mảng
        reverse(arr, k + 1, N - 1);

        // Bước 5: Lưu hoán vị vừa tạo vào mảng bộ nhớ
        for (int i = 0; i < N; i++) {
            return_permute_arr[count][i] = arr[i];
        }
        count++;
    }
}

// Hàm sinh 14833 derangement
void generate_all_derangements() {
    int d = 0; // total derangements counter
    for (int i = 0; i < TOTAL_PERMUTATIONS; i++) {
        int c = 0; // fixed point counter
        for (int j = 0; j < N; j++)
            if (return_permute_arr[i][j] == j) {c++; break;}
        if (c == 0) {
            for (int j = 0; j < N; j++)
                return_der_arr[d][j] = return_permute_arr[i][j];
            d ++;
        }
    }
    printf("Generated derangement == Theor. Value ?? %d\n", d==TOTAL_DERANGEMENT);
}

// Hàm sinh 14833 S-box
void generate_s_box() {
    for (int I = 0; I < TOTAL_DERANGEMENT; I++) {
        for (int a=0; a < SBOX_SIZE; a++) {
            unsigned char b = 0;
            for (int i = 0; i < N; i++) {
                if ((a & (1 << i)) == (1 << i)) b = b ^ (1 << return_der_arr[I][i]);
            }
            return_sbox_arr[I][a] = b;
            /* result visualizer
            if (a < 255)
                printf("%d, ", return_sbox_arr[I][a]);
            else
                printf("%d }, \n", return_sbox_arr[I][a]);
            */
        }
    }
}

// Hàm xuất sbox sang .mem
void export_sbox_to_mem(const char *filename) {
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        printf("Can't open %s\n", filename);
        return;
    }
    for (int i = 0; i < TOTAL_DERANGEMENT; i++) {
        for (int j = 0; j < SBOX_SIZE; j++) {
            fprintf(file, "%02X", return_sbox_arr[i][j]);
            if (j < SBOX_SIZE - 1) fprintf(file, " "); // blank for bytes on same row
        }
        fprintf(file, "\n");
    }
    fclose(file);
    printf("Written to: %s\n", filename);
}

// Hàm xuất chỉnh hợp sang mem
void export_derangements_to_mem(const char *filename) {
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        printf("Can't open %s\n", filename);
        return;
    }
    for (int i = 0; i < TOTAL_DERANGEMENT; i++) {
        // A packed word is one derangement row e.g [7, 6, 5, 4, 3, 2, 1, 0] -> 0x76543210
        unsigned int packed_word = 0;
        for (int j = 0; j < N; j++) {
            // return_del_arr[i][j] is 3-bit value, so we mask with 0b111 (0x7) to ensure only 3 bits are used, then shift left by j*3 to pack into the correct position in the 24-bit word
            packed_word |= ((unsigned int) return_der_arr[i][j] & 0x7)<<(j*3);
        }
        fprintf(file, "%06X\n", packed_word);
    }
    fclose(file);
    printf("Written to: %s\n", filename);
}

int main() {
    // 1. Chạy hàm sinh hoán vị để nạp đầy dữ liệu vào return_permute_arr
    generate_all_permutations();
    // 2. Chạy hàm sinh hoán vị toàn phần để nạp đầy dữ liệu vào return_der_arr
    generate_all_derangements();
    // 3. Chạy hàm sinh S-box để nạp đầy dữ liệu vào return_sbox_arr
    generate_s_box();
    // 4. Viết data vào tệp .mem
    // export_sbox_to_mem("sbox_patterns.mem");
    // 4 (alternative). Viết data rút gọn vào tệp .mem
    export_derangements_to_mem("raw_perm_rules.mem");
    return 0;
}
