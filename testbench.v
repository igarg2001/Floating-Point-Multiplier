`include "multiplier.v"
module multiplier_test;
reg [15:0] hp_inA, hp_inB;
wire [15:0] hp_product;
wire [1:0] Exceptions;
hp_multiplier B0 (hp_inA, hp_inB, hp_product, Exceptions);
initial begin

    //1. A=2.5, B=4.9
    #0;
    hp_inA = 16'b0100000100000000;
    hp_inB = 16'b0100010011100110;

    //2. A=0, B=4.9
    #1000;
    hp_inA = 16'b0000000000000000;
    hp_inB = 16'b0100010011100110;

    //3. A=+inf, B=4.9
    #1000;
    hp_inA = 16'b0111110000000000;
    hp_inB = 16'b0100010011100110;

    //4. A=-inf, B=0
    #1000;
    hp_inA = 16'b1111110000000000;
    hp_inB = 16'b0000000000000000;

    //5. A=NaN, B=4.9
    #1000;
    hp_inA = 16'b0111110100000100;
    hp_inB = 16'b0100010011100110;

    //6. A=-NaN, B=0
    #1000;
    hp_inA = 16'b1111110100000100;
    hp_inB = 16'b0000000000000000;

    //7. A=+Denormalized B=4.9
    #1000;
    hp_inA = 16'b0000000100011110;
    hp_inB = 16'b0100010011100110;

    //8. A=-Denormalized B=0
    #1000;
    hp_inA = 16'b1000000100011110;
    hp_inB = 16'b0000000000000000;

    //9. Underflow: A = 0.0000763, B = 0.0001526
    #1000;
    hp_inA = 16'b0000010100000000;
    hp_inB = 16'b0000100100000110;

   
//    10. Saved from underflow: A = 1.5, B = 1.5
    #1000;
    hp_inA = 16'b0100001000000000;
    hp_inB = 16'b0100001000000000;

    //11. A = +2.5, B = +4
    #15000;
    hp_inA = 16'b0100000100000000;
    hp_inB = 16'b0100010000000000;

    //12. A = +2.5, B = -4
    #15000;
    hp_inA = 16'b0100000100000000;
    hp_inB = 16'b1100010000000000;

    //13. A = -2.5, B = +4
    #15000;
    hp_inA = 16'b1100000100000000;
    hp_inB = 16'b0100010000000000;

      //14. A = -2.5, B = -4
    #15000;
    hp_inA = 16'b1100000100000000;
    hp_inB = 16'b1100010000000000;

    //12. 
    // #1000;
    // hp_inA = 16'b0100000100000000;
    // hp_inB = 16'b0100010011100110;

    // #1000;
    // hp_inA = 16'b0100000100000000;
    // hp_inB = 16'b0100010011100110;

    // #1000;
    // hp_inA = 16'b0100000100000000;
    // hp_inB = 16'b0100010011100110;

    // #1000;
    // hp_inA = 16'b0100000100000000;
    // hp_inB = 16'b0100010011100110;
    // #1000;
    // hp_inA = 16'b0100000100000000;
    // hp_inB = 16'b0100010011100110;
    // #1000;
    // hp_inA = 16'b0100000100000000;
    // hp_inB = 16'b0100010011100110;
    // #1000;
    // hp_inA = 16'b0100000100000000;
    // hp_inB = 16'b0100010011100110;
    // #1000;
    // hp_inA = 16'b0100000100000000;
    // hp_inB = 16'b0100010011100110;
    // #1000;
    // hp_inA = 16'b0100000100000000;
    // hp_inB = 16'b0100010011100110;
end

initial begin
    $monitor("A = %d\nB = %d\nOutput = %b\nDecimal output = %d\n", hp_inA, hp_inB, hp_product, hp_product);
end

endmodule