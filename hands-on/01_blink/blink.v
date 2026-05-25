// Copyright 2025 proyecto-tang-nano-9k contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * blink — LED parpadeante en Tang Nano 9K
 *
 * Enciende y apaga el LED0 cada HALF_PERIOD ciclos de reloj.
 * Con CLK de 27 MHz y HALF_PERIOD = 13_500_000 el LED parpadea a ~1 Hz
 * (0.5 s encendido, 0.5 s apagado).
 *
 * El LED de la Tang Nano 9K es activo en bajo: led_n = 0 → encendido.
 *
 * Ports:
 *   clk   - Reloj de entrada (27 MHz, pin 52)
 *   led_n - Salida al LED0, activo en bajo (pin 10)
 */
module blink #(
  // Ciclos de reloj para medio periodo. Ajustar en testbench para simular rápido.
  parameter integer HALF_PERIOD = 13_500_000
) (
  input  wire clk,    // Reloj 27 MHz
  output wire led_n   // LED activo en bajo
);

  // Número de bits necesarios para contar hasta HALF_PERIOD-1.
  // 2^24 = 16_777_216 > 13_500_000  → 24 bits alcanza.
  localparam integer CNT_WIDTH = 24;

  reg [CNT_WIDTH-1:0] cnt_q;
  reg                 led_q;

  // -----------------------------------------------------------
  // Contador y toggle del LED
  // -----------------------------------------------------------
  always @(posedge clk) begin
    if (cnt_q == HALF_PERIOD - 1) begin
      cnt_q <= {CNT_WIDTH{1'b0}};
      led_q <= ~led_q;
    end else begin
      cnt_q <= cnt_q + 1'b1;
    end
  end

  // led_n = 0 cuando led_q = 1  (activo en bajo)
  assign led_n = ~led_q;

endmodule
