#include <stdint.h>

#define MMIO_UART_TX      (*(volatile uint32_t *)0x80000000u)
#define MMIO_UART_RX      (*(volatile uint32_t *)0x80000004u)
#define MMIO_UART_RX_STAT (*(volatile uint32_t *)0x80000008u)
#define MMIO_TIMER        (*(volatile uint32_t *)0x8000000Cu)

#define W 10
#define H 20
#define PIECE_N 7
#define ROT_N 4

#define KEY_LEFT_A  'a'
#define KEY_LEFT_A2 'A'
#define KEY_LEFT_H  'h'
#define KEY_RIGHT_D 'd'
#define KEY_RIGHT_D2 'D'
#define KEY_RIGHT_L 'l'
#define KEY_ROT_W   'w'
#define KEY_ROT_W2  'W'
#define KEY_ROT_K   'k'
#define KEY_DOWN_S  's'
#define KEY_DOWN_S2 'S'
#define KEY_DOWN_J  'j'
#define KEY_DROP_SP ' '
#define KEY_QUIT_Q  'q'
#define KEY_QUIT_Q2 'Q'

// 57.8 MHz board clock -> ~1 second tick if timer increments once each second.
// If your timer increments every CPU cycle, set this to e.g. 5_780_000 for 100ms.
#define GRAVITY_TICKS 1u

static uint8_t board[H][W];
static int score = 0;
static int game_over = 0;

typedef struct {
    int piece;
    int rot;
    int x;
    int y;
} Active;

static Active cur;
static uint32_t rng_state = 0x1234ABCDu;

// 4x4 bitmap, bit index = row*4 + col. 1 means occupied.
static const uint16_t SHAPES[PIECE_N][ROT_N] = {
    // I
    {0x0F00, 0x2222, 0x00F0, 0x4444},
    // J
    {0x8E00, 0x6440, 0x0E20, 0x44C0},
    // L
    {0x2E00, 0x4460, 0x0E80, 0xC440},
    // O
    {0x6600, 0x6600, 0x6600, 0x6600},
    // S
    {0x6C00, 0x4620, 0x06C0, 0x8C40},
    // T
    {0x4E00, 0x4640, 0x0E40, 0x4C40},
    // Z
    {0xC600, 0x2640, 0x0C60, 0x4C80}
};

static void uart_putc(char c) {
    MMIO_UART_TX = (uint32_t)(uint8_t)c;
}

static void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

static void uart_put_uint(int v) {
    char buf[16];
    int i = 0;
    if (v == 0) {
        uart_putc('0');
        return;
    }
    if (v < 0) {
        uart_putc('-');
        v = -v;
    }
    while (v > 0 && i < (int)sizeof(buf)) {
        buf[i++] = (char)('0' + (v % 10));
        v /= 10;
    }
    while (i--) {
        uart_putc(buf[i]);
    }
}

static uint32_t prng(void) {
    rng_state ^= rng_state << 13;
    rng_state ^= rng_state >> 17;
    rng_state ^= rng_state << 5;
    return rng_state;
}

static int shape_bit(uint16_t m, int r, int c) {
    int bit = r * 4 + c;
    return (m >> (15 - bit)) & 1;
}

static int collides(int nx, int ny, int nrot) {
    uint16_t s = SHAPES[cur.piece][nrot & 3];
    for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
            if (!shape_bit(s, r, c)) continue;
            int gx = nx + c;
            int gy = ny + r;
            if (gx < 0 || gx >= W || gy >= H) return 1;
            if (gy >= 0 && board[gy][gx]) return 1;
        }
    }
    return 0;
}

static void lock_piece(void) {
    uint16_t s = SHAPES[cur.piece][cur.rot & 3];
    for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
            if (!shape_bit(s, r, c)) continue;
            int gx = cur.x + c;
            int gy = cur.y + r;
            if (gy >= 0 && gy < H && gx >= 0 && gx < W) {
                board[gy][gx] = (uint8_t)(cur.piece + 1);
            }
        }
    }
}

static void clear_lines(void) {
    int lines = 0;
    for (int y = H - 1; y >= 0; y--) {
        int full = 1;
        for (int x = 0; x < W; x++) {
            if (board[y][x] == 0) {
                full = 0;
                break;
            }
        }
        if (full) {
            lines++;
            for (int yy = y; yy > 0; yy--) {
                for (int x = 0; x < W; x++) {
                    board[yy][x] = board[yy - 1][x];
                }
            }
            for (int x = 0; x < W; x++) board[0][x] = 0;
            y++;
        }
    }
    score += lines * 100;
}

