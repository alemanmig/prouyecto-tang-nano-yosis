# Guía de Pines y Restricciones (.cst) — Tang Nano 9K

Esta guía cubre la sintaxis del archivo `.cst` de Gowin y la referencia de pines de la Tang Nano 9K que usaremos en los proyectos.

---

## ¿Qué es el archivo .cst?

El archivo `.cst` (Constraint) es el equivalente del `.pcf` de iCE40. Le dice a `nextpnr-gowin` **qué pines físicos del chip** corresponden a **qué señales de tu diseño**.

Sin el `.cst`, nextpnr puede ubicar las señales de I/O en cualquier pin disponible — lo que rompería la conexión con los periféricos de la placa (LEDs, reloj, etc.).

---

## Sintaxis del archivo .cst

### Asignación de pin (IO_LOC)

```
IO_LOC "<nombre_señal>" <número_pin>;
```

Para buses (arrays):

```
IO_LOC "<nombre_señal>[<índice>]" <número_pin>;
```

### Atributos del pin (IO_PORT)

```
IO_PORT "<nombre_señal>" <atributo>=<valor>;
```

Atributos comunes:

| Atributo      | Valores posibles                    | Descripción                          |
| ------------- | ----------------------------------- | ------------------------------------ |
| `IO_TYPE`     | `LVCMOS33`, `LVCMOS18`, `LVCMOS25` | Estándar de voltaje (Tang Nano = 3.3V)|
| `PULL_MODE`   | `UP`, `DOWN`, `NONE`, `KEEPER`     | Resistencia de pull                  |
| `DRIVE`       | `4`, `8`, `16`, `24`               | Corriente de salida (mA)             |
| `SLEW_RATE`   | `FAST`, `SLOW`                     | Velocidad de transición              |

### Ejemplo completo

```
// Reloj 27 MHz
IO_LOC "clk" 52;
IO_PORT "clk" IO_TYPE=LVCMOS33;

// LED 0 (activo en bajo)
IO_LOC "led_n[0]" 10;
IO_PORT "led_n[0]" IO_TYPE=LVCMOS33 DRIVE=8 PULL_MODE=NONE;
```

---

## Pines de la Tang Nano 9K

### Reloj

| Señal      | Pin | Frecuencia | Descripción                        |
| ---------- | --- | ---------- | ---------------------------------- |
| `clk`      | 52  | 27 MHz     | Oscilador en placa                 |

### LEDs integrados (activo en BAJO — conectados a GND a través de los LEDs)

| LED    | Pin | Color  | Nota                    |
| ------ | --- | ------ | ----------------------- |
| LED[0] | 10  | Verde  | `0` = encendido         |
| LED[1] | 11  | Verde  | `0` = encendido         |
| LED[2] | 13  | Verde  | `0` = encendido         |
| LED[3] | 14  | Verde  | `0` = encendido         |
| LED[4] | 15  | Verde  | `0` = encendido         |
| LED[5] | 16  | Verde  | `0` = encendido         |

> **Importante:** Los LEDs son **activo en bajo**. Para encender un LED, la señal debe estar en `0`. Para apagarlo, en `1`. Esto es diferente a muchas placas que usan activo en alto.
>
> Convenio LowRISC: nombrar la señal con sufijo `_n` para indicar lógica invertida: `led_n[5:0]`.

### Botones (activo en BAJO)

| Botón   | Pin | Descripción                              |
| ------- | --- | ---------------------------------------- |
| S1      | 3   | Botón de usuario (pull-up interno)       |
| S2      | 4   | Botón de usuario (pull-up interno)       |

> Los botones leen `0` cuando están presionados, `1` en reposo (pull-up).

### UART (USB-Serial integrado via BL616)

| Señal    | Pin | Descripción              |
| -------- | --- | ------------------------ |
| `uart_tx`| 17  | TX del FPGA → USB        |
| `uart_rx`| 18  | RX del FPGA ← USB        |

### HDMI (TMDS)

