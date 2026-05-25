// Copyright 2025 proyecto-tang-nano-9k contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * tb_blink — Testbench para el módulo blink
 *
 * Usa HALF_PERIOD = 5 para que el toggle ocurra cada 5 ciclos y
 * la simulación sea instantánea. Verifica que:
 *   1. led_n arranca en 1 (LED apagado).
 *   2. led_n cambia a 0 después de HALF_PERIOD ciclos (LED enciende).
 *   3. led_n vuelve a 1 después de otro HALF_PERIOD (LED apaga).
 *
 * Genera blink.vcd para visualizar en WaveTrace / GTKWave.
 */
`timescale 1ns/1ps

module tb_blink;

  // ---- Parámetro de simulación (pequeño para ir rápido) ----
  localparam integer HALF_PERIOD_SIM = 5;

  // ---- Señales ----
  reg  clk;
  wire led_n;

  // ---- DUT ----
  blink #(
    .HALF_PERIOD(HALF_PERIOD_SIM)
  ) dut (
    .clk  (clk),
    .led_n(led_n)
  );

  // ---- Reloj: periodo = 2 ns (equivale a 500 MHz en sim, solo para ver ciclos) ----
  initial clk = 0;
  always #1 clk = ~clk;

  // ---- Volcado de señales ----
  initial begin
    $dumpfile("blink.vcd");
    $dumpvars(0, tb_blink);
  end

  // ---- Verificación ----
  integer errors;
  initial begin
    errors = 0;

    // Ciclo 0: led_n debe iniciar en 1 (led_q = 0, apagado)
    @(negedge clk);
    if (led_n !== 1'b1) begin
      $display("FAIL  t=%0t: led_n=%b (esperado 1 al inicio)", $time, led_n);
      errors = errors + 1;
    end

    // Esperar HALF_PERIOD ciclos → primer toggle (LED enciende, led_n = 0)
    repeat (HALF_PERIOD_SIM) @(posedge clk);
    #1; // pequeño delay post-flanco para leer salida
    if (led_n !== 1'b0) begin
      $display("FAIL  t=%0t: led_n=%b (esperado 0 tras primer HALF_PERIOD)", $time, led_n);
      errors = errors + 1;
    end else begin
      $display("PASS  t=%0t: primer toggle OK — LED encendido (led_n=0)", $time);
    end

    // Esperar otro HALF_PERIOD → segundo toggle (LED apaga, led_n = 1)
    repeat (HALF_PERIOD_SIM) @(posedge clk);
    #1;
    if (led_n !== 1'b1) begin
      $display("FAIL  t=%0t: led_n=%b (esperado 1 tras segundo HALF_PERIOD)", $time, led_n);
      errors = errors + 1;
    end else begin
      $display("PASS  t=%0t: segundo toggle OK — LED apagado (led_n=1)", $time);
    end

    // Resumen
    if (errors == 0)
      $display("\n=== TODOS LOS TESTS PASARON ===");
    else
      $display("\n=== %0d ERRORES ENCONTRADOS ===", errors);

    // Simular 2 periodos más para ver la forma de onda completa
    repeat (HALF_PERIOD_SIM * 4) @(posedge clk);
    $finish;
  end

endmodule
