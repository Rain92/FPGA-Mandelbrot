#include <stdint.h>

uint8_t ascii2scancode(uint8_t ascii)
{
    uint8_t scancode;
    switch (ascii)
    {
    case 0x20:
        scancode = 0x29;
        break; // space
    case 0x08:
        scancode = 0x66;
        break; // backspace (BS control code)
    case 0x09:
        scancode = 0x0D;
        break; // tab (HT control code)
    case 0x0D:
        scancode = 0x5A;
        break; // enter (CR control code)
    case 0x1B:
        scancode = 0x76;
        break; // escape (ESC control code)
    case 0x7F:
        scancode = 0x71;
        break; // delete
    case 0x61:
        scancode = 0x1C;
        break; // a
    case 0x62:
        scancode = 0x32;
        break; // b
    case 0x63:
        scancode = 0x21;
        break; // c
    case 0x64:
        scancode = 0x23;
        break; // d
    case 0x65:
        scancode = 0x24;
        break; // e
    case 0x66:
        scancode = 0x2B;
        break; // f
    case 0x67:
        scancode = 0x34;
        break; // g
    case 0x68:
        scancode = 0x33;
        break; // h
    case 0x69:
        scancode = 0x43;
        break; // i
    case 0x6A:
        scancode = 0x3B;
        break; // j
    case 0x6B:
        scancode = 0x42;
        break; // k
    case 0x6C:
        scancode = 0x4B;
        break; // l
    case 0x6D:
        scancode = 0x3A;
        break; // m
    case 0x6E:
        scancode = 0x31;
        break; // n
    case 0x6F:
        scancode = 0x44;
        break; // o
    case 0x70:
        scancode = 0x4D;
        break; // p
    case 0x71:
        scancode = 0x15;
        break; // q
    case 0x72:
        scancode = 0x2D;
        break; // r
    case 0x73:
        scancode = 0x1B;
        break; // s
    case 0x74:
        scancode = 0x2C;
        break; // t
    case 0x75:
        scancode = 0x3C;
        break; // u
    case 0x76:
        scancode = 0x2A;
        break; // v
    case 0x77:
        scancode = 0x1D;
        break; // w
    case 0x78:
        scancode = 0x22;
        break; // x
    case 0x79:
        scancode = 0x35;
        break; // y
    case 0x7A:
        scancode = 0x1A;
        break; // z
    case 0x41:
        scancode = 0x1C;
        break; // A
    case 0x42:
        scancode = 0x32;
        break; // B
    case 0x43:
        scancode = 0x21;
        break; // C
    case 0x44:
        scancode = 0x23;
        break; // D
    case 0x45:
        scancode = 0x24;
        break; // E
    case 0x46:
        scancode = 0x2B;
        break; // F
    case 0x47:
        scancode = 0x34;
        break; // G
    case 0x48:
        scancode = 0x33;
        break; // H
    case 0x49:
        scancode = 0x43;
        break; // I
    case 0x4A:
        scancode = 0x3B;
        break; // J
    case 0x4B:
        scancode = 0x42;
        break; // K
    case 0x4C:
        scancode = 0x4B;
        break; // L
    case 0x4D:
        scancode = 0x3A;
        break; // M
    case 0x4E:
        scancode = 0x31;
        break; // N
    case 0x4F:
        scancode = 0x44;
        break; // O
    case 0x50:
        scancode = 0x4D;
        break; // P
    case 0x51:
        scancode = 0x15;
        break; // Q
    case 0x52:
        scancode = 0x2D;
        break; // R
    case 0x53:
        scancode = 0x1B;
        break; // S
    case 0x54:
        scancode = 0x2C;
        break; // T
    case 0x55:
        scancode = 0x3C;
        break; // U
    case 0x56:
        scancode = 0x2A;
        break; // V
    case 0x57:
        scancode = 0x1D;
        break; // W
    case 0x58:
        scancode = 0x22;
        break; // X
    case 0x59:
        scancode = 0x35;
        break; // Y
    case 0x5A:
        scancode = 0x1A;
        break; // Z
    case 0x21:
        scancode = 0x16;
        break; // !
    case 0x22:
        scancode = 0x52;
        break; // "
    case 0x23:
        scancode = 0x26;
        break; // #
    case 0x24:
        scancode = 0x25;
        break; // $
    case 0x25:
        scancode = 0x2E;
        break; // %
    case 0x26:
        scancode = 0x3D;
        break; // &
    case 0x28:
        scancode = 0x46;
        break; // (
    case 0x29:
        scancode = 0x45;
        break; // )
    case 0x2A:
        scancode = 0x3E;
        break; // *
    case 0x2B:
        scancode = 0x55;
        break; // +
    case 0x3A:
        scancode = 0x4C;
        break; // :
    case 0x3C:
        scancode = 0x41;
        break; // <
    case 0x3E:
        scancode = 0x49;
        break; // >
    case 0x3F:
        scancode = 0x4A;
        break; // ?
    case 0x40:
        scancode = 0x1E;
        break; // @
    case 0x5E:
        scancode = 0x36;
        break; // ^
    case 0x5F:
        scancode = 0x4E;
        break; // _
    case 0x7B:
        scancode = 0x54;
        break; // {
    case 0x7C:
        scancode = 0x5D;
        break; // |
    case 0x7D:
        scancode = 0x5B;
        break; // }
    case 0x7E:
        scancode = 0x0E;
        break; // ~
    case 0x30:
        scancode = 0x45;
        break; // 0
    case 0x31:
        scancode = 0x16;
        break; // 1
    case 0x32:
        scancode = 0x1E;
        break; // 2
    case 0x33:
        scancode = 0x26;
        break; // 3
    case 0x34:
        scancode = 0x25;
        break; // 4
    case 0x35:
        scancode = 0x2E;
        break; // 5
    case 0x36:
        scancode = 0x36;
        break; // 6
    case 0x37:
        scancode = 0x3D;
        break; // 7
    case 0x38:
        scancode = 0x3E;
        break; // 8
    case 0x39:
        scancode = 0x46;
        break; // 9
    case 0x27:
        scancode = 0x52;
        break; // '
    case 0x2C:
        scancode = 0x41;
        break; // ,
    case 0x2D:
        scancode = 0x4E;
        break; // -
    case 0x2E:
        scancode = 0x49;
        break; // .
    case 0x2F:
        scancode = 0x4A;
        break; // /
    case 0x3B:
        scancode = 0x4C;
        break; // ;
    case 0x3D:
        scancode = 0x55;
        break; // =
    case 0x5B:
        scancode = 0x54;
        break; // [
    case 0x5C:
        scancode = 0x5D;
        break; // \ 
        case 0x5D: scancode = 0x5B; break; // ]
    case 0x60:
        scancode = 0x0E;
        break; // `
    default:
        scancode = 0x00;
        break;
    }
    return scancode;
}
