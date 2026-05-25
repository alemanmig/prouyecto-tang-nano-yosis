# proyecto-tang-nano-9k

Aprendiendo FPGA desde cero con la placa **Tang Nano 9K** (Gowin GW1NR-9C) y el toolchain open-source basado en Yosys + nextpnr-gowin. Cada proyecto introduce conceptos nuevos de Verilog/SystemVerilog y diseño digital, verificados en hardware real.

## Hardware

| Componente     | Detalle                                              |
| -------------- | ---------------------------------------------------- |
| FPGA           | Gowin GW1NR-9C                                       |
| Paquete        | QN88 (88-pin QFN)                                    |
| Recursos       | 8,640 LUTs, 6,480 FFs, 468 KB BRAM, 608 KB Flash    |
| Reloj          | 27 MHz oscilador en placa (pin 52)                   |
| LEDs           | 6 LEDs integrados (activo en bajo, pines 10–16)      |
| Programador    | USB-C integrado (chip BL616, JTAG)                   |
| Extras         | HDMI (TMDS), LCD SPI, PSRAM 64 Mbit                  |

## Toolchain (open-source)

```
Verilog → yosys (synth_gowin) → nextpnr-gowin → gowin_pack → .fs → openFPGALoader
           síntesis               place & route    bitstream      flash USB-C
```

Instrucciones de instalación en macOS: [docs/setup_macos.md](docs/setup_macos.md)

## Estructura del repositorio

```
proyecto-tang-nano-9k/
├── docs/
│   ├── setup_macos.md              ← Instalación del toolchain en macOS
│   ├── guia_toolchain_gowin.md     ← Qué hace cada herramienta del toolchain
│   └── guia_cst_pines.md           ← Referencia de pines y sintaxis .cst
├── hands-on/
│   ├── 01_blink/                   ← LED parpadeante (Hola Mundo)
│   ├── 02_pwm/                     ← Control de brillo por PWM
│   ├── 03_counter/                 ← Contador binario con LEDs
│   └── README.md                   ← Índice de proyectos
└── README.md                       ← Este archivo
```

## Proyectos

| #  | Proyecto   | Qué hace                              | Conceptos clave                                         |
| -- | ---------- | ------------------------------------- | ------------------------------------------------------- |
| 01 | Blink      | LED parpadea cada ~0.5 s              | `reg`, `always @(posedge clk)`, divisor de frecuencia   |
| 02 | PWM        | LED sube y baja de brillo suavemente  | PWM, duty cycle, comparador, operador ternario          |
| 03 | Counter    | Contador binario 0–63 en 6 LEDs      | bus `[5:0]`, prescaler, testbench básico                |

## Quick Start

```bash
# 1. Instalar toolchain (ver docs/setup_macos.md)
# Opción recomendada: OSS CAD Suite
# https://github.com/YosysHQ/oss-cad-suite-build/releases/latest

# 2. Clonar el repo
git clone https://github.com/alemanmig/proyecto-tang-nano-9k.git
cd proyecto-tang-nano-9k/hands-on/01_blink

# 3. Compilar
make

# 4. Conectar la placa por USB-C y cargar
make flash
```

## Coding Style

Este proyecto sigue las convenciones del **LowRISC Verilog Coding Style Guide**:
- Nombres de módulos en `snake_case`
- Parámetros en `ALL_CAPS`
- Señales activas en bajo con sufijo `_n` (ej. `led_n`)
- Un módulo por archivo, el nombre del archivo igual al módulo

## Referencias

- Tang Nano 9K — SiPEED wiki: <https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html>
- LowRISC Verilog Style Guide: <https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md>
- Proyecto Apicula (Gowin open-source): <https://github.com/YosysHQ/apicula>
- OSS CAD Suite: <https://github.com/YosysHQ/oss-cad-suite-build>
