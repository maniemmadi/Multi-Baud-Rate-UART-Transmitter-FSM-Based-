`timescale 1ns/1ps
module uart_tb;

// Parameters
parameter CLK_FREQ = 100_000_000;
parameter BAUD = 115200; // Change here to test 9600, 115200, 1_000_000

reg clk;
reg rst;
reg start;
reg [7:0] data_in;

wire tx;
wire done;

// Instantiate UART
uart_transmitter #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD(BAUD)
) uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .data_in(data_in),
    .tx(tx),
    .done(done)
);

// 100 MHz clock
always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    start = 0;
    data_in = 0;

    #20;
    rst = 0;
    // Example: Send 10110000
    send_char(8'b10110000);
    send_char(8'b10110010);
    send_char(8'b10111001);
    send_char(8'b10011011);
    send_char(8'b10011010);
    // Example: Send 1100011 padded to 8 bits
    send_char(8'b01100011);

    // Wait long enough for all characters to transmit
    #8_330_000; // wait long enough for all 8 characters at 9600 baud// adjust based on baud rate
    $finish;
end

// TASK to send character
task send_char;
input [7:0] char;
begin
    @(posedge clk);
    data_in = char;
    start = 1;

    @(posedge clk);
    start = 0;

    @(posedge done);
    @(posedge clk); // small gap
end
endtask

endmodule