# 01 — Blink: LED Parpadeante

El "Hola Mundo" del mundo FPGA. Un contador divide el reloj de 27 MHz hasta obtener un parpadeo visible (~1 Hz) en el LED0 de la Tang Nano 9K.

---

## Qué hace

El LED0 (pin 10) enciende durante 0.5 s y apaga durante 0.5 s, repitiendo indefinidamente. Como el LED es **activo en bajo**, la señal `led_n` vale `0` cuando el LED está encendido.

```
clk (27 MHz)  ┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌ ... (27 millones de flancos por segundo)
              └┘└┘└┘└┘└┘└┘└┘└┘└┘└

cnt_q         0 → 1 → 2 → ... → 13_499_999 → 0 → 1 → ...

led_q         0─────────────────────1──────────────────0──
              (apagado 0.5 s)       (encendido 0.5 s)

led_n         1─────────────────────0──────────────────1──
              (físicamente apagado) (físicamente encendido)
```

---

## Arquitectura del módulo

```
         ┌─────────────────────────────────┐
clk ────►│                                 │
         │   cnt_q [23:0]                  ├──► led_n
         │   ┌──────────────┐   led_q      │
         │   │ == HALF-1 ?  │──toggle──►   │
         │   │ else +1      │             │
         │   └──────────────┘             │
         └─────────────────────────────────┘
```

El diseño tiene un único registro de estado (`led_q`) y un contador de 24 bits (`cnt_q`). Cuando el contador llega a `HALF_PERIOD - 1`, se reinicia a cero y el estado del LED se invierte.

---

## Archivos

| Archivo         | Descripción                                      |
| --------------- | ------------------------------------------------ |
| `blink.v`       | Módulo RTL principal (Verilog, LowRISC style)    |
| `blink.cst`     | Restricciones de pines para Tang Nano 9K         |
| `Makefile`      | Flujo completo: síntesis → P&R → flash           |
| `tb_blink.v`    | Testbench con verificación automática            |

---

## Parámetros

| Parámetro     | Valor por defecto | Descripción                                  |
| ------------- | ----------------- | -------------------------------------------- |
| `HALF_PERIOD` | `13_500_000`      | Ciclos de reloj por semiperiodo (0.5 s a 27 MHz) |

Calcular `HALF_PERIOD` para otras frecuencias de parpadeo:

```
HALF_PERIOD = CLK_Hz / (2 × BLINK_Hz)

Ejemplos a 27 MHz:
  1 Hz  → 13_500_000   (0.5 s on/off)
  2 Hz  →  6_750_000   (0.25 s on/off)
  0.5 Hz→ 27_000_000   (1 s on/off)  ← requiere CNT_WIDTH = 25
```

---

## Pines utilizados

| Señal    | Pin | Descripción              |
| -------- | --- | ------------------------ |
| `clk`    | 52  | Reloj 27 MHz             |
| `led_n`  | 10  | LED0, activo en bajo     |

---

## Comandos

```bash
# Compilar
make

# Cargar en la placa (SRAM, volátil)
make flash

# Simular y verificar lógica
make sim

# Limpiar artefactos
make clean
```

### Salida esperada de `make`

```
yosys -p "synth_gowin -top blink -json blink.json" blink.v
...
=== blink ===
   Number of wires:              3
   Number of wire bits:         26
   Number of cells:              2
     GND                         1
     VCC                         1
...
nextpnr-himbaechel --device GW1NR-LV9QN88PC6/I5 --chipdb ... --json blink.json ...
...
Info: Max frequency for clock 'clk': XXXX MHz
gowin_pack -d GW1NR-LV9QN88PC6/I5 -o blink.fs blink_pnr.json
```

### Salida esperada de `make sim`

```
PASS  t=11: primer toggle OK — LED encendido (led_n=0)
PASS  t=21: segundo toggle OK — LED apagado (led_n=1)

=== TODOS LOS TESTS PASARON ===
```

---

## Conceptos aplicados

**Divisor de frecuencia** — La FPGA no puede "dormir". La única forma de generar una señal lenta es contar flancos del reloj rápido. Un contador de N bits acumula pulsos; cuando llega al límite, genera un evento (aquí, un toggle del LED).

**Registro síncrono** — `cnt_q` y `led_q` son flip-flops D que solo cambian en el flanco positivo de `clk`. Esto es la base de todo diseño digital síncrono.

**Lógica activa en bajo** — Los LEDs de la Tang Nano 9K están conectados entre el pin del FPGA y GND a través de una resistencia. El FPGA "enciende" el LED poniendo el pin a `0` (cortocircuito a GND = corriente circula = LED enciende). El sufijo `_n` en `led_n` comunica esta convención en el código.

**Parámetro de módulo** — `HALF_PERIOD` como parámetro permite reusar el mismo módulo con distinta frecuencia de parpadeo, y es esencial para la simulación (usar un valor pequeño evita simular millones de ciclos).

---

## Siguiente proyecto

[02 — PWM](../02_pwm/) — En lugar de encender/apagar bruscamente, el LED sube y baja de brillo suavemente usando modulación por ancho de pulso.
