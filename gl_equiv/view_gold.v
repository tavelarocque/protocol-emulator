// Turns each $equiv cell (A: the RTL's signal, B: the netlist's) into a
// wire from the RTL's side, so that everything downstream runs on the RTL's
// values alone. Used by base.ys.
(* techmap_celltype = "$equiv" *)
module view_gold (input A, input B, output Y);
  assign Y = A;
endmodule
