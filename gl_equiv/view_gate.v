// As view_gold.v, from the netlist's side: everything downstream of each
// $equiv cell runs on the netlist's values alone. Used by base.ys.
(* techmap_celltype = "$equiv" *)
module view_gate (input A, input B, output Y);
  assign Y = B;
endmodule
