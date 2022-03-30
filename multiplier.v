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


        /* booth_mul_rad4 A0 (
	 	.temp_manA (booth_manA),
	 	.temp_manB (booth_manB),
	 	.temp_product (booth_product)
	 	);*/
		
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
		
			// Checking for Underflow and Overflow
			exp_product_flow = {1'b0, exp_product} + 5'd15;
			if (exp_product_flow < 6'd16) begin
				// $display("exp_product_flow = %b", exp_product_flow);
				$display("Exception - Underflow\n");
				Exceptions = 2'b10;
				hp_product = 16'bx;
			end
			else if (exp_product_flow > 6'd45) begin
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
			//if (exp_A+exp_B>46 || exp_A+exp_B<15)
		end
	end
endmodule



module multiplier_test;
	reg [15:0] hp_inA, hp_inB;
	wire [15:0] hp_product;
	wire [1:0] Exceptions;
	
	reg [4:0] count;
	hp_multiplier B0 (hp_inA, hp_inB, hp_product, Exceptions);
	initial begin

		count = 5'd0;
         //1. A = 5, B = 6
        #0;
		hp_inA = 16'b0100010100000000;
		hp_inB = 16'b0100011000000000;
		count = count + 5'd1;

		//2. A=0, B=4.9
		#1000;
		hp_inA = 16'b0000000000000000;
		hp_inB = 16'b0100010011100110;
		count = count+5'd1;

		//3. A=+inf, B=4.9
		#1000;
		hp_inA = 16'b0111110000000000;
		hp_inB = 16'b0100010011100110;
		count = count+5'd1;
		
		//4. A=-inf, B=0
		#1000;
		hp_inA = 16'b1111110000000000;
		hp_inB = 16'b0000000000000000;
		count = count+5'd1;

		//5. A=NaN, B=4.9
		#1000;
		hp_inA = 16'b0111110100000100;
		hp_inB = 16'b0100010011100110;
		count = count+5'd1;

		//6. A=-NaN, B=0
		#1000;
		hp_inA = 16'b1111110100000100;
		hp_inB = 16'b0000000000000000;
		count = count+5'd1;

		//7. A=+Denormalized B=4.9
		#1000;
		hp_inA = 16'b0000000100011110;
		hp_inB = 16'b0100010011100110;
		count = count+5'd1;

		//8. A=-Denormalized B=0
		#1000;
		hp_inA = 16'b1000000100011110;
		hp_inB = 16'b0000000000000000;
		count = count+5'd1;
	
		//9. Underflow: A = 0.0000763, B = 0.0001526
		#1000;
		hp_inA = 16'b0000010100000000;
		hp_inB = 16'b0000100100000110;
		count = count+5'd1;

   
		//10. Case where shifting of the mantissa is needed: A = 3.0, B = 3.0
		#1000;
		hp_inA = 16'b0100001000000000;
		hp_inB = 16'b0100001000000000;
		count = count+5'd1;

		//11. A = +2.5, B = +4
		#15000;
		hp_inA = 16'b0100000100000000;
		hp_inB = 16'b0100010000000000;
		count = count+5'd1;
	
		//12. A = +2.5, B = -4
		#15000;
		hp_inA = 16'b0100000100000000;
		hp_inB = 16'b1100010000000000;
		count = count+5'd1;

		//13. A = -2.5, B = +4
		#15000;
		hp_inA = 16'b1100000100000000;
		hp_inB = 16'b0100010000000000;
		count = count+5'd1;

		//14. A = -2.5, B = -4
		#15000;
		hp_inA = 16'b1100000100000000;
		hp_inB = 16'b1100010000000000;
		count = count+5'd1;

		//15. A = 1.5*2^-8, B = 1.5*2^-7
		#15000;
		hp_inA = 16'b0001111000000000;
		hp_inB = 16'b0010001000000000;
		count = count+5'd1;

		//16. A=2.5, B=4.9
		#15000;
		hp_inA = 16'b0100000100000000;
		hp_inB = 16'b0100010011100110;
		count = count+5'd1;

        //17. Overflow: A = 270, B = 1082
		#15000;
		hp_inA = 16'b0101110000111000;
		hp_inB = 16'b0110010000111010;
        count = count+5'd1;
        //18. Overflow due to bit shift: A = 192, B = 384
        #15000;
		hp_inA = 16'b0101101000000000;
		hp_inB = 16'b0101111000000000;
        count = count+5'd1;

        //19. Max range A = 65504, B = -65504
		// #15000;
		hp_inA = 16'b0111101111111111;
		hp_inB = 16'b1111101111111111;
        count = count+5'd1;

        //20. A = 65504, B = 1
		#15000;
		hp_inA = 16'b0111101111111111;
		hp_inB = 16'b0011110000000000;
        count = count+5'd1;
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
		$monitor("Test case = %d\nA = %b\nB = %b\nOutput = %b\nExceptions=%b\n", count, hp_inA, hp_inB, hp_product, Exceptions);
	end
endmodule