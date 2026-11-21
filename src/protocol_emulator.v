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

    wire _236;
    wire _237;
    wire [1:0] _234;
    wire [1:0] _233;
    wire _235;
    wire _238;
    wire [1:0] _231;
    wire [1:0] _230;
    wire _232;
    wire _239;
    wire _226;
    wire _227;
    wire [1:0] _223;
    wire _225;
    wire _228;
    wire [1:0] _220;
    wire _222;
    wire _229;
    wire _216;
    wire _217;
    wire [1:0] _213;
    wire _215;
    wire _218;
    wire [1:0] _210;
    wire _212;
    wire _219;
    wire _206;
    wire _207;
    wire [1:0] _203;
    wire _205;
    wire _208;
    wire [1:0] _200;
    wire _202;
    wire _209;
    wire _196;
    wire _197;
    wire [1:0] _193;
    wire _195;
    wire _198;
    wire [1:0] _190;
    wire _192;
    wire _199;
    wire _186;
    wire _187;
    wire [1:0] _183;
    wire _185;
    wire _188;
    wire [1:0] _180;
    wire _182;
    wire _189;
    wire _176;
    wire _177;
    wire [1:0] _173;
    wire _175;
    wire _178;
    wire [1:0] _170;
    wire _172;
    wire _179;
    wire _166;
    wire _167;
    wire [1:0] _160;
    wire _162;
    wire _168;
    wire [1:0] _157;
    wire _159;
    wire _169;
    wire [7:0] _240;
    wire _279;
    wire [1:0] _276;
    wire _278;
    wire _280;
    wire _274;
    wire [1:0] _271;
    wire _273;
    wire _275;
    wire _269;
    wire [1:0] _266;
    wire _268;
    wire _270;
    wire _264;
    wire [1:0] _261;
    wire _263;
    wire _265;
    wire _259;
    wire [1:0] _256;
    wire _258;
    wire _260;
    wire _254;
    wire [1:0] _251;
    wire _253;
    wire _255;
    wire _249;
    wire [1:0] _246;
    wire _248;
    wire _250;
    wire _244;
    wire [1:0] _241;
    wire _243;
    wire _245;
    wire [7:0] _281;
    wire [15:0] _312;
    wire _606;
    wire [14:0] _605;
    wire [15:0] _607;
    wire [1:0] _588;
    wire [13:0] _581;
    wire [15:0] _589;
    wire [7:0] _576;
    wire [15:0] _580;
    wire [15:0] _575;
    wire [6:0] _567;
    wire [15:0] _571;
    wire [5:0] _562;
    wire [15:0] _566;
    wire [15:0] _561;
    wire [12:0] _552;
    wire [15:0] _556;
    wire [9:0] _532;
    wire [15:0] _536;
    wire [15:0] _528;
    wire _516;
    wire [15:0] _520;
    wire [2:0] _473;
    wire _474;
    wire _475;
    wire [15:0] _512;
    wire [15:0] _469;
    wire [10:0] _460;
    wire [15:0] _464;
    wire [15:0] _459;
    wire [15:0] _454;
    wire [15:0] _449;
    wire [15:0] _444;
    wire [15:0] _439;
    wire [15:0] _434;
    wire [15:0] _429;
    wire [15:0] _421;
    wire _409;
    wire [15:0] _413;
    wire _367;
    wire _368;
    wire [15:0] _405;
    wire [15:0] _362;
    wire [15:0] _357;
    wire [15:0] _352;
    wire [15:0] _347;
    wire [15:0] _342;
    wire [15:0] _337;
    wire [15:0] _332;
    reg [15:0] _602;
    wire [15:0] _603;
    wire [15:0] _604;
    wire [4:0] _303;
    wire _304;
    wire _305;
    wire _298;
    wire _293;
    wire _297;
    wire _299;
    wire _306;
    wire [15:0] _608;
    wire [15:0] _609;
    wire [15:0] _3;
    reg [15:0] host_miso_shift;
    wire _4495;
    wire _4494;
    wire _4492;
    wire _4493;
    wire [2:0] _4489;
    wire _4490;
    wire _4488;
    wire _4486;
    wire _4487;
    wire [1:0] _4480;
    wire [2:0] _4481;
    wire _1757;
    wire _1752;
    wire _1746;
    wire _1747;
    wire _1745;
    wire _1748;
    wire _1749;
    wire [6:0] _1741;
    wire _1742;
    wire _1740;
    wire _1743;
    wire _1750;
    wire _1753;
    wire _4475;
    wire [2:0] _4451;
    wire _377;
    wire _4445;
    wire _4443;
    wire _4441;
    wire _4439;
    wire [3:0] _655;
    wire [3:0] _4409;
    wire [3:0] _4410;
    wire [1:0] _4404;
    wire [3:0] _4405;
    wire [3:0] _4401;
    wire [3:0] _4400;
    wire _4399;
    wire [3:0] _4402;
    wire _4398;
    wire [3:0] _4406;
    wire [3:0] _4407;
    wire _864;
    wire _376;
    wire _829;
    wire _828;
    wire _830;
    wire _831;
    wire _820;
    wire _822;
    wire _825;
    wire _817;
    wire _804;
    wire [2:0] _659;
    wire [15:0] _4392;
    wire [5:0] _4382;
    wire [7:0] _623;
    wire [6:0] _619;
    wire _620;
    wire _617;
    wire _621;
    wire [7:0] _624;
    wire [7:0] _4;
    reg [7:0] cfg_t0_start;
    wire [1:0] _882;
    wire [1:0] _876;
    wire [1:0] _874;
    wire _875;
    wire [1:0] _877;
    wire _872;
    wire [1:0] _878;
    wire [1:0] _879;
    wire [1:0] _880;
    wire [1:0] _881;
    wire [1:0] _883;
    wire [1:0] _5;
    wire [1:0] _6;
    reg [1:0] t0_page;
    wire [7:0] _4383;
    wire [7:0] _888;
    wire [6:0] _885;
    wire _886;
    wire _884;
    wire _887;
    wire [7:0] _889;
    wire [7:0] _7;
    reg [7:0] cfg_t0_timeout_vector;
    wire _4381;
    wire [7:0] _4384;
    wire [7:0] _4378;
    wire [7:0] _4379;
    wire [15:0] _897;
    wire [15:0] _898;
    wire [15:0] _899;
    wire [15:0] _900;
    wire [15:0] _901;
    wire [15:0] _903;
    wire [15:0] _8;
    wire [15:0] _9;
    reg [15:0] t0_wait_count;
    wire [6:0] _905;
    wire _906;
    wire _904;
    wire _907;
    wire [15:0] _908;
    wire [15:0] _10;
    reg [15:0] cfg_t0_timeout;
    wire _895;
    wire _892;
    wire _891;
    wire _893;
    wire _894;
    wire _896;
    wire _910;
    wire _912;
    wire _913;
    wire _914;
    wire _916;
    wire _11;
    wire _12;
    reg t0_waiting;
    wire [15:0] _813;
    wire _815;
    wire _806;
    wire _816;
    wire _802;
    wire _800;
    wire _799;
    wire _798;
    wire _797;
    wire _796;
    wire _795;
    wire _794;
    wire _793;
    wire [2:0] _661;
    reg _801;
    wire _803;
    wire _4374;
    wire _4373;
    wire _4375;
    wire _4376;
    wire _4369;
    wire _4368;
    wire _4366;
    wire _4367;
    wire _4363;
    wire _4364;
    wire _4365;
    wire [15:0] _4348;
    wire [2:0] _4345;
    wire _4346;
    wire [15:0] _4349;
    wire _4342;
    wire [15:0] _4343;
    wire _2499;
    wire [1:0] _2500;
    wire [3:0] _2501;
    wire [7:0] _2502;
    wire [15:0] _2503;
    wire [31:0] _2504;
    wire [31:0] _972;
    wire [6:0] _918;
    wire _919;
    wire _917;
    wire _920;
    wire [15:0] _921;
    wire [15:0] _13;
    reg [15:0] cfg_t0_crc_init_lo;
    wire [6:0] _923;
    wire _924;
    wire _922;
    wire _925;
    wire [15:0] _926;
    wire [15:0] _14;
    reg [15:0] cfg_t0_crc_init_hi;
    wire [31:0] _1203;
    wire [15:0] _1200;
    wire [31:0] _1201;
    wire [31:0] _1202;
    wire [31:0] _1204;
    wire [31:0] _1205;
    wire _1198;
    wire [31:0] _1206;
    wire _1186;
    wire _1185;
    wire _1184;
    wire _1183;
    wire _1182;
    wire _1181;
    wire _1180;
    wire _1179;
    wire _1178;
    wire _1177;
    wire _1176;
    wire _1175;
    wire _1174;
    wire _1173;
    wire _1172;
    wire _1171;
    wire [4:0] _1168;
    wire [4:0] _1169;
    wire [3:0] _1170;
    reg _1187;
    wire [15:0] _1165;
    wire [15:0] _1166;
    wire _1167;
    wire _981;
    wire _1188;
    wire _978;
    wire _1189;
    wire [1:0] _1190;
    wire [3:0] _1191;
    wire [7:0] _1192;
    wire [15:0] _1193;
    wire [31:0] _1194;
    wire [6:0] _928;
    wire _929;
    wire _927;
    wire _930;
    wire [15:0] _931;
    wire [15:0] _15;
    reg [15:0] cfg_t0_crc_poly_lo;
    wire [6:0] _933;
    wire _934;
    wire _932;
    wire _935;
    wire [15:0] _936;
    wire [15:0] _16;
    reg [15:0] cfg_t0_crc_poly_hi;
    wire [31:0] _977;
    wire [31:0] _1195;
    wire [30:0] _975;
    wire [31:0] _976;
    wire [31:0] _1196;
    wire _968;
    wire [2:0] _965;
    wire _966;
    wire _964;
    wire _969;
    wire [2:0] _951;
    wire _952;
    wire _953;
    wire _950;
    wire _955;
    wire _956;
    wire _941;
    wire _957;
    wire _958;
    wire _959;
    wire _960;
    wire _962;
    wire _17;
    wire _18;
    reg t0_crc_run;
    wire _963;
    wire _970;
    wire [31:0] _1197;
    wire [31:0] _1207;
    wire [31:0] _1208;
    wire [31:0] _1209;
    wire [31:0] _1210;
    wire [31:0] _19;
    wire [31:0] _20;
    reg [31:0] t0_crc;
    wire [31:0] _2505;
    wire [15:0] _2506;
    wire [15:0] _2494;
    wire [15:0] _4320;
    wire _4318;
    wire [15:0] _4321;
    wire [15:0] _1038;
    wire [31:0] _1039;
    wire [23:0] _1034;
    wire [31:0] _1035;
    wire [27:0] _1030;
    wire [31:0] _1031;
    wire [29:0] _1026;
    wire [31:0] _1027;
    wire [30:0] _1022;
    wire [31:0] _1023;
    wire [31:0] _1020;
    wire _1018;
    wire [31:0] _1024;
    wire _1017;
    wire [31:0] _1028;
    wire _1016;
    wire [31:0] _1032;
    wire _1015;
    wire [31:0] _1036;
    wire [4:0] _1012;
    wire [4:0] _1013;
    wire _1014;
    wire [31:0] _1040;
    wire [15:0] _1041;
    wire [15:0] _4278;
    wire [31:0] _4280;
    wire [23:0] _4274;
    wire [31:0] _4276;
    wire [27:0] _4270;
    wire [31:0] _4272;
    wire [29:0] _4266;
    wire [31:0] _4268;
    wire [30:0] _4262;
    wire [31:0] _4264;
    wire [31:0] _4261;
    wire _4259;
    wire [31:0] _4265;
    wire _4258;
    wire [31:0] _4269;
    wire _4257;
    wire [31:0] _4273;
    wire _4256;
    wire [31:0] _4277;
    wire _4255;
    wire [31:0] _4281;
    wire [15:0] _4282;
    wire [15:0] _4251;
    wire [31:0] _4252;
    wire [23:0] _4247;
    wire [31:0] _4248;
    wire [27:0] _4243;
    wire [31:0] _4244;
    wire [29:0] _4239;
    wire [31:0] _4240;
    wire [30:0] _4235;
    wire [31:0] _4236;
    wire [31:0] _4233;
    wire _4231;
    wire [31:0] _4237;
    wire _4230;
    wire [31:0] _4241;
    wire _4229;
    wire [31:0] _4245;
    wire _4228;
    wire [31:0] _4249;
    wire _4227;
    wire [31:0] _4253;
    wire [15:0] _4254;
    wire [15:0] _4283;
    wire [15:0] _4284;
    wire [15:0] _4225;
    wire _4221;
    wire [15:0] _4222;
    wire [15:0] _4223;
    wire _4220;
    wire [15:0] _4224;
    wire _4219;
    wire [15:0] _4226;
    wire _4218;
    wire [15:0] _4285;
    wire _4213;
    wire _4214;
    reg [15:0] t0_tx_mem_3;
    wire _4207;
    wire _4208;
    reg [15:0] t0_tx_mem_2;
    wire _4201;
    wire _4202;
    reg [15:0] t0_tx_mem_1;
    wire [1:0] _1236;
    wire [1:0] _1237;
    wire [1:0] _21;
    reg [1:0] t0_tx_wr;
    wire _4195;
    wire _4196;
    wire [15:0] _4191;
    reg [15:0] t0_tx_mem_0;
    wire [1:0] _1244;
    wire [1:0] _1245;
    wire [1:0] _22;
    reg [1:0] t0_tx_rd;
    reg [15:0] _4216;
    wire [4:0] _838;
    wire _1238;
    wire _1250;
    wire _1247;
    wire _1248;
    wire _1249;
    wire _1251;
    wire _1269;
    wire _1272;
    wire _23;
    wire _1239;
    wire [2:0] _4161;
    wire _1230;
    wire _1223;
    wire _1221;
    wire _1224;
    wire _1225;
    wire [6:0] _1216;
    wire _1217;
    wire _1215;
    wire _1218;
    wire _1226;
    wire _1213;
    wire _1756;
    wire _1229;
    wire _4154;
    wire _4155;
    wire _4151;
    wire _4152;
    reg buf_wrote;
    wire _4149;
    wire [9:0] _4133;
    wire [9:0] _4130;
    wire [9:0] _4131;
    wire [6:0] _1279;
    wire _1280;
    wire _1276;
    wire _1277;
    wire _1278;
    wire _1281;
    wire _24;
    wire _4128;
    wire [2:0] _4102;
    wire _484;
    wire _4096;
    wire _4094;
    wire _4092;
    wire _4090;
    wire [3:0] _4067;
    wire [1:0] _4061;
    wire [3:0] _4062;
    wire _4056;
    wire [3:0] _4059;
    wire _4055;
    wire [3:0] _4063;
    wire [3:0] _4064;
    wire _1389;
    wire _483;
    wire _1354;
    wire _1353;
    wire _1355;
    wire _1356;
    wire _1345;
    wire _1347;
    wire _1350;
    wire _1342;
    wire _1329;
    wire [5:0] _4046;
    wire [1:0] _4045;
    wire [7:0] _4047;
    wire [5:0] _4036;
    wire [7:0] _1286;
    wire [6:0] _1283;
    wire _1284;
    wire _1282;
    wire _1285;
    wire [7:0] _1287;
    wire [7:0] _25;
    reg [7:0] cfg_t1_start;
    wire [1:0] _1407;
    wire [1:0] _1401;
    wire _1400;
    wire [1:0] _1402;
    wire _1397;
    wire [1:0] _1403;
    wire [1:0] _1404;
    wire [1:0] _1405;
    wire [1:0] _1406;
    wire [1:0] _1408;
    wire [1:0] _26;
    wire [1:0] _27;
    reg [1:0] t1_page;
    wire [7:0] _4037;
    wire [7:0] _1413;
    wire [6:0] _1410;
    wire _1411;
    wire _1409;
    wire _1412;
    wire [7:0] _1414;
    wire [7:0] _28;
    reg [7:0] cfg_t1_timeout_vector;
    wire _4035;
    wire [7:0] _4038;
    wire [7:0] _4033;
    wire [15:0] _1423;
    wire [15:0] _1424;
    wire [15:0] _1425;
    wire [15:0] _1426;
    wire [15:0] _1428;
    wire [15:0] _29;
    wire [15:0] _30;
    reg [15:0] t1_wait_count;
    wire [6:0] _1430;
    wire _1431;
    wire _1429;
    wire _1432;
    wire [15:0] _1433;
    wire [15:0] _31;
    reg [15:0] cfg_t1_timeout;
    wire _1420;
    wire _1417;
    wire _1416;
    wire _1418;
    wire _1419;
    wire _1421;
    wire _1435;
    wire _1437;
    wire _1438;
    wire _1439;
    wire _1441;
    wire _32;
    wire _33;
    reg t1_waiting;
    wire [15:0] _1338;
    wire _1340;
    wire _1331;
    wire _1341;
    wire _1327;
    wire _1325;
    wire _1324;
    wire _1323;
    wire _1322;
    wire _1321;
    wire _1320;
    wire _1319;
    wire _1318;
    wire [2:0] _1317;
    reg _1326;
    wire _1328;
    wire _4028;
    wire _4027;
    wire _4029;
    wire _4030;
    wire _4023;
    wire _4022;
    wire _4020;
    wire _4021;
    wire _4017;
    wire _4018;
    wire _4019;
    wire [15:0] _4002;
    wire _4000;
    wire [15:0] _4003;
    wire _3996;
    wire [15:0] _3997;
    wire _1787;
    wire [1:0] _1788;
    wire [3:0] _1789;
    wire [7:0] _1790;
    wire [15:0] _1791;
    wire [31:0] _1792;
    wire [6:0] _1443;
    wire _1444;
    wire _1442;
    wire _1445;
    wire [15:0] _1446;
    wire [15:0] _34;
    reg [15:0] cfg_t1_crc_init_lo;
    wire [6:0] _1448;
    wire _1449;
    wire _1447;
    wire _1450;
    wire [15:0] _1451;
    wire [15:0] _35;
    reg [15:0] cfg_t1_crc_init_hi;
    wire [31:0] _1728;
    wire [15:0] _1725;
    wire [31:0] _1726;
    wire [31:0] _1727;
    wire [31:0] _1729;
    wire [31:0] _1730;
    wire _1723;
    wire [31:0] _1731;
    wire _1711;
    wire _1710;
    wire _1709;
    wire _1708;
    wire _1707;
    wire _1706;
    wire _1705;
    wire _1704;
    wire _1703;
    wire _1702;
    wire _1701;
    wire _1700;
    wire _1699;
    wire _1698;
    wire _1697;
    wire _1696;
    wire [4:0] _1694;
    wire [3:0] _1695;
    reg _1712;
    wire [15:0] _1690;
    wire [15:0] _1691;
    wire _1692;
    wire _1506;
    wire _1713;
    wire _1503;
    wire _1714;
    wire [1:0] _1715;
    wire [3:0] _1716;
    wire [7:0] _1717;
    wire [15:0] _1718;
    wire [31:0] _1719;
    wire [6:0] _1453;
    wire _1454;
    wire _1452;
    wire _1455;
    wire [15:0] _1456;
    wire [15:0] _36;
    reg [15:0] cfg_t1_crc_poly_lo;
    wire [6:0] _1458;
    wire _1459;
    wire _1457;
    wire _1460;
    wire [15:0] _1461;
    wire [15:0] _37;
    reg [15:0] cfg_t1_crc_poly_hi;
    wire [31:0] _1502;
    wire [31:0] _1720;
    wire [30:0] _1500;
    wire [31:0] _1501;
    wire [31:0] _1721;
    wire _1493;
    wire _1491;
    wire _1489;
    wire _1494;
    wire _1477;
    wire _1478;
    wire _1475;
    wire _1480;
    wire _1481;
    wire _1466;
    wire _1482;
    wire _1483;
    wire _1484;
    wire _1485;
    wire _1487;
    wire _38;
    wire _39;
    reg t1_crc_run;
    wire _1488;
    wire _1495;
    wire [31:0] _1722;
    wire [31:0] _1732;
    wire [31:0] _1733;
    wire [31:0] _1734;
    wire [31:0] _1735;
    wire [31:0] _40;
    wire [31:0] _41;
    reg [31:0] t1_crc;
    wire [31:0] _1793;
    wire [15:0] _1794;
    wire [15:0] _1785;
    wire [15:0] _3974;
    wire _3972;
    wire [15:0] _3975;
    wire [15:0] _1563;
    wire [31:0] _1564;
    wire [23:0] _1559;
    wire [31:0] _1560;
    wire [27:0] _1555;
    wire [31:0] _1556;
    wire [29:0] _1551;
    wire [31:0] _1552;
    wire [30:0] _1547;
    wire [31:0] _1548;
    wire [31:0] _1545;
    wire _1543;
    wire [31:0] _1549;
    wire _1542;
    wire [31:0] _1553;
    wire _1541;
    wire [31:0] _1557;
    wire _1540;
    wire [31:0] _1561;
    wire [4:0] _1538;
    wire _1539;
    wire [31:0] _1565;
    wire [15:0] _1566;
    wire [15:0] _3932;
    wire [31:0] _3934;
    wire [23:0] _3928;
    wire [31:0] _3930;
    wire [27:0] _3924;
    wire [31:0] _3926;
    wire [29:0] _3920;
    wire [31:0] _3922;
    wire [30:0] _3916;
    wire [31:0] _3918;
    wire [31:0] _3915;
    wire _3913;
    wire [31:0] _3919;
    wire _3912;
    wire [31:0] _3923;
    wire _3911;
    wire [31:0] _3927;
    wire _3910;
    wire [31:0] _3931;
    wire _3909;
    wire [31:0] _3935;
    wire [15:0] _3936;
    wire [15:0] _3905;
    wire [31:0] _3906;
    wire [23:0] _3901;
    wire [31:0] _3902;
    wire [27:0] _3897;
    wire [31:0] _3898;
    wire [29:0] _3893;
    wire [31:0] _3894;
    wire [30:0] _3889;
    wire [31:0] _3890;
    wire [31:0] _3887;
    wire _3885;
    wire [31:0] _3891;
    wire _3884;
    wire [31:0] _3895;
    wire _3883;
    wire [31:0] _3899;
    wire _3882;
    wire [31:0] _3903;
    wire _3881;
    wire [31:0] _3907;
    wire [15:0] _3908;
    wire [15:0] _3937;
    wire [15:0] _3938;
    wire [15:0] _3879;
    wire _3875;
    wire [15:0] _3876;
    wire [15:0] _3877;
    wire _3874;
    wire [15:0] _3878;
    wire _3873;
    wire [15:0] _3880;
    wire _3872;
    wire [15:0] _3939;
    wire _3867;
    wire _3868;
    reg [15:0] t1_tx_mem_3;
    wire _3861;
    wire _3862;
    reg [15:0] t1_tx_mem_2;
    wire _3855;
    wire _3856;
    reg [15:0] t1_tx_mem_1;
    wire [1:0] _1763;
    wire [1:0] _1764;
    wire [1:0] _42;
    reg [1:0] t1_tx_wr;
    wire _3849;
    wire _3850;
    wire [15:0] _43;
    wire _508;
    wire _509;
    reg [15:0] t1_rx_mem_3;
    wire _502;
    wire _503;
    reg [15:0] t1_rx_mem_2;
    wire _496;
    wire _497;
    reg [15:0] t1_rx_mem_1;
    wire [1:0] _1766;
    wire [1:0] _1767;
    wire [1:0] _44;
    reg [1:0] t1_rx_wr;
    wire _490;
    wire _491;
    wire [15:0] _2005;
    wire [31:0] _2007;
    wire [23:0] _2001;
    wire [31:0] _2003;
    wire [27:0] _1997;
    wire [31:0] _1999;
    wire [29:0] _1993;
    wire [31:0] _1995;
    wire [31:0] _1991;
    wire [31:0] _1990;
    wire _1989;
    wire [31:0] _1992;
    wire _1988;
    wire [31:0] _1996;
    wire _1987;
    wire [31:0] _2000;
    wire _1986;
    wire [31:0] _2004;
    wire _1985;
    wire [31:0] _2008;
    wire [15:0] _2009;
    wire [15:0] _2010;
    wire [15:0] _2011;
    wire [15:0] _1981;
    wire [31:0] _1982;
    wire [23:0] _1977;
    wire [31:0] _1978;
    wire [27:0] _1973;
    wire [31:0] _1974;
    wire [29:0] _1969;
    wire [31:0] _1970;
    wire [30:0] _1965;
    wire [31:0] _1966;
    wire [31:0] _1963;
    wire _1961;
    wire [31:0] _1967;
    wire _1960;
    wire [31:0] _1971;
    wire _1959;
    wire [31:0] _1975;
    wire _1958;
    wire [31:0] _1979;
    wire [4:0] _1956;
    wire _1957;
    wire [31:0] _1983;
    wire [15:0] _1984;
    wire [15:0] _2012;
    wire [15:0] _1947;
    wire [31:0] _1949;
    wire [23:0] _1943;
    wire [31:0] _1945;
    wire [27:0] _1939;
    wire [31:0] _1941;
    wire [29:0] _1935;
    wire [31:0] _1937;
    wire _1931;
    wire [31:0] _1934;
    wire _1930;
    wire [31:0] _1938;
    wire _1929;
    wire [31:0] _1942;
    wire _1928;
    wire [31:0] _1946;
    wire _1927;
    wire [31:0] _1950;
    wire [15:0] _1951;
    wire [15:0] _1952;
    wire [15:0] _1953;
    wire [15:0] _1923;
    wire [31:0] _1924;
    wire [23:0] _1919;
    wire [31:0] _1920;
    wire [27:0] _1915;
    wire [31:0] _1916;
    wire [29:0] _1911;
    wire [31:0] _1912;
    wire [30:0] _1907;
    wire [31:0] _1908;
    wire [15:0] _1530;
    wire [31:0] _1532;
    wire [23:0] _1526;
    wire [31:0] _1528;
    wire [27:0] _1522;
    wire [31:0] _1524;
    wire [29:0] _1518;
    wire [31:0] _1520;
    wire _1514;
    wire [31:0] _1517;
    wire _1513;
    wire [31:0] _1521;
    wire _1512;
    wire [31:0] _1525;
    wire _1511;
    wire [31:0] _1529;
    wire _1510;
    wire [31:0] _1533;
    wire [15:0] _1534;
    wire [15:0] _1535;
    wire [15:0] _1857;
    wire [15:0] _1852;
    wire [31:0] _1854;
    wire [23:0] _1848;
    wire [31:0] _1850;
    wire [27:0] _1844;
    wire [31:0] _1846;
    wire [29:0] _1840;
    wire [31:0] _1842;
    wire [30:0] _1836;
    wire [31:0] _1838;
    wire [31:0] _1835;
    wire _1833;
    wire [31:0] _1839;
    wire _1832;
    wire [31:0] _1843;
    wire _1831;
    wire [31:0] _1847;
    wire _1830;
    wire [31:0] _1851;
    wire _1829;
    wire [31:0] _1855;
    wire [15:0] _1856;
    wire [15:0] _1858;
    wire [15:0] _1825;
    wire [31:0] _1826;
    wire [23:0] _1821;
    wire [31:0] _1822;
    wire [27:0] _1817;
    wire [31:0] _1818;
    wire [29:0] _1813;
    wire [31:0] _1814;
    wire [30:0] _1809;
    wire [31:0] _1810;
    wire _1678;
    wire _1675;
    wire _1674;
    wire _1673;
    wire _1672;
    wire _1671;
    wire _1670;
    wire _1669;
    wire _1668;
    reg _1676;
    wire _1679;
    wire _1666;
    wire _1663;
    wire _1662;
    wire _1661;
    wire _1660;
    wire _1659;
    wire _1658;
    wire _1657;
    wire _1656;
    wire [2:0] _1655;
    reg _1664;
    wire _1667;
    wire [4:0] _1651;
    wire _1652;
    wire _1649;
    wire _1648;
    wire _1647;
    wire _1646;
    wire _1645;
    wire _1644;
    wire _1643;
    wire _1642;
    wire [2:0] _1641;
    reg _1650;
    wire _1653;
    wire [4:0] _1637;
    wire _1638;
    wire _1635;
    wire _1634;
    wire _1633;
    wire _1632;
    wire _1631;
    wire _1630;
    wire _1629;
    wire _1628;
    wire [2:0] _1627;
    reg _1636;
    wire _1639;
    wire [4:0] _1623;
    wire _1624;
    wire _1621;
    wire _1620;
    wire _1619;
    wire _1618;
    wire _1617;
    wire _1616;
    wire _1615;
    wire _1614;
    wire [2:0] _1613;
    reg _1622;
    wire _1625;
    wire [4:0] _1609;
    wire _1610;
    wire _1607;
    wire _1606;
    wire _1605;
    wire _1604;
    wire _1603;
    wire _1602;
    wire _1601;
    wire _1600;
    wire [2:0] _1598;
    wire [2:0] _1599;
    reg _1608;
    wire _1611;
    wire [4:0] _1595;
    wire _1596;
    wire _1593;
    wire _1592;
    wire _1591;
    wire _1590;
    wire _1589;
    wire _1588;
    wire _1587;
    wire _1586;
    wire [2:0] _1585;
    reg _1594;
    wire _1597;
    wire [4:0] _1581;
    wire _1582;
    wire _1579;
    wire _1578;
    wire _1577;
    wire _1576;
    wire _1575;
    wire _1574;
    wire _1573;
    wire _1572;
    wire [2:0] _1570;
    wire [2:0] _1772;
    wire [6:0] _1769;
    wire _1770;
    wire _1768;
    wire _1771;
    wire [2:0] _1773;
    wire [2:0] _45;
    reg [2:0] cfg_t1_in_base;
    wire [2:0] _1571;
    reg _1580;
    wire _1583;
    wire [7:0] _1680;
    wire [15:0] _1681;
    wire [1:0] _1568;
    reg [15:0] _1689;
    wire [31:0] _1807;
    wire _1806;
    wire [31:0] _1811;
    wire _1805;
    wire [31:0] _1815;
    wire _1804;
    wire [31:0] _1819;
    wire _1803;
    wire [31:0] _1823;
    wire _1802;
    wire [31:0] _1827;
    wire [15:0] _1828;
    wire [15:0] _1859;
    wire [15:0] _1861;
    wire [15:0] _1800;
    wire _1783;
    wire [15:0] _1796;
    wire [15:0] _1797;
    wire _1781;
    wire [15:0] _1798;
    wire _1780;
    wire [15:0] _1801;
    wire _1778;
    wire [15:0] _1862;
    wire [15:0] _1863;
    wire [15:0] _1864;
    wire [15:0] _1865;
    wire [15:0] _1867;
    wire [15:0] _46;
    wire [15:0] _47;
    reg [15:0] t1_isr;
    wire [31:0] _1905;
    wire _1903;
    wire [31:0] _1909;
    wire _1902;
    wire [31:0] _1913;
    wire _1901;
    wire [31:0] _1917;
    wire _1900;
    wire [31:0] _1921;
    wire [4:0] _1884;
    wire [5:0] _1881;
    wire [5:0] _1880;
    wire [5:0] _1882;
    wire [5:0] _1879;
    wire _1883;
    wire [4:0] _1886;
    wire [5:0] _1385;
    wire [5:0] _1383;
    wire [5:0] _1376;
    wire [5:0] _1384;
    wire _1386;
    wire _1387;
    wire _1371;
    wire _1370;
    wire _1372;
    wire _1388;
    wire [4:0] _1888;
    wire [4:0] _1877;
    wire _1871;
    wire [4:0] _1873;
    wire [4:0] _1874;
    wire _1870;
    wire [4:0] _1875;
    wire _1869;
    wire [4:0] _1878;
    wire _1868;
    wire [4:0] _1889;
    wire [4:0] _1890;
    wire [4:0] _1891;
    wire [4:0] _1892;
    wire [4:0] _1894;
    wire [4:0] _48;
    wire [4:0] _49;
    reg [4:0] t1_isr_count;
    wire [4:0] _1898;
    wire _1899;
    wire [31:0] _1925;
    wire [15:0] _1926;
    wire _1505;
    wire [15:0] _1954;
    wire _1896;
    wire [15:0] _2013;
    wire [15:0] _50;
    reg [15:0] t1_rx_mem_0;
    wire [1:0] _2040;
    wire _2037;
    wire _2032;
    wire _2033;
    wire _2027;
    wire _2025;
    wire _2028;
    wire _2029;
    wire _2021;
    wire _2022;
    wire [6:0] _2017;
    wire _2018;
    wire _2014;
    wire _2015;
    wire _2016;
    wire _2019;
    wire _2023;
    wire _51;
    wire _2030;
    wire _2034;
    wire _2038;
    wire [1:0] _2041;
    wire [1:0] _52;
    reg [1:0] t1_rx_rd;
    reg [15:0] _511;
    wire _401;
    wire _402;
    reg [15:0] t0_rx_mem_3;
    wire _395;
    wire _396;
    reg [15:0] t0_rx_mem_2;
    wire _389;
    wire _390;
    reg [15:0] t0_rx_mem_1;
    wire [1:0] _2043;
    wire [1:0] _2044;
    wire [1:0] _53;
    reg [1:0] t0_rx_wr;
    wire _383;
    wire _384;
    wire [15:0] _3720;
    wire [31:0] _3722;
    wire [23:0] _3716;
    wire [31:0] _3718;
    wire [27:0] _3712;
    wire [31:0] _3714;
    wire [29:0] _3708;
    wire [31:0] _3710;
    wire _3704;
    wire [31:0] _3707;
    wire _3703;
    wire [31:0] _3711;
    wire _3702;
    wire [31:0] _3715;
    wire _3701;
    wire [31:0] _3719;
    wire _3700;
    wire [31:0] _3723;
    wire [15:0] _3724;
    wire [15:0] _3725;
    wire [15:0] _3726;
    wire [15:0] _3696;
    wire [31:0] _3697;
    wire [23:0] _3692;
    wire [31:0] _3693;
    wire [27:0] _3688;
    wire [31:0] _3689;
    wire [29:0] _3684;
    wire [31:0] _3685;
    wire [30:0] _3680;
    wire [31:0] _3681;
    wire [31:0] _3678;
    wire _3676;
    wire [31:0] _3682;
    wire _3675;
    wire [31:0] _3686;
    wire _3674;
    wire [31:0] _3690;
    wire _3673;
    wire [31:0] _3694;
    wire [4:0] _3671;
    wire _3672;
    wire [31:0] _3698;
    wire [15:0] _3699;
    wire [15:0] _3727;
    wire [15:0] _3662;
    wire [31:0] _3664;
    wire [23:0] _3658;
    wire [31:0] _3660;
    wire [27:0] _3654;
    wire [31:0] _3656;
    wire [29:0] _3650;
    wire [31:0] _3652;
    wire _3646;
    wire [31:0] _3649;
    wire _3645;
    wire [31:0] _3653;
    wire _3644;
    wire [31:0] _3657;
    wire _3643;
    wire [31:0] _3661;
    wire _3642;
    wire [31:0] _3665;
    wire [15:0] _3666;
    wire [15:0] _3667;
    wire [15:0] _3668;
    wire [15:0] _3638;
    wire [31:0] _3639;
    wire [23:0] _3634;
    wire [31:0] _3635;
    wire [27:0] _3630;
    wire [31:0] _3631;
    wire [29:0] _3626;
    wire [31:0] _3627;
    wire [30:0] _3622;
    wire [31:0] _3623;
    wire [15:0] _1005;
    wire [31:0] _1007;
    wire [23:0] _1001;
    wire [31:0] _1003;
    wire [27:0] _997;
    wire [31:0] _999;
    wire [29:0] _993;
    wire [31:0] _995;
    wire _989;
    wire [31:0] _992;
    wire _988;
    wire [31:0] _996;
    wire _987;
    wire [31:0] _1000;
    wire _986;
    wire [31:0] _1004;
    wire _985;
    wire [31:0] _1008;
    wire [15:0] _1009;
    wire [15:0] _1010;
    wire [15:0] _3572;
    wire [15:0] _3567;
    wire [31:0] _3569;
    wire [23:0] _3563;
    wire [31:0] _3565;
    wire [27:0] _3559;
    wire [31:0] _3561;
    wire [29:0] _3555;
    wire [31:0] _3557;
    wire [30:0] _3551;
    wire [31:0] _3553;
    wire [31:0] _3550;
    wire _3548;
    wire [31:0] _3554;
    wire _3547;
    wire [31:0] _3558;
    wire _3546;
    wire [31:0] _3562;
    wire _3545;
    wire [31:0] _3566;
    wire _3544;
    wire [31:0] _3570;
    wire [15:0] _3571;
    wire [15:0] _3573;
    wire [15:0] _3540;
    wire [31:0] _3541;
    wire [23:0] _3536;
    wire [31:0] _3537;
    wire [27:0] _3532;
    wire [31:0] _3533;
    wire [29:0] _3528;
    wire [31:0] _3529;
    wire [30:0] _3524;
    wire [31:0] _3525;
    wire _1153;
    wire _1150;
    wire _1149;
    wire _1148;
    wire _1147;
    wire _1146;
    wire _1145;
    wire _1144;
    wire _1143;
    reg _1151;
    wire _1154;
    wire _1141;
    wire _1138;
    wire _1137;
    wire _1136;
    wire _1135;
    wire _1134;
    wire _1133;
    wire _1132;
    wire _1131;
    wire [2:0] _1130;
    reg _1139;
    wire _1142;
    wire _1127;
    wire _1124;
    wire _1123;
    wire _1122;
    wire _1121;
    wire _1120;
    wire _1119;
    wire _1118;
    wire _1117;
    wire [2:0] _1116;
    reg _1125;
    wire _1128;
    wire _1113;
    wire _1110;
    wire _1109;
    wire _1108;
    wire _1107;
    wire _1106;
    wire _1105;
    wire _1104;
    wire _1103;
    wire [2:0] _1102;
    reg _1111;
    wire _1114;
    wire _1099;
    wire _1096;
    wire _1095;
    wire _1094;
    wire _1093;
    wire _1092;
    wire _1091;
    wire _1090;
    wire _1089;
    wire [2:0] _1088;
    reg _1097;
    wire _1100;
    wire _1085;
    wire _1082;
    wire _1081;
    wire _1080;
    wire _1079;
    wire _1078;
    wire _1077;
    wire _1076;
    wire _1075;
    wire [2:0] _1074;
    reg _1083;
    wire _1086;
    wire _1071;
    wire _1068;
    wire _1067;
    wire _1066;
    wire _1065;
    wire _1064;
    wire _1063;
    wire _1062;
    wire _1061;
    wire [2:0] _1060;
    reg _1069;
    wire _1072;
    wire _1057;
    wire _1054;
    wire _1053;
    wire _1052;
    wire _1051;
    wire _1050;
    wire _1049;
    wire _1048;
    wire _788;
    wire _787;
    wire _786;
    wire [1:0] _785;
    reg _789;
    wire _783;
    wire _784;
    wire _790;
    wire [2:0] _778;
    wire _780;
    wire _781;
    wire _791;
    wire _774;
    wire _773;
    wire _772;
    wire [1:0] _771;
    reg _775;
    wire _769;
    wire _770;
    wire _776;
    wire [2:0] _764;
    wire _766;
    wire _767;
    wire _777;
    wire _760;
    wire _759;
    wire _758;
    wire [1:0] _757;
    reg _761;
    wire _755;
    wire _756;
    wire _762;
    wire [2:0] _750;
    wire _752;
    wire _753;
    wire _763;
    wire _746;
    wire _745;
    wire _744;
    wire [1:0] _743;
    reg _747;
    wire _741;
    wire _742;
    wire _748;
    wire [2:0] _736;
    wire _738;
    wire _739;
    wire _749;
    wire _732;
    wire _731;
    wire _730;
    wire [1:0] _729;
    reg _733;
    wire _727;
    wire _728;
    wire _734;
    wire [2:0] _722;
    wire _724;
    wire _725;
    wire _735;
    wire _718;
    wire _717;
    wire _716;
    wire [1:0] _715;
    reg _719;
    wire _713;
    wire _714;
    wire _720;
    wire [2:0] _708;
    wire _710;
    wire _711;
    wire _721;
    wire _704;
    wire _703;
    wire _702;
    wire [1:0] _701;
    reg _705;
    wire _699;
    wire _700;
    wire _706;
    wire [2:0] _694;
    wire _696;
    wire _697;
    wire _707;
    wire _2209;
    wire _2202;
    wire _2203;
    wire _2210;
    wire _2211;
    wire _54;
    reg smp_data;
    wire _2298;
    wire _2196;
    wire _2197;
    wire _2198;
    wire _2195;
    wire _2199;
    wire _2235;
    wire _2231;
    wire _2232;
    wire [7:0] _2216;
    wire [6:0] _2213;
    wire _2214;
    wire _2212;
    wire _2215;
    wire [7:0] _2217;
    wire [7:0] _55;
    reg [7:0] cfg_smp_sync;
    wire [7:0] _2227;
    wire [6:0] _2223;
    wire [7:0] _2224;
    wire [7:0] _2221;
    wire [7:0] _2222;
    wire _2172;
    wire _2165;
    wire _2138;
    wire _2139;
    wire _2140;
    wire _2166;
    wire _2173;
    wire _2174;
    wire _2175;
    wire [7:0] _2225;
    wire [7:0] _2226;
    wire [7:0] _2228;
    wire [7:0] _2229;
    wire [7:0] _56;
    reg [7:0] smp_history;
    wire [6:0] _2189;
    wire [7:0] _2190;
    wire _2191;
    wire _2192;
    wire _2193;
    wire _2194;
    wire _2233;
    wire _2234;
    wire _2236;
    wire _2237;
    wire _57;
    reg smp_synced;
    wire _2200;
    wire _2182;
    wire [3:0] _2255;
    wire [3:0] _2250;
    wire [3:0] _2164;
    wire _2247;
    wire _2248;
    wire [3:0] _2251;
    wire _2170;
    wire _2171;
    wire [3:0] _2252;
    wire [3:0] _2159;
    wire [3:0] _2155;
    wire _2156;
    wire _2157;
    wire [3:0] _2160;
    wire _2241;
    wire _2167;
    wire _2168;
    wire _2169;
    wire _2239;
    wire _2240;
    wire _2242;
    wire _2243;
    wire _58;
    reg smp_slevel;
    wire _2147;
    wire _2148;
    wire _2152;
    wire _2153;
    wire [3:0] _2161;
    wire [3:0] _2162;
    wire [3:0] _2163;
    wire _2134;
    wire _2135;
    wire [3:0] _2253;
    wire [3:0] _2254;
    wire [3:0] _2256;
    wire [3:0] _2257;
    wire [3:0] _59;
    reg [3:0] smp_run;
    wire _2180;
    wire [2:0] _2136;
    wire _2177;
    wire _2178;
    wire _2179;
    wire _2181;
    wire _2183;
    wire _2184;
    wire [4:0] _2133;
    wire _2142;
    wire _2110;
    wire [4:0] _2280;
    wire [4:0] _2129;
    wire [4:0] _2130;
    wire [4:0] _2082;
    wire [4:0] _2101;
    wire [4:0] _2102;
    wire _2096;
    wire _2097;
    wire _2270;
    wire [2:0] _2118;
    wire [2:0] _2266;
    wire [2:0] _2262;
    wire _2259;
    wire _2260;
    wire [2:0] _2263;
    wire [2:0] _2265;
    wire [2:0] _2267;
    wire [2:0] _2268;
    wire [2:0] _60;
    reg [2:0] smp_missed;
    wire _2092;
    wire _2115;
    wire _2116;
    wire [2:0] _2119;
    wire [2:0] _2121;
    wire _2122;
    wire [2:0] _2090;
    wire _2114;
    wire _2123;
    wire _2112;
    wire _2124;
    wire _2108;
    wire _2109;
    wire _2125;
    wire _2126;
    wire _2271;
    wire _2272;
    wire _61;
    reg smp_carrier;
    wire [14:0] _573;
    wire [14:0] _2277;
    wire [6:0] _2274;
    wire _2275;
    wire _2273;
    wire _2276;
    wire [14:0] _2278;
    wire [14:0] _62;
    reg [14:0] cfg_smp_time;
    wire [4:0] _2086;
    wire _2087;
    wire _2088;
    wire _2089;
    wire _2098;
    wire _2099;
    wire [4:0] _2104;
    wire _2105;
    wire _2106;
    wire _2074;
    wire _2107;
    wire _2127;
    wire [4:0] _2132;
    wire [4:0] _2281;
    wire [4:0] _2282;
    wire [4:0] _63;
    reg [4:0] smp_phase;
    wire _2083;
    wire _2084;
    wire [9:0] _2286;
    wire _2287;
    wire _2288;
    wire [9:0] _2290;
    wire [9:0] _2291;
    wire [9:0] _2292;
    wire [9:0] _64;
    reg [9:0] smp_pre;
    wire _2208;
    wire _2294;
    wire _2057;
    wire _2056;
    wire _2055;
    wire _2054;
    wire _2053;
    wire _2052;
    wire _2051;
    wire _2050;
    reg _2058;
    reg smp_fall;
    reg smp_mid;
    wire _2295;
    wire _2296;
    wire _65;
    reg smp_last;
    wire _2072;
    wire _2071;
    wire _2070;
    wire _2069;
    wire _2068;
    wire _2067;
    wire _2066;
    wire _2065;
    reg _2073;
    wire _2078;
    wire _2085;
    wire _2111;
    wire _2143;
    wire _2185;
    wire _2201;
    wire _2297;
    wire [9:0] _2046;
    wire _2048;
    wire _2049;
    wire _2299;
    wire _2300;
    wire _66;
    reg smp_strobe;
    wire _684;
    wire [7:0] _164;
    wire _3469;
    wire _3468;
    wire _3467;
    wire _3466;
    wire _3465;
    wire _3464;
    wire _3463;
    wire _3462;
    reg _3470;
    wire _3461;
    wire [3:0] _3459;
    wire [2:0] _3456;
    wire [3:0] _3457;
    wire _3460;
    wire _3471;
    wire _3452;
    wire _3451;
    wire _3450;
    wire _3449;
    wire _3448;
    wire _3447;
    wire _3446;
    wire _3445;
    reg _3453;
    wire _3444;
    wire [3:0] _3442;
    wire [2:0] _3439;
    wire [3:0] _3440;
    wire _3443;
    wire _3454;
    wire _3435;
    wire _3434;
    wire _3433;
    wire _3432;
    wire _3431;
    wire _3430;
    wire _3429;
    wire _3428;
    reg _3436;
    wire _3427;
    wire [3:0] _3425;
    wire [2:0] _3422;
    wire [3:0] _3423;
    wire _3426;
    wire _3437;
    wire _3418;
    wire _3417;
    wire _3416;
    wire _3415;
    wire _3414;
    wire _3413;
    wire _3412;
    wire _3411;
    reg _3419;
    wire _3410;
    wire [3:0] _3408;
    wire [2:0] _3405;
    wire [3:0] _3406;
    wire _3409;
    wire _3420;
    wire _3401;
    wire _3400;
    wire _3399;
    wire _3398;
    wire _3397;
    wire _3396;
    wire _3395;
    wire _3394;
    reg _3402;
    wire _3393;
    wire [3:0] _3391;
    wire [2:0] _3388;
    wire [3:0] _3389;
    wire _3392;
    wire _3403;
    wire _3384;
    wire _3383;
    wire _3382;
    wire _3381;
    wire _3380;
    wire _3379;
    wire _3378;
    wire _3377;
    reg _3385;
    wire _3376;
    wire [3:0] _3374;
    wire [2:0] _3371;
    wire [3:0] _3372;
    wire _3375;
    wire _3386;
    wire _3367;
    wire _3366;
    wire _3365;
    wire _3364;
    wire _3363;
    wire _3362;
    wire _3361;
    wire _3360;
    reg _3368;
    wire _3359;
    wire [3:0] _3357;
    wire [2:0] _3354;
    wire [3:0] _3355;
    wire _3358;
    wire _3369;
    wire _3350;
    wire _3349;
    wire _3348;
    wire _3347;
    wire _3346;
    wire _3345;
    wire _3344;
    wire [1:0] _3337;
    wire [3:0] _3338;
    wire [2:0] _3333;
    wire [3:0] _3334;
    wire [3:0] _3331;
    wire _3330;
    wire [3:0] _3335;
    wire _3329;
    wire [3:0] _3339;
    wire [2:0] _3326;
    wire [2:0] _3327;
    wire _3328;
    wire [3:0] _3341;
    wire [7:0] _3342;
    wire _3343;
    reg _3351;
    wire _3318;
    wire _3317;
    wire _3316;
    wire _3315;
    wire _3314;
    wire _3313;
    wire _3312;
    wire _3311;
    reg _3319;
    wire _3310;
    wire [2:0] _3307;
    wire [4:0] _3308;
    wire _3309;
    wire _3320;
    wire _3302;
    wire _3301;
    wire _3300;
    wire _3299;
    wire _3298;
    wire _3297;
    wire _3296;
    wire _3295;
    reg _3303;
    wire _3294;
    wire [2:0] _3291;
    wire [4:0] _3292;
    wire _3293;
    wire _3304;
    wire _3286;
    wire _3285;
    wire _3284;
    wire _3283;
    wire _3282;
    wire _3281;
    wire _3280;
    wire _3279;
    reg _3287;
    wire _3278;
    wire [2:0] _3275;
    wire [4:0] _3276;
    wire _3277;
    wire _3288;
    wire _3270;
    wire _3269;
    wire _3268;
    wire _3267;
    wire _3266;
    wire _3265;
    wire _3264;
    wire _3263;
    reg _3271;
    wire _3262;
    wire [2:0] _3259;
    wire [4:0] _3260;
    wire _3261;
    wire _3272;
    wire _3254;
    wire _3253;
    wire _3252;
    wire _3251;
    wire _3250;
    wire _3249;
    wire _3248;
    wire _3247;
    reg _3255;
    wire _3246;
    wire [2:0] _3243;
    wire [4:0] _3244;
    wire _3245;
    wire _3256;
    wire _3238;
    wire _3237;
    wire _3236;
    wire _3235;
    wire _3234;
    wire _3233;
    wire _3232;
    wire _3231;
    reg _3239;
    wire _3230;
    wire [2:0] _3227;
    wire [4:0] _3228;
    wire _3229;
    wire _3240;
    wire _3222;
    wire _3221;
    wire _3220;
    wire _3219;
    wire _3218;
    wire _3217;
    wire _3216;
    wire _3215;
    reg _3223;
    wire _3214;
    wire [2:0] _3211;
    wire [4:0] _3212;
    wire _3213;
    wire _3224;
    wire _3206;
    wire _3205;
    wire _3204;
    wire _3203;
    wire _3202;
    wire _3201;
    wire _3200;
    wire _3199;
    reg _3207;
    wire _3198;
    wire [2:0] _3195;
    wire [4:0] _3196;
    wire _3197;
    wire _3208;
    wire [7:0] _3321;
    wire _3188;
    wire _3187;
    wire _3186;
    wire _3185;
    wire _3184;
    wire _3183;
    wire _3182;
    wire _3181;
    reg _3189;
    wire _3180;
    wire [2:0] _3177;
    wire [3:0] _3178;
    wire _3179;
    wire _3190;
    wire _3173;
    wire _3172;
    wire _3171;
    wire _3170;
    wire _3169;
    wire _3168;
    wire _3167;
    wire _3166;
    reg _3174;
    wire _3165;
    wire [2:0] _3162;
    wire [3:0] _3163;
    wire _3164;
    wire _3175;
    wire _3158;
    wire _3157;
    wire _3156;
    wire _3155;
    wire _3154;
    wire _3153;
    wire _3152;
    wire _3151;
    reg _3159;
    wire _3150;
    wire [2:0] _3147;
    wire [3:0] _3148;
    wire _3149;
    wire _3160;
    wire _3143;
    wire _3142;
    wire _3141;
    wire _3140;
    wire _3139;
    wire _3138;
    wire _3137;
    wire _3136;
    reg _3144;
    wire _3135;
    wire [2:0] _3132;
    wire [3:0] _3133;
    wire _3134;
    wire _3145;
    wire _3128;
    wire _3127;
    wire _3126;
    wire _3125;
    wire _3124;
    wire _3123;
    wire _3122;
    wire _3121;
    reg _3129;
    wire _3120;
    wire [2:0] _3117;
    wire [3:0] _3118;
    wire _3119;
    wire _3130;
    wire _3113;
    wire _3112;
    wire _3111;
    wire _3110;
    wire _3109;
    wire _3108;
    wire _3107;
    wire _3106;
    reg _3114;
    wire _3105;
    wire [2:0] _3102;
    wire [3:0] _3103;
    wire _3104;
    wire _3115;
    wire _3098;
    wire _3097;
    wire _3096;
    wire _3095;
    wire _3094;
    wire _3093;
    wire _3092;
    wire _3091;
    reg _3099;
    wire _3090;
    wire [2:0] _3087;
    wire [3:0] _3088;
    wire _3089;
    wire _3100;
    wire _3083;
    wire _3082;
    wire _3081;
    wire _3080;
    wire _3079;
    wire _3078;
    wire _3077;
    wire _3076;
    reg _3084;
    wire _3075;
    wire [3:0] _3073;
    wire [7:0] _447;
    wire [7:0] _2305;
    wire [6:0] _2302;
    wire _2303;
    wire _2301;
    wire _2304;
    wire [7:0] _2306;
    wire [7:0] _67;
    reg [7:0] cfg_t1_out_cfg;
    wire [2:0] _3070;
    wire [2:0] _3071;
    wire [3:0] _3072;
    wire _3074;
    wire _3085;
    wire [7:0] _3191;
    wire _3064;
    wire _3063;
    wire _3062;
    wire _3061;
    wire _3060;
    wire _3059;
    wire _3058;
    wire _3057;
    reg _3065;
    wire _3056;
    wire [2:0] _3053;
    wire [3:0] _3054;
    wire _3055;
    wire _3066;
    wire _3049;
    wire _3048;
    wire _3047;
    wire _3046;
    wire _3045;
    wire _3044;
    wire _3043;
    wire _3042;
    reg _3050;
    wire _3041;
    wire [2:0] _3038;
    wire [3:0] _3039;
    wire _3040;
    wire _3051;
    wire _3034;
    wire _3033;
    wire _3032;
    wire _3031;
    wire _3030;
    wire _3029;
    wire _3028;
    wire _3027;
    reg _3035;
    wire _3026;
    wire [2:0] _3023;
    wire [3:0] _3024;
    wire _3025;
    wire _3036;
    wire _3019;
    wire _3018;
    wire _3017;
    wire _3016;
    wire _3015;
    wire _3014;
    wire _3013;
    wire _3012;
    reg _3020;
    wire _3011;
    wire [2:0] _3008;
    wire [3:0] _3009;
    wire _3010;
    wire _3021;
    wire _3004;
    wire _3003;
    wire _3002;
    wire _3001;
    wire _3000;
    wire _2999;
    wire _2998;
    wire _2997;
    reg _3005;
    wire _2996;
    wire [2:0] _2993;
    wire [3:0] _2994;
    wire _2995;
    wire _3006;
    wire _2989;
    wire _2988;
    wire _2987;
    wire _2986;
    wire _2985;
    wire _2984;
    wire _2983;
    wire _2982;
    reg _2990;
    wire _2981;
    wire [2:0] _2978;
    wire [3:0] _2979;
    wire _2980;
    wire _2991;
    wire _2974;
    wire _2973;
    wire _2972;
    wire _2971;
    wire _2970;
    wire _2969;
    wire _2968;
    wire _2967;
    reg _2975;
    wire _2966;
    wire [2:0] _2963;
    wire [3:0] _2964;
    wire _2965;
    wire _2976;
    wire _2959;
    wire _2958;
    wire _2957;
    wire _2956;
    wire _2955;
    wire _2954;
    wire _2953;
    wire _2952;
    reg _2960;
    wire _2948;
    wire [3:0] _2946;
    wire [7:0] _2311;
    wire [6:0] _2308;
    wire _2309;
    wire _2307;
    wire _2310;
    wire [7:0] _2312;
    wire [7:0] _68;
    reg [7:0] cfg_t1_set_cfg;
    wire [2:0] _2943;
    wire [2:0] _2944;
    wire [3:0] _2945;
    wire _2947;
    wire _2961;
    wire [7:0] _3067;
    wire _2901;
    wire _2900;
    wire _2899;
    wire _2898;
    wire _2897;
    wire _2896;
    wire _2895;
    wire _2894;
    reg _2902;
    wire _2893;
    wire [3:0] _2891;
    wire [2:0] _2888;
    wire [3:0] _2889;
    wire _2892;
    wire _2903;
    wire _2884;
    wire _2883;
    wire _2882;
    wire _2881;
    wire _2880;
    wire _2879;
    wire _2878;
    wire _2877;
    reg _2885;
    wire _2876;
    wire [3:0] _2874;
    wire [2:0] _2871;
    wire [3:0] _2872;
    wire _2875;
    wire _2886;
    wire _2867;
    wire _2866;
    wire _2865;
    wire _2864;
    wire _2863;
    wire _2862;
    wire _2861;
    wire _2860;
    reg _2868;
    wire _2859;
    wire [3:0] _2857;
    wire [2:0] _2854;
    wire [3:0] _2855;
    wire _2858;
    wire _2869;
    wire _2850;
    wire _2849;
    wire _2848;
    wire _2847;
    wire _2846;
    wire _2845;
    wire _2844;
    wire _2843;
    reg _2851;
    wire _2842;
    wire [3:0] _2840;
    wire [2:0] _2837;
    wire [3:0] _2838;
    wire _2841;
    wire _2852;
    wire _2833;
    wire _2832;
    wire _2831;
    wire _2830;
    wire _2829;
    wire _2828;
    wire _2827;
    wire _2826;
    reg _2834;
    wire _2825;
    wire [3:0] _2823;
    wire [2:0] _2820;
    wire [3:0] _2821;
    wire _2824;
    wire _2835;
    wire _2816;
    wire _2815;
    wire _2814;
    wire _2813;
    wire _2812;
    wire _2811;
    wire _2810;
    wire _2809;
    reg _2817;
    wire _2808;
    wire [3:0] _2806;
    wire [2:0] _2803;
    wire [3:0] _2804;
    wire _2807;
    wire _2818;
    wire _2799;
    wire _2798;
    wire _2797;
    wire _2796;
    wire _2795;
    wire _2794;
    wire _2793;
    wire _2792;
    reg _2800;
    wire _2791;
    wire [3:0] _2789;
    wire [2:0] _2786;
    wire [3:0] _2787;
    wire _2790;
    wire _2801;
    wire _2782;
    wire _2781;
    wire _2780;
    wire _2779;
    wire _2778;
    wire _2777;
    wire _2776;
    wire [1:0] _2769;
    wire [3:0] _2770;
    wire [2:0] _2765;
    wire [3:0] _2766;
    wire [3:0] _2763;
    wire _2762;
    wire [3:0] _2767;
    wire _2761;
    wire [3:0] _2771;
    wire [2:0] _2758;
    wire [2:0] _2759;
    wire _2760;
    wire [3:0] _2773;
    wire [7:0] _2774;
    wire _2775;
    reg _2783;
    wire _2750;
    wire _2749;
    wire _2748;
    wire _2747;
    wire _2746;
    wire _2745;
    wire _2744;
    wire _2743;
    reg _2751;
    wire _2742;
    wire [2:0] _2739;
    wire [4:0] _2740;
    wire _2741;
    wire _2752;
    wire _2734;
    wire _2733;
    wire _2732;
    wire _2731;
    wire _2730;
    wire _2729;
    wire _2728;
    wire _2727;
    reg _2735;
    wire _2726;
    wire [2:0] _2723;
    wire [4:0] _2724;
    wire _2725;
    wire _2736;
    wire _2718;
    wire _2717;
    wire _2716;
    wire _2715;
    wire _2714;
    wire _2713;
    wire _2712;
    wire _2711;
    reg _2719;
    wire _2710;
    wire [2:0] _2707;
    wire [4:0] _2708;
    wire _2709;
    wire _2720;
    wire _2702;
    wire _2701;
    wire _2700;
    wire _2699;
    wire _2698;
    wire _2697;
    wire _2696;
    wire _2695;
    reg _2703;
    wire _2694;
    wire [2:0] _2691;
    wire [4:0] _2692;
    wire _2693;
    wire _2704;
    wire _2686;
    wire _2685;
    wire _2684;
    wire _2683;
    wire _2682;
    wire _2681;
    wire _2680;
    wire _2679;
    reg _2687;
    wire _2678;
    wire [2:0] _2675;
    wire [4:0] _2676;
    wire _2677;
    wire _2688;
    wire _2670;
    wire _2669;
    wire _2668;
    wire _2667;
    wire _2666;
    wire _2665;
    wire _2664;
    wire _2663;
    reg _2671;
    wire _2662;
    wire [2:0] _2659;
    wire [4:0] _2660;
    wire _2661;
    wire _2672;
    wire _2654;
    wire _2653;
    wire _2652;
    wire _2651;
    wire _2650;
    wire _2649;
    wire _2648;
    wire _2647;
    reg _2655;
    wire _2646;
    wire [2:0] _2643;
    wire [4:0] _2644;
    wire _2645;
    wire _2656;
    wire _2638;
    wire _2637;
    wire _2636;
    wire _2635;
    wire _2634;
    wire _2633;
    wire _2632;
    wire _2631;
    reg _2639;
    wire _2630;
    wire [2:0] _2627;
    wire [4:0] _2628;
    wire _2629;
    wire _2640;
    wire [7:0] _2753;
    wire _2620;
    wire _2619;
    wire _2618;
    wire _2617;
    wire _2616;
    wire _2615;
    wire _2614;
    wire _2613;
    reg _2621;
    wire _2612;
    wire [2:0] _2609;
    wire [3:0] _2610;
    wire _2611;
    wire _2622;
    wire _2605;
    wire _2604;
    wire _2603;
    wire _2602;
    wire _2601;
    wire _2600;
    wire _2599;
    wire _2598;
    reg _2606;
    wire _2597;
    wire [2:0] _2594;
    wire [3:0] _2595;
    wire _2596;
    wire _2607;
    wire _2590;
    wire _2589;
    wire _2588;
    wire _2587;
    wire _2586;
    wire _2585;
    wire _2584;
    wire _2583;
    reg _2591;
    wire _2582;
    wire [2:0] _2579;
    wire [3:0] _2580;
    wire _2581;
    wire _2592;
    wire _2575;
    wire _2574;
    wire _2573;
    wire _2572;
    wire _2571;
    wire _2570;
    wire _2569;
    wire _2568;
    reg _2576;
    wire _2567;
    wire [2:0] _2564;
    wire [3:0] _2565;
    wire _2566;
    wire _2577;
    wire _2560;
    wire _2559;
    wire _2558;
    wire _2557;
    wire _2556;
    wire _2555;
    wire _2554;
    wire _2553;
    reg _2561;
    wire _2552;
    wire [2:0] _2549;
    wire [3:0] _2550;
    wire _2551;
    wire _2562;
    wire _2545;
    wire _2544;
    wire _2543;
    wire _2542;
    wire _2541;
    wire _2540;
    wire _2539;
    wire _2538;
    reg _2546;
    wire _2537;
    wire [2:0] _2534;
    wire [3:0] _2535;
    wire _2536;
    wire _2547;
    wire _2530;
    wire _2529;
    wire _2528;
    wire _2527;
    wire _2526;
    wire _2525;
    wire _2524;
    wire _2523;
    reg _2531;
    wire _2522;
    wire [2:0] _2519;
    wire [3:0] _2520;
    wire _2521;
    wire _2532;
    wire _2515;
    wire _2514;
    wire _2513;
    wire _2512;
    wire _2511;
    wire _2510;
    wire _2509;
    wire _2508;
    reg _2516;
    wire _2492;
    wire [3:0] _2490;
    wire [7:0] _2317;
    wire [6:0] _2314;
    wire _2315;
    wire _2313;
    wire _2316;
    wire [7:0] _2318;
    wire [7:0] _69;
    reg [7:0] cfg_t0_out_cfg;
    wire [2:0] _2487;
    wire [2:0] _2488;
    wire [3:0] _2489;
    wire _2491;
    wire _2517;
    wire [7:0] _2623;
    wire _2481;
    wire _2480;
    wire _2479;
    wire _2478;
    wire _2477;
    wire _2476;
    wire _2475;
    wire _2474;
    reg _2482;
    wire _2473;
    wire [2:0] _2470;
    wire [3:0] _2471;
    wire _2472;
    wire _2483;
    wire _2466;
    wire _2465;
    wire _2464;
    wire _2463;
    wire _2462;
    wire _2461;
    wire _2460;
    wire _2459;
    reg _2467;
    wire _2458;
    wire [2:0] _2455;
    wire [3:0] _2456;
    wire _2457;
    wire _2468;
    wire _2451;
    wire _2450;
    wire _2449;
    wire _2448;
    wire _2447;
    wire _2446;
    wire _2445;
    wire _2444;
    reg _2452;
    wire _2443;
    wire [2:0] _2440;
    wire [3:0] _2441;
    wire _2442;
    wire _2453;
    wire _2436;
    wire _2435;
    wire _2434;
    wire _2433;
    wire _2432;
    wire _2431;
    wire _2430;
    wire _2429;
    reg _2437;
    wire _2428;
    wire [2:0] _2425;
    wire [3:0] _2426;
    wire _2427;
    wire _2438;
    wire _2421;
    wire _2420;
    wire _2419;
    wire _2418;
    wire _2417;
    wire _2416;
    wire _2415;
    wire _2414;
    reg _2422;
    wire _2413;
    wire [2:0] _2410;
    wire [3:0] _2411;
    wire _2412;
    wire _2423;
    wire _2406;
    wire _2405;
    wire _2404;
    wire _2403;
    wire _2402;
    wire _2401;
    wire _2400;
    wire _2399;
    reg _2407;
    wire _2398;
    wire [2:0] _2395;
    wire [3:0] _2396;
    wire _2397;
    wire _2408;
    wire _2391;
    wire _2390;
    wire _2389;
    wire _2388;
    wire _2387;
    wire _2386;
    wire _2385;
    wire _2384;
    reg _2392;
    wire _2383;
    wire [2:0] _2380;
    wire [3:0] _2381;
    wire _2382;
    wire _2393;
    wire _2376;
    wire _2375;
    wire _2374;
    wire _2373;
    wire _2372;
    wire _2371;
    wire _2370;
    wire _2369;
    reg _2377;
    wire _2365;
    wire [3:0] _2363;
    wire [7:0] _2323;
    wire [6:0] _2320;
    wire _2321;
    wire _2319;
    wire _2322;
    wire [7:0] _2324;
    wire [7:0] _70;
    reg [7:0] cfg_t0_set_cfg;
    wire [2:0] _2360;
    wire [2:0] _2361;
    wire [3:0] _2362;
    wire _2364;
    wire _2378;
    wire [7:0] _2484;
    wire _2357;
    wire _2354;
    wire _2355;
    wire _2358;
    wire [7:0] _2485;
    wire _2350;
    wire _2351;
    wire _2347;
    wire _2348;
    wire _2352;
    wire [7:0] _2624;
    wire [1:0] _2342;
    wire _2344;
    wire _2340;
    wire _2341;
    wire _2345;
    wire [7:0] _2754;
    wire _2755;
    wire [1:0] _2336;
    wire [3:0] _2337;
    wire [5:0] _2329;
    wire [6:0] _2326;
    wire _2327;
    wire _2325;
    wire _2328;
    wire [5:0] _2330;
    wire [5:0] _71;
    reg [5:0] cfg_t0_sideset;
    wire [2:0] _2332;
    wire [2:0] _2333;
    wire [3:0] _2334;
    wire _2338;
    wire _2784;
    wire [7:0] _2904;
    wire [7:0] _2905;
    wire [7:0] _2906;
    wire [7:0] _2907;
    wire [7:0] _72;
    wire _2940;
    wire _2937;
    wire _2938;
    wire _2941;
    wire [7:0] _3068;
    wire _2933;
    wire _2934;
    wire _2930;
    wire _2931;
    wire _2935;
    wire [7:0] _3192;
    wire [1:0] _2925;
    wire _2927;
    wire _2923;
    wire _2924;
    wire _2928;
    wire [7:0] _3322;
    wire _3323;
    wire [1:0] _2919;
    wire [3:0] _2920;
    wire [5:0] _2912;
    wire [6:0] _2909;
    wire _2910;
    wire _2908;
    wire _2911;
    wire [5:0] _2913;
    wire [5:0] _73;
    reg [5:0] cfg_t1_sideset;
    wire [2:0] _2915;
    wire [2:0] _2916;
    wire [3:0] _2917;
    wire _2921;
    wire _3352;
    wire [7:0] _3472;
    wire [7:0] _3473;
    wire [7:0] _3474;
    wire [7:0] _3475;
    wire [7:0] _74;
    wire [7:0] _75;
    reg [7:0] pin_out;
    wire _683;
    wire [7:0] _679;
    reg [7:0] pins_sync1;
    reg [7:0] pins_sync2;
    wire [7:0] _680;
    wire [7:0] _3480;
    wire [6:0] _3477;
    wire _3478;
    wire _3476;
    wire _3479;
    wire [7:0] _3481;
    wire [7:0] _76;
    reg [7:0] cfg_sync_bypass;
    wire [7:0] _78;
    wire [7:0] _673;
    wire [7:0] _681;
    wire _682;
    wire [6:0] _3483;
    wire _3484;
    wire _3482;
    wire _3485;
    wire [15:0] _3486;
    wire [15:0] _79;
    reg [15:0] cfg_pin_modes;
    wire [1:0] _672;
    reg _685;
    wire _670;
    wire _671;
    wire _689;
    wire [6:0] _3488;
    wire _3489;
    wire _3487;
    wire _3490;
    wire [15:0] _3491;
    wire [15:0] _80;
    reg [15:0] cfg_smp_pre;
    wire [2:0] _664;
    wire [2:0] _663;
    wire [2:0] _665;
    wire _667;
    wire [8:0] _569;
    wire [8:0] _3496;
    wire [6:0] _3493;
    wire _3494;
    wire _3492;
    wire _3495;
    wire [8:0] _3497;
    wire [8:0] _81;
    reg [8:0] cfg_smp_ctrl;
    wire _662;
    wire _668;
    wire _693;
    wire [7:0] _792;
    wire _1047;
    wire [2:0] _3502;
    wire [6:0] _3499;
    wire _3500;
    wire _3498;
    wire _3501;
    wire [2:0] _3503;
    wire [2:0] _82;
    reg [2:0] cfg_t0_in_base;
    wire [2:0] _1046;
    reg _1055;
    wire _1058;
    wire [7:0] _1155;
    wire [15:0] _1156;
    wire [1:0] _1043;
    reg [15:0] _1164;
    wire [31:0] _3522;
    wire _3521;
    wire [31:0] _3526;
    wire _3520;
    wire [31:0] _3530;
    wire _3519;
    wire [31:0] _3534;
    wire _3518;
    wire [31:0] _3538;
    wire _3517;
    wire [31:0] _3542;
    wire [15:0] _3543;
    wire [15:0] _3574;
    wire [15:0] _3576;
    wire [15:0] _3515;
    wire _3510;
    wire [15:0] _3511;
    wire [15:0] _3512;
    wire _3508;
    wire [15:0] _3513;
    wire _3507;
    wire [15:0] _3516;
    wire _3505;
    wire [15:0] _3577;
    wire [15:0] _3578;
    wire [15:0] _3579;
    wire [15:0] _3580;
    wire [15:0] _3582;
    wire [15:0] _83;
    wire [15:0] _84;
    reg [15:0] t0_isr;
    wire [31:0] _3620;
    wire _3618;
    wire [31:0] _3624;
    wire _3617;
    wire [31:0] _3628;
    wire _3616;
    wire [31:0] _3632;
    wire _3615;
    wire [31:0] _3636;
    wire [4:0] _3599;
    wire [5:0] _3596;
    wire [5:0] _3595;
    wire [5:0] _3597;
    wire _3598;
    wire [4:0] _3601;
    wire [5:0] _860;
    wire [5:0] _858;
    wire [5:0] _851;
    wire [5:0] _859;
    wire _861;
    wire _862;
    wire _846;
    wire _845;
    wire _847;
    wire _863;
    wire [4:0] _3603;
    wire [4:0] _3592;
    wire _3586;
    wire [4:0] _3588;
    wire [4:0] _3589;
    wire _3585;
    wire [4:0] _3590;
    wire _3584;
    wire [4:0] _3593;
    wire _3583;
    wire [4:0] _3604;
    wire [4:0] _3605;
    wire [4:0] _3606;
    wire [4:0] _3607;
    wire [4:0] _3609;
    wire [4:0] _85;
    wire [4:0] _86;
    reg [4:0] t0_isr_count;
    wire [4:0] _3613;
    wire _3614;
    wire [31:0] _3640;
    wire [15:0] _3641;
    wire _980;
    wire [15:0] _3669;
    wire _3611;
    wire [15:0] _3728;
    wire [15:0] _87;
    reg [15:0] t0_rx_mem_0;
    wire [1:0] _3758;
    wire _3755;
    wire _3750;
    wire _3751;
    wire _3746;
    wire _3742;
    wire _3740;
    wire _3743;
    wire _3744;
    wire _3736;
    wire _3737;
    wire [6:0] _3732;
    wire [6:0] _326;
    wire _3733;
    wire _3729;
    wire _3730;
    wire _1274;
    wire _1275;
    wire _3731;
    wire _3734;
    wire _3738;
    wire _88;
    wire _3745;
    wire _3747;
    wire _3748;
    wire _3752;
    wire _3756;
    wire [1:0] _3759;
    wire [1:0] _89;
    reg [1:0] t0_rx_rd;
    reg [15:0] _404;
    wire [15:0] _3773;
    wire [15:0] _3774;
    wire [9:0] _3772;
    wire _3771;
    wire _3767;
    wire _3765;
    wire _3768;
    wire _3762;
    wire _3760;
    wire _3763;
    wire _3769;
    wire _3770;
    wire _90;
    wire [15:0] _3780;
    wire [15:0] _91;
    wire [15:0] _92;
    wire _1737;
    wire _1738;
    wire [15:0] _3844;
    wire [15:0] _3845;
    reg [15:0] t1_tx_mem_0;
    wire [1:0] _3814;
    wire _3808;
    wire _3785;
    wire _3782;
    wire _3783;
    wire _3784;
    wire _3786;
    wire _3804;
    wire _3807;
    wire _93;
    wire _3809;
    wire [1:0] _3815;
    wire [1:0] _94;
    reg [1:0] t1_tx_rd;
    reg [15:0] _3870;
    wire _1349;
    wire _3802;
    wire [4:0] _462;
    wire [4:0] _3820;
    wire [6:0] _3817;
    wire _3818;
    wire _3816;
    wire _3819;
    wire [4:0] _3821;
    wire [4:0] _95;
    reg [4:0] cfg_t1_threshold;
    wire [4:0] _3796;
    wire [4:0] _1380;
    wire [3:0] _1377;
    wire _1379;
    wire [4:0] _1382;
    wire [5:0] _3793;
    wire [5:0] _3792;
    wire [5:0] _3794;
    wire _3795;
    wire [4:0] _3798;
    wire _3799;
    wire _3800;
    wire _3788;
    wire _3789;
    wire _3790;
    wire _3801;
    wire _3803;
    wire [4:0] _3838;
    wire _1346;
    wire [4:0] _3835;
    wire _3829;
    wire [4:0] _3831;
    wire [4:0] _3832;
    wire _3827;
    wire [4:0] _3833;
    wire _3826;
    wire [4:0] _3836;
    wire _3825;
    wire [4:0] _3839;
    wire [4:0] _3823;
    wire [4:0] _3840;
    wire [4:0] _3841;
    wire [4:0] _3842;
    wire [4:0] _3843;
    wire [4:0] _96;
    wire [4:0] _97;
    reg [4:0] t1_osr_count;
    wire _1365;
    wire _1366;
    wire _1360;
    wire _1359;
    wire _1361;
    wire _1367;
    wire _3805;
    wire _3806;
    wire [15:0] _3871;
    wire [15:0] _3940;
    wire [15:0] _3941;
    wire [15:0] _3942;
    wire [15:0] _3944;
    wire [15:0] _98;
    wire [15:0] _99;
    reg [15:0] t1_osr;
    wire [15:0] _1536;
    wire [5:0] _3949;
    wire [6:0] _3946;
    wire _3947;
    wire _3945;
    wire _3948;
    wire [5:0] _3950;
    wire [5:0] _100;
    reg [5:0] cfg_t1_shift;
    wire _1504;
    wire [15:0] _1567;
    wire [1:0] _3965;
    wire _3967;
    wire [15:0] _3968;
    wire _3961;
    wire [15:0] _3962;
    wire [15:0] _3963;
    wire _3957;
    wire [15:0] _3958;
    wire _3955;
    wire [15:0] _3959;
    wire _3954;
    wire [15:0] _3964;
    wire _3953;
    wire [15:0] _3969;
    wire _3952;
    wire [15:0] _3976;
    wire [15:0] _3977;
    wire [15:0] _3978;
    wire [15:0] _3979;
    wire [15:0] _3981;
    wire [15:0] _101;
    wire [15:0] _102;
    reg [15:0] t1_y;
    reg [15:0] _1795;
    wire _3991;
    wire [15:0] _3992;
    wire [2:0] _1470;
    wire _1472;
    wire [2:0] _1467;
    wire _1469;
    wire _1473;
    wire [15:0] _3993;
    wire [4:0] _2950;
    wire [15:0] _2951;
    wire [1:0] _1398;
    wire _3987;
    wire [15:0] _3988;
    wire _3985;
    wire [15:0] _3989;
    wire _3984;
    wire [15:0] _3994;
    wire _3983;
    wire [15:0] _3998;
    wire _3982;
    wire [15:0] _4004;
    wire [15:0] _4005;
    wire [15:0] _4006;
    wire [15:0] _4007;
    wire [15:0] _4009;
    wire [15:0] _103;
    wire [15:0] _104;
    reg [15:0] t1_x;
    wire _4013;
    wire _4014;
    wire _4015;
    wire [2:0] _3970;
    reg _4024;
    wire _4011;
    wire _4025;
    wire _4031;
    wire [7:0] _4039;
    reg [7:0] t1_pc;
    wire [7:0] _4040;
    wire [7:0] _4041;
    wire [7:0] _4042;
    wire [7:0] _4043;
    wire [7:0] _105;
    wire [7:0] _106;
    wire [7:0] _4048;
    wire _4044;
    wire [15:0] _4054;
    wire [15:0] _107;
    wire [2:0] _1314;
    wire _1316;
    wire _1330;
    wire _1343;
    wire _1351;
    wire _1357;
    wire _1368;
    wire _1390;
    wire _1391;
    wire _1392;
    wire [3:0] _4065;
    wire _1308;
    wire _1309;
    wire [3:0] _4068;
    wire _1303;
    wire [3:0] _4069;
    wire _1297;
    wire [3:0] _4071;
    wire [3:0] _108;
    wire [3:0] _109;
    reg [3:0] t1_delay_left;
    wire _1312;
    wire [15:0] _4083;
    wire [6:0] _4073;
    wire _4074;
    wire _4072;
    wire _4075;
    wire [15:0] _4076;
    wire [15:0] _110;
    reg [15:0] cfg_t1_clkdiv;
    wire _4081;
    wire [15:0] _4085;
    wire [15:0] _4079;
    wire [15:0] _4086;
    wire _4077;
    wire [15:0] _4088;
    wire [15:0] _111;
    reg [15:0] t1_div_count;
    wire _1302;
    wire _1290;
    wire _1289;
    wire _1291;
    reg t1_loaded;
    wire _1295;
    wire _1288;
    wire _1296;
    wire _1310;
    wire _1313;
    wire _4091;
    wire _4093;
    wire _4095;
    wire _4097;
    wire _112;
    wire _485;
    wire [2:0] _4099;
    wire [2:0] _4100;
    wire [2:0] _4103;
    wire [2:0] _113;
    reg [2:0] t1_rx_level;
    wire _2036;
    wire _4119;
    wire _4120;
    wire _1211;
    wire _4115;
    wire _4116;
    wire _4117;
    wire [9:0] _4108;
    wire [6:0] _4105;
    wire _4106;
    wire _4104;
    wire _4107;
    wire [9:0] _4109;
    wire [9:0] _114;
    reg [9:0] cfg_buf_end;
    wire _4112;
    wire _4113;
    wire _4111;
    wire _4114;
    wire _4118;
    wire _4121;
    wire _115;
    wire _4126;
    wire _4127;
    wire _4129;
    wire [9:0] _4132;
    wire [6:0] _4123;
    wire _4124;
    wire _4122;
    wire _4125;
    wire [9:0] _4134;
    wire [9:0] _116;
    reg [9:0] buf_ptr;
    wire _4143;
    wire _4144;
    wire [2:0] _4139;
    wire [6:0] _4136;
    wire _4137;
    wire _4135;
    wire _4138;
    wire [2:0] _4140;
    wire [2:0] _117;
    reg [2:0] cfg_buf_ctrl;
    wire [1:0] _1219;
    wire _4142;
    wire _4145;
    wire _4150;
    wire _4153;
    wire _4156;
    wire _118;
    wire _1214;
    wire _1227;
    wire _1231;
    wire [2:0] _4158;
    wire [2:0] _4159;
    wire [2:0] _4162;
    wire [2:0] _119;
    reg [2:0] t0_tx_level;
    wire _824;
    wire _1267;
    wire [4:0] _4167;
    wire [6:0] _4164;
    wire _4165;
    wire _4163;
    wire _4166;
    wire [4:0] _4168;
    wire [4:0] _120;
    reg [4:0] cfg_t0_threshold;
    wire [4:0] _1261;
    wire [4:0] _855;
    wire [3:0] _852;
    wire _854;
    wire [4:0] _857;
    wire [5:0] _1258;
    wire [5:0] _1257;
    wire [5:0] _1259;
    wire _1260;
    wire [4:0] _1263;
    wire _1264;
    wire _1265;
    wire _1253;
    wire _1254;
    wire _1255;
    wire _1266;
    wire _1268;
    wire [4:0] _4185;
    wire _821;
    wire [4:0] _4182;
    wire _4176;
    wire [4:0] _4178;
    wire [4:0] _4179;
    wire _4174;
    wire [4:0] _4180;
    wire _4173;
    wire [4:0] _4183;
    wire _4172;
    wire [4:0] _4186;
    wire [4:0] _4170;
    wire [4:0] _4187;
    wire [4:0] _4188;
    wire [4:0] _4189;
    wire [4:0] _4190;
    wire [4:0] _121;
    wire [4:0] _122;
    reg [4:0] t0_osr_count;
    wire _840;
    wire _841;
    wire _835;
    wire _834;
    wire _836;
    wire _842;
    wire _1270;
    wire _1271;
    wire [15:0] _4217;
    wire [15:0] _4286;
    wire [15:0] _4287;
    wire [15:0] _4288;
    wire [15:0] _4290;
    wire [15:0] _123;
    wire [15:0] _124;
    reg [15:0] t0_osr;
    wire [15:0] _1011;
    wire [5:0] _4295;
    wire [6:0] _4292;
    wire _4293;
    wire _4291;
    wire _4294;
    wire [5:0] _4296;
    wire [5:0] _125;
    reg [5:0] cfg_t0_shift;
    wire _979;
    wire [15:0] _1042;
    wire [1:0] _4311;
    wire _4313;
    wire [15:0] _4314;
    wire _4307;
    wire [15:0] _4308;
    wire [15:0] _4309;
    wire _4303;
    wire [15:0] _4304;
    wire _4301;
    wire [15:0] _4305;
    wire _4300;
    wire [15:0] _4310;
    wire _4299;
    wire [15:0] _4315;
    wire _4298;
    wire [15:0] _4322;
    wire [15:0] _4323;
    wire [15:0] _4324;
    wire [15:0] _4325;
    wire [15:0] _4327;
    wire [15:0] _126;
    wire [15:0] _127;
    reg [15:0] t0_y;
    reg [15:0] _2507;
    wire _4337;
    wire [15:0] _4338;
    wire [2:0] _945;
    wire _947;
    wire [2:0] _942;
    wire _944;
    wire _948;
    wire [15:0] _4339;
    wire [4:0] _2367;
    wire [15:0] _2368;
    wire [1:0] _873;
    wire _4333;
    wire [15:0] _4334;
    wire _4331;
    wire [15:0] _4335;
    wire _4330;
    wire [15:0] _4340;
    wire _4329;
    wire [15:0] _4344;
    wire _4328;
    wire [15:0] _4350;
    wire [15:0] _4351;
    wire [15:0] _4352;
    wire [15:0] _4353;
    wire [15:0] _4355;
    wire [15:0] _128;
    wire [15:0] _129;
    reg [15:0] t0_x;
    wire _4359;
    wire _4360;
    wire _4361;
    wire [2:0] _4316;
    reg _4370;
    wire _4357;
    wire _4371;
    wire _4377;
    wire [7:0] _4385;
    reg [7:0] t0_pc;
    wire [7:0] _4386;
    wire [7:0] _4387;
    wire [7:0] _4388;
    wire [7:0] _4389;
    wire [7:0] _130;
    wire [7:0] _131;
    wire [7:0] _4391;
    wire _4390;
    wire [15:0] _4397;
    wire [15:0] _132;
    wire [2:0] _658;
    wire _660;
    wire _805;
    wire _818;
    wire _826;
    wire _832;
    wire _843;
    wire _865;
    wire _866;
    wire _867;
    wire [3:0] _4408;
    wire _652;
    wire _653;
    wire [3:0] _4411;
    wire _647;
    wire [3:0] _4412;
    wire _641;
    wire [3:0] _4414;
    wire [3:0] _133;
    wire [3:0] _134;
    reg [3:0] t0_delay_left;
    wire _656;
    wire [15:0] _4426;
    wire [6:0] _4416;
    wire _4417;
    wire _4415;
    wire _4418;
    wire [15:0] _4419;
    wire [15:0] _135;
    reg [15:0] cfg_t0_clkdiv;
    wire _4424;
    wire [15:0] _4428;
    wire [15:0] _4422;
    wire [15:0] _4429;
    wire _4420;
    wire [15:0] _4431;
    wire [15:0] _136;
    reg [15:0] t0_div_count;
    wire _646;
    wire _634;
    wire [5:0] _437;
    wire [5:0] _4436;
    wire [6:0] _4433;
    wire _4434;
    wire _4432;
    wire _4435;
    wire [5:0] _4437;
    wire [5:0] _137;
    reg [5:0] cfg_load;
    wire [1:0] _631;
    wire [6:0] _627;
    wire _628;
    wire _626;
    wire _629;
    wire [1:0] _630;
    wire [1:0] _632;
    wire _633;
    wire _635;
    reg t0_loaded;
    wire _639;
    wire _625;
    wire _640;
    wire _654;
    wire _657;
    wire _4440;
    wire _4442;
    wire _4444;
    wire _4446;
    wire _138;
    wire _378;
    wire [2:0] _4448;
    wire [2:0] _4449;
    wire [2:0] _4452;
    wire [2:0] _139;
    reg [2:0] t0_rx_level;
    wire _3754;
    wire _4473;
    wire [15:0] _622;
    wire [2:0] _4471;
    wire [6:0] _618;
    wire _4469;
    wire _319;
    reg host_mosi_s1;
    reg host_mosi_s2;
    wire [22:0] _317;
    wire [22:0] _4453;
    wire [22:0] _4454;
    wire [22:0] _4455;
    wire [22:0] _140;
    reg [22:0] host_shift_in;
    wire [23:0] _324;
    wire [7:0] _325;
    wire _315;
    wire [7:0] _4456;
    wire [7:0] _4457;
    wire [7:0] _4458;
    wire [7:0] _141;
    reg [7:0] host_cmd;
    wire _616;
    wire [4:0] _610;
    wire [4:0] _4462;
    wire [4:0] _4459;
    wire _4460;
    wire [4:0] _4463;
    wire [4:0] _4464;
    wire [4:0] _4466;
    wire [4:0] _142;
    reg [4:0] host_bit_count;
    wire _611;
    wire _282;
    reg host_cs_n_s1;
    reg host_cs_n_s2;
    wire _309;
    reg host_sck_prev;
    wire _307;
    wire vdd;
    wire _144;
    wire _146;
    wire [7:0] _148;
    wire _287;
    reg host_sck_s1;
    reg host_sck_s2;
    wire _308;
    wire _310;
    wire _612;
    wire _4467;
    wire _4470;
    wire [2:0] _4472;
    wire [2:0] _149;
    reg [2:0] cfg_ctrl;
    wire _1751;
    wire _4474;
    wire _4476;
    wire _150;
    wire _1739;
    wire _1754;
    wire _1758;
    wire [2:0] _4478;
    wire [2:0] _4479;
    wire [2:0] _4482;
    wire [2:0] _151;
    reg [2:0] t1_tx_level;
    wire _4484;
    wire gnd;
    wire [7:0] _4496;
    assign _236 = pin_out[0:0];
    assign _237 = ~ _236;
    assign _234 = 2'b10;
    assign _233 = cfg_pin_modes[1:0];
    assign _235 = _233 == _234;
    assign _238 = _235 & _237;
    assign _231 = 2'b01;
    assign _230 = cfg_pin_modes[1:0];
    assign _232 = _230 == _231;
    assign _239 = _232 | _238;
    assign _226 = pin_out[1:1];
    assign _227 = ~ _226;
    assign _223 = cfg_pin_modes[3:2];
    assign _225 = _223 == _234;
    assign _228 = _225 & _227;
    assign _220 = cfg_pin_modes[3:2];
    assign _222 = _220 == _231;
    assign _229 = _222 | _228;
    assign _216 = pin_out[2:2];
    assign _217 = ~ _216;
    assign _213 = cfg_pin_modes[5:4];
    assign _215 = _213 == _234;
    assign _218 = _215 & _217;
    assign _210 = cfg_pin_modes[5:4];
    assign _212 = _210 == _231;
    assign _219 = _212 | _218;
    assign _206 = pin_out[3:3];
    assign _207 = ~ _206;
    assign _203 = cfg_pin_modes[7:6];
    assign _205 = _203 == _234;
    assign _208 = _205 & _207;
    assign _200 = cfg_pin_modes[7:6];
    assign _202 = _200 == _231;
    assign _209 = _202 | _208;
    assign _196 = pin_out[4:4];
    assign _197 = ~ _196;
    assign _193 = cfg_pin_modes[9:8];
    assign _195 = _193 == _234;
    assign _198 = _195 & _197;
    assign _190 = cfg_pin_modes[9:8];
    assign _192 = _190 == _231;
    assign _199 = _192 | _198;
    assign _186 = pin_out[5:5];
    assign _187 = ~ _186;
    assign _183 = cfg_pin_modes[11:10];
    assign _185 = _183 == _234;
    assign _188 = _185 & _187;
    assign _180 = cfg_pin_modes[11:10];
    assign _182 = _180 == _231;
    assign _189 = _182 | _188;
    assign _176 = pin_out[6:6];
    assign _177 = ~ _176;
    assign _173 = cfg_pin_modes[13:12];
    assign _175 = _173 == _234;
    assign _178 = _175 & _177;
    assign _170 = cfg_pin_modes[13:12];
    assign _172 = _170 == _231;
    assign _179 = _172 | _178;
    assign _166 = pin_out[7:7];
    assign _167 = ~ _166;
    assign _160 = cfg_pin_modes[15:14];
    assign _162 = _160 == _234;
    assign _168 = _162 & _167;
    assign _157 = cfg_pin_modes[15:14];
    assign _159 = _157 == _231;
    assign _169 = _159 | _168;
    assign _240 = { _169,
                    _179,
                    _189,
                    _199,
                    _209,
                    _219,
                    _229,
                    _239 };
    assign _279 = pin_out[0:0];
    assign _276 = cfg_pin_modes[1:0];
    assign _278 = _276 == _231;
    assign _280 = _278 & _279;
    assign _274 = pin_out[1:1];
    assign _271 = cfg_pin_modes[3:2];
    assign _273 = _271 == _231;
    assign _275 = _273 & _274;
    assign _269 = pin_out[2:2];
    assign _266 = cfg_pin_modes[5:4];
    assign _268 = _266 == _231;
    assign _270 = _268 & _269;
    assign _264 = pin_out[3:3];
    assign _261 = cfg_pin_modes[7:6];
    assign _263 = _261 == _231;
    assign _265 = _263 & _264;
    assign _259 = pin_out[4:4];
    assign _256 = cfg_pin_modes[9:8];
    assign _258 = _256 == _231;
    assign _260 = _258 & _259;
    assign _254 = pin_out[5:5];
    assign _251 = cfg_pin_modes[11:10];
    assign _253 = _251 == _231;
    assign _255 = _253 & _254;
    assign _249 = pin_out[6:6];
    assign _246 = cfg_pin_modes[13:12];
    assign _248 = _246 == _231;
    assign _250 = _248 & _249;
    assign _244 = pin_out[7:7];
    assign _241 = cfg_pin_modes[15:14];
    assign _243 = _241 == _231;
    assign _245 = _243 & _244;
    assign _281 = { _245,
                    _250,
                    _255,
                    _260,
                    _265,
                    _270,
                    _275,
                    _280 };
    assign _312 = 16'b0000000000000000;
    assign _606 = 1'b0;
    assign _605 = host_miso_shift[14:0];
    assign _607 = { _605,
                    _606 };
    assign _588 = { smp_synced,
                    smp_carrier };
    assign _581 = 14'b00000000000000;
    assign _589 = { _581,
                    _588 };
    assign _576 = 8'b00000000;
    assign _580 = { _576,
                    cfg_smp_sync };
    assign _575 = { gnd,
                    cfg_smp_time };
    assign _567 = 7'b0000000;
    assign _571 = { _567,
                    cfg_smp_ctrl };
    assign _562 = 6'b000000;
    assign _566 = { _562,
                    cfg_buf_end };
    assign _561 = { _562,
                    buf_ptr };
    assign _552 = 13'b0000000000000;
    assign _556 = { _552,
                    cfg_buf_ctrl };
    assign _532 = 10'b0000000000;
    assign _536 = { _532,
                    cfg_t1_shift };
    assign _528 = { _532,
                    cfg_t1_sideset };
    assign _516 = cfg_ctrl[1:1];
    assign _520 = { t1_pc,
                    _516,
                    t1_rx_level,
                    gnd,
                    t1_tx_level };
    assign _473 = 3'b000;
    assign _474 = t1_rx_level == _473;
    assign _475 = ~ _474;
    assign _512 = _475 ? _511 : _312;
    assign _469 = { _576,
                    cfg_t1_timeout_vector };
    assign _460 = 11'b00000000000;
    assign _464 = { _460,
                    cfg_t1_threshold };
    assign _459 = { _552,
                    cfg_t1_in_base };
    assign _454 = { _576,
                    cfg_t1_set_cfg };
    assign _449 = { _576,
                    cfg_t1_out_cfg };
    assign _444 = { _576,
                    cfg_t1_start };
    assign _439 = { _532,
                    cfg_load };
    assign _434 = { _532,
                    cfg_t0_shift };
    assign _429 = { _576,
                    cfg_sync_bypass };
    assign _421 = { _532,
                    cfg_t0_sideset };
    assign _409 = cfg_ctrl[0:0];
    assign _413 = { t0_pc,
                    _409,
                    t0_rx_level,
                    gnd,
                    t0_tx_level };
    assign _367 = t0_rx_level == _473;
    assign _368 = ~ _367;
    assign _405 = _368 ? _404 : _312;
    assign _362 = { _576,
                    cfg_t0_timeout_vector };
    assign _357 = { _460,
                    cfg_t0_threshold };
    assign _352 = { _552,
                    cfg_t0_in_base };
    assign _347 = { _576,
                    cfg_t0_set_cfg };
    assign _342 = { _576,
                    cfg_t0_out_cfg };
    assign _337 = { _576,
                    cfg_t0_start };
    assign _332 = { _552,
                    cfg_ctrl };
    always @* begin
        case (_326)
        0:
            _602 <= _312;
        1:
            _602 <= _312;
        2:
            _602 <= _312;
        3:
            _602 <= _312;
        4:
            _602 <= _312;
        5:
            _602 <= _312;
        6:
            _602 <= _312;
        7:
            _602 <= _312;
        8:
            _602 <= _312;
        9:
            _602 <= _312;
        10:
            _602 <= _312;
        11:
            _602 <= _312;
        12:
            _602 <= _312;
        13:
            _602 <= _312;
        14:
            _602 <= _312;
        15:
            _602 <= _312;
        16:
            _602 <= _312;
        17:
            _602 <= _312;
        18:
            _602 <= _312;
        19:
            _602 <= _312;
        20:
            _602 <= _312;
        21:
            _602 <= _312;
        22:
            _602 <= _312;
        23:
            _602 <= _312;
        24:
            _602 <= _312;
        25:
            _602 <= _312;
        26:
            _602 <= _312;
        27:
            _602 <= _312;
        28:
            _602 <= _312;
        29:
            _602 <= _312;
        30:
            _602 <= _312;
        31:
            _602 <= _312;
        32:
            _602 <= _312;
        33:
            _602 <= _312;
        34:
            _602 <= _312;
        35:
            _602 <= _312;
        36:
            _602 <= _312;
        37:
            _602 <= _312;
        38:
            _602 <= _312;
        39:
            _602 <= _312;
        40:
            _602 <= _312;
        41:
            _602 <= _312;
        42:
            _602 <= _312;
        43:
            _602 <= _312;
        44:
            _602 <= _312;
        45:
            _602 <= _312;
        46:
            _602 <= _312;
        47:
            _602 <= _312;
        48:
            _602 <= _312;
        49:
            _602 <= _312;
        50:
            _602 <= _312;
        51:
            _602 <= _312;
        52:
            _602 <= _312;
        53:
            _602 <= _312;
        54:
            _602 <= _312;
        55:
            _602 <= _312;
        56:
            _602 <= _312;
        57:
            _602 <= _312;
        58:
            _602 <= _312;
        59:
            _602 <= _312;
        60:
            _602 <= _312;
        61:
            _602 <= _312;
        62:
            _602 <= _312;
        63:
            _602 <= _312;
        64:
            _602 <= _332;
        65:
            _602 <= _337;
        66:
            _602 <= _342;
        67:
            _602 <= _347;
        68:
            _602 <= _352;
        69:
            _602 <= _357;
        70:
            _602 <= _362;
        71:
            _602 <= cfg_pin_modes;
        72:
            _602 <= _312;
        73:
            _602 <= _405;
        74:
            _602 <= _413;
        75:
            _602 <= cfg_t0_timeout;
        76:
            _602 <= _421;
        77:
            _602 <= cfg_t0_clkdiv;
        78:
            _602 <= _429;
        79:
            _602 <= _434;
        80:
            _602 <= _439;
        81:
            _602 <= _444;
        82:
            _602 <= _449;
        83:
            _602 <= _454;
        84:
            _602 <= _459;
        85:
            _602 <= _464;
        86:
            _602 <= _469;
        87:
            _602 <= _312;
        88:
            _602 <= _312;
        89:
            _602 <= _512;
        90:
            _602 <= _520;
        91:
            _602 <= cfg_t1_timeout;
        92:
            _602 <= _528;
        93:
            _602 <= cfg_t1_clkdiv;
        94:
            _602 <= _312;
        95:
            _602 <= _536;
        96:
            _602 <= _312;
        97:
            _602 <= cfg_t0_crc_poly_lo;
        98:
            _602 <= cfg_t0_crc_poly_hi;
        99:
            _602 <= cfg_t0_crc_init_lo;
        100:
            _602 <= cfg_t0_crc_init_hi;
        101:
            _602 <= _312;
        102:
            _602 <= _312;
        103:
            _602 <= cfg_smp_pre;
        104:
            _602 <= _556;
        105:
            _602 <= _561;
        106:
            _602 <= _566;
        107:
            _602 <= _92;
        108:
            _602 <= _571;
        109:
            _602 <= _575;
        110:
            _602 <= _580;
        111:
            _602 <= _589;
        112:
            _602 <= _312;
        113:
            _602 <= cfg_t1_crc_poly_lo;
        114:
            _602 <= cfg_t1_crc_poly_hi;
        115:
            _602 <= cfg_t1_crc_init_lo;
        116:
            _602 <= cfg_t1_crc_init_hi;
        default:
            _602 <= _312;
        endcase
    end
    assign _603 = _315 ? _602 : host_miso_shift;
    assign _604 = _310 ? _603 : host_miso_shift;
    assign _303 = 5'b01001;
    assign _304 = host_bit_count < _303;
    assign _305 = ~ _304;
    assign _298 = ~ host_cs_n_s2;
    assign _293 = ~ host_sck_s2;
    assign _297 = _293 & host_sck_prev;
    assign _299 = _297 & _298;
    assign _306 = _299 & _305;
    assign _608 = _306 ? _607 : _604;
    assign _609 = host_cs_n_s2 ? host_miso_shift : _608;
    assign _3 = _609;
    always @(posedge _146) begin
        if (_144)
            host_miso_shift <= _312;
        else
            host_miso_shift <= _3;
    end
    assign _4495 = host_miso_shift[15:15];
    assign _4494 = cfg_ctrl[0:0];
    assign _4492 = t0_rx_level == _473;
    assign _4493 = ~ _4492;
    assign _4489 = 3'b100;
    assign _4490 = t0_tx_level == _4489;
    assign _4488 = cfg_ctrl[1:1];
    assign _4486 = t1_rx_level == _473;
    assign _4487 = ~ _4486;
    assign _4480 = 2'b00;
    assign _4481 = { _4480,
                     _3809 };
    assign _1757 = ~ _1756;
    assign _1752 = ~ _1751;
    assign _1746 = 1'b1;
    assign _1747 = _1211 == _1746;
    assign _1745 = _1219 == _231;
    assign _1748 = _1745 & _1747;
    assign _1749 = ~ _1748;
    assign _1741 = 7'b1011000;
    assign _1742 = _618 == _1741;
    assign _1740 = _612 & _616;
    assign _1743 = _1740 & _1742;
    assign _1750 = _1743 & _1749;
    assign _1753 = _1750 & _1752;
    assign _4475 = ~ _1756;
    assign _4451 = { _4480,
                     _3756 };
    assign _377 = ~ _376;
    assign _4445 = _867 & _863;
    assign _4443 = ~ _376;
    assign _4441 = ~ _821;
    assign _4439 = _658 == _4489;
    assign _655 = 4'b0000;
    assign _4409 = 4'b0001;
    assign _4410 = t0_delay_left - _4409;
    assign _4404 = _4402[3:2];
    assign _4405 = { _4480,
                     _4404 };
    assign _4401 = 4'b0111;
    assign _4400 = 4'b1111;
    assign _4399 = _2336[0:0];
    assign _4402 = _4399 ? _4401 : _4400;
    assign _4398 = _2336[1:1];
    assign _4406 = _4398 ? _4405 : _4402;
    assign _4407 = _2763 & _4406;
    assign _864 = _863 & _376;
    assign _376 = t0_rx_level == _4489;
    assign _829 = ~ _821;
    assign _828 = _658 == _4489;
    assign _830 = _828 & _829;
    assign _831 = _830 & _376;
    assign _820 = _658 == _4489;
    assign _822 = _820 & _821;
    assign _825 = _822 & _824;
    assign _817 = ~ _816;
    assign _804 = ~ _803;
    assign _659 = 3'b001;
    assign _4392 = 16'b1111111111111111;
    assign _4382 = _132[5:0];
    assign _623 = _622[7:0];
    assign _619 = 7'b1000001;
    assign _620 = _618 == _619;
    assign _617 = _612 & _616;
    assign _621 = _617 & _620;
    assign _624 = _621 ? _623 : cfg_t0_start;
    assign _4 = _624;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_start <= _576;
        else
            cfg_t0_start <= _4;
    end
    assign _882 = cfg_t0_start[7:6];
    assign _876 = _132[1:0];
    assign _874 = 2'b11;
    assign _875 = _873 == _874;
    assign _877 = _875 ? _876 : t0_page;
    assign _872 = _658 == _951;
    assign _878 = _872 ? _877 : t0_page;
    assign _879 = _867 ? _878 : t0_page;
    assign _880 = _653 ? t0_page : _879;
    assign _881 = _647 ? t0_page : _880;
    assign _883 = _641 ? _882 : _881;
    assign _5 = _883;
    assign _6 = _5;
    always @(posedge _146) begin
        if (_144)
            t0_page <= _4480;
        else
            t0_page <= _6;
    end
    assign _4383 = { t0_page,
                     _4382 };
    assign _888 = _622[7:0];
    assign _885 = 7'b1000110;
    assign _886 = _618 == _885;
    assign _884 = _612 & _616;
    assign _887 = _884 & _886;
    assign _889 = _887 ? _888 : cfg_t0_timeout_vector;
    assign _7 = _889;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_timeout_vector <= _576;
        else
            cfg_t0_timeout_vector <= _7;
    end
    assign _4381 = _658 == _473;
    assign _4384 = _4381 ? _4383 : cfg_t0_timeout_vector;
    assign _4378 = 8'b00000001;
    assign _4379 = t0_pc + _4378;
    assign _897 = 16'b0000000000000001;
    assign _898 = _813 - _897;
    assign _899 = _896 ? _898 : t0_wait_count;
    assign _900 = _653 ? t0_wait_count : _899;
    assign _901 = _647 ? t0_wait_count : _900;
    assign _903 = _641 ? _312 : _901;
    assign _8 = _903;
    assign _9 = _8;
    always @(posedge _146) begin
        if (_144)
            t0_wait_count <= _312;
        else
            t0_wait_count <= _9;
    end
    assign _905 = 7'b1001011;
    assign _906 = _618 == _905;
    assign _904 = _612 & _616;
    assign _907 = _904 & _906;
    assign _908 = _907 ? _622 : cfg_t0_timeout;
    assign _10 = _908;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_timeout <= _312;
        else
            cfg_t0_timeout <= _10;
    end
    assign _895 = ~ _815;
    assign _892 = ~ _803;
    assign _891 = _658 == _659;
    assign _893 = _891 & _892;
    assign _894 = _893 & _806;
    assign _896 = _894 & _895;
    assign _910 = _896 ? _1746 : t0_waiting;
    assign _912 = _867 ? _606 : _910;
    assign _913 = _653 ? t0_waiting : _912;
    assign _914 = _647 ? t0_waiting : _913;
    assign _916 = _641 ? _606 : _914;
    assign _11 = _916;
    assign _12 = _11;
    always @(posedge _146) begin
        if (_144)
            t0_waiting <= _606;
        else
            t0_waiting <= _12;
    end
    assign _813 = t0_waiting ? t0_wait_count : cfg_t0_timeout;
    assign _815 = _813 == _312;
    assign _806 = _132[4:4];
    assign _816 = _806 & _815;
    assign _802 = _132[8:8];
    assign _800 = _792[7:7];
    assign _799 = _792[6:6];
    assign _798 = _792[5:5];
    assign _797 = _792[4:4];
    assign _796 = _792[3:3];
    assign _795 = _792[2:2];
    assign _794 = _792[1:1];
    assign _793 = _792[0:0];
    assign _661 = _132[7:5];
    always @* begin
        case (_661)
        0:
            _801 <= _793;
        1:
            _801 <= _794;
        2:
            _801 <= _795;
        3:
            _801 <= _796;
        4:
            _801 <= _797;
        5:
            _801 <= _798;
        6:
            _801 <= _799;
        default:
            _801 <= _800;
        endcase
    end
    assign _803 = _801 == _802;
    assign _4374 = ~ _803;
    assign _4373 = _658 == _659;
    assign _4375 = _4373 & _4374;
    assign _4376 = _4375 & _816;
    assign _4369 = t0_isr_count < cfg_t0_threshold;
    assign _4368 = t0_osr_count < cfg_t0_threshold;
    assign _4366 = t0_x == t0_y;
    assign _4367 = ~ _4366;
    assign _4363 = t0_y == _312;
    assign _4364 = ~ _4363;
    assign _4365 = ~ _4364;
    assign _4348 = t0_x - _897;
    assign _4345 = 3'b010;
    assign _4346 = _4316 == _4345;
    assign _4349 = _4346 ? _4348 : t0_x;
    assign _4342 = _4311 == _231;
    assign _4343 = _4342 ? _1042 : t0_x;
    assign _2499 = cfg_t0_shift[4:4];
    assign _2500 = { _2499,
                     _2499 };
    assign _2501 = { _2500,
                     _2500 };
    assign _2502 = { _2501,
                     _2501 };
    assign _2503 = { _2502,
                     _2502 };
    assign _2504 = { _2503,
                     _2503 };
    assign _972 = 32'b00000000000000000000000000000000;
    assign _918 = 7'b1100011;
    assign _919 = _618 == _918;
    assign _917 = _612 & _616;
    assign _920 = _917 & _919;
    assign _921 = _920 ? _622 : cfg_t0_crc_init_lo;
    assign _13 = _921;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_crc_init_lo <= _312;
        else
            cfg_t0_crc_init_lo <= _13;
    end
    assign _923 = 7'b1100100;
    assign _924 = _618 == _923;
    assign _922 = _612 & _616;
    assign _925 = _922 & _924;
    assign _926 = _925 ? _622 : cfg_t0_crc_init_hi;
    assign _14 = _926;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_crc_init_hi <= _312;
        else
            cfg_t0_crc_init_hi <= _14;
    end
    assign _1203 = { cfg_t0_crc_init_hi,
                     cfg_t0_crc_init_lo };
    assign _1200 = t0_crc[31:16];
    assign _1201 = { _312,
                     _1200 };
    assign _1202 = _952 ? _1201 : _1197;
    assign _1204 = _950 ? _1203 : _1202;
    assign _1205 = _948 ? _1204 : _1197;
    assign _1198 = _658 == _1598;
    assign _1206 = _1198 ? _1205 : _1197;
    assign _1186 = _1166[15:15];
    assign _1185 = _1166[14:14];
    assign _1184 = _1166[13:13];
    assign _1183 = _1166[12:12];
    assign _1182 = _1166[11:11];
    assign _1181 = _1166[10:10];
    assign _1180 = _1166[9:9];
    assign _1179 = _1166[8:8];
    assign _1178 = _1166[7:7];
    assign _1177 = _1166[6:6];
    assign _1176 = _1166[5:5];
    assign _1175 = _1166[4:4];
    assign _1174 = _1166[3:3];
    assign _1173 = _1166[2:2];
    assign _1172 = _1166[1:1];
    assign _1171 = _1166[0:0];
    assign _1168 = 5'b00001;
    assign _1169 = _857 - _1168;
    assign _1170 = _1169[3:0];
    always @* begin
        case (_1170)
        0:
            _1187 <= _1171;
        1:
            _1187 <= _1172;
        2:
            _1187 <= _1173;
        3:
            _1187 <= _1174;
        4:
            _1187 <= _1175;
        5:
            _1187 <= _1176;
        6:
            _1187 <= _1177;
        7:
            _1187 <= _1178;
        8:
            _1187 <= _1179;
        9:
            _1187 <= _1180;
        10:
            _1187 <= _1181;
        11:
            _1187 <= _1182;
        12:
            _1187 <= _1183;
        13:
            _1187 <= _1184;
        14:
            _1187 <= _1185;
        default:
            _1187 <= _1186;
        endcase
    end
    assign _1165 = _1164 & _1010;
    assign _1166 = _964 ? _1165 : _1042;
    assign _1167 = _1166[0:0];
    assign _981 = _964 ? _980 : _979;
    assign _1188 = _981 ? _1187 : _1167;
    assign _978 = t0_crc[0:0];
    assign _1189 = _978 ^ _1188;
    assign _1190 = { _1189,
                     _1189 };
    assign _1191 = { _1190,
                     _1190 };
    assign _1192 = { _1191,
                     _1191 };
    assign _1193 = { _1192,
                     _1192 };
    assign _1194 = { _1193,
                     _1193 };
    assign _928 = 7'b1100001;
    assign _929 = _618 == _928;
    assign _927 = _612 & _616;
    assign _930 = _927 & _929;
    assign _931 = _930 ? _622 : cfg_t0_crc_poly_lo;
    assign _15 = _931;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_crc_poly_lo <= _312;
        else
            cfg_t0_crc_poly_lo <= _15;
    end
    assign _933 = 7'b1100010;
    assign _934 = _618 == _933;
    assign _932 = _612 & _616;
    assign _935 = _932 & _934;
    assign _936 = _935 ? _622 : cfg_t0_crc_poly_hi;
    assign _16 = _936;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_crc_poly_hi <= _312;
        else
            cfg_t0_crc_poly_hi <= _16;
    end
    assign _977 = { cfg_t0_crc_poly_hi,
                    cfg_t0_crc_poly_lo };
    assign _1195 = _977 & _1194;
    assign _975 = t0_crc[31:1];
    assign _976 = { _606,
                    _975 };
    assign _1196 = _976 ^ _1195;
    assign _968 = _658 == _4345;
    assign _965 = 3'b011;
    assign _966 = _658 == _965;
    assign _964 = cfg_t0_shift[5:5];
    assign _969 = _964 ? _968 : _966;
    assign _951 = 3'b110;
    assign _952 = _945 == _951;
    assign _953 = _952 ? gnd : t0_crc_run;
    assign _950 = _942 == _951;
    assign _955 = _950 ? _1746 : _953;
    assign _956 = _948 ? _955 : t0_crc_run;
    assign _941 = _658 == _1598;
    assign _957 = _941 ? _956 : t0_crc_run;
    assign _958 = _867 ? _957 : t0_crc_run;
    assign _959 = _653 ? t0_crc_run : _958;
    assign _960 = _647 ? t0_crc_run : _959;
    assign _962 = _641 ? _1746 : _960;
    assign _17 = _962;
    assign _18 = _17;
    always @(posedge _146) begin
        if (_144)
            t0_crc_run <= _606;
        else
            t0_crc_run <= _18;
    end
    assign _963 = _867 & t0_crc_run;
    assign _970 = _963 & _969;
    assign _1197 = _970 ? _1196 : t0_crc;
    assign _1207 = _867 ? _1206 : _1197;
    assign _1208 = _653 ? t0_crc : _1207;
    assign _1209 = _647 ? t0_crc : _1208;
    assign _1210 = _641 ? _1203 : _1209;
    assign _19 = _1210;
    assign _20 = _19;
    always @(posedge _146) begin
        if (_144)
            t0_crc <= _972;
        else
            t0_crc <= _20;
    end
    assign _2505 = t0_crc ^ _2504;
    assign _2506 = _2505[15:0];
    assign _2494 = { _576,
                     _792 };
    assign _4320 = t0_y - _897;
    assign _4318 = _4316 == _4489;
    assign _4321 = _4318 ? _4320 : t0_y;
    assign _1038 = _1036[31:16];
    assign _1039 = { _312,
                     _1038 };
    assign _1034 = _1032[31:8];
    assign _1035 = { _576,
                     _1034 };
    assign _1030 = _1028[31:4];
    assign _1031 = { _655,
                     _1030 };
    assign _1026 = _1024[31:2];
    assign _1027 = { _4480,
                     _1026 };
    assign _1022 = _1020[31:1];
    assign _1023 = { _606,
                     _1022 };
    assign _1020 = { _312,
                     t0_osr };
    assign _1018 = _1013[0:0];
    assign _1024 = _1018 ? _1023 : _1020;
    assign _1017 = _1013[1:1];
    assign _1028 = _1017 ? _1027 : _1024;
    assign _1016 = _1013[2:2];
    assign _1032 = _1016 ? _1031 : _1028;
    assign _1015 = _1013[3:3];
    assign _1036 = _1015 ? _1035 : _1032;
    assign _1012 = 5'b10000;
    assign _1013 = _1012 - _857;
    assign _1014 = _1013[4:4];
    assign _1040 = _1014 ? _1039 : _1036;
    assign _1041 = _1040[15:0];
    assign _4278 = _4277[15:0];
    assign _4280 = { _4278,
                     _312 };
    assign _4274 = _4273[23:0];
    assign _4276 = { _4274,
                     _576 };
    assign _4270 = _4269[27:0];
    assign _4272 = { _4270,
                     _655 };
    assign _4266 = _4265[29:0];
    assign _4268 = { _4266,
                     _4480 };
    assign _4262 = _4261[30:0];
    assign _4264 = { _4262,
                     _606 };
    assign _4261 = { _312,
                     t0_osr };
    assign _4259 = _857[0:0];
    assign _4265 = _4259 ? _4264 : _4261;
    assign _4258 = _857[1:1];
    assign _4269 = _4258 ? _4268 : _4265;
    assign _4257 = _857[2:2];
    assign _4273 = _4257 ? _4272 : _4269;
    assign _4256 = _857[3:3];
    assign _4277 = _4256 ? _4276 : _4273;
    assign _4255 = _857[4:4];
    assign _4281 = _4255 ? _4280 : _4277;
    assign _4282 = _4281[15:0];
    assign _4251 = _4249[31:16];
    assign _4252 = { _312,
                     _4251 };
    assign _4247 = _4245[31:8];
    assign _4248 = { _576,
                     _4247 };
    assign _4243 = _4241[31:4];
    assign _4244 = { _655,
                     _4243 };
    assign _4239 = _4237[31:2];
    assign _4240 = { _4480,
                     _4239 };
    assign _4235 = _4233[31:1];
    assign _4236 = { _606,
                     _4235 };
    assign _4233 = { _312,
                     t0_osr };
    assign _4231 = _857[0:0];
    assign _4237 = _4231 ? _4236 : _4233;
    assign _4230 = _857[1:1];
    assign _4241 = _4230 ? _4240 : _4237;
    assign _4229 = _857[2:2];
    assign _4245 = _4229 ? _4244 : _4241;
    assign _4228 = _857[3:3];
    assign _4249 = _4228 ? _4248 : _4245;
    assign _4227 = _857[4:4];
    assign _4253 = _4227 ? _4252 : _4249;
    assign _4254 = _4253[15:0];
    assign _4283 = _979 ? _4282 : _4254;
    assign _4284 = _1268 ? _4216 : _4283;
    assign _4225 = _821 ? _4216 : _4217;
    assign _4221 = _942 == _4489;
    assign _4222 = _4221 ? _2507 : _4217;
    assign _4223 = _948 ? _4222 : _4217;
    assign _4220 = _658 == _1598;
    assign _4224 = _4220 ? _4223 : _4217;
    assign _4219 = _658 == _4489;
    assign _4226 = _4219 ? _4225 : _4224;
    assign _4218 = _658 == _965;
    assign _4285 = _4218 ? _4284 : _4226;
    assign _4213 = t0_tx_wr == _874;
    assign _4214 = _1231 & _4213;
    always @(posedge _146) begin
        if (_144)
            t0_tx_mem_3 <= _312;
        else
            if (_4214)
                t0_tx_mem_3 <= _4191;
    end
    assign _4207 = t0_tx_wr == _234;
    assign _4208 = _1231 & _4207;
    always @(posedge _146) begin
        if (_144)
            t0_tx_mem_2 <= _312;
        else
            if (_4208)
                t0_tx_mem_2 <= _4191;
    end
    assign _4201 = t0_tx_wr == _231;
    assign _4202 = _1231 & _4201;
    always @(posedge _146) begin
        if (_144)
            t0_tx_mem_1 <= _312;
        else
            if (_4202)
                t0_tx_mem_1 <= _4191;
    end
    assign _1236 = t0_tx_wr + _231;
    assign _1237 = _1231 ? _1236 : t0_tx_wr;
    assign _21 = _1237;
    always @(posedge _146) begin
        if (_144)
            t0_tx_wr <= _4480;
        else
            t0_tx_wr <= _21;
    end
    assign _4195 = t0_tx_wr == _4480;
    assign _4196 = _1231 & _4195;
    assign _4191 = _1214 ? _92 : _622;
    always @(posedge _146) begin
        if (_144)
            t0_tx_mem_0 <= _312;
        else
            if (_4196)
                t0_tx_mem_0 <= _4191;
    end
    assign _1244 = t0_tx_rd + _231;
    assign _1245 = _1239 ? _1244 : t0_tx_rd;
    assign _22 = _1245;
    always @(posedge _146) begin
        if (_144)
            t0_tx_rd <= _4480;
        else
            t0_tx_rd <= _22;
    end
    always @* begin
        case (t0_tx_rd)
        0:
            _4216 <= t0_tx_mem_0;
        1:
            _4216 <= t0_tx_mem_1;
        2:
            _4216 <= t0_tx_mem_2;
        default:
            _4216 <= t0_tx_mem_3;
        endcase
    end
    assign _838 = 5'b00000;
    assign _1238 = ~ _824;
    assign _1250 = ~ _824;
    assign _1247 = _658 == _4489;
    assign _1248 = _657 & _1247;
    assign _1249 = _1248 & _821;
    assign _1251 = _1249 & _1250;
    assign _1269 = _1251 | _1268;
    assign _1272 = _1269 | _1271;
    assign _23 = _1272;
    assign _1239 = _23 & _1238;
    assign _4161 = { _4480,
                     _1239 };
    assign _1230 = ~ _1229;
    assign _1223 = _1211 == _606;
    assign _1221 = _1219 == _231;
    assign _1224 = _1221 & _1223;
    assign _1225 = ~ _1224;
    assign _1216 = 7'b1001000;
    assign _1217 = _618 == _1216;
    assign _1215 = _612 & _616;
    assign _1218 = _1215 & _1217;
    assign _1226 = _1218 & _1225;
    assign _1213 = _1211 == _606;
    assign _1756 = t1_tx_level == _4489;
    assign _1229 = t0_tx_level == _4489;
    assign _4154 = _1211 ? _1756 : _1229;
    assign _4155 = ~ _4154;
    assign _4151 = _1751 & _1211;
    assign _4152 = ~ _4151;
    always @(posedge _146) begin
        if (_144)
            buf_wrote <= _606;
        else
            buf_wrote <= _90;
    end
    assign _4149 = ~ buf_wrote;
    assign _4133 = _622[9:0];
    assign _4130 = 10'b0000000001;
    assign _4131 = buf_ptr + _4130;
    assign _1279 = 7'b1101011;
    assign _1280 = _326 == _1279;
    assign _1276 = _325[7:7];
    assign _1277 = ~ _1276;
    assign _1278 = _1275 & _1277;
    assign _1281 = _1278 & _1280;
    assign _24 = _1281;
    assign _4128 = _24 & _3768;
    assign _4102 = { _4480,
                     _2038 };
    assign _484 = ~ _483;
    assign _4096 = _1392 & _1388;
    assign _4094 = ~ _483;
    assign _4092 = ~ _1346;
    assign _4090 = _1314 == _4489;
    assign _4067 = t1_delay_left - _4409;
    assign _4061 = _4059[3:2];
    assign _4062 = { _4480,
                     _4061 };
    assign _4056 = _2919[0:0];
    assign _4059 = _4056 ? _4401 : _4400;
    assign _4055 = _2919[1:1];
    assign _4063 = _4055 ? _4062 : _4059;
    assign _4064 = _3331 & _4063;
    assign _1389 = _1388 & _483;
    assign _483 = t1_rx_level == _4489;
    assign _1354 = ~ _1346;
    assign _1353 = _1314 == _4489;
    assign _1355 = _1353 & _1354;
    assign _1356 = _1355 & _483;
    assign _1345 = _1314 == _4489;
    assign _1347 = _1345 & _1346;
    assign _1350 = _1347 & _1349;
    assign _1342 = ~ _1341;
    assign _1329 = ~ _1328;
    assign _4046 = _618[5:0];
    assign _4045 = cfg_load[1:0];
    assign _4047 = { _4045,
                     _4046 };
    assign _4036 = _107[5:0];
    assign _1286 = _622[7:0];
    assign _1283 = 7'b1010001;
    assign _1284 = _618 == _1283;
    assign _1282 = _612 & _616;
    assign _1285 = _1282 & _1284;
    assign _1287 = _1285 ? _1286 : cfg_t1_start;
    assign _25 = _1287;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_start <= _576;
        else
            cfg_t1_start <= _25;
    end
    assign _1407 = cfg_t1_start[7:6];
    assign _1401 = _107[1:0];
    assign _1400 = _1398 == _874;
    assign _1402 = _1400 ? _1401 : t1_page;
    assign _1397 = _1314 == _951;
    assign _1403 = _1397 ? _1402 : t1_page;
    assign _1404 = _1392 ? _1403 : t1_page;
    assign _1405 = _1309 ? t1_page : _1404;
    assign _1406 = _1303 ? t1_page : _1405;
    assign _1408 = _1297 ? _1407 : _1406;
    assign _26 = _1408;
    assign _27 = _26;
    always @(posedge _146) begin
        if (_144)
            t1_page <= _4480;
        else
            t1_page <= _27;
    end
    assign _4037 = { t1_page,
                     _4036 };
    assign _1413 = _622[7:0];
    assign _1410 = 7'b1010110;
    assign _1411 = _618 == _1410;
    assign _1409 = _612 & _616;
    assign _1412 = _1409 & _1411;
    assign _1414 = _1412 ? _1413 : cfg_t1_timeout_vector;
    assign _28 = _1414;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_timeout_vector <= _576;
        else
            cfg_t1_timeout_vector <= _28;
    end
    assign _4035 = _1314 == _473;
    assign _4038 = _4035 ? _4037 : cfg_t1_timeout_vector;
    assign _4033 = t1_pc + _4378;
    assign _1423 = _1338 - _897;
    assign _1424 = _1421 ? _1423 : t1_wait_count;
    assign _1425 = _1309 ? t1_wait_count : _1424;
    assign _1426 = _1303 ? t1_wait_count : _1425;
    assign _1428 = _1297 ? _312 : _1426;
    assign _29 = _1428;
    assign _30 = _29;
    always @(posedge _146) begin
        if (_144)
            t1_wait_count <= _312;
        else
            t1_wait_count <= _30;
    end
    assign _1430 = 7'b1011011;
    assign _1431 = _618 == _1430;
    assign _1429 = _612 & _616;
    assign _1432 = _1429 & _1431;
    assign _1433 = _1432 ? _622 : cfg_t1_timeout;
    assign _31 = _1433;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_timeout <= _312;
        else
            cfg_t1_timeout <= _31;
    end
    assign _1420 = ~ _1340;
    assign _1417 = ~ _1328;
    assign _1416 = _1314 == _659;
    assign _1418 = _1416 & _1417;
    assign _1419 = _1418 & _1331;
    assign _1421 = _1419 & _1420;
    assign _1435 = _1421 ? _1746 : t1_waiting;
    assign _1437 = _1392 ? _606 : _1435;
    assign _1438 = _1309 ? t1_waiting : _1437;
    assign _1439 = _1303 ? t1_waiting : _1438;
    assign _1441 = _1297 ? _606 : _1439;
    assign _32 = _1441;
    assign _33 = _32;
    always @(posedge _146) begin
        if (_144)
            t1_waiting <= _606;
        else
            t1_waiting <= _33;
    end
    assign _1338 = t1_waiting ? t1_wait_count : cfg_t1_timeout;
    assign _1340 = _1338 == _312;
    assign _1331 = _107[4:4];
    assign _1341 = _1331 & _1340;
    assign _1327 = _107[8:8];
    assign _1325 = _792[7:7];
    assign _1324 = _792[6:6];
    assign _1323 = _792[5:5];
    assign _1322 = _792[4:4];
    assign _1321 = _792[3:3];
    assign _1320 = _792[2:2];
    assign _1319 = _792[1:1];
    assign _1318 = _792[0:0];
    assign _1317 = _107[7:5];
    always @* begin
        case (_1317)
        0:
            _1326 <= _1318;
        1:
            _1326 <= _1319;
        2:
            _1326 <= _1320;
        3:
            _1326 <= _1321;
        4:
            _1326 <= _1322;
        5:
            _1326 <= _1323;
        6:
            _1326 <= _1324;
        default:
            _1326 <= _1325;
        endcase
    end
    assign _1328 = _1326 == _1327;
    assign _4028 = ~ _1328;
    assign _4027 = _1314 == _659;
    assign _4029 = _4027 & _4028;
    assign _4030 = _4029 & _1341;
    assign _4023 = t1_isr_count < cfg_t1_threshold;
    assign _4022 = t1_osr_count < cfg_t1_threshold;
    assign _4020 = t1_x == t1_y;
    assign _4021 = ~ _4020;
    assign _4017 = t1_y == _312;
    assign _4018 = ~ _4017;
    assign _4019 = ~ _4018;
    assign _4002 = t1_x - _897;
    assign _4000 = _3970 == _4345;
    assign _4003 = _4000 ? _4002 : t1_x;
    assign _3996 = _3965 == _231;
    assign _3997 = _3996 ? _1567 : t1_x;
    assign _1787 = cfg_t1_shift[4:4];
    assign _1788 = { _1787,
                     _1787 };
    assign _1789 = { _1788,
                     _1788 };
    assign _1790 = { _1789,
                     _1789 };
    assign _1791 = { _1790,
                     _1790 };
    assign _1792 = { _1791,
                     _1791 };
    assign _1443 = 7'b1110011;
    assign _1444 = _618 == _1443;
    assign _1442 = _612 & _616;
    assign _1445 = _1442 & _1444;
    assign _1446 = _1445 ? _622 : cfg_t1_crc_init_lo;
    assign _34 = _1446;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_crc_init_lo <= _312;
        else
            cfg_t1_crc_init_lo <= _34;
    end
    assign _1448 = 7'b1110100;
    assign _1449 = _618 == _1448;
    assign _1447 = _612 & _616;
    assign _1450 = _1447 & _1449;
    assign _1451 = _1450 ? _622 : cfg_t1_crc_init_hi;
    assign _35 = _1451;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_crc_init_hi <= _312;
        else
            cfg_t1_crc_init_hi <= _35;
    end
    assign _1728 = { cfg_t1_crc_init_hi,
                     cfg_t1_crc_init_lo };
    assign _1725 = t1_crc[31:16];
    assign _1726 = { _312,
                     _1725 };
    assign _1727 = _1477 ? _1726 : _1722;
    assign _1729 = _1475 ? _1728 : _1727;
    assign _1730 = _1473 ? _1729 : _1722;
    assign _1723 = _1314 == _1598;
    assign _1731 = _1723 ? _1730 : _1722;
    assign _1711 = _1691[15:15];
    assign _1710 = _1691[14:14];
    assign _1709 = _1691[13:13];
    assign _1708 = _1691[12:12];
    assign _1707 = _1691[11:11];
    assign _1706 = _1691[10:10];
    assign _1705 = _1691[9:9];
    assign _1704 = _1691[8:8];
    assign _1703 = _1691[7:7];
    assign _1702 = _1691[6:6];
    assign _1701 = _1691[5:5];
    assign _1700 = _1691[4:4];
    assign _1699 = _1691[3:3];
    assign _1698 = _1691[2:2];
    assign _1697 = _1691[1:1];
    assign _1696 = _1691[0:0];
    assign _1694 = _1382 - _1168;
    assign _1695 = _1694[3:0];
    always @* begin
        case (_1695)
        0:
            _1712 <= _1696;
        1:
            _1712 <= _1697;
        2:
            _1712 <= _1698;
        3:
            _1712 <= _1699;
        4:
            _1712 <= _1700;
        5:
            _1712 <= _1701;
        6:
            _1712 <= _1702;
        7:
            _1712 <= _1703;
        8:
            _1712 <= _1704;
        9:
            _1712 <= _1705;
        10:
            _1712 <= _1706;
        11:
            _1712 <= _1707;
        12:
            _1712 <= _1708;
        13:
            _1712 <= _1709;
        14:
            _1712 <= _1710;
        default:
            _1712 <= _1711;
        endcase
    end
    assign _1690 = _1689 & _1535;
    assign _1691 = _1489 ? _1690 : _1567;
    assign _1692 = _1691[0:0];
    assign _1506 = _1489 ? _1505 : _1504;
    assign _1713 = _1506 ? _1712 : _1692;
    assign _1503 = t1_crc[0:0];
    assign _1714 = _1503 ^ _1713;
    assign _1715 = { _1714,
                     _1714 };
    assign _1716 = { _1715,
                     _1715 };
    assign _1717 = { _1716,
                     _1716 };
    assign _1718 = { _1717,
                     _1717 };
    assign _1719 = { _1718,
                     _1718 };
    assign _1453 = 7'b1110001;
    assign _1454 = _618 == _1453;
    assign _1452 = _612 & _616;
    assign _1455 = _1452 & _1454;
    assign _1456 = _1455 ? _622 : cfg_t1_crc_poly_lo;
    assign _36 = _1456;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_crc_poly_lo <= _312;
        else
            cfg_t1_crc_poly_lo <= _36;
    end
    assign _1458 = 7'b1110010;
    assign _1459 = _618 == _1458;
    assign _1457 = _612 & _616;
    assign _1460 = _1457 & _1459;
    assign _1461 = _1460 ? _622 : cfg_t1_crc_poly_hi;
    assign _37 = _1461;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_crc_poly_hi <= _312;
        else
            cfg_t1_crc_poly_hi <= _37;
    end
    assign _1502 = { cfg_t1_crc_poly_hi,
                     cfg_t1_crc_poly_lo };
    assign _1720 = _1502 & _1719;
    assign _1500 = t1_crc[31:1];
    assign _1501 = { _606,
                     _1500 };
    assign _1721 = _1501 ^ _1720;
    assign _1493 = _1314 == _4345;
    assign _1491 = _1314 == _965;
    assign _1489 = cfg_t1_shift[5:5];
    assign _1494 = _1489 ? _1493 : _1491;
    assign _1477 = _1470 == _951;
    assign _1478 = _1477 ? gnd : t1_crc_run;
    assign _1475 = _1467 == _951;
    assign _1480 = _1475 ? _1746 : _1478;
    assign _1481 = _1473 ? _1480 : t1_crc_run;
    assign _1466 = _1314 == _1598;
    assign _1482 = _1466 ? _1481 : t1_crc_run;
    assign _1483 = _1392 ? _1482 : t1_crc_run;
    assign _1484 = _1309 ? t1_crc_run : _1483;
    assign _1485 = _1303 ? t1_crc_run : _1484;
    assign _1487 = _1297 ? _1746 : _1485;
    assign _38 = _1487;
    assign _39 = _38;
    always @(posedge _146) begin
        if (_144)
            t1_crc_run <= _606;
        else
            t1_crc_run <= _39;
    end
    assign _1488 = _1392 & t1_crc_run;
    assign _1495 = _1488 & _1494;
    assign _1722 = _1495 ? _1721 : t1_crc;
    assign _1732 = _1392 ? _1731 : _1722;
    assign _1733 = _1309 ? t1_crc : _1732;
    assign _1734 = _1303 ? t1_crc : _1733;
    assign _1735 = _1297 ? _1728 : _1734;
    assign _40 = _1735;
    assign _41 = _40;
    always @(posedge _146) begin
        if (_144)
            t1_crc <= _972;
        else
            t1_crc <= _41;
    end
    assign _1793 = t1_crc ^ _1792;
    assign _1794 = _1793[15:0];
    assign _1785 = { _576,
                     _792 };
    assign _3974 = t1_y - _897;
    assign _3972 = _3970 == _4489;
    assign _3975 = _3972 ? _3974 : t1_y;
    assign _1563 = _1561[31:16];
    assign _1564 = { _312,
                     _1563 };
    assign _1559 = _1557[31:8];
    assign _1560 = { _576,
                     _1559 };
    assign _1555 = _1553[31:4];
    assign _1556 = { _655,
                     _1555 };
    assign _1551 = _1549[31:2];
    assign _1552 = { _4480,
                     _1551 };
    assign _1547 = _1545[31:1];
    assign _1548 = { _606,
                     _1547 };
    assign _1545 = { _312,
                     t1_osr };
    assign _1543 = _1538[0:0];
    assign _1549 = _1543 ? _1548 : _1545;
    assign _1542 = _1538[1:1];
    assign _1553 = _1542 ? _1552 : _1549;
    assign _1541 = _1538[2:2];
    assign _1557 = _1541 ? _1556 : _1553;
    assign _1540 = _1538[3:3];
    assign _1561 = _1540 ? _1560 : _1557;
    assign _1538 = _1012 - _1382;
    assign _1539 = _1538[4:4];
    assign _1565 = _1539 ? _1564 : _1561;
    assign _1566 = _1565[15:0];
    assign _3932 = _3931[15:0];
    assign _3934 = { _3932,
                     _312 };
    assign _3928 = _3927[23:0];
    assign _3930 = { _3928,
                     _576 };
    assign _3924 = _3923[27:0];
    assign _3926 = { _3924,
                     _655 };
    assign _3920 = _3919[29:0];
    assign _3922 = { _3920,
                     _4480 };
    assign _3916 = _3915[30:0];
    assign _3918 = { _3916,
                     _606 };
    assign _3915 = { _312,
                     t1_osr };
    assign _3913 = _1382[0:0];
    assign _3919 = _3913 ? _3918 : _3915;
    assign _3912 = _1382[1:1];
    assign _3923 = _3912 ? _3922 : _3919;
    assign _3911 = _1382[2:2];
    assign _3927 = _3911 ? _3926 : _3923;
    assign _3910 = _1382[3:3];
    assign _3931 = _3910 ? _3930 : _3927;
    assign _3909 = _1382[4:4];
    assign _3935 = _3909 ? _3934 : _3931;
    assign _3936 = _3935[15:0];
    assign _3905 = _3903[31:16];
    assign _3906 = { _312,
                     _3905 };
    assign _3901 = _3899[31:8];
    assign _3902 = { _576,
                     _3901 };
    assign _3897 = _3895[31:4];
    assign _3898 = { _655,
                     _3897 };
    assign _3893 = _3891[31:2];
    assign _3894 = { _4480,
                     _3893 };
    assign _3889 = _3887[31:1];
    assign _3890 = { _606,
                     _3889 };
    assign _3887 = { _312,
                     t1_osr };
    assign _3885 = _1382[0:0];
    assign _3891 = _3885 ? _3890 : _3887;
    assign _3884 = _1382[1:1];
    assign _3895 = _3884 ? _3894 : _3891;
    assign _3883 = _1382[2:2];
    assign _3899 = _3883 ? _3898 : _3895;
    assign _3882 = _1382[3:3];
    assign _3903 = _3882 ? _3902 : _3899;
    assign _3881 = _1382[4:4];
    assign _3907 = _3881 ? _3906 : _3903;
    assign _3908 = _3907[15:0];
    assign _3937 = _1504 ? _3936 : _3908;
    assign _3938 = _3803 ? _3870 : _3937;
    assign _3879 = _1346 ? _3870 : _3871;
    assign _3875 = _1467 == _4489;
    assign _3876 = _3875 ? _1795 : _3871;
    assign _3877 = _1473 ? _3876 : _3871;
    assign _3874 = _1314 == _1598;
    assign _3878 = _3874 ? _3877 : _3871;
    assign _3873 = _1314 == _4489;
    assign _3880 = _3873 ? _3879 : _3878;
    assign _3872 = _1314 == _965;
    assign _3939 = _3872 ? _3938 : _3880;
    assign _3867 = t1_tx_wr == _874;
    assign _3868 = _1758 & _3867;
    always @(posedge _146) begin
        if (_144)
            t1_tx_mem_3 <= _312;
        else
            if (_3868)
                t1_tx_mem_3 <= _3845;
    end
    assign _3861 = t1_tx_wr == _234;
    assign _3862 = _1758 & _3861;
    always @(posedge _146) begin
        if (_144)
            t1_tx_mem_2 <= _312;
        else
            if (_3862)
                t1_tx_mem_2 <= _3845;
    end
    assign _3855 = t1_tx_wr == _231;
    assign _3856 = _1758 & _3855;
    always @(posedge _146) begin
        if (_144)
            t1_tx_mem_1 <= _312;
        else
            if (_3856)
                t1_tx_mem_1 <= _3845;
    end
    assign _1763 = t1_tx_wr + _231;
    assign _1764 = _1758 ? _1763 : t1_tx_wr;
    assign _42 = _1764;
    always @(posedge _146) begin
        if (_144)
            t1_tx_wr <= _4480;
        else
            t1_tx_wr <= _42;
    end
    assign _3849 = t1_tx_wr == _4480;
    assign _3850 = _1758 & _3849;
    assign _43 = _404;
    assign _508 = t1_rx_wr == _874;
    assign _509 = _485 & _508;
    always @(posedge _146) begin
        if (_144)
            t1_rx_mem_3 <= _312;
        else
            if (_509)
                t1_rx_mem_3 <= _50;
    end
    assign _502 = t1_rx_wr == _234;
    assign _503 = _485 & _502;
    always @(posedge _146) begin
        if (_144)
            t1_rx_mem_2 <= _312;
        else
            if (_503)
                t1_rx_mem_2 <= _50;
    end
    assign _496 = t1_rx_wr == _231;
    assign _497 = _485 & _496;
    always @(posedge _146) begin
        if (_144)
            t1_rx_mem_1 <= _312;
        else
            if (_497)
                t1_rx_mem_1 <= _50;
    end
    assign _1766 = t1_rx_wr + _231;
    assign _1767 = _485 ? _1766 : t1_rx_wr;
    assign _44 = _1767;
    always @(posedge _146) begin
        if (_144)
            t1_rx_wr <= _4480;
        else
            t1_rx_wr <= _44;
    end
    assign _490 = t1_rx_wr == _4480;
    assign _491 = _485 & _490;
    assign _2005 = _2004[15:0];
    assign _2007 = { _2005,
                     _312 };
    assign _2001 = _2000[23:0];
    assign _2003 = { _2001,
                     _576 };
    assign _1997 = _1996[27:0];
    assign _1999 = { _1997,
                     _655 };
    assign _1993 = _1992[29:0];
    assign _1995 = { _1993,
                     _4480 };
    assign _1991 = 32'b11111111111111111111111111111110;
    assign _1990 = 32'b11111111111111111111111111111111;
    assign _1989 = _1886[0:0];
    assign _1992 = _1989 ? _1991 : _1990;
    assign _1988 = _1886[1:1];
    assign _1996 = _1988 ? _1995 : _1992;
    assign _1987 = _1886[2:2];
    assign _2000 = _1987 ? _1999 : _1996;
    assign _1986 = _1886[3:3];
    assign _2004 = _1986 ? _2003 : _2000;
    assign _1985 = _1886[4:4];
    assign _2008 = _1985 ? _2007 : _2004;
    assign _2009 = _2008[15:0];
    assign _2010 = ~ _2009;
    assign _2011 = _1859 & _2010;
    assign _1981 = _1979[31:16];
    assign _1982 = { _312,
                     _1981 };
    assign _1977 = _1975[31:8];
    assign _1978 = { _576,
                     _1977 };
    assign _1973 = _1971[31:4];
    assign _1974 = { _655,
                     _1973 };
    assign _1969 = _1967[31:2];
    assign _1970 = { _4480,
                     _1969 };
    assign _1965 = _1963[31:1];
    assign _1966 = { _606,
                     _1965 };
    assign _1963 = { _312,
                     _1859 };
    assign _1961 = _1956[0:0];
    assign _1967 = _1961 ? _1966 : _1963;
    assign _1960 = _1956[1:1];
    assign _1971 = _1960 ? _1970 : _1967;
    assign _1959 = _1956[2:2];
    assign _1975 = _1959 ? _1974 : _1971;
    assign _1958 = _1956[3:3];
    assign _1979 = _1958 ? _1978 : _1975;
    assign _1956 = _1012 - _1886;
    assign _1957 = _1956[4:4];
    assign _1983 = _1957 ? _1982 : _1979;
    assign _1984 = _1983[15:0];
    assign _2012 = _1505 ? _2011 : _1984;
    assign _1947 = _1946[15:0];
    assign _1949 = { _1947,
                     _312 };
    assign _1943 = _1942[23:0];
    assign _1945 = { _1943,
                     _576 };
    assign _1939 = _1938[27:0];
    assign _1941 = { _1939,
                     _655 };
    assign _1935 = _1934[29:0];
    assign _1937 = { _1935,
                     _4480 };
    assign _1931 = t1_isr_count[0:0];
    assign _1934 = _1931 ? _1991 : _1990;
    assign _1930 = t1_isr_count[1:1];
    assign _1938 = _1930 ? _1937 : _1934;
    assign _1929 = t1_isr_count[2:2];
    assign _1942 = _1929 ? _1941 : _1938;
    assign _1928 = t1_isr_count[3:3];
    assign _1946 = _1928 ? _1945 : _1942;
    assign _1927 = t1_isr_count[4:4];
    assign _1950 = _1927 ? _1949 : _1946;
    assign _1951 = _1950[15:0];
    assign _1952 = ~ _1951;
    assign _1953 = t1_isr & _1952;
    assign _1923 = _1921[31:16];
    assign _1924 = { _312,
                     _1923 };
    assign _1919 = _1917[31:8];
    assign _1920 = { _576,
                     _1919 };
    assign _1915 = _1913[31:4];
    assign _1916 = { _655,
                     _1915 };
    assign _1911 = _1909[31:2];
    assign _1912 = { _4480,
                     _1911 };
    assign _1907 = _1905[31:1];
    assign _1908 = { _606,
                     _1907 };
    assign _1530 = _1529[15:0];
    assign _1532 = { _1530,
                     _312 };
    assign _1526 = _1525[23:0];
    assign _1528 = { _1526,
                     _576 };
    assign _1522 = _1521[27:0];
    assign _1524 = { _1522,
                     _655 };
    assign _1518 = _1517[29:0];
    assign _1520 = { _1518,
                     _4480 };
    assign _1514 = _1382[0:0];
    assign _1517 = _1514 ? _1991 : _1990;
    assign _1513 = _1382[1:1];
    assign _1521 = _1513 ? _1520 : _1517;
    assign _1512 = _1382[2:2];
    assign _1525 = _1512 ? _1524 : _1521;
    assign _1511 = _1382[3:3];
    assign _1529 = _1511 ? _1528 : _1525;
    assign _1510 = _1382[4:4];
    assign _1533 = _1510 ? _1532 : _1529;
    assign _1534 = _1533[15:0];
    assign _1535 = ~ _1534;
    assign _1857 = _1689 & _1535;
    assign _1852 = _1851[15:0];
    assign _1854 = { _1852,
                     _312 };
    assign _1848 = _1847[23:0];
    assign _1850 = { _1848,
                     _576 };
    assign _1844 = _1843[27:0];
    assign _1846 = { _1844,
                     _655 };
    assign _1840 = _1839[29:0];
    assign _1842 = { _1840,
                     _4480 };
    assign _1836 = _1835[30:0];
    assign _1838 = { _1836,
                     _606 };
    assign _1835 = { _312,
                     t1_isr };
    assign _1833 = _1382[0:0];
    assign _1839 = _1833 ? _1838 : _1835;
    assign _1832 = _1382[1:1];
    assign _1843 = _1832 ? _1842 : _1839;
    assign _1831 = _1382[2:2];
    assign _1847 = _1831 ? _1846 : _1843;
    assign _1830 = _1382[3:3];
    assign _1851 = _1830 ? _1850 : _1847;
    assign _1829 = _1382[4:4];
    assign _1855 = _1829 ? _1854 : _1851;
    assign _1856 = _1855[15:0];
    assign _1858 = _1856 | _1857;
    assign _1825 = _1823[31:16];
    assign _1826 = { _312,
                     _1825 };
    assign _1821 = _1819[31:8];
    assign _1822 = { _576,
                     _1821 };
    assign _1817 = _1815[31:4];
    assign _1818 = { _655,
                     _1817 };
    assign _1813 = _1811[31:2];
    assign _1814 = { _4480,
                     _1813 };
    assign _1809 = _1807[31:1];
    assign _1810 = { _606,
                     _1809 };
    assign _1678 = _838 < _1382;
    assign _1675 = _792[7:7];
    assign _1674 = _792[6:6];
    assign _1673 = _792[5:5];
    assign _1672 = _792[4:4];
    assign _1671 = _792[3:3];
    assign _1670 = _792[2:2];
    assign _1669 = _792[1:1];
    assign _1668 = _792[0:0];
    always @* begin
        case (cfg_t1_in_base)
        0:
            _1676 <= _1668;
        1:
            _1676 <= _1669;
        2:
            _1676 <= _1670;
        3:
            _1676 <= _1671;
        4:
            _1676 <= _1672;
        5:
            _1676 <= _1673;
        6:
            _1676 <= _1674;
        default:
            _1676 <= _1675;
        endcase
    end
    assign _1679 = _1676 & _1678;
    assign _1666 = _1168 < _1382;
    assign _1663 = _792[7:7];
    assign _1662 = _792[6:6];
    assign _1661 = _792[5:5];
    assign _1660 = _792[4:4];
    assign _1659 = _792[3:3];
    assign _1658 = _792[2:2];
    assign _1657 = _792[1:1];
    assign _1656 = _792[0:0];
    assign _1655 = cfg_t1_in_base + _659;
    always @* begin
        case (_1655)
        0:
            _1664 <= _1656;
        1:
            _1664 <= _1657;
        2:
            _1664 <= _1658;
        3:
            _1664 <= _1659;
        4:
            _1664 <= _1660;
        5:
            _1664 <= _1661;
        6:
            _1664 <= _1662;
        default:
            _1664 <= _1663;
        endcase
    end
    assign _1667 = _1664 & _1666;
    assign _1651 = 5'b00010;
    assign _1652 = _1651 < _1382;
    assign _1649 = _792[7:7];
    assign _1648 = _792[6:6];
    assign _1647 = _792[5:5];
    assign _1646 = _792[4:4];
    assign _1645 = _792[3:3];
    assign _1644 = _792[2:2];
    assign _1643 = _792[1:1];
    assign _1642 = _792[0:0];
    assign _1641 = cfg_t1_in_base + _4345;
    always @* begin
        case (_1641)
        0:
            _1650 <= _1642;
        1:
            _1650 <= _1643;
        2:
            _1650 <= _1644;
        3:
            _1650 <= _1645;
        4:
            _1650 <= _1646;
        5:
            _1650 <= _1647;
        6:
            _1650 <= _1648;
        default:
            _1650 <= _1649;
        endcase
    end
    assign _1653 = _1650 & _1652;
    assign _1637 = 5'b00011;
    assign _1638 = _1637 < _1382;
    assign _1635 = _792[7:7];
    assign _1634 = _792[6:6];
    assign _1633 = _792[5:5];
    assign _1632 = _792[4:4];
    assign _1631 = _792[3:3];
    assign _1630 = _792[2:2];
    assign _1629 = _792[1:1];
    assign _1628 = _792[0:0];
    assign _1627 = cfg_t1_in_base + _965;
    always @* begin
        case (_1627)
        0:
            _1636 <= _1628;
        1:
            _1636 <= _1629;
        2:
            _1636 <= _1630;
        3:
            _1636 <= _1631;
        4:
            _1636 <= _1632;
        5:
            _1636 <= _1633;
        6:
            _1636 <= _1634;
        default:
            _1636 <= _1635;
        endcase
    end
    assign _1639 = _1636 & _1638;
    assign _1623 = 5'b00100;
    assign _1624 = _1623 < _1382;
    assign _1621 = _792[7:7];
    assign _1620 = _792[6:6];
    assign _1619 = _792[5:5];
    assign _1618 = _792[4:4];
    assign _1617 = _792[3:3];
    assign _1616 = _792[2:2];
    assign _1615 = _792[1:1];
    assign _1614 = _792[0:0];
    assign _1613 = cfg_t1_in_base + _4489;
    always @* begin
        case (_1613)
        0:
            _1622 <= _1614;
        1:
            _1622 <= _1615;
        2:
            _1622 <= _1616;
        3:
            _1622 <= _1617;
        4:
            _1622 <= _1618;
        5:
            _1622 <= _1619;
        6:
            _1622 <= _1620;
        default:
            _1622 <= _1621;
        endcase
    end
    assign _1625 = _1622 & _1624;
    assign _1609 = 5'b00101;
    assign _1610 = _1609 < _1382;
    assign _1607 = _792[7:7];
    assign _1606 = _792[6:6];
    assign _1605 = _792[5:5];
    assign _1604 = _792[4:4];
    assign _1603 = _792[3:3];
    assign _1602 = _792[2:2];
    assign _1601 = _792[1:1];
    assign _1600 = _792[0:0];
    assign _1598 = 3'b101;
    assign _1599 = cfg_t1_in_base + _1598;
    always @* begin
        case (_1599)
        0:
            _1608 <= _1600;
        1:
            _1608 <= _1601;
        2:
            _1608 <= _1602;
        3:
            _1608 <= _1603;
        4:
            _1608 <= _1604;
        5:
            _1608 <= _1605;
        6:
            _1608 <= _1606;
        default:
            _1608 <= _1607;
        endcase
    end
    assign _1611 = _1608 & _1610;
    assign _1595 = 5'b00110;
    assign _1596 = _1595 < _1382;
    assign _1593 = _792[7:7];
    assign _1592 = _792[6:6];
    assign _1591 = _792[5:5];
    assign _1590 = _792[4:4];
    assign _1589 = _792[3:3];
    assign _1588 = _792[2:2];
    assign _1587 = _792[1:1];
    assign _1586 = _792[0:0];
    assign _1585 = cfg_t1_in_base + _951;
    always @* begin
        case (_1585)
        0:
            _1594 <= _1586;
        1:
            _1594 <= _1587;
        2:
            _1594 <= _1588;
        3:
            _1594 <= _1589;
        4:
            _1594 <= _1590;
        5:
            _1594 <= _1591;
        6:
            _1594 <= _1592;
        default:
            _1594 <= _1593;
        endcase
    end
    assign _1597 = _1594 & _1596;
    assign _1581 = 5'b00111;
    assign _1582 = _1581 < _1382;
    assign _1579 = _792[7:7];
    assign _1578 = _792[6:6];
    assign _1577 = _792[5:5];
    assign _1576 = _792[4:4];
    assign _1575 = _792[3:3];
    assign _1574 = _792[2:2];
    assign _1573 = _792[1:1];
    assign _1572 = _792[0:0];
    assign _1570 = 3'b111;
    assign _1772 = _622[2:0];
    assign _1769 = 7'b1010100;
    assign _1770 = _618 == _1769;
    assign _1768 = _612 & _616;
    assign _1771 = _1768 & _1770;
    assign _1773 = _1771 ? _1772 : cfg_t1_in_base;
    assign _45 = _1773;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_in_base <= _473;
        else
            cfg_t1_in_base <= _45;
    end
    assign _1571 = cfg_t1_in_base + _1570;
    always @* begin
        case (_1571)
        0:
            _1580 <= _1572;
        1:
            _1580 <= _1573;
        2:
            _1580 <= _1574;
        3:
            _1580 <= _1575;
        4:
            _1580 <= _1576;
        5:
            _1580 <= _1577;
        6:
            _1580 <= _1578;
        default:
            _1580 <= _1579;
        endcase
    end
    assign _1583 = _1580 & _1582;
    assign _1680 = { _1583,
                     _1597,
                     _1611,
                     _1625,
                     _1639,
                     _1653,
                     _1667,
                     _1679 };
    assign _1681 = { _576,
                     _1680 };
    assign _1568 = _107[8:7];
    always @* begin
        case (_1568)
        0:
            _1689 <= _1681;
        1:
            _1689 <= t1_x;
        2:
            _1689 <= t1_y;
        default:
            _1689 <= _312;
        endcase
    end
    assign _1807 = { _1689,
                     t1_isr };
    assign _1806 = _1382[0:0];
    assign _1811 = _1806 ? _1810 : _1807;
    assign _1805 = _1382[1:1];
    assign _1815 = _1805 ? _1814 : _1811;
    assign _1804 = _1382[2:2];
    assign _1819 = _1804 ? _1818 : _1815;
    assign _1803 = _1382[3:3];
    assign _1823 = _1803 ? _1822 : _1819;
    assign _1802 = _1382[4:4];
    assign _1827 = _1802 ? _1826 : _1823;
    assign _1828 = _1827[15:0];
    assign _1859 = _1505 ? _1858 : _1828;
    assign _1861 = _1388 ? _312 : _1859;
    assign _1800 = _1346 ? t1_isr : _312;
    assign _1783 = _1467 == _965;
    assign _1796 = _1783 ? _1795 : t1_isr;
    assign _1797 = _1473 ? _1796 : t1_isr;
    assign _1781 = _1314 == _1598;
    assign _1798 = _1781 ? _1797 : t1_isr;
    assign _1780 = _1314 == _4489;
    assign _1801 = _1780 ? _1800 : _1798;
    assign _1778 = _1314 == _4345;
    assign _1862 = _1778 ? _1861 : _1801;
    assign _1863 = _1392 ? _1862 : t1_isr;
    assign _1864 = _1309 ? t1_isr : _1863;
    assign _1865 = _1303 ? t1_isr : _1864;
    assign _1867 = _1297 ? _312 : _1865;
    assign _46 = _1867;
    assign _47 = _46;
    always @(posedge _146) begin
        if (_144)
            t1_isr <= _312;
        else
            t1_isr <= _47;
    end
    assign _1905 = { _312,
                     t1_isr };
    assign _1903 = _1898[0:0];
    assign _1909 = _1903 ? _1908 : _1905;
    assign _1902 = _1898[1:1];
    assign _1913 = _1902 ? _1912 : _1909;
    assign _1901 = _1898[2:2];
    assign _1917 = _1901 ? _1916 : _1913;
    assign _1900 = _1898[3:3];
    assign _1921 = _1900 ? _1920 : _1917;
    assign _1884 = _1882[4:0];
    assign _1881 = { gnd,
                     _1382 };
    assign _1880 = { gnd,
                     t1_isr_count };
    assign _1882 = _1880 + _1881;
    assign _1879 = 6'b010000;
    assign _1883 = _1879 < _1882;
    assign _1886 = _1883 ? _1012 : _1884;
    assign _1385 = { gnd,
                     cfg_t1_threshold };
    assign _1383 = { gnd,
                     _1382 };
    assign _1376 = { gnd,
                     t1_isr_count };
    assign _1384 = _1376 + _1383;
    assign _1386 = _1384 < _1385;
    assign _1387 = ~ _1386;
    assign _1371 = cfg_t1_shift[3:3];
    assign _1370 = _1314 == _4345;
    assign _1372 = _1370 & _1371;
    assign _1388 = _1372 & _1387;
    assign _1888 = _1388 ? _838 : _1886;
    assign _1877 = _1346 ? t1_isr_count : _838;
    assign _1871 = _1467 == _965;
    assign _1873 = _1871 ? _838 : t1_isr_count;
    assign _1874 = _1473 ? _1873 : t1_isr_count;
    assign _1870 = _1314 == _1598;
    assign _1875 = _1870 ? _1874 : t1_isr_count;
    assign _1869 = _1314 == _4489;
    assign _1878 = _1869 ? _1877 : _1875;
    assign _1868 = _1314 == _4345;
    assign _1889 = _1868 ? _1888 : _1878;
    assign _1890 = _1392 ? _1889 : t1_isr_count;
    assign _1891 = _1309 ? t1_isr_count : _1890;
    assign _1892 = _1303 ? t1_isr_count : _1891;
    assign _1894 = _1297 ? _838 : _1892;
    assign _48 = _1894;
    assign _49 = _48;
    always @(posedge _146) begin
        if (_144)
            t1_isr_count <= _838;
        else
            t1_isr_count <= _49;
    end
    assign _1898 = _1012 - t1_isr_count;
    assign _1899 = _1898[4:4];
    assign _1925 = _1899 ? _1924 : _1921;
    assign _1926 = _1925[15:0];
    assign _1505 = cfg_t1_shift[1:1];
    assign _1954 = _1505 ? _1953 : _1926;
    assign _1896 = _1314 == _4345;
    assign _2013 = _1896 ? _2012 : _1954;
    assign _50 = _2013;
    always @(posedge _146) begin
        if (_144)
            t1_rx_mem_0 <= _312;
        else
            if (_491)
                t1_rx_mem_0 <= _50;
    end
    assign _2040 = t1_rx_rd + _231;
    assign _2037 = ~ _2036;
    assign _2032 = _1211 == _1746;
    assign _2033 = _115 & _2032;
    assign _2027 = _1211 == _1746;
    assign _2025 = _1219 == _234;
    assign _2028 = _2025 & _2027;
    assign _2029 = ~ _2028;
    assign _2021 = t1_rx_level == _473;
    assign _2022 = ~ _2021;
    assign _2017 = 7'b1011001;
    assign _2018 = _326 == _2017;
    assign _2014 = _325[7:7];
    assign _2015 = ~ _2014;
    assign _2016 = _1275 & _2015;
    assign _2019 = _2016 & _2018;
    assign _2023 = _2019 & _2022;
    assign _51 = _2023;
    assign _2030 = _51 & _2029;
    assign _2034 = _2030 | _2033;
    assign _2038 = _2034 & _2037;
    assign _2041 = _2038 ? _2040 : t1_rx_rd;
    assign _52 = _2041;
    always @(posedge _146) begin
        if (_144)
            t1_rx_rd <= _4480;
        else
            t1_rx_rd <= _52;
    end
    always @* begin
        case (t1_rx_rd)
        0:
            _511 <= t1_rx_mem_0;
        1:
            _511 <= t1_rx_mem_1;
        2:
            _511 <= t1_rx_mem_2;
        default:
            _511 <= t1_rx_mem_3;
        endcase
    end
    assign _401 = t0_rx_wr == _874;
    assign _402 = _378 & _401;
    always @(posedge _146) begin
        if (_144)
            t0_rx_mem_3 <= _312;
        else
            if (_402)
                t0_rx_mem_3 <= _87;
    end
    assign _395 = t0_rx_wr == _234;
    assign _396 = _378 & _395;
    always @(posedge _146) begin
        if (_144)
            t0_rx_mem_2 <= _312;
        else
            if (_396)
                t0_rx_mem_2 <= _87;
    end
    assign _389 = t0_rx_wr == _231;
    assign _390 = _378 & _389;
    always @(posedge _146) begin
        if (_144)
            t0_rx_mem_1 <= _312;
        else
            if (_390)
                t0_rx_mem_1 <= _87;
    end
    assign _2043 = t0_rx_wr + _231;
    assign _2044 = _378 ? _2043 : t0_rx_wr;
    assign _53 = _2044;
    always @(posedge _146) begin
        if (_144)
            t0_rx_wr <= _4480;
        else
            t0_rx_wr <= _53;
    end
    assign _383 = t0_rx_wr == _4480;
    assign _384 = _378 & _383;
    assign _3720 = _3719[15:0];
    assign _3722 = { _3720,
                     _312 };
    assign _3716 = _3715[23:0];
    assign _3718 = { _3716,
                     _576 };
    assign _3712 = _3711[27:0];
    assign _3714 = { _3712,
                     _655 };
    assign _3708 = _3707[29:0];
    assign _3710 = { _3708,
                     _4480 };
    assign _3704 = _3601[0:0];
    assign _3707 = _3704 ? _1991 : _1990;
    assign _3703 = _3601[1:1];
    assign _3711 = _3703 ? _3710 : _3707;
    assign _3702 = _3601[2:2];
    assign _3715 = _3702 ? _3714 : _3711;
    assign _3701 = _3601[3:3];
    assign _3719 = _3701 ? _3718 : _3715;
    assign _3700 = _3601[4:4];
    assign _3723 = _3700 ? _3722 : _3719;
    assign _3724 = _3723[15:0];
    assign _3725 = ~ _3724;
    assign _3726 = _3574 & _3725;
    assign _3696 = _3694[31:16];
    assign _3697 = { _312,
                     _3696 };
    assign _3692 = _3690[31:8];
    assign _3693 = { _576,
                     _3692 };
    assign _3688 = _3686[31:4];
    assign _3689 = { _655,
                     _3688 };
    assign _3684 = _3682[31:2];
    assign _3685 = { _4480,
                     _3684 };
    assign _3680 = _3678[31:1];
    assign _3681 = { _606,
                     _3680 };
    assign _3678 = { _312,
                     _3574 };
    assign _3676 = _3671[0:0];
    assign _3682 = _3676 ? _3681 : _3678;
    assign _3675 = _3671[1:1];
    assign _3686 = _3675 ? _3685 : _3682;
    assign _3674 = _3671[2:2];
    assign _3690 = _3674 ? _3689 : _3686;
    assign _3673 = _3671[3:3];
    assign _3694 = _3673 ? _3693 : _3690;
    assign _3671 = _1012 - _3601;
    assign _3672 = _3671[4:4];
    assign _3698 = _3672 ? _3697 : _3694;
    assign _3699 = _3698[15:0];
    assign _3727 = _980 ? _3726 : _3699;
    assign _3662 = _3661[15:0];
    assign _3664 = { _3662,
                     _312 };
    assign _3658 = _3657[23:0];
    assign _3660 = { _3658,
                     _576 };
    assign _3654 = _3653[27:0];
    assign _3656 = { _3654,
                     _655 };
    assign _3650 = _3649[29:0];
    assign _3652 = { _3650,
                     _4480 };
    assign _3646 = t0_isr_count[0:0];
    assign _3649 = _3646 ? _1991 : _1990;
    assign _3645 = t0_isr_count[1:1];
    assign _3653 = _3645 ? _3652 : _3649;
    assign _3644 = t0_isr_count[2:2];
    assign _3657 = _3644 ? _3656 : _3653;
    assign _3643 = t0_isr_count[3:3];
    assign _3661 = _3643 ? _3660 : _3657;
    assign _3642 = t0_isr_count[4:4];
    assign _3665 = _3642 ? _3664 : _3661;
    assign _3666 = _3665[15:0];
    assign _3667 = ~ _3666;
    assign _3668 = t0_isr & _3667;
    assign _3638 = _3636[31:16];
    assign _3639 = { _312,
                     _3638 };
    assign _3634 = _3632[31:8];
    assign _3635 = { _576,
                     _3634 };
    assign _3630 = _3628[31:4];
    assign _3631 = { _655,
                     _3630 };
    assign _3626 = _3624[31:2];
    assign _3627 = { _4480,
                     _3626 };
    assign _3622 = _3620[31:1];
    assign _3623 = { _606,
                     _3622 };
    assign _1005 = _1004[15:0];
    assign _1007 = { _1005,
                     _312 };
    assign _1001 = _1000[23:0];
    assign _1003 = { _1001,
                     _576 };
    assign _997 = _996[27:0];
    assign _999 = { _997,
                    _655 };
    assign _993 = _992[29:0];
    assign _995 = { _993,
                    _4480 };
    assign _989 = _857[0:0];
    assign _992 = _989 ? _1991 : _1990;
    assign _988 = _857[1:1];
    assign _996 = _988 ? _995 : _992;
    assign _987 = _857[2:2];
    assign _1000 = _987 ? _999 : _996;
    assign _986 = _857[3:3];
    assign _1004 = _986 ? _1003 : _1000;
    assign _985 = _857[4:4];
    assign _1008 = _985 ? _1007 : _1004;
    assign _1009 = _1008[15:0];
    assign _1010 = ~ _1009;
    assign _3572 = _1164 & _1010;
    assign _3567 = _3566[15:0];
    assign _3569 = { _3567,
                     _312 };
    assign _3563 = _3562[23:0];
    assign _3565 = { _3563,
                     _576 };
    assign _3559 = _3558[27:0];
    assign _3561 = { _3559,
                     _655 };
    assign _3555 = _3554[29:0];
    assign _3557 = { _3555,
                     _4480 };
    assign _3551 = _3550[30:0];
    assign _3553 = { _3551,
                     _606 };
    assign _3550 = { _312,
                     t0_isr };
    assign _3548 = _857[0:0];
    assign _3554 = _3548 ? _3553 : _3550;
    assign _3547 = _857[1:1];
    assign _3558 = _3547 ? _3557 : _3554;
    assign _3546 = _857[2:2];
    assign _3562 = _3546 ? _3561 : _3558;
    assign _3545 = _857[3:3];
    assign _3566 = _3545 ? _3565 : _3562;
    assign _3544 = _857[4:4];
    assign _3570 = _3544 ? _3569 : _3566;
    assign _3571 = _3570[15:0];
    assign _3573 = _3571 | _3572;
    assign _3540 = _3538[31:16];
    assign _3541 = { _312,
                     _3540 };
    assign _3536 = _3534[31:8];
    assign _3537 = { _576,
                     _3536 };
    assign _3532 = _3530[31:4];
    assign _3533 = { _655,
                     _3532 };
    assign _3528 = _3526[31:2];
    assign _3529 = { _4480,
                     _3528 };
    assign _3524 = _3522[31:1];
    assign _3525 = { _606,
                     _3524 };
    assign _1153 = _838 < _857;
    assign _1150 = _792[7:7];
    assign _1149 = _792[6:6];
    assign _1148 = _792[5:5];
    assign _1147 = _792[4:4];
    assign _1146 = _792[3:3];
    assign _1145 = _792[2:2];
    assign _1144 = _792[1:1];
    assign _1143 = _792[0:0];
    always @* begin
        case (cfg_t0_in_base)
        0:
            _1151 <= _1143;
        1:
            _1151 <= _1144;
        2:
            _1151 <= _1145;
        3:
            _1151 <= _1146;
        4:
            _1151 <= _1147;
        5:
            _1151 <= _1148;
        6:
            _1151 <= _1149;
        default:
            _1151 <= _1150;
        endcase
    end
    assign _1154 = _1151 & _1153;
    assign _1141 = _1168 < _857;
    assign _1138 = _792[7:7];
    assign _1137 = _792[6:6];
    assign _1136 = _792[5:5];
    assign _1135 = _792[4:4];
    assign _1134 = _792[3:3];
    assign _1133 = _792[2:2];
    assign _1132 = _792[1:1];
    assign _1131 = _792[0:0];
    assign _1130 = cfg_t0_in_base + _659;
    always @* begin
        case (_1130)
        0:
            _1139 <= _1131;
        1:
            _1139 <= _1132;
        2:
            _1139 <= _1133;
        3:
            _1139 <= _1134;
        4:
            _1139 <= _1135;
        5:
            _1139 <= _1136;
        6:
            _1139 <= _1137;
        default:
            _1139 <= _1138;
        endcase
    end
    assign _1142 = _1139 & _1141;
    assign _1127 = _1651 < _857;
    assign _1124 = _792[7:7];
    assign _1123 = _792[6:6];
    assign _1122 = _792[5:5];
    assign _1121 = _792[4:4];
    assign _1120 = _792[3:3];
    assign _1119 = _792[2:2];
    assign _1118 = _792[1:1];
    assign _1117 = _792[0:0];
    assign _1116 = cfg_t0_in_base + _4345;
    always @* begin
        case (_1116)
        0:
            _1125 <= _1117;
        1:
            _1125 <= _1118;
        2:
            _1125 <= _1119;
        3:
            _1125 <= _1120;
        4:
            _1125 <= _1121;
        5:
            _1125 <= _1122;
        6:
            _1125 <= _1123;
        default:
            _1125 <= _1124;
        endcase
    end
    assign _1128 = _1125 & _1127;
    assign _1113 = _1637 < _857;
    assign _1110 = _792[7:7];
    assign _1109 = _792[6:6];
    assign _1108 = _792[5:5];
    assign _1107 = _792[4:4];
    assign _1106 = _792[3:3];
    assign _1105 = _792[2:2];
    assign _1104 = _792[1:1];
    assign _1103 = _792[0:0];
    assign _1102 = cfg_t0_in_base + _965;
    always @* begin
        case (_1102)
        0:
            _1111 <= _1103;
        1:
            _1111 <= _1104;
        2:
            _1111 <= _1105;
        3:
            _1111 <= _1106;
        4:
            _1111 <= _1107;
        5:
            _1111 <= _1108;
        6:
            _1111 <= _1109;
        default:
            _1111 <= _1110;
        endcase
    end
    assign _1114 = _1111 & _1113;
    assign _1099 = _1623 < _857;
    assign _1096 = _792[7:7];
    assign _1095 = _792[6:6];
    assign _1094 = _792[5:5];
    assign _1093 = _792[4:4];
    assign _1092 = _792[3:3];
    assign _1091 = _792[2:2];
    assign _1090 = _792[1:1];
    assign _1089 = _792[0:0];
    assign _1088 = cfg_t0_in_base + _4489;
    always @* begin
        case (_1088)
        0:
            _1097 <= _1089;
        1:
            _1097 <= _1090;
        2:
            _1097 <= _1091;
        3:
            _1097 <= _1092;
        4:
            _1097 <= _1093;
        5:
            _1097 <= _1094;
        6:
            _1097 <= _1095;
        default:
            _1097 <= _1096;
        endcase
    end
    assign _1100 = _1097 & _1099;
    assign _1085 = _1609 < _857;
    assign _1082 = _792[7:7];
    assign _1081 = _792[6:6];
    assign _1080 = _792[5:5];
    assign _1079 = _792[4:4];
    assign _1078 = _792[3:3];
    assign _1077 = _792[2:2];
    assign _1076 = _792[1:1];
    assign _1075 = _792[0:0];
    assign _1074 = cfg_t0_in_base + _1598;
    always @* begin
        case (_1074)
        0:
            _1083 <= _1075;
        1:
            _1083 <= _1076;
        2:
            _1083 <= _1077;
        3:
            _1083 <= _1078;
        4:
            _1083 <= _1079;
        5:
            _1083 <= _1080;
        6:
            _1083 <= _1081;
        default:
            _1083 <= _1082;
        endcase
    end
    assign _1086 = _1083 & _1085;
    assign _1071 = _1595 < _857;
    assign _1068 = _792[7:7];
    assign _1067 = _792[6:6];
    assign _1066 = _792[5:5];
    assign _1065 = _792[4:4];
    assign _1064 = _792[3:3];
    assign _1063 = _792[2:2];
    assign _1062 = _792[1:1];
    assign _1061 = _792[0:0];
    assign _1060 = cfg_t0_in_base + _951;
    always @* begin
        case (_1060)
        0:
            _1069 <= _1061;
        1:
            _1069 <= _1062;
        2:
            _1069 <= _1063;
        3:
            _1069 <= _1064;
        4:
            _1069 <= _1065;
        5:
            _1069 <= _1066;
        6:
            _1069 <= _1067;
        default:
            _1069 <= _1068;
        endcase
    end
    assign _1072 = _1069 & _1071;
    assign _1057 = _1581 < _857;
    assign _1054 = _792[7:7];
    assign _1053 = _792[6:6];
    assign _1052 = _792[5:5];
    assign _1051 = _792[4:4];
    assign _1050 = _792[3:3];
    assign _1049 = _792[2:2];
    assign _1048 = _792[1:1];
    assign _788 = _787 & _786;
    assign _787 = pin_out[0:0];
    assign _786 = _681[0:0];
    assign _785 = cfg_pin_modes[1:0];
    always @* begin
        case (_785)
        0:
            _789 <= _786;
        1:
            _789 <= _787;
        2:
            _789 <= _788;
        default:
            _789 <= _786;
        endcase
    end
    assign _783 = _778 == _1570;
    assign _784 = _662 & _783;
    assign _790 = _784 ? smp_strobe : _789;
    assign _778 = _663 + _664;
    assign _780 = _778 == _473;
    assign _781 = _662 & _780;
    assign _791 = _781 ? smp_data : _790;
    assign _774 = _773 & _772;
    assign _773 = pin_out[1:1];
    assign _772 = _681[1:1];
    assign _771 = cfg_pin_modes[3:2];
    always @* begin
        case (_771)
        0:
            _775 <= _772;
        1:
            _775 <= _773;
        2:
            _775 <= _774;
        default:
            _775 <= _772;
        endcase
    end
    assign _769 = _764 == _473;
    assign _770 = _662 & _769;
    assign _776 = _770 ? smp_strobe : _775;
    assign _764 = _663 + _664;
    assign _766 = _764 == _659;
    assign _767 = _662 & _766;
    assign _777 = _767 ? smp_data : _776;
    assign _760 = _759 & _758;
    assign _759 = pin_out[2:2];
    assign _758 = _681[2:2];
    assign _757 = cfg_pin_modes[5:4];
    always @* begin
        case (_757)
        0:
            _761 <= _758;
        1:
            _761 <= _759;
        2:
            _761 <= _760;
        default:
            _761 <= _758;
        endcase
    end
    assign _755 = _750 == _659;
    assign _756 = _662 & _755;
    assign _762 = _756 ? smp_strobe : _761;
    assign _750 = _663 + _664;
    assign _752 = _750 == _4345;
    assign _753 = _662 & _752;
    assign _763 = _753 ? smp_data : _762;
    assign _746 = _745 & _744;
    assign _745 = pin_out[3:3];
    assign _744 = _681[3:3];
    assign _743 = cfg_pin_modes[7:6];
    always @* begin
        case (_743)
        0:
            _747 <= _744;
        1:
            _747 <= _745;
        2:
            _747 <= _746;
        default:
            _747 <= _744;
        endcase
    end
    assign _741 = _736 == _4345;
    assign _742 = _662 & _741;
    assign _748 = _742 ? smp_strobe : _747;
    assign _736 = _663 + _664;
    assign _738 = _736 == _965;
    assign _739 = _662 & _738;
    assign _749 = _739 ? smp_data : _748;
    assign _732 = _731 & _730;
    assign _731 = pin_out[4:4];
    assign _730 = _681[4:4];
    assign _729 = cfg_pin_modes[9:8];
    always @* begin
        case (_729)
        0:
            _733 <= _730;
        1:
            _733 <= _731;
        2:
            _733 <= _732;
        default:
            _733 <= _730;
        endcase
    end
    assign _727 = _722 == _965;
    assign _728 = _662 & _727;
    assign _734 = _728 ? smp_strobe : _733;
    assign _722 = _663 + _664;
    assign _724 = _722 == _4489;
    assign _725 = _662 & _724;
    assign _735 = _725 ? smp_data : _734;
    assign _718 = _717 & _716;
    assign _717 = pin_out[5:5];
    assign _716 = _681[5:5];
    assign _715 = cfg_pin_modes[11:10];
    always @* begin
        case (_715)
        0:
            _719 <= _716;
        1:
            _719 <= _717;
        2:
            _719 <= _718;
        default:
            _719 <= _716;
        endcase
    end
    assign _713 = _708 == _4489;
    assign _714 = _662 & _713;
    assign _720 = _714 ? smp_strobe : _719;
    assign _708 = _663 + _664;
    assign _710 = _708 == _1598;
    assign _711 = _662 & _710;
    assign _721 = _711 ? smp_data : _720;
    assign _704 = _703 & _702;
    assign _703 = pin_out[6:6];
    assign _702 = _681[6:6];
    assign _701 = cfg_pin_modes[13:12];
    always @* begin
        case (_701)
        0:
            _705 <= _702;
        1:
            _705 <= _703;
        2:
            _705 <= _704;
        default:
            _705 <= _702;
        endcase
    end
    assign _699 = _694 == _1598;
    assign _700 = _662 & _699;
    assign _706 = _700 ? smp_strobe : _705;
    assign _694 = _663 + _664;
    assign _696 = _694 == _951;
    assign _697 = _662 & _696;
    assign _707 = _697 ? smp_data : _706;
    assign _2209 = _2208 ? _2202 : smp_data;
    assign _2202 = _2201 ? _2148 : smp_data;
    assign _2203 = _2198 ? _2167 : _2202;
    assign _2210 = _2049 ? _2209 : _2203;
    assign _2211 = _662 ? _2210 : _606;
    assign _54 = _2211;
    always @(posedge _146) begin
        if (_144)
            smp_data <= _606;
        else
            smp_data <= _54;
    end
    assign _2298 = _2208 ? _2201 : smp_strobe;
    assign _2196 = ~ _2195;
    assign _2197 = _2194 | _2196;
    assign _2198 = _2175 & _2197;
    assign _2195 = cfg_smp_ctrl[5:5];
    assign _2199 = ~ _2195;
    assign _2235 = _2208 ? _2194 : smp_synced;
    assign _2231 = _2224 == cfg_smp_sync;
    assign _2232 = _2175 & _2231;
    assign _2216 = _622[7:0];
    assign _2213 = 7'b1101110;
    assign _2214 = _618 == _2213;
    assign _2212 = _612 & _616;
    assign _2215 = _2212 & _2214;
    assign _2217 = _2215 ? _2216 : cfg_smp_sync;
    assign _55 = _2217;
    always @(posedge _146) begin
        if (_144)
            cfg_smp_sync <= _576;
        else
            cfg_smp_sync <= _55;
    end
    assign _2227 = _2208 ? _2222 : smp_history;
    assign _2223 = _2222[7:1];
    assign _2224 = { _2167,
                     _2223 };
    assign _2221 = _2185 ? _2190 : smp_history;
    assign _2222 = _2111 ? _2221 : _576;
    assign _2172 = ~ _2171;
    assign _2165 = _2163 == _2164;
    assign _2138 = _2136 == _473;
    assign _2139 = ~ _2138;
    assign _2140 = _2135 & _2139;
    assign _2166 = _2140 & _2165;
    assign _2173 = _2166 & _2172;
    assign _2174 = ~ _2173;
    assign _2175 = _2135 & _2174;
    assign _2225 = _2175 ? _2224 : _2222;
    assign _2226 = _2126 ? _2225 : _576;
    assign _2228 = _2049 ? _2227 : _2226;
    assign _2229 = _662 ? _2228 : _576;
    assign _56 = _2229;
    always @(posedge _146) begin
        if (_144)
            smp_history <= _576;
        else
            smp_history <= _56;
    end
    assign _2189 = smp_history[7:1];
    assign _2190 = { _2148,
                     _2189 };
    assign _2191 = _2190 == cfg_smp_sync;
    assign _2192 = _2185 & _2191;
    assign _2193 = smp_synced | _2192;
    assign _2194 = _2111 & _2193;
    assign _2233 = _2194 | _2232;
    assign _2234 = _2126 & _2233;
    assign _2236 = _2049 ? _2235 : _2234;
    assign _2237 = _662 ? _2236 : _606;
    assign _57 = _2237;
    always @(posedge _146) begin
        if (_144)
            smp_synced <= _606;
        else
            smp_synced <= _57;
    end
    assign _2200 = smp_synced | _2199;
    assign _2182 = ~ _2153;
    assign _2255 = _2208 ? _2163 : smp_run;
    assign _2250 = _2163 + _4409;
    assign _2164 = { gnd,
                     _2136 };
    assign _2247 = _2164 < _2163;
    assign _2248 = ~ _2247;
    assign _2251 = _2248 ? _2250 : _2163;
    assign _2170 = _2167 ^ _2169;
    assign _2171 = ~ _2170;
    assign _2252 = _2171 ? _2251 : _4409;
    assign _2159 = smp_run + _4409;
    assign _2155 = { gnd,
                     _2136 };
    assign _2156 = _2155 < smp_run;
    assign _2157 = ~ _2156;
    assign _2160 = _2157 ? _2159 : smp_run;
    assign _2241 = _2208 ? _2169 : smp_slevel;
    assign _2167 = smp_mid ^ _2147;
    assign _2168 = _2143 ? _2148 : smp_slevel;
    assign _2169 = _2111 & _2168;
    assign _2239 = _2135 ? _2167 : _2169;
    assign _2240 = _2126 & _2239;
    assign _2242 = _2049 ? _2241 : _2240;
    assign _2243 = _662 ? _2242 : _606;
    assign _58 = _2243;
    always @(posedge _146) begin
        if (_144)
            smp_slevel <= _606;
        else
            smp_slevel <= _58;
    end
    assign _2147 = cfg_smp_ctrl[4:4];
    assign _2148 = _2073 ^ _2147;
    assign _2152 = _2148 ^ smp_slevel;
    assign _2153 = ~ _2152;
    assign _2161 = _2153 ? _2160 : _4409;
    assign _2162 = _2143 ? _2161 : smp_run;
    assign _2163 = _2111 ? _2162 : _655;
    assign _2134 = _2132 == _2133;
    assign _2135 = _2126 & _2134;
    assign _2253 = _2135 ? _2252 : _2163;
    assign _2254 = _2126 ? _2253 : _655;
    assign _2256 = _2049 ? _2255 : _2254;
    assign _2257 = _662 ? _2256 : _655;
    assign _59 = _2257;
    always @(posedge _146) begin
        if (_144)
            smp_run <= _655;
        else
            smp_run <= _59;
    end
    assign _2180 = smp_run == _2155;
    assign _2136 = cfg_smp_pre[15:13];
    assign _2177 = _2136 == _473;
    assign _2178 = ~ _2177;
    assign _2179 = _2143 & _2178;
    assign _2181 = _2179 & _2180;
    assign _2183 = _2181 & _2182;
    assign _2184 = ~ _2183;
    assign _2133 = cfg_smp_time[9:5];
    assign _2142 = _2104 == _2133;
    assign _2110 = _2088 ? _2098 : smp_carrier;
    assign _2280 = _2208 ? _2104 : smp_phase;
    assign _2129 = _2104 + _1168;
    assign _2130 = _2109 ? _2104 : _2129;
    assign _2082 = cfg_smp_time[4:0];
    assign _2101 = smp_phase + _1168;
    assign _2102 = _2088 ? smp_phase : _2101;
    assign _2096 = smp_missed < _2090;
    assign _2097 = _2092 | _2096;
    assign _2270 = _2208 ? _2111 : smp_carrier;
    assign _2118 = smp_missed + _659;
    assign _2266 = _2208 ? _2121 : smp_missed;
    assign _2262 = _2121 + _659;
    assign _2259 = ~ _2114;
    assign _2260 = _2124 & _2259;
    assign _2263 = _2260 ? _2262 : _2121;
    assign _2265 = _2107 ? _473 : _2263;
    assign _2267 = _2049 ? _2266 : _2265;
    assign _2268 = _662 ? _2267 : _473;
    assign _60 = _2268;
    always @(posedge _146) begin
        if (_144)
            smp_missed <= _473;
        else
            smp_missed <= _60;
    end
    assign _2092 = _2090 == _1570;
    assign _2115 = ~ _2092;
    assign _2116 = _2098 & _2115;
    assign _2119 = _2116 ? _2118 : smp_missed;
    assign _2121 = _2085 ? _473 : _2119;
    assign _2122 = _2121 < _2090;
    assign _2090 = cfg_smp_ctrl[8:6];
    assign _2114 = _2090 == _1570;
    assign _2123 = _2114 | _2122;
    assign _2112 = _2109 & _2111;
    assign _2124 = _2112 & _2123;
    assign _2108 = _2104 < _2086;
    assign _2109 = ~ _2108;
    assign _2125 = _2109 ? _2124 : _2111;
    assign _2126 = _2107 | _2125;
    assign _2271 = _2049 ? _2270 : _2126;
    assign _2272 = _662 ? _2271 : _606;
    assign _61 = _2272;
    always @(posedge _146) begin
        if (_144)
            smp_carrier <= _606;
        else
            smp_carrier <= _61;
    end
    assign _573 = 15'b000000000000000;
    assign _2277 = _622[14:0];
    assign _2274 = 7'b1101101;
    assign _2275 = _618 == _2274;
    assign _2273 = _612 & _616;
    assign _2276 = _2273 & _2275;
    assign _2278 = _2276 ? _2277 : cfg_smp_time;
    assign _62 = _2278;
    always @(posedge _146) begin
        if (_144)
            cfg_smp_time <= _573;
        else
            cfg_smp_time <= _62;
    end
    assign _2086 = cfg_smp_time[14:10];
    assign _2087 = smp_phase < _2086;
    assign _2088 = ~ _2087;
    assign _2089 = _2088 & smp_carrier;
    assign _2098 = _2089 & _2097;
    assign _2099 = _2085 | _2098;
    assign _2104 = _2099 ? _838 : _2102;
    assign _2105 = _2104 < _2082;
    assign _2106 = ~ _2105;
    assign _2074 = smp_mid ^ _2073;
    assign _2107 = _2074 & _2106;
    assign _2127 = _2107 | _2124;
    assign _2132 = _2127 ? _838 : _2130;
    assign _2281 = _2049 ? _2280 : _2132;
    assign _2282 = _662 ? _2281 : _838;
    assign _63 = _2282;
    always @(posedge _146) begin
        if (_144)
            smp_phase <= _838;
        else
            smp_phase <= _63;
    end
    assign _2083 = smp_phase < _2082;
    assign _2084 = ~ _2083;
    assign _2286 = smp_pre + _4130;
    assign _2287 = _2286 < _2046;
    assign _2288 = ~ _2287;
    assign _2290 = _2288 ? _532 : _2286;
    assign _2291 = _2049 ? _2290 : _532;
    assign _2292 = _662 ? _2291 : _532;
    assign _64 = _2292;
    always @(posedge _146) begin
        if (_144)
            smp_pre <= _532;
        else
            smp_pre <= _64;
    end
    assign _2208 = smp_pre == _532;
    assign _2294 = _2208 ? _2073 : smp_last;
    assign _2057 = _78[7:7];
    assign _2056 = _78[6:6];
    assign _2055 = _78[5:5];
    assign _2054 = _78[4:4];
    assign _2053 = _78[3:3];
    assign _2052 = _78[2:2];
    assign _2051 = _78[1:1];
    assign _2050 = _78[0:0];
    always @* begin
        case (_663)
        0:
            _2058 <= _2050;
        1:
            _2058 <= _2051;
        2:
            _2058 <= _2052;
        3:
            _2058 <= _2053;
        4:
            _2058 <= _2054;
        5:
            _2058 <= _2055;
        6:
            _2058 <= _2056;
        default:
            _2058 <= _2057;
        endcase
    end
    always @(negedge _146) begin
        if (_144)
            smp_fall <= _606;
        else
            smp_fall <= _2058;
    end
    always @(posedge _146) begin
        if (_144)
            smp_mid <= _606;
        else
            smp_mid <= smp_fall;
    end
    assign _2295 = _2049 ? _2294 : smp_mid;
    assign _2296 = _662 ? _2295 : _606;
    assign _65 = _2296;
    always @(posedge _146) begin
        if (_144)
            smp_last <= _606;
        else
            smp_last <= _65;
    end
    assign _2072 = pins_sync2[7:7];
    assign _2071 = pins_sync2[6:6];
    assign _2070 = pins_sync2[5:5];
    assign _2069 = pins_sync2[4:4];
    assign _2068 = pins_sync2[3:3];
    assign _2067 = pins_sync2[2:2];
    assign _2066 = pins_sync2[1:1];
    assign _2065 = pins_sync2[0:0];
    always @* begin
        case (_663)
        0:
            _2073 <= _2065;
        1:
            _2073 <= _2066;
        2:
            _2073 <= _2067;
        3:
            _2073 <= _2068;
        4:
            _2073 <= _2069;
        5:
            _2073 <= _2070;
        6:
            _2073 <= _2071;
        default:
            _2073 <= _2072;
        endcase
    end
    assign _2078 = _2073 ^ smp_last;
    assign _2085 = _2078 & _2084;
    assign _2111 = _2085 | _2110;
    assign _2143 = _2111 & _2142;
    assign _2185 = _2143 & _2184;
    assign _2201 = _2185 & _2200;
    assign _2297 = _2201 | _2198;
    assign _2046 = cfg_smp_pre[9:0];
    assign _2048 = _2046 == _532;
    assign _2049 = ~ _2048;
    assign _2299 = _2049 ? _2298 : _2297;
    assign _2300 = _662 & _2299;
    assign _66 = _2300;
    always @(posedge _146) begin
        if (_144)
            smp_strobe <= _606;
        else
            smp_strobe <= _66;
    end
    assign _684 = _683 & _682;
    assign _164 = 8'b11111111;
    assign _3469 = _3342[7:7];
    assign _3468 = _3342[6:6];
    assign _3467 = _3342[5:5];
    assign _3466 = _3342[4:4];
    assign _3465 = _3342[3:3];
    assign _3464 = _3342[2:2];
    assign _3463 = _3342[1:1];
    assign _3462 = _3342[0:0];
    always @* begin
        case (_3456)
        0:
            _3470 <= _3462;
        1:
            _3470 <= _3463;
        2:
            _3470 <= _3464;
        3:
            _3470 <= _3465;
        4:
            _3470 <= _3466;
        5:
            _3470 <= _3467;
        6:
            _3470 <= _3468;
        default:
            _3470 <= _3469;
        endcase
    end
    assign _3461 = _3322[0:0];
    assign _3459 = { _4480,
                     _2919 };
    assign _3456 = _473 - _2915;
    assign _3457 = { gnd,
                     _3456 };
    assign _3460 = _3457 < _3459;
    assign _3471 = _3460 ? _3470 : _3461;
    assign _3452 = _3342[7:7];
    assign _3451 = _3342[6:6];
    assign _3450 = _3342[5:5];
    assign _3449 = _3342[4:4];
    assign _3448 = _3342[3:3];
    assign _3447 = _3342[2:2];
    assign _3446 = _3342[1:1];
    assign _3445 = _3342[0:0];
    always @* begin
        case (_3439)
        0:
            _3453 <= _3445;
        1:
            _3453 <= _3446;
        2:
            _3453 <= _3447;
        3:
            _3453 <= _3448;
        4:
            _3453 <= _3449;
        5:
            _3453 <= _3450;
        6:
            _3453 <= _3451;
        default:
            _3453 <= _3452;
        endcase
    end
    assign _3444 = _3322[1:1];
    assign _3442 = { _4480,
                     _2919 };
    assign _3439 = _659 - _2915;
    assign _3440 = { gnd,
                     _3439 };
    assign _3443 = _3440 < _3442;
    assign _3454 = _3443 ? _3453 : _3444;
    assign _3435 = _3342[7:7];
    assign _3434 = _3342[6:6];
    assign _3433 = _3342[5:5];
    assign _3432 = _3342[4:4];
    assign _3431 = _3342[3:3];
    assign _3430 = _3342[2:2];
    assign _3429 = _3342[1:1];
    assign _3428 = _3342[0:0];
    always @* begin
        case (_3422)
        0:
            _3436 <= _3428;
        1:
            _3436 <= _3429;
        2:
            _3436 <= _3430;
        3:
            _3436 <= _3431;
        4:
            _3436 <= _3432;
        5:
            _3436 <= _3433;
        6:
            _3436 <= _3434;
        default:
            _3436 <= _3435;
        endcase
    end
    assign _3427 = _3322[2:2];
    assign _3425 = { _4480,
                     _2919 };
    assign _3422 = _4345 - _2915;
    assign _3423 = { gnd,
                     _3422 };
    assign _3426 = _3423 < _3425;
    assign _3437 = _3426 ? _3436 : _3427;
    assign _3418 = _3342[7:7];
    assign _3417 = _3342[6:6];
    assign _3416 = _3342[5:5];
    assign _3415 = _3342[4:4];
    assign _3414 = _3342[3:3];
    assign _3413 = _3342[2:2];
    assign _3412 = _3342[1:1];
    assign _3411 = _3342[0:0];
    always @* begin
        case (_3405)
        0:
            _3419 <= _3411;
        1:
            _3419 <= _3412;
        2:
            _3419 <= _3413;
        3:
            _3419 <= _3414;
        4:
            _3419 <= _3415;
        5:
            _3419 <= _3416;
        6:
            _3419 <= _3417;
        default:
            _3419 <= _3418;
        endcase
    end
    assign _3410 = _3322[3:3];
    assign _3408 = { _4480,
                     _2919 };
    assign _3405 = _965 - _2915;
    assign _3406 = { gnd,
                     _3405 };
    assign _3409 = _3406 < _3408;
    assign _3420 = _3409 ? _3419 : _3410;
    assign _3401 = _3342[7:7];
    assign _3400 = _3342[6:6];
    assign _3399 = _3342[5:5];
    assign _3398 = _3342[4:4];
    assign _3397 = _3342[3:3];
    assign _3396 = _3342[2:2];
    assign _3395 = _3342[1:1];
    assign _3394 = _3342[0:0];
    always @* begin
        case (_3388)
        0:
            _3402 <= _3394;
        1:
            _3402 <= _3395;
        2:
            _3402 <= _3396;
        3:
            _3402 <= _3397;
        4:
            _3402 <= _3398;
        5:
            _3402 <= _3399;
        6:
            _3402 <= _3400;
        default:
            _3402 <= _3401;
        endcase
    end
    assign _3393 = _3322[4:4];
    assign _3391 = { _4480,
                     _2919 };
    assign _3388 = _4489 - _2915;
    assign _3389 = { gnd,
                     _3388 };
    assign _3392 = _3389 < _3391;
    assign _3403 = _3392 ? _3402 : _3393;
    assign _3384 = _3342[7:7];
    assign _3383 = _3342[6:6];
    assign _3382 = _3342[5:5];
    assign _3381 = _3342[4:4];
    assign _3380 = _3342[3:3];
    assign _3379 = _3342[2:2];
    assign _3378 = _3342[1:1];
    assign _3377 = _3342[0:0];
    always @* begin
        case (_3371)
        0:
            _3385 <= _3377;
        1:
            _3385 <= _3378;
        2:
            _3385 <= _3379;
        3:
            _3385 <= _3380;
        4:
            _3385 <= _3381;
        5:
            _3385 <= _3382;
        6:
            _3385 <= _3383;
        default:
            _3385 <= _3384;
        endcase
    end
    assign _3376 = _3322[5:5];
    assign _3374 = { _4480,
                     _2919 };
    assign _3371 = _1598 - _2915;
    assign _3372 = { gnd,
                     _3371 };
    assign _3375 = _3372 < _3374;
    assign _3386 = _3375 ? _3385 : _3376;
    assign _3367 = _3342[7:7];
    assign _3366 = _3342[6:6];
    assign _3365 = _3342[5:5];
    assign _3364 = _3342[4:4];
    assign _3363 = _3342[3:3];
    assign _3362 = _3342[2:2];
    assign _3361 = _3342[1:1];
    assign _3360 = _3342[0:0];
    always @* begin
        case (_3354)
        0:
            _3368 <= _3360;
        1:
            _3368 <= _3361;
        2:
            _3368 <= _3362;
        3:
            _3368 <= _3363;
        4:
            _3368 <= _3364;
        5:
            _3368 <= _3365;
        6:
            _3368 <= _3366;
        default:
            _3368 <= _3367;
        endcase
    end
    assign _3359 = _3322[6:6];
    assign _3357 = { _4480,
                     _2919 };
    assign _3354 = _951 - _2915;
    assign _3355 = { gnd,
                     _3354 };
    assign _3358 = _3355 < _3357;
    assign _3369 = _3358 ? _3368 : _3359;
    assign _3350 = _3342[7:7];
    assign _3349 = _3342[6:6];
    assign _3348 = _3342[5:5];
    assign _3347 = _3342[4:4];
    assign _3346 = _3342[3:3];
    assign _3345 = _3342[2:2];
    assign _3344 = _3342[1:1];
    assign _3337 = _3335[3:2];
    assign _3338 = { _4480,
                     _3337 };
    assign _3333 = _3331[3:1];
    assign _3334 = { _606,
                     _3333 };
    assign _3331 = _107[12:9];
    assign _3330 = _3327[0:0];
    assign _3335 = _3330 ? _3334 : _3331;
    assign _3329 = _3327[1:1];
    assign _3339 = _3329 ? _3338 : _3335;
    assign _3326 = { gnd,
                     _2919 };
    assign _3327 = _4489 - _3326;
    assign _3328 = _3327[2:2];
    assign _3341 = _3328 ? _655 : _3339;
    assign _3342 = { _655,
                     _3341 };
    assign _3343 = _3342[0:0];
    always @* begin
        case (_2916)
        0:
            _3351 <= _3343;
        1:
            _3351 <= _3344;
        2:
            _3351 <= _3345;
        3:
            _3351 <= _3346;
        4:
            _3351 <= _3347;
        5:
            _3351 <= _3348;
        6:
            _3351 <= _3349;
        default:
            _3351 <= _3350;
        endcase
    end
    assign _3318 = _1567[7:7];
    assign _3317 = _1567[6:6];
    assign _3316 = _1567[5:5];
    assign _3315 = _1567[4:4];
    assign _3314 = _1567[3:3];
    assign _3313 = _1567[2:2];
    assign _3312 = _1567[1:1];
    assign _3311 = _1567[0:0];
    always @* begin
        case (_3307)
        0:
            _3319 <= _3311;
        1:
            _3319 <= _3312;
        2:
            _3319 <= _3313;
        3:
            _3319 <= _3314;
        4:
            _3319 <= _3315;
        5:
            _3319 <= _3316;
        6:
            _3319 <= _3317;
        default:
            _3319 <= _3318;
        endcase
    end
    assign _3310 = _72[0:0];
    assign _3307 = _473 - _3070;
    assign _3308 = { _4480,
                     _3307 };
    assign _3309 = _3308 < _1382;
    assign _3320 = _3309 ? _3319 : _3310;
    assign _3302 = _1567[7:7];
    assign _3301 = _1567[6:6];
    assign _3300 = _1567[5:5];
    assign _3299 = _1567[4:4];
    assign _3298 = _1567[3:3];
    assign _3297 = _1567[2:2];
    assign _3296 = _1567[1:1];
    assign _3295 = _1567[0:0];
    always @* begin
        case (_3291)
        0:
            _3303 <= _3295;
        1:
            _3303 <= _3296;
        2:
            _3303 <= _3297;
        3:
            _3303 <= _3298;
        4:
            _3303 <= _3299;
        5:
            _3303 <= _3300;
        6:
            _3303 <= _3301;
        default:
            _3303 <= _3302;
        endcase
    end
    assign _3294 = _72[1:1];
    assign _3291 = _659 - _3070;
    assign _3292 = { _4480,
                     _3291 };
    assign _3293 = _3292 < _1382;
    assign _3304 = _3293 ? _3303 : _3294;
    assign _3286 = _1567[7:7];
    assign _3285 = _1567[6:6];
    assign _3284 = _1567[5:5];
    assign _3283 = _1567[4:4];
    assign _3282 = _1567[3:3];
    assign _3281 = _1567[2:2];
    assign _3280 = _1567[1:1];
    assign _3279 = _1567[0:0];
    always @* begin
        case (_3275)
        0:
            _3287 <= _3279;
        1:
            _3287 <= _3280;
        2:
            _3287 <= _3281;
        3:
            _3287 <= _3282;
        4:
            _3287 <= _3283;
        5:
            _3287 <= _3284;
        6:
            _3287 <= _3285;
        default:
            _3287 <= _3286;
        endcase
    end
    assign _3278 = _72[2:2];
    assign _3275 = _4345 - _3070;
    assign _3276 = { _4480,
                     _3275 };
    assign _3277 = _3276 < _1382;
    assign _3288 = _3277 ? _3287 : _3278;
    assign _3270 = _1567[7:7];
    assign _3269 = _1567[6:6];
    assign _3268 = _1567[5:5];
    assign _3267 = _1567[4:4];
    assign _3266 = _1567[3:3];
    assign _3265 = _1567[2:2];
    assign _3264 = _1567[1:1];
    assign _3263 = _1567[0:0];
    always @* begin
        case (_3259)
        0:
            _3271 <= _3263;
        1:
            _3271 <= _3264;
        2:
            _3271 <= _3265;
        3:
            _3271 <= _3266;
        4:
            _3271 <= _3267;
        5:
            _3271 <= _3268;
        6:
            _3271 <= _3269;
        default:
            _3271 <= _3270;
        endcase
    end
    assign _3262 = _72[3:3];
    assign _3259 = _965 - _3070;
    assign _3260 = { _4480,
                     _3259 };
    assign _3261 = _3260 < _1382;
    assign _3272 = _3261 ? _3271 : _3262;
    assign _3254 = _1567[7:7];
    assign _3253 = _1567[6:6];
    assign _3252 = _1567[5:5];
    assign _3251 = _1567[4:4];
    assign _3250 = _1567[3:3];
    assign _3249 = _1567[2:2];
    assign _3248 = _1567[1:1];
    assign _3247 = _1567[0:0];
    always @* begin
        case (_3243)
        0:
            _3255 <= _3247;
        1:
            _3255 <= _3248;
        2:
            _3255 <= _3249;
        3:
            _3255 <= _3250;
        4:
            _3255 <= _3251;
        5:
            _3255 <= _3252;
        6:
            _3255 <= _3253;
        default:
            _3255 <= _3254;
        endcase
    end
    assign _3246 = _72[4:4];
    assign _3243 = _4489 - _3070;
    assign _3244 = { _4480,
                     _3243 };
    assign _3245 = _3244 < _1382;
    assign _3256 = _3245 ? _3255 : _3246;
    assign _3238 = _1567[7:7];
    assign _3237 = _1567[6:6];
    assign _3236 = _1567[5:5];
    assign _3235 = _1567[4:4];
    assign _3234 = _1567[3:3];
    assign _3233 = _1567[2:2];
    assign _3232 = _1567[1:1];
    assign _3231 = _1567[0:0];
    always @* begin
        case (_3227)
        0:
            _3239 <= _3231;
        1:
            _3239 <= _3232;
        2:
            _3239 <= _3233;
        3:
            _3239 <= _3234;
        4:
            _3239 <= _3235;
        5:
            _3239 <= _3236;
        6:
            _3239 <= _3237;
        default:
            _3239 <= _3238;
        endcase
    end
    assign _3230 = _72[5:5];
    assign _3227 = _1598 - _3070;
    assign _3228 = { _4480,
                     _3227 };
    assign _3229 = _3228 < _1382;
    assign _3240 = _3229 ? _3239 : _3230;
    assign _3222 = _1567[7:7];
    assign _3221 = _1567[6:6];
    assign _3220 = _1567[5:5];
    assign _3219 = _1567[4:4];
    assign _3218 = _1567[3:3];
    assign _3217 = _1567[2:2];
    assign _3216 = _1567[1:1];
    assign _3215 = _1567[0:0];
    always @* begin
        case (_3211)
        0:
            _3223 <= _3215;
        1:
            _3223 <= _3216;
        2:
            _3223 <= _3217;
        3:
            _3223 <= _3218;
        4:
            _3223 <= _3219;
        5:
            _3223 <= _3220;
        6:
            _3223 <= _3221;
        default:
            _3223 <= _3222;
        endcase
    end
    assign _3214 = _72[6:6];
    assign _3211 = _951 - _3070;
    assign _3212 = { _4480,
                     _3211 };
    assign _3213 = _3212 < _1382;
    assign _3224 = _3213 ? _3223 : _3214;
    assign _3206 = _1567[7:7];
    assign _3205 = _1567[6:6];
    assign _3204 = _1567[5:5];
    assign _3203 = _1567[4:4];
    assign _3202 = _1567[3:3];
    assign _3201 = _1567[2:2];
    assign _3200 = _1567[1:1];
    assign _3199 = _1567[0:0];
    always @* begin
        case (_3195)
        0:
            _3207 <= _3199;
        1:
            _3207 <= _3200;
        2:
            _3207 <= _3201;
        3:
            _3207 <= _3202;
        4:
            _3207 <= _3203;
        5:
            _3207 <= _3204;
        6:
            _3207 <= _3205;
        default:
            _3207 <= _3206;
        endcase
    end
    assign _3198 = _72[7:7];
    assign _3195 = _1570 - _3070;
    assign _3196 = { _4480,
                     _3195 };
    assign _3197 = _3196 < _1382;
    assign _3208 = _3197 ? _3207 : _3198;
    assign _3321 = { _3208,
                     _3224,
                     _3240,
                     _3256,
                     _3272,
                     _3288,
                     _3304,
                     _3320 };
    assign _3188 = _1795[7:7];
    assign _3187 = _1795[6:6];
    assign _3186 = _1795[5:5];
    assign _3185 = _1795[4:4];
    assign _3184 = _1795[3:3];
    assign _3183 = _1795[2:2];
    assign _3182 = _1795[1:1];
    assign _3181 = _1795[0:0];
    always @* begin
        case (_3177)
        0:
            _3189 <= _3181;
        1:
            _3189 <= _3182;
        2:
            _3189 <= _3183;
        3:
            _3189 <= _3184;
        4:
            _3189 <= _3185;
        5:
            _3189 <= _3186;
        6:
            _3189 <= _3187;
        default:
            _3189 <= _3188;
        endcase
    end
    assign _3180 = _72[0:0];
    assign _3177 = _473 - _3070;
    assign _3178 = { gnd,
                     _3177 };
    assign _3179 = _3178 < _3073;
    assign _3190 = _3179 ? _3189 : _3180;
    assign _3173 = _1795[7:7];
    assign _3172 = _1795[6:6];
    assign _3171 = _1795[5:5];
    assign _3170 = _1795[4:4];
    assign _3169 = _1795[3:3];
    assign _3168 = _1795[2:2];
    assign _3167 = _1795[1:1];
    assign _3166 = _1795[0:0];
    always @* begin
        case (_3162)
        0:
            _3174 <= _3166;
        1:
            _3174 <= _3167;
        2:
            _3174 <= _3168;
        3:
            _3174 <= _3169;
        4:
            _3174 <= _3170;
        5:
            _3174 <= _3171;
        6:
            _3174 <= _3172;
        default:
            _3174 <= _3173;
        endcase
    end
    assign _3165 = _72[1:1];
    assign _3162 = _659 - _3070;
    assign _3163 = { gnd,
                     _3162 };
    assign _3164 = _3163 < _3073;
    assign _3175 = _3164 ? _3174 : _3165;
    assign _3158 = _1795[7:7];
    assign _3157 = _1795[6:6];
    assign _3156 = _1795[5:5];
    assign _3155 = _1795[4:4];
    assign _3154 = _1795[3:3];
    assign _3153 = _1795[2:2];
    assign _3152 = _1795[1:1];
    assign _3151 = _1795[0:0];
    always @* begin
        case (_3147)
        0:
            _3159 <= _3151;
        1:
            _3159 <= _3152;
        2:
            _3159 <= _3153;
        3:
            _3159 <= _3154;
        4:
            _3159 <= _3155;
        5:
            _3159 <= _3156;
        6:
            _3159 <= _3157;
        default:
            _3159 <= _3158;
        endcase
    end
    assign _3150 = _72[2:2];
    assign _3147 = _4345 - _3070;
    assign _3148 = { gnd,
                     _3147 };
    assign _3149 = _3148 < _3073;
    assign _3160 = _3149 ? _3159 : _3150;
    assign _3143 = _1795[7:7];
    assign _3142 = _1795[6:6];
    assign _3141 = _1795[5:5];
    assign _3140 = _1795[4:4];
    assign _3139 = _1795[3:3];
    assign _3138 = _1795[2:2];
    assign _3137 = _1795[1:1];
    assign _3136 = _1795[0:0];
    always @* begin
        case (_3132)
        0:
            _3144 <= _3136;
        1:
            _3144 <= _3137;
        2:
            _3144 <= _3138;
        3:
            _3144 <= _3139;
        4:
            _3144 <= _3140;
        5:
            _3144 <= _3141;
        6:
            _3144 <= _3142;
        default:
            _3144 <= _3143;
        endcase
    end
    assign _3135 = _72[3:3];
    assign _3132 = _965 - _3070;
    assign _3133 = { gnd,
                     _3132 };
    assign _3134 = _3133 < _3073;
    assign _3145 = _3134 ? _3144 : _3135;
    assign _3128 = _1795[7:7];
    assign _3127 = _1795[6:6];
    assign _3126 = _1795[5:5];
    assign _3125 = _1795[4:4];
    assign _3124 = _1795[3:3];
    assign _3123 = _1795[2:2];
    assign _3122 = _1795[1:1];
    assign _3121 = _1795[0:0];
    always @* begin
        case (_3117)
        0:
            _3129 <= _3121;
        1:
            _3129 <= _3122;
        2:
            _3129 <= _3123;
        3:
            _3129 <= _3124;
        4:
            _3129 <= _3125;
        5:
            _3129 <= _3126;
        6:
            _3129 <= _3127;
        default:
            _3129 <= _3128;
        endcase
    end
    assign _3120 = _72[4:4];
    assign _3117 = _4489 - _3070;
    assign _3118 = { gnd,
                     _3117 };
    assign _3119 = _3118 < _3073;
    assign _3130 = _3119 ? _3129 : _3120;
    assign _3113 = _1795[7:7];
    assign _3112 = _1795[6:6];
    assign _3111 = _1795[5:5];
    assign _3110 = _1795[4:4];
    assign _3109 = _1795[3:3];
    assign _3108 = _1795[2:2];
    assign _3107 = _1795[1:1];
    assign _3106 = _1795[0:0];
    always @* begin
        case (_3102)
        0:
            _3114 <= _3106;
        1:
            _3114 <= _3107;
        2:
            _3114 <= _3108;
        3:
            _3114 <= _3109;
        4:
            _3114 <= _3110;
        5:
            _3114 <= _3111;
        6:
            _3114 <= _3112;
        default:
            _3114 <= _3113;
        endcase
    end
    assign _3105 = _72[5:5];
    assign _3102 = _1598 - _3070;
    assign _3103 = { gnd,
                     _3102 };
    assign _3104 = _3103 < _3073;
    assign _3115 = _3104 ? _3114 : _3105;
    assign _3098 = _1795[7:7];
    assign _3097 = _1795[6:6];
    assign _3096 = _1795[5:5];
    assign _3095 = _1795[4:4];
    assign _3094 = _1795[3:3];
    assign _3093 = _1795[2:2];
    assign _3092 = _1795[1:1];
    assign _3091 = _1795[0:0];
    always @* begin
        case (_3087)
        0:
            _3099 <= _3091;
        1:
            _3099 <= _3092;
        2:
            _3099 <= _3093;
        3:
            _3099 <= _3094;
        4:
            _3099 <= _3095;
        5:
            _3099 <= _3096;
        6:
            _3099 <= _3097;
        default:
            _3099 <= _3098;
        endcase
    end
    assign _3090 = _72[6:6];
    assign _3087 = _951 - _3070;
    assign _3088 = { gnd,
                     _3087 };
    assign _3089 = _3088 < _3073;
    assign _3100 = _3089 ? _3099 : _3090;
    assign _3083 = _1795[7:7];
    assign _3082 = _1795[6:6];
    assign _3081 = _1795[5:5];
    assign _3080 = _1795[4:4];
    assign _3079 = _1795[3:3];
    assign _3078 = _1795[2:2];
    assign _3077 = _1795[1:1];
    assign _3076 = _1795[0:0];
    always @* begin
        case (_3071)
        0:
            _3084 <= _3076;
        1:
            _3084 <= _3077;
        2:
            _3084 <= _3078;
        3:
            _3084 <= _3079;
        4:
            _3084 <= _3080;
        5:
            _3084 <= _3081;
        6:
            _3084 <= _3082;
        default:
            _3084 <= _3083;
        endcase
    end
    assign _3075 = _72[7:7];
    assign _3073 = cfg_t1_out_cfg[7:4];
    assign _447 = 8'b00010000;
    assign _2305 = _622[7:0];
    assign _2302 = 7'b1010010;
    assign _2303 = _618 == _2302;
    assign _2301 = _612 & _616;
    assign _2304 = _2301 & _2303;
    assign _2306 = _2304 ? _2305 : cfg_t1_out_cfg;
    assign _67 = _2306;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_out_cfg <= _447;
        else
            cfg_t1_out_cfg <= _67;
    end
    assign _3070 = cfg_t1_out_cfg[2:0];
    assign _3071 = _1570 - _3070;
    assign _3072 = { gnd,
                     _3071 };
    assign _3074 = _3072 < _3073;
    assign _3085 = _3074 ? _3084 : _3075;
    assign _3191 = { _3085,
                     _3100,
                     _3115,
                     _3130,
                     _3145,
                     _3160,
                     _3175,
                     _3190 };
    assign _3064 = _2951[7:7];
    assign _3063 = _2951[6:6];
    assign _3062 = _2951[5:5];
    assign _3061 = _2951[4:4];
    assign _3060 = _2951[3:3];
    assign _3059 = _2951[2:2];
    assign _3058 = _2951[1:1];
    assign _3057 = _2951[0:0];
    always @* begin
        case (_3053)
        0:
            _3065 <= _3057;
        1:
            _3065 <= _3058;
        2:
            _3065 <= _3059;
        3:
            _3065 <= _3060;
        4:
            _3065 <= _3061;
        5:
            _3065 <= _3062;
        6:
            _3065 <= _3063;
        default:
            _3065 <= _3064;
        endcase
    end
    assign _3056 = _72[0:0];
    assign _3053 = _473 - _2943;
    assign _3054 = { gnd,
                     _3053 };
    assign _3055 = _3054 < _2946;
    assign _3066 = _3055 ? _3065 : _3056;
    assign _3049 = _2951[7:7];
    assign _3048 = _2951[6:6];
    assign _3047 = _2951[5:5];
    assign _3046 = _2951[4:4];
    assign _3045 = _2951[3:3];
    assign _3044 = _2951[2:2];
    assign _3043 = _2951[1:1];
    assign _3042 = _2951[0:0];
    always @* begin
        case (_3038)
        0:
            _3050 <= _3042;
        1:
            _3050 <= _3043;
        2:
            _3050 <= _3044;
        3:
            _3050 <= _3045;
        4:
            _3050 <= _3046;
        5:
            _3050 <= _3047;
        6:
            _3050 <= _3048;
        default:
            _3050 <= _3049;
        endcase
    end
    assign _3041 = _72[1:1];
    assign _3038 = _659 - _2943;
    assign _3039 = { gnd,
                     _3038 };
    assign _3040 = _3039 < _2946;
    assign _3051 = _3040 ? _3050 : _3041;
    assign _3034 = _2951[7:7];
    assign _3033 = _2951[6:6];
    assign _3032 = _2951[5:5];
    assign _3031 = _2951[4:4];
    assign _3030 = _2951[3:3];
    assign _3029 = _2951[2:2];
    assign _3028 = _2951[1:1];
    assign _3027 = _2951[0:0];
    always @* begin
        case (_3023)
        0:
            _3035 <= _3027;
        1:
            _3035 <= _3028;
        2:
            _3035 <= _3029;
        3:
            _3035 <= _3030;
        4:
            _3035 <= _3031;
        5:
            _3035 <= _3032;
        6:
            _3035 <= _3033;
        default:
            _3035 <= _3034;
        endcase
    end
    assign _3026 = _72[2:2];
    assign _3023 = _4345 - _2943;
    assign _3024 = { gnd,
                     _3023 };
    assign _3025 = _3024 < _2946;
    assign _3036 = _3025 ? _3035 : _3026;
    assign _3019 = _2951[7:7];
    assign _3018 = _2951[6:6];
    assign _3017 = _2951[5:5];
    assign _3016 = _2951[4:4];
    assign _3015 = _2951[3:3];
    assign _3014 = _2951[2:2];
    assign _3013 = _2951[1:1];
    assign _3012 = _2951[0:0];
    always @* begin
        case (_3008)
        0:
            _3020 <= _3012;
        1:
            _3020 <= _3013;
        2:
            _3020 <= _3014;
        3:
            _3020 <= _3015;
        4:
            _3020 <= _3016;
        5:
            _3020 <= _3017;
        6:
            _3020 <= _3018;
        default:
            _3020 <= _3019;
        endcase
    end
    assign _3011 = _72[3:3];
    assign _3008 = _965 - _2943;
    assign _3009 = { gnd,
                     _3008 };
    assign _3010 = _3009 < _2946;
    assign _3021 = _3010 ? _3020 : _3011;
    assign _3004 = _2951[7:7];
    assign _3003 = _2951[6:6];
    assign _3002 = _2951[5:5];
    assign _3001 = _2951[4:4];
    assign _3000 = _2951[3:3];
    assign _2999 = _2951[2:2];
    assign _2998 = _2951[1:1];
    assign _2997 = _2951[0:0];
    always @* begin
        case (_2993)
        0:
            _3005 <= _2997;
        1:
            _3005 <= _2998;
        2:
            _3005 <= _2999;
        3:
            _3005 <= _3000;
        4:
            _3005 <= _3001;
        5:
            _3005 <= _3002;
        6:
            _3005 <= _3003;
        default:
            _3005 <= _3004;
        endcase
    end
    assign _2996 = _72[4:4];
    assign _2993 = _4489 - _2943;
    assign _2994 = { gnd,
                     _2993 };
    assign _2995 = _2994 < _2946;
    assign _3006 = _2995 ? _3005 : _2996;
    assign _2989 = _2951[7:7];
    assign _2988 = _2951[6:6];
    assign _2987 = _2951[5:5];
    assign _2986 = _2951[4:4];
    assign _2985 = _2951[3:3];
    assign _2984 = _2951[2:2];
    assign _2983 = _2951[1:1];
    assign _2982 = _2951[0:0];
    always @* begin
        case (_2978)
        0:
            _2990 <= _2982;
        1:
            _2990 <= _2983;
        2:
            _2990 <= _2984;
        3:
            _2990 <= _2985;
        4:
            _2990 <= _2986;
        5:
            _2990 <= _2987;
        6:
            _2990 <= _2988;
        default:
            _2990 <= _2989;
        endcase
    end
    assign _2981 = _72[5:5];
    assign _2978 = _1598 - _2943;
    assign _2979 = { gnd,
                     _2978 };
    assign _2980 = _2979 < _2946;
    assign _2991 = _2980 ? _2990 : _2981;
    assign _2974 = _2951[7:7];
    assign _2973 = _2951[6:6];
    assign _2972 = _2951[5:5];
    assign _2971 = _2951[4:4];
    assign _2970 = _2951[3:3];
    assign _2969 = _2951[2:2];
    assign _2968 = _2951[1:1];
    assign _2967 = _2951[0:0];
    always @* begin
        case (_2963)
        0:
            _2975 <= _2967;
        1:
            _2975 <= _2968;
        2:
            _2975 <= _2969;
        3:
            _2975 <= _2970;
        4:
            _2975 <= _2971;
        5:
            _2975 <= _2972;
        6:
            _2975 <= _2973;
        default:
            _2975 <= _2974;
        endcase
    end
    assign _2966 = _72[6:6];
    assign _2963 = _951 - _2943;
    assign _2964 = { gnd,
                     _2963 };
    assign _2965 = _2964 < _2946;
    assign _2976 = _2965 ? _2975 : _2966;
    assign _2959 = _2951[7:7];
    assign _2958 = _2951[6:6];
    assign _2957 = _2951[5:5];
    assign _2956 = _2951[4:4];
    assign _2955 = _2951[3:3];
    assign _2954 = _2951[2:2];
    assign _2953 = _2951[1:1];
    assign _2952 = _2951[0:0];
    always @* begin
        case (_2944)
        0:
            _2960 <= _2952;
        1:
            _2960 <= _2953;
        2:
            _2960 <= _2954;
        3:
            _2960 <= _2955;
        4:
            _2960 <= _2956;
        5:
            _2960 <= _2957;
        6:
            _2960 <= _2958;
        default:
            _2960 <= _2959;
        endcase
    end
    assign _2948 = _72[7:7];
    assign _2946 = cfg_t1_set_cfg[7:4];
    assign _2311 = _622[7:0];
    assign _2308 = 7'b1010011;
    assign _2309 = _618 == _2308;
    assign _2307 = _612 & _616;
    assign _2310 = _2307 & _2309;
    assign _2312 = _2310 ? _2311 : cfg_t1_set_cfg;
    assign _68 = _2312;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_set_cfg <= _447;
        else
            cfg_t1_set_cfg <= _68;
    end
    assign _2943 = cfg_t1_set_cfg[2:0];
    assign _2944 = _1570 - _2943;
    assign _2945 = { gnd,
                     _2944 };
    assign _2947 = _2945 < _2946;
    assign _2961 = _2947 ? _2960 : _2948;
    assign _3067 = { _2961,
                     _2976,
                     _2991,
                     _3006,
                     _3021,
                     _3036,
                     _3051,
                     _3066 };
    assign _2901 = _2774[7:7];
    assign _2900 = _2774[6:6];
    assign _2899 = _2774[5:5];
    assign _2898 = _2774[4:4];
    assign _2897 = _2774[3:3];
    assign _2896 = _2774[2:2];
    assign _2895 = _2774[1:1];
    assign _2894 = _2774[0:0];
    always @* begin
        case (_2888)
        0:
            _2902 <= _2894;
        1:
            _2902 <= _2895;
        2:
            _2902 <= _2896;
        3:
            _2902 <= _2897;
        4:
            _2902 <= _2898;
        5:
            _2902 <= _2899;
        6:
            _2902 <= _2900;
        default:
            _2902 <= _2901;
        endcase
    end
    assign _2893 = _2754[0:0];
    assign _2891 = { _4480,
                     _2336 };
    assign _2888 = _473 - _2332;
    assign _2889 = { gnd,
                     _2888 };
    assign _2892 = _2889 < _2891;
    assign _2903 = _2892 ? _2902 : _2893;
    assign _2884 = _2774[7:7];
    assign _2883 = _2774[6:6];
    assign _2882 = _2774[5:5];
    assign _2881 = _2774[4:4];
    assign _2880 = _2774[3:3];
    assign _2879 = _2774[2:2];
    assign _2878 = _2774[1:1];
    assign _2877 = _2774[0:0];
    always @* begin
        case (_2871)
        0:
            _2885 <= _2877;
        1:
            _2885 <= _2878;
        2:
            _2885 <= _2879;
        3:
            _2885 <= _2880;
        4:
            _2885 <= _2881;
        5:
            _2885 <= _2882;
        6:
            _2885 <= _2883;
        default:
            _2885 <= _2884;
        endcase
    end
    assign _2876 = _2754[1:1];
    assign _2874 = { _4480,
                     _2336 };
    assign _2871 = _659 - _2332;
    assign _2872 = { gnd,
                     _2871 };
    assign _2875 = _2872 < _2874;
    assign _2886 = _2875 ? _2885 : _2876;
    assign _2867 = _2774[7:7];
    assign _2866 = _2774[6:6];
    assign _2865 = _2774[5:5];
    assign _2864 = _2774[4:4];
    assign _2863 = _2774[3:3];
    assign _2862 = _2774[2:2];
    assign _2861 = _2774[1:1];
    assign _2860 = _2774[0:0];
    always @* begin
        case (_2854)
        0:
            _2868 <= _2860;
        1:
            _2868 <= _2861;
        2:
            _2868 <= _2862;
        3:
            _2868 <= _2863;
        4:
            _2868 <= _2864;
        5:
            _2868 <= _2865;
        6:
            _2868 <= _2866;
        default:
            _2868 <= _2867;
        endcase
    end
    assign _2859 = _2754[2:2];
    assign _2857 = { _4480,
                     _2336 };
    assign _2854 = _4345 - _2332;
    assign _2855 = { gnd,
                     _2854 };
    assign _2858 = _2855 < _2857;
    assign _2869 = _2858 ? _2868 : _2859;
    assign _2850 = _2774[7:7];
    assign _2849 = _2774[6:6];
    assign _2848 = _2774[5:5];
    assign _2847 = _2774[4:4];
    assign _2846 = _2774[3:3];
    assign _2845 = _2774[2:2];
    assign _2844 = _2774[1:1];
    assign _2843 = _2774[0:0];
    always @* begin
        case (_2837)
        0:
            _2851 <= _2843;
        1:
            _2851 <= _2844;
        2:
            _2851 <= _2845;
        3:
            _2851 <= _2846;
        4:
            _2851 <= _2847;
        5:
            _2851 <= _2848;
        6:
            _2851 <= _2849;
        default:
            _2851 <= _2850;
        endcase
    end
    assign _2842 = _2754[3:3];
    assign _2840 = { _4480,
                     _2336 };
    assign _2837 = _965 - _2332;
    assign _2838 = { gnd,
                     _2837 };
    assign _2841 = _2838 < _2840;
    assign _2852 = _2841 ? _2851 : _2842;
    assign _2833 = _2774[7:7];
    assign _2832 = _2774[6:6];
    assign _2831 = _2774[5:5];
    assign _2830 = _2774[4:4];
    assign _2829 = _2774[3:3];
    assign _2828 = _2774[2:2];
    assign _2827 = _2774[1:1];
    assign _2826 = _2774[0:0];
    always @* begin
        case (_2820)
        0:
            _2834 <= _2826;
        1:
            _2834 <= _2827;
        2:
            _2834 <= _2828;
        3:
            _2834 <= _2829;
        4:
            _2834 <= _2830;
        5:
            _2834 <= _2831;
        6:
            _2834 <= _2832;
        default:
            _2834 <= _2833;
        endcase
    end
    assign _2825 = _2754[4:4];
    assign _2823 = { _4480,
                     _2336 };
    assign _2820 = _4489 - _2332;
    assign _2821 = { gnd,
                     _2820 };
    assign _2824 = _2821 < _2823;
    assign _2835 = _2824 ? _2834 : _2825;
    assign _2816 = _2774[7:7];
    assign _2815 = _2774[6:6];
    assign _2814 = _2774[5:5];
    assign _2813 = _2774[4:4];
    assign _2812 = _2774[3:3];
    assign _2811 = _2774[2:2];
    assign _2810 = _2774[1:1];
    assign _2809 = _2774[0:0];
    always @* begin
        case (_2803)
        0:
            _2817 <= _2809;
        1:
            _2817 <= _2810;
        2:
            _2817 <= _2811;
        3:
            _2817 <= _2812;
        4:
            _2817 <= _2813;
        5:
            _2817 <= _2814;
        6:
            _2817 <= _2815;
        default:
            _2817 <= _2816;
        endcase
    end
    assign _2808 = _2754[5:5];
    assign _2806 = { _4480,
                     _2336 };
    assign _2803 = _1598 - _2332;
    assign _2804 = { gnd,
                     _2803 };
    assign _2807 = _2804 < _2806;
    assign _2818 = _2807 ? _2817 : _2808;
    assign _2799 = _2774[7:7];
    assign _2798 = _2774[6:6];
    assign _2797 = _2774[5:5];
    assign _2796 = _2774[4:4];
    assign _2795 = _2774[3:3];
    assign _2794 = _2774[2:2];
    assign _2793 = _2774[1:1];
    assign _2792 = _2774[0:0];
    always @* begin
        case (_2786)
        0:
            _2800 <= _2792;
        1:
            _2800 <= _2793;
        2:
            _2800 <= _2794;
        3:
            _2800 <= _2795;
        4:
            _2800 <= _2796;
        5:
            _2800 <= _2797;
        6:
            _2800 <= _2798;
        default:
            _2800 <= _2799;
        endcase
    end
    assign _2791 = _2754[6:6];
    assign _2789 = { _4480,
                     _2336 };
    assign _2786 = _951 - _2332;
    assign _2787 = { gnd,
                     _2786 };
    assign _2790 = _2787 < _2789;
    assign _2801 = _2790 ? _2800 : _2791;
    assign _2782 = _2774[7:7];
    assign _2781 = _2774[6:6];
    assign _2780 = _2774[5:5];
    assign _2779 = _2774[4:4];
    assign _2778 = _2774[3:3];
    assign _2777 = _2774[2:2];
    assign _2776 = _2774[1:1];
    assign _2769 = _2767[3:2];
    assign _2770 = { _4480,
                     _2769 };
    assign _2765 = _2763[3:1];
    assign _2766 = { _606,
                     _2765 };
    assign _2763 = _132[12:9];
    assign _2762 = _2759[0:0];
    assign _2767 = _2762 ? _2766 : _2763;
    assign _2761 = _2759[1:1];
    assign _2771 = _2761 ? _2770 : _2767;
    assign _2758 = { gnd,
                     _2336 };
    assign _2759 = _4489 - _2758;
    assign _2760 = _2759[2:2];
    assign _2773 = _2760 ? _655 : _2771;
    assign _2774 = { _655,
                     _2773 };
    assign _2775 = _2774[0:0];
    always @* begin
        case (_2333)
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
    assign _2750 = _1042[7:7];
    assign _2749 = _1042[6:6];
    assign _2748 = _1042[5:5];
    assign _2747 = _1042[4:4];
    assign _2746 = _1042[3:3];
    assign _2745 = _1042[2:2];
    assign _2744 = _1042[1:1];
    assign _2743 = _1042[0:0];
    always @* begin
        case (_2739)
        0:
            _2751 <= _2743;
        1:
            _2751 <= _2744;
        2:
            _2751 <= _2745;
        3:
            _2751 <= _2746;
        4:
            _2751 <= _2747;
        5:
            _2751 <= _2748;
        6:
            _2751 <= _2749;
        default:
            _2751 <= _2750;
        endcase
    end
    assign _2742 = pin_out[0:0];
    assign _2739 = _473 - _2487;
    assign _2740 = { _4480,
                     _2739 };
    assign _2741 = _2740 < _857;
    assign _2752 = _2741 ? _2751 : _2742;
    assign _2734 = _1042[7:7];
    assign _2733 = _1042[6:6];
    assign _2732 = _1042[5:5];
    assign _2731 = _1042[4:4];
    assign _2730 = _1042[3:3];
    assign _2729 = _1042[2:2];
    assign _2728 = _1042[1:1];
    assign _2727 = _1042[0:0];
    always @* begin
        case (_2723)
        0:
            _2735 <= _2727;
        1:
            _2735 <= _2728;
        2:
            _2735 <= _2729;
        3:
            _2735 <= _2730;
        4:
            _2735 <= _2731;
        5:
            _2735 <= _2732;
        6:
            _2735 <= _2733;
        default:
            _2735 <= _2734;
        endcase
    end
    assign _2726 = pin_out[1:1];
    assign _2723 = _659 - _2487;
    assign _2724 = { _4480,
                     _2723 };
    assign _2725 = _2724 < _857;
    assign _2736 = _2725 ? _2735 : _2726;
    assign _2718 = _1042[7:7];
    assign _2717 = _1042[6:6];
    assign _2716 = _1042[5:5];
    assign _2715 = _1042[4:4];
    assign _2714 = _1042[3:3];
    assign _2713 = _1042[2:2];
    assign _2712 = _1042[1:1];
    assign _2711 = _1042[0:0];
    always @* begin
        case (_2707)
        0:
            _2719 <= _2711;
        1:
            _2719 <= _2712;
        2:
            _2719 <= _2713;
        3:
            _2719 <= _2714;
        4:
            _2719 <= _2715;
        5:
            _2719 <= _2716;
        6:
            _2719 <= _2717;
        default:
            _2719 <= _2718;
        endcase
    end
    assign _2710 = pin_out[2:2];
    assign _2707 = _4345 - _2487;
    assign _2708 = { _4480,
                     _2707 };
    assign _2709 = _2708 < _857;
    assign _2720 = _2709 ? _2719 : _2710;
    assign _2702 = _1042[7:7];
    assign _2701 = _1042[6:6];
    assign _2700 = _1042[5:5];
    assign _2699 = _1042[4:4];
    assign _2698 = _1042[3:3];
    assign _2697 = _1042[2:2];
    assign _2696 = _1042[1:1];
    assign _2695 = _1042[0:0];
    always @* begin
        case (_2691)
        0:
            _2703 <= _2695;
        1:
            _2703 <= _2696;
        2:
            _2703 <= _2697;
        3:
            _2703 <= _2698;
        4:
            _2703 <= _2699;
        5:
            _2703 <= _2700;
        6:
            _2703 <= _2701;
        default:
            _2703 <= _2702;
        endcase
    end
    assign _2694 = pin_out[3:3];
    assign _2691 = _965 - _2487;
    assign _2692 = { _4480,
                     _2691 };
    assign _2693 = _2692 < _857;
    assign _2704 = _2693 ? _2703 : _2694;
    assign _2686 = _1042[7:7];
    assign _2685 = _1042[6:6];
    assign _2684 = _1042[5:5];
    assign _2683 = _1042[4:4];
    assign _2682 = _1042[3:3];
    assign _2681 = _1042[2:2];
    assign _2680 = _1042[1:1];
    assign _2679 = _1042[0:0];
    always @* begin
        case (_2675)
        0:
            _2687 <= _2679;
        1:
            _2687 <= _2680;
        2:
            _2687 <= _2681;
        3:
            _2687 <= _2682;
        4:
            _2687 <= _2683;
        5:
            _2687 <= _2684;
        6:
            _2687 <= _2685;
        default:
            _2687 <= _2686;
        endcase
    end
    assign _2678 = pin_out[4:4];
    assign _2675 = _4489 - _2487;
    assign _2676 = { _4480,
                     _2675 };
    assign _2677 = _2676 < _857;
    assign _2688 = _2677 ? _2687 : _2678;
    assign _2670 = _1042[7:7];
    assign _2669 = _1042[6:6];
    assign _2668 = _1042[5:5];
    assign _2667 = _1042[4:4];
    assign _2666 = _1042[3:3];
    assign _2665 = _1042[2:2];
    assign _2664 = _1042[1:1];
    assign _2663 = _1042[0:0];
    always @* begin
        case (_2659)
        0:
            _2671 <= _2663;
        1:
            _2671 <= _2664;
        2:
            _2671 <= _2665;
        3:
            _2671 <= _2666;
        4:
            _2671 <= _2667;
        5:
            _2671 <= _2668;
        6:
            _2671 <= _2669;
        default:
            _2671 <= _2670;
        endcase
    end
    assign _2662 = pin_out[5:5];
    assign _2659 = _1598 - _2487;
    assign _2660 = { _4480,
                     _2659 };
    assign _2661 = _2660 < _857;
    assign _2672 = _2661 ? _2671 : _2662;
    assign _2654 = _1042[7:7];
    assign _2653 = _1042[6:6];
    assign _2652 = _1042[5:5];
    assign _2651 = _1042[4:4];
    assign _2650 = _1042[3:3];
    assign _2649 = _1042[2:2];
    assign _2648 = _1042[1:1];
    assign _2647 = _1042[0:0];
    always @* begin
        case (_2643)
        0:
            _2655 <= _2647;
        1:
            _2655 <= _2648;
        2:
            _2655 <= _2649;
        3:
            _2655 <= _2650;
        4:
            _2655 <= _2651;
        5:
            _2655 <= _2652;
        6:
            _2655 <= _2653;
        default:
            _2655 <= _2654;
        endcase
    end
    assign _2646 = pin_out[6:6];
    assign _2643 = _951 - _2487;
    assign _2644 = { _4480,
                     _2643 };
    assign _2645 = _2644 < _857;
    assign _2656 = _2645 ? _2655 : _2646;
    assign _2638 = _1042[7:7];
    assign _2637 = _1042[6:6];
    assign _2636 = _1042[5:5];
    assign _2635 = _1042[4:4];
    assign _2634 = _1042[3:3];
    assign _2633 = _1042[2:2];
    assign _2632 = _1042[1:1];
    assign _2631 = _1042[0:0];
    always @* begin
        case (_2627)
        0:
            _2639 <= _2631;
        1:
            _2639 <= _2632;
        2:
            _2639 <= _2633;
        3:
            _2639 <= _2634;
        4:
            _2639 <= _2635;
        5:
            _2639 <= _2636;
        6:
            _2639 <= _2637;
        default:
            _2639 <= _2638;
        endcase
    end
    assign _2630 = pin_out[7:7];
    assign _2627 = _1570 - _2487;
    assign _2628 = { _4480,
                     _2627 };
    assign _2629 = _2628 < _857;
    assign _2640 = _2629 ? _2639 : _2630;
    assign _2753 = { _2640,
                     _2656,
                     _2672,
                     _2688,
                     _2704,
                     _2720,
                     _2736,
                     _2752 };
    assign _2620 = _2507[7:7];
    assign _2619 = _2507[6:6];
    assign _2618 = _2507[5:5];
    assign _2617 = _2507[4:4];
    assign _2616 = _2507[3:3];
    assign _2615 = _2507[2:2];
    assign _2614 = _2507[1:1];
    assign _2613 = _2507[0:0];
    always @* begin
        case (_2609)
        0:
            _2621 <= _2613;
        1:
            _2621 <= _2614;
        2:
            _2621 <= _2615;
        3:
            _2621 <= _2616;
        4:
            _2621 <= _2617;
        5:
            _2621 <= _2618;
        6:
            _2621 <= _2619;
        default:
            _2621 <= _2620;
        endcase
    end
    assign _2612 = pin_out[0:0];
    assign _2609 = _473 - _2487;
    assign _2610 = { gnd,
                     _2609 };
    assign _2611 = _2610 < _2490;
    assign _2622 = _2611 ? _2621 : _2612;
    assign _2605 = _2507[7:7];
    assign _2604 = _2507[6:6];
    assign _2603 = _2507[5:5];
    assign _2602 = _2507[4:4];
    assign _2601 = _2507[3:3];
    assign _2600 = _2507[2:2];
    assign _2599 = _2507[1:1];
    assign _2598 = _2507[0:0];
    always @* begin
        case (_2594)
        0:
            _2606 <= _2598;
        1:
            _2606 <= _2599;
        2:
            _2606 <= _2600;
        3:
            _2606 <= _2601;
        4:
            _2606 <= _2602;
        5:
            _2606 <= _2603;
        6:
            _2606 <= _2604;
        default:
            _2606 <= _2605;
        endcase
    end
    assign _2597 = pin_out[1:1];
    assign _2594 = _659 - _2487;
    assign _2595 = { gnd,
                     _2594 };
    assign _2596 = _2595 < _2490;
    assign _2607 = _2596 ? _2606 : _2597;
    assign _2590 = _2507[7:7];
    assign _2589 = _2507[6:6];
    assign _2588 = _2507[5:5];
    assign _2587 = _2507[4:4];
    assign _2586 = _2507[3:3];
    assign _2585 = _2507[2:2];
    assign _2584 = _2507[1:1];
    assign _2583 = _2507[0:0];
    always @* begin
        case (_2579)
        0:
            _2591 <= _2583;
        1:
            _2591 <= _2584;
        2:
            _2591 <= _2585;
        3:
            _2591 <= _2586;
        4:
            _2591 <= _2587;
        5:
            _2591 <= _2588;
        6:
            _2591 <= _2589;
        default:
            _2591 <= _2590;
        endcase
    end
    assign _2582 = pin_out[2:2];
    assign _2579 = _4345 - _2487;
    assign _2580 = { gnd,
                     _2579 };
    assign _2581 = _2580 < _2490;
    assign _2592 = _2581 ? _2591 : _2582;
    assign _2575 = _2507[7:7];
    assign _2574 = _2507[6:6];
    assign _2573 = _2507[5:5];
    assign _2572 = _2507[4:4];
    assign _2571 = _2507[3:3];
    assign _2570 = _2507[2:2];
    assign _2569 = _2507[1:1];
    assign _2568 = _2507[0:0];
    always @* begin
        case (_2564)
        0:
            _2576 <= _2568;
        1:
            _2576 <= _2569;
        2:
            _2576 <= _2570;
        3:
            _2576 <= _2571;
        4:
            _2576 <= _2572;
        5:
            _2576 <= _2573;
        6:
            _2576 <= _2574;
        default:
            _2576 <= _2575;
        endcase
    end
    assign _2567 = pin_out[3:3];
    assign _2564 = _965 - _2487;
    assign _2565 = { gnd,
                     _2564 };
    assign _2566 = _2565 < _2490;
    assign _2577 = _2566 ? _2576 : _2567;
    assign _2560 = _2507[7:7];
    assign _2559 = _2507[6:6];
    assign _2558 = _2507[5:5];
    assign _2557 = _2507[4:4];
    assign _2556 = _2507[3:3];
    assign _2555 = _2507[2:2];
    assign _2554 = _2507[1:1];
    assign _2553 = _2507[0:0];
    always @* begin
        case (_2549)
        0:
            _2561 <= _2553;
        1:
            _2561 <= _2554;
        2:
            _2561 <= _2555;
        3:
            _2561 <= _2556;
        4:
            _2561 <= _2557;
        5:
            _2561 <= _2558;
        6:
            _2561 <= _2559;
        default:
            _2561 <= _2560;
        endcase
    end
    assign _2552 = pin_out[4:4];
    assign _2549 = _4489 - _2487;
    assign _2550 = { gnd,
                     _2549 };
    assign _2551 = _2550 < _2490;
    assign _2562 = _2551 ? _2561 : _2552;
    assign _2545 = _2507[7:7];
    assign _2544 = _2507[6:6];
    assign _2543 = _2507[5:5];
    assign _2542 = _2507[4:4];
    assign _2541 = _2507[3:3];
    assign _2540 = _2507[2:2];
    assign _2539 = _2507[1:1];
    assign _2538 = _2507[0:0];
    always @* begin
        case (_2534)
        0:
            _2546 <= _2538;
        1:
            _2546 <= _2539;
        2:
            _2546 <= _2540;
        3:
            _2546 <= _2541;
        4:
            _2546 <= _2542;
        5:
            _2546 <= _2543;
        6:
            _2546 <= _2544;
        default:
            _2546 <= _2545;
        endcase
    end
    assign _2537 = pin_out[5:5];
    assign _2534 = _1598 - _2487;
    assign _2535 = { gnd,
                     _2534 };
    assign _2536 = _2535 < _2490;
    assign _2547 = _2536 ? _2546 : _2537;
    assign _2530 = _2507[7:7];
    assign _2529 = _2507[6:6];
    assign _2528 = _2507[5:5];
    assign _2527 = _2507[4:4];
    assign _2526 = _2507[3:3];
    assign _2525 = _2507[2:2];
    assign _2524 = _2507[1:1];
    assign _2523 = _2507[0:0];
    always @* begin
        case (_2519)
        0:
            _2531 <= _2523;
        1:
            _2531 <= _2524;
        2:
            _2531 <= _2525;
        3:
            _2531 <= _2526;
        4:
            _2531 <= _2527;
        5:
            _2531 <= _2528;
        6:
            _2531 <= _2529;
        default:
            _2531 <= _2530;
        endcase
    end
    assign _2522 = pin_out[6:6];
    assign _2519 = _951 - _2487;
    assign _2520 = { gnd,
                     _2519 };
    assign _2521 = _2520 < _2490;
    assign _2532 = _2521 ? _2531 : _2522;
    assign _2515 = _2507[7:7];
    assign _2514 = _2507[6:6];
    assign _2513 = _2507[5:5];
    assign _2512 = _2507[4:4];
    assign _2511 = _2507[3:3];
    assign _2510 = _2507[2:2];
    assign _2509 = _2507[1:1];
    assign _2508 = _2507[0:0];
    always @* begin
        case (_2488)
        0:
            _2516 <= _2508;
        1:
            _2516 <= _2509;
        2:
            _2516 <= _2510;
        3:
            _2516 <= _2511;
        4:
            _2516 <= _2512;
        5:
            _2516 <= _2513;
        6:
            _2516 <= _2514;
        default:
            _2516 <= _2515;
        endcase
    end
    assign _2492 = pin_out[7:7];
    assign _2490 = cfg_t0_out_cfg[7:4];
    assign _2317 = _622[7:0];
    assign _2314 = 7'b1000010;
    assign _2315 = _618 == _2314;
    assign _2313 = _612 & _616;
    assign _2316 = _2313 & _2315;
    assign _2318 = _2316 ? _2317 : cfg_t0_out_cfg;
    assign _69 = _2318;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_out_cfg <= _447;
        else
            cfg_t0_out_cfg <= _69;
    end
    assign _2487 = cfg_t0_out_cfg[2:0];
    assign _2488 = _1570 - _2487;
    assign _2489 = { gnd,
                     _2488 };
    assign _2491 = _2489 < _2490;
    assign _2517 = _2491 ? _2516 : _2492;
    assign _2623 = { _2517,
                     _2532,
                     _2547,
                     _2562,
                     _2577,
                     _2592,
                     _2607,
                     _2622 };
    assign _2481 = _2368[7:7];
    assign _2480 = _2368[6:6];
    assign _2479 = _2368[5:5];
    assign _2478 = _2368[4:4];
    assign _2477 = _2368[3:3];
    assign _2476 = _2368[2:2];
    assign _2475 = _2368[1:1];
    assign _2474 = _2368[0:0];
    always @* begin
        case (_2470)
        0:
            _2482 <= _2474;
        1:
            _2482 <= _2475;
        2:
            _2482 <= _2476;
        3:
            _2482 <= _2477;
        4:
            _2482 <= _2478;
        5:
            _2482 <= _2479;
        6:
            _2482 <= _2480;
        default:
            _2482 <= _2481;
        endcase
    end
    assign _2473 = pin_out[0:0];
    assign _2470 = _473 - _2360;
    assign _2471 = { gnd,
                     _2470 };
    assign _2472 = _2471 < _2363;
    assign _2483 = _2472 ? _2482 : _2473;
    assign _2466 = _2368[7:7];
    assign _2465 = _2368[6:6];
    assign _2464 = _2368[5:5];
    assign _2463 = _2368[4:4];
    assign _2462 = _2368[3:3];
    assign _2461 = _2368[2:2];
    assign _2460 = _2368[1:1];
    assign _2459 = _2368[0:0];
    always @* begin
        case (_2455)
        0:
            _2467 <= _2459;
        1:
            _2467 <= _2460;
        2:
            _2467 <= _2461;
        3:
            _2467 <= _2462;
        4:
            _2467 <= _2463;
        5:
            _2467 <= _2464;
        6:
            _2467 <= _2465;
        default:
            _2467 <= _2466;
        endcase
    end
    assign _2458 = pin_out[1:1];
    assign _2455 = _659 - _2360;
    assign _2456 = { gnd,
                     _2455 };
    assign _2457 = _2456 < _2363;
    assign _2468 = _2457 ? _2467 : _2458;
    assign _2451 = _2368[7:7];
    assign _2450 = _2368[6:6];
    assign _2449 = _2368[5:5];
    assign _2448 = _2368[4:4];
    assign _2447 = _2368[3:3];
    assign _2446 = _2368[2:2];
    assign _2445 = _2368[1:1];
    assign _2444 = _2368[0:0];
    always @* begin
        case (_2440)
        0:
            _2452 <= _2444;
        1:
            _2452 <= _2445;
        2:
            _2452 <= _2446;
        3:
            _2452 <= _2447;
        4:
            _2452 <= _2448;
        5:
            _2452 <= _2449;
        6:
            _2452 <= _2450;
        default:
            _2452 <= _2451;
        endcase
    end
    assign _2443 = pin_out[2:2];
    assign _2440 = _4345 - _2360;
    assign _2441 = { gnd,
                     _2440 };
    assign _2442 = _2441 < _2363;
    assign _2453 = _2442 ? _2452 : _2443;
    assign _2436 = _2368[7:7];
    assign _2435 = _2368[6:6];
    assign _2434 = _2368[5:5];
    assign _2433 = _2368[4:4];
    assign _2432 = _2368[3:3];
    assign _2431 = _2368[2:2];
    assign _2430 = _2368[1:1];
    assign _2429 = _2368[0:0];
    always @* begin
        case (_2425)
        0:
            _2437 <= _2429;
        1:
            _2437 <= _2430;
        2:
            _2437 <= _2431;
        3:
            _2437 <= _2432;
        4:
            _2437 <= _2433;
        5:
            _2437 <= _2434;
        6:
            _2437 <= _2435;
        default:
            _2437 <= _2436;
        endcase
    end
    assign _2428 = pin_out[3:3];
    assign _2425 = _965 - _2360;
    assign _2426 = { gnd,
                     _2425 };
    assign _2427 = _2426 < _2363;
    assign _2438 = _2427 ? _2437 : _2428;
    assign _2421 = _2368[7:7];
    assign _2420 = _2368[6:6];
    assign _2419 = _2368[5:5];
    assign _2418 = _2368[4:4];
    assign _2417 = _2368[3:3];
    assign _2416 = _2368[2:2];
    assign _2415 = _2368[1:1];
    assign _2414 = _2368[0:0];
    always @* begin
        case (_2410)
        0:
            _2422 <= _2414;
        1:
            _2422 <= _2415;
        2:
            _2422 <= _2416;
        3:
            _2422 <= _2417;
        4:
            _2422 <= _2418;
        5:
            _2422 <= _2419;
        6:
            _2422 <= _2420;
        default:
            _2422 <= _2421;
        endcase
    end
    assign _2413 = pin_out[4:4];
    assign _2410 = _4489 - _2360;
    assign _2411 = { gnd,
                     _2410 };
    assign _2412 = _2411 < _2363;
    assign _2423 = _2412 ? _2422 : _2413;
    assign _2406 = _2368[7:7];
    assign _2405 = _2368[6:6];
    assign _2404 = _2368[5:5];
    assign _2403 = _2368[4:4];
    assign _2402 = _2368[3:3];
    assign _2401 = _2368[2:2];
    assign _2400 = _2368[1:1];
    assign _2399 = _2368[0:0];
    always @* begin
        case (_2395)
        0:
            _2407 <= _2399;
        1:
            _2407 <= _2400;
        2:
            _2407 <= _2401;
        3:
            _2407 <= _2402;
        4:
            _2407 <= _2403;
        5:
            _2407 <= _2404;
        6:
            _2407 <= _2405;
        default:
            _2407 <= _2406;
        endcase
    end
    assign _2398 = pin_out[5:5];
    assign _2395 = _1598 - _2360;
    assign _2396 = { gnd,
                     _2395 };
    assign _2397 = _2396 < _2363;
    assign _2408 = _2397 ? _2407 : _2398;
    assign _2391 = _2368[7:7];
    assign _2390 = _2368[6:6];
    assign _2389 = _2368[5:5];
    assign _2388 = _2368[4:4];
    assign _2387 = _2368[3:3];
    assign _2386 = _2368[2:2];
    assign _2385 = _2368[1:1];
    assign _2384 = _2368[0:0];
    always @* begin
        case (_2380)
        0:
            _2392 <= _2384;
        1:
            _2392 <= _2385;
        2:
            _2392 <= _2386;
        3:
            _2392 <= _2387;
        4:
            _2392 <= _2388;
        5:
            _2392 <= _2389;
        6:
            _2392 <= _2390;
        default:
            _2392 <= _2391;
        endcase
    end
    assign _2383 = pin_out[6:6];
    assign _2380 = _951 - _2360;
    assign _2381 = { gnd,
                     _2380 };
    assign _2382 = _2381 < _2363;
    assign _2393 = _2382 ? _2392 : _2383;
    assign _2376 = _2368[7:7];
    assign _2375 = _2368[6:6];
    assign _2374 = _2368[5:5];
    assign _2373 = _2368[4:4];
    assign _2372 = _2368[3:3];
    assign _2371 = _2368[2:2];
    assign _2370 = _2368[1:1];
    assign _2369 = _2368[0:0];
    always @* begin
        case (_2361)
        0:
            _2377 <= _2369;
        1:
            _2377 <= _2370;
        2:
            _2377 <= _2371;
        3:
            _2377 <= _2372;
        4:
            _2377 <= _2373;
        5:
            _2377 <= _2374;
        6:
            _2377 <= _2375;
        default:
            _2377 <= _2376;
        endcase
    end
    assign _2365 = pin_out[7:7];
    assign _2363 = cfg_t0_set_cfg[7:4];
    assign _2323 = _622[7:0];
    assign _2320 = 7'b1000011;
    assign _2321 = _618 == _2320;
    assign _2319 = _612 & _616;
    assign _2322 = _2319 & _2321;
    assign _2324 = _2322 ? _2323 : cfg_t0_set_cfg;
    assign _70 = _2324;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_set_cfg <= _447;
        else
            cfg_t0_set_cfg <= _70;
    end
    assign _2360 = cfg_t0_set_cfg[2:0];
    assign _2361 = _1570 - _2360;
    assign _2362 = { gnd,
                     _2361 };
    assign _2364 = _2362 < _2363;
    assign _2378 = _2364 ? _2377 : _2365;
    assign _2484 = { _2378,
                     _2393,
                     _2408,
                     _2423,
                     _2438,
                     _2453,
                     _2468,
                     _2483 };
    assign _2357 = _873 == _4480;
    assign _2354 = _658 == _951;
    assign _2355 = _867 & _2354;
    assign _2358 = _2355 & _2357;
    assign _2485 = _2358 ? _2484 : pin_out;
    assign _2350 = _942 == _4345;
    assign _2351 = _948 & _2350;
    assign _2347 = _658 == _1598;
    assign _2348 = _867 & _2347;
    assign _2352 = _2348 & _2351;
    assign _2624 = _2352 ? _2623 : _2485;
    assign _2342 = _132[8:7];
    assign _2344 = _2342 == _4480;
    assign _2340 = _658 == _965;
    assign _2341 = _867 & _2340;
    assign _2345 = _2341 & _2344;
    assign _2754 = _2345 ? _2753 : _2624;
    assign _2755 = _2754[7:7];
    assign _2336 = cfg_t0_sideset[5:4];
    assign _2337 = { _4480,
                     _2336 };
    assign _2329 = _622[5:0];
    assign _2326 = 7'b1001100;
    assign _2327 = _618 == _2326;
    assign _2325 = _612 & _616;
    assign _2328 = _2325 & _2327;
    assign _2330 = _2328 ? _2329 : cfg_t0_sideset;
    assign _71 = _2330;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_sideset <= _562;
        else
            cfg_t0_sideset <= _71;
    end
    assign _2332 = cfg_t0_sideset[2:0];
    assign _2333 = _1570 - _2332;
    assign _2334 = { gnd,
                     _2333 };
    assign _2338 = _2334 < _2337;
    assign _2784 = _2338 ? _2783 : _2755;
    assign _2904 = { _2784,
                     _2801,
                     _2818,
                     _2835,
                     _2852,
                     _2869,
                     _2886,
                     _2903 };
    assign _2905 = _653 ? pin_out : _2904;
    assign _2906 = _647 ? pin_out : _2905;
    assign _2907 = _641 ? pin_out : _2906;
    assign _72 = _2907;
    assign _2940 = _1398 == _4480;
    assign _2937 = _1314 == _951;
    assign _2938 = _1392 & _2937;
    assign _2941 = _2938 & _2940;
    assign _3068 = _2941 ? _3067 : _72;
    assign _2933 = _1467 == _4345;
    assign _2934 = _1473 & _2933;
    assign _2930 = _1314 == _1598;
    assign _2931 = _1392 & _2930;
    assign _2935 = _2931 & _2934;
    assign _3192 = _2935 ? _3191 : _3068;
    assign _2925 = _107[8:7];
    assign _2927 = _2925 == _4480;
    assign _2923 = _1314 == _965;
    assign _2924 = _1392 & _2923;
    assign _2928 = _2924 & _2927;
    assign _3322 = _2928 ? _3321 : _3192;
    assign _3323 = _3322[7:7];
    assign _2919 = cfg_t1_sideset[5:4];
    assign _2920 = { _4480,
                     _2919 };
    assign _2912 = _622[5:0];
    assign _2909 = 7'b1011100;
    assign _2910 = _618 == _2909;
    assign _2908 = _612 & _616;
    assign _2911 = _2908 & _2910;
    assign _2913 = _2911 ? _2912 : cfg_t1_sideset;
    assign _73 = _2913;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_sideset <= _562;
        else
            cfg_t1_sideset <= _73;
    end
    assign _2915 = cfg_t1_sideset[2:0];
    assign _2916 = _1570 - _2915;
    assign _2917 = { gnd,
                     _2916 };
    assign _2921 = _2917 < _2920;
    assign _3352 = _2921 ? _3351 : _3323;
    assign _3472 = { _3352,
                     _3369,
                     _3386,
                     _3403,
                     _3420,
                     _3437,
                     _3454,
                     _3471 };
    assign _3473 = _1309 ? _72 : _3472;
    assign _3474 = _1303 ? _72 : _3473;
    assign _3475 = _1297 ? _72 : _3474;
    assign _74 = _3475;
    assign _75 = _74;
    always @(posedge _146) begin
        if (_144)
            pin_out <= _164;
        else
            pin_out <= _75;
    end
    assign _683 = pin_out[7:7];
    assign _679 = ~ cfg_sync_bypass;
    always @(posedge _146) begin
        if (_144)
            pins_sync1 <= _164;
        else
            pins_sync1 <= _78;
    end
    always @(posedge _146) begin
        if (_144)
            pins_sync2 <= _164;
        else
            pins_sync2 <= pins_sync1;
    end
    assign _680 = pins_sync2 & _679;
    assign _3480 = _622[7:0];
    assign _3477 = 7'b1001110;
    assign _3478 = _618 == _3477;
    assign _3476 = _612 & _616;
    assign _3479 = _3476 & _3478;
    assign _3481 = _3479 ? _3480 : cfg_sync_bypass;
    assign _76 = _3481;
    always @(posedge _146) begin
        if (_144)
            cfg_sync_bypass <= _576;
        else
            cfg_sync_bypass <= _76;
    end
    assign _78 = uio_in;
    assign _673 = _78 & cfg_sync_bypass;
    assign _681 = _673 | _680;
    assign _682 = _681[7:7];
    assign _3483 = 7'b1000111;
    assign _3484 = _618 == _3483;
    assign _3482 = _612 & _616;
    assign _3485 = _3482 & _3484;
    assign _3486 = _3485 ? _622 : cfg_pin_modes;
    assign _79 = _3486;
    always @(posedge _146) begin
        if (_144)
            cfg_pin_modes <= _312;
        else
            cfg_pin_modes <= _79;
    end
    assign _672 = cfg_pin_modes[15:14];
    always @* begin
        case (_672)
        0:
            _685 <= _682;
        1:
            _685 <= _683;
        2:
            _685 <= _684;
        default:
            _685 <= _682;
        endcase
    end
    assign _670 = _665 == _951;
    assign _671 = _662 & _670;
    assign _689 = _671 ? smp_strobe : _685;
    assign _3488 = 7'b1100111;
    assign _3489 = _618 == _3488;
    assign _3487 = _612 & _616;
    assign _3490 = _3487 & _3489;
    assign _3491 = _3490 ? _622 : cfg_smp_pre;
    assign _80 = _3491;
    always @(posedge _146) begin
        if (_144)
            cfg_smp_pre <= _312;
        else
            cfg_smp_pre <= _80;
    end
    assign _664 = cfg_smp_pre[12:10];
    assign _663 = cfg_smp_ctrl[3:1];
    assign _665 = _663 + _664;
    assign _667 = _665 == _1570;
    assign _569 = 9'b000000000;
    assign _3496 = _622[8:0];
    assign _3493 = 7'b1101100;
    assign _3494 = _618 == _3493;
    assign _3492 = _612 & _616;
    assign _3495 = _3492 & _3494;
    assign _3497 = _3495 ? _3496 : cfg_smp_ctrl;
    assign _81 = _3497;
    always @(posedge _146) begin
        if (_144)
            cfg_smp_ctrl <= _569;
        else
            cfg_smp_ctrl <= _81;
    end
    assign _662 = cfg_smp_ctrl[0:0];
    assign _668 = _662 & _667;
    assign _693 = _668 ? smp_data : _689;
    assign _792 = { _693,
                    _707,
                    _721,
                    _735,
                    _749,
                    _763,
                    _777,
                    _791 };
    assign _1047 = _792[0:0];
    assign _3502 = _622[2:0];
    assign _3499 = 7'b1000100;
    assign _3500 = _618 == _3499;
    assign _3498 = _612 & _616;
    assign _3501 = _3498 & _3500;
    assign _3503 = _3501 ? _3502 : cfg_t0_in_base;
    assign _82 = _3503;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_in_base <= _473;
        else
            cfg_t0_in_base <= _82;
    end
    assign _1046 = cfg_t0_in_base + _1570;
    always @* begin
        case (_1046)
        0:
            _1055 <= _1047;
        1:
            _1055 <= _1048;
        2:
            _1055 <= _1049;
        3:
            _1055 <= _1050;
        4:
            _1055 <= _1051;
        5:
            _1055 <= _1052;
        6:
            _1055 <= _1053;
        default:
            _1055 <= _1054;
        endcase
    end
    assign _1058 = _1055 & _1057;
    assign _1155 = { _1058,
                     _1072,
                     _1086,
                     _1100,
                     _1114,
                     _1128,
                     _1142,
                     _1154 };
    assign _1156 = { _576,
                     _1155 };
    assign _1043 = _132[8:7];
    always @* begin
        case (_1043)
        0:
            _1164 <= _1156;
        1:
            _1164 <= t0_x;
        2:
            _1164 <= t0_y;
        default:
            _1164 <= _312;
        endcase
    end
    assign _3522 = { _1164,
                     t0_isr };
    assign _3521 = _857[0:0];
    assign _3526 = _3521 ? _3525 : _3522;
    assign _3520 = _857[1:1];
    assign _3530 = _3520 ? _3529 : _3526;
    assign _3519 = _857[2:2];
    assign _3534 = _3519 ? _3533 : _3530;
    assign _3518 = _857[3:3];
    assign _3538 = _3518 ? _3537 : _3534;
    assign _3517 = _857[4:4];
    assign _3542 = _3517 ? _3541 : _3538;
    assign _3543 = _3542[15:0];
    assign _3574 = _980 ? _3573 : _3543;
    assign _3576 = _863 ? _312 : _3574;
    assign _3515 = _821 ? t0_isr : _312;
    assign _3510 = _942 == _965;
    assign _3511 = _3510 ? _2507 : t0_isr;
    assign _3512 = _948 ? _3511 : t0_isr;
    assign _3508 = _658 == _1598;
    assign _3513 = _3508 ? _3512 : t0_isr;
    assign _3507 = _658 == _4489;
    assign _3516 = _3507 ? _3515 : _3513;
    assign _3505 = _658 == _4345;
    assign _3577 = _3505 ? _3576 : _3516;
    assign _3578 = _867 ? _3577 : t0_isr;
    assign _3579 = _653 ? t0_isr : _3578;
    assign _3580 = _647 ? t0_isr : _3579;
    assign _3582 = _641 ? _312 : _3580;
    assign _83 = _3582;
    assign _84 = _83;
    always @(posedge _146) begin
        if (_144)
            t0_isr <= _312;
        else
            t0_isr <= _84;
    end
    assign _3620 = { _312,
                     t0_isr };
    assign _3618 = _3613[0:0];
    assign _3624 = _3618 ? _3623 : _3620;
    assign _3617 = _3613[1:1];
    assign _3628 = _3617 ? _3627 : _3624;
    assign _3616 = _3613[2:2];
    assign _3632 = _3616 ? _3631 : _3628;
    assign _3615 = _3613[3:3];
    assign _3636 = _3615 ? _3635 : _3632;
    assign _3599 = _3597[4:0];
    assign _3596 = { gnd,
                     _857 };
    assign _3595 = { gnd,
                     t0_isr_count };
    assign _3597 = _3595 + _3596;
    assign _3598 = _1879 < _3597;
    assign _3601 = _3598 ? _1012 : _3599;
    assign _860 = { gnd,
                    cfg_t0_threshold };
    assign _858 = { gnd,
                    _857 };
    assign _851 = { gnd,
                    t0_isr_count };
    assign _859 = _851 + _858;
    assign _861 = _859 < _860;
    assign _862 = ~ _861;
    assign _846 = cfg_t0_shift[3:3];
    assign _845 = _658 == _4345;
    assign _847 = _845 & _846;
    assign _863 = _847 & _862;
    assign _3603 = _863 ? _838 : _3601;
    assign _3592 = _821 ? t0_isr_count : _838;
    assign _3586 = _942 == _965;
    assign _3588 = _3586 ? _838 : t0_isr_count;
    assign _3589 = _948 ? _3588 : t0_isr_count;
    assign _3585 = _658 == _1598;
    assign _3590 = _3585 ? _3589 : t0_isr_count;
    assign _3584 = _658 == _4489;
    assign _3593 = _3584 ? _3592 : _3590;
    assign _3583 = _658 == _4345;
    assign _3604 = _3583 ? _3603 : _3593;
    assign _3605 = _867 ? _3604 : t0_isr_count;
    assign _3606 = _653 ? t0_isr_count : _3605;
    assign _3607 = _647 ? t0_isr_count : _3606;
    assign _3609 = _641 ? _838 : _3607;
    assign _85 = _3609;
    assign _86 = _85;
    always @(posedge _146) begin
        if (_144)
            t0_isr_count <= _838;
        else
            t0_isr_count <= _86;
    end
    assign _3613 = _1012 - t0_isr_count;
    assign _3614 = _3613[4:4];
    assign _3640 = _3614 ? _3639 : _3636;
    assign _3641 = _3640[15:0];
    assign _980 = cfg_t0_shift[1:1];
    assign _3669 = _980 ? _3668 : _3641;
    assign _3611 = _658 == _4345;
    assign _3728 = _3611 ? _3727 : _3669;
    assign _87 = _3728;
    always @(posedge _146) begin
        if (_144)
            t0_rx_mem_0 <= _312;
        else
            if (_384)
                t0_rx_mem_0 <= _87;
    end
    assign _3758 = t0_rx_rd + _231;
    assign _3755 = ~ _3754;
    assign _3750 = _1211 == _606;
    assign _3751 = _115 & _3750;
    assign _3746 = ~ _1751;
    assign _3742 = _1211 == _606;
    assign _3740 = _1219 == _234;
    assign _3743 = _3740 & _3742;
    assign _3744 = ~ _3743;
    assign _3736 = t0_rx_level == _473;
    assign _3737 = ~ _3736;
    assign _3732 = 7'b1001001;
    assign _326 = _325[6:0];
    assign _3733 = _326 == _3732;
    assign _3729 = _325[7:7];
    assign _3730 = ~ _3729;
    assign _1274 = host_bit_count == _1581;
    assign _1275 = _310 & _1274;
    assign _3731 = _1275 & _3730;
    assign _3734 = _3731 & _3733;
    assign _3738 = _3734 & _3737;
    assign _88 = _3738;
    assign _3745 = _88 & _3744;
    assign _3747 = _3745 & _3746;
    assign _3748 = _150 | _3747;
    assign _3752 = _3748 | _3751;
    assign _3756 = _3752 & _3755;
    assign _3759 = _3756 ? _3758 : t0_rx_rd;
    assign _89 = _3759;
    always @(posedge _146) begin
        if (_144)
            t0_rx_rd <= _4480;
        else
            t0_rx_rd <= _89;
    end
    always @* begin
        case (t0_rx_rd)
        0:
            _404 <= t0_rx_mem_0;
        1:
            _404 <= t0_rx_mem_1;
        2:
            _404 <= t0_rx_mem_2;
        default:
            _404 <= t0_rx_mem_3;
        endcase
    end
    assign _3773 = _1211 ? _511 : _404;
    assign _3774 = _115 ? _3773 : _622;
    assign _3772 = _90 ? buf_ptr : _116;
    assign _3771 = ~ _90;
    assign _3767 = _1219 == _874;
    assign _3765 = _1219 == _4480;
    assign _3768 = _3765 | _3767;
    assign _3762 = _618 == _1279;
    assign _3760 = _612 & _616;
    assign _3763 = _3760 & _3762;
    assign _3769 = _3763 & _3768;
    assign _3770 = _115 | _3769;
    assign _90 = _3770;
    RM_IHPSG13_1P_1024x16_c2_bm_bist
        sram_buf
        ( .A_CLK(_146),
          .A_MEN(vdd),
          .A_WEN(_90),
          .A_REN(_3771),
          .A_ADDR(_3772),
          .A_DIN(_3774),
          .A_DLY(vdd),
          .A_BM(_4392),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_532),
          .A_BIST_DIN(_312),
          .A_BIST_BM(_312),
          .A_DOUT(_3780[15:0]) );
    assign _91 = _3780;
    assign _92 = _91;
    assign _1737 = _1211 == _1746;
    assign _1738 = _118 & _1737;
    assign _3844 = _1738 ? _92 : _622;
    assign _3845 = _150 ? _43 : _3844;
    always @(posedge _146) begin
        if (_144)
            t1_tx_mem_0 <= _312;
        else
            if (_3850)
                t1_tx_mem_0 <= _3845;
    end
    assign _3814 = t1_tx_rd + _231;
    assign _3808 = ~ _1349;
    assign _3785 = ~ _1349;
    assign _3782 = _1314 == _4489;
    assign _3783 = _1313 & _3782;
    assign _3784 = _3783 & _1346;
    assign _3786 = _3784 & _3785;
    assign _3804 = _3786 | _3803;
    assign _3807 = _3804 | _3806;
    assign _93 = _3807;
    assign _3809 = _93 & _3808;
    assign _3815 = _3809 ? _3814 : t1_tx_rd;
    assign _94 = _3815;
    always @(posedge _146) begin
        if (_144)
            t1_tx_rd <= _4480;
        else
            t1_tx_rd <= _94;
    end
    always @* begin
        case (t1_tx_rd)
        0:
            _3870 <= t1_tx_mem_0;
        1:
            _3870 <= t1_tx_mem_1;
        2:
            _3870 <= t1_tx_mem_2;
        default:
            _3870 <= t1_tx_mem_3;
        endcase
    end
    assign _1349 = t1_tx_level == _473;
    assign _3802 = ~ _1349;
    assign _462 = 5'b01000;
    assign _3820 = _622[4:0];
    assign _3817 = 7'b1010101;
    assign _3818 = _618 == _3817;
    assign _3816 = _612 & _616;
    assign _3819 = _3816 & _3818;
    assign _3821 = _3819 ? _3820 : cfg_t1_threshold;
    assign _95 = _3821;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_threshold <= _462;
        else
            cfg_t1_threshold <= _95;
    end
    assign _3796 = _3794[4:0];
    assign _1380 = { gnd,
                     _1377 };
    assign _1377 = _107[3:0];
    assign _1379 = _1377 == _655;
    assign _1382 = _1379 ? _1012 : _1380;
    assign _3793 = { gnd,
                     _1382 };
    assign _3792 = { gnd,
                     t1_osr_count };
    assign _3794 = _3792 + _3793;
    assign _3795 = _1879 < _3794;
    assign _3798 = _3795 ? _1012 : _3796;
    assign _3799 = _3798 < cfg_t1_threshold;
    assign _3800 = ~ _3799;
    assign _3788 = _1314 == _965;
    assign _3789 = _1392 & _3788;
    assign _3790 = _3789 & _1360;
    assign _3801 = _3790 & _3800;
    assign _3803 = _3801 & _3802;
    assign _3838 = _3803 ? _838 : _3798;
    assign _1346 = _107[8:8];
    assign _3835 = _1346 ? _838 : _3823;
    assign _3829 = _1467 == _4489;
    assign _3831 = _3829 ? _838 : _3823;
    assign _3832 = _1473 ? _3831 : _3823;
    assign _3827 = _1314 == _1598;
    assign _3833 = _3827 ? _3832 : _3823;
    assign _3826 = _1314 == _4489;
    assign _3836 = _3826 ? _3835 : _3833;
    assign _3825 = _1314 == _965;
    assign _3839 = _3825 ? _3838 : _3836;
    assign _3823 = _3806 ? _838 : t1_osr_count;
    assign _3840 = _1392 ? _3839 : _3823;
    assign _3841 = _1309 ? t1_osr_count : _3840;
    assign _3842 = _1303 ? t1_osr_count : _3841;
    assign _3843 = _1297 ? cfg_t1_threshold : _3842;
    assign _96 = _3843;
    assign _97 = _96;
    always @(posedge _146) begin
        if (_144)
            t1_osr_count <= _838;
        else
            t1_osr_count <= _97;
    end
    assign _1365 = t1_osr_count < cfg_t1_threshold;
    assign _1366 = ~ _1365;
    assign _1360 = cfg_t1_shift[2:2];
    assign _1359 = _1314 == _965;
    assign _1361 = _1359 & _1360;
    assign _1367 = _1361 & _1366;
    assign _3805 = _1313 & _1367;
    assign _3806 = _3805 & _3802;
    assign _3871 = _3806 ? _3870 : t1_osr;
    assign _3940 = _1392 ? _3939 : _3871;
    assign _3941 = _1309 ? t1_osr : _3940;
    assign _3942 = _1303 ? t1_osr : _3941;
    assign _3944 = _1297 ? _312 : _3942;
    assign _98 = _3944;
    assign _99 = _98;
    always @(posedge _146) begin
        if (_144)
            t1_osr <= _312;
        else
            t1_osr <= _99;
    end
    assign _1536 = t1_osr & _1535;
    assign _3949 = _622[5:0];
    assign _3946 = 7'b1011111;
    assign _3947 = _618 == _3946;
    assign _3945 = _612 & _616;
    assign _3948 = _3945 & _3947;
    assign _3950 = _3948 ? _3949 : cfg_t1_shift;
    assign _100 = _3950;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_shift <= _562;
        else
            cfg_t1_shift <= _100;
    end
    assign _1504 = cfg_t1_shift[0:0];
    assign _1567 = _1504 ? _1566 : _1536;
    assign _3965 = _107[8:7];
    assign _3967 = _3965 == _234;
    assign _3968 = _3967 ? _1567 : t1_y;
    assign _3961 = _1467 == _659;
    assign _3962 = _3961 ? _1795 : t1_y;
    assign _3963 = _1473 ? _3962 : t1_y;
    assign _3957 = _1398 == _234;
    assign _3958 = _3957 ? _2951 : t1_y;
    assign _3955 = _1314 == _951;
    assign _3959 = _3955 ? _3958 : t1_y;
    assign _3954 = _1314 == _1598;
    assign _3964 = _3954 ? _3963 : _3959;
    assign _3953 = _1314 == _965;
    assign _3969 = _3953 ? _3968 : _3964;
    assign _3952 = _1314 == _473;
    assign _3976 = _3952 ? _3975 : _3969;
    assign _3977 = _1392 ? _3976 : t1_y;
    assign _3978 = _1309 ? t1_y : _3977;
    assign _3979 = _1303 ? t1_y : _3978;
    assign _3981 = _1297 ? _312 : _3979;
    assign _101 = _3981;
    assign _102 = _101;
    always @(posedge _146) begin
        if (_144)
            t1_y <= _312;
        else
            t1_y <= _102;
    end
    always @* begin
        case (_1470)
        0:
            _1795 <= t1_x;
        1:
            _1795 <= t1_y;
        2:
            _1795 <= _1785;
        3:
            _1795 <= t1_isr;
        4:
            _1795 <= t1_osr;
        5:
            _1795 <= _312;
        default:
            _1795 <= _1794;
        endcase
    end
    assign _3991 = _1467 == _473;
    assign _3992 = _3991 ? _1795 : t1_x;
    assign _1470 = _107[5:3];
    assign _1472 = _1470 < _1570;
    assign _1467 = _107[8:6];
    assign _1469 = _1467 < _1570;
    assign _1473 = _1469 & _1472;
    assign _3993 = _1473 ? _3992 : t1_x;
    assign _2950 = _107[4:0];
    assign _2951 = { _460,
                     _2950 };
    assign _1398 = _107[8:7];
    assign _3987 = _1398 == _231;
    assign _3988 = _3987 ? _2951 : t1_x;
    assign _3985 = _1314 == _951;
    assign _3989 = _3985 ? _3988 : t1_x;
    assign _3984 = _1314 == _1598;
    assign _3994 = _3984 ? _3993 : _3989;
    assign _3983 = _1314 == _965;
    assign _3998 = _3983 ? _3997 : _3994;
    assign _3982 = _1314 == _473;
    assign _4004 = _3982 ? _4003 : _3998;
    assign _4005 = _1392 ? _4004 : t1_x;
    assign _4006 = _1309 ? t1_x : _4005;
    assign _4007 = _1303 ? t1_x : _4006;
    assign _4009 = _1297 ? _312 : _4007;
    assign _103 = _4009;
    assign _104 = _103;
    always @(posedge _146) begin
        if (_144)
            t1_x <= _312;
        else
            t1_x <= _104;
    end
    assign _4013 = t1_x == _312;
    assign _4014 = ~ _4013;
    assign _4015 = ~ _4014;
    assign _3970 = _107[8:6];
    always @* begin
        case (_3970)
        0:
            _4024 <= vdd;
        1:
            _4024 <= _4015;
        2:
            _4024 <= _4014;
        3:
            _4024 <= _4019;
        4:
            _4024 <= _4018;
        5:
            _4024 <= _4021;
        6:
            _4024 <= _4022;
        default:
            _4024 <= _4023;
        endcase
    end
    assign _4011 = _1314 == _473;
    assign _4025 = _4011 & _4024;
    assign _4031 = _4025 | _4030;
    assign _4039 = _4031 ? _4038 : _4033;
    always @(posedge _146) begin
        if (_144)
            t1_pc <= _576;
        else
            t1_pc <= _106;
    end
    assign _4040 = _1392 ? _4039 : t1_pc;
    assign _4041 = _1309 ? t1_pc : _4040;
    assign _4042 = _1303 ? t1_pc : _4041;
    assign _4043 = _1297 ? cfg_t1_start : _4042;
    assign _105 = _4043;
    assign _106 = _105;
    assign _4048 = _1291 ? _4047 : _106;
    assign _4044 = ~ _1291;
    RM_IHPSG13_1P_256x16_c2_bm_bist
        sram1
        ( .A_CLK(_146),
          .A_MEN(vdd),
          .A_WEN(_1291),
          .A_REN(_4044),
          .A_ADDR(_4048),
          .A_DIN(_622),
          .A_DLY(vdd),
          .A_BM(_4392),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_576),
          .A_BIST_DIN(_312),
          .A_BIST_BM(_312),
          .A_DOUT(_4054[15:0]) );
    assign _107 = _4054;
    assign _1314 = _107[15:13];
    assign _1316 = _1314 == _659;
    assign _1330 = _1316 & _1329;
    assign _1343 = _1330 & _1342;
    assign _1351 = _1343 | _1350;
    assign _1357 = _1351 | _1356;
    assign _1368 = _1357 | _1367;
    assign _1390 = _1368 | _1389;
    assign _1391 = ~ _1390;
    assign _1392 = _1313 & _1391;
    assign _4065 = _1392 ? _4064 : t1_delay_left;
    assign _1308 = t1_delay_left == _655;
    assign _1309 = ~ _1308;
    assign _4068 = _1309 ? _4067 : _4065;
    assign _1303 = ~ _1302;
    assign _4069 = _1303 ? t1_delay_left : _4068;
    assign _1297 = ~ _1296;
    assign _4071 = _1297 ? _655 : _4069;
    assign _108 = _4071;
    assign _109 = _108;
    always @(posedge _146) begin
        if (_144)
            t1_delay_left <= _655;
        else
            t1_delay_left <= _109;
    end
    assign _1312 = t1_delay_left == _655;
    assign _4083 = cfg_t1_clkdiv - _897;
    assign _4073 = 7'b1011101;
    assign _4074 = _618 == _4073;
    assign _4072 = _612 & _616;
    assign _4075 = _4072 & _4074;
    assign _4076 = _4075 ? _622 : cfg_t1_clkdiv;
    assign _110 = _4076;
    always @(posedge _146) begin
        if (_144)
            cfg_t1_clkdiv <= _312;
        else
            cfg_t1_clkdiv <= _110;
    end
    assign _4081 = cfg_t1_clkdiv == _312;
    assign _4085 = _4081 ? _312 : _4083;
    assign _4079 = t1_div_count - _897;
    assign _4086 = _1302 ? _4085 : _4079;
    assign _4077 = ~ _1296;
    assign _4088 = _4077 ? _312 : _4086;
    assign _111 = _4088;
    always @(posedge _146) begin
        if (_144)
            t1_div_count <= _312;
        else
            t1_div_count <= _111;
    end
    assign _1302 = t1_div_count == _312;
    assign _1290 = ~ _1288;
    assign _1289 = _632[1:1];
    assign _1291 = _1289 & _1290;
    always @(posedge _146) begin
        if (_144)
            t1_loaded <= _606;
        else
            t1_loaded <= _1291;
    end
    assign _1295 = ~ t1_loaded;
    assign _1288 = cfg_ctrl[1:1];
    assign _1296 = _1288 & _1295;
    assign _1310 = _1296 & _1302;
    assign _1313 = _1310 & _1312;
    assign _4091 = _1313 & _4090;
    assign _4093 = _4091 & _4092;
    assign _4095 = _4093 & _4094;
    assign _4097 = _4095 | _4096;
    assign _112 = _4097;
    assign _485 = _112 & _484;
    assign _4099 = { _4480,
                     _485 };
    assign _4100 = t1_rx_level + _4099;
    assign _4103 = _4100 - _4102;
    assign _113 = _4103;
    always @(posedge _146) begin
        if (_144)
            t1_rx_level <= _473;
        else
            t1_rx_level <= _113;
    end
    assign _2036 = t1_rx_level == _473;
    assign _4119 = _1211 ? _2036 : _3754;
    assign _4120 = ~ _4119;
    assign _1211 = cfg_buf_ctrl[2:2];
    assign _4115 = ~ _1211;
    assign _4116 = _1751 & _4115;
    assign _4117 = ~ _4116;
    assign _4108 = _622[9:0];
    assign _4105 = 7'b1101010;
    assign _4106 = _618 == _4105;
    assign _4104 = _612 & _616;
    assign _4107 = _4104 & _4106;
    assign _4109 = _4107 ? _4108 : cfg_buf_end;
    assign _114 = _4109;
    always @(posedge _146) begin
        if (_144)
            cfg_buf_end <= _532;
        else
            cfg_buf_end <= _114;
    end
    assign _4112 = buf_ptr == cfg_buf_end;
    assign _4113 = ~ _4112;
    assign _4111 = _1219 == _234;
    assign _4114 = _4111 & _4113;
    assign _4118 = _4114 & _4117;
    assign _4121 = _4118 & _4120;
    assign _115 = _4121;
    assign _4126 = _118 | _115;
    assign _4127 = _4126 | _3769;
    assign _4129 = _4127 | _4128;
    assign _4132 = _4129 ? _4131 : buf_ptr;
    assign _4123 = 7'b1101001;
    assign _4124 = _618 == _4123;
    assign _4122 = _612 & _616;
    assign _4125 = _4122 & _4124;
    assign _4134 = _4125 ? _4133 : _4132;
    assign _116 = _4134;
    always @(posedge _146) begin
        if (_144)
            buf_ptr <= _532;
        else
            buf_ptr <= _116;
    end
    assign _4143 = buf_ptr == cfg_buf_end;
    assign _4144 = ~ _4143;
    assign _4139 = _622[2:0];
    assign _4136 = 7'b1101000;
    assign _4137 = _618 == _4136;
    assign _4135 = _612 & _616;
    assign _4138 = _4135 & _4137;
    assign _4140 = _4138 ? _4139 : cfg_buf_ctrl;
    assign _117 = _4140;
    always @(posedge _146) begin
        if (_144)
            cfg_buf_ctrl <= _473;
        else
            cfg_buf_ctrl <= _117;
    end
    assign _1219 = cfg_buf_ctrl[1:0];
    assign _4142 = _1219 == _231;
    assign _4145 = _4142 & _4144;
    assign _4150 = _4145 & _4149;
    assign _4153 = _4150 & _4152;
    assign _4156 = _4153 & _4155;
    assign _118 = _4156;
    assign _1214 = _118 & _1213;
    assign _1227 = _1214 | _1226;
    assign _1231 = _1227 & _1230;
    assign _4158 = { _4480,
                     _1231 };
    assign _4159 = t0_tx_level + _4158;
    assign _4162 = _4159 - _4161;
    assign _119 = _4162;
    always @(posedge _146) begin
        if (_144)
            t0_tx_level <= _473;
        else
            t0_tx_level <= _119;
    end
    assign _824 = t0_tx_level == _473;
    assign _1267 = ~ _824;
    assign _4167 = _622[4:0];
    assign _4164 = 7'b1000101;
    assign _4165 = _618 == _4164;
    assign _4163 = _612 & _616;
    assign _4166 = _4163 & _4165;
    assign _4168 = _4166 ? _4167 : cfg_t0_threshold;
    assign _120 = _4168;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_threshold <= _462;
        else
            cfg_t0_threshold <= _120;
    end
    assign _1261 = _1259[4:0];
    assign _855 = { gnd,
                    _852 };
    assign _852 = _132[3:0];
    assign _854 = _852 == _655;
    assign _857 = _854 ? _1012 : _855;
    assign _1258 = { gnd,
                     _857 };
    assign _1257 = { gnd,
                     t0_osr_count };
    assign _1259 = _1257 + _1258;
    assign _1260 = _1879 < _1259;
    assign _1263 = _1260 ? _1012 : _1261;
    assign _1264 = _1263 < cfg_t0_threshold;
    assign _1265 = ~ _1264;
    assign _1253 = _658 == _965;
    assign _1254 = _867 & _1253;
    assign _1255 = _1254 & _835;
    assign _1266 = _1255 & _1265;
    assign _1268 = _1266 & _1267;
    assign _4185 = _1268 ? _838 : _1263;
    assign _821 = _132[8:8];
    assign _4182 = _821 ? _838 : _4170;
    assign _4176 = _942 == _4489;
    assign _4178 = _4176 ? _838 : _4170;
    assign _4179 = _948 ? _4178 : _4170;
    assign _4174 = _658 == _1598;
    assign _4180 = _4174 ? _4179 : _4170;
    assign _4173 = _658 == _4489;
    assign _4183 = _4173 ? _4182 : _4180;
    assign _4172 = _658 == _965;
    assign _4186 = _4172 ? _4185 : _4183;
    assign _4170 = _1271 ? _838 : t0_osr_count;
    assign _4187 = _867 ? _4186 : _4170;
    assign _4188 = _653 ? t0_osr_count : _4187;
    assign _4189 = _647 ? t0_osr_count : _4188;
    assign _4190 = _641 ? cfg_t0_threshold : _4189;
    assign _121 = _4190;
    assign _122 = _121;
    always @(posedge _146) begin
        if (_144)
            t0_osr_count <= _838;
        else
            t0_osr_count <= _122;
    end
    assign _840 = t0_osr_count < cfg_t0_threshold;
    assign _841 = ~ _840;
    assign _835 = cfg_t0_shift[2:2];
    assign _834 = _658 == _965;
    assign _836 = _834 & _835;
    assign _842 = _836 & _841;
    assign _1270 = _657 & _842;
    assign _1271 = _1270 & _1267;
    assign _4217 = _1271 ? _4216 : t0_osr;
    assign _4286 = _867 ? _4285 : _4217;
    assign _4287 = _653 ? t0_osr : _4286;
    assign _4288 = _647 ? t0_osr : _4287;
    assign _4290 = _641 ? _312 : _4288;
    assign _123 = _4290;
    assign _124 = _123;
    always @(posedge _146) begin
        if (_144)
            t0_osr <= _312;
        else
            t0_osr <= _124;
    end
    assign _1011 = t0_osr & _1010;
    assign _4295 = _622[5:0];
    assign _4292 = 7'b1001111;
    assign _4293 = _618 == _4292;
    assign _4291 = _612 & _616;
    assign _4294 = _4291 & _4293;
    assign _4296 = _4294 ? _4295 : cfg_t0_shift;
    assign _125 = _4296;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_shift <= _562;
        else
            cfg_t0_shift <= _125;
    end
    assign _979 = cfg_t0_shift[0:0];
    assign _1042 = _979 ? _1041 : _1011;
    assign _4311 = _132[8:7];
    assign _4313 = _4311 == _234;
    assign _4314 = _4313 ? _1042 : t0_y;
    assign _4307 = _942 == _659;
    assign _4308 = _4307 ? _2507 : t0_y;
    assign _4309 = _948 ? _4308 : t0_y;
    assign _4303 = _873 == _234;
    assign _4304 = _4303 ? _2368 : t0_y;
    assign _4301 = _658 == _951;
    assign _4305 = _4301 ? _4304 : t0_y;
    assign _4300 = _658 == _1598;
    assign _4310 = _4300 ? _4309 : _4305;
    assign _4299 = _658 == _965;
    assign _4315 = _4299 ? _4314 : _4310;
    assign _4298 = _658 == _473;
    assign _4322 = _4298 ? _4321 : _4315;
    assign _4323 = _867 ? _4322 : t0_y;
    assign _4324 = _653 ? t0_y : _4323;
    assign _4325 = _647 ? t0_y : _4324;
    assign _4327 = _641 ? _312 : _4325;
    assign _126 = _4327;
    assign _127 = _126;
    always @(posedge _146) begin
        if (_144)
            t0_y <= _312;
        else
            t0_y <= _127;
    end
    always @* begin
        case (_945)
        0:
            _2507 <= t0_x;
        1:
            _2507 <= t0_y;
        2:
            _2507 <= _2494;
        3:
            _2507 <= t0_isr;
        4:
            _2507 <= t0_osr;
        5:
            _2507 <= _312;
        default:
            _2507 <= _2506;
        endcase
    end
    assign _4337 = _942 == _473;
    assign _4338 = _4337 ? _2507 : t0_x;
    assign _945 = _132[5:3];
    assign _947 = _945 < _1570;
    assign _942 = _132[8:6];
    assign _944 = _942 < _1570;
    assign _948 = _944 & _947;
    assign _4339 = _948 ? _4338 : t0_x;
    assign _2367 = _132[4:0];
    assign _2368 = { _460,
                     _2367 };
    assign _873 = _132[8:7];
    assign _4333 = _873 == _231;
    assign _4334 = _4333 ? _2368 : t0_x;
    assign _4331 = _658 == _951;
    assign _4335 = _4331 ? _4334 : t0_x;
    assign _4330 = _658 == _1598;
    assign _4340 = _4330 ? _4339 : _4335;
    assign _4329 = _658 == _965;
    assign _4344 = _4329 ? _4343 : _4340;
    assign _4328 = _658 == _473;
    assign _4350 = _4328 ? _4349 : _4344;
    assign _4351 = _867 ? _4350 : t0_x;
    assign _4352 = _653 ? t0_x : _4351;
    assign _4353 = _647 ? t0_x : _4352;
    assign _4355 = _641 ? _312 : _4353;
    assign _128 = _4355;
    assign _129 = _128;
    always @(posedge _146) begin
        if (_144)
            t0_x <= _312;
        else
            t0_x <= _129;
    end
    assign _4359 = t0_x == _312;
    assign _4360 = ~ _4359;
    assign _4361 = ~ _4360;
    assign _4316 = _132[8:6];
    always @* begin
        case (_4316)
        0:
            _4370 <= vdd;
        1:
            _4370 <= _4361;
        2:
            _4370 <= _4360;
        3:
            _4370 <= _4365;
        4:
            _4370 <= _4364;
        5:
            _4370 <= _4367;
        6:
            _4370 <= _4368;
        default:
            _4370 <= _4369;
        endcase
    end
    assign _4357 = _658 == _473;
    assign _4371 = _4357 & _4370;
    assign _4377 = _4371 | _4376;
    assign _4385 = _4377 ? _4384 : _4379;
    always @(posedge _146) begin
        if (_144)
            t0_pc <= _576;
        else
            t0_pc <= _131;
    end
    assign _4386 = _867 ? _4385 : t0_pc;
    assign _4387 = _653 ? t0_pc : _4386;
    assign _4388 = _647 ? t0_pc : _4387;
    assign _4389 = _641 ? cfg_t0_start : _4388;
    assign _130 = _4389;
    assign _131 = _130;
    assign _4391 = _635 ? _4047 : _131;
    assign _4390 = ~ _635;
    RM_IHPSG13_1P_256x16_c2_bm_bist
        sram0
        ( .A_CLK(_146),
          .A_MEN(vdd),
          .A_WEN(_635),
          .A_REN(_4390),
          .A_ADDR(_4391),
          .A_DIN(_622),
          .A_DLY(vdd),
          .A_BM(_4392),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_576),
          .A_BIST_DIN(_312),
          .A_BIST_BM(_312),
          .A_DOUT(_4397[15:0]) );
    assign _132 = _4397;
    assign _658 = _132[15:13];
    assign _660 = _658 == _659;
    assign _805 = _660 & _804;
    assign _818 = _805 & _817;
    assign _826 = _818 | _825;
    assign _832 = _826 | _831;
    assign _843 = _832 | _842;
    assign _865 = _843 | _864;
    assign _866 = ~ _865;
    assign _867 = _657 & _866;
    assign _4408 = _867 ? _4407 : t0_delay_left;
    assign _652 = t0_delay_left == _655;
    assign _653 = ~ _652;
    assign _4411 = _653 ? _4410 : _4408;
    assign _647 = ~ _646;
    assign _4412 = _647 ? t0_delay_left : _4411;
    assign _641 = ~ _640;
    assign _4414 = _641 ? _655 : _4412;
    assign _133 = _4414;
    assign _134 = _133;
    always @(posedge _146) begin
        if (_144)
            t0_delay_left <= _655;
        else
            t0_delay_left <= _134;
    end
    assign _656 = t0_delay_left == _655;
    assign _4426 = cfg_t0_clkdiv - _897;
    assign _4416 = 7'b1001101;
    assign _4417 = _618 == _4416;
    assign _4415 = _612 & _616;
    assign _4418 = _4415 & _4417;
    assign _4419 = _4418 ? _622 : cfg_t0_clkdiv;
    assign _135 = _4419;
    always @(posedge _146) begin
        if (_144)
            cfg_t0_clkdiv <= _312;
        else
            cfg_t0_clkdiv <= _135;
    end
    assign _4424 = cfg_t0_clkdiv == _312;
    assign _4428 = _4424 ? _312 : _4426;
    assign _4422 = t0_div_count - _897;
    assign _4429 = _646 ? _4428 : _4422;
    assign _4420 = ~ _640;
    assign _4431 = _4420 ? _312 : _4429;
    assign _136 = _4431;
    always @(posedge _146) begin
        if (_144)
            t0_div_count <= _312;
        else
            t0_div_count <= _136;
    end
    assign _646 = t0_div_count == _312;
    assign _634 = ~ _625;
    assign _437 = 6'b110000;
    assign _4436 = _622[5:0];
    assign _4433 = 7'b1010000;
    assign _4434 = _618 == _4433;
    assign _4432 = _612 & _616;
    assign _4435 = _4432 & _4434;
    assign _4437 = _4435 ? _4436 : cfg_load;
    assign _137 = _4437;
    always @(posedge _146) begin
        if (_144)
            cfg_load <= _437;
        else
            cfg_load <= _137;
    end
    assign _631 = cfg_load[5:4];
    assign _627 = 7'b1000000;
    assign _628 = _618 < _627;
    assign _626 = _612 & _616;
    assign _629 = _626 & _628;
    assign _630 = { _629,
                    _629 };
    assign _632 = _630 & _631;
    assign _633 = _632[0:0];
    assign _635 = _633 & _634;
    always @(posedge _146) begin
        if (_144)
            t0_loaded <= _606;
        else
            t0_loaded <= _635;
    end
    assign _639 = ~ t0_loaded;
    assign _625 = cfg_ctrl[0:0];
    assign _640 = _625 & _639;
    assign _654 = _640 & _646;
    assign _657 = _654 & _656;
    assign _4440 = _657 & _4439;
    assign _4442 = _4440 & _4441;
    assign _4444 = _4442 & _4443;
    assign _4446 = _4444 | _4445;
    assign _138 = _4446;
    assign _378 = _138 & _377;
    assign _4448 = { _4480,
                     _378 };
    assign _4449 = t0_rx_level + _4448;
    assign _4452 = _4449 - _4451;
    assign _139 = _4452;
    always @(posedge _146) begin
        if (_144)
            t0_rx_level <= _473;
        else
            t0_rx_level <= _139;
    end
    assign _3754 = t0_rx_level == _473;
    assign _4473 = ~ _3754;
    assign _622 = _324[15:0];
    assign _4471 = _622[2:0];
    assign _618 = host_cmd[6:0];
    assign _4469 = _618 == _627;
    assign _319 = _148[2:2];
    always @(posedge _146) begin
        if (_144)
            host_mosi_s1 <= gnd;
        else
            host_mosi_s1 <= _319;
    end
    always @(posedge _146) begin
        if (_144)
            host_mosi_s2 <= gnd;
        else
            host_mosi_s2 <= host_mosi_s1;
    end
    assign _317 = 23'b00000000000000000000000;
    assign _4453 = _324[22:0];
    assign _4454 = _310 ? _4453 : host_shift_in;
    assign _4455 = host_cs_n_s2 ? host_shift_in : _4454;
    assign _140 = _4455;
    always @(posedge _146) begin
        if (_144)
            host_shift_in <= _317;
        else
            host_shift_in <= _140;
    end
    assign _324 = { host_shift_in,
                    host_mosi_s2 };
    assign _325 = _324[7:0];
    assign _315 = host_bit_count == _1581;
    assign _4456 = _315 ? _325 : host_cmd;
    assign _4457 = _310 ? _4456 : host_cmd;
    assign _4458 = host_cs_n_s2 ? host_cmd : _4457;
    assign _141 = _4458;
    always @(posedge _146) begin
        if (_144)
            host_cmd <= _576;
        else
            host_cmd <= _141;
    end
    assign _616 = host_cmd[7:7];
    assign _610 = 5'b10111;
    assign _4462 = host_bit_count + _1168;
    assign _4459 = 5'b11000;
    assign _4460 = host_bit_count < _4459;
    assign _4463 = _4460 ? _4462 : host_bit_count;
    assign _4464 = _310 ? _4463 : host_bit_count;
    assign _4466 = host_cs_n_s2 ? _838 : _4464;
    assign _142 = _4466;
    always @(posedge _146) begin
        if (_144)
            host_bit_count <= _838;
        else
            host_bit_count <= _142;
    end
    assign _611 = host_bit_count == _610;
    assign _282 = _148[1:1];
    always @(posedge _146) begin
        if (_144)
            host_cs_n_s1 <= vdd;
        else
            host_cs_n_s1 <= _282;
    end
    always @(posedge _146) begin
        if (_144)
            host_cs_n_s2 <= vdd;
        else
            host_cs_n_s2 <= host_cs_n_s1;
    end
    assign _309 = ~ host_cs_n_s2;
    always @(posedge _146) begin
        if (_144)
            host_sck_prev <= _606;
        else
            host_sck_prev <= host_sck_s2;
    end
    assign _307 = ~ host_sck_prev;
    assign vdd = 1'b1;
    assign _144 = clear;
    assign _146 = clock;
    assign _148 = ui_in;
    assign _287 = _148[0:0];
    always @(posedge _146) begin
        if (_144)
            host_sck_s1 <= gnd;
        else
            host_sck_s1 <= _287;
    end
    always @(posedge _146) begin
        if (_144)
            host_sck_s2 <= gnd;
        else
            host_sck_s2 <= host_sck_s1;
    end
    assign _308 = host_sck_s2 & _307;
    assign _310 = _308 & _309;
    assign _612 = _310 & _611;
    assign _4467 = _612 & _616;
    assign _4470 = _4467 & _4469;
    assign _4472 = _4470 ? _4471 : cfg_ctrl;
    assign _149 = _4472;
    always @(posedge _146) begin
        if (_144)
            cfg_ctrl <= _473;
        else
            cfg_ctrl <= _149;
    end
    assign _1751 = cfg_ctrl[2:2];
    assign _4474 = _1751 & _4473;
    assign _4476 = _4474 & _4475;
    assign _150 = _4476;
    assign _1739 = _150 | _1738;
    assign _1754 = _1739 | _1753;
    assign _1758 = _1754 & _1757;
    assign _4478 = { _4480,
                     _1758 };
    assign _4479 = t1_tx_level + _4478;
    assign _4482 = _4479 - _4481;
    assign _151 = _4482;
    always @(posedge _146) begin
        if (_144)
            t1_tx_level <= _473;
        else
            t1_tx_level <= _151;
    end
    assign _4484 = t1_tx_level == _4489;
    assign gnd = 1'b0;
    assign _4496 = { gnd,
                     _4484,
                     _4487,
                     _4488,
                     _4490,
                     _4493,
                     _4494,
                     _4495 };
    assign uo_out = _4496;
    assign uio_out = _281;
    assign uio_oe = _240;

endmodule
