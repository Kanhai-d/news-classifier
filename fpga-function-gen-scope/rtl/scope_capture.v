// Capture FSM of the oscilloscope.
//
//   S_WAIT    : look for the wave crossing the trigger level while going up.
//   S_CAPTURE : save 512 samples into the RAM bank that is not on screen.
//   S_DONE    : wait for the end of the screen frame (frame_tick),
//               show the new bank and go back to S_WAIT.
//
// timebase picks how many generator samples are skipped between saved samples:
//   0 = every sample, 1 = every 4th, 2 = every 16th, 3 = every 64th
module scope_capture #(
    parameter [7:0] LEVEL = 8'd128
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       sample_ce,     // one pulse per generator sample
    input  wire [7:0] sample,
    input  wire [1:0] timebase,
    input  wire       frame_tick,    // one pulse per screen frame (in the blank time)
    output wire       we,
    output wire [9:0] waddr,
    output wire [7:0] wdata,
    output reg        disp_bank      // bank the screen reads
);
    localparam [1:0] S_WAIT = 2'd0, S_CAPTURE = 2'd1, S_DONE = 2'd2;

    reg  [1:0]  state;
    reg         wr_bank;
    reg  [8:0]  addr;
    reg  [7:0]  prev;
    reg  [5:0]  dec_cnt;
    reg  [14:0] wait_cnt;

    // Time scale: skip samples.
    reg [5:0] dec_limit;
    always @(*) begin
        case (timebase)
            2'd0:    dec_limit = 6'd0;
            2'd1:    dec_limit = 6'd3;
            2'd2:    dec_limit = 6'd15;
            default: dec_limit = 6'd63;
        endcase
    end

    wire scope_ce = sample_ce && (dec_cnt >= dec_limit);

    // Rising crossing of the level, or a time out so the screen never freezes.
    wire hit = (prev < LEVEL) && (sample >= LEVEL);
    wire trig = hit || wait_cnt[14];

    assign we    = scope_ce && ((state == S_WAIT && trig) || (state == S_CAPTURE));
    assign waddr = {wr_bank, addr};
    assign wdata = sample;

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_WAIT;
            wr_bank   <= 1'b0;
            disp_bank <= 1'b1;
            addr      <= 9'd0;
            prev      <= 8'd0;
            dec_cnt   <= 6'd0;
            wait_cnt  <= 15'd0;
        end else begin
            if (sample_ce)
                dec_cnt <= scope_ce ? 6'd0 : dec_cnt + 6'd1;
            if (scope_ce)
                prev <= sample;

            case (state)
                S_WAIT: begin
                    if (scope_ce) begin
                        if (trig) begin
                            addr     <= 9'd1;      // sample 0 is written now
                            wait_cnt <= 15'd0;
                            state    <= S_CAPTURE;
                        end else begin
                            wait_cnt <= wait_cnt + 15'd1;
                        end
                    end
                end

                S_CAPTURE: begin
                    if (scope_ce) begin
                        if (addr == 9'd511) begin
                            addr  <= 9'd0;
                            state <= S_DONE;
                        end else begin
                            addr <= addr + 9'd1;
                        end
                    end
                end

                S_DONE: begin
                    if (frame_tick) begin
                        disp_bank <= wr_bank;
                        wr_bank   <= ~wr_bank;
                        state     <= S_WAIT;
                    end
                end

                default: state <= S_WAIT;
            endcase
        end
    end
endmodule
