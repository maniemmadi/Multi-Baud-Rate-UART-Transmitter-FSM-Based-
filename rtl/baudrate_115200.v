`timescale 1ns/1ps
module uart_transmitter #(
    parameter CLK_FREQ = 100_000_000,  // Input clock frequency
    parameter BAUD = 115200              // Default baud rate
)(
    input clk,
    input rst,
    input start,
    input [7:0] data_in,
    output reg tx,
    output reg done
);

// FSM states
parameter IDLE  = 3'b000;
parameter START = 3'b001;
parameter DATA  = 3'b010;
parameter STOP  = 3'b011;
parameter DONE  = 3'b100;

// FSM registers
reg [2:0] state;
reg [3:0] bit_index;
reg [7:0] data_reg;

// Baud rate generator
localparam integer BAUD_DIV = CLK_FREQ / BAUD; // calculate divider
reg [31:0] baud_cnt; // enough to count high dividers
wire baud_tick;

always @(posedge clk or posedge rst) begin
    if(rst)
        baud_cnt <= 0;
    else if(baud_cnt == BAUD_DIV-1)
        baud_cnt <= 0;
    else
        baud_cnt <= baud_cnt + 1;
end

assign baud_tick = (baud_cnt == BAUD_DIV-1);

// FSM
always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
        tx <= 1;
        done <= 0;
        bit_index <= 0;
        data_reg <= 0;
    end else begin
        case(state)

        IDLE: begin
            tx <= 1;
            done <= 0;
            if(start) begin
                data_reg <= data_in;
                state <= START;
            end
        end

        START: begin
            if(baud_tick) begin
                tx <= 0;  // start bit
                state <= DATA;
                bit_index <= 0;
            end
        end

        DATA: begin
            if(baud_tick) begin
                tx <= data_reg[bit_index];
                if(bit_index == 7)
                    state <= STOP;
                else
                    bit_index <= bit_index + 1;
            end
        end

        STOP: begin
            if(baud_tick) begin
                tx <= 1; // stop bit
                state <= DONE;
            end
        end

        DONE: begin
            done <= 1;
            state <= IDLE;
        end

        endcase
    end
end

endmodule