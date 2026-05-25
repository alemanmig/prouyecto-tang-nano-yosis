# ============================================================
# Makefile — 01_blink / Tang Nano 9K (Gowin GW1NR-9C)
# Toolchain: yosys + nextpnr-himbaechel + gowin_pack + openFPGALoader
# ============================================================

TOP    = blink
SRC    = $(TOP).v
CST    = $(TOP).cst

DEVICE = GW1NR-LV9QN88PC6/I5
BOARD  = tangnano9k
CHIPDB = $(HOME)/oss-cad-suite/share/nextpnr/himbaechel/gowin/chipdb-GW1N-9C.bin

# ------------------------------------------------------------
# Flujo principal: síntesis → P&R → bitstream
# ------------------------------------------------------------
all: $(TOP).fs

# 1. Síntesis: Verilog → netlist JSON (Gowin primitivas)
$(TOP).json: $(SRC)
	yosys -p "synth_gowin -top $(TOP) -json $@" $<

# 2. Place & Route: netlist → netlist ubicado y enrutado
$(TOP)_pnr.json: $(TOP).json $(CST)
	nextpnr-himbaechel \
	  --device $(DEVICE) \
	  --chipdb $(CHIPDB) \
	  --json $(TOP).json \
	  --cst $(CST) \
	  --write $@

# 3. Pack: netlist P&R → bitstream .fs
$(TOP).fs: $(TOP)_pnr.json
	gowin_pack -d $(DEVICE) -o $@ $<

# ------------------------------------------------------------
# Programar la placa
# ------------------------------------------------------------

# Cargar en SRAM — volátil, ideal para desarrollo
flash: $(TOP).fs
	openFPGALoader -b $(BOARD) $<

# Cargar en Flash interna — persiste al reiniciar
flash-persistent: $(TOP).fs
	openFPGALoader -b $(BOARD) --write-flash $<

# ------------------------------------------------------------
# Simulación con iverilog
# ------------------------------------------------------------
sim: tb_$(TOP).v $(SRC)
	iverilog -o sim.vvp tb_$(TOP).v $(SRC)
	vvp sim.vvp

# ------------------------------------------------------------
# Limpieza
# ------------------------------------------------------------
clean:
	rm -f *.json *.fs *.vvp *.vcd

.PHONY: all flash flash-persistent sim clean
