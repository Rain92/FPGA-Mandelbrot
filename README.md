# FPGA Mandelbrot

A fast Mandelbrot generator written in SystemVerilog.

![GitHub Logo](/images/monitor.jpg)

The Mandelbrot pattern is generated using multiple pipelined calculation cores using fixed point arthmatic.
The module is fully parameterized so the number of calculation cores and the bit-width of the fixed point numbers can be adjusted to favor speed or precision, a better precision allows deeper zooms. On an Artix-7 100T FPGA it's possible to deploy 4 cores with 74 bit numbers, which enables very deep zooms at a decent speed.
The generator can be controlled via a PS/2 keyboard. It's possible to navigate, zoom in/out and increase or decrese the maximum iteration count.
Two kinds of video outputs are supported. Firstly via a VGA interface, see https://github.com/Rain92/vga_interface. Secondly via HDMI, for that the popular module form https://github.com/hdl-util/hdmi was used.


## Project
Vivado project files for two FPGA boards are included. For targeting the cheap EBAZ4205 FPGA a VGA interface was used.
Another target is the Artix-7 100T powered Wukong Board by QMTech for which the HDMI port was used.


![GitHub Logo](/images/fpga.jpg)

## Simulator
A fast and lightweight Verilator based simulator is included.
It uses MiniFb to display the video frames in real time in a window and also includes support for basic keyboard inputs.  

![GitHub Logo](/images/sim.png)

To run the simulator MiniFB has to be built first:

```
git submodule update --init --recursive
cd sim/minifb
mkdir build
cd build
cmake .. -DUSE_OPENGL_API=OFF -DUSE_WAYLAND_API=OFF
make
cd ../..
```

Then you can run the simulator with:
```
make && ./obj_dir/Vsim_hdmi_window
```


## Acknowledgements
The HDMI module: https://github.com/hdl-util/hdmi \
MiniFB: https://github.com/emoon/minifb \
The PS/2 keyboard controller is based on https://forum.digikey.com/t/ps-2-keyboard-to-ascii-converter-vhdl/12616 and was ported to SystemVerilog. 

