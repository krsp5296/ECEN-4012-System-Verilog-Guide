module fp_compare (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic        lt,
    output logic        eq,
    output logic        gt,
    output logic        invalid
);
 
    // ---- Field extraction -----------------------------------------------
    logic        sign_a, sign_b;
    logic [7:0]  exp_a,  exp_b;
    logic [22:0] mant_a, mant_b;
 
    assign {sign_a, exp_a, mant_a} = a;
    assign {sign_b, exp_b, mant_b} = b;
 
    // ---- Classification --------------------------------------------------
    // A NaN has exponent all-ones AND a non-zero mantissa.
    // An infinity has exponent all-ones AND a zero mantissa.
    // A zero has exponent zero AND mantissa zero (sign may be either).
    logic is_nan_a,  is_nan_b;
    logic is_zero_a, is_zero_b;
 
    assign is_nan_a  = (exp_a == 8'hFF) && (mant_a != 23'b0);
    assign is_nan_b  = (exp_b == 8'hFF) && (mant_b != 23'b0);
    assign is_zero_a = (exp_a == 8'h00) && (mant_a == 23'b0);
    assign is_zero_b = (exp_b == 8'h00) && (mant_b == 23'b0);
 
    // Magnitude pattern (exponent + mantissa, 31 bits). For same-signed
    // ordered floats, larger magnitude bits == larger absolute value.
    logic [30:0] mag_a, mag_b;
    assign mag_a = {exp_a, mant_a};
    assign mag_b = {exp_b, mant_b};
 
    // ---- Comparison core -------------------------------------------------
    always_comb begin
        // Default: ordered, equal. Each branch overrides as needed.
        lt      = 1'b0;
        eq      = 1'b0;
        gt      = 1'b0;
        invalid = 1'b0;
 
        if (is_nan_a || is_nan_b) begin
            // IEEE 754: any comparison with NaN is unordered.
            invalid = 1'b1;
        end
        else if (is_zero_a && is_zero_b) begin
            // +0 == -0 regardless of sign bits.
            eq = 1'b1;
        end
        else if (sign_a != sign_b) begin
            // Different signs: positive > negative. (Zeros handled above.)
            gt = (sign_a == 1'b0);  // a positive, b negative -> a > b
            lt = (sign_a == 1'b1);  // a negative, b positive -> a < b
        end
        else begin
            // Same sign, both non-zero, neither is NaN.
            // For positive numbers, larger magnitude pattern == larger value.
            // For negative numbers, larger magnitude pattern == smaller value
            // (more negative), so the relation flips.
            if (mag_a == mag_b) begin
                eq = 1'b1;
            end
            else if (sign_a == 1'b0) begin
                // Both positive.
                gt = (mag_a > mag_b);
                lt = (mag_a < mag_b);
            end
            else begin
                // Both negative.
                gt = (mag_a < mag_b);
                lt = (mag_a > mag_b);
            end
        end
    end
 
endmodule
