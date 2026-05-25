# Guía del Toolchain Gowin — Yosys + nextpnr-himbaechel

Esta guía explica qué hace cada herramienta del flujo de trabajo open-source para la Tang Nano 9K, la diferencia con el flujo iCE40 y cómo diagnosticar problemas.

> **Nota OSS CAD Suite (2025+):** Las versiones recientes reemplazaron `nextpnr-gowin` por
> `nextpnr-himbaechel`, el nuevo backend unificado de nextpnr. El chipdb de Gowin se
> encuentra en `~/oss-cad-suite/share/nextpnr/himbaechel/gowin/chipdb-GW1N-9C.bin`.

---

## El Flujo Completo

```
┌──────────────────────────────────────────────────────────┐
│  Tu diseño (.v / .sv)  +  Restricciones (.cst)           │
└───────────────┬──────────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────┐
│  1. yosys  (síntesis)            │
│     synth_gowin -json out.json   │
│                                  │
│  RTL → Netlist de primitivas     │
│  Gowin (LUT4, DFF, BRAM…)        │
└───────────────┬──────────────────┘
                │  out.json  (netlist)
                ▼
┌──────────────────────────────────┐
│  2. nextpnr-himbaechel  (P&R)    │
│     --device GW1NR-LV9QN88PC6/I5│
│     --chipdb chipdb-GW1N-9C.bin  │
│     --json out.json              │
│     --cst design.cst             │
│     --write pnr.json             │
│                                  │
│  Netlist → Netlist ubicado y     │
│  enrutado en el chip físico      │
└───────────────┬──────────────────┘
                │  pnr.json  (netlist P&R)
                ▼
┌──────────────────────────────────┐
│  3. gowin_pack  (empaquetado)    │
│     -d GW1NR-LV9QN88PC6/I5      │
│     -o design.fs  pnr.json      │
│                                  │
│  Netlist P&R → Bitstream .fs     │
│  (formato propietario Gowin)     │
└───────────────┬──────────────────┘
                │  design.fs  (bitstream)
                ▼
┌──────────────────────────────────┐
│  4. openFPGALoader  (flash)      │
│     -b tangnano9k design.fs      │
│                                  │
│  Carga el bitstream en la FPGA   │
│  vía USB-C / JTAG                │
└──────────────────────────────────┘
```

---

## 1. yosys — Síntesis

### ¿Qué hace?

Toma el código RTL (Verilog / SystemVerilog) y lo convierte en una lista de compuertas lógicas primitivas que existen físicamente en el chip Gowin. Este proceso se llama **síntesis**.

### Comando para Gowin

```bash
yosys -p "synth_gowin -json salida.json" diseño.v
```

Flags útiles de `synth_gowin`:

| Flag           | Función                                             |
| -------------- | --------------------------------------------------- |
| `-json <file>` | Escribe el netlist en formato JSON para nextpnr     |
| `-top <name>`  | Especifica el módulo top-level (si no lo detecta)   |
| `-nodffe`      | Desactiva inferencia de D flip-flops con enable     |
| `-nobram`      | No mapea a bloques BRAM físicos                     |
| `-nolutnot`    | No usa primitivas LUT NOT                           |

### ¿Qué genera?

Un archivo `.json` con la **netlist**: la descripción de qué primitivas Gowin (LUT4, DFF, BRAM, etc.) se necesitan y cómo están conectadas entre sí.

### Diferencia con iCE40

En el proyecto iCESugar usabas `synth_ice40`. Para Gowin el comando es `synth_gowin` — el flujo es idéntico conceptualmente, solo cambia el target de síntesis.

---

## 2. nextpnr-himbaechel — Place & Route

### ¿Qué hace?

Toma el netlist de yosys y lo **ubica** (place) en celdas físicas concretas del chip, luego **enruta** (route) las conexiones entre ellas. Es el reemplazo de `nextpnr-gowin` en versiones recientes de nextpnr — ahora un único binario maneja múltiples familias de FPGAs (Gowin, Microchip PolarFire, etc.) a través de bases de datos de chip (chipdb).

### Comando

```bash
nextpnr-himbaechel \
  --device GW1NR-LV9QN88PC6/I5 \
  --chipdb ~/oss-cad-suite/share/nextpnr/himbaechel/gowin/chipdb-GW1N-9C.bin \
  --json entrada.json \
  --cst restricciones.cst \
  --write salida_pnr.json
```

### Device string para Tang Nano 9K

```
GW1NR-LV9QN88PC6/I5
```

Desglosado:
- `GW1NR` — familia GW1N con PSRAM integrada
- `LV` — Low Voltage (3.3V / 1.8V)
- `9` — 9K LUTs
- `QN88` — package QFN de 88 pines
- `PC6/I5` — speed grade

### Chipdb para Tang Nano 9K

```
~/oss-cad-suite/share/nextpnr/himbaechel/gowin/chipdb-GW1N-9C.bin
```

El archivo `chipdb-GW1N-9C.bin` describe la arquitectura física exacta del GW1NR-9C (topología de interconexión, ubicación de celdas, recursos disponibles).

### Archivo .cst

El archivo `.cst` (Constraint) es el equivalente al `.pcf` que usabas con iCE40. Especifica qué pines físicos del chip corresponden a qué señales de tu diseño.

