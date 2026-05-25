# Puesta en Marcha — Tang Nano 9K en macOS

Guía completa para configurar el entorno de desarrollo open-source para la placa **Tang Nano 9K** (Gowin GW1NR-9C) en macOS, usando la cadena de herramientas basada en Yosys + nextpnr-himbaechel.

---

## ¿Qué es la Tang Nano 9K?

La **Tang Nano 9K** es una placa de desarrollo FPGA compacta basada en el chip **Gowin GW1NR-9C**. Sus características principales son:

- **8,640 celdas lógicas** (LUTs de 4 entradas)
- **468 KB de BRAM** embebida
- **608 KB de Flash** integrada (para configuración no volátil)
- **PLL** para generación de relojes
- **Oscilador de 27 MHz** en placa (pin 52)
- **6 LEDs RGB** integrados (activo en bajo, pines 10–16)
- Puerto USB-C para alimentación y programación
- **HDMI** (TMDS), pantalla LCD SPI, y PSRAM de 64 Mbit integrados
- Familia Gowin — con soporte de herramientas **open-source** via proyecto Apicula/nextpnr

---

## Flujo de Trabajo General

```
Diseño HDL (Verilog / SystemVerilog)
           ↓
   Síntesis (yosys -p "synth_gowin")   ← convierte RTL en netlist Gowin
           ↓
  Place & Route (nextpnr-himbaechel)    ← ubica y enruta en el chip real
           ↓
  Empaquetado (gowin_pack)              ← genera el bitstream .fs
           ↓
  Programar la placa (openFPGALoader)   ← carga el bitstream por USB-C
```

Para simular antes de grabar:

```
Verilog + Testbench
           ↓
   Simular (iverilog + vvp)
           ↓
   Archivo .vcd
           ↓
   Visualizar señales (WaveTrace en VS Code)
```

---

## Herramientas Necesarias

| Herramienta        | Función                                    | Incluida en OSS CAD Suite |
| ------------------ | ------------------------------------------ | ------------------------- |
| **yosys**          | Síntesis: Verilog → netlist Gowin          | ✅                         |
| **nextpnr-himbaechel** | Place & Route para Gowin (reemplaza nextpnr-gowin) | ✅             |
| **gowin_pack**     | Empaquetado: netlist PnR → bitstream .fs   | ✅                         |
| **openFPGALoader** | Programar la placa vía USB-C               | ✅                         |
| **iverilog**       | Simulación de diseños Verilog              | ✅                         |

> La forma más sencilla y confiable en macOS es instalar **OSS CAD Suite**, que incluye todas las herramientas en un único paquete binario pre-compilado.

---

## Opción A — OSS CAD Suite (Recomendada)

### Paso 1: Descargar OSS CAD Suite

Ir a la página de releases del proyecto:

```
https://github.com/YosysHQ/oss-cad-suite-build/releases/latest
```

Descargar el archivo para macOS según tu procesador:
- **Apple Silicon (M1/M2/M3/M4):** `oss-cad-suite-darwin-arm64-<fecha>.tgz`
- **Intel:** `oss-cad-suite-darwin-x64-<fecha>.tgz`

### Paso 2: Extraer y configurar

```bash
# Extraer en el directorio home (o donde prefieras)
cd ~
tar -xzf ~/Downloads/oss-cad-suite-darwin-arm64-*.tgz

# Agregar al PATH (agregar esta línea a ~/.zshrc o ~/.bash_profile)
echo 'source ~/oss-cad-suite/environment' >> ~/.zshrc

# Recargar la terminal
source ~/.zshrc
```

### Paso 3: Verificar la instalación

```bash
yosys --version
# Yosys 0.xx (git sha1 ...)

nextpnr-gowin --version
# "nextpnr-gowin" -- Next Generation Place and Route (Version ...)

openFPGALoader --version
# openFPGALoader x.x.x ...

iverilog -V
# Icarus Verilog version xx.x (stable)
```

---

## Opción B — Homebrew (Instalación individual)

> **Nota:** A mayo 2026, Homebrew incluye `yosys` y `openfpgaloader` directamente. Para `nextpnr-gowin` se recomienda el tap de YosysHQ o compilar desde fuente. Si encuentras problemas, usa la Opción A.

### Paso 1: Instalar Homebrew (si no lo tienes)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Paso 2: Instalar yosys

```bash
brew install yosys
yosys --version
```

### Paso 3: Instalar nextpnr-gowin vía tap YosysHQ

```bash
brew tap YosysHQ/tabby-cad-toolchain
brew install nextpnr-gowin
```

### Paso 4: Instalar openFPGALoader

```bash
brew install openfpgaloader
```

### Paso 5: Instalar iverilog (simulación)

```bash
brew install icarus-verilog
```

---

## Permisos USB en macOS

La Tang Nano 9K usa un chip **Bouffalo BL616** como interfaz USB-JTAG. macOS puede bloquear el acceso la primera vez.

```bash
# Verificar que macOS detecta la placa
ls /dev/cu.*
# Debe aparecer algo como: /dev/cu.usbmodem...

# Alternativamente con openFPGALoader
openFPGALoader --detect
```

Si la placa no aparece:
1. Ir a **Preferencias del Sistema → Privacidad y Seguridad** y aprobar el driver si aparece bloqueado.
2. Desconectar y reconectar el cable USB-C.
3. Probar con un cable distinto (algunos cables USB-C son solo de carga, sin datos).

---

## Verificación del Entorno Completo

Ejecutar cada comando para confirmar:

```bash
yosys --version
nextpnr-himbaechel --version
gowin_pack --help 2>&1 | head -3
openFPGALoader --help 2>&1 | head -1   # no tiene --version, pero responde si está instalado
iverilog -V
```

Tabla de estado esperado:

| Herramienta        | Estado | Comando de verificación         |
| ------------------ | ------ | ------------------------------- |
| yosys              | ✅      | `yosys --version`               |
| nextpnr-himbaechel | ✅      | `nextpnr-himbaechel --version`  |
| gowin_pack         | ✅      | `gowin_pack --help`             |
| openFPGALoader     | ✅      | `openFPGALoader --version`      |
| iverilog           | ✅      | `iverilog -V`                   |

---

## Visualizador de Señales (Simulación)

**WaveTrace** — extensión de VS Code (recomendada):
- Abre VS Code → Extensions → busca `WaveTrace`
- Abre archivos `.vcd` directamente en el editor sin instalación adicional

**GTKWave** — alternativa clásica:
```
https://github.com/gtkwave/gtkwave/releases
```

---

## Siguiente Paso

Con el entorno listo, el primer proyecto es el **LED Parpadeante** — el "Hola Mundo" del mundo FPGA.
Ver `hands-on/01_blink/`.

---

## Referencias

- Tang Nano 9K — SiPEED wiki: <https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html>
- Proyecto Apicula (ingeniería inversa Gowin): <https://github.com/YosysHQ/apicula>
- nextpnr-gowin: <https://github.com/YosysHQ/nextpnr>
- OSS CAD Suite: <https://github.com/YosysHQ/oss-cad-suite-build>
- openFPGALoader: <https://github.com/trabucayre/openFPGALoader>
- yosys: <https://github.com/YosysHQ/yosys>
