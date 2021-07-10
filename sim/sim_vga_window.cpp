#include <fcntl.h>
#include <stdlib.h>
#include <vector>
#include <queue>
#include "Vsim_vga_window.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "ascii2scancode.h"
#include "minifb/include/MiniFB.h"

#define LOG(...) fprintf(stderr, __VA_ARGS__)

const int bit_depth = 6;

bool use_keyboard = true;
bool trace = false;
// bool trace = true;
int max_frames = 1;

VerilatedVcdC *m_trace;

bool frameFinished = false; /* when the vsync signal transition from low to high */
bool old_hsync = true;      /* hsync is useless since it's not moved during the vsync */
bool old_vsync = true;

std::queue<uint8_t> input_queue;

void keyboard_input(struct mfb_window *window, mfb_key key, mfb_key_mod mod, bool isPressed)
{
    uint8_t input_code;

    if (key == KB_KEY_LEFT_SHIFT)
        input_code = 0x12;
    else if (key == KB_KEY_RIGHT_SHIFT)
        input_code = 0x59;
    else
    {
        input_code = ascii2scancode(key);
    }

    if (!isPressed)
        input_queue.push(0xF0); // break code

    input_queue.push(input_code);

    // fprintf(stdout, " keyboard: %d key: %s (pressed: %d) [key_mod: %x]\n", input_code, mfb_get_key_name(key), isPressed, mod);
}

bool get_parity(unsigned int n)
{
    bool parity = 0;
    while (n)
    {
        parity = !parity;
        n = n & (n - 1);
    }
    return parity;
}

int main(int argc, char *argv[])
{
    LOG(" [+] starting VGA simulation\n");
    uint64_t tickcount = 0;
    uint64_t framecount = 0;

    Vsim_vga_window *top_module = new Vsim_vga_window;

    if (trace)
    {
        Verilated::traceEverOn(true);
        m_trace = new VerilatedVcdC;
        top_module->trace(m_trace, 99);
        m_trace->open("trace.vcd");
    }

    top_module->CLOCK_33 = 0;
    top_module->eval();

    int img_width = top_module->VGA_SCREEN_WIDTH;
    int img_height = top_module->VGA_SCREEN_HEIGHT;
    top_module->PS2_CLOCK = 1;
    top_module->PS2_DATA = 1;

    std::vector<uint8_t> buffer(img_width * img_height * 4, 0);

    uint32_t buffer_idx = 0;

    uint8_t active_input = 0;
    uint8_t input_state = 0;
    uint8_t input_shift_idx = 0;

    struct mfb_window *window = mfb_open_ex("VGA Simulator", img_width, img_height, WF_RESIZABLE);
    if (!window)
        return 0;

    if (use_keyboard)
        mfb_set_keyboard_callback(window, keyboard_input);

    int window_state;

    do
    {

        buffer_idx = 0;
        while (buffer_idx < buffer.size())
        {
            top_module->CLOCK_33 = 0;
            top_module->eval();

            if (trace)
                m_trace->dump(10 * tickcount);

            // shift out keyboard input
            const int clock_devider = 1 << 9;
            if (use_keyboard && tickcount % clock_devider == 0)
            {
                if (active_input == 0 && !input_queue.empty())
                {
                    active_input = input_queue.front();
                    input_queue.pop();
                    input_state = 1;
                    input_shift_idx = 0;
                }

                if (input_state == 1 || input_state == 3)
                {
                    if (tickcount % (clock_devider << 1) == 0)
                    {
                        top_module->PS2_CLOCK = 0;
                    }
                    else
                    {
                        top_module->PS2_CLOCK = 1;
                        input_state++;
                    }
                }
                else if (input_state == 2)
                {
                    if (tickcount % (clock_devider << 1) == 0)
                    {
                        top_module->PS2_CLOCK = 0;
                    }
                    else
                    {
                        top_module->PS2_CLOCK = 1;

                        if (input_shift_idx == 0) // 1 startbit: 0
                            top_module->PS2_DATA = 0;
                        else if (input_shift_idx >= 1 && input_shift_idx <= 8) // 8 databits
                            top_module->PS2_DATA = (active_input >> (input_shift_idx - 1)) & 1;
                        else if (input_shift_idx == 9) // 1 paritybit
                            top_module->PS2_DATA = get_parity(active_input) ? 0 : 1;
                        else if (input_shift_idx == 10) // 1 stopbit: 1
                            top_module->PS2_DATA = 1;

                        if (++input_shift_idx == 11)
                        {
                            top_module->PS2_DATA = 1;
                            input_state = 3;
                        }
                    }
                }
                else if (input_state == 4)
                {
                    top_module->PS2_CLOCK = 1;
                    if (++input_shift_idx > 20)
                    {
                        active_input = 0;
                        input_state = 0;
                        input_shift_idx = 0;
                    }
                }
            }

            top_module->CLOCK_33 = 1;
            top_module->eval();

            if (trace)
                m_trace->dump(10 * tickcount + 5);

            // grab VGA output
            if (top_module->VGA_ACTIVE)
            {
                buffer[buffer_idx++] = top_module->VGA_B << (8 - bit_depth);
                buffer[buffer_idx++] = top_module->VGA_G << (8 - bit_depth);
                buffer[buffer_idx++] = top_module->VGA_R << (8 - bit_depth);
                buffer[buffer_idx++] = 255;
            }

            /* we need to dump when vsync transitions from low to high */
            frameFinished = (!old_vsync && top_module->VGA_VSYNC);

            old_vsync = top_module->VGA_VSYNC;
            old_hsync = top_module->VGA_HSYNC;

            tickcount++;

            if (frameFinished)
                break;
        }

        window_state = mfb_update_ex(window, buffer.data(), img_width, img_height);

        if (trace)
            m_trace->flush();

        framecount++;

        if (trace && max_frames > 0 && framecount == max_frames + 1)
            break;

        // if (framecount % 60 == 0)
        //     LOG("Drawing frame: %d\n", framecount);

        if (window_state < 0)
        {
            window = NULL;
            break;
        }
    } while (mfb_wait_sync(window));

    if (trace)
        m_trace->flush();

    return EXIT_SUCCESS;
}
