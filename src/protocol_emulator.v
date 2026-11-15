module protocol_emulator (
    uio_in,
    clear,
    clock,
    ui_in,
    uo_out,
    uio_out,
    uio_oe
);

    input [7:0] uio_in;
    input clear;
    input clock;
    input [7:0] ui_in;
    output [7:0] uo_out;
    output [7:0] uio_out;
    output [7:0] uio_oe;

    wire _189;
    wire _190;
    wire [1:0] _187;
    wire [1:0] _186;
    wire _188;
    wire _191;
    wire [1:0] _184;
    wire [1:0] _183;
    wire _185;
    wire _192;
    wire _179;
    wire _180;
    wire [1:0] _176;
    wire _178;
    wire _181;
    wire [1:0] _173;
    wire _175;
    wire _182;
    wire _169;
    wire _170;
    wire [1:0] _166;
    wire _168;
    wire _171;
    wire [1:0] _163;
    wire _165;
    wire _172;
    wire _159;
    wire _160;
    wire [1:0] _156;
    wire _158;
    wire _161;
    wire [1:0] _153;
    wire _155;
    wire _162;
    wire _149;
    wire _150;
    wire [1:0] _146;
    wire _148;
    wire _151;
    wire [1:0] _143;
    wire _145;
    wire _152;
    wire _139;
    wire _140;
    wire [1:0] _136;
    wire _138;
    wire _141;
    wire [1:0] _133;
    wire _135;
    wire _142;
    wire _129;
    wire _130;
    wire [1:0] _126;
    wire _128;
    wire _131;
    wire [1:0] _123;
    wire _125;
    wire _132;
    wire _119;
    wire _120;
    wire [1:0] _113;
    wire _115;
    wire _121;
    wire [1:0] _110;
    wire _112;
    wire _122;
    wire [7:0] _193;
    wire _232;
    wire [1:0] _229;
    wire _231;
    wire _233;
    wire _227;
    wire [1:0] _224;
    wire _226;
    wire _228;
    wire _222;
    wire [1:0] _219;
    wire _221;
    wire _223;
    wire _217;
    wire [1:0] _214;
    wire _216;
    wire _218;
    wire _212;
    wire [1:0] _209;
    wire _211;
    wire _213;
    wire _207;
    wire [1:0] _204;
    wire _206;
    wire _208;
    wire _202;
    wire [1:0] _199;
    wire _201;
    wire _203;
    wire _197;
    wire [1:0] _194;
    wire _196;
    wire _198;
    wire [7:0] _234;
    wire [15:0] _356;
    wire _716;
    wire [14:0] _715;
    wire [15:0] _717;
    wire [13:0] _710;
    wire [15:0] _711;
    wire [9:0] _702;
    wire [15:0] _706;
    wire _696;
    wire [14:0] _695;
    wire [15:0] _697;
    wire [17:0] _693;
    wire [15:0] _694;
    wire [15:0] _698;
    wire [3:0] _681;
    wire _682;
    wire _683;
    reg [15:0] t1_rx_mem_15;
    wire [3:0] _675;
    wire _676;
    wire _677;
    reg [15:0] t1_rx_mem_14;
    wire [3:0] _669;
    wire _670;
    wire _671;
    reg [15:0] t1_rx_mem_13;
    wire [3:0] _663;
    wire _664;
    wire _665;
    reg [15:0] t1_rx_mem_12;
    wire [3:0] _657;
    wire _658;
    wire _659;
    reg [15:0] t1_rx_mem_11;
    wire [3:0] _651;
    wire _652;
    wire _653;
    reg [15:0] t1_rx_mem_10;
    wire [3:0] _645;
    wire _646;
    wire _647;
    reg [15:0] t1_rx_mem_9;
    wire [3:0] _639;
    wire _640;
    wire _641;
    reg [15:0] t1_rx_mem_8;
    wire [3:0] _633;
    wire _634;
    wire _635;
    reg [15:0] t1_rx_mem_7;
    wire [3:0] _627;
    wire _628;
    wire _629;
    reg [15:0] t1_rx_mem_6;
    wire [3:0] _621;
    wire _622;
    wire _623;
    reg [15:0] t1_rx_mem_5;
    wire [3:0] _615;
    wire _616;
    wire _617;
    reg [15:0] t1_rx_mem_4;
    wire [3:0] _609;
    wire _610;
    wire _611;
    reg [15:0] t1_rx_mem_3;
    wire [3:0] _603;
    wire _604;
    wire _605;
    reg [15:0] t1_rx_mem_2;
    wire [3:0] _597;
    wire _598;
    wire _599;
    reg [15:0] t1_rx_mem_1;
    wire [3:0] _591;
    wire [3:0] _246;
    wire [3:0] _247;
    wire [3:0] _3;
    reg [3:0] t1_rx_wr;
    wire _592;
    wire _593;
    wire [15:0] _308;
    wire [31:0] _310;
    wire [7:0] _305;
    wire [23:0] _304;
    wire [31:0] _306;
    wire [27:0] _300;
    wire [31:0] _302;
    wire [1:0] _297;
    wire [29:0] _296;
    wire [31:0] _298;
    wire [31:0] _294;
    wire [31:0] _293;
    wire _292;
    wire [31:0] _295;
    wire _291;
    wire [31:0] _299;
    wire _290;
    wire [31:0] _303;
    wire _289;
    wire [31:0] _307;
    wire _288;
    wire [31:0] _311;
    wire [15:0] _312;
    wire [15:0] _313;
    wire [15:0] _314;
    wire [15:0] _284;
    wire [31:0] _285;
    wire [23:0] _280;
    wire [31:0] _281;
    wire [27:0] _276;
    wire [31:0] _277;
    wire [29:0] _272;
    wire [31:0] _273;
    wire [30:0] _268;
    wire [31:0] _269;
    wire [31:0] _266;
    wire _261;
    wire [31:0] _270;
    wire _260;
    wire [31:0] _274;
    wire _259;
    wire [31:0] _278;
    wire _258;
    wire [31:0] _282;
    wire [4:0] _252;
    wire [4:0] _256;
    wire _257;
    wire [31:0] _286;
    wire [15:0] _287;
    wire [15:0] _315;
    wire [15:0] _4;
    reg [15:0] t1_rx_mem_0;
    wire [3:0] _324;
    wire [3:0] _325;
    wire [3:0] _5;
    reg [3:0] t1_rx_rd;
    reg [15:0] _685;
    wire [4:0] _585;
    wire _586;
    wire _587;
    wire [15:0] _686;
    wire [15:0] _584;
    wire [10:0] _575;
    wire [15:0] _579;
    wire [12:0] _570;
    wire [15:0] _574;
    wire [15:0] _569;
    wire [15:0] _564;
    wire [15:0] _559;
    wire [15:0] _554;
    wire [15:0] _549;
    wire [15:0] _541;
    wire _531;
    wire [15:0] _532;
    wire [17:0] _528;
    wire [15:0] _529;
    wire [15:0] _533;
    wire _411;
    wire _412;
    wire [15:0] _521;
    wire [15:0] _406;
    wire [15:0] _401;
    wire [15:0] _396;
    wire [15:0] _391;
    wire [15:0] _386;
    wire [15:0] _381;
    wire [15:0] _376;
    reg [15:0] _712;
    wire [15:0] _713;
    wire [15:0] _714;
    wire [4:0] _347;
    wire _348;
    wire _349;
    wire _342;
    wire _337;
    wire _341;
    wire _343;
    wire _350;
    wire [15:0] _718;
    wire [15:0] _719;
    wire [15:0] _6;
    reg [15:0] host_miso_shift;
    wire _5237;
    wire _5236;
    wire _5234;
    wire _5235;
    wire _5232;
    wire _5230;
    wire _5228;
    wire _5229;
    wire [4:0] _5223;
    wire _3602;
    wire _3597;
    wire [6:0] _3593;
    wire _3594;
    wire _3592;
    wire _3595;
    wire _3598;
    wire _3601;
    wire _5217;
    wire [4:0] _5193;
    wire _421;
    wire _5187;
    wire _5185;
    wire [2:0] _5182;
    wire _5183;
    wire [3:0] _5160;
    wire [1:0] _5154;
    wire [3:0] _5155;
    wire _5149;
    wire [3:0] _5152;
    wire _5148;
    wire [3:0] _5156;
    wire [3:0] _5157;
    wire _420;
    wire _2412;
    wire _2411;
    wire _2413;
    wire _2414;
    wire _2403;
    wire _2405;
    wire _2408;
    wire _2400;
    wire _2397;
    wire [2:0] _2395;
    wire [7:0] _733;
    wire [6:0] _729;
    wire _730;
    wire _727;
    wire _731;
    wire [7:0] _734;
    wire [7:0] _7;
    reg [7:0] cfg_t0_start;
    wire [5:0] _5140;
    wire [1:0] _5139;
    wire [7:0] _5141;
    wire [7:0] _739;
    wire [6:0] _736;
    wire _737;
    wire _735;
    wire _738;
    wire [7:0] _740;
    wire [7:0] _8;
    reg [7:0] cfg_t0_timeout_vector;
    wire [2:0] _5137;
    wire _5138;
    wire [7:0] _5142;
    wire [7:0] _5135;
    wire [7:0] _5136;
    wire [15:0] _2379;
    wire [15:0] _2380;
    wire [15:0] _2381;
    wire [15:0] _2382;
    wire [15:0] _2383;
    wire [15:0] _2385;
    wire [15:0] _9;
    wire [15:0] _10;
    reg [15:0] t0_wait_count;
    wire [6:0] _2387;
    wire _2388;
    wire _2386;
    wire _2389;
    wire [15:0] _2390;
    wire [15:0] _11;
    reg [15:0] cfg_t0_timeout;
    wire _2418;
    wire _2377;
    wire _2364;
    wire _2301;
    wire _2365;
    wire _2367;
    wire _2378;
    wire _2419;
    wire _2421;
    wire _2422;
    wire _2423;
    wire _2425;
    wire _12;
    wire _13;
    reg t0_waiting;
    wire [15:0] _2374;
    wire _2376;
    wire _2366;
    wire _2399;
    wire _2362;
    wire _2360;
    wire _2359;
    wire _2358;
    wire _2357;
    wire _2356;
    wire _2355;
    wire _2354;
    wire _2353;
    wire [2:0] _2302;
    reg _2361;
    wire _2363;
    wire _5131;
    wire _5130;
    wire _5132;
    wire _5133;
    wire _5126;
    wire [4:0] _399;
    wire [4:0] _2430;
    wire [6:0] _2427;
    wire _2428;
    wire _2426;
    wire _2429;
    wire [4:0] _2431;
    wire [4:0] _14;
    reg [4:0] cfg_t0_threshold;
    wire [4:0] _2468;
    wire [5:0] _2465;
    wire [5:0] _2458;
    wire [5:0] _2466;
    wire [5:0] _2457;
    wire _2467;
    wire [4:0] _2470;
    wire [4:0] _2455;
    wire _2449;
    wire [4:0] _2451;
    wire [4:0] _2452;
    wire _2440;
    wire [4:0] _2453;
    wire _2438;
    wire [4:0] _2456;
    wire _2436;
    wire [4:0] _2471;
    wire [4:0] _2472;
    wire [4:0] _2473;
    wire [4:0] _2474;
    wire [4:0] _2475;
    wire [4:0] _15;
    wire [4:0] _16;
    reg [4:0] t0_osr_count;
    wire _5125;
    wire _5123;
    wire _5124;
    wire _5120;
    wire _5121;
    wire _5122;
    wire [15:0] _5105;
    wire [2:0] _5102;
    wire _5103;
    wire [15:0] _5106;
    wire _5099;
    wire [15:0] _5100;
    wire _2350;
    wire _2349;
    wire _2348;
    wire [1:0] _2347;
    reg _2351;
    wire _2345;
    wire _2344;
    wire _2343;
    wire [1:0] _2342;
    reg _2346;
    wire _2340;
    wire _2339;
    wire _2338;
    wire [1:0] _2337;
    reg _2341;
    wire _2335;
    wire _2334;
    wire _2333;
    wire [1:0] _2332;
    reg _2336;
    wire _2330;
    wire _2329;
    wire _2328;
    wire [1:0] _2327;
    reg _2331;
    wire _2325;
    wire _2324;
    wire _2323;
    wire [1:0] _2322;
    reg _2326;
    wire _2320;
    wire _2319;
    wire _2318;
    wire [1:0] _2317;
    reg _2321;
    wire _2315;
    wire [7:0] _117;
    wire _4826;
    wire _4825;
    wire _4824;
    wire _4823;
    wire _4822;
    wire _4821;
    wire _4820;
    wire _4819;
    reg _4827;
    wire _4818;
    wire [3:0] _4816;
    wire [2:0] _4813;
    wire [3:0] _4814;
    wire _4817;
    wire _4828;
    wire _4809;
    wire _4808;
    wire _4807;
    wire _4806;
    wire _4805;
    wire _4804;
    wire _4803;
    wire _4802;
    reg _4810;
    wire _4801;
    wire [3:0] _4799;
    wire [2:0] _4796;
    wire [3:0] _4797;
    wire _4800;
    wire _4811;
    wire _4792;
    wire _4791;
    wire _4790;
    wire _4789;
    wire _4788;
    wire _4787;
    wire _4786;
    wire _4785;
    reg _4793;
    wire _4784;
    wire [3:0] _4782;
    wire [2:0] _4779;
    wire [3:0] _4780;
    wire _4783;
    wire _4794;
    wire _4775;
    wire _4774;
    wire _4773;
    wire _4772;
    wire _4771;
    wire _4770;
    wire _4769;
    wire _4768;
    reg _4776;
    wire _4767;
    wire [3:0] _4765;
    wire [2:0] _4761;
    wire [2:0] _4762;
    wire [3:0] _4763;
    wire _4766;
    wire _4777;
    wire _4758;
    wire _4757;
    wire _4756;
    wire _4755;
    wire _4754;
    wire _4753;
    wire _4752;
    wire _4751;
    reg _4759;
    wire _4750;
    wire [3:0] _4748;
    wire [2:0] _4745;
    wire [3:0] _4746;
    wire _4749;
    wire _4760;
    wire _4741;
    wire _4740;
    wire _4739;
    wire _4738;
    wire _4737;
    wire _4736;
    wire _4735;
    wire _4734;
    reg _4742;
    wire _4733;
    wire [3:0] _4731;
    wire [2:0] _4727;
    wire [2:0] _4728;
    wire [3:0] _4729;
    wire _4732;
    wire _4743;
    wire _4724;
    wire _4723;
    wire _4722;
    wire _4721;
    wire _4720;
    wire _4719;
    wire _4718;
    wire _4717;
    reg _4725;
    wire _4716;
    wire [3:0] _4714;
    wire [2:0] _4710;
    wire [2:0] _4711;
    wire [3:0] _4712;
    wire _4715;
    wire _4726;
    wire _4707;
    wire _4706;
    wire _4705;
    wire _4704;
    wire _4703;
    wire _4702;
    wire _4701;
    wire [1:0] _4694;
    wire [3:0] _4695;
    wire [2:0] _4690;
    wire [3:0] _4691;
    wire _4688;
    wire [3:0] _4692;
    wire _4687;
    wire [3:0] _4696;
    wire [2:0] _4684;
    wire [2:0] _4685;
    wire _4686;
    wire [3:0] _4698;
    wire [7:0] _4699;
    wire _4700;
    reg _4708;
    wire _4676;
    wire _4675;
    wire _4674;
    wire _4673;
    wire _4672;
    wire _4671;
    wire _4670;
    wire _4669;
    reg _4677;
    wire _4668;
    wire [2:0] _4665;
    wire [4:0] _4666;
    wire _4667;
    wire _4678;
    wire _4660;
    wire _4659;
    wire _4658;
    wire _4657;
    wire _4656;
    wire _4655;
    wire _4654;
    wire _4653;
    reg _4661;
    wire _4652;
    wire [2:0] _4649;
    wire [4:0] _4650;
    wire _4651;
    wire _4662;
    wire _4644;
    wire _4643;
    wire _4642;
    wire _4641;
    wire _4640;
    wire _4639;
    wire _4638;
    wire _4637;
    reg _4645;
    wire _4636;
    wire [2:0] _4633;
    wire [4:0] _4634;
    wire _4635;
    wire _4646;
    wire _4628;
    wire _4627;
    wire _4626;
    wire _4625;
    wire _4624;
    wire _4623;
    wire _4622;
    wire _4621;
    reg _4629;
    wire _4620;
    wire [2:0] _4617;
    wire [4:0] _4618;
    wire _4619;
    wire _4630;
    wire _4612;
    wire _4611;
    wire _4610;
    wire _4609;
    wire _4608;
    wire _4607;
    wire _4606;
    wire _4605;
    reg _4613;
    wire _4604;
    wire [2:0] _4601;
    wire [4:0] _4602;
    wire _4603;
    wire _4614;
    wire _4596;
    wire _4595;
    wire _4594;
    wire _4593;
    wire _4592;
    wire _4591;
    wire _4590;
    wire _4589;
    reg _4597;
    wire _4588;
    wire [2:0] _4585;
    wire [4:0] _4586;
    wire _4587;
    wire _4598;
    wire _4580;
    wire _4579;
    wire _4578;
    wire _4577;
    wire _4576;
    wire _4575;
    wire _4574;
    wire _4573;
    reg _4581;
    wire _4572;
    wire [2:0] _4569;
    wire [4:0] _4570;
    wire _4571;
    wire _4582;
    wire _4564;
    wire _4563;
    wire _4562;
    wire _4561;
    wire _4560;
    wire _4559;
    wire _4558;
    wire _4557;
    reg _4565;
    wire _4556;
    wire [2:0] _4552;
    wire [2:0] _4553;
    wire [4:0] _4554;
    wire _4555;
    wire _4566;
    wire [7:0] _4679;
    wire _4546;
    wire _4545;
    wire _4544;
    wire _4543;
    wire _4542;
    wire _4541;
    wire _4540;
    wire _4539;
    reg _4547;
    wire _4538;
    wire [2:0] _4535;
    wire [3:0] _4536;
    wire _4537;
    wire _4548;
    wire _4531;
    wire _4530;
    wire _4529;
    wire _4528;
    wire _4527;
    wire _4526;
    wire _4525;
    wire _4524;
    reg _4532;
    wire _4523;
    wire [2:0] _4520;
    wire [3:0] _4521;
    wire _4522;
    wire _4533;
    wire _4516;
    wire _4515;
    wire _4514;
    wire _4513;
    wire _4512;
    wire _4511;
    wire _4510;
    wire _4509;
    reg _4517;
    wire _4508;
    wire [2:0] _4505;
    wire [3:0] _4506;
    wire _4507;
    wire _4518;
    wire _4501;
    wire _4500;
    wire _4499;
    wire _4498;
    wire _4497;
    wire _4496;
    wire _4495;
    wire _4494;
    reg _4502;
    wire _4493;
    wire [2:0] _4490;
    wire [3:0] _4491;
    wire _4492;
    wire _4503;
    wire _4486;
    wire _4485;
    wire _4484;
    wire _4483;
    wire _4482;
    wire _4481;
    wire _4480;
    wire _4479;
    reg _4487;
    wire _4478;
    wire [2:0] _4475;
    wire [3:0] _4476;
    wire _4477;
    wire _4488;
    wire _4471;
    wire _4470;
    wire _4469;
    wire _4468;
    wire _4467;
    wire _4466;
    wire _4465;
    wire _4464;
    reg _4472;
    wire _4463;
    wire [2:0] _4460;
    wire [3:0] _4461;
    wire _4462;
    wire _4473;
    wire _4456;
    wire _4455;
    wire _4454;
    wire _4453;
    wire _4452;
    wire _4451;
    wire _4450;
    wire _4449;
    reg _4457;
    wire _4448;
    wire [2:0] _4445;
    wire [3:0] _4446;
    wire _4447;
    wire _4458;
    wire _4441;
    wire _4440;
    wire _4439;
    wire _4438;
    wire _4437;
    wire _4436;
    wire _4435;
    wire _4434;
    reg _4442;
    wire _4433;
    wire [3:0] _4431;
    wire [7:0] _562;
    wire [7:0] _2480;
    wire [6:0] _2477;
    wire _2478;
    wire _2476;
    wire _2479;
    wire [7:0] _2481;
    wire [7:0] _17;
    reg [7:0] cfg_t1_out_cfg;
    wire [2:0] _4428;
    wire [2:0] _4429;
    wire [3:0] _4430;
    wire _4432;
    wire _4443;
    wire [7:0] _4549;
    wire _4422;
    wire _4421;
    wire _4420;
    wire _4419;
    wire _4418;
    wire _4417;
    wire _4416;
    wire _4415;
    reg _4423;
    wire _4414;
    wire [2:0] _4411;
    wire [3:0] _4412;
    wire _4413;
    wire _4424;
    wire _4407;
    wire _4406;
    wire _4405;
    wire _4404;
    wire _4403;
    wire _4402;
    wire _4401;
    wire _4400;
    reg _4408;
    wire _4399;
    wire [2:0] _4396;
    wire [3:0] _4397;
    wire _4398;
    wire _4409;
    wire _4392;
    wire _4391;
    wire _4390;
    wire _4389;
    wire _4388;
    wire _4387;
    wire _4386;
    wire _4385;
    reg _4393;
    wire _4384;
    wire [2:0] _4381;
    wire [3:0] _4382;
    wire _4383;
    wire _4394;
    wire _4377;
    wire _4376;
    wire _4375;
    wire _4374;
    wire _4373;
    wire _4372;
    wire _4371;
    wire _4370;
    reg _4378;
    wire _4369;
    wire [2:0] _4366;
    wire [3:0] _4367;
    wire _4368;
    wire _4379;
    wire _4362;
    wire _4361;
    wire _4360;
    wire _4359;
    wire _4358;
    wire _4357;
    wire _4356;
    wire _4355;
    reg _4363;
    wire _4354;
    wire [2:0] _4351;
    wire [3:0] _4352;
    wire _4353;
    wire _4364;
    wire _4347;
    wire _4346;
    wire _4345;
    wire _4344;
    wire _4343;
    wire _4342;
    wire _4341;
    wire _4340;
    reg _4348;
    wire _4339;
    wire [2:0] _4336;
    wire [3:0] _4337;
    wire _4338;
    wire _4349;
    wire _4332;
    wire _4331;
    wire _4330;
    wire _4329;
    wire _4328;
    wire _4327;
    wire _4326;
    wire _4325;
    reg _4333;
    wire _4324;
    wire [2:0] _4321;
    wire [3:0] _4322;
    wire _4323;
    wire _4334;
    wire _4317;
    wire _4316;
    wire _4315;
    wire _4314;
    wire _4313;
    wire _4312;
    wire _4311;
    wire _4310;
    reg _4318;
    wire _4309;
    wire [3:0] _4307;
    wire [7:0] _2486;
    wire [6:0] _2483;
    wire _2484;
    wire _2482;
    wire _2485;
    wire [7:0] _2487;
    wire [7:0] _18;
    reg [7:0] cfg_t1_set_cfg;
    wire [2:0] _4304;
    wire [2:0] _4305;
    wire [3:0] _4306;
    wire _4308;
    wire _4319;
    wire [7:0] _4425;
    wire _3137;
    wire _3136;
    wire _3135;
    wire _3134;
    wire _3133;
    wire _3132;
    wire _3131;
    wire _3130;
    reg _3138;
    wire _3129;
    wire [3:0] _3127;
    wire [2:0] _3124;
    wire [3:0] _3125;
    wire _3128;
    wire _3139;
    wire _3120;
    wire _3119;
    wire _3118;
    wire _3117;
    wire _3116;
    wire _3115;
    wire _3114;
    wire _3113;
    reg _3121;
    wire _3112;
    wire [3:0] _3110;
    wire [2:0] _3107;
    wire [3:0] _3108;
    wire _3111;
    wire _3122;
    wire _3103;
    wire _3102;
    wire _3101;
    wire _3100;
    wire _3099;
    wire _3098;
    wire _3097;
    wire _3096;
    reg _3104;
    wire _3095;
    wire [3:0] _3093;
    wire [2:0] _3090;
    wire [3:0] _3091;
    wire _3094;
    wire _3105;
    wire _3086;
    wire _3085;
    wire _3084;
    wire _3083;
    wire _3082;
    wire _3081;
    wire _3080;
    wire _3079;
    reg _3087;
    wire _3078;
    wire [3:0] _3076;
    wire [2:0] _3073;
    wire [3:0] _3074;
    wire _3077;
    wire _3088;
    wire _3069;
    wire _3068;
    wire _3067;
    wire _3066;
    wire _3065;
    wire _3064;
    wire _3063;
    wire _3062;
    reg _3070;
    wire _3061;
    wire [3:0] _3059;
    wire [2:0] _3056;
    wire [3:0] _3057;
    wire _3060;
    wire _3071;
    wire _3052;
    wire _3051;
    wire _3050;
    wire _3049;
    wire _3048;
    wire _3047;
    wire _3046;
    wire _3045;
    reg _3053;
    wire _3044;
    wire [3:0] _3042;
    wire [2:0] _3039;
    wire [3:0] _3040;
    wire _3043;
    wire _3054;
    wire _3035;
    wire _3034;
    wire _3033;
    wire _3032;
    wire _3031;
    wire _3030;
    wire _3029;
    wire _3028;
    reg _3036;
    wire _3027;
    wire [3:0] _3025;
    wire [2:0] _3022;
    wire [3:0] _3023;
    wire _3026;
    wire _3037;
    wire _3018;
    wire _3017;
    wire _3016;
    wire _3015;
    wire _3014;
    wire _3013;
    wire _3012;
    wire [1:0] _3005;
    wire [3:0] _3006;
    wire [2:0] _3001;
    wire [3:0] _3002;
    wire [3:0] _2999;
    wire _2998;
    wire [3:0] _3003;
    wire _2997;
    wire [3:0] _3007;
    wire [2:0] _2994;
    wire [2:0] _2995;
    wire _2996;
    wire [3:0] _3009;
    wire [7:0] _3010;
    wire _3011;
    reg _3019;
    wire _2986;
    wire _2985;
    wire _2984;
    wire _2983;
    wire _2982;
    wire _2981;
    wire _2980;
    wire _2979;
    reg _2987;
    wire _2978;
    wire [2:0] _2975;
    wire [4:0] _2976;
    wire _2977;
    wire _2988;
    wire _2970;
    wire _2969;
    wire _2968;
    wire _2967;
    wire _2966;
    wire _2965;
    wire _2964;
    wire _2963;
    reg _2971;
    wire _2962;
    wire [2:0] _2959;
    wire [4:0] _2960;
    wire _2961;
    wire _2972;
    wire _2954;
    wire _2953;
    wire _2952;
    wire _2951;
    wire _2950;
    wire _2949;
    wire _2948;
    wire _2947;
    reg _2955;
    wire _2946;
    wire [2:0] _2943;
    wire [4:0] _2944;
    wire _2945;
    wire _2956;
    wire _2938;
    wire _2937;
    wire _2936;
    wire _2935;
    wire _2934;
    wire _2933;
    wire _2932;
    wire _2931;
    reg _2939;
    wire _2930;
    wire [2:0] _2927;
    wire [4:0] _2928;
    wire _2929;
    wire _2940;
    wire _2922;
    wire _2921;
    wire _2920;
    wire _2919;
    wire _2918;
    wire _2917;
    wire _2916;
    wire _2915;
    reg _2923;
    wire _2914;
    wire [2:0] _2911;
    wire [4:0] _2912;
    wire _2913;
    wire _2924;
    wire _2906;
    wire _2905;
    wire _2904;
    wire _2903;
    wire _2902;
    wire _2901;
    wire _2900;
    wire _2899;
    reg _2907;
    wire _2898;
    wire [2:0] _2895;
    wire [4:0] _2896;
    wire _2897;
    wire _2908;
    wire _2890;
    wire _2889;
    wire _2888;
    wire _2887;
    wire _2886;
    wire _2885;
    wire _2884;
    wire _2883;
    reg _2891;
    wire _2882;
    wire [2:0] _2879;
    wire [4:0] _2880;
    wire _2881;
    wire _2892;
    wire _2874;
    wire _2873;
    wire _2872;
    wire _2871;
    wire _2870;
    wire _2869;
    wire _2868;
    wire _2867;
    reg _2875;
    wire _2807;
    wire [2:0] _2804;
    wire [4:0] _2805;
    wire _2806;
    wire _2876;
    wire [7:0] _2989;
    wire _2797;
    wire _2796;
    wire _2795;
    wire _2794;
    wire _2793;
    wire _2792;
    wire _2791;
    wire _2790;
    reg _2798;
    wire _2789;
    wire [2:0] _2786;
    wire [3:0] _2787;
    wire _2788;
    wire _2799;
    wire _2782;
    wire _2781;
    wire _2780;
    wire _2779;
    wire _2778;
    wire _2777;
    wire _2776;
    wire _2775;
    reg _2783;
    wire _2774;
    wire [2:0] _2771;
    wire [3:0] _2772;
    wire _2773;
    wire _2784;
    wire _2767;
    wire _2766;
    wire _2765;
    wire _2764;
    wire _2763;
    wire _2762;
    wire _2761;
    wire _2760;
    reg _2768;
    wire _2759;
    wire [2:0] _2756;
    wire [3:0] _2757;
    wire _2758;
    wire _2769;
    wire _2752;
    wire _2751;
    wire _2750;
    wire _2749;
    wire _2748;
    wire _2747;
    wire _2746;
    wire _2745;
    reg _2753;
    wire _2744;
    wire [2:0] _2741;
    wire [3:0] _2742;
    wire _2743;
    wire _2754;
    wire _2737;
    wire _2736;
    wire _2735;
    wire _2734;
    wire _2733;
    wire _2732;
    wire _2731;
    wire _2730;
    reg _2738;
    wire _2729;
    wire [2:0] _2726;
    wire [3:0] _2727;
    wire _2728;
    wire _2739;
    wire _2722;
    wire _2721;
    wire _2720;
    wire _2719;
    wire _2718;
    wire _2717;
    wire _2716;
    wire _2715;
    reg _2723;
    wire _2714;
    wire [2:0] _2711;
    wire [3:0] _2712;
    wire _2713;
    wire _2724;
    wire _2707;
    wire _2706;
    wire _2705;
    wire _2704;
    wire _2703;
    wire _2702;
    wire _2701;
    wire _2700;
    reg _2708;
    wire _2699;
    wire [2:0] _2696;
    wire [3:0] _2697;
    wire _2698;
    wire _2709;
    wire _2692;
    wire _2691;
    wire _2690;
    wire _2689;
    wire _2688;
    wire _2687;
    wire _2686;
    wire _2685;
    reg _2693;
    wire _2668;
    wire [3:0] _2666;
    wire [7:0] _2492;
    wire [6:0] _2489;
    wire _2490;
    wire _2488;
    wire _2491;
    wire [7:0] _2493;
    wire [7:0] _19;
    reg [7:0] cfg_t0_out_cfg;
    wire [2:0] _2663;
    wire [2:0] _2664;
    wire [3:0] _2665;
    wire _2667;
    wire _2694;
    wire [7:0] _2800;
    wire _2657;
    wire _2656;
    wire _2655;
    wire _2654;
    wire _2653;
    wire _2652;
    wire _2651;
    wire _2650;
    reg _2658;
    wire _2649;
    wire [2:0] _2646;
    wire [3:0] _2647;
    wire _2648;
    wire _2659;
    wire _2642;
    wire _2641;
    wire _2640;
    wire _2639;
    wire _2638;
    wire _2637;
    wire _2636;
    wire _2635;
    reg _2643;
    wire _2634;
    wire [2:0] _2631;
    wire [3:0] _2632;
    wire _2633;
    wire _2644;
    wire _2627;
    wire _2626;
    wire _2625;
    wire _2624;
    wire _2623;
    wire _2622;
    wire _2621;
    wire _2620;
    reg _2628;
    wire _2619;
    wire [2:0] _2616;
    wire [3:0] _2617;
    wire _2618;
    wire _2629;
    wire _2612;
    wire _2611;
    wire _2610;
    wire _2609;
    wire _2608;
    wire _2607;
    wire _2606;
    wire _2605;
    reg _2613;
    wire _2604;
    wire [2:0] _2601;
    wire [3:0] _2602;
    wire _2603;
    wire _2614;
    wire _2597;
    wire _2596;
    wire _2595;
    wire _2594;
    wire _2593;
    wire _2592;
    wire _2591;
    wire _2590;
    reg _2598;
    wire _2589;
    wire [2:0] _2586;
    wire [3:0] _2587;
    wire _2588;
    wire _2599;
    wire _2582;
    wire _2581;
    wire _2580;
    wire _2579;
    wire _2578;
    wire _2577;
    wire _2576;
    wire _2575;
    reg _2583;
    wire _2574;
    wire [2:0] _2571;
    wire [3:0] _2572;
    wire _2573;
    wire _2584;
    wire _2567;
    wire _2566;
    wire _2565;
    wire _2564;
    wire _2563;
    wire _2562;
    wire _2561;
    wire _2560;
    reg _2568;
    wire _2559;
    wire [2:0] _2556;
    wire [3:0] _2557;
    wire _2558;
    wire _2569;
    wire _2552;
    wire _2551;
    wire _2550;
    wire _2549;
    wire _2548;
    wire _2547;
    wire _2546;
    wire _2545;
    reg _2553;
    wire _2541;
    wire [3:0] _2539;
    wire [7:0] _2498;
    wire [6:0] _2495;
    wire _2496;
    wire _2494;
    wire _2497;
    wire [7:0] _2499;
    wire [7:0] _20;
    reg [7:0] cfg_t0_set_cfg;
    wire [2:0] _2536;
    wire [2:0] _2537;
    wire [3:0] _2538;
    wire _2540;
    wire _2554;
    wire [7:0] _2660;
    wire _2533;
    wire _2529;
    wire _2530;
    wire _2534;
    wire [7:0] _2661;
    wire _2525;
    wire _2526;
    wire _2522;
    wire _2523;
    wire _2527;
    wire [7:0] _2801;
    wire [1:0] _2517;
    wire _2519;
    wire _2515;
    wire _2516;
    wire _2520;
    wire [7:0] _2990;
    wire _2991;
    wire [1:0] _2511;
    wire [3:0] _2512;
    wire [5:0] _539;
    wire [5:0] _2504;
    wire [6:0] _2501;
    wire _2502;
    wire _2500;
    wire _2503;
    wire [5:0] _2505;
    wire [5:0] _21;
    reg [5:0] cfg_t0_sideset;
    wire [2:0] _2507;
    wire [2:0] _2508;
    wire [3:0] _2509;
    wire _2513;
    wire _3020;
    wire [7:0] _3140;
    wire [7:0] _3141;
    wire [7:0] _3142;
    wire [7:0] _3143;
    wire [7:0] _22;
    wire _4301;
    wire _4298;
    wire _4299;
    wire _4302;
    wire [7:0] _4426;
    wire _4294;
    wire _4295;
    wire _4291;
    wire _4292;
    wire _4296;
    wire [7:0] _4550;
    wire [1:0] _4286;
    wire _4288;
    wire _4284;
    wire _4285;
    wire _4289;
    wire [7:0] _4680;
    wire _4681;
    wire [3:0] _4281;
    wire [2:0] _4277;
    wire [2:0] _4278;
    wire [3:0] _4279;
    wire _4282;
    wire _4709;
    wire [7:0] _4829;
    wire [3:0] _4254;
    wire [1:0] _4248;
    wire [3:0] _4249;
    wire _4243;
    wire [3:0] _4246;
    wire [5:0] _3148;
    wire [6:0] _3145;
    wire _3146;
    wire _3144;
    wire _3147;
    wire [5:0] _3149;
    wire [5:0] _23;
    reg [5:0] cfg_t1_sideset;
    wire [1:0] _4241;
    wire _4242;
    wire [3:0] _4250;
    wire [3:0] _4240;
    wire [3:0] _4251;
    wire _317;
    wire _318;
    wire _3160;
    wire _3161;
    wire [6:0] _3156;
    wire _3157;
    wire _3153;
    wire _3154;
    wire _3155;
    wire _3158;
    wire _3162;
    wire _24;
    wire _319;
    wire [4:0] _3190;
    wire _240;
    wire _3184;
    wire _3182;
    wire _3179;
    wire _3180;
    wire _3183;
    wire _3185;
    wire _25;
    wire _241;
    wire [4:0] _3187;
    wire [4:0] _3188;
    wire [4:0] _3191;
    wire [4:0] _26;
    reg [4:0] t1_rx_level;
    wire _239;
    wire _3266;
    wire _3265;
    wire _3267;
    wire _3268;
    wire _3258;
    wire _3259;
    wire _3262;
    wire _3255;
    wire _3252;
    wire _2295;
    wire _2296;
    reg [15:0] prog_255;
    wire [7:0] _2288;
    wire _2289;
    wire _2290;
    reg [15:0] prog_254;
    wire [7:0] _2282;
    wire _2283;
    wire _2284;
    reg [15:0] prog_253;
    wire [7:0] _2276;
    wire _2277;
    wire _2278;
    reg [15:0] prog_252;
    wire [7:0] _2270;
    wire _2271;
    wire _2272;
    reg [15:0] prog_251;
    wire [7:0] _2264;
    wire _2265;
    wire _2266;
    reg [15:0] prog_250;
    wire [7:0] _2258;
    wire _2259;
    wire _2260;
    reg [15:0] prog_249;
    wire [7:0] _2252;
    wire _2253;
    wire _2254;
    reg [15:0] prog_248;
    wire [7:0] _2246;
    wire _2247;
    wire _2248;
    reg [15:0] prog_247;
    wire [7:0] _2240;
    wire _2241;
    wire _2242;
    reg [15:0] prog_246;
    wire [7:0] _2234;
    wire _2235;
    wire _2236;
    reg [15:0] prog_245;
    wire [7:0] _2228;
    wire _2229;
    wire _2230;
    reg [15:0] prog_244;
    wire [7:0] _2222;
    wire _2223;
    wire _2224;
    reg [15:0] prog_243;
    wire [7:0] _2216;
    wire _2217;
    wire _2218;
    reg [15:0] prog_242;
    wire [7:0] _2210;
    wire _2211;
    wire _2212;
    reg [15:0] prog_241;
    wire [7:0] _2204;
    wire _2205;
    wire _2206;
    reg [15:0] prog_240;
    wire [7:0] _2198;
    wire _2199;
    wire _2200;
    reg [15:0] prog_239;
    wire [7:0] _2192;
    wire _2193;
    wire _2194;
    reg [15:0] prog_238;
    wire [7:0] _2186;
    wire _2187;
    wire _2188;
    reg [15:0] prog_237;
    wire [7:0] _2180;
    wire _2181;
    wire _2182;
    reg [15:0] prog_236;
    wire [7:0] _2174;
    wire _2175;
    wire _2176;
    reg [15:0] prog_235;
    wire [7:0] _2168;
    wire _2169;
    wire _2170;
    reg [15:0] prog_234;
    wire [7:0] _2162;
    wire _2163;
    wire _2164;
    reg [15:0] prog_233;
    wire [7:0] _2156;
    wire _2157;
    wire _2158;
    reg [15:0] prog_232;
    wire [7:0] _2150;
    wire _2151;
    wire _2152;
    reg [15:0] prog_231;
    wire [7:0] _2144;
    wire _2145;
    wire _2146;
    reg [15:0] prog_230;
    wire [7:0] _2138;
    wire _2139;
    wire _2140;
    reg [15:0] prog_229;
    wire [7:0] _2132;
    wire _2133;
    wire _2134;
    reg [15:0] prog_228;
    wire [7:0] _2126;
    wire _2127;
    wire _2128;
    reg [15:0] prog_227;
    wire [7:0] _2120;
    wire _2121;
    wire _2122;
    reg [15:0] prog_226;
    wire [7:0] _2114;
    wire _2115;
    wire _2116;
    reg [15:0] prog_225;
    wire [7:0] _2108;
    wire _2109;
    wire _2110;
    reg [15:0] prog_224;
    wire [7:0] _2102;
    wire _2103;
    wire _2104;
    reg [15:0] prog_223;
    wire [7:0] _2096;
    wire _2097;
    wire _2098;
    reg [15:0] prog_222;
    wire [7:0] _2090;
    wire _2091;
    wire _2092;
    reg [15:0] prog_221;
    wire [7:0] _2084;
    wire _2085;
    wire _2086;
    reg [15:0] prog_220;
    wire [7:0] _2078;
    wire _2079;
    wire _2080;
    reg [15:0] prog_219;
    wire [7:0] _2072;
    wire _2073;
    wire _2074;
    reg [15:0] prog_218;
    wire [7:0] _2066;
    wire _2067;
    wire _2068;
    reg [15:0] prog_217;
    wire [7:0] _2060;
    wire _2061;
    wire _2062;
    reg [15:0] prog_216;
    wire [7:0] _2054;
    wire _2055;
    wire _2056;
    reg [15:0] prog_215;
    wire [7:0] _2048;
    wire _2049;
    wire _2050;
    reg [15:0] prog_214;
    wire [7:0] _2042;
    wire _2043;
    wire _2044;
    reg [15:0] prog_213;
    wire [7:0] _2036;
    wire _2037;
    wire _2038;
    reg [15:0] prog_212;
    wire [7:0] _2030;
    wire _2031;
    wire _2032;
    reg [15:0] prog_211;
    wire [7:0] _2024;
    wire _2025;
    wire _2026;
    reg [15:0] prog_210;
    wire [7:0] _2018;
    wire _2019;
    wire _2020;
    reg [15:0] prog_209;
    wire [7:0] _2012;
    wire _2013;
    wire _2014;
    reg [15:0] prog_208;
    wire [7:0] _2006;
    wire _2007;
    wire _2008;
    reg [15:0] prog_207;
    wire [7:0] _2000;
    wire _2001;
    wire _2002;
    reg [15:0] prog_206;
    wire [7:0] _1994;
    wire _1995;
    wire _1996;
    reg [15:0] prog_205;
    wire [7:0] _1988;
    wire _1989;
    wire _1990;
    reg [15:0] prog_204;
    wire [7:0] _1982;
    wire _1983;
    wire _1984;
    reg [15:0] prog_203;
    wire [7:0] _1976;
    wire _1977;
    wire _1978;
    reg [15:0] prog_202;
    wire [7:0] _1970;
    wire _1971;
    wire _1972;
    reg [15:0] prog_201;
    wire [7:0] _1964;
    wire _1965;
    wire _1966;
    reg [15:0] prog_200;
    wire [7:0] _1958;
    wire _1959;
    wire _1960;
    reg [15:0] prog_199;
    wire [7:0] _1952;
    wire _1953;
    wire _1954;
    reg [15:0] prog_198;
    wire [7:0] _1946;
    wire _1947;
    wire _1948;
    reg [15:0] prog_197;
    wire [7:0] _1940;
    wire _1941;
    wire _1942;
    reg [15:0] prog_196;
    wire [7:0] _1934;
    wire _1935;
    wire _1936;
    reg [15:0] prog_195;
    wire [7:0] _1928;
    wire _1929;
    wire _1930;
    reg [15:0] prog_194;
    wire [7:0] _1922;
    wire _1923;
    wire _1924;
    reg [15:0] prog_193;
    wire [7:0] _1916;
    wire _1917;
    wire _1918;
    reg [15:0] prog_192;
    wire [7:0] _1910;
    wire _1911;
    wire _1912;
    reg [15:0] prog_191;
    wire [7:0] _1904;
    wire _1905;
    wire _1906;
    reg [15:0] prog_190;
    wire [7:0] _1898;
    wire _1899;
    wire _1900;
    reg [15:0] prog_189;
    wire [7:0] _1892;
    wire _1893;
    wire _1894;
    reg [15:0] prog_188;
    wire [7:0] _1886;
    wire _1887;
    wire _1888;
    reg [15:0] prog_187;
    wire [7:0] _1880;
    wire _1881;
    wire _1882;
    reg [15:0] prog_186;
    wire [7:0] _1874;
    wire _1875;
    wire _1876;
    reg [15:0] prog_185;
    wire [7:0] _1868;
    wire _1869;
    wire _1870;
    reg [15:0] prog_184;
    wire [7:0] _1862;
    wire _1863;
    wire _1864;
    reg [15:0] prog_183;
    wire [7:0] _1856;
    wire _1857;
    wire _1858;
    reg [15:0] prog_182;
    wire [7:0] _1850;
    wire _1851;
    wire _1852;
    reg [15:0] prog_181;
    wire [7:0] _1844;
    wire _1845;
    wire _1846;
    reg [15:0] prog_180;
    wire [7:0] _1838;
    wire _1839;
    wire _1840;
    reg [15:0] prog_179;
    wire [7:0] _1832;
    wire _1833;
    wire _1834;
    reg [15:0] prog_178;
    wire [7:0] _1826;
    wire _1827;
    wire _1828;
    reg [15:0] prog_177;
    wire [7:0] _1820;
    wire _1821;
    wire _1822;
    reg [15:0] prog_176;
    wire [7:0] _1814;
    wire _1815;
    wire _1816;
    reg [15:0] prog_175;
    wire [7:0] _1808;
    wire _1809;
    wire _1810;
    reg [15:0] prog_174;
    wire [7:0] _1802;
    wire _1803;
    wire _1804;
    reg [15:0] prog_173;
    wire [7:0] _1796;
    wire _1797;
    wire _1798;
    reg [15:0] prog_172;
    wire [7:0] _1790;
    wire _1791;
    wire _1792;
    reg [15:0] prog_171;
    wire [7:0] _1784;
    wire _1785;
    wire _1786;
    reg [15:0] prog_170;
    wire [7:0] _1778;
    wire _1779;
    wire _1780;
    reg [15:0] prog_169;
    wire [7:0] _1772;
    wire _1773;
    wire _1774;
    reg [15:0] prog_168;
    wire [7:0] _1766;
    wire _1767;
    wire _1768;
    reg [15:0] prog_167;
    wire [7:0] _1760;
    wire _1761;
    wire _1762;
    reg [15:0] prog_166;
    wire [7:0] _1754;
    wire _1755;
    wire _1756;
    reg [15:0] prog_165;
    wire [7:0] _1748;
    wire _1749;
    wire _1750;
    reg [15:0] prog_164;
    wire [7:0] _1742;
    wire _1743;
    wire _1744;
    reg [15:0] prog_163;
    wire [7:0] _1736;
    wire _1737;
    wire _1738;
    reg [15:0] prog_162;
    wire [7:0] _1730;
    wire _1731;
    wire _1732;
    reg [15:0] prog_161;
    wire [7:0] _1724;
    wire _1725;
    wire _1726;
    reg [15:0] prog_160;
    wire [7:0] _1718;
    wire _1719;
    wire _1720;
    reg [15:0] prog_159;
    wire [7:0] _1712;
    wire _1713;
    wire _1714;
    reg [15:0] prog_158;
    wire [7:0] _1706;
    wire _1707;
    wire _1708;
    reg [15:0] prog_157;
    wire [7:0] _1700;
    wire _1701;
    wire _1702;
    reg [15:0] prog_156;
    wire [7:0] _1694;
    wire _1695;
    wire _1696;
    reg [15:0] prog_155;
    wire [7:0] _1688;
    wire _1689;
    wire _1690;
    reg [15:0] prog_154;
    wire [7:0] _1682;
    wire _1683;
    wire _1684;
    reg [15:0] prog_153;
    wire [7:0] _1676;
    wire _1677;
    wire _1678;
    reg [15:0] prog_152;
    wire [7:0] _1670;
    wire _1671;
    wire _1672;
    reg [15:0] prog_151;
    wire [7:0] _1664;
    wire _1665;
    wire _1666;
    reg [15:0] prog_150;
    wire [7:0] _1658;
    wire _1659;
    wire _1660;
    reg [15:0] prog_149;
    wire [7:0] _1652;
    wire _1653;
    wire _1654;
    reg [15:0] prog_148;
    wire [7:0] _1646;
    wire _1647;
    wire _1648;
    reg [15:0] prog_147;
    wire [7:0] _1640;
    wire _1641;
    wire _1642;
    reg [15:0] prog_146;
    wire [7:0] _1634;
    wire _1635;
    wire _1636;
    reg [15:0] prog_145;
    wire [7:0] _1628;
    wire _1629;
    wire _1630;
    reg [15:0] prog_144;
    wire [7:0] _1622;
    wire _1623;
    wire _1624;
    reg [15:0] prog_143;
    wire [7:0] _1616;
    wire _1617;
    wire _1618;
    reg [15:0] prog_142;
    wire [7:0] _1610;
    wire _1611;
    wire _1612;
    reg [15:0] prog_141;
    wire [7:0] _1604;
    wire _1605;
    wire _1606;
    reg [15:0] prog_140;
    wire [7:0] _1598;
    wire _1599;
    wire _1600;
    reg [15:0] prog_139;
    wire [7:0] _1592;
    wire _1593;
    wire _1594;
    reg [15:0] prog_138;
    wire [7:0] _1586;
    wire _1587;
    wire _1588;
    reg [15:0] prog_137;
    wire [7:0] _1580;
    wire _1581;
    wire _1582;
    reg [15:0] prog_136;
    wire [7:0] _1574;
    wire _1575;
    wire _1576;
    reg [15:0] prog_135;
    wire [7:0] _1568;
    wire _1569;
    wire _1570;
    reg [15:0] prog_134;
    wire [7:0] _1562;
    wire _1563;
    wire _1564;
    reg [15:0] prog_133;
    wire [7:0] _1556;
    wire _1557;
    wire _1558;
    reg [15:0] prog_132;
    wire [7:0] _1550;
    wire _1551;
    wire _1552;
    reg [15:0] prog_131;
    wire [7:0] _1544;
    wire _1545;
    wire _1546;
    reg [15:0] prog_130;
    wire [7:0] _1538;
    wire _1539;
    wire _1540;
    reg [15:0] prog_129;
    wire [7:0] _1532;
    wire _1533;
    wire _1534;
    reg [15:0] prog_128;
    wire [7:0] _1526;
    wire _1527;
    wire _1528;
    reg [15:0] prog_127;
    wire [7:0] _1520;
    wire _1521;
    wire _1522;
    reg [15:0] prog_126;
    wire [7:0] _1514;
    wire _1515;
    wire _1516;
    reg [15:0] prog_125;
    wire [7:0] _1508;
    wire _1509;
    wire _1510;
    reg [15:0] prog_124;
    wire [7:0] _1502;
    wire _1503;
    wire _1504;
    reg [15:0] prog_123;
    wire [7:0] _1496;
    wire _1497;
    wire _1498;
    reg [15:0] prog_122;
    wire [7:0] _1490;
    wire _1491;
    wire _1492;
    reg [15:0] prog_121;
    wire [7:0] _1484;
    wire _1485;
    wire _1486;
    reg [15:0] prog_120;
    wire [7:0] _1478;
    wire _1479;
    wire _1480;
    reg [15:0] prog_119;
    wire [7:0] _1472;
    wire _1473;
    wire _1474;
    reg [15:0] prog_118;
    wire [7:0] _1466;
    wire _1467;
    wire _1468;
    reg [15:0] prog_117;
    wire [7:0] _1460;
    wire _1461;
    wire _1462;
    reg [15:0] prog_116;
    wire [7:0] _1454;
    wire _1455;
    wire _1456;
    reg [15:0] prog_115;
    wire [7:0] _1448;
    wire _1449;
    wire _1450;
    reg [15:0] prog_114;
    wire [7:0] _1442;
    wire _1443;
    wire _1444;
    reg [15:0] prog_113;
    wire [7:0] _1436;
    wire _1437;
    wire _1438;
    reg [15:0] prog_112;
    wire [7:0] _1430;
    wire _1431;
    wire _1432;
    reg [15:0] prog_111;
    wire [7:0] _1424;
    wire _1425;
    wire _1426;
    reg [15:0] prog_110;
    wire [7:0] _1418;
    wire _1419;
    wire _1420;
    reg [15:0] prog_109;
    wire [7:0] _1412;
    wire _1413;
    wire _1414;
    reg [15:0] prog_108;
    wire [7:0] _1406;
    wire _1407;
    wire _1408;
    reg [15:0] prog_107;
    wire [7:0] _1400;
    wire _1401;
    wire _1402;
    reg [15:0] prog_106;
    wire [7:0] _1394;
    wire _1395;
    wire _1396;
    reg [15:0] prog_105;
    wire [7:0] _1388;
    wire _1389;
    wire _1390;
    reg [15:0] prog_104;
    wire [7:0] _1382;
    wire _1383;
    wire _1384;
    reg [15:0] prog_103;
    wire [7:0] _1376;
    wire _1377;
    wire _1378;
    reg [15:0] prog_102;
    wire [7:0] _1370;
    wire _1371;
    wire _1372;
    reg [15:0] prog_101;
    wire [7:0] _1364;
    wire _1365;
    wire _1366;
    reg [15:0] prog_100;
    wire [7:0] _1358;
    wire _1359;
    wire _1360;
    reg [15:0] prog_99;
    wire [7:0] _1352;
    wire _1353;
    wire _1354;
    reg [15:0] prog_98;
    wire [7:0] _1346;
    wire _1347;
    wire _1348;
    reg [15:0] prog_97;
    wire [7:0] _1340;
    wire _1341;
    wire _1342;
    reg [15:0] prog_96;
    wire [7:0] _1334;
    wire _1335;
    wire _1336;
    reg [15:0] prog_95;
    wire [7:0] _1328;
    wire _1329;
    wire _1330;
    reg [15:0] prog_94;
    wire [7:0] _1322;
    wire _1323;
    wire _1324;
    reg [15:0] prog_93;
    wire [7:0] _1316;
    wire _1317;
    wire _1318;
    reg [15:0] prog_92;
    wire [7:0] _1310;
    wire _1311;
    wire _1312;
    reg [15:0] prog_91;
    wire [7:0] _1304;
    wire _1305;
    wire _1306;
    reg [15:0] prog_90;
    wire [7:0] _1298;
    wire _1299;
    wire _1300;
    reg [15:0] prog_89;
    wire [7:0] _1292;
    wire _1293;
    wire _1294;
    reg [15:0] prog_88;
    wire [7:0] _1286;
    wire _1287;
    wire _1288;
    reg [15:0] prog_87;
    wire [7:0] _1280;
    wire _1281;
    wire _1282;
    reg [15:0] prog_86;
    wire [7:0] _1274;
    wire _1275;
    wire _1276;
    reg [15:0] prog_85;
    wire [7:0] _1268;
    wire _1269;
    wire _1270;
    reg [15:0] prog_84;
    wire [7:0] _1262;
    wire _1263;
    wire _1264;
    reg [15:0] prog_83;
    wire [7:0] _1256;
    wire _1257;
    wire _1258;
    reg [15:0] prog_82;
    wire [7:0] _1250;
    wire _1251;
    wire _1252;
    reg [15:0] prog_81;
    wire [7:0] _1244;
    wire _1245;
    wire _1246;
    reg [15:0] prog_80;
    wire [7:0] _1238;
    wire _1239;
    wire _1240;
    reg [15:0] prog_79;
    wire [7:0] _1232;
    wire _1233;
    wire _1234;
    reg [15:0] prog_78;
    wire [7:0] _1226;
    wire _1227;
    wire _1228;
    reg [15:0] prog_77;
    wire [7:0] _1220;
    wire _1221;
    wire _1222;
    reg [15:0] prog_76;
    wire [7:0] _1214;
    wire _1215;
    wire _1216;
    reg [15:0] prog_75;
    wire [7:0] _1208;
    wire _1209;
    wire _1210;
    reg [15:0] prog_74;
    wire [7:0] _1202;
    wire _1203;
    wire _1204;
    reg [15:0] prog_73;
    wire [7:0] _1196;
    wire _1197;
    wire _1198;
    reg [15:0] prog_72;
    wire [7:0] _1190;
    wire _1191;
    wire _1192;
    reg [15:0] prog_71;
    wire [7:0] _1184;
    wire _1185;
    wire _1186;
    reg [15:0] prog_70;
    wire [7:0] _1178;
    wire _1179;
    wire _1180;
    reg [15:0] prog_69;
    wire [7:0] _1172;
    wire _1173;
    wire _1174;
    reg [15:0] prog_68;
    wire [7:0] _1166;
    wire _1167;
    wire _1168;
    reg [15:0] prog_67;
    wire [7:0] _1160;
    wire _1161;
    wire _1162;
    reg [15:0] prog_66;
    wire [7:0] _1154;
    wire _1155;
    wire _1156;
    reg [15:0] prog_65;
    wire [7:0] _1148;
    wire _1149;
    wire _1150;
    reg [15:0] prog_64;
    wire [7:0] _1142;
    wire _1143;
    wire _1144;
    reg [15:0] prog_63;
    wire [7:0] _1136;
    wire _1137;
    wire _1138;
    reg [15:0] prog_62;
    wire [7:0] _1130;
    wire _1131;
    wire _1132;
    reg [15:0] prog_61;
    wire [7:0] _1124;
    wire _1125;
    wire _1126;
    reg [15:0] prog_60;
    wire [7:0] _1118;
    wire _1119;
    wire _1120;
    reg [15:0] prog_59;
    wire [7:0] _1112;
    wire _1113;
    wire _1114;
    reg [15:0] prog_58;
    wire [7:0] _1106;
    wire _1107;
    wire _1108;
    reg [15:0] prog_57;
    wire [7:0] _1100;
    wire _1101;
    wire _1102;
    reg [15:0] prog_56;
    wire [7:0] _1094;
    wire _1095;
    wire _1096;
    reg [15:0] prog_55;
    wire [7:0] _1088;
    wire _1089;
    wire _1090;
    reg [15:0] prog_54;
    wire [7:0] _1082;
    wire _1083;
    wire _1084;
    reg [15:0] prog_53;
    wire [7:0] _1076;
    wire _1077;
    wire _1078;
    reg [15:0] prog_52;
    wire [7:0] _1070;
    wire _1071;
    wire _1072;
    reg [15:0] prog_51;
    wire [7:0] _1064;
    wire _1065;
    wire _1066;
    reg [15:0] prog_50;
    wire [7:0] _1058;
    wire _1059;
    wire _1060;
    reg [15:0] prog_49;
    wire [7:0] _1052;
    wire _1053;
    wire _1054;
    reg [15:0] prog_48;
    wire [7:0] _1046;
    wire _1047;
    wire _1048;
    reg [15:0] prog_47;
    wire [7:0] _1040;
    wire _1041;
    wire _1042;
    reg [15:0] prog_46;
    wire [7:0] _1034;
    wire _1035;
    wire _1036;
    reg [15:0] prog_45;
    wire [7:0] _1028;
    wire _1029;
    wire _1030;
    reg [15:0] prog_44;
    wire [7:0] _1022;
    wire _1023;
    wire _1024;
    reg [15:0] prog_43;
    wire [7:0] _1016;
    wire _1017;
    wire _1018;
    reg [15:0] prog_42;
    wire [7:0] _1010;
    wire _1011;
    wire _1012;
    reg [15:0] prog_41;
    wire [7:0] _1004;
    wire _1005;
    wire _1006;
    reg [15:0] prog_40;
    wire [7:0] _998;
    wire _999;
    wire _1000;
    reg [15:0] prog_39;
    wire [7:0] _992;
    wire _993;
    wire _994;
    reg [15:0] prog_38;
    wire [7:0] _986;
    wire _987;
    wire _988;
    reg [15:0] prog_37;
    wire [7:0] _980;
    wire _981;
    wire _982;
    reg [15:0] prog_36;
    wire [7:0] _974;
    wire _975;
    wire _976;
    reg [15:0] prog_35;
    wire [7:0] _968;
    wire _969;
    wire _970;
    reg [15:0] prog_34;
    wire [7:0] _962;
    wire _963;
    wire _964;
    reg [15:0] prog_33;
    wire [7:0] _956;
    wire _957;
    wire _958;
    reg [15:0] prog_32;
    wire [7:0] _950;
    wire _951;
    wire _952;
    reg [15:0] prog_31;
    wire [7:0] _944;
    wire _945;
    wire _946;
    reg [15:0] prog_30;
    wire [7:0] _938;
    wire _939;
    wire _940;
    reg [15:0] prog_29;
    wire [7:0] _932;
    wire _933;
    wire _934;
    reg [15:0] prog_28;
    wire [7:0] _926;
    wire _927;
    wire _928;
    reg [15:0] prog_27;
    wire [7:0] _920;
    wire _921;
    wire _922;
    reg [15:0] prog_26;
    wire [7:0] _914;
    wire _915;
    wire _916;
    reg [15:0] prog_25;
    wire [7:0] _908;
    wire _909;
    wire _910;
    reg [15:0] prog_24;
    wire [7:0] _902;
    wire _903;
    wire _904;
    reg [15:0] prog_23;
    wire [7:0] _896;
    wire _897;
    wire _898;
    reg [15:0] prog_22;
    wire [7:0] _890;
    wire _891;
    wire _892;
    reg [15:0] prog_21;
    wire [7:0] _884;
    wire _885;
    wire _886;
    reg [15:0] prog_20;
    wire [7:0] _878;
    wire _879;
    wire _880;
    reg [15:0] prog_19;
    wire [7:0] _872;
    wire _873;
    wire _874;
    reg [15:0] prog_18;
    wire [7:0] _866;
    wire _867;
    wire _868;
    reg [15:0] prog_17;
    wire _861;
    wire _862;
    reg [15:0] prog_16;
    wire [7:0] _854;
    wire _855;
    wire _856;
    reg [15:0] prog_15;
    wire [7:0] _848;
    wire _849;
    wire _850;
    reg [15:0] prog_14;
    wire [7:0] _842;
    wire _843;
    wire _844;
    reg [15:0] prog_13;
    wire [7:0] _836;
    wire _837;
    wire _838;
    reg [15:0] prog_12;
    wire [7:0] _830;
    wire _831;
    wire _832;
    reg [15:0] prog_11;
    wire [7:0] _824;
    wire _825;
    wire _826;
    reg [15:0] prog_10;
    wire [7:0] _818;
    wire _819;
    wire _820;
    reg [15:0] prog_9;
    wire [7:0] _812;
    wire _813;
    wire _814;
    reg [15:0] prog_8;
    wire [7:0] _806;
    wire _807;
    wire _808;
    reg [15:0] prog_7;
    wire [7:0] _800;
    wire _801;
    wire _802;
    reg [15:0] prog_6;
    wire [7:0] _794;
    wire _795;
    wire _796;
    reg [15:0] prog_5;
    wire [7:0] _788;
    wire _789;
    wire _790;
    reg [15:0] prog_4;
    wire [7:0] _782;
    wire _783;
    wire _784;
    reg [15:0] prog_3;
    wire [7:0] _776;
    wire _777;
    wire _778;
    reg [15:0] prog_2;
    wire _771;
    wire _772;
    reg [15:0] prog_1;
    wire [5:0] _762;
    wire [1:0] _761;
    wire [7:0] _763;
    wire _765;
    wire [6:0] _758;
    wire _759;
    wire _757;
    wire _760;
    wire _766;
    reg [15:0] prog_0;
    wire [7:0] _3196;
    wire [6:0] _3193;
    wire _3194;
    wire _3192;
    wire _3195;
    wire [7:0] _3197;
    wire [7:0] _27;
    reg [7:0] cfg_t1_start;
    wire [5:0] _4232;
    wire [1:0] _4231;
    wire [7:0] _4233;
    wire [7:0] _3202;
    wire [6:0] _3199;
    wire _3200;
    wire _3198;
    wire _3201;
    wire [7:0] _3203;
    wire [7:0] _28;
    reg [7:0] cfg_t1_timeout_vector;
    wire _4230;
    wire [7:0] _4234;
    wire [7:0] _4228;
    wire [15:0] _3239;
    wire [15:0] _3240;
    wire [15:0] _3241;
    wire [15:0] _3242;
    wire [15:0] _3244;
    wire [15:0] _29;
    wire [15:0] _30;
    reg [15:0] t1_wait_count;
    wire [6:0] _3246;
    wire _3247;
    wire _3245;
    wire _3248;
    wire [15:0] _3249;
    wire [15:0] _31;
    reg [15:0] cfg_t1_timeout;
    wire _3236;
    wire _3223;
    wire _3210;
    wire _3224;
    wire _3226;
    wire _3237;
    wire _3273;
    wire _3275;
    wire _3276;
    wire _3277;
    wire _3279;
    wire _32;
    wire _33;
    reg t1_waiting;
    wire [15:0] _3233;
    wire _3235;
    wire _3225;
    wire _3254;
    wire _3221;
    wire _3219;
    wire _3218;
    wire _3217;
    wire _3216;
    wire _3215;
    wire _3214;
    wire _3213;
    wire _3212;
    wire [2:0] _3211;
    reg _3220;
    wire _3222;
    wire _4223;
    wire _4222;
    wire _4224;
    wire _4225;
    wire [4:0] _3313;
    wire [5:0] _3310;
    wire [5:0] _3303;
    wire [5:0] _3311;
    wire _3312;
    wire [4:0] _3315;
    wire [4:0] _3300;
    wire _3294;
    wire [4:0] _3296;
    wire [4:0] _3297;
    wire _3285;
    wire [4:0] _3298;
    wire _3283;
    wire [4:0] _3301;
    wire _3281;
    wire [4:0] _3316;
    wire [4:0] _3317;
    wire [4:0] _3318;
    wire [4:0] _3319;
    wire [4:0] _3321;
    wire [4:0] _34;
    wire [4:0] _35;
    reg [4:0] t1_isr_count;
    wire _4218;
    wire [4:0] _3326;
    wire [6:0] _3323;
    wire _3324;
    wire _3322;
    wire _3325;
    wire [4:0] _3327;
    wire [4:0] _36;
    reg [4:0] cfg_t1_threshold;
    wire [4:0] _3349;
    wire [5:0] _3346;
    wire [5:0] _3345;
    wire [5:0] _3347;
    wire _3348;
    wire [4:0] _3351;
    wire [4:0] _3342;
    wire _3336;
    wire [4:0] _3338;
    wire [4:0] _3339;
    wire _3334;
    wire [4:0] _3340;
    wire _3333;
    wire [4:0] _3343;
    wire _3332;
    wire [4:0] _3352;
    wire [4:0] _3353;
    wire [4:0] _3354;
    wire [4:0] _3355;
    wire [4:0] _3356;
    wire [4:0] _37;
    wire [4:0] _38;
    reg [4:0] t1_osr_count;
    wire _4217;
    wire _4215;
    wire _4216;
    wire _4212;
    wire _4213;
    wire _4214;
    wire [15:0] _4197;
    wire _4195;
    wire [15:0] _4198;
    wire _4191;
    wire [15:0] _4192;
    wire [15:0] _3583;
    wire [15:0] _3552;
    wire [31:0] _3554;
    wire [23:0] _3548;
    wire [31:0] _3550;
    wire [27:0] _3544;
    wire [31:0] _3546;
    wire [29:0] _3540;
    wire [31:0] _3542;
    wire [30:0] _3536;
    wire [31:0] _3538;
    wire [31:0] _3535;
    wire _3533;
    wire [31:0] _3539;
    wire _3532;
    wire [31:0] _3543;
    wire _3531;
    wire [31:0] _3547;
    wire _3530;
    wire [31:0] _3551;
    wire _3529;
    wire [31:0] _3555;
    wire [15:0] _3556;
    wire [15:0] _3584;
    wire [15:0] _3525;
    wire [31:0] _3526;
    wire [23:0] _3521;
    wire [31:0] _3522;
    wire [27:0] _3517;
    wire [31:0] _3518;
    wire [29:0] _3513;
    wire [31:0] _3514;
    wire [30:0] _3509;
    wire [31:0] _3510;
    wire _3501;
    wire _3498;
    wire _3497;
    wire _3496;
    wire _3495;
    wire _3494;
    wire _3493;
    wire _3492;
    wire _3491;
    reg _3499;
    wire _3502;
    wire [4:0] _3488;
    wire _3489;
    wire _3486;
    wire _3485;
    wire _3484;
    wire _3483;
    wire _3482;
    wire _3481;
    wire _3480;
    wire _3479;
    wire [2:0] _3478;
    reg _3487;
    wire _3490;
    wire [4:0] _3474;
    wire _3475;
    wire _3472;
    wire _3471;
    wire _3470;
    wire _3469;
    wire _3468;
    wire _3467;
    wire _3466;
    wire _3465;
    wire [2:0] _3464;
    reg _3473;
    wire _3476;
    wire [4:0] _3460;
    wire _3461;
    wire _3458;
    wire _3457;
    wire _3456;
    wire _3455;
    wire _3454;
    wire _3453;
    wire _3452;
    wire _3451;
    wire [2:0] _3450;
    reg _3459;
    wire _3462;
    wire [4:0] _3446;
    wire _3447;
    wire _3444;
    wire _3443;
    wire _3442;
    wire _3441;
    wire _3440;
    wire _3439;
    wire _3438;
    wire _3437;
    wire [2:0] _3436;
    reg _3445;
    wire _3448;
    wire [4:0] _3432;
    wire _3433;
    wire _3430;
    wire _3429;
    wire _3428;
    wire _3427;
    wire _3426;
    wire _3425;
    wire _3424;
    wire _3423;
    wire [2:0] _3422;
    reg _3431;
    wire _3434;
    wire [4:0] _3418;
    wire _3419;
    wire _3416;
    wire _3415;
    wire _3414;
    wire _3413;
    wire _3412;
    wire _3411;
    wire _3410;
    wire _3409;
    wire [2:0] _3408;
    reg _3417;
    wire _3420;
    wire [4:0] _3404;
    wire _3405;
    wire _3402;
    wire _3401;
    wire _3400;
    wire _3399;
    wire _3398;
    wire _3397;
    wire _3396;
    wire _3395;
    wire [2:0] _3361;
    wire [6:0] _3358;
    wire _3359;
    wire _3357;
    wire _3360;
    wire [2:0] _3362;
    wire [2:0] _39;
    reg [2:0] cfg_t1_in_base;
    wire [2:0] _3394;
    reg _3403;
    wire _3406;
    wire [7:0] _3503;
    wire [15:0] _3504;
    wire [1:0] _3391;
    reg [15:0] _3506;
    wire [31:0] _3507;
    wire _3390;
    wire [31:0] _3511;
    wire _3389;
    wire [31:0] _3515;
    wire _3388;
    wire [31:0] _3519;
    wire _3387;
    wire [31:0] _3523;
    wire _3386;
    wire [31:0] _3527;
    wire [15:0] _3528;
    wire _251;
    wire [15:0] _3585;
    wire [15:0] _3384;
    wire _3366;
    wire [15:0] _3380;
    wire [15:0] _3381;
    wire _3365;
    wire [15:0] _3382;
    wire _3364;
    wire [15:0] _3385;
    wire _3363;
    wire [15:0] _3586;
    wire [15:0] _3587;
    wire [15:0] _3588;
    wire [15:0] _3589;
    wire [15:0] _3591;
    wire [15:0] _40;
    wire [15:0] _41;
    reg [15:0] t1_isr;
    wire [15:0] _3374;
    wire [15:0] _4169;
    wire _4167;
    wire [15:0] _4170;
    wire [15:0] _4158;
    wire [31:0] _4159;
    wire [23:0] _4154;
    wire [31:0] _4155;
    wire [27:0] _4150;
    wire [31:0] _4151;
    wire [29:0] _4146;
    wire [31:0] _4147;
    wire [30:0] _4142;
    wire [31:0] _4143;
    wire [31:0] _4140;
    wire _4138;
    wire [31:0] _4144;
    wire _4137;
    wire [31:0] _4148;
    wire _4136;
    wire [31:0] _4152;
    wire _4135;
    wire [31:0] _4156;
    wire [4:0] _4133;
    wire _4134;
    wire [31:0] _4160;
    wire [15:0] _4161;
    wire [15:0] _3577;
    wire [31:0] _3579;
    wire [23:0] _3573;
    wire [31:0] _3575;
    wire [27:0] _3569;
    wire [31:0] _3571;
    wire [29:0] _3565;
    wire [31:0] _3567;
    wire _3561;
    wire [31:0] _3564;
    wire _3560;
    wire [31:0] _3568;
    wire _3559;
    wire [31:0] _3572;
    wire _3558;
    wire [31:0] _3576;
    wire _3557;
    wire [31:0] _3580;
    wire [15:0] _3581;
    wire [15:0] _3582;
    wire [15:0] _4091;
    wire [31:0] _4093;
    wire [23:0] _4087;
    wire [31:0] _4089;
    wire [27:0] _4083;
    wire [31:0] _4085;
    wire [29:0] _4079;
    wire [31:0] _4081;
    wire [30:0] _4075;
    wire [31:0] _4077;
    wire [31:0] _4074;
    wire _4072;
    wire [31:0] _4078;
    wire _4071;
    wire [31:0] _4082;
    wire _4070;
    wire [31:0] _4086;
    wire _4069;
    wire [31:0] _4090;
    wire _4068;
    wire [31:0] _4094;
    wire [15:0] _4095;
    wire [15:0] _4064;
    wire [31:0] _4065;
    wire [23:0] _4060;
    wire [31:0] _4061;
    wire [27:0] _4056;
    wire [31:0] _4057;
    wire [29:0] _4052;
    wire [31:0] _4053;
    wire [30:0] _4048;
    wire [31:0] _4049;
    wire [31:0] _4046;
    wire _4044;
    wire [31:0] _4050;
    wire _4043;
    wire [31:0] _4054;
    wire _4042;
    wire [31:0] _4058;
    wire _4041;
    wire [31:0] _4062;
    wire [4:0] _3307;
    wire [3:0] _3304;
    wire _3306;
    wire [4:0] _3309;
    wire _4040;
    wire [31:0] _4066;
    wire [15:0] _4067;
    wire [15:0] _4096;
    wire _4033;
    wire _4034;
    reg [15:0] t1_tx_mem_15;
    wire _4027;
    wire _4028;
    reg [15:0] t1_tx_mem_14;
    wire _4021;
    wire _4022;
    reg [15:0] t1_tx_mem_13;
    wire _4015;
    wire _4016;
    reg [15:0] t1_tx_mem_12;
    wire _4009;
    wire _4010;
    reg [15:0] t1_tx_mem_11;
    wire _4003;
    wire _4004;
    reg [15:0] t1_tx_mem_10;
    wire _3997;
    wire _3998;
    reg [15:0] t1_tx_mem_9;
    wire _3991;
    wire _3992;
    reg [15:0] t1_tx_mem_8;
    wire _3985;
    wire _3986;
    reg [15:0] t1_tx_mem_7;
    wire _3979;
    wire _3980;
    reg [15:0] t1_tx_mem_6;
    wire _3973;
    wire _3974;
    reg [15:0] t1_tx_mem_5;
    wire _3967;
    wire _3968;
    reg [15:0] t1_tx_mem_4;
    wire _3961;
    wire _3962;
    reg [15:0] t1_tx_mem_3;
    wire _3955;
    wire _3956;
    reg [15:0] t1_tx_mem_2;
    wire _3949;
    wire _3950;
    reg [15:0] t1_tx_mem_1;
    wire [3:0] _3608;
    wire [3:0] _3609;
    wire [3:0] _42;
    reg [3:0] t1_tx_wr;
    wire _3943;
    wire _3944;
    wire _517;
    wire _518;
    reg [15:0] t0_rx_mem_15;
    wire _511;
    wire _512;
    reg [15:0] t0_rx_mem_14;
    wire _505;
    wire _506;
    reg [15:0] t0_rx_mem_13;
    wire _499;
    wire _500;
    reg [15:0] t0_rx_mem_12;
    wire _493;
    wire _494;
    reg [15:0] t0_rx_mem_11;
    wire _487;
    wire _488;
    reg [15:0] t0_rx_mem_10;
    wire _481;
    wire _482;
    reg [15:0] t0_rx_mem_9;
    wire _475;
    wire _476;
    reg [15:0] t0_rx_mem_8;
    wire _469;
    wire _470;
    reg [15:0] t0_rx_mem_7;
    wire _463;
    wire _464;
    reg [15:0] t0_rx_mem_6;
    wire _457;
    wire _458;
    reg [15:0] t0_rx_mem_5;
    wire _451;
    wire _452;
    reg [15:0] t0_rx_mem_4;
    wire _445;
    wire _446;
    reg [15:0] t0_rx_mem_3;
    wire _439;
    wire _440;
    reg [15:0] t0_rx_mem_2;
    wire _433;
    wire _434;
    reg [15:0] t0_rx_mem_1;
    wire [3:0] _3611;
    wire [3:0] _3612;
    wire [3:0] _43;
    reg [3:0] t0_rx_wr;
    wire _427;
    wire _428;
    wire [15:0] _3890;
    wire [31:0] _3892;
    wire [23:0] _3886;
    wire [31:0] _3888;
    wire [27:0] _3882;
    wire [31:0] _3884;
    wire [29:0] _3878;
    wire [31:0] _3880;
    wire _3874;
    wire [31:0] _3877;
    wire _3873;
    wire [31:0] _3881;
    wire _3872;
    wire [31:0] _3885;
    wire _3871;
    wire [31:0] _3889;
    wire _3870;
    wire [31:0] _3893;
    wire [15:0] _3894;
    wire [15:0] _3895;
    wire [15:0] _3896;
    wire [15:0] _3866;
    wire [31:0] _3867;
    wire [23:0] _3862;
    wire [31:0] _3863;
    wire [27:0] _3858;
    wire [31:0] _3859;
    wire [29:0] _3854;
    wire [31:0] _3855;
    wire [30:0] _3850;
    wire [31:0] _3851;
    wire [15:0] _3803;
    wire [15:0] _3798;
    wire [31:0] _3800;
    wire [23:0] _3794;
    wire [31:0] _3796;
    wire [27:0] _3790;
    wire [31:0] _3792;
    wire [29:0] _3786;
    wire [31:0] _3788;
    wire [30:0] _3782;
    wire [31:0] _3784;
    wire [31:0] _3781;
    wire _3779;
    wire [31:0] _3785;
    wire _3778;
    wire [31:0] _3789;
    wire _3777;
    wire [31:0] _3793;
    wire _3776;
    wire [31:0] _3797;
    wire _3775;
    wire [31:0] _3801;
    wire [15:0] _3802;
    wire [15:0] _3804;
    wire [15:0] _3771;
    wire [31:0] _3772;
    wire [23:0] _3767;
    wire [31:0] _3768;
    wire [27:0] _3763;
    wire [31:0] _3764;
    wire [29:0] _3759;
    wire [31:0] _3760;
    wire [30:0] _3755;
    wire [31:0] _3756;
    wire _3747;
    wire _3744;
    wire _3743;
    wire _3742;
    wire _3741;
    wire _3740;
    wire _3739;
    wire _3738;
    wire _3737;
    reg _3745;
    wire _3748;
    wire _3735;
    wire _3732;
    wire _3731;
    wire _3730;
    wire _3729;
    wire _3728;
    wire _3727;
    wire _3726;
    wire _3725;
    wire [2:0] _3724;
    reg _3733;
    wire _3736;
    wire _3721;
    wire _3718;
    wire _3717;
    wire _3716;
    wire _3715;
    wire _3714;
    wire _3713;
    wire _3712;
    wire _3711;
    wire [2:0] _3710;
    reg _3719;
    wire _3722;
    wire _3707;
    wire _3704;
    wire _3703;
    wire _3702;
    wire _3701;
    wire _3700;
    wire _3699;
    wire _3698;
    wire _3697;
    wire [2:0] _3696;
    reg _3705;
    wire _3708;
    wire _3693;
    wire _3690;
    wire _3689;
    wire _3688;
    wire _3687;
    wire _3686;
    wire _3685;
    wire _3684;
    wire _3683;
    wire [2:0] _3682;
    reg _3691;
    wire _3694;
    wire _3679;
    wire _3676;
    wire _3675;
    wire _3674;
    wire _3673;
    wire _3672;
    wire _3671;
    wire _3670;
    wire _3669;
    wire [2:0] _3668;
    reg _3677;
    wire _3680;
    wire _3665;
    wire _3662;
    wire _3661;
    wire _3660;
    wire _3659;
    wire _3658;
    wire _3657;
    wire _3656;
    wire _3655;
    wire [2:0] _3654;
    reg _3663;
    wire _3666;
    wire _3651;
    wire _3648;
    wire _3647;
    wire _3646;
    wire _3645;
    wire _3644;
    wire _3643;
    wire _3642;
    wire _3641;
    wire [2:0] _3617;
    wire [6:0] _3614;
    wire _3615;
    wire _3613;
    wire _3616;
    wire [2:0] _3618;
    wire [2:0] _44;
    reg [2:0] cfg_t0_in_base;
    wire [2:0] _3640;
    reg _3649;
    wire _3652;
    wire [7:0] _3749;
    wire [15:0] _3750;
    wire [1:0] _3637;
    reg [15:0] _3752;
    wire [31:0] _3753;
    wire _3636;
    wire [31:0] _3757;
    wire _3635;
    wire [31:0] _3761;
    wire _3634;
    wire [31:0] _3765;
    wire _3633;
    wire [31:0] _3769;
    wire _3632;
    wire [31:0] _3773;
    wire [15:0] _3774;
    wire [15:0] _3805;
    wire [15:0] _3629;
    wire _3624;
    wire [15:0] _3625;
    wire [15:0] _3626;
    wire _3622;
    wire [15:0] _3627;
    wire _3621;
    wire [15:0] _3630;
    wire _3620;
    wire [15:0] _3806;
    wire [15:0] _3807;
    wire [15:0] _3808;
    wire [15:0] _3809;
    wire [15:0] _3811;
    wire [15:0] _45;
    wire [15:0] _46;
    reg [15:0] t0_isr;
    wire [31:0] _3848;
    wire _3846;
    wire [31:0] _3852;
    wire _3845;
    wire [31:0] _3856;
    wire _3844;
    wire [31:0] _3860;
    wire _3843;
    wire [31:0] _3864;
    wire [4:0] _3831;
    wire [5:0] _3828;
    wire [5:0] _3827;
    wire [5:0] _3829;
    wire _3830;
    wire [4:0] _3833;
    wire [4:0] _3824;
    wire _3818;
    wire [4:0] _3820;
    wire [4:0] _3821;
    wire _3817;
    wire [4:0] _3822;
    wire _3816;
    wire [4:0] _3825;
    wire _3815;
    wire [4:0] _3834;
    wire [4:0] _3835;
    wire [4:0] _3836;
    wire [4:0] _3837;
    wire [4:0] _3839;
    wire [4:0] _47;
    wire [4:0] _48;
    reg [4:0] t0_isr_count;
    wire [4:0] _3841;
    wire _3842;
    wire [31:0] _3868;
    wire [15:0] _3869;
    wire _3631;
    wire [15:0] _3897;
    wire [15:0] _49;
    reg [15:0] t0_rx_mem_0;
    wire [3:0] _3916;
    wire _3913;
    wire _3908;
    wire _3905;
    wire _3906;
    wire [6:0] _3901;
    wire [6:0] _370;
    wire _3902;
    wire _3898;
    wire _3899;
    wire _3151;
    wire _3152;
    wire _3900;
    wire _3903;
    wire _3907;
    wire _50;
    wire _3909;
    wire _3910;
    wire _3914;
    wire [3:0] _3917;
    wire [3:0] _51;
    reg [3:0] t0_rx_rd;
    reg [15:0] _520;
    wire [15:0] _52;
    wire [15:0] _3939;
    reg [15:0] t1_tx_mem_0;
    wire [3:0] _3930;
    wire _3924;
    wire _3261;
    wire _3922;
    wire _3919;
    wire _3920;
    wire _3921;
    wire _3923;
    wire _53;
    wire _3925;
    wire [3:0] _3931;
    wire [3:0] _54;
    reg [3:0] t1_tx_rd;
    reg [15:0] _4036;
    wire _3181;
    wire [15:0] _4037;
    wire _3935;
    wire [15:0] _3936;
    wire [15:0] _3937;
    wire _3934;
    wire [15:0] _3938;
    wire _3933;
    wire [15:0] _4038;
    wire _3932;
    wire [15:0] _4097;
    wire [15:0] _4098;
    wire [15:0] _4099;
    wire [15:0] _4100;
    wire [15:0] _4102;
    wire [15:0] _55;
    wire [15:0] _56;
    reg [15:0] t1_osr;
    wire [15:0] _4131;
    wire [1:0] _4107;
    wire [6:0] _4104;
    wire _4105;
    wire _4103;
    wire _4106;
    wire [1:0] _4108;
    wire [1:0] _57;
    reg [1:0] cfg_t1_shift;
    wire _4039;
    wire [15:0] _4162;
    wire [1:0] _4128;
    wire _4130;
    wire [15:0] _4163;
    wire _4124;
    wire [15:0] _4125;
    wire [15:0] _4126;
    wire _4117;
    wire [15:0] _4121;
    wire _4114;
    wire [15:0] _4122;
    wire _4112;
    wire [15:0] _4127;
    wire _4111;
    wire [15:0] _4164;
    wire _4110;
    wire [15:0] _4171;
    wire [15:0] _4172;
    wire [15:0] _4173;
    wire [15:0] _4174;
    wire [15:0] _4176;
    wire [15:0] _58;
    wire [15:0] _59;
    reg [15:0] t1_y;
    reg [15:0] _3379;
    wire _4186;
    wire [15:0] _4187;
    wire [2:0] _3289;
    wire _3291;
    wire [2:0] _3286;
    wire _3288;
    wire _3292;
    wire [15:0] _4188;
    wire [4:0] _4119;
    wire [15:0] _4120;
    wire [1:0] _4115;
    wire _4182;
    wire [15:0] _4183;
    wire _4180;
    wire [15:0] _4184;
    wire _4179;
    wire [15:0] _4189;
    wire _4178;
    wire [15:0] _4193;
    wire _4177;
    wire [15:0] _4199;
    wire [15:0] _4200;
    wire [15:0] _4201;
    wire [15:0] _4202;
    wire [15:0] _4204;
    wire [15:0] _60;
    wire [15:0] _61;
    reg [15:0] t1_x;
    wire _4208;
    wire _4209;
    wire _4210;
    wire [2:0] _4165;
    reg _4219;
    wire _4206;
    wire _4220;
    wire _4226;
    wire [7:0] _4235;
    wire [7:0] _4236;
    wire [7:0] _4237;
    wire [7:0] _4238;
    wire [7:0] _4239;
    wire [7:0] _62;
    wire [7:0] _63;
    reg [7:0] t1_pc;
    reg [15:0] _3176;
    wire [2:0] _3177;
    wire _3251;
    wire _3253;
    wire _3256;
    wire _3263;
    wire _3269;
    wire _3270;
    wire _3174;
    wire _3169;
    wire _3175;
    wire _3271;
    wire [3:0] _4252;
    wire [3:0] _4255;
    wire [3:0] _4256;
    wire [3:0] _4258;
    wire [3:0] _64;
    wire [3:0] _65;
    reg [3:0] t1_delay_left;
    wire _3207;
    wire _3208;
    wire [7:0] _4830;
    wire [15:0] _4270;
    wire [6:0] _4260;
    wire _4261;
    wire _4259;
    wire _4262;
    wire [15:0] _4263;
    wire [15:0] _66;
    reg [15:0] cfg_t1_clkdiv;
    wire _4268;
    wire [15:0] _4272;
    wire [15:0] _4266;
    wire [15:0] _4273;
    wire _4264;
    wire [15:0] _4275;
    wire [15:0] _67;
    reg [15:0] t1_div_count;
    wire _3168;
    wire _3205;
    wire [7:0] _4831;
    wire _3163;
    wire _3204;
    wire [7:0] _4832;
    wire [7:0] _68;
    wire [7:0] _69;
    reg [7:0] pin_out;
    wire _2314;
    wire [7:0] _2310;
    reg [7:0] pins_sync1;
    reg [7:0] pins_sync2;
    wire [7:0] _2311;
    wire [7:0] _4837;
    wire [6:0] _4834;
    wire _4835;
    wire _4833;
    wire _4836;
    wire [7:0] _4838;
    wire [7:0] _70;
    reg [7:0] cfg_sync_bypass;
    wire [7:0] _72;
    wire [7:0] _2304;
    wire [7:0] _2312;
    wire _2313;
    wire [6:0] _4840;
    wire _4841;
    wire _4839;
    wire _4842;
    wire [15:0] _4843;
    wire [15:0] _73;
    reg [15:0] cfg_pin_modes;
    wire [1:0] _2303;
    reg _2316;
    wire [7:0] _2352;
    wire [15:0] _2676;
    wire [15:0] _5077;
    wire _5075;
    wire [15:0] _5078;
    wire [15:0] _2862;
    wire [31:0] _2863;
    wire [23:0] _2858;
    wire [31:0] _2859;
    wire [27:0] _2854;
    wire [31:0] _2855;
    wire [29:0] _2850;
    wire [31:0] _2851;
    wire [30:0] _2846;
    wire [31:0] _2847;
    wire [31:0] _2844;
    wire _2842;
    wire [31:0] _2848;
    wire _2841;
    wire [31:0] _2852;
    wire _2840;
    wire [31:0] _2856;
    wire _2839;
    wire [31:0] _2860;
    wire [4:0] _2837;
    wire _2838;
    wire [31:0] _2864;
    wire [15:0] _2865;
    wire [15:0] _2829;
    wire [31:0] _2831;
    wire [23:0] _2825;
    wire [31:0] _2827;
    wire [27:0] _2821;
    wire [31:0] _2823;
    wire [29:0] _2817;
    wire [31:0] _2819;
    wire _2813;
    wire [31:0] _2816;
    wire _2812;
    wire [31:0] _2820;
    wire _2811;
    wire [31:0] _2824;
    wire _2810;
    wire [31:0] _2828;
    wire _2809;
    wire [31:0] _2832;
    wire [15:0] _2833;
    wire [15:0] _2834;
    wire [15:0] _5035;
    wire [31:0] _5037;
    wire [23:0] _5031;
    wire [31:0] _5033;
    wire [27:0] _5027;
    wire [31:0] _5029;
    wire [29:0] _5023;
    wire [31:0] _5025;
    wire [30:0] _5019;
    wire [31:0] _5021;
    wire [31:0] _5018;
    wire _5016;
    wire [31:0] _5022;
    wire _5015;
    wire [31:0] _5026;
    wire _5014;
    wire [31:0] _5030;
    wire _5013;
    wire [31:0] _5034;
    wire _5012;
    wire [31:0] _5038;
    wire [15:0] _5039;
    wire [15:0] _5008;
    wire [31:0] _5009;
    wire [23:0] _5004;
    wire [31:0] _5005;
    wire [27:0] _5000;
    wire [31:0] _5001;
    wire [29:0] _4996;
    wire [31:0] _4997;
    wire [30:0] _4992;
    wire [31:0] _4993;
    wire [31:0] _4990;
    wire _4988;
    wire [31:0] _4994;
    wire _4987;
    wire [31:0] _4998;
    wire _4986;
    wire [31:0] _5002;
    wire _4985;
    wire [31:0] _5006;
    wire [4:0] _2462;
    wire [3:0] _2459;
    wire _2461;
    wire [4:0] _2464;
    wire _4984;
    wire [31:0] _5010;
    wire [15:0] _5011;
    wire [15:0] _5040;
    wire _4978;
    wire _4979;
    reg [15:0] t0_tx_mem_15;
    wire _4972;
    wire _4973;
    reg [15:0] t0_tx_mem_14;
    wire _4966;
    wire _4967;
    reg [15:0] t0_tx_mem_13;
    wire _4960;
    wire _4961;
    reg [15:0] t0_tx_mem_12;
    wire _4954;
    wire _4955;
    reg [15:0] t0_tx_mem_11;
    wire _4948;
    wire _4949;
    reg [15:0] t0_tx_mem_10;
    wire _4942;
    wire _4943;
    reg [15:0] t0_tx_mem_9;
    wire _4936;
    wire _4937;
    reg [15:0] t0_tx_mem_8;
    wire _4930;
    wire _4931;
    reg [15:0] t0_tx_mem_7;
    wire _4924;
    wire _4925;
    reg [15:0] t0_tx_mem_6;
    wire _4918;
    wire _4919;
    reg [15:0] t0_tx_mem_5;
    wire _4912;
    wire _4913;
    reg [15:0] t0_tx_mem_4;
    wire _4906;
    wire _4907;
    reg [15:0] t0_tx_mem_3;
    wire _4900;
    wire _4901;
    reg [15:0] t0_tx_mem_2;
    wire _4894;
    wire _4895;
    reg [15:0] t0_tx_mem_1;
    wire [3:0] _4856;
    wire [3:0] _4857;
    wire [3:0] _74;
    reg [3:0] t0_tx_wr;
    wire _4888;
    wire _4889;
    reg [15:0] t0_tx_mem_0;
    wire [3:0] _4876;
    wire _4862;
    wire [4:0] _4864;
    wire _4849;
    wire _4850;
    wire [6:0] _4845;
    wire _4846;
    wire _4844;
    wire _4847;
    wire _4851;
    wire [4:0] _4859;
    wire [4:0] _4860;
    wire [4:0] _4865;
    wire [4:0] _75;
    reg [4:0] t0_tx_level;
    wire _2407;
    wire _4870;
    wire _4867;
    wire _4868;
    wire _4869;
    wire _4871;
    wire _76;
    wire _4863;
    wire [3:0] _4877;
    wire [3:0] _77;
    reg [3:0] t0_tx_rd;
    reg [15:0] _4981;
    wire _2404;
    wire [15:0] _4982;
    wire _4881;
    wire [15:0] _4882;
    wire [15:0] _4883;
    wire _4880;
    wire [15:0] _4884;
    wire _4879;
    wire [15:0] _4983;
    wire _4878;
    wire [15:0] _5041;
    wire [15:0] _5042;
    wire [15:0] _5043;
    wire [15:0] _5044;
    wire [15:0] _5046;
    wire [15:0] _78;
    wire [15:0] _79;
    reg [15:0] t0_osr;
    wire [15:0] _2835;
    wire [1:0] _5051;
    wire [6:0] _5048;
    wire _5049;
    wire _5047;
    wire _5050;
    wire [1:0] _5052;
    wire [1:0] _80;
    reg [1:0] cfg_t0_shift;
    wire _2808;
    wire [15:0] _2866;
    wire [1:0] _5068;
    wire _5070;
    wire [15:0] _5071;
    wire _5064;
    wire [15:0] _5065;
    wire [15:0] _5066;
    wire _5060;
    wire [15:0] _5061;
    wire _5058;
    wire [15:0] _5062;
    wire _5056;
    wire [15:0] _5067;
    wire _5055;
    wire [15:0] _5072;
    wire _5054;
    wire [15:0] _5079;
    wire [15:0] _5080;
    wire [15:0] _5081;
    wire [15:0] _5082;
    wire [15:0] _5084;
    wire [15:0] _81;
    wire [15:0] _82;
    reg [15:0] t0_y;
    reg [15:0] _2684;
    wire _5094;
    wire [15:0] _5095;
    wire [2:0] _2444;
    wire _2446;
    wire [2:0] _2441;
    wire _2443;
    wire _2447;
    wire [15:0] _5096;
    wire [4:0] _2543;
    wire [15:0] _2544;
    wire [1:0] _2531;
    wire _5090;
    wire [15:0] _5091;
    wire _5088;
    wire [15:0] _5092;
    wire _5087;
    wire [15:0] _5097;
    wire _5086;
    wire [15:0] _5101;
    wire _5085;
    wire [15:0] _5107;
    wire [15:0] _5108;
    wire [15:0] _5109;
    wire [15:0] _5110;
    wire [15:0] _5112;
    wire [15:0] _83;
    wire [15:0] _84;
    reg [15:0] t0_x;
    wire _5116;
    wire _5117;
    wire _5118;
    wire [2:0] _5073;
    reg _5127;
    wire _5114;
    wire _5128;
    wire _5134;
    wire [7:0] _5143;
    wire [7:0] _5144;
    wire [7:0] _5145;
    wire [7:0] _5146;
    wire [7:0] _5147;
    wire [7:0] _85;
    wire [7:0] _86;
    reg [7:0] t0_pc;
    reg [15:0] _2298;
    wire [2:0] _2299;
    wire _2396;
    wire _2398;
    wire _2401;
    wire _2409;
    wire _2415;
    wire _2416;
    wire _2417;
    wire [3:0] _5158;
    wire _753;
    wire _754;
    wire [3:0] _5161;
    wire _748;
    wire [3:0] _5162;
    wire _742;
    wire [3:0] _5164;
    wire [3:0] _87;
    wire [3:0] _88;
    reg [3:0] t0_delay_left;
    wire _2393;
    wire [15:0] _5176;
    wire [6:0] _5166;
    wire _5167;
    wire _5165;
    wire _5168;
    wire [15:0] _5169;
    wire [15:0] _89;
    reg [15:0] cfg_t0_clkdiv;
    wire _5174;
    wire [15:0] _5178;
    wire [15:0] _5172;
    wire [15:0] _5179;
    wire _5170;
    wire [15:0] _5181;
    wire [15:0] _90;
    reg [15:0] t0_div_count;
    wire _747;
    wire _741;
    wire _2391;
    wire _2394;
    wire _5184;
    wire _5186;
    wire _5188;
    wire _91;
    wire _422;
    wire [4:0] _5190;
    wire [4:0] _5191;
    wire [4:0] _5194;
    wire [4:0] _92;
    reg [4:0] t0_rx_level;
    wire _3912;
    wire _5215;
    wire [15:0] _732;
    wire [4:0] _5213;
    wire [6:0] _728;
    wire _5211;
    wire _363;
    reg host_mosi_s1;
    reg host_mosi_s2;
    wire [22:0] _361;
    wire [22:0] _5195;
    wire [22:0] _5196;
    wire [22:0] _5197;
    wire [22:0] _93;
    reg [22:0] host_shift_in;
    wire [23:0] _368;
    wire [7:0] _369;
    wire _359;
    wire [7:0] _5198;
    wire [7:0] _5199;
    wire [7:0] _5200;
    wire [7:0] _94;
    reg [7:0] host_cmd;
    wire _726;
    wire [4:0] _720;
    wire [4:0] _5204;
    wire [4:0] _5201;
    wire _5202;
    wire [4:0] _5205;
    wire [4:0] _5206;
    wire [4:0] _5208;
    wire [4:0] _95;
    reg [4:0] host_bit_count;
    wire _721;
    wire _326;
    reg host_cs_n_s1;
    reg host_cs_n_s2;
    wire _353;
    reg host_sck_prev;
    wire _351;
    wire vdd;
    wire _97;
    wire _99;
    wire [7:0] _101;
    wire _331;
    reg host_sck_s1;
    reg host_sck_s2;
    wire _352;
    wire _354;
    wire _722;
    wire _5209;
    wire _5212;
    wire [4:0] _5214;
    wire [4:0] _102;
    reg [4:0] cfg_ctrl;
    wire _3596;
    wire _5216;
    wire _5218;
    wire _103;
    wire _3599;
    wire _3603;
    wire [4:0] _5220;
    wire [4:0] _5221;
    wire [4:0] _5224;
    wire [4:0] _104;
    reg [4:0] t1_tx_level;
    wire _5226;
    wire gnd;
    wire [7:0] _5238;
    assign _189 = pin_out[0:0];
    assign _190 = ~ _189;
    assign _187 = 2'b10;
    assign _186 = cfg_pin_modes[1:0];
    assign _188 = _186 == _187;
    assign _191 = _188 & _190;
    assign _184 = 2'b01;
    assign _183 = cfg_pin_modes[1:0];
    assign _185 = _183 == _184;
    assign _192 = _185 | _191;
    assign _179 = pin_out[1:1];
    assign _180 = ~ _179;
    assign _176 = cfg_pin_modes[3:2];
    assign _178 = _176 == _187;
    assign _181 = _178 & _180;
    assign _173 = cfg_pin_modes[3:2];
    assign _175 = _173 == _184;
    assign _182 = _175 | _181;
    assign _169 = pin_out[2:2];
    assign _170 = ~ _169;
    assign _166 = cfg_pin_modes[5:4];
    assign _168 = _166 == _187;
    assign _171 = _168 & _170;
    assign _163 = cfg_pin_modes[5:4];
    assign _165 = _163 == _184;
    assign _172 = _165 | _171;
    assign _159 = pin_out[3:3];
    assign _160 = ~ _159;
    assign _156 = cfg_pin_modes[7:6];
    assign _158 = _156 == _187;
    assign _161 = _158 & _160;
    assign _153 = cfg_pin_modes[7:6];
    assign _155 = _153 == _184;
    assign _162 = _155 | _161;
    assign _149 = pin_out[4:4];
    assign _150 = ~ _149;
    assign _146 = cfg_pin_modes[9:8];
    assign _148 = _146 == _187;
    assign _151 = _148 & _150;
    assign _143 = cfg_pin_modes[9:8];
    assign _145 = _143 == _184;
    assign _152 = _145 | _151;
    assign _139 = pin_out[5:5];
    assign _140 = ~ _139;
    assign _136 = cfg_pin_modes[11:10];
    assign _138 = _136 == _187;
    assign _141 = _138 & _140;
    assign _133 = cfg_pin_modes[11:10];
    assign _135 = _133 == _184;
    assign _142 = _135 | _141;
    assign _129 = pin_out[6:6];
    assign _130 = ~ _129;
    assign _126 = cfg_pin_modes[13:12];
    assign _128 = _126 == _187;
    assign _131 = _128 & _130;
    assign _123 = cfg_pin_modes[13:12];
    assign _125 = _123 == _184;
    assign _132 = _125 | _131;
    assign _119 = pin_out[7:7];
    assign _120 = ~ _119;
    assign _113 = cfg_pin_modes[15:14];
    assign _115 = _113 == _187;
    assign _121 = _115 & _120;
    assign _110 = cfg_pin_modes[15:14];
    assign _112 = _110 == _184;
    assign _122 = _112 | _121;
    assign _193 = { _122,
                    _132,
                    _142,
                    _152,
                    _162,
                    _172,
                    _182,
                    _192 };
    assign _232 = pin_out[0:0];
    assign _229 = cfg_pin_modes[1:0];
    assign _231 = _229 == _184;
    assign _233 = _231 & _232;
    assign _227 = pin_out[1:1];
    assign _224 = cfg_pin_modes[3:2];
    assign _226 = _224 == _184;
    assign _228 = _226 & _227;
    assign _222 = pin_out[2:2];
    assign _219 = cfg_pin_modes[5:4];
    assign _221 = _219 == _184;
    assign _223 = _221 & _222;
    assign _217 = pin_out[3:3];
    assign _214 = cfg_pin_modes[7:6];
    assign _216 = _214 == _184;
    assign _218 = _216 & _217;
    assign _212 = pin_out[4:4];
    assign _209 = cfg_pin_modes[9:8];
    assign _211 = _209 == _184;
    assign _213 = _211 & _212;
    assign _207 = pin_out[5:5];
    assign _204 = cfg_pin_modes[11:10];
    assign _206 = _204 == _184;
    assign _208 = _206 & _207;
    assign _202 = pin_out[6:6];
    assign _199 = cfg_pin_modes[13:12];
    assign _201 = _199 == _184;
    assign _203 = _201 & _202;
    assign _197 = pin_out[7:7];
    assign _194 = cfg_pin_modes[15:14];
    assign _196 = _194 == _184;
    assign _198 = _196 & _197;
    assign _234 = { _198,
                    _203,
                    _208,
                    _213,
                    _218,
                    _223,
                    _228,
                    _233 };
    assign _356 = 16'b0000000000000000;
    assign _716 = 1'b0;
    assign _715 = host_miso_shift[14:0];
    assign _717 = { _715,
                    _716 };
    assign _710 = 14'b00000000000000;
    assign _711 = { _710,
                    cfg_t1_shift };
    assign _702 = 10'b0000000000;
    assign _706 = { _702,
                    cfg_t1_sideset };
    assign _696 = cfg_ctrl[1:1];
    assign _695 = 15'b000000000000000;
    assign _697 = { _695,
                    _696 };
    assign _693 = { t1_pc,
                    t1_rx_level,
                    t1_tx_level };
    assign _694 = _693[15:0];
    assign _698 = _694 ^ _697;
    assign _681 = 4'b1111;
    assign _682 = t1_rx_wr == _681;
    assign _683 = _241 & _682;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_15 <= _356;
        else
            if (_683)
                t1_rx_mem_15 <= _4;
    end
    assign _675 = 4'b1110;
    assign _676 = t1_rx_wr == _675;
    assign _677 = _241 & _676;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_14 <= _356;
        else
            if (_677)
                t1_rx_mem_14 <= _4;
    end
    assign _669 = 4'b1101;
    assign _670 = t1_rx_wr == _669;
    assign _671 = _241 & _670;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_13 <= _356;
        else
            if (_671)
                t1_rx_mem_13 <= _4;
    end
    assign _663 = 4'b1100;
    assign _664 = t1_rx_wr == _663;
    assign _665 = _241 & _664;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_12 <= _356;
        else
            if (_665)
                t1_rx_mem_12 <= _4;
    end
    assign _657 = 4'b1011;
    assign _658 = t1_rx_wr == _657;
    assign _659 = _241 & _658;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_11 <= _356;
        else
            if (_659)
                t1_rx_mem_11 <= _4;
    end
    assign _651 = 4'b1010;
    assign _652 = t1_rx_wr == _651;
    assign _653 = _241 & _652;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_10 <= _356;
        else
            if (_653)
                t1_rx_mem_10 <= _4;
    end
    assign _645 = 4'b1001;
    assign _646 = t1_rx_wr == _645;
    assign _647 = _241 & _646;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_9 <= _356;
        else
            if (_647)
                t1_rx_mem_9 <= _4;
    end
    assign _639 = 4'b1000;
    assign _640 = t1_rx_wr == _639;
    assign _641 = _241 & _640;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_8 <= _356;
        else
            if (_641)
                t1_rx_mem_8 <= _4;
    end
    assign _633 = 4'b0111;
    assign _634 = t1_rx_wr == _633;
    assign _635 = _241 & _634;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_7 <= _356;
        else
            if (_635)
                t1_rx_mem_7 <= _4;
    end
    assign _627 = 4'b0110;
    assign _628 = t1_rx_wr == _627;
    assign _629 = _241 & _628;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_6 <= _356;
        else
            if (_629)
                t1_rx_mem_6 <= _4;
    end
    assign _621 = 4'b0101;
    assign _622 = t1_rx_wr == _621;
    assign _623 = _241 & _622;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_5 <= _356;
        else
            if (_623)
                t1_rx_mem_5 <= _4;
    end
    assign _615 = 4'b0100;
    assign _616 = t1_rx_wr == _615;
    assign _617 = _241 & _616;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_4 <= _356;
        else
            if (_617)
                t1_rx_mem_4 <= _4;
    end
    assign _609 = 4'b0011;
    assign _610 = t1_rx_wr == _609;
    assign _611 = _241 & _610;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_3 <= _356;
        else
            if (_611)
                t1_rx_mem_3 <= _4;
    end
    assign _603 = 4'b0010;
    assign _604 = t1_rx_wr == _603;
    assign _605 = _241 & _604;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_2 <= _356;
        else
            if (_605)
                t1_rx_mem_2 <= _4;
    end
    assign _597 = 4'b0001;
    assign _598 = t1_rx_wr == _597;
    assign _599 = _241 & _598;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_1 <= _356;
        else
            if (_599)
                t1_rx_mem_1 <= _4;
    end
    assign _591 = 4'b0000;
    assign _246 = t1_rx_wr + _597;
    assign _247 = _241 ? _246 : t1_rx_wr;
    assign _3 = _247;
    always @(posedge _99) begin
        if (_97)
            t1_rx_wr <= _591;
        else
            t1_rx_wr <= _3;
    end
    assign _592 = t1_rx_wr == _591;
    assign _593 = _241 & _592;
    assign _308 = _307[15:0];
    assign _310 = { _308,
                    _356 };
    assign _305 = 8'b00000000;
    assign _304 = _303[23:0];
    assign _306 = { _304,
                    _305 };
    assign _300 = _299[27:0];
    assign _302 = { _300,
                    _591 };
    assign _297 = 2'b00;
    assign _296 = _295[29:0];
    assign _298 = { _296,
                    _297 };
    assign _294 = 32'b11111111111111111111111111111110;
    assign _293 = 32'b11111111111111111111111111111111;
    assign _292 = t1_isr_count[0:0];
    assign _295 = _292 ? _294 : _293;
    assign _291 = t1_isr_count[1:1];
    assign _299 = _291 ? _298 : _295;
    assign _290 = t1_isr_count[2:2];
    assign _303 = _290 ? _302 : _299;
    assign _289 = t1_isr_count[3:3];
    assign _307 = _289 ? _306 : _303;
    assign _288 = t1_isr_count[4:4];
    assign _311 = _288 ? _310 : _307;
    assign _312 = _311[15:0];
    assign _313 = ~ _312;
    assign _314 = t1_isr & _313;
    assign _284 = _282[31:16];
    assign _285 = { _356,
                    _284 };
    assign _280 = _278[31:8];
    assign _281 = { _305,
                    _280 };
    assign _276 = _274[31:4];
    assign _277 = { _591,
                    _276 };
    assign _272 = _270[31:2];
    assign _273 = { _297,
                    _272 };
    assign _268 = _266[31:1];
    assign _269 = { _716,
                    _268 };
    assign _266 = { _356,
                    t1_isr };
    assign _261 = _256[0:0];
    assign _270 = _261 ? _269 : _266;
    assign _260 = _256[1:1];
    assign _274 = _260 ? _273 : _270;
    assign _259 = _256[2:2];
    assign _278 = _259 ? _277 : _274;
    assign _258 = _256[3:3];
    assign _282 = _258 ? _281 : _278;
    assign _252 = 5'b10000;
    assign _256 = _252 - t1_isr_count;
    assign _257 = _256[4:4];
    assign _286 = _257 ? _285 : _282;
    assign _287 = _286[15:0];
    assign _315 = _251 ? _314 : _287;
    assign _4 = _315;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_0 <= _356;
        else
            if (_593)
                t1_rx_mem_0 <= _4;
    end
    assign _324 = t1_rx_rd + _597;
    assign _325 = _319 ? _324 : t1_rx_rd;
    assign _5 = _325;
    always @(posedge _99) begin
        if (_97)
            t1_rx_rd <= _591;
        else
            t1_rx_rd <= _5;
    end
    always @* begin
        case (t1_rx_rd)
        0:
            _685 <= t1_rx_mem_0;
        1:
            _685 <= t1_rx_mem_1;
        2:
            _685 <= t1_rx_mem_2;
        3:
            _685 <= t1_rx_mem_3;
        4:
            _685 <= t1_rx_mem_4;
        5:
            _685 <= t1_rx_mem_5;
        6:
            _685 <= t1_rx_mem_6;
        7:
            _685 <= t1_rx_mem_7;
        8:
            _685 <= t1_rx_mem_8;
        9:
            _685 <= t1_rx_mem_9;
        10:
            _685 <= t1_rx_mem_10;
        11:
            _685 <= t1_rx_mem_11;
        12:
            _685 <= t1_rx_mem_12;
        13:
            _685 <= t1_rx_mem_13;
        14:
            _685 <= t1_rx_mem_14;
        default:
            _685 <= t1_rx_mem_15;
        endcase
    end
    assign _585 = 5'b00000;
    assign _586 = t1_rx_level == _585;
    assign _587 = ~ _586;
    assign _686 = _587 ? _685 : _356;
    assign _584 = { _305,
                    cfg_t1_timeout_vector };
    assign _575 = 11'b00000000000;
    assign _579 = { _575,
                    cfg_t1_threshold };
    assign _570 = 13'b0000000000000;
    assign _574 = { _570,
                    cfg_t1_in_base };
    assign _569 = { _305,
                    cfg_t1_set_cfg };
    assign _564 = { _305,
                    cfg_t1_out_cfg };
    assign _559 = { _305,
                    cfg_t1_start };
    assign _554 = { _710,
                    cfg_t0_shift };
    assign _549 = { _305,
                    cfg_sync_bypass };
    assign _541 = { _702,
                    cfg_t0_sideset };
    assign _531 = cfg_ctrl[0:0];
    assign _532 = { _695,
                    _531 };
    assign _528 = { t0_pc,
                    t0_rx_level,
                    t0_tx_level };
    assign _529 = _528[15:0];
    assign _533 = _529 ^ _532;
    assign _411 = t0_rx_level == _585;
    assign _412 = ~ _411;
    assign _521 = _412 ? _520 : _356;
    assign _406 = { _305,
                    cfg_t0_timeout_vector };
    assign _401 = { _575,
                    cfg_t0_threshold };
    assign _396 = { _570,
                    cfg_t0_in_base };
    assign _391 = { _305,
                    cfg_t0_set_cfg };
    assign _386 = { _305,
                    cfg_t0_out_cfg };
    assign _381 = { _305,
                    cfg_t0_start };
    assign _376 = { _575,
                    cfg_ctrl };
    always @* begin
        case (_370)
        0:
            _712 <= _356;
        1:
            _712 <= _356;
        2:
            _712 <= _356;
        3:
            _712 <= _356;
        4:
            _712 <= _356;
        5:
            _712 <= _356;
        6:
            _712 <= _356;
        7:
            _712 <= _356;
        8:
            _712 <= _356;
        9:
            _712 <= _356;
        10:
            _712 <= _356;
        11:
            _712 <= _356;
        12:
            _712 <= _356;
        13:
            _712 <= _356;
        14:
            _712 <= _356;
        15:
            _712 <= _356;
        16:
            _712 <= _356;
        17:
            _712 <= _356;
        18:
            _712 <= _356;
        19:
            _712 <= _356;
        20:
            _712 <= _356;
        21:
            _712 <= _356;
        22:
            _712 <= _356;
        23:
            _712 <= _356;
        24:
            _712 <= _356;
        25:
            _712 <= _356;
        26:
            _712 <= _356;
        27:
            _712 <= _356;
        28:
            _712 <= _356;
        29:
            _712 <= _356;
        30:
            _712 <= _356;
        31:
            _712 <= _356;
        32:
            _712 <= _356;
        33:
            _712 <= _356;
        34:
            _712 <= _356;
        35:
            _712 <= _356;
        36:
            _712 <= _356;
        37:
            _712 <= _356;
        38:
            _712 <= _356;
        39:
            _712 <= _356;
        40:
            _712 <= _356;
        41:
            _712 <= _356;
        42:
            _712 <= _356;
        43:
            _712 <= _356;
        44:
            _712 <= _356;
        45:
            _712 <= _356;
        46:
            _712 <= _356;
        47:
            _712 <= _356;
        48:
            _712 <= _356;
        49:
            _712 <= _356;
        50:
            _712 <= _356;
        51:
            _712 <= _356;
        52:
            _712 <= _356;
        53:
            _712 <= _356;
        54:
            _712 <= _356;
        55:
            _712 <= _356;
        56:
            _712 <= _356;
        57:
            _712 <= _356;
        58:
            _712 <= _356;
        59:
            _712 <= _356;
        60:
            _712 <= _356;
        61:
            _712 <= _356;
        62:
            _712 <= _356;
        63:
            _712 <= _356;
        64:
            _712 <= _376;
        65:
            _712 <= _381;
        66:
            _712 <= _386;
        67:
            _712 <= _391;
        68:
            _712 <= _396;
        69:
            _712 <= _401;
        70:
            _712 <= _406;
        71:
            _712 <= cfg_pin_modes;
        72:
            _712 <= _356;
        73:
            _712 <= _521;
        74:
            _712 <= _533;
        75:
            _712 <= cfg_t0_timeout;
        76:
            _712 <= _541;
        77:
            _712 <= cfg_t0_clkdiv;
        78:
            _712 <= _549;
        79:
            _712 <= _554;
        80:
            _712 <= _356;
        81:
            _712 <= _559;
        82:
            _712 <= _564;
        83:
            _712 <= _569;
        84:
            _712 <= _574;
        85:
            _712 <= _579;
        86:
            _712 <= _584;
        87:
            _712 <= _356;
        88:
            _712 <= _356;
        89:
            _712 <= _686;
        90:
            _712 <= _698;
        91:
            _712 <= cfg_t1_timeout;
        92:
            _712 <= _706;
        93:
            _712 <= cfg_t1_clkdiv;
        94:
            _712 <= _356;
        95:
            _712 <= _711;
        default:
            _712 <= _356;
        endcase
    end
    assign _713 = _359 ? _712 : host_miso_shift;
    assign _714 = _354 ? _713 : host_miso_shift;
    assign _347 = 5'b01001;
    assign _348 = host_bit_count < _347;
    assign _349 = ~ _348;
    assign _342 = ~ host_cs_n_s2;
    assign _337 = ~ host_sck_s2;
    assign _341 = _337 & host_sck_prev;
    assign _343 = _341 & _342;
    assign _350 = _343 & _349;
    assign _718 = _350 ? _717 : _714;
    assign _719 = host_cs_n_s2 ? host_miso_shift : _718;
    assign _6 = _719;
    always @(posedge _99) begin
        if (_97)
            host_miso_shift <= _356;
        else
            host_miso_shift <= _6;
    end
    assign _5237 = host_miso_shift[15:15];
    assign _5236 = cfg_ctrl[0:0];
    assign _5234 = t0_rx_level == _585;
    assign _5235 = ~ _5234;
    assign _5232 = t0_tx_level == _252;
    assign _5230 = cfg_ctrl[1:1];
    assign _5228 = t1_rx_level == _585;
    assign _5229 = ~ _5228;
    assign _5223 = { _591,
                     _3925 };
    assign _3602 = ~ _3601;
    assign _3597 = ~ _3596;
    assign _3593 = 7'b1011000;
    assign _3594 = _728 == _3593;
    assign _3592 = _722 & _726;
    assign _3595 = _3592 & _3594;
    assign _3598 = _3595 & _3597;
    assign _3601 = t1_tx_level == _252;
    assign _5217 = ~ _3601;
    assign _5193 = { _591,
                     _3914 };
    assign _421 = ~ _420;
    assign _5187 = ~ _420;
    assign _5185 = ~ _2404;
    assign _5182 = 3'b100;
    assign _5183 = _2299 == _5182;
    assign _5160 = t0_delay_left - _597;
    assign _5154 = _5152[3:2];
    assign _5155 = { _297,
                     _5154 };
    assign _5149 = _2511[0:0];
    assign _5152 = _5149 ? _633 : _681;
    assign _5148 = _2511[1:1];
    assign _5156 = _5148 ? _5155 : _5152;
    assign _5157 = _2999 & _5156;
    assign _420 = t0_rx_level == _252;
    assign _2412 = ~ _2404;
    assign _2411 = _2299 == _5182;
    assign _2413 = _2411 & _2412;
    assign _2414 = _2413 & _420;
    assign _2403 = _2299 == _5182;
    assign _2405 = _2403 & _2404;
    assign _2408 = _2405 & _2407;
    assign _2400 = ~ _2399;
    assign _2397 = ~ _2363;
    assign _2395 = 3'b001;
    assign _733 = _732[7:0];
    assign _729 = 7'b1000001;
    assign _730 = _728 == _729;
    assign _727 = _722 & _726;
    assign _731 = _727 & _730;
    assign _734 = _731 ? _733 : cfg_t0_start;
    assign _7 = _734;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_start <= _305;
        else
            cfg_t0_start <= _7;
    end
    assign _5140 = _2298[5:0];
    assign _5139 = t0_pc[7:6];
    assign _5141 = { _5139,
                     _5140 };
    assign _739 = _732[7:0];
    assign _736 = 7'b1000110;
    assign _737 = _728 == _736;
    assign _735 = _722 & _726;
    assign _738 = _735 & _737;
    assign _740 = _738 ? _739 : cfg_t0_timeout_vector;
    assign _8 = _740;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_timeout_vector <= _305;
        else
            cfg_t0_timeout_vector <= _8;
    end
    assign _5137 = 3'b000;
    assign _5138 = _2299 == _5137;
    assign _5142 = _5138 ? _5141 : cfg_t0_timeout_vector;
    assign _5135 = 8'b00000001;
    assign _5136 = t0_pc + _5135;
    assign _2379 = 16'b0000000000000001;
    assign _2380 = _2374 - _2379;
    assign _2381 = _2378 ? _2380 : t0_wait_count;
    assign _2382 = _754 ? t0_wait_count : _2381;
    assign _2383 = _748 ? t0_wait_count : _2382;
    assign _2385 = _742 ? _356 : _2383;
    assign _9 = _2385;
    assign _10 = _9;
    always @(posedge _99) begin
        if (_97)
            t0_wait_count <= _356;
        else
            t0_wait_count <= _10;
    end
    assign _2387 = 7'b1001011;
    assign _2388 = _728 == _2387;
    assign _2386 = _722 & _726;
    assign _2389 = _2386 & _2388;
    assign _2390 = _2389 ? _732 : cfg_t0_timeout;
    assign _11 = _2390;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_timeout <= _356;
        else
            cfg_t0_timeout <= _11;
    end
    assign _2418 = 1'b1;
    assign _2377 = ~ _2376;
    assign _2364 = ~ _2363;
    assign _2301 = _2299 == _2395;
    assign _2365 = _2301 & _2364;
    assign _2367 = _2365 & _2366;
    assign _2378 = _2367 & _2377;
    assign _2419 = _2378 ? _2418 : t0_waiting;
    assign _2421 = _2417 ? _716 : _2419;
    assign _2422 = _754 ? t0_waiting : _2421;
    assign _2423 = _748 ? t0_waiting : _2422;
    assign _2425 = _742 ? _716 : _2423;
    assign _12 = _2425;
    assign _13 = _12;
    always @(posedge _99) begin
        if (_97)
            t0_waiting <= _716;
        else
            t0_waiting <= _13;
    end
    assign _2374 = t0_waiting ? t0_wait_count : cfg_t0_timeout;
    assign _2376 = _2374 == _356;
    assign _2366 = _2298[4:4];
    assign _2399 = _2366 & _2376;
    assign _2362 = _2298[8:8];
    assign _2360 = _2352[7:7];
    assign _2359 = _2352[6:6];
    assign _2358 = _2352[5:5];
    assign _2357 = _2352[4:4];
    assign _2356 = _2352[3:3];
    assign _2355 = _2352[2:2];
    assign _2354 = _2352[1:1];
    assign _2353 = _2352[0:0];
    assign _2302 = _2298[7:5];
    always @* begin
        case (_2302)
        0:
            _2361 <= _2353;
        1:
            _2361 <= _2354;
        2:
            _2361 <= _2355;
        3:
            _2361 <= _2356;
        4:
            _2361 <= _2357;
        5:
            _2361 <= _2358;
        6:
            _2361 <= _2359;
        default:
            _2361 <= _2360;
        endcase
    end
    assign _2363 = _2361 == _2362;
    assign _5131 = ~ _2363;
    assign _5130 = _2299 == _2395;
    assign _5132 = _5130 & _5131;
    assign _5133 = _5132 & _2399;
    assign _5126 = t0_isr_count < cfg_t0_threshold;
    assign _399 = 5'b01000;
    assign _2430 = _732[4:0];
    assign _2427 = 7'b1000101;
    assign _2428 = _728 == _2427;
    assign _2426 = _722 & _726;
    assign _2429 = _2426 & _2428;
    assign _2431 = _2429 ? _2430 : cfg_t0_threshold;
    assign _14 = _2431;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_threshold <= _399;
        else
            cfg_t0_threshold <= _14;
    end
    assign _2468 = _2466[4:0];
    assign _2465 = { gnd,
                     _2464 };
    assign _2458 = { gnd,
                     t0_osr_count };
    assign _2466 = _2458 + _2465;
    assign _2457 = 6'b010000;
    assign _2467 = _2457 < _2466;
    assign _2470 = _2467 ? _252 : _2468;
    assign _2455 = _2404 ? _585 : t0_osr_count;
    assign _2449 = _2441 == _5182;
    assign _2451 = _2449 ? _585 : t0_osr_count;
    assign _2452 = _2447 ? _2451 : t0_osr_count;
    assign _2440 = _2299 == _4727;
    assign _2453 = _2440 ? _2452 : t0_osr_count;
    assign _2438 = _2299 == _5182;
    assign _2456 = _2438 ? _2455 : _2453;
    assign _2436 = _2299 == _4761;
    assign _2471 = _2436 ? _2470 : _2456;
    assign _2472 = _2417 ? _2471 : t0_osr_count;
    assign _2473 = _754 ? t0_osr_count : _2472;
    assign _2474 = _748 ? t0_osr_count : _2473;
    assign _2475 = _742 ? cfg_t0_threshold : _2474;
    assign _15 = _2475;
    assign _16 = _15;
    always @(posedge _99) begin
        if (_97)
            t0_osr_count <= _585;
        else
            t0_osr_count <= _16;
    end
    assign _5125 = t0_osr_count < cfg_t0_threshold;
    assign _5123 = t0_x == t0_y;
    assign _5124 = ~ _5123;
    assign _5120 = t0_y == _356;
    assign _5121 = ~ _5120;
    assign _5122 = ~ _5121;
    assign _5105 = t0_x - _2379;
    assign _5102 = 3'b010;
    assign _5103 = _5073 == _5102;
    assign _5106 = _5103 ? _5105 : t0_x;
    assign _5099 = _5068 == _184;
    assign _5100 = _5099 ? _2866 : t0_x;
    assign _2350 = _2349 & _2348;
    assign _2349 = pin_out[0:0];
    assign _2348 = _2312[0:0];
    assign _2347 = cfg_pin_modes[1:0];
    always @* begin
        case (_2347)
        0:
            _2351 <= _2348;
        1:
            _2351 <= _2349;
        2:
            _2351 <= _2350;
        default:
            _2351 <= _2348;
        endcase
    end
    assign _2345 = _2344 & _2343;
    assign _2344 = pin_out[1:1];
    assign _2343 = _2312[1:1];
    assign _2342 = cfg_pin_modes[3:2];
    always @* begin
        case (_2342)
        0:
            _2346 <= _2343;
        1:
            _2346 <= _2344;
        2:
            _2346 <= _2345;
        default:
            _2346 <= _2343;
        endcase
    end
    assign _2340 = _2339 & _2338;
    assign _2339 = pin_out[2:2];
    assign _2338 = _2312[2:2];
    assign _2337 = cfg_pin_modes[5:4];
    always @* begin
        case (_2337)
        0:
            _2341 <= _2338;
        1:
            _2341 <= _2339;
        2:
            _2341 <= _2340;
        default:
            _2341 <= _2338;
        endcase
    end
    assign _2335 = _2334 & _2333;
    assign _2334 = pin_out[3:3];
    assign _2333 = _2312[3:3];
    assign _2332 = cfg_pin_modes[7:6];
    always @* begin
        case (_2332)
        0:
            _2336 <= _2333;
        1:
            _2336 <= _2334;
        2:
            _2336 <= _2335;
        default:
            _2336 <= _2333;
        endcase
    end
    assign _2330 = _2329 & _2328;
    assign _2329 = pin_out[4:4];
    assign _2328 = _2312[4:4];
    assign _2327 = cfg_pin_modes[9:8];
    always @* begin
        case (_2327)
        0:
            _2331 <= _2328;
        1:
            _2331 <= _2329;
        2:
            _2331 <= _2330;
        default:
            _2331 <= _2328;
        endcase
    end
    assign _2325 = _2324 & _2323;
    assign _2324 = pin_out[5:5];
    assign _2323 = _2312[5:5];
    assign _2322 = cfg_pin_modes[11:10];
    always @* begin
        case (_2322)
        0:
            _2326 <= _2323;
        1:
            _2326 <= _2324;
        2:
            _2326 <= _2325;
        default:
            _2326 <= _2323;
        endcase
    end
    assign _2320 = _2319 & _2318;
    assign _2319 = pin_out[6:6];
    assign _2318 = _2312[6:6];
    assign _2317 = cfg_pin_modes[13:12];
    always @* begin
        case (_2317)
        0:
            _2321 <= _2318;
        1:
            _2321 <= _2319;
        2:
            _2321 <= _2320;
        default:
            _2321 <= _2318;
        endcase
    end
    assign _2315 = _2314 & _2313;
    assign _117 = 8'b11111111;
    assign _4826 = _4699[7:7];
    assign _4825 = _4699[6:6];
    assign _4824 = _4699[5:5];
    assign _4823 = _4699[4:4];
    assign _4822 = _4699[3:3];
    assign _4821 = _4699[2:2];
    assign _4820 = _4699[1:1];
    assign _4819 = _4699[0:0];
    always @* begin
        case (_4813)
        0:
            _4827 <= _4819;
        1:
            _4827 <= _4820;
        2:
            _4827 <= _4821;
        3:
            _4827 <= _4822;
        4:
            _4827 <= _4823;
        5:
            _4827 <= _4824;
        6:
            _4827 <= _4825;
        default:
            _4827 <= _4826;
        endcase
    end
    assign _4818 = _4680[0:0];
    assign _4816 = { _297,
                     _4241 };
    assign _4813 = _5137 - _4277;
    assign _4814 = { gnd,
                     _4813 };
    assign _4817 = _4814 < _4816;
    assign _4828 = _4817 ? _4827 : _4818;
    assign _4809 = _4699[7:7];
    assign _4808 = _4699[6:6];
    assign _4807 = _4699[5:5];
    assign _4806 = _4699[4:4];
    assign _4805 = _4699[3:3];
    assign _4804 = _4699[2:2];
    assign _4803 = _4699[1:1];
    assign _4802 = _4699[0:0];
    always @* begin
        case (_4796)
        0:
            _4810 <= _4802;
        1:
            _4810 <= _4803;
        2:
            _4810 <= _4804;
        3:
            _4810 <= _4805;
        4:
            _4810 <= _4806;
        5:
            _4810 <= _4807;
        6:
            _4810 <= _4808;
        default:
            _4810 <= _4809;
        endcase
    end
    assign _4801 = _4680[1:1];
    assign _4799 = { _297,
                     _4241 };
    assign _4796 = _2395 - _4277;
    assign _4797 = { gnd,
                     _4796 };
    assign _4800 = _4797 < _4799;
    assign _4811 = _4800 ? _4810 : _4801;
    assign _4792 = _4699[7:7];
    assign _4791 = _4699[6:6];
    assign _4790 = _4699[5:5];
    assign _4789 = _4699[4:4];
    assign _4788 = _4699[3:3];
    assign _4787 = _4699[2:2];
    assign _4786 = _4699[1:1];
    assign _4785 = _4699[0:0];
    always @* begin
        case (_4779)
        0:
            _4793 <= _4785;
        1:
            _4793 <= _4786;
        2:
            _4793 <= _4787;
        3:
            _4793 <= _4788;
        4:
            _4793 <= _4789;
        5:
            _4793 <= _4790;
        6:
            _4793 <= _4791;
        default:
            _4793 <= _4792;
        endcase
    end
    assign _4784 = _4680[2:2];
    assign _4782 = { _297,
                     _4241 };
    assign _4779 = _5102 - _4277;
    assign _4780 = { gnd,
                     _4779 };
    assign _4783 = _4780 < _4782;
    assign _4794 = _4783 ? _4793 : _4784;
    assign _4775 = _4699[7:7];
    assign _4774 = _4699[6:6];
    assign _4773 = _4699[5:5];
    assign _4772 = _4699[4:4];
    assign _4771 = _4699[3:3];
    assign _4770 = _4699[2:2];
    assign _4769 = _4699[1:1];
    assign _4768 = _4699[0:0];
    always @* begin
        case (_4762)
        0:
            _4776 <= _4768;
        1:
            _4776 <= _4769;
        2:
            _4776 <= _4770;
        3:
            _4776 <= _4771;
        4:
            _4776 <= _4772;
        5:
            _4776 <= _4773;
        6:
            _4776 <= _4774;
        default:
            _4776 <= _4775;
        endcase
    end
    assign _4767 = _4680[3:3];
    assign _4765 = { _297,
                     _4241 };
    assign _4761 = 3'b011;
    assign _4762 = _4761 - _4277;
    assign _4763 = { gnd,
                     _4762 };
    assign _4766 = _4763 < _4765;
    assign _4777 = _4766 ? _4776 : _4767;
    assign _4758 = _4699[7:7];
    assign _4757 = _4699[6:6];
    assign _4756 = _4699[5:5];
    assign _4755 = _4699[4:4];
    assign _4754 = _4699[3:3];
    assign _4753 = _4699[2:2];
    assign _4752 = _4699[1:1];
    assign _4751 = _4699[0:0];
    always @* begin
        case (_4745)
        0:
            _4759 <= _4751;
        1:
            _4759 <= _4752;
        2:
            _4759 <= _4753;
        3:
            _4759 <= _4754;
        4:
            _4759 <= _4755;
        5:
            _4759 <= _4756;
        6:
            _4759 <= _4757;
        default:
            _4759 <= _4758;
        endcase
    end
    assign _4750 = _4680[4:4];
    assign _4748 = { _297,
                     _4241 };
    assign _4745 = _5182 - _4277;
    assign _4746 = { gnd,
                     _4745 };
    assign _4749 = _4746 < _4748;
    assign _4760 = _4749 ? _4759 : _4750;
    assign _4741 = _4699[7:7];
    assign _4740 = _4699[6:6];
    assign _4739 = _4699[5:5];
    assign _4738 = _4699[4:4];
    assign _4737 = _4699[3:3];
    assign _4736 = _4699[2:2];
    assign _4735 = _4699[1:1];
    assign _4734 = _4699[0:0];
    always @* begin
        case (_4728)
        0:
            _4742 <= _4734;
        1:
            _4742 <= _4735;
        2:
            _4742 <= _4736;
        3:
            _4742 <= _4737;
        4:
            _4742 <= _4738;
        5:
            _4742 <= _4739;
        6:
            _4742 <= _4740;
        default:
            _4742 <= _4741;
        endcase
    end
    assign _4733 = _4680[5:5];
    assign _4731 = { _297,
                     _4241 };
    assign _4727 = 3'b101;
    assign _4728 = _4727 - _4277;
    assign _4729 = { gnd,
                     _4728 };
    assign _4732 = _4729 < _4731;
    assign _4743 = _4732 ? _4742 : _4733;
    assign _4724 = _4699[7:7];
    assign _4723 = _4699[6:6];
    assign _4722 = _4699[5:5];
    assign _4721 = _4699[4:4];
    assign _4720 = _4699[3:3];
    assign _4719 = _4699[2:2];
    assign _4718 = _4699[1:1];
    assign _4717 = _4699[0:0];
    always @* begin
        case (_4711)
        0:
            _4725 <= _4717;
        1:
            _4725 <= _4718;
        2:
            _4725 <= _4719;
        3:
            _4725 <= _4720;
        4:
            _4725 <= _4721;
        5:
            _4725 <= _4722;
        6:
            _4725 <= _4723;
        default:
            _4725 <= _4724;
        endcase
    end
    assign _4716 = _4680[6:6];
    assign _4714 = { _297,
                     _4241 };
    assign _4710 = 3'b110;
    assign _4711 = _4710 - _4277;
    assign _4712 = { gnd,
                     _4711 };
    assign _4715 = _4712 < _4714;
    assign _4726 = _4715 ? _4725 : _4716;
    assign _4707 = _4699[7:7];
    assign _4706 = _4699[6:6];
    assign _4705 = _4699[5:5];
    assign _4704 = _4699[4:4];
    assign _4703 = _4699[3:3];
    assign _4702 = _4699[2:2];
    assign _4701 = _4699[1:1];
    assign _4694 = _4692[3:2];
    assign _4695 = { _297,
                     _4694 };
    assign _4690 = _4240[3:1];
    assign _4691 = { _716,
                     _4690 };
    assign _4688 = _4685[0:0];
    assign _4692 = _4688 ? _4691 : _4240;
    assign _4687 = _4685[1:1];
    assign _4696 = _4687 ? _4695 : _4692;
    assign _4684 = { gnd,
                     _4241 };
    assign _4685 = _5182 - _4684;
    assign _4686 = _4685[2:2];
    assign _4698 = _4686 ? _591 : _4696;
    assign _4699 = { _591,
                     _4698 };
    assign _4700 = _4699[0:0];
    always @* begin
        case (_4278)
        0:
            _4708 <= _4700;
        1:
            _4708 <= _4701;
        2:
            _4708 <= _4702;
        3:
            _4708 <= _4703;
        4:
            _4708 <= _4704;
        5:
            _4708 <= _4705;
        6:
            _4708 <= _4706;
        default:
            _4708 <= _4707;
        endcase
    end
    assign _4676 = _4162[7:7];
    assign _4675 = _4162[6:6];
    assign _4674 = _4162[5:5];
    assign _4673 = _4162[4:4];
    assign _4672 = _4162[3:3];
    assign _4671 = _4162[2:2];
    assign _4670 = _4162[1:1];
    assign _4669 = _4162[0:0];
    always @* begin
        case (_4665)
        0:
            _4677 <= _4669;
        1:
            _4677 <= _4670;
        2:
            _4677 <= _4671;
        3:
            _4677 <= _4672;
        4:
            _4677 <= _4673;
        5:
            _4677 <= _4674;
        6:
            _4677 <= _4675;
        default:
            _4677 <= _4676;
        endcase
    end
    assign _4668 = _22[0:0];
    assign _4665 = _5137 - _4428;
    assign _4666 = { _297,
                     _4665 };
    assign _4667 = _4666 < _3309;
    assign _4678 = _4667 ? _4677 : _4668;
    assign _4660 = _4162[7:7];
    assign _4659 = _4162[6:6];
    assign _4658 = _4162[5:5];
    assign _4657 = _4162[4:4];
    assign _4656 = _4162[3:3];
    assign _4655 = _4162[2:2];
    assign _4654 = _4162[1:1];
    assign _4653 = _4162[0:0];
    always @* begin
        case (_4649)
        0:
            _4661 <= _4653;
        1:
            _4661 <= _4654;
        2:
            _4661 <= _4655;
        3:
            _4661 <= _4656;
        4:
            _4661 <= _4657;
        5:
            _4661 <= _4658;
        6:
            _4661 <= _4659;
        default:
            _4661 <= _4660;
        endcase
    end
    assign _4652 = _22[1:1];
    assign _4649 = _2395 - _4428;
    assign _4650 = { _297,
                     _4649 };
    assign _4651 = _4650 < _3309;
    assign _4662 = _4651 ? _4661 : _4652;
    assign _4644 = _4162[7:7];
    assign _4643 = _4162[6:6];
    assign _4642 = _4162[5:5];
    assign _4641 = _4162[4:4];
    assign _4640 = _4162[3:3];
    assign _4639 = _4162[2:2];
    assign _4638 = _4162[1:1];
    assign _4637 = _4162[0:0];
    always @* begin
        case (_4633)
        0:
            _4645 <= _4637;
        1:
            _4645 <= _4638;
        2:
            _4645 <= _4639;
        3:
            _4645 <= _4640;
        4:
            _4645 <= _4641;
        5:
            _4645 <= _4642;
        6:
            _4645 <= _4643;
        default:
            _4645 <= _4644;
        endcase
    end
    assign _4636 = _22[2:2];
    assign _4633 = _5102 - _4428;
    assign _4634 = { _297,
                     _4633 };
    assign _4635 = _4634 < _3309;
    assign _4646 = _4635 ? _4645 : _4636;
    assign _4628 = _4162[7:7];
    assign _4627 = _4162[6:6];
    assign _4626 = _4162[5:5];
    assign _4625 = _4162[4:4];
    assign _4624 = _4162[3:3];
    assign _4623 = _4162[2:2];
    assign _4622 = _4162[1:1];
    assign _4621 = _4162[0:0];
    always @* begin
        case (_4617)
        0:
            _4629 <= _4621;
        1:
            _4629 <= _4622;
        2:
            _4629 <= _4623;
        3:
            _4629 <= _4624;
        4:
            _4629 <= _4625;
        5:
            _4629 <= _4626;
        6:
            _4629 <= _4627;
        default:
            _4629 <= _4628;
        endcase
    end
    assign _4620 = _22[3:3];
    assign _4617 = _4761 - _4428;
    assign _4618 = { _297,
                     _4617 };
    assign _4619 = _4618 < _3309;
    assign _4630 = _4619 ? _4629 : _4620;
    assign _4612 = _4162[7:7];
    assign _4611 = _4162[6:6];
    assign _4610 = _4162[5:5];
    assign _4609 = _4162[4:4];
    assign _4608 = _4162[3:3];
    assign _4607 = _4162[2:2];
    assign _4606 = _4162[1:1];
    assign _4605 = _4162[0:0];
    always @* begin
        case (_4601)
        0:
            _4613 <= _4605;
        1:
            _4613 <= _4606;
        2:
            _4613 <= _4607;
        3:
            _4613 <= _4608;
        4:
            _4613 <= _4609;
        5:
            _4613 <= _4610;
        6:
            _4613 <= _4611;
        default:
            _4613 <= _4612;
        endcase
    end
    assign _4604 = _22[4:4];
    assign _4601 = _5182 - _4428;
    assign _4602 = { _297,
                     _4601 };
    assign _4603 = _4602 < _3309;
    assign _4614 = _4603 ? _4613 : _4604;
    assign _4596 = _4162[7:7];
    assign _4595 = _4162[6:6];
    assign _4594 = _4162[5:5];
    assign _4593 = _4162[4:4];
    assign _4592 = _4162[3:3];
    assign _4591 = _4162[2:2];
    assign _4590 = _4162[1:1];
    assign _4589 = _4162[0:0];
    always @* begin
        case (_4585)
        0:
            _4597 <= _4589;
        1:
            _4597 <= _4590;
        2:
            _4597 <= _4591;
        3:
            _4597 <= _4592;
        4:
            _4597 <= _4593;
        5:
            _4597 <= _4594;
        6:
            _4597 <= _4595;
        default:
            _4597 <= _4596;
        endcase
    end
    assign _4588 = _22[5:5];
    assign _4585 = _4727 - _4428;
    assign _4586 = { _297,
                     _4585 };
    assign _4587 = _4586 < _3309;
    assign _4598 = _4587 ? _4597 : _4588;
    assign _4580 = _4162[7:7];
    assign _4579 = _4162[6:6];
    assign _4578 = _4162[5:5];
    assign _4577 = _4162[4:4];
    assign _4576 = _4162[3:3];
    assign _4575 = _4162[2:2];
    assign _4574 = _4162[1:1];
    assign _4573 = _4162[0:0];
    always @* begin
        case (_4569)
        0:
            _4581 <= _4573;
        1:
            _4581 <= _4574;
        2:
            _4581 <= _4575;
        3:
            _4581 <= _4576;
        4:
            _4581 <= _4577;
        5:
            _4581 <= _4578;
        6:
            _4581 <= _4579;
        default:
            _4581 <= _4580;
        endcase
    end
    assign _4572 = _22[6:6];
    assign _4569 = _4710 - _4428;
    assign _4570 = { _297,
                     _4569 };
    assign _4571 = _4570 < _3309;
    assign _4582 = _4571 ? _4581 : _4572;
    assign _4564 = _4162[7:7];
    assign _4563 = _4162[6:6];
    assign _4562 = _4162[5:5];
    assign _4561 = _4162[4:4];
    assign _4560 = _4162[3:3];
    assign _4559 = _4162[2:2];
    assign _4558 = _4162[1:1];
    assign _4557 = _4162[0:0];
    always @* begin
        case (_4553)
        0:
            _4565 <= _4557;
        1:
            _4565 <= _4558;
        2:
            _4565 <= _4559;
        3:
            _4565 <= _4560;
        4:
            _4565 <= _4561;
        5:
            _4565 <= _4562;
        6:
            _4565 <= _4563;
        default:
            _4565 <= _4564;
        endcase
    end
    assign _4556 = _22[7:7];
    assign _4552 = 3'b111;
    assign _4553 = _4552 - _4428;
    assign _4554 = { _297,
                     _4553 };
    assign _4555 = _4554 < _3309;
    assign _4566 = _4555 ? _4565 : _4556;
    assign _4679 = { _4566,
                     _4582,
                     _4598,
                     _4614,
                     _4630,
                     _4646,
                     _4662,
                     _4678 };
    assign _4546 = _3379[7:7];
    assign _4545 = _3379[6:6];
    assign _4544 = _3379[5:5];
    assign _4543 = _3379[4:4];
    assign _4542 = _3379[3:3];
    assign _4541 = _3379[2:2];
    assign _4540 = _3379[1:1];
    assign _4539 = _3379[0:0];
    always @* begin
        case (_4535)
        0:
            _4547 <= _4539;
        1:
            _4547 <= _4540;
        2:
            _4547 <= _4541;
        3:
            _4547 <= _4542;
        4:
            _4547 <= _4543;
        5:
            _4547 <= _4544;
        6:
            _4547 <= _4545;
        default:
            _4547 <= _4546;
        endcase
    end
    assign _4538 = _22[0:0];
    assign _4535 = _5137 - _4428;
    assign _4536 = { gnd,
                     _4535 };
    assign _4537 = _4536 < _4431;
    assign _4548 = _4537 ? _4547 : _4538;
    assign _4531 = _3379[7:7];
    assign _4530 = _3379[6:6];
    assign _4529 = _3379[5:5];
    assign _4528 = _3379[4:4];
    assign _4527 = _3379[3:3];
    assign _4526 = _3379[2:2];
    assign _4525 = _3379[1:1];
    assign _4524 = _3379[0:0];
    always @* begin
        case (_4520)
        0:
            _4532 <= _4524;
        1:
            _4532 <= _4525;
        2:
            _4532 <= _4526;
        3:
            _4532 <= _4527;
        4:
            _4532 <= _4528;
        5:
            _4532 <= _4529;
        6:
            _4532 <= _4530;
        default:
            _4532 <= _4531;
        endcase
    end
    assign _4523 = _22[1:1];
    assign _4520 = _2395 - _4428;
    assign _4521 = { gnd,
                     _4520 };
    assign _4522 = _4521 < _4431;
    assign _4533 = _4522 ? _4532 : _4523;
    assign _4516 = _3379[7:7];
    assign _4515 = _3379[6:6];
    assign _4514 = _3379[5:5];
    assign _4513 = _3379[4:4];
    assign _4512 = _3379[3:3];
    assign _4511 = _3379[2:2];
    assign _4510 = _3379[1:1];
    assign _4509 = _3379[0:0];
    always @* begin
        case (_4505)
        0:
            _4517 <= _4509;
        1:
            _4517 <= _4510;
        2:
            _4517 <= _4511;
        3:
            _4517 <= _4512;
        4:
            _4517 <= _4513;
        5:
            _4517 <= _4514;
        6:
            _4517 <= _4515;
        default:
            _4517 <= _4516;
        endcase
    end
    assign _4508 = _22[2:2];
    assign _4505 = _5102 - _4428;
    assign _4506 = { gnd,
                     _4505 };
    assign _4507 = _4506 < _4431;
    assign _4518 = _4507 ? _4517 : _4508;
    assign _4501 = _3379[7:7];
    assign _4500 = _3379[6:6];
    assign _4499 = _3379[5:5];
    assign _4498 = _3379[4:4];
    assign _4497 = _3379[3:3];
    assign _4496 = _3379[2:2];
    assign _4495 = _3379[1:1];
    assign _4494 = _3379[0:0];
    always @* begin
        case (_4490)
        0:
            _4502 <= _4494;
        1:
            _4502 <= _4495;
        2:
            _4502 <= _4496;
        3:
            _4502 <= _4497;
        4:
            _4502 <= _4498;
        5:
            _4502 <= _4499;
        6:
            _4502 <= _4500;
        default:
            _4502 <= _4501;
        endcase
    end
    assign _4493 = _22[3:3];
    assign _4490 = _4761 - _4428;
    assign _4491 = { gnd,
                     _4490 };
    assign _4492 = _4491 < _4431;
    assign _4503 = _4492 ? _4502 : _4493;
    assign _4486 = _3379[7:7];
    assign _4485 = _3379[6:6];
    assign _4484 = _3379[5:5];
    assign _4483 = _3379[4:4];
    assign _4482 = _3379[3:3];
    assign _4481 = _3379[2:2];
    assign _4480 = _3379[1:1];
    assign _4479 = _3379[0:0];
    always @* begin
        case (_4475)
        0:
            _4487 <= _4479;
        1:
            _4487 <= _4480;
        2:
            _4487 <= _4481;
        3:
            _4487 <= _4482;
        4:
            _4487 <= _4483;
        5:
            _4487 <= _4484;
        6:
            _4487 <= _4485;
        default:
            _4487 <= _4486;
        endcase
    end
    assign _4478 = _22[4:4];
    assign _4475 = _5182 - _4428;
    assign _4476 = { gnd,
                     _4475 };
    assign _4477 = _4476 < _4431;
    assign _4488 = _4477 ? _4487 : _4478;
    assign _4471 = _3379[7:7];
    assign _4470 = _3379[6:6];
    assign _4469 = _3379[5:5];
    assign _4468 = _3379[4:4];
    assign _4467 = _3379[3:3];
    assign _4466 = _3379[2:2];
    assign _4465 = _3379[1:1];
    assign _4464 = _3379[0:0];
    always @* begin
        case (_4460)
        0:
            _4472 <= _4464;
        1:
            _4472 <= _4465;
        2:
            _4472 <= _4466;
        3:
            _4472 <= _4467;
        4:
            _4472 <= _4468;
        5:
            _4472 <= _4469;
        6:
            _4472 <= _4470;
        default:
            _4472 <= _4471;
        endcase
    end
    assign _4463 = _22[5:5];
    assign _4460 = _4727 - _4428;
    assign _4461 = { gnd,
                     _4460 };
    assign _4462 = _4461 < _4431;
    assign _4473 = _4462 ? _4472 : _4463;
    assign _4456 = _3379[7:7];
    assign _4455 = _3379[6:6];
    assign _4454 = _3379[5:5];
    assign _4453 = _3379[4:4];
    assign _4452 = _3379[3:3];
    assign _4451 = _3379[2:2];
    assign _4450 = _3379[1:1];
    assign _4449 = _3379[0:0];
    always @* begin
        case (_4445)
        0:
            _4457 <= _4449;
        1:
            _4457 <= _4450;
        2:
            _4457 <= _4451;
        3:
            _4457 <= _4452;
        4:
            _4457 <= _4453;
        5:
            _4457 <= _4454;
        6:
            _4457 <= _4455;
        default:
            _4457 <= _4456;
        endcase
    end
    assign _4448 = _22[6:6];
    assign _4445 = _4710 - _4428;
    assign _4446 = { gnd,
                     _4445 };
    assign _4447 = _4446 < _4431;
    assign _4458 = _4447 ? _4457 : _4448;
    assign _4441 = _3379[7:7];
    assign _4440 = _3379[6:6];
    assign _4439 = _3379[5:5];
    assign _4438 = _3379[4:4];
    assign _4437 = _3379[3:3];
    assign _4436 = _3379[2:2];
    assign _4435 = _3379[1:1];
    assign _4434 = _3379[0:0];
    always @* begin
        case (_4429)
        0:
            _4442 <= _4434;
        1:
            _4442 <= _4435;
        2:
            _4442 <= _4436;
        3:
            _4442 <= _4437;
        4:
            _4442 <= _4438;
        5:
            _4442 <= _4439;
        6:
            _4442 <= _4440;
        default:
            _4442 <= _4441;
        endcase
    end
    assign _4433 = _22[7:7];
    assign _4431 = cfg_t1_out_cfg[7:4];
    assign _562 = 8'b00010000;
    assign _2480 = _732[7:0];
    assign _2477 = 7'b1010010;
    assign _2478 = _728 == _2477;
    assign _2476 = _722 & _726;
    assign _2479 = _2476 & _2478;
    assign _2481 = _2479 ? _2480 : cfg_t1_out_cfg;
    assign _17 = _2481;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_out_cfg <= _562;
        else
            cfg_t1_out_cfg <= _17;
    end
    assign _4428 = cfg_t1_out_cfg[2:0];
    assign _4429 = _4552 - _4428;
    assign _4430 = { gnd,
                     _4429 };
    assign _4432 = _4430 < _4431;
    assign _4443 = _4432 ? _4442 : _4433;
    assign _4549 = { _4443,
                     _4458,
                     _4473,
                     _4488,
                     _4503,
                     _4518,
                     _4533,
                     _4548 };
    assign _4422 = _4120[7:7];
    assign _4421 = _4120[6:6];
    assign _4420 = _4120[5:5];
    assign _4419 = _4120[4:4];
    assign _4418 = _4120[3:3];
    assign _4417 = _4120[2:2];
    assign _4416 = _4120[1:1];
    assign _4415 = _4120[0:0];
    always @* begin
        case (_4411)
        0:
            _4423 <= _4415;
        1:
            _4423 <= _4416;
        2:
            _4423 <= _4417;
        3:
            _4423 <= _4418;
        4:
            _4423 <= _4419;
        5:
            _4423 <= _4420;
        6:
            _4423 <= _4421;
        default:
            _4423 <= _4422;
        endcase
    end
    assign _4414 = _22[0:0];
    assign _4411 = _5137 - _4304;
    assign _4412 = { gnd,
                     _4411 };
    assign _4413 = _4412 < _4307;
    assign _4424 = _4413 ? _4423 : _4414;
    assign _4407 = _4120[7:7];
    assign _4406 = _4120[6:6];
    assign _4405 = _4120[5:5];
    assign _4404 = _4120[4:4];
    assign _4403 = _4120[3:3];
    assign _4402 = _4120[2:2];
    assign _4401 = _4120[1:1];
    assign _4400 = _4120[0:0];
    always @* begin
        case (_4396)
        0:
            _4408 <= _4400;
        1:
            _4408 <= _4401;
        2:
            _4408 <= _4402;
        3:
            _4408 <= _4403;
        4:
            _4408 <= _4404;
        5:
            _4408 <= _4405;
        6:
            _4408 <= _4406;
        default:
            _4408 <= _4407;
        endcase
    end
    assign _4399 = _22[1:1];
    assign _4396 = _2395 - _4304;
    assign _4397 = { gnd,
                     _4396 };
    assign _4398 = _4397 < _4307;
    assign _4409 = _4398 ? _4408 : _4399;
    assign _4392 = _4120[7:7];
    assign _4391 = _4120[6:6];
    assign _4390 = _4120[5:5];
    assign _4389 = _4120[4:4];
    assign _4388 = _4120[3:3];
    assign _4387 = _4120[2:2];
    assign _4386 = _4120[1:1];
    assign _4385 = _4120[0:0];
    always @* begin
        case (_4381)
        0:
            _4393 <= _4385;
        1:
            _4393 <= _4386;
        2:
            _4393 <= _4387;
        3:
            _4393 <= _4388;
        4:
            _4393 <= _4389;
        5:
            _4393 <= _4390;
        6:
            _4393 <= _4391;
        default:
            _4393 <= _4392;
        endcase
    end
    assign _4384 = _22[2:2];
    assign _4381 = _5102 - _4304;
    assign _4382 = { gnd,
                     _4381 };
    assign _4383 = _4382 < _4307;
    assign _4394 = _4383 ? _4393 : _4384;
    assign _4377 = _4120[7:7];
    assign _4376 = _4120[6:6];
    assign _4375 = _4120[5:5];
    assign _4374 = _4120[4:4];
    assign _4373 = _4120[3:3];
    assign _4372 = _4120[2:2];
    assign _4371 = _4120[1:1];
    assign _4370 = _4120[0:0];
    always @* begin
        case (_4366)
        0:
            _4378 <= _4370;
        1:
            _4378 <= _4371;
        2:
            _4378 <= _4372;
        3:
            _4378 <= _4373;
        4:
            _4378 <= _4374;
        5:
            _4378 <= _4375;
        6:
            _4378 <= _4376;
        default:
            _4378 <= _4377;
        endcase
    end
    assign _4369 = _22[3:3];
    assign _4366 = _4761 - _4304;
    assign _4367 = { gnd,
                     _4366 };
    assign _4368 = _4367 < _4307;
    assign _4379 = _4368 ? _4378 : _4369;
    assign _4362 = _4120[7:7];
    assign _4361 = _4120[6:6];
    assign _4360 = _4120[5:5];
    assign _4359 = _4120[4:4];
    assign _4358 = _4120[3:3];
    assign _4357 = _4120[2:2];
    assign _4356 = _4120[1:1];
    assign _4355 = _4120[0:0];
    always @* begin
        case (_4351)
        0:
            _4363 <= _4355;
        1:
            _4363 <= _4356;
        2:
            _4363 <= _4357;
        3:
            _4363 <= _4358;
        4:
            _4363 <= _4359;
        5:
            _4363 <= _4360;
        6:
            _4363 <= _4361;
        default:
            _4363 <= _4362;
        endcase
    end
    assign _4354 = _22[4:4];
    assign _4351 = _5182 - _4304;
    assign _4352 = { gnd,
                     _4351 };
    assign _4353 = _4352 < _4307;
    assign _4364 = _4353 ? _4363 : _4354;
    assign _4347 = _4120[7:7];
    assign _4346 = _4120[6:6];
    assign _4345 = _4120[5:5];
    assign _4344 = _4120[4:4];
    assign _4343 = _4120[3:3];
    assign _4342 = _4120[2:2];
    assign _4341 = _4120[1:1];
    assign _4340 = _4120[0:0];
    always @* begin
        case (_4336)
        0:
            _4348 <= _4340;
        1:
            _4348 <= _4341;
        2:
            _4348 <= _4342;
        3:
            _4348 <= _4343;
        4:
            _4348 <= _4344;
        5:
            _4348 <= _4345;
        6:
            _4348 <= _4346;
        default:
            _4348 <= _4347;
        endcase
    end
    assign _4339 = _22[5:5];
    assign _4336 = _4727 - _4304;
    assign _4337 = { gnd,
                     _4336 };
    assign _4338 = _4337 < _4307;
    assign _4349 = _4338 ? _4348 : _4339;
    assign _4332 = _4120[7:7];
    assign _4331 = _4120[6:6];
    assign _4330 = _4120[5:5];
    assign _4329 = _4120[4:4];
    assign _4328 = _4120[3:3];
    assign _4327 = _4120[2:2];
    assign _4326 = _4120[1:1];
    assign _4325 = _4120[0:0];
    always @* begin
        case (_4321)
        0:
            _4333 <= _4325;
        1:
            _4333 <= _4326;
        2:
            _4333 <= _4327;
        3:
            _4333 <= _4328;
        4:
            _4333 <= _4329;
        5:
            _4333 <= _4330;
        6:
            _4333 <= _4331;
        default:
            _4333 <= _4332;
        endcase
    end
    assign _4324 = _22[6:6];
    assign _4321 = _4710 - _4304;
    assign _4322 = { gnd,
                     _4321 };
    assign _4323 = _4322 < _4307;
    assign _4334 = _4323 ? _4333 : _4324;
    assign _4317 = _4120[7:7];
    assign _4316 = _4120[6:6];
    assign _4315 = _4120[5:5];
    assign _4314 = _4120[4:4];
    assign _4313 = _4120[3:3];
    assign _4312 = _4120[2:2];
    assign _4311 = _4120[1:1];
    assign _4310 = _4120[0:0];
    always @* begin
        case (_4305)
        0:
            _4318 <= _4310;
        1:
            _4318 <= _4311;
        2:
            _4318 <= _4312;
        3:
            _4318 <= _4313;
        4:
            _4318 <= _4314;
        5:
            _4318 <= _4315;
        6:
            _4318 <= _4316;
        default:
            _4318 <= _4317;
        endcase
    end
    assign _4309 = _22[7:7];
    assign _4307 = cfg_t1_set_cfg[7:4];
    assign _2486 = _732[7:0];
    assign _2483 = 7'b1010011;
    assign _2484 = _728 == _2483;
    assign _2482 = _722 & _726;
    assign _2485 = _2482 & _2484;
    assign _2487 = _2485 ? _2486 : cfg_t1_set_cfg;
    assign _18 = _2487;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_set_cfg <= _562;
        else
            cfg_t1_set_cfg <= _18;
    end
    assign _4304 = cfg_t1_set_cfg[2:0];
    assign _4305 = _4552 - _4304;
    assign _4306 = { gnd,
                     _4305 };
    assign _4308 = _4306 < _4307;
    assign _4319 = _4308 ? _4318 : _4309;
    assign _4425 = { _4319,
                     _4334,
                     _4349,
                     _4364,
                     _4379,
                     _4394,
                     _4409,
                     _4424 };
    assign _3137 = _3010[7:7];
    assign _3136 = _3010[6:6];
    assign _3135 = _3010[5:5];
    assign _3134 = _3010[4:4];
    assign _3133 = _3010[3:3];
    assign _3132 = _3010[2:2];
    assign _3131 = _3010[1:1];
    assign _3130 = _3010[0:0];
    always @* begin
        case (_3124)
        0:
            _3138 <= _3130;
        1:
            _3138 <= _3131;
        2:
            _3138 <= _3132;
        3:
            _3138 <= _3133;
        4:
            _3138 <= _3134;
        5:
            _3138 <= _3135;
        6:
            _3138 <= _3136;
        default:
            _3138 <= _3137;
        endcase
    end
    assign _3129 = _2990[0:0];
    assign _3127 = { _297,
                     _2511 };
    assign _3124 = _5137 - _2507;
    assign _3125 = { gnd,
                     _3124 };
    assign _3128 = _3125 < _3127;
    assign _3139 = _3128 ? _3138 : _3129;
    assign _3120 = _3010[7:7];
    assign _3119 = _3010[6:6];
    assign _3118 = _3010[5:5];
    assign _3117 = _3010[4:4];
    assign _3116 = _3010[3:3];
    assign _3115 = _3010[2:2];
    assign _3114 = _3010[1:1];
    assign _3113 = _3010[0:0];
    always @* begin
        case (_3107)
        0:
            _3121 <= _3113;
        1:
            _3121 <= _3114;
        2:
            _3121 <= _3115;
        3:
            _3121 <= _3116;
        4:
            _3121 <= _3117;
        5:
            _3121 <= _3118;
        6:
            _3121 <= _3119;
        default:
            _3121 <= _3120;
        endcase
    end
    assign _3112 = _2990[1:1];
    assign _3110 = { _297,
                     _2511 };
    assign _3107 = _2395 - _2507;
    assign _3108 = { gnd,
                     _3107 };
    assign _3111 = _3108 < _3110;
    assign _3122 = _3111 ? _3121 : _3112;
    assign _3103 = _3010[7:7];
    assign _3102 = _3010[6:6];
    assign _3101 = _3010[5:5];
    assign _3100 = _3010[4:4];
    assign _3099 = _3010[3:3];
    assign _3098 = _3010[2:2];
    assign _3097 = _3010[1:1];
    assign _3096 = _3010[0:0];
    always @* begin
        case (_3090)
        0:
            _3104 <= _3096;
        1:
            _3104 <= _3097;
        2:
            _3104 <= _3098;
        3:
            _3104 <= _3099;
        4:
            _3104 <= _3100;
        5:
            _3104 <= _3101;
        6:
            _3104 <= _3102;
        default:
            _3104 <= _3103;
        endcase
    end
    assign _3095 = _2990[2:2];
    assign _3093 = { _297,
                     _2511 };
    assign _3090 = _5102 - _2507;
    assign _3091 = { gnd,
                     _3090 };
    assign _3094 = _3091 < _3093;
    assign _3105 = _3094 ? _3104 : _3095;
    assign _3086 = _3010[7:7];
    assign _3085 = _3010[6:6];
    assign _3084 = _3010[5:5];
    assign _3083 = _3010[4:4];
    assign _3082 = _3010[3:3];
    assign _3081 = _3010[2:2];
    assign _3080 = _3010[1:1];
    assign _3079 = _3010[0:0];
    always @* begin
        case (_3073)
        0:
            _3087 <= _3079;
        1:
            _3087 <= _3080;
        2:
            _3087 <= _3081;
        3:
            _3087 <= _3082;
        4:
            _3087 <= _3083;
        5:
            _3087 <= _3084;
        6:
            _3087 <= _3085;
        default:
            _3087 <= _3086;
        endcase
    end
    assign _3078 = _2990[3:3];
    assign _3076 = { _297,
                     _2511 };
    assign _3073 = _4761 - _2507;
    assign _3074 = { gnd,
                     _3073 };
    assign _3077 = _3074 < _3076;
    assign _3088 = _3077 ? _3087 : _3078;
    assign _3069 = _3010[7:7];
    assign _3068 = _3010[6:6];
    assign _3067 = _3010[5:5];
    assign _3066 = _3010[4:4];
    assign _3065 = _3010[3:3];
    assign _3064 = _3010[2:2];
    assign _3063 = _3010[1:1];
    assign _3062 = _3010[0:0];
    always @* begin
        case (_3056)
        0:
            _3070 <= _3062;
        1:
            _3070 <= _3063;
        2:
            _3070 <= _3064;
        3:
            _3070 <= _3065;
        4:
            _3070 <= _3066;
        5:
            _3070 <= _3067;
        6:
            _3070 <= _3068;
        default:
            _3070 <= _3069;
        endcase
    end
    assign _3061 = _2990[4:4];
    assign _3059 = { _297,
                     _2511 };
    assign _3056 = _5182 - _2507;
    assign _3057 = { gnd,
                     _3056 };
    assign _3060 = _3057 < _3059;
    assign _3071 = _3060 ? _3070 : _3061;
    assign _3052 = _3010[7:7];
    assign _3051 = _3010[6:6];
    assign _3050 = _3010[5:5];
    assign _3049 = _3010[4:4];
    assign _3048 = _3010[3:3];
    assign _3047 = _3010[2:2];
    assign _3046 = _3010[1:1];
    assign _3045 = _3010[0:0];
    always @* begin
        case (_3039)
        0:
            _3053 <= _3045;
        1:
            _3053 <= _3046;
        2:
            _3053 <= _3047;
        3:
            _3053 <= _3048;
        4:
            _3053 <= _3049;
        5:
            _3053 <= _3050;
        6:
            _3053 <= _3051;
        default:
            _3053 <= _3052;
        endcase
    end
    assign _3044 = _2990[5:5];
    assign _3042 = { _297,
                     _2511 };
    assign _3039 = _4727 - _2507;
    assign _3040 = { gnd,
                     _3039 };
    assign _3043 = _3040 < _3042;
    assign _3054 = _3043 ? _3053 : _3044;
    assign _3035 = _3010[7:7];
    assign _3034 = _3010[6:6];
    assign _3033 = _3010[5:5];
    assign _3032 = _3010[4:4];
    assign _3031 = _3010[3:3];
    assign _3030 = _3010[2:2];
    assign _3029 = _3010[1:1];
    assign _3028 = _3010[0:0];
    always @* begin
        case (_3022)
        0:
            _3036 <= _3028;
        1:
            _3036 <= _3029;
        2:
            _3036 <= _3030;
        3:
            _3036 <= _3031;
        4:
            _3036 <= _3032;
        5:
            _3036 <= _3033;
        6:
            _3036 <= _3034;
        default:
            _3036 <= _3035;
        endcase
    end
    assign _3027 = _2990[6:6];
    assign _3025 = { _297,
                     _2511 };
    assign _3022 = _4710 - _2507;
    assign _3023 = { gnd,
                     _3022 };
    assign _3026 = _3023 < _3025;
    assign _3037 = _3026 ? _3036 : _3027;
    assign _3018 = _3010[7:7];
    assign _3017 = _3010[6:6];
    assign _3016 = _3010[5:5];
    assign _3015 = _3010[4:4];
    assign _3014 = _3010[3:3];
    assign _3013 = _3010[2:2];
    assign _3012 = _3010[1:1];
    assign _3005 = _3003[3:2];
    assign _3006 = { _297,
                     _3005 };
    assign _3001 = _2999[3:1];
    assign _3002 = { _716,
                     _3001 };
    assign _2999 = _2298[12:9];
    assign _2998 = _2995[0:0];
    assign _3003 = _2998 ? _3002 : _2999;
    assign _2997 = _2995[1:1];
    assign _3007 = _2997 ? _3006 : _3003;
    assign _2994 = { gnd,
                     _2511 };
    assign _2995 = _5182 - _2994;
    assign _2996 = _2995[2:2];
    assign _3009 = _2996 ? _591 : _3007;
    assign _3010 = { _591,
                     _3009 };
    assign _3011 = _3010[0:0];
    always @* begin
        case (_2508)
        0:
            _3019 <= _3011;
        1:
            _3019 <= _3012;
        2:
            _3019 <= _3013;
        3:
            _3019 <= _3014;
        4:
            _3019 <= _3015;
        5:
            _3019 <= _3016;
        6:
            _3019 <= _3017;
        default:
            _3019 <= _3018;
        endcase
    end
    assign _2986 = _2866[7:7];
    assign _2985 = _2866[6:6];
    assign _2984 = _2866[5:5];
    assign _2983 = _2866[4:4];
    assign _2982 = _2866[3:3];
    assign _2981 = _2866[2:2];
    assign _2980 = _2866[1:1];
    assign _2979 = _2866[0:0];
    always @* begin
        case (_2975)
        0:
            _2987 <= _2979;
        1:
            _2987 <= _2980;
        2:
            _2987 <= _2981;
        3:
            _2987 <= _2982;
        4:
            _2987 <= _2983;
        5:
            _2987 <= _2984;
        6:
            _2987 <= _2985;
        default:
            _2987 <= _2986;
        endcase
    end
    assign _2978 = pin_out[0:0];
    assign _2975 = _5137 - _2663;
    assign _2976 = { _297,
                     _2975 };
    assign _2977 = _2976 < _2464;
    assign _2988 = _2977 ? _2987 : _2978;
    assign _2970 = _2866[7:7];
    assign _2969 = _2866[6:6];
    assign _2968 = _2866[5:5];
    assign _2967 = _2866[4:4];
    assign _2966 = _2866[3:3];
    assign _2965 = _2866[2:2];
    assign _2964 = _2866[1:1];
    assign _2963 = _2866[0:0];
    always @* begin
        case (_2959)
        0:
            _2971 <= _2963;
        1:
            _2971 <= _2964;
        2:
            _2971 <= _2965;
        3:
            _2971 <= _2966;
        4:
            _2971 <= _2967;
        5:
            _2971 <= _2968;
        6:
            _2971 <= _2969;
        default:
            _2971 <= _2970;
        endcase
    end
    assign _2962 = pin_out[1:1];
    assign _2959 = _2395 - _2663;
    assign _2960 = { _297,
                     _2959 };
    assign _2961 = _2960 < _2464;
    assign _2972 = _2961 ? _2971 : _2962;
    assign _2954 = _2866[7:7];
    assign _2953 = _2866[6:6];
    assign _2952 = _2866[5:5];
    assign _2951 = _2866[4:4];
    assign _2950 = _2866[3:3];
    assign _2949 = _2866[2:2];
    assign _2948 = _2866[1:1];
    assign _2947 = _2866[0:0];
    always @* begin
        case (_2943)
        0:
            _2955 <= _2947;
        1:
            _2955 <= _2948;
        2:
            _2955 <= _2949;
        3:
            _2955 <= _2950;
        4:
            _2955 <= _2951;
        5:
            _2955 <= _2952;
        6:
            _2955 <= _2953;
        default:
            _2955 <= _2954;
        endcase
    end
    assign _2946 = pin_out[2:2];
    assign _2943 = _5102 - _2663;
    assign _2944 = { _297,
                     _2943 };
    assign _2945 = _2944 < _2464;
    assign _2956 = _2945 ? _2955 : _2946;
    assign _2938 = _2866[7:7];
    assign _2937 = _2866[6:6];
    assign _2936 = _2866[5:5];
    assign _2935 = _2866[4:4];
    assign _2934 = _2866[3:3];
    assign _2933 = _2866[2:2];
    assign _2932 = _2866[1:1];
    assign _2931 = _2866[0:0];
    always @* begin
        case (_2927)
        0:
            _2939 <= _2931;
        1:
            _2939 <= _2932;
        2:
            _2939 <= _2933;
        3:
            _2939 <= _2934;
        4:
            _2939 <= _2935;
        5:
            _2939 <= _2936;
        6:
            _2939 <= _2937;
        default:
            _2939 <= _2938;
        endcase
    end
    assign _2930 = pin_out[3:3];
    assign _2927 = _4761 - _2663;
    assign _2928 = { _297,
                     _2927 };
    assign _2929 = _2928 < _2464;
    assign _2940 = _2929 ? _2939 : _2930;
    assign _2922 = _2866[7:7];
    assign _2921 = _2866[6:6];
    assign _2920 = _2866[5:5];
    assign _2919 = _2866[4:4];
    assign _2918 = _2866[3:3];
    assign _2917 = _2866[2:2];
    assign _2916 = _2866[1:1];
    assign _2915 = _2866[0:0];
    always @* begin
        case (_2911)
        0:
            _2923 <= _2915;
        1:
            _2923 <= _2916;
        2:
            _2923 <= _2917;
        3:
            _2923 <= _2918;
        4:
            _2923 <= _2919;
        5:
            _2923 <= _2920;
        6:
            _2923 <= _2921;
        default:
            _2923 <= _2922;
        endcase
    end
    assign _2914 = pin_out[4:4];
    assign _2911 = _5182 - _2663;
    assign _2912 = { _297,
                     _2911 };
    assign _2913 = _2912 < _2464;
    assign _2924 = _2913 ? _2923 : _2914;
    assign _2906 = _2866[7:7];
    assign _2905 = _2866[6:6];
    assign _2904 = _2866[5:5];
    assign _2903 = _2866[4:4];
    assign _2902 = _2866[3:3];
    assign _2901 = _2866[2:2];
    assign _2900 = _2866[1:1];
    assign _2899 = _2866[0:0];
    always @* begin
        case (_2895)
        0:
            _2907 <= _2899;
        1:
            _2907 <= _2900;
        2:
            _2907 <= _2901;
        3:
            _2907 <= _2902;
        4:
            _2907 <= _2903;
        5:
            _2907 <= _2904;
        6:
            _2907 <= _2905;
        default:
            _2907 <= _2906;
        endcase
    end
    assign _2898 = pin_out[5:5];
    assign _2895 = _4727 - _2663;
    assign _2896 = { _297,
                     _2895 };
    assign _2897 = _2896 < _2464;
    assign _2908 = _2897 ? _2907 : _2898;
    assign _2890 = _2866[7:7];
    assign _2889 = _2866[6:6];
    assign _2888 = _2866[5:5];
    assign _2887 = _2866[4:4];
    assign _2886 = _2866[3:3];
    assign _2885 = _2866[2:2];
    assign _2884 = _2866[1:1];
    assign _2883 = _2866[0:0];
    always @* begin
        case (_2879)
        0:
            _2891 <= _2883;
        1:
            _2891 <= _2884;
        2:
            _2891 <= _2885;
        3:
            _2891 <= _2886;
        4:
            _2891 <= _2887;
        5:
            _2891 <= _2888;
        6:
            _2891 <= _2889;
        default:
            _2891 <= _2890;
        endcase
    end
    assign _2882 = pin_out[6:6];
    assign _2879 = _4710 - _2663;
    assign _2880 = { _297,
                     _2879 };
    assign _2881 = _2880 < _2464;
    assign _2892 = _2881 ? _2891 : _2882;
    assign _2874 = _2866[7:7];
    assign _2873 = _2866[6:6];
    assign _2872 = _2866[5:5];
    assign _2871 = _2866[4:4];
    assign _2870 = _2866[3:3];
    assign _2869 = _2866[2:2];
    assign _2868 = _2866[1:1];
    assign _2867 = _2866[0:0];
    always @* begin
        case (_2804)
        0:
            _2875 <= _2867;
        1:
            _2875 <= _2868;
        2:
            _2875 <= _2869;
        3:
            _2875 <= _2870;
        4:
            _2875 <= _2871;
        5:
            _2875 <= _2872;
        6:
            _2875 <= _2873;
        default:
            _2875 <= _2874;
        endcase
    end
    assign _2807 = pin_out[7:7];
    assign _2804 = _4552 - _2663;
    assign _2805 = { _297,
                     _2804 };
    assign _2806 = _2805 < _2464;
    assign _2876 = _2806 ? _2875 : _2807;
    assign _2989 = { _2876,
                     _2892,
                     _2908,
                     _2924,
                     _2940,
                     _2956,
                     _2972,
                     _2988 };
    assign _2797 = _2684[7:7];
    assign _2796 = _2684[6:6];
    assign _2795 = _2684[5:5];
    assign _2794 = _2684[4:4];
    assign _2793 = _2684[3:3];
    assign _2792 = _2684[2:2];
    assign _2791 = _2684[1:1];
    assign _2790 = _2684[0:0];
    always @* begin
        case (_2786)
        0:
            _2798 <= _2790;
        1:
            _2798 <= _2791;
        2:
            _2798 <= _2792;
        3:
            _2798 <= _2793;
        4:
            _2798 <= _2794;
        5:
            _2798 <= _2795;
        6:
            _2798 <= _2796;
        default:
            _2798 <= _2797;
        endcase
    end
    assign _2789 = pin_out[0:0];
    assign _2786 = _5137 - _2663;
    assign _2787 = { gnd,
                     _2786 };
    assign _2788 = _2787 < _2666;
    assign _2799 = _2788 ? _2798 : _2789;
    assign _2782 = _2684[7:7];
    assign _2781 = _2684[6:6];
    assign _2780 = _2684[5:5];
    assign _2779 = _2684[4:4];
    assign _2778 = _2684[3:3];
    assign _2777 = _2684[2:2];
    assign _2776 = _2684[1:1];
    assign _2775 = _2684[0:0];
    always @* begin
        case (_2771)
        0:
            _2783 <= _2775;
        1:
            _2783 <= _2776;
        2:
            _2783 <= _2777;
        3:
            _2783 <= _2778;
        4:
            _2783 <= _2779;
        5:
            _2783 <= _2780;
        6:
            _2783 <= _2781;
        default:
            _2783 <= _2782;
        endcase
    end
    assign _2774 = pin_out[1:1];
    assign _2771 = _2395 - _2663;
    assign _2772 = { gnd,
                     _2771 };
    assign _2773 = _2772 < _2666;
    assign _2784 = _2773 ? _2783 : _2774;
    assign _2767 = _2684[7:7];
    assign _2766 = _2684[6:6];
    assign _2765 = _2684[5:5];
    assign _2764 = _2684[4:4];
    assign _2763 = _2684[3:3];
    assign _2762 = _2684[2:2];
    assign _2761 = _2684[1:1];
    assign _2760 = _2684[0:0];
    always @* begin
        case (_2756)
        0:
            _2768 <= _2760;
        1:
            _2768 <= _2761;
        2:
            _2768 <= _2762;
        3:
            _2768 <= _2763;
        4:
            _2768 <= _2764;
        5:
            _2768 <= _2765;
        6:
            _2768 <= _2766;
        default:
            _2768 <= _2767;
        endcase
    end
    assign _2759 = pin_out[2:2];
    assign _2756 = _5102 - _2663;
    assign _2757 = { gnd,
                     _2756 };
    assign _2758 = _2757 < _2666;
    assign _2769 = _2758 ? _2768 : _2759;
    assign _2752 = _2684[7:7];
    assign _2751 = _2684[6:6];
    assign _2750 = _2684[5:5];
    assign _2749 = _2684[4:4];
    assign _2748 = _2684[3:3];
    assign _2747 = _2684[2:2];
    assign _2746 = _2684[1:1];
    assign _2745 = _2684[0:0];
    always @* begin
        case (_2741)
        0:
            _2753 <= _2745;
        1:
            _2753 <= _2746;
        2:
            _2753 <= _2747;
        3:
            _2753 <= _2748;
        4:
            _2753 <= _2749;
        5:
            _2753 <= _2750;
        6:
            _2753 <= _2751;
        default:
            _2753 <= _2752;
        endcase
    end
    assign _2744 = pin_out[3:3];
    assign _2741 = _4761 - _2663;
    assign _2742 = { gnd,
                     _2741 };
    assign _2743 = _2742 < _2666;
    assign _2754 = _2743 ? _2753 : _2744;
    assign _2737 = _2684[7:7];
    assign _2736 = _2684[6:6];
    assign _2735 = _2684[5:5];
    assign _2734 = _2684[4:4];
    assign _2733 = _2684[3:3];
    assign _2732 = _2684[2:2];
    assign _2731 = _2684[1:1];
    assign _2730 = _2684[0:0];
    always @* begin
        case (_2726)
        0:
            _2738 <= _2730;
        1:
            _2738 <= _2731;
        2:
            _2738 <= _2732;
        3:
            _2738 <= _2733;
        4:
            _2738 <= _2734;
        5:
            _2738 <= _2735;
        6:
            _2738 <= _2736;
        default:
            _2738 <= _2737;
        endcase
    end
    assign _2729 = pin_out[4:4];
    assign _2726 = _5182 - _2663;
    assign _2727 = { gnd,
                     _2726 };
    assign _2728 = _2727 < _2666;
    assign _2739 = _2728 ? _2738 : _2729;
    assign _2722 = _2684[7:7];
    assign _2721 = _2684[6:6];
    assign _2720 = _2684[5:5];
    assign _2719 = _2684[4:4];
    assign _2718 = _2684[3:3];
    assign _2717 = _2684[2:2];
    assign _2716 = _2684[1:1];
    assign _2715 = _2684[0:0];
    always @* begin
        case (_2711)
        0:
            _2723 <= _2715;
        1:
            _2723 <= _2716;
        2:
            _2723 <= _2717;
        3:
            _2723 <= _2718;
        4:
            _2723 <= _2719;
        5:
            _2723 <= _2720;
        6:
            _2723 <= _2721;
        default:
            _2723 <= _2722;
        endcase
    end
    assign _2714 = pin_out[5:5];
    assign _2711 = _4727 - _2663;
    assign _2712 = { gnd,
                     _2711 };
    assign _2713 = _2712 < _2666;
    assign _2724 = _2713 ? _2723 : _2714;
    assign _2707 = _2684[7:7];
    assign _2706 = _2684[6:6];
    assign _2705 = _2684[5:5];
    assign _2704 = _2684[4:4];
    assign _2703 = _2684[3:3];
    assign _2702 = _2684[2:2];
    assign _2701 = _2684[1:1];
    assign _2700 = _2684[0:0];
    always @* begin
        case (_2696)
        0:
            _2708 <= _2700;
        1:
            _2708 <= _2701;
        2:
            _2708 <= _2702;
        3:
            _2708 <= _2703;
        4:
            _2708 <= _2704;
        5:
            _2708 <= _2705;
        6:
            _2708 <= _2706;
        default:
            _2708 <= _2707;
        endcase
    end
    assign _2699 = pin_out[6:6];
    assign _2696 = _4710 - _2663;
    assign _2697 = { gnd,
                     _2696 };
    assign _2698 = _2697 < _2666;
    assign _2709 = _2698 ? _2708 : _2699;
    assign _2692 = _2684[7:7];
    assign _2691 = _2684[6:6];
    assign _2690 = _2684[5:5];
    assign _2689 = _2684[4:4];
    assign _2688 = _2684[3:3];
    assign _2687 = _2684[2:2];
    assign _2686 = _2684[1:1];
    assign _2685 = _2684[0:0];
    always @* begin
        case (_2664)
        0:
            _2693 <= _2685;
        1:
            _2693 <= _2686;
        2:
            _2693 <= _2687;
        3:
            _2693 <= _2688;
        4:
            _2693 <= _2689;
        5:
            _2693 <= _2690;
        6:
            _2693 <= _2691;
        default:
            _2693 <= _2692;
        endcase
    end
    assign _2668 = pin_out[7:7];
    assign _2666 = cfg_t0_out_cfg[7:4];
    assign _2492 = _732[7:0];
    assign _2489 = 7'b1000010;
    assign _2490 = _728 == _2489;
    assign _2488 = _722 & _726;
    assign _2491 = _2488 & _2490;
    assign _2493 = _2491 ? _2492 : cfg_t0_out_cfg;
    assign _19 = _2493;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_out_cfg <= _562;
        else
            cfg_t0_out_cfg <= _19;
    end
    assign _2663 = cfg_t0_out_cfg[2:0];
    assign _2664 = _4552 - _2663;
    assign _2665 = { gnd,
                     _2664 };
    assign _2667 = _2665 < _2666;
    assign _2694 = _2667 ? _2693 : _2668;
    assign _2800 = { _2694,
                     _2709,
                     _2724,
                     _2739,
                     _2754,
                     _2769,
                     _2784,
                     _2799 };
    assign _2657 = _2544[7:7];
    assign _2656 = _2544[6:6];
    assign _2655 = _2544[5:5];
    assign _2654 = _2544[4:4];
    assign _2653 = _2544[3:3];
    assign _2652 = _2544[2:2];
    assign _2651 = _2544[1:1];
    assign _2650 = _2544[0:0];
    always @* begin
        case (_2646)
        0:
            _2658 <= _2650;
        1:
            _2658 <= _2651;
        2:
            _2658 <= _2652;
        3:
            _2658 <= _2653;
        4:
            _2658 <= _2654;
        5:
            _2658 <= _2655;
        6:
            _2658 <= _2656;
        default:
            _2658 <= _2657;
        endcase
    end
    assign _2649 = pin_out[0:0];
    assign _2646 = _5137 - _2536;
    assign _2647 = { gnd,
                     _2646 };
    assign _2648 = _2647 < _2539;
    assign _2659 = _2648 ? _2658 : _2649;
    assign _2642 = _2544[7:7];
    assign _2641 = _2544[6:6];
    assign _2640 = _2544[5:5];
    assign _2639 = _2544[4:4];
    assign _2638 = _2544[3:3];
    assign _2637 = _2544[2:2];
    assign _2636 = _2544[1:1];
    assign _2635 = _2544[0:0];
    always @* begin
        case (_2631)
        0:
            _2643 <= _2635;
        1:
            _2643 <= _2636;
        2:
            _2643 <= _2637;
        3:
            _2643 <= _2638;
        4:
            _2643 <= _2639;
        5:
            _2643 <= _2640;
        6:
            _2643 <= _2641;
        default:
            _2643 <= _2642;
        endcase
    end
    assign _2634 = pin_out[1:1];
    assign _2631 = _2395 - _2536;
    assign _2632 = { gnd,
                     _2631 };
    assign _2633 = _2632 < _2539;
    assign _2644 = _2633 ? _2643 : _2634;
    assign _2627 = _2544[7:7];
    assign _2626 = _2544[6:6];
    assign _2625 = _2544[5:5];
    assign _2624 = _2544[4:4];
    assign _2623 = _2544[3:3];
    assign _2622 = _2544[2:2];
    assign _2621 = _2544[1:1];
    assign _2620 = _2544[0:0];
    always @* begin
        case (_2616)
        0:
            _2628 <= _2620;
        1:
            _2628 <= _2621;
        2:
            _2628 <= _2622;
        3:
            _2628 <= _2623;
        4:
            _2628 <= _2624;
        5:
            _2628 <= _2625;
        6:
            _2628 <= _2626;
        default:
            _2628 <= _2627;
        endcase
    end
    assign _2619 = pin_out[2:2];
    assign _2616 = _5102 - _2536;
    assign _2617 = { gnd,
                     _2616 };
    assign _2618 = _2617 < _2539;
    assign _2629 = _2618 ? _2628 : _2619;
    assign _2612 = _2544[7:7];
    assign _2611 = _2544[6:6];
    assign _2610 = _2544[5:5];
    assign _2609 = _2544[4:4];
    assign _2608 = _2544[3:3];
    assign _2607 = _2544[2:2];
    assign _2606 = _2544[1:1];
    assign _2605 = _2544[0:0];
    always @* begin
        case (_2601)
        0:
            _2613 <= _2605;
        1:
            _2613 <= _2606;
        2:
            _2613 <= _2607;
        3:
            _2613 <= _2608;
        4:
            _2613 <= _2609;
        5:
            _2613 <= _2610;
        6:
            _2613 <= _2611;
        default:
            _2613 <= _2612;
        endcase
    end
    assign _2604 = pin_out[3:3];
    assign _2601 = _4761 - _2536;
    assign _2602 = { gnd,
                     _2601 };
    assign _2603 = _2602 < _2539;
    assign _2614 = _2603 ? _2613 : _2604;
    assign _2597 = _2544[7:7];
    assign _2596 = _2544[6:6];
    assign _2595 = _2544[5:5];
    assign _2594 = _2544[4:4];
    assign _2593 = _2544[3:3];
    assign _2592 = _2544[2:2];
    assign _2591 = _2544[1:1];
    assign _2590 = _2544[0:0];
    always @* begin
        case (_2586)
        0:
            _2598 <= _2590;
        1:
            _2598 <= _2591;
        2:
            _2598 <= _2592;
        3:
            _2598 <= _2593;
        4:
            _2598 <= _2594;
        5:
            _2598 <= _2595;
        6:
            _2598 <= _2596;
        default:
            _2598 <= _2597;
        endcase
    end
    assign _2589 = pin_out[4:4];
    assign _2586 = _5182 - _2536;
    assign _2587 = { gnd,
                     _2586 };
    assign _2588 = _2587 < _2539;
    assign _2599 = _2588 ? _2598 : _2589;
    assign _2582 = _2544[7:7];
    assign _2581 = _2544[6:6];
    assign _2580 = _2544[5:5];
    assign _2579 = _2544[4:4];
    assign _2578 = _2544[3:3];
    assign _2577 = _2544[2:2];
    assign _2576 = _2544[1:1];
    assign _2575 = _2544[0:0];
    always @* begin
        case (_2571)
        0:
            _2583 <= _2575;
        1:
            _2583 <= _2576;
        2:
            _2583 <= _2577;
        3:
            _2583 <= _2578;
        4:
            _2583 <= _2579;
        5:
            _2583 <= _2580;
        6:
            _2583 <= _2581;
        default:
            _2583 <= _2582;
        endcase
    end
    assign _2574 = pin_out[5:5];
    assign _2571 = _4727 - _2536;
    assign _2572 = { gnd,
                     _2571 };
    assign _2573 = _2572 < _2539;
    assign _2584 = _2573 ? _2583 : _2574;
    assign _2567 = _2544[7:7];
    assign _2566 = _2544[6:6];
    assign _2565 = _2544[5:5];
    assign _2564 = _2544[4:4];
    assign _2563 = _2544[3:3];
    assign _2562 = _2544[2:2];
    assign _2561 = _2544[1:1];
    assign _2560 = _2544[0:0];
    always @* begin
        case (_2556)
        0:
            _2568 <= _2560;
        1:
            _2568 <= _2561;
        2:
            _2568 <= _2562;
        3:
            _2568 <= _2563;
        4:
            _2568 <= _2564;
        5:
            _2568 <= _2565;
        6:
            _2568 <= _2566;
        default:
            _2568 <= _2567;
        endcase
    end
    assign _2559 = pin_out[6:6];
    assign _2556 = _4710 - _2536;
    assign _2557 = { gnd,
                     _2556 };
    assign _2558 = _2557 < _2539;
    assign _2569 = _2558 ? _2568 : _2559;
    assign _2552 = _2544[7:7];
    assign _2551 = _2544[6:6];
    assign _2550 = _2544[5:5];
    assign _2549 = _2544[4:4];
    assign _2548 = _2544[3:3];
    assign _2547 = _2544[2:2];
    assign _2546 = _2544[1:1];
    assign _2545 = _2544[0:0];
    always @* begin
        case (_2537)
        0:
            _2553 <= _2545;
        1:
            _2553 <= _2546;
        2:
            _2553 <= _2547;
        3:
            _2553 <= _2548;
        4:
            _2553 <= _2549;
        5:
            _2553 <= _2550;
        6:
            _2553 <= _2551;
        default:
            _2553 <= _2552;
        endcase
    end
    assign _2541 = pin_out[7:7];
    assign _2539 = cfg_t0_set_cfg[7:4];
    assign _2498 = _732[7:0];
    assign _2495 = 7'b1000011;
    assign _2496 = _728 == _2495;
    assign _2494 = _722 & _726;
    assign _2497 = _2494 & _2496;
    assign _2499 = _2497 ? _2498 : cfg_t0_set_cfg;
    assign _20 = _2499;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_set_cfg <= _562;
        else
            cfg_t0_set_cfg <= _20;
    end
    assign _2536 = cfg_t0_set_cfg[2:0];
    assign _2537 = _4552 - _2536;
    assign _2538 = { gnd,
                     _2537 };
    assign _2540 = _2538 < _2539;
    assign _2554 = _2540 ? _2553 : _2541;
    assign _2660 = { _2554,
                     _2569,
                     _2584,
                     _2599,
                     _2614,
                     _2629,
                     _2644,
                     _2659 };
    assign _2533 = _2531 == _297;
    assign _2529 = _2299 == _4710;
    assign _2530 = _2417 & _2529;
    assign _2534 = _2530 & _2533;
    assign _2661 = _2534 ? _2660 : pin_out;
    assign _2525 = _2441 == _5102;
    assign _2526 = _2447 & _2525;
    assign _2522 = _2299 == _4727;
    assign _2523 = _2417 & _2522;
    assign _2527 = _2523 & _2526;
    assign _2801 = _2527 ? _2800 : _2661;
    assign _2517 = _2298[8:7];
    assign _2519 = _2517 == _297;
    assign _2515 = _2299 == _4761;
    assign _2516 = _2417 & _2515;
    assign _2520 = _2516 & _2519;
    assign _2990 = _2520 ? _2989 : _2801;
    assign _2991 = _2990[7:7];
    assign _2511 = cfg_t0_sideset[5:4];
    assign _2512 = { _297,
                     _2511 };
    assign _539 = 6'b000000;
    assign _2504 = _732[5:0];
    assign _2501 = 7'b1001100;
    assign _2502 = _728 == _2501;
    assign _2500 = _722 & _726;
    assign _2503 = _2500 & _2502;
    assign _2505 = _2503 ? _2504 : cfg_t0_sideset;
    assign _21 = _2505;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_sideset <= _539;
        else
            cfg_t0_sideset <= _21;
    end
    assign _2507 = cfg_t0_sideset[2:0];
    assign _2508 = _4552 - _2507;
    assign _2509 = { gnd,
                     _2508 };
    assign _2513 = _2509 < _2512;
    assign _3020 = _2513 ? _3019 : _2991;
    assign _3140 = { _3020,
                     _3037,
                     _3054,
                     _3071,
                     _3088,
                     _3105,
                     _3122,
                     _3139 };
    assign _3141 = _754 ? pin_out : _3140;
    assign _3142 = _748 ? pin_out : _3141;
    assign _3143 = _742 ? pin_out : _3142;
    assign _22 = _3143;
    assign _4301 = _4115 == _297;
    assign _4298 = _3177 == _4710;
    assign _4299 = _3271 & _4298;
    assign _4302 = _4299 & _4301;
    assign _4426 = _4302 ? _4425 : _22;
    assign _4294 = _3286 == _5102;
    assign _4295 = _3292 & _4294;
    assign _4291 = _3177 == _4727;
    assign _4292 = _3271 & _4291;
    assign _4296 = _4292 & _4295;
    assign _4550 = _4296 ? _4549 : _4426;
    assign _4286 = _3176[8:7];
    assign _4288 = _4286 == _297;
    assign _4284 = _3177 == _4761;
    assign _4285 = _3271 & _4284;
    assign _4289 = _4285 & _4288;
    assign _4680 = _4289 ? _4679 : _4550;
    assign _4681 = _4680[7:7];
    assign _4281 = { _297,
                     _4241 };
    assign _4277 = cfg_t1_sideset[2:0];
    assign _4278 = _4552 - _4277;
    assign _4279 = { gnd,
                     _4278 };
    assign _4282 = _4279 < _4281;
    assign _4709 = _4282 ? _4708 : _4681;
    assign _4829 = { _4709,
                     _4726,
                     _4743,
                     _4760,
                     _4777,
                     _4794,
                     _4811,
                     _4828 };
    assign _4254 = t1_delay_left - _597;
    assign _4248 = _4246[3:2];
    assign _4249 = { _297,
                     _4248 };
    assign _4243 = _4241[0:0];
    assign _4246 = _4243 ? _633 : _681;
    assign _3148 = _732[5:0];
    assign _3145 = 7'b1011100;
    assign _3146 = _728 == _3145;
    assign _3144 = _722 & _726;
    assign _3147 = _3144 & _3146;
    assign _3149 = _3147 ? _3148 : cfg_t1_sideset;
    assign _23 = _3149;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_sideset <= _539;
        else
            cfg_t1_sideset <= _23;
    end
    assign _4241 = cfg_t1_sideset[5:4];
    assign _4242 = _4241[1:1];
    assign _4250 = _4242 ? _4249 : _4246;
    assign _4240 = _3176[12:9];
    assign _4251 = _4240 & _4250;
    assign _317 = t1_rx_level == _585;
    assign _318 = ~ _317;
    assign _3160 = t1_rx_level == _585;
    assign _3161 = ~ _3160;
    assign _3156 = 7'b1011001;
    assign _3157 = _370 == _3156;
    assign _3153 = _369[7:7];
    assign _3154 = ~ _3153;
    assign _3155 = _3152 & _3154;
    assign _3158 = _3155 & _3157;
    assign _3162 = _3158 & _3161;
    assign _24 = _3162;
    assign _319 = _24 & _318;
    assign _3190 = { _591,
                     _319 };
    assign _240 = ~ _239;
    assign _3184 = ~ _239;
    assign _3182 = ~ _3181;
    assign _3179 = _3177 == _5182;
    assign _3180 = _3175 & _3179;
    assign _3183 = _3180 & _3182;
    assign _3185 = _3183 & _3184;
    assign _25 = _3185;
    assign _241 = _25 & _240;
    assign _3187 = { _591,
                     _241 };
    assign _3188 = t1_rx_level + _3187;
    assign _3191 = _3188 - _3190;
    assign _26 = _3191;
    always @(posedge _99) begin
        if (_97)
            t1_rx_level <= _585;
        else
            t1_rx_level <= _26;
    end
    assign _239 = t1_rx_level == _252;
    assign _3266 = ~ _3181;
    assign _3265 = _3177 == _5182;
    assign _3267 = _3265 & _3266;
    assign _3268 = _3267 & _239;
    assign _3258 = _3177 == _5182;
    assign _3259 = _3258 & _3181;
    assign _3262 = _3259 & _3261;
    assign _3255 = ~ _3254;
    assign _3252 = ~ _3222;
    assign _2295 = _763 == _117;
    assign _2296 = _760 & _2295;
    always @(posedge _99) begin
        if (_97)
            prog_255 <= _356;
        else
            if (_2296)
                prog_255 <= _732;
    end
    assign _2288 = 8'b11111110;
    assign _2289 = _763 == _2288;
    assign _2290 = _760 & _2289;
    always @(posedge _99) begin
        if (_97)
            prog_254 <= _356;
        else
            if (_2290)
                prog_254 <= _732;
    end
    assign _2282 = 8'b11111101;
    assign _2283 = _763 == _2282;
    assign _2284 = _760 & _2283;
    always @(posedge _99) begin
        if (_97)
            prog_253 <= _356;
        else
            if (_2284)
                prog_253 <= _732;
    end
    assign _2276 = 8'b11111100;
    assign _2277 = _763 == _2276;
    assign _2278 = _760 & _2277;
    always @(posedge _99) begin
        if (_97)
            prog_252 <= _356;
        else
            if (_2278)
                prog_252 <= _732;
    end
    assign _2270 = 8'b11111011;
    assign _2271 = _763 == _2270;
    assign _2272 = _760 & _2271;
    always @(posedge _99) begin
        if (_97)
            prog_251 <= _356;
        else
            if (_2272)
                prog_251 <= _732;
    end
    assign _2264 = 8'b11111010;
    assign _2265 = _763 == _2264;
    assign _2266 = _760 & _2265;
    always @(posedge _99) begin
        if (_97)
            prog_250 <= _356;
        else
            if (_2266)
                prog_250 <= _732;
    end
    assign _2258 = 8'b11111001;
    assign _2259 = _763 == _2258;
    assign _2260 = _760 & _2259;
    always @(posedge _99) begin
        if (_97)
            prog_249 <= _356;
        else
            if (_2260)
                prog_249 <= _732;
    end
    assign _2252 = 8'b11111000;
    assign _2253 = _763 == _2252;
    assign _2254 = _760 & _2253;
    always @(posedge _99) begin
        if (_97)
            prog_248 <= _356;
        else
            if (_2254)
                prog_248 <= _732;
    end
    assign _2246 = 8'b11110111;
    assign _2247 = _763 == _2246;
    assign _2248 = _760 & _2247;
    always @(posedge _99) begin
        if (_97)
            prog_247 <= _356;
        else
            if (_2248)
                prog_247 <= _732;
    end
    assign _2240 = 8'b11110110;
    assign _2241 = _763 == _2240;
    assign _2242 = _760 & _2241;
    always @(posedge _99) begin
        if (_97)
            prog_246 <= _356;
        else
            if (_2242)
                prog_246 <= _732;
    end
    assign _2234 = 8'b11110101;
    assign _2235 = _763 == _2234;
    assign _2236 = _760 & _2235;
    always @(posedge _99) begin
        if (_97)
            prog_245 <= _356;
        else
            if (_2236)
                prog_245 <= _732;
    end
    assign _2228 = 8'b11110100;
    assign _2229 = _763 == _2228;
    assign _2230 = _760 & _2229;
    always @(posedge _99) begin
        if (_97)
            prog_244 <= _356;
        else
            if (_2230)
                prog_244 <= _732;
    end
    assign _2222 = 8'b11110011;
    assign _2223 = _763 == _2222;
    assign _2224 = _760 & _2223;
    always @(posedge _99) begin
        if (_97)
            prog_243 <= _356;
        else
            if (_2224)
                prog_243 <= _732;
    end
    assign _2216 = 8'b11110010;
    assign _2217 = _763 == _2216;
    assign _2218 = _760 & _2217;
    always @(posedge _99) begin
        if (_97)
            prog_242 <= _356;
        else
            if (_2218)
                prog_242 <= _732;
    end
    assign _2210 = 8'b11110001;
    assign _2211 = _763 == _2210;
    assign _2212 = _760 & _2211;
    always @(posedge _99) begin
        if (_97)
            prog_241 <= _356;
        else
            if (_2212)
                prog_241 <= _732;
    end
    assign _2204 = 8'b11110000;
    assign _2205 = _763 == _2204;
    assign _2206 = _760 & _2205;
    always @(posedge _99) begin
        if (_97)
            prog_240 <= _356;
        else
            if (_2206)
                prog_240 <= _732;
    end
    assign _2198 = 8'b11101111;
    assign _2199 = _763 == _2198;
    assign _2200 = _760 & _2199;
    always @(posedge _99) begin
        if (_97)
            prog_239 <= _356;
        else
            if (_2200)
                prog_239 <= _732;
    end
    assign _2192 = 8'b11101110;
    assign _2193 = _763 == _2192;
    assign _2194 = _760 & _2193;
    always @(posedge _99) begin
        if (_97)
            prog_238 <= _356;
        else
            if (_2194)
                prog_238 <= _732;
    end
    assign _2186 = 8'b11101101;
    assign _2187 = _763 == _2186;
    assign _2188 = _760 & _2187;
    always @(posedge _99) begin
        if (_97)
            prog_237 <= _356;
        else
            if (_2188)
                prog_237 <= _732;
    end
    assign _2180 = 8'b11101100;
    assign _2181 = _763 == _2180;
    assign _2182 = _760 & _2181;
    always @(posedge _99) begin
        if (_97)
            prog_236 <= _356;
        else
            if (_2182)
                prog_236 <= _732;
    end
    assign _2174 = 8'b11101011;
    assign _2175 = _763 == _2174;
    assign _2176 = _760 & _2175;
    always @(posedge _99) begin
        if (_97)
            prog_235 <= _356;
        else
            if (_2176)
                prog_235 <= _732;
    end
    assign _2168 = 8'b11101010;
    assign _2169 = _763 == _2168;
    assign _2170 = _760 & _2169;
    always @(posedge _99) begin
        if (_97)
            prog_234 <= _356;
        else
            if (_2170)
                prog_234 <= _732;
    end
    assign _2162 = 8'b11101001;
    assign _2163 = _763 == _2162;
    assign _2164 = _760 & _2163;
    always @(posedge _99) begin
        if (_97)
            prog_233 <= _356;
        else
            if (_2164)
                prog_233 <= _732;
    end
    assign _2156 = 8'b11101000;
    assign _2157 = _763 == _2156;
    assign _2158 = _760 & _2157;
    always @(posedge _99) begin
        if (_97)
            prog_232 <= _356;
        else
            if (_2158)
                prog_232 <= _732;
    end
    assign _2150 = 8'b11100111;
    assign _2151 = _763 == _2150;
    assign _2152 = _760 & _2151;
    always @(posedge _99) begin
        if (_97)
            prog_231 <= _356;
        else
            if (_2152)
                prog_231 <= _732;
    end
    assign _2144 = 8'b11100110;
    assign _2145 = _763 == _2144;
    assign _2146 = _760 & _2145;
    always @(posedge _99) begin
        if (_97)
            prog_230 <= _356;
        else
            if (_2146)
                prog_230 <= _732;
    end
    assign _2138 = 8'b11100101;
    assign _2139 = _763 == _2138;
    assign _2140 = _760 & _2139;
    always @(posedge _99) begin
        if (_97)
            prog_229 <= _356;
        else
            if (_2140)
                prog_229 <= _732;
    end
    assign _2132 = 8'b11100100;
    assign _2133 = _763 == _2132;
    assign _2134 = _760 & _2133;
    always @(posedge _99) begin
        if (_97)
            prog_228 <= _356;
        else
            if (_2134)
                prog_228 <= _732;
    end
    assign _2126 = 8'b11100011;
    assign _2127 = _763 == _2126;
    assign _2128 = _760 & _2127;
    always @(posedge _99) begin
        if (_97)
            prog_227 <= _356;
        else
            if (_2128)
                prog_227 <= _732;
    end
    assign _2120 = 8'b11100010;
    assign _2121 = _763 == _2120;
    assign _2122 = _760 & _2121;
    always @(posedge _99) begin
        if (_97)
            prog_226 <= _356;
        else
            if (_2122)
                prog_226 <= _732;
    end
    assign _2114 = 8'b11100001;
    assign _2115 = _763 == _2114;
    assign _2116 = _760 & _2115;
    always @(posedge _99) begin
        if (_97)
            prog_225 <= _356;
        else
            if (_2116)
                prog_225 <= _732;
    end
    assign _2108 = 8'b11100000;
    assign _2109 = _763 == _2108;
    assign _2110 = _760 & _2109;
    always @(posedge _99) begin
        if (_97)
            prog_224 <= _356;
        else
            if (_2110)
                prog_224 <= _732;
    end
    assign _2102 = 8'b11011111;
    assign _2103 = _763 == _2102;
    assign _2104 = _760 & _2103;
    always @(posedge _99) begin
        if (_97)
            prog_223 <= _356;
        else
            if (_2104)
                prog_223 <= _732;
    end
    assign _2096 = 8'b11011110;
    assign _2097 = _763 == _2096;
    assign _2098 = _760 & _2097;
    always @(posedge _99) begin
        if (_97)
            prog_222 <= _356;
        else
            if (_2098)
                prog_222 <= _732;
    end
    assign _2090 = 8'b11011101;
    assign _2091 = _763 == _2090;
    assign _2092 = _760 & _2091;
    always @(posedge _99) begin
        if (_97)
            prog_221 <= _356;
        else
            if (_2092)
                prog_221 <= _732;
    end
    assign _2084 = 8'b11011100;
    assign _2085 = _763 == _2084;
    assign _2086 = _760 & _2085;
    always @(posedge _99) begin
        if (_97)
            prog_220 <= _356;
        else
            if (_2086)
                prog_220 <= _732;
    end
    assign _2078 = 8'b11011011;
    assign _2079 = _763 == _2078;
    assign _2080 = _760 & _2079;
    always @(posedge _99) begin
        if (_97)
            prog_219 <= _356;
        else
            if (_2080)
                prog_219 <= _732;
    end
    assign _2072 = 8'b11011010;
    assign _2073 = _763 == _2072;
    assign _2074 = _760 & _2073;
    always @(posedge _99) begin
        if (_97)
            prog_218 <= _356;
        else
            if (_2074)
                prog_218 <= _732;
    end
    assign _2066 = 8'b11011001;
    assign _2067 = _763 == _2066;
    assign _2068 = _760 & _2067;
    always @(posedge _99) begin
        if (_97)
            prog_217 <= _356;
        else
            if (_2068)
                prog_217 <= _732;
    end
    assign _2060 = 8'b11011000;
    assign _2061 = _763 == _2060;
    assign _2062 = _760 & _2061;
    always @(posedge _99) begin
        if (_97)
            prog_216 <= _356;
        else
            if (_2062)
                prog_216 <= _732;
    end
    assign _2054 = 8'b11010111;
    assign _2055 = _763 == _2054;
    assign _2056 = _760 & _2055;
    always @(posedge _99) begin
        if (_97)
            prog_215 <= _356;
        else
            if (_2056)
                prog_215 <= _732;
    end
    assign _2048 = 8'b11010110;
    assign _2049 = _763 == _2048;
    assign _2050 = _760 & _2049;
    always @(posedge _99) begin
        if (_97)
            prog_214 <= _356;
        else
            if (_2050)
                prog_214 <= _732;
    end
    assign _2042 = 8'b11010101;
    assign _2043 = _763 == _2042;
    assign _2044 = _760 & _2043;
    always @(posedge _99) begin
        if (_97)
            prog_213 <= _356;
        else
            if (_2044)
                prog_213 <= _732;
    end
    assign _2036 = 8'b11010100;
    assign _2037 = _763 == _2036;
    assign _2038 = _760 & _2037;
    always @(posedge _99) begin
        if (_97)
            prog_212 <= _356;
        else
            if (_2038)
                prog_212 <= _732;
    end
    assign _2030 = 8'b11010011;
    assign _2031 = _763 == _2030;
    assign _2032 = _760 & _2031;
    always @(posedge _99) begin
        if (_97)
            prog_211 <= _356;
        else
            if (_2032)
                prog_211 <= _732;
    end
    assign _2024 = 8'b11010010;
    assign _2025 = _763 == _2024;
    assign _2026 = _760 & _2025;
    always @(posedge _99) begin
        if (_97)
            prog_210 <= _356;
        else
            if (_2026)
                prog_210 <= _732;
    end
    assign _2018 = 8'b11010001;
    assign _2019 = _763 == _2018;
    assign _2020 = _760 & _2019;
    always @(posedge _99) begin
        if (_97)
            prog_209 <= _356;
        else
            if (_2020)
                prog_209 <= _732;
    end
    assign _2012 = 8'b11010000;
    assign _2013 = _763 == _2012;
    assign _2014 = _760 & _2013;
    always @(posedge _99) begin
        if (_97)
            prog_208 <= _356;
        else
            if (_2014)
                prog_208 <= _732;
    end
    assign _2006 = 8'b11001111;
    assign _2007 = _763 == _2006;
    assign _2008 = _760 & _2007;
    always @(posedge _99) begin
        if (_97)
            prog_207 <= _356;
        else
            if (_2008)
                prog_207 <= _732;
    end
    assign _2000 = 8'b11001110;
    assign _2001 = _763 == _2000;
    assign _2002 = _760 & _2001;
    always @(posedge _99) begin
        if (_97)
            prog_206 <= _356;
        else
            if (_2002)
                prog_206 <= _732;
    end
    assign _1994 = 8'b11001101;
    assign _1995 = _763 == _1994;
    assign _1996 = _760 & _1995;
    always @(posedge _99) begin
        if (_97)
            prog_205 <= _356;
        else
            if (_1996)
                prog_205 <= _732;
    end
    assign _1988 = 8'b11001100;
    assign _1989 = _763 == _1988;
    assign _1990 = _760 & _1989;
    always @(posedge _99) begin
        if (_97)
            prog_204 <= _356;
        else
            if (_1990)
                prog_204 <= _732;
    end
    assign _1982 = 8'b11001011;
    assign _1983 = _763 == _1982;
    assign _1984 = _760 & _1983;
    always @(posedge _99) begin
        if (_97)
            prog_203 <= _356;
        else
            if (_1984)
                prog_203 <= _732;
    end
    assign _1976 = 8'b11001010;
    assign _1977 = _763 == _1976;
    assign _1978 = _760 & _1977;
    always @(posedge _99) begin
        if (_97)
            prog_202 <= _356;
        else
            if (_1978)
                prog_202 <= _732;
    end
    assign _1970 = 8'b11001001;
    assign _1971 = _763 == _1970;
    assign _1972 = _760 & _1971;
    always @(posedge _99) begin
        if (_97)
            prog_201 <= _356;
        else
            if (_1972)
                prog_201 <= _732;
    end
    assign _1964 = 8'b11001000;
    assign _1965 = _763 == _1964;
    assign _1966 = _760 & _1965;
    always @(posedge _99) begin
        if (_97)
            prog_200 <= _356;
        else
            if (_1966)
                prog_200 <= _732;
    end
    assign _1958 = 8'b11000111;
    assign _1959 = _763 == _1958;
    assign _1960 = _760 & _1959;
    always @(posedge _99) begin
        if (_97)
            prog_199 <= _356;
        else
            if (_1960)
                prog_199 <= _732;
    end
    assign _1952 = 8'b11000110;
    assign _1953 = _763 == _1952;
    assign _1954 = _760 & _1953;
    always @(posedge _99) begin
        if (_97)
            prog_198 <= _356;
        else
            if (_1954)
                prog_198 <= _732;
    end
    assign _1946 = 8'b11000101;
    assign _1947 = _763 == _1946;
    assign _1948 = _760 & _1947;
    always @(posedge _99) begin
        if (_97)
            prog_197 <= _356;
        else
            if (_1948)
                prog_197 <= _732;
    end
    assign _1940 = 8'b11000100;
    assign _1941 = _763 == _1940;
    assign _1942 = _760 & _1941;
    always @(posedge _99) begin
        if (_97)
            prog_196 <= _356;
        else
            if (_1942)
                prog_196 <= _732;
    end
    assign _1934 = 8'b11000011;
    assign _1935 = _763 == _1934;
    assign _1936 = _760 & _1935;
    always @(posedge _99) begin
        if (_97)
            prog_195 <= _356;
        else
            if (_1936)
                prog_195 <= _732;
    end
    assign _1928 = 8'b11000010;
    assign _1929 = _763 == _1928;
    assign _1930 = _760 & _1929;
    always @(posedge _99) begin
        if (_97)
            prog_194 <= _356;
        else
            if (_1930)
                prog_194 <= _732;
    end
    assign _1922 = 8'b11000001;
    assign _1923 = _763 == _1922;
    assign _1924 = _760 & _1923;
    always @(posedge _99) begin
        if (_97)
            prog_193 <= _356;
        else
            if (_1924)
                prog_193 <= _732;
    end
    assign _1916 = 8'b11000000;
    assign _1917 = _763 == _1916;
    assign _1918 = _760 & _1917;
    always @(posedge _99) begin
        if (_97)
            prog_192 <= _356;
        else
            if (_1918)
                prog_192 <= _732;
    end
    assign _1910 = 8'b10111111;
    assign _1911 = _763 == _1910;
    assign _1912 = _760 & _1911;
    always @(posedge _99) begin
        if (_97)
            prog_191 <= _356;
        else
            if (_1912)
                prog_191 <= _732;
    end
    assign _1904 = 8'b10111110;
    assign _1905 = _763 == _1904;
    assign _1906 = _760 & _1905;
    always @(posedge _99) begin
        if (_97)
            prog_190 <= _356;
        else
            if (_1906)
                prog_190 <= _732;
    end
    assign _1898 = 8'b10111101;
    assign _1899 = _763 == _1898;
    assign _1900 = _760 & _1899;
    always @(posedge _99) begin
        if (_97)
            prog_189 <= _356;
        else
            if (_1900)
                prog_189 <= _732;
    end
    assign _1892 = 8'b10111100;
    assign _1893 = _763 == _1892;
    assign _1894 = _760 & _1893;
    always @(posedge _99) begin
        if (_97)
            prog_188 <= _356;
        else
            if (_1894)
                prog_188 <= _732;
    end
    assign _1886 = 8'b10111011;
    assign _1887 = _763 == _1886;
    assign _1888 = _760 & _1887;
    always @(posedge _99) begin
        if (_97)
            prog_187 <= _356;
        else
            if (_1888)
                prog_187 <= _732;
    end
    assign _1880 = 8'b10111010;
    assign _1881 = _763 == _1880;
    assign _1882 = _760 & _1881;
    always @(posedge _99) begin
        if (_97)
            prog_186 <= _356;
        else
            if (_1882)
                prog_186 <= _732;
    end
    assign _1874 = 8'b10111001;
    assign _1875 = _763 == _1874;
    assign _1876 = _760 & _1875;
    always @(posedge _99) begin
        if (_97)
            prog_185 <= _356;
        else
            if (_1876)
                prog_185 <= _732;
    end
    assign _1868 = 8'b10111000;
    assign _1869 = _763 == _1868;
    assign _1870 = _760 & _1869;
    always @(posedge _99) begin
        if (_97)
            prog_184 <= _356;
        else
            if (_1870)
                prog_184 <= _732;
    end
    assign _1862 = 8'b10110111;
    assign _1863 = _763 == _1862;
    assign _1864 = _760 & _1863;
    always @(posedge _99) begin
        if (_97)
            prog_183 <= _356;
        else
            if (_1864)
                prog_183 <= _732;
    end
    assign _1856 = 8'b10110110;
    assign _1857 = _763 == _1856;
    assign _1858 = _760 & _1857;
    always @(posedge _99) begin
        if (_97)
            prog_182 <= _356;
        else
            if (_1858)
                prog_182 <= _732;
    end
    assign _1850 = 8'b10110101;
    assign _1851 = _763 == _1850;
    assign _1852 = _760 & _1851;
    always @(posedge _99) begin
        if (_97)
            prog_181 <= _356;
        else
            if (_1852)
                prog_181 <= _732;
    end
    assign _1844 = 8'b10110100;
    assign _1845 = _763 == _1844;
    assign _1846 = _760 & _1845;
    always @(posedge _99) begin
        if (_97)
            prog_180 <= _356;
        else
            if (_1846)
                prog_180 <= _732;
    end
    assign _1838 = 8'b10110011;
    assign _1839 = _763 == _1838;
    assign _1840 = _760 & _1839;
    always @(posedge _99) begin
        if (_97)
            prog_179 <= _356;
        else
            if (_1840)
                prog_179 <= _732;
    end
    assign _1832 = 8'b10110010;
    assign _1833 = _763 == _1832;
    assign _1834 = _760 & _1833;
    always @(posedge _99) begin
        if (_97)
            prog_178 <= _356;
        else
            if (_1834)
                prog_178 <= _732;
    end
    assign _1826 = 8'b10110001;
    assign _1827 = _763 == _1826;
    assign _1828 = _760 & _1827;
    always @(posedge _99) begin
        if (_97)
            prog_177 <= _356;
        else
            if (_1828)
                prog_177 <= _732;
    end
    assign _1820 = 8'b10110000;
    assign _1821 = _763 == _1820;
    assign _1822 = _760 & _1821;
    always @(posedge _99) begin
        if (_97)
            prog_176 <= _356;
        else
            if (_1822)
                prog_176 <= _732;
    end
    assign _1814 = 8'b10101111;
    assign _1815 = _763 == _1814;
    assign _1816 = _760 & _1815;
    always @(posedge _99) begin
        if (_97)
            prog_175 <= _356;
        else
            if (_1816)
                prog_175 <= _732;
    end
    assign _1808 = 8'b10101110;
    assign _1809 = _763 == _1808;
    assign _1810 = _760 & _1809;
    always @(posedge _99) begin
        if (_97)
            prog_174 <= _356;
        else
            if (_1810)
                prog_174 <= _732;
    end
    assign _1802 = 8'b10101101;
    assign _1803 = _763 == _1802;
    assign _1804 = _760 & _1803;
    always @(posedge _99) begin
        if (_97)
            prog_173 <= _356;
        else
            if (_1804)
                prog_173 <= _732;
    end
    assign _1796 = 8'b10101100;
    assign _1797 = _763 == _1796;
    assign _1798 = _760 & _1797;
    always @(posedge _99) begin
        if (_97)
            prog_172 <= _356;
        else
            if (_1798)
                prog_172 <= _732;
    end
    assign _1790 = 8'b10101011;
    assign _1791 = _763 == _1790;
    assign _1792 = _760 & _1791;
    always @(posedge _99) begin
        if (_97)
            prog_171 <= _356;
        else
            if (_1792)
                prog_171 <= _732;
    end
    assign _1784 = 8'b10101010;
    assign _1785 = _763 == _1784;
    assign _1786 = _760 & _1785;
    always @(posedge _99) begin
        if (_97)
            prog_170 <= _356;
        else
            if (_1786)
                prog_170 <= _732;
    end
    assign _1778 = 8'b10101001;
    assign _1779 = _763 == _1778;
    assign _1780 = _760 & _1779;
    always @(posedge _99) begin
        if (_97)
            prog_169 <= _356;
        else
            if (_1780)
                prog_169 <= _732;
    end
    assign _1772 = 8'b10101000;
    assign _1773 = _763 == _1772;
    assign _1774 = _760 & _1773;
    always @(posedge _99) begin
        if (_97)
            prog_168 <= _356;
        else
            if (_1774)
                prog_168 <= _732;
    end
    assign _1766 = 8'b10100111;
    assign _1767 = _763 == _1766;
    assign _1768 = _760 & _1767;
    always @(posedge _99) begin
        if (_97)
            prog_167 <= _356;
        else
            if (_1768)
                prog_167 <= _732;
    end
    assign _1760 = 8'b10100110;
    assign _1761 = _763 == _1760;
    assign _1762 = _760 & _1761;
    always @(posedge _99) begin
        if (_97)
            prog_166 <= _356;
        else
            if (_1762)
                prog_166 <= _732;
    end
    assign _1754 = 8'b10100101;
    assign _1755 = _763 == _1754;
    assign _1756 = _760 & _1755;
    always @(posedge _99) begin
        if (_97)
            prog_165 <= _356;
        else
            if (_1756)
                prog_165 <= _732;
    end
    assign _1748 = 8'b10100100;
    assign _1749 = _763 == _1748;
    assign _1750 = _760 & _1749;
    always @(posedge _99) begin
        if (_97)
            prog_164 <= _356;
        else
            if (_1750)
                prog_164 <= _732;
    end
    assign _1742 = 8'b10100011;
    assign _1743 = _763 == _1742;
    assign _1744 = _760 & _1743;
    always @(posedge _99) begin
        if (_97)
            prog_163 <= _356;
        else
            if (_1744)
                prog_163 <= _732;
    end
    assign _1736 = 8'b10100010;
    assign _1737 = _763 == _1736;
    assign _1738 = _760 & _1737;
    always @(posedge _99) begin
        if (_97)
            prog_162 <= _356;
        else
            if (_1738)
                prog_162 <= _732;
    end
    assign _1730 = 8'b10100001;
    assign _1731 = _763 == _1730;
    assign _1732 = _760 & _1731;
    always @(posedge _99) begin
        if (_97)
            prog_161 <= _356;
        else
            if (_1732)
                prog_161 <= _732;
    end
    assign _1724 = 8'b10100000;
    assign _1725 = _763 == _1724;
    assign _1726 = _760 & _1725;
    always @(posedge _99) begin
        if (_97)
            prog_160 <= _356;
        else
            if (_1726)
                prog_160 <= _732;
    end
    assign _1718 = 8'b10011111;
    assign _1719 = _763 == _1718;
    assign _1720 = _760 & _1719;
    always @(posedge _99) begin
        if (_97)
            prog_159 <= _356;
        else
            if (_1720)
                prog_159 <= _732;
    end
    assign _1712 = 8'b10011110;
    assign _1713 = _763 == _1712;
    assign _1714 = _760 & _1713;
    always @(posedge _99) begin
        if (_97)
            prog_158 <= _356;
        else
            if (_1714)
                prog_158 <= _732;
    end
    assign _1706 = 8'b10011101;
    assign _1707 = _763 == _1706;
    assign _1708 = _760 & _1707;
    always @(posedge _99) begin
        if (_97)
            prog_157 <= _356;
        else
            if (_1708)
                prog_157 <= _732;
    end
    assign _1700 = 8'b10011100;
    assign _1701 = _763 == _1700;
    assign _1702 = _760 & _1701;
    always @(posedge _99) begin
        if (_97)
            prog_156 <= _356;
        else
            if (_1702)
                prog_156 <= _732;
    end
    assign _1694 = 8'b10011011;
    assign _1695 = _763 == _1694;
    assign _1696 = _760 & _1695;
    always @(posedge _99) begin
        if (_97)
            prog_155 <= _356;
        else
            if (_1696)
                prog_155 <= _732;
    end
    assign _1688 = 8'b10011010;
    assign _1689 = _763 == _1688;
    assign _1690 = _760 & _1689;
    always @(posedge _99) begin
        if (_97)
            prog_154 <= _356;
        else
            if (_1690)
                prog_154 <= _732;
    end
    assign _1682 = 8'b10011001;
    assign _1683 = _763 == _1682;
    assign _1684 = _760 & _1683;
    always @(posedge _99) begin
        if (_97)
            prog_153 <= _356;
        else
            if (_1684)
                prog_153 <= _732;
    end
    assign _1676 = 8'b10011000;
    assign _1677 = _763 == _1676;
    assign _1678 = _760 & _1677;
    always @(posedge _99) begin
        if (_97)
            prog_152 <= _356;
        else
            if (_1678)
                prog_152 <= _732;
    end
    assign _1670 = 8'b10010111;
    assign _1671 = _763 == _1670;
    assign _1672 = _760 & _1671;
    always @(posedge _99) begin
        if (_97)
            prog_151 <= _356;
        else
            if (_1672)
                prog_151 <= _732;
    end
    assign _1664 = 8'b10010110;
    assign _1665 = _763 == _1664;
    assign _1666 = _760 & _1665;
    always @(posedge _99) begin
        if (_97)
            prog_150 <= _356;
        else
            if (_1666)
                prog_150 <= _732;
    end
    assign _1658 = 8'b10010101;
    assign _1659 = _763 == _1658;
    assign _1660 = _760 & _1659;
    always @(posedge _99) begin
        if (_97)
            prog_149 <= _356;
        else
            if (_1660)
                prog_149 <= _732;
    end
    assign _1652 = 8'b10010100;
    assign _1653 = _763 == _1652;
    assign _1654 = _760 & _1653;
    always @(posedge _99) begin
        if (_97)
            prog_148 <= _356;
        else
            if (_1654)
                prog_148 <= _732;
    end
    assign _1646 = 8'b10010011;
    assign _1647 = _763 == _1646;
    assign _1648 = _760 & _1647;
    always @(posedge _99) begin
        if (_97)
            prog_147 <= _356;
        else
            if (_1648)
                prog_147 <= _732;
    end
    assign _1640 = 8'b10010010;
    assign _1641 = _763 == _1640;
    assign _1642 = _760 & _1641;
    always @(posedge _99) begin
        if (_97)
            prog_146 <= _356;
        else
            if (_1642)
                prog_146 <= _732;
    end
    assign _1634 = 8'b10010001;
    assign _1635 = _763 == _1634;
    assign _1636 = _760 & _1635;
    always @(posedge _99) begin
        if (_97)
            prog_145 <= _356;
        else
            if (_1636)
                prog_145 <= _732;
    end
    assign _1628 = 8'b10010000;
    assign _1629 = _763 == _1628;
    assign _1630 = _760 & _1629;
    always @(posedge _99) begin
        if (_97)
            prog_144 <= _356;
        else
            if (_1630)
                prog_144 <= _732;
    end
    assign _1622 = 8'b10001111;
    assign _1623 = _763 == _1622;
    assign _1624 = _760 & _1623;
    always @(posedge _99) begin
        if (_97)
            prog_143 <= _356;
        else
            if (_1624)
                prog_143 <= _732;
    end
    assign _1616 = 8'b10001110;
    assign _1617 = _763 == _1616;
    assign _1618 = _760 & _1617;
    always @(posedge _99) begin
        if (_97)
            prog_142 <= _356;
        else
            if (_1618)
                prog_142 <= _732;
    end
    assign _1610 = 8'b10001101;
    assign _1611 = _763 == _1610;
    assign _1612 = _760 & _1611;
    always @(posedge _99) begin
        if (_97)
            prog_141 <= _356;
        else
            if (_1612)
                prog_141 <= _732;
    end
    assign _1604 = 8'b10001100;
    assign _1605 = _763 == _1604;
    assign _1606 = _760 & _1605;
    always @(posedge _99) begin
        if (_97)
            prog_140 <= _356;
        else
            if (_1606)
                prog_140 <= _732;
    end
    assign _1598 = 8'b10001011;
    assign _1599 = _763 == _1598;
    assign _1600 = _760 & _1599;
    always @(posedge _99) begin
        if (_97)
            prog_139 <= _356;
        else
            if (_1600)
                prog_139 <= _732;
    end
    assign _1592 = 8'b10001010;
    assign _1593 = _763 == _1592;
    assign _1594 = _760 & _1593;
    always @(posedge _99) begin
        if (_97)
            prog_138 <= _356;
        else
            if (_1594)
                prog_138 <= _732;
    end
    assign _1586 = 8'b10001001;
    assign _1587 = _763 == _1586;
    assign _1588 = _760 & _1587;
    always @(posedge _99) begin
        if (_97)
            prog_137 <= _356;
        else
            if (_1588)
                prog_137 <= _732;
    end
    assign _1580 = 8'b10001000;
    assign _1581 = _763 == _1580;
    assign _1582 = _760 & _1581;
    always @(posedge _99) begin
        if (_97)
            prog_136 <= _356;
        else
            if (_1582)
                prog_136 <= _732;
    end
    assign _1574 = 8'b10000111;
    assign _1575 = _763 == _1574;
    assign _1576 = _760 & _1575;
    always @(posedge _99) begin
        if (_97)
            prog_135 <= _356;
        else
            if (_1576)
                prog_135 <= _732;
    end
    assign _1568 = 8'b10000110;
    assign _1569 = _763 == _1568;
    assign _1570 = _760 & _1569;
    always @(posedge _99) begin
        if (_97)
            prog_134 <= _356;
        else
            if (_1570)
                prog_134 <= _732;
    end
    assign _1562 = 8'b10000101;
    assign _1563 = _763 == _1562;
    assign _1564 = _760 & _1563;
    always @(posedge _99) begin
        if (_97)
            prog_133 <= _356;
        else
            if (_1564)
                prog_133 <= _732;
    end
    assign _1556 = 8'b10000100;
    assign _1557 = _763 == _1556;
    assign _1558 = _760 & _1557;
    always @(posedge _99) begin
        if (_97)
            prog_132 <= _356;
        else
            if (_1558)
                prog_132 <= _732;
    end
    assign _1550 = 8'b10000011;
    assign _1551 = _763 == _1550;
    assign _1552 = _760 & _1551;
    always @(posedge _99) begin
        if (_97)
            prog_131 <= _356;
        else
            if (_1552)
                prog_131 <= _732;
    end
    assign _1544 = 8'b10000010;
    assign _1545 = _763 == _1544;
    assign _1546 = _760 & _1545;
    always @(posedge _99) begin
        if (_97)
            prog_130 <= _356;
        else
            if (_1546)
                prog_130 <= _732;
    end
    assign _1538 = 8'b10000001;
    assign _1539 = _763 == _1538;
    assign _1540 = _760 & _1539;
    always @(posedge _99) begin
        if (_97)
            prog_129 <= _356;
        else
            if (_1540)
                prog_129 <= _732;
    end
    assign _1532 = 8'b10000000;
    assign _1533 = _763 == _1532;
    assign _1534 = _760 & _1533;
    always @(posedge _99) begin
        if (_97)
            prog_128 <= _356;
        else
            if (_1534)
                prog_128 <= _732;
    end
    assign _1526 = 8'b01111111;
    assign _1527 = _763 == _1526;
    assign _1528 = _760 & _1527;
    always @(posedge _99) begin
        if (_97)
            prog_127 <= _356;
        else
            if (_1528)
                prog_127 <= _732;
    end
    assign _1520 = 8'b01111110;
    assign _1521 = _763 == _1520;
    assign _1522 = _760 & _1521;
    always @(posedge _99) begin
        if (_97)
            prog_126 <= _356;
        else
            if (_1522)
                prog_126 <= _732;
    end
    assign _1514 = 8'b01111101;
    assign _1515 = _763 == _1514;
    assign _1516 = _760 & _1515;
    always @(posedge _99) begin
        if (_97)
            prog_125 <= _356;
        else
            if (_1516)
                prog_125 <= _732;
    end
    assign _1508 = 8'b01111100;
    assign _1509 = _763 == _1508;
    assign _1510 = _760 & _1509;
    always @(posedge _99) begin
        if (_97)
            prog_124 <= _356;
        else
            if (_1510)
                prog_124 <= _732;
    end
    assign _1502 = 8'b01111011;
    assign _1503 = _763 == _1502;
    assign _1504 = _760 & _1503;
    always @(posedge _99) begin
        if (_97)
            prog_123 <= _356;
        else
            if (_1504)
                prog_123 <= _732;
    end
    assign _1496 = 8'b01111010;
    assign _1497 = _763 == _1496;
    assign _1498 = _760 & _1497;
    always @(posedge _99) begin
        if (_97)
            prog_122 <= _356;
        else
            if (_1498)
                prog_122 <= _732;
    end
    assign _1490 = 8'b01111001;
    assign _1491 = _763 == _1490;
    assign _1492 = _760 & _1491;
    always @(posedge _99) begin
        if (_97)
            prog_121 <= _356;
        else
            if (_1492)
                prog_121 <= _732;
    end
    assign _1484 = 8'b01111000;
    assign _1485 = _763 == _1484;
    assign _1486 = _760 & _1485;
    always @(posedge _99) begin
        if (_97)
            prog_120 <= _356;
        else
            if (_1486)
                prog_120 <= _732;
    end
    assign _1478 = 8'b01110111;
    assign _1479 = _763 == _1478;
    assign _1480 = _760 & _1479;
    always @(posedge _99) begin
        if (_97)
            prog_119 <= _356;
        else
            if (_1480)
                prog_119 <= _732;
    end
    assign _1472 = 8'b01110110;
    assign _1473 = _763 == _1472;
    assign _1474 = _760 & _1473;
    always @(posedge _99) begin
        if (_97)
            prog_118 <= _356;
        else
            if (_1474)
                prog_118 <= _732;
    end
    assign _1466 = 8'b01110101;
    assign _1467 = _763 == _1466;
    assign _1468 = _760 & _1467;
    always @(posedge _99) begin
        if (_97)
            prog_117 <= _356;
        else
            if (_1468)
                prog_117 <= _732;
    end
    assign _1460 = 8'b01110100;
    assign _1461 = _763 == _1460;
    assign _1462 = _760 & _1461;
    always @(posedge _99) begin
        if (_97)
            prog_116 <= _356;
        else
            if (_1462)
                prog_116 <= _732;
    end
    assign _1454 = 8'b01110011;
    assign _1455 = _763 == _1454;
    assign _1456 = _760 & _1455;
    always @(posedge _99) begin
        if (_97)
            prog_115 <= _356;
        else
            if (_1456)
                prog_115 <= _732;
    end
    assign _1448 = 8'b01110010;
    assign _1449 = _763 == _1448;
    assign _1450 = _760 & _1449;
    always @(posedge _99) begin
        if (_97)
            prog_114 <= _356;
        else
            if (_1450)
                prog_114 <= _732;
    end
    assign _1442 = 8'b01110001;
    assign _1443 = _763 == _1442;
    assign _1444 = _760 & _1443;
    always @(posedge _99) begin
        if (_97)
            prog_113 <= _356;
        else
            if (_1444)
                prog_113 <= _732;
    end
    assign _1436 = 8'b01110000;
    assign _1437 = _763 == _1436;
    assign _1438 = _760 & _1437;
    always @(posedge _99) begin
        if (_97)
            prog_112 <= _356;
        else
            if (_1438)
                prog_112 <= _732;
    end
    assign _1430 = 8'b01101111;
    assign _1431 = _763 == _1430;
    assign _1432 = _760 & _1431;
    always @(posedge _99) begin
        if (_97)
            prog_111 <= _356;
        else
            if (_1432)
                prog_111 <= _732;
    end
    assign _1424 = 8'b01101110;
    assign _1425 = _763 == _1424;
    assign _1426 = _760 & _1425;
    always @(posedge _99) begin
        if (_97)
            prog_110 <= _356;
        else
            if (_1426)
                prog_110 <= _732;
    end
    assign _1418 = 8'b01101101;
    assign _1419 = _763 == _1418;
    assign _1420 = _760 & _1419;
    always @(posedge _99) begin
        if (_97)
            prog_109 <= _356;
        else
            if (_1420)
                prog_109 <= _732;
    end
    assign _1412 = 8'b01101100;
    assign _1413 = _763 == _1412;
    assign _1414 = _760 & _1413;
    always @(posedge _99) begin
        if (_97)
            prog_108 <= _356;
        else
            if (_1414)
                prog_108 <= _732;
    end
    assign _1406 = 8'b01101011;
    assign _1407 = _763 == _1406;
    assign _1408 = _760 & _1407;
    always @(posedge _99) begin
        if (_97)
            prog_107 <= _356;
        else
            if (_1408)
                prog_107 <= _732;
    end
    assign _1400 = 8'b01101010;
    assign _1401 = _763 == _1400;
    assign _1402 = _760 & _1401;
    always @(posedge _99) begin
        if (_97)
            prog_106 <= _356;
        else
            if (_1402)
                prog_106 <= _732;
    end
    assign _1394 = 8'b01101001;
    assign _1395 = _763 == _1394;
    assign _1396 = _760 & _1395;
    always @(posedge _99) begin
        if (_97)
            prog_105 <= _356;
        else
            if (_1396)
                prog_105 <= _732;
    end
    assign _1388 = 8'b01101000;
    assign _1389 = _763 == _1388;
    assign _1390 = _760 & _1389;
    always @(posedge _99) begin
        if (_97)
            prog_104 <= _356;
        else
            if (_1390)
                prog_104 <= _732;
    end
    assign _1382 = 8'b01100111;
    assign _1383 = _763 == _1382;
    assign _1384 = _760 & _1383;
    always @(posedge _99) begin
        if (_97)
            prog_103 <= _356;
        else
            if (_1384)
                prog_103 <= _732;
    end
    assign _1376 = 8'b01100110;
    assign _1377 = _763 == _1376;
    assign _1378 = _760 & _1377;
    always @(posedge _99) begin
        if (_97)
            prog_102 <= _356;
        else
            if (_1378)
                prog_102 <= _732;
    end
    assign _1370 = 8'b01100101;
    assign _1371 = _763 == _1370;
    assign _1372 = _760 & _1371;
    always @(posedge _99) begin
        if (_97)
            prog_101 <= _356;
        else
            if (_1372)
                prog_101 <= _732;
    end
    assign _1364 = 8'b01100100;
    assign _1365 = _763 == _1364;
    assign _1366 = _760 & _1365;
    always @(posedge _99) begin
        if (_97)
            prog_100 <= _356;
        else
            if (_1366)
                prog_100 <= _732;
    end
    assign _1358 = 8'b01100011;
    assign _1359 = _763 == _1358;
    assign _1360 = _760 & _1359;
    always @(posedge _99) begin
        if (_97)
            prog_99 <= _356;
        else
            if (_1360)
                prog_99 <= _732;
    end
    assign _1352 = 8'b01100010;
    assign _1353 = _763 == _1352;
    assign _1354 = _760 & _1353;
    always @(posedge _99) begin
        if (_97)
            prog_98 <= _356;
        else
            if (_1354)
                prog_98 <= _732;
    end
    assign _1346 = 8'b01100001;
    assign _1347 = _763 == _1346;
    assign _1348 = _760 & _1347;
    always @(posedge _99) begin
        if (_97)
            prog_97 <= _356;
        else
            if (_1348)
                prog_97 <= _732;
    end
    assign _1340 = 8'b01100000;
    assign _1341 = _763 == _1340;
    assign _1342 = _760 & _1341;
    always @(posedge _99) begin
        if (_97)
            prog_96 <= _356;
        else
            if (_1342)
                prog_96 <= _732;
    end
    assign _1334 = 8'b01011111;
    assign _1335 = _763 == _1334;
    assign _1336 = _760 & _1335;
    always @(posedge _99) begin
        if (_97)
            prog_95 <= _356;
        else
            if (_1336)
                prog_95 <= _732;
    end
    assign _1328 = 8'b01011110;
    assign _1329 = _763 == _1328;
    assign _1330 = _760 & _1329;
    always @(posedge _99) begin
        if (_97)
            prog_94 <= _356;
        else
            if (_1330)
                prog_94 <= _732;
    end
    assign _1322 = 8'b01011101;
    assign _1323 = _763 == _1322;
    assign _1324 = _760 & _1323;
    always @(posedge _99) begin
        if (_97)
            prog_93 <= _356;
        else
            if (_1324)
                prog_93 <= _732;
    end
    assign _1316 = 8'b01011100;
    assign _1317 = _763 == _1316;
    assign _1318 = _760 & _1317;
    always @(posedge _99) begin
        if (_97)
            prog_92 <= _356;
        else
            if (_1318)
                prog_92 <= _732;
    end
    assign _1310 = 8'b01011011;
    assign _1311 = _763 == _1310;
    assign _1312 = _760 & _1311;
    always @(posedge _99) begin
        if (_97)
            prog_91 <= _356;
        else
            if (_1312)
                prog_91 <= _732;
    end
    assign _1304 = 8'b01011010;
    assign _1305 = _763 == _1304;
    assign _1306 = _760 & _1305;
    always @(posedge _99) begin
        if (_97)
            prog_90 <= _356;
        else
            if (_1306)
                prog_90 <= _732;
    end
    assign _1298 = 8'b01011001;
    assign _1299 = _763 == _1298;
    assign _1300 = _760 & _1299;
    always @(posedge _99) begin
        if (_97)
            prog_89 <= _356;
        else
            if (_1300)
                prog_89 <= _732;
    end
    assign _1292 = 8'b01011000;
    assign _1293 = _763 == _1292;
    assign _1294 = _760 & _1293;
    always @(posedge _99) begin
        if (_97)
            prog_88 <= _356;
        else
            if (_1294)
                prog_88 <= _732;
    end
    assign _1286 = 8'b01010111;
    assign _1287 = _763 == _1286;
    assign _1288 = _760 & _1287;
    always @(posedge _99) begin
        if (_97)
            prog_87 <= _356;
        else
            if (_1288)
                prog_87 <= _732;
    end
    assign _1280 = 8'b01010110;
    assign _1281 = _763 == _1280;
    assign _1282 = _760 & _1281;
    always @(posedge _99) begin
        if (_97)
            prog_86 <= _356;
        else
            if (_1282)
                prog_86 <= _732;
    end
    assign _1274 = 8'b01010101;
    assign _1275 = _763 == _1274;
    assign _1276 = _760 & _1275;
    always @(posedge _99) begin
        if (_97)
            prog_85 <= _356;
        else
            if (_1276)
                prog_85 <= _732;
    end
    assign _1268 = 8'b01010100;
    assign _1269 = _763 == _1268;
    assign _1270 = _760 & _1269;
    always @(posedge _99) begin
        if (_97)
            prog_84 <= _356;
        else
            if (_1270)
                prog_84 <= _732;
    end
    assign _1262 = 8'b01010011;
    assign _1263 = _763 == _1262;
    assign _1264 = _760 & _1263;
    always @(posedge _99) begin
        if (_97)
            prog_83 <= _356;
        else
            if (_1264)
                prog_83 <= _732;
    end
    assign _1256 = 8'b01010010;
    assign _1257 = _763 == _1256;
    assign _1258 = _760 & _1257;
    always @(posedge _99) begin
        if (_97)
            prog_82 <= _356;
        else
            if (_1258)
                prog_82 <= _732;
    end
    assign _1250 = 8'b01010001;
    assign _1251 = _763 == _1250;
    assign _1252 = _760 & _1251;
    always @(posedge _99) begin
        if (_97)
            prog_81 <= _356;
        else
            if (_1252)
                prog_81 <= _732;
    end
    assign _1244 = 8'b01010000;
    assign _1245 = _763 == _1244;
    assign _1246 = _760 & _1245;
    always @(posedge _99) begin
        if (_97)
            prog_80 <= _356;
        else
            if (_1246)
                prog_80 <= _732;
    end
    assign _1238 = 8'b01001111;
    assign _1239 = _763 == _1238;
    assign _1240 = _760 & _1239;
    always @(posedge _99) begin
        if (_97)
            prog_79 <= _356;
        else
            if (_1240)
                prog_79 <= _732;
    end
    assign _1232 = 8'b01001110;
    assign _1233 = _763 == _1232;
    assign _1234 = _760 & _1233;
    always @(posedge _99) begin
        if (_97)
            prog_78 <= _356;
        else
            if (_1234)
                prog_78 <= _732;
    end
    assign _1226 = 8'b01001101;
    assign _1227 = _763 == _1226;
    assign _1228 = _760 & _1227;
    always @(posedge _99) begin
        if (_97)
            prog_77 <= _356;
        else
            if (_1228)
                prog_77 <= _732;
    end
    assign _1220 = 8'b01001100;
    assign _1221 = _763 == _1220;
    assign _1222 = _760 & _1221;
    always @(posedge _99) begin
        if (_97)
            prog_76 <= _356;
        else
            if (_1222)
                prog_76 <= _732;
    end
    assign _1214 = 8'b01001011;
    assign _1215 = _763 == _1214;
    assign _1216 = _760 & _1215;
    always @(posedge _99) begin
        if (_97)
            prog_75 <= _356;
        else
            if (_1216)
                prog_75 <= _732;
    end
    assign _1208 = 8'b01001010;
    assign _1209 = _763 == _1208;
    assign _1210 = _760 & _1209;
    always @(posedge _99) begin
        if (_97)
            prog_74 <= _356;
        else
            if (_1210)
                prog_74 <= _732;
    end
    assign _1202 = 8'b01001001;
    assign _1203 = _763 == _1202;
    assign _1204 = _760 & _1203;
    always @(posedge _99) begin
        if (_97)
            prog_73 <= _356;
        else
            if (_1204)
                prog_73 <= _732;
    end
    assign _1196 = 8'b01001000;
    assign _1197 = _763 == _1196;
    assign _1198 = _760 & _1197;
    always @(posedge _99) begin
        if (_97)
            prog_72 <= _356;
        else
            if (_1198)
                prog_72 <= _732;
    end
    assign _1190 = 8'b01000111;
    assign _1191 = _763 == _1190;
    assign _1192 = _760 & _1191;
    always @(posedge _99) begin
        if (_97)
            prog_71 <= _356;
        else
            if (_1192)
                prog_71 <= _732;
    end
    assign _1184 = 8'b01000110;
    assign _1185 = _763 == _1184;
    assign _1186 = _760 & _1185;
    always @(posedge _99) begin
        if (_97)
            prog_70 <= _356;
        else
            if (_1186)
                prog_70 <= _732;
    end
    assign _1178 = 8'b01000101;
    assign _1179 = _763 == _1178;
    assign _1180 = _760 & _1179;
    always @(posedge _99) begin
        if (_97)
            prog_69 <= _356;
        else
            if (_1180)
                prog_69 <= _732;
    end
    assign _1172 = 8'b01000100;
    assign _1173 = _763 == _1172;
    assign _1174 = _760 & _1173;
    always @(posedge _99) begin
        if (_97)
            prog_68 <= _356;
        else
            if (_1174)
                prog_68 <= _732;
    end
    assign _1166 = 8'b01000011;
    assign _1167 = _763 == _1166;
    assign _1168 = _760 & _1167;
    always @(posedge _99) begin
        if (_97)
            prog_67 <= _356;
        else
            if (_1168)
                prog_67 <= _732;
    end
    assign _1160 = 8'b01000010;
    assign _1161 = _763 == _1160;
    assign _1162 = _760 & _1161;
    always @(posedge _99) begin
        if (_97)
            prog_66 <= _356;
        else
            if (_1162)
                prog_66 <= _732;
    end
    assign _1154 = 8'b01000001;
    assign _1155 = _763 == _1154;
    assign _1156 = _760 & _1155;
    always @(posedge _99) begin
        if (_97)
            prog_65 <= _356;
        else
            if (_1156)
                prog_65 <= _732;
    end
    assign _1148 = 8'b01000000;
    assign _1149 = _763 == _1148;
    assign _1150 = _760 & _1149;
    always @(posedge _99) begin
        if (_97)
            prog_64 <= _356;
        else
            if (_1150)
                prog_64 <= _732;
    end
    assign _1142 = 8'b00111111;
    assign _1143 = _763 == _1142;
    assign _1144 = _760 & _1143;
    always @(posedge _99) begin
        if (_97)
            prog_63 <= _356;
        else
            if (_1144)
                prog_63 <= _732;
    end
    assign _1136 = 8'b00111110;
    assign _1137 = _763 == _1136;
    assign _1138 = _760 & _1137;
    always @(posedge _99) begin
        if (_97)
            prog_62 <= _356;
        else
            if (_1138)
                prog_62 <= _732;
    end
    assign _1130 = 8'b00111101;
    assign _1131 = _763 == _1130;
    assign _1132 = _760 & _1131;
    always @(posedge _99) begin
        if (_97)
            prog_61 <= _356;
        else
            if (_1132)
                prog_61 <= _732;
    end
    assign _1124 = 8'b00111100;
    assign _1125 = _763 == _1124;
    assign _1126 = _760 & _1125;
    always @(posedge _99) begin
        if (_97)
            prog_60 <= _356;
        else
            if (_1126)
                prog_60 <= _732;
    end
    assign _1118 = 8'b00111011;
    assign _1119 = _763 == _1118;
    assign _1120 = _760 & _1119;
    always @(posedge _99) begin
        if (_97)
            prog_59 <= _356;
        else
            if (_1120)
                prog_59 <= _732;
    end
    assign _1112 = 8'b00111010;
    assign _1113 = _763 == _1112;
    assign _1114 = _760 & _1113;
    always @(posedge _99) begin
        if (_97)
            prog_58 <= _356;
        else
            if (_1114)
                prog_58 <= _732;
    end
    assign _1106 = 8'b00111001;
    assign _1107 = _763 == _1106;
    assign _1108 = _760 & _1107;
    always @(posedge _99) begin
        if (_97)
            prog_57 <= _356;
        else
            if (_1108)
                prog_57 <= _732;
    end
    assign _1100 = 8'b00111000;
    assign _1101 = _763 == _1100;
    assign _1102 = _760 & _1101;
    always @(posedge _99) begin
        if (_97)
            prog_56 <= _356;
        else
            if (_1102)
                prog_56 <= _732;
    end
    assign _1094 = 8'b00110111;
    assign _1095 = _763 == _1094;
    assign _1096 = _760 & _1095;
    always @(posedge _99) begin
        if (_97)
            prog_55 <= _356;
        else
            if (_1096)
                prog_55 <= _732;
    end
    assign _1088 = 8'b00110110;
    assign _1089 = _763 == _1088;
    assign _1090 = _760 & _1089;
    always @(posedge _99) begin
        if (_97)
            prog_54 <= _356;
        else
            if (_1090)
                prog_54 <= _732;
    end
    assign _1082 = 8'b00110101;
    assign _1083 = _763 == _1082;
    assign _1084 = _760 & _1083;
    always @(posedge _99) begin
        if (_97)
            prog_53 <= _356;
        else
            if (_1084)
                prog_53 <= _732;
    end
    assign _1076 = 8'b00110100;
    assign _1077 = _763 == _1076;
    assign _1078 = _760 & _1077;
    always @(posedge _99) begin
        if (_97)
            prog_52 <= _356;
        else
            if (_1078)
                prog_52 <= _732;
    end
    assign _1070 = 8'b00110011;
    assign _1071 = _763 == _1070;
    assign _1072 = _760 & _1071;
    always @(posedge _99) begin
        if (_97)
            prog_51 <= _356;
        else
            if (_1072)
                prog_51 <= _732;
    end
    assign _1064 = 8'b00110010;
    assign _1065 = _763 == _1064;
    assign _1066 = _760 & _1065;
    always @(posedge _99) begin
        if (_97)
            prog_50 <= _356;
        else
            if (_1066)
                prog_50 <= _732;
    end
    assign _1058 = 8'b00110001;
    assign _1059 = _763 == _1058;
    assign _1060 = _760 & _1059;
    always @(posedge _99) begin
        if (_97)
            prog_49 <= _356;
        else
            if (_1060)
                prog_49 <= _732;
    end
    assign _1052 = 8'b00110000;
    assign _1053 = _763 == _1052;
    assign _1054 = _760 & _1053;
    always @(posedge _99) begin
        if (_97)
            prog_48 <= _356;
        else
            if (_1054)
                prog_48 <= _732;
    end
    assign _1046 = 8'b00101111;
    assign _1047 = _763 == _1046;
    assign _1048 = _760 & _1047;
    always @(posedge _99) begin
        if (_97)
            prog_47 <= _356;
        else
            if (_1048)
                prog_47 <= _732;
    end
    assign _1040 = 8'b00101110;
    assign _1041 = _763 == _1040;
    assign _1042 = _760 & _1041;
    always @(posedge _99) begin
        if (_97)
            prog_46 <= _356;
        else
            if (_1042)
                prog_46 <= _732;
    end
    assign _1034 = 8'b00101101;
    assign _1035 = _763 == _1034;
    assign _1036 = _760 & _1035;
    always @(posedge _99) begin
        if (_97)
            prog_45 <= _356;
        else
            if (_1036)
                prog_45 <= _732;
    end
    assign _1028 = 8'b00101100;
    assign _1029 = _763 == _1028;
    assign _1030 = _760 & _1029;
    always @(posedge _99) begin
        if (_97)
            prog_44 <= _356;
        else
            if (_1030)
                prog_44 <= _732;
    end
    assign _1022 = 8'b00101011;
    assign _1023 = _763 == _1022;
    assign _1024 = _760 & _1023;
    always @(posedge _99) begin
        if (_97)
            prog_43 <= _356;
        else
            if (_1024)
                prog_43 <= _732;
    end
    assign _1016 = 8'b00101010;
    assign _1017 = _763 == _1016;
    assign _1018 = _760 & _1017;
    always @(posedge _99) begin
        if (_97)
            prog_42 <= _356;
        else
            if (_1018)
                prog_42 <= _732;
    end
    assign _1010 = 8'b00101001;
    assign _1011 = _763 == _1010;
    assign _1012 = _760 & _1011;
    always @(posedge _99) begin
        if (_97)
            prog_41 <= _356;
        else
            if (_1012)
                prog_41 <= _732;
    end
    assign _1004 = 8'b00101000;
    assign _1005 = _763 == _1004;
    assign _1006 = _760 & _1005;
    always @(posedge _99) begin
        if (_97)
            prog_40 <= _356;
        else
            if (_1006)
                prog_40 <= _732;
    end
    assign _998 = 8'b00100111;
    assign _999 = _763 == _998;
    assign _1000 = _760 & _999;
    always @(posedge _99) begin
        if (_97)
            prog_39 <= _356;
        else
            if (_1000)
                prog_39 <= _732;
    end
    assign _992 = 8'b00100110;
    assign _993 = _763 == _992;
    assign _994 = _760 & _993;
    always @(posedge _99) begin
        if (_97)
            prog_38 <= _356;
        else
            if (_994)
                prog_38 <= _732;
    end
    assign _986 = 8'b00100101;
    assign _987 = _763 == _986;
    assign _988 = _760 & _987;
    always @(posedge _99) begin
        if (_97)
            prog_37 <= _356;
        else
            if (_988)
                prog_37 <= _732;
    end
    assign _980 = 8'b00100100;
    assign _981 = _763 == _980;
    assign _982 = _760 & _981;
    always @(posedge _99) begin
        if (_97)
            prog_36 <= _356;
        else
            if (_982)
                prog_36 <= _732;
    end
    assign _974 = 8'b00100011;
    assign _975 = _763 == _974;
    assign _976 = _760 & _975;
    always @(posedge _99) begin
        if (_97)
            prog_35 <= _356;
        else
            if (_976)
                prog_35 <= _732;
    end
    assign _968 = 8'b00100010;
    assign _969 = _763 == _968;
    assign _970 = _760 & _969;
    always @(posedge _99) begin
        if (_97)
            prog_34 <= _356;
        else
            if (_970)
                prog_34 <= _732;
    end
    assign _962 = 8'b00100001;
    assign _963 = _763 == _962;
    assign _964 = _760 & _963;
    always @(posedge _99) begin
        if (_97)
            prog_33 <= _356;
        else
            if (_964)
                prog_33 <= _732;
    end
    assign _956 = 8'b00100000;
    assign _957 = _763 == _956;
    assign _958 = _760 & _957;
    always @(posedge _99) begin
        if (_97)
            prog_32 <= _356;
        else
            if (_958)
                prog_32 <= _732;
    end
    assign _950 = 8'b00011111;
    assign _951 = _763 == _950;
    assign _952 = _760 & _951;
    always @(posedge _99) begin
        if (_97)
            prog_31 <= _356;
        else
            if (_952)
                prog_31 <= _732;
    end
    assign _944 = 8'b00011110;
    assign _945 = _763 == _944;
    assign _946 = _760 & _945;
    always @(posedge _99) begin
        if (_97)
            prog_30 <= _356;
        else
            if (_946)
                prog_30 <= _732;
    end
    assign _938 = 8'b00011101;
    assign _939 = _763 == _938;
    assign _940 = _760 & _939;
    always @(posedge _99) begin
        if (_97)
            prog_29 <= _356;
        else
            if (_940)
                prog_29 <= _732;
    end
    assign _932 = 8'b00011100;
    assign _933 = _763 == _932;
    assign _934 = _760 & _933;
    always @(posedge _99) begin
        if (_97)
            prog_28 <= _356;
        else
            if (_934)
                prog_28 <= _732;
    end
    assign _926 = 8'b00011011;
    assign _927 = _763 == _926;
    assign _928 = _760 & _927;
    always @(posedge _99) begin
        if (_97)
            prog_27 <= _356;
        else
            if (_928)
                prog_27 <= _732;
    end
    assign _920 = 8'b00011010;
    assign _921 = _763 == _920;
    assign _922 = _760 & _921;
    always @(posedge _99) begin
        if (_97)
            prog_26 <= _356;
        else
            if (_922)
                prog_26 <= _732;
    end
    assign _914 = 8'b00011001;
    assign _915 = _763 == _914;
    assign _916 = _760 & _915;
    always @(posedge _99) begin
        if (_97)
            prog_25 <= _356;
        else
            if (_916)
                prog_25 <= _732;
    end
    assign _908 = 8'b00011000;
    assign _909 = _763 == _908;
    assign _910 = _760 & _909;
    always @(posedge _99) begin
        if (_97)
            prog_24 <= _356;
        else
            if (_910)
                prog_24 <= _732;
    end
    assign _902 = 8'b00010111;
    assign _903 = _763 == _902;
    assign _904 = _760 & _903;
    always @(posedge _99) begin
        if (_97)
            prog_23 <= _356;
        else
            if (_904)
                prog_23 <= _732;
    end
    assign _896 = 8'b00010110;
    assign _897 = _763 == _896;
    assign _898 = _760 & _897;
    always @(posedge _99) begin
        if (_97)
            prog_22 <= _356;
        else
            if (_898)
                prog_22 <= _732;
    end
    assign _890 = 8'b00010101;
    assign _891 = _763 == _890;
    assign _892 = _760 & _891;
    always @(posedge _99) begin
        if (_97)
            prog_21 <= _356;
        else
            if (_892)
                prog_21 <= _732;
    end
    assign _884 = 8'b00010100;
    assign _885 = _763 == _884;
    assign _886 = _760 & _885;
    always @(posedge _99) begin
        if (_97)
            prog_20 <= _356;
        else
            if (_886)
                prog_20 <= _732;
    end
    assign _878 = 8'b00010011;
    assign _879 = _763 == _878;
    assign _880 = _760 & _879;
    always @(posedge _99) begin
        if (_97)
            prog_19 <= _356;
        else
            if (_880)
                prog_19 <= _732;
    end
    assign _872 = 8'b00010010;
    assign _873 = _763 == _872;
    assign _874 = _760 & _873;
    always @(posedge _99) begin
        if (_97)
            prog_18 <= _356;
        else
            if (_874)
                prog_18 <= _732;
    end
    assign _866 = 8'b00010001;
    assign _867 = _763 == _866;
    assign _868 = _760 & _867;
    always @(posedge _99) begin
        if (_97)
            prog_17 <= _356;
        else
            if (_868)
                prog_17 <= _732;
    end
    assign _861 = _763 == _562;
    assign _862 = _760 & _861;
    always @(posedge _99) begin
        if (_97)
            prog_16 <= _356;
        else
            if (_862)
                prog_16 <= _732;
    end
    assign _854 = 8'b00001111;
    assign _855 = _763 == _854;
    assign _856 = _760 & _855;
    always @(posedge _99) begin
        if (_97)
            prog_15 <= _356;
        else
            if (_856)
                prog_15 <= _732;
    end
    assign _848 = 8'b00001110;
    assign _849 = _763 == _848;
    assign _850 = _760 & _849;
    always @(posedge _99) begin
        if (_97)
            prog_14 <= _356;
        else
            if (_850)
                prog_14 <= _732;
    end
    assign _842 = 8'b00001101;
    assign _843 = _763 == _842;
    assign _844 = _760 & _843;
    always @(posedge _99) begin
        if (_97)
            prog_13 <= _356;
        else
            if (_844)
                prog_13 <= _732;
    end
    assign _836 = 8'b00001100;
    assign _837 = _763 == _836;
    assign _838 = _760 & _837;
    always @(posedge _99) begin
        if (_97)
            prog_12 <= _356;
        else
            if (_838)
                prog_12 <= _732;
    end
    assign _830 = 8'b00001011;
    assign _831 = _763 == _830;
    assign _832 = _760 & _831;
    always @(posedge _99) begin
        if (_97)
            prog_11 <= _356;
        else
            if (_832)
                prog_11 <= _732;
    end
    assign _824 = 8'b00001010;
    assign _825 = _763 == _824;
    assign _826 = _760 & _825;
    always @(posedge _99) begin
        if (_97)
            prog_10 <= _356;
        else
            if (_826)
                prog_10 <= _732;
    end
    assign _818 = 8'b00001001;
    assign _819 = _763 == _818;
    assign _820 = _760 & _819;
    always @(posedge _99) begin
        if (_97)
            prog_9 <= _356;
        else
            if (_820)
                prog_9 <= _732;
    end
    assign _812 = 8'b00001000;
    assign _813 = _763 == _812;
    assign _814 = _760 & _813;
    always @(posedge _99) begin
        if (_97)
            prog_8 <= _356;
        else
            if (_814)
                prog_8 <= _732;
    end
    assign _806 = 8'b00000111;
    assign _807 = _763 == _806;
    assign _808 = _760 & _807;
    always @(posedge _99) begin
        if (_97)
            prog_7 <= _356;
        else
            if (_808)
                prog_7 <= _732;
    end
    assign _800 = 8'b00000110;
    assign _801 = _763 == _800;
    assign _802 = _760 & _801;
    always @(posedge _99) begin
        if (_97)
            prog_6 <= _356;
        else
            if (_802)
                prog_6 <= _732;
    end
    assign _794 = 8'b00000101;
    assign _795 = _763 == _794;
    assign _796 = _760 & _795;
    always @(posedge _99) begin
        if (_97)
            prog_5 <= _356;
        else
            if (_796)
                prog_5 <= _732;
    end
    assign _788 = 8'b00000100;
    assign _789 = _763 == _788;
    assign _790 = _760 & _789;
    always @(posedge _99) begin
        if (_97)
            prog_4 <= _356;
        else
            if (_790)
                prog_4 <= _732;
    end
    assign _782 = 8'b00000011;
    assign _783 = _763 == _782;
    assign _784 = _760 & _783;
    always @(posedge _99) begin
        if (_97)
            prog_3 <= _356;
        else
            if (_784)
                prog_3 <= _732;
    end
    assign _776 = 8'b00000010;
    assign _777 = _763 == _776;
    assign _778 = _760 & _777;
    always @(posedge _99) begin
        if (_97)
            prog_2 <= _356;
        else
            if (_778)
                prog_2 <= _732;
    end
    assign _771 = _763 == _5135;
    assign _772 = _760 & _771;
    always @(posedge _99) begin
        if (_97)
            prog_1 <= _356;
        else
            if (_772)
                prog_1 <= _732;
    end
    assign _762 = _728[5:0];
    assign _761 = cfg_ctrl[4:3];
    assign _763 = { _761,
                    _762 };
    assign _765 = _763 == _305;
    assign _758 = 7'b1000000;
    assign _759 = _728 < _758;
    assign _757 = _722 & _726;
    assign _760 = _757 & _759;
    assign _766 = _760 & _765;
    always @(posedge _99) begin
        if (_97)
            prog_0 <= _356;
        else
            if (_766)
                prog_0 <= _732;
    end
    assign _3196 = _732[7:0];
    assign _3193 = 7'b1010001;
    assign _3194 = _728 == _3193;
    assign _3192 = _722 & _726;
    assign _3195 = _3192 & _3194;
    assign _3197 = _3195 ? _3196 : cfg_t1_start;
    assign _27 = _3197;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_start <= _305;
        else
            cfg_t1_start <= _27;
    end
    assign _4232 = _3176[5:0];
    assign _4231 = t1_pc[7:6];
    assign _4233 = { _4231,
                     _4232 };
    assign _3202 = _732[7:0];
    assign _3199 = 7'b1010110;
    assign _3200 = _728 == _3199;
    assign _3198 = _722 & _726;
    assign _3201 = _3198 & _3200;
    assign _3203 = _3201 ? _3202 : cfg_t1_timeout_vector;
    assign _28 = _3203;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_timeout_vector <= _305;
        else
            cfg_t1_timeout_vector <= _28;
    end
    assign _4230 = _3177 == _5137;
    assign _4234 = _4230 ? _4233 : cfg_t1_timeout_vector;
    assign _4228 = t1_pc + _5135;
    assign _3239 = _3233 - _2379;
    assign _3240 = _3237 ? _3239 : t1_wait_count;
    assign _3241 = _3208 ? t1_wait_count : _3240;
    assign _3242 = _3205 ? t1_wait_count : _3241;
    assign _3244 = _3204 ? _356 : _3242;
    assign _29 = _3244;
    assign _30 = _29;
    always @(posedge _99) begin
        if (_97)
            t1_wait_count <= _356;
        else
            t1_wait_count <= _30;
    end
    assign _3246 = 7'b1011011;
    assign _3247 = _728 == _3246;
    assign _3245 = _722 & _726;
    assign _3248 = _3245 & _3247;
    assign _3249 = _3248 ? _732 : cfg_t1_timeout;
    assign _31 = _3249;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_timeout <= _356;
        else
            cfg_t1_timeout <= _31;
    end
    assign _3236 = ~ _3235;
    assign _3223 = ~ _3222;
    assign _3210 = _3177 == _2395;
    assign _3224 = _3210 & _3223;
    assign _3226 = _3224 & _3225;
    assign _3237 = _3226 & _3236;
    assign _3273 = _3237 ? _2418 : t1_waiting;
    assign _3275 = _3271 ? _716 : _3273;
    assign _3276 = _3208 ? t1_waiting : _3275;
    assign _3277 = _3205 ? t1_waiting : _3276;
    assign _3279 = _3204 ? _716 : _3277;
    assign _32 = _3279;
    assign _33 = _32;
    always @(posedge _99) begin
        if (_97)
            t1_waiting <= _716;
        else
            t1_waiting <= _33;
    end
    assign _3233 = t1_waiting ? t1_wait_count : cfg_t1_timeout;
    assign _3235 = _3233 == _356;
    assign _3225 = _3176[4:4];
    assign _3254 = _3225 & _3235;
    assign _3221 = _3176[8:8];
    assign _3219 = _2352[7:7];
    assign _3218 = _2352[6:6];
    assign _3217 = _2352[5:5];
    assign _3216 = _2352[4:4];
    assign _3215 = _2352[3:3];
    assign _3214 = _2352[2:2];
    assign _3213 = _2352[1:1];
    assign _3212 = _2352[0:0];
    assign _3211 = _3176[7:5];
    always @* begin
        case (_3211)
        0:
            _3220 <= _3212;
        1:
            _3220 <= _3213;
        2:
            _3220 <= _3214;
        3:
            _3220 <= _3215;
        4:
            _3220 <= _3216;
        5:
            _3220 <= _3217;
        6:
            _3220 <= _3218;
        default:
            _3220 <= _3219;
        endcase
    end
    assign _3222 = _3220 == _3221;
    assign _4223 = ~ _3222;
    assign _4222 = _3177 == _2395;
    assign _4224 = _4222 & _4223;
    assign _4225 = _4224 & _3254;
    assign _3313 = _3311[4:0];
    assign _3310 = { gnd,
                     _3309 };
    assign _3303 = { gnd,
                     t1_isr_count };
    assign _3311 = _3303 + _3310;
    assign _3312 = _2457 < _3311;
    assign _3315 = _3312 ? _252 : _3313;
    assign _3300 = _3181 ? t1_isr_count : _585;
    assign _3294 = _3286 == _4761;
    assign _3296 = _3294 ? _585 : t1_isr_count;
    assign _3297 = _3292 ? _3296 : t1_isr_count;
    assign _3285 = _3177 == _4727;
    assign _3298 = _3285 ? _3297 : t1_isr_count;
    assign _3283 = _3177 == _5182;
    assign _3301 = _3283 ? _3300 : _3298;
    assign _3281 = _3177 == _5102;
    assign _3316 = _3281 ? _3315 : _3301;
    assign _3317 = _3271 ? _3316 : t1_isr_count;
    assign _3318 = _3208 ? t1_isr_count : _3317;
    assign _3319 = _3205 ? t1_isr_count : _3318;
    assign _3321 = _3204 ? _585 : _3319;
    assign _34 = _3321;
    assign _35 = _34;
    always @(posedge _99) begin
        if (_97)
            t1_isr_count <= _585;
        else
            t1_isr_count <= _35;
    end
    assign _4218 = t1_isr_count < cfg_t1_threshold;
    assign _3326 = _732[4:0];
    assign _3323 = 7'b1010101;
    assign _3324 = _728 == _3323;
    assign _3322 = _722 & _726;
    assign _3325 = _3322 & _3324;
    assign _3327 = _3325 ? _3326 : cfg_t1_threshold;
    assign _36 = _3327;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_threshold <= _399;
        else
            cfg_t1_threshold <= _36;
    end
    assign _3349 = _3347[4:0];
    assign _3346 = { gnd,
                     _3309 };
    assign _3345 = { gnd,
                     t1_osr_count };
    assign _3347 = _3345 + _3346;
    assign _3348 = _2457 < _3347;
    assign _3351 = _3348 ? _252 : _3349;
    assign _3342 = _3181 ? _585 : t1_osr_count;
    assign _3336 = _3286 == _5182;
    assign _3338 = _3336 ? _585 : t1_osr_count;
    assign _3339 = _3292 ? _3338 : t1_osr_count;
    assign _3334 = _3177 == _4727;
    assign _3340 = _3334 ? _3339 : t1_osr_count;
    assign _3333 = _3177 == _5182;
    assign _3343 = _3333 ? _3342 : _3340;
    assign _3332 = _3177 == _4761;
    assign _3352 = _3332 ? _3351 : _3343;
    assign _3353 = _3271 ? _3352 : t1_osr_count;
    assign _3354 = _3208 ? t1_osr_count : _3353;
    assign _3355 = _3205 ? t1_osr_count : _3354;
    assign _3356 = _3204 ? cfg_t1_threshold : _3355;
    assign _37 = _3356;
    assign _38 = _37;
    always @(posedge _99) begin
        if (_97)
            t1_osr_count <= _585;
        else
            t1_osr_count <= _38;
    end
    assign _4217 = t1_osr_count < cfg_t1_threshold;
    assign _4215 = t1_x == t1_y;
    assign _4216 = ~ _4215;
    assign _4212 = t1_y == _356;
    assign _4213 = ~ _4212;
    assign _4214 = ~ _4213;
    assign _4197 = t1_x - _2379;
    assign _4195 = _4165 == _5102;
    assign _4198 = _4195 ? _4197 : t1_x;
    assign _4191 = _4128 == _184;
    assign _4192 = _4191 ? _4162 : t1_x;
    assign _3583 = _3506 & _3582;
    assign _3552 = _3551[15:0];
    assign _3554 = { _3552,
                     _356 };
    assign _3548 = _3547[23:0];
    assign _3550 = { _3548,
                     _305 };
    assign _3544 = _3543[27:0];
    assign _3546 = { _3544,
                     _591 };
    assign _3540 = _3539[29:0];
    assign _3542 = { _3540,
                     _297 };
    assign _3536 = _3535[30:0];
    assign _3538 = { _3536,
                     _716 };
    assign _3535 = { _356,
                     t1_isr };
    assign _3533 = _3309[0:0];
    assign _3539 = _3533 ? _3538 : _3535;
    assign _3532 = _3309[1:1];
    assign _3543 = _3532 ? _3542 : _3539;
    assign _3531 = _3309[2:2];
    assign _3547 = _3531 ? _3546 : _3543;
    assign _3530 = _3309[3:3];
    assign _3551 = _3530 ? _3550 : _3547;
    assign _3529 = _3309[4:4];
    assign _3555 = _3529 ? _3554 : _3551;
    assign _3556 = _3555[15:0];
    assign _3584 = _3556 | _3583;
    assign _3525 = _3523[31:16];
    assign _3526 = { _356,
                     _3525 };
    assign _3521 = _3519[31:8];
    assign _3522 = { _305,
                     _3521 };
    assign _3517 = _3515[31:4];
    assign _3518 = { _591,
                     _3517 };
    assign _3513 = _3511[31:2];
    assign _3514 = { _297,
                     _3513 };
    assign _3509 = _3507[31:1];
    assign _3510 = { _716,
                     _3509 };
    assign _3501 = _585 < _3309;
    assign _3498 = _2352[7:7];
    assign _3497 = _2352[6:6];
    assign _3496 = _2352[5:5];
    assign _3495 = _2352[4:4];
    assign _3494 = _2352[3:3];
    assign _3493 = _2352[2:2];
    assign _3492 = _2352[1:1];
    assign _3491 = _2352[0:0];
    always @* begin
        case (cfg_t1_in_base)
        0:
            _3499 <= _3491;
        1:
            _3499 <= _3492;
        2:
            _3499 <= _3493;
        3:
            _3499 <= _3494;
        4:
            _3499 <= _3495;
        5:
            _3499 <= _3496;
        6:
            _3499 <= _3497;
        default:
            _3499 <= _3498;
        endcase
    end
    assign _3502 = _3499 & _3501;
    assign _3488 = 5'b00001;
    assign _3489 = _3488 < _3309;
    assign _3486 = _2352[7:7];
    assign _3485 = _2352[6:6];
    assign _3484 = _2352[5:5];
    assign _3483 = _2352[4:4];
    assign _3482 = _2352[3:3];
    assign _3481 = _2352[2:2];
    assign _3480 = _2352[1:1];
    assign _3479 = _2352[0:0];
    assign _3478 = cfg_t1_in_base + _2395;
    always @* begin
        case (_3478)
        0:
            _3487 <= _3479;
        1:
            _3487 <= _3480;
        2:
            _3487 <= _3481;
        3:
            _3487 <= _3482;
        4:
            _3487 <= _3483;
        5:
            _3487 <= _3484;
        6:
            _3487 <= _3485;
        default:
            _3487 <= _3486;
        endcase
    end
    assign _3490 = _3487 & _3489;
    assign _3474 = 5'b00010;
    assign _3475 = _3474 < _3309;
    assign _3472 = _2352[7:7];
    assign _3471 = _2352[6:6];
    assign _3470 = _2352[5:5];
    assign _3469 = _2352[4:4];
    assign _3468 = _2352[3:3];
    assign _3467 = _2352[2:2];
    assign _3466 = _2352[1:1];
    assign _3465 = _2352[0:0];
    assign _3464 = cfg_t1_in_base + _5102;
    always @* begin
        case (_3464)
        0:
            _3473 <= _3465;
        1:
            _3473 <= _3466;
        2:
            _3473 <= _3467;
        3:
            _3473 <= _3468;
        4:
            _3473 <= _3469;
        5:
            _3473 <= _3470;
        6:
            _3473 <= _3471;
        default:
            _3473 <= _3472;
        endcase
    end
    assign _3476 = _3473 & _3475;
    assign _3460 = 5'b00011;
    assign _3461 = _3460 < _3309;
    assign _3458 = _2352[7:7];
    assign _3457 = _2352[6:6];
    assign _3456 = _2352[5:5];
    assign _3455 = _2352[4:4];
    assign _3454 = _2352[3:3];
    assign _3453 = _2352[2:2];
    assign _3452 = _2352[1:1];
    assign _3451 = _2352[0:0];
    assign _3450 = cfg_t1_in_base + _4761;
    always @* begin
        case (_3450)
        0:
            _3459 <= _3451;
        1:
            _3459 <= _3452;
        2:
            _3459 <= _3453;
        3:
            _3459 <= _3454;
        4:
            _3459 <= _3455;
        5:
            _3459 <= _3456;
        6:
            _3459 <= _3457;
        default:
            _3459 <= _3458;
        endcase
    end
    assign _3462 = _3459 & _3461;
    assign _3446 = 5'b00100;
    assign _3447 = _3446 < _3309;
    assign _3444 = _2352[7:7];
    assign _3443 = _2352[6:6];
    assign _3442 = _2352[5:5];
    assign _3441 = _2352[4:4];
    assign _3440 = _2352[3:3];
    assign _3439 = _2352[2:2];
    assign _3438 = _2352[1:1];
    assign _3437 = _2352[0:0];
    assign _3436 = cfg_t1_in_base + _5182;
    always @* begin
        case (_3436)
        0:
            _3445 <= _3437;
        1:
            _3445 <= _3438;
        2:
            _3445 <= _3439;
        3:
            _3445 <= _3440;
        4:
            _3445 <= _3441;
        5:
            _3445 <= _3442;
        6:
            _3445 <= _3443;
        default:
            _3445 <= _3444;
        endcase
    end
    assign _3448 = _3445 & _3447;
    assign _3432 = 5'b00101;
    assign _3433 = _3432 < _3309;
    assign _3430 = _2352[7:7];
    assign _3429 = _2352[6:6];
    assign _3428 = _2352[5:5];
    assign _3427 = _2352[4:4];
    assign _3426 = _2352[3:3];
    assign _3425 = _2352[2:2];
    assign _3424 = _2352[1:1];
    assign _3423 = _2352[0:0];
    assign _3422 = cfg_t1_in_base + _4727;
    always @* begin
        case (_3422)
        0:
            _3431 <= _3423;
        1:
            _3431 <= _3424;
        2:
            _3431 <= _3425;
        3:
            _3431 <= _3426;
        4:
            _3431 <= _3427;
        5:
            _3431 <= _3428;
        6:
            _3431 <= _3429;
        default:
            _3431 <= _3430;
        endcase
    end
    assign _3434 = _3431 & _3433;
    assign _3418 = 5'b00110;
    assign _3419 = _3418 < _3309;
    assign _3416 = _2352[7:7];
    assign _3415 = _2352[6:6];
    assign _3414 = _2352[5:5];
    assign _3413 = _2352[4:4];
    assign _3412 = _2352[3:3];
    assign _3411 = _2352[2:2];
    assign _3410 = _2352[1:1];
    assign _3409 = _2352[0:0];
    assign _3408 = cfg_t1_in_base + _4710;
    always @* begin
        case (_3408)
        0:
            _3417 <= _3409;
        1:
            _3417 <= _3410;
        2:
            _3417 <= _3411;
        3:
            _3417 <= _3412;
        4:
            _3417 <= _3413;
        5:
            _3417 <= _3414;
        6:
            _3417 <= _3415;
        default:
            _3417 <= _3416;
        endcase
    end
    assign _3420 = _3417 & _3419;
    assign _3404 = 5'b00111;
    assign _3405 = _3404 < _3309;
    assign _3402 = _2352[7:7];
    assign _3401 = _2352[6:6];
    assign _3400 = _2352[5:5];
    assign _3399 = _2352[4:4];
    assign _3398 = _2352[3:3];
    assign _3397 = _2352[2:2];
    assign _3396 = _2352[1:1];
    assign _3395 = _2352[0:0];
    assign _3361 = _732[2:0];
    assign _3358 = 7'b1010100;
    assign _3359 = _728 == _3358;
    assign _3357 = _722 & _726;
    assign _3360 = _3357 & _3359;
    assign _3362 = _3360 ? _3361 : cfg_t1_in_base;
    assign _39 = _3362;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_in_base <= _5137;
        else
            cfg_t1_in_base <= _39;
    end
    assign _3394 = cfg_t1_in_base + _4552;
    always @* begin
        case (_3394)
        0:
            _3403 <= _3395;
        1:
            _3403 <= _3396;
        2:
            _3403 <= _3397;
        3:
            _3403 <= _3398;
        4:
            _3403 <= _3399;
        5:
            _3403 <= _3400;
        6:
            _3403 <= _3401;
        default:
            _3403 <= _3402;
        endcase
    end
    assign _3406 = _3403 & _3405;
    assign _3503 = { _3406,
                     _3420,
                     _3434,
                     _3448,
                     _3462,
                     _3476,
                     _3490,
                     _3502 };
    assign _3504 = { _305,
                     _3503 };
    assign _3391 = _3176[8:7];
    always @* begin
        case (_3391)
        0:
            _3506 <= _3504;
        1:
            _3506 <= t1_x;
        2:
            _3506 <= t1_y;
        default:
            _3506 <= _356;
        endcase
    end
    assign _3507 = { _3506,
                     t1_isr };
    assign _3390 = _3309[0:0];
    assign _3511 = _3390 ? _3510 : _3507;
    assign _3389 = _3309[1:1];
    assign _3515 = _3389 ? _3514 : _3511;
    assign _3388 = _3309[2:2];
    assign _3519 = _3388 ? _3518 : _3515;
    assign _3387 = _3309[3:3];
    assign _3523 = _3387 ? _3522 : _3519;
    assign _3386 = _3309[4:4];
    assign _3527 = _3386 ? _3526 : _3523;
    assign _3528 = _3527[15:0];
    assign _251 = cfg_t1_shift[1:1];
    assign _3585 = _251 ? _3584 : _3528;
    assign _3384 = _3181 ? t1_isr : _356;
    assign _3366 = _3286 == _4761;
    assign _3380 = _3366 ? _3379 : t1_isr;
    assign _3381 = _3292 ? _3380 : t1_isr;
    assign _3365 = _3177 == _4727;
    assign _3382 = _3365 ? _3381 : t1_isr;
    assign _3364 = _3177 == _5182;
    assign _3385 = _3364 ? _3384 : _3382;
    assign _3363 = _3177 == _5102;
    assign _3586 = _3363 ? _3585 : _3385;
    assign _3587 = _3271 ? _3586 : t1_isr;
    assign _3588 = _3208 ? t1_isr : _3587;
    assign _3589 = _3205 ? t1_isr : _3588;
    assign _3591 = _3204 ? _356 : _3589;
    assign _40 = _3591;
    assign _41 = _40;
    always @(posedge _99) begin
        if (_97)
            t1_isr <= _356;
        else
            t1_isr <= _41;
    end
    assign _3374 = { _305,
                     _2352 };
    assign _4169 = t1_y - _2379;
    assign _4167 = _4165 == _5182;
    assign _4170 = _4167 ? _4169 : t1_y;
    assign _4158 = _4156[31:16];
    assign _4159 = { _356,
                     _4158 };
    assign _4154 = _4152[31:8];
    assign _4155 = { _305,
                     _4154 };
    assign _4150 = _4148[31:4];
    assign _4151 = { _591,
                     _4150 };
    assign _4146 = _4144[31:2];
    assign _4147 = { _297,
                     _4146 };
    assign _4142 = _4140[31:1];
    assign _4143 = { _716,
                     _4142 };
    assign _4140 = { _356,
                     t1_osr };
    assign _4138 = _4133[0:0];
    assign _4144 = _4138 ? _4143 : _4140;
    assign _4137 = _4133[1:1];
    assign _4148 = _4137 ? _4147 : _4144;
    assign _4136 = _4133[2:2];
    assign _4152 = _4136 ? _4151 : _4148;
    assign _4135 = _4133[3:3];
    assign _4156 = _4135 ? _4155 : _4152;
    assign _4133 = _252 - _3309;
    assign _4134 = _4133[4:4];
    assign _4160 = _4134 ? _4159 : _4156;
    assign _4161 = _4160[15:0];
    assign _3577 = _3576[15:0];
    assign _3579 = { _3577,
                     _356 };
    assign _3573 = _3572[23:0];
    assign _3575 = { _3573,
                     _305 };
    assign _3569 = _3568[27:0];
    assign _3571 = { _3569,
                     _591 };
    assign _3565 = _3564[29:0];
    assign _3567 = { _3565,
                     _297 };
    assign _3561 = _3309[0:0];
    assign _3564 = _3561 ? _294 : _293;
    assign _3560 = _3309[1:1];
    assign _3568 = _3560 ? _3567 : _3564;
    assign _3559 = _3309[2:2];
    assign _3572 = _3559 ? _3571 : _3568;
    assign _3558 = _3309[3:3];
    assign _3576 = _3558 ? _3575 : _3572;
    assign _3557 = _3309[4:4];
    assign _3580 = _3557 ? _3579 : _3576;
    assign _3581 = _3580[15:0];
    assign _3582 = ~ _3581;
    assign _4091 = _4090[15:0];
    assign _4093 = { _4091,
                     _356 };
    assign _4087 = _4086[23:0];
    assign _4089 = { _4087,
                     _305 };
    assign _4083 = _4082[27:0];
    assign _4085 = { _4083,
                     _591 };
    assign _4079 = _4078[29:0];
    assign _4081 = { _4079,
                     _297 };
    assign _4075 = _4074[30:0];
    assign _4077 = { _4075,
                     _716 };
    assign _4074 = { _356,
                     t1_osr };
    assign _4072 = _3309[0:0];
    assign _4078 = _4072 ? _4077 : _4074;
    assign _4071 = _3309[1:1];
    assign _4082 = _4071 ? _4081 : _4078;
    assign _4070 = _3309[2:2];
    assign _4086 = _4070 ? _4085 : _4082;
    assign _4069 = _3309[3:3];
    assign _4090 = _4069 ? _4089 : _4086;
    assign _4068 = _3309[4:4];
    assign _4094 = _4068 ? _4093 : _4090;
    assign _4095 = _4094[15:0];
    assign _4064 = _4062[31:16];
    assign _4065 = { _356,
                     _4064 };
    assign _4060 = _4058[31:8];
    assign _4061 = { _305,
                     _4060 };
    assign _4056 = _4054[31:4];
    assign _4057 = { _591,
                     _4056 };
    assign _4052 = _4050[31:2];
    assign _4053 = { _297,
                     _4052 };
    assign _4048 = _4046[31:1];
    assign _4049 = { _716,
                     _4048 };
    assign _4046 = { _356,
                     t1_osr };
    assign _4044 = _3309[0:0];
    assign _4050 = _4044 ? _4049 : _4046;
    assign _4043 = _3309[1:1];
    assign _4054 = _4043 ? _4053 : _4050;
    assign _4042 = _3309[2:2];
    assign _4058 = _4042 ? _4057 : _4054;
    assign _4041 = _3309[3:3];
    assign _4062 = _4041 ? _4061 : _4058;
    assign _3307 = { gnd,
                     _3304 };
    assign _3304 = _3176[3:0];
    assign _3306 = _3304 == _591;
    assign _3309 = _3306 ? _252 : _3307;
    assign _4040 = _3309[4:4];
    assign _4066 = _4040 ? _4065 : _4062;
    assign _4067 = _4066[15:0];
    assign _4096 = _4039 ? _4095 : _4067;
    assign _4033 = t1_tx_wr == _681;
    assign _4034 = _3603 & _4033;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_15 <= _356;
        else
            if (_4034)
                t1_tx_mem_15 <= _3939;
    end
    assign _4027 = t1_tx_wr == _675;
    assign _4028 = _3603 & _4027;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_14 <= _356;
        else
            if (_4028)
                t1_tx_mem_14 <= _3939;
    end
    assign _4021 = t1_tx_wr == _669;
    assign _4022 = _3603 & _4021;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_13 <= _356;
        else
            if (_4022)
                t1_tx_mem_13 <= _3939;
    end
    assign _4015 = t1_tx_wr == _663;
    assign _4016 = _3603 & _4015;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_12 <= _356;
        else
            if (_4016)
                t1_tx_mem_12 <= _3939;
    end
    assign _4009 = t1_tx_wr == _657;
    assign _4010 = _3603 & _4009;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_11 <= _356;
        else
            if (_4010)
                t1_tx_mem_11 <= _3939;
    end
    assign _4003 = t1_tx_wr == _651;
    assign _4004 = _3603 & _4003;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_10 <= _356;
        else
            if (_4004)
                t1_tx_mem_10 <= _3939;
    end
    assign _3997 = t1_tx_wr == _645;
    assign _3998 = _3603 & _3997;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_9 <= _356;
        else
            if (_3998)
                t1_tx_mem_9 <= _3939;
    end
    assign _3991 = t1_tx_wr == _639;
    assign _3992 = _3603 & _3991;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_8 <= _356;
        else
            if (_3992)
                t1_tx_mem_8 <= _3939;
    end
    assign _3985 = t1_tx_wr == _633;
    assign _3986 = _3603 & _3985;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_7 <= _356;
        else
            if (_3986)
                t1_tx_mem_7 <= _3939;
    end
    assign _3979 = t1_tx_wr == _627;
    assign _3980 = _3603 & _3979;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_6 <= _356;
        else
            if (_3980)
                t1_tx_mem_6 <= _3939;
    end
    assign _3973 = t1_tx_wr == _621;
    assign _3974 = _3603 & _3973;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_5 <= _356;
        else
            if (_3974)
                t1_tx_mem_5 <= _3939;
    end
    assign _3967 = t1_tx_wr == _615;
    assign _3968 = _3603 & _3967;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_4 <= _356;
        else
            if (_3968)
                t1_tx_mem_4 <= _3939;
    end
    assign _3961 = t1_tx_wr == _609;
    assign _3962 = _3603 & _3961;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_3 <= _356;
        else
            if (_3962)
                t1_tx_mem_3 <= _3939;
    end
    assign _3955 = t1_tx_wr == _603;
    assign _3956 = _3603 & _3955;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_2 <= _356;
        else
            if (_3956)
                t1_tx_mem_2 <= _3939;
    end
    assign _3949 = t1_tx_wr == _597;
    assign _3950 = _3603 & _3949;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_1 <= _356;
        else
            if (_3950)
                t1_tx_mem_1 <= _3939;
    end
    assign _3608 = t1_tx_wr + _597;
    assign _3609 = _3603 ? _3608 : t1_tx_wr;
    assign _42 = _3609;
    always @(posedge _99) begin
        if (_97)
            t1_tx_wr <= _591;
        else
            t1_tx_wr <= _42;
    end
    assign _3943 = t1_tx_wr == _591;
    assign _3944 = _3603 & _3943;
    assign _517 = t0_rx_wr == _681;
    assign _518 = _422 & _517;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_15 <= _356;
        else
            if (_518)
                t0_rx_mem_15 <= _49;
    end
    assign _511 = t0_rx_wr == _675;
    assign _512 = _422 & _511;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_14 <= _356;
        else
            if (_512)
                t0_rx_mem_14 <= _49;
    end
    assign _505 = t0_rx_wr == _669;
    assign _506 = _422 & _505;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_13 <= _356;
        else
            if (_506)
                t0_rx_mem_13 <= _49;
    end
    assign _499 = t0_rx_wr == _663;
    assign _500 = _422 & _499;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_12 <= _356;
        else
            if (_500)
                t0_rx_mem_12 <= _49;
    end
    assign _493 = t0_rx_wr == _657;
    assign _494 = _422 & _493;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_11 <= _356;
        else
            if (_494)
                t0_rx_mem_11 <= _49;
    end
    assign _487 = t0_rx_wr == _651;
    assign _488 = _422 & _487;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_10 <= _356;
        else
            if (_488)
                t0_rx_mem_10 <= _49;
    end
    assign _481 = t0_rx_wr == _645;
    assign _482 = _422 & _481;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_9 <= _356;
        else
            if (_482)
                t0_rx_mem_9 <= _49;
    end
    assign _475 = t0_rx_wr == _639;
    assign _476 = _422 & _475;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_8 <= _356;
        else
            if (_476)
                t0_rx_mem_8 <= _49;
    end
    assign _469 = t0_rx_wr == _633;
    assign _470 = _422 & _469;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_7 <= _356;
        else
            if (_470)
                t0_rx_mem_7 <= _49;
    end
    assign _463 = t0_rx_wr == _627;
    assign _464 = _422 & _463;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_6 <= _356;
        else
            if (_464)
                t0_rx_mem_6 <= _49;
    end
    assign _457 = t0_rx_wr == _621;
    assign _458 = _422 & _457;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_5 <= _356;
        else
            if (_458)
                t0_rx_mem_5 <= _49;
    end
    assign _451 = t0_rx_wr == _615;
    assign _452 = _422 & _451;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_4 <= _356;
        else
            if (_452)
                t0_rx_mem_4 <= _49;
    end
    assign _445 = t0_rx_wr == _609;
    assign _446 = _422 & _445;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_3 <= _356;
        else
            if (_446)
                t0_rx_mem_3 <= _49;
    end
    assign _439 = t0_rx_wr == _603;
    assign _440 = _422 & _439;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_2 <= _356;
        else
            if (_440)
                t0_rx_mem_2 <= _49;
    end
    assign _433 = t0_rx_wr == _597;
    assign _434 = _422 & _433;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_1 <= _356;
        else
            if (_434)
                t0_rx_mem_1 <= _49;
    end
    assign _3611 = t0_rx_wr + _597;
    assign _3612 = _422 ? _3611 : t0_rx_wr;
    assign _43 = _3612;
    always @(posedge _99) begin
        if (_97)
            t0_rx_wr <= _591;
        else
            t0_rx_wr <= _43;
    end
    assign _427 = t0_rx_wr == _591;
    assign _428 = _422 & _427;
    assign _3890 = _3889[15:0];
    assign _3892 = { _3890,
                     _356 };
    assign _3886 = _3885[23:0];
    assign _3888 = { _3886,
                     _305 };
    assign _3882 = _3881[27:0];
    assign _3884 = { _3882,
                     _591 };
    assign _3878 = _3877[29:0];
    assign _3880 = { _3878,
                     _297 };
    assign _3874 = t0_isr_count[0:0];
    assign _3877 = _3874 ? _294 : _293;
    assign _3873 = t0_isr_count[1:1];
    assign _3881 = _3873 ? _3880 : _3877;
    assign _3872 = t0_isr_count[2:2];
    assign _3885 = _3872 ? _3884 : _3881;
    assign _3871 = t0_isr_count[3:3];
    assign _3889 = _3871 ? _3888 : _3885;
    assign _3870 = t0_isr_count[4:4];
    assign _3893 = _3870 ? _3892 : _3889;
    assign _3894 = _3893[15:0];
    assign _3895 = ~ _3894;
    assign _3896 = t0_isr & _3895;
    assign _3866 = _3864[31:16];
    assign _3867 = { _356,
                     _3866 };
    assign _3862 = _3860[31:8];
    assign _3863 = { _305,
                     _3862 };
    assign _3858 = _3856[31:4];
    assign _3859 = { _591,
                     _3858 };
    assign _3854 = _3852[31:2];
    assign _3855 = { _297,
                     _3854 };
    assign _3850 = _3848[31:1];
    assign _3851 = { _716,
                     _3850 };
    assign _3803 = _3752 & _2834;
    assign _3798 = _3797[15:0];
    assign _3800 = { _3798,
                     _356 };
    assign _3794 = _3793[23:0];
    assign _3796 = { _3794,
                     _305 };
    assign _3790 = _3789[27:0];
    assign _3792 = { _3790,
                     _591 };
    assign _3786 = _3785[29:0];
    assign _3788 = { _3786,
                     _297 };
    assign _3782 = _3781[30:0];
    assign _3784 = { _3782,
                     _716 };
    assign _3781 = { _356,
                     t0_isr };
    assign _3779 = _2464[0:0];
    assign _3785 = _3779 ? _3784 : _3781;
    assign _3778 = _2464[1:1];
    assign _3789 = _3778 ? _3788 : _3785;
    assign _3777 = _2464[2:2];
    assign _3793 = _3777 ? _3792 : _3789;
    assign _3776 = _2464[3:3];
    assign _3797 = _3776 ? _3796 : _3793;
    assign _3775 = _2464[4:4];
    assign _3801 = _3775 ? _3800 : _3797;
    assign _3802 = _3801[15:0];
    assign _3804 = _3802 | _3803;
    assign _3771 = _3769[31:16];
    assign _3772 = { _356,
                     _3771 };
    assign _3767 = _3765[31:8];
    assign _3768 = { _305,
                     _3767 };
    assign _3763 = _3761[31:4];
    assign _3764 = { _591,
                     _3763 };
    assign _3759 = _3757[31:2];
    assign _3760 = { _297,
                     _3759 };
    assign _3755 = _3753[31:1];
    assign _3756 = { _716,
                     _3755 };
    assign _3747 = _585 < _2464;
    assign _3744 = _2352[7:7];
    assign _3743 = _2352[6:6];
    assign _3742 = _2352[5:5];
    assign _3741 = _2352[4:4];
    assign _3740 = _2352[3:3];
    assign _3739 = _2352[2:2];
    assign _3738 = _2352[1:1];
    assign _3737 = _2352[0:0];
    always @* begin
        case (cfg_t0_in_base)
        0:
            _3745 <= _3737;
        1:
            _3745 <= _3738;
        2:
            _3745 <= _3739;
        3:
            _3745 <= _3740;
        4:
            _3745 <= _3741;
        5:
            _3745 <= _3742;
        6:
            _3745 <= _3743;
        default:
            _3745 <= _3744;
        endcase
    end
    assign _3748 = _3745 & _3747;
    assign _3735 = _3488 < _2464;
    assign _3732 = _2352[7:7];
    assign _3731 = _2352[6:6];
    assign _3730 = _2352[5:5];
    assign _3729 = _2352[4:4];
    assign _3728 = _2352[3:3];
    assign _3727 = _2352[2:2];
    assign _3726 = _2352[1:1];
    assign _3725 = _2352[0:0];
    assign _3724 = cfg_t0_in_base + _2395;
    always @* begin
        case (_3724)
        0:
            _3733 <= _3725;
        1:
            _3733 <= _3726;
        2:
            _3733 <= _3727;
        3:
            _3733 <= _3728;
        4:
            _3733 <= _3729;
        5:
            _3733 <= _3730;
        6:
            _3733 <= _3731;
        default:
            _3733 <= _3732;
        endcase
    end
    assign _3736 = _3733 & _3735;
    assign _3721 = _3474 < _2464;
    assign _3718 = _2352[7:7];
    assign _3717 = _2352[6:6];
    assign _3716 = _2352[5:5];
    assign _3715 = _2352[4:4];
    assign _3714 = _2352[3:3];
    assign _3713 = _2352[2:2];
    assign _3712 = _2352[1:1];
    assign _3711 = _2352[0:0];
    assign _3710 = cfg_t0_in_base + _5102;
    always @* begin
        case (_3710)
        0:
            _3719 <= _3711;
        1:
            _3719 <= _3712;
        2:
            _3719 <= _3713;
        3:
            _3719 <= _3714;
        4:
            _3719 <= _3715;
        5:
            _3719 <= _3716;
        6:
            _3719 <= _3717;
        default:
            _3719 <= _3718;
        endcase
    end
    assign _3722 = _3719 & _3721;
    assign _3707 = _3460 < _2464;
    assign _3704 = _2352[7:7];
    assign _3703 = _2352[6:6];
    assign _3702 = _2352[5:5];
    assign _3701 = _2352[4:4];
    assign _3700 = _2352[3:3];
    assign _3699 = _2352[2:2];
    assign _3698 = _2352[1:1];
    assign _3697 = _2352[0:0];
    assign _3696 = cfg_t0_in_base + _4761;
    always @* begin
        case (_3696)
        0:
            _3705 <= _3697;
        1:
            _3705 <= _3698;
        2:
            _3705 <= _3699;
        3:
            _3705 <= _3700;
        4:
            _3705 <= _3701;
        5:
            _3705 <= _3702;
        6:
            _3705 <= _3703;
        default:
            _3705 <= _3704;
        endcase
    end
    assign _3708 = _3705 & _3707;
    assign _3693 = _3446 < _2464;
    assign _3690 = _2352[7:7];
    assign _3689 = _2352[6:6];
    assign _3688 = _2352[5:5];
    assign _3687 = _2352[4:4];
    assign _3686 = _2352[3:3];
    assign _3685 = _2352[2:2];
    assign _3684 = _2352[1:1];
    assign _3683 = _2352[0:0];
    assign _3682 = cfg_t0_in_base + _5182;
    always @* begin
        case (_3682)
        0:
            _3691 <= _3683;
        1:
            _3691 <= _3684;
        2:
            _3691 <= _3685;
        3:
            _3691 <= _3686;
        4:
            _3691 <= _3687;
        5:
            _3691 <= _3688;
        6:
            _3691 <= _3689;
        default:
            _3691 <= _3690;
        endcase
    end
    assign _3694 = _3691 & _3693;
    assign _3679 = _3432 < _2464;
    assign _3676 = _2352[7:7];
    assign _3675 = _2352[6:6];
    assign _3674 = _2352[5:5];
    assign _3673 = _2352[4:4];
    assign _3672 = _2352[3:3];
    assign _3671 = _2352[2:2];
    assign _3670 = _2352[1:1];
    assign _3669 = _2352[0:0];
    assign _3668 = cfg_t0_in_base + _4727;
    always @* begin
        case (_3668)
        0:
            _3677 <= _3669;
        1:
            _3677 <= _3670;
        2:
            _3677 <= _3671;
        3:
            _3677 <= _3672;
        4:
            _3677 <= _3673;
        5:
            _3677 <= _3674;
        6:
            _3677 <= _3675;
        default:
            _3677 <= _3676;
        endcase
    end
    assign _3680 = _3677 & _3679;
    assign _3665 = _3418 < _2464;
    assign _3662 = _2352[7:7];
    assign _3661 = _2352[6:6];
    assign _3660 = _2352[5:5];
    assign _3659 = _2352[4:4];
    assign _3658 = _2352[3:3];
    assign _3657 = _2352[2:2];
    assign _3656 = _2352[1:1];
    assign _3655 = _2352[0:0];
    assign _3654 = cfg_t0_in_base + _4710;
    always @* begin
        case (_3654)
        0:
            _3663 <= _3655;
        1:
            _3663 <= _3656;
        2:
            _3663 <= _3657;
        3:
            _3663 <= _3658;
        4:
            _3663 <= _3659;
        5:
            _3663 <= _3660;
        6:
            _3663 <= _3661;
        default:
            _3663 <= _3662;
        endcase
    end
    assign _3666 = _3663 & _3665;
    assign _3651 = _3404 < _2464;
    assign _3648 = _2352[7:7];
    assign _3647 = _2352[6:6];
    assign _3646 = _2352[5:5];
    assign _3645 = _2352[4:4];
    assign _3644 = _2352[3:3];
    assign _3643 = _2352[2:2];
    assign _3642 = _2352[1:1];
    assign _3641 = _2352[0:0];
    assign _3617 = _732[2:0];
    assign _3614 = 7'b1000100;
    assign _3615 = _728 == _3614;
    assign _3613 = _722 & _726;
    assign _3616 = _3613 & _3615;
    assign _3618 = _3616 ? _3617 : cfg_t0_in_base;
    assign _44 = _3618;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_in_base <= _5137;
        else
            cfg_t0_in_base <= _44;
    end
    assign _3640 = cfg_t0_in_base + _4552;
    always @* begin
        case (_3640)
        0:
            _3649 <= _3641;
        1:
            _3649 <= _3642;
        2:
            _3649 <= _3643;
        3:
            _3649 <= _3644;
        4:
            _3649 <= _3645;
        5:
            _3649 <= _3646;
        6:
            _3649 <= _3647;
        default:
            _3649 <= _3648;
        endcase
    end
    assign _3652 = _3649 & _3651;
    assign _3749 = { _3652,
                     _3666,
                     _3680,
                     _3694,
                     _3708,
                     _3722,
                     _3736,
                     _3748 };
    assign _3750 = { _305,
                     _3749 };
    assign _3637 = _2298[8:7];
    always @* begin
        case (_3637)
        0:
            _3752 <= _3750;
        1:
            _3752 <= t0_x;
        2:
            _3752 <= t0_y;
        default:
            _3752 <= _356;
        endcase
    end
    assign _3753 = { _3752,
                     t0_isr };
    assign _3636 = _2464[0:0];
    assign _3757 = _3636 ? _3756 : _3753;
    assign _3635 = _2464[1:1];
    assign _3761 = _3635 ? _3760 : _3757;
    assign _3634 = _2464[2:2];
    assign _3765 = _3634 ? _3764 : _3761;
    assign _3633 = _2464[3:3];
    assign _3769 = _3633 ? _3768 : _3765;
    assign _3632 = _2464[4:4];
    assign _3773 = _3632 ? _3772 : _3769;
    assign _3774 = _3773[15:0];
    assign _3805 = _3631 ? _3804 : _3774;
    assign _3629 = _2404 ? t0_isr : _356;
    assign _3624 = _2441 == _4761;
    assign _3625 = _3624 ? _2684 : t0_isr;
    assign _3626 = _2447 ? _3625 : t0_isr;
    assign _3622 = _2299 == _4727;
    assign _3627 = _3622 ? _3626 : t0_isr;
    assign _3621 = _2299 == _5182;
    assign _3630 = _3621 ? _3629 : _3627;
    assign _3620 = _2299 == _5102;
    assign _3806 = _3620 ? _3805 : _3630;
    assign _3807 = _2417 ? _3806 : t0_isr;
    assign _3808 = _754 ? t0_isr : _3807;
    assign _3809 = _748 ? t0_isr : _3808;
    assign _3811 = _742 ? _356 : _3809;
    assign _45 = _3811;
    assign _46 = _45;
    always @(posedge _99) begin
        if (_97)
            t0_isr <= _356;
        else
            t0_isr <= _46;
    end
    assign _3848 = { _356,
                     t0_isr };
    assign _3846 = _3841[0:0];
    assign _3852 = _3846 ? _3851 : _3848;
    assign _3845 = _3841[1:1];
    assign _3856 = _3845 ? _3855 : _3852;
    assign _3844 = _3841[2:2];
    assign _3860 = _3844 ? _3859 : _3856;
    assign _3843 = _3841[3:3];
    assign _3864 = _3843 ? _3863 : _3860;
    assign _3831 = _3829[4:0];
    assign _3828 = { gnd,
                     _2464 };
    assign _3827 = { gnd,
                     t0_isr_count };
    assign _3829 = _3827 + _3828;
    assign _3830 = _2457 < _3829;
    assign _3833 = _3830 ? _252 : _3831;
    assign _3824 = _2404 ? t0_isr_count : _585;
    assign _3818 = _2441 == _4761;
    assign _3820 = _3818 ? _585 : t0_isr_count;
    assign _3821 = _2447 ? _3820 : t0_isr_count;
    assign _3817 = _2299 == _4727;
    assign _3822 = _3817 ? _3821 : t0_isr_count;
    assign _3816 = _2299 == _5182;
    assign _3825 = _3816 ? _3824 : _3822;
    assign _3815 = _2299 == _5102;
    assign _3834 = _3815 ? _3833 : _3825;
    assign _3835 = _2417 ? _3834 : t0_isr_count;
    assign _3836 = _754 ? t0_isr_count : _3835;
    assign _3837 = _748 ? t0_isr_count : _3836;
    assign _3839 = _742 ? _585 : _3837;
    assign _47 = _3839;
    assign _48 = _47;
    always @(posedge _99) begin
        if (_97)
            t0_isr_count <= _585;
        else
            t0_isr_count <= _48;
    end
    assign _3841 = _252 - t0_isr_count;
    assign _3842 = _3841[4:4];
    assign _3868 = _3842 ? _3867 : _3864;
    assign _3869 = _3868[15:0];
    assign _3631 = cfg_t0_shift[1:1];
    assign _3897 = _3631 ? _3896 : _3869;
    assign _49 = _3897;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_0 <= _356;
        else
            if (_428)
                t0_rx_mem_0 <= _49;
    end
    assign _3916 = t0_rx_rd + _597;
    assign _3913 = ~ _3912;
    assign _3908 = ~ _3596;
    assign _3905 = t0_rx_level == _585;
    assign _3906 = ~ _3905;
    assign _3901 = 7'b1001001;
    assign _370 = _369[6:0];
    assign _3902 = _370 == _3901;
    assign _3898 = _369[7:7];
    assign _3899 = ~ _3898;
    assign _3151 = host_bit_count == _3404;
    assign _3152 = _354 & _3151;
    assign _3900 = _3152 & _3899;
    assign _3903 = _3900 & _3902;
    assign _3907 = _3903 & _3906;
    assign _50 = _3907;
    assign _3909 = _50 & _3908;
    assign _3910 = _103 | _3909;
    assign _3914 = _3910 & _3913;
    assign _3917 = _3914 ? _3916 : t0_rx_rd;
    assign _51 = _3917;
    always @(posedge _99) begin
        if (_97)
            t0_rx_rd <= _591;
        else
            t0_rx_rd <= _51;
    end
    always @* begin
        case (t0_rx_rd)
        0:
            _520 <= t0_rx_mem_0;
        1:
            _520 <= t0_rx_mem_1;
        2:
            _520 <= t0_rx_mem_2;
        3:
            _520 <= t0_rx_mem_3;
        4:
            _520 <= t0_rx_mem_4;
        5:
            _520 <= t0_rx_mem_5;
        6:
            _520 <= t0_rx_mem_6;
        7:
            _520 <= t0_rx_mem_7;
        8:
            _520 <= t0_rx_mem_8;
        9:
            _520 <= t0_rx_mem_9;
        10:
            _520 <= t0_rx_mem_10;
        11:
            _520 <= t0_rx_mem_11;
        12:
            _520 <= t0_rx_mem_12;
        13:
            _520 <= t0_rx_mem_13;
        14:
            _520 <= t0_rx_mem_14;
        default:
            _520 <= t0_rx_mem_15;
        endcase
    end
    assign _52 = _520;
    assign _3939 = _103 ? _52 : _732;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_0 <= _356;
        else
            if (_3944)
                t1_tx_mem_0 <= _3939;
    end
    assign _3930 = t1_tx_rd + _597;
    assign _3924 = ~ _3261;
    assign _3261 = t1_tx_level == _585;
    assign _3922 = ~ _3261;
    assign _3919 = _3177 == _5182;
    assign _3920 = _3175 & _3919;
    assign _3921 = _3920 & _3181;
    assign _3923 = _3921 & _3922;
    assign _53 = _3923;
    assign _3925 = _53 & _3924;
    assign _3931 = _3925 ? _3930 : t1_tx_rd;
    assign _54 = _3931;
    always @(posedge _99) begin
        if (_97)
            t1_tx_rd <= _591;
        else
            t1_tx_rd <= _54;
    end
    always @* begin
        case (t1_tx_rd)
        0:
            _4036 <= t1_tx_mem_0;
        1:
            _4036 <= t1_tx_mem_1;
        2:
            _4036 <= t1_tx_mem_2;
        3:
            _4036 <= t1_tx_mem_3;
        4:
            _4036 <= t1_tx_mem_4;
        5:
            _4036 <= t1_tx_mem_5;
        6:
            _4036 <= t1_tx_mem_6;
        7:
            _4036 <= t1_tx_mem_7;
        8:
            _4036 <= t1_tx_mem_8;
        9:
            _4036 <= t1_tx_mem_9;
        10:
            _4036 <= t1_tx_mem_10;
        11:
            _4036 <= t1_tx_mem_11;
        12:
            _4036 <= t1_tx_mem_12;
        13:
            _4036 <= t1_tx_mem_13;
        14:
            _4036 <= t1_tx_mem_14;
        default:
            _4036 <= t1_tx_mem_15;
        endcase
    end
    assign _3181 = _3176[8:8];
    assign _4037 = _3181 ? _4036 : t1_osr;
    assign _3935 = _3286 == _5182;
    assign _3936 = _3935 ? _3379 : t1_osr;
    assign _3937 = _3292 ? _3936 : t1_osr;
    assign _3934 = _3177 == _4727;
    assign _3938 = _3934 ? _3937 : t1_osr;
    assign _3933 = _3177 == _5182;
    assign _4038 = _3933 ? _4037 : _3938;
    assign _3932 = _3177 == _4761;
    assign _4097 = _3932 ? _4096 : _4038;
    assign _4098 = _3271 ? _4097 : t1_osr;
    assign _4099 = _3208 ? t1_osr : _4098;
    assign _4100 = _3205 ? t1_osr : _4099;
    assign _4102 = _3204 ? _356 : _4100;
    assign _55 = _4102;
    assign _56 = _55;
    always @(posedge _99) begin
        if (_97)
            t1_osr <= _356;
        else
            t1_osr <= _56;
    end
    assign _4131 = t1_osr & _3582;
    assign _4107 = _732[1:0];
    assign _4104 = 7'b1011111;
    assign _4105 = _728 == _4104;
    assign _4103 = _722 & _726;
    assign _4106 = _4103 & _4105;
    assign _4108 = _4106 ? _4107 : cfg_t1_shift;
    assign _57 = _4108;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_shift <= _297;
        else
            cfg_t1_shift <= _57;
    end
    assign _4039 = cfg_t1_shift[0:0];
    assign _4162 = _4039 ? _4161 : _4131;
    assign _4128 = _3176[8:7];
    assign _4130 = _4128 == _187;
    assign _4163 = _4130 ? _4162 : t1_y;
    assign _4124 = _3286 == _2395;
    assign _4125 = _4124 ? _3379 : t1_y;
    assign _4126 = _3292 ? _4125 : t1_y;
    assign _4117 = _4115 == _187;
    assign _4121 = _4117 ? _4120 : t1_y;
    assign _4114 = _3177 == _4710;
    assign _4122 = _4114 ? _4121 : t1_y;
    assign _4112 = _3177 == _4727;
    assign _4127 = _4112 ? _4126 : _4122;
    assign _4111 = _3177 == _4761;
    assign _4164 = _4111 ? _4163 : _4127;
    assign _4110 = _3177 == _5137;
    assign _4171 = _4110 ? _4170 : _4164;
    assign _4172 = _3271 ? _4171 : t1_y;
    assign _4173 = _3208 ? t1_y : _4172;
    assign _4174 = _3205 ? t1_y : _4173;
    assign _4176 = _3204 ? _356 : _4174;
    assign _58 = _4176;
    assign _59 = _58;
    always @(posedge _99) begin
        if (_97)
            t1_y <= _356;
        else
            t1_y <= _59;
    end
    always @* begin
        case (_3289)
        0:
            _3379 <= t1_x;
        1:
            _3379 <= t1_y;
        2:
            _3379 <= _3374;
        3:
            _3379 <= t1_isr;
        4:
            _3379 <= t1_osr;
        default:
            _3379 <= _356;
        endcase
    end
    assign _4186 = _3286 == _5137;
    assign _4187 = _4186 ? _3379 : t1_x;
    assign _3289 = _3176[5:3];
    assign _3291 = _3289 < _4710;
    assign _3286 = _3176[8:6];
    assign _3288 = _3286 < _4710;
    assign _3292 = _3288 & _3291;
    assign _4188 = _3292 ? _4187 : t1_x;
    assign _4119 = _3176[4:0];
    assign _4120 = { _575,
                     _4119 };
    assign _4115 = _3176[8:7];
    assign _4182 = _4115 == _184;
    assign _4183 = _4182 ? _4120 : t1_x;
    assign _4180 = _3177 == _4710;
    assign _4184 = _4180 ? _4183 : t1_x;
    assign _4179 = _3177 == _4727;
    assign _4189 = _4179 ? _4188 : _4184;
    assign _4178 = _3177 == _4761;
    assign _4193 = _4178 ? _4192 : _4189;
    assign _4177 = _3177 == _5137;
    assign _4199 = _4177 ? _4198 : _4193;
    assign _4200 = _3271 ? _4199 : t1_x;
    assign _4201 = _3208 ? t1_x : _4200;
    assign _4202 = _3205 ? t1_x : _4201;
    assign _4204 = _3204 ? _356 : _4202;
    assign _60 = _4204;
    assign _61 = _60;
    always @(posedge _99) begin
        if (_97)
            t1_x <= _356;
        else
            t1_x <= _61;
    end
    assign _4208 = t1_x == _356;
    assign _4209 = ~ _4208;
    assign _4210 = ~ _4209;
    assign _4165 = _3176[8:6];
    always @* begin
        case (_4165)
        0:
            _4219 <= vdd;
        1:
            _4219 <= _4210;
        2:
            _4219 <= _4209;
        3:
            _4219 <= _4214;
        4:
            _4219 <= _4213;
        5:
            _4219 <= _4216;
        6:
            _4219 <= _4217;
        default:
            _4219 <= _4218;
        endcase
    end
    assign _4206 = _3177 == _5137;
    assign _4220 = _4206 & _4219;
    assign _4226 = _4220 | _4225;
    assign _4235 = _4226 ? _4234 : _4228;
    assign _4236 = _3271 ? _4235 : t1_pc;
    assign _4237 = _3208 ? t1_pc : _4236;
    assign _4238 = _3205 ? t1_pc : _4237;
    assign _4239 = _3204 ? cfg_t1_start : _4238;
    assign _62 = _4239;
    assign _63 = _62;
    always @(posedge _99) begin
        if (_97)
            t1_pc <= _305;
        else
            t1_pc <= _63;
    end
    always @* begin
        case (t1_pc)
        0:
            _3176 <= prog_0;
        1:
            _3176 <= prog_1;
        2:
            _3176 <= prog_2;
        3:
            _3176 <= prog_3;
        4:
            _3176 <= prog_4;
        5:
            _3176 <= prog_5;
        6:
            _3176 <= prog_6;
        7:
            _3176 <= prog_7;
        8:
            _3176 <= prog_8;
        9:
            _3176 <= prog_9;
        10:
            _3176 <= prog_10;
        11:
            _3176 <= prog_11;
        12:
            _3176 <= prog_12;
        13:
            _3176 <= prog_13;
        14:
            _3176 <= prog_14;
        15:
            _3176 <= prog_15;
        16:
            _3176 <= prog_16;
        17:
            _3176 <= prog_17;
        18:
            _3176 <= prog_18;
        19:
            _3176 <= prog_19;
        20:
            _3176 <= prog_20;
        21:
            _3176 <= prog_21;
        22:
            _3176 <= prog_22;
        23:
            _3176 <= prog_23;
        24:
            _3176 <= prog_24;
        25:
            _3176 <= prog_25;
        26:
            _3176 <= prog_26;
        27:
            _3176 <= prog_27;
        28:
            _3176 <= prog_28;
        29:
            _3176 <= prog_29;
        30:
            _3176 <= prog_30;
        31:
            _3176 <= prog_31;
        32:
            _3176 <= prog_32;
        33:
            _3176 <= prog_33;
        34:
            _3176 <= prog_34;
        35:
            _3176 <= prog_35;
        36:
            _3176 <= prog_36;
        37:
            _3176 <= prog_37;
        38:
            _3176 <= prog_38;
        39:
            _3176 <= prog_39;
        40:
            _3176 <= prog_40;
        41:
            _3176 <= prog_41;
        42:
            _3176 <= prog_42;
        43:
            _3176 <= prog_43;
        44:
            _3176 <= prog_44;
        45:
            _3176 <= prog_45;
        46:
            _3176 <= prog_46;
        47:
            _3176 <= prog_47;
        48:
            _3176 <= prog_48;
        49:
            _3176 <= prog_49;
        50:
            _3176 <= prog_50;
        51:
            _3176 <= prog_51;
        52:
            _3176 <= prog_52;
        53:
            _3176 <= prog_53;
        54:
            _3176 <= prog_54;
        55:
            _3176 <= prog_55;
        56:
            _3176 <= prog_56;
        57:
            _3176 <= prog_57;
        58:
            _3176 <= prog_58;
        59:
            _3176 <= prog_59;
        60:
            _3176 <= prog_60;
        61:
            _3176 <= prog_61;
        62:
            _3176 <= prog_62;
        63:
            _3176 <= prog_63;
        64:
            _3176 <= prog_64;
        65:
            _3176 <= prog_65;
        66:
            _3176 <= prog_66;
        67:
            _3176 <= prog_67;
        68:
            _3176 <= prog_68;
        69:
            _3176 <= prog_69;
        70:
            _3176 <= prog_70;
        71:
            _3176 <= prog_71;
        72:
            _3176 <= prog_72;
        73:
            _3176 <= prog_73;
        74:
            _3176 <= prog_74;
        75:
            _3176 <= prog_75;
        76:
            _3176 <= prog_76;
        77:
            _3176 <= prog_77;
        78:
            _3176 <= prog_78;
        79:
            _3176 <= prog_79;
        80:
            _3176 <= prog_80;
        81:
            _3176 <= prog_81;
        82:
            _3176 <= prog_82;
        83:
            _3176 <= prog_83;
        84:
            _3176 <= prog_84;
        85:
            _3176 <= prog_85;
        86:
            _3176 <= prog_86;
        87:
            _3176 <= prog_87;
        88:
            _3176 <= prog_88;
        89:
            _3176 <= prog_89;
        90:
            _3176 <= prog_90;
        91:
            _3176 <= prog_91;
        92:
            _3176 <= prog_92;
        93:
            _3176 <= prog_93;
        94:
            _3176 <= prog_94;
        95:
            _3176 <= prog_95;
        96:
            _3176 <= prog_96;
        97:
            _3176 <= prog_97;
        98:
            _3176 <= prog_98;
        99:
            _3176 <= prog_99;
        100:
            _3176 <= prog_100;
        101:
            _3176 <= prog_101;
        102:
            _3176 <= prog_102;
        103:
            _3176 <= prog_103;
        104:
            _3176 <= prog_104;
        105:
            _3176 <= prog_105;
        106:
            _3176 <= prog_106;
        107:
            _3176 <= prog_107;
        108:
            _3176 <= prog_108;
        109:
            _3176 <= prog_109;
        110:
            _3176 <= prog_110;
        111:
            _3176 <= prog_111;
        112:
            _3176 <= prog_112;
        113:
            _3176 <= prog_113;
        114:
            _3176 <= prog_114;
        115:
            _3176 <= prog_115;
        116:
            _3176 <= prog_116;
        117:
            _3176 <= prog_117;
        118:
            _3176 <= prog_118;
        119:
            _3176 <= prog_119;
        120:
            _3176 <= prog_120;
        121:
            _3176 <= prog_121;
        122:
            _3176 <= prog_122;
        123:
            _3176 <= prog_123;
        124:
            _3176 <= prog_124;
        125:
            _3176 <= prog_125;
        126:
            _3176 <= prog_126;
        127:
            _3176 <= prog_127;
        128:
            _3176 <= prog_128;
        129:
            _3176 <= prog_129;
        130:
            _3176 <= prog_130;
        131:
            _3176 <= prog_131;
        132:
            _3176 <= prog_132;
        133:
            _3176 <= prog_133;
        134:
            _3176 <= prog_134;
        135:
            _3176 <= prog_135;
        136:
            _3176 <= prog_136;
        137:
            _3176 <= prog_137;
        138:
            _3176 <= prog_138;
        139:
            _3176 <= prog_139;
        140:
            _3176 <= prog_140;
        141:
            _3176 <= prog_141;
        142:
            _3176 <= prog_142;
        143:
            _3176 <= prog_143;
        144:
            _3176 <= prog_144;
        145:
            _3176 <= prog_145;
        146:
            _3176 <= prog_146;
        147:
            _3176 <= prog_147;
        148:
            _3176 <= prog_148;
        149:
            _3176 <= prog_149;
        150:
            _3176 <= prog_150;
        151:
            _3176 <= prog_151;
        152:
            _3176 <= prog_152;
        153:
            _3176 <= prog_153;
        154:
            _3176 <= prog_154;
        155:
            _3176 <= prog_155;
        156:
            _3176 <= prog_156;
        157:
            _3176 <= prog_157;
        158:
            _3176 <= prog_158;
        159:
            _3176 <= prog_159;
        160:
            _3176 <= prog_160;
        161:
            _3176 <= prog_161;
        162:
            _3176 <= prog_162;
        163:
            _3176 <= prog_163;
        164:
            _3176 <= prog_164;
        165:
            _3176 <= prog_165;
        166:
            _3176 <= prog_166;
        167:
            _3176 <= prog_167;
        168:
            _3176 <= prog_168;
        169:
            _3176 <= prog_169;
        170:
            _3176 <= prog_170;
        171:
            _3176 <= prog_171;
        172:
            _3176 <= prog_172;
        173:
            _3176 <= prog_173;
        174:
            _3176 <= prog_174;
        175:
            _3176 <= prog_175;
        176:
            _3176 <= prog_176;
        177:
            _3176 <= prog_177;
        178:
            _3176 <= prog_178;
        179:
            _3176 <= prog_179;
        180:
            _3176 <= prog_180;
        181:
            _3176 <= prog_181;
        182:
            _3176 <= prog_182;
        183:
            _3176 <= prog_183;
        184:
            _3176 <= prog_184;
        185:
            _3176 <= prog_185;
        186:
            _3176 <= prog_186;
        187:
            _3176 <= prog_187;
        188:
            _3176 <= prog_188;
        189:
            _3176 <= prog_189;
        190:
            _3176 <= prog_190;
        191:
            _3176 <= prog_191;
        192:
            _3176 <= prog_192;
        193:
            _3176 <= prog_193;
        194:
            _3176 <= prog_194;
        195:
            _3176 <= prog_195;
        196:
            _3176 <= prog_196;
        197:
            _3176 <= prog_197;
        198:
            _3176 <= prog_198;
        199:
            _3176 <= prog_199;
        200:
            _3176 <= prog_200;
        201:
            _3176 <= prog_201;
        202:
            _3176 <= prog_202;
        203:
            _3176 <= prog_203;
        204:
            _3176 <= prog_204;
        205:
            _3176 <= prog_205;
        206:
            _3176 <= prog_206;
        207:
            _3176 <= prog_207;
        208:
            _3176 <= prog_208;
        209:
            _3176 <= prog_209;
        210:
            _3176 <= prog_210;
        211:
            _3176 <= prog_211;
        212:
            _3176 <= prog_212;
        213:
            _3176 <= prog_213;
        214:
            _3176 <= prog_214;
        215:
            _3176 <= prog_215;
        216:
            _3176 <= prog_216;
        217:
            _3176 <= prog_217;
        218:
            _3176 <= prog_218;
        219:
            _3176 <= prog_219;
        220:
            _3176 <= prog_220;
        221:
            _3176 <= prog_221;
        222:
            _3176 <= prog_222;
        223:
            _3176 <= prog_223;
        224:
            _3176 <= prog_224;
        225:
            _3176 <= prog_225;
        226:
            _3176 <= prog_226;
        227:
            _3176 <= prog_227;
        228:
            _3176 <= prog_228;
        229:
            _3176 <= prog_229;
        230:
            _3176 <= prog_230;
        231:
            _3176 <= prog_231;
        232:
            _3176 <= prog_232;
        233:
            _3176 <= prog_233;
        234:
            _3176 <= prog_234;
        235:
            _3176 <= prog_235;
        236:
            _3176 <= prog_236;
        237:
            _3176 <= prog_237;
        238:
            _3176 <= prog_238;
        239:
            _3176 <= prog_239;
        240:
            _3176 <= prog_240;
        241:
            _3176 <= prog_241;
        242:
            _3176 <= prog_242;
        243:
            _3176 <= prog_243;
        244:
            _3176 <= prog_244;
        245:
            _3176 <= prog_245;
        246:
            _3176 <= prog_246;
        247:
            _3176 <= prog_247;
        248:
            _3176 <= prog_248;
        249:
            _3176 <= prog_249;
        250:
            _3176 <= prog_250;
        251:
            _3176 <= prog_251;
        252:
            _3176 <= prog_252;
        253:
            _3176 <= prog_253;
        254:
            _3176 <= prog_254;
        default:
            _3176 <= prog_255;
        endcase
    end
    assign _3177 = _3176[15:13];
    assign _3251 = _3177 == _2395;
    assign _3253 = _3251 & _3252;
    assign _3256 = _3253 & _3255;
    assign _3263 = _3256 | _3262;
    assign _3269 = _3263 | _3268;
    assign _3270 = ~ _3269;
    assign _3174 = t1_delay_left == _591;
    assign _3169 = _3163 & _3168;
    assign _3175 = _3169 & _3174;
    assign _3271 = _3175 & _3270;
    assign _4252 = _3271 ? _4251 : t1_delay_left;
    assign _4255 = _3208 ? _4254 : _4252;
    assign _4256 = _3205 ? t1_delay_left : _4255;
    assign _4258 = _3204 ? _591 : _4256;
    assign _64 = _4258;
    assign _65 = _64;
    always @(posedge _99) begin
        if (_97)
            t1_delay_left <= _591;
        else
            t1_delay_left <= _65;
    end
    assign _3207 = t1_delay_left == _591;
    assign _3208 = ~ _3207;
    assign _4830 = _3208 ? _22 : _4829;
    assign _4270 = cfg_t1_clkdiv - _2379;
    assign _4260 = 7'b1011101;
    assign _4261 = _728 == _4260;
    assign _4259 = _722 & _726;
    assign _4262 = _4259 & _4261;
    assign _4263 = _4262 ? _732 : cfg_t1_clkdiv;
    assign _66 = _4263;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_clkdiv <= _356;
        else
            cfg_t1_clkdiv <= _66;
    end
    assign _4268 = cfg_t1_clkdiv == _356;
    assign _4272 = _4268 ? _356 : _4270;
    assign _4266 = t1_div_count - _2379;
    assign _4273 = _3168 ? _4272 : _4266;
    assign _4264 = ~ _3163;
    assign _4275 = _4264 ? _356 : _4273;
    assign _67 = _4275;
    always @(posedge _99) begin
        if (_97)
            t1_div_count <= _356;
        else
            t1_div_count <= _67;
    end
    assign _3168 = t1_div_count == _356;
    assign _3205 = ~ _3168;
    assign _4831 = _3205 ? _22 : _4830;
    assign _3163 = cfg_ctrl[1:1];
    assign _3204 = ~ _3163;
    assign _4832 = _3204 ? _22 : _4831;
    assign _68 = _4832;
    assign _69 = _68;
    always @(posedge _99) begin
        if (_97)
            pin_out <= _117;
        else
            pin_out <= _69;
    end
    assign _2314 = pin_out[7:7];
    assign _2310 = ~ cfg_sync_bypass;
    always @(posedge _99) begin
        if (_97)
            pins_sync1 <= _117;
        else
            pins_sync1 <= _72;
    end
    always @(posedge _99) begin
        if (_97)
            pins_sync2 <= _117;
        else
            pins_sync2 <= pins_sync1;
    end
    assign _2311 = pins_sync2 & _2310;
    assign _4837 = _732[7:0];
    assign _4834 = 7'b1001110;
    assign _4835 = _728 == _4834;
    assign _4833 = _722 & _726;
    assign _4836 = _4833 & _4835;
    assign _4838 = _4836 ? _4837 : cfg_sync_bypass;
    assign _70 = _4838;
    always @(posedge _99) begin
        if (_97)
            cfg_sync_bypass <= _305;
        else
            cfg_sync_bypass <= _70;
    end
    assign _72 = uio_in;
    assign _2304 = _72 & cfg_sync_bypass;
    assign _2312 = _2304 | _2311;
    assign _2313 = _2312[7:7];
    assign _4840 = 7'b1000111;
    assign _4841 = _728 == _4840;
    assign _4839 = _722 & _726;
    assign _4842 = _4839 & _4841;
    assign _4843 = _4842 ? _732 : cfg_pin_modes;
    assign _73 = _4843;
    always @(posedge _99) begin
        if (_97)
            cfg_pin_modes <= _356;
        else
            cfg_pin_modes <= _73;
    end
    assign _2303 = cfg_pin_modes[15:14];
    always @* begin
        case (_2303)
        0:
            _2316 <= _2313;
        1:
            _2316 <= _2314;
        2:
            _2316 <= _2315;
        default:
            _2316 <= _2313;
        endcase
    end
    assign _2352 = { _2316,
                     _2321,
                     _2326,
                     _2331,
                     _2336,
                     _2341,
                     _2346,
                     _2351 };
    assign _2676 = { _305,
                     _2352 };
    assign _5077 = t0_y - _2379;
    assign _5075 = _5073 == _5182;
    assign _5078 = _5075 ? _5077 : t0_y;
    assign _2862 = _2860[31:16];
    assign _2863 = { _356,
                     _2862 };
    assign _2858 = _2856[31:8];
    assign _2859 = { _305,
                     _2858 };
    assign _2854 = _2852[31:4];
    assign _2855 = { _591,
                     _2854 };
    assign _2850 = _2848[31:2];
    assign _2851 = { _297,
                     _2850 };
    assign _2846 = _2844[31:1];
    assign _2847 = { _716,
                     _2846 };
    assign _2844 = { _356,
                     t0_osr };
    assign _2842 = _2837[0:0];
    assign _2848 = _2842 ? _2847 : _2844;
    assign _2841 = _2837[1:1];
    assign _2852 = _2841 ? _2851 : _2848;
    assign _2840 = _2837[2:2];
    assign _2856 = _2840 ? _2855 : _2852;
    assign _2839 = _2837[3:3];
    assign _2860 = _2839 ? _2859 : _2856;
    assign _2837 = _252 - _2464;
    assign _2838 = _2837[4:4];
    assign _2864 = _2838 ? _2863 : _2860;
    assign _2865 = _2864[15:0];
    assign _2829 = _2828[15:0];
    assign _2831 = { _2829,
                     _356 };
    assign _2825 = _2824[23:0];
    assign _2827 = { _2825,
                     _305 };
    assign _2821 = _2820[27:0];
    assign _2823 = { _2821,
                     _591 };
    assign _2817 = _2816[29:0];
    assign _2819 = { _2817,
                     _297 };
    assign _2813 = _2464[0:0];
    assign _2816 = _2813 ? _294 : _293;
    assign _2812 = _2464[1:1];
    assign _2820 = _2812 ? _2819 : _2816;
    assign _2811 = _2464[2:2];
    assign _2824 = _2811 ? _2823 : _2820;
    assign _2810 = _2464[3:3];
    assign _2828 = _2810 ? _2827 : _2824;
    assign _2809 = _2464[4:4];
    assign _2832 = _2809 ? _2831 : _2828;
    assign _2833 = _2832[15:0];
    assign _2834 = ~ _2833;
    assign _5035 = _5034[15:0];
    assign _5037 = { _5035,
                     _356 };
    assign _5031 = _5030[23:0];
    assign _5033 = { _5031,
                     _305 };
    assign _5027 = _5026[27:0];
    assign _5029 = { _5027,
                     _591 };
    assign _5023 = _5022[29:0];
    assign _5025 = { _5023,
                     _297 };
    assign _5019 = _5018[30:0];
    assign _5021 = { _5019,
                     _716 };
    assign _5018 = { _356,
                     t0_osr };
    assign _5016 = _2464[0:0];
    assign _5022 = _5016 ? _5021 : _5018;
    assign _5015 = _2464[1:1];
    assign _5026 = _5015 ? _5025 : _5022;
    assign _5014 = _2464[2:2];
    assign _5030 = _5014 ? _5029 : _5026;
    assign _5013 = _2464[3:3];
    assign _5034 = _5013 ? _5033 : _5030;
    assign _5012 = _2464[4:4];
    assign _5038 = _5012 ? _5037 : _5034;
    assign _5039 = _5038[15:0];
    assign _5008 = _5006[31:16];
    assign _5009 = { _356,
                     _5008 };
    assign _5004 = _5002[31:8];
    assign _5005 = { _305,
                     _5004 };
    assign _5000 = _4998[31:4];
    assign _5001 = { _591,
                     _5000 };
    assign _4996 = _4994[31:2];
    assign _4997 = { _297,
                     _4996 };
    assign _4992 = _4990[31:1];
    assign _4993 = { _716,
                     _4992 };
    assign _4990 = { _356,
                     t0_osr };
    assign _4988 = _2464[0:0];
    assign _4994 = _4988 ? _4993 : _4990;
    assign _4987 = _2464[1:1];
    assign _4998 = _4987 ? _4997 : _4994;
    assign _4986 = _2464[2:2];
    assign _5002 = _4986 ? _5001 : _4998;
    assign _4985 = _2464[3:3];
    assign _5006 = _4985 ? _5005 : _5002;
    assign _2462 = { gnd,
                     _2459 };
    assign _2459 = _2298[3:0];
    assign _2461 = _2459 == _591;
    assign _2464 = _2461 ? _252 : _2462;
    assign _4984 = _2464[4:4];
    assign _5010 = _4984 ? _5009 : _5006;
    assign _5011 = _5010[15:0];
    assign _5040 = _2808 ? _5039 : _5011;
    assign _4978 = t0_tx_wr == _681;
    assign _4979 = _4851 & _4978;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_15 <= _356;
        else
            if (_4979)
                t0_tx_mem_15 <= _732;
    end
    assign _4972 = t0_tx_wr == _675;
    assign _4973 = _4851 & _4972;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_14 <= _356;
        else
            if (_4973)
                t0_tx_mem_14 <= _732;
    end
    assign _4966 = t0_tx_wr == _669;
    assign _4967 = _4851 & _4966;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_13 <= _356;
        else
            if (_4967)
                t0_tx_mem_13 <= _732;
    end
    assign _4960 = t0_tx_wr == _663;
    assign _4961 = _4851 & _4960;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_12 <= _356;
        else
            if (_4961)
                t0_tx_mem_12 <= _732;
    end
    assign _4954 = t0_tx_wr == _657;
    assign _4955 = _4851 & _4954;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_11 <= _356;
        else
            if (_4955)
                t0_tx_mem_11 <= _732;
    end
    assign _4948 = t0_tx_wr == _651;
    assign _4949 = _4851 & _4948;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_10 <= _356;
        else
            if (_4949)
                t0_tx_mem_10 <= _732;
    end
    assign _4942 = t0_tx_wr == _645;
    assign _4943 = _4851 & _4942;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_9 <= _356;
        else
            if (_4943)
                t0_tx_mem_9 <= _732;
    end
    assign _4936 = t0_tx_wr == _639;
    assign _4937 = _4851 & _4936;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_8 <= _356;
        else
            if (_4937)
                t0_tx_mem_8 <= _732;
    end
    assign _4930 = t0_tx_wr == _633;
    assign _4931 = _4851 & _4930;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_7 <= _356;
        else
            if (_4931)
                t0_tx_mem_7 <= _732;
    end
    assign _4924 = t0_tx_wr == _627;
    assign _4925 = _4851 & _4924;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_6 <= _356;
        else
            if (_4925)
                t0_tx_mem_6 <= _732;
    end
    assign _4918 = t0_tx_wr == _621;
    assign _4919 = _4851 & _4918;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_5 <= _356;
        else
            if (_4919)
                t0_tx_mem_5 <= _732;
    end
    assign _4912 = t0_tx_wr == _615;
    assign _4913 = _4851 & _4912;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_4 <= _356;
        else
            if (_4913)
                t0_tx_mem_4 <= _732;
    end
    assign _4906 = t0_tx_wr == _609;
    assign _4907 = _4851 & _4906;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_3 <= _356;
        else
            if (_4907)
                t0_tx_mem_3 <= _732;
    end
    assign _4900 = t0_tx_wr == _603;
    assign _4901 = _4851 & _4900;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_2 <= _356;
        else
            if (_4901)
                t0_tx_mem_2 <= _732;
    end
    assign _4894 = t0_tx_wr == _597;
    assign _4895 = _4851 & _4894;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_1 <= _356;
        else
            if (_4895)
                t0_tx_mem_1 <= _732;
    end
    assign _4856 = t0_tx_wr + _597;
    assign _4857 = _4851 ? _4856 : t0_tx_wr;
    assign _74 = _4857;
    always @(posedge _99) begin
        if (_97)
            t0_tx_wr <= _591;
        else
            t0_tx_wr <= _74;
    end
    assign _4888 = t0_tx_wr == _591;
    assign _4889 = _4851 & _4888;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_0 <= _356;
        else
            if (_4889)
                t0_tx_mem_0 <= _732;
    end
    assign _4876 = t0_tx_rd + _597;
    assign _4862 = ~ _2407;
    assign _4864 = { _591,
                     _4863 };
    assign _4849 = t0_tx_level == _252;
    assign _4850 = ~ _4849;
    assign _4845 = 7'b1001000;
    assign _4846 = _728 == _4845;
    assign _4844 = _722 & _726;
    assign _4847 = _4844 & _4846;
    assign _4851 = _4847 & _4850;
    assign _4859 = { _591,
                     _4851 };
    assign _4860 = t0_tx_level + _4859;
    assign _4865 = _4860 - _4864;
    assign _75 = _4865;
    always @(posedge _99) begin
        if (_97)
            t0_tx_level <= _585;
        else
            t0_tx_level <= _75;
    end
    assign _2407 = t0_tx_level == _585;
    assign _4870 = ~ _2407;
    assign _4867 = _2299 == _5182;
    assign _4868 = _2394 & _4867;
    assign _4869 = _4868 & _2404;
    assign _4871 = _4869 & _4870;
    assign _76 = _4871;
    assign _4863 = _76 & _4862;
    assign _4877 = _4863 ? _4876 : t0_tx_rd;
    assign _77 = _4877;
    always @(posedge _99) begin
        if (_97)
            t0_tx_rd <= _591;
        else
            t0_tx_rd <= _77;
    end
    always @* begin
        case (t0_tx_rd)
        0:
            _4981 <= t0_tx_mem_0;
        1:
            _4981 <= t0_tx_mem_1;
        2:
            _4981 <= t0_tx_mem_2;
        3:
            _4981 <= t0_tx_mem_3;
        4:
            _4981 <= t0_tx_mem_4;
        5:
            _4981 <= t0_tx_mem_5;
        6:
            _4981 <= t0_tx_mem_6;
        7:
            _4981 <= t0_tx_mem_7;
        8:
            _4981 <= t0_tx_mem_8;
        9:
            _4981 <= t0_tx_mem_9;
        10:
            _4981 <= t0_tx_mem_10;
        11:
            _4981 <= t0_tx_mem_11;
        12:
            _4981 <= t0_tx_mem_12;
        13:
            _4981 <= t0_tx_mem_13;
        14:
            _4981 <= t0_tx_mem_14;
        default:
            _4981 <= t0_tx_mem_15;
        endcase
    end
    assign _2404 = _2298[8:8];
    assign _4982 = _2404 ? _4981 : t0_osr;
    assign _4881 = _2441 == _5182;
    assign _4882 = _4881 ? _2684 : t0_osr;
    assign _4883 = _2447 ? _4882 : t0_osr;
    assign _4880 = _2299 == _4727;
    assign _4884 = _4880 ? _4883 : t0_osr;
    assign _4879 = _2299 == _5182;
    assign _4983 = _4879 ? _4982 : _4884;
    assign _4878 = _2299 == _4761;
    assign _5041 = _4878 ? _5040 : _4983;
    assign _5042 = _2417 ? _5041 : t0_osr;
    assign _5043 = _754 ? t0_osr : _5042;
    assign _5044 = _748 ? t0_osr : _5043;
    assign _5046 = _742 ? _356 : _5044;
    assign _78 = _5046;
    assign _79 = _78;
    always @(posedge _99) begin
        if (_97)
            t0_osr <= _356;
        else
            t0_osr <= _79;
    end
    assign _2835 = t0_osr & _2834;
    assign _5051 = _732[1:0];
    assign _5048 = 7'b1001111;
    assign _5049 = _728 == _5048;
    assign _5047 = _722 & _726;
    assign _5050 = _5047 & _5049;
    assign _5052 = _5050 ? _5051 : cfg_t0_shift;
    assign _80 = _5052;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_shift <= _297;
        else
            cfg_t0_shift <= _80;
    end
    assign _2808 = cfg_t0_shift[0:0];
    assign _2866 = _2808 ? _2865 : _2835;
    assign _5068 = _2298[8:7];
    assign _5070 = _5068 == _187;
    assign _5071 = _5070 ? _2866 : t0_y;
    assign _5064 = _2441 == _2395;
    assign _5065 = _5064 ? _2684 : t0_y;
    assign _5066 = _2447 ? _5065 : t0_y;
    assign _5060 = _2531 == _187;
    assign _5061 = _5060 ? _2544 : t0_y;
    assign _5058 = _2299 == _4710;
    assign _5062 = _5058 ? _5061 : t0_y;
    assign _5056 = _2299 == _4727;
    assign _5067 = _5056 ? _5066 : _5062;
    assign _5055 = _2299 == _4761;
    assign _5072 = _5055 ? _5071 : _5067;
    assign _5054 = _2299 == _5137;
    assign _5079 = _5054 ? _5078 : _5072;
    assign _5080 = _2417 ? _5079 : t0_y;
    assign _5081 = _754 ? t0_y : _5080;
    assign _5082 = _748 ? t0_y : _5081;
    assign _5084 = _742 ? _356 : _5082;
    assign _81 = _5084;
    assign _82 = _81;
    always @(posedge _99) begin
        if (_97)
            t0_y <= _356;
        else
            t0_y <= _82;
    end
    always @* begin
        case (_2444)
        0:
            _2684 <= t0_x;
        1:
            _2684 <= t0_y;
        2:
            _2684 <= _2676;
        3:
            _2684 <= t0_isr;
        4:
            _2684 <= t0_osr;
        default:
            _2684 <= _356;
        endcase
    end
    assign _5094 = _2441 == _5137;
    assign _5095 = _5094 ? _2684 : t0_x;
    assign _2444 = _2298[5:3];
    assign _2446 = _2444 < _4710;
    assign _2441 = _2298[8:6];
    assign _2443 = _2441 < _4710;
    assign _2447 = _2443 & _2446;
    assign _5096 = _2447 ? _5095 : t0_x;
    assign _2543 = _2298[4:0];
    assign _2544 = { _575,
                     _2543 };
    assign _2531 = _2298[8:7];
    assign _5090 = _2531 == _184;
    assign _5091 = _5090 ? _2544 : t0_x;
    assign _5088 = _2299 == _4710;
    assign _5092 = _5088 ? _5091 : t0_x;
    assign _5087 = _2299 == _4727;
    assign _5097 = _5087 ? _5096 : _5092;
    assign _5086 = _2299 == _4761;
    assign _5101 = _5086 ? _5100 : _5097;
    assign _5085 = _2299 == _5137;
    assign _5107 = _5085 ? _5106 : _5101;
    assign _5108 = _2417 ? _5107 : t0_x;
    assign _5109 = _754 ? t0_x : _5108;
    assign _5110 = _748 ? t0_x : _5109;
    assign _5112 = _742 ? _356 : _5110;
    assign _83 = _5112;
    assign _84 = _83;
    always @(posedge _99) begin
        if (_97)
            t0_x <= _356;
        else
            t0_x <= _84;
    end
    assign _5116 = t0_x == _356;
    assign _5117 = ~ _5116;
    assign _5118 = ~ _5117;
    assign _5073 = _2298[8:6];
    always @* begin
        case (_5073)
        0:
            _5127 <= vdd;
        1:
            _5127 <= _5118;
        2:
            _5127 <= _5117;
        3:
            _5127 <= _5122;
        4:
            _5127 <= _5121;
        5:
            _5127 <= _5124;
        6:
            _5127 <= _5125;
        default:
            _5127 <= _5126;
        endcase
    end
    assign _5114 = _2299 == _5137;
    assign _5128 = _5114 & _5127;
    assign _5134 = _5128 | _5133;
    assign _5143 = _5134 ? _5142 : _5136;
    assign _5144 = _2417 ? _5143 : t0_pc;
    assign _5145 = _754 ? t0_pc : _5144;
    assign _5146 = _748 ? t0_pc : _5145;
    assign _5147 = _742 ? cfg_t0_start : _5146;
    assign _85 = _5147;
    assign _86 = _85;
    always @(posedge _99) begin
        if (_97)
            t0_pc <= _305;
        else
            t0_pc <= _86;
    end
    always @* begin
        case (t0_pc)
        0:
            _2298 <= prog_0;
        1:
            _2298 <= prog_1;
        2:
            _2298 <= prog_2;
        3:
            _2298 <= prog_3;
        4:
            _2298 <= prog_4;
        5:
            _2298 <= prog_5;
        6:
            _2298 <= prog_6;
        7:
            _2298 <= prog_7;
        8:
            _2298 <= prog_8;
        9:
            _2298 <= prog_9;
        10:
            _2298 <= prog_10;
        11:
            _2298 <= prog_11;
        12:
            _2298 <= prog_12;
        13:
            _2298 <= prog_13;
        14:
            _2298 <= prog_14;
        15:
            _2298 <= prog_15;
        16:
            _2298 <= prog_16;
        17:
            _2298 <= prog_17;
        18:
            _2298 <= prog_18;
        19:
            _2298 <= prog_19;
        20:
            _2298 <= prog_20;
        21:
            _2298 <= prog_21;
        22:
            _2298 <= prog_22;
        23:
            _2298 <= prog_23;
        24:
            _2298 <= prog_24;
        25:
            _2298 <= prog_25;
        26:
            _2298 <= prog_26;
        27:
            _2298 <= prog_27;
        28:
            _2298 <= prog_28;
        29:
            _2298 <= prog_29;
        30:
            _2298 <= prog_30;
        31:
            _2298 <= prog_31;
        32:
            _2298 <= prog_32;
        33:
            _2298 <= prog_33;
        34:
            _2298 <= prog_34;
        35:
            _2298 <= prog_35;
        36:
            _2298 <= prog_36;
        37:
            _2298 <= prog_37;
        38:
            _2298 <= prog_38;
        39:
            _2298 <= prog_39;
        40:
            _2298 <= prog_40;
        41:
            _2298 <= prog_41;
        42:
            _2298 <= prog_42;
        43:
            _2298 <= prog_43;
        44:
            _2298 <= prog_44;
        45:
            _2298 <= prog_45;
        46:
            _2298 <= prog_46;
        47:
            _2298 <= prog_47;
        48:
            _2298 <= prog_48;
        49:
            _2298 <= prog_49;
        50:
            _2298 <= prog_50;
        51:
            _2298 <= prog_51;
        52:
            _2298 <= prog_52;
        53:
            _2298 <= prog_53;
        54:
            _2298 <= prog_54;
        55:
            _2298 <= prog_55;
        56:
            _2298 <= prog_56;
        57:
            _2298 <= prog_57;
        58:
            _2298 <= prog_58;
        59:
            _2298 <= prog_59;
        60:
            _2298 <= prog_60;
        61:
            _2298 <= prog_61;
        62:
            _2298 <= prog_62;
        63:
            _2298 <= prog_63;
        64:
            _2298 <= prog_64;
        65:
            _2298 <= prog_65;
        66:
            _2298 <= prog_66;
        67:
            _2298 <= prog_67;
        68:
            _2298 <= prog_68;
        69:
            _2298 <= prog_69;
        70:
            _2298 <= prog_70;
        71:
            _2298 <= prog_71;
        72:
            _2298 <= prog_72;
        73:
            _2298 <= prog_73;
        74:
            _2298 <= prog_74;
        75:
            _2298 <= prog_75;
        76:
            _2298 <= prog_76;
        77:
            _2298 <= prog_77;
        78:
            _2298 <= prog_78;
        79:
            _2298 <= prog_79;
        80:
            _2298 <= prog_80;
        81:
            _2298 <= prog_81;
        82:
            _2298 <= prog_82;
        83:
            _2298 <= prog_83;
        84:
            _2298 <= prog_84;
        85:
            _2298 <= prog_85;
        86:
            _2298 <= prog_86;
        87:
            _2298 <= prog_87;
        88:
            _2298 <= prog_88;
        89:
            _2298 <= prog_89;
        90:
            _2298 <= prog_90;
        91:
            _2298 <= prog_91;
        92:
            _2298 <= prog_92;
        93:
            _2298 <= prog_93;
        94:
            _2298 <= prog_94;
        95:
            _2298 <= prog_95;
        96:
            _2298 <= prog_96;
        97:
            _2298 <= prog_97;
        98:
            _2298 <= prog_98;
        99:
            _2298 <= prog_99;
        100:
            _2298 <= prog_100;
        101:
            _2298 <= prog_101;
        102:
            _2298 <= prog_102;
        103:
            _2298 <= prog_103;
        104:
            _2298 <= prog_104;
        105:
            _2298 <= prog_105;
        106:
            _2298 <= prog_106;
        107:
            _2298 <= prog_107;
        108:
            _2298 <= prog_108;
        109:
            _2298 <= prog_109;
        110:
            _2298 <= prog_110;
        111:
            _2298 <= prog_111;
        112:
            _2298 <= prog_112;
        113:
            _2298 <= prog_113;
        114:
            _2298 <= prog_114;
        115:
            _2298 <= prog_115;
        116:
            _2298 <= prog_116;
        117:
            _2298 <= prog_117;
        118:
            _2298 <= prog_118;
        119:
            _2298 <= prog_119;
        120:
            _2298 <= prog_120;
        121:
            _2298 <= prog_121;
        122:
            _2298 <= prog_122;
        123:
            _2298 <= prog_123;
        124:
            _2298 <= prog_124;
        125:
            _2298 <= prog_125;
        126:
            _2298 <= prog_126;
        127:
            _2298 <= prog_127;
        128:
            _2298 <= prog_128;
        129:
            _2298 <= prog_129;
        130:
            _2298 <= prog_130;
        131:
            _2298 <= prog_131;
        132:
            _2298 <= prog_132;
        133:
            _2298 <= prog_133;
        134:
            _2298 <= prog_134;
        135:
            _2298 <= prog_135;
        136:
            _2298 <= prog_136;
        137:
            _2298 <= prog_137;
        138:
            _2298 <= prog_138;
        139:
            _2298 <= prog_139;
        140:
            _2298 <= prog_140;
        141:
            _2298 <= prog_141;
        142:
            _2298 <= prog_142;
        143:
            _2298 <= prog_143;
        144:
            _2298 <= prog_144;
        145:
            _2298 <= prog_145;
        146:
            _2298 <= prog_146;
        147:
            _2298 <= prog_147;
        148:
            _2298 <= prog_148;
        149:
            _2298 <= prog_149;
        150:
            _2298 <= prog_150;
        151:
            _2298 <= prog_151;
        152:
            _2298 <= prog_152;
        153:
            _2298 <= prog_153;
        154:
            _2298 <= prog_154;
        155:
            _2298 <= prog_155;
        156:
            _2298 <= prog_156;
        157:
            _2298 <= prog_157;
        158:
            _2298 <= prog_158;
        159:
            _2298 <= prog_159;
        160:
            _2298 <= prog_160;
        161:
            _2298 <= prog_161;
        162:
            _2298 <= prog_162;
        163:
            _2298 <= prog_163;
        164:
            _2298 <= prog_164;
        165:
            _2298 <= prog_165;
        166:
            _2298 <= prog_166;
        167:
            _2298 <= prog_167;
        168:
            _2298 <= prog_168;
        169:
            _2298 <= prog_169;
        170:
            _2298 <= prog_170;
        171:
            _2298 <= prog_171;
        172:
            _2298 <= prog_172;
        173:
            _2298 <= prog_173;
        174:
            _2298 <= prog_174;
        175:
            _2298 <= prog_175;
        176:
            _2298 <= prog_176;
        177:
            _2298 <= prog_177;
        178:
            _2298 <= prog_178;
        179:
            _2298 <= prog_179;
        180:
            _2298 <= prog_180;
        181:
            _2298 <= prog_181;
        182:
            _2298 <= prog_182;
        183:
            _2298 <= prog_183;
        184:
            _2298 <= prog_184;
        185:
            _2298 <= prog_185;
        186:
            _2298 <= prog_186;
        187:
            _2298 <= prog_187;
        188:
            _2298 <= prog_188;
        189:
            _2298 <= prog_189;
        190:
            _2298 <= prog_190;
        191:
            _2298 <= prog_191;
        192:
            _2298 <= prog_192;
        193:
            _2298 <= prog_193;
        194:
            _2298 <= prog_194;
        195:
            _2298 <= prog_195;
        196:
            _2298 <= prog_196;
        197:
            _2298 <= prog_197;
        198:
            _2298 <= prog_198;
        199:
            _2298 <= prog_199;
        200:
            _2298 <= prog_200;
        201:
            _2298 <= prog_201;
        202:
            _2298 <= prog_202;
        203:
            _2298 <= prog_203;
        204:
            _2298 <= prog_204;
        205:
            _2298 <= prog_205;
        206:
            _2298 <= prog_206;
        207:
            _2298 <= prog_207;
        208:
            _2298 <= prog_208;
        209:
            _2298 <= prog_209;
        210:
            _2298 <= prog_210;
        211:
            _2298 <= prog_211;
        212:
            _2298 <= prog_212;
        213:
            _2298 <= prog_213;
        214:
            _2298 <= prog_214;
        215:
            _2298 <= prog_215;
        216:
            _2298 <= prog_216;
        217:
            _2298 <= prog_217;
        218:
            _2298 <= prog_218;
        219:
            _2298 <= prog_219;
        220:
            _2298 <= prog_220;
        221:
            _2298 <= prog_221;
        222:
            _2298 <= prog_222;
        223:
            _2298 <= prog_223;
        224:
            _2298 <= prog_224;
        225:
            _2298 <= prog_225;
        226:
            _2298 <= prog_226;
        227:
            _2298 <= prog_227;
        228:
            _2298 <= prog_228;
        229:
            _2298 <= prog_229;
        230:
            _2298 <= prog_230;
        231:
            _2298 <= prog_231;
        232:
            _2298 <= prog_232;
        233:
            _2298 <= prog_233;
        234:
            _2298 <= prog_234;
        235:
            _2298 <= prog_235;
        236:
            _2298 <= prog_236;
        237:
            _2298 <= prog_237;
        238:
            _2298 <= prog_238;
        239:
            _2298 <= prog_239;
        240:
            _2298 <= prog_240;
        241:
            _2298 <= prog_241;
        242:
            _2298 <= prog_242;
        243:
            _2298 <= prog_243;
        244:
            _2298 <= prog_244;
        245:
            _2298 <= prog_245;
        246:
            _2298 <= prog_246;
        247:
            _2298 <= prog_247;
        248:
            _2298 <= prog_248;
        249:
            _2298 <= prog_249;
        250:
            _2298 <= prog_250;
        251:
            _2298 <= prog_251;
        252:
            _2298 <= prog_252;
        253:
            _2298 <= prog_253;
        254:
            _2298 <= prog_254;
        default:
            _2298 <= prog_255;
        endcase
    end
    assign _2299 = _2298[15:13];
    assign _2396 = _2299 == _2395;
    assign _2398 = _2396 & _2397;
    assign _2401 = _2398 & _2400;
    assign _2409 = _2401 | _2408;
    assign _2415 = _2409 | _2414;
    assign _2416 = ~ _2415;
    assign _2417 = _2394 & _2416;
    assign _5158 = _2417 ? _5157 : t0_delay_left;
    assign _753 = t0_delay_left == _591;
    assign _754 = ~ _753;
    assign _5161 = _754 ? _5160 : _5158;
    assign _748 = ~ _747;
    assign _5162 = _748 ? t0_delay_left : _5161;
    assign _742 = ~ _741;
    assign _5164 = _742 ? _591 : _5162;
    assign _87 = _5164;
    assign _88 = _87;
    always @(posedge _99) begin
        if (_97)
            t0_delay_left <= _591;
        else
            t0_delay_left <= _88;
    end
    assign _2393 = t0_delay_left == _591;
    assign _5176 = cfg_t0_clkdiv - _2379;
    assign _5166 = 7'b1001101;
    assign _5167 = _728 == _5166;
    assign _5165 = _722 & _726;
    assign _5168 = _5165 & _5167;
    assign _5169 = _5168 ? _732 : cfg_t0_clkdiv;
    assign _89 = _5169;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_clkdiv <= _356;
        else
            cfg_t0_clkdiv <= _89;
    end
    assign _5174 = cfg_t0_clkdiv == _356;
    assign _5178 = _5174 ? _356 : _5176;
    assign _5172 = t0_div_count - _2379;
    assign _5179 = _747 ? _5178 : _5172;
    assign _5170 = ~ _741;
    assign _5181 = _5170 ? _356 : _5179;
    assign _90 = _5181;
    always @(posedge _99) begin
        if (_97)
            t0_div_count <= _356;
        else
            t0_div_count <= _90;
    end
    assign _747 = t0_div_count == _356;
    assign _741 = cfg_ctrl[0:0];
    assign _2391 = _741 & _747;
    assign _2394 = _2391 & _2393;
    assign _5184 = _2394 & _5183;
    assign _5186 = _5184 & _5185;
    assign _5188 = _5186 & _5187;
    assign _91 = _5188;
    assign _422 = _91 & _421;
    assign _5190 = { _591,
                     _422 };
    assign _5191 = t0_rx_level + _5190;
    assign _5194 = _5191 - _5193;
    assign _92 = _5194;
    always @(posedge _99) begin
        if (_97)
            t0_rx_level <= _585;
        else
            t0_rx_level <= _92;
    end
    assign _3912 = t0_rx_level == _585;
    assign _5215 = ~ _3912;
    assign _732 = _368[15:0];
    assign _5213 = _732[4:0];
    assign _728 = host_cmd[6:0];
    assign _5211 = _728 == _758;
    assign _363 = _101[2:2];
    always @(posedge _99) begin
        if (_97)
            host_mosi_s1 <= gnd;
        else
            host_mosi_s1 <= _363;
    end
    always @(posedge _99) begin
        if (_97)
            host_mosi_s2 <= gnd;
        else
            host_mosi_s2 <= host_mosi_s1;
    end
    assign _361 = 23'b00000000000000000000000;
    assign _5195 = _368[22:0];
    assign _5196 = _354 ? _5195 : host_shift_in;
    assign _5197 = host_cs_n_s2 ? host_shift_in : _5196;
    assign _93 = _5197;
    always @(posedge _99) begin
        if (_97)
            host_shift_in <= _361;
        else
            host_shift_in <= _93;
    end
    assign _368 = { host_shift_in,
                    host_mosi_s2 };
    assign _369 = _368[7:0];
    assign _359 = host_bit_count == _3404;
    assign _5198 = _359 ? _369 : host_cmd;
    assign _5199 = _354 ? _5198 : host_cmd;
    assign _5200 = host_cs_n_s2 ? host_cmd : _5199;
    assign _94 = _5200;
    always @(posedge _99) begin
        if (_97)
            host_cmd <= _305;
        else
            host_cmd <= _94;
    end
    assign _726 = host_cmd[7:7];
    assign _720 = 5'b10111;
    assign _5204 = host_bit_count + _3488;
    assign _5201 = 5'b11000;
    assign _5202 = host_bit_count < _5201;
    assign _5205 = _5202 ? _5204 : host_bit_count;
    assign _5206 = _354 ? _5205 : host_bit_count;
    assign _5208 = host_cs_n_s2 ? _585 : _5206;
    assign _95 = _5208;
    always @(posedge _99) begin
        if (_97)
            host_bit_count <= _585;
        else
            host_bit_count <= _95;
    end
    assign _721 = host_bit_count == _720;
    assign _326 = _101[1:1];
    always @(posedge _99) begin
        if (_97)
            host_cs_n_s1 <= vdd;
        else
            host_cs_n_s1 <= _326;
    end
    always @(posedge _99) begin
        if (_97)
            host_cs_n_s2 <= vdd;
        else
            host_cs_n_s2 <= host_cs_n_s1;
    end
    assign _353 = ~ host_cs_n_s2;
    always @(posedge _99) begin
        if (_97)
            host_sck_prev <= _716;
        else
            host_sck_prev <= host_sck_s2;
    end
    assign _351 = ~ host_sck_prev;
    assign vdd = 1'b1;
    assign _97 = clear;
    assign _99 = clock;
    assign _101 = ui_in;
    assign _331 = _101[0:0];
    always @(posedge _99) begin
        if (_97)
            host_sck_s1 <= gnd;
        else
            host_sck_s1 <= _331;
    end
    always @(posedge _99) begin
        if (_97)
            host_sck_s2 <= gnd;
        else
            host_sck_s2 <= host_sck_s1;
    end
    assign _352 = host_sck_s2 & _351;
    assign _354 = _352 & _353;
    assign _722 = _354 & _721;
    assign _5209 = _722 & _726;
    assign _5212 = _5209 & _5211;
    assign _5214 = _5212 ? _5213 : cfg_ctrl;
    assign _102 = _5214;
    always @(posedge _99) begin
        if (_97)
            cfg_ctrl <= _585;
        else
            cfg_ctrl <= _102;
    end
    assign _3596 = cfg_ctrl[2:2];
    assign _5216 = _3596 & _5215;
    assign _5218 = _5216 & _5217;
    assign _103 = _5218;
    assign _3599 = _103 | _3598;
    assign _3603 = _3599 & _3602;
    assign _5220 = { _591,
                     _3603 };
    assign _5221 = t1_tx_level + _5220;
    assign _5224 = _5221 - _5223;
    assign _104 = _5224;
    always @(posedge _99) begin
        if (_97)
            t1_tx_level <= _585;
        else
            t1_tx_level <= _104;
    end
    assign _5226 = t1_tx_level == _252;
    assign gnd = 1'b0;
    assign _5238 = { gnd,
                     _5226,
                     _5229,
                     _5230,
                     _5232,
                     _5235,
                     _5236,
                     _5237 };
    assign uo_out = _5238;
    assign uio_out = _234;
    assign uio_oe = _193;

endmodule
