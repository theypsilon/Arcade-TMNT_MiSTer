module rom_loader_mia(
	input reset,
	input clk_sys,
	input [25:0] ioctl_addr,
	input [15:0] ioctl_dout,
	input ioctl_wr,
	input load_en,
	
	output reg rom_68k_we,
	output reg rom_z80_we,
	output reg rom_tiles_we,
	output reg rom_sprites_we,
	output reg rom_007232_we,
	output reg rom_prom2_we,
	
	output reg [25:0] rom_addr	// Word-based
);

// ROM data is sent in the order defined in the MRA file and loaded to:

// 			MIA
// 68k		256kB		SDRAM 	16bit		0x0000000
// Z80		32kB		BRAM		8bit
// Tiles		256kB		SDRAM 	32bit		0x1000000
// Sprites	1MB		SDRAM 	32bit		0x1200000
// k007232	128kB		BRAM		8bit
// Prio		256B		BRAM		4bit

// Byte-based lengths
localparam ROM_68K_L = 		26'h040000;
localparam ROM_Z80_L = 		26'h008000;
localparam ROM_TILES_L = 	26'h040000;
localparam ROM_SPRITES_L = 26'h100000;
localparam ROM_007232_L = 	26'h020000;
localparam ROM_PROM2_L = 	26'h000100;

// Bases
wire [25:0] ROM_68K_B = 	26'h000000;
wire [25:0] ROM_Z80_B = 	ROM_68K_B + 		ROM_68K_L;
wire [25:0] ROM_TILES_B = 	ROM_Z80_B + 		ROM_Z80_L;
wire [25:0] ROM_SPRITES_B = ROM_TILES_B + 	ROM_TILES_L;
wire [25:0] ROM_007232_B = ROM_SPRITES_B + 	ROM_SPRITES_L;
wire [25:0] ROM_PROM2_B = 	ROM_007232_B + 	ROM_007232_L;
wire [25:0] ROM_END = 		ROM_PROM2_B + 		ROM_PROM2_L;

wire is_68k = 		ioctl_addr >= ROM_68K_B && ioctl_addr < ROM_Z80_B;
wire is_z80 = 		ioctl_addr >= ROM_Z80_B && ioctl_addr < ROM_TILES_B;
wire is_tiles = 	ioctl_addr >= ROM_TILES_B && ioctl_addr < ROM_SPRITES_B;
wire is_sprites = ioctl_addr >= ROM_SPRITES_B && ioctl_addr < ROM_007232_B;
wire is_007232 = 	ioctl_addr >= ROM_007232_B && ioctl_addr < ROM_PROM2_B;
wire is_prom2 = 	ioctl_addr >= ROM_PROM2_B && ioctl_addr < ROM_END;

// Byte-based offsets
localparam offs_tiles = 26'h1000000;
localparam offs_sprites = 26'h1200000;
localparam offs_m68k = 26'h0000000;

wire [25:0] addr_68k = 		(ioctl_addr - ROM_68K_B) + offs_m68k;
wire [25:0] addr_z80 = 		ioctl_addr - ROM_Z80_B;
wire [25:0] addr_tiles = 	(ioctl_addr - ROM_TILES_B) + offs_tiles;
wire [25:0] addr_sprites = (ioctl_addr - ROM_SPRITES_B) + offs_sprites;
wire [25:0] addr_007232 = 	ioctl_addr - ROM_007232_B;
wire [25:0] addr_prom2 = 	ioctl_addr - ROM_PROM2_B;

always @(posedge clk_sys) begin
	if (ioctl_wr & load_en) begin
		if (is_68k) begin
			rom_68k_we <= 1'b1;
			rom_addr <= {1'b0, addr_68k[25:1]};
		end else if (is_z80) begin
			rom_z80_we <= 1'b1;
			rom_addr <= addr_z80;
		end else if (is_tiles) begin
			rom_tiles_we <= 1'b1;
			rom_addr <= {1'b0, addr_tiles[25:1]};
		end else if (is_sprites) begin
			rom_sprites_we <= 1'b1;
			rom_addr <= {1'b0, addr_sprites[25:1]};
		end else if (is_007232) begin
			rom_007232_we <= 1'b1;
			rom_addr <= addr_007232;
		end else if (is_prom2) begin
			rom_prom2_we <= 1'b1;
			rom_addr <= addr_prom2;
		end
	end else begin
		rom_68k_we <= 1'b0;
		rom_z80_we <= 1'b0;
		rom_tiles_we <= 1'b0;
		rom_sprites_we <= 1'b0;
		rom_007232_we <= 1'b0;
		rom_prom2_we <= 1'b0;
	end
end

endmodule