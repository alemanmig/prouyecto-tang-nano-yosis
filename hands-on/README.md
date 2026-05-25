# Hands-On — Proyectos Tang Nano 9K

Índice de proyectos prácticos ordenados por dificultad. Cada carpeta es autónoma: tiene su propio Verilog, `.cst` y `Makefile`.

## Índice de Proyectos

| #  | Carpeta       | Proyecto       | Qué hace                              | Estado   |
| -- | ------------- | -------------- | ------------------------------------- | -------- |
| 01 | `01_blink/`   | LED Blink      | LED parpadea cada ~0.5 s              | Pendiente|
| 02 | `02_pwm/`     | PWM            | LED sube y baja de brillo suavemente  | Pendiente|
| 03 | `03_counter/` | Contador       | Contador binario 0–63 en 6 LEDs      | Pendiente|

## Cómo usar cada proyecto

```bash
cd hands-on/01_blink

# Compilar (síntesis + P&R + pack)
make

# Cargar en la placa (SRAM, volátil)
make flash

# Simulación (si tiene testbench)
make sim

# Limpiar artefactos
make clean
```

## Estructura de cada proyecto

```
XX_nombre/
├── XX_nombre.v       ← Módulo top (LowRISC style)
├── XX_nombre.cst     ← Restricciones de pines Tang Nano 9K
├── Makefile          ← Flujo completo yosys → nextpnr → pack → flash
├── tb_XX_nombre.v    ← Testbench (opcional)
└── XX_nombre.md      ← Documentación del proyecto
```