| Señal         | Pin  | Descripción       |
| ------------- | ---- | ----------------- |
| `tmds_clk_p`  | 69   | TMDS clock +      |
| `tmds_clk_n`  | 68   | TMDS clock −      |
| `tmds_d_p[0]` | 71   | TMDS data 0 +     |
| `tmds_d_n[0]` | 70   | TMDS data 0 −     |
| `tmds_d_p[1]` | 73   | TMDS data 1 +     |
| `tmds_d_n[1]` | 72   | TMDS data 1 −     |
| `tmds_d_p[2]` | 75   | TMDS data 2 +     |
| `tmds_d_n[2]` | 74   | TMDS data 2 −     |

---

## Plantilla .cst para proyectos básicos

Copiar y adaptar para cada proyecto:

```
// ============================================================
// Constraints — Tang Nano 9K (GW1NR-LV9QN88PC6/I5)
// ============================================================

// --- Reloj 27 MHz ---
IO_LOC "clk" 52;
IO_PORT "clk" IO_TYPE=LVCMOS33;

// --- LEDs (activo en bajo) ---
IO_LOC "led_n[0]" 10;
IO_LOC "led_n[1]" 11;
IO_LOC "led_n[2]" 13;
IO_LOC "led_n[3]" 14;
IO_LOC "led_n[4]" 15;
IO_LOC "led_n[5]" 16;
IO_PORT "led_n[0]" IO_TYPE=LVCMOS33 DRIVE=8;
IO_PORT "led_n[1]" IO_TYPE=LVCMOS33 DRIVE=8;
IO_PORT "led_n[2]" IO_TYPE=LVCMOS33 DRIVE=8;
IO_PORT "led_n[3]" IO_TYPE=LVCMOS33 DRIVE=8;
IO_PORT "led_n[4]" IO_TYPE=LVCMOS33 DRIVE=8;
IO_PORT "led_n[5]" IO_TYPE=LVCMOS33 DRIVE=8;

// --- Botones (activo en bajo, pull-up interno) ---
// IO_LOC "btn_n[0]" 3;
// IO_PORT "btn_n[0]" IO_TYPE=LVCMOS33 PULL_MODE=UP;
// IO_LOC "btn_n[1]" 4;
// IO_PORT "btn_n[1]" IO_TYPE=LVCMOS33 PULL_MODE=UP;
```

---

## Comparación .pcf (iCE40) vs .cst (Gowin)

| Aspecto            | iCE40 (.pcf)                        | Gowin (.cst)                              |
| ------------------ | ----------------------------------- | ----------------------------------------- |
| Asignación de pin  | `set_io led B6`                     | `IO_LOC "led" 10;`                        |
| Bus                | `set_io led[0] B6`                  | `IO_LOC "led[0]" 10;`                     |
| Pull-up            | `set_io btn -pullup yes`            | `IO_PORT "btn" PULL_MODE=UP;`             |
| Voltaje            | Implícito (3.3V)                    | `IO_PORT "sig" IO_TYPE=LVCMOS33;`         |

---

## Errores Comunes

**"No IO_LOC for port X"** — Falta asignar pin a una señal que aparece en el módulo top. Agregar la línea `IO_LOC "X" <pin>;` en el `.cst`.

**"Pin XX is already used"** — Dos señales están intentando usar el mismo pin físico. Revisar si hay duplicados en el `.cst`.

**"Unknown port X"** — El nombre de la señal en el `.cst` no coincide exactamente con el nombre en el módulo top de Verilog. Son case-sensitive.

**LEDs no responden** — Verificar que la lógica es activo en bajo. Si el diseño usa `led = 1` para encender, cambiar a `led_n = ~led`.

---

## Referencias

- Tang Nano 9K Schematic: <https://dl.sipeed.com/shareURL/TANG/Nano9K/2_Schematic>
- SiPEED Tang Nano 9K wiki: <https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html>
- Gowin Primitive Reference: <https://www.gowinsemi.com/en/support/database/14/>
