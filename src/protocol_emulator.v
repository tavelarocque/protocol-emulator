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

    wire _231;
    wire _232;
    wire [1:0] _229;
    wire [1:0] _228;
    wire _230;
    wire _233;
    wire [1:0] _226;
    wire [1:0] _225;
    wire _227;
    wire _234;
    wire _221;
    wire _222;
    wire [1:0] _218;
    wire _220;
    wire _223;
    wire [1:0] _215;
    wire _217;
    wire _224;
    wire _211;
    wire _212;
    wire [1:0] _208;
    wire _210;
    wire _213;
    wire [1:0] _205;
    wire _207;
    wire _214;
    wire _201;
    wire _202;
    wire [1:0] _198;
    wire _200;
    wire _203;
    wire [1:0] _195;
    wire _197;
    wire _204;
    wire _191;
    wire _192;
    wire [1:0] _188;
    wire _190;
    wire _193;
    wire [1:0] _185;
    wire _187;
    wire _194;
    wire _181;
    wire _182;
    wire [1:0] _178;
    wire _180;
    wire _183;
    wire [1:0] _175;
    wire _177;
    wire _184;
    wire _171;
    wire _172;
    wire [1:0] _168;
    wire _170;
    wire _173;
    wire [1:0] _165;
    wire _167;
    wire _174;
    wire _161;
    wire _162;
    wire [1:0] _155;
    wire _157;
    wire _163;
    wire [1:0] _152;
    wire _154;
    wire _164;
    wire [7:0] _235;
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
    wire _239;
    wire [1:0] _236;
    wire _238;
    wire _240;
    wire [7:0] _276;
    wire [15:0] _307;
    wire _598;
    wire [14:0] _597;
    wire [15:0] _599;
    wire [1:0] _580;
    wire [13:0] _573;
    wire [15:0] _581;
    wire [7:0] _568;
    wire [15:0] _572;
    wire [15:0] _567;
    wire [6:0] _559;
    wire [15:0] _563;
    wire [5:0] _554;
    wire [15:0] _558;
    wire [15:0] _553;
    wire [12:0] _544;
    wire [15:0] _548;
    wire [9:0] _527;
    wire [15:0] _531;
    wire [15:0] _523;
    wire _511;
    wire [15:0] _515;
    wire [2:0] _468;
    wire _469;
    wire _470;
    wire [15:0] _507;
    wire [15:0] _464;
    wire [10:0] _455;
    wire [15:0] _459;
    wire [15:0] _454;
    wire [15:0] _449;
    wire [15:0] _444;
    wire [15:0] _439;
    wire [15:0] _434;
    wire [15:0] _429;
    wire [15:0] _424;
    wire [15:0] _416;
    wire _404;
    wire [15:0] _408;
    wire _362;
    wire _363;
    wire [15:0] _400;
    wire [15:0] _357;
    wire [15:0] _352;
    wire [15:0] _347;
    wire [15:0] _342;
    wire [15:0] _337;
    wire [15:0] _332;
    wire [15:0] _327;
    reg [15:0] _594;
    wire [15:0] _595;
    wire [15:0] _596;
    wire [4:0] _298;
    wire _299;
    wire _300;
    wire _293;
    wire _288;
    wire _292;
    wire _294;
    wire _301;
    wire [15:0] _600;
    wire [15:0] _601;
    wire [15:0] _3;
    reg [15:0] host_miso_shift;
    wire _4373;
    wire _4372;
    wire _4370;
    wire _4371;
    wire [2:0] _4367;
    wire _4368;
    wire _4366;
    wire _4364;
    wire _4365;
    wire [1:0] _4358;
    wire [2:0] _4359;
    wire _1848;
    wire _1843;
    wire _1837;
    wire _1838;
    wire _1836;
    wire _1839;
    wire _1840;
    wire [6:0] _1832;
    wire _1833;
    wire _1831;
    wire _1834;
    wire _1841;
    wire _1844;
    wire _4353;
    wire [2:0] _4329;
    wire _372;
    wire _4323;
    wire _4321;
    wire _4319;
    wire _4317;
    wire [3:0] _647;
    wire [3:0] _4287;
    wire [3:0] _4288;
    wire [1:0] _4282;
    wire [3:0] _4283;
    wire [3:0] _4279;
    wire [3:0] _4278;
    wire _4277;
    wire [3:0] _4280;
    wire _4276;
    wire [3:0] _4284;
    wire [3:0] _4285;
    wire _955;
    wire _371;
    wire _920;
    wire _919;
    wire _921;
    wire _922;
    wire _911;
    wire _913;
    wire _916;
    wire _908;
    wire _895;
    wire [2:0] _651;
    wire [15:0] _4270;
    wire [5:0] _4260;
    wire [7:0] _615;
    wire [6:0] _611;
    wire _612;
    wire _609;
    wire _613;
    wire [7:0] _616;
    wire [7:0] _4;
    reg [7:0] cfg_t0_start;
    wire [1:0] _973;
    wire [1:0] _967;
    wire [1:0] _965;
    wire _966;
    wire [1:0] _968;
    wire _963;
    wire [1:0] _969;
    wire [1:0] _970;
    wire [1:0] _971;
    wire [1:0] _972;
    wire [1:0] _974;
    wire [1:0] _5;
    wire [1:0] _6;
    reg [1:0] t0_page;
    wire [7:0] _4261;
    wire [7:0] _979;
    wire [6:0] _976;
    wire _977;
    wire _975;
    wire _978;
    wire [7:0] _980;
    wire [7:0] _7;
    reg [7:0] cfg_t0_timeout_vector;
    wire _4259;
    wire [7:0] _4262;
    wire [7:0] _4256;
    wire [7:0] _4257;
    wire [15:0] _988;
    wire [15:0] _989;
    wire [15:0] _990;
    wire [15:0] _991;
    wire [15:0] _992;
    wire [15:0] _994;
    wire [15:0] _8;
    wire [15:0] _9;
    reg [15:0] t0_wait_count;
    wire [6:0] _996;
    wire _997;
    wire _995;
    wire _998;
    wire [15:0] _999;
    wire [15:0] _10;
    reg [15:0] cfg_t0_timeout;
    wire _986;
    wire _983;
    wire _982;
    wire _984;
    wire _985;
    wire _987;
    wire _1001;
    wire _1003;
    wire _1004;
    wire _1005;
    wire _1007;
    wire _11;
    wire _12;
    reg t0_waiting;
    wire [15:0] _904;
    wire _906;
    wire _897;
    wire _907;
    wire _893;
    wire _891;
    wire _890;
    wire _889;
    wire _888;
    wire _887;
    wire _886;
    wire _885;
    wire _884;
    wire [2:0] _653;
    reg _892;
    wire _894;
    wire _4252;
    wire _4251;
    wire _4253;
    wire _4254;
    wire _4247;
    wire _4246;
    wire _4244;
    wire _4245;
    wire _4241;
    wire _4242;
    wire _4243;
    wire [15:0] _4226;
    wire [2:0] _4223;
    wire _4224;
    wire [15:0] _4227;
    wire _4220;
    wire [15:0] _4221;
    wire _2382;
    wire [1:0] _2383;
    wire [3:0] _2384;
    wire [7:0] _2385;
    wire [15:0] _2386;
    wire [31:0] _2387;
    wire [31:0] _1063;
    wire [6:0] _1009;
    wire _1010;
    wire _1008;
    wire _1011;
    wire [15:0] _1012;
    wire [15:0] _13;
    reg [15:0] cfg_t0_crc_init_lo;
    wire [6:0] _1014;
    wire _1015;
    wire _1013;
    wire _1016;
    wire [15:0] _1017;
    wire [15:0] _14;
    reg [15:0] cfg_t0_crc_init_hi;
    wire [31:0] _1294;
    wire [15:0] _1291;
    wire [31:0] _1292;
    wire [31:0] _1293;
    wire [31:0] _1295;
    wire [31:0] _1296;
    wire _1289;
    wire [31:0] _1297;
    wire _1277;
    wire _1276;
    wire _1275;
    wire _1274;
    wire _1273;
    wire _1272;
    wire _1271;
    wire _1270;
    wire _1269;
    wire _1268;
    wire _1267;
    wire _1266;
    wire _1265;
    wire _1264;
    wire _1263;
    wire _1262;
    wire [4:0] _1259;
    wire [4:0] _1260;
    wire [3:0] _1261;
    reg _1278;
    wire [15:0] _1256;
    wire [15:0] _1257;
    wire _1258;
    wire _1072;
    wire _1279;
    wire _1069;
    wire _1280;
    wire [1:0] _1281;
    wire [3:0] _1282;
    wire [7:0] _1283;
    wire [15:0] _1284;
    wire [31:0] _1285;
    wire [6:0] _1019;
    wire _1020;
    wire _1018;
    wire _1021;
    wire [15:0] _1022;
    wire [15:0] _15;
    reg [15:0] cfg_t0_crc_poly_lo;
    wire [6:0] _1024;
    wire _1025;
    wire _1023;
    wire _1026;
    wire [15:0] _1027;
    wire [15:0] _16;
    reg [15:0] cfg_t0_crc_poly_hi;
    wire [31:0] _1068;
    wire [31:0] _1286;
    wire [30:0] _1066;
    wire [31:0] _1067;
    wire [31:0] _1287;
    wire _1059;
    wire [2:0] _1056;
    wire _1057;
    wire _1055;
    wire _1060;
    wire [2:0] _1042;
    wire _1043;
    wire _1044;
    wire _1041;
    wire _1046;
    wire _1047;
    wire _1032;
    wire _1048;
    wire _1049;
    wire _1050;
    wire _1051;
    wire _1053;
    wire _17;
    wire _18;
    reg t0_crc_run;
    wire _1054;
    wire _1061;
    wire [31:0] _1288;
    wire [31:0] _1298;
    wire [31:0] _1299;
    wire [31:0] _1300;
    wire [31:0] _1301;
    wire [31:0] _19;
    wire [31:0] _20;
    reg [31:0] t0_crc;
    wire [31:0] _2388;
    wire [15:0] _2389;
    wire [15:0] _2377;
    wire [15:0] _4198;
    wire _4196;
    wire [15:0] _4199;
    wire [15:0] _1129;
    wire [31:0] _1130;
    wire [23:0] _1125;
    wire [31:0] _1126;
    wire [27:0] _1121;
    wire [31:0] _1122;
    wire [29:0] _1117;
    wire [31:0] _1118;
    wire [30:0] _1113;
    wire [31:0] _1114;
    wire [31:0] _1111;
    wire _1109;
    wire [31:0] _1115;
    wire _1108;
    wire [31:0] _1119;
    wire _1107;
    wire [31:0] _1123;
    wire _1106;
    wire [31:0] _1127;
    wire [4:0] _1103;
    wire [4:0] _1104;
    wire _1105;
    wire [31:0] _1131;
    wire [15:0] _1132;
    wire [15:0] _4156;
    wire [31:0] _4158;
    wire [23:0] _4152;
    wire [31:0] _4154;
    wire [27:0] _4148;
    wire [31:0] _4150;
    wire [29:0] _4144;
    wire [31:0] _4146;
    wire [30:0] _4140;
    wire [31:0] _4142;
    wire [31:0] _4139;
    wire _4137;
    wire [31:0] _4143;
    wire _4136;
    wire [31:0] _4147;
    wire _4135;
    wire [31:0] _4151;
    wire _4134;
    wire [31:0] _4155;
    wire _4133;
    wire [31:0] _4159;
    wire [15:0] _4160;
    wire [15:0] _4129;
    wire [31:0] _4130;
    wire [23:0] _4125;
    wire [31:0] _4126;
    wire [27:0] _4121;
    wire [31:0] _4122;
    wire [29:0] _4117;
    wire [31:0] _4118;
    wire [30:0] _4113;
    wire [31:0] _4114;
    wire [31:0] _4111;
    wire _4109;
    wire [31:0] _4115;
    wire _4108;
    wire [31:0] _4119;
    wire _4107;
    wire [31:0] _4123;
    wire _4106;
    wire [31:0] _4127;
    wire _4105;
    wire [31:0] _4131;
    wire [15:0] _4132;
    wire [15:0] _4161;
    wire [15:0] _4162;
    wire [15:0] _4103;
    wire _4099;
    wire [15:0] _4100;
    wire [15:0] _4101;
    wire _4098;
    wire [15:0] _4102;
    wire _4097;
    wire [15:0] _4104;
    wire _4096;
    wire [15:0] _4163;
    wire _4091;
    wire _4092;
    reg [15:0] t0_tx_mem_3;
    wire _4085;
    wire _4086;
    reg [15:0] t0_tx_mem_2;
    wire _4079;
    wire _4080;
    reg [15:0] t0_tx_mem_1;
    wire [1:0] _1327;
    wire [1:0] _1328;
    wire [1:0] _21;
    reg [1:0] t0_tx_wr;
    wire _4073;
    wire _4074;
    wire [15:0] _4069;
    reg [15:0] t0_tx_mem_0;
    wire [1:0] _1335;
    wire [1:0] _1336;
    wire [1:0] _22;
    reg [1:0] t0_tx_rd;
    reg [15:0] _4094;
    wire [4:0] _929;
    wire _1329;
    wire _1341;
    wire _1338;
    wire _1339;
    wire _1340;
    wire _1342;
    wire _1360;
    wire _1363;
    wire _23;
    wire _1330;
    wire [2:0] _4039;
    wire _1321;
    wire _1314;
    wire _1312;
    wire _1315;
    wire _1316;
    wire [6:0] _1307;
    wire _1308;
    wire _1306;
    wire _1309;
    wire _1317;
    wire _1304;
    wire _1847;
    wire _1320;
    wire _4032;
    wire _4033;
    wire _4029;
    wire _4030;
    reg buf_wrote;
    wire _4027;
    wire [9:0] _4011;
    wire [9:0] _4008;
    wire [9:0] _4009;
    wire [6:0] _1370;
    wire _1371;
    wire _1367;
    wire _1368;
    wire _1369;
    wire _1372;
    wire _24;
    wire _4006;
    wire [2:0] _3980;
    wire _479;
    wire _3974;
    wire _3972;
    wire _3970;
    wire _3968;
    wire [3:0] _3945;
    wire [1:0] _3939;
    wire [3:0] _3940;
    wire _3934;
    wire [3:0] _3937;
    wire _3933;
    wire [3:0] _3941;
    wire [3:0] _3942;
    wire _1480;
    wire _478;
    wire _1445;
    wire _1444;
    wire _1446;
    wire _1447;
    wire _1436;
    wire _1438;
    wire _1441;
    wire _1433;
    wire _1420;
    wire [5:0] _3924;
    wire [1:0] _3923;
    wire [7:0] _3925;
    wire [5:0] _3914;
    wire [7:0] _1377;
    wire [6:0] _1374;
    wire _1375;
    wire _1373;
    wire _1376;
    wire [7:0] _1378;
    wire [7:0] _25;
    reg [7:0] cfg_t1_start;
    wire [1:0] _1498;
    wire [1:0] _1492;
    wire _1491;
    wire [1:0] _1493;
    wire _1488;
    wire [1:0] _1494;
    wire [1:0] _1495;
    wire [1:0] _1496;
    wire [1:0] _1497;
    wire [1:0] _1499;
    wire [1:0] _26;
    wire [1:0] _27;
    reg [1:0] t1_page;
    wire [7:0] _3915;
    wire [7:0] _1504;
    wire [6:0] _1501;
    wire _1502;
    wire _1500;
    wire _1503;
    wire [7:0] _1505;
    wire [7:0] _28;
    reg [7:0] cfg_t1_timeout_vector;
    wire _3913;
    wire [7:0] _3916;
    wire [7:0] _3911;
    wire [15:0] _1514;
    wire [15:0] _1515;
    wire [15:0] _1516;
    wire [15:0] _1517;
    wire [15:0] _1519;
    wire [15:0] _29;
    wire [15:0] _30;
    reg [15:0] t1_wait_count;
    wire [6:0] _1521;
    wire _1522;
    wire _1520;
    wire _1523;
    wire [15:0] _1524;
    wire [15:0] _31;
    reg [15:0] cfg_t1_timeout;
    wire _1511;
    wire _1508;
    wire _1507;
    wire _1509;
    wire _1510;
    wire _1512;
    wire _1526;
    wire _1528;
    wire _1529;
    wire _1530;
    wire _1532;
    wire _32;
    wire _33;
    reg t1_waiting;
    wire [15:0] _1429;
    wire _1431;
    wire _1422;
    wire _1432;
    wire _1418;
    wire _1416;
    wire _1415;
    wire _1414;
    wire _1413;
    wire _1412;
    wire _1411;
    wire _1410;
    wire _1409;
    wire [2:0] _1408;
    reg _1417;
    wire _1419;
    wire _3906;
    wire _3905;
    wire _3907;
    wire _3908;
    wire _3901;
    wire _3900;
    wire _3898;
    wire _3899;
    wire _3895;
    wire _3896;
    wire _3897;
    wire [15:0] _3880;
    wire _3878;
    wire [15:0] _3881;
    wire _3874;
    wire [15:0] _3875;
    wire _1878;
    wire [1:0] _1879;
    wire [3:0] _1880;
    wire [7:0] _1881;
    wire [15:0] _1882;
    wire [31:0] _1883;
    wire [6:0] _1534;
    wire _1535;
    wire _1533;
    wire _1536;
    wire [15:0] _1537;
    wire [15:0] _34;
    reg [15:0] cfg_t1_crc_init_lo;
    wire [6:0] _1539;
    wire _1540;
    wire _1538;
    wire _1541;
    wire [15:0] _1542;
    wire [15:0] _35;
    reg [15:0] cfg_t1_crc_init_hi;
    wire [31:0] _1819;
    wire [15:0] _1816;
    wire [31:0] _1817;
    wire [31:0] _1818;
    wire [31:0] _1820;
    wire [31:0] _1821;
    wire _1814;
    wire [31:0] _1822;
    wire _1802;
    wire _1801;
    wire _1800;
    wire _1799;
    wire _1798;
    wire _1797;
    wire _1796;
    wire _1795;
    wire _1794;
    wire _1793;
    wire _1792;
    wire _1791;
    wire _1790;
    wire _1789;
    wire _1788;
    wire _1787;
    wire [4:0] _1785;
    wire [3:0] _1786;
    reg _1803;
    wire [15:0] _1781;
    wire [15:0] _1782;
    wire _1783;
    wire _1597;
    wire _1804;
    wire _1594;
    wire _1805;
    wire [1:0] _1806;
    wire [3:0] _1807;
    wire [7:0] _1808;
    wire [15:0] _1809;
    wire [31:0] _1810;
    wire [6:0] _1544;
    wire _1545;
    wire _1543;
    wire _1546;
    wire [15:0] _1547;
    wire [15:0] _36;
    reg [15:0] cfg_t1_crc_poly_lo;
    wire [6:0] _1549;
    wire _1550;
    wire _1548;
    wire _1551;
    wire [15:0] _1552;
    wire [15:0] _37;
    reg [15:0] cfg_t1_crc_poly_hi;
    wire [31:0] _1593;
    wire [31:0] _1811;
    wire [30:0] _1591;
    wire [31:0] _1592;
    wire [31:0] _1812;
    wire _1584;
    wire _1582;
    wire _1580;
    wire _1585;
    wire _1568;
    wire _1569;
    wire _1566;
    wire _1571;
    wire _1572;
    wire _1557;
    wire _1573;
    wire _1574;
    wire _1575;
    wire _1576;
    wire _1578;
    wire _38;
    wire _39;
    reg t1_crc_run;
    wire _1579;
    wire _1586;
    wire [31:0] _1813;
    wire [31:0] _1823;
    wire [31:0] _1824;
    wire [31:0] _1825;
    wire [31:0] _1826;
    wire [31:0] _40;
    wire [31:0] _41;
    reg [31:0] t1_crc;
    wire [31:0] _1884;
    wire [15:0] _1885;
    wire [15:0] _1876;
    wire [15:0] _3852;
    wire _3850;
    wire [15:0] _3853;
    wire [15:0] _1654;
    wire [31:0] _1655;
    wire [23:0] _1650;
    wire [31:0] _1651;
    wire [27:0] _1646;
    wire [31:0] _1647;
    wire [29:0] _1642;
    wire [31:0] _1643;
    wire [30:0] _1638;
    wire [31:0] _1639;
    wire [31:0] _1636;
    wire _1634;
    wire [31:0] _1640;
    wire _1633;
    wire [31:0] _1644;
    wire _1632;
    wire [31:0] _1648;
    wire _1631;
    wire [31:0] _1652;
    wire [4:0] _1629;
    wire _1630;
    wire [31:0] _1656;
    wire [15:0] _1657;
    wire [15:0] _3810;
    wire [31:0] _3812;
    wire [23:0] _3806;
    wire [31:0] _3808;
    wire [27:0] _3802;
    wire [31:0] _3804;
    wire [29:0] _3798;
    wire [31:0] _3800;
    wire [30:0] _3794;
    wire [31:0] _3796;
    wire [31:0] _3793;
    wire _3791;
    wire [31:0] _3797;
    wire _3790;
    wire [31:0] _3801;
    wire _3789;
    wire [31:0] _3805;
    wire _3788;
    wire [31:0] _3809;
    wire _3787;
    wire [31:0] _3813;
    wire [15:0] _3814;
    wire [15:0] _3783;
    wire [31:0] _3784;
    wire [23:0] _3779;
    wire [31:0] _3780;
    wire [27:0] _3775;
    wire [31:0] _3776;
    wire [29:0] _3771;
    wire [31:0] _3772;
    wire [30:0] _3767;
    wire [31:0] _3768;
    wire [31:0] _3765;
    wire _3763;
    wire [31:0] _3769;
    wire _3762;
    wire [31:0] _3773;
    wire _3761;
    wire [31:0] _3777;
    wire _3760;
    wire [31:0] _3781;
    wire _3759;
    wire [31:0] _3785;
    wire [15:0] _3786;
    wire [15:0] _3815;
    wire [15:0] _3816;
    wire [15:0] _3757;
    wire _3753;
    wire [15:0] _3754;
    wire [15:0] _3755;
    wire _3752;
    wire [15:0] _3756;
    wire _3751;
    wire [15:0] _3758;
    wire _3750;
    wire [15:0] _3817;
    wire _3745;
    wire _3746;
    reg [15:0] t1_tx_mem_3;
    wire _3739;
    wire _3740;
    reg [15:0] t1_tx_mem_2;
    wire _3733;
    wire _3734;
    reg [15:0] t1_tx_mem_1;
    wire [1:0] _1854;
    wire [1:0] _1855;
    wire [1:0] _42;
    reg [1:0] t1_tx_wr;
    wire _3727;
    wire _3728;
    wire [15:0] _43;
    wire _503;
    wire _504;
    reg [15:0] t1_rx_mem_3;
    wire _497;
    wire _498;
    reg [15:0] t1_rx_mem_2;
    wire _491;
    wire _492;
    reg [15:0] t1_rx_mem_1;
    wire [1:0] _1857;
    wire [1:0] _1858;
    wire [1:0] _44;
    reg [1:0] t1_rx_wr;
    wire _485;
    wire _486;
    wire [15:0] _2096;
    wire [31:0] _2098;
    wire [23:0] _2092;
    wire [31:0] _2094;
    wire [27:0] _2088;
    wire [31:0] _2090;
    wire [29:0] _2084;
    wire [31:0] _2086;
    wire [31:0] _2082;
    wire [31:0] _2081;
    wire _2080;
    wire [31:0] _2083;
    wire _2079;
    wire [31:0] _2087;
    wire _2078;
    wire [31:0] _2091;
    wire _2077;
    wire [31:0] _2095;
    wire _2076;
    wire [31:0] _2099;
    wire [15:0] _2100;
    wire [15:0] _2101;
    wire [15:0] _2102;
    wire [15:0] _2072;
    wire [31:0] _2073;
    wire [23:0] _2068;
    wire [31:0] _2069;
    wire [27:0] _2064;
    wire [31:0] _2065;
    wire [29:0] _2060;
    wire [31:0] _2061;
    wire [30:0] _2056;
    wire [31:0] _2057;
    wire [31:0] _2054;
    wire _2052;
    wire [31:0] _2058;
    wire _2051;
    wire [31:0] _2062;
    wire _2050;
    wire [31:0] _2066;
    wire _2049;
    wire [31:0] _2070;
    wire [4:0] _2047;
    wire _2048;
    wire [31:0] _2074;
    wire [15:0] _2075;
    wire [15:0] _2103;
    wire [15:0] _2038;
    wire [31:0] _2040;
    wire [23:0] _2034;
    wire [31:0] _2036;
    wire [27:0] _2030;
    wire [31:0] _2032;
    wire [29:0] _2026;
    wire [31:0] _2028;
    wire _2022;
    wire [31:0] _2025;
    wire _2021;
    wire [31:0] _2029;
    wire _2020;
    wire [31:0] _2033;
    wire _2019;
    wire [31:0] _2037;
    wire _2018;
    wire [31:0] _2041;
    wire [15:0] _2042;
    wire [15:0] _2043;
    wire [15:0] _2044;
    wire [15:0] _2014;
    wire [31:0] _2015;
    wire [23:0] _2010;
    wire [31:0] _2011;
    wire [27:0] _2006;
    wire [31:0] _2007;
    wire [29:0] _2002;
    wire [31:0] _2003;
    wire [30:0] _1998;
    wire [31:0] _1999;
    wire [15:0] _1621;
    wire [31:0] _1623;
    wire [23:0] _1617;
    wire [31:0] _1619;
    wire [27:0] _1613;
    wire [31:0] _1615;
    wire [29:0] _1609;
    wire [31:0] _1611;
    wire _1605;
    wire [31:0] _1608;
    wire _1604;
    wire [31:0] _1612;
    wire _1603;
    wire [31:0] _1616;
    wire _1602;
    wire [31:0] _1620;
    wire _1601;
    wire [31:0] _1624;
    wire [15:0] _1625;
    wire [15:0] _1626;
    wire [15:0] _1948;
    wire [15:0] _1943;
    wire [31:0] _1945;
    wire [23:0] _1939;
    wire [31:0] _1941;
    wire [27:0] _1935;
    wire [31:0] _1937;
    wire [29:0] _1931;
    wire [31:0] _1933;
    wire [30:0] _1927;
    wire [31:0] _1929;
    wire [31:0] _1926;
    wire _1924;
    wire [31:0] _1930;
    wire _1923;
    wire [31:0] _1934;
    wire _1922;
    wire [31:0] _1938;
    wire _1921;
    wire [31:0] _1942;
    wire _1920;
    wire [31:0] _1946;
    wire [15:0] _1947;
    wire [15:0] _1949;
    wire [15:0] _1916;
    wire [31:0] _1917;
    wire [23:0] _1912;
    wire [31:0] _1913;
    wire [27:0] _1908;
    wire [31:0] _1909;
    wire [29:0] _1904;
    wire [31:0] _1905;
    wire [30:0] _1900;
    wire [31:0] _1901;
    wire _1769;
    wire _1766;
    wire _1765;
    wire _1764;
    wire _1763;
    wire _1762;
    wire _1761;
    wire _1760;
    wire _1759;
    reg _1767;
    wire _1770;
    wire _1757;
    wire _1754;
    wire _1753;
    wire _1752;
    wire _1751;
    wire _1750;
    wire _1749;
    wire _1748;
    wire _1747;
    wire [2:0] _1746;
    reg _1755;
    wire _1758;
    wire [4:0] _1742;
    wire _1743;
    wire _1740;
    wire _1739;
    wire _1738;
    wire _1737;
    wire _1736;
    wire _1735;
    wire _1734;
    wire _1733;
    wire [2:0] _1732;
    reg _1741;
    wire _1744;
    wire [4:0] _1728;
    wire _1729;
    wire _1726;
    wire _1725;
    wire _1724;
    wire _1723;
    wire _1722;
    wire _1721;
    wire _1720;
    wire _1719;
    wire [2:0] _1718;
    reg _1727;
    wire _1730;
    wire [4:0] _1714;
    wire _1715;
    wire _1712;
    wire _1711;
    wire _1710;
    wire _1709;
    wire _1708;
    wire _1707;
    wire _1706;
    wire _1705;
    wire [2:0] _1704;
    reg _1713;
    wire _1716;
    wire [4:0] _1700;
    wire _1701;
    wire _1698;
    wire _1697;
    wire _1696;
    wire _1695;
    wire _1694;
    wire _1693;
    wire _1692;
    wire _1691;
    wire [2:0] _1689;
    wire [2:0] _1690;
    reg _1699;
    wire _1702;
    wire [4:0] _1686;
    wire _1687;
    wire _1684;
    wire _1683;
    wire _1682;
    wire _1681;
    wire _1680;
    wire _1679;
    wire _1678;
    wire _1677;
    wire [2:0] _1676;
    reg _1685;
    wire _1688;
    wire [4:0] _1672;
    wire _1673;
    wire _1670;
    wire _1669;
    wire _1668;
    wire _1667;
    wire _1666;
    wire _1665;
    wire _1664;
    wire _1663;
    wire [2:0] _1661;
    wire [2:0] _1863;
    wire [6:0] _1860;
    wire _1861;
    wire _1859;
    wire _1862;
    wire [2:0] _1864;
    wire [2:0] _45;
    reg [2:0] cfg_t1_in_base;
    wire [2:0] _1662;
    reg _1671;
    wire _1674;
    wire [7:0] _1771;
    wire [15:0] _1772;
    wire [1:0] _1659;
    reg [15:0] _1780;
    wire [31:0] _1898;
    wire _1897;
    wire [31:0] _1902;
    wire _1896;
    wire [31:0] _1906;
    wire _1895;
    wire [31:0] _1910;
    wire _1894;
    wire [31:0] _1914;
    wire _1893;
    wire [31:0] _1918;
    wire [15:0] _1919;
    wire [15:0] _1950;
    wire [15:0] _1952;
    wire [15:0] _1891;
    wire _1874;
    wire [15:0] _1887;
    wire [15:0] _1888;
    wire _1872;
    wire [15:0] _1889;
    wire _1871;
    wire [15:0] _1892;
    wire _1869;
    wire [15:0] _1953;
    wire [15:0] _1954;
    wire [15:0] _1955;
    wire [15:0] _1956;
    wire [15:0] _1958;
    wire [15:0] _46;
    wire [15:0] _47;
    reg [15:0] t1_isr;
    wire [31:0] _1996;
    wire _1994;
    wire [31:0] _2000;
    wire _1993;
    wire [31:0] _2004;
    wire _1992;
    wire [31:0] _2008;
    wire _1991;
    wire [31:0] _2012;
    wire [4:0] _1975;
    wire [5:0] _1972;
    wire [5:0] _1971;
    wire [5:0] _1973;
    wire [5:0] _1970;
    wire _1974;
    wire [4:0] _1977;
    wire [5:0] _1476;
    wire [5:0] _1474;
    wire [5:0] _1467;
    wire [5:0] _1475;
    wire _1477;
    wire _1478;
    wire _1462;
    wire _1461;
    wire _1463;
    wire _1479;
    wire [4:0] _1979;
    wire [4:0] _1968;
    wire _1962;
    wire [4:0] _1964;
    wire [4:0] _1965;
    wire _1961;
    wire [4:0] _1966;
    wire _1960;
    wire [4:0] _1969;
    wire _1959;
    wire [4:0] _1980;
    wire [4:0] _1981;
    wire [4:0] _1982;
    wire [4:0] _1983;
    wire [4:0] _1985;
    wire [4:0] _48;
    wire [4:0] _49;
    reg [4:0] t1_isr_count;
    wire [4:0] _1989;
    wire _1990;
    wire [31:0] _2016;
    wire [15:0] _2017;
    wire _1596;
    wire [15:0] _2045;
    wire _1987;
    wire [15:0] _2104;
    wire [15:0] _50;
    reg [15:0] t1_rx_mem_0;
    wire [1:0] _2131;
    wire _2128;
    wire _2123;
    wire _2124;
    wire _2118;
    wire _2116;
    wire _2119;
    wire _2120;
    wire _2112;
    wire _2113;
    wire [6:0] _2108;
    wire _2109;
    wire _2105;
    wire _2106;
    wire _2107;
    wire _2110;
    wire _2114;
    wire _51;
    wire _2121;
    wire _2125;
    wire _2129;
    wire [1:0] _2132;
    wire [1:0] _52;
    reg [1:0] t1_rx_rd;
    reg [15:0] _506;
    wire _396;
    wire _397;
    reg [15:0] t0_rx_mem_3;
    wire _390;
    wire _391;
    reg [15:0] t0_rx_mem_2;
    wire _384;
    wire _385;
    reg [15:0] t0_rx_mem_1;
    wire [1:0] _2134;
    wire [1:0] _2135;
    wire [1:0] _53;
    reg [1:0] t0_rx_wr;
    wire _378;
    wire _379;
    wire [15:0] _3598;
    wire [31:0] _3600;
    wire [23:0] _3594;
    wire [31:0] _3596;
    wire [27:0] _3590;
    wire [31:0] _3592;
    wire [29:0] _3586;
    wire [31:0] _3588;
    wire _3582;
    wire [31:0] _3585;
    wire _3581;
    wire [31:0] _3589;
    wire _3580;
    wire [31:0] _3593;
    wire _3579;
    wire [31:0] _3597;
    wire _3578;
    wire [31:0] _3601;
    wire [15:0] _3602;
    wire [15:0] _3603;
    wire [15:0] _3604;
    wire [15:0] _3574;
    wire [31:0] _3575;
    wire [23:0] _3570;
    wire [31:0] _3571;
    wire [27:0] _3566;
    wire [31:0] _3567;
    wire [29:0] _3562;
    wire [31:0] _3563;
    wire [30:0] _3558;
    wire [31:0] _3559;
    wire [31:0] _3556;
    wire _3554;
    wire [31:0] _3560;
    wire _3553;
    wire [31:0] _3564;
    wire _3552;
    wire [31:0] _3568;
    wire _3551;
    wire [31:0] _3572;
    wire [4:0] _3549;
    wire _3550;
    wire [31:0] _3576;
    wire [15:0] _3577;
    wire [15:0] _3605;
    wire [15:0] _3540;
    wire [31:0] _3542;
    wire [23:0] _3536;
    wire [31:0] _3538;
    wire [27:0] _3532;
    wire [31:0] _3534;
    wire [29:0] _3528;
    wire [31:0] _3530;
    wire _3524;
    wire [31:0] _3527;
    wire _3523;
    wire [31:0] _3531;
    wire _3522;
    wire [31:0] _3535;
    wire _3521;
    wire [31:0] _3539;
    wire _3520;
    wire [31:0] _3543;
    wire [15:0] _3544;
    wire [15:0] _3545;
    wire [15:0] _3546;
    wire [15:0] _3516;
    wire [31:0] _3517;
    wire [23:0] _3512;
    wire [31:0] _3513;
    wire [27:0] _3508;
    wire [31:0] _3509;
    wire [29:0] _3504;
    wire [31:0] _3505;
    wire [30:0] _3500;
    wire [31:0] _3501;
    wire [15:0] _1096;
    wire [31:0] _1098;
    wire [23:0] _1092;
    wire [31:0] _1094;
    wire [27:0] _1088;
    wire [31:0] _1090;
    wire [29:0] _1084;
    wire [31:0] _1086;
    wire _1080;
    wire [31:0] _1083;
    wire _1079;
    wire [31:0] _1087;
    wire _1078;
    wire [31:0] _1091;
    wire _1077;
    wire [31:0] _1095;
    wire _1076;
    wire [31:0] _1099;
    wire [15:0] _1100;
    wire [15:0] _1101;
    wire [15:0] _3450;
    wire [15:0] _3445;
    wire [31:0] _3447;
    wire [23:0] _3441;
    wire [31:0] _3443;
    wire [27:0] _3437;
    wire [31:0] _3439;
    wire [29:0] _3433;
    wire [31:0] _3435;
    wire [30:0] _3429;
    wire [31:0] _3431;
    wire [31:0] _3428;
    wire _3426;
    wire [31:0] _3432;
    wire _3425;
    wire [31:0] _3436;
    wire _3424;
    wire [31:0] _3440;
    wire _3423;
    wire [31:0] _3444;
    wire _3422;
    wire [31:0] _3448;
    wire [15:0] _3449;
    wire [15:0] _3451;
    wire [15:0] _3418;
    wire [31:0] _3419;
    wire [23:0] _3414;
    wire [31:0] _3415;
    wire [27:0] _3410;
    wire [31:0] _3411;
    wire [29:0] _3406;
    wire [31:0] _3407;
    wire [30:0] _3402;
    wire [31:0] _3403;
    wire _1244;
    wire _1241;
    wire _1240;
    wire _1239;
    wire _1238;
    wire _1237;
    wire _1236;
    wire _1235;
    wire _1234;
    reg _1242;
    wire _1245;
    wire _1232;
    wire _1229;
    wire _1228;
    wire _1227;
    wire _1226;
    wire _1225;
    wire _1224;
    wire _1223;
    wire _1222;
    wire [2:0] _1221;
    reg _1230;
    wire _1233;
    wire _1218;
    wire _1215;
    wire _1214;
    wire _1213;
    wire _1212;
    wire _1211;
    wire _1210;
    wire _1209;
    wire _1208;
    wire [2:0] _1207;
    reg _1216;
    wire _1219;
    wire _1204;
    wire _1201;
    wire _1200;
    wire _1199;
    wire _1198;
    wire _1197;
    wire _1196;
    wire _1195;
    wire _1194;
    wire [2:0] _1193;
    reg _1202;
    wire _1205;
    wire _1190;
    wire _1187;
    wire _1186;
    wire _1185;
    wire _1184;
    wire _1183;
    wire _1182;
    wire _1181;
    wire _1180;
    wire [2:0] _1179;
    reg _1188;
    wire _1191;
    wire _1176;
    wire _1173;
    wire _1172;
    wire _1171;
    wire _1170;
    wire _1169;
    wire _1168;
    wire _1167;
    wire _1166;
    wire [2:0] _1165;
    reg _1174;
    wire _1177;
    wire _1162;
    wire _1159;
    wire _1158;
    wire _1157;
    wire _1156;
    wire _1155;
    wire _1154;
    wire _1153;
    wire _1152;
    wire [2:0] _1151;
    reg _1160;
    wire _1163;
    wire _1148;
    wire _1145;
    wire _1144;
    wire _1143;
    wire _1142;
    wire _1141;
    wire _1140;
    wire _1139;
    wire _879;
    wire _878;
    wire _877;
    wire [1:0] _876;
    reg _880;
    wire _874;
    wire _875;
    wire _881;
    wire _871;
    wire _872;
    wire _882;
    wire _866;
    wire _865;
    wire _864;
    wire [1:0] _863;
    reg _867;
    wire _861;
    wire _862;
    wire _868;
    wire _858;
    wire _859;
    wire _869;
    wire _853;
    wire _852;
    wire _851;
    wire [1:0] _850;
    reg _854;
    wire _848;
    wire _849;
    wire _855;
    wire _845;
    wire _846;
    wire _856;
    wire _840;
    wire _839;
    wire _838;
    wire [1:0] _837;
    reg _841;
    wire _835;
    wire _836;
    wire _842;
    wire _832;
    wire _833;
    wire _843;
    wire _827;
    wire _826;
    wire _825;
    wire [1:0] _824;
    reg _828;
    wire _822;
    wire _823;
    wire _829;
    wire _819;
    wire _820;
    wire _830;
    wire _814;
    wire _813;
    wire _812;
    wire [1:0] _811;
    reg _815;
    wire _809;
    wire _810;
    wire _816;
    wire _806;
    wire _807;
    wire _817;
    wire _801;
    wire _800;
    wire _799;
    wire [1:0] _798;
    reg _802;
    wire _796;
    wire _797;
    wire _803;
    wire _793;
    wire _794;
    wire _804;
    wire _2137;
    wire _2139;
    wire _2140;
    wire _54;
    reg smp_data;
    wire _779;
    wire _780;
    wire _781;
    wire _720;
    wire _721;
    wire _2158;
    wire _2159;
    wire [7:0] _2145;
    wire [6:0] _2142;
    wire _2143;
    wire _2141;
    wire _2144;
    wire [7:0] _2146;
    wire [7:0] _55;
    reg [7:0] cfg_smp_sync;
    wire [6:0] _2152;
    wire _2138;
    wire [7:0] _2153;
    wire [7:0] _2150;
    wire [7:0] _2151;
    wire _766;
    wire _767;
    wire [7:0] _2154;
    wire [7:0] _2155;
    wire [7:0] _2156;
    wire [7:0] _56;
    reg [7:0] smp_history;
    wire [6:0] _773;
    wire _768;
    wire _769;
    wire [7:0] _774;
    wire _775;
    wire _776;
    wire _777;
    wire _778;
    wire _2160;
    wire _2161;
    wire _2162;
    wire _57;
    reg smp_synced;
    wire _722;
    wire [4:0] _717;
    wire _718;
    wire _709;
    wire [4:0] _762;
    wire [4:0] _763;
    wire [4:0] _692;
    wire [4:0] _713;
    wire [4:0] _714;
    wire _706;
    wire _707;
    wire [2:0] _751;
    wire [2:0] _2167;
    wire _2164;
    wire _2165;
    wire [2:0] _2168;
    wire [2:0] _2170;
    wire [2:0] _2171;
    wire [2:0] _58;
    reg [2:0] smp_missed;
    wire _702;
    wire _748;
    wire _749;
    wire [2:0] _752;
    wire [2:0] _754;
    wire _755;
    wire [2:0] _700;
    wire _747;
    wire _756;
    wire _745;
    wire _757;
    wire _743;
    wire _744;
    wire _758;
    wire _759;
    wire _2173;
    wire _59;
    reg smp_carrier;
    wire [14:0] _565;
    wire [14:0] _2178;
    wire [6:0] _2175;
    wire _2176;
    wire _2174;
    wire _2177;
    wire [14:0] _2179;
    wire [14:0] _60;
    reg [14:0] cfg_smp_time;
    wire [4:0] _696;
    wire _697;
    wire _698;
    wire _699;
    wire _708;
    wire _711;
    wire [4:0] _716;
    wire _740;
    wire _741;
    wire _739;
    wire _742;
    wire _760;
    wire [4:0] _765;
    wire [4:0] _2181;
    wire [4:0] _61;
    reg [4:0] smp_phase;
    wire _693;
    wire _694;
    wire _731;
    wire _730;
    wire _729;
    wire _728;
    wire _727;
    wire _726;
    wire _725;
    wire _724;
    reg _732;
    reg smp_fall;
    reg smp_mid;
    wire _2183;
    wire _62;
    reg smp_last;
    wire _683;
    wire _682;
    wire _681;
    wire _680;
    wire _679;
    wire _678;
    wire _677;
    wire _676;
    reg _684;
    wire _688;
    wire _695;
    wire _710;
    wire _719;
    wire _723;
    wire _782;
    wire _783;
    reg smp_strobe;
    wire _674;
    wire [7:0] _159;
    wire _3352;
    wire _3351;
    wire _3350;
    wire _3349;
    wire _3348;
    wire _3347;
    wire _3346;
    wire _3345;
    reg _3353;
    wire _3344;
    wire [3:0] _3342;
    wire [2:0] _3339;
    wire [3:0] _3340;
    wire _3343;
    wire _3354;
    wire _3335;
    wire _3334;
    wire _3333;
    wire _3332;
    wire _3331;
    wire _3330;
    wire _3329;
    wire _3328;
    reg _3336;
    wire _3327;
    wire [3:0] _3325;
    wire [2:0] _3322;
    wire [3:0] _3323;
    wire _3326;
    wire _3337;
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
    wire [3:0] _3308;
    wire [2:0] _3305;
    wire [3:0] _3306;
    wire _3309;
    wire _3320;
    wire _3301;
    wire _3300;
    wire _3299;
    wire _3298;
    wire _3297;
    wire _3296;
    wire _3295;
    wire _3294;
    reg _3302;
    wire _3293;
    wire [3:0] _3291;
    wire [2:0] _3288;
    wire [3:0] _3289;
    wire _3292;
    wire _3303;
    wire _3284;
    wire _3283;
    wire _3282;
    wire _3281;
    wire _3280;
    wire _3279;
    wire _3278;
    wire _3277;
    reg _3285;
    wire _3276;
    wire [3:0] _3274;
    wire [2:0] _3271;
    wire [3:0] _3272;
    wire _3275;
    wire _3286;
    wire _3267;
    wire _3266;
    wire _3265;
    wire _3264;
    wire _3263;
    wire _3262;
    wire _3261;
    wire _3260;
    reg _3268;
    wire _3259;
    wire [3:0] _3257;
    wire [2:0] _3254;
    wire [3:0] _3255;
    wire _3258;
    wire _3269;
    wire _3250;
    wire _3249;
    wire _3248;
    wire _3247;
    wire _3246;
    wire _3245;
    wire _3244;
    wire _3243;
    reg _3251;
    wire _3242;
    wire [3:0] _3240;
    wire [2:0] _3237;
    wire [3:0] _3238;
    wire _3241;
    wire _3252;
    wire _3233;
    wire _3232;
    wire _3231;
    wire _3230;
    wire _3229;
    wire _3228;
    wire _3227;
    wire [1:0] _3220;
    wire [3:0] _3221;
    wire [2:0] _3216;
    wire [3:0] _3217;
    wire [3:0] _3214;
    wire _3213;
    wire [3:0] _3218;
    wire _3212;
    wire [3:0] _3222;
    wire [2:0] _3209;
    wire [2:0] _3210;
    wire _3211;
    wire [3:0] _3224;
    wire [7:0] _3225;
    wire _3226;
    reg _3234;
    wire _3201;
    wire _3200;
    wire _3199;
    wire _3198;
    wire _3197;
    wire _3196;
    wire _3195;
    wire _3194;
    reg _3202;
    wire _3193;
    wire [2:0] _3190;
    wire [4:0] _3191;
    wire _3192;
    wire _3203;
    wire _3185;
    wire _3184;
    wire _3183;
    wire _3182;
    wire _3181;
    wire _3180;
    wire _3179;
    wire _3178;
    reg _3186;
    wire _3177;
    wire [2:0] _3174;
    wire [4:0] _3175;
    wire _3176;
    wire _3187;
    wire _3169;
    wire _3168;
    wire _3167;
    wire _3166;
    wire _3165;
    wire _3164;
    wire _3163;
    wire _3162;
    reg _3170;
    wire _3161;
    wire [2:0] _3158;
    wire [4:0] _3159;
    wire _3160;
    wire _3171;
    wire _3153;
    wire _3152;
    wire _3151;
    wire _3150;
    wire _3149;
    wire _3148;
    wire _3147;
    wire _3146;
    reg _3154;
    wire _3145;
    wire [2:0] _3142;
    wire [4:0] _3143;
    wire _3144;
    wire _3155;
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
    wire [2:0] _3126;
    wire [4:0] _3127;
    wire _3128;
    wire _3139;
    wire _3121;
    wire _3120;
    wire _3119;
    wire _3118;
    wire _3117;
    wire _3116;
    wire _3115;
    wire _3114;
    reg _3122;
    wire _3113;
    wire [2:0] _3110;
    wire [4:0] _3111;
    wire _3112;
    wire _3123;
    wire _3105;
    wire _3104;
    wire _3103;
    wire _3102;
    wire _3101;
    wire _3100;
    wire _3099;
    wire _3098;
    reg _3106;
    wire _3097;
    wire [2:0] _3094;
    wire [4:0] _3095;
    wire _3096;
    wire _3107;
    wire _3089;
    wire _3088;
    wire _3087;
    wire _3086;
    wire _3085;
    wire _3084;
    wire _3083;
    wire _3082;
    reg _3090;
    wire _3081;
    wire [2:0] _3078;
    wire [4:0] _3079;
    wire _3080;
    wire _3091;
    wire [7:0] _3204;
    wire _3071;
    wire _3070;
    wire _3069;
    wire _3068;
    wire _3067;
    wire _3066;
    wire _3065;
    wire _3064;
    reg _3072;
    wire _3063;
    wire [2:0] _3060;
    wire [3:0] _3061;
    wire _3062;
    wire _3073;
    wire _3056;
    wire _3055;
    wire _3054;
    wire _3053;
    wire _3052;
    wire _3051;
    wire _3050;
    wire _3049;
    reg _3057;
    wire _3048;
    wire [2:0] _3045;
    wire [3:0] _3046;
    wire _3047;
    wire _3058;
    wire _3041;
    wire _3040;
    wire _3039;
    wire _3038;
    wire _3037;
    wire _3036;
    wire _3035;
    wire _3034;
    reg _3042;
    wire _3033;
    wire [2:0] _3030;
    wire [3:0] _3031;
    wire _3032;
    wire _3043;
    wire _3026;
    wire _3025;
    wire _3024;
    wire _3023;
    wire _3022;
    wire _3021;
    wire _3020;
    wire _3019;
    reg _3027;
    wire _3018;
    wire [2:0] _3015;
    wire [3:0] _3016;
    wire _3017;
    wire _3028;
    wire _3011;
    wire _3010;
    wire _3009;
    wire _3008;
    wire _3007;
    wire _3006;
    wire _3005;
    wire _3004;
    reg _3012;
    wire _3003;
    wire [2:0] _3000;
    wire [3:0] _3001;
    wire _3002;
    wire _3013;
    wire _2996;
    wire _2995;
    wire _2994;
    wire _2993;
    wire _2992;
    wire _2991;
    wire _2990;
    wire _2989;
    reg _2997;
    wire _2988;
    wire [2:0] _2985;
    wire [3:0] _2986;
    wire _2987;
    wire _2998;
    wire _2981;
    wire _2980;
    wire _2979;
    wire _2978;
    wire _2977;
    wire _2976;
    wire _2975;
    wire _2974;
    reg _2982;
    wire _2973;
    wire [2:0] _2970;
    wire [3:0] _2971;
    wire _2972;
    wire _2983;
    wire _2966;
    wire _2965;
    wire _2964;
    wire _2963;
    wire _2962;
    wire _2961;
    wire _2960;
    wire _2959;
    reg _2967;
    wire _2958;
    wire [3:0] _2956;
    wire [7:0] _442;
    wire [7:0] _2188;
    wire [6:0] _2185;
    wire _2186;
    wire _2184;
    wire _2187;
    wire [7:0] _2189;
    wire [7:0] _63;
    reg [7:0] cfg_t1_out_cfg;
    wire [2:0] _2953;
    wire [2:0] _2954;
    wire [3:0] _2955;
    wire _2957;
    wire _2968;
    wire [7:0] _3074;
    wire _2947;
    wire _2946;
    wire _2945;
    wire _2944;
    wire _2943;
    wire _2942;
    wire _2941;
    wire _2940;
    reg _2948;
    wire _2939;
    wire [2:0] _2936;
    wire [3:0] _2937;
    wire _2938;
    wire _2949;
    wire _2932;
    wire _2931;
    wire _2930;
    wire _2929;
    wire _2928;
    wire _2927;
    wire _2926;
    wire _2925;
    reg _2933;
    wire _2924;
    wire [2:0] _2921;
    wire [3:0] _2922;
    wire _2923;
    wire _2934;
    wire _2917;
    wire _2916;
    wire _2915;
    wire _2914;
    wire _2913;
    wire _2912;
    wire _2911;
    wire _2910;
    reg _2918;
    wire _2909;
    wire [2:0] _2906;
    wire [3:0] _2907;
    wire _2908;
    wire _2919;
    wire _2902;
    wire _2901;
    wire _2900;
    wire _2899;
    wire _2898;
    wire _2897;
    wire _2896;
    wire _2895;
    reg _2903;
    wire _2894;
    wire [2:0] _2891;
    wire [3:0] _2892;
    wire _2893;
    wire _2904;
    wire _2887;
    wire _2886;
    wire _2885;
    wire _2884;
    wire _2883;
    wire _2882;
    wire _2881;
    wire _2880;
    reg _2888;
    wire _2879;
    wire [2:0] _2876;
    wire [3:0] _2877;
    wire _2878;
    wire _2889;
    wire _2872;
    wire _2871;
    wire _2870;
    wire _2869;
    wire _2868;
    wire _2867;
    wire _2866;
    wire _2865;
    reg _2873;
    wire _2864;
    wire [2:0] _2861;
    wire [3:0] _2862;
    wire _2863;
    wire _2874;
    wire _2857;
    wire _2856;
    wire _2855;
    wire _2854;
    wire _2853;
    wire _2852;
    wire _2851;
    wire _2850;
    reg _2858;
    wire _2849;
    wire [2:0] _2846;
    wire [3:0] _2847;
    wire _2848;
    wire _2859;
    wire _2842;
    wire _2841;
    wire _2840;
    wire _2839;
    wire _2838;
    wire _2837;
    wire _2836;
    wire _2835;
    reg _2843;
    wire _2831;
    wire [3:0] _2829;
    wire [7:0] _2194;
    wire [6:0] _2191;
    wire _2192;
    wire _2190;
    wire _2193;
    wire [7:0] _2195;
    wire [7:0] _64;
    reg [7:0] cfg_t1_set_cfg;
    wire [2:0] _2826;
    wire [2:0] _2827;
    wire [3:0] _2828;
    wire _2830;
    wire _2844;
    wire [7:0] _2950;
    wire _2784;
    wire _2783;
    wire _2782;
    wire _2781;
    wire _2780;
    wire _2779;
    wire _2778;
    wire _2777;
    reg _2785;
    wire _2776;
    wire [3:0] _2774;
    wire [2:0] _2771;
    wire [3:0] _2772;
    wire _2775;
    wire _2786;
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
    wire [3:0] _2757;
    wire [2:0] _2754;
    wire [3:0] _2755;
    wire _2758;
    wire _2769;
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
    wire [3:0] _2740;
    wire [2:0] _2737;
    wire [3:0] _2738;
    wire _2741;
    wire _2752;
    wire _2733;
    wire _2732;
    wire _2731;
    wire _2730;
    wire _2729;
    wire _2728;
    wire _2727;
    wire _2726;
    reg _2734;
    wire _2725;
    wire [3:0] _2723;
    wire [2:0] _2720;
    wire [3:0] _2721;
    wire _2724;
    wire _2735;
    wire _2716;
    wire _2715;
    wire _2714;
    wire _2713;
    wire _2712;
    wire _2711;
    wire _2710;
    wire _2709;
    reg _2717;
    wire _2708;
    wire [3:0] _2706;
    wire [2:0] _2703;
    wire [3:0] _2704;
    wire _2707;
    wire _2718;
    wire _2699;
    wire _2698;
    wire _2697;
    wire _2696;
    wire _2695;
    wire _2694;
    wire _2693;
    wire _2692;
    reg _2700;
    wire _2691;
    wire [3:0] _2689;
    wire [2:0] _2686;
    wire [3:0] _2687;
    wire _2690;
    wire _2701;
    wire _2682;
    wire _2681;
    wire _2680;
    wire _2679;
    wire _2678;
    wire _2677;
    wire _2676;
    wire _2675;
    reg _2683;
    wire _2674;
    wire [3:0] _2672;
    wire [2:0] _2669;
    wire [3:0] _2670;
    wire _2673;
    wire _2684;
    wire _2665;
    wire _2664;
    wire _2663;
    wire _2662;
    wire _2661;
    wire _2660;
    wire _2659;
    wire [1:0] _2652;
    wire [3:0] _2653;
    wire [2:0] _2648;
    wire [3:0] _2649;
    wire [3:0] _2646;
    wire _2645;
    wire [3:0] _2650;
    wire _2644;
    wire [3:0] _2654;
    wire [2:0] _2641;
    wire [2:0] _2642;
    wire _2643;
    wire [3:0] _2656;
    wire [7:0] _2657;
    wire _2658;
    reg _2666;
    wire _2633;
    wire _2632;
    wire _2631;
    wire _2630;
    wire _2629;
    wire _2628;
    wire _2627;
    wire _2626;
    reg _2634;
    wire _2625;
    wire [2:0] _2622;
    wire [4:0] _2623;
    wire _2624;
    wire _2635;
    wire _2617;
    wire _2616;
    wire _2615;
    wire _2614;
    wire _2613;
    wire _2612;
    wire _2611;
    wire _2610;
    reg _2618;
    wire _2609;
    wire [2:0] _2606;
    wire [4:0] _2607;
    wire _2608;
    wire _2619;
    wire _2601;
    wire _2600;
    wire _2599;
    wire _2598;
    wire _2597;
    wire _2596;
    wire _2595;
    wire _2594;
    reg _2602;
    wire _2593;
    wire [2:0] _2590;
    wire [4:0] _2591;
    wire _2592;
    wire _2603;
    wire _2585;
    wire _2584;
    wire _2583;
    wire _2582;
    wire _2581;
    wire _2580;
    wire _2579;
    wire _2578;
    reg _2586;
    wire _2577;
    wire [2:0] _2574;
    wire [4:0] _2575;
    wire _2576;
    wire _2587;
    wire _2569;
    wire _2568;
    wire _2567;
    wire _2566;
    wire _2565;
    wire _2564;
    wire _2563;
    wire _2562;
    reg _2570;
    wire _2561;
    wire [2:0] _2558;
    wire [4:0] _2559;
    wire _2560;
    wire _2571;
    wire _2553;
    wire _2552;
    wire _2551;
    wire _2550;
    wire _2549;
    wire _2548;
    wire _2547;
    wire _2546;
    reg _2554;
    wire _2545;
    wire [2:0] _2542;
    wire [4:0] _2543;
    wire _2544;
    wire _2555;
    wire _2537;
    wire _2536;
    wire _2535;
    wire _2534;
    wire _2533;
    wire _2532;
    wire _2531;
    wire _2530;
    reg _2538;
    wire _2529;
    wire [2:0] _2526;
    wire [4:0] _2527;
    wire _2528;
    wire _2539;
    wire _2521;
    wire _2520;
    wire _2519;
    wire _2518;
    wire _2517;
    wire _2516;
    wire _2515;
    wire _2514;
    reg _2522;
    wire _2513;
    wire [2:0] _2510;
    wire [4:0] _2511;
    wire _2512;
    wire _2523;
    wire [7:0] _2636;
    wire _2503;
    wire _2502;
    wire _2501;
    wire _2500;
    wire _2499;
    wire _2498;
    wire _2497;
    wire _2496;
    reg _2504;
    wire _2495;
    wire [2:0] _2492;
    wire [3:0] _2493;
    wire _2494;
    wire _2505;
    wire _2488;
    wire _2487;
    wire _2486;
    wire _2485;
    wire _2484;
    wire _2483;
    wire _2482;
    wire _2481;
    reg _2489;
    wire _2480;
    wire [2:0] _2477;
    wire [3:0] _2478;
    wire _2479;
    wire _2490;
    wire _2473;
    wire _2472;
    wire _2471;
    wire _2470;
    wire _2469;
    wire _2468;
    wire _2467;
    wire _2466;
    reg _2474;
    wire _2465;
    wire [2:0] _2462;
    wire [3:0] _2463;
    wire _2464;
    wire _2475;
    wire _2458;
    wire _2457;
    wire _2456;
    wire _2455;
    wire _2454;
    wire _2453;
    wire _2452;
    wire _2451;
    reg _2459;
    wire _2450;
    wire [2:0] _2447;
    wire [3:0] _2448;
    wire _2449;
    wire _2460;
    wire _2443;
    wire _2442;
    wire _2441;
    wire _2440;
    wire _2439;
    wire _2438;
    wire _2437;
    wire _2436;
    reg _2444;
    wire _2435;
    wire [2:0] _2432;
    wire [3:0] _2433;
    wire _2434;
    wire _2445;
    wire _2428;
    wire _2427;
    wire _2426;
    wire _2425;
    wire _2424;
    wire _2423;
    wire _2422;
    wire _2421;
    reg _2429;
    wire _2420;
    wire [2:0] _2417;
    wire [3:0] _2418;
    wire _2419;
    wire _2430;
    wire _2413;
    wire _2412;
    wire _2411;
    wire _2410;
    wire _2409;
    wire _2408;
    wire _2407;
    wire _2406;
    reg _2414;
    wire _2405;
    wire [2:0] _2402;
    wire [3:0] _2403;
    wire _2404;
    wire _2415;
    wire _2398;
    wire _2397;
    wire _2396;
    wire _2395;
    wire _2394;
    wire _2393;
    wire _2392;
    wire _2391;
    reg _2399;
    wire _2375;
    wire [3:0] _2373;
    wire [7:0] _2200;
    wire [6:0] _2197;
    wire _2198;
    wire _2196;
    wire _2199;
    wire [7:0] _2201;
    wire [7:0] _65;
    reg [7:0] cfg_t0_out_cfg;
    wire [2:0] _2370;
    wire [2:0] _2371;
    wire [3:0] _2372;
    wire _2374;
    wire _2400;
    wire [7:0] _2506;
    wire _2364;
    wire _2363;
    wire _2362;
    wire _2361;
    wire _2360;
    wire _2359;
    wire _2358;
    wire _2357;
    reg _2365;
    wire _2356;
    wire [2:0] _2353;
    wire [3:0] _2354;
    wire _2355;
    wire _2366;
    wire _2349;
    wire _2348;
    wire _2347;
    wire _2346;
    wire _2345;
    wire _2344;
    wire _2343;
    wire _2342;
    reg _2350;
    wire _2341;
    wire [2:0] _2338;
    wire [3:0] _2339;
    wire _2340;
    wire _2351;
    wire _2334;
    wire _2333;
    wire _2332;
    wire _2331;
    wire _2330;
    wire _2329;
    wire _2328;
    wire _2327;
    reg _2335;
    wire _2326;
    wire [2:0] _2323;
    wire [3:0] _2324;
    wire _2325;
    wire _2336;
    wire _2319;
    wire _2318;
    wire _2317;
    wire _2316;
    wire _2315;
    wire _2314;
    wire _2313;
    wire _2312;
    reg _2320;
    wire _2311;
    wire [2:0] _2308;
    wire [3:0] _2309;
    wire _2310;
    wire _2321;
    wire _2304;
    wire _2303;
    wire _2302;
    wire _2301;
    wire _2300;
    wire _2299;
    wire _2298;
    wire _2297;
    reg _2305;
    wire _2296;
    wire [2:0] _2293;
    wire [3:0] _2294;
    wire _2295;
    wire _2306;
    wire _2289;
    wire _2288;
    wire _2287;
    wire _2286;
    wire _2285;
    wire _2284;
    wire _2283;
    wire _2282;
    reg _2290;
    wire _2281;
    wire [2:0] _2278;
    wire [3:0] _2279;
    wire _2280;
    wire _2291;
    wire _2274;
    wire _2273;
    wire _2272;
    wire _2271;
    wire _2270;
    wire _2269;
    wire _2268;
    wire _2267;
    reg _2275;
    wire _2266;
    wire [2:0] _2263;
    wire [3:0] _2264;
    wire _2265;
    wire _2276;
    wire _2259;
    wire _2258;
    wire _2257;
    wire _2256;
    wire _2255;
    wire _2254;
    wire _2253;
    wire _2252;
    reg _2260;
    wire _2248;
    wire [3:0] _2246;
    wire [7:0] _2206;
    wire [6:0] _2203;
    wire _2204;
    wire _2202;
    wire _2205;
    wire [7:0] _2207;
    wire [7:0] _66;
    reg [7:0] cfg_t0_set_cfg;
    wire [2:0] _2243;
    wire [2:0] _2244;
    wire [3:0] _2245;
    wire _2247;
    wire _2261;
    wire [7:0] _2367;
    wire _2240;
    wire _2237;
    wire _2238;
    wire _2241;
    wire [7:0] _2368;
    wire _2233;
    wire _2234;
    wire _2230;
    wire _2231;
    wire _2235;
    wire [7:0] _2507;
    wire [1:0] _2225;
    wire _2227;
    wire _2223;
    wire _2224;
    wire _2228;
    wire [7:0] _2637;
    wire _2638;
    wire [1:0] _2219;
    wire [3:0] _2220;
    wire [5:0] _2212;
    wire [6:0] _2209;
    wire _2210;
    wire _2208;
    wire _2211;
    wire [5:0] _2213;
    wire [5:0] _67;
    reg [5:0] cfg_t0_sideset;
    wire [2:0] _2215;
    wire [2:0] _2216;
    wire [3:0] _2217;
    wire _2221;
    wire _2667;
    wire [7:0] _2787;
    wire [7:0] _2788;
    wire [7:0] _2789;
    wire [7:0] _2790;
    wire [7:0] _68;
    wire _2823;
    wire _2820;
    wire _2821;
    wire _2824;
    wire [7:0] _2951;
    wire _2816;
    wire _2817;
    wire _2813;
    wire _2814;
    wire _2818;
    wire [7:0] _3075;
    wire [1:0] _2808;
    wire _2810;
    wire _2806;
    wire _2807;
    wire _2811;
    wire [7:0] _3205;
    wire _3206;
    wire [1:0] _2802;
    wire [3:0] _2803;
    wire [5:0] _2795;
    wire [6:0] _2792;
    wire _2793;
    wire _2791;
    wire _2794;
    wire [5:0] _2796;
    wire [5:0] _69;
    reg [5:0] cfg_t1_sideset;
    wire [2:0] _2798;
    wire [2:0] _2799;
    wire [3:0] _2800;
    wire _2804;
    wire _3235;
    wire [7:0] _3355;
    wire [7:0] _3356;
    wire [7:0] _3357;
    wire [7:0] _3358;
    wire [7:0] _70;
    wire [7:0] _71;
    reg [7:0] pin_out;
    wire _673;
    wire [7:0] _669;
    reg [7:0] pins_sync1;
    reg [7:0] pins_sync2;
    wire [7:0] _670;
    wire [7:0] _3363;
    wire [6:0] _3360;
    wire _3361;
    wire _3359;
    wire _3362;
    wire [7:0] _3364;
    wire [7:0] _72;
    reg [7:0] cfg_sync_bypass;
    wire [7:0] _74;
    wire [7:0] _663;
    wire [7:0] _671;
    wire _672;
    wire [6:0] _3366;
    wire _3367;
    wire _3365;
    wire _3368;
    wire [15:0] _3369;
    wire [15:0] _75;
    reg [15:0] cfg_pin_modes;
    wire [1:0] _662;
    reg _675;
    wire _660;
    wire _661;
    wire _787;
    wire [2:0] _655;
    wire _657;
    wire [8:0] _561;
    wire [8:0] _3374;
    wire [6:0] _3371;
    wire _3372;
    wire _3370;
    wire _3373;
    wire [8:0] _3375;
    wire [8:0] _76;
    reg [8:0] cfg_smp_ctrl;
    wire _654;
    wire _658;
    wire _791;
    wire [7:0] _883;
    wire _1138;
    wire [2:0] _3380;
    wire [6:0] _3377;
    wire _3378;
    wire _3376;
    wire _3379;
    wire [2:0] _3381;
    wire [2:0] _77;
    reg [2:0] cfg_t0_in_base;
    wire [2:0] _1137;
    reg _1146;
    wire _1149;
    wire [7:0] _1246;
    wire [15:0] _1247;
    wire [1:0] _1134;
    reg [15:0] _1255;
    wire [31:0] _3400;
    wire _3399;
    wire [31:0] _3404;
    wire _3398;
    wire [31:0] _3408;
    wire _3397;
    wire [31:0] _3412;
    wire _3396;
    wire [31:0] _3416;
    wire _3395;
    wire [31:0] _3420;
    wire [15:0] _3421;
    wire [15:0] _3452;
    wire [15:0] _3454;
    wire [15:0] _3393;
    wire _3388;
    wire [15:0] _3389;
    wire [15:0] _3390;
    wire _3386;
    wire [15:0] _3391;
    wire _3385;
    wire [15:0] _3394;
    wire _3383;
    wire [15:0] _3455;
    wire [15:0] _3456;
    wire [15:0] _3457;
    wire [15:0] _3458;
    wire [15:0] _3460;
    wire [15:0] _78;
    wire [15:0] _79;
    reg [15:0] t0_isr;
    wire [31:0] _3498;
    wire _3496;
    wire [31:0] _3502;
    wire _3495;
    wire [31:0] _3506;
    wire _3494;
    wire [31:0] _3510;
    wire _3493;
    wire [31:0] _3514;
    wire [4:0] _3477;
    wire [5:0] _3474;
    wire [5:0] _3473;
    wire [5:0] _3475;
    wire _3476;
    wire [4:0] _3479;
    wire [5:0] _951;
    wire [5:0] _949;
    wire [5:0] _942;
    wire [5:0] _950;
    wire _952;
    wire _953;
    wire _937;
    wire _936;
    wire _938;
    wire _954;
    wire [4:0] _3481;
    wire [4:0] _3470;
    wire _3464;
    wire [4:0] _3466;
    wire [4:0] _3467;
    wire _3463;
    wire [4:0] _3468;
    wire _3462;
    wire [4:0] _3471;
    wire _3461;
    wire [4:0] _3482;
    wire [4:0] _3483;
    wire [4:0] _3484;
    wire [4:0] _3485;
    wire [4:0] _3487;
    wire [4:0] _80;
    wire [4:0] _81;
    reg [4:0] t0_isr_count;
    wire [4:0] _3491;
    wire _3492;
    wire [31:0] _3518;
    wire [15:0] _3519;
    wire _1071;
    wire [15:0] _3547;
    wire _3489;
    wire [15:0] _3606;
    wire [15:0] _82;
    reg [15:0] t0_rx_mem_0;
    wire [1:0] _3636;
    wire _3633;
    wire _3628;
    wire _3629;
    wire _3624;
    wire _3620;
    wire _3618;
    wire _3621;
    wire _3622;
    wire _3614;
    wire _3615;
    wire [6:0] _3610;
    wire [6:0] _321;
    wire _3611;
    wire _3607;
    wire _3608;
    wire _1365;
    wire _1366;
    wire _3609;
    wire _3612;
    wire _3616;
    wire _83;
    wire _3623;
    wire _3625;
    wire _3626;
    wire _3630;
    wire _3634;
    wire [1:0] _3637;
    wire [1:0] _84;
    reg [1:0] t0_rx_rd;
    reg [15:0] _399;
    wire [15:0] _3651;
    wire [15:0] _3652;
    wire [9:0] _3650;
    wire _3649;
    wire _3645;
    wire _3643;
    wire _3646;
    wire _3640;
    wire _3638;
    wire _3641;
    wire _3647;
    wire _3648;
    wire _85;
    wire [15:0] _3658;
    wire [15:0] _86;
    wire [15:0] _87;
    wire _1828;
    wire _1829;
    wire [15:0] _3722;
    wire [15:0] _3723;
    reg [15:0] t1_tx_mem_0;
    wire [1:0] _3692;
    wire _3686;
    wire _3663;
    wire _3660;
    wire _3661;
    wire _3662;
    wire _3664;
    wire _3682;
    wire _3685;
    wire _88;
    wire _3687;
    wire [1:0] _3693;
    wire [1:0] _89;
    reg [1:0] t1_tx_rd;
    reg [15:0] _3748;
    wire _1440;
    wire _3680;
    wire [4:0] _457;
    wire [4:0] _3698;
    wire [6:0] _3695;
    wire _3696;
    wire _3694;
    wire _3697;
    wire [4:0] _3699;
    wire [4:0] _90;
    reg [4:0] cfg_t1_threshold;
    wire [4:0] _3674;
    wire [4:0] _1471;
    wire [3:0] _1468;
    wire _1470;
    wire [4:0] _1473;
    wire [5:0] _3671;
    wire [5:0] _3670;
    wire [5:0] _3672;
    wire _3673;
    wire [4:0] _3676;
    wire _3677;
    wire _3678;
    wire _3666;
    wire _3667;
    wire _3668;
    wire _3679;
    wire _3681;
    wire [4:0] _3716;
    wire _1437;
    wire [4:0] _3713;
    wire _3707;
    wire [4:0] _3709;
    wire [4:0] _3710;
    wire _3705;
    wire [4:0] _3711;
    wire _3704;
    wire [4:0] _3714;
    wire _3703;
    wire [4:0] _3717;
    wire [4:0] _3701;
    wire [4:0] _3718;
    wire [4:0] _3719;
    wire [4:0] _3720;
    wire [4:0] _3721;
    wire [4:0] _91;
    wire [4:0] _92;
    reg [4:0] t1_osr_count;
    wire _1456;
    wire _1457;
    wire _1451;
    wire _1450;
    wire _1452;
    wire _1458;
    wire _3683;
    wire _3684;
    wire [15:0] _3749;
    wire [15:0] _3818;
    wire [15:0] _3819;
    wire [15:0] _3820;
    wire [15:0] _3822;
    wire [15:0] _93;
    wire [15:0] _94;
    reg [15:0] t1_osr;
    wire [15:0] _1627;
    wire [5:0] _3827;
    wire [6:0] _3824;
    wire _3825;
    wire _3823;
    wire _3826;
    wire [5:0] _3828;
    wire [5:0] _95;
    reg [5:0] cfg_t1_shift;
    wire _1595;
    wire [15:0] _1658;
    wire [1:0] _3843;
    wire _3845;
    wire [15:0] _3846;
    wire _3839;
    wire [15:0] _3840;
    wire [15:0] _3841;
    wire _3835;
    wire [15:0] _3836;
    wire _3833;
    wire [15:0] _3837;
    wire _3832;
    wire [15:0] _3842;
    wire _3831;
    wire [15:0] _3847;
    wire _3830;
    wire [15:0] _3854;
    wire [15:0] _3855;
    wire [15:0] _3856;
    wire [15:0] _3857;
    wire [15:0] _3859;
    wire [15:0] _96;
    wire [15:0] _97;
    reg [15:0] t1_y;
    reg [15:0] _1886;
    wire _3869;
    wire [15:0] _3870;
    wire [2:0] _1561;
    wire _1563;
    wire [2:0] _1558;
    wire _1560;
    wire _1564;
    wire [15:0] _3871;
    wire [4:0] _2833;
    wire [15:0] _2834;
    wire [1:0] _1489;
    wire _3865;
    wire [15:0] _3866;
    wire _3863;
    wire [15:0] _3867;
    wire _3862;
    wire [15:0] _3872;
    wire _3861;
    wire [15:0] _3876;
    wire _3860;
    wire [15:0] _3882;
    wire [15:0] _3883;
    wire [15:0] _3884;
    wire [15:0] _3885;
    wire [15:0] _3887;
    wire [15:0] _98;
    wire [15:0] _99;
    reg [15:0] t1_x;
    wire _3891;
    wire _3892;
    wire _3893;
    wire [2:0] _3848;
    reg _3902;
    wire _3889;
    wire _3903;
    wire _3909;
    wire [7:0] _3917;
    reg [7:0] t1_pc;
    wire [7:0] _3918;
    wire [7:0] _3919;
    wire [7:0] _3920;
    wire [7:0] _3921;
    wire [7:0] _100;
    wire [7:0] _101;
    wire [7:0] _3926;
    wire _3922;
    wire [15:0] _3932;
    wire [15:0] _102;
    wire [2:0] _1405;
    wire _1407;
    wire _1421;
    wire _1434;
    wire _1442;
    wire _1448;
    wire _1459;
    wire _1481;
    wire _1482;
    wire _1483;
    wire [3:0] _3943;
    wire _1399;
    wire _1400;
    wire [3:0] _3946;
    wire _1394;
    wire [3:0] _3947;
    wire _1388;
    wire [3:0] _3949;
    wire [3:0] _103;
    wire [3:0] _104;
    reg [3:0] t1_delay_left;
    wire _1403;
    wire [15:0] _3961;
    wire [6:0] _3951;
    wire _3952;
    wire _3950;
    wire _3953;
    wire [15:0] _3954;
    wire [15:0] _105;
    reg [15:0] cfg_t1_clkdiv;
    wire _3959;
    wire [15:0] _3963;
    wire [15:0] _3957;
    wire [15:0] _3964;
    wire _3955;
    wire [15:0] _3966;
    wire [15:0] _106;
    reg [15:0] t1_div_count;
    wire _1393;
    wire _1381;
    wire _1380;
    wire _1382;
    reg t1_loaded;
    wire _1386;
    wire _1379;
    wire _1387;
    wire _1401;
    wire _1404;
    wire _3969;
    wire _3971;
    wire _3973;
    wire _3975;
    wire _107;
    wire _480;
    wire [2:0] _3977;
    wire [2:0] _3978;
    wire [2:0] _3981;
    wire [2:0] _108;
    reg [2:0] t1_rx_level;
    wire _2127;
    wire _3997;
    wire _3998;
    wire _1302;
    wire _3993;
    wire _3994;
    wire _3995;
    wire [9:0] _3986;
    wire [6:0] _3983;
    wire _3984;
    wire _3982;
    wire _3985;
    wire [9:0] _3987;
    wire [9:0] _109;
    reg [9:0] cfg_buf_end;
    wire _3990;
    wire _3991;
    wire _3989;
    wire _3992;
    wire _3996;
    wire _3999;
    wire _110;
    wire _4004;
    wire _4005;
    wire _4007;
    wire [9:0] _4010;
    wire [6:0] _4001;
    wire _4002;
    wire _4000;
    wire _4003;
    wire [9:0] _4012;
    wire [9:0] _111;
    reg [9:0] buf_ptr;
    wire _4021;
    wire _4022;
    wire [2:0] _4017;
    wire [6:0] _4014;
    wire _4015;
    wire _4013;
    wire _4016;
    wire [2:0] _4018;
    wire [2:0] _112;
    reg [2:0] cfg_buf_ctrl;
    wire [1:0] _1310;
    wire _4020;
    wire _4023;
    wire _4028;
    wire _4031;
    wire _4034;
    wire _113;
    wire _1305;
    wire _1318;
    wire _1322;
    wire [2:0] _4036;
    wire [2:0] _4037;
    wire [2:0] _4040;
    wire [2:0] _114;
    reg [2:0] t0_tx_level;
    wire _915;
    wire _1358;
    wire [4:0] _4045;
    wire [6:0] _4042;
    wire _4043;
    wire _4041;
    wire _4044;
    wire [4:0] _4046;
    wire [4:0] _115;
    reg [4:0] cfg_t0_threshold;
    wire [4:0] _1352;
    wire [4:0] _946;
    wire [3:0] _943;
    wire _945;
    wire [4:0] _948;
    wire [5:0] _1349;
    wire [5:0] _1348;
    wire [5:0] _1350;
    wire _1351;
    wire [4:0] _1354;
    wire _1355;
    wire _1356;
    wire _1344;
    wire _1345;
    wire _1346;
    wire _1357;
    wire _1359;
    wire [4:0] _4063;
    wire _912;
    wire [4:0] _4060;
    wire _4054;
    wire [4:0] _4056;
    wire [4:0] _4057;
    wire _4052;
    wire [4:0] _4058;
    wire _4051;
    wire [4:0] _4061;
    wire _4050;
    wire [4:0] _4064;
    wire [4:0] _4048;
    wire [4:0] _4065;
    wire [4:0] _4066;
    wire [4:0] _4067;
    wire [4:0] _4068;
    wire [4:0] _116;
    wire [4:0] _117;
    reg [4:0] t0_osr_count;
    wire _931;
    wire _932;
    wire _926;
    wire _925;
    wire _927;
    wire _933;
    wire _1361;
    wire _1362;
    wire [15:0] _4095;
    wire [15:0] _4164;
    wire [15:0] _4165;
    wire [15:0] _4166;
    wire [15:0] _4168;
    wire [15:0] _118;
    wire [15:0] _119;
    reg [15:0] t0_osr;
    wire [15:0] _1102;
    wire [5:0] _4173;
    wire [6:0] _4170;
    wire _4171;
    wire _4169;
    wire _4172;
    wire [5:0] _4174;
    wire [5:0] _120;
    reg [5:0] cfg_t0_shift;
    wire _1070;
    wire [15:0] _1133;
    wire [1:0] _4189;
    wire _4191;
    wire [15:0] _4192;
    wire _4185;
    wire [15:0] _4186;
    wire [15:0] _4187;
    wire _4181;
    wire [15:0] _4182;
    wire _4179;
    wire [15:0] _4183;
    wire _4178;
    wire [15:0] _4188;
    wire _4177;
    wire [15:0] _4193;
    wire _4176;
    wire [15:0] _4200;
    wire [15:0] _4201;
    wire [15:0] _4202;
    wire [15:0] _4203;
    wire [15:0] _4205;
    wire [15:0] _121;
    wire [15:0] _122;
    reg [15:0] t0_y;
    reg [15:0] _2390;
    wire _4215;
    wire [15:0] _4216;
    wire [2:0] _1036;
    wire _1038;
    wire [2:0] _1033;
    wire _1035;
    wire _1039;
    wire [15:0] _4217;
    wire [4:0] _2250;
    wire [15:0] _2251;
    wire [1:0] _964;
    wire _4211;
    wire [15:0] _4212;
    wire _4209;
    wire [15:0] _4213;
    wire _4208;
    wire [15:0] _4218;
    wire _4207;
    wire [15:0] _4222;
    wire _4206;
    wire [15:0] _4228;
    wire [15:0] _4229;
    wire [15:0] _4230;
    wire [15:0] _4231;
    wire [15:0] _4233;
    wire [15:0] _123;
    wire [15:0] _124;
    reg [15:0] t0_x;
    wire _4237;
    wire _4238;
    wire _4239;
    wire [2:0] _4194;
    reg _4248;
    wire _4235;
    wire _4249;
    wire _4255;
    wire [7:0] _4263;
    reg [7:0] t0_pc;
    wire [7:0] _4264;
    wire [7:0] _4265;
    wire [7:0] _4266;
    wire [7:0] _4267;
    wire [7:0] _125;
    wire [7:0] _126;
    wire [7:0] _4269;
    wire _4268;
    wire [15:0] _4275;
    wire [15:0] _127;
    wire [2:0] _650;
    wire _652;
    wire _896;
    wire _909;
    wire _917;
    wire _923;
    wire _934;
    wire _956;
    wire _957;
    wire _958;
    wire [3:0] _4286;
    wire _644;
    wire _645;
    wire [3:0] _4289;
    wire _639;
    wire [3:0] _4290;
    wire _633;
    wire [3:0] _4292;
    wire [3:0] _128;
    wire [3:0] _129;
    reg [3:0] t0_delay_left;
    wire _648;
    wire [15:0] _4304;
    wire [6:0] _4294;
    wire _4295;
    wire _4293;
    wire _4296;
    wire [15:0] _4297;
    wire [15:0] _130;
    reg [15:0] cfg_t0_clkdiv;
    wire _4302;
    wire [15:0] _4306;
    wire [15:0] _4300;
    wire [15:0] _4307;
    wire _4298;
    wire [15:0] _4309;
    wire [15:0] _131;
    reg [15:0] t0_div_count;
    wire _638;
    wire _626;
    wire [5:0] _432;
    wire [5:0] _4314;
    wire [6:0] _4311;
    wire _4312;
    wire _4310;
    wire _4313;
    wire [5:0] _4315;
    wire [5:0] _132;
    reg [5:0] cfg_load;
    wire [1:0] _623;
    wire [6:0] _619;
    wire _620;
    wire _618;
    wire _621;
    wire [1:0] _622;
    wire [1:0] _624;
    wire _625;
    wire _627;
    reg t0_loaded;
    wire _631;
    wire _617;
    wire _632;
    wire _646;
    wire _649;
    wire _4318;
    wire _4320;
    wire _4322;
    wire _4324;
    wire _133;
    wire _373;
    wire [2:0] _4326;
    wire [2:0] _4327;
    wire [2:0] _4330;
    wire [2:0] _134;
    reg [2:0] t0_rx_level;
    wire _3632;
    wire _4351;
    wire [15:0] _614;
    wire [2:0] _4349;
    wire [6:0] _610;
    wire _4347;
    wire _314;
    reg host_mosi_s1;
    reg host_mosi_s2;
    wire [22:0] _312;
    wire [22:0] _4331;
    wire [22:0] _4332;
    wire [22:0] _4333;
    wire [22:0] _135;
    reg [22:0] host_shift_in;
    wire [23:0] _319;
    wire [7:0] _320;
    wire _310;
    wire [7:0] _4334;
    wire [7:0] _4335;
    wire [7:0] _4336;
    wire [7:0] _136;
    reg [7:0] host_cmd;
    wire _608;
    wire [4:0] _602;
    wire [4:0] _4340;
    wire [4:0] _4337;
    wire _4338;
    wire [4:0] _4341;
    wire [4:0] _4342;
    wire [4:0] _4344;
    wire [4:0] _137;
    reg [4:0] host_bit_count;
    wire _603;
    wire _277;
    reg host_cs_n_s1;
    reg host_cs_n_s2;
    wire _304;
    reg host_sck_prev;
    wire _302;
    wire vdd;
    wire _139;
    wire _141;
    wire [7:0] _143;
    wire _282;
    reg host_sck_s1;
    reg host_sck_s2;
    wire _303;
    wire _305;
    wire _604;
    wire _4345;
    wire _4348;
    wire [2:0] _4350;
    wire [2:0] _144;
    reg [2:0] cfg_ctrl;
    wire _1842;
    wire _4352;
    wire _4354;
    wire _145;
    wire _1830;
    wire _1845;
    wire _1849;
    wire [2:0] _4356;
    wire [2:0] _4357;
    wire [2:0] _4360;
    wire [2:0] _146;
    reg [2:0] t1_tx_level;
    wire _4362;
    wire gnd;
    wire [7:0] _4374;
    assign _231 = pin_out[0:0];
    assign _232 = ~ _231;
    assign _229 = 2'b10;
    assign _228 = cfg_pin_modes[1:0];
    assign _230 = _228 == _229;
    assign _233 = _230 & _232;
    assign _226 = 2'b01;
    assign _225 = cfg_pin_modes[1:0];
    assign _227 = _225 == _226;
    assign _234 = _227 | _233;
    assign _221 = pin_out[1:1];
    assign _222 = ~ _221;
    assign _218 = cfg_pin_modes[3:2];
    assign _220 = _218 == _229;
    assign _223 = _220 & _222;
    assign _215 = cfg_pin_modes[3:2];
    assign _217 = _215 == _226;
    assign _224 = _217 | _223;
    assign _211 = pin_out[2:2];
    assign _212 = ~ _211;
    assign _208 = cfg_pin_modes[5:4];
    assign _210 = _208 == _229;
    assign _213 = _210 & _212;
    assign _205 = cfg_pin_modes[5:4];
    assign _207 = _205 == _226;
    assign _214 = _207 | _213;
    assign _201 = pin_out[3:3];
    assign _202 = ~ _201;
    assign _198 = cfg_pin_modes[7:6];
    assign _200 = _198 == _229;
    assign _203 = _200 & _202;
    assign _195 = cfg_pin_modes[7:6];
    assign _197 = _195 == _226;
    assign _204 = _197 | _203;
    assign _191 = pin_out[4:4];
    assign _192 = ~ _191;
    assign _188 = cfg_pin_modes[9:8];
    assign _190 = _188 == _229;
    assign _193 = _190 & _192;
    assign _185 = cfg_pin_modes[9:8];
    assign _187 = _185 == _226;
    assign _194 = _187 | _193;
    assign _181 = pin_out[5:5];
    assign _182 = ~ _181;
    assign _178 = cfg_pin_modes[11:10];
    assign _180 = _178 == _229;
    assign _183 = _180 & _182;
    assign _175 = cfg_pin_modes[11:10];
    assign _177 = _175 == _226;
    assign _184 = _177 | _183;
    assign _171 = pin_out[6:6];
    assign _172 = ~ _171;
    assign _168 = cfg_pin_modes[13:12];
    assign _170 = _168 == _229;
    assign _173 = _170 & _172;
    assign _165 = cfg_pin_modes[13:12];
    assign _167 = _165 == _226;
    assign _174 = _167 | _173;
    assign _161 = pin_out[7:7];
    assign _162 = ~ _161;
    assign _155 = cfg_pin_modes[15:14];
    assign _157 = _155 == _229;
    assign _163 = _157 & _162;
    assign _152 = cfg_pin_modes[15:14];
    assign _154 = _152 == _226;
    assign _164 = _154 | _163;
    assign _235 = { _164,
                    _174,
                    _184,
                    _194,
                    _204,
                    _214,
                    _224,
                    _234 };
    assign _274 = pin_out[0:0];
    assign _271 = cfg_pin_modes[1:0];
    assign _273 = _271 == _226;
    assign _275 = _273 & _274;
    assign _269 = pin_out[1:1];
    assign _266 = cfg_pin_modes[3:2];
    assign _268 = _266 == _226;
    assign _270 = _268 & _269;
    assign _264 = pin_out[2:2];
    assign _261 = cfg_pin_modes[5:4];
    assign _263 = _261 == _226;
    assign _265 = _263 & _264;
    assign _259 = pin_out[3:3];
    assign _256 = cfg_pin_modes[7:6];
    assign _258 = _256 == _226;
    assign _260 = _258 & _259;
    assign _254 = pin_out[4:4];
    assign _251 = cfg_pin_modes[9:8];
    assign _253 = _251 == _226;
    assign _255 = _253 & _254;
    assign _249 = pin_out[5:5];
    assign _246 = cfg_pin_modes[11:10];
    assign _248 = _246 == _226;
    assign _250 = _248 & _249;
    assign _244 = pin_out[6:6];
    assign _241 = cfg_pin_modes[13:12];
    assign _243 = _241 == _226;
    assign _245 = _243 & _244;
    assign _239 = pin_out[7:7];
    assign _236 = cfg_pin_modes[15:14];
    assign _238 = _236 == _226;
    assign _240 = _238 & _239;
    assign _276 = { _240,
                    _245,
                    _250,
                    _255,
                    _260,
                    _265,
                    _270,
                    _275 };
    assign _307 = 16'b0000000000000000;
    assign _598 = 1'b0;
    assign _597 = host_miso_shift[14:0];
    assign _599 = { _597,
                    _598 };
    assign _580 = { smp_synced,
                    smp_carrier };
    assign _573 = 14'b00000000000000;
    assign _581 = { _573,
                    _580 };
    assign _568 = 8'b00000000;
    assign _572 = { _568,
                    cfg_smp_sync };
    assign _567 = { gnd,
                    cfg_smp_time };
    assign _559 = 7'b0000000;
    assign _563 = { _559,
                    cfg_smp_ctrl };
    assign _554 = 6'b000000;
    assign _558 = { _554,
                    cfg_buf_end };
    assign _553 = { _554,
                    buf_ptr };
    assign _544 = 13'b0000000000000;
    assign _548 = { _544,
                    cfg_buf_ctrl };
    assign _527 = 10'b0000000000;
    assign _531 = { _527,
                    cfg_t1_shift };
    assign _523 = { _527,
                    cfg_t1_sideset };
    assign _511 = cfg_ctrl[1:1];
    assign _515 = { t1_pc,
                    _511,
                    t1_rx_level,
                    gnd,
                    t1_tx_level };
    assign _468 = 3'b000;
    assign _469 = t1_rx_level == _468;
    assign _470 = ~ _469;
    assign _507 = _470 ? _506 : _307;
    assign _464 = { _568,
                    cfg_t1_timeout_vector };
    assign _455 = 11'b00000000000;
    assign _459 = { _455,
                    cfg_t1_threshold };
    assign _454 = { _544,
                    cfg_t1_in_base };
    assign _449 = { _568,
                    cfg_t1_set_cfg };
    assign _444 = { _568,
                    cfg_t1_out_cfg };
    assign _439 = { _568,
                    cfg_t1_start };
    assign _434 = { _527,
                    cfg_load };
    assign _429 = { _527,
                    cfg_t0_shift };
    assign _424 = { _568,
                    cfg_sync_bypass };
    assign _416 = { _527,
                    cfg_t0_sideset };
    assign _404 = cfg_ctrl[0:0];
    assign _408 = { t0_pc,
                    _404,
                    t0_rx_level,
                    gnd,
                    t0_tx_level };
    assign _362 = t0_rx_level == _468;
    assign _363 = ~ _362;
    assign _400 = _363 ? _399 : _307;
    assign _357 = { _568,
                    cfg_t0_timeout_vector };
    assign _352 = { _455,
                    cfg_t0_threshold };
    assign _347 = { _544,
                    cfg_t0_in_base };
    assign _342 = { _568,
                    cfg_t0_set_cfg };
    assign _337 = { _568,
                    cfg_t0_out_cfg };
    assign _332 = { _568,
                    cfg_t0_start };
    assign _327 = { _544,
                    cfg_ctrl };
    always @* begin
        case (_321)
        0:
            _594 <= _307;
        1:
            _594 <= _307;
        2:
            _594 <= _307;
        3:
            _594 <= _307;
        4:
            _594 <= _307;
        5:
            _594 <= _307;
        6:
            _594 <= _307;
        7:
            _594 <= _307;
        8:
            _594 <= _307;
        9:
            _594 <= _307;
        10:
            _594 <= _307;
        11:
            _594 <= _307;
        12:
            _594 <= _307;
        13:
            _594 <= _307;
        14:
            _594 <= _307;
        15:
            _594 <= _307;
        16:
            _594 <= _307;
        17:
            _594 <= _307;
        18:
            _594 <= _307;
        19:
            _594 <= _307;
        20:
            _594 <= _307;
        21:
            _594 <= _307;
        22:
            _594 <= _307;
        23:
            _594 <= _307;
        24:
            _594 <= _307;
        25:
            _594 <= _307;
        26:
            _594 <= _307;
        27:
            _594 <= _307;
        28:
            _594 <= _307;
        29:
            _594 <= _307;
        30:
            _594 <= _307;
        31:
            _594 <= _307;
        32:
            _594 <= _307;
        33:
            _594 <= _307;
        34:
            _594 <= _307;
        35:
            _594 <= _307;
        36:
            _594 <= _307;
        37:
            _594 <= _307;
        38:
            _594 <= _307;
        39:
            _594 <= _307;
        40:
            _594 <= _307;
        41:
            _594 <= _307;
        42:
            _594 <= _307;
        43:
            _594 <= _307;
        44:
            _594 <= _307;
        45:
            _594 <= _307;
        46:
            _594 <= _307;
        47:
            _594 <= _307;
        48:
            _594 <= _307;
        49:
            _594 <= _307;
        50:
            _594 <= _307;
        51:
            _594 <= _307;
        52:
            _594 <= _307;
        53:
            _594 <= _307;
        54:
            _594 <= _307;
        55:
            _594 <= _307;
        56:
            _594 <= _307;
        57:
            _594 <= _307;
        58:
            _594 <= _307;
        59:
            _594 <= _307;
        60:
            _594 <= _307;
        61:
            _594 <= _307;
        62:
            _594 <= _307;
        63:
            _594 <= _307;
        64:
            _594 <= _327;
        65:
            _594 <= _332;
        66:
            _594 <= _337;
        67:
            _594 <= _342;
        68:
            _594 <= _347;
        69:
            _594 <= _352;
        70:
            _594 <= _357;
        71:
            _594 <= cfg_pin_modes;
        72:
            _594 <= _307;
        73:
            _594 <= _400;
        74:
            _594 <= _408;
        75:
            _594 <= cfg_t0_timeout;
        76:
            _594 <= _416;
        77:
            _594 <= cfg_t0_clkdiv;
        78:
            _594 <= _424;
        79:
            _594 <= _429;
        80:
            _594 <= _434;
        81:
            _594 <= _439;
        82:
            _594 <= _444;
        83:
            _594 <= _449;
        84:
            _594 <= _454;
        85:
            _594 <= _459;
        86:
            _594 <= _464;
        87:
            _594 <= _307;
        88:
            _594 <= _307;
        89:
            _594 <= _507;
        90:
            _594 <= _515;
        91:
            _594 <= cfg_t1_timeout;
        92:
            _594 <= _523;
        93:
            _594 <= cfg_t1_clkdiv;
        94:
            _594 <= _307;
        95:
            _594 <= _531;
        96:
            _594 <= _307;
        97:
            _594 <= cfg_t0_crc_poly_lo;
        98:
            _594 <= cfg_t0_crc_poly_hi;
        99:
            _594 <= cfg_t0_crc_init_lo;
        100:
            _594 <= cfg_t0_crc_init_hi;
        101:
            _594 <= _307;
        102:
            _594 <= _307;
        103:
            _594 <= _307;
        104:
            _594 <= _548;
        105:
            _594 <= _553;
        106:
            _594 <= _558;
        107:
            _594 <= _87;
        108:
            _594 <= _563;
        109:
            _594 <= _567;
        110:
            _594 <= _572;
        111:
            _594 <= _581;
        112:
            _594 <= _307;
        113:
            _594 <= cfg_t1_crc_poly_lo;
        114:
            _594 <= cfg_t1_crc_poly_hi;
        115:
            _594 <= cfg_t1_crc_init_lo;
        116:
            _594 <= cfg_t1_crc_init_hi;
        default:
            _594 <= _307;
        endcase
    end
    assign _595 = _310 ? _594 : host_miso_shift;
    assign _596 = _305 ? _595 : host_miso_shift;
    assign _298 = 5'b01001;
    assign _299 = host_bit_count < _298;
    assign _300 = ~ _299;
    assign _293 = ~ host_cs_n_s2;
    assign _288 = ~ host_sck_s2;
    assign _292 = _288 & host_sck_prev;
    assign _294 = _292 & _293;
    assign _301 = _294 & _300;
    assign _600 = _301 ? _599 : _596;
    assign _601 = host_cs_n_s2 ? host_miso_shift : _600;
    assign _3 = _601;
    always @(posedge _141) begin
        if (_139)
            host_miso_shift <= _307;
        else
            host_miso_shift <= _3;
    end
    assign _4373 = host_miso_shift[15:15];
    assign _4372 = cfg_ctrl[0:0];
    assign _4370 = t0_rx_level == _468;
    assign _4371 = ~ _4370;
    assign _4367 = 3'b100;
    assign _4368 = t0_tx_level == _4367;
    assign _4366 = cfg_ctrl[1:1];
    assign _4364 = t1_rx_level == _468;
    assign _4365 = ~ _4364;
    assign _4358 = 2'b00;
    assign _4359 = { _4358,
                     _3687 };
    assign _1848 = ~ _1847;
    assign _1843 = ~ _1842;
    assign _1837 = 1'b1;
    assign _1838 = _1302 == _1837;
    assign _1836 = _1310 == _226;
    assign _1839 = _1836 & _1838;
    assign _1840 = ~ _1839;
    assign _1832 = 7'b1011000;
    assign _1833 = _610 == _1832;
    assign _1831 = _604 & _608;
    assign _1834 = _1831 & _1833;
    assign _1841 = _1834 & _1840;
    assign _1844 = _1841 & _1843;
    assign _4353 = ~ _1847;
    assign _4329 = { _4358,
                     _3634 };
    assign _372 = ~ _371;
    assign _4323 = _958 & _954;
    assign _4321 = ~ _371;
    assign _4319 = ~ _912;
    assign _4317 = _650 == _4367;
    assign _647 = 4'b0000;
    assign _4287 = 4'b0001;
    assign _4288 = t0_delay_left - _4287;
    assign _4282 = _4280[3:2];
    assign _4283 = { _4358,
                     _4282 };
    assign _4279 = 4'b0111;
    assign _4278 = 4'b1111;
    assign _4277 = _2219[0:0];
    assign _4280 = _4277 ? _4279 : _4278;
    assign _4276 = _2219[1:1];
    assign _4284 = _4276 ? _4283 : _4280;
    assign _4285 = _2646 & _4284;
    assign _955 = _954 & _371;
    assign _371 = t0_rx_level == _4367;
    assign _920 = ~ _912;
    assign _919 = _650 == _4367;
    assign _921 = _919 & _920;
    assign _922 = _921 & _371;
    assign _911 = _650 == _4367;
    assign _913 = _911 & _912;
    assign _916 = _913 & _915;
    assign _908 = ~ _907;
    assign _895 = ~ _894;
    assign _651 = 3'b001;
    assign _4270 = 16'b1111111111111111;
    assign _4260 = _127[5:0];
    assign _615 = _614[7:0];
    assign _611 = 7'b1000001;
    assign _612 = _610 == _611;
    assign _609 = _604 & _608;
    assign _613 = _609 & _612;
    assign _616 = _613 ? _615 : cfg_t0_start;
    assign _4 = _616;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_start <= _568;
        else
            cfg_t0_start <= _4;
    end
    assign _973 = cfg_t0_start[7:6];
    assign _967 = _127[1:0];
    assign _965 = 2'b11;
    assign _966 = _964 == _965;
    assign _968 = _966 ? _967 : t0_page;
    assign _963 = _650 == _1042;
    assign _969 = _963 ? _968 : t0_page;
    assign _970 = _958 ? _969 : t0_page;
    assign _971 = _645 ? t0_page : _970;
    assign _972 = _639 ? t0_page : _971;
    assign _974 = _633 ? _973 : _972;
    assign _5 = _974;
    assign _6 = _5;
    always @(posedge _141) begin
        if (_139)
            t0_page <= _4358;
        else
            t0_page <= _6;
    end
    assign _4261 = { t0_page,
                     _4260 };
    assign _979 = _614[7:0];
    assign _976 = 7'b1000110;
    assign _977 = _610 == _976;
    assign _975 = _604 & _608;
    assign _978 = _975 & _977;
    assign _980 = _978 ? _979 : cfg_t0_timeout_vector;
    assign _7 = _980;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_timeout_vector <= _568;
        else
            cfg_t0_timeout_vector <= _7;
    end
    assign _4259 = _650 == _468;
    assign _4262 = _4259 ? _4261 : cfg_t0_timeout_vector;
    assign _4256 = 8'b00000001;
    assign _4257 = t0_pc + _4256;
    assign _988 = 16'b0000000000000001;
    assign _989 = _904 - _988;
    assign _990 = _987 ? _989 : t0_wait_count;
    assign _991 = _645 ? t0_wait_count : _990;
    assign _992 = _639 ? t0_wait_count : _991;
    assign _994 = _633 ? _307 : _992;
    assign _8 = _994;
    assign _9 = _8;
    always @(posedge _141) begin
        if (_139)
            t0_wait_count <= _307;
        else
            t0_wait_count <= _9;
    end
    assign _996 = 7'b1001011;
    assign _997 = _610 == _996;
    assign _995 = _604 & _608;
    assign _998 = _995 & _997;
    assign _999 = _998 ? _614 : cfg_t0_timeout;
    assign _10 = _999;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_timeout <= _307;
        else
            cfg_t0_timeout <= _10;
    end
    assign _986 = ~ _906;
    assign _983 = ~ _894;
    assign _982 = _650 == _651;
    assign _984 = _982 & _983;
    assign _985 = _984 & _897;
    assign _987 = _985 & _986;
    assign _1001 = _987 ? _1837 : t0_waiting;
    assign _1003 = _958 ? _598 : _1001;
    assign _1004 = _645 ? t0_waiting : _1003;
    assign _1005 = _639 ? t0_waiting : _1004;
    assign _1007 = _633 ? _598 : _1005;
    assign _11 = _1007;
    assign _12 = _11;
    always @(posedge _141) begin
        if (_139)
            t0_waiting <= _598;
        else
            t0_waiting <= _12;
    end
    assign _904 = t0_waiting ? t0_wait_count : cfg_t0_timeout;
    assign _906 = _904 == _307;
    assign _897 = _127[4:4];
    assign _907 = _897 & _906;
    assign _893 = _127[8:8];
    assign _891 = _883[7:7];
    assign _890 = _883[6:6];
    assign _889 = _883[5:5];
    assign _888 = _883[4:4];
    assign _887 = _883[3:3];
    assign _886 = _883[2:2];
    assign _885 = _883[1:1];
    assign _884 = _883[0:0];
    assign _653 = _127[7:5];
    always @* begin
        case (_653)
        0:
            _892 <= _884;
        1:
            _892 <= _885;
        2:
            _892 <= _886;
        3:
            _892 <= _887;
        4:
            _892 <= _888;
        5:
            _892 <= _889;
        6:
            _892 <= _890;
        default:
            _892 <= _891;
        endcase
    end
    assign _894 = _892 == _893;
    assign _4252 = ~ _894;
    assign _4251 = _650 == _651;
    assign _4253 = _4251 & _4252;
    assign _4254 = _4253 & _907;
    assign _4247 = t0_isr_count < cfg_t0_threshold;
    assign _4246 = t0_osr_count < cfg_t0_threshold;
    assign _4244 = t0_x == t0_y;
    assign _4245 = ~ _4244;
    assign _4241 = t0_y == _307;
    assign _4242 = ~ _4241;
    assign _4243 = ~ _4242;
    assign _4226 = t0_x - _988;
    assign _4223 = 3'b010;
    assign _4224 = _4194 == _4223;
    assign _4227 = _4224 ? _4226 : t0_x;
    assign _4220 = _4189 == _226;
    assign _4221 = _4220 ? _1133 : t0_x;
    assign _2382 = cfg_t0_shift[4:4];
    assign _2383 = { _2382,
                     _2382 };
    assign _2384 = { _2383,
                     _2383 };
    assign _2385 = { _2384,
                     _2384 };
    assign _2386 = { _2385,
                     _2385 };
    assign _2387 = { _2386,
                     _2386 };
    assign _1063 = 32'b00000000000000000000000000000000;
    assign _1009 = 7'b1100011;
    assign _1010 = _610 == _1009;
    assign _1008 = _604 & _608;
    assign _1011 = _1008 & _1010;
    assign _1012 = _1011 ? _614 : cfg_t0_crc_init_lo;
    assign _13 = _1012;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_crc_init_lo <= _307;
        else
            cfg_t0_crc_init_lo <= _13;
    end
    assign _1014 = 7'b1100100;
    assign _1015 = _610 == _1014;
    assign _1013 = _604 & _608;
    assign _1016 = _1013 & _1015;
    assign _1017 = _1016 ? _614 : cfg_t0_crc_init_hi;
    assign _14 = _1017;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_crc_init_hi <= _307;
        else
            cfg_t0_crc_init_hi <= _14;
    end
    assign _1294 = { cfg_t0_crc_init_hi,
                     cfg_t0_crc_init_lo };
    assign _1291 = t0_crc[31:16];
    assign _1292 = { _307,
                     _1291 };
    assign _1293 = _1043 ? _1292 : _1288;
    assign _1295 = _1041 ? _1294 : _1293;
    assign _1296 = _1039 ? _1295 : _1288;
    assign _1289 = _650 == _1689;
    assign _1297 = _1289 ? _1296 : _1288;
    assign _1277 = _1257[15:15];
    assign _1276 = _1257[14:14];
    assign _1275 = _1257[13:13];
    assign _1274 = _1257[12:12];
    assign _1273 = _1257[11:11];
    assign _1272 = _1257[10:10];
    assign _1271 = _1257[9:9];
    assign _1270 = _1257[8:8];
    assign _1269 = _1257[7:7];
    assign _1268 = _1257[6:6];
    assign _1267 = _1257[5:5];
    assign _1266 = _1257[4:4];
    assign _1265 = _1257[3:3];
    assign _1264 = _1257[2:2];
    assign _1263 = _1257[1:1];
    assign _1262 = _1257[0:0];
    assign _1259 = 5'b00001;
    assign _1260 = _948 - _1259;
    assign _1261 = _1260[3:0];
    always @* begin
        case (_1261)
        0:
            _1278 <= _1262;
        1:
            _1278 <= _1263;
        2:
            _1278 <= _1264;
        3:
            _1278 <= _1265;
        4:
            _1278 <= _1266;
        5:
            _1278 <= _1267;
        6:
            _1278 <= _1268;
        7:
            _1278 <= _1269;
        8:
            _1278 <= _1270;
        9:
            _1278 <= _1271;
        10:
            _1278 <= _1272;
        11:
            _1278 <= _1273;
        12:
            _1278 <= _1274;
        13:
            _1278 <= _1275;
        14:
            _1278 <= _1276;
        default:
            _1278 <= _1277;
        endcase
    end
    assign _1256 = _1255 & _1101;
    assign _1257 = _1055 ? _1256 : _1133;
    assign _1258 = _1257[0:0];
    assign _1072 = _1055 ? _1071 : _1070;
    assign _1279 = _1072 ? _1278 : _1258;
    assign _1069 = t0_crc[0:0];
    assign _1280 = _1069 ^ _1279;
    assign _1281 = { _1280,
                     _1280 };
    assign _1282 = { _1281,
                     _1281 };
    assign _1283 = { _1282,
                     _1282 };
    assign _1284 = { _1283,
                     _1283 };
    assign _1285 = { _1284,
                     _1284 };
    assign _1019 = 7'b1100001;
    assign _1020 = _610 == _1019;
    assign _1018 = _604 & _608;
    assign _1021 = _1018 & _1020;
    assign _1022 = _1021 ? _614 : cfg_t0_crc_poly_lo;
    assign _15 = _1022;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_crc_poly_lo <= _307;
        else
            cfg_t0_crc_poly_lo <= _15;
    end
    assign _1024 = 7'b1100010;
    assign _1025 = _610 == _1024;
    assign _1023 = _604 & _608;
    assign _1026 = _1023 & _1025;
    assign _1027 = _1026 ? _614 : cfg_t0_crc_poly_hi;
    assign _16 = _1027;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_crc_poly_hi <= _307;
        else
            cfg_t0_crc_poly_hi <= _16;
    end
    assign _1068 = { cfg_t0_crc_poly_hi,
                     cfg_t0_crc_poly_lo };
    assign _1286 = _1068 & _1285;
    assign _1066 = t0_crc[31:1];
    assign _1067 = { _598,
                     _1066 };
    assign _1287 = _1067 ^ _1286;
    assign _1059 = _650 == _4223;
    assign _1056 = 3'b011;
    assign _1057 = _650 == _1056;
    assign _1055 = cfg_t0_shift[5:5];
    assign _1060 = _1055 ? _1059 : _1057;
    assign _1042 = 3'b110;
    assign _1043 = _1036 == _1042;
    assign _1044 = _1043 ? gnd : t0_crc_run;
    assign _1041 = _1033 == _1042;
    assign _1046 = _1041 ? _1837 : _1044;
    assign _1047 = _1039 ? _1046 : t0_crc_run;
    assign _1032 = _650 == _1689;
    assign _1048 = _1032 ? _1047 : t0_crc_run;
    assign _1049 = _958 ? _1048 : t0_crc_run;
    assign _1050 = _645 ? t0_crc_run : _1049;
    assign _1051 = _639 ? t0_crc_run : _1050;
    assign _1053 = _633 ? _1837 : _1051;
    assign _17 = _1053;
    assign _18 = _17;
    always @(posedge _141) begin
        if (_139)
            t0_crc_run <= _598;
        else
            t0_crc_run <= _18;
    end
    assign _1054 = _958 & t0_crc_run;
    assign _1061 = _1054 & _1060;
    assign _1288 = _1061 ? _1287 : t0_crc;
    assign _1298 = _958 ? _1297 : _1288;
    assign _1299 = _645 ? t0_crc : _1298;
    assign _1300 = _639 ? t0_crc : _1299;
    assign _1301 = _633 ? _1294 : _1300;
    assign _19 = _1301;
    assign _20 = _19;
    always @(posedge _141) begin
        if (_139)
            t0_crc <= _1063;
        else
            t0_crc <= _20;
    end
    assign _2388 = t0_crc ^ _2387;
    assign _2389 = _2388[15:0];
    assign _2377 = { _568,
                     _883 };
    assign _4198 = t0_y - _988;
    assign _4196 = _4194 == _4367;
    assign _4199 = _4196 ? _4198 : t0_y;
    assign _1129 = _1127[31:16];
    assign _1130 = { _307,
                     _1129 };
    assign _1125 = _1123[31:8];
    assign _1126 = { _568,
                     _1125 };
    assign _1121 = _1119[31:4];
    assign _1122 = { _647,
                     _1121 };
    assign _1117 = _1115[31:2];
    assign _1118 = { _4358,
                     _1117 };
    assign _1113 = _1111[31:1];
    assign _1114 = { _598,
                     _1113 };
    assign _1111 = { _307,
                     t0_osr };
    assign _1109 = _1104[0:0];
    assign _1115 = _1109 ? _1114 : _1111;
    assign _1108 = _1104[1:1];
    assign _1119 = _1108 ? _1118 : _1115;
    assign _1107 = _1104[2:2];
    assign _1123 = _1107 ? _1122 : _1119;
    assign _1106 = _1104[3:3];
    assign _1127 = _1106 ? _1126 : _1123;
    assign _1103 = 5'b10000;
    assign _1104 = _1103 - _948;
    assign _1105 = _1104[4:4];
    assign _1131 = _1105 ? _1130 : _1127;
    assign _1132 = _1131[15:0];
    assign _4156 = _4155[15:0];
    assign _4158 = { _4156,
                     _307 };
    assign _4152 = _4151[23:0];
    assign _4154 = { _4152,
                     _568 };
    assign _4148 = _4147[27:0];
    assign _4150 = { _4148,
                     _647 };
    assign _4144 = _4143[29:0];
    assign _4146 = { _4144,
                     _4358 };
    assign _4140 = _4139[30:0];
    assign _4142 = { _4140,
                     _598 };
    assign _4139 = { _307,
                     t0_osr };
    assign _4137 = _948[0:0];
    assign _4143 = _4137 ? _4142 : _4139;
    assign _4136 = _948[1:1];
    assign _4147 = _4136 ? _4146 : _4143;
    assign _4135 = _948[2:2];
    assign _4151 = _4135 ? _4150 : _4147;
    assign _4134 = _948[3:3];
    assign _4155 = _4134 ? _4154 : _4151;
    assign _4133 = _948[4:4];
    assign _4159 = _4133 ? _4158 : _4155;
    assign _4160 = _4159[15:0];
    assign _4129 = _4127[31:16];
    assign _4130 = { _307,
                     _4129 };
    assign _4125 = _4123[31:8];
    assign _4126 = { _568,
                     _4125 };
    assign _4121 = _4119[31:4];
    assign _4122 = { _647,
                     _4121 };
    assign _4117 = _4115[31:2];
    assign _4118 = { _4358,
                     _4117 };
    assign _4113 = _4111[31:1];
    assign _4114 = { _598,
                     _4113 };
    assign _4111 = { _307,
                     t0_osr };
    assign _4109 = _948[0:0];
    assign _4115 = _4109 ? _4114 : _4111;
    assign _4108 = _948[1:1];
    assign _4119 = _4108 ? _4118 : _4115;
    assign _4107 = _948[2:2];
    assign _4123 = _4107 ? _4122 : _4119;
    assign _4106 = _948[3:3];
    assign _4127 = _4106 ? _4126 : _4123;
    assign _4105 = _948[4:4];
    assign _4131 = _4105 ? _4130 : _4127;
    assign _4132 = _4131[15:0];
    assign _4161 = _1070 ? _4160 : _4132;
    assign _4162 = _1359 ? _4094 : _4161;
    assign _4103 = _912 ? _4094 : _4095;
    assign _4099 = _1033 == _4367;
    assign _4100 = _4099 ? _2390 : _4095;
    assign _4101 = _1039 ? _4100 : _4095;
    assign _4098 = _650 == _1689;
    assign _4102 = _4098 ? _4101 : _4095;
    assign _4097 = _650 == _4367;
    assign _4104 = _4097 ? _4103 : _4102;
    assign _4096 = _650 == _1056;
    assign _4163 = _4096 ? _4162 : _4104;
    assign _4091 = t0_tx_wr == _965;
    assign _4092 = _1322 & _4091;
    always @(posedge _141) begin
        if (_139)
            t0_tx_mem_3 <= _307;
        else
            if (_4092)
                t0_tx_mem_3 <= _4069;
    end
    assign _4085 = t0_tx_wr == _229;
    assign _4086 = _1322 & _4085;
    always @(posedge _141) begin
        if (_139)
            t0_tx_mem_2 <= _307;
        else
            if (_4086)
                t0_tx_mem_2 <= _4069;
    end
    assign _4079 = t0_tx_wr == _226;
    assign _4080 = _1322 & _4079;
    always @(posedge _141) begin
        if (_139)
            t0_tx_mem_1 <= _307;
        else
            if (_4080)
                t0_tx_mem_1 <= _4069;
    end
    assign _1327 = t0_tx_wr + _226;
    assign _1328 = _1322 ? _1327 : t0_tx_wr;
    assign _21 = _1328;
    always @(posedge _141) begin
        if (_139)
            t0_tx_wr <= _4358;
        else
            t0_tx_wr <= _21;
    end
    assign _4073 = t0_tx_wr == _4358;
    assign _4074 = _1322 & _4073;
    assign _4069 = _1305 ? _87 : _614;
    always @(posedge _141) begin
        if (_139)
            t0_tx_mem_0 <= _307;
        else
            if (_4074)
                t0_tx_mem_0 <= _4069;
    end
    assign _1335 = t0_tx_rd + _226;
    assign _1336 = _1330 ? _1335 : t0_tx_rd;
    assign _22 = _1336;
    always @(posedge _141) begin
        if (_139)
            t0_tx_rd <= _4358;
        else
            t0_tx_rd <= _22;
    end
    always @* begin
        case (t0_tx_rd)
        0:
            _4094 <= t0_tx_mem_0;
        1:
            _4094 <= t0_tx_mem_1;
        2:
            _4094 <= t0_tx_mem_2;
        default:
            _4094 <= t0_tx_mem_3;
        endcase
    end
    assign _929 = 5'b00000;
    assign _1329 = ~ _915;
    assign _1341 = ~ _915;
    assign _1338 = _650 == _4367;
    assign _1339 = _649 & _1338;
    assign _1340 = _1339 & _912;
    assign _1342 = _1340 & _1341;
    assign _1360 = _1342 | _1359;
    assign _1363 = _1360 | _1362;
    assign _23 = _1363;
    assign _1330 = _23 & _1329;
    assign _4039 = { _4358,
                     _1330 };
    assign _1321 = ~ _1320;
    assign _1314 = _1302 == _598;
    assign _1312 = _1310 == _226;
    assign _1315 = _1312 & _1314;
    assign _1316 = ~ _1315;
    assign _1307 = 7'b1001000;
    assign _1308 = _610 == _1307;
    assign _1306 = _604 & _608;
    assign _1309 = _1306 & _1308;
    assign _1317 = _1309 & _1316;
    assign _1304 = _1302 == _598;
    assign _1847 = t1_tx_level == _4367;
    assign _1320 = t0_tx_level == _4367;
    assign _4032 = _1302 ? _1847 : _1320;
    assign _4033 = ~ _4032;
    assign _4029 = _1842 & _1302;
    assign _4030 = ~ _4029;
    always @(posedge _141) begin
        if (_139)
            buf_wrote <= _598;
        else
            buf_wrote <= _85;
    end
    assign _4027 = ~ buf_wrote;
    assign _4011 = _614[9:0];
    assign _4008 = 10'b0000000001;
    assign _4009 = buf_ptr + _4008;
    assign _1370 = 7'b1101011;
    assign _1371 = _321 == _1370;
    assign _1367 = _320[7:7];
    assign _1368 = ~ _1367;
    assign _1369 = _1366 & _1368;
    assign _1372 = _1369 & _1371;
    assign _24 = _1372;
    assign _4006 = _24 & _3646;
    assign _3980 = { _4358,
                     _2129 };
    assign _479 = ~ _478;
    assign _3974 = _1483 & _1479;
    assign _3972 = ~ _478;
    assign _3970 = ~ _1437;
    assign _3968 = _1405 == _4367;
    assign _3945 = t1_delay_left - _4287;
    assign _3939 = _3937[3:2];
    assign _3940 = { _4358,
                     _3939 };
    assign _3934 = _2802[0:0];
    assign _3937 = _3934 ? _4279 : _4278;
    assign _3933 = _2802[1:1];
    assign _3941 = _3933 ? _3940 : _3937;
    assign _3942 = _3214 & _3941;
    assign _1480 = _1479 & _478;
    assign _478 = t1_rx_level == _4367;
    assign _1445 = ~ _1437;
    assign _1444 = _1405 == _4367;
    assign _1446 = _1444 & _1445;
    assign _1447 = _1446 & _478;
    assign _1436 = _1405 == _4367;
    assign _1438 = _1436 & _1437;
    assign _1441 = _1438 & _1440;
    assign _1433 = ~ _1432;
    assign _1420 = ~ _1419;
    assign _3924 = _610[5:0];
    assign _3923 = cfg_load[1:0];
    assign _3925 = { _3923,
                     _3924 };
    assign _3914 = _102[5:0];
    assign _1377 = _614[7:0];
    assign _1374 = 7'b1010001;
    assign _1375 = _610 == _1374;
    assign _1373 = _604 & _608;
    assign _1376 = _1373 & _1375;
    assign _1378 = _1376 ? _1377 : cfg_t1_start;
    assign _25 = _1378;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_start <= _568;
        else
            cfg_t1_start <= _25;
    end
    assign _1498 = cfg_t1_start[7:6];
    assign _1492 = _102[1:0];
    assign _1491 = _1489 == _965;
    assign _1493 = _1491 ? _1492 : t1_page;
    assign _1488 = _1405 == _1042;
    assign _1494 = _1488 ? _1493 : t1_page;
    assign _1495 = _1483 ? _1494 : t1_page;
    assign _1496 = _1400 ? t1_page : _1495;
    assign _1497 = _1394 ? t1_page : _1496;
    assign _1499 = _1388 ? _1498 : _1497;
    assign _26 = _1499;
    assign _27 = _26;
    always @(posedge _141) begin
        if (_139)
            t1_page <= _4358;
        else
            t1_page <= _27;
    end
    assign _3915 = { t1_page,
                     _3914 };
    assign _1504 = _614[7:0];
    assign _1501 = 7'b1010110;
    assign _1502 = _610 == _1501;
    assign _1500 = _604 & _608;
    assign _1503 = _1500 & _1502;
    assign _1505 = _1503 ? _1504 : cfg_t1_timeout_vector;
    assign _28 = _1505;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_timeout_vector <= _568;
        else
            cfg_t1_timeout_vector <= _28;
    end
    assign _3913 = _1405 == _468;
    assign _3916 = _3913 ? _3915 : cfg_t1_timeout_vector;
    assign _3911 = t1_pc + _4256;
    assign _1514 = _1429 - _988;
    assign _1515 = _1512 ? _1514 : t1_wait_count;
    assign _1516 = _1400 ? t1_wait_count : _1515;
    assign _1517 = _1394 ? t1_wait_count : _1516;
    assign _1519 = _1388 ? _307 : _1517;
    assign _29 = _1519;
    assign _30 = _29;
    always @(posedge _141) begin
        if (_139)
            t1_wait_count <= _307;
        else
            t1_wait_count <= _30;
    end
    assign _1521 = 7'b1011011;
    assign _1522 = _610 == _1521;
    assign _1520 = _604 & _608;
    assign _1523 = _1520 & _1522;
    assign _1524 = _1523 ? _614 : cfg_t1_timeout;
    assign _31 = _1524;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_timeout <= _307;
        else
            cfg_t1_timeout <= _31;
    end
    assign _1511 = ~ _1431;
    assign _1508 = ~ _1419;
    assign _1507 = _1405 == _651;
    assign _1509 = _1507 & _1508;
    assign _1510 = _1509 & _1422;
    assign _1512 = _1510 & _1511;
    assign _1526 = _1512 ? _1837 : t1_waiting;
    assign _1528 = _1483 ? _598 : _1526;
    assign _1529 = _1400 ? t1_waiting : _1528;
    assign _1530 = _1394 ? t1_waiting : _1529;
    assign _1532 = _1388 ? _598 : _1530;
    assign _32 = _1532;
    assign _33 = _32;
    always @(posedge _141) begin
        if (_139)
            t1_waiting <= _598;
        else
            t1_waiting <= _33;
    end
    assign _1429 = t1_waiting ? t1_wait_count : cfg_t1_timeout;
    assign _1431 = _1429 == _307;
    assign _1422 = _102[4:4];
    assign _1432 = _1422 & _1431;
    assign _1418 = _102[8:8];
    assign _1416 = _883[7:7];
    assign _1415 = _883[6:6];
    assign _1414 = _883[5:5];
    assign _1413 = _883[4:4];
    assign _1412 = _883[3:3];
    assign _1411 = _883[2:2];
    assign _1410 = _883[1:1];
    assign _1409 = _883[0:0];
    assign _1408 = _102[7:5];
    always @* begin
        case (_1408)
        0:
            _1417 <= _1409;
        1:
            _1417 <= _1410;
        2:
            _1417 <= _1411;
        3:
            _1417 <= _1412;
        4:
            _1417 <= _1413;
        5:
            _1417 <= _1414;
        6:
            _1417 <= _1415;
        default:
            _1417 <= _1416;
        endcase
    end
    assign _1419 = _1417 == _1418;
    assign _3906 = ~ _1419;
    assign _3905 = _1405 == _651;
    assign _3907 = _3905 & _3906;
    assign _3908 = _3907 & _1432;
    assign _3901 = t1_isr_count < cfg_t1_threshold;
    assign _3900 = t1_osr_count < cfg_t1_threshold;
    assign _3898 = t1_x == t1_y;
    assign _3899 = ~ _3898;
    assign _3895 = t1_y == _307;
    assign _3896 = ~ _3895;
    assign _3897 = ~ _3896;
    assign _3880 = t1_x - _988;
    assign _3878 = _3848 == _4223;
    assign _3881 = _3878 ? _3880 : t1_x;
    assign _3874 = _3843 == _226;
    assign _3875 = _3874 ? _1658 : t1_x;
    assign _1878 = cfg_t1_shift[4:4];
    assign _1879 = { _1878,
                     _1878 };
    assign _1880 = { _1879,
                     _1879 };
    assign _1881 = { _1880,
                     _1880 };
    assign _1882 = { _1881,
                     _1881 };
    assign _1883 = { _1882,
                     _1882 };
    assign _1534 = 7'b1110011;
    assign _1535 = _610 == _1534;
    assign _1533 = _604 & _608;
    assign _1536 = _1533 & _1535;
    assign _1537 = _1536 ? _614 : cfg_t1_crc_init_lo;
    assign _34 = _1537;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_crc_init_lo <= _307;
        else
            cfg_t1_crc_init_lo <= _34;
    end
    assign _1539 = 7'b1110100;
    assign _1540 = _610 == _1539;
    assign _1538 = _604 & _608;
    assign _1541 = _1538 & _1540;
    assign _1542 = _1541 ? _614 : cfg_t1_crc_init_hi;
    assign _35 = _1542;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_crc_init_hi <= _307;
        else
            cfg_t1_crc_init_hi <= _35;
    end
    assign _1819 = { cfg_t1_crc_init_hi,
                     cfg_t1_crc_init_lo };
    assign _1816 = t1_crc[31:16];
    assign _1817 = { _307,
                     _1816 };
    assign _1818 = _1568 ? _1817 : _1813;
    assign _1820 = _1566 ? _1819 : _1818;
    assign _1821 = _1564 ? _1820 : _1813;
    assign _1814 = _1405 == _1689;
    assign _1822 = _1814 ? _1821 : _1813;
    assign _1802 = _1782[15:15];
    assign _1801 = _1782[14:14];
    assign _1800 = _1782[13:13];
    assign _1799 = _1782[12:12];
    assign _1798 = _1782[11:11];
    assign _1797 = _1782[10:10];
    assign _1796 = _1782[9:9];
    assign _1795 = _1782[8:8];
    assign _1794 = _1782[7:7];
    assign _1793 = _1782[6:6];
    assign _1792 = _1782[5:5];
    assign _1791 = _1782[4:4];
    assign _1790 = _1782[3:3];
    assign _1789 = _1782[2:2];
    assign _1788 = _1782[1:1];
    assign _1787 = _1782[0:0];
    assign _1785 = _1473 - _1259;
    assign _1786 = _1785[3:0];
    always @* begin
        case (_1786)
        0:
            _1803 <= _1787;
        1:
            _1803 <= _1788;
        2:
            _1803 <= _1789;
        3:
            _1803 <= _1790;
        4:
            _1803 <= _1791;
        5:
            _1803 <= _1792;
        6:
            _1803 <= _1793;
        7:
            _1803 <= _1794;
        8:
            _1803 <= _1795;
        9:
            _1803 <= _1796;
        10:
            _1803 <= _1797;
        11:
            _1803 <= _1798;
        12:
            _1803 <= _1799;
        13:
            _1803 <= _1800;
        14:
            _1803 <= _1801;
        default:
            _1803 <= _1802;
        endcase
    end
    assign _1781 = _1780 & _1626;
    assign _1782 = _1580 ? _1781 : _1658;
    assign _1783 = _1782[0:0];
    assign _1597 = _1580 ? _1596 : _1595;
    assign _1804 = _1597 ? _1803 : _1783;
    assign _1594 = t1_crc[0:0];
    assign _1805 = _1594 ^ _1804;
    assign _1806 = { _1805,
                     _1805 };
    assign _1807 = { _1806,
                     _1806 };
    assign _1808 = { _1807,
                     _1807 };
    assign _1809 = { _1808,
                     _1808 };
    assign _1810 = { _1809,
                     _1809 };
    assign _1544 = 7'b1110001;
    assign _1545 = _610 == _1544;
    assign _1543 = _604 & _608;
    assign _1546 = _1543 & _1545;
    assign _1547 = _1546 ? _614 : cfg_t1_crc_poly_lo;
    assign _36 = _1547;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_crc_poly_lo <= _307;
        else
            cfg_t1_crc_poly_lo <= _36;
    end
    assign _1549 = 7'b1110010;
    assign _1550 = _610 == _1549;
    assign _1548 = _604 & _608;
    assign _1551 = _1548 & _1550;
    assign _1552 = _1551 ? _614 : cfg_t1_crc_poly_hi;
    assign _37 = _1552;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_crc_poly_hi <= _307;
        else
            cfg_t1_crc_poly_hi <= _37;
    end
    assign _1593 = { cfg_t1_crc_poly_hi,
                     cfg_t1_crc_poly_lo };
    assign _1811 = _1593 & _1810;
    assign _1591 = t1_crc[31:1];
    assign _1592 = { _598,
                     _1591 };
    assign _1812 = _1592 ^ _1811;
    assign _1584 = _1405 == _4223;
    assign _1582 = _1405 == _1056;
    assign _1580 = cfg_t1_shift[5:5];
    assign _1585 = _1580 ? _1584 : _1582;
    assign _1568 = _1561 == _1042;
    assign _1569 = _1568 ? gnd : t1_crc_run;
    assign _1566 = _1558 == _1042;
    assign _1571 = _1566 ? _1837 : _1569;
    assign _1572 = _1564 ? _1571 : t1_crc_run;
    assign _1557 = _1405 == _1689;
    assign _1573 = _1557 ? _1572 : t1_crc_run;
    assign _1574 = _1483 ? _1573 : t1_crc_run;
    assign _1575 = _1400 ? t1_crc_run : _1574;
    assign _1576 = _1394 ? t1_crc_run : _1575;
    assign _1578 = _1388 ? _1837 : _1576;
    assign _38 = _1578;
    assign _39 = _38;
    always @(posedge _141) begin
        if (_139)
            t1_crc_run <= _598;
        else
            t1_crc_run <= _39;
    end
    assign _1579 = _1483 & t1_crc_run;
    assign _1586 = _1579 & _1585;
    assign _1813 = _1586 ? _1812 : t1_crc;
    assign _1823 = _1483 ? _1822 : _1813;
    assign _1824 = _1400 ? t1_crc : _1823;
    assign _1825 = _1394 ? t1_crc : _1824;
    assign _1826 = _1388 ? _1819 : _1825;
    assign _40 = _1826;
    assign _41 = _40;
    always @(posedge _141) begin
        if (_139)
            t1_crc <= _1063;
        else
            t1_crc <= _41;
    end
    assign _1884 = t1_crc ^ _1883;
    assign _1885 = _1884[15:0];
    assign _1876 = { _568,
                     _883 };
    assign _3852 = t1_y - _988;
    assign _3850 = _3848 == _4367;
    assign _3853 = _3850 ? _3852 : t1_y;
    assign _1654 = _1652[31:16];
    assign _1655 = { _307,
                     _1654 };
    assign _1650 = _1648[31:8];
    assign _1651 = { _568,
                     _1650 };
    assign _1646 = _1644[31:4];
    assign _1647 = { _647,
                     _1646 };
    assign _1642 = _1640[31:2];
    assign _1643 = { _4358,
                     _1642 };
    assign _1638 = _1636[31:1];
    assign _1639 = { _598,
                     _1638 };
    assign _1636 = { _307,
                     t1_osr };
    assign _1634 = _1629[0:0];
    assign _1640 = _1634 ? _1639 : _1636;
    assign _1633 = _1629[1:1];
    assign _1644 = _1633 ? _1643 : _1640;
    assign _1632 = _1629[2:2];
    assign _1648 = _1632 ? _1647 : _1644;
    assign _1631 = _1629[3:3];
    assign _1652 = _1631 ? _1651 : _1648;
    assign _1629 = _1103 - _1473;
    assign _1630 = _1629[4:4];
    assign _1656 = _1630 ? _1655 : _1652;
    assign _1657 = _1656[15:0];
    assign _3810 = _3809[15:0];
    assign _3812 = { _3810,
                     _307 };
    assign _3806 = _3805[23:0];
    assign _3808 = { _3806,
                     _568 };
    assign _3802 = _3801[27:0];
    assign _3804 = { _3802,
                     _647 };
    assign _3798 = _3797[29:0];
    assign _3800 = { _3798,
                     _4358 };
    assign _3794 = _3793[30:0];
    assign _3796 = { _3794,
                     _598 };
    assign _3793 = { _307,
                     t1_osr };
    assign _3791 = _1473[0:0];
    assign _3797 = _3791 ? _3796 : _3793;
    assign _3790 = _1473[1:1];
    assign _3801 = _3790 ? _3800 : _3797;
    assign _3789 = _1473[2:2];
    assign _3805 = _3789 ? _3804 : _3801;
    assign _3788 = _1473[3:3];
    assign _3809 = _3788 ? _3808 : _3805;
    assign _3787 = _1473[4:4];
    assign _3813 = _3787 ? _3812 : _3809;
    assign _3814 = _3813[15:0];
    assign _3783 = _3781[31:16];
    assign _3784 = { _307,
                     _3783 };
    assign _3779 = _3777[31:8];
    assign _3780 = { _568,
                     _3779 };
    assign _3775 = _3773[31:4];
    assign _3776 = { _647,
                     _3775 };
    assign _3771 = _3769[31:2];
    assign _3772 = { _4358,
                     _3771 };
    assign _3767 = _3765[31:1];
    assign _3768 = { _598,
                     _3767 };
    assign _3765 = { _307,
                     t1_osr };
    assign _3763 = _1473[0:0];
    assign _3769 = _3763 ? _3768 : _3765;
    assign _3762 = _1473[1:1];
    assign _3773 = _3762 ? _3772 : _3769;
    assign _3761 = _1473[2:2];
    assign _3777 = _3761 ? _3776 : _3773;
    assign _3760 = _1473[3:3];
    assign _3781 = _3760 ? _3780 : _3777;
    assign _3759 = _1473[4:4];
    assign _3785 = _3759 ? _3784 : _3781;
    assign _3786 = _3785[15:0];
    assign _3815 = _1595 ? _3814 : _3786;
    assign _3816 = _3681 ? _3748 : _3815;
    assign _3757 = _1437 ? _3748 : _3749;
    assign _3753 = _1558 == _4367;
    assign _3754 = _3753 ? _1886 : _3749;
    assign _3755 = _1564 ? _3754 : _3749;
    assign _3752 = _1405 == _1689;
    assign _3756 = _3752 ? _3755 : _3749;
    assign _3751 = _1405 == _4367;
    assign _3758 = _3751 ? _3757 : _3756;
    assign _3750 = _1405 == _1056;
    assign _3817 = _3750 ? _3816 : _3758;
    assign _3745 = t1_tx_wr == _965;
    assign _3746 = _1849 & _3745;
    always @(posedge _141) begin
        if (_139)
            t1_tx_mem_3 <= _307;
        else
            if (_3746)
                t1_tx_mem_3 <= _3723;
    end
    assign _3739 = t1_tx_wr == _229;
    assign _3740 = _1849 & _3739;
    always @(posedge _141) begin
        if (_139)
            t1_tx_mem_2 <= _307;
        else
            if (_3740)
                t1_tx_mem_2 <= _3723;
    end
    assign _3733 = t1_tx_wr == _226;
    assign _3734 = _1849 & _3733;
    always @(posedge _141) begin
        if (_139)
            t1_tx_mem_1 <= _307;
        else
            if (_3734)
                t1_tx_mem_1 <= _3723;
    end
    assign _1854 = t1_tx_wr + _226;
    assign _1855 = _1849 ? _1854 : t1_tx_wr;
    assign _42 = _1855;
    always @(posedge _141) begin
        if (_139)
            t1_tx_wr <= _4358;
        else
            t1_tx_wr <= _42;
    end
    assign _3727 = t1_tx_wr == _4358;
    assign _3728 = _1849 & _3727;
    assign _43 = _399;
    assign _503 = t1_rx_wr == _965;
    assign _504 = _480 & _503;
    always @(posedge _141) begin
        if (_139)
            t1_rx_mem_3 <= _307;
        else
            if (_504)
                t1_rx_mem_3 <= _50;
    end
    assign _497 = t1_rx_wr == _229;
    assign _498 = _480 & _497;
    always @(posedge _141) begin
        if (_139)
            t1_rx_mem_2 <= _307;
        else
            if (_498)
                t1_rx_mem_2 <= _50;
    end
    assign _491 = t1_rx_wr == _226;
    assign _492 = _480 & _491;
    always @(posedge _141) begin
        if (_139)
            t1_rx_mem_1 <= _307;
        else
            if (_492)
                t1_rx_mem_1 <= _50;
    end
    assign _1857 = t1_rx_wr + _226;
    assign _1858 = _480 ? _1857 : t1_rx_wr;
    assign _44 = _1858;
    always @(posedge _141) begin
        if (_139)
            t1_rx_wr <= _4358;
        else
            t1_rx_wr <= _44;
    end
    assign _485 = t1_rx_wr == _4358;
    assign _486 = _480 & _485;
    assign _2096 = _2095[15:0];
    assign _2098 = { _2096,
                     _307 };
    assign _2092 = _2091[23:0];
    assign _2094 = { _2092,
                     _568 };
    assign _2088 = _2087[27:0];
    assign _2090 = { _2088,
                     _647 };
    assign _2084 = _2083[29:0];
    assign _2086 = { _2084,
                     _4358 };
    assign _2082 = 32'b11111111111111111111111111111110;
    assign _2081 = 32'b11111111111111111111111111111111;
    assign _2080 = _1977[0:0];
    assign _2083 = _2080 ? _2082 : _2081;
    assign _2079 = _1977[1:1];
    assign _2087 = _2079 ? _2086 : _2083;
    assign _2078 = _1977[2:2];
    assign _2091 = _2078 ? _2090 : _2087;
    assign _2077 = _1977[3:3];
    assign _2095 = _2077 ? _2094 : _2091;
    assign _2076 = _1977[4:4];
    assign _2099 = _2076 ? _2098 : _2095;
    assign _2100 = _2099[15:0];
    assign _2101 = ~ _2100;
    assign _2102 = _1950 & _2101;
    assign _2072 = _2070[31:16];
    assign _2073 = { _307,
                     _2072 };
    assign _2068 = _2066[31:8];
    assign _2069 = { _568,
                     _2068 };
    assign _2064 = _2062[31:4];
    assign _2065 = { _647,
                     _2064 };
    assign _2060 = _2058[31:2];
    assign _2061 = { _4358,
                     _2060 };
    assign _2056 = _2054[31:1];
    assign _2057 = { _598,
                     _2056 };
    assign _2054 = { _307,
                     _1950 };
    assign _2052 = _2047[0:0];
    assign _2058 = _2052 ? _2057 : _2054;
    assign _2051 = _2047[1:1];
    assign _2062 = _2051 ? _2061 : _2058;
    assign _2050 = _2047[2:2];
    assign _2066 = _2050 ? _2065 : _2062;
    assign _2049 = _2047[3:3];
    assign _2070 = _2049 ? _2069 : _2066;
    assign _2047 = _1103 - _1977;
    assign _2048 = _2047[4:4];
    assign _2074 = _2048 ? _2073 : _2070;
    assign _2075 = _2074[15:0];
    assign _2103 = _1596 ? _2102 : _2075;
    assign _2038 = _2037[15:0];
    assign _2040 = { _2038,
                     _307 };
    assign _2034 = _2033[23:0];
    assign _2036 = { _2034,
                     _568 };
    assign _2030 = _2029[27:0];
    assign _2032 = { _2030,
                     _647 };
    assign _2026 = _2025[29:0];
    assign _2028 = { _2026,
                     _4358 };
    assign _2022 = t1_isr_count[0:0];
    assign _2025 = _2022 ? _2082 : _2081;
    assign _2021 = t1_isr_count[1:1];
    assign _2029 = _2021 ? _2028 : _2025;
    assign _2020 = t1_isr_count[2:2];
    assign _2033 = _2020 ? _2032 : _2029;
    assign _2019 = t1_isr_count[3:3];
    assign _2037 = _2019 ? _2036 : _2033;
    assign _2018 = t1_isr_count[4:4];
    assign _2041 = _2018 ? _2040 : _2037;
    assign _2042 = _2041[15:0];
    assign _2043 = ~ _2042;
    assign _2044 = t1_isr & _2043;
    assign _2014 = _2012[31:16];
    assign _2015 = { _307,
                     _2014 };
    assign _2010 = _2008[31:8];
    assign _2011 = { _568,
                     _2010 };
    assign _2006 = _2004[31:4];
    assign _2007 = { _647,
                     _2006 };
    assign _2002 = _2000[31:2];
    assign _2003 = { _4358,
                     _2002 };
    assign _1998 = _1996[31:1];
    assign _1999 = { _598,
                     _1998 };
    assign _1621 = _1620[15:0];
    assign _1623 = { _1621,
                     _307 };
    assign _1617 = _1616[23:0];
    assign _1619 = { _1617,
                     _568 };
    assign _1613 = _1612[27:0];
    assign _1615 = { _1613,
                     _647 };
    assign _1609 = _1608[29:0];
    assign _1611 = { _1609,
                     _4358 };
    assign _1605 = _1473[0:0];
    assign _1608 = _1605 ? _2082 : _2081;
    assign _1604 = _1473[1:1];
    assign _1612 = _1604 ? _1611 : _1608;
    assign _1603 = _1473[2:2];
    assign _1616 = _1603 ? _1615 : _1612;
    assign _1602 = _1473[3:3];
    assign _1620 = _1602 ? _1619 : _1616;
    assign _1601 = _1473[4:4];
    assign _1624 = _1601 ? _1623 : _1620;
    assign _1625 = _1624[15:0];
    assign _1626 = ~ _1625;
    assign _1948 = _1780 & _1626;
    assign _1943 = _1942[15:0];
    assign _1945 = { _1943,
                     _307 };
    assign _1939 = _1938[23:0];
    assign _1941 = { _1939,
                     _568 };
    assign _1935 = _1934[27:0];
    assign _1937 = { _1935,
                     _647 };
    assign _1931 = _1930[29:0];
    assign _1933 = { _1931,
                     _4358 };
    assign _1927 = _1926[30:0];
    assign _1929 = { _1927,
                     _598 };
    assign _1926 = { _307,
                     t1_isr };
    assign _1924 = _1473[0:0];
    assign _1930 = _1924 ? _1929 : _1926;
    assign _1923 = _1473[1:1];
    assign _1934 = _1923 ? _1933 : _1930;
    assign _1922 = _1473[2:2];
    assign _1938 = _1922 ? _1937 : _1934;
    assign _1921 = _1473[3:3];
    assign _1942 = _1921 ? _1941 : _1938;
    assign _1920 = _1473[4:4];
    assign _1946 = _1920 ? _1945 : _1942;
    assign _1947 = _1946[15:0];
    assign _1949 = _1947 | _1948;
    assign _1916 = _1914[31:16];
    assign _1917 = { _307,
                     _1916 };
    assign _1912 = _1910[31:8];
    assign _1913 = { _568,
                     _1912 };
    assign _1908 = _1906[31:4];
    assign _1909 = { _647,
                     _1908 };
    assign _1904 = _1902[31:2];
    assign _1905 = { _4358,
                     _1904 };
    assign _1900 = _1898[31:1];
    assign _1901 = { _598,
                     _1900 };
    assign _1769 = _929 < _1473;
    assign _1766 = _883[7:7];
    assign _1765 = _883[6:6];
    assign _1764 = _883[5:5];
    assign _1763 = _883[4:4];
    assign _1762 = _883[3:3];
    assign _1761 = _883[2:2];
    assign _1760 = _883[1:1];
    assign _1759 = _883[0:0];
    always @* begin
        case (cfg_t1_in_base)
        0:
            _1767 <= _1759;
        1:
            _1767 <= _1760;
        2:
            _1767 <= _1761;
        3:
            _1767 <= _1762;
        4:
            _1767 <= _1763;
        5:
            _1767 <= _1764;
        6:
            _1767 <= _1765;
        default:
            _1767 <= _1766;
        endcase
    end
    assign _1770 = _1767 & _1769;
    assign _1757 = _1259 < _1473;
    assign _1754 = _883[7:7];
    assign _1753 = _883[6:6];
    assign _1752 = _883[5:5];
    assign _1751 = _883[4:4];
    assign _1750 = _883[3:3];
    assign _1749 = _883[2:2];
    assign _1748 = _883[1:1];
    assign _1747 = _883[0:0];
    assign _1746 = cfg_t1_in_base + _651;
    always @* begin
        case (_1746)
        0:
            _1755 <= _1747;
        1:
            _1755 <= _1748;
        2:
            _1755 <= _1749;
        3:
            _1755 <= _1750;
        4:
            _1755 <= _1751;
        5:
            _1755 <= _1752;
        6:
            _1755 <= _1753;
        default:
            _1755 <= _1754;
        endcase
    end
    assign _1758 = _1755 & _1757;
    assign _1742 = 5'b00010;
    assign _1743 = _1742 < _1473;
    assign _1740 = _883[7:7];
    assign _1739 = _883[6:6];
    assign _1738 = _883[5:5];
    assign _1737 = _883[4:4];
    assign _1736 = _883[3:3];
    assign _1735 = _883[2:2];
    assign _1734 = _883[1:1];
    assign _1733 = _883[0:0];
    assign _1732 = cfg_t1_in_base + _4223;
    always @* begin
        case (_1732)
        0:
            _1741 <= _1733;
        1:
            _1741 <= _1734;
        2:
            _1741 <= _1735;
        3:
            _1741 <= _1736;
        4:
            _1741 <= _1737;
        5:
            _1741 <= _1738;
        6:
            _1741 <= _1739;
        default:
            _1741 <= _1740;
        endcase
    end
    assign _1744 = _1741 & _1743;
    assign _1728 = 5'b00011;
    assign _1729 = _1728 < _1473;
    assign _1726 = _883[7:7];
    assign _1725 = _883[6:6];
    assign _1724 = _883[5:5];
    assign _1723 = _883[4:4];
    assign _1722 = _883[3:3];
    assign _1721 = _883[2:2];
    assign _1720 = _883[1:1];
    assign _1719 = _883[0:0];
    assign _1718 = cfg_t1_in_base + _1056;
    always @* begin
        case (_1718)
        0:
            _1727 <= _1719;
        1:
            _1727 <= _1720;
        2:
            _1727 <= _1721;
        3:
            _1727 <= _1722;
        4:
            _1727 <= _1723;
        5:
            _1727 <= _1724;
        6:
            _1727 <= _1725;
        default:
            _1727 <= _1726;
        endcase
    end
    assign _1730 = _1727 & _1729;
    assign _1714 = 5'b00100;
    assign _1715 = _1714 < _1473;
    assign _1712 = _883[7:7];
    assign _1711 = _883[6:6];
    assign _1710 = _883[5:5];
    assign _1709 = _883[4:4];
    assign _1708 = _883[3:3];
    assign _1707 = _883[2:2];
    assign _1706 = _883[1:1];
    assign _1705 = _883[0:0];
    assign _1704 = cfg_t1_in_base + _4367;
    always @* begin
        case (_1704)
        0:
            _1713 <= _1705;
        1:
            _1713 <= _1706;
        2:
            _1713 <= _1707;
        3:
            _1713 <= _1708;
        4:
            _1713 <= _1709;
        5:
            _1713 <= _1710;
        6:
            _1713 <= _1711;
        default:
            _1713 <= _1712;
        endcase
    end
    assign _1716 = _1713 & _1715;
    assign _1700 = 5'b00101;
    assign _1701 = _1700 < _1473;
    assign _1698 = _883[7:7];
    assign _1697 = _883[6:6];
    assign _1696 = _883[5:5];
    assign _1695 = _883[4:4];
    assign _1694 = _883[3:3];
    assign _1693 = _883[2:2];
    assign _1692 = _883[1:1];
    assign _1691 = _883[0:0];
    assign _1689 = 3'b101;
    assign _1690 = cfg_t1_in_base + _1689;
    always @* begin
        case (_1690)
        0:
            _1699 <= _1691;
        1:
            _1699 <= _1692;
        2:
            _1699 <= _1693;
        3:
            _1699 <= _1694;
        4:
            _1699 <= _1695;
        5:
            _1699 <= _1696;
        6:
            _1699 <= _1697;
        default:
            _1699 <= _1698;
        endcase
    end
    assign _1702 = _1699 & _1701;
    assign _1686 = 5'b00110;
    assign _1687 = _1686 < _1473;
    assign _1684 = _883[7:7];
    assign _1683 = _883[6:6];
    assign _1682 = _883[5:5];
    assign _1681 = _883[4:4];
    assign _1680 = _883[3:3];
    assign _1679 = _883[2:2];
    assign _1678 = _883[1:1];
    assign _1677 = _883[0:0];
    assign _1676 = cfg_t1_in_base + _1042;
    always @* begin
        case (_1676)
        0:
            _1685 <= _1677;
        1:
            _1685 <= _1678;
        2:
            _1685 <= _1679;
        3:
            _1685 <= _1680;
        4:
            _1685 <= _1681;
        5:
            _1685 <= _1682;
        6:
            _1685 <= _1683;
        default:
            _1685 <= _1684;
        endcase
    end
    assign _1688 = _1685 & _1687;
    assign _1672 = 5'b00111;
    assign _1673 = _1672 < _1473;
    assign _1670 = _883[7:7];
    assign _1669 = _883[6:6];
    assign _1668 = _883[5:5];
    assign _1667 = _883[4:4];
    assign _1666 = _883[3:3];
    assign _1665 = _883[2:2];
    assign _1664 = _883[1:1];
    assign _1663 = _883[0:0];
    assign _1661 = 3'b111;
    assign _1863 = _614[2:0];
    assign _1860 = 7'b1010100;
    assign _1861 = _610 == _1860;
    assign _1859 = _604 & _608;
    assign _1862 = _1859 & _1861;
    assign _1864 = _1862 ? _1863 : cfg_t1_in_base;
    assign _45 = _1864;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_in_base <= _468;
        else
            cfg_t1_in_base <= _45;
    end
    assign _1662 = cfg_t1_in_base + _1661;
    always @* begin
        case (_1662)
        0:
            _1671 <= _1663;
        1:
            _1671 <= _1664;
        2:
            _1671 <= _1665;
        3:
            _1671 <= _1666;
        4:
            _1671 <= _1667;
        5:
            _1671 <= _1668;
        6:
            _1671 <= _1669;
        default:
            _1671 <= _1670;
        endcase
    end
    assign _1674 = _1671 & _1673;
    assign _1771 = { _1674,
                     _1688,
                     _1702,
                     _1716,
                     _1730,
                     _1744,
                     _1758,
                     _1770 };
    assign _1772 = { _568,
                     _1771 };
    assign _1659 = _102[8:7];
    always @* begin
        case (_1659)
        0:
            _1780 <= _1772;
        1:
            _1780 <= t1_x;
        2:
            _1780 <= t1_y;
        default:
            _1780 <= _307;
        endcase
    end
    assign _1898 = { _1780,
                     t1_isr };
    assign _1897 = _1473[0:0];
    assign _1902 = _1897 ? _1901 : _1898;
    assign _1896 = _1473[1:1];
    assign _1906 = _1896 ? _1905 : _1902;
    assign _1895 = _1473[2:2];
    assign _1910 = _1895 ? _1909 : _1906;
    assign _1894 = _1473[3:3];
    assign _1914 = _1894 ? _1913 : _1910;
    assign _1893 = _1473[4:4];
    assign _1918 = _1893 ? _1917 : _1914;
    assign _1919 = _1918[15:0];
    assign _1950 = _1596 ? _1949 : _1919;
    assign _1952 = _1479 ? _307 : _1950;
    assign _1891 = _1437 ? t1_isr : _307;
    assign _1874 = _1558 == _1056;
    assign _1887 = _1874 ? _1886 : t1_isr;
    assign _1888 = _1564 ? _1887 : t1_isr;
    assign _1872 = _1405 == _1689;
    assign _1889 = _1872 ? _1888 : t1_isr;
    assign _1871 = _1405 == _4367;
    assign _1892 = _1871 ? _1891 : _1889;
    assign _1869 = _1405 == _4223;
    assign _1953 = _1869 ? _1952 : _1892;
    assign _1954 = _1483 ? _1953 : t1_isr;
    assign _1955 = _1400 ? t1_isr : _1954;
    assign _1956 = _1394 ? t1_isr : _1955;
    assign _1958 = _1388 ? _307 : _1956;
    assign _46 = _1958;
    assign _47 = _46;
    always @(posedge _141) begin
        if (_139)
            t1_isr <= _307;
        else
            t1_isr <= _47;
    end
    assign _1996 = { _307,
                     t1_isr };
    assign _1994 = _1989[0:0];
    assign _2000 = _1994 ? _1999 : _1996;
    assign _1993 = _1989[1:1];
    assign _2004 = _1993 ? _2003 : _2000;
    assign _1992 = _1989[2:2];
    assign _2008 = _1992 ? _2007 : _2004;
    assign _1991 = _1989[3:3];
    assign _2012 = _1991 ? _2011 : _2008;
    assign _1975 = _1973[4:0];
    assign _1972 = { gnd,
                     _1473 };
    assign _1971 = { gnd,
                     t1_isr_count };
    assign _1973 = _1971 + _1972;
    assign _1970 = 6'b010000;
    assign _1974 = _1970 < _1973;
    assign _1977 = _1974 ? _1103 : _1975;
    assign _1476 = { gnd,
                     cfg_t1_threshold };
    assign _1474 = { gnd,
                     _1473 };
    assign _1467 = { gnd,
                     t1_isr_count };
    assign _1475 = _1467 + _1474;
    assign _1477 = _1475 < _1476;
    assign _1478 = ~ _1477;
    assign _1462 = cfg_t1_shift[3:3];
    assign _1461 = _1405 == _4223;
    assign _1463 = _1461 & _1462;
    assign _1479 = _1463 & _1478;
    assign _1979 = _1479 ? _929 : _1977;
    assign _1968 = _1437 ? t1_isr_count : _929;
    assign _1962 = _1558 == _1056;
    assign _1964 = _1962 ? _929 : t1_isr_count;
    assign _1965 = _1564 ? _1964 : t1_isr_count;
    assign _1961 = _1405 == _1689;
    assign _1966 = _1961 ? _1965 : t1_isr_count;
    assign _1960 = _1405 == _4367;
    assign _1969 = _1960 ? _1968 : _1966;
    assign _1959 = _1405 == _4223;
    assign _1980 = _1959 ? _1979 : _1969;
    assign _1981 = _1483 ? _1980 : t1_isr_count;
    assign _1982 = _1400 ? t1_isr_count : _1981;
    assign _1983 = _1394 ? t1_isr_count : _1982;
    assign _1985 = _1388 ? _929 : _1983;
    assign _48 = _1985;
    assign _49 = _48;
    always @(posedge _141) begin
        if (_139)
            t1_isr_count <= _929;
        else
            t1_isr_count <= _49;
    end
    assign _1989 = _1103 - t1_isr_count;
    assign _1990 = _1989[4:4];
    assign _2016 = _1990 ? _2015 : _2012;
    assign _2017 = _2016[15:0];
    assign _1596 = cfg_t1_shift[1:1];
    assign _2045 = _1596 ? _2044 : _2017;
    assign _1987 = _1405 == _4223;
    assign _2104 = _1987 ? _2103 : _2045;
    assign _50 = _2104;
    always @(posedge _141) begin
        if (_139)
            t1_rx_mem_0 <= _307;
        else
            if (_486)
                t1_rx_mem_0 <= _50;
    end
    assign _2131 = t1_rx_rd + _226;
    assign _2128 = ~ _2127;
    assign _2123 = _1302 == _1837;
    assign _2124 = _110 & _2123;
    assign _2118 = _1302 == _1837;
    assign _2116 = _1310 == _229;
    assign _2119 = _2116 & _2118;
    assign _2120 = ~ _2119;
    assign _2112 = t1_rx_level == _468;
    assign _2113 = ~ _2112;
    assign _2108 = 7'b1011001;
    assign _2109 = _321 == _2108;
    assign _2105 = _320[7:7];
    assign _2106 = ~ _2105;
    assign _2107 = _1366 & _2106;
    assign _2110 = _2107 & _2109;
    assign _2114 = _2110 & _2113;
    assign _51 = _2114;
    assign _2121 = _51 & _2120;
    assign _2125 = _2121 | _2124;
    assign _2129 = _2125 & _2128;
    assign _2132 = _2129 ? _2131 : t1_rx_rd;
    assign _52 = _2132;
    always @(posedge _141) begin
        if (_139)
            t1_rx_rd <= _4358;
        else
            t1_rx_rd <= _52;
    end
    always @* begin
        case (t1_rx_rd)
        0:
            _506 <= t1_rx_mem_0;
        1:
            _506 <= t1_rx_mem_1;
        2:
            _506 <= t1_rx_mem_2;
        default:
            _506 <= t1_rx_mem_3;
        endcase
    end
    assign _396 = t0_rx_wr == _965;
    assign _397 = _373 & _396;
    always @(posedge _141) begin
        if (_139)
            t0_rx_mem_3 <= _307;
        else
            if (_397)
                t0_rx_mem_3 <= _82;
    end
    assign _390 = t0_rx_wr == _229;
    assign _391 = _373 & _390;
    always @(posedge _141) begin
        if (_139)
            t0_rx_mem_2 <= _307;
        else
            if (_391)
                t0_rx_mem_2 <= _82;
    end
    assign _384 = t0_rx_wr == _226;
    assign _385 = _373 & _384;
    always @(posedge _141) begin
        if (_139)
            t0_rx_mem_1 <= _307;
        else
            if (_385)
                t0_rx_mem_1 <= _82;
    end
    assign _2134 = t0_rx_wr + _226;
    assign _2135 = _373 ? _2134 : t0_rx_wr;
    assign _53 = _2135;
    always @(posedge _141) begin
        if (_139)
            t0_rx_wr <= _4358;
        else
            t0_rx_wr <= _53;
    end
    assign _378 = t0_rx_wr == _4358;
    assign _379 = _373 & _378;
    assign _3598 = _3597[15:0];
    assign _3600 = { _3598,
                     _307 };
    assign _3594 = _3593[23:0];
    assign _3596 = { _3594,
                     _568 };
    assign _3590 = _3589[27:0];
    assign _3592 = { _3590,
                     _647 };
    assign _3586 = _3585[29:0];
    assign _3588 = { _3586,
                     _4358 };
    assign _3582 = _3479[0:0];
    assign _3585 = _3582 ? _2082 : _2081;
    assign _3581 = _3479[1:1];
    assign _3589 = _3581 ? _3588 : _3585;
    assign _3580 = _3479[2:2];
    assign _3593 = _3580 ? _3592 : _3589;
    assign _3579 = _3479[3:3];
    assign _3597 = _3579 ? _3596 : _3593;
    assign _3578 = _3479[4:4];
    assign _3601 = _3578 ? _3600 : _3597;
    assign _3602 = _3601[15:0];
    assign _3603 = ~ _3602;
    assign _3604 = _3452 & _3603;
    assign _3574 = _3572[31:16];
    assign _3575 = { _307,
                     _3574 };
    assign _3570 = _3568[31:8];
    assign _3571 = { _568,
                     _3570 };
    assign _3566 = _3564[31:4];
    assign _3567 = { _647,
                     _3566 };
    assign _3562 = _3560[31:2];
    assign _3563 = { _4358,
                     _3562 };
    assign _3558 = _3556[31:1];
    assign _3559 = { _598,
                     _3558 };
    assign _3556 = { _307,
                     _3452 };
    assign _3554 = _3549[0:0];
    assign _3560 = _3554 ? _3559 : _3556;
    assign _3553 = _3549[1:1];
    assign _3564 = _3553 ? _3563 : _3560;
    assign _3552 = _3549[2:2];
    assign _3568 = _3552 ? _3567 : _3564;
    assign _3551 = _3549[3:3];
    assign _3572 = _3551 ? _3571 : _3568;
    assign _3549 = _1103 - _3479;
    assign _3550 = _3549[4:4];
    assign _3576 = _3550 ? _3575 : _3572;
    assign _3577 = _3576[15:0];
    assign _3605 = _1071 ? _3604 : _3577;
    assign _3540 = _3539[15:0];
    assign _3542 = { _3540,
                     _307 };
    assign _3536 = _3535[23:0];
    assign _3538 = { _3536,
                     _568 };
    assign _3532 = _3531[27:0];
    assign _3534 = { _3532,
                     _647 };
    assign _3528 = _3527[29:0];
    assign _3530 = { _3528,
                     _4358 };
    assign _3524 = t0_isr_count[0:0];
    assign _3527 = _3524 ? _2082 : _2081;
    assign _3523 = t0_isr_count[1:1];
    assign _3531 = _3523 ? _3530 : _3527;
    assign _3522 = t0_isr_count[2:2];
    assign _3535 = _3522 ? _3534 : _3531;
    assign _3521 = t0_isr_count[3:3];
    assign _3539 = _3521 ? _3538 : _3535;
    assign _3520 = t0_isr_count[4:4];
    assign _3543 = _3520 ? _3542 : _3539;
    assign _3544 = _3543[15:0];
    assign _3545 = ~ _3544;
    assign _3546 = t0_isr & _3545;
    assign _3516 = _3514[31:16];
    assign _3517 = { _307,
                     _3516 };
    assign _3512 = _3510[31:8];
    assign _3513 = { _568,
                     _3512 };
    assign _3508 = _3506[31:4];
    assign _3509 = { _647,
                     _3508 };
    assign _3504 = _3502[31:2];
    assign _3505 = { _4358,
                     _3504 };
    assign _3500 = _3498[31:1];
    assign _3501 = { _598,
                     _3500 };
    assign _1096 = _1095[15:0];
    assign _1098 = { _1096,
                     _307 };
    assign _1092 = _1091[23:0];
    assign _1094 = { _1092,
                     _568 };
    assign _1088 = _1087[27:0];
    assign _1090 = { _1088,
                     _647 };
    assign _1084 = _1083[29:0];
    assign _1086 = { _1084,
                     _4358 };
    assign _1080 = _948[0:0];
    assign _1083 = _1080 ? _2082 : _2081;
    assign _1079 = _948[1:1];
    assign _1087 = _1079 ? _1086 : _1083;
    assign _1078 = _948[2:2];
    assign _1091 = _1078 ? _1090 : _1087;
    assign _1077 = _948[3:3];
    assign _1095 = _1077 ? _1094 : _1091;
    assign _1076 = _948[4:4];
    assign _1099 = _1076 ? _1098 : _1095;
    assign _1100 = _1099[15:0];
    assign _1101 = ~ _1100;
    assign _3450 = _1255 & _1101;
    assign _3445 = _3444[15:0];
    assign _3447 = { _3445,
                     _307 };
    assign _3441 = _3440[23:0];
    assign _3443 = { _3441,
                     _568 };
    assign _3437 = _3436[27:0];
    assign _3439 = { _3437,
                     _647 };
    assign _3433 = _3432[29:0];
    assign _3435 = { _3433,
                     _4358 };
    assign _3429 = _3428[30:0];
    assign _3431 = { _3429,
                     _598 };
    assign _3428 = { _307,
                     t0_isr };
    assign _3426 = _948[0:0];
    assign _3432 = _3426 ? _3431 : _3428;
    assign _3425 = _948[1:1];
    assign _3436 = _3425 ? _3435 : _3432;
    assign _3424 = _948[2:2];
    assign _3440 = _3424 ? _3439 : _3436;
    assign _3423 = _948[3:3];
    assign _3444 = _3423 ? _3443 : _3440;
    assign _3422 = _948[4:4];
    assign _3448 = _3422 ? _3447 : _3444;
    assign _3449 = _3448[15:0];
    assign _3451 = _3449 | _3450;
    assign _3418 = _3416[31:16];
    assign _3419 = { _307,
                     _3418 };
    assign _3414 = _3412[31:8];
    assign _3415 = { _568,
                     _3414 };
    assign _3410 = _3408[31:4];
    assign _3411 = { _647,
                     _3410 };
    assign _3406 = _3404[31:2];
    assign _3407 = { _4358,
                     _3406 };
    assign _3402 = _3400[31:1];
    assign _3403 = { _598,
                     _3402 };
    assign _1244 = _929 < _948;
    assign _1241 = _883[7:7];
    assign _1240 = _883[6:6];
    assign _1239 = _883[5:5];
    assign _1238 = _883[4:4];
    assign _1237 = _883[3:3];
    assign _1236 = _883[2:2];
    assign _1235 = _883[1:1];
    assign _1234 = _883[0:0];
    always @* begin
        case (cfg_t0_in_base)
        0:
            _1242 <= _1234;
        1:
            _1242 <= _1235;
        2:
            _1242 <= _1236;
        3:
            _1242 <= _1237;
        4:
            _1242 <= _1238;
        5:
            _1242 <= _1239;
        6:
            _1242 <= _1240;
        default:
            _1242 <= _1241;
        endcase
    end
    assign _1245 = _1242 & _1244;
    assign _1232 = _1259 < _948;
    assign _1229 = _883[7:7];
    assign _1228 = _883[6:6];
    assign _1227 = _883[5:5];
    assign _1226 = _883[4:4];
    assign _1225 = _883[3:3];
    assign _1224 = _883[2:2];
    assign _1223 = _883[1:1];
    assign _1222 = _883[0:0];
    assign _1221 = cfg_t0_in_base + _651;
    always @* begin
        case (_1221)
        0:
            _1230 <= _1222;
        1:
            _1230 <= _1223;
        2:
            _1230 <= _1224;
        3:
            _1230 <= _1225;
        4:
            _1230 <= _1226;
        5:
            _1230 <= _1227;
        6:
            _1230 <= _1228;
        default:
            _1230 <= _1229;
        endcase
    end
    assign _1233 = _1230 & _1232;
    assign _1218 = _1742 < _948;
    assign _1215 = _883[7:7];
    assign _1214 = _883[6:6];
    assign _1213 = _883[5:5];
    assign _1212 = _883[4:4];
    assign _1211 = _883[3:3];
    assign _1210 = _883[2:2];
    assign _1209 = _883[1:1];
    assign _1208 = _883[0:0];
    assign _1207 = cfg_t0_in_base + _4223;
    always @* begin
        case (_1207)
        0:
            _1216 <= _1208;
        1:
            _1216 <= _1209;
        2:
            _1216 <= _1210;
        3:
            _1216 <= _1211;
        4:
            _1216 <= _1212;
        5:
            _1216 <= _1213;
        6:
            _1216 <= _1214;
        default:
            _1216 <= _1215;
        endcase
    end
    assign _1219 = _1216 & _1218;
    assign _1204 = _1728 < _948;
    assign _1201 = _883[7:7];
    assign _1200 = _883[6:6];
    assign _1199 = _883[5:5];
    assign _1198 = _883[4:4];
    assign _1197 = _883[3:3];
    assign _1196 = _883[2:2];
    assign _1195 = _883[1:1];
    assign _1194 = _883[0:0];
    assign _1193 = cfg_t0_in_base + _1056;
    always @* begin
        case (_1193)
        0:
            _1202 <= _1194;
        1:
            _1202 <= _1195;
        2:
            _1202 <= _1196;
        3:
            _1202 <= _1197;
        4:
            _1202 <= _1198;
        5:
            _1202 <= _1199;
        6:
            _1202 <= _1200;
        default:
            _1202 <= _1201;
        endcase
    end
    assign _1205 = _1202 & _1204;
    assign _1190 = _1714 < _948;
    assign _1187 = _883[7:7];
    assign _1186 = _883[6:6];
    assign _1185 = _883[5:5];
    assign _1184 = _883[4:4];
    assign _1183 = _883[3:3];
    assign _1182 = _883[2:2];
    assign _1181 = _883[1:1];
    assign _1180 = _883[0:0];
    assign _1179 = cfg_t0_in_base + _4367;
    always @* begin
        case (_1179)
        0:
            _1188 <= _1180;
        1:
            _1188 <= _1181;
        2:
            _1188 <= _1182;
        3:
            _1188 <= _1183;
        4:
            _1188 <= _1184;
        5:
            _1188 <= _1185;
        6:
            _1188 <= _1186;
        default:
            _1188 <= _1187;
        endcase
    end
    assign _1191 = _1188 & _1190;
    assign _1176 = _1700 < _948;
    assign _1173 = _883[7:7];
    assign _1172 = _883[6:6];
    assign _1171 = _883[5:5];
    assign _1170 = _883[4:4];
    assign _1169 = _883[3:3];
    assign _1168 = _883[2:2];
    assign _1167 = _883[1:1];
    assign _1166 = _883[0:0];
    assign _1165 = cfg_t0_in_base + _1689;
    always @* begin
        case (_1165)
        0:
            _1174 <= _1166;
        1:
            _1174 <= _1167;
        2:
            _1174 <= _1168;
        3:
            _1174 <= _1169;
        4:
            _1174 <= _1170;
        5:
            _1174 <= _1171;
        6:
            _1174 <= _1172;
        default:
            _1174 <= _1173;
        endcase
    end
    assign _1177 = _1174 & _1176;
    assign _1162 = _1686 < _948;
    assign _1159 = _883[7:7];
    assign _1158 = _883[6:6];
    assign _1157 = _883[5:5];
    assign _1156 = _883[4:4];
    assign _1155 = _883[3:3];
    assign _1154 = _883[2:2];
    assign _1153 = _883[1:1];
    assign _1152 = _883[0:0];
    assign _1151 = cfg_t0_in_base + _1042;
    always @* begin
        case (_1151)
        0:
            _1160 <= _1152;
        1:
            _1160 <= _1153;
        2:
            _1160 <= _1154;
        3:
            _1160 <= _1155;
        4:
            _1160 <= _1156;
        5:
            _1160 <= _1157;
        6:
            _1160 <= _1158;
        default:
            _1160 <= _1159;
        endcase
    end
    assign _1163 = _1160 & _1162;
    assign _1148 = _1672 < _948;
    assign _1145 = _883[7:7];
    assign _1144 = _883[6:6];
    assign _1143 = _883[5:5];
    assign _1142 = _883[4:4];
    assign _1141 = _883[3:3];
    assign _1140 = _883[2:2];
    assign _1139 = _883[1:1];
    assign _879 = _878 & _877;
    assign _878 = pin_out[0:0];
    assign _877 = _671[0:0];
    assign _876 = cfg_pin_modes[1:0];
    always @* begin
        case (_876)
        0:
            _880 <= _877;
        1:
            _880 <= _878;
        2:
            _880 <= _879;
        default:
            _880 <= _877;
        endcase
    end
    assign _874 = _655 == _1661;
    assign _875 = _654 & _874;
    assign _881 = _875 ? smp_strobe : _880;
    assign _871 = _655 == _468;
    assign _872 = _654 & _871;
    assign _882 = _872 ? smp_data : _881;
    assign _866 = _865 & _864;
    assign _865 = pin_out[1:1];
    assign _864 = _671[1:1];
    assign _863 = cfg_pin_modes[3:2];
    always @* begin
        case (_863)
        0:
            _867 <= _864;
        1:
            _867 <= _865;
        2:
            _867 <= _866;
        default:
            _867 <= _864;
        endcase
    end
    assign _861 = _655 == _468;
    assign _862 = _654 & _861;
    assign _868 = _862 ? smp_strobe : _867;
    assign _858 = _655 == _651;
    assign _859 = _654 & _858;
    assign _869 = _859 ? smp_data : _868;
    assign _853 = _852 & _851;
    assign _852 = pin_out[2:2];
    assign _851 = _671[2:2];
    assign _850 = cfg_pin_modes[5:4];
    always @* begin
        case (_850)
        0:
            _854 <= _851;
        1:
            _854 <= _852;
        2:
            _854 <= _853;
        default:
            _854 <= _851;
        endcase
    end
    assign _848 = _655 == _651;
    assign _849 = _654 & _848;
    assign _855 = _849 ? smp_strobe : _854;
    assign _845 = _655 == _4223;
    assign _846 = _654 & _845;
    assign _856 = _846 ? smp_data : _855;
    assign _840 = _839 & _838;
    assign _839 = pin_out[3:3];
    assign _838 = _671[3:3];
    assign _837 = cfg_pin_modes[7:6];
    always @* begin
        case (_837)
        0:
            _841 <= _838;
        1:
            _841 <= _839;
        2:
            _841 <= _840;
        default:
            _841 <= _838;
        endcase
    end
    assign _835 = _655 == _4223;
    assign _836 = _654 & _835;
    assign _842 = _836 ? smp_strobe : _841;
    assign _832 = _655 == _1056;
    assign _833 = _654 & _832;
    assign _843 = _833 ? smp_data : _842;
    assign _827 = _826 & _825;
    assign _826 = pin_out[4:4];
    assign _825 = _671[4:4];
    assign _824 = cfg_pin_modes[9:8];
    always @* begin
        case (_824)
        0:
            _828 <= _825;
        1:
            _828 <= _826;
        2:
            _828 <= _827;
        default:
            _828 <= _825;
        endcase
    end
    assign _822 = _655 == _1056;
    assign _823 = _654 & _822;
    assign _829 = _823 ? smp_strobe : _828;
    assign _819 = _655 == _4367;
    assign _820 = _654 & _819;
    assign _830 = _820 ? smp_data : _829;
    assign _814 = _813 & _812;
    assign _813 = pin_out[5:5];
    assign _812 = _671[5:5];
    assign _811 = cfg_pin_modes[11:10];
    always @* begin
        case (_811)
        0:
            _815 <= _812;
        1:
            _815 <= _813;
        2:
            _815 <= _814;
        default:
            _815 <= _812;
        endcase
    end
    assign _809 = _655 == _4367;
    assign _810 = _654 & _809;
    assign _816 = _810 ? smp_strobe : _815;
    assign _806 = _655 == _1689;
    assign _807 = _654 & _806;
    assign _817 = _807 ? smp_data : _816;
    assign _801 = _800 & _799;
    assign _800 = pin_out[6:6];
    assign _799 = _671[6:6];
    assign _798 = cfg_pin_modes[13:12];
    always @* begin
        case (_798)
        0:
            _802 <= _799;
        1:
            _802 <= _800;
        2:
            _802 <= _801;
        default:
            _802 <= _799;
        endcase
    end
    assign _796 = _655 == _1689;
    assign _797 = _654 & _796;
    assign _803 = _797 ? smp_strobe : _802;
    assign _793 = _655 == _1042;
    assign _794 = _654 & _793;
    assign _804 = _794 ? smp_data : _803;
    assign _2137 = _723 ? _769 : smp_data;
    assign _2139 = _781 ? _2138 : _2137;
    assign _2140 = _654 ? _2139 : _598;
    assign _54 = _2140;
    always @(posedge _141) begin
        if (_139)
            smp_data <= _598;
        else
            smp_data <= _54;
    end
    assign _779 = ~ _720;
    assign _780 = _778 | _779;
    assign _781 = _767 & _780;
    assign _720 = cfg_smp_ctrl[5:5];
    assign _721 = ~ _720;
    assign _2158 = _2153 == cfg_smp_sync;
    assign _2159 = _767 & _2158;
    assign _2145 = _614[7:0];
    assign _2142 = 7'b1101110;
    assign _2143 = _610 == _2142;
    assign _2141 = _604 & _608;
    assign _2144 = _2141 & _2143;
    assign _2146 = _2144 ? _2145 : cfg_smp_sync;
    assign _55 = _2146;
    always @(posedge _141) begin
        if (_139)
            cfg_smp_sync <= _568;
        else
            cfg_smp_sync <= _55;
    end
    assign _2152 = _2151[7:1];
    assign _2138 = smp_mid ^ _768;
    assign _2153 = { _2138,
                     _2152 };
    assign _2150 = _719 ? _774 : smp_history;
    assign _2151 = _710 ? _2150 : _568;
    assign _766 = _765 == _717;
    assign _767 = _759 & _766;
    assign _2154 = _767 ? _2153 : _2151;
    assign _2155 = _759 ? _2154 : _568;
    assign _2156 = _654 ? _2155 : _568;
    assign _56 = _2156;
    always @(posedge _141) begin
        if (_139)
            smp_history <= _568;
        else
            smp_history <= _56;
    end
    assign _773 = smp_history[7:1];
    assign _768 = cfg_smp_ctrl[4:4];
    assign _769 = _684 ^ _768;
    assign _774 = { _769,
                    _773 };
    assign _775 = _774 == cfg_smp_sync;
    assign _776 = _719 & _775;
    assign _777 = smp_synced | _776;
    assign _778 = _710 & _777;
    assign _2160 = _778 | _2159;
    assign _2161 = _759 & _2160;
    assign _2162 = _654 ? _2161 : _598;
    assign _57 = _2162;
    always @(posedge _141) begin
        if (_139)
            smp_synced <= _598;
        else
            smp_synced <= _57;
    end
    assign _722 = smp_synced | _721;
    assign _717 = cfg_smp_time[9:5];
    assign _718 = _716 == _717;
    assign _709 = _698 ? _708 : smp_carrier;
    assign _762 = _716 + _1259;
    assign _763 = _744 ? _716 : _762;
    assign _692 = cfg_smp_time[4:0];
    assign _713 = smp_phase + _1259;
    assign _714 = _698 ? smp_phase : _713;
    assign _706 = smp_missed < _700;
    assign _707 = _702 | _706;
    assign _751 = smp_missed + _651;
    assign _2167 = _754 + _651;
    assign _2164 = ~ _747;
    assign _2165 = _757 & _2164;
    assign _2168 = _2165 ? _2167 : _754;
    assign _2170 = _742 ? _468 : _2168;
    assign _2171 = _654 ? _2170 : _468;
    assign _58 = _2171;
    always @(posedge _141) begin
        if (_139)
            smp_missed <= _468;
        else
            smp_missed <= _58;
    end
    assign _702 = _700 == _1661;
    assign _748 = ~ _702;
    assign _749 = _708 & _748;
    assign _752 = _749 ? _751 : smp_missed;
    assign _754 = _695 ? _468 : _752;
    assign _755 = _754 < _700;
    assign _700 = cfg_smp_ctrl[8:6];
    assign _747 = _700 == _1661;
    assign _756 = _747 | _755;
    assign _745 = _744 & _710;
    assign _757 = _745 & _756;
    assign _743 = _716 < _696;
    assign _744 = ~ _743;
    assign _758 = _744 ? _757 : _710;
    assign _759 = _742 | _758;
    assign _2173 = _654 ? _759 : _598;
    assign _59 = _2173;
    always @(posedge _141) begin
        if (_139)
            smp_carrier <= _598;
        else
            smp_carrier <= _59;
    end
    assign _565 = 15'b000000000000000;
    assign _2178 = _614[14:0];
    assign _2175 = 7'b1101101;
    assign _2176 = _610 == _2175;
    assign _2174 = _604 & _608;
    assign _2177 = _2174 & _2176;
    assign _2179 = _2177 ? _2178 : cfg_smp_time;
    assign _60 = _2179;
    always @(posedge _141) begin
        if (_139)
            cfg_smp_time <= _565;
        else
            cfg_smp_time <= _60;
    end
    assign _696 = cfg_smp_time[14:10];
    assign _697 = smp_phase < _696;
    assign _698 = ~ _697;
    assign _699 = _698 & smp_carrier;
    assign _708 = _699 & _707;
    assign _711 = _695 | _708;
    assign _716 = _711 ? _929 : _714;
    assign _740 = _716 < _692;
    assign _741 = ~ _740;
    assign _739 = smp_mid ^ _684;
    assign _742 = _739 & _741;
    assign _760 = _742 | _757;
    assign _765 = _760 ? _929 : _763;
    assign _2181 = _654 ? _765 : _929;
    assign _61 = _2181;
    always @(posedge _141) begin
        if (_139)
            smp_phase <= _929;
        else
            smp_phase <= _61;
    end
    assign _693 = smp_phase < _692;
    assign _694 = ~ _693;
    assign _731 = _74[7:7];
    assign _730 = _74[6:6];
    assign _729 = _74[5:5];
    assign _728 = _74[4:4];
    assign _727 = _74[3:3];
    assign _726 = _74[2:2];
    assign _725 = _74[1:1];
    assign _724 = _74[0:0];
    always @* begin
        case (_655)
        0:
            _732 <= _724;
        1:
            _732 <= _725;
        2:
            _732 <= _726;
        3:
            _732 <= _727;
        4:
            _732 <= _728;
        5:
            _732 <= _729;
        6:
            _732 <= _730;
        default:
            _732 <= _731;
        endcase
    end
    always @(negedge _141) begin
        if (_139)
            smp_fall <= _598;
        else
            smp_fall <= _732;
    end
    always @(posedge _141) begin
        if (_139)
            smp_mid <= _598;
        else
            smp_mid <= smp_fall;
    end
    assign _2183 = _654 ? smp_mid : _598;
    assign _62 = _2183;
    always @(posedge _141) begin
        if (_139)
            smp_last <= _598;
        else
            smp_last <= _62;
    end
    assign _683 = pins_sync2[7:7];
    assign _682 = pins_sync2[6:6];
    assign _681 = pins_sync2[5:5];
    assign _680 = pins_sync2[4:4];
    assign _679 = pins_sync2[3:3];
    assign _678 = pins_sync2[2:2];
    assign _677 = pins_sync2[1:1];
    assign _676 = pins_sync2[0:0];
    always @* begin
        case (_655)
        0:
            _684 <= _676;
        1:
            _684 <= _677;
        2:
            _684 <= _678;
        3:
            _684 <= _679;
        4:
            _684 <= _680;
        5:
            _684 <= _681;
        6:
            _684 <= _682;
        default:
            _684 <= _683;
        endcase
    end
    assign _688 = _684 ^ smp_last;
    assign _695 = _688 & _694;
    assign _710 = _695 | _709;
    assign _719 = _710 & _718;
    assign _723 = _719 & _722;
    assign _782 = _723 | _781;
    assign _783 = _654 & _782;
    always @(posedge _141) begin
        if (_139)
            smp_strobe <= _598;
        else
            smp_strobe <= _783;
    end
    assign _674 = _673 & _672;
    assign _159 = 8'b11111111;
    assign _3352 = _3225[7:7];
    assign _3351 = _3225[6:6];
    assign _3350 = _3225[5:5];
    assign _3349 = _3225[4:4];
    assign _3348 = _3225[3:3];
    assign _3347 = _3225[2:2];
    assign _3346 = _3225[1:1];
    assign _3345 = _3225[0:0];
    always @* begin
        case (_3339)
        0:
            _3353 <= _3345;
        1:
            _3353 <= _3346;
        2:
            _3353 <= _3347;
        3:
            _3353 <= _3348;
        4:
            _3353 <= _3349;
        5:
            _3353 <= _3350;
        6:
            _3353 <= _3351;
        default:
            _3353 <= _3352;
        endcase
    end
    assign _3344 = _3205[0:0];
    assign _3342 = { _4358,
                     _2802 };
    assign _3339 = _468 - _2798;
    assign _3340 = { gnd,
                     _3339 };
    assign _3343 = _3340 < _3342;
    assign _3354 = _3343 ? _3353 : _3344;
    assign _3335 = _3225[7:7];
    assign _3334 = _3225[6:6];
    assign _3333 = _3225[5:5];
    assign _3332 = _3225[4:4];
    assign _3331 = _3225[3:3];
    assign _3330 = _3225[2:2];
    assign _3329 = _3225[1:1];
    assign _3328 = _3225[0:0];
    always @* begin
        case (_3322)
        0:
            _3336 <= _3328;
        1:
            _3336 <= _3329;
        2:
            _3336 <= _3330;
        3:
            _3336 <= _3331;
        4:
            _3336 <= _3332;
        5:
            _3336 <= _3333;
        6:
            _3336 <= _3334;
        default:
            _3336 <= _3335;
        endcase
    end
    assign _3327 = _3205[1:1];
    assign _3325 = { _4358,
                     _2802 };
    assign _3322 = _651 - _2798;
    assign _3323 = { gnd,
                     _3322 };
    assign _3326 = _3323 < _3325;
    assign _3337 = _3326 ? _3336 : _3327;
    assign _3318 = _3225[7:7];
    assign _3317 = _3225[6:6];
    assign _3316 = _3225[5:5];
    assign _3315 = _3225[4:4];
    assign _3314 = _3225[3:3];
    assign _3313 = _3225[2:2];
    assign _3312 = _3225[1:1];
    assign _3311 = _3225[0:0];
    always @* begin
        case (_3305)
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
    assign _3310 = _3205[2:2];
    assign _3308 = { _4358,
                     _2802 };
    assign _3305 = _4223 - _2798;
    assign _3306 = { gnd,
                     _3305 };
    assign _3309 = _3306 < _3308;
    assign _3320 = _3309 ? _3319 : _3310;
    assign _3301 = _3225[7:7];
    assign _3300 = _3225[6:6];
    assign _3299 = _3225[5:5];
    assign _3298 = _3225[4:4];
    assign _3297 = _3225[3:3];
    assign _3296 = _3225[2:2];
    assign _3295 = _3225[1:1];
    assign _3294 = _3225[0:0];
    always @* begin
        case (_3288)
        0:
            _3302 <= _3294;
        1:
            _3302 <= _3295;
        2:
            _3302 <= _3296;
        3:
            _3302 <= _3297;
        4:
            _3302 <= _3298;
        5:
            _3302 <= _3299;
        6:
            _3302 <= _3300;
        default:
            _3302 <= _3301;
        endcase
    end
    assign _3293 = _3205[3:3];
    assign _3291 = { _4358,
                     _2802 };
    assign _3288 = _1056 - _2798;
    assign _3289 = { gnd,
                     _3288 };
    assign _3292 = _3289 < _3291;
    assign _3303 = _3292 ? _3302 : _3293;
    assign _3284 = _3225[7:7];
    assign _3283 = _3225[6:6];
    assign _3282 = _3225[5:5];
    assign _3281 = _3225[4:4];
    assign _3280 = _3225[3:3];
    assign _3279 = _3225[2:2];
    assign _3278 = _3225[1:1];
    assign _3277 = _3225[0:0];
    always @* begin
        case (_3271)
        0:
            _3285 <= _3277;
        1:
            _3285 <= _3278;
        2:
            _3285 <= _3279;
        3:
            _3285 <= _3280;
        4:
            _3285 <= _3281;
        5:
            _3285 <= _3282;
        6:
            _3285 <= _3283;
        default:
            _3285 <= _3284;
        endcase
    end
    assign _3276 = _3205[4:4];
    assign _3274 = { _4358,
                     _2802 };
    assign _3271 = _4367 - _2798;
    assign _3272 = { gnd,
                     _3271 };
    assign _3275 = _3272 < _3274;
    assign _3286 = _3275 ? _3285 : _3276;
    assign _3267 = _3225[7:7];
    assign _3266 = _3225[6:6];
    assign _3265 = _3225[5:5];
    assign _3264 = _3225[4:4];
    assign _3263 = _3225[3:3];
    assign _3262 = _3225[2:2];
    assign _3261 = _3225[1:1];
    assign _3260 = _3225[0:0];
    always @* begin
        case (_3254)
        0:
            _3268 <= _3260;
        1:
            _3268 <= _3261;
        2:
            _3268 <= _3262;
        3:
            _3268 <= _3263;
        4:
            _3268 <= _3264;
        5:
            _3268 <= _3265;
        6:
            _3268 <= _3266;
        default:
            _3268 <= _3267;
        endcase
    end
    assign _3259 = _3205[5:5];
    assign _3257 = { _4358,
                     _2802 };
    assign _3254 = _1689 - _2798;
    assign _3255 = { gnd,
                     _3254 };
    assign _3258 = _3255 < _3257;
    assign _3269 = _3258 ? _3268 : _3259;
    assign _3250 = _3225[7:7];
    assign _3249 = _3225[6:6];
    assign _3248 = _3225[5:5];
    assign _3247 = _3225[4:4];
    assign _3246 = _3225[3:3];
    assign _3245 = _3225[2:2];
    assign _3244 = _3225[1:1];
    assign _3243 = _3225[0:0];
    always @* begin
        case (_3237)
        0:
            _3251 <= _3243;
        1:
            _3251 <= _3244;
        2:
            _3251 <= _3245;
        3:
            _3251 <= _3246;
        4:
            _3251 <= _3247;
        5:
            _3251 <= _3248;
        6:
            _3251 <= _3249;
        default:
            _3251 <= _3250;
        endcase
    end
    assign _3242 = _3205[6:6];
    assign _3240 = { _4358,
                     _2802 };
    assign _3237 = _1042 - _2798;
    assign _3238 = { gnd,
                     _3237 };
    assign _3241 = _3238 < _3240;
    assign _3252 = _3241 ? _3251 : _3242;
    assign _3233 = _3225[7:7];
    assign _3232 = _3225[6:6];
    assign _3231 = _3225[5:5];
    assign _3230 = _3225[4:4];
    assign _3229 = _3225[3:3];
    assign _3228 = _3225[2:2];
    assign _3227 = _3225[1:1];
    assign _3220 = _3218[3:2];
    assign _3221 = { _4358,
                     _3220 };
    assign _3216 = _3214[3:1];
    assign _3217 = { _598,
                     _3216 };
    assign _3214 = _102[12:9];
    assign _3213 = _3210[0:0];
    assign _3218 = _3213 ? _3217 : _3214;
    assign _3212 = _3210[1:1];
    assign _3222 = _3212 ? _3221 : _3218;
    assign _3209 = { gnd,
                     _2802 };
    assign _3210 = _4367 - _3209;
    assign _3211 = _3210[2:2];
    assign _3224 = _3211 ? _647 : _3222;
    assign _3225 = { _647,
                     _3224 };
    assign _3226 = _3225[0:0];
    always @* begin
        case (_2799)
        0:
            _3234 <= _3226;
        1:
            _3234 <= _3227;
        2:
            _3234 <= _3228;
        3:
            _3234 <= _3229;
        4:
            _3234 <= _3230;
        5:
            _3234 <= _3231;
        6:
            _3234 <= _3232;
        default:
            _3234 <= _3233;
        endcase
    end
    assign _3201 = _1658[7:7];
    assign _3200 = _1658[6:6];
    assign _3199 = _1658[5:5];
    assign _3198 = _1658[4:4];
    assign _3197 = _1658[3:3];
    assign _3196 = _1658[2:2];
    assign _3195 = _1658[1:1];
    assign _3194 = _1658[0:0];
    always @* begin
        case (_3190)
        0:
            _3202 <= _3194;
        1:
            _3202 <= _3195;
        2:
            _3202 <= _3196;
        3:
            _3202 <= _3197;
        4:
            _3202 <= _3198;
        5:
            _3202 <= _3199;
        6:
            _3202 <= _3200;
        default:
            _3202 <= _3201;
        endcase
    end
    assign _3193 = _68[0:0];
    assign _3190 = _468 - _2953;
    assign _3191 = { _4358,
                     _3190 };
    assign _3192 = _3191 < _1473;
    assign _3203 = _3192 ? _3202 : _3193;
    assign _3185 = _1658[7:7];
    assign _3184 = _1658[6:6];
    assign _3183 = _1658[5:5];
    assign _3182 = _1658[4:4];
    assign _3181 = _1658[3:3];
    assign _3180 = _1658[2:2];
    assign _3179 = _1658[1:1];
    assign _3178 = _1658[0:0];
    always @* begin
        case (_3174)
        0:
            _3186 <= _3178;
        1:
            _3186 <= _3179;
        2:
            _3186 <= _3180;
        3:
            _3186 <= _3181;
        4:
            _3186 <= _3182;
        5:
            _3186 <= _3183;
        6:
            _3186 <= _3184;
        default:
            _3186 <= _3185;
        endcase
    end
    assign _3177 = _68[1:1];
    assign _3174 = _651 - _2953;
    assign _3175 = { _4358,
                     _3174 };
    assign _3176 = _3175 < _1473;
    assign _3187 = _3176 ? _3186 : _3177;
    assign _3169 = _1658[7:7];
    assign _3168 = _1658[6:6];
    assign _3167 = _1658[5:5];
    assign _3166 = _1658[4:4];
    assign _3165 = _1658[3:3];
    assign _3164 = _1658[2:2];
    assign _3163 = _1658[1:1];
    assign _3162 = _1658[0:0];
    always @* begin
        case (_3158)
        0:
            _3170 <= _3162;
        1:
            _3170 <= _3163;
        2:
            _3170 <= _3164;
        3:
            _3170 <= _3165;
        4:
            _3170 <= _3166;
        5:
            _3170 <= _3167;
        6:
            _3170 <= _3168;
        default:
            _3170 <= _3169;
        endcase
    end
    assign _3161 = _68[2:2];
    assign _3158 = _4223 - _2953;
    assign _3159 = { _4358,
                     _3158 };
    assign _3160 = _3159 < _1473;
    assign _3171 = _3160 ? _3170 : _3161;
    assign _3153 = _1658[7:7];
    assign _3152 = _1658[6:6];
    assign _3151 = _1658[5:5];
    assign _3150 = _1658[4:4];
    assign _3149 = _1658[3:3];
    assign _3148 = _1658[2:2];
    assign _3147 = _1658[1:1];
    assign _3146 = _1658[0:0];
    always @* begin
        case (_3142)
        0:
            _3154 <= _3146;
        1:
            _3154 <= _3147;
        2:
            _3154 <= _3148;
        3:
            _3154 <= _3149;
        4:
            _3154 <= _3150;
        5:
            _3154 <= _3151;
        6:
            _3154 <= _3152;
        default:
            _3154 <= _3153;
        endcase
    end
    assign _3145 = _68[3:3];
    assign _3142 = _1056 - _2953;
    assign _3143 = { _4358,
                     _3142 };
    assign _3144 = _3143 < _1473;
    assign _3155 = _3144 ? _3154 : _3145;
    assign _3137 = _1658[7:7];
    assign _3136 = _1658[6:6];
    assign _3135 = _1658[5:5];
    assign _3134 = _1658[4:4];
    assign _3133 = _1658[3:3];
    assign _3132 = _1658[2:2];
    assign _3131 = _1658[1:1];
    assign _3130 = _1658[0:0];
    always @* begin
        case (_3126)
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
    assign _3129 = _68[4:4];
    assign _3126 = _4367 - _2953;
    assign _3127 = { _4358,
                     _3126 };
    assign _3128 = _3127 < _1473;
    assign _3139 = _3128 ? _3138 : _3129;
    assign _3121 = _1658[7:7];
    assign _3120 = _1658[6:6];
    assign _3119 = _1658[5:5];
    assign _3118 = _1658[4:4];
    assign _3117 = _1658[3:3];
    assign _3116 = _1658[2:2];
    assign _3115 = _1658[1:1];
    assign _3114 = _1658[0:0];
    always @* begin
        case (_3110)
        0:
            _3122 <= _3114;
        1:
            _3122 <= _3115;
        2:
            _3122 <= _3116;
        3:
            _3122 <= _3117;
        4:
            _3122 <= _3118;
        5:
            _3122 <= _3119;
        6:
            _3122 <= _3120;
        default:
            _3122 <= _3121;
        endcase
    end
    assign _3113 = _68[5:5];
    assign _3110 = _1689 - _2953;
    assign _3111 = { _4358,
                     _3110 };
    assign _3112 = _3111 < _1473;
    assign _3123 = _3112 ? _3122 : _3113;
    assign _3105 = _1658[7:7];
    assign _3104 = _1658[6:6];
    assign _3103 = _1658[5:5];
    assign _3102 = _1658[4:4];
    assign _3101 = _1658[3:3];
    assign _3100 = _1658[2:2];
    assign _3099 = _1658[1:1];
    assign _3098 = _1658[0:0];
    always @* begin
        case (_3094)
        0:
            _3106 <= _3098;
        1:
            _3106 <= _3099;
        2:
            _3106 <= _3100;
        3:
            _3106 <= _3101;
        4:
            _3106 <= _3102;
        5:
            _3106 <= _3103;
        6:
            _3106 <= _3104;
        default:
            _3106 <= _3105;
        endcase
    end
    assign _3097 = _68[6:6];
    assign _3094 = _1042 - _2953;
    assign _3095 = { _4358,
                     _3094 };
    assign _3096 = _3095 < _1473;
    assign _3107 = _3096 ? _3106 : _3097;
    assign _3089 = _1658[7:7];
    assign _3088 = _1658[6:6];
    assign _3087 = _1658[5:5];
    assign _3086 = _1658[4:4];
    assign _3085 = _1658[3:3];
    assign _3084 = _1658[2:2];
    assign _3083 = _1658[1:1];
    assign _3082 = _1658[0:0];
    always @* begin
        case (_3078)
        0:
            _3090 <= _3082;
        1:
            _3090 <= _3083;
        2:
            _3090 <= _3084;
        3:
            _3090 <= _3085;
        4:
            _3090 <= _3086;
        5:
            _3090 <= _3087;
        6:
            _3090 <= _3088;
        default:
            _3090 <= _3089;
        endcase
    end
    assign _3081 = _68[7:7];
    assign _3078 = _1661 - _2953;
    assign _3079 = { _4358,
                     _3078 };
    assign _3080 = _3079 < _1473;
    assign _3091 = _3080 ? _3090 : _3081;
    assign _3204 = { _3091,
                     _3107,
                     _3123,
                     _3139,
                     _3155,
                     _3171,
                     _3187,
                     _3203 };
    assign _3071 = _1886[7:7];
    assign _3070 = _1886[6:6];
    assign _3069 = _1886[5:5];
    assign _3068 = _1886[4:4];
    assign _3067 = _1886[3:3];
    assign _3066 = _1886[2:2];
    assign _3065 = _1886[1:1];
    assign _3064 = _1886[0:0];
    always @* begin
        case (_3060)
        0:
            _3072 <= _3064;
        1:
            _3072 <= _3065;
        2:
            _3072 <= _3066;
        3:
            _3072 <= _3067;
        4:
            _3072 <= _3068;
        5:
            _3072 <= _3069;
        6:
            _3072 <= _3070;
        default:
            _3072 <= _3071;
        endcase
    end
    assign _3063 = _68[0:0];
    assign _3060 = _468 - _2953;
    assign _3061 = { gnd,
                     _3060 };
    assign _3062 = _3061 < _2956;
    assign _3073 = _3062 ? _3072 : _3063;
    assign _3056 = _1886[7:7];
    assign _3055 = _1886[6:6];
    assign _3054 = _1886[5:5];
    assign _3053 = _1886[4:4];
    assign _3052 = _1886[3:3];
    assign _3051 = _1886[2:2];
    assign _3050 = _1886[1:1];
    assign _3049 = _1886[0:0];
    always @* begin
        case (_3045)
        0:
            _3057 <= _3049;
        1:
            _3057 <= _3050;
        2:
            _3057 <= _3051;
        3:
            _3057 <= _3052;
        4:
            _3057 <= _3053;
        5:
            _3057 <= _3054;
        6:
            _3057 <= _3055;
        default:
            _3057 <= _3056;
        endcase
    end
    assign _3048 = _68[1:1];
    assign _3045 = _651 - _2953;
    assign _3046 = { gnd,
                     _3045 };
    assign _3047 = _3046 < _2956;
    assign _3058 = _3047 ? _3057 : _3048;
    assign _3041 = _1886[7:7];
    assign _3040 = _1886[6:6];
    assign _3039 = _1886[5:5];
    assign _3038 = _1886[4:4];
    assign _3037 = _1886[3:3];
    assign _3036 = _1886[2:2];
    assign _3035 = _1886[1:1];
    assign _3034 = _1886[0:0];
    always @* begin
        case (_3030)
        0:
            _3042 <= _3034;
        1:
            _3042 <= _3035;
        2:
            _3042 <= _3036;
        3:
            _3042 <= _3037;
        4:
            _3042 <= _3038;
        5:
            _3042 <= _3039;
        6:
            _3042 <= _3040;
        default:
            _3042 <= _3041;
        endcase
    end
    assign _3033 = _68[2:2];
    assign _3030 = _4223 - _2953;
    assign _3031 = { gnd,
                     _3030 };
    assign _3032 = _3031 < _2956;
    assign _3043 = _3032 ? _3042 : _3033;
    assign _3026 = _1886[7:7];
    assign _3025 = _1886[6:6];
    assign _3024 = _1886[5:5];
    assign _3023 = _1886[4:4];
    assign _3022 = _1886[3:3];
    assign _3021 = _1886[2:2];
    assign _3020 = _1886[1:1];
    assign _3019 = _1886[0:0];
    always @* begin
        case (_3015)
        0:
            _3027 <= _3019;
        1:
            _3027 <= _3020;
        2:
            _3027 <= _3021;
        3:
            _3027 <= _3022;
        4:
            _3027 <= _3023;
        5:
            _3027 <= _3024;
        6:
            _3027 <= _3025;
        default:
            _3027 <= _3026;
        endcase
    end
    assign _3018 = _68[3:3];
    assign _3015 = _1056 - _2953;
    assign _3016 = { gnd,
                     _3015 };
    assign _3017 = _3016 < _2956;
    assign _3028 = _3017 ? _3027 : _3018;
    assign _3011 = _1886[7:7];
    assign _3010 = _1886[6:6];
    assign _3009 = _1886[5:5];
    assign _3008 = _1886[4:4];
    assign _3007 = _1886[3:3];
    assign _3006 = _1886[2:2];
    assign _3005 = _1886[1:1];
    assign _3004 = _1886[0:0];
    always @* begin
        case (_3000)
        0:
            _3012 <= _3004;
        1:
            _3012 <= _3005;
        2:
            _3012 <= _3006;
        3:
            _3012 <= _3007;
        4:
            _3012 <= _3008;
        5:
            _3012 <= _3009;
        6:
            _3012 <= _3010;
        default:
            _3012 <= _3011;
        endcase
    end
    assign _3003 = _68[4:4];
    assign _3000 = _4367 - _2953;
    assign _3001 = { gnd,
                     _3000 };
    assign _3002 = _3001 < _2956;
    assign _3013 = _3002 ? _3012 : _3003;
    assign _2996 = _1886[7:7];
    assign _2995 = _1886[6:6];
    assign _2994 = _1886[5:5];
    assign _2993 = _1886[4:4];
    assign _2992 = _1886[3:3];
    assign _2991 = _1886[2:2];
    assign _2990 = _1886[1:1];
    assign _2989 = _1886[0:0];
    always @* begin
        case (_2985)
        0:
            _2997 <= _2989;
        1:
            _2997 <= _2990;
        2:
            _2997 <= _2991;
        3:
            _2997 <= _2992;
        4:
            _2997 <= _2993;
        5:
            _2997 <= _2994;
        6:
            _2997 <= _2995;
        default:
            _2997 <= _2996;
        endcase
    end
    assign _2988 = _68[5:5];
    assign _2985 = _1689 - _2953;
    assign _2986 = { gnd,
                     _2985 };
    assign _2987 = _2986 < _2956;
    assign _2998 = _2987 ? _2997 : _2988;
    assign _2981 = _1886[7:7];
    assign _2980 = _1886[6:6];
    assign _2979 = _1886[5:5];
    assign _2978 = _1886[4:4];
    assign _2977 = _1886[3:3];
    assign _2976 = _1886[2:2];
    assign _2975 = _1886[1:1];
    assign _2974 = _1886[0:0];
    always @* begin
        case (_2970)
        0:
            _2982 <= _2974;
        1:
            _2982 <= _2975;
        2:
            _2982 <= _2976;
        3:
            _2982 <= _2977;
        4:
            _2982 <= _2978;
        5:
            _2982 <= _2979;
        6:
            _2982 <= _2980;
        default:
            _2982 <= _2981;
        endcase
    end
    assign _2973 = _68[6:6];
    assign _2970 = _1042 - _2953;
    assign _2971 = { gnd,
                     _2970 };
    assign _2972 = _2971 < _2956;
    assign _2983 = _2972 ? _2982 : _2973;
    assign _2966 = _1886[7:7];
    assign _2965 = _1886[6:6];
    assign _2964 = _1886[5:5];
    assign _2963 = _1886[4:4];
    assign _2962 = _1886[3:3];
    assign _2961 = _1886[2:2];
    assign _2960 = _1886[1:1];
    assign _2959 = _1886[0:0];
    always @* begin
        case (_2954)
        0:
            _2967 <= _2959;
        1:
            _2967 <= _2960;
        2:
            _2967 <= _2961;
        3:
            _2967 <= _2962;
        4:
            _2967 <= _2963;
        5:
            _2967 <= _2964;
        6:
            _2967 <= _2965;
        default:
            _2967 <= _2966;
        endcase
    end
    assign _2958 = _68[7:7];
    assign _2956 = cfg_t1_out_cfg[7:4];
    assign _442 = 8'b00010000;
    assign _2188 = _614[7:0];
    assign _2185 = 7'b1010010;
    assign _2186 = _610 == _2185;
    assign _2184 = _604 & _608;
    assign _2187 = _2184 & _2186;
    assign _2189 = _2187 ? _2188 : cfg_t1_out_cfg;
    assign _63 = _2189;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_out_cfg <= _442;
        else
            cfg_t1_out_cfg <= _63;
    end
    assign _2953 = cfg_t1_out_cfg[2:0];
    assign _2954 = _1661 - _2953;
    assign _2955 = { gnd,
                     _2954 };
    assign _2957 = _2955 < _2956;
    assign _2968 = _2957 ? _2967 : _2958;
    assign _3074 = { _2968,
                     _2983,
                     _2998,
                     _3013,
                     _3028,
                     _3043,
                     _3058,
                     _3073 };
    assign _2947 = _2834[7:7];
    assign _2946 = _2834[6:6];
    assign _2945 = _2834[5:5];
    assign _2944 = _2834[4:4];
    assign _2943 = _2834[3:3];
    assign _2942 = _2834[2:2];
    assign _2941 = _2834[1:1];
    assign _2940 = _2834[0:0];
    always @* begin
        case (_2936)
        0:
            _2948 <= _2940;
        1:
            _2948 <= _2941;
        2:
            _2948 <= _2942;
        3:
            _2948 <= _2943;
        4:
            _2948 <= _2944;
        5:
            _2948 <= _2945;
        6:
            _2948 <= _2946;
        default:
            _2948 <= _2947;
        endcase
    end
    assign _2939 = _68[0:0];
    assign _2936 = _468 - _2826;
    assign _2937 = { gnd,
                     _2936 };
    assign _2938 = _2937 < _2829;
    assign _2949 = _2938 ? _2948 : _2939;
    assign _2932 = _2834[7:7];
    assign _2931 = _2834[6:6];
    assign _2930 = _2834[5:5];
    assign _2929 = _2834[4:4];
    assign _2928 = _2834[3:3];
    assign _2927 = _2834[2:2];
    assign _2926 = _2834[1:1];
    assign _2925 = _2834[0:0];
    always @* begin
        case (_2921)
        0:
            _2933 <= _2925;
        1:
            _2933 <= _2926;
        2:
            _2933 <= _2927;
        3:
            _2933 <= _2928;
        4:
            _2933 <= _2929;
        5:
            _2933 <= _2930;
        6:
            _2933 <= _2931;
        default:
            _2933 <= _2932;
        endcase
    end
    assign _2924 = _68[1:1];
    assign _2921 = _651 - _2826;
    assign _2922 = { gnd,
                     _2921 };
    assign _2923 = _2922 < _2829;
    assign _2934 = _2923 ? _2933 : _2924;
    assign _2917 = _2834[7:7];
    assign _2916 = _2834[6:6];
    assign _2915 = _2834[5:5];
    assign _2914 = _2834[4:4];
    assign _2913 = _2834[3:3];
    assign _2912 = _2834[2:2];
    assign _2911 = _2834[1:1];
    assign _2910 = _2834[0:0];
    always @* begin
        case (_2906)
        0:
            _2918 <= _2910;
        1:
            _2918 <= _2911;
        2:
            _2918 <= _2912;
        3:
            _2918 <= _2913;
        4:
            _2918 <= _2914;
        5:
            _2918 <= _2915;
        6:
            _2918 <= _2916;
        default:
            _2918 <= _2917;
        endcase
    end
    assign _2909 = _68[2:2];
    assign _2906 = _4223 - _2826;
    assign _2907 = { gnd,
                     _2906 };
    assign _2908 = _2907 < _2829;
    assign _2919 = _2908 ? _2918 : _2909;
    assign _2902 = _2834[7:7];
    assign _2901 = _2834[6:6];
    assign _2900 = _2834[5:5];
    assign _2899 = _2834[4:4];
    assign _2898 = _2834[3:3];
    assign _2897 = _2834[2:2];
    assign _2896 = _2834[1:1];
    assign _2895 = _2834[0:0];
    always @* begin
        case (_2891)
        0:
            _2903 <= _2895;
        1:
            _2903 <= _2896;
        2:
            _2903 <= _2897;
        3:
            _2903 <= _2898;
        4:
            _2903 <= _2899;
        5:
            _2903 <= _2900;
        6:
            _2903 <= _2901;
        default:
            _2903 <= _2902;
        endcase
    end
    assign _2894 = _68[3:3];
    assign _2891 = _1056 - _2826;
    assign _2892 = { gnd,
                     _2891 };
    assign _2893 = _2892 < _2829;
    assign _2904 = _2893 ? _2903 : _2894;
    assign _2887 = _2834[7:7];
    assign _2886 = _2834[6:6];
    assign _2885 = _2834[5:5];
    assign _2884 = _2834[4:4];
    assign _2883 = _2834[3:3];
    assign _2882 = _2834[2:2];
    assign _2881 = _2834[1:1];
    assign _2880 = _2834[0:0];
    always @* begin
        case (_2876)
        0:
            _2888 <= _2880;
        1:
            _2888 <= _2881;
        2:
            _2888 <= _2882;
        3:
            _2888 <= _2883;
        4:
            _2888 <= _2884;
        5:
            _2888 <= _2885;
        6:
            _2888 <= _2886;
        default:
            _2888 <= _2887;
        endcase
    end
    assign _2879 = _68[4:4];
    assign _2876 = _4367 - _2826;
    assign _2877 = { gnd,
                     _2876 };
    assign _2878 = _2877 < _2829;
    assign _2889 = _2878 ? _2888 : _2879;
    assign _2872 = _2834[7:7];
    assign _2871 = _2834[6:6];
    assign _2870 = _2834[5:5];
    assign _2869 = _2834[4:4];
    assign _2868 = _2834[3:3];
    assign _2867 = _2834[2:2];
    assign _2866 = _2834[1:1];
    assign _2865 = _2834[0:0];
    always @* begin
        case (_2861)
        0:
            _2873 <= _2865;
        1:
            _2873 <= _2866;
        2:
            _2873 <= _2867;
        3:
            _2873 <= _2868;
        4:
            _2873 <= _2869;
        5:
            _2873 <= _2870;
        6:
            _2873 <= _2871;
        default:
            _2873 <= _2872;
        endcase
    end
    assign _2864 = _68[5:5];
    assign _2861 = _1689 - _2826;
    assign _2862 = { gnd,
                     _2861 };
    assign _2863 = _2862 < _2829;
    assign _2874 = _2863 ? _2873 : _2864;
    assign _2857 = _2834[7:7];
    assign _2856 = _2834[6:6];
    assign _2855 = _2834[5:5];
    assign _2854 = _2834[4:4];
    assign _2853 = _2834[3:3];
    assign _2852 = _2834[2:2];
    assign _2851 = _2834[1:1];
    assign _2850 = _2834[0:0];
    always @* begin
        case (_2846)
        0:
            _2858 <= _2850;
        1:
            _2858 <= _2851;
        2:
            _2858 <= _2852;
        3:
            _2858 <= _2853;
        4:
            _2858 <= _2854;
        5:
            _2858 <= _2855;
        6:
            _2858 <= _2856;
        default:
            _2858 <= _2857;
        endcase
    end
    assign _2849 = _68[6:6];
    assign _2846 = _1042 - _2826;
    assign _2847 = { gnd,
                     _2846 };
    assign _2848 = _2847 < _2829;
    assign _2859 = _2848 ? _2858 : _2849;
    assign _2842 = _2834[7:7];
    assign _2841 = _2834[6:6];
    assign _2840 = _2834[5:5];
    assign _2839 = _2834[4:4];
    assign _2838 = _2834[3:3];
    assign _2837 = _2834[2:2];
    assign _2836 = _2834[1:1];
    assign _2835 = _2834[0:0];
    always @* begin
        case (_2827)
        0:
            _2843 <= _2835;
        1:
            _2843 <= _2836;
        2:
            _2843 <= _2837;
        3:
            _2843 <= _2838;
        4:
            _2843 <= _2839;
        5:
            _2843 <= _2840;
        6:
            _2843 <= _2841;
        default:
            _2843 <= _2842;
        endcase
    end
    assign _2831 = _68[7:7];
    assign _2829 = cfg_t1_set_cfg[7:4];
    assign _2194 = _614[7:0];
    assign _2191 = 7'b1010011;
    assign _2192 = _610 == _2191;
    assign _2190 = _604 & _608;
    assign _2193 = _2190 & _2192;
    assign _2195 = _2193 ? _2194 : cfg_t1_set_cfg;
    assign _64 = _2195;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_set_cfg <= _442;
        else
            cfg_t1_set_cfg <= _64;
    end
    assign _2826 = cfg_t1_set_cfg[2:0];
    assign _2827 = _1661 - _2826;
    assign _2828 = { gnd,
                     _2827 };
    assign _2830 = _2828 < _2829;
    assign _2844 = _2830 ? _2843 : _2831;
    assign _2950 = { _2844,
                     _2859,
                     _2874,
                     _2889,
                     _2904,
                     _2919,
                     _2934,
                     _2949 };
    assign _2784 = _2657[7:7];
    assign _2783 = _2657[6:6];
    assign _2782 = _2657[5:5];
    assign _2781 = _2657[4:4];
    assign _2780 = _2657[3:3];
    assign _2779 = _2657[2:2];
    assign _2778 = _2657[1:1];
    assign _2777 = _2657[0:0];
    always @* begin
        case (_2771)
        0:
            _2785 <= _2777;
        1:
            _2785 <= _2778;
        2:
            _2785 <= _2779;
        3:
            _2785 <= _2780;
        4:
            _2785 <= _2781;
        5:
            _2785 <= _2782;
        6:
            _2785 <= _2783;
        default:
            _2785 <= _2784;
        endcase
    end
    assign _2776 = _2637[0:0];
    assign _2774 = { _4358,
                     _2219 };
    assign _2771 = _468 - _2215;
    assign _2772 = { gnd,
                     _2771 };
    assign _2775 = _2772 < _2774;
    assign _2786 = _2775 ? _2785 : _2776;
    assign _2767 = _2657[7:7];
    assign _2766 = _2657[6:6];
    assign _2765 = _2657[5:5];
    assign _2764 = _2657[4:4];
    assign _2763 = _2657[3:3];
    assign _2762 = _2657[2:2];
    assign _2761 = _2657[1:1];
    assign _2760 = _2657[0:0];
    always @* begin
        case (_2754)
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
    assign _2759 = _2637[1:1];
    assign _2757 = { _4358,
                     _2219 };
    assign _2754 = _651 - _2215;
    assign _2755 = { gnd,
                     _2754 };
    assign _2758 = _2755 < _2757;
    assign _2769 = _2758 ? _2768 : _2759;
    assign _2750 = _2657[7:7];
    assign _2749 = _2657[6:6];
    assign _2748 = _2657[5:5];
    assign _2747 = _2657[4:4];
    assign _2746 = _2657[3:3];
    assign _2745 = _2657[2:2];
    assign _2744 = _2657[1:1];
    assign _2743 = _2657[0:0];
    always @* begin
        case (_2737)
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
    assign _2742 = _2637[2:2];
    assign _2740 = { _4358,
                     _2219 };
    assign _2737 = _4223 - _2215;
    assign _2738 = { gnd,
                     _2737 };
    assign _2741 = _2738 < _2740;
    assign _2752 = _2741 ? _2751 : _2742;
    assign _2733 = _2657[7:7];
    assign _2732 = _2657[6:6];
    assign _2731 = _2657[5:5];
    assign _2730 = _2657[4:4];
    assign _2729 = _2657[3:3];
    assign _2728 = _2657[2:2];
    assign _2727 = _2657[1:1];
    assign _2726 = _2657[0:0];
    always @* begin
        case (_2720)
        0:
            _2734 <= _2726;
        1:
            _2734 <= _2727;
        2:
            _2734 <= _2728;
        3:
            _2734 <= _2729;
        4:
            _2734 <= _2730;
        5:
            _2734 <= _2731;
        6:
            _2734 <= _2732;
        default:
            _2734 <= _2733;
        endcase
    end
    assign _2725 = _2637[3:3];
    assign _2723 = { _4358,
                     _2219 };
    assign _2720 = _1056 - _2215;
    assign _2721 = { gnd,
                     _2720 };
    assign _2724 = _2721 < _2723;
    assign _2735 = _2724 ? _2734 : _2725;
    assign _2716 = _2657[7:7];
    assign _2715 = _2657[6:6];
    assign _2714 = _2657[5:5];
    assign _2713 = _2657[4:4];
    assign _2712 = _2657[3:3];
    assign _2711 = _2657[2:2];
    assign _2710 = _2657[1:1];
    assign _2709 = _2657[0:0];
    always @* begin
        case (_2703)
        0:
            _2717 <= _2709;
        1:
            _2717 <= _2710;
        2:
            _2717 <= _2711;
        3:
            _2717 <= _2712;
        4:
            _2717 <= _2713;
        5:
            _2717 <= _2714;
        6:
            _2717 <= _2715;
        default:
            _2717 <= _2716;
        endcase
    end
    assign _2708 = _2637[4:4];
    assign _2706 = { _4358,
                     _2219 };
    assign _2703 = _4367 - _2215;
    assign _2704 = { gnd,
                     _2703 };
    assign _2707 = _2704 < _2706;
    assign _2718 = _2707 ? _2717 : _2708;
    assign _2699 = _2657[7:7];
    assign _2698 = _2657[6:6];
    assign _2697 = _2657[5:5];
    assign _2696 = _2657[4:4];
    assign _2695 = _2657[3:3];
    assign _2694 = _2657[2:2];
    assign _2693 = _2657[1:1];
    assign _2692 = _2657[0:0];
    always @* begin
        case (_2686)
        0:
            _2700 <= _2692;
        1:
            _2700 <= _2693;
        2:
            _2700 <= _2694;
        3:
            _2700 <= _2695;
        4:
            _2700 <= _2696;
        5:
            _2700 <= _2697;
        6:
            _2700 <= _2698;
        default:
            _2700 <= _2699;
        endcase
    end
    assign _2691 = _2637[5:5];
    assign _2689 = { _4358,
                     _2219 };
    assign _2686 = _1689 - _2215;
    assign _2687 = { gnd,
                     _2686 };
    assign _2690 = _2687 < _2689;
    assign _2701 = _2690 ? _2700 : _2691;
    assign _2682 = _2657[7:7];
    assign _2681 = _2657[6:6];
    assign _2680 = _2657[5:5];
    assign _2679 = _2657[4:4];
    assign _2678 = _2657[3:3];
    assign _2677 = _2657[2:2];
    assign _2676 = _2657[1:1];
    assign _2675 = _2657[0:0];
    always @* begin
        case (_2669)
        0:
            _2683 <= _2675;
        1:
            _2683 <= _2676;
        2:
            _2683 <= _2677;
        3:
            _2683 <= _2678;
        4:
            _2683 <= _2679;
        5:
            _2683 <= _2680;
        6:
            _2683 <= _2681;
        default:
            _2683 <= _2682;
        endcase
    end
    assign _2674 = _2637[6:6];
    assign _2672 = { _4358,
                     _2219 };
    assign _2669 = _1042 - _2215;
    assign _2670 = { gnd,
                     _2669 };
    assign _2673 = _2670 < _2672;
    assign _2684 = _2673 ? _2683 : _2674;
    assign _2665 = _2657[7:7];
    assign _2664 = _2657[6:6];
    assign _2663 = _2657[5:5];
    assign _2662 = _2657[4:4];
    assign _2661 = _2657[3:3];
    assign _2660 = _2657[2:2];
    assign _2659 = _2657[1:1];
    assign _2652 = _2650[3:2];
    assign _2653 = { _4358,
                     _2652 };
    assign _2648 = _2646[3:1];
    assign _2649 = { _598,
                     _2648 };
    assign _2646 = _127[12:9];
    assign _2645 = _2642[0:0];
    assign _2650 = _2645 ? _2649 : _2646;
    assign _2644 = _2642[1:1];
    assign _2654 = _2644 ? _2653 : _2650;
    assign _2641 = { gnd,
                     _2219 };
    assign _2642 = _4367 - _2641;
    assign _2643 = _2642[2:2];
    assign _2656 = _2643 ? _647 : _2654;
    assign _2657 = { _647,
                     _2656 };
    assign _2658 = _2657[0:0];
    always @* begin
        case (_2216)
        0:
            _2666 <= _2658;
        1:
            _2666 <= _2659;
        2:
            _2666 <= _2660;
        3:
            _2666 <= _2661;
        4:
            _2666 <= _2662;
        5:
            _2666 <= _2663;
        6:
            _2666 <= _2664;
        default:
            _2666 <= _2665;
        endcase
    end
    assign _2633 = _1133[7:7];
    assign _2632 = _1133[6:6];
    assign _2631 = _1133[5:5];
    assign _2630 = _1133[4:4];
    assign _2629 = _1133[3:3];
    assign _2628 = _1133[2:2];
    assign _2627 = _1133[1:1];
    assign _2626 = _1133[0:0];
    always @* begin
        case (_2622)
        0:
            _2634 <= _2626;
        1:
            _2634 <= _2627;
        2:
            _2634 <= _2628;
        3:
            _2634 <= _2629;
        4:
            _2634 <= _2630;
        5:
            _2634 <= _2631;
        6:
            _2634 <= _2632;
        default:
            _2634 <= _2633;
        endcase
    end
    assign _2625 = pin_out[0:0];
    assign _2622 = _468 - _2370;
    assign _2623 = { _4358,
                     _2622 };
    assign _2624 = _2623 < _948;
    assign _2635 = _2624 ? _2634 : _2625;
    assign _2617 = _1133[7:7];
    assign _2616 = _1133[6:6];
    assign _2615 = _1133[5:5];
    assign _2614 = _1133[4:4];
    assign _2613 = _1133[3:3];
    assign _2612 = _1133[2:2];
    assign _2611 = _1133[1:1];
    assign _2610 = _1133[0:0];
    always @* begin
        case (_2606)
        0:
            _2618 <= _2610;
        1:
            _2618 <= _2611;
        2:
            _2618 <= _2612;
        3:
            _2618 <= _2613;
        4:
            _2618 <= _2614;
        5:
            _2618 <= _2615;
        6:
            _2618 <= _2616;
        default:
            _2618 <= _2617;
        endcase
    end
    assign _2609 = pin_out[1:1];
    assign _2606 = _651 - _2370;
    assign _2607 = { _4358,
                     _2606 };
    assign _2608 = _2607 < _948;
    assign _2619 = _2608 ? _2618 : _2609;
    assign _2601 = _1133[7:7];
    assign _2600 = _1133[6:6];
    assign _2599 = _1133[5:5];
    assign _2598 = _1133[4:4];
    assign _2597 = _1133[3:3];
    assign _2596 = _1133[2:2];
    assign _2595 = _1133[1:1];
    assign _2594 = _1133[0:0];
    always @* begin
        case (_2590)
        0:
            _2602 <= _2594;
        1:
            _2602 <= _2595;
        2:
            _2602 <= _2596;
        3:
            _2602 <= _2597;
        4:
            _2602 <= _2598;
        5:
            _2602 <= _2599;
        6:
            _2602 <= _2600;
        default:
            _2602 <= _2601;
        endcase
    end
    assign _2593 = pin_out[2:2];
    assign _2590 = _4223 - _2370;
    assign _2591 = { _4358,
                     _2590 };
    assign _2592 = _2591 < _948;
    assign _2603 = _2592 ? _2602 : _2593;
    assign _2585 = _1133[7:7];
    assign _2584 = _1133[6:6];
    assign _2583 = _1133[5:5];
    assign _2582 = _1133[4:4];
    assign _2581 = _1133[3:3];
    assign _2580 = _1133[2:2];
    assign _2579 = _1133[1:1];
    assign _2578 = _1133[0:0];
    always @* begin
        case (_2574)
        0:
            _2586 <= _2578;
        1:
            _2586 <= _2579;
        2:
            _2586 <= _2580;
        3:
            _2586 <= _2581;
        4:
            _2586 <= _2582;
        5:
            _2586 <= _2583;
        6:
            _2586 <= _2584;
        default:
            _2586 <= _2585;
        endcase
    end
    assign _2577 = pin_out[3:3];
    assign _2574 = _1056 - _2370;
    assign _2575 = { _4358,
                     _2574 };
    assign _2576 = _2575 < _948;
    assign _2587 = _2576 ? _2586 : _2577;
    assign _2569 = _1133[7:7];
    assign _2568 = _1133[6:6];
    assign _2567 = _1133[5:5];
    assign _2566 = _1133[4:4];
    assign _2565 = _1133[3:3];
    assign _2564 = _1133[2:2];
    assign _2563 = _1133[1:1];
    assign _2562 = _1133[0:0];
    always @* begin
        case (_2558)
        0:
            _2570 <= _2562;
        1:
            _2570 <= _2563;
        2:
            _2570 <= _2564;
        3:
            _2570 <= _2565;
        4:
            _2570 <= _2566;
        5:
            _2570 <= _2567;
        6:
            _2570 <= _2568;
        default:
            _2570 <= _2569;
        endcase
    end
    assign _2561 = pin_out[4:4];
    assign _2558 = _4367 - _2370;
    assign _2559 = { _4358,
                     _2558 };
    assign _2560 = _2559 < _948;
    assign _2571 = _2560 ? _2570 : _2561;
    assign _2553 = _1133[7:7];
    assign _2552 = _1133[6:6];
    assign _2551 = _1133[5:5];
    assign _2550 = _1133[4:4];
    assign _2549 = _1133[3:3];
    assign _2548 = _1133[2:2];
    assign _2547 = _1133[1:1];
    assign _2546 = _1133[0:0];
    always @* begin
        case (_2542)
        0:
            _2554 <= _2546;
        1:
            _2554 <= _2547;
        2:
            _2554 <= _2548;
        3:
            _2554 <= _2549;
        4:
            _2554 <= _2550;
        5:
            _2554 <= _2551;
        6:
            _2554 <= _2552;
        default:
            _2554 <= _2553;
        endcase
    end
    assign _2545 = pin_out[5:5];
    assign _2542 = _1689 - _2370;
    assign _2543 = { _4358,
                     _2542 };
    assign _2544 = _2543 < _948;
    assign _2555 = _2544 ? _2554 : _2545;
    assign _2537 = _1133[7:7];
    assign _2536 = _1133[6:6];
    assign _2535 = _1133[5:5];
    assign _2534 = _1133[4:4];
    assign _2533 = _1133[3:3];
    assign _2532 = _1133[2:2];
    assign _2531 = _1133[1:1];
    assign _2530 = _1133[0:0];
    always @* begin
        case (_2526)
        0:
            _2538 <= _2530;
        1:
            _2538 <= _2531;
        2:
            _2538 <= _2532;
        3:
            _2538 <= _2533;
        4:
            _2538 <= _2534;
        5:
            _2538 <= _2535;
        6:
            _2538 <= _2536;
        default:
            _2538 <= _2537;
        endcase
    end
    assign _2529 = pin_out[6:6];
    assign _2526 = _1042 - _2370;
    assign _2527 = { _4358,
                     _2526 };
    assign _2528 = _2527 < _948;
    assign _2539 = _2528 ? _2538 : _2529;
    assign _2521 = _1133[7:7];
    assign _2520 = _1133[6:6];
    assign _2519 = _1133[5:5];
    assign _2518 = _1133[4:4];
    assign _2517 = _1133[3:3];
    assign _2516 = _1133[2:2];
    assign _2515 = _1133[1:1];
    assign _2514 = _1133[0:0];
    always @* begin
        case (_2510)
        0:
            _2522 <= _2514;
        1:
            _2522 <= _2515;
        2:
            _2522 <= _2516;
        3:
            _2522 <= _2517;
        4:
            _2522 <= _2518;
        5:
            _2522 <= _2519;
        6:
            _2522 <= _2520;
        default:
            _2522 <= _2521;
        endcase
    end
    assign _2513 = pin_out[7:7];
    assign _2510 = _1661 - _2370;
    assign _2511 = { _4358,
                     _2510 };
    assign _2512 = _2511 < _948;
    assign _2523 = _2512 ? _2522 : _2513;
    assign _2636 = { _2523,
                     _2539,
                     _2555,
                     _2571,
                     _2587,
                     _2603,
                     _2619,
                     _2635 };
    assign _2503 = _2390[7:7];
    assign _2502 = _2390[6:6];
    assign _2501 = _2390[5:5];
    assign _2500 = _2390[4:4];
    assign _2499 = _2390[3:3];
    assign _2498 = _2390[2:2];
    assign _2497 = _2390[1:1];
    assign _2496 = _2390[0:0];
    always @* begin
        case (_2492)
        0:
            _2504 <= _2496;
        1:
            _2504 <= _2497;
        2:
            _2504 <= _2498;
        3:
            _2504 <= _2499;
        4:
            _2504 <= _2500;
        5:
            _2504 <= _2501;
        6:
            _2504 <= _2502;
        default:
            _2504 <= _2503;
        endcase
    end
    assign _2495 = pin_out[0:0];
    assign _2492 = _468 - _2370;
    assign _2493 = { gnd,
                     _2492 };
    assign _2494 = _2493 < _2373;
    assign _2505 = _2494 ? _2504 : _2495;
    assign _2488 = _2390[7:7];
    assign _2487 = _2390[6:6];
    assign _2486 = _2390[5:5];
    assign _2485 = _2390[4:4];
    assign _2484 = _2390[3:3];
    assign _2483 = _2390[2:2];
    assign _2482 = _2390[1:1];
    assign _2481 = _2390[0:0];
    always @* begin
        case (_2477)
        0:
            _2489 <= _2481;
        1:
            _2489 <= _2482;
        2:
            _2489 <= _2483;
        3:
            _2489 <= _2484;
        4:
            _2489 <= _2485;
        5:
            _2489 <= _2486;
        6:
            _2489 <= _2487;
        default:
            _2489 <= _2488;
        endcase
    end
    assign _2480 = pin_out[1:1];
    assign _2477 = _651 - _2370;
    assign _2478 = { gnd,
                     _2477 };
    assign _2479 = _2478 < _2373;
    assign _2490 = _2479 ? _2489 : _2480;
    assign _2473 = _2390[7:7];
    assign _2472 = _2390[6:6];
    assign _2471 = _2390[5:5];
    assign _2470 = _2390[4:4];
    assign _2469 = _2390[3:3];
    assign _2468 = _2390[2:2];
    assign _2467 = _2390[1:1];
    assign _2466 = _2390[0:0];
    always @* begin
        case (_2462)
        0:
            _2474 <= _2466;
        1:
            _2474 <= _2467;
        2:
            _2474 <= _2468;
        3:
            _2474 <= _2469;
        4:
            _2474 <= _2470;
        5:
            _2474 <= _2471;
        6:
            _2474 <= _2472;
        default:
            _2474 <= _2473;
        endcase
    end
    assign _2465 = pin_out[2:2];
    assign _2462 = _4223 - _2370;
    assign _2463 = { gnd,
                     _2462 };
    assign _2464 = _2463 < _2373;
    assign _2475 = _2464 ? _2474 : _2465;
    assign _2458 = _2390[7:7];
    assign _2457 = _2390[6:6];
    assign _2456 = _2390[5:5];
    assign _2455 = _2390[4:4];
    assign _2454 = _2390[3:3];
    assign _2453 = _2390[2:2];
    assign _2452 = _2390[1:1];
    assign _2451 = _2390[0:0];
    always @* begin
        case (_2447)
        0:
            _2459 <= _2451;
        1:
            _2459 <= _2452;
        2:
            _2459 <= _2453;
        3:
            _2459 <= _2454;
        4:
            _2459 <= _2455;
        5:
            _2459 <= _2456;
        6:
            _2459 <= _2457;
        default:
            _2459 <= _2458;
        endcase
    end
    assign _2450 = pin_out[3:3];
    assign _2447 = _1056 - _2370;
    assign _2448 = { gnd,
                     _2447 };
    assign _2449 = _2448 < _2373;
    assign _2460 = _2449 ? _2459 : _2450;
    assign _2443 = _2390[7:7];
    assign _2442 = _2390[6:6];
    assign _2441 = _2390[5:5];
    assign _2440 = _2390[4:4];
    assign _2439 = _2390[3:3];
    assign _2438 = _2390[2:2];
    assign _2437 = _2390[1:1];
    assign _2436 = _2390[0:0];
    always @* begin
        case (_2432)
        0:
            _2444 <= _2436;
        1:
            _2444 <= _2437;
        2:
            _2444 <= _2438;
        3:
            _2444 <= _2439;
        4:
            _2444 <= _2440;
        5:
            _2444 <= _2441;
        6:
            _2444 <= _2442;
        default:
            _2444 <= _2443;
        endcase
    end
    assign _2435 = pin_out[4:4];
    assign _2432 = _4367 - _2370;
    assign _2433 = { gnd,
                     _2432 };
    assign _2434 = _2433 < _2373;
    assign _2445 = _2434 ? _2444 : _2435;
    assign _2428 = _2390[7:7];
    assign _2427 = _2390[6:6];
    assign _2426 = _2390[5:5];
    assign _2425 = _2390[4:4];
    assign _2424 = _2390[3:3];
    assign _2423 = _2390[2:2];
    assign _2422 = _2390[1:1];
    assign _2421 = _2390[0:0];
    always @* begin
        case (_2417)
        0:
            _2429 <= _2421;
        1:
            _2429 <= _2422;
        2:
            _2429 <= _2423;
        3:
            _2429 <= _2424;
        4:
            _2429 <= _2425;
        5:
            _2429 <= _2426;
        6:
            _2429 <= _2427;
        default:
            _2429 <= _2428;
        endcase
    end
    assign _2420 = pin_out[5:5];
    assign _2417 = _1689 - _2370;
    assign _2418 = { gnd,
                     _2417 };
    assign _2419 = _2418 < _2373;
    assign _2430 = _2419 ? _2429 : _2420;
    assign _2413 = _2390[7:7];
    assign _2412 = _2390[6:6];
    assign _2411 = _2390[5:5];
    assign _2410 = _2390[4:4];
    assign _2409 = _2390[3:3];
    assign _2408 = _2390[2:2];
    assign _2407 = _2390[1:1];
    assign _2406 = _2390[0:0];
    always @* begin
        case (_2402)
        0:
            _2414 <= _2406;
        1:
            _2414 <= _2407;
        2:
            _2414 <= _2408;
        3:
            _2414 <= _2409;
        4:
            _2414 <= _2410;
        5:
            _2414 <= _2411;
        6:
            _2414 <= _2412;
        default:
            _2414 <= _2413;
        endcase
    end
    assign _2405 = pin_out[6:6];
    assign _2402 = _1042 - _2370;
    assign _2403 = { gnd,
                     _2402 };
    assign _2404 = _2403 < _2373;
    assign _2415 = _2404 ? _2414 : _2405;
    assign _2398 = _2390[7:7];
    assign _2397 = _2390[6:6];
    assign _2396 = _2390[5:5];
    assign _2395 = _2390[4:4];
    assign _2394 = _2390[3:3];
    assign _2393 = _2390[2:2];
    assign _2392 = _2390[1:1];
    assign _2391 = _2390[0:0];
    always @* begin
        case (_2371)
        0:
            _2399 <= _2391;
        1:
            _2399 <= _2392;
        2:
            _2399 <= _2393;
        3:
            _2399 <= _2394;
        4:
            _2399 <= _2395;
        5:
            _2399 <= _2396;
        6:
            _2399 <= _2397;
        default:
            _2399 <= _2398;
        endcase
    end
    assign _2375 = pin_out[7:7];
    assign _2373 = cfg_t0_out_cfg[7:4];
    assign _2200 = _614[7:0];
    assign _2197 = 7'b1000010;
    assign _2198 = _610 == _2197;
    assign _2196 = _604 & _608;
    assign _2199 = _2196 & _2198;
    assign _2201 = _2199 ? _2200 : cfg_t0_out_cfg;
    assign _65 = _2201;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_out_cfg <= _442;
        else
            cfg_t0_out_cfg <= _65;
    end
    assign _2370 = cfg_t0_out_cfg[2:0];
    assign _2371 = _1661 - _2370;
    assign _2372 = { gnd,
                     _2371 };
    assign _2374 = _2372 < _2373;
    assign _2400 = _2374 ? _2399 : _2375;
    assign _2506 = { _2400,
                     _2415,
                     _2430,
                     _2445,
                     _2460,
                     _2475,
                     _2490,
                     _2505 };
    assign _2364 = _2251[7:7];
    assign _2363 = _2251[6:6];
    assign _2362 = _2251[5:5];
    assign _2361 = _2251[4:4];
    assign _2360 = _2251[3:3];
    assign _2359 = _2251[2:2];
    assign _2358 = _2251[1:1];
    assign _2357 = _2251[0:0];
    always @* begin
        case (_2353)
        0:
            _2365 <= _2357;
        1:
            _2365 <= _2358;
        2:
            _2365 <= _2359;
        3:
            _2365 <= _2360;
        4:
            _2365 <= _2361;
        5:
            _2365 <= _2362;
        6:
            _2365 <= _2363;
        default:
            _2365 <= _2364;
        endcase
    end
    assign _2356 = pin_out[0:0];
    assign _2353 = _468 - _2243;
    assign _2354 = { gnd,
                     _2353 };
    assign _2355 = _2354 < _2246;
    assign _2366 = _2355 ? _2365 : _2356;
    assign _2349 = _2251[7:7];
    assign _2348 = _2251[6:6];
    assign _2347 = _2251[5:5];
    assign _2346 = _2251[4:4];
    assign _2345 = _2251[3:3];
    assign _2344 = _2251[2:2];
    assign _2343 = _2251[1:1];
    assign _2342 = _2251[0:0];
    always @* begin
        case (_2338)
        0:
            _2350 <= _2342;
        1:
            _2350 <= _2343;
        2:
            _2350 <= _2344;
        3:
            _2350 <= _2345;
        4:
            _2350 <= _2346;
        5:
            _2350 <= _2347;
        6:
            _2350 <= _2348;
        default:
            _2350 <= _2349;
        endcase
    end
    assign _2341 = pin_out[1:1];
    assign _2338 = _651 - _2243;
    assign _2339 = { gnd,
                     _2338 };
    assign _2340 = _2339 < _2246;
    assign _2351 = _2340 ? _2350 : _2341;
    assign _2334 = _2251[7:7];
    assign _2333 = _2251[6:6];
    assign _2332 = _2251[5:5];
    assign _2331 = _2251[4:4];
    assign _2330 = _2251[3:3];
    assign _2329 = _2251[2:2];
    assign _2328 = _2251[1:1];
    assign _2327 = _2251[0:0];
    always @* begin
        case (_2323)
        0:
            _2335 <= _2327;
        1:
            _2335 <= _2328;
        2:
            _2335 <= _2329;
        3:
            _2335 <= _2330;
        4:
            _2335 <= _2331;
        5:
            _2335 <= _2332;
        6:
            _2335 <= _2333;
        default:
            _2335 <= _2334;
        endcase
    end
    assign _2326 = pin_out[2:2];
    assign _2323 = _4223 - _2243;
    assign _2324 = { gnd,
                     _2323 };
    assign _2325 = _2324 < _2246;
    assign _2336 = _2325 ? _2335 : _2326;
    assign _2319 = _2251[7:7];
    assign _2318 = _2251[6:6];
    assign _2317 = _2251[5:5];
    assign _2316 = _2251[4:4];
    assign _2315 = _2251[3:3];
    assign _2314 = _2251[2:2];
    assign _2313 = _2251[1:1];
    assign _2312 = _2251[0:0];
    always @* begin
        case (_2308)
        0:
            _2320 <= _2312;
        1:
            _2320 <= _2313;
        2:
            _2320 <= _2314;
        3:
            _2320 <= _2315;
        4:
            _2320 <= _2316;
        5:
            _2320 <= _2317;
        6:
            _2320 <= _2318;
        default:
            _2320 <= _2319;
        endcase
    end
    assign _2311 = pin_out[3:3];
    assign _2308 = _1056 - _2243;
    assign _2309 = { gnd,
                     _2308 };
    assign _2310 = _2309 < _2246;
    assign _2321 = _2310 ? _2320 : _2311;
    assign _2304 = _2251[7:7];
    assign _2303 = _2251[6:6];
    assign _2302 = _2251[5:5];
    assign _2301 = _2251[4:4];
    assign _2300 = _2251[3:3];
    assign _2299 = _2251[2:2];
    assign _2298 = _2251[1:1];
    assign _2297 = _2251[0:0];
    always @* begin
        case (_2293)
        0:
            _2305 <= _2297;
        1:
            _2305 <= _2298;
        2:
            _2305 <= _2299;
        3:
            _2305 <= _2300;
        4:
            _2305 <= _2301;
        5:
            _2305 <= _2302;
        6:
            _2305 <= _2303;
        default:
            _2305 <= _2304;
        endcase
    end
    assign _2296 = pin_out[4:4];
    assign _2293 = _4367 - _2243;
    assign _2294 = { gnd,
                     _2293 };
    assign _2295 = _2294 < _2246;
    assign _2306 = _2295 ? _2305 : _2296;
    assign _2289 = _2251[7:7];
    assign _2288 = _2251[6:6];
    assign _2287 = _2251[5:5];
    assign _2286 = _2251[4:4];
    assign _2285 = _2251[3:3];
    assign _2284 = _2251[2:2];
    assign _2283 = _2251[1:1];
    assign _2282 = _2251[0:0];
    always @* begin
        case (_2278)
        0:
            _2290 <= _2282;
        1:
            _2290 <= _2283;
        2:
            _2290 <= _2284;
        3:
            _2290 <= _2285;
        4:
            _2290 <= _2286;
        5:
            _2290 <= _2287;
        6:
            _2290 <= _2288;
        default:
            _2290 <= _2289;
        endcase
    end
    assign _2281 = pin_out[5:5];
    assign _2278 = _1689 - _2243;
    assign _2279 = { gnd,
                     _2278 };
    assign _2280 = _2279 < _2246;
    assign _2291 = _2280 ? _2290 : _2281;
    assign _2274 = _2251[7:7];
    assign _2273 = _2251[6:6];
    assign _2272 = _2251[5:5];
    assign _2271 = _2251[4:4];
    assign _2270 = _2251[3:3];
    assign _2269 = _2251[2:2];
    assign _2268 = _2251[1:1];
    assign _2267 = _2251[0:0];
    always @* begin
        case (_2263)
        0:
            _2275 <= _2267;
        1:
            _2275 <= _2268;
        2:
            _2275 <= _2269;
        3:
            _2275 <= _2270;
        4:
            _2275 <= _2271;
        5:
            _2275 <= _2272;
        6:
            _2275 <= _2273;
        default:
            _2275 <= _2274;
        endcase
    end
    assign _2266 = pin_out[6:6];
    assign _2263 = _1042 - _2243;
    assign _2264 = { gnd,
                     _2263 };
    assign _2265 = _2264 < _2246;
    assign _2276 = _2265 ? _2275 : _2266;
    assign _2259 = _2251[7:7];
    assign _2258 = _2251[6:6];
    assign _2257 = _2251[5:5];
    assign _2256 = _2251[4:4];
    assign _2255 = _2251[3:3];
    assign _2254 = _2251[2:2];
    assign _2253 = _2251[1:1];
    assign _2252 = _2251[0:0];
    always @* begin
        case (_2244)
        0:
            _2260 <= _2252;
        1:
            _2260 <= _2253;
        2:
            _2260 <= _2254;
        3:
            _2260 <= _2255;
        4:
            _2260 <= _2256;
        5:
            _2260 <= _2257;
        6:
            _2260 <= _2258;
        default:
            _2260 <= _2259;
        endcase
    end
    assign _2248 = pin_out[7:7];
    assign _2246 = cfg_t0_set_cfg[7:4];
    assign _2206 = _614[7:0];
    assign _2203 = 7'b1000011;
    assign _2204 = _610 == _2203;
    assign _2202 = _604 & _608;
    assign _2205 = _2202 & _2204;
    assign _2207 = _2205 ? _2206 : cfg_t0_set_cfg;
    assign _66 = _2207;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_set_cfg <= _442;
        else
            cfg_t0_set_cfg <= _66;
    end
    assign _2243 = cfg_t0_set_cfg[2:0];
    assign _2244 = _1661 - _2243;
    assign _2245 = { gnd,
                     _2244 };
    assign _2247 = _2245 < _2246;
    assign _2261 = _2247 ? _2260 : _2248;
    assign _2367 = { _2261,
                     _2276,
                     _2291,
                     _2306,
                     _2321,
                     _2336,
                     _2351,
                     _2366 };
    assign _2240 = _964 == _4358;
    assign _2237 = _650 == _1042;
    assign _2238 = _958 & _2237;
    assign _2241 = _2238 & _2240;
    assign _2368 = _2241 ? _2367 : pin_out;
    assign _2233 = _1033 == _4223;
    assign _2234 = _1039 & _2233;
    assign _2230 = _650 == _1689;
    assign _2231 = _958 & _2230;
    assign _2235 = _2231 & _2234;
    assign _2507 = _2235 ? _2506 : _2368;
    assign _2225 = _127[8:7];
    assign _2227 = _2225 == _4358;
    assign _2223 = _650 == _1056;
    assign _2224 = _958 & _2223;
    assign _2228 = _2224 & _2227;
    assign _2637 = _2228 ? _2636 : _2507;
    assign _2638 = _2637[7:7];
    assign _2219 = cfg_t0_sideset[5:4];
    assign _2220 = { _4358,
                     _2219 };
    assign _2212 = _614[5:0];
    assign _2209 = 7'b1001100;
    assign _2210 = _610 == _2209;
    assign _2208 = _604 & _608;
    assign _2211 = _2208 & _2210;
    assign _2213 = _2211 ? _2212 : cfg_t0_sideset;
    assign _67 = _2213;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_sideset <= _554;
        else
            cfg_t0_sideset <= _67;
    end
    assign _2215 = cfg_t0_sideset[2:0];
    assign _2216 = _1661 - _2215;
    assign _2217 = { gnd,
                     _2216 };
    assign _2221 = _2217 < _2220;
    assign _2667 = _2221 ? _2666 : _2638;
    assign _2787 = { _2667,
                     _2684,
                     _2701,
                     _2718,
                     _2735,
                     _2752,
                     _2769,
                     _2786 };
    assign _2788 = _645 ? pin_out : _2787;
    assign _2789 = _639 ? pin_out : _2788;
    assign _2790 = _633 ? pin_out : _2789;
    assign _68 = _2790;
    assign _2823 = _1489 == _4358;
    assign _2820 = _1405 == _1042;
    assign _2821 = _1483 & _2820;
    assign _2824 = _2821 & _2823;
    assign _2951 = _2824 ? _2950 : _68;
    assign _2816 = _1558 == _4223;
    assign _2817 = _1564 & _2816;
    assign _2813 = _1405 == _1689;
    assign _2814 = _1483 & _2813;
    assign _2818 = _2814 & _2817;
    assign _3075 = _2818 ? _3074 : _2951;
    assign _2808 = _102[8:7];
    assign _2810 = _2808 == _4358;
    assign _2806 = _1405 == _1056;
    assign _2807 = _1483 & _2806;
    assign _2811 = _2807 & _2810;
    assign _3205 = _2811 ? _3204 : _3075;
    assign _3206 = _3205[7:7];
    assign _2802 = cfg_t1_sideset[5:4];
    assign _2803 = { _4358,
                     _2802 };
    assign _2795 = _614[5:0];
    assign _2792 = 7'b1011100;
    assign _2793 = _610 == _2792;
    assign _2791 = _604 & _608;
    assign _2794 = _2791 & _2793;
    assign _2796 = _2794 ? _2795 : cfg_t1_sideset;
    assign _69 = _2796;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_sideset <= _554;
        else
            cfg_t1_sideset <= _69;
    end
    assign _2798 = cfg_t1_sideset[2:0];
    assign _2799 = _1661 - _2798;
    assign _2800 = { gnd,
                     _2799 };
    assign _2804 = _2800 < _2803;
    assign _3235 = _2804 ? _3234 : _3206;
    assign _3355 = { _3235,
                     _3252,
                     _3269,
                     _3286,
                     _3303,
                     _3320,
                     _3337,
                     _3354 };
    assign _3356 = _1400 ? _68 : _3355;
    assign _3357 = _1394 ? _68 : _3356;
    assign _3358 = _1388 ? _68 : _3357;
    assign _70 = _3358;
    assign _71 = _70;
    always @(posedge _141) begin
        if (_139)
            pin_out <= _159;
        else
            pin_out <= _71;
    end
    assign _673 = pin_out[7:7];
    assign _669 = ~ cfg_sync_bypass;
    always @(posedge _141) begin
        if (_139)
            pins_sync1 <= _159;
        else
            pins_sync1 <= _74;
    end
    always @(posedge _141) begin
        if (_139)
            pins_sync2 <= _159;
        else
            pins_sync2 <= pins_sync1;
    end
    assign _670 = pins_sync2 & _669;
    assign _3363 = _614[7:0];
    assign _3360 = 7'b1001110;
    assign _3361 = _610 == _3360;
    assign _3359 = _604 & _608;
    assign _3362 = _3359 & _3361;
    assign _3364 = _3362 ? _3363 : cfg_sync_bypass;
    assign _72 = _3364;
    always @(posedge _141) begin
        if (_139)
            cfg_sync_bypass <= _568;
        else
            cfg_sync_bypass <= _72;
    end
    assign _74 = uio_in;
    assign _663 = _74 & cfg_sync_bypass;
    assign _671 = _663 | _670;
    assign _672 = _671[7:7];
    assign _3366 = 7'b1000111;
    assign _3367 = _610 == _3366;
    assign _3365 = _604 & _608;
    assign _3368 = _3365 & _3367;
    assign _3369 = _3368 ? _614 : cfg_pin_modes;
    assign _75 = _3369;
    always @(posedge _141) begin
        if (_139)
            cfg_pin_modes <= _307;
        else
            cfg_pin_modes <= _75;
    end
    assign _662 = cfg_pin_modes[15:14];
    always @* begin
        case (_662)
        0:
            _675 <= _672;
        1:
            _675 <= _673;
        2:
            _675 <= _674;
        default:
            _675 <= _672;
        endcase
    end
    assign _660 = _655 == _1042;
    assign _661 = _654 & _660;
    assign _787 = _661 ? smp_strobe : _675;
    assign _655 = cfg_smp_ctrl[3:1];
    assign _657 = _655 == _1661;
    assign _561 = 9'b000000000;
    assign _3374 = _614[8:0];
    assign _3371 = 7'b1101100;
    assign _3372 = _610 == _3371;
    assign _3370 = _604 & _608;
    assign _3373 = _3370 & _3372;
    assign _3375 = _3373 ? _3374 : cfg_smp_ctrl;
    assign _76 = _3375;
    always @(posedge _141) begin
        if (_139)
            cfg_smp_ctrl <= _561;
        else
            cfg_smp_ctrl <= _76;
    end
    assign _654 = cfg_smp_ctrl[0:0];
    assign _658 = _654 & _657;
    assign _791 = _658 ? smp_data : _787;
    assign _883 = { _791,
                    _804,
                    _817,
                    _830,
                    _843,
                    _856,
                    _869,
                    _882 };
    assign _1138 = _883[0:0];
    assign _3380 = _614[2:0];
    assign _3377 = 7'b1000100;
    assign _3378 = _610 == _3377;
    assign _3376 = _604 & _608;
    assign _3379 = _3376 & _3378;
    assign _3381 = _3379 ? _3380 : cfg_t0_in_base;
    assign _77 = _3381;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_in_base <= _468;
        else
            cfg_t0_in_base <= _77;
    end
    assign _1137 = cfg_t0_in_base + _1661;
    always @* begin
        case (_1137)
        0:
            _1146 <= _1138;
        1:
            _1146 <= _1139;
        2:
            _1146 <= _1140;
        3:
            _1146 <= _1141;
        4:
            _1146 <= _1142;
        5:
            _1146 <= _1143;
        6:
            _1146 <= _1144;
        default:
            _1146 <= _1145;
        endcase
    end
    assign _1149 = _1146 & _1148;
    assign _1246 = { _1149,
                     _1163,
                     _1177,
                     _1191,
                     _1205,
                     _1219,
                     _1233,
                     _1245 };
    assign _1247 = { _568,
                     _1246 };
    assign _1134 = _127[8:7];
    always @* begin
        case (_1134)
        0:
            _1255 <= _1247;
        1:
            _1255 <= t0_x;
        2:
            _1255 <= t0_y;
        default:
            _1255 <= _307;
        endcase
    end
    assign _3400 = { _1255,
                     t0_isr };
    assign _3399 = _948[0:0];
    assign _3404 = _3399 ? _3403 : _3400;
    assign _3398 = _948[1:1];
    assign _3408 = _3398 ? _3407 : _3404;
    assign _3397 = _948[2:2];
    assign _3412 = _3397 ? _3411 : _3408;
    assign _3396 = _948[3:3];
    assign _3416 = _3396 ? _3415 : _3412;
    assign _3395 = _948[4:4];
    assign _3420 = _3395 ? _3419 : _3416;
    assign _3421 = _3420[15:0];
    assign _3452 = _1071 ? _3451 : _3421;
    assign _3454 = _954 ? _307 : _3452;
    assign _3393 = _912 ? t0_isr : _307;
    assign _3388 = _1033 == _1056;
    assign _3389 = _3388 ? _2390 : t0_isr;
    assign _3390 = _1039 ? _3389 : t0_isr;
    assign _3386 = _650 == _1689;
    assign _3391 = _3386 ? _3390 : t0_isr;
    assign _3385 = _650 == _4367;
    assign _3394 = _3385 ? _3393 : _3391;
    assign _3383 = _650 == _4223;
    assign _3455 = _3383 ? _3454 : _3394;
    assign _3456 = _958 ? _3455 : t0_isr;
    assign _3457 = _645 ? t0_isr : _3456;
    assign _3458 = _639 ? t0_isr : _3457;
    assign _3460 = _633 ? _307 : _3458;
    assign _78 = _3460;
    assign _79 = _78;
    always @(posedge _141) begin
        if (_139)
            t0_isr <= _307;
        else
            t0_isr <= _79;
    end
    assign _3498 = { _307,
                     t0_isr };
    assign _3496 = _3491[0:0];
    assign _3502 = _3496 ? _3501 : _3498;
    assign _3495 = _3491[1:1];
    assign _3506 = _3495 ? _3505 : _3502;
    assign _3494 = _3491[2:2];
    assign _3510 = _3494 ? _3509 : _3506;
    assign _3493 = _3491[3:3];
    assign _3514 = _3493 ? _3513 : _3510;
    assign _3477 = _3475[4:0];
    assign _3474 = { gnd,
                     _948 };
    assign _3473 = { gnd,
                     t0_isr_count };
    assign _3475 = _3473 + _3474;
    assign _3476 = _1970 < _3475;
    assign _3479 = _3476 ? _1103 : _3477;
    assign _951 = { gnd,
                    cfg_t0_threshold };
    assign _949 = { gnd,
                    _948 };
    assign _942 = { gnd,
                    t0_isr_count };
    assign _950 = _942 + _949;
    assign _952 = _950 < _951;
    assign _953 = ~ _952;
    assign _937 = cfg_t0_shift[3:3];
    assign _936 = _650 == _4223;
    assign _938 = _936 & _937;
    assign _954 = _938 & _953;
    assign _3481 = _954 ? _929 : _3479;
    assign _3470 = _912 ? t0_isr_count : _929;
    assign _3464 = _1033 == _1056;
    assign _3466 = _3464 ? _929 : t0_isr_count;
    assign _3467 = _1039 ? _3466 : t0_isr_count;
    assign _3463 = _650 == _1689;
    assign _3468 = _3463 ? _3467 : t0_isr_count;
    assign _3462 = _650 == _4367;
    assign _3471 = _3462 ? _3470 : _3468;
    assign _3461 = _650 == _4223;
    assign _3482 = _3461 ? _3481 : _3471;
    assign _3483 = _958 ? _3482 : t0_isr_count;
    assign _3484 = _645 ? t0_isr_count : _3483;
    assign _3485 = _639 ? t0_isr_count : _3484;
    assign _3487 = _633 ? _929 : _3485;
    assign _80 = _3487;
    assign _81 = _80;
    always @(posedge _141) begin
        if (_139)
            t0_isr_count <= _929;
        else
            t0_isr_count <= _81;
    end
    assign _3491 = _1103 - t0_isr_count;
    assign _3492 = _3491[4:4];
    assign _3518 = _3492 ? _3517 : _3514;
    assign _3519 = _3518[15:0];
    assign _1071 = cfg_t0_shift[1:1];
    assign _3547 = _1071 ? _3546 : _3519;
    assign _3489 = _650 == _4223;
    assign _3606 = _3489 ? _3605 : _3547;
    assign _82 = _3606;
    always @(posedge _141) begin
        if (_139)
            t0_rx_mem_0 <= _307;
        else
            if (_379)
                t0_rx_mem_0 <= _82;
    end
    assign _3636 = t0_rx_rd + _226;
    assign _3633 = ~ _3632;
    assign _3628 = _1302 == _598;
    assign _3629 = _110 & _3628;
    assign _3624 = ~ _1842;
    assign _3620 = _1302 == _598;
    assign _3618 = _1310 == _229;
    assign _3621 = _3618 & _3620;
    assign _3622 = ~ _3621;
    assign _3614 = t0_rx_level == _468;
    assign _3615 = ~ _3614;
    assign _3610 = 7'b1001001;
    assign _321 = _320[6:0];
    assign _3611 = _321 == _3610;
    assign _3607 = _320[7:7];
    assign _3608 = ~ _3607;
    assign _1365 = host_bit_count == _1672;
    assign _1366 = _305 & _1365;
    assign _3609 = _1366 & _3608;
    assign _3612 = _3609 & _3611;
    assign _3616 = _3612 & _3615;
    assign _83 = _3616;
    assign _3623 = _83 & _3622;
    assign _3625 = _3623 & _3624;
    assign _3626 = _145 | _3625;
    assign _3630 = _3626 | _3629;
    assign _3634 = _3630 & _3633;
    assign _3637 = _3634 ? _3636 : t0_rx_rd;
    assign _84 = _3637;
    always @(posedge _141) begin
        if (_139)
            t0_rx_rd <= _4358;
        else
            t0_rx_rd <= _84;
    end
    always @* begin
        case (t0_rx_rd)
        0:
            _399 <= t0_rx_mem_0;
        1:
            _399 <= t0_rx_mem_1;
        2:
            _399 <= t0_rx_mem_2;
        default:
            _399 <= t0_rx_mem_3;
        endcase
    end
    assign _3651 = _1302 ? _506 : _399;
    assign _3652 = _110 ? _3651 : _614;
    assign _3650 = _85 ? buf_ptr : _111;
    assign _3649 = ~ _85;
    assign _3645 = _1310 == _965;
    assign _3643 = _1310 == _4358;
    assign _3646 = _3643 | _3645;
    assign _3640 = _610 == _1370;
    assign _3638 = _604 & _608;
    assign _3641 = _3638 & _3640;
    assign _3647 = _3641 & _3646;
    assign _3648 = _110 | _3647;
    assign _85 = _3648;
    RM_IHPSG13_1P_1024x16_c2_bm_bist
        sram_buf
        ( .A_CLK(_141),
          .A_MEN(vdd),
          .A_WEN(_85),
          .A_REN(_3649),
          .A_ADDR(_3650),
          .A_DIN(_3652),
          .A_DLY(vdd),
          .A_BM(_4270),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_527),
          .A_BIST_DIN(_307),
          .A_BIST_BM(_307),
          .A_DOUT(_3658[15:0]) );
    assign _86 = _3658;
    assign _87 = _86;
    assign _1828 = _1302 == _1837;
    assign _1829 = _113 & _1828;
    assign _3722 = _1829 ? _87 : _614;
    assign _3723 = _145 ? _43 : _3722;
    always @(posedge _141) begin
        if (_139)
            t1_tx_mem_0 <= _307;
        else
            if (_3728)
                t1_tx_mem_0 <= _3723;
    end
    assign _3692 = t1_tx_rd + _226;
    assign _3686 = ~ _1440;
    assign _3663 = ~ _1440;
    assign _3660 = _1405 == _4367;
    assign _3661 = _1404 & _3660;
    assign _3662 = _3661 & _1437;
    assign _3664 = _3662 & _3663;
    assign _3682 = _3664 | _3681;
    assign _3685 = _3682 | _3684;
    assign _88 = _3685;
    assign _3687 = _88 & _3686;
    assign _3693 = _3687 ? _3692 : t1_tx_rd;
    assign _89 = _3693;
    always @(posedge _141) begin
        if (_139)
            t1_tx_rd <= _4358;
        else
            t1_tx_rd <= _89;
    end
    always @* begin
        case (t1_tx_rd)
        0:
            _3748 <= t1_tx_mem_0;
        1:
            _3748 <= t1_tx_mem_1;
        2:
            _3748 <= t1_tx_mem_2;
        default:
            _3748 <= t1_tx_mem_3;
        endcase
    end
    assign _1440 = t1_tx_level == _468;
    assign _3680 = ~ _1440;
    assign _457 = 5'b01000;
    assign _3698 = _614[4:0];
    assign _3695 = 7'b1010101;
    assign _3696 = _610 == _3695;
    assign _3694 = _604 & _608;
    assign _3697 = _3694 & _3696;
    assign _3699 = _3697 ? _3698 : cfg_t1_threshold;
    assign _90 = _3699;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_threshold <= _457;
        else
            cfg_t1_threshold <= _90;
    end
    assign _3674 = _3672[4:0];
    assign _1471 = { gnd,
                     _1468 };
    assign _1468 = _102[3:0];
    assign _1470 = _1468 == _647;
    assign _1473 = _1470 ? _1103 : _1471;
    assign _3671 = { gnd,
                     _1473 };
    assign _3670 = { gnd,
                     t1_osr_count };
    assign _3672 = _3670 + _3671;
    assign _3673 = _1970 < _3672;
    assign _3676 = _3673 ? _1103 : _3674;
    assign _3677 = _3676 < cfg_t1_threshold;
    assign _3678 = ~ _3677;
    assign _3666 = _1405 == _1056;
    assign _3667 = _1483 & _3666;
    assign _3668 = _3667 & _1451;
    assign _3679 = _3668 & _3678;
    assign _3681 = _3679 & _3680;
    assign _3716 = _3681 ? _929 : _3676;
    assign _1437 = _102[8:8];
    assign _3713 = _1437 ? _929 : _3701;
    assign _3707 = _1558 == _4367;
    assign _3709 = _3707 ? _929 : _3701;
    assign _3710 = _1564 ? _3709 : _3701;
    assign _3705 = _1405 == _1689;
    assign _3711 = _3705 ? _3710 : _3701;
    assign _3704 = _1405 == _4367;
    assign _3714 = _3704 ? _3713 : _3711;
    assign _3703 = _1405 == _1056;
    assign _3717 = _3703 ? _3716 : _3714;
    assign _3701 = _3684 ? _929 : t1_osr_count;
    assign _3718 = _1483 ? _3717 : _3701;
    assign _3719 = _1400 ? t1_osr_count : _3718;
    assign _3720 = _1394 ? t1_osr_count : _3719;
    assign _3721 = _1388 ? cfg_t1_threshold : _3720;
    assign _91 = _3721;
    assign _92 = _91;
    always @(posedge _141) begin
        if (_139)
            t1_osr_count <= _929;
        else
            t1_osr_count <= _92;
    end
    assign _1456 = t1_osr_count < cfg_t1_threshold;
    assign _1457 = ~ _1456;
    assign _1451 = cfg_t1_shift[2:2];
    assign _1450 = _1405 == _1056;
    assign _1452 = _1450 & _1451;
    assign _1458 = _1452 & _1457;
    assign _3683 = _1404 & _1458;
    assign _3684 = _3683 & _3680;
    assign _3749 = _3684 ? _3748 : t1_osr;
    assign _3818 = _1483 ? _3817 : _3749;
    assign _3819 = _1400 ? t1_osr : _3818;
    assign _3820 = _1394 ? t1_osr : _3819;
    assign _3822 = _1388 ? _307 : _3820;
    assign _93 = _3822;
    assign _94 = _93;
    always @(posedge _141) begin
        if (_139)
            t1_osr <= _307;
        else
            t1_osr <= _94;
    end
    assign _1627 = t1_osr & _1626;
    assign _3827 = _614[5:0];
    assign _3824 = 7'b1011111;
    assign _3825 = _610 == _3824;
    assign _3823 = _604 & _608;
    assign _3826 = _3823 & _3825;
    assign _3828 = _3826 ? _3827 : cfg_t1_shift;
    assign _95 = _3828;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_shift <= _554;
        else
            cfg_t1_shift <= _95;
    end
    assign _1595 = cfg_t1_shift[0:0];
    assign _1658 = _1595 ? _1657 : _1627;
    assign _3843 = _102[8:7];
    assign _3845 = _3843 == _229;
    assign _3846 = _3845 ? _1658 : t1_y;
    assign _3839 = _1558 == _651;
    assign _3840 = _3839 ? _1886 : t1_y;
    assign _3841 = _1564 ? _3840 : t1_y;
    assign _3835 = _1489 == _229;
    assign _3836 = _3835 ? _2834 : t1_y;
    assign _3833 = _1405 == _1042;
    assign _3837 = _3833 ? _3836 : t1_y;
    assign _3832 = _1405 == _1689;
    assign _3842 = _3832 ? _3841 : _3837;
    assign _3831 = _1405 == _1056;
    assign _3847 = _3831 ? _3846 : _3842;
    assign _3830 = _1405 == _468;
    assign _3854 = _3830 ? _3853 : _3847;
    assign _3855 = _1483 ? _3854 : t1_y;
    assign _3856 = _1400 ? t1_y : _3855;
    assign _3857 = _1394 ? t1_y : _3856;
    assign _3859 = _1388 ? _307 : _3857;
    assign _96 = _3859;
    assign _97 = _96;
    always @(posedge _141) begin
        if (_139)
            t1_y <= _307;
        else
            t1_y <= _97;
    end
    always @* begin
        case (_1561)
        0:
            _1886 <= t1_x;
        1:
            _1886 <= t1_y;
        2:
            _1886 <= _1876;
        3:
            _1886 <= t1_isr;
        4:
            _1886 <= t1_osr;
        5:
            _1886 <= _307;
        default:
            _1886 <= _1885;
        endcase
    end
    assign _3869 = _1558 == _468;
    assign _3870 = _3869 ? _1886 : t1_x;
    assign _1561 = _102[5:3];
    assign _1563 = _1561 < _1661;
    assign _1558 = _102[8:6];
    assign _1560 = _1558 < _1661;
    assign _1564 = _1560 & _1563;
    assign _3871 = _1564 ? _3870 : t1_x;
    assign _2833 = _102[4:0];
    assign _2834 = { _455,
                     _2833 };
    assign _1489 = _102[8:7];
    assign _3865 = _1489 == _226;
    assign _3866 = _3865 ? _2834 : t1_x;
    assign _3863 = _1405 == _1042;
    assign _3867 = _3863 ? _3866 : t1_x;
    assign _3862 = _1405 == _1689;
    assign _3872 = _3862 ? _3871 : _3867;
    assign _3861 = _1405 == _1056;
    assign _3876 = _3861 ? _3875 : _3872;
    assign _3860 = _1405 == _468;
    assign _3882 = _3860 ? _3881 : _3876;
    assign _3883 = _1483 ? _3882 : t1_x;
    assign _3884 = _1400 ? t1_x : _3883;
    assign _3885 = _1394 ? t1_x : _3884;
    assign _3887 = _1388 ? _307 : _3885;
    assign _98 = _3887;
    assign _99 = _98;
    always @(posedge _141) begin
        if (_139)
            t1_x <= _307;
        else
            t1_x <= _99;
    end
    assign _3891 = t1_x == _307;
    assign _3892 = ~ _3891;
    assign _3893 = ~ _3892;
    assign _3848 = _102[8:6];
    always @* begin
        case (_3848)
        0:
            _3902 <= vdd;
        1:
            _3902 <= _3893;
        2:
            _3902 <= _3892;
        3:
            _3902 <= _3897;
        4:
            _3902 <= _3896;
        5:
            _3902 <= _3899;
        6:
            _3902 <= _3900;
        default:
            _3902 <= _3901;
        endcase
    end
    assign _3889 = _1405 == _468;
    assign _3903 = _3889 & _3902;
    assign _3909 = _3903 | _3908;
    assign _3917 = _3909 ? _3916 : _3911;
    always @(posedge _141) begin
        if (_139)
            t1_pc <= _568;
        else
            t1_pc <= _101;
    end
    assign _3918 = _1483 ? _3917 : t1_pc;
    assign _3919 = _1400 ? t1_pc : _3918;
    assign _3920 = _1394 ? t1_pc : _3919;
    assign _3921 = _1388 ? cfg_t1_start : _3920;
    assign _100 = _3921;
    assign _101 = _100;
    assign _3926 = _1382 ? _3925 : _101;
    assign _3922 = ~ _1382;
    RM_IHPSG13_1P_256x16_c2_bm_bist
        sram1
        ( .A_CLK(_141),
          .A_MEN(vdd),
          .A_WEN(_1382),
          .A_REN(_3922),
          .A_ADDR(_3926),
          .A_DIN(_614),
          .A_DLY(vdd),
          .A_BM(_4270),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_568),
          .A_BIST_DIN(_307),
          .A_BIST_BM(_307),
          .A_DOUT(_3932[15:0]) );
    assign _102 = _3932;
    assign _1405 = _102[15:13];
    assign _1407 = _1405 == _651;
    assign _1421 = _1407 & _1420;
    assign _1434 = _1421 & _1433;
    assign _1442 = _1434 | _1441;
    assign _1448 = _1442 | _1447;
    assign _1459 = _1448 | _1458;
    assign _1481 = _1459 | _1480;
    assign _1482 = ~ _1481;
    assign _1483 = _1404 & _1482;
    assign _3943 = _1483 ? _3942 : t1_delay_left;
    assign _1399 = t1_delay_left == _647;
    assign _1400 = ~ _1399;
    assign _3946 = _1400 ? _3945 : _3943;
    assign _1394 = ~ _1393;
    assign _3947 = _1394 ? t1_delay_left : _3946;
    assign _1388 = ~ _1387;
    assign _3949 = _1388 ? _647 : _3947;
    assign _103 = _3949;
    assign _104 = _103;
    always @(posedge _141) begin
        if (_139)
            t1_delay_left <= _647;
        else
            t1_delay_left <= _104;
    end
    assign _1403 = t1_delay_left == _647;
    assign _3961 = cfg_t1_clkdiv - _988;
    assign _3951 = 7'b1011101;
    assign _3952 = _610 == _3951;
    assign _3950 = _604 & _608;
    assign _3953 = _3950 & _3952;
    assign _3954 = _3953 ? _614 : cfg_t1_clkdiv;
    assign _105 = _3954;
    always @(posedge _141) begin
        if (_139)
            cfg_t1_clkdiv <= _307;
        else
            cfg_t1_clkdiv <= _105;
    end
    assign _3959 = cfg_t1_clkdiv == _307;
    assign _3963 = _3959 ? _307 : _3961;
    assign _3957 = t1_div_count - _988;
    assign _3964 = _1393 ? _3963 : _3957;
    assign _3955 = ~ _1387;
    assign _3966 = _3955 ? _307 : _3964;
    assign _106 = _3966;
    always @(posedge _141) begin
        if (_139)
            t1_div_count <= _307;
        else
            t1_div_count <= _106;
    end
    assign _1393 = t1_div_count == _307;
    assign _1381 = ~ _1379;
    assign _1380 = _624[1:1];
    assign _1382 = _1380 & _1381;
    always @(posedge _141) begin
        if (_139)
            t1_loaded <= _598;
        else
            t1_loaded <= _1382;
    end
    assign _1386 = ~ t1_loaded;
    assign _1379 = cfg_ctrl[1:1];
    assign _1387 = _1379 & _1386;
    assign _1401 = _1387 & _1393;
    assign _1404 = _1401 & _1403;
    assign _3969 = _1404 & _3968;
    assign _3971 = _3969 & _3970;
    assign _3973 = _3971 & _3972;
    assign _3975 = _3973 | _3974;
    assign _107 = _3975;
    assign _480 = _107 & _479;
    assign _3977 = { _4358,
                     _480 };
    assign _3978 = t1_rx_level + _3977;
    assign _3981 = _3978 - _3980;
    assign _108 = _3981;
    always @(posedge _141) begin
        if (_139)
            t1_rx_level <= _468;
        else
            t1_rx_level <= _108;
    end
    assign _2127 = t1_rx_level == _468;
    assign _3997 = _1302 ? _2127 : _3632;
    assign _3998 = ~ _3997;
    assign _1302 = cfg_buf_ctrl[2:2];
    assign _3993 = ~ _1302;
    assign _3994 = _1842 & _3993;
    assign _3995 = ~ _3994;
    assign _3986 = _614[9:0];
    assign _3983 = 7'b1101010;
    assign _3984 = _610 == _3983;
    assign _3982 = _604 & _608;
    assign _3985 = _3982 & _3984;
    assign _3987 = _3985 ? _3986 : cfg_buf_end;
    assign _109 = _3987;
    always @(posedge _141) begin
        if (_139)
            cfg_buf_end <= _527;
        else
            cfg_buf_end <= _109;
    end
    assign _3990 = buf_ptr == cfg_buf_end;
    assign _3991 = ~ _3990;
    assign _3989 = _1310 == _229;
    assign _3992 = _3989 & _3991;
    assign _3996 = _3992 & _3995;
    assign _3999 = _3996 & _3998;
    assign _110 = _3999;
    assign _4004 = _113 | _110;
    assign _4005 = _4004 | _3647;
    assign _4007 = _4005 | _4006;
    assign _4010 = _4007 ? _4009 : buf_ptr;
    assign _4001 = 7'b1101001;
    assign _4002 = _610 == _4001;
    assign _4000 = _604 & _608;
    assign _4003 = _4000 & _4002;
    assign _4012 = _4003 ? _4011 : _4010;
    assign _111 = _4012;
    always @(posedge _141) begin
        if (_139)
            buf_ptr <= _527;
        else
            buf_ptr <= _111;
    end
    assign _4021 = buf_ptr == cfg_buf_end;
    assign _4022 = ~ _4021;
    assign _4017 = _614[2:0];
    assign _4014 = 7'b1101000;
    assign _4015 = _610 == _4014;
    assign _4013 = _604 & _608;
    assign _4016 = _4013 & _4015;
    assign _4018 = _4016 ? _4017 : cfg_buf_ctrl;
    assign _112 = _4018;
    always @(posedge _141) begin
        if (_139)
            cfg_buf_ctrl <= _468;
        else
            cfg_buf_ctrl <= _112;
    end
    assign _1310 = cfg_buf_ctrl[1:0];
    assign _4020 = _1310 == _226;
    assign _4023 = _4020 & _4022;
    assign _4028 = _4023 & _4027;
    assign _4031 = _4028 & _4030;
    assign _4034 = _4031 & _4033;
    assign _113 = _4034;
    assign _1305 = _113 & _1304;
    assign _1318 = _1305 | _1317;
    assign _1322 = _1318 & _1321;
    assign _4036 = { _4358,
                     _1322 };
    assign _4037 = t0_tx_level + _4036;
    assign _4040 = _4037 - _4039;
    assign _114 = _4040;
    always @(posedge _141) begin
        if (_139)
            t0_tx_level <= _468;
        else
            t0_tx_level <= _114;
    end
    assign _915 = t0_tx_level == _468;
    assign _1358 = ~ _915;
    assign _4045 = _614[4:0];
    assign _4042 = 7'b1000101;
    assign _4043 = _610 == _4042;
    assign _4041 = _604 & _608;
    assign _4044 = _4041 & _4043;
    assign _4046 = _4044 ? _4045 : cfg_t0_threshold;
    assign _115 = _4046;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_threshold <= _457;
        else
            cfg_t0_threshold <= _115;
    end
    assign _1352 = _1350[4:0];
    assign _946 = { gnd,
                    _943 };
    assign _943 = _127[3:0];
    assign _945 = _943 == _647;
    assign _948 = _945 ? _1103 : _946;
    assign _1349 = { gnd,
                     _948 };
    assign _1348 = { gnd,
                     t0_osr_count };
    assign _1350 = _1348 + _1349;
    assign _1351 = _1970 < _1350;
    assign _1354 = _1351 ? _1103 : _1352;
    assign _1355 = _1354 < cfg_t0_threshold;
    assign _1356 = ~ _1355;
    assign _1344 = _650 == _1056;
    assign _1345 = _958 & _1344;
    assign _1346 = _1345 & _926;
    assign _1357 = _1346 & _1356;
    assign _1359 = _1357 & _1358;
    assign _4063 = _1359 ? _929 : _1354;
    assign _912 = _127[8:8];
    assign _4060 = _912 ? _929 : _4048;
    assign _4054 = _1033 == _4367;
    assign _4056 = _4054 ? _929 : _4048;
    assign _4057 = _1039 ? _4056 : _4048;
    assign _4052 = _650 == _1689;
    assign _4058 = _4052 ? _4057 : _4048;
    assign _4051 = _650 == _4367;
    assign _4061 = _4051 ? _4060 : _4058;
    assign _4050 = _650 == _1056;
    assign _4064 = _4050 ? _4063 : _4061;
    assign _4048 = _1362 ? _929 : t0_osr_count;
    assign _4065 = _958 ? _4064 : _4048;
    assign _4066 = _645 ? t0_osr_count : _4065;
    assign _4067 = _639 ? t0_osr_count : _4066;
    assign _4068 = _633 ? cfg_t0_threshold : _4067;
    assign _116 = _4068;
    assign _117 = _116;
    always @(posedge _141) begin
        if (_139)
            t0_osr_count <= _929;
        else
            t0_osr_count <= _117;
    end
    assign _931 = t0_osr_count < cfg_t0_threshold;
    assign _932 = ~ _931;
    assign _926 = cfg_t0_shift[2:2];
    assign _925 = _650 == _1056;
    assign _927 = _925 & _926;
    assign _933 = _927 & _932;
    assign _1361 = _649 & _933;
    assign _1362 = _1361 & _1358;
    assign _4095 = _1362 ? _4094 : t0_osr;
    assign _4164 = _958 ? _4163 : _4095;
    assign _4165 = _645 ? t0_osr : _4164;
    assign _4166 = _639 ? t0_osr : _4165;
    assign _4168 = _633 ? _307 : _4166;
    assign _118 = _4168;
    assign _119 = _118;
    always @(posedge _141) begin
        if (_139)
            t0_osr <= _307;
        else
            t0_osr <= _119;
    end
    assign _1102 = t0_osr & _1101;
    assign _4173 = _614[5:0];
    assign _4170 = 7'b1001111;
    assign _4171 = _610 == _4170;
    assign _4169 = _604 & _608;
    assign _4172 = _4169 & _4171;
    assign _4174 = _4172 ? _4173 : cfg_t0_shift;
    assign _120 = _4174;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_shift <= _554;
        else
            cfg_t0_shift <= _120;
    end
    assign _1070 = cfg_t0_shift[0:0];
    assign _1133 = _1070 ? _1132 : _1102;
    assign _4189 = _127[8:7];
    assign _4191 = _4189 == _229;
    assign _4192 = _4191 ? _1133 : t0_y;
    assign _4185 = _1033 == _651;
    assign _4186 = _4185 ? _2390 : t0_y;
    assign _4187 = _1039 ? _4186 : t0_y;
    assign _4181 = _964 == _229;
    assign _4182 = _4181 ? _2251 : t0_y;
    assign _4179 = _650 == _1042;
    assign _4183 = _4179 ? _4182 : t0_y;
    assign _4178 = _650 == _1689;
    assign _4188 = _4178 ? _4187 : _4183;
    assign _4177 = _650 == _1056;
    assign _4193 = _4177 ? _4192 : _4188;
    assign _4176 = _650 == _468;
    assign _4200 = _4176 ? _4199 : _4193;
    assign _4201 = _958 ? _4200 : t0_y;
    assign _4202 = _645 ? t0_y : _4201;
    assign _4203 = _639 ? t0_y : _4202;
    assign _4205 = _633 ? _307 : _4203;
    assign _121 = _4205;
    assign _122 = _121;
    always @(posedge _141) begin
        if (_139)
            t0_y <= _307;
        else
            t0_y <= _122;
    end
    always @* begin
        case (_1036)
        0:
            _2390 <= t0_x;
        1:
            _2390 <= t0_y;
        2:
            _2390 <= _2377;
        3:
            _2390 <= t0_isr;
        4:
            _2390 <= t0_osr;
        5:
            _2390 <= _307;
        default:
            _2390 <= _2389;
        endcase
    end
    assign _4215 = _1033 == _468;
    assign _4216 = _4215 ? _2390 : t0_x;
    assign _1036 = _127[5:3];
    assign _1038 = _1036 < _1661;
    assign _1033 = _127[8:6];
    assign _1035 = _1033 < _1661;
    assign _1039 = _1035 & _1038;
    assign _4217 = _1039 ? _4216 : t0_x;
    assign _2250 = _127[4:0];
    assign _2251 = { _455,
                     _2250 };
    assign _964 = _127[8:7];
    assign _4211 = _964 == _226;
    assign _4212 = _4211 ? _2251 : t0_x;
    assign _4209 = _650 == _1042;
    assign _4213 = _4209 ? _4212 : t0_x;
    assign _4208 = _650 == _1689;
    assign _4218 = _4208 ? _4217 : _4213;
    assign _4207 = _650 == _1056;
    assign _4222 = _4207 ? _4221 : _4218;
    assign _4206 = _650 == _468;
    assign _4228 = _4206 ? _4227 : _4222;
    assign _4229 = _958 ? _4228 : t0_x;
    assign _4230 = _645 ? t0_x : _4229;
    assign _4231 = _639 ? t0_x : _4230;
    assign _4233 = _633 ? _307 : _4231;
    assign _123 = _4233;
    assign _124 = _123;
    always @(posedge _141) begin
        if (_139)
            t0_x <= _307;
        else
            t0_x <= _124;
    end
    assign _4237 = t0_x == _307;
    assign _4238 = ~ _4237;
    assign _4239 = ~ _4238;
    assign _4194 = _127[8:6];
    always @* begin
        case (_4194)
        0:
            _4248 <= vdd;
        1:
            _4248 <= _4239;
        2:
            _4248 <= _4238;
        3:
            _4248 <= _4243;
        4:
            _4248 <= _4242;
        5:
            _4248 <= _4245;
        6:
            _4248 <= _4246;
        default:
            _4248 <= _4247;
        endcase
    end
    assign _4235 = _650 == _468;
    assign _4249 = _4235 & _4248;
    assign _4255 = _4249 | _4254;
    assign _4263 = _4255 ? _4262 : _4257;
    always @(posedge _141) begin
        if (_139)
            t0_pc <= _568;
        else
            t0_pc <= _126;
    end
    assign _4264 = _958 ? _4263 : t0_pc;
    assign _4265 = _645 ? t0_pc : _4264;
    assign _4266 = _639 ? t0_pc : _4265;
    assign _4267 = _633 ? cfg_t0_start : _4266;
    assign _125 = _4267;
    assign _126 = _125;
    assign _4269 = _627 ? _3925 : _126;
    assign _4268 = ~ _627;
    RM_IHPSG13_1P_256x16_c2_bm_bist
        sram0
        ( .A_CLK(_141),
          .A_MEN(vdd),
          .A_WEN(_627),
          .A_REN(_4268),
          .A_ADDR(_4269),
          .A_DIN(_614),
          .A_DLY(vdd),
          .A_BM(_4270),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_568),
          .A_BIST_DIN(_307),
          .A_BIST_BM(_307),
          .A_DOUT(_4275[15:0]) );
    assign _127 = _4275;
    assign _650 = _127[15:13];
    assign _652 = _650 == _651;
    assign _896 = _652 & _895;
    assign _909 = _896 & _908;
    assign _917 = _909 | _916;
    assign _923 = _917 | _922;
    assign _934 = _923 | _933;
    assign _956 = _934 | _955;
    assign _957 = ~ _956;
    assign _958 = _649 & _957;
    assign _4286 = _958 ? _4285 : t0_delay_left;
    assign _644 = t0_delay_left == _647;
    assign _645 = ~ _644;
    assign _4289 = _645 ? _4288 : _4286;
    assign _639 = ~ _638;
    assign _4290 = _639 ? t0_delay_left : _4289;
    assign _633 = ~ _632;
    assign _4292 = _633 ? _647 : _4290;
    assign _128 = _4292;
    assign _129 = _128;
    always @(posedge _141) begin
        if (_139)
            t0_delay_left <= _647;
        else
            t0_delay_left <= _129;
    end
    assign _648 = t0_delay_left == _647;
    assign _4304 = cfg_t0_clkdiv - _988;
    assign _4294 = 7'b1001101;
    assign _4295 = _610 == _4294;
    assign _4293 = _604 & _608;
    assign _4296 = _4293 & _4295;
    assign _4297 = _4296 ? _614 : cfg_t0_clkdiv;
    assign _130 = _4297;
    always @(posedge _141) begin
        if (_139)
            cfg_t0_clkdiv <= _307;
        else
            cfg_t0_clkdiv <= _130;
    end
    assign _4302 = cfg_t0_clkdiv == _307;
    assign _4306 = _4302 ? _307 : _4304;
    assign _4300 = t0_div_count - _988;
    assign _4307 = _638 ? _4306 : _4300;
    assign _4298 = ~ _632;
    assign _4309 = _4298 ? _307 : _4307;
    assign _131 = _4309;
    always @(posedge _141) begin
        if (_139)
            t0_div_count <= _307;
        else
            t0_div_count <= _131;
    end
    assign _638 = t0_div_count == _307;
    assign _626 = ~ _617;
    assign _432 = 6'b110000;
    assign _4314 = _614[5:0];
    assign _4311 = 7'b1010000;
    assign _4312 = _610 == _4311;
    assign _4310 = _604 & _608;
    assign _4313 = _4310 & _4312;
    assign _4315 = _4313 ? _4314 : cfg_load;
    assign _132 = _4315;
    always @(posedge _141) begin
        if (_139)
            cfg_load <= _432;
        else
            cfg_load <= _132;
    end
    assign _623 = cfg_load[5:4];
    assign _619 = 7'b1000000;
    assign _620 = _610 < _619;
    assign _618 = _604 & _608;
    assign _621 = _618 & _620;
    assign _622 = { _621,
                    _621 };
    assign _624 = _622 & _623;
    assign _625 = _624[0:0];
    assign _627 = _625 & _626;
    always @(posedge _141) begin
        if (_139)
            t0_loaded <= _598;
        else
            t0_loaded <= _627;
    end
    assign _631 = ~ t0_loaded;
    assign _617 = cfg_ctrl[0:0];
    assign _632 = _617 & _631;
    assign _646 = _632 & _638;
    assign _649 = _646 & _648;
    assign _4318 = _649 & _4317;
    assign _4320 = _4318 & _4319;
    assign _4322 = _4320 & _4321;
    assign _4324 = _4322 | _4323;
    assign _133 = _4324;
    assign _373 = _133 & _372;
    assign _4326 = { _4358,
                     _373 };
    assign _4327 = t0_rx_level + _4326;
    assign _4330 = _4327 - _4329;
    assign _134 = _4330;
    always @(posedge _141) begin
        if (_139)
            t0_rx_level <= _468;
        else
            t0_rx_level <= _134;
    end
    assign _3632 = t0_rx_level == _468;
    assign _4351 = ~ _3632;
    assign _614 = _319[15:0];
    assign _4349 = _614[2:0];
    assign _610 = host_cmd[6:0];
    assign _4347 = _610 == _619;
    assign _314 = _143[2:2];
    always @(posedge _141) begin
        if (_139)
            host_mosi_s1 <= gnd;
        else
            host_mosi_s1 <= _314;
    end
    always @(posedge _141) begin
        if (_139)
            host_mosi_s2 <= gnd;
        else
            host_mosi_s2 <= host_mosi_s1;
    end
    assign _312 = 23'b00000000000000000000000;
    assign _4331 = _319[22:0];
    assign _4332 = _305 ? _4331 : host_shift_in;
    assign _4333 = host_cs_n_s2 ? host_shift_in : _4332;
    assign _135 = _4333;
    always @(posedge _141) begin
        if (_139)
            host_shift_in <= _312;
        else
            host_shift_in <= _135;
    end
    assign _319 = { host_shift_in,
                    host_mosi_s2 };
    assign _320 = _319[7:0];
    assign _310 = host_bit_count == _1672;
    assign _4334 = _310 ? _320 : host_cmd;
    assign _4335 = _305 ? _4334 : host_cmd;
    assign _4336 = host_cs_n_s2 ? host_cmd : _4335;
    assign _136 = _4336;
    always @(posedge _141) begin
        if (_139)
            host_cmd <= _568;
        else
            host_cmd <= _136;
    end
    assign _608 = host_cmd[7:7];
    assign _602 = 5'b10111;
    assign _4340 = host_bit_count + _1259;
    assign _4337 = 5'b11000;
    assign _4338 = host_bit_count < _4337;
    assign _4341 = _4338 ? _4340 : host_bit_count;
    assign _4342 = _305 ? _4341 : host_bit_count;
    assign _4344 = host_cs_n_s2 ? _929 : _4342;
    assign _137 = _4344;
    always @(posedge _141) begin
        if (_139)
            host_bit_count <= _929;
        else
            host_bit_count <= _137;
    end
    assign _603 = host_bit_count == _602;
    assign _277 = _143[1:1];
    always @(posedge _141) begin
        if (_139)
            host_cs_n_s1 <= vdd;
        else
            host_cs_n_s1 <= _277;
    end
    always @(posedge _141) begin
        if (_139)
            host_cs_n_s2 <= vdd;
        else
            host_cs_n_s2 <= host_cs_n_s1;
    end
    assign _304 = ~ host_cs_n_s2;
    always @(posedge _141) begin
        if (_139)
            host_sck_prev <= _598;
        else
            host_sck_prev <= host_sck_s2;
    end
    assign _302 = ~ host_sck_prev;
    assign vdd = 1'b1;
    assign _139 = clear;
    assign _141 = clock;
    assign _143 = ui_in;
    assign _282 = _143[0:0];
    always @(posedge _141) begin
        if (_139)
            host_sck_s1 <= gnd;
        else
            host_sck_s1 <= _282;
    end
    always @(posedge _141) begin
        if (_139)
            host_sck_s2 <= gnd;
        else
            host_sck_s2 <= host_sck_s1;
    end
    assign _303 = host_sck_s2 & _302;
    assign _305 = _303 & _304;
    assign _604 = _305 & _603;
    assign _4345 = _604 & _608;
    assign _4348 = _4345 & _4347;
    assign _4350 = _4348 ? _4349 : cfg_ctrl;
    assign _144 = _4350;
    always @(posedge _141) begin
        if (_139)
            cfg_ctrl <= _468;
        else
            cfg_ctrl <= _144;
    end
    assign _1842 = cfg_ctrl[2:2];
    assign _4352 = _1842 & _4351;
    assign _4354 = _4352 & _4353;
    assign _145 = _4354;
    assign _1830 = _145 | _1829;
    assign _1845 = _1830 | _1844;
    assign _1849 = _1845 & _1848;
    assign _4356 = { _4358,
                     _1849 };
    assign _4357 = t1_tx_level + _4356;
    assign _4360 = _4357 - _4359;
    assign _146 = _4360;
    always @(posedge _141) begin
        if (_139)
            t1_tx_level <= _468;
        else
            t1_tx_level <= _146;
    end
    assign _4362 = t1_tx_level == _4367;
    assign gnd = 1'b0;
    assign _4374 = { gnd,
                     _4362,
                     _4365,
                     _4366,
                     _4368,
                     _4371,
                     _4372,
                     _4373 };
    assign uo_out = _4374;
    assign uio_out = _276;
    assign uio_oe = _235;

endmodule
