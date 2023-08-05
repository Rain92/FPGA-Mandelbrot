ROOT_DIR:=$(strip $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

PATH_DESIGN = $(ROOT_DIR)/../rtl
PATH_DESIGN2 = $(ROOT_DIR)/../rtl/hdmi
SOURCE_MAIN_VGA_V = top_vga_sim.sv
SOURCE_MAIN_HDMI_V = top_hdmi_sim.sv

FLAGS := -Wall -Wno-TIMESCALEMOD -Wno-UNUSED -Wno-fatal --trace -cc
CFLAGS := -Os
LDFLAGS  := -L$(ROOT_DIR)/minifb/build -lminifb -lX11

all: vgasim_vga_window Vvgasim_vga_bitmap vgasim_hdmi_window

Vvgasim_vga_bitmap:
	verilator -I$(PATH_DESIGN) $(FLAGS) -CFLAGS "$(CFLAGS)" $(SOURCE_MAIN_VGA_V) --exe sim_vga_bitmap.cpp --prefix Vsim_vga_bitmap
	make -C obj_dir -j  -f Vsim_vga_bitmap.mk Vsim_vga_bitmap

vgasim_vga_window:
	verilator -I$(PATH_DESIGN) $(FLAGS) -CFLAGS "$(CFLAGS)" -LDFLAGS "$(LDFLAGS)" $(SOURCE_MAIN_VGA_V) --exe sim_vga_window.cpp --prefix Vsim_vga_window
	make -C obj_dir -j  -f Vsim_vga_window.mk Vsim_vga_window

vgasim_hdmi_window:
	verilator -I$(PATH_DESIGN) -I$(PATH_DESIGN2) $(FLAGS) -CFLAGS "$(CFLAGS)" -LDFLAGS "$(LDFLAGS)" $(SOURCE_MAIN_HDMI_V) --exe sim_hdmi_window.cpp --prefix Vsim_hdmi_window
	make -C obj_dir -j  -f Vsim_hdmi_window.mk Vsim_hdmi_window


clean:
	rm -vfr obj_dir