```
IO_LOC "clk"      52;
IO_LOC "led_n[0]" 10;
IO_LOC "led_n[1]" 11;
```

Ver `docs/guia_cst_pines.md` para la referencia completa de pines.

### ¿Qué genera?

Un archivo `.json` con la netlist **colocada y enrutada**: cada compuerta tiene ya una posición física en el silicio.

---

## 3. gowin_pack — Empaquetado del Bitstream

### ¿Qué hace?

Convierte el netlist P&R en el **bitstream** binario `.fs` que el chip Gowin puede cargar. Este es el archivo que entiende el hardware directamente.

### Comando

```bash
gowin_pack -d GW1NR-LV9QN88PC6/I5 -o diseño.fs pnr.json
```

### ¿Qué genera?

Un archivo `.fs` (Gowin bitstream). Es el equivalente al `.bin` que generaba `icepack` para iCE40.

---

## 4. openFPGALoader — Programación

### ¿Qué hace?

Carga el bitstream en la FPGA vía USB-C / JTAG. Soporta carga en RAM (volátil, se pierde al quitar power) y en Flash (no volátil, persiste).

### Comandos

```bash
# Cargar en SRAM (rápido, volátil — ideal para desarrollo)
openFPGALoader -b tangnano9k diseño.fs

# Cargar en Flash interna (persiste al reiniciar)
openFPGALoader -b tangnano9k --write-flash diseño.fs

# Detectar la placa conectada
openFPGALoader --detect
```

> **Nota:** `openFPGALoader --version` no es un flag válido — si el comando responde con
> un mensaje de error de opciones, significa que la herramienta **sí está instalada**.

### Diferencia con iCE40

En el proyecto iCESugar usabas `cp archivo.bin /Volumes/iCELink/` (drag & drop). La Tang Nano 9K usa JTAG real vía `openFPGALoader`, que es más robusto y ofrece más opciones.

---

## 5. iverilog — Simulación (opcional pero recomendado)

### ¿Qué hace?

Simula el comportamiento del diseño Verilog **antes** de sintetizar, ejecutando un testbench. Ahorra tiempo detectando errores lógicos sin necesidad de cargar en la placa.

### Comandos básicos

```bash
# Compilar diseño + testbench
iverilog -o sim.vvp diseño.v tb_diseño.v

# Ejecutar la simulación
vvp sim.vvp

# Genera un archivo .vcd para ver señales en WaveTrace
```

---

## Makefile Tipo para Tang Nano 9K

```makefile
# ============================================================
# Makefile — Tang Nano 9K (Gowin GW1NR-9C)
# LowRISC coding style
# ============================================================

TOP     ?= top
SRC     ?= $(TOP).v
CST     ?= $(TOP).cst
DEVICE   = GW1NR-LV9QN88PC6/I5
BOARD    = tangnano9k
CHIPDB   = $(HOME)/oss-cad-suite/share/nextpnr/himbaechel/gowin/chipdb-GW1N-9C.bin

all: $(TOP).fs

# 1. Síntesis
$(TOP).json: $(SRC)
	yosys -p "synth_gowin -top $(TOP) -json $@" $<

# 2. Place & Route
$(TOP)_pnr.json: $(TOP).json $(CST)
	nextpnr-himbaechel \
	  --device $(DEVICE) \
	  --chipdb $(CHIPDB) \
	  --json $(TOP).json \
	  --cst $(CST) \
	  --write $@

# 3. Empaquetado
$(TOP).fs: $(TOP)_pnr.json
	gowin_pack -d $(DEVICE) -o $@ $<

# 4. Cargar en SRAM (desarrollo)
flash: $(TOP).fs
	openFPGALoader -b $(BOARD) $<

# 4b. Cargar en Flash (persistente)
flash-persistent: $(TOP).fs
	openFPGALoader -b $(BOARD) --write-flash $<

# Simulación
sim: $(SRC) tb_$(TOP).v
	iverilog -o sim.vvp $(SRC) tb_$(TOP).v
	vvp sim.vvp

clean:
	rm -f *.json *.fs *.vvp *.vcd

.PHONY: all flash flash-persistent sim clean
```

---

## Comparación iCE40 vs Gowin

| Paso           | iCESugar (iCE40)            | Tang Nano 9K (Gowin)                   |
| -------------- | --------------------------- | -------------------------------------- |
| Síntesis       | `synth_ice40`               | `synth_gowin`                          |
| P&R            | `nextpnr-ice40`             | `nextpnr-himbaechel` + `--chipdb`      |
| Bitstream      | `icepack` → `.bin`          | `gowin_pack` → `.fs`                   |
| Restricciones  | `.pcf`                      | `.cst`                                 |
| Programar      | `cp .bin /Volumes/iCELink`  | `openFPGALoader -b tangnano9k`         |
| Recursos       | 1,280 LUTs                  | 8,640 LUTs (6.75× más grande)          |

---

## Referencias

- Yosys synth_gowin: <https://yosyshq.readthedocs.io/projects/yosys/en/latest/cmd/synth_gowin.html>
- Proyecto Apicula (Gowin open-source): <https://github.com/YosysHQ/apicula>
- openFPGALoader boards: <https://trabucayre.github.io/openFPGALoader/guide/first-steps.html>