static void spawn_piece(void) {
    cur.piece = (int)(prng() % PIECE_N);
    cur.rot = 0;
    cur.x = 3;
    cur.y = -1;
    if (collides(cur.x, cur.y, cur.rot)) {
        game_over = 1;
    }
}

static int move_down(void) {
    if (!collides(cur.x, cur.y + 1, cur.rot)) {
        cur.y++;
        return 1;
    }
    return 0;
}

static void try_move(int dx) {
    if (!collides(cur.x + dx, cur.y, cur.rot)) {
        cur.x += dx;
    }
}

static void try_rotate(void) {
    int nr = (cur.rot + 1) & 3;
    if (!collides(cur.x, cur.y, nr)) {
        cur.rot = nr;
        return;
    }
    if (!collides(cur.x - 1, cur.y, nr)) {
        cur.x--;
        cur.rot = nr;
        return;
    }
    if (!collides(cur.x + 1, cur.y, nr)) {
        cur.x++;
        cur.rot = nr;
    }
}

static int active_has_block(int y, int x) {
    uint16_t s = SHAPES[cur.piece][cur.rot & 3];
    int ry = y - cur.y;
    int rx = x - cur.x;
    if (ry < 0 || ry >= 4 || rx < 0 || rx >= 4) return 0;
    return shape_bit(s, ry, rx);
}

static void emit_cell(uint8_t v) {
    // ANSI 16-color background palette.
    switch (v) {
        case 1: uart_puts("\033[46m  \033[0m"); break;
        case 2: uart_puts("\033[44m  \033[0m"); break;
        case 3: uart_puts("\033[43m  \033[0m"); break;
        case 4: uart_puts("\033[47m  \033[0m"); break;
        case 5: uart_puts("\033[42m  \033[0m"); break;
        case 6: uart_puts("\033[45m  \033[0m"); break;
        case 7: uart_puts("\033[41m  \033[0m"); break;
        default: uart_puts(" ."); break;
    }
}

static void render(void) {
    uart_puts("\033[2J\033[H");
    uart_puts("TETRIS (pipeline_lut_opt)\r\n");
    uart_puts("A/D: move, W: rotate, S: soft drop, SPACE: hard drop, Q: quit\r\n");
    uart_puts("Score: ");
    uart_put_uint(score);
    uart_puts("\r\n");

    for (int y = 0; y < H; y++) {
        uart_puts("|");
        for (int x = 0; x < W; x++) {
            uint8_t v = board[y][x];
            if (active_has_block(y, x)) v = (uint8_t)(cur.piece + 1);
            emit_cell(v);
        }
        uart_puts("|\r\n");
    }
    uart_puts("+--------------------+\r\n");
}

static void game_init(void) {
    for (int y = 0; y < H; y++) {
        for (int x = 0; x < W; x++) {
            board[y][x] = 0;
        }
    }
    score = 0;
    game_over = 0;
    rng_state = MMIO_TIMER ^ 0x9E3779B9u;
    spawn_piece();
}

int main(void) {
    uint32_t last_tick;

    game_init();
    last_tick = MMIO_TIMER;

    while (!game_over) {
        if (MMIO_UART_RX_STAT & 1u) {
            char k = (char)(MMIO_UART_RX & 0xFFu);
            if (k == KEY_LEFT_A || k == KEY_LEFT_A2 || k == KEY_LEFT_H) try_move(-1);
            else if (k == KEY_RIGHT_D || k == KEY_RIGHT_D2 || k == KEY_RIGHT_L) try_move(1);
            else if (k == KEY_ROT_W || k == KEY_ROT_W2 || k == KEY_ROT_K) try_rotate();
            else if (k == KEY_DOWN_S || k == KEY_DOWN_S2 || k == KEY_DOWN_J) {
                if (!move_down()) {
                    lock_piece();
                    clear_lines();
                    spawn_piece();
                }
            } else if (k == KEY_DROP_SP) {
                while (move_down()) {}
                lock_piece();
                clear_lines();
                spawn_piece();
            } else if (k == KEY_QUIT_Q || k == KEY_QUIT_Q2) {
                break;
            }
        }

        uint32_t now = MMIO_TIMER;
        if ((uint32_t)(now - last_tick) >= GRAVITY_TICKS) {
            if (!move_down()) {
                lock_piece();
                clear_lines();
                spawn_piece();
            }
            last_tick = now;
            render();
        }
    }

    uart_puts("\r\nGame Over. Final Score: ");
    uart_put_uint(score);
    uart_puts("\r\n");
    while (1) {}
    return 0;
}
