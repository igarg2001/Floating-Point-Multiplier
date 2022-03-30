module booth_mul_rad4 (temp_manA, temp_manB, temp_product); //radix4_booth_multiplier
	input [12:0] temp_manA;
	input [12:0] temp_manB;
   
	output reg [25:0] temp_product;
	
	reg [12:0] M;
	reg [12:0] M2;
	reg [12:0] M_;
	reg [12:0] M2_;
	reg [2:0] multiplier;
	reg [12:0] temp_sum;
	
	reg [2:0] i;
	
	always @(*) begin
		M = temp_manA;
		M2 = temp_manA << 1'b1;
		M_ = ~temp_manA + 13'd1;
		M2_ = M_ << 1'b1;
		temp_product = {13'b0, temp_manB}; // Initialization
		for (i=0; i<6; i=i+1) begin
			multiplier = temp_product[2:0];
            // $display("multiplier = %b\n", multiplier);
			case (multiplier)
				3'b000:
					temp_sum = temp_product[25:13];
				3'b001:
					temp_sum = temp_product[25:13] + M;
				3'b010:
					temp_sum = temp_product[25:13] + M;
				3'b011:
					temp_sum = temp_product[25:13] + M2;
				3'b100:
					temp_sum = temp_product[25:13] + M2_;
				3'b101:
					temp_sum = temp_product[25:13] + M_;
				3'b110:
					temp_sum = temp_product[25:13] + M_;
				3'b111:
					temp_sum = temp_product[25:13];
			endcase
			// Right Shifting the result by two bits
            // $display("temp_sum = %b\n", temp_sum);
			temp_product = {temp_sum[12], temp_sum[12], temp_sum[12:0], temp_product[12:2]};
		end
	end
endmodule

module hp_multiplier (hp_inA, hp_inB, hp_product, Exceptions);
	input [15:0] hp_inA;
	input [15:0] hp_inB;
	output reg [15:0] hp_product;
	output reg [1:0] Exceptions;

    
	
	reg [9:0] man_A, man_B;
	reg [4:0] exp_A, exp_B;
	reg 	  sign_A, sign_B;
	
	reg [5:0] exp_product;
	reg sign_product;
    reg [9:0] man_product;
	reg [12:0] booth_manA, booth_manB;
	wire [25:0] booth_product;

    reg[5:0] exp_product_flow;

    reg[1:0] normCheck;


    booth_mul_rad4 A0 (
	.temp_manA (booth_manA),
    .temp_manB (booth_manB),
    .temp_product (booth_product)
	);
	
	/*assign sign_A = hp_inA[15];
	assign exp_A = hp_inA[14:10];
	assign man_A = hp_inA[9:0];
	assign sign_B = hp_inB[15];
	assign exp_B = hp_inB[14:10];
	assign man_B = hp_inB[9:0];*/
	
	always @(*) begin
		
		// Breaking up the half-precision number
		sign_A = hp_inA[15];
		exp_A = hp_inA[14:10];
		man_A = hp_inA[9:0];
		sign_B = hp_inB[15];
		exp_B = hp_inB[14:10];
		man_B = hp_inB[9:0];


        // booth_mul_rad4 A0 (
		// 	.temp_manA (booth_manA),
		// 	.temp_manB (booth_manB),
		// 	.temp_product (booth_product)
		// 	);
		
		// Checking for exceptions (NaN, Infinity, etc)
		
		// If any of the inputs is infinity, set Exceptions flag to 11
		if ( (exp_A==31 && man_A==10'b0) || (exp_B==31 && man_B==10'b0)) begin
			Exceptions = 2'b11;
			hp_product = 16'bx;
			$display("Invalid Input - Atleast one of the inputs is infinity");
		end
		
		// If any of the inputs is NaN, set Exceptions flag to 11
		else if ( (exp_A==31 && man_A!=10'b0) || (exp_B==31 && man_B!=10'b0)) begin
			Exceptions = 2'b11;
			hp_product = 16'bx;
			$display("Invalid Input - Atleast one of the inputs is NaN");
		end
		
		// If any of the inputs is a Denormalized number, set Exceptions flag to 11
		else if ( (exp_A==0 && man_A!=10'b0) || (exp_B==0 && man_B!=10'b0)) begin
			Exceptions = 2'b11;
			hp_product = 16'bx;
			$display("Invalid Input - Atleast one of the inputs is a Denormalized number");
		end
		
		// If any of the inputs is zero, set output to zero
		// This is just done to save execution time in certain cases
		else if ( (exp_A==0 && man_A==10'b0) || (exp_B==0 && man_B==10'b0)) begin
            $display("Valid Input - One of the inputs is Zero");
			Exceptions = 2'b00;
			hp_product = 16'b0;
		end
		
		// Now dealing with Floating point numbers
		else begin
			exp_product = exp_A + exp_B - 5'd15;
			sign_product = sign_A ^ sign_B;
			
			#100;
            booth_manA = {3'b001, man_A};
			booth_manB = {2'b01, man_B, 1'b0};
            #100;

            normCheck = booth_product[22:21];
            case (normCheck)
                2'b01: begin
                    man_product = booth_product[20:11];
                end
                2'b10: begin
                    man_product = booth_product[21:12];
                    exp_product = exp_product + 5'd1;
                end
                2'b11: begin
                    man_product = booth_product[21:12];
                    exp_product = exp_product + 5'd1;
                end
        endcase
        exp_product_flow = {1'b0, exp_product} + 5'd15;
        if (exp_product_flow < 6'd15) begin
            // $display("exp_product_flow = %b", exp_product_flow);
            $display("Exception - Underflow\n");
            Exceptions = 2'b10;
            hp_product = 16'bx;
        end
        else if (exp_product_flow > 6'd46) begin
            //  $display("exp_product_flow = %b", exp_product_flow);
            $display("Exception - Overflow\n");
            Exceptions = 2'b01;
            hp_product = 16'bx;
        end
        else begin
             $display("Valid Output\n");
             hp_product = {sign_product, exp_product[4:0], man_product};
             Exceptions = 2'b00;
        end
			// Calling the Booth Multiplier module
			// Checking for underflow and Overflow
			//if (exp_A+exp_B>46 || exp_A+exp_B<15)
		end
	end
endmodule

