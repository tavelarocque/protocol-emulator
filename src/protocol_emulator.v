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

    wire _221;
    wire _222;
    wire [1:0] _219;
    wire [1:0] _218;
    wire _220;
    wire _223;
    wire [1:0] _216;
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
    wire [1:0] _158;
    wire _160;
    wire _163;
    wire [1:0] _155;
    wire _157;
    wire _164;
    wire _151;
    wire _152;
    wire [1:0] _145;
    wire _147;
    wire _153;
    wire [1:0] _142;
    wire _144;
    wire _154;
    wire [7:0] _225;
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
    wire _234;
    wire [1:0] _231;
    wire _233;
    wire _235;
    wire _229;
    wire [1:0] _226;
    wire _228;
    wire _230;
    wire [7:0] _266;
    wire [15:0] _297;
    wire _565;
    wire [14:0] _564;
    wire [15:0] _566;
    wire [5:0] _544;
    wire [15:0] _548;
    wire [15:0] _543;
    wire [12:0] _534;
    wire [15:0] _538;
    wire [9:0] _517;
    wire [15:0] _521;
    wire [15:0] _513;
    wire _501;
    wire [15:0] _505;
    wire [2:0] _458;
    wire _459;
    wire _460;
    wire [15:0] _497;
    wire [7:0] _450;
    wire [15:0] _454;
    wire [10:0] _445;
    wire [15:0] _449;
    wire [15:0] _444;
    wire [15:0] _439;
    wire [15:0] _434;
    wire [15:0] _429;
    wire [15:0] _424;
    wire [15:0] _419;
    wire [15:0] _414;
    wire [15:0] _406;
    wire _394;
    wire [15:0] _398;
    wire _352;
    wire _353;
    wire [15:0] _390;
    wire [15:0] _347;
    wire [15:0] _342;
    wire [15:0] _337;
    wire [15:0] _332;
    wire [15:0] _327;
    wire [15:0] _322;
    wire [15:0] _317;
    reg [15:0] _561;
    wire [15:0] _562;
    wire [15:0] _563;
    wire [4:0] _288;
    wire _289;
    wire _290;
    wire _283;
    wire _278;
    wire _282;
    wire _284;
    wire _291;
    wire [15:0] _567;
    wire [15:0] _568;
    wire [15:0] _3;
    reg [15:0] host_miso_shift;
    wire _4106;
    wire _4105;
    wire _4103;
    wire _4104;
    wire [2:0] _4100;
    wire _4101;
    wire _4099;
    wire _4097;
    wire _4098;
    wire [1:0] _4091;
    wire [2:0] _4092;
    wire _1635;
    wire _1630;
    wire _1624;
    wire _1625;
    wire _1623;
    wire _1626;
    wire _1627;
    wire [6:0] _1619;
    wire _1620;
    wire _1618;
    wire _1621;
    wire _1628;
    wire _1631;
    wire _4086;
    wire [2:0] _4062;
    wire _362;
    wire _4056;
    wire _4054;
    wire _4052;
    wire _4050;
    wire [3:0] _614;
    wire [3:0] _4020;
    wire [3:0] _4021;
    wire [1:0] _4015;
    wire [3:0] _4016;
    wire [3:0] _4012;
    wire [3:0] _4011;
    wire _4010;
    wire [3:0] _4013;
    wire _4009;
    wire [3:0] _4017;
    wire [3:0] _4018;
    wire _742;
    wire _361;
    wire _707;
    wire _706;
    wire _708;
    wire _709;
    wire _698;
    wire _700;
    wire _703;
    wire _695;
    wire _682;
    wire [2:0] _618;
    wire [15:0] _4003;
    wire [5:0] _3993;
    wire [7:0] _582;
    wire [6:0] _578;
    wire _579;
    wire _576;
    wire _580;
    wire [7:0] _583;
    wire [7:0] _4;
    reg [7:0] cfg_t0_start;
    wire [1:0] _760;
    wire [1:0] _754;
    wire [1:0] _752;
    wire _753;
    wire [1:0] _755;
    wire _750;
    wire [1:0] _756;
    wire [1:0] _757;
    wire [1:0] _758;
    wire [1:0] _759;
    wire [1:0] _761;
    wire [1:0] _5;
    wire [1:0] _6;
    reg [1:0] t0_page;
    wire [7:0] _3994;
    wire [7:0] _766;
    wire [6:0] _763;
    wire _764;
    wire _762;
    wire _765;
    wire [7:0] _767;
    wire [7:0] _7;
    reg [7:0] cfg_t0_timeout_vector;
    wire _3992;
    wire [7:0] _3995;
    wire [7:0] _3989;
    wire [7:0] _3990;
    wire [15:0] _775;
    wire [15:0] _776;
    wire [15:0] _777;
    wire [15:0] _778;
    wire [15:0] _779;
    wire [15:0] _781;
    wire [15:0] _8;
    wire [15:0] _9;
    reg [15:0] t0_wait_count;
    wire [6:0] _783;
    wire _784;
    wire _782;
    wire _785;
    wire [15:0] _786;
    wire [15:0] _10;
    reg [15:0] cfg_t0_timeout;
    wire _773;
    wire _770;
    wire _769;
    wire _771;
    wire _772;
    wire _774;
    wire _788;
    wire _790;
    wire _791;
    wire _792;
    wire _794;
    wire _11;
    wire _12;
    reg t0_waiting;
    wire [15:0] _691;
    wire _693;
    wire _684;
    wire _694;
    wire _680;
    wire _678;
    wire _677;
    wire _676;
    wire _675;
    wire _674;
    wire _673;
    wire _672;
    wire _671;
    wire [2:0] _620;
    reg _679;
    wire _681;
    wire _3985;
    wire _3984;
    wire _3986;
    wire _3987;
    wire _3980;
    wire _3979;
    wire _3977;
    wire _3978;
    wire _3974;
    wire _3975;
    wire _3976;
    wire [15:0] _3959;
    wire [2:0] _3956;
    wire _3957;
    wire [15:0] _3960;
    wire _3953;
    wire [15:0] _3954;
    wire _2121;
    wire [1:0] _2122;
    wire [3:0] _2123;
    wire [7:0] _2124;
    wire [15:0] _2125;
    wire [31:0] _2126;
    wire [31:0] _850;
    wire [6:0] _796;
    wire _797;
    wire _795;
    wire _798;
    wire [15:0] _799;
    wire [15:0] _13;
    reg [15:0] cfg_t0_crc_init_lo;
    wire [6:0] _801;
    wire _802;
    wire _800;
    wire _803;
    wire [15:0] _804;
    wire [15:0] _14;
    reg [15:0] cfg_t0_crc_init_hi;
    wire [31:0] _1081;
    wire [15:0] _1078;
    wire [31:0] _1079;
    wire [31:0] _1080;
    wire [31:0] _1082;
    wire [31:0] _1083;
    wire _1076;
    wire [31:0] _1084;
    wire _1064;
    wire _1063;
    wire _1062;
    wire _1061;
    wire _1060;
    wire _1059;
    wire _1058;
    wire _1057;
    wire _1056;
    wire _1055;
    wire _1054;
    wire _1053;
    wire _1052;
    wire _1051;
    wire _1050;
    wire _1049;
    wire [4:0] _1046;
    wire [4:0] _1047;
    wire [3:0] _1048;
    reg _1065;
    wire [15:0] _1043;
    wire [15:0] _1044;
    wire _1045;
    wire _859;
    wire _1066;
    wire _856;
    wire _1067;
    wire [1:0] _1068;
    wire [3:0] _1069;
    wire [7:0] _1070;
    wire [15:0] _1071;
    wire [31:0] _1072;
    wire [6:0] _806;
    wire _807;
    wire _805;
    wire _808;
    wire [15:0] _809;
    wire [15:0] _15;
    reg [15:0] cfg_t0_crc_poly_lo;
    wire [6:0] _811;
    wire _812;
    wire _810;
    wire _813;
    wire [15:0] _814;
    wire [15:0] _16;
    reg [15:0] cfg_t0_crc_poly_hi;
    wire [31:0] _855;
    wire [31:0] _1073;
    wire [30:0] _853;
    wire [31:0] _854;
    wire [31:0] _1074;
    wire _846;
    wire [2:0] _843;
    wire _844;
    wire _842;
    wire _847;
    wire [2:0] _829;
    wire _830;
    wire _831;
    wire _828;
    wire _833;
    wire _834;
    wire _819;
    wire _835;
    wire _836;
    wire _837;
    wire _838;
    wire _840;
    wire _17;
    wire _18;
    reg t0_crc_run;
    wire _841;
    wire _848;
    wire [31:0] _1075;
    wire [31:0] _1085;
    wire [31:0] _1086;
    wire [31:0] _1087;
    wire [31:0] _1088;
    wire [31:0] _19;
    wire [31:0] _20;
    reg [31:0] t0_crc;
    wire [31:0] _2127;
    wire [15:0] _2128;
    wire [15:0] _2116;
    wire [15:0] _3931;
    wire _3929;
    wire [15:0] _3932;
    wire [15:0] _916;
    wire [31:0] _917;
    wire [23:0] _912;
    wire [31:0] _913;
    wire [27:0] _908;
    wire [31:0] _909;
    wire [29:0] _904;
    wire [31:0] _905;
    wire [30:0] _900;
    wire [31:0] _901;
    wire [31:0] _898;
    wire _896;
    wire [31:0] _902;
    wire _895;
    wire [31:0] _906;
    wire _894;
    wire [31:0] _910;
    wire _893;
    wire [31:0] _914;
    wire [4:0] _890;
    wire [4:0] _891;
    wire _892;
    wire [31:0] _918;
    wire [15:0] _919;
    wire [15:0] _3889;
    wire [31:0] _3891;
    wire [23:0] _3885;
    wire [31:0] _3887;
    wire [27:0] _3881;
    wire [31:0] _3883;
    wire [29:0] _3877;
    wire [31:0] _3879;
    wire [30:0] _3873;
    wire [31:0] _3875;
    wire [31:0] _3872;
    wire _3870;
    wire [31:0] _3876;
    wire _3869;
    wire [31:0] _3880;
    wire _3868;
    wire [31:0] _3884;
    wire _3867;
    wire [31:0] _3888;
    wire _3866;
    wire [31:0] _3892;
    wire [15:0] _3893;
    wire [15:0] _3862;
    wire [31:0] _3863;
    wire [23:0] _3858;
    wire [31:0] _3859;
    wire [27:0] _3854;
    wire [31:0] _3855;
    wire [29:0] _3850;
    wire [31:0] _3851;
    wire [30:0] _3846;
    wire [31:0] _3847;
    wire [31:0] _3844;
    wire _3842;
    wire [31:0] _3848;
    wire _3841;
    wire [31:0] _3852;
    wire _3840;
    wire [31:0] _3856;
    wire _3839;
    wire [31:0] _3860;
    wire _3838;
    wire [31:0] _3864;
    wire [15:0] _3865;
    wire [15:0] _3894;
    wire [15:0] _3895;
    wire [15:0] _3836;
    wire _3832;
    wire [15:0] _3833;
    wire [15:0] _3834;
    wire _3831;
    wire [15:0] _3835;
    wire _3830;
    wire [15:0] _3837;
    wire _3829;
    wire [15:0] _3896;
    wire _3824;
    wire _3825;
    reg [15:0] t0_tx_mem_3;
    wire _3818;
    wire _3819;
    reg [15:0] t0_tx_mem_2;
    wire _3812;
    wire _3813;
    reg [15:0] t0_tx_mem_1;
    wire [1:0] _1114;
    wire [1:0] _1115;
    wire [1:0] _21;
    reg [1:0] t0_tx_wr;
    wire _3806;
    wire _3807;
    wire [15:0] _3802;
    reg [15:0] t0_tx_mem_0;
    wire [1:0] _1122;
    wire [1:0] _1123;
    wire [1:0] _22;
    reg [1:0] t0_tx_rd;
    reg [15:0] _3827;
    wire [4:0] _716;
    wire _1116;
    wire _1128;
    wire _1125;
    wire _1126;
    wire _1127;
    wire _1129;
    wire _1147;
    wire _1150;
    wire _23;
    wire _1117;
    wire [2:0] _3772;
    wire _1108;
    wire _1101;
    wire _1099;
    wire _1102;
    wire _1103;
    wire [6:0] _1094;
    wire _1095;
    wire _1093;
    wire _1096;
    wire _1104;
    wire _1091;
    wire _1634;
    wire _1107;
    wire _3765;
    wire _3766;
    wire _3762;
    wire _3763;
    reg buf_wrote;
    wire _3760;
    wire [9:0] _3744;
    wire [9:0] _3741;
    wire [9:0] _3742;
    wire [6:0] _1157;
    wire _1158;
    wire _1154;
    wire _1155;
    wire _1156;
    wire _1159;
    wire _24;
    wire _3739;
    wire [2:0] _3713;
    wire _469;
    wire _3707;
    wire _3705;
    wire _3703;
    wire _3701;
    wire [3:0] _3678;
    wire [1:0] _3672;
    wire [3:0] _3673;
    wire _3667;
    wire [3:0] _3670;
    wire _3666;
    wire [3:0] _3674;
    wire [3:0] _3675;
    wire _1267;
    wire _468;
    wire _1232;
    wire _1231;
    wire _1233;
    wire _1234;
    wire _1223;
    wire _1225;
    wire _1228;
    wire _1220;
    wire _1207;
    wire [5:0] _3657;
    wire [1:0] _3656;
    wire [7:0] _3658;
    wire [5:0] _3647;
    wire [7:0] _1164;
    wire [6:0] _1161;
    wire _1162;
    wire _1160;
    wire _1163;
    wire [7:0] _1165;
    wire [7:0] _25;
    reg [7:0] cfg_t1_start;
    wire [1:0] _1285;
    wire [1:0] _1279;
    wire _1278;
    wire [1:0] _1280;
    wire _1275;
    wire [1:0] _1281;
    wire [1:0] _1282;
    wire [1:0] _1283;
    wire [1:0] _1284;
    wire [1:0] _1286;
    wire [1:0] _26;
    wire [1:0] _27;
    reg [1:0] t1_page;
    wire [7:0] _3648;
    wire [7:0] _1291;
    wire [6:0] _1288;
    wire _1289;
    wire _1287;
    wire _1290;
    wire [7:0] _1292;
    wire [7:0] _28;
    reg [7:0] cfg_t1_timeout_vector;
    wire _3646;
    wire [7:0] _3649;
    wire [7:0] _3644;
    wire [15:0] _1301;
    wire [15:0] _1302;
    wire [15:0] _1303;
    wire [15:0] _1304;
    wire [15:0] _1306;
    wire [15:0] _29;
    wire [15:0] _30;
    reg [15:0] t1_wait_count;
    wire [6:0] _1308;
    wire _1309;
    wire _1307;
    wire _1310;
    wire [15:0] _1311;
    wire [15:0] _31;
    reg [15:0] cfg_t1_timeout;
    wire _1298;
    wire _1295;
    wire _1294;
    wire _1296;
    wire _1297;
    wire _1299;
    wire _1313;
    wire _1315;
    wire _1316;
    wire _1317;
    wire _1319;
    wire _32;
    wire _33;
    reg t1_waiting;
    wire [15:0] _1216;
    wire _1218;
    wire _1209;
    wire _1219;
    wire _1205;
    wire _1203;
    wire _1202;
    wire _1201;
    wire _1200;
    wire _1199;
    wire _1198;
    wire _1197;
    wire _1196;
    wire [2:0] _1195;
    reg _1204;
    wire _1206;
    wire _3639;
    wire _3638;
    wire _3640;
    wire _3641;
    wire _3634;
    wire _3633;
    wire _3631;
    wire _3632;
    wire _3628;
    wire _3629;
    wire _3630;
    wire [15:0] _3613;
    wire _3611;
    wire [15:0] _3614;
    wire _3607;
    wire [15:0] _3608;
    wire _1665;
    wire [1:0] _1666;
    wire [3:0] _1667;
    wire [7:0] _1668;
    wire [15:0] _1669;
    wire [31:0] _1670;
    wire [6:0] _1321;
    wire _1322;
    wire _1320;
    wire _1323;
    wire [15:0] _1324;
    wire [15:0] _34;
    reg [15:0] cfg_t1_crc_init_lo;
    wire [6:0] _1326;
    wire _1327;
    wire _1325;
    wire _1328;
    wire [15:0] _1329;
    wire [15:0] _35;
    reg [15:0] cfg_t1_crc_init_hi;
    wire [31:0] _1606;
    wire [15:0] _1603;
    wire [31:0] _1604;
    wire [31:0] _1605;
    wire [31:0] _1607;
    wire [31:0] _1608;
    wire _1601;
    wire [31:0] _1609;
    wire _1589;
    wire _1588;
    wire _1587;
    wire _1586;
    wire _1585;
    wire _1584;
    wire _1583;
    wire _1582;
    wire _1581;
    wire _1580;
    wire _1579;
    wire _1578;
    wire _1577;
    wire _1576;
    wire _1575;
    wire _1574;
    wire [4:0] _1572;
    wire [3:0] _1573;
    reg _1590;
    wire [15:0] _1568;
    wire [15:0] _1569;
    wire _1570;
    wire _1384;
    wire _1591;
    wire _1381;
    wire _1592;
    wire [1:0] _1593;
    wire [3:0] _1594;
    wire [7:0] _1595;
    wire [15:0] _1596;
    wire [31:0] _1597;
    wire [6:0] _1331;
    wire _1332;
    wire _1330;
    wire _1333;
    wire [15:0] _1334;
    wire [15:0] _36;
    reg [15:0] cfg_t1_crc_poly_lo;
    wire [6:0] _1336;
    wire _1337;
    wire _1335;
    wire _1338;
    wire [15:0] _1339;
    wire [15:0] _37;
    reg [15:0] cfg_t1_crc_poly_hi;
    wire [31:0] _1380;
    wire [31:0] _1598;
    wire [30:0] _1378;
    wire [31:0] _1379;
    wire [31:0] _1599;
    wire _1371;
    wire _1369;
    wire _1367;
    wire _1372;
    wire _1355;
    wire _1356;
    wire _1353;
    wire _1358;
    wire _1359;
    wire _1344;
    wire _1360;
    wire _1361;
    wire _1362;
    wire _1363;
    wire _1365;
    wire _38;
    wire _39;
    reg t1_crc_run;
    wire _1366;
    wire _1373;
    wire [31:0] _1600;
    wire [31:0] _1610;
    wire [31:0] _1611;
    wire [31:0] _1612;
    wire [31:0] _1613;
    wire [31:0] _40;
    wire [31:0] _41;
    reg [31:0] t1_crc;
    wire [31:0] _1671;
    wire [15:0] _1672;
    wire [15:0] _1663;
    wire [15:0] _3585;
    wire _3583;
    wire [15:0] _3586;
    wire [15:0] _1441;
    wire [31:0] _1442;
    wire [23:0] _1437;
    wire [31:0] _1438;
    wire [27:0] _1433;
    wire [31:0] _1434;
    wire [29:0] _1429;
    wire [31:0] _1430;
    wire [30:0] _1425;
    wire [31:0] _1426;
    wire [31:0] _1423;
    wire _1421;
    wire [31:0] _1427;
    wire _1420;
    wire [31:0] _1431;
    wire _1419;
    wire [31:0] _1435;
    wire _1418;
    wire [31:0] _1439;
    wire [4:0] _1416;
    wire _1417;
    wire [31:0] _1443;
    wire [15:0] _1444;
    wire [15:0] _3543;
    wire [31:0] _3545;
    wire [23:0] _3539;
    wire [31:0] _3541;
    wire [27:0] _3535;
    wire [31:0] _3537;
    wire [29:0] _3531;
    wire [31:0] _3533;
    wire [30:0] _3527;
    wire [31:0] _3529;
    wire [31:0] _3526;
    wire _3524;
    wire [31:0] _3530;
    wire _3523;
    wire [31:0] _3534;
    wire _3522;
    wire [31:0] _3538;
    wire _3521;
    wire [31:0] _3542;
    wire _3520;
    wire [31:0] _3546;
    wire [15:0] _3547;
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
    wire [31:0] _3498;
    wire _3496;
    wire [31:0] _3502;
    wire _3495;
    wire [31:0] _3506;
    wire _3494;
    wire [31:0] _3510;
    wire _3493;
    wire [31:0] _3514;
    wire _3492;
    wire [31:0] _3518;
    wire [15:0] _3519;
    wire [15:0] _3548;
    wire [15:0] _3549;
    wire [15:0] _3490;
    wire _3486;
    wire [15:0] _3487;
    wire [15:0] _3488;
    wire _3485;
    wire [15:0] _3489;
    wire _3484;
    wire [15:0] _3491;
    wire _3483;
    wire [15:0] _3550;
    wire _3478;
    wire _3479;
    reg [15:0] t1_tx_mem_3;
    wire _3472;
    wire _3473;
    reg [15:0] t1_tx_mem_2;
    wire _3466;
    wire _3467;
    reg [15:0] t1_tx_mem_1;
    wire [1:0] _1641;
    wire [1:0] _1642;
    wire [1:0] _42;
    reg [1:0] t1_tx_wr;
    wire _3460;
    wire _3461;
    wire [15:0] _43;
    wire _493;
    wire _494;
    reg [15:0] t1_rx_mem_3;
    wire _487;
    wire _488;
    reg [15:0] t1_rx_mem_2;
    wire _481;
    wire _482;
    reg [15:0] t1_rx_mem_1;
    wire [1:0] _1644;
    wire [1:0] _1645;
    wire [1:0] _44;
    reg [1:0] t1_rx_wr;
    wire _475;
    wire _476;
    wire [15:0] _1883;
    wire [31:0] _1885;
    wire [23:0] _1879;
    wire [31:0] _1881;
    wire [27:0] _1875;
    wire [31:0] _1877;
    wire [29:0] _1871;
    wire [31:0] _1873;
    wire [31:0] _1869;
    wire [31:0] _1868;
    wire _1867;
    wire [31:0] _1870;
    wire _1866;
    wire [31:0] _1874;
    wire _1865;
    wire [31:0] _1878;
    wire _1864;
    wire [31:0] _1882;
    wire _1863;
    wire [31:0] _1886;
    wire [15:0] _1887;
    wire [15:0] _1888;
    wire [15:0] _1889;
    wire [15:0] _1859;
    wire [31:0] _1860;
    wire [23:0] _1855;
    wire [31:0] _1856;
    wire [27:0] _1851;
    wire [31:0] _1852;
    wire [29:0] _1847;
    wire [31:0] _1848;
    wire [30:0] _1843;
    wire [31:0] _1844;
    wire [31:0] _1841;
    wire _1839;
    wire [31:0] _1845;
    wire _1838;
    wire [31:0] _1849;
    wire _1837;
    wire [31:0] _1853;
    wire _1836;
    wire [31:0] _1857;
    wire [4:0] _1834;
    wire _1835;
    wire [31:0] _1861;
    wire [15:0] _1862;
    wire [15:0] _1890;
    wire [15:0] _1825;
    wire [31:0] _1827;
    wire [23:0] _1821;
    wire [31:0] _1823;
    wire [27:0] _1817;
    wire [31:0] _1819;
    wire [29:0] _1813;
    wire [31:0] _1815;
    wire _1809;
    wire [31:0] _1812;
    wire _1808;
    wire [31:0] _1816;
    wire _1807;
    wire [31:0] _1820;
    wire _1806;
    wire [31:0] _1824;
    wire _1805;
    wire [31:0] _1828;
    wire [15:0] _1829;
    wire [15:0] _1830;
    wire [15:0] _1831;
    wire [15:0] _1801;
    wire [31:0] _1802;
    wire [23:0] _1797;
    wire [31:0] _1798;
    wire [27:0] _1793;
    wire [31:0] _1794;
    wire [29:0] _1789;
    wire [31:0] _1790;
    wire [30:0] _1785;
    wire [31:0] _1786;
    wire [15:0] _1408;
    wire [31:0] _1410;
    wire [23:0] _1404;
    wire [31:0] _1406;
    wire [27:0] _1400;
    wire [31:0] _1402;
    wire [29:0] _1396;
    wire [31:0] _1398;
    wire _1392;
    wire [31:0] _1395;
    wire _1391;
    wire [31:0] _1399;
    wire _1390;
    wire [31:0] _1403;
    wire _1389;
    wire [31:0] _1407;
    wire _1388;
    wire [31:0] _1411;
    wire [15:0] _1412;
    wire [15:0] _1413;
    wire [15:0] _1735;
    wire [15:0] _1730;
    wire [31:0] _1732;
    wire [23:0] _1726;
    wire [31:0] _1728;
    wire [27:0] _1722;
    wire [31:0] _1724;
    wire [29:0] _1718;
    wire [31:0] _1720;
    wire [30:0] _1714;
    wire [31:0] _1716;
    wire [31:0] _1713;
    wire _1711;
    wire [31:0] _1717;
    wire _1710;
    wire [31:0] _1721;
    wire _1709;
    wire [31:0] _1725;
    wire _1708;
    wire [31:0] _1729;
    wire _1707;
    wire [31:0] _1733;
    wire [15:0] _1734;
    wire [15:0] _1736;
    wire [15:0] _1703;
    wire [31:0] _1704;
    wire [23:0] _1699;
    wire [31:0] _1700;
    wire [27:0] _1695;
    wire [31:0] _1696;
    wire [29:0] _1691;
    wire [31:0] _1692;
    wire [30:0] _1687;
    wire [31:0] _1688;
    wire _1556;
    wire _1553;
    wire _1552;
    wire _1551;
    wire _1550;
    wire _1549;
    wire _1548;
    wire _1547;
    wire _1546;
    reg _1554;
    wire _1557;
    wire _1544;
    wire _1541;
    wire _1540;
    wire _1539;
    wire _1538;
    wire _1537;
    wire _1536;
    wire _1535;
    wire _1534;
    wire [2:0] _1533;
    reg _1542;
    wire _1545;
    wire [4:0] _1529;
    wire _1530;
    wire _1527;
    wire _1526;
    wire _1525;
    wire _1524;
    wire _1523;
    wire _1522;
    wire _1521;
    wire _1520;
    wire [2:0] _1519;
    reg _1528;
    wire _1531;
    wire [4:0] _1515;
    wire _1516;
    wire _1513;
    wire _1512;
    wire _1511;
    wire _1510;
    wire _1509;
    wire _1508;
    wire _1507;
    wire _1506;
    wire [2:0] _1505;
    reg _1514;
    wire _1517;
    wire [4:0] _1501;
    wire _1502;
    wire _1499;
    wire _1498;
    wire _1497;
    wire _1496;
    wire _1495;
    wire _1494;
    wire _1493;
    wire _1492;
    wire [2:0] _1491;
    reg _1500;
    wire _1503;
    wire [4:0] _1487;
    wire _1488;
    wire _1485;
    wire _1484;
    wire _1483;
    wire _1482;
    wire _1481;
    wire _1480;
    wire _1479;
    wire _1478;
    wire [2:0] _1476;
    wire [2:0] _1477;
    reg _1486;
    wire _1489;
    wire [4:0] _1473;
    wire _1474;
    wire _1471;
    wire _1470;
    wire _1469;
    wire _1468;
    wire _1467;
    wire _1466;
    wire _1465;
    wire _1464;
    wire [2:0] _1463;
    reg _1472;
    wire _1475;
    wire [4:0] _1459;
    wire _1460;
    wire _1457;
    wire _1456;
    wire _1455;
    wire _1454;
    wire _1453;
    wire _1452;
    wire _1451;
    wire _1450;
    wire [2:0] _1448;
    wire [2:0] _1650;
    wire [6:0] _1647;
    wire _1648;
    wire _1646;
    wire _1649;
    wire [2:0] _1651;
    wire [2:0] _45;
    reg [2:0] cfg_t1_in_base;
    wire [2:0] _1449;
    reg _1458;
    wire _1461;
    wire [7:0] _1558;
    wire [15:0] _1559;
    wire [1:0] _1446;
    reg [15:0] _1567;
    wire [31:0] _1685;
    wire _1684;
    wire [31:0] _1689;
    wire _1683;
    wire [31:0] _1693;
    wire _1682;
    wire [31:0] _1697;
    wire _1681;
    wire [31:0] _1701;
    wire _1680;
    wire [31:0] _1705;
    wire [15:0] _1706;
    wire [15:0] _1737;
    wire [15:0] _1739;
    wire [15:0] _1678;
    wire _1661;
    wire [15:0] _1674;
    wire [15:0] _1675;
    wire _1659;
    wire [15:0] _1676;
    wire _1658;
    wire [15:0] _1679;
    wire _1656;
    wire [15:0] _1740;
    wire [15:0] _1741;
    wire [15:0] _1742;
    wire [15:0] _1743;
    wire [15:0] _1745;
    wire [15:0] _46;
    wire [15:0] _47;
    reg [15:0] t1_isr;
    wire [31:0] _1783;
    wire _1781;
    wire [31:0] _1787;
    wire _1780;
    wire [31:0] _1791;
    wire _1779;
    wire [31:0] _1795;
    wire _1778;
    wire [31:0] _1799;
    wire [4:0] _1762;
    wire [5:0] _1759;
    wire [5:0] _1758;
    wire [5:0] _1760;
    wire [5:0] _1757;
    wire _1761;
    wire [4:0] _1764;
    wire [5:0] _1263;
    wire [5:0] _1261;
    wire [5:0] _1254;
    wire [5:0] _1262;
    wire _1264;
    wire _1265;
    wire _1249;
    wire _1248;
    wire _1250;
    wire _1266;
    wire [4:0] _1766;
    wire [4:0] _1755;
    wire _1749;
    wire [4:0] _1751;
    wire [4:0] _1752;
    wire _1748;
    wire [4:0] _1753;
    wire _1747;
    wire [4:0] _1756;
    wire _1746;
    wire [4:0] _1767;
    wire [4:0] _1768;
    wire [4:0] _1769;
    wire [4:0] _1770;
    wire [4:0] _1772;
    wire [4:0] _48;
    wire [4:0] _49;
    reg [4:0] t1_isr_count;
    wire [4:0] _1776;
    wire _1777;
    wire [31:0] _1803;
    wire [15:0] _1804;
    wire _1383;
    wire [15:0] _1832;
    wire _1774;
    wire [15:0] _1891;
    wire [15:0] _50;
    reg [15:0] t1_rx_mem_0;
    wire [1:0] _1918;
    wire _1915;
    wire _1910;
    wire _1911;
    wire _1905;
    wire _1903;
    wire _1906;
    wire _1907;
    wire _1899;
    wire _1900;
    wire [6:0] _1895;
    wire _1896;
    wire _1892;
    wire _1893;
    wire _1894;
    wire _1897;
    wire _1901;
    wire _51;
    wire _1908;
    wire _1912;
    wire _1916;
    wire [1:0] _1919;
    wire [1:0] _52;
    reg [1:0] t1_rx_rd;
    reg [15:0] _496;
    wire _386;
    wire _387;
    reg [15:0] t0_rx_mem_3;
    wire _380;
    wire _381;
    reg [15:0] t0_rx_mem_2;
    wire _374;
    wire _375;
    reg [15:0] t0_rx_mem_1;
    wire [1:0] _1921;
    wire [1:0] _1922;
    wire [1:0] _53;
    reg [1:0] t0_rx_wr;
    wire _368;
    wire _369;
    wire [15:0] _3331;
    wire [31:0] _3333;
    wire [23:0] _3327;
    wire [31:0] _3329;
    wire [27:0] _3323;
    wire [31:0] _3325;
    wire [29:0] _3319;
    wire [31:0] _3321;
    wire _3315;
    wire [31:0] _3318;
    wire _3314;
    wire [31:0] _3322;
    wire _3313;
    wire [31:0] _3326;
    wire _3312;
    wire [31:0] _3330;
    wire _3311;
    wire [31:0] _3334;
    wire [15:0] _3335;
    wire [15:0] _3336;
    wire [15:0] _3337;
    wire [15:0] _3307;
    wire [31:0] _3308;
    wire [23:0] _3303;
    wire [31:0] _3304;
    wire [27:0] _3299;
    wire [31:0] _3300;
    wire [29:0] _3295;
    wire [31:0] _3296;
    wire [30:0] _3291;
    wire [31:0] _3292;
    wire [31:0] _3289;
    wire _3287;
    wire [31:0] _3293;
    wire _3286;
    wire [31:0] _3297;
    wire _3285;
    wire [31:0] _3301;
    wire _3284;
    wire [31:0] _3305;
    wire [4:0] _3282;
    wire _3283;
    wire [31:0] _3309;
    wire [15:0] _3310;
    wire [15:0] _3338;
    wire [15:0] _3273;
    wire [31:0] _3275;
    wire [23:0] _3269;
    wire [31:0] _3271;
    wire [27:0] _3265;
    wire [31:0] _3267;
    wire [29:0] _3261;
    wire [31:0] _3263;
    wire _3257;
    wire [31:0] _3260;
    wire _3256;
    wire [31:0] _3264;
    wire _3255;
    wire [31:0] _3268;
    wire _3254;
    wire [31:0] _3272;
    wire _3253;
    wire [31:0] _3276;
    wire [15:0] _3277;
    wire [15:0] _3278;
    wire [15:0] _3279;
    wire [15:0] _3249;
    wire [31:0] _3250;
    wire [23:0] _3245;
    wire [31:0] _3246;
    wire [27:0] _3241;
    wire [31:0] _3242;
    wire [29:0] _3237;
    wire [31:0] _3238;
    wire [30:0] _3233;
    wire [31:0] _3234;
    wire [15:0] _883;
    wire [31:0] _885;
    wire [23:0] _879;
    wire [31:0] _881;
    wire [27:0] _875;
    wire [31:0] _877;
    wire [29:0] _871;
    wire [31:0] _873;
    wire _867;
    wire [31:0] _870;
    wire _866;
    wire [31:0] _874;
    wire _865;
    wire [31:0] _878;
    wire _864;
    wire [31:0] _882;
    wire _863;
    wire [31:0] _886;
    wire [15:0] _887;
    wire [15:0] _888;
    wire [15:0] _3183;
    wire [15:0] _3178;
    wire [31:0] _3180;
    wire [23:0] _3174;
    wire [31:0] _3176;
    wire [27:0] _3170;
    wire [31:0] _3172;
    wire [29:0] _3166;
    wire [31:0] _3168;
    wire [30:0] _3162;
    wire [31:0] _3164;
    wire [31:0] _3161;
    wire _3159;
    wire [31:0] _3165;
    wire _3158;
    wire [31:0] _3169;
    wire _3157;
    wire [31:0] _3173;
    wire _3156;
    wire [31:0] _3177;
    wire _3155;
    wire [31:0] _3181;
    wire [15:0] _3182;
    wire [15:0] _3184;
    wire [15:0] _3151;
    wire [31:0] _3152;
    wire [23:0] _3147;
    wire [31:0] _3148;
    wire [27:0] _3143;
    wire [31:0] _3144;
    wire [29:0] _3139;
    wire [31:0] _3140;
    wire [30:0] _3135;
    wire [31:0] _3136;
    wire _1031;
    wire _1028;
    wire _1027;
    wire _1026;
    wire _1025;
    wire _1024;
    wire _1023;
    wire _1022;
    wire _1021;
    reg _1029;
    wire _1032;
    wire _1019;
    wire _1016;
    wire _1015;
    wire _1014;
    wire _1013;
    wire _1012;
    wire _1011;
    wire _1010;
    wire _1009;
    wire [2:0] _1008;
    reg _1017;
    wire _1020;
    wire _1005;
    wire _1002;
    wire _1001;
    wire _1000;
    wire _999;
    wire _998;
    wire _997;
    wire _996;
    wire _995;
    wire [2:0] _994;
    reg _1003;
    wire _1006;
    wire _991;
    wire _988;
    wire _987;
    wire _986;
    wire _985;
    wire _984;
    wire _983;
    wire _982;
    wire _981;
    wire [2:0] _980;
    reg _989;
    wire _992;
    wire _977;
    wire _974;
    wire _973;
    wire _972;
    wire _971;
    wire _970;
    wire _969;
    wire _968;
    wire _967;
    wire [2:0] _966;
    reg _975;
    wire _978;
    wire _963;
    wire _960;
    wire _959;
    wire _958;
    wire _957;
    wire _956;
    wire _955;
    wire _954;
    wire _953;
    wire [2:0] _952;
    reg _961;
    wire _964;
    wire _949;
    wire _946;
    wire _945;
    wire _944;
    wire _943;
    wire _942;
    wire _941;
    wire _940;
    wire _939;
    wire [2:0] _938;
    reg _947;
    wire _950;
    wire _935;
    wire _932;
    wire _931;
    wire _930;
    wire _929;
    wire _928;
    wire _927;
    wire _926;
    wire _668;
    wire _667;
    wire _666;
    wire [1:0] _665;
    reg _669;
    wire _663;
    wire _662;
    wire _661;
    wire [1:0] _660;
    reg _664;
    wire _658;
    wire _657;
    wire _656;
    wire [1:0] _655;
    reg _659;
    wire _653;
    wire _652;
    wire _651;
    wire [1:0] _650;
    reg _654;
    wire _648;
    wire _647;
    wire _646;
    wire [1:0] _645;
    reg _649;
    wire _643;
    wire _642;
    wire _641;
    wire [1:0] _640;
    reg _644;
    wire _638;
    wire _637;
    wire _636;
    wire [1:0] _635;
    reg _639;
    wire _633;
    wire [7:0] _149;
    wire _3091;
    wire _3090;
    wire _3089;
    wire _3088;
    wire _3087;
    wire _3086;
    wire _3085;
    wire _3084;
    reg _3092;
    wire _3083;
    wire [3:0] _3081;
    wire [2:0] _3078;
    wire [3:0] _3079;
    wire _3082;
    wire _3093;
    wire _3074;
    wire _3073;
    wire _3072;
    wire _3071;
    wire _3070;
    wire _3069;
    wire _3068;
    wire _3067;
    reg _3075;
    wire _3066;
    wire [3:0] _3064;
    wire [2:0] _3061;
    wire [3:0] _3062;
    wire _3065;
    wire _3076;
    wire _3057;
    wire _3056;
    wire _3055;
    wire _3054;
    wire _3053;
    wire _3052;
    wire _3051;
    wire _3050;
    reg _3058;
    wire _3049;
    wire [3:0] _3047;
    wire [2:0] _3044;
    wire [3:0] _3045;
    wire _3048;
    wire _3059;
    wire _3040;
    wire _3039;
    wire _3038;
    wire _3037;
    wire _3036;
    wire _3035;
    wire _3034;
    wire _3033;
    reg _3041;
    wire _3032;
    wire [3:0] _3030;
    wire [2:0] _3027;
    wire [3:0] _3028;
    wire _3031;
    wire _3042;
    wire _3023;
    wire _3022;
    wire _3021;
    wire _3020;
    wire _3019;
    wire _3018;
    wire _3017;
    wire _3016;
    reg _3024;
    wire _3015;
    wire [3:0] _3013;
    wire [2:0] _3010;
    wire [3:0] _3011;
    wire _3014;
    wire _3025;
    wire _3006;
    wire _3005;
    wire _3004;
    wire _3003;
    wire _3002;
    wire _3001;
    wire _3000;
    wire _2999;
    reg _3007;
    wire _2998;
    wire [3:0] _2996;
    wire [2:0] _2993;
    wire [3:0] _2994;
    wire _2997;
    wire _3008;
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
    wire [3:0] _2979;
    wire [2:0] _2976;
    wire [3:0] _2977;
    wire _2980;
    wire _2991;
    wire _2972;
    wire _2971;
    wire _2970;
    wire _2969;
    wire _2968;
    wire _2967;
    wire _2966;
    wire [1:0] _2959;
    wire [3:0] _2960;
    wire [2:0] _2955;
    wire [3:0] _2956;
    wire [3:0] _2953;
    wire _2952;
    wire [3:0] _2957;
    wire _2951;
    wire [3:0] _2961;
    wire [2:0] _2948;
    wire [2:0] _2949;
    wire _2950;
    wire [3:0] _2963;
    wire [7:0] _2964;
    wire _2965;
    reg _2973;
    wire _2940;
    wire _2939;
    wire _2938;
    wire _2937;
    wire _2936;
    wire _2935;
    wire _2934;
    wire _2933;
    reg _2941;
    wire _2932;
    wire [2:0] _2929;
    wire [4:0] _2930;
    wire _2931;
    wire _2942;
    wire _2924;
    wire _2923;
    wire _2922;
    wire _2921;
    wire _2920;
    wire _2919;
    wire _2918;
    wire _2917;
    reg _2925;
    wire _2916;
    wire [2:0] _2913;
    wire [4:0] _2914;
    wire _2915;
    wire _2926;
    wire _2908;
    wire _2907;
    wire _2906;
    wire _2905;
    wire _2904;
    wire _2903;
    wire _2902;
    wire _2901;
    reg _2909;
    wire _2900;
    wire [2:0] _2897;
    wire [4:0] _2898;
    wire _2899;
    wire _2910;
    wire _2892;
    wire _2891;
    wire _2890;
    wire _2889;
    wire _2888;
    wire _2887;
    wire _2886;
    wire _2885;
    reg _2893;
    wire _2884;
    wire [2:0] _2881;
    wire [4:0] _2882;
    wire _2883;
    wire _2894;
    wire _2876;
    wire _2875;
    wire _2874;
    wire _2873;
    wire _2872;
    wire _2871;
    wire _2870;
    wire _2869;
    reg _2877;
    wire _2868;
    wire [2:0] _2865;
    wire [4:0] _2866;
    wire _2867;
    wire _2878;
    wire _2860;
    wire _2859;
    wire _2858;
    wire _2857;
    wire _2856;
    wire _2855;
    wire _2854;
    wire _2853;
    reg _2861;
    wire _2852;
    wire [2:0] _2849;
    wire [4:0] _2850;
    wire _2851;
    wire _2862;
    wire _2844;
    wire _2843;
    wire _2842;
    wire _2841;
    wire _2840;
    wire _2839;
    wire _2838;
    wire _2837;
    reg _2845;
    wire _2836;
    wire [2:0] _2833;
    wire [4:0] _2834;
    wire _2835;
    wire _2846;
    wire _2828;
    wire _2827;
    wire _2826;
    wire _2825;
    wire _2824;
    wire _2823;
    wire _2822;
    wire _2821;
    reg _2829;
    wire _2820;
    wire [2:0] _2817;
    wire [4:0] _2818;
    wire _2819;
    wire _2830;
    wire [7:0] _2943;
    wire _2810;
    wire _2809;
    wire _2808;
    wire _2807;
    wire _2806;
    wire _2805;
    wire _2804;
    wire _2803;
    reg _2811;
    wire _2802;
    wire [2:0] _2799;
    wire [3:0] _2800;
    wire _2801;
    wire _2812;
    wire _2795;
    wire _2794;
    wire _2793;
    wire _2792;
    wire _2791;
    wire _2790;
    wire _2789;
    wire _2788;
    reg _2796;
    wire _2787;
    wire [2:0] _2784;
    wire [3:0] _2785;
    wire _2786;
    wire _2797;
    wire _2780;
    wire _2779;
    wire _2778;
    wire _2777;
    wire _2776;
    wire _2775;
    wire _2774;
    wire _2773;
    reg _2781;
    wire _2772;
    wire [2:0] _2769;
    wire [3:0] _2770;
    wire _2771;
    wire _2782;
    wire _2765;
    wire _2764;
    wire _2763;
    wire _2762;
    wire _2761;
    wire _2760;
    wire _2759;
    wire _2758;
    reg _2766;
    wire _2757;
    wire [2:0] _2754;
    wire [3:0] _2755;
    wire _2756;
    wire _2767;
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
    wire [3:0] _2740;
    wire _2741;
    wire _2752;
    wire _2735;
    wire _2734;
    wire _2733;
    wire _2732;
    wire _2731;
    wire _2730;
    wire _2729;
    wire _2728;
    reg _2736;
    wire _2727;
    wire [2:0] _2724;
    wire [3:0] _2725;
    wire _2726;
    wire _2737;
    wire _2720;
    wire _2719;
    wire _2718;
    wire _2717;
    wire _2716;
    wire _2715;
    wire _2714;
    wire _2713;
    reg _2721;
    wire _2712;
    wire [2:0] _2709;
    wire [3:0] _2710;
    wire _2711;
    wire _2722;
    wire _2705;
    wire _2704;
    wire _2703;
    wire _2702;
    wire _2701;
    wire _2700;
    wire _2699;
    wire _2698;
    reg _2706;
    wire _2697;
    wire [3:0] _2695;
    wire [7:0] _432;
    wire [7:0] _1927;
    wire [6:0] _1924;
    wire _1925;
    wire _1923;
    wire _1926;
    wire [7:0] _1928;
    wire [7:0] _54;
    reg [7:0] cfg_t1_out_cfg;
    wire [2:0] _2692;
    wire [2:0] _2693;
    wire [3:0] _2694;
    wire _2696;
    wire _2707;
    wire [7:0] _2813;
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
    wire [3:0] _2676;
    wire _2677;
    wire _2688;
    wire _2671;
    wire _2670;
    wire _2669;
    wire _2668;
    wire _2667;
    wire _2666;
    wire _2665;
    wire _2664;
    reg _2672;
    wire _2663;
    wire [2:0] _2660;
    wire [3:0] _2661;
    wire _2662;
    wire _2673;
    wire _2656;
    wire _2655;
    wire _2654;
    wire _2653;
    wire _2652;
    wire _2651;
    wire _2650;
    wire _2649;
    reg _2657;
    wire _2648;
    wire [2:0] _2645;
    wire [3:0] _2646;
    wire _2647;
    wire _2658;
    wire _2641;
    wire _2640;
    wire _2639;
    wire _2638;
    wire _2637;
    wire _2636;
    wire _2635;
    wire _2634;
    reg _2642;
    wire _2633;
    wire [2:0] _2630;
    wire [3:0] _2631;
    wire _2632;
    wire _2643;
    wire _2626;
    wire _2625;
    wire _2624;
    wire _2623;
    wire _2622;
    wire _2621;
    wire _2620;
    wire _2619;
    reg _2627;
    wire _2618;
    wire [2:0] _2615;
    wire [3:0] _2616;
    wire _2617;
    wire _2628;
    wire _2611;
    wire _2610;
    wire _2609;
    wire _2608;
    wire _2607;
    wire _2606;
    wire _2605;
    wire _2604;
    reg _2612;
    wire _2603;
    wire [2:0] _2600;
    wire [3:0] _2601;
    wire _2602;
    wire _2613;
    wire _2596;
    wire _2595;
    wire _2594;
    wire _2593;
    wire _2592;
    wire _2591;
    wire _2590;
    wire _2589;
    reg _2597;
    wire _2588;
    wire [2:0] _2585;
    wire [3:0] _2586;
    wire _2587;
    wire _2598;
    wire _2581;
    wire _2580;
    wire _2579;
    wire _2578;
    wire _2577;
    wire _2576;
    wire _2575;
    wire _2574;
    reg _2582;
    wire _2570;
    wire [3:0] _2568;
    wire [7:0] _1933;
    wire [6:0] _1930;
    wire _1931;
    wire _1929;
    wire _1932;
    wire [7:0] _1934;
    wire [7:0] _55;
    reg [7:0] cfg_t1_set_cfg;
    wire [2:0] _2565;
    wire [2:0] _2566;
    wire [3:0] _2567;
    wire _2569;
    wire _2583;
    wire [7:0] _2689;
    wire _2523;
    wire _2522;
    wire _2521;
    wire _2520;
    wire _2519;
    wire _2518;
    wire _2517;
    wire _2516;
    reg _2524;
    wire _2515;
    wire [3:0] _2513;
    wire [2:0] _2510;
    wire [3:0] _2511;
    wire _2514;
    wire _2525;
    wire _2506;
    wire _2505;
    wire _2504;
    wire _2503;
    wire _2502;
    wire _2501;
    wire _2500;
    wire _2499;
    reg _2507;
    wire _2498;
    wire [3:0] _2496;
    wire [2:0] _2493;
    wire [3:0] _2494;
    wire _2497;
    wire _2508;
    wire _2489;
    wire _2488;
    wire _2487;
    wire _2486;
    wire _2485;
    wire _2484;
    wire _2483;
    wire _2482;
    reg _2490;
    wire _2481;
    wire [3:0] _2479;
    wire [2:0] _2476;
    wire [3:0] _2477;
    wire _2480;
    wire _2491;
    wire _2472;
    wire _2471;
    wire _2470;
    wire _2469;
    wire _2468;
    wire _2467;
    wire _2466;
    wire _2465;
    reg _2473;
    wire _2464;
    wire [3:0] _2462;
    wire [2:0] _2459;
    wire [3:0] _2460;
    wire _2463;
    wire _2474;
    wire _2455;
    wire _2454;
    wire _2453;
    wire _2452;
    wire _2451;
    wire _2450;
    wire _2449;
    wire _2448;
    reg _2456;
    wire _2447;
    wire [3:0] _2445;
    wire [2:0] _2442;
    wire [3:0] _2443;
    wire _2446;
    wire _2457;
    wire _2438;
    wire _2437;
    wire _2436;
    wire _2435;
    wire _2434;
    wire _2433;
    wire _2432;
    wire _2431;
    reg _2439;
    wire _2430;
    wire [3:0] _2428;
    wire [2:0] _2425;
    wire [3:0] _2426;
    wire _2429;
    wire _2440;
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
    wire [3:0] _2411;
    wire [2:0] _2408;
    wire [3:0] _2409;
    wire _2412;
    wire _2423;
    wire _2404;
    wire _2403;
    wire _2402;
    wire _2401;
    wire _2400;
    wire _2399;
    wire _2398;
    wire [1:0] _2391;
    wire [3:0] _2392;
    wire [2:0] _2387;
    wire [3:0] _2388;
    wire [3:0] _2385;
    wire _2384;
    wire [3:0] _2389;
    wire _2383;
    wire [3:0] _2393;
    wire [2:0] _2380;
    wire [2:0] _2381;
    wire _2382;
    wire [3:0] _2395;
    wire [7:0] _2396;
    wire _2397;
    reg _2405;
    wire _2372;
    wire _2371;
    wire _2370;
    wire _2369;
    wire _2368;
    wire _2367;
    wire _2366;
    wire _2365;
    reg _2373;
    wire _2364;
    wire [2:0] _2361;
    wire [4:0] _2362;
    wire _2363;
    wire _2374;
    wire _2356;
    wire _2355;
    wire _2354;
    wire _2353;
    wire _2352;
    wire _2351;
    wire _2350;
    wire _2349;
    reg _2357;
    wire _2348;
    wire [2:0] _2345;
    wire [4:0] _2346;
    wire _2347;
    wire _2358;
    wire _2340;
    wire _2339;
    wire _2338;
    wire _2337;
    wire _2336;
    wire _2335;
    wire _2334;
    wire _2333;
    reg _2341;
    wire _2332;
    wire [2:0] _2329;
    wire [4:0] _2330;
    wire _2331;
    wire _2342;
    wire _2324;
    wire _2323;
    wire _2322;
    wire _2321;
    wire _2320;
    wire _2319;
    wire _2318;
    wire _2317;
    reg _2325;
    wire _2316;
    wire [2:0] _2313;
    wire [4:0] _2314;
    wire _2315;
    wire _2326;
    wire _2308;
    wire _2307;
    wire _2306;
    wire _2305;
    wire _2304;
    wire _2303;
    wire _2302;
    wire _2301;
    reg _2309;
    wire _2300;
    wire [2:0] _2297;
    wire [4:0] _2298;
    wire _2299;
    wire _2310;
    wire _2292;
    wire _2291;
    wire _2290;
    wire _2289;
    wire _2288;
    wire _2287;
    wire _2286;
    wire _2285;
    reg _2293;
    wire _2284;
    wire [2:0] _2281;
    wire [4:0] _2282;
    wire _2283;
    wire _2294;
    wire _2276;
    wire _2275;
    wire _2274;
    wire _2273;
    wire _2272;
    wire _2271;
    wire _2270;
    wire _2269;
    reg _2277;
    wire _2268;
    wire [2:0] _2265;
    wire [4:0] _2266;
    wire _2267;
    wire _2278;
    wire _2260;
    wire _2259;
    wire _2258;
    wire _2257;
    wire _2256;
    wire _2255;
    wire _2254;
    wire _2253;
    reg _2261;
    wire _2252;
    wire [2:0] _2249;
    wire [4:0] _2250;
    wire _2251;
    wire _2262;
    wire [7:0] _2375;
    wire _2242;
    wire _2241;
    wire _2240;
    wire _2239;
    wire _2238;
    wire _2237;
    wire _2236;
    wire _2235;
    reg _2243;
    wire _2234;
    wire [2:0] _2231;
    wire [3:0] _2232;
    wire _2233;
    wire _2244;
    wire _2227;
    wire _2226;
    wire _2225;
    wire _2224;
    wire _2223;
    wire _2222;
    wire _2221;
    wire _2220;
    reg _2228;
    wire _2219;
    wire [2:0] _2216;
    wire [3:0] _2217;
    wire _2218;
    wire _2229;
    wire _2212;
    wire _2211;
    wire _2210;
    wire _2209;
    wire _2208;
    wire _2207;
    wire _2206;
    wire _2205;
    reg _2213;
    wire _2204;
    wire [2:0] _2201;
    wire [3:0] _2202;
    wire _2203;
    wire _2214;
    wire _2197;
    wire _2196;
    wire _2195;
    wire _2194;
    wire _2193;
    wire _2192;
    wire _2191;
    wire _2190;
    reg _2198;
    wire _2189;
    wire [2:0] _2186;
    wire [3:0] _2187;
    wire _2188;
    wire _2199;
    wire _2182;
    wire _2181;
    wire _2180;
    wire _2179;
    wire _2178;
    wire _2177;
    wire _2176;
    wire _2175;
    reg _2183;
    wire _2174;
    wire [2:0] _2171;
    wire [3:0] _2172;
    wire _2173;
    wire _2184;
    wire _2167;
    wire _2166;
    wire _2165;
    wire _2164;
    wire _2163;
    wire _2162;
    wire _2161;
    wire _2160;
    reg _2168;
    wire _2159;
    wire [2:0] _2156;
    wire [3:0] _2157;
    wire _2158;
    wire _2169;
    wire _2152;
    wire _2151;
    wire _2150;
    wire _2149;
    wire _2148;
    wire _2147;
    wire _2146;
    wire _2145;
    reg _2153;
    wire _2144;
    wire [2:0] _2141;
    wire [3:0] _2142;
    wire _2143;
    wire _2154;
    wire _2137;
    wire _2136;
    wire _2135;
    wire _2134;
    wire _2133;
    wire _2132;
    wire _2131;
    wire _2130;
    reg _2138;
    wire _2114;
    wire [3:0] _2112;
    wire [7:0] _1939;
    wire [6:0] _1936;
    wire _1937;
    wire _1935;
    wire _1938;
    wire [7:0] _1940;
    wire [7:0] _56;
    reg [7:0] cfg_t0_out_cfg;
    wire [2:0] _2109;
    wire [2:0] _2110;
    wire [3:0] _2111;
    wire _2113;
    wire _2139;
    wire [7:0] _2245;
    wire _2103;
    wire _2102;
    wire _2101;
    wire _2100;
    wire _2099;
    wire _2098;
    wire _2097;
    wire _2096;
    reg _2104;
    wire _2095;
    wire [2:0] _2092;
    wire [3:0] _2093;
    wire _2094;
    wire _2105;
    wire _2088;
    wire _2087;
    wire _2086;
    wire _2085;
    wire _2084;
    wire _2083;
    wire _2082;
    wire _2081;
    reg _2089;
    wire _2080;
    wire [2:0] _2077;
    wire [3:0] _2078;
    wire _2079;
    wire _2090;
    wire _2073;
    wire _2072;
    wire _2071;
    wire _2070;
    wire _2069;
    wire _2068;
    wire _2067;
    wire _2066;
    reg _2074;
    wire _2065;
    wire [2:0] _2062;
    wire [3:0] _2063;
    wire _2064;
    wire _2075;
    wire _2058;
    wire _2057;
    wire _2056;
    wire _2055;
    wire _2054;
    wire _2053;
    wire _2052;
    wire _2051;
    reg _2059;
    wire _2050;
    wire [2:0] _2047;
    wire [3:0] _2048;
    wire _2049;
    wire _2060;
    wire _2043;
    wire _2042;
    wire _2041;
    wire _2040;
    wire _2039;
    wire _2038;
    wire _2037;
    wire _2036;
    reg _2044;
    wire _2035;
    wire [2:0] _2032;
    wire [3:0] _2033;
    wire _2034;
    wire _2045;
    wire _2028;
    wire _2027;
    wire _2026;
    wire _2025;
    wire _2024;
    wire _2023;
    wire _2022;
    wire _2021;
    reg _2029;
    wire _2020;
    wire [2:0] _2017;
    wire [3:0] _2018;
    wire _2019;
    wire _2030;
    wire _2013;
    wire _2012;
    wire _2011;
    wire _2010;
    wire _2009;
    wire _2008;
    wire _2007;
    wire _2006;
    reg _2014;
    wire _2005;
    wire [2:0] _2002;
    wire [3:0] _2003;
    wire _2004;
    wire _2015;
    wire _1998;
    wire _1997;
    wire _1996;
    wire _1995;
    wire _1994;
    wire _1993;
    wire _1992;
    wire _1991;
    reg _1999;
    wire _1987;
    wire [3:0] _1985;
    wire [7:0] _1945;
    wire [6:0] _1942;
    wire _1943;
    wire _1941;
    wire _1944;
    wire [7:0] _1946;
    wire [7:0] _57;
    reg [7:0] cfg_t0_set_cfg;
    wire [2:0] _1982;
    wire [2:0] _1983;
    wire [3:0] _1984;
    wire _1986;
    wire _2000;
    wire [7:0] _2106;
    wire _1979;
    wire _1976;
    wire _1977;
    wire _1980;
    wire [7:0] _2107;
    wire _1972;
    wire _1973;
    wire _1969;
    wire _1970;
    wire _1974;
    wire [7:0] _2246;
    wire [1:0] _1964;
    wire _1966;
    wire _1962;
    wire _1963;
    wire _1967;
    wire [7:0] _2376;
    wire _2377;
    wire [1:0] _1958;
    wire [3:0] _1959;
    wire [5:0] _1951;
    wire [6:0] _1948;
    wire _1949;
    wire _1947;
    wire _1950;
    wire [5:0] _1952;
    wire [5:0] _58;
    reg [5:0] cfg_t0_sideset;
    wire [2:0] _1954;
    wire [2:0] _1955;
    wire [3:0] _1956;
    wire _1960;
    wire _2406;
    wire [7:0] _2526;
    wire [7:0] _2527;
    wire [7:0] _2528;
    wire [7:0] _2529;
    wire [7:0] _59;
    wire _2562;
    wire _2559;
    wire _2560;
    wire _2563;
    wire [7:0] _2690;
    wire _2555;
    wire _2556;
    wire _2552;
    wire _2553;
    wire _2557;
    wire [7:0] _2814;
    wire [1:0] _2547;
    wire _2549;
    wire _2545;
    wire _2546;
    wire _2550;
    wire [7:0] _2944;
    wire _2945;
    wire [1:0] _2541;
    wire [3:0] _2542;
    wire [5:0] _2534;
    wire [6:0] _2531;
    wire _2532;
    wire _2530;
    wire _2533;
    wire [5:0] _2535;
    wire [5:0] _60;
    reg [5:0] cfg_t1_sideset;
    wire [2:0] _2537;
    wire [2:0] _2538;
    wire [3:0] _2539;
    wire _2543;
    wire _2974;
    wire [7:0] _3094;
    wire [7:0] _3095;
    wire [7:0] _3096;
    wire [7:0] _3097;
    wire [7:0] _61;
    wire [7:0] _62;
    reg [7:0] pin_out;
    wire _632;
    wire [7:0] _628;
    reg [7:0] pins_sync1;
    reg [7:0] pins_sync2;
    wire [7:0] _629;
    wire [7:0] _3102;
    wire [6:0] _3099;
    wire _3100;
    wire _3098;
    wire _3101;
    wire [7:0] _3103;
    wire [7:0] _63;
    reg [7:0] cfg_sync_bypass;
    wire [7:0] _65;
    wire [7:0] _622;
    wire [7:0] _630;
    wire _631;
    wire [6:0] _3105;
    wire _3106;
    wire _3104;
    wire _3107;
    wire [15:0] _3108;
    wire [15:0] _66;
    reg [15:0] cfg_pin_modes;
    wire [1:0] _621;
    reg _634;
    wire [7:0] _670;
    wire _925;
    wire [2:0] _3113;
    wire [6:0] _3110;
    wire _3111;
    wire _3109;
    wire _3112;
    wire [2:0] _3114;
    wire [2:0] _67;
    reg [2:0] cfg_t0_in_base;
    wire [2:0] _924;
    reg _933;
    wire _936;
    wire [7:0] _1033;
    wire [15:0] _1034;
    wire [1:0] _921;
    reg [15:0] _1042;
    wire [31:0] _3133;
    wire _3132;
    wire [31:0] _3137;
    wire _3131;
    wire [31:0] _3141;
    wire _3130;
    wire [31:0] _3145;
    wire _3129;
    wire [31:0] _3149;
    wire _3128;
    wire [31:0] _3153;
    wire [15:0] _3154;
    wire [15:0] _3185;
    wire [15:0] _3187;
    wire [15:0] _3126;
    wire _3121;
    wire [15:0] _3122;
    wire [15:0] _3123;
    wire _3119;
    wire [15:0] _3124;
    wire _3118;
    wire [15:0] _3127;
    wire _3116;
    wire [15:0] _3188;
    wire [15:0] _3189;
    wire [15:0] _3190;
    wire [15:0] _3191;
    wire [15:0] _3193;
    wire [15:0] _68;
    wire [15:0] _69;
    reg [15:0] t0_isr;
    wire [31:0] _3231;
    wire _3229;
    wire [31:0] _3235;
    wire _3228;
    wire [31:0] _3239;
    wire _3227;
    wire [31:0] _3243;
    wire _3226;
    wire [31:0] _3247;
    wire [4:0] _3210;
    wire [5:0] _3207;
    wire [5:0] _3206;
    wire [5:0] _3208;
    wire _3209;
    wire [4:0] _3212;
    wire [5:0] _738;
    wire [5:0] _736;
    wire [5:0] _729;
    wire [5:0] _737;
    wire _739;
    wire _740;
    wire _724;
    wire _723;
    wire _725;
    wire _741;
    wire [4:0] _3214;
    wire [4:0] _3203;
    wire _3197;
    wire [4:0] _3199;
    wire [4:0] _3200;
    wire _3196;
    wire [4:0] _3201;
    wire _3195;
    wire [4:0] _3204;
    wire _3194;
    wire [4:0] _3215;
    wire [4:0] _3216;
    wire [4:0] _3217;
    wire [4:0] _3218;
    wire [4:0] _3220;
    wire [4:0] _70;
    wire [4:0] _71;
    reg [4:0] t0_isr_count;
    wire [4:0] _3224;
    wire _3225;
    wire [31:0] _3251;
    wire [15:0] _3252;
    wire _858;
    wire [15:0] _3280;
    wire _3222;
    wire [15:0] _3339;
    wire [15:0] _72;
    reg [15:0] t0_rx_mem_0;
    wire [1:0] _3369;
    wire _3366;
    wire _3361;
    wire _3362;
    wire _3357;
    wire _3353;
    wire _3351;
    wire _3354;
    wire _3355;
    wire _3347;
    wire _3348;
    wire [6:0] _3343;
    wire [6:0] _311;
    wire _3344;
    wire _3340;
    wire _3341;
    wire _1152;
    wire _1153;
    wire _3342;
    wire _3345;
    wire _3349;
    wire _73;
    wire _3356;
    wire _3358;
    wire _3359;
    wire _3363;
    wire _3367;
    wire [1:0] _3370;
    wire [1:0] _74;
    reg [1:0] t0_rx_rd;
    reg [15:0] _389;
    wire [15:0] _3384;
    wire [15:0] _3385;
    wire [9:0] _3383;
    wire _3382;
    wire _3378;
    wire _3376;
    wire _3379;
    wire _3373;
    wire _3371;
    wire _3374;
    wire _3380;
    wire _3381;
    wire _75;
    wire [15:0] _3391;
    wire [15:0] _76;
    wire [15:0] _77;
    wire _1615;
    wire _1616;
    wire [15:0] _3455;
    wire [15:0] _3456;
    reg [15:0] t1_tx_mem_0;
    wire [1:0] _3425;
    wire _3419;
    wire _3396;
    wire _3393;
    wire _3394;
    wire _3395;
    wire _3397;
    wire _3415;
    wire _3418;
    wire _78;
    wire _3420;
    wire [1:0] _3426;
    wire [1:0] _79;
    reg [1:0] t1_tx_rd;
    reg [15:0] _3481;
    wire _1227;
    wire _3413;
    wire [4:0] _447;
    wire [4:0] _3431;
    wire [6:0] _3428;
    wire _3429;
    wire _3427;
    wire _3430;
    wire [4:0] _3432;
    wire [4:0] _80;
    reg [4:0] cfg_t1_threshold;
    wire [4:0] _3407;
    wire [4:0] _1258;
    wire [3:0] _1255;
    wire _1257;
    wire [4:0] _1260;
    wire [5:0] _3404;
    wire [5:0] _3403;
    wire [5:0] _3405;
    wire _3406;
    wire [4:0] _3409;
    wire _3410;
    wire _3411;
    wire _3399;
    wire _3400;
    wire _3401;
    wire _3412;
    wire _3414;
    wire [4:0] _3449;
    wire _1224;
    wire [4:0] _3446;
    wire _3440;
    wire [4:0] _3442;
    wire [4:0] _3443;
    wire _3438;
    wire [4:0] _3444;
    wire _3437;
    wire [4:0] _3447;
    wire _3436;
    wire [4:0] _3450;
    wire [4:0] _3434;
    wire [4:0] _3451;
    wire [4:0] _3452;
    wire [4:0] _3453;
    wire [4:0] _3454;
    wire [4:0] _81;
    wire [4:0] _82;
    reg [4:0] t1_osr_count;
    wire _1243;
    wire _1244;
    wire _1238;
    wire _1237;
    wire _1239;
    wire _1245;
    wire _3416;
    wire _3417;
    wire [15:0] _3482;
    wire [15:0] _3551;
    wire [15:0] _3552;
    wire [15:0] _3553;
    wire [15:0] _3555;
    wire [15:0] _83;
    wire [15:0] _84;
    reg [15:0] t1_osr;
    wire [15:0] _1414;
    wire [5:0] _3560;
    wire [6:0] _3557;
    wire _3558;
    wire _3556;
    wire _3559;
    wire [5:0] _3561;
    wire [5:0] _85;
    reg [5:0] cfg_t1_shift;
    wire _1382;
    wire [15:0] _1445;
    wire [1:0] _3576;
    wire _3578;
    wire [15:0] _3579;
    wire _3572;
    wire [15:0] _3573;
    wire [15:0] _3574;
    wire _3568;
    wire [15:0] _3569;
    wire _3566;
    wire [15:0] _3570;
    wire _3565;
    wire [15:0] _3575;
    wire _3564;
    wire [15:0] _3580;
    wire _3563;
    wire [15:0] _3587;
    wire [15:0] _3588;
    wire [15:0] _3589;
    wire [15:0] _3590;
    wire [15:0] _3592;
    wire [15:0] _86;
    wire [15:0] _87;
    reg [15:0] t1_y;
    reg [15:0] _1673;
    wire _3602;
    wire [15:0] _3603;
    wire [2:0] _1348;
    wire _1350;
    wire [2:0] _1345;
    wire _1347;
    wire _1351;
    wire [15:0] _3604;
    wire [4:0] _2572;
    wire [15:0] _2573;
    wire [1:0] _1276;
    wire _3598;
    wire [15:0] _3599;
    wire _3596;
    wire [15:0] _3600;
    wire _3595;
    wire [15:0] _3605;
    wire _3594;
    wire [15:0] _3609;
    wire _3593;
    wire [15:0] _3615;
    wire [15:0] _3616;
    wire [15:0] _3617;
    wire [15:0] _3618;
    wire [15:0] _3620;
    wire [15:0] _88;
    wire [15:0] _89;
    reg [15:0] t1_x;
    wire _3624;
    wire _3625;
    wire _3626;
    wire [2:0] _3581;
    reg _3635;
    wire _3622;
    wire _3636;
    wire _3642;
    wire [7:0] _3650;
    reg [7:0] t1_pc;
    wire [7:0] _3651;
    wire [7:0] _3652;
    wire [7:0] _3653;
    wire [7:0] _3654;
    wire [7:0] _90;
    wire [7:0] _91;
    wire [7:0] _3659;
    wire _3655;
    wire [15:0] _3665;
    wire [15:0] _92;
    wire [2:0] _1192;
    wire _1194;
    wire _1208;
    wire _1221;
    wire _1229;
    wire _1235;
    wire _1246;
    wire _1268;
    wire _1269;
    wire _1270;
    wire [3:0] _3676;
    wire _1186;
    wire _1187;
    wire [3:0] _3679;
    wire _1181;
    wire [3:0] _3680;
    wire _1175;
    wire [3:0] _3682;
    wire [3:0] _93;
    wire [3:0] _94;
    reg [3:0] t1_delay_left;
    wire _1190;
    wire [15:0] _3694;
    wire [6:0] _3684;
    wire _3685;
    wire _3683;
    wire _3686;
    wire [15:0] _3687;
    wire [15:0] _95;
    reg [15:0] cfg_t1_clkdiv;
    wire _3692;
    wire [15:0] _3696;
    wire [15:0] _3690;
    wire [15:0] _3697;
    wire _3688;
    wire [15:0] _3699;
    wire [15:0] _96;
    reg [15:0] t1_div_count;
    wire _1180;
    wire _1168;
    wire _1167;
    wire _1169;
    reg t1_loaded;
    wire _1173;
    wire _1166;
    wire _1174;
    wire _1188;
    wire _1191;
    wire _3702;
    wire _3704;
    wire _3706;
    wire _3708;
    wire _97;
    wire _470;
    wire [2:0] _3710;
    wire [2:0] _3711;
    wire [2:0] _3714;
    wire [2:0] _98;
    reg [2:0] t1_rx_level;
    wire _1914;
    wire _3730;
    wire _3731;
    wire _1089;
    wire _3726;
    wire _3727;
    wire _3728;
    wire [9:0] _3719;
    wire [6:0] _3716;
    wire _3717;
    wire _3715;
    wire _3718;
    wire [9:0] _3720;
    wire [9:0] _99;
    reg [9:0] cfg_buf_end;
    wire _3723;
    wire _3724;
    wire _3722;
    wire _3725;
    wire _3729;
    wire _3732;
    wire _100;
    wire _3737;
    wire _3738;
    wire _3740;
    wire [9:0] _3743;
    wire [6:0] _3734;
    wire _3735;
    wire _3733;
    wire _3736;
    wire [9:0] _3745;
    wire [9:0] _101;
    reg [9:0] buf_ptr;
    wire _3754;
    wire _3755;
    wire [2:0] _3750;
    wire [6:0] _3747;
    wire _3748;
    wire _3746;
    wire _3749;
    wire [2:0] _3751;
    wire [2:0] _102;
    reg [2:0] cfg_buf_ctrl;
    wire [1:0] _1097;
    wire _3753;
    wire _3756;
    wire _3761;
    wire _3764;
    wire _3767;
    wire _103;
    wire _1092;
    wire _1105;
    wire _1109;
    wire [2:0] _3769;
    wire [2:0] _3770;
    wire [2:0] _3773;
    wire [2:0] _104;
    reg [2:0] t0_tx_level;
    wire _702;
    wire _1145;
    wire [4:0] _3778;
    wire [6:0] _3775;
    wire _3776;
    wire _3774;
    wire _3777;
    wire [4:0] _3779;
    wire [4:0] _105;
    reg [4:0] cfg_t0_threshold;
    wire [4:0] _1139;
    wire [4:0] _733;
    wire [3:0] _730;
    wire _732;
    wire [4:0] _735;
    wire [5:0] _1136;
    wire [5:0] _1135;
    wire [5:0] _1137;
    wire _1138;
    wire [4:0] _1141;
    wire _1142;
    wire _1143;
    wire _1131;
    wire _1132;
    wire _1133;
    wire _1144;
    wire _1146;
    wire [4:0] _3796;
    wire _699;
    wire [4:0] _3793;
    wire _3787;
    wire [4:0] _3789;
    wire [4:0] _3790;
    wire _3785;
    wire [4:0] _3791;
    wire _3784;
    wire [4:0] _3794;
    wire _3783;
    wire [4:0] _3797;
    wire [4:0] _3781;
    wire [4:0] _3798;
    wire [4:0] _3799;
    wire [4:0] _3800;
    wire [4:0] _3801;
    wire [4:0] _106;
    wire [4:0] _107;
    reg [4:0] t0_osr_count;
    wire _718;
    wire _719;
    wire _713;
    wire _712;
    wire _714;
    wire _720;
    wire _1148;
    wire _1149;
    wire [15:0] _3828;
    wire [15:0] _3897;
    wire [15:0] _3898;
    wire [15:0] _3899;
    wire [15:0] _3901;
    wire [15:0] _108;
    wire [15:0] _109;
    reg [15:0] t0_osr;
    wire [15:0] _889;
    wire [5:0] _3906;
    wire [6:0] _3903;
    wire _3904;
    wire _3902;
    wire _3905;
    wire [5:0] _3907;
    wire [5:0] _110;
    reg [5:0] cfg_t0_shift;
    wire _857;
    wire [15:0] _920;
    wire [1:0] _3922;
    wire _3924;
    wire [15:0] _3925;
    wire _3918;
    wire [15:0] _3919;
    wire [15:0] _3920;
    wire _3914;
    wire [15:0] _3915;
    wire _3912;
    wire [15:0] _3916;
    wire _3911;
    wire [15:0] _3921;
    wire _3910;
    wire [15:0] _3926;
    wire _3909;
    wire [15:0] _3933;
    wire [15:0] _3934;
    wire [15:0] _3935;
    wire [15:0] _3936;
    wire [15:0] _3938;
    wire [15:0] _111;
    wire [15:0] _112;
    reg [15:0] t0_y;
    reg [15:0] _2129;
    wire _3948;
    wire [15:0] _3949;
    wire [2:0] _823;
    wire _825;
    wire [2:0] _820;
    wire _822;
    wire _826;
    wire [15:0] _3950;
    wire [4:0] _1989;
    wire [15:0] _1990;
    wire [1:0] _751;
    wire _3944;
    wire [15:0] _3945;
    wire _3942;
    wire [15:0] _3946;
    wire _3941;
    wire [15:0] _3951;
    wire _3940;
    wire [15:0] _3955;
    wire _3939;
    wire [15:0] _3961;
    wire [15:0] _3962;
    wire [15:0] _3963;
    wire [15:0] _3964;
    wire [15:0] _3966;
    wire [15:0] _113;
    wire [15:0] _114;
    reg [15:0] t0_x;
    wire _3970;
    wire _3971;
    wire _3972;
    wire [2:0] _3927;
    reg _3981;
    wire _3968;
    wire _3982;
    wire _3988;
    wire [7:0] _3996;
    reg [7:0] t0_pc;
    wire [7:0] _3997;
    wire [7:0] _3998;
    wire [7:0] _3999;
    wire [7:0] _4000;
    wire [7:0] _115;
    wire [7:0] _116;
    wire [7:0] _4002;
    wire _4001;
    wire [15:0] _4008;
    wire [15:0] _117;
    wire [2:0] _617;
    wire _619;
    wire _683;
    wire _696;
    wire _704;
    wire _710;
    wire _721;
    wire _743;
    wire _744;
    wire _745;
    wire [3:0] _4019;
    wire _611;
    wire _612;
    wire [3:0] _4022;
    wire _606;
    wire [3:0] _4023;
    wire _600;
    wire [3:0] _4025;
    wire [3:0] _118;
    wire [3:0] _119;
    reg [3:0] t0_delay_left;
    wire _615;
    wire [15:0] _4037;
    wire [6:0] _4027;
    wire _4028;
    wire _4026;
    wire _4029;
    wire [15:0] _4030;
    wire [15:0] _120;
    reg [15:0] cfg_t0_clkdiv;
    wire _4035;
    wire [15:0] _4039;
    wire [15:0] _4033;
    wire [15:0] _4040;
    wire _4031;
    wire [15:0] _4042;
    wire [15:0] _121;
    reg [15:0] t0_div_count;
    wire _605;
    wire _593;
    wire [5:0] _422;
    wire [5:0] _4047;
    wire [6:0] _4044;
    wire _4045;
    wire _4043;
    wire _4046;
    wire [5:0] _4048;
    wire [5:0] _122;
    reg [5:0] cfg_load;
    wire [1:0] _590;
    wire [6:0] _586;
    wire _587;
    wire _585;
    wire _588;
    wire [1:0] _589;
    wire [1:0] _591;
    wire _592;
    wire _594;
    reg t0_loaded;
    wire _598;
    wire _584;
    wire _599;
    wire _613;
    wire _616;
    wire _4051;
    wire _4053;
    wire _4055;
    wire _4057;
    wire _123;
    wire _363;
    wire [2:0] _4059;
    wire [2:0] _4060;
    wire [2:0] _4063;
    wire [2:0] _124;
    reg [2:0] t0_rx_level;
    wire _3365;
    wire _4084;
    wire [15:0] _581;
    wire [2:0] _4082;
    wire [6:0] _577;
    wire _4080;
    wire _304;
    reg host_mosi_s1;
    reg host_mosi_s2;
    wire [22:0] _302;
    wire [22:0] _4064;
    wire [22:0] _4065;
    wire [22:0] _4066;
    wire [22:0] _125;
    reg [22:0] host_shift_in;
    wire [23:0] _309;
    wire [7:0] _310;
    wire _300;
    wire [7:0] _4067;
    wire [7:0] _4068;
    wire [7:0] _4069;
    wire [7:0] _126;
    reg [7:0] host_cmd;
    wire _575;
    wire [4:0] _569;
    wire [4:0] _4073;
    wire [4:0] _4070;
    wire _4071;
    wire [4:0] _4074;
    wire [4:0] _4075;
    wire [4:0] _4077;
    wire [4:0] _127;
    reg [4:0] host_bit_count;
    wire _570;
    wire _267;
    reg host_cs_n_s1;
    reg host_cs_n_s2;
    wire _294;
    reg host_sck_prev;
    wire _292;
    wire vdd;
    wire _129;
    wire _131;
    wire [7:0] _133;
    wire _272;
    reg host_sck_s1;
    reg host_sck_s2;
    wire _293;
    wire _295;
    wire _571;
    wire _4078;
    wire _4081;
    wire [2:0] _4083;
    wire [2:0] _134;
    reg [2:0] cfg_ctrl;
    wire _1629;
    wire _4085;
    wire _4087;
    wire _135;
    wire _1617;
    wire _1632;
    wire _1636;
    wire [2:0] _4089;
    wire [2:0] _4090;
    wire [2:0] _4093;
    wire [2:0] _136;
    reg [2:0] t1_tx_level;
    wire _4095;
    wire gnd;
    wire [7:0] _4107;
    assign _221 = pin_out[0:0];
    assign _222 = ~ _221;
    assign _219 = 2'b10;
    assign _218 = cfg_pin_modes[1:0];
    assign _220 = _218 == _219;
    assign _223 = _220 & _222;
    assign _216 = 2'b01;
    assign _215 = cfg_pin_modes[1:0];
    assign _217 = _215 == _216;
    assign _224 = _217 | _223;
    assign _211 = pin_out[1:1];
    assign _212 = ~ _211;
    assign _208 = cfg_pin_modes[3:2];
    assign _210 = _208 == _219;
    assign _213 = _210 & _212;
    assign _205 = cfg_pin_modes[3:2];
    assign _207 = _205 == _216;
    assign _214 = _207 | _213;
    assign _201 = pin_out[2:2];
    assign _202 = ~ _201;
    assign _198 = cfg_pin_modes[5:4];
    assign _200 = _198 == _219;
    assign _203 = _200 & _202;
    assign _195 = cfg_pin_modes[5:4];
    assign _197 = _195 == _216;
    assign _204 = _197 | _203;
    assign _191 = pin_out[3:3];
    assign _192 = ~ _191;
    assign _188 = cfg_pin_modes[7:6];
    assign _190 = _188 == _219;
    assign _193 = _190 & _192;
    assign _185 = cfg_pin_modes[7:6];
    assign _187 = _185 == _216;
    assign _194 = _187 | _193;
    assign _181 = pin_out[4:4];
    assign _182 = ~ _181;
    assign _178 = cfg_pin_modes[9:8];
    assign _180 = _178 == _219;
    assign _183 = _180 & _182;
    assign _175 = cfg_pin_modes[9:8];
    assign _177 = _175 == _216;
    assign _184 = _177 | _183;
    assign _171 = pin_out[5:5];
    assign _172 = ~ _171;
    assign _168 = cfg_pin_modes[11:10];
    assign _170 = _168 == _219;
    assign _173 = _170 & _172;
    assign _165 = cfg_pin_modes[11:10];
    assign _167 = _165 == _216;
    assign _174 = _167 | _173;
    assign _161 = pin_out[6:6];
    assign _162 = ~ _161;
    assign _158 = cfg_pin_modes[13:12];
    assign _160 = _158 == _219;
    assign _163 = _160 & _162;
    assign _155 = cfg_pin_modes[13:12];
    assign _157 = _155 == _216;
    assign _164 = _157 | _163;
    assign _151 = pin_out[7:7];
    assign _152 = ~ _151;
    assign _145 = cfg_pin_modes[15:14];
    assign _147 = _145 == _219;
    assign _153 = _147 & _152;
    assign _142 = cfg_pin_modes[15:14];
    assign _144 = _142 == _216;
    assign _154 = _144 | _153;
    assign _225 = { _154,
                    _164,
                    _174,
                    _184,
                    _194,
                    _204,
                    _214,
                    _224 };
    assign _264 = pin_out[0:0];
    assign _261 = cfg_pin_modes[1:0];
    assign _263 = _261 == _216;
    assign _265 = _263 & _264;
    assign _259 = pin_out[1:1];
    assign _256 = cfg_pin_modes[3:2];
    assign _258 = _256 == _216;
    assign _260 = _258 & _259;
    assign _254 = pin_out[2:2];
    assign _251 = cfg_pin_modes[5:4];
    assign _253 = _251 == _216;
    assign _255 = _253 & _254;
    assign _249 = pin_out[3:3];
    assign _246 = cfg_pin_modes[7:6];
    assign _248 = _246 == _216;
    assign _250 = _248 & _249;
    assign _244 = pin_out[4:4];
    assign _241 = cfg_pin_modes[9:8];
    assign _243 = _241 == _216;
    assign _245 = _243 & _244;
    assign _239 = pin_out[5:5];
    assign _236 = cfg_pin_modes[11:10];
    assign _238 = _236 == _216;
    assign _240 = _238 & _239;
    assign _234 = pin_out[6:6];
    assign _231 = cfg_pin_modes[13:12];
    assign _233 = _231 == _216;
    assign _235 = _233 & _234;
    assign _229 = pin_out[7:7];
    assign _226 = cfg_pin_modes[15:14];
    assign _228 = _226 == _216;
    assign _230 = _228 & _229;
    assign _266 = { _230,
                    _235,
                    _240,
                    _245,
                    _250,
                    _255,
                    _260,
                    _265 };
    assign _297 = 16'b0000000000000000;
    assign _565 = 1'b0;
    assign _564 = host_miso_shift[14:0];
    assign _566 = { _564,
                    _565 };
    assign _544 = 6'b000000;
    assign _548 = { _544,
                    cfg_buf_end };
    assign _543 = { _544,
                    buf_ptr };
    assign _534 = 13'b0000000000000;
    assign _538 = { _534,
                    cfg_buf_ctrl };
    assign _517 = 10'b0000000000;
    assign _521 = { _517,
                    cfg_t1_shift };
    assign _513 = { _517,
                    cfg_t1_sideset };
    assign _501 = cfg_ctrl[1:1];
    assign _505 = { t1_pc,
                    _501,
                    t1_rx_level,
                    gnd,
                    t1_tx_level };
    assign _458 = 3'b000;
    assign _459 = t1_rx_level == _458;
    assign _460 = ~ _459;
    assign _497 = _460 ? _496 : _297;
    assign _450 = 8'b00000000;
    assign _454 = { _450,
                    cfg_t1_timeout_vector };
    assign _445 = 11'b00000000000;
    assign _449 = { _445,
                    cfg_t1_threshold };
    assign _444 = { _534,
                    cfg_t1_in_base };
    assign _439 = { _450,
                    cfg_t1_set_cfg };
    assign _434 = { _450,
                    cfg_t1_out_cfg };
    assign _429 = { _450,
                    cfg_t1_start };
    assign _424 = { _517,
                    cfg_load };
    assign _419 = { _517,
                    cfg_t0_shift };
    assign _414 = { _450,
                    cfg_sync_bypass };
    assign _406 = { _517,
                    cfg_t0_sideset };
    assign _394 = cfg_ctrl[0:0];
    assign _398 = { t0_pc,
                    _394,
                    t0_rx_level,
                    gnd,
                    t0_tx_level };
    assign _352 = t0_rx_level == _458;
    assign _353 = ~ _352;
    assign _390 = _353 ? _389 : _297;
    assign _347 = { _450,
                    cfg_t0_timeout_vector };
    assign _342 = { _445,
                    cfg_t0_threshold };
    assign _337 = { _534,
                    cfg_t0_in_base };
    assign _332 = { _450,
                    cfg_t0_set_cfg };
    assign _327 = { _450,
                    cfg_t0_out_cfg };
    assign _322 = { _450,
                    cfg_t0_start };
    assign _317 = { _534,
                    cfg_ctrl };
    always @* begin
        case (_311)
        0:
            _561 <= _297;
        1:
            _561 <= _297;
        2:
            _561 <= _297;
        3:
            _561 <= _297;
        4:
            _561 <= _297;
        5:
            _561 <= _297;
        6:
            _561 <= _297;
        7:
            _561 <= _297;
        8:
            _561 <= _297;
        9:
            _561 <= _297;
        10:
            _561 <= _297;
        11:
            _561 <= _297;
        12:
            _561 <= _297;
        13:
            _561 <= _297;
        14:
            _561 <= _297;
        15:
            _561 <= _297;
        16:
            _561 <= _297;
        17:
            _561 <= _297;
        18:
            _561 <= _297;
        19:
            _561 <= _297;
        20:
            _561 <= _297;
        21:
            _561 <= _297;
        22:
            _561 <= _297;
        23:
            _561 <= _297;
        24:
            _561 <= _297;
        25:
            _561 <= _297;
        26:
            _561 <= _297;
        27:
            _561 <= _297;
        28:
            _561 <= _297;
        29:
            _561 <= _297;
        30:
            _561 <= _297;
        31:
            _561 <= _297;
        32:
            _561 <= _297;
        33:
            _561 <= _297;
        34:
            _561 <= _297;
        35:
            _561 <= _297;
        36:
            _561 <= _297;
        37:
            _561 <= _297;
        38:
            _561 <= _297;
        39:
            _561 <= _297;
        40:
            _561 <= _297;
        41:
            _561 <= _297;
        42:
            _561 <= _297;
        43:
            _561 <= _297;
        44:
            _561 <= _297;
        45:
            _561 <= _297;
        46:
            _561 <= _297;
        47:
            _561 <= _297;
        48:
            _561 <= _297;
        49:
            _561 <= _297;
        50:
            _561 <= _297;
        51:
            _561 <= _297;
        52:
            _561 <= _297;
        53:
            _561 <= _297;
        54:
            _561 <= _297;
        55:
            _561 <= _297;
        56:
            _561 <= _297;
        57:
            _561 <= _297;
        58:
            _561 <= _297;
        59:
            _561 <= _297;
        60:
            _561 <= _297;
        61:
            _561 <= _297;
        62:
            _561 <= _297;
        63:
            _561 <= _297;
        64:
            _561 <= _317;
        65:
            _561 <= _322;
        66:
            _561 <= _327;
        67:
            _561 <= _332;
        68:
            _561 <= _337;
        69:
            _561 <= _342;
        70:
            _561 <= _347;
        71:
            _561 <= cfg_pin_modes;
        72:
            _561 <= _297;
        73:
            _561 <= _390;
        74:
            _561 <= _398;
        75:
            _561 <= cfg_t0_timeout;
        76:
            _561 <= _406;
        77:
            _561 <= cfg_t0_clkdiv;
        78:
            _561 <= _414;
        79:
            _561 <= _419;
        80:
            _561 <= _424;
        81:
            _561 <= _429;
        82:
            _561 <= _434;
        83:
            _561 <= _439;
        84:
            _561 <= _444;
        85:
            _561 <= _449;
        86:
            _561 <= _454;
        87:
            _561 <= _297;
        88:
            _561 <= _297;
        89:
            _561 <= _497;
        90:
            _561 <= _505;
        91:
            _561 <= cfg_t1_timeout;
        92:
            _561 <= _513;
        93:
            _561 <= cfg_t1_clkdiv;
        94:
            _561 <= _297;
        95:
            _561 <= _521;
        96:
            _561 <= _297;
        97:
            _561 <= cfg_t0_crc_poly_lo;
        98:
            _561 <= cfg_t0_crc_poly_hi;
        99:
            _561 <= cfg_t0_crc_init_lo;
        100:
            _561 <= cfg_t0_crc_init_hi;
        101:
            _561 <= _297;
        102:
            _561 <= _297;
        103:
            _561 <= _297;
        104:
            _561 <= _538;
        105:
            _561 <= _543;
        106:
            _561 <= _548;
        107:
            _561 <= _77;
        108:
            _561 <= _297;
        109:
            _561 <= _297;
        110:
            _561 <= _297;
        111:
            _561 <= _297;
        112:
            _561 <= _297;
        113:
            _561 <= cfg_t1_crc_poly_lo;
        114:
            _561 <= cfg_t1_crc_poly_hi;
        115:
            _561 <= cfg_t1_crc_init_lo;
        116:
            _561 <= cfg_t1_crc_init_hi;
        default:
            _561 <= _297;
        endcase
    end
    assign _562 = _300 ? _561 : host_miso_shift;
    assign _563 = _295 ? _562 : host_miso_shift;
    assign _288 = 5'b01001;
    assign _289 = host_bit_count < _288;
    assign _290 = ~ _289;
    assign _283 = ~ host_cs_n_s2;
    assign _278 = ~ host_sck_s2;
    assign _282 = _278 & host_sck_prev;
    assign _284 = _282 & _283;
    assign _291 = _284 & _290;
    assign _567 = _291 ? _566 : _563;
    assign _568 = host_cs_n_s2 ? host_miso_shift : _567;
    assign _3 = _568;
    always @(posedge _131) begin
        if (_129)
            host_miso_shift <= _297;
        else
            host_miso_shift <= _3;
    end
    assign _4106 = host_miso_shift[15:15];
    assign _4105 = cfg_ctrl[0:0];
    assign _4103 = t0_rx_level == _458;
    assign _4104 = ~ _4103;
    assign _4100 = 3'b100;
    assign _4101 = t0_tx_level == _4100;
    assign _4099 = cfg_ctrl[1:1];
    assign _4097 = t1_rx_level == _458;
    assign _4098 = ~ _4097;
    assign _4091 = 2'b00;
    assign _4092 = { _4091,
                     _3420 };
    assign _1635 = ~ _1634;
    assign _1630 = ~ _1629;
    assign _1624 = 1'b1;
    assign _1625 = _1089 == _1624;
    assign _1623 = _1097 == _216;
    assign _1626 = _1623 & _1625;
    assign _1627 = ~ _1626;
    assign _1619 = 7'b1011000;
    assign _1620 = _577 == _1619;
    assign _1618 = _571 & _575;
    assign _1621 = _1618 & _1620;
    assign _1628 = _1621 & _1627;
    assign _1631 = _1628 & _1630;
    assign _4086 = ~ _1634;
    assign _4062 = { _4091,
                     _3367 };
    assign _362 = ~ _361;
    assign _4056 = _745 & _741;
    assign _4054 = ~ _361;
    assign _4052 = ~ _699;
    assign _4050 = _617 == _4100;
    assign _614 = 4'b0000;
    assign _4020 = 4'b0001;
    assign _4021 = t0_delay_left - _4020;
    assign _4015 = _4013[3:2];
    assign _4016 = { _4091,
                     _4015 };
    assign _4012 = 4'b0111;
    assign _4011 = 4'b1111;
    assign _4010 = _1958[0:0];
    assign _4013 = _4010 ? _4012 : _4011;
    assign _4009 = _1958[1:1];
    assign _4017 = _4009 ? _4016 : _4013;
    assign _4018 = _2385 & _4017;
    assign _742 = _741 & _361;
    assign _361 = t0_rx_level == _4100;
    assign _707 = ~ _699;
    assign _706 = _617 == _4100;
    assign _708 = _706 & _707;
    assign _709 = _708 & _361;
    assign _698 = _617 == _4100;
    assign _700 = _698 & _699;
    assign _703 = _700 & _702;
    assign _695 = ~ _694;
    assign _682 = ~ _681;
    assign _618 = 3'b001;
    assign _4003 = 16'b1111111111111111;
    assign _3993 = _117[5:0];
    assign _582 = _581[7:0];
    assign _578 = 7'b1000001;
    assign _579 = _577 == _578;
    assign _576 = _571 & _575;
    assign _580 = _576 & _579;
    assign _583 = _580 ? _582 : cfg_t0_start;
    assign _4 = _583;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_start <= _450;
        else
            cfg_t0_start <= _4;
    end
    assign _760 = cfg_t0_start[7:6];
    assign _754 = _117[1:0];
    assign _752 = 2'b11;
    assign _753 = _751 == _752;
    assign _755 = _753 ? _754 : t0_page;
    assign _750 = _617 == _829;
    assign _756 = _750 ? _755 : t0_page;
    assign _757 = _745 ? _756 : t0_page;
    assign _758 = _612 ? t0_page : _757;
    assign _759 = _606 ? t0_page : _758;
    assign _761 = _600 ? _760 : _759;
    assign _5 = _761;
    assign _6 = _5;
    always @(posedge _131) begin
        if (_129)
            t0_page <= _4091;
        else
            t0_page <= _6;
    end
    assign _3994 = { t0_page,
                     _3993 };
    assign _766 = _581[7:0];
    assign _763 = 7'b1000110;
    assign _764 = _577 == _763;
    assign _762 = _571 & _575;
    assign _765 = _762 & _764;
    assign _767 = _765 ? _766 : cfg_t0_timeout_vector;
    assign _7 = _767;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_timeout_vector <= _450;
        else
            cfg_t0_timeout_vector <= _7;
    end
    assign _3992 = _617 == _458;
    assign _3995 = _3992 ? _3994 : cfg_t0_timeout_vector;
    assign _3989 = 8'b00000001;
    assign _3990 = t0_pc + _3989;
    assign _775 = 16'b0000000000000001;
    assign _776 = _691 - _775;
    assign _777 = _774 ? _776 : t0_wait_count;
    assign _778 = _612 ? t0_wait_count : _777;
    assign _779 = _606 ? t0_wait_count : _778;
    assign _781 = _600 ? _297 : _779;
    assign _8 = _781;
    assign _9 = _8;
    always @(posedge _131) begin
        if (_129)
            t0_wait_count <= _297;
        else
            t0_wait_count <= _9;
    end
    assign _783 = 7'b1001011;
    assign _784 = _577 == _783;
    assign _782 = _571 & _575;
    assign _785 = _782 & _784;
    assign _786 = _785 ? _581 : cfg_t0_timeout;
    assign _10 = _786;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_timeout <= _297;
        else
            cfg_t0_timeout <= _10;
    end
    assign _773 = ~ _693;
    assign _770 = ~ _681;
    assign _769 = _617 == _618;
    assign _771 = _769 & _770;
    assign _772 = _771 & _684;
    assign _774 = _772 & _773;
    assign _788 = _774 ? _1624 : t0_waiting;
    assign _790 = _745 ? _565 : _788;
    assign _791 = _612 ? t0_waiting : _790;
    assign _792 = _606 ? t0_waiting : _791;
    assign _794 = _600 ? _565 : _792;
    assign _11 = _794;
    assign _12 = _11;
    always @(posedge _131) begin
        if (_129)
            t0_waiting <= _565;
        else
            t0_waiting <= _12;
    end
    assign _691 = t0_waiting ? t0_wait_count : cfg_t0_timeout;
    assign _693 = _691 == _297;
    assign _684 = _117[4:4];
    assign _694 = _684 & _693;
    assign _680 = _117[8:8];
    assign _678 = _670[7:7];
    assign _677 = _670[6:6];
    assign _676 = _670[5:5];
    assign _675 = _670[4:4];
    assign _674 = _670[3:3];
    assign _673 = _670[2:2];
    assign _672 = _670[1:1];
    assign _671 = _670[0:0];
    assign _620 = _117[7:5];
    always @* begin
        case (_620)
        0:
            _679 <= _671;
        1:
            _679 <= _672;
        2:
            _679 <= _673;
        3:
            _679 <= _674;
        4:
            _679 <= _675;
        5:
            _679 <= _676;
        6:
            _679 <= _677;
        default:
            _679 <= _678;
        endcase
    end
    assign _681 = _679 == _680;
    assign _3985 = ~ _681;
    assign _3984 = _617 == _618;
    assign _3986 = _3984 & _3985;
    assign _3987 = _3986 & _694;
    assign _3980 = t0_isr_count < cfg_t0_threshold;
    assign _3979 = t0_osr_count < cfg_t0_threshold;
    assign _3977 = t0_x == t0_y;
    assign _3978 = ~ _3977;
    assign _3974 = t0_y == _297;
    assign _3975 = ~ _3974;
    assign _3976 = ~ _3975;
    assign _3959 = t0_x - _775;
    assign _3956 = 3'b010;
    assign _3957 = _3927 == _3956;
    assign _3960 = _3957 ? _3959 : t0_x;
    assign _3953 = _3922 == _216;
    assign _3954 = _3953 ? _920 : t0_x;
    assign _2121 = cfg_t0_shift[4:4];
    assign _2122 = { _2121,
                     _2121 };
    assign _2123 = { _2122,
                     _2122 };
    assign _2124 = { _2123,
                     _2123 };
    assign _2125 = { _2124,
                     _2124 };
    assign _2126 = { _2125,
                     _2125 };
    assign _850 = 32'b00000000000000000000000000000000;
    assign _796 = 7'b1100011;
    assign _797 = _577 == _796;
    assign _795 = _571 & _575;
    assign _798 = _795 & _797;
    assign _799 = _798 ? _581 : cfg_t0_crc_init_lo;
    assign _13 = _799;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_crc_init_lo <= _297;
        else
            cfg_t0_crc_init_lo <= _13;
    end
    assign _801 = 7'b1100100;
    assign _802 = _577 == _801;
    assign _800 = _571 & _575;
    assign _803 = _800 & _802;
    assign _804 = _803 ? _581 : cfg_t0_crc_init_hi;
    assign _14 = _804;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_crc_init_hi <= _297;
        else
            cfg_t0_crc_init_hi <= _14;
    end
    assign _1081 = { cfg_t0_crc_init_hi,
                     cfg_t0_crc_init_lo };
    assign _1078 = t0_crc[31:16];
    assign _1079 = { _297,
                     _1078 };
    assign _1080 = _830 ? _1079 : _1075;
    assign _1082 = _828 ? _1081 : _1080;
    assign _1083 = _826 ? _1082 : _1075;
    assign _1076 = _617 == _1476;
    assign _1084 = _1076 ? _1083 : _1075;
    assign _1064 = _1044[15:15];
    assign _1063 = _1044[14:14];
    assign _1062 = _1044[13:13];
    assign _1061 = _1044[12:12];
    assign _1060 = _1044[11:11];
    assign _1059 = _1044[10:10];
    assign _1058 = _1044[9:9];
    assign _1057 = _1044[8:8];
    assign _1056 = _1044[7:7];
    assign _1055 = _1044[6:6];
    assign _1054 = _1044[5:5];
    assign _1053 = _1044[4:4];
    assign _1052 = _1044[3:3];
    assign _1051 = _1044[2:2];
    assign _1050 = _1044[1:1];
    assign _1049 = _1044[0:0];
    assign _1046 = 5'b00001;
    assign _1047 = _735 - _1046;
    assign _1048 = _1047[3:0];
    always @* begin
        case (_1048)
        0:
            _1065 <= _1049;
        1:
            _1065 <= _1050;
        2:
            _1065 <= _1051;
        3:
            _1065 <= _1052;
        4:
            _1065 <= _1053;
        5:
            _1065 <= _1054;
        6:
            _1065 <= _1055;
        7:
            _1065 <= _1056;
        8:
            _1065 <= _1057;
        9:
            _1065 <= _1058;
        10:
            _1065 <= _1059;
        11:
            _1065 <= _1060;
        12:
            _1065 <= _1061;
        13:
            _1065 <= _1062;
        14:
            _1065 <= _1063;
        default:
            _1065 <= _1064;
        endcase
    end
    assign _1043 = _1042 & _888;
    assign _1044 = _842 ? _1043 : _920;
    assign _1045 = _1044[0:0];
    assign _859 = _842 ? _858 : _857;
    assign _1066 = _859 ? _1065 : _1045;
    assign _856 = t0_crc[0:0];
    assign _1067 = _856 ^ _1066;
    assign _1068 = { _1067,
                     _1067 };
    assign _1069 = { _1068,
                     _1068 };
    assign _1070 = { _1069,
                     _1069 };
    assign _1071 = { _1070,
                     _1070 };
    assign _1072 = { _1071,
                     _1071 };
    assign _806 = 7'b1100001;
    assign _807 = _577 == _806;
    assign _805 = _571 & _575;
    assign _808 = _805 & _807;
    assign _809 = _808 ? _581 : cfg_t0_crc_poly_lo;
    assign _15 = _809;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_crc_poly_lo <= _297;
        else
            cfg_t0_crc_poly_lo <= _15;
    end
    assign _811 = 7'b1100010;
    assign _812 = _577 == _811;
    assign _810 = _571 & _575;
    assign _813 = _810 & _812;
    assign _814 = _813 ? _581 : cfg_t0_crc_poly_hi;
    assign _16 = _814;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_crc_poly_hi <= _297;
        else
            cfg_t0_crc_poly_hi <= _16;
    end
    assign _855 = { cfg_t0_crc_poly_hi,
                    cfg_t0_crc_poly_lo };
    assign _1073 = _855 & _1072;
    assign _853 = t0_crc[31:1];
    assign _854 = { _565,
                    _853 };
    assign _1074 = _854 ^ _1073;
    assign _846 = _617 == _3956;
    assign _843 = 3'b011;
    assign _844 = _617 == _843;
    assign _842 = cfg_t0_shift[5:5];
    assign _847 = _842 ? _846 : _844;
    assign _829 = 3'b110;
    assign _830 = _823 == _829;
    assign _831 = _830 ? gnd : t0_crc_run;
    assign _828 = _820 == _829;
    assign _833 = _828 ? _1624 : _831;
    assign _834 = _826 ? _833 : t0_crc_run;
    assign _819 = _617 == _1476;
    assign _835 = _819 ? _834 : t0_crc_run;
    assign _836 = _745 ? _835 : t0_crc_run;
    assign _837 = _612 ? t0_crc_run : _836;
    assign _838 = _606 ? t0_crc_run : _837;
    assign _840 = _600 ? _1624 : _838;
    assign _17 = _840;
    assign _18 = _17;
    always @(posedge _131) begin
        if (_129)
            t0_crc_run <= _565;
        else
            t0_crc_run <= _18;
    end
    assign _841 = _745 & t0_crc_run;
    assign _848 = _841 & _847;
    assign _1075 = _848 ? _1074 : t0_crc;
    assign _1085 = _745 ? _1084 : _1075;
    assign _1086 = _612 ? t0_crc : _1085;
    assign _1087 = _606 ? t0_crc : _1086;
    assign _1088 = _600 ? _1081 : _1087;
    assign _19 = _1088;
    assign _20 = _19;
    always @(posedge _131) begin
        if (_129)
            t0_crc <= _850;
        else
            t0_crc <= _20;
    end
    assign _2127 = t0_crc ^ _2126;
    assign _2128 = _2127[15:0];
    assign _2116 = { _450,
                     _670 };
    assign _3931 = t0_y - _775;
    assign _3929 = _3927 == _4100;
    assign _3932 = _3929 ? _3931 : t0_y;
    assign _916 = _914[31:16];
    assign _917 = { _297,
                    _916 };
    assign _912 = _910[31:8];
    assign _913 = { _450,
                    _912 };
    assign _908 = _906[31:4];
    assign _909 = { _614,
                    _908 };
    assign _904 = _902[31:2];
    assign _905 = { _4091,
                    _904 };
    assign _900 = _898[31:1];
    assign _901 = { _565,
                    _900 };
    assign _898 = { _297,
                    t0_osr };
    assign _896 = _891[0:0];
    assign _902 = _896 ? _901 : _898;
    assign _895 = _891[1:1];
    assign _906 = _895 ? _905 : _902;
    assign _894 = _891[2:2];
    assign _910 = _894 ? _909 : _906;
    assign _893 = _891[3:3];
    assign _914 = _893 ? _913 : _910;
    assign _890 = 5'b10000;
    assign _891 = _890 - _735;
    assign _892 = _891[4:4];
    assign _918 = _892 ? _917 : _914;
    assign _919 = _918[15:0];
    assign _3889 = _3888[15:0];
    assign _3891 = { _3889,
                     _297 };
    assign _3885 = _3884[23:0];
    assign _3887 = { _3885,
                     _450 };
    assign _3881 = _3880[27:0];
    assign _3883 = { _3881,
                     _614 };
    assign _3877 = _3876[29:0];
    assign _3879 = { _3877,
                     _4091 };
    assign _3873 = _3872[30:0];
    assign _3875 = { _3873,
                     _565 };
    assign _3872 = { _297,
                     t0_osr };
    assign _3870 = _735[0:0];
    assign _3876 = _3870 ? _3875 : _3872;
    assign _3869 = _735[1:1];
    assign _3880 = _3869 ? _3879 : _3876;
    assign _3868 = _735[2:2];
    assign _3884 = _3868 ? _3883 : _3880;
    assign _3867 = _735[3:3];
    assign _3888 = _3867 ? _3887 : _3884;
    assign _3866 = _735[4:4];
    assign _3892 = _3866 ? _3891 : _3888;
    assign _3893 = _3892[15:0];
    assign _3862 = _3860[31:16];
    assign _3863 = { _297,
                     _3862 };
    assign _3858 = _3856[31:8];
    assign _3859 = { _450,
                     _3858 };
    assign _3854 = _3852[31:4];
    assign _3855 = { _614,
                     _3854 };
    assign _3850 = _3848[31:2];
    assign _3851 = { _4091,
                     _3850 };
    assign _3846 = _3844[31:1];
    assign _3847 = { _565,
                     _3846 };
    assign _3844 = { _297,
                     t0_osr };
    assign _3842 = _735[0:0];
    assign _3848 = _3842 ? _3847 : _3844;
    assign _3841 = _735[1:1];
    assign _3852 = _3841 ? _3851 : _3848;
    assign _3840 = _735[2:2];
    assign _3856 = _3840 ? _3855 : _3852;
    assign _3839 = _735[3:3];
    assign _3860 = _3839 ? _3859 : _3856;
    assign _3838 = _735[4:4];
    assign _3864 = _3838 ? _3863 : _3860;
    assign _3865 = _3864[15:0];
    assign _3894 = _857 ? _3893 : _3865;
    assign _3895 = _1146 ? _3827 : _3894;
    assign _3836 = _699 ? _3827 : _3828;
    assign _3832 = _820 == _4100;
    assign _3833 = _3832 ? _2129 : _3828;
    assign _3834 = _826 ? _3833 : _3828;
    assign _3831 = _617 == _1476;
    assign _3835 = _3831 ? _3834 : _3828;
    assign _3830 = _617 == _4100;
    assign _3837 = _3830 ? _3836 : _3835;
    assign _3829 = _617 == _843;
    assign _3896 = _3829 ? _3895 : _3837;
    assign _3824 = t0_tx_wr == _752;
    assign _3825 = _1109 & _3824;
    always @(posedge _131) begin
        if (_129)
            t0_tx_mem_3 <= _297;
        else
            if (_3825)
                t0_tx_mem_3 <= _3802;
    end
    assign _3818 = t0_tx_wr == _219;
    assign _3819 = _1109 & _3818;
    always @(posedge _131) begin
        if (_129)
            t0_tx_mem_2 <= _297;
        else
            if (_3819)
                t0_tx_mem_2 <= _3802;
    end
    assign _3812 = t0_tx_wr == _216;
    assign _3813 = _1109 & _3812;
    always @(posedge _131) begin
        if (_129)
            t0_tx_mem_1 <= _297;
        else
            if (_3813)
                t0_tx_mem_1 <= _3802;
    end
    assign _1114 = t0_tx_wr + _216;
    assign _1115 = _1109 ? _1114 : t0_tx_wr;
    assign _21 = _1115;
    always @(posedge _131) begin
        if (_129)
            t0_tx_wr <= _4091;
        else
            t0_tx_wr <= _21;
    end
    assign _3806 = t0_tx_wr == _4091;
    assign _3807 = _1109 & _3806;
    assign _3802 = _1092 ? _77 : _581;
    always @(posedge _131) begin
        if (_129)
            t0_tx_mem_0 <= _297;
        else
            if (_3807)
                t0_tx_mem_0 <= _3802;
    end
    assign _1122 = t0_tx_rd + _216;
    assign _1123 = _1117 ? _1122 : t0_tx_rd;
    assign _22 = _1123;
    always @(posedge _131) begin
        if (_129)
            t0_tx_rd <= _4091;
        else
            t0_tx_rd <= _22;
    end
    always @* begin
        case (t0_tx_rd)
        0:
            _3827 <= t0_tx_mem_0;
        1:
            _3827 <= t0_tx_mem_1;
        2:
            _3827 <= t0_tx_mem_2;
        default:
            _3827 <= t0_tx_mem_3;
        endcase
    end
    assign _716 = 5'b00000;
    assign _1116 = ~ _702;
    assign _1128 = ~ _702;
    assign _1125 = _617 == _4100;
    assign _1126 = _616 & _1125;
    assign _1127 = _1126 & _699;
    assign _1129 = _1127 & _1128;
    assign _1147 = _1129 | _1146;
    assign _1150 = _1147 | _1149;
    assign _23 = _1150;
    assign _1117 = _23 & _1116;
    assign _3772 = { _4091,
                     _1117 };
    assign _1108 = ~ _1107;
    assign _1101 = _1089 == _565;
    assign _1099 = _1097 == _216;
    assign _1102 = _1099 & _1101;
    assign _1103 = ~ _1102;
    assign _1094 = 7'b1001000;
    assign _1095 = _577 == _1094;
    assign _1093 = _571 & _575;
    assign _1096 = _1093 & _1095;
    assign _1104 = _1096 & _1103;
    assign _1091 = _1089 == _565;
    assign _1634 = t1_tx_level == _4100;
    assign _1107 = t0_tx_level == _4100;
    assign _3765 = _1089 ? _1634 : _1107;
    assign _3766 = ~ _3765;
    assign _3762 = _1629 & _1089;
    assign _3763 = ~ _3762;
    always @(posedge _131) begin
        if (_129)
            buf_wrote <= _565;
        else
            buf_wrote <= _75;
    end
    assign _3760 = ~ buf_wrote;
    assign _3744 = _581[9:0];
    assign _3741 = 10'b0000000001;
    assign _3742 = buf_ptr + _3741;
    assign _1157 = 7'b1101011;
    assign _1158 = _311 == _1157;
    assign _1154 = _310[7:7];
    assign _1155 = ~ _1154;
    assign _1156 = _1153 & _1155;
    assign _1159 = _1156 & _1158;
    assign _24 = _1159;
    assign _3739 = _24 & _3379;
    assign _3713 = { _4091,
                     _1916 };
    assign _469 = ~ _468;
    assign _3707 = _1270 & _1266;
    assign _3705 = ~ _468;
    assign _3703 = ~ _1224;
    assign _3701 = _1192 == _4100;
    assign _3678 = t1_delay_left - _4020;
    assign _3672 = _3670[3:2];
    assign _3673 = { _4091,
                     _3672 };
    assign _3667 = _2541[0:0];
    assign _3670 = _3667 ? _4012 : _4011;
    assign _3666 = _2541[1:1];
    assign _3674 = _3666 ? _3673 : _3670;
    assign _3675 = _2953 & _3674;
    assign _1267 = _1266 & _468;
    assign _468 = t1_rx_level == _4100;
    assign _1232 = ~ _1224;
    assign _1231 = _1192 == _4100;
    assign _1233 = _1231 & _1232;
    assign _1234 = _1233 & _468;
    assign _1223 = _1192 == _4100;
    assign _1225 = _1223 & _1224;
    assign _1228 = _1225 & _1227;
    assign _1220 = ~ _1219;
    assign _1207 = ~ _1206;
    assign _3657 = _577[5:0];
    assign _3656 = cfg_load[1:0];
    assign _3658 = { _3656,
                     _3657 };
    assign _3647 = _92[5:0];
    assign _1164 = _581[7:0];
    assign _1161 = 7'b1010001;
    assign _1162 = _577 == _1161;
    assign _1160 = _571 & _575;
    assign _1163 = _1160 & _1162;
    assign _1165 = _1163 ? _1164 : cfg_t1_start;
    assign _25 = _1165;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_start <= _450;
        else
            cfg_t1_start <= _25;
    end
    assign _1285 = cfg_t1_start[7:6];
    assign _1279 = _92[1:0];
    assign _1278 = _1276 == _752;
    assign _1280 = _1278 ? _1279 : t1_page;
    assign _1275 = _1192 == _829;
    assign _1281 = _1275 ? _1280 : t1_page;
    assign _1282 = _1270 ? _1281 : t1_page;
    assign _1283 = _1187 ? t1_page : _1282;
    assign _1284 = _1181 ? t1_page : _1283;
    assign _1286 = _1175 ? _1285 : _1284;
    assign _26 = _1286;
    assign _27 = _26;
    always @(posedge _131) begin
        if (_129)
            t1_page <= _4091;
        else
            t1_page <= _27;
    end
    assign _3648 = { t1_page,
                     _3647 };
    assign _1291 = _581[7:0];
    assign _1288 = 7'b1010110;
    assign _1289 = _577 == _1288;
    assign _1287 = _571 & _575;
    assign _1290 = _1287 & _1289;
    assign _1292 = _1290 ? _1291 : cfg_t1_timeout_vector;
    assign _28 = _1292;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_timeout_vector <= _450;
        else
            cfg_t1_timeout_vector <= _28;
    end
    assign _3646 = _1192 == _458;
    assign _3649 = _3646 ? _3648 : cfg_t1_timeout_vector;
    assign _3644 = t1_pc + _3989;
    assign _1301 = _1216 - _775;
    assign _1302 = _1299 ? _1301 : t1_wait_count;
    assign _1303 = _1187 ? t1_wait_count : _1302;
    assign _1304 = _1181 ? t1_wait_count : _1303;
    assign _1306 = _1175 ? _297 : _1304;
    assign _29 = _1306;
    assign _30 = _29;
    always @(posedge _131) begin
        if (_129)
            t1_wait_count <= _297;
        else
            t1_wait_count <= _30;
    end
    assign _1308 = 7'b1011011;
    assign _1309 = _577 == _1308;
    assign _1307 = _571 & _575;
    assign _1310 = _1307 & _1309;
    assign _1311 = _1310 ? _581 : cfg_t1_timeout;
    assign _31 = _1311;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_timeout <= _297;
        else
            cfg_t1_timeout <= _31;
    end
    assign _1298 = ~ _1218;
    assign _1295 = ~ _1206;
    assign _1294 = _1192 == _618;
    assign _1296 = _1294 & _1295;
    assign _1297 = _1296 & _1209;
    assign _1299 = _1297 & _1298;
    assign _1313 = _1299 ? _1624 : t1_waiting;
    assign _1315 = _1270 ? _565 : _1313;
    assign _1316 = _1187 ? t1_waiting : _1315;
    assign _1317 = _1181 ? t1_waiting : _1316;
    assign _1319 = _1175 ? _565 : _1317;
    assign _32 = _1319;
    assign _33 = _32;
    always @(posedge _131) begin
        if (_129)
            t1_waiting <= _565;
        else
            t1_waiting <= _33;
    end
    assign _1216 = t1_waiting ? t1_wait_count : cfg_t1_timeout;
    assign _1218 = _1216 == _297;
    assign _1209 = _92[4:4];
    assign _1219 = _1209 & _1218;
    assign _1205 = _92[8:8];
    assign _1203 = _670[7:7];
    assign _1202 = _670[6:6];
    assign _1201 = _670[5:5];
    assign _1200 = _670[4:4];
    assign _1199 = _670[3:3];
    assign _1198 = _670[2:2];
    assign _1197 = _670[1:1];
    assign _1196 = _670[0:0];
    assign _1195 = _92[7:5];
    always @* begin
        case (_1195)
        0:
            _1204 <= _1196;
        1:
            _1204 <= _1197;
        2:
            _1204 <= _1198;
        3:
            _1204 <= _1199;
        4:
            _1204 <= _1200;
        5:
            _1204 <= _1201;
        6:
            _1204 <= _1202;
        default:
            _1204 <= _1203;
        endcase
    end
    assign _1206 = _1204 == _1205;
    assign _3639 = ~ _1206;
    assign _3638 = _1192 == _618;
    assign _3640 = _3638 & _3639;
    assign _3641 = _3640 & _1219;
    assign _3634 = t1_isr_count < cfg_t1_threshold;
    assign _3633 = t1_osr_count < cfg_t1_threshold;
    assign _3631 = t1_x == t1_y;
    assign _3632 = ~ _3631;
    assign _3628 = t1_y == _297;
    assign _3629 = ~ _3628;
    assign _3630 = ~ _3629;
    assign _3613 = t1_x - _775;
    assign _3611 = _3581 == _3956;
    assign _3614 = _3611 ? _3613 : t1_x;
    assign _3607 = _3576 == _216;
    assign _3608 = _3607 ? _1445 : t1_x;
    assign _1665 = cfg_t1_shift[4:4];
    assign _1666 = { _1665,
                     _1665 };
    assign _1667 = { _1666,
                     _1666 };
    assign _1668 = { _1667,
                     _1667 };
    assign _1669 = { _1668,
                     _1668 };
    assign _1670 = { _1669,
                     _1669 };
    assign _1321 = 7'b1110011;
    assign _1322 = _577 == _1321;
    assign _1320 = _571 & _575;
    assign _1323 = _1320 & _1322;
    assign _1324 = _1323 ? _581 : cfg_t1_crc_init_lo;
    assign _34 = _1324;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_crc_init_lo <= _297;
        else
            cfg_t1_crc_init_lo <= _34;
    end
    assign _1326 = 7'b1110100;
    assign _1327 = _577 == _1326;
    assign _1325 = _571 & _575;
    assign _1328 = _1325 & _1327;
    assign _1329 = _1328 ? _581 : cfg_t1_crc_init_hi;
    assign _35 = _1329;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_crc_init_hi <= _297;
        else
            cfg_t1_crc_init_hi <= _35;
    end
    assign _1606 = { cfg_t1_crc_init_hi,
                     cfg_t1_crc_init_lo };
    assign _1603 = t1_crc[31:16];
    assign _1604 = { _297,
                     _1603 };
    assign _1605 = _1355 ? _1604 : _1600;
    assign _1607 = _1353 ? _1606 : _1605;
    assign _1608 = _1351 ? _1607 : _1600;
    assign _1601 = _1192 == _1476;
    assign _1609 = _1601 ? _1608 : _1600;
    assign _1589 = _1569[15:15];
    assign _1588 = _1569[14:14];
    assign _1587 = _1569[13:13];
    assign _1586 = _1569[12:12];
    assign _1585 = _1569[11:11];
    assign _1584 = _1569[10:10];
    assign _1583 = _1569[9:9];
    assign _1582 = _1569[8:8];
    assign _1581 = _1569[7:7];
    assign _1580 = _1569[6:6];
    assign _1579 = _1569[5:5];
    assign _1578 = _1569[4:4];
    assign _1577 = _1569[3:3];
    assign _1576 = _1569[2:2];
    assign _1575 = _1569[1:1];
    assign _1574 = _1569[0:0];
    assign _1572 = _1260 - _1046;
    assign _1573 = _1572[3:0];
    always @* begin
        case (_1573)
        0:
            _1590 <= _1574;
        1:
            _1590 <= _1575;
        2:
            _1590 <= _1576;
        3:
            _1590 <= _1577;
        4:
            _1590 <= _1578;
        5:
            _1590 <= _1579;
        6:
            _1590 <= _1580;
        7:
            _1590 <= _1581;
        8:
            _1590 <= _1582;
        9:
            _1590 <= _1583;
        10:
            _1590 <= _1584;
        11:
            _1590 <= _1585;
        12:
            _1590 <= _1586;
        13:
            _1590 <= _1587;
        14:
            _1590 <= _1588;
        default:
            _1590 <= _1589;
        endcase
    end
    assign _1568 = _1567 & _1413;
    assign _1569 = _1367 ? _1568 : _1445;
    assign _1570 = _1569[0:0];
    assign _1384 = _1367 ? _1383 : _1382;
    assign _1591 = _1384 ? _1590 : _1570;
    assign _1381 = t1_crc[0:0];
    assign _1592 = _1381 ^ _1591;
    assign _1593 = { _1592,
                     _1592 };
    assign _1594 = { _1593,
                     _1593 };
    assign _1595 = { _1594,
                     _1594 };
    assign _1596 = { _1595,
                     _1595 };
    assign _1597 = { _1596,
                     _1596 };
    assign _1331 = 7'b1110001;
    assign _1332 = _577 == _1331;
    assign _1330 = _571 & _575;
    assign _1333 = _1330 & _1332;
    assign _1334 = _1333 ? _581 : cfg_t1_crc_poly_lo;
    assign _36 = _1334;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_crc_poly_lo <= _297;
        else
            cfg_t1_crc_poly_lo <= _36;
    end
    assign _1336 = 7'b1110010;
    assign _1337 = _577 == _1336;
    assign _1335 = _571 & _575;
    assign _1338 = _1335 & _1337;
    assign _1339 = _1338 ? _581 : cfg_t1_crc_poly_hi;
    assign _37 = _1339;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_crc_poly_hi <= _297;
        else
            cfg_t1_crc_poly_hi <= _37;
    end
    assign _1380 = { cfg_t1_crc_poly_hi,
                     cfg_t1_crc_poly_lo };
    assign _1598 = _1380 & _1597;
    assign _1378 = t1_crc[31:1];
    assign _1379 = { _565,
                     _1378 };
    assign _1599 = _1379 ^ _1598;
    assign _1371 = _1192 == _3956;
    assign _1369 = _1192 == _843;
    assign _1367 = cfg_t1_shift[5:5];
    assign _1372 = _1367 ? _1371 : _1369;
    assign _1355 = _1348 == _829;
    assign _1356 = _1355 ? gnd : t1_crc_run;
    assign _1353 = _1345 == _829;
    assign _1358 = _1353 ? _1624 : _1356;
    assign _1359 = _1351 ? _1358 : t1_crc_run;
    assign _1344 = _1192 == _1476;
    assign _1360 = _1344 ? _1359 : t1_crc_run;
    assign _1361 = _1270 ? _1360 : t1_crc_run;
    assign _1362 = _1187 ? t1_crc_run : _1361;
    assign _1363 = _1181 ? t1_crc_run : _1362;
    assign _1365 = _1175 ? _1624 : _1363;
    assign _38 = _1365;
    assign _39 = _38;
    always @(posedge _131) begin
        if (_129)
            t1_crc_run <= _565;
        else
            t1_crc_run <= _39;
    end
    assign _1366 = _1270 & t1_crc_run;
    assign _1373 = _1366 & _1372;
    assign _1600 = _1373 ? _1599 : t1_crc;
    assign _1610 = _1270 ? _1609 : _1600;
    assign _1611 = _1187 ? t1_crc : _1610;
    assign _1612 = _1181 ? t1_crc : _1611;
    assign _1613 = _1175 ? _1606 : _1612;
    assign _40 = _1613;
    assign _41 = _40;
    always @(posedge _131) begin
        if (_129)
            t1_crc <= _850;
        else
            t1_crc <= _41;
    end
    assign _1671 = t1_crc ^ _1670;
    assign _1672 = _1671[15:0];
    assign _1663 = { _450,
                     _670 };
    assign _3585 = t1_y - _775;
    assign _3583 = _3581 == _4100;
    assign _3586 = _3583 ? _3585 : t1_y;
    assign _1441 = _1439[31:16];
    assign _1442 = { _297,
                     _1441 };
    assign _1437 = _1435[31:8];
    assign _1438 = { _450,
                     _1437 };
    assign _1433 = _1431[31:4];
    assign _1434 = { _614,
                     _1433 };
    assign _1429 = _1427[31:2];
    assign _1430 = { _4091,
                     _1429 };
    assign _1425 = _1423[31:1];
    assign _1426 = { _565,
                     _1425 };
    assign _1423 = { _297,
                     t1_osr };
    assign _1421 = _1416[0:0];
    assign _1427 = _1421 ? _1426 : _1423;
    assign _1420 = _1416[1:1];
    assign _1431 = _1420 ? _1430 : _1427;
    assign _1419 = _1416[2:2];
    assign _1435 = _1419 ? _1434 : _1431;
    assign _1418 = _1416[3:3];
    assign _1439 = _1418 ? _1438 : _1435;
    assign _1416 = _890 - _1260;
    assign _1417 = _1416[4:4];
    assign _1443 = _1417 ? _1442 : _1439;
    assign _1444 = _1443[15:0];
    assign _3543 = _3542[15:0];
    assign _3545 = { _3543,
                     _297 };
    assign _3539 = _3538[23:0];
    assign _3541 = { _3539,
                     _450 };
    assign _3535 = _3534[27:0];
    assign _3537 = { _3535,
                     _614 };
    assign _3531 = _3530[29:0];
    assign _3533 = { _3531,
                     _4091 };
    assign _3527 = _3526[30:0];
    assign _3529 = { _3527,
                     _565 };
    assign _3526 = { _297,
                     t1_osr };
    assign _3524 = _1260[0:0];
    assign _3530 = _3524 ? _3529 : _3526;
    assign _3523 = _1260[1:1];
    assign _3534 = _3523 ? _3533 : _3530;
    assign _3522 = _1260[2:2];
    assign _3538 = _3522 ? _3537 : _3534;
    assign _3521 = _1260[3:3];
    assign _3542 = _3521 ? _3541 : _3538;
    assign _3520 = _1260[4:4];
    assign _3546 = _3520 ? _3545 : _3542;
    assign _3547 = _3546[15:0];
    assign _3516 = _3514[31:16];
    assign _3517 = { _297,
                     _3516 };
    assign _3512 = _3510[31:8];
    assign _3513 = { _450,
                     _3512 };
    assign _3508 = _3506[31:4];
    assign _3509 = { _614,
                     _3508 };
    assign _3504 = _3502[31:2];
    assign _3505 = { _4091,
                     _3504 };
    assign _3500 = _3498[31:1];
    assign _3501 = { _565,
                     _3500 };
    assign _3498 = { _297,
                     t1_osr };
    assign _3496 = _1260[0:0];
    assign _3502 = _3496 ? _3501 : _3498;
    assign _3495 = _1260[1:1];
    assign _3506 = _3495 ? _3505 : _3502;
    assign _3494 = _1260[2:2];
    assign _3510 = _3494 ? _3509 : _3506;
    assign _3493 = _1260[3:3];
    assign _3514 = _3493 ? _3513 : _3510;
    assign _3492 = _1260[4:4];
    assign _3518 = _3492 ? _3517 : _3514;
    assign _3519 = _3518[15:0];
    assign _3548 = _1382 ? _3547 : _3519;
    assign _3549 = _3414 ? _3481 : _3548;
    assign _3490 = _1224 ? _3481 : _3482;
    assign _3486 = _1345 == _4100;
    assign _3487 = _3486 ? _1673 : _3482;
    assign _3488 = _1351 ? _3487 : _3482;
    assign _3485 = _1192 == _1476;
    assign _3489 = _3485 ? _3488 : _3482;
    assign _3484 = _1192 == _4100;
    assign _3491 = _3484 ? _3490 : _3489;
    assign _3483 = _1192 == _843;
    assign _3550 = _3483 ? _3549 : _3491;
    assign _3478 = t1_tx_wr == _752;
    assign _3479 = _1636 & _3478;
    always @(posedge _131) begin
        if (_129)
            t1_tx_mem_3 <= _297;
        else
            if (_3479)
                t1_tx_mem_3 <= _3456;
    end
    assign _3472 = t1_tx_wr == _219;
    assign _3473 = _1636 & _3472;
    always @(posedge _131) begin
        if (_129)
            t1_tx_mem_2 <= _297;
        else
            if (_3473)
                t1_tx_mem_2 <= _3456;
    end
    assign _3466 = t1_tx_wr == _216;
    assign _3467 = _1636 & _3466;
    always @(posedge _131) begin
        if (_129)
            t1_tx_mem_1 <= _297;
        else
            if (_3467)
                t1_tx_mem_1 <= _3456;
    end
    assign _1641 = t1_tx_wr + _216;
    assign _1642 = _1636 ? _1641 : t1_tx_wr;
    assign _42 = _1642;
    always @(posedge _131) begin
        if (_129)
            t1_tx_wr <= _4091;
        else
            t1_tx_wr <= _42;
    end
    assign _3460 = t1_tx_wr == _4091;
    assign _3461 = _1636 & _3460;
    assign _43 = _389;
    assign _493 = t1_rx_wr == _752;
    assign _494 = _470 & _493;
    always @(posedge _131) begin
        if (_129)
            t1_rx_mem_3 <= _297;
        else
            if (_494)
                t1_rx_mem_3 <= _50;
    end
    assign _487 = t1_rx_wr == _219;
    assign _488 = _470 & _487;
    always @(posedge _131) begin
        if (_129)
            t1_rx_mem_2 <= _297;
        else
            if (_488)
                t1_rx_mem_2 <= _50;
    end
    assign _481 = t1_rx_wr == _216;
    assign _482 = _470 & _481;
    always @(posedge _131) begin
        if (_129)
            t1_rx_mem_1 <= _297;
        else
            if (_482)
                t1_rx_mem_1 <= _50;
    end
    assign _1644 = t1_rx_wr + _216;
    assign _1645 = _470 ? _1644 : t1_rx_wr;
    assign _44 = _1645;
    always @(posedge _131) begin
        if (_129)
            t1_rx_wr <= _4091;
        else
            t1_rx_wr <= _44;
    end
    assign _475 = t1_rx_wr == _4091;
    assign _476 = _470 & _475;
    assign _1883 = _1882[15:0];
    assign _1885 = { _1883,
                     _297 };
    assign _1879 = _1878[23:0];
    assign _1881 = { _1879,
                     _450 };
    assign _1875 = _1874[27:0];
    assign _1877 = { _1875,
                     _614 };
    assign _1871 = _1870[29:0];
    assign _1873 = { _1871,
                     _4091 };
    assign _1869 = 32'b11111111111111111111111111111110;
    assign _1868 = 32'b11111111111111111111111111111111;
    assign _1867 = _1764[0:0];
    assign _1870 = _1867 ? _1869 : _1868;
    assign _1866 = _1764[1:1];
    assign _1874 = _1866 ? _1873 : _1870;
    assign _1865 = _1764[2:2];
    assign _1878 = _1865 ? _1877 : _1874;
    assign _1864 = _1764[3:3];
    assign _1882 = _1864 ? _1881 : _1878;
    assign _1863 = _1764[4:4];
    assign _1886 = _1863 ? _1885 : _1882;
    assign _1887 = _1886[15:0];
    assign _1888 = ~ _1887;
    assign _1889 = _1737 & _1888;
    assign _1859 = _1857[31:16];
    assign _1860 = { _297,
                     _1859 };
    assign _1855 = _1853[31:8];
    assign _1856 = { _450,
                     _1855 };
    assign _1851 = _1849[31:4];
    assign _1852 = { _614,
                     _1851 };
    assign _1847 = _1845[31:2];
    assign _1848 = { _4091,
                     _1847 };
    assign _1843 = _1841[31:1];
    assign _1844 = { _565,
                     _1843 };
    assign _1841 = { _297,
                     _1737 };
    assign _1839 = _1834[0:0];
    assign _1845 = _1839 ? _1844 : _1841;
    assign _1838 = _1834[1:1];
    assign _1849 = _1838 ? _1848 : _1845;
    assign _1837 = _1834[2:2];
    assign _1853 = _1837 ? _1852 : _1849;
    assign _1836 = _1834[3:3];
    assign _1857 = _1836 ? _1856 : _1853;
    assign _1834 = _890 - _1764;
    assign _1835 = _1834[4:4];
    assign _1861 = _1835 ? _1860 : _1857;
    assign _1862 = _1861[15:0];
    assign _1890 = _1383 ? _1889 : _1862;
    assign _1825 = _1824[15:0];
    assign _1827 = { _1825,
                     _297 };
    assign _1821 = _1820[23:0];
    assign _1823 = { _1821,
                     _450 };
    assign _1817 = _1816[27:0];
    assign _1819 = { _1817,
                     _614 };
    assign _1813 = _1812[29:0];
    assign _1815 = { _1813,
                     _4091 };
    assign _1809 = t1_isr_count[0:0];
    assign _1812 = _1809 ? _1869 : _1868;
    assign _1808 = t1_isr_count[1:1];
    assign _1816 = _1808 ? _1815 : _1812;
    assign _1807 = t1_isr_count[2:2];
    assign _1820 = _1807 ? _1819 : _1816;
    assign _1806 = t1_isr_count[3:3];
    assign _1824 = _1806 ? _1823 : _1820;
    assign _1805 = t1_isr_count[4:4];
    assign _1828 = _1805 ? _1827 : _1824;
    assign _1829 = _1828[15:0];
    assign _1830 = ~ _1829;
    assign _1831 = t1_isr & _1830;
    assign _1801 = _1799[31:16];
    assign _1802 = { _297,
                     _1801 };
    assign _1797 = _1795[31:8];
    assign _1798 = { _450,
                     _1797 };
    assign _1793 = _1791[31:4];
    assign _1794 = { _614,
                     _1793 };
    assign _1789 = _1787[31:2];
    assign _1790 = { _4091,
                     _1789 };
    assign _1785 = _1783[31:1];
    assign _1786 = { _565,
                     _1785 };
    assign _1408 = _1407[15:0];
    assign _1410 = { _1408,
                     _297 };
    assign _1404 = _1403[23:0];
    assign _1406 = { _1404,
                     _450 };
    assign _1400 = _1399[27:0];
    assign _1402 = { _1400,
                     _614 };
    assign _1396 = _1395[29:0];
    assign _1398 = { _1396,
                     _4091 };
    assign _1392 = _1260[0:0];
    assign _1395 = _1392 ? _1869 : _1868;
    assign _1391 = _1260[1:1];
    assign _1399 = _1391 ? _1398 : _1395;
    assign _1390 = _1260[2:2];
    assign _1403 = _1390 ? _1402 : _1399;
    assign _1389 = _1260[3:3];
    assign _1407 = _1389 ? _1406 : _1403;
    assign _1388 = _1260[4:4];
    assign _1411 = _1388 ? _1410 : _1407;
    assign _1412 = _1411[15:0];
    assign _1413 = ~ _1412;
    assign _1735 = _1567 & _1413;
    assign _1730 = _1729[15:0];
    assign _1732 = { _1730,
                     _297 };
    assign _1726 = _1725[23:0];
    assign _1728 = { _1726,
                     _450 };
    assign _1722 = _1721[27:0];
    assign _1724 = { _1722,
                     _614 };
    assign _1718 = _1717[29:0];
    assign _1720 = { _1718,
                     _4091 };
    assign _1714 = _1713[30:0];
    assign _1716 = { _1714,
                     _565 };
    assign _1713 = { _297,
                     t1_isr };
    assign _1711 = _1260[0:0];
    assign _1717 = _1711 ? _1716 : _1713;
    assign _1710 = _1260[1:1];
    assign _1721 = _1710 ? _1720 : _1717;
    assign _1709 = _1260[2:2];
    assign _1725 = _1709 ? _1724 : _1721;
    assign _1708 = _1260[3:3];
    assign _1729 = _1708 ? _1728 : _1725;
    assign _1707 = _1260[4:4];
    assign _1733 = _1707 ? _1732 : _1729;
    assign _1734 = _1733[15:0];
    assign _1736 = _1734 | _1735;
    assign _1703 = _1701[31:16];
    assign _1704 = { _297,
                     _1703 };
    assign _1699 = _1697[31:8];
    assign _1700 = { _450,
                     _1699 };
    assign _1695 = _1693[31:4];
    assign _1696 = { _614,
                     _1695 };
    assign _1691 = _1689[31:2];
    assign _1692 = { _4091,
                     _1691 };
    assign _1687 = _1685[31:1];
    assign _1688 = { _565,
                     _1687 };
    assign _1556 = _716 < _1260;
    assign _1553 = _670[7:7];
    assign _1552 = _670[6:6];
    assign _1551 = _670[5:5];
    assign _1550 = _670[4:4];
    assign _1549 = _670[3:3];
    assign _1548 = _670[2:2];
    assign _1547 = _670[1:1];
    assign _1546 = _670[0:0];
    always @* begin
        case (cfg_t1_in_base)
        0:
            _1554 <= _1546;
        1:
            _1554 <= _1547;
        2:
            _1554 <= _1548;
        3:
            _1554 <= _1549;
        4:
            _1554 <= _1550;
        5:
            _1554 <= _1551;
        6:
            _1554 <= _1552;
        default:
            _1554 <= _1553;
        endcase
    end
    assign _1557 = _1554 & _1556;
    assign _1544 = _1046 < _1260;
    assign _1541 = _670[7:7];
    assign _1540 = _670[6:6];
    assign _1539 = _670[5:5];
    assign _1538 = _670[4:4];
    assign _1537 = _670[3:3];
    assign _1536 = _670[2:2];
    assign _1535 = _670[1:1];
    assign _1534 = _670[0:0];
    assign _1533 = cfg_t1_in_base + _618;
    always @* begin
        case (_1533)
        0:
            _1542 <= _1534;
        1:
            _1542 <= _1535;
        2:
            _1542 <= _1536;
        3:
            _1542 <= _1537;
        4:
            _1542 <= _1538;
        5:
            _1542 <= _1539;
        6:
            _1542 <= _1540;
        default:
            _1542 <= _1541;
        endcase
    end
    assign _1545 = _1542 & _1544;
    assign _1529 = 5'b00010;
    assign _1530 = _1529 < _1260;
    assign _1527 = _670[7:7];
    assign _1526 = _670[6:6];
    assign _1525 = _670[5:5];
    assign _1524 = _670[4:4];
    assign _1523 = _670[3:3];
    assign _1522 = _670[2:2];
    assign _1521 = _670[1:1];
    assign _1520 = _670[0:0];
    assign _1519 = cfg_t1_in_base + _3956;
    always @* begin
        case (_1519)
        0:
            _1528 <= _1520;
        1:
            _1528 <= _1521;
        2:
            _1528 <= _1522;
        3:
            _1528 <= _1523;
        4:
            _1528 <= _1524;
        5:
            _1528 <= _1525;
        6:
            _1528 <= _1526;
        default:
            _1528 <= _1527;
        endcase
    end
    assign _1531 = _1528 & _1530;
    assign _1515 = 5'b00011;
    assign _1516 = _1515 < _1260;
    assign _1513 = _670[7:7];
    assign _1512 = _670[6:6];
    assign _1511 = _670[5:5];
    assign _1510 = _670[4:4];
    assign _1509 = _670[3:3];
    assign _1508 = _670[2:2];
    assign _1507 = _670[1:1];
    assign _1506 = _670[0:0];
    assign _1505 = cfg_t1_in_base + _843;
    always @* begin
        case (_1505)
        0:
            _1514 <= _1506;
        1:
            _1514 <= _1507;
        2:
            _1514 <= _1508;
        3:
            _1514 <= _1509;
        4:
            _1514 <= _1510;
        5:
            _1514 <= _1511;
        6:
            _1514 <= _1512;
        default:
            _1514 <= _1513;
        endcase
    end
    assign _1517 = _1514 & _1516;
    assign _1501 = 5'b00100;
    assign _1502 = _1501 < _1260;
    assign _1499 = _670[7:7];
    assign _1498 = _670[6:6];
    assign _1497 = _670[5:5];
    assign _1496 = _670[4:4];
    assign _1495 = _670[3:3];
    assign _1494 = _670[2:2];
    assign _1493 = _670[1:1];
    assign _1492 = _670[0:0];
    assign _1491 = cfg_t1_in_base + _4100;
    always @* begin
        case (_1491)
        0:
            _1500 <= _1492;
        1:
            _1500 <= _1493;
        2:
            _1500 <= _1494;
        3:
            _1500 <= _1495;
        4:
            _1500 <= _1496;
        5:
            _1500 <= _1497;
        6:
            _1500 <= _1498;
        default:
            _1500 <= _1499;
        endcase
    end
    assign _1503 = _1500 & _1502;
    assign _1487 = 5'b00101;
    assign _1488 = _1487 < _1260;
    assign _1485 = _670[7:7];
    assign _1484 = _670[6:6];
    assign _1483 = _670[5:5];
    assign _1482 = _670[4:4];
    assign _1481 = _670[3:3];
    assign _1480 = _670[2:2];
    assign _1479 = _670[1:1];
    assign _1478 = _670[0:0];
    assign _1476 = 3'b101;
    assign _1477 = cfg_t1_in_base + _1476;
    always @* begin
        case (_1477)
        0:
            _1486 <= _1478;
        1:
            _1486 <= _1479;
        2:
            _1486 <= _1480;
        3:
            _1486 <= _1481;
        4:
            _1486 <= _1482;
        5:
            _1486 <= _1483;
        6:
            _1486 <= _1484;
        default:
            _1486 <= _1485;
        endcase
    end
    assign _1489 = _1486 & _1488;
    assign _1473 = 5'b00110;
    assign _1474 = _1473 < _1260;
    assign _1471 = _670[7:7];
    assign _1470 = _670[6:6];
    assign _1469 = _670[5:5];
    assign _1468 = _670[4:4];
    assign _1467 = _670[3:3];
    assign _1466 = _670[2:2];
    assign _1465 = _670[1:1];
    assign _1464 = _670[0:0];
    assign _1463 = cfg_t1_in_base + _829;
    always @* begin
        case (_1463)
        0:
            _1472 <= _1464;
        1:
            _1472 <= _1465;
        2:
            _1472 <= _1466;
        3:
            _1472 <= _1467;
        4:
            _1472 <= _1468;
        5:
            _1472 <= _1469;
        6:
            _1472 <= _1470;
        default:
            _1472 <= _1471;
        endcase
    end
    assign _1475 = _1472 & _1474;
    assign _1459 = 5'b00111;
    assign _1460 = _1459 < _1260;
    assign _1457 = _670[7:7];
    assign _1456 = _670[6:6];
    assign _1455 = _670[5:5];
    assign _1454 = _670[4:4];
    assign _1453 = _670[3:3];
    assign _1452 = _670[2:2];
    assign _1451 = _670[1:1];
    assign _1450 = _670[0:0];
    assign _1448 = 3'b111;
    assign _1650 = _581[2:0];
    assign _1647 = 7'b1010100;
    assign _1648 = _577 == _1647;
    assign _1646 = _571 & _575;
    assign _1649 = _1646 & _1648;
    assign _1651 = _1649 ? _1650 : cfg_t1_in_base;
    assign _45 = _1651;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_in_base <= _458;
        else
            cfg_t1_in_base <= _45;
    end
    assign _1449 = cfg_t1_in_base + _1448;
    always @* begin
        case (_1449)
        0:
            _1458 <= _1450;
        1:
            _1458 <= _1451;
        2:
            _1458 <= _1452;
        3:
            _1458 <= _1453;
        4:
            _1458 <= _1454;
        5:
            _1458 <= _1455;
        6:
            _1458 <= _1456;
        default:
            _1458 <= _1457;
        endcase
    end
    assign _1461 = _1458 & _1460;
    assign _1558 = { _1461,
                     _1475,
                     _1489,
                     _1503,
                     _1517,
                     _1531,
                     _1545,
                     _1557 };
    assign _1559 = { _450,
                     _1558 };
    assign _1446 = _92[8:7];
    always @* begin
        case (_1446)
        0:
            _1567 <= _1559;
        1:
            _1567 <= t1_x;
        2:
            _1567 <= t1_y;
        default:
            _1567 <= _297;
        endcase
    end
    assign _1685 = { _1567,
                     t1_isr };
    assign _1684 = _1260[0:0];
    assign _1689 = _1684 ? _1688 : _1685;
    assign _1683 = _1260[1:1];
    assign _1693 = _1683 ? _1692 : _1689;
    assign _1682 = _1260[2:2];
    assign _1697 = _1682 ? _1696 : _1693;
    assign _1681 = _1260[3:3];
    assign _1701 = _1681 ? _1700 : _1697;
    assign _1680 = _1260[4:4];
    assign _1705 = _1680 ? _1704 : _1701;
    assign _1706 = _1705[15:0];
    assign _1737 = _1383 ? _1736 : _1706;
    assign _1739 = _1266 ? _297 : _1737;
    assign _1678 = _1224 ? t1_isr : _297;
    assign _1661 = _1345 == _843;
    assign _1674 = _1661 ? _1673 : t1_isr;
    assign _1675 = _1351 ? _1674 : t1_isr;
    assign _1659 = _1192 == _1476;
    assign _1676 = _1659 ? _1675 : t1_isr;
    assign _1658 = _1192 == _4100;
    assign _1679 = _1658 ? _1678 : _1676;
    assign _1656 = _1192 == _3956;
    assign _1740 = _1656 ? _1739 : _1679;
    assign _1741 = _1270 ? _1740 : t1_isr;
    assign _1742 = _1187 ? t1_isr : _1741;
    assign _1743 = _1181 ? t1_isr : _1742;
    assign _1745 = _1175 ? _297 : _1743;
    assign _46 = _1745;
    assign _47 = _46;
    always @(posedge _131) begin
        if (_129)
            t1_isr <= _297;
        else
            t1_isr <= _47;
    end
    assign _1783 = { _297,
                     t1_isr };
    assign _1781 = _1776[0:0];
    assign _1787 = _1781 ? _1786 : _1783;
    assign _1780 = _1776[1:1];
    assign _1791 = _1780 ? _1790 : _1787;
    assign _1779 = _1776[2:2];
    assign _1795 = _1779 ? _1794 : _1791;
    assign _1778 = _1776[3:3];
    assign _1799 = _1778 ? _1798 : _1795;
    assign _1762 = _1760[4:0];
    assign _1759 = { gnd,
                     _1260 };
    assign _1758 = { gnd,
                     t1_isr_count };
    assign _1760 = _1758 + _1759;
    assign _1757 = 6'b010000;
    assign _1761 = _1757 < _1760;
    assign _1764 = _1761 ? _890 : _1762;
    assign _1263 = { gnd,
                     cfg_t1_threshold };
    assign _1261 = { gnd,
                     _1260 };
    assign _1254 = { gnd,
                     t1_isr_count };
    assign _1262 = _1254 + _1261;
    assign _1264 = _1262 < _1263;
    assign _1265 = ~ _1264;
    assign _1249 = cfg_t1_shift[3:3];
    assign _1248 = _1192 == _3956;
    assign _1250 = _1248 & _1249;
    assign _1266 = _1250 & _1265;
    assign _1766 = _1266 ? _716 : _1764;
    assign _1755 = _1224 ? t1_isr_count : _716;
    assign _1749 = _1345 == _843;
    assign _1751 = _1749 ? _716 : t1_isr_count;
    assign _1752 = _1351 ? _1751 : t1_isr_count;
    assign _1748 = _1192 == _1476;
    assign _1753 = _1748 ? _1752 : t1_isr_count;
    assign _1747 = _1192 == _4100;
    assign _1756 = _1747 ? _1755 : _1753;
    assign _1746 = _1192 == _3956;
    assign _1767 = _1746 ? _1766 : _1756;
    assign _1768 = _1270 ? _1767 : t1_isr_count;
    assign _1769 = _1187 ? t1_isr_count : _1768;
    assign _1770 = _1181 ? t1_isr_count : _1769;
    assign _1772 = _1175 ? _716 : _1770;
    assign _48 = _1772;
    assign _49 = _48;
    always @(posedge _131) begin
        if (_129)
            t1_isr_count <= _716;
        else
            t1_isr_count <= _49;
    end
    assign _1776 = _890 - t1_isr_count;
    assign _1777 = _1776[4:4];
    assign _1803 = _1777 ? _1802 : _1799;
    assign _1804 = _1803[15:0];
    assign _1383 = cfg_t1_shift[1:1];
    assign _1832 = _1383 ? _1831 : _1804;
    assign _1774 = _1192 == _3956;
    assign _1891 = _1774 ? _1890 : _1832;
    assign _50 = _1891;
    always @(posedge _131) begin
        if (_129)
            t1_rx_mem_0 <= _297;
        else
            if (_476)
                t1_rx_mem_0 <= _50;
    end
    assign _1918 = t1_rx_rd + _216;
    assign _1915 = ~ _1914;
    assign _1910 = _1089 == _1624;
    assign _1911 = _100 & _1910;
    assign _1905 = _1089 == _1624;
    assign _1903 = _1097 == _219;
    assign _1906 = _1903 & _1905;
    assign _1907 = ~ _1906;
    assign _1899 = t1_rx_level == _458;
    assign _1900 = ~ _1899;
    assign _1895 = 7'b1011001;
    assign _1896 = _311 == _1895;
    assign _1892 = _310[7:7];
    assign _1893 = ~ _1892;
    assign _1894 = _1153 & _1893;
    assign _1897 = _1894 & _1896;
    assign _1901 = _1897 & _1900;
    assign _51 = _1901;
    assign _1908 = _51 & _1907;
    assign _1912 = _1908 | _1911;
    assign _1916 = _1912 & _1915;
    assign _1919 = _1916 ? _1918 : t1_rx_rd;
    assign _52 = _1919;
    always @(posedge _131) begin
        if (_129)
            t1_rx_rd <= _4091;
        else
            t1_rx_rd <= _52;
    end
    always @* begin
        case (t1_rx_rd)
        0:
            _496 <= t1_rx_mem_0;
        1:
            _496 <= t1_rx_mem_1;
        2:
            _496 <= t1_rx_mem_2;
        default:
            _496 <= t1_rx_mem_3;
        endcase
    end
    assign _386 = t0_rx_wr == _752;
    assign _387 = _363 & _386;
    always @(posedge _131) begin
        if (_129)
            t0_rx_mem_3 <= _297;
        else
            if (_387)
                t0_rx_mem_3 <= _72;
    end
    assign _380 = t0_rx_wr == _219;
    assign _381 = _363 & _380;
    always @(posedge _131) begin
        if (_129)
            t0_rx_mem_2 <= _297;
        else
            if (_381)
                t0_rx_mem_2 <= _72;
    end
    assign _374 = t0_rx_wr == _216;
    assign _375 = _363 & _374;
    always @(posedge _131) begin
        if (_129)
            t0_rx_mem_1 <= _297;
        else
            if (_375)
                t0_rx_mem_1 <= _72;
    end
    assign _1921 = t0_rx_wr + _216;
    assign _1922 = _363 ? _1921 : t0_rx_wr;
    assign _53 = _1922;
    always @(posedge _131) begin
        if (_129)
            t0_rx_wr <= _4091;
        else
            t0_rx_wr <= _53;
    end
    assign _368 = t0_rx_wr == _4091;
    assign _369 = _363 & _368;
    assign _3331 = _3330[15:0];
    assign _3333 = { _3331,
                     _297 };
    assign _3327 = _3326[23:0];
    assign _3329 = { _3327,
                     _450 };
    assign _3323 = _3322[27:0];
    assign _3325 = { _3323,
                     _614 };
    assign _3319 = _3318[29:0];
    assign _3321 = { _3319,
                     _4091 };
    assign _3315 = _3212[0:0];
    assign _3318 = _3315 ? _1869 : _1868;
    assign _3314 = _3212[1:1];
    assign _3322 = _3314 ? _3321 : _3318;
    assign _3313 = _3212[2:2];
    assign _3326 = _3313 ? _3325 : _3322;
    assign _3312 = _3212[3:3];
    assign _3330 = _3312 ? _3329 : _3326;
    assign _3311 = _3212[4:4];
    assign _3334 = _3311 ? _3333 : _3330;
    assign _3335 = _3334[15:0];
    assign _3336 = ~ _3335;
    assign _3337 = _3185 & _3336;
    assign _3307 = _3305[31:16];
    assign _3308 = { _297,
                     _3307 };
    assign _3303 = _3301[31:8];
    assign _3304 = { _450,
                     _3303 };
    assign _3299 = _3297[31:4];
    assign _3300 = { _614,
                     _3299 };
    assign _3295 = _3293[31:2];
    assign _3296 = { _4091,
                     _3295 };
    assign _3291 = _3289[31:1];
    assign _3292 = { _565,
                     _3291 };
    assign _3289 = { _297,
                     _3185 };
    assign _3287 = _3282[0:0];
    assign _3293 = _3287 ? _3292 : _3289;
    assign _3286 = _3282[1:1];
    assign _3297 = _3286 ? _3296 : _3293;
    assign _3285 = _3282[2:2];
    assign _3301 = _3285 ? _3300 : _3297;
    assign _3284 = _3282[3:3];
    assign _3305 = _3284 ? _3304 : _3301;
    assign _3282 = _890 - _3212;
    assign _3283 = _3282[4:4];
    assign _3309 = _3283 ? _3308 : _3305;
    assign _3310 = _3309[15:0];
    assign _3338 = _858 ? _3337 : _3310;
    assign _3273 = _3272[15:0];
    assign _3275 = { _3273,
                     _297 };
    assign _3269 = _3268[23:0];
    assign _3271 = { _3269,
                     _450 };
    assign _3265 = _3264[27:0];
    assign _3267 = { _3265,
                     _614 };
    assign _3261 = _3260[29:0];
    assign _3263 = { _3261,
                     _4091 };
    assign _3257 = t0_isr_count[0:0];
    assign _3260 = _3257 ? _1869 : _1868;
    assign _3256 = t0_isr_count[1:1];
    assign _3264 = _3256 ? _3263 : _3260;
    assign _3255 = t0_isr_count[2:2];
    assign _3268 = _3255 ? _3267 : _3264;
    assign _3254 = t0_isr_count[3:3];
    assign _3272 = _3254 ? _3271 : _3268;
    assign _3253 = t0_isr_count[4:4];
    assign _3276 = _3253 ? _3275 : _3272;
    assign _3277 = _3276[15:0];
    assign _3278 = ~ _3277;
    assign _3279 = t0_isr & _3278;
    assign _3249 = _3247[31:16];
    assign _3250 = { _297,
                     _3249 };
    assign _3245 = _3243[31:8];
    assign _3246 = { _450,
                     _3245 };
    assign _3241 = _3239[31:4];
    assign _3242 = { _614,
                     _3241 };
    assign _3237 = _3235[31:2];
    assign _3238 = { _4091,
                     _3237 };
    assign _3233 = _3231[31:1];
    assign _3234 = { _565,
                     _3233 };
    assign _883 = _882[15:0];
    assign _885 = { _883,
                    _297 };
    assign _879 = _878[23:0];
    assign _881 = { _879,
                    _450 };
    assign _875 = _874[27:0];
    assign _877 = { _875,
                    _614 };
    assign _871 = _870[29:0];
    assign _873 = { _871,
                    _4091 };
    assign _867 = _735[0:0];
    assign _870 = _867 ? _1869 : _1868;
    assign _866 = _735[1:1];
    assign _874 = _866 ? _873 : _870;
    assign _865 = _735[2:2];
    assign _878 = _865 ? _877 : _874;
    assign _864 = _735[3:3];
    assign _882 = _864 ? _881 : _878;
    assign _863 = _735[4:4];
    assign _886 = _863 ? _885 : _882;
    assign _887 = _886[15:0];
    assign _888 = ~ _887;
    assign _3183 = _1042 & _888;
    assign _3178 = _3177[15:0];
    assign _3180 = { _3178,
                     _297 };
    assign _3174 = _3173[23:0];
    assign _3176 = { _3174,
                     _450 };
    assign _3170 = _3169[27:0];
    assign _3172 = { _3170,
                     _614 };
    assign _3166 = _3165[29:0];
    assign _3168 = { _3166,
                     _4091 };
    assign _3162 = _3161[30:0];
    assign _3164 = { _3162,
                     _565 };
    assign _3161 = { _297,
                     t0_isr };
    assign _3159 = _735[0:0];
    assign _3165 = _3159 ? _3164 : _3161;
    assign _3158 = _735[1:1];
    assign _3169 = _3158 ? _3168 : _3165;
    assign _3157 = _735[2:2];
    assign _3173 = _3157 ? _3172 : _3169;
    assign _3156 = _735[3:3];
    assign _3177 = _3156 ? _3176 : _3173;
    assign _3155 = _735[4:4];
    assign _3181 = _3155 ? _3180 : _3177;
    assign _3182 = _3181[15:0];
    assign _3184 = _3182 | _3183;
    assign _3151 = _3149[31:16];
    assign _3152 = { _297,
                     _3151 };
    assign _3147 = _3145[31:8];
    assign _3148 = { _450,
                     _3147 };
    assign _3143 = _3141[31:4];
    assign _3144 = { _614,
                     _3143 };
    assign _3139 = _3137[31:2];
    assign _3140 = { _4091,
                     _3139 };
    assign _3135 = _3133[31:1];
    assign _3136 = { _565,
                     _3135 };
    assign _1031 = _716 < _735;
    assign _1028 = _670[7:7];
    assign _1027 = _670[6:6];
    assign _1026 = _670[5:5];
    assign _1025 = _670[4:4];
    assign _1024 = _670[3:3];
    assign _1023 = _670[2:2];
    assign _1022 = _670[1:1];
    assign _1021 = _670[0:0];
    always @* begin
        case (cfg_t0_in_base)
        0:
            _1029 <= _1021;
        1:
            _1029 <= _1022;
        2:
            _1029 <= _1023;
        3:
            _1029 <= _1024;
        4:
            _1029 <= _1025;
        5:
            _1029 <= _1026;
        6:
            _1029 <= _1027;
        default:
            _1029 <= _1028;
        endcase
    end
    assign _1032 = _1029 & _1031;
    assign _1019 = _1046 < _735;
    assign _1016 = _670[7:7];
    assign _1015 = _670[6:6];
    assign _1014 = _670[5:5];
    assign _1013 = _670[4:4];
    assign _1012 = _670[3:3];
    assign _1011 = _670[2:2];
    assign _1010 = _670[1:1];
    assign _1009 = _670[0:0];
    assign _1008 = cfg_t0_in_base + _618;
    always @* begin
        case (_1008)
        0:
            _1017 <= _1009;
        1:
            _1017 <= _1010;
        2:
            _1017 <= _1011;
        3:
            _1017 <= _1012;
        4:
            _1017 <= _1013;
        5:
            _1017 <= _1014;
        6:
            _1017 <= _1015;
        default:
            _1017 <= _1016;
        endcase
    end
    assign _1020 = _1017 & _1019;
    assign _1005 = _1529 < _735;
    assign _1002 = _670[7:7];
    assign _1001 = _670[6:6];
    assign _1000 = _670[5:5];
    assign _999 = _670[4:4];
    assign _998 = _670[3:3];
    assign _997 = _670[2:2];
    assign _996 = _670[1:1];
    assign _995 = _670[0:0];
    assign _994 = cfg_t0_in_base + _3956;
    always @* begin
        case (_994)
        0:
            _1003 <= _995;
        1:
            _1003 <= _996;
        2:
            _1003 <= _997;
        3:
            _1003 <= _998;
        4:
            _1003 <= _999;
        5:
            _1003 <= _1000;
        6:
            _1003 <= _1001;
        default:
            _1003 <= _1002;
        endcase
    end
    assign _1006 = _1003 & _1005;
    assign _991 = _1515 < _735;
    assign _988 = _670[7:7];
    assign _987 = _670[6:6];
    assign _986 = _670[5:5];
    assign _985 = _670[4:4];
    assign _984 = _670[3:3];
    assign _983 = _670[2:2];
    assign _982 = _670[1:1];
    assign _981 = _670[0:0];
    assign _980 = cfg_t0_in_base + _843;
    always @* begin
        case (_980)
        0:
            _989 <= _981;
        1:
            _989 <= _982;
        2:
            _989 <= _983;
        3:
            _989 <= _984;
        4:
            _989 <= _985;
        5:
            _989 <= _986;
        6:
            _989 <= _987;
        default:
            _989 <= _988;
        endcase
    end
    assign _992 = _989 & _991;
    assign _977 = _1501 < _735;
    assign _974 = _670[7:7];
    assign _973 = _670[6:6];
    assign _972 = _670[5:5];
    assign _971 = _670[4:4];
    assign _970 = _670[3:3];
    assign _969 = _670[2:2];
    assign _968 = _670[1:1];
    assign _967 = _670[0:0];
    assign _966 = cfg_t0_in_base + _4100;
    always @* begin
        case (_966)
        0:
            _975 <= _967;
        1:
            _975 <= _968;
        2:
            _975 <= _969;
        3:
            _975 <= _970;
        4:
            _975 <= _971;
        5:
            _975 <= _972;
        6:
            _975 <= _973;
        default:
            _975 <= _974;
        endcase
    end
    assign _978 = _975 & _977;
    assign _963 = _1487 < _735;
    assign _960 = _670[7:7];
    assign _959 = _670[6:6];
    assign _958 = _670[5:5];
    assign _957 = _670[4:4];
    assign _956 = _670[3:3];
    assign _955 = _670[2:2];
    assign _954 = _670[1:1];
    assign _953 = _670[0:0];
    assign _952 = cfg_t0_in_base + _1476;
    always @* begin
        case (_952)
        0:
            _961 <= _953;
        1:
            _961 <= _954;
        2:
            _961 <= _955;
        3:
            _961 <= _956;
        4:
            _961 <= _957;
        5:
            _961 <= _958;
        6:
            _961 <= _959;
        default:
            _961 <= _960;
        endcase
    end
    assign _964 = _961 & _963;
    assign _949 = _1473 < _735;
    assign _946 = _670[7:7];
    assign _945 = _670[6:6];
    assign _944 = _670[5:5];
    assign _943 = _670[4:4];
    assign _942 = _670[3:3];
    assign _941 = _670[2:2];
    assign _940 = _670[1:1];
    assign _939 = _670[0:0];
    assign _938 = cfg_t0_in_base + _829;
    always @* begin
        case (_938)
        0:
            _947 <= _939;
        1:
            _947 <= _940;
        2:
            _947 <= _941;
        3:
            _947 <= _942;
        4:
            _947 <= _943;
        5:
            _947 <= _944;
        6:
            _947 <= _945;
        default:
            _947 <= _946;
        endcase
    end
    assign _950 = _947 & _949;
    assign _935 = _1459 < _735;
    assign _932 = _670[7:7];
    assign _931 = _670[6:6];
    assign _930 = _670[5:5];
    assign _929 = _670[4:4];
    assign _928 = _670[3:3];
    assign _927 = _670[2:2];
    assign _926 = _670[1:1];
    assign _668 = _667 & _666;
    assign _667 = pin_out[0:0];
    assign _666 = _630[0:0];
    assign _665 = cfg_pin_modes[1:0];
    always @* begin
        case (_665)
        0:
            _669 <= _666;
        1:
            _669 <= _667;
        2:
            _669 <= _668;
        default:
            _669 <= _666;
        endcase
    end
    assign _663 = _662 & _661;
    assign _662 = pin_out[1:1];
    assign _661 = _630[1:1];
    assign _660 = cfg_pin_modes[3:2];
    always @* begin
        case (_660)
        0:
            _664 <= _661;
        1:
            _664 <= _662;
        2:
            _664 <= _663;
        default:
            _664 <= _661;
        endcase
    end
    assign _658 = _657 & _656;
    assign _657 = pin_out[2:2];
    assign _656 = _630[2:2];
    assign _655 = cfg_pin_modes[5:4];
    always @* begin
        case (_655)
        0:
            _659 <= _656;
        1:
            _659 <= _657;
        2:
            _659 <= _658;
        default:
            _659 <= _656;
        endcase
    end
    assign _653 = _652 & _651;
    assign _652 = pin_out[3:3];
    assign _651 = _630[3:3];
    assign _650 = cfg_pin_modes[7:6];
    always @* begin
        case (_650)
        0:
            _654 <= _651;
        1:
            _654 <= _652;
        2:
            _654 <= _653;
        default:
            _654 <= _651;
        endcase
    end
    assign _648 = _647 & _646;
    assign _647 = pin_out[4:4];
    assign _646 = _630[4:4];
    assign _645 = cfg_pin_modes[9:8];
    always @* begin
        case (_645)
        0:
            _649 <= _646;
        1:
            _649 <= _647;
        2:
            _649 <= _648;
        default:
            _649 <= _646;
        endcase
    end
    assign _643 = _642 & _641;
    assign _642 = pin_out[5:5];
    assign _641 = _630[5:5];
    assign _640 = cfg_pin_modes[11:10];
    always @* begin
        case (_640)
        0:
            _644 <= _641;
        1:
            _644 <= _642;
        2:
            _644 <= _643;
        default:
            _644 <= _641;
        endcase
    end
    assign _638 = _637 & _636;
    assign _637 = pin_out[6:6];
    assign _636 = _630[6:6];
    assign _635 = cfg_pin_modes[13:12];
    always @* begin
        case (_635)
        0:
            _639 <= _636;
        1:
            _639 <= _637;
        2:
            _639 <= _638;
        default:
            _639 <= _636;
        endcase
    end
    assign _633 = _632 & _631;
    assign _149 = 8'b11111111;
    assign _3091 = _2964[7:7];
    assign _3090 = _2964[6:6];
    assign _3089 = _2964[5:5];
    assign _3088 = _2964[4:4];
    assign _3087 = _2964[3:3];
    assign _3086 = _2964[2:2];
    assign _3085 = _2964[1:1];
    assign _3084 = _2964[0:0];
    always @* begin
        case (_3078)
        0:
            _3092 <= _3084;
        1:
            _3092 <= _3085;
        2:
            _3092 <= _3086;
        3:
            _3092 <= _3087;
        4:
            _3092 <= _3088;
        5:
            _3092 <= _3089;
        6:
            _3092 <= _3090;
        default:
            _3092 <= _3091;
        endcase
    end
    assign _3083 = _2944[0:0];
    assign _3081 = { _4091,
                     _2541 };
    assign _3078 = _458 - _2537;
    assign _3079 = { gnd,
                     _3078 };
    assign _3082 = _3079 < _3081;
    assign _3093 = _3082 ? _3092 : _3083;
    assign _3074 = _2964[7:7];
    assign _3073 = _2964[6:6];
    assign _3072 = _2964[5:5];
    assign _3071 = _2964[4:4];
    assign _3070 = _2964[3:3];
    assign _3069 = _2964[2:2];
    assign _3068 = _2964[1:1];
    assign _3067 = _2964[0:0];
    always @* begin
        case (_3061)
        0:
            _3075 <= _3067;
        1:
            _3075 <= _3068;
        2:
            _3075 <= _3069;
        3:
            _3075 <= _3070;
        4:
            _3075 <= _3071;
        5:
            _3075 <= _3072;
        6:
            _3075 <= _3073;
        default:
            _3075 <= _3074;
        endcase
    end
    assign _3066 = _2944[1:1];
    assign _3064 = { _4091,
                     _2541 };
    assign _3061 = _618 - _2537;
    assign _3062 = { gnd,
                     _3061 };
    assign _3065 = _3062 < _3064;
    assign _3076 = _3065 ? _3075 : _3066;
    assign _3057 = _2964[7:7];
    assign _3056 = _2964[6:6];
    assign _3055 = _2964[5:5];
    assign _3054 = _2964[4:4];
    assign _3053 = _2964[3:3];
    assign _3052 = _2964[2:2];
    assign _3051 = _2964[1:1];
    assign _3050 = _2964[0:0];
    always @* begin
        case (_3044)
        0:
            _3058 <= _3050;
        1:
            _3058 <= _3051;
        2:
            _3058 <= _3052;
        3:
            _3058 <= _3053;
        4:
            _3058 <= _3054;
        5:
            _3058 <= _3055;
        6:
            _3058 <= _3056;
        default:
            _3058 <= _3057;
        endcase
    end
    assign _3049 = _2944[2:2];
    assign _3047 = { _4091,
                     _2541 };
    assign _3044 = _3956 - _2537;
    assign _3045 = { gnd,
                     _3044 };
    assign _3048 = _3045 < _3047;
    assign _3059 = _3048 ? _3058 : _3049;
    assign _3040 = _2964[7:7];
    assign _3039 = _2964[6:6];
    assign _3038 = _2964[5:5];
    assign _3037 = _2964[4:4];
    assign _3036 = _2964[3:3];
    assign _3035 = _2964[2:2];
    assign _3034 = _2964[1:1];
    assign _3033 = _2964[0:0];
    always @* begin
        case (_3027)
        0:
            _3041 <= _3033;
        1:
            _3041 <= _3034;
        2:
            _3041 <= _3035;
        3:
            _3041 <= _3036;
        4:
            _3041 <= _3037;
        5:
            _3041 <= _3038;
        6:
            _3041 <= _3039;
        default:
            _3041 <= _3040;
        endcase
    end
    assign _3032 = _2944[3:3];
    assign _3030 = { _4091,
                     _2541 };
    assign _3027 = _843 - _2537;
    assign _3028 = { gnd,
                     _3027 };
    assign _3031 = _3028 < _3030;
    assign _3042 = _3031 ? _3041 : _3032;
    assign _3023 = _2964[7:7];
    assign _3022 = _2964[6:6];
    assign _3021 = _2964[5:5];
    assign _3020 = _2964[4:4];
    assign _3019 = _2964[3:3];
    assign _3018 = _2964[2:2];
    assign _3017 = _2964[1:1];
    assign _3016 = _2964[0:0];
    always @* begin
        case (_3010)
        0:
            _3024 <= _3016;
        1:
            _3024 <= _3017;
        2:
            _3024 <= _3018;
        3:
            _3024 <= _3019;
        4:
            _3024 <= _3020;
        5:
            _3024 <= _3021;
        6:
            _3024 <= _3022;
        default:
            _3024 <= _3023;
        endcase
    end
    assign _3015 = _2944[4:4];
    assign _3013 = { _4091,
                     _2541 };
    assign _3010 = _4100 - _2537;
    assign _3011 = { gnd,
                     _3010 };
    assign _3014 = _3011 < _3013;
    assign _3025 = _3014 ? _3024 : _3015;
    assign _3006 = _2964[7:7];
    assign _3005 = _2964[6:6];
    assign _3004 = _2964[5:5];
    assign _3003 = _2964[4:4];
    assign _3002 = _2964[3:3];
    assign _3001 = _2964[2:2];
    assign _3000 = _2964[1:1];
    assign _2999 = _2964[0:0];
    always @* begin
        case (_2993)
        0:
            _3007 <= _2999;
        1:
            _3007 <= _3000;
        2:
            _3007 <= _3001;
        3:
            _3007 <= _3002;
        4:
            _3007 <= _3003;
        5:
            _3007 <= _3004;
        6:
            _3007 <= _3005;
        default:
            _3007 <= _3006;
        endcase
    end
    assign _2998 = _2944[5:5];
    assign _2996 = { _4091,
                     _2541 };
    assign _2993 = _1476 - _2537;
    assign _2994 = { gnd,
                     _2993 };
    assign _2997 = _2994 < _2996;
    assign _3008 = _2997 ? _3007 : _2998;
    assign _2989 = _2964[7:7];
    assign _2988 = _2964[6:6];
    assign _2987 = _2964[5:5];
    assign _2986 = _2964[4:4];
    assign _2985 = _2964[3:3];
    assign _2984 = _2964[2:2];
    assign _2983 = _2964[1:1];
    assign _2982 = _2964[0:0];
    always @* begin
        case (_2976)
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
    assign _2981 = _2944[6:6];
    assign _2979 = { _4091,
                     _2541 };
    assign _2976 = _829 - _2537;
    assign _2977 = { gnd,
                     _2976 };
    assign _2980 = _2977 < _2979;
    assign _2991 = _2980 ? _2990 : _2981;
    assign _2972 = _2964[7:7];
    assign _2971 = _2964[6:6];
    assign _2970 = _2964[5:5];
    assign _2969 = _2964[4:4];
    assign _2968 = _2964[3:3];
    assign _2967 = _2964[2:2];
    assign _2966 = _2964[1:1];
    assign _2959 = _2957[3:2];
    assign _2960 = { _4091,
                     _2959 };
    assign _2955 = _2953[3:1];
    assign _2956 = { _565,
                     _2955 };
    assign _2953 = _92[12:9];
    assign _2952 = _2949[0:0];
    assign _2957 = _2952 ? _2956 : _2953;
    assign _2951 = _2949[1:1];
    assign _2961 = _2951 ? _2960 : _2957;
    assign _2948 = { gnd,
                     _2541 };
    assign _2949 = _4100 - _2948;
    assign _2950 = _2949[2:2];
    assign _2963 = _2950 ? _614 : _2961;
    assign _2964 = { _614,
                     _2963 };
    assign _2965 = _2964[0:0];
    always @* begin
        case (_2538)
        0:
            _2973 <= _2965;
        1:
            _2973 <= _2966;
        2:
            _2973 <= _2967;
        3:
            _2973 <= _2968;
        4:
            _2973 <= _2969;
        5:
            _2973 <= _2970;
        6:
            _2973 <= _2971;
        default:
            _2973 <= _2972;
        endcase
    end
    assign _2940 = _1445[7:7];
    assign _2939 = _1445[6:6];
    assign _2938 = _1445[5:5];
    assign _2937 = _1445[4:4];
    assign _2936 = _1445[3:3];
    assign _2935 = _1445[2:2];
    assign _2934 = _1445[1:1];
    assign _2933 = _1445[0:0];
    always @* begin
        case (_2929)
        0:
            _2941 <= _2933;
        1:
            _2941 <= _2934;
        2:
            _2941 <= _2935;
        3:
            _2941 <= _2936;
        4:
            _2941 <= _2937;
        5:
            _2941 <= _2938;
        6:
            _2941 <= _2939;
        default:
            _2941 <= _2940;
        endcase
    end
    assign _2932 = _59[0:0];
    assign _2929 = _458 - _2692;
    assign _2930 = { _4091,
                     _2929 };
    assign _2931 = _2930 < _1260;
    assign _2942 = _2931 ? _2941 : _2932;
    assign _2924 = _1445[7:7];
    assign _2923 = _1445[6:6];
    assign _2922 = _1445[5:5];
    assign _2921 = _1445[4:4];
    assign _2920 = _1445[3:3];
    assign _2919 = _1445[2:2];
    assign _2918 = _1445[1:1];
    assign _2917 = _1445[0:0];
    always @* begin
        case (_2913)
        0:
            _2925 <= _2917;
        1:
            _2925 <= _2918;
        2:
            _2925 <= _2919;
        3:
            _2925 <= _2920;
        4:
            _2925 <= _2921;
        5:
            _2925 <= _2922;
        6:
            _2925 <= _2923;
        default:
            _2925 <= _2924;
        endcase
    end
    assign _2916 = _59[1:1];
    assign _2913 = _618 - _2692;
    assign _2914 = { _4091,
                     _2913 };
    assign _2915 = _2914 < _1260;
    assign _2926 = _2915 ? _2925 : _2916;
    assign _2908 = _1445[7:7];
    assign _2907 = _1445[6:6];
    assign _2906 = _1445[5:5];
    assign _2905 = _1445[4:4];
    assign _2904 = _1445[3:3];
    assign _2903 = _1445[2:2];
    assign _2902 = _1445[1:1];
    assign _2901 = _1445[0:0];
    always @* begin
        case (_2897)
        0:
            _2909 <= _2901;
        1:
            _2909 <= _2902;
        2:
            _2909 <= _2903;
        3:
            _2909 <= _2904;
        4:
            _2909 <= _2905;
        5:
            _2909 <= _2906;
        6:
            _2909 <= _2907;
        default:
            _2909 <= _2908;
        endcase
    end
    assign _2900 = _59[2:2];
    assign _2897 = _3956 - _2692;
    assign _2898 = { _4091,
                     _2897 };
    assign _2899 = _2898 < _1260;
    assign _2910 = _2899 ? _2909 : _2900;
    assign _2892 = _1445[7:7];
    assign _2891 = _1445[6:6];
    assign _2890 = _1445[5:5];
    assign _2889 = _1445[4:4];
    assign _2888 = _1445[3:3];
    assign _2887 = _1445[2:2];
    assign _2886 = _1445[1:1];
    assign _2885 = _1445[0:0];
    always @* begin
        case (_2881)
        0:
            _2893 <= _2885;
        1:
            _2893 <= _2886;
        2:
            _2893 <= _2887;
        3:
            _2893 <= _2888;
        4:
            _2893 <= _2889;
        5:
            _2893 <= _2890;
        6:
            _2893 <= _2891;
        default:
            _2893 <= _2892;
        endcase
    end
    assign _2884 = _59[3:3];
    assign _2881 = _843 - _2692;
    assign _2882 = { _4091,
                     _2881 };
    assign _2883 = _2882 < _1260;
    assign _2894 = _2883 ? _2893 : _2884;
    assign _2876 = _1445[7:7];
    assign _2875 = _1445[6:6];
    assign _2874 = _1445[5:5];
    assign _2873 = _1445[4:4];
    assign _2872 = _1445[3:3];
    assign _2871 = _1445[2:2];
    assign _2870 = _1445[1:1];
    assign _2869 = _1445[0:0];
    always @* begin
        case (_2865)
        0:
            _2877 <= _2869;
        1:
            _2877 <= _2870;
        2:
            _2877 <= _2871;
        3:
            _2877 <= _2872;
        4:
            _2877 <= _2873;
        5:
            _2877 <= _2874;
        6:
            _2877 <= _2875;
        default:
            _2877 <= _2876;
        endcase
    end
    assign _2868 = _59[4:4];
    assign _2865 = _4100 - _2692;
    assign _2866 = { _4091,
                     _2865 };
    assign _2867 = _2866 < _1260;
    assign _2878 = _2867 ? _2877 : _2868;
    assign _2860 = _1445[7:7];
    assign _2859 = _1445[6:6];
    assign _2858 = _1445[5:5];
    assign _2857 = _1445[4:4];
    assign _2856 = _1445[3:3];
    assign _2855 = _1445[2:2];
    assign _2854 = _1445[1:1];
    assign _2853 = _1445[0:0];
    always @* begin
        case (_2849)
        0:
            _2861 <= _2853;
        1:
            _2861 <= _2854;
        2:
            _2861 <= _2855;
        3:
            _2861 <= _2856;
        4:
            _2861 <= _2857;
        5:
            _2861 <= _2858;
        6:
            _2861 <= _2859;
        default:
            _2861 <= _2860;
        endcase
    end
    assign _2852 = _59[5:5];
    assign _2849 = _1476 - _2692;
    assign _2850 = { _4091,
                     _2849 };
    assign _2851 = _2850 < _1260;
    assign _2862 = _2851 ? _2861 : _2852;
    assign _2844 = _1445[7:7];
    assign _2843 = _1445[6:6];
    assign _2842 = _1445[5:5];
    assign _2841 = _1445[4:4];
    assign _2840 = _1445[3:3];
    assign _2839 = _1445[2:2];
    assign _2838 = _1445[1:1];
    assign _2837 = _1445[0:0];
    always @* begin
        case (_2833)
        0:
            _2845 <= _2837;
        1:
            _2845 <= _2838;
        2:
            _2845 <= _2839;
        3:
            _2845 <= _2840;
        4:
            _2845 <= _2841;
        5:
            _2845 <= _2842;
        6:
            _2845 <= _2843;
        default:
            _2845 <= _2844;
        endcase
    end
    assign _2836 = _59[6:6];
    assign _2833 = _829 - _2692;
    assign _2834 = { _4091,
                     _2833 };
    assign _2835 = _2834 < _1260;
    assign _2846 = _2835 ? _2845 : _2836;
    assign _2828 = _1445[7:7];
    assign _2827 = _1445[6:6];
    assign _2826 = _1445[5:5];
    assign _2825 = _1445[4:4];
    assign _2824 = _1445[3:3];
    assign _2823 = _1445[2:2];
    assign _2822 = _1445[1:1];
    assign _2821 = _1445[0:0];
    always @* begin
        case (_2817)
        0:
            _2829 <= _2821;
        1:
            _2829 <= _2822;
        2:
            _2829 <= _2823;
        3:
            _2829 <= _2824;
        4:
            _2829 <= _2825;
        5:
            _2829 <= _2826;
        6:
            _2829 <= _2827;
        default:
            _2829 <= _2828;
        endcase
    end
    assign _2820 = _59[7:7];
    assign _2817 = _1448 - _2692;
    assign _2818 = { _4091,
                     _2817 };
    assign _2819 = _2818 < _1260;
    assign _2830 = _2819 ? _2829 : _2820;
    assign _2943 = { _2830,
                     _2846,
                     _2862,
                     _2878,
                     _2894,
                     _2910,
                     _2926,
                     _2942 };
    assign _2810 = _1673[7:7];
    assign _2809 = _1673[6:6];
    assign _2808 = _1673[5:5];
    assign _2807 = _1673[4:4];
    assign _2806 = _1673[3:3];
    assign _2805 = _1673[2:2];
    assign _2804 = _1673[1:1];
    assign _2803 = _1673[0:0];
    always @* begin
        case (_2799)
        0:
            _2811 <= _2803;
        1:
            _2811 <= _2804;
        2:
            _2811 <= _2805;
        3:
            _2811 <= _2806;
        4:
            _2811 <= _2807;
        5:
            _2811 <= _2808;
        6:
            _2811 <= _2809;
        default:
            _2811 <= _2810;
        endcase
    end
    assign _2802 = _59[0:0];
    assign _2799 = _458 - _2692;
    assign _2800 = { gnd,
                     _2799 };
    assign _2801 = _2800 < _2695;
    assign _2812 = _2801 ? _2811 : _2802;
    assign _2795 = _1673[7:7];
    assign _2794 = _1673[6:6];
    assign _2793 = _1673[5:5];
    assign _2792 = _1673[4:4];
    assign _2791 = _1673[3:3];
    assign _2790 = _1673[2:2];
    assign _2789 = _1673[1:1];
    assign _2788 = _1673[0:0];
    always @* begin
        case (_2784)
        0:
            _2796 <= _2788;
        1:
            _2796 <= _2789;
        2:
            _2796 <= _2790;
        3:
            _2796 <= _2791;
        4:
            _2796 <= _2792;
        5:
            _2796 <= _2793;
        6:
            _2796 <= _2794;
        default:
            _2796 <= _2795;
        endcase
    end
    assign _2787 = _59[1:1];
    assign _2784 = _618 - _2692;
    assign _2785 = { gnd,
                     _2784 };
    assign _2786 = _2785 < _2695;
    assign _2797 = _2786 ? _2796 : _2787;
    assign _2780 = _1673[7:7];
    assign _2779 = _1673[6:6];
    assign _2778 = _1673[5:5];
    assign _2777 = _1673[4:4];
    assign _2776 = _1673[3:3];
    assign _2775 = _1673[2:2];
    assign _2774 = _1673[1:1];
    assign _2773 = _1673[0:0];
    always @* begin
        case (_2769)
        0:
            _2781 <= _2773;
        1:
            _2781 <= _2774;
        2:
            _2781 <= _2775;
        3:
            _2781 <= _2776;
        4:
            _2781 <= _2777;
        5:
            _2781 <= _2778;
        6:
            _2781 <= _2779;
        default:
            _2781 <= _2780;
        endcase
    end
    assign _2772 = _59[2:2];
    assign _2769 = _3956 - _2692;
    assign _2770 = { gnd,
                     _2769 };
    assign _2771 = _2770 < _2695;
    assign _2782 = _2771 ? _2781 : _2772;
    assign _2765 = _1673[7:7];
    assign _2764 = _1673[6:6];
    assign _2763 = _1673[5:5];
    assign _2762 = _1673[4:4];
    assign _2761 = _1673[3:3];
    assign _2760 = _1673[2:2];
    assign _2759 = _1673[1:1];
    assign _2758 = _1673[0:0];
    always @* begin
        case (_2754)
        0:
            _2766 <= _2758;
        1:
            _2766 <= _2759;
        2:
            _2766 <= _2760;
        3:
            _2766 <= _2761;
        4:
            _2766 <= _2762;
        5:
            _2766 <= _2763;
        6:
            _2766 <= _2764;
        default:
            _2766 <= _2765;
        endcase
    end
    assign _2757 = _59[3:3];
    assign _2754 = _843 - _2692;
    assign _2755 = { gnd,
                     _2754 };
    assign _2756 = _2755 < _2695;
    assign _2767 = _2756 ? _2766 : _2757;
    assign _2750 = _1673[7:7];
    assign _2749 = _1673[6:6];
    assign _2748 = _1673[5:5];
    assign _2747 = _1673[4:4];
    assign _2746 = _1673[3:3];
    assign _2745 = _1673[2:2];
    assign _2744 = _1673[1:1];
    assign _2743 = _1673[0:0];
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
    assign _2742 = _59[4:4];
    assign _2739 = _4100 - _2692;
    assign _2740 = { gnd,
                     _2739 };
    assign _2741 = _2740 < _2695;
    assign _2752 = _2741 ? _2751 : _2742;
    assign _2735 = _1673[7:7];
    assign _2734 = _1673[6:6];
    assign _2733 = _1673[5:5];
    assign _2732 = _1673[4:4];
    assign _2731 = _1673[3:3];
    assign _2730 = _1673[2:2];
    assign _2729 = _1673[1:1];
    assign _2728 = _1673[0:0];
    always @* begin
        case (_2724)
        0:
            _2736 <= _2728;
        1:
            _2736 <= _2729;
        2:
            _2736 <= _2730;
        3:
            _2736 <= _2731;
        4:
            _2736 <= _2732;
        5:
            _2736 <= _2733;
        6:
            _2736 <= _2734;
        default:
            _2736 <= _2735;
        endcase
    end
    assign _2727 = _59[5:5];
    assign _2724 = _1476 - _2692;
    assign _2725 = { gnd,
                     _2724 };
    assign _2726 = _2725 < _2695;
    assign _2737 = _2726 ? _2736 : _2727;
    assign _2720 = _1673[7:7];
    assign _2719 = _1673[6:6];
    assign _2718 = _1673[5:5];
    assign _2717 = _1673[4:4];
    assign _2716 = _1673[3:3];
    assign _2715 = _1673[2:2];
    assign _2714 = _1673[1:1];
    assign _2713 = _1673[0:0];
    always @* begin
        case (_2709)
        0:
            _2721 <= _2713;
        1:
            _2721 <= _2714;
        2:
            _2721 <= _2715;
        3:
            _2721 <= _2716;
        4:
            _2721 <= _2717;
        5:
            _2721 <= _2718;
        6:
            _2721 <= _2719;
        default:
            _2721 <= _2720;
        endcase
    end
    assign _2712 = _59[6:6];
    assign _2709 = _829 - _2692;
    assign _2710 = { gnd,
                     _2709 };
    assign _2711 = _2710 < _2695;
    assign _2722 = _2711 ? _2721 : _2712;
    assign _2705 = _1673[7:7];
    assign _2704 = _1673[6:6];
    assign _2703 = _1673[5:5];
    assign _2702 = _1673[4:4];
    assign _2701 = _1673[3:3];
    assign _2700 = _1673[2:2];
    assign _2699 = _1673[1:1];
    assign _2698 = _1673[0:0];
    always @* begin
        case (_2693)
        0:
            _2706 <= _2698;
        1:
            _2706 <= _2699;
        2:
            _2706 <= _2700;
        3:
            _2706 <= _2701;
        4:
            _2706 <= _2702;
        5:
            _2706 <= _2703;
        6:
            _2706 <= _2704;
        default:
            _2706 <= _2705;
        endcase
    end
    assign _2697 = _59[7:7];
    assign _2695 = cfg_t1_out_cfg[7:4];
    assign _432 = 8'b00010000;
    assign _1927 = _581[7:0];
    assign _1924 = 7'b1010010;
    assign _1925 = _577 == _1924;
    assign _1923 = _571 & _575;
    assign _1926 = _1923 & _1925;
    assign _1928 = _1926 ? _1927 : cfg_t1_out_cfg;
    assign _54 = _1928;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_out_cfg <= _432;
        else
            cfg_t1_out_cfg <= _54;
    end
    assign _2692 = cfg_t1_out_cfg[2:0];
    assign _2693 = _1448 - _2692;
    assign _2694 = { gnd,
                     _2693 };
    assign _2696 = _2694 < _2695;
    assign _2707 = _2696 ? _2706 : _2697;
    assign _2813 = { _2707,
                     _2722,
                     _2737,
                     _2752,
                     _2767,
                     _2782,
                     _2797,
                     _2812 };
    assign _2686 = _2573[7:7];
    assign _2685 = _2573[6:6];
    assign _2684 = _2573[5:5];
    assign _2683 = _2573[4:4];
    assign _2682 = _2573[3:3];
    assign _2681 = _2573[2:2];
    assign _2680 = _2573[1:1];
    assign _2679 = _2573[0:0];
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
    assign _2678 = _59[0:0];
    assign _2675 = _458 - _2565;
    assign _2676 = { gnd,
                     _2675 };
    assign _2677 = _2676 < _2568;
    assign _2688 = _2677 ? _2687 : _2678;
    assign _2671 = _2573[7:7];
    assign _2670 = _2573[6:6];
    assign _2669 = _2573[5:5];
    assign _2668 = _2573[4:4];
    assign _2667 = _2573[3:3];
    assign _2666 = _2573[2:2];
    assign _2665 = _2573[1:1];
    assign _2664 = _2573[0:0];
    always @* begin
        case (_2660)
        0:
            _2672 <= _2664;
        1:
            _2672 <= _2665;
        2:
            _2672 <= _2666;
        3:
            _2672 <= _2667;
        4:
            _2672 <= _2668;
        5:
            _2672 <= _2669;
        6:
            _2672 <= _2670;
        default:
            _2672 <= _2671;
        endcase
    end
    assign _2663 = _59[1:1];
    assign _2660 = _618 - _2565;
    assign _2661 = { gnd,
                     _2660 };
    assign _2662 = _2661 < _2568;
    assign _2673 = _2662 ? _2672 : _2663;
    assign _2656 = _2573[7:7];
    assign _2655 = _2573[6:6];
    assign _2654 = _2573[5:5];
    assign _2653 = _2573[4:4];
    assign _2652 = _2573[3:3];
    assign _2651 = _2573[2:2];
    assign _2650 = _2573[1:1];
    assign _2649 = _2573[0:0];
    always @* begin
        case (_2645)
        0:
            _2657 <= _2649;
        1:
            _2657 <= _2650;
        2:
            _2657 <= _2651;
        3:
            _2657 <= _2652;
        4:
            _2657 <= _2653;
        5:
            _2657 <= _2654;
        6:
            _2657 <= _2655;
        default:
            _2657 <= _2656;
        endcase
    end
    assign _2648 = _59[2:2];
    assign _2645 = _3956 - _2565;
    assign _2646 = { gnd,
                     _2645 };
    assign _2647 = _2646 < _2568;
    assign _2658 = _2647 ? _2657 : _2648;
    assign _2641 = _2573[7:7];
    assign _2640 = _2573[6:6];
    assign _2639 = _2573[5:5];
    assign _2638 = _2573[4:4];
    assign _2637 = _2573[3:3];
    assign _2636 = _2573[2:2];
    assign _2635 = _2573[1:1];
    assign _2634 = _2573[0:0];
    always @* begin
        case (_2630)
        0:
            _2642 <= _2634;
        1:
            _2642 <= _2635;
        2:
            _2642 <= _2636;
        3:
            _2642 <= _2637;
        4:
            _2642 <= _2638;
        5:
            _2642 <= _2639;
        6:
            _2642 <= _2640;
        default:
            _2642 <= _2641;
        endcase
    end
    assign _2633 = _59[3:3];
    assign _2630 = _843 - _2565;
    assign _2631 = { gnd,
                     _2630 };
    assign _2632 = _2631 < _2568;
    assign _2643 = _2632 ? _2642 : _2633;
    assign _2626 = _2573[7:7];
    assign _2625 = _2573[6:6];
    assign _2624 = _2573[5:5];
    assign _2623 = _2573[4:4];
    assign _2622 = _2573[3:3];
    assign _2621 = _2573[2:2];
    assign _2620 = _2573[1:1];
    assign _2619 = _2573[0:0];
    always @* begin
        case (_2615)
        0:
            _2627 <= _2619;
        1:
            _2627 <= _2620;
        2:
            _2627 <= _2621;
        3:
            _2627 <= _2622;
        4:
            _2627 <= _2623;
        5:
            _2627 <= _2624;
        6:
            _2627 <= _2625;
        default:
            _2627 <= _2626;
        endcase
    end
    assign _2618 = _59[4:4];
    assign _2615 = _4100 - _2565;
    assign _2616 = { gnd,
                     _2615 };
    assign _2617 = _2616 < _2568;
    assign _2628 = _2617 ? _2627 : _2618;
    assign _2611 = _2573[7:7];
    assign _2610 = _2573[6:6];
    assign _2609 = _2573[5:5];
    assign _2608 = _2573[4:4];
    assign _2607 = _2573[3:3];
    assign _2606 = _2573[2:2];
    assign _2605 = _2573[1:1];
    assign _2604 = _2573[0:0];
    always @* begin
        case (_2600)
        0:
            _2612 <= _2604;
        1:
            _2612 <= _2605;
        2:
            _2612 <= _2606;
        3:
            _2612 <= _2607;
        4:
            _2612 <= _2608;
        5:
            _2612 <= _2609;
        6:
            _2612 <= _2610;
        default:
            _2612 <= _2611;
        endcase
    end
    assign _2603 = _59[5:5];
    assign _2600 = _1476 - _2565;
    assign _2601 = { gnd,
                     _2600 };
    assign _2602 = _2601 < _2568;
    assign _2613 = _2602 ? _2612 : _2603;
    assign _2596 = _2573[7:7];
    assign _2595 = _2573[6:6];
    assign _2594 = _2573[5:5];
    assign _2593 = _2573[4:4];
    assign _2592 = _2573[3:3];
    assign _2591 = _2573[2:2];
    assign _2590 = _2573[1:1];
    assign _2589 = _2573[0:0];
    always @* begin
        case (_2585)
        0:
            _2597 <= _2589;
        1:
            _2597 <= _2590;
        2:
            _2597 <= _2591;
        3:
            _2597 <= _2592;
        4:
            _2597 <= _2593;
        5:
            _2597 <= _2594;
        6:
            _2597 <= _2595;
        default:
            _2597 <= _2596;
        endcase
    end
    assign _2588 = _59[6:6];
    assign _2585 = _829 - _2565;
    assign _2586 = { gnd,
                     _2585 };
    assign _2587 = _2586 < _2568;
    assign _2598 = _2587 ? _2597 : _2588;
    assign _2581 = _2573[7:7];
    assign _2580 = _2573[6:6];
    assign _2579 = _2573[5:5];
    assign _2578 = _2573[4:4];
    assign _2577 = _2573[3:3];
    assign _2576 = _2573[2:2];
    assign _2575 = _2573[1:1];
    assign _2574 = _2573[0:0];
    always @* begin
        case (_2566)
        0:
            _2582 <= _2574;
        1:
            _2582 <= _2575;
        2:
            _2582 <= _2576;
        3:
            _2582 <= _2577;
        4:
            _2582 <= _2578;
        5:
            _2582 <= _2579;
        6:
            _2582 <= _2580;
        default:
            _2582 <= _2581;
        endcase
    end
    assign _2570 = _59[7:7];
    assign _2568 = cfg_t1_set_cfg[7:4];
    assign _1933 = _581[7:0];
    assign _1930 = 7'b1010011;
    assign _1931 = _577 == _1930;
    assign _1929 = _571 & _575;
    assign _1932 = _1929 & _1931;
    assign _1934 = _1932 ? _1933 : cfg_t1_set_cfg;
    assign _55 = _1934;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_set_cfg <= _432;
        else
            cfg_t1_set_cfg <= _55;
    end
    assign _2565 = cfg_t1_set_cfg[2:0];
    assign _2566 = _1448 - _2565;
    assign _2567 = { gnd,
                     _2566 };
    assign _2569 = _2567 < _2568;
    assign _2583 = _2569 ? _2582 : _2570;
    assign _2689 = { _2583,
                     _2598,
                     _2613,
                     _2628,
                     _2643,
                     _2658,
                     _2673,
                     _2688 };
    assign _2523 = _2396[7:7];
    assign _2522 = _2396[6:6];
    assign _2521 = _2396[5:5];
    assign _2520 = _2396[4:4];
    assign _2519 = _2396[3:3];
    assign _2518 = _2396[2:2];
    assign _2517 = _2396[1:1];
    assign _2516 = _2396[0:0];
    always @* begin
        case (_2510)
        0:
            _2524 <= _2516;
        1:
            _2524 <= _2517;
        2:
            _2524 <= _2518;
        3:
            _2524 <= _2519;
        4:
            _2524 <= _2520;
        5:
            _2524 <= _2521;
        6:
            _2524 <= _2522;
        default:
            _2524 <= _2523;
        endcase
    end
    assign _2515 = _2376[0:0];
    assign _2513 = { _4091,
                     _1958 };
    assign _2510 = _458 - _1954;
    assign _2511 = { gnd,
                     _2510 };
    assign _2514 = _2511 < _2513;
    assign _2525 = _2514 ? _2524 : _2515;
    assign _2506 = _2396[7:7];
    assign _2505 = _2396[6:6];
    assign _2504 = _2396[5:5];
    assign _2503 = _2396[4:4];
    assign _2502 = _2396[3:3];
    assign _2501 = _2396[2:2];
    assign _2500 = _2396[1:1];
    assign _2499 = _2396[0:0];
    always @* begin
        case (_2493)
        0:
            _2507 <= _2499;
        1:
            _2507 <= _2500;
        2:
            _2507 <= _2501;
        3:
            _2507 <= _2502;
        4:
            _2507 <= _2503;
        5:
            _2507 <= _2504;
        6:
            _2507 <= _2505;
        default:
            _2507 <= _2506;
        endcase
    end
    assign _2498 = _2376[1:1];
    assign _2496 = { _4091,
                     _1958 };
    assign _2493 = _618 - _1954;
    assign _2494 = { gnd,
                     _2493 };
    assign _2497 = _2494 < _2496;
    assign _2508 = _2497 ? _2507 : _2498;
    assign _2489 = _2396[7:7];
    assign _2488 = _2396[6:6];
    assign _2487 = _2396[5:5];
    assign _2486 = _2396[4:4];
    assign _2485 = _2396[3:3];
    assign _2484 = _2396[2:2];
    assign _2483 = _2396[1:1];
    assign _2482 = _2396[0:0];
    always @* begin
        case (_2476)
        0:
            _2490 <= _2482;
        1:
            _2490 <= _2483;
        2:
            _2490 <= _2484;
        3:
            _2490 <= _2485;
        4:
            _2490 <= _2486;
        5:
            _2490 <= _2487;
        6:
            _2490 <= _2488;
        default:
            _2490 <= _2489;
        endcase
    end
    assign _2481 = _2376[2:2];
    assign _2479 = { _4091,
                     _1958 };
    assign _2476 = _3956 - _1954;
    assign _2477 = { gnd,
                     _2476 };
    assign _2480 = _2477 < _2479;
    assign _2491 = _2480 ? _2490 : _2481;
    assign _2472 = _2396[7:7];
    assign _2471 = _2396[6:6];
    assign _2470 = _2396[5:5];
    assign _2469 = _2396[4:4];
    assign _2468 = _2396[3:3];
    assign _2467 = _2396[2:2];
    assign _2466 = _2396[1:1];
    assign _2465 = _2396[0:0];
    always @* begin
        case (_2459)
        0:
            _2473 <= _2465;
        1:
            _2473 <= _2466;
        2:
            _2473 <= _2467;
        3:
            _2473 <= _2468;
        4:
            _2473 <= _2469;
        5:
            _2473 <= _2470;
        6:
            _2473 <= _2471;
        default:
            _2473 <= _2472;
        endcase
    end
    assign _2464 = _2376[3:3];
    assign _2462 = { _4091,
                     _1958 };
    assign _2459 = _843 - _1954;
    assign _2460 = { gnd,
                     _2459 };
    assign _2463 = _2460 < _2462;
    assign _2474 = _2463 ? _2473 : _2464;
    assign _2455 = _2396[7:7];
    assign _2454 = _2396[6:6];
    assign _2453 = _2396[5:5];
    assign _2452 = _2396[4:4];
    assign _2451 = _2396[3:3];
    assign _2450 = _2396[2:2];
    assign _2449 = _2396[1:1];
    assign _2448 = _2396[0:0];
    always @* begin
        case (_2442)
        0:
            _2456 <= _2448;
        1:
            _2456 <= _2449;
        2:
            _2456 <= _2450;
        3:
            _2456 <= _2451;
        4:
            _2456 <= _2452;
        5:
            _2456 <= _2453;
        6:
            _2456 <= _2454;
        default:
            _2456 <= _2455;
        endcase
    end
    assign _2447 = _2376[4:4];
    assign _2445 = { _4091,
                     _1958 };
    assign _2442 = _4100 - _1954;
    assign _2443 = { gnd,
                     _2442 };
    assign _2446 = _2443 < _2445;
    assign _2457 = _2446 ? _2456 : _2447;
    assign _2438 = _2396[7:7];
    assign _2437 = _2396[6:6];
    assign _2436 = _2396[5:5];
    assign _2435 = _2396[4:4];
    assign _2434 = _2396[3:3];
    assign _2433 = _2396[2:2];
    assign _2432 = _2396[1:1];
    assign _2431 = _2396[0:0];
    always @* begin
        case (_2425)
        0:
            _2439 <= _2431;
        1:
            _2439 <= _2432;
        2:
            _2439 <= _2433;
        3:
            _2439 <= _2434;
        4:
            _2439 <= _2435;
        5:
            _2439 <= _2436;
        6:
            _2439 <= _2437;
        default:
            _2439 <= _2438;
        endcase
    end
    assign _2430 = _2376[5:5];
    assign _2428 = { _4091,
                     _1958 };
    assign _2425 = _1476 - _1954;
    assign _2426 = { gnd,
                     _2425 };
    assign _2429 = _2426 < _2428;
    assign _2440 = _2429 ? _2439 : _2430;
    assign _2421 = _2396[7:7];
    assign _2420 = _2396[6:6];
    assign _2419 = _2396[5:5];
    assign _2418 = _2396[4:4];
    assign _2417 = _2396[3:3];
    assign _2416 = _2396[2:2];
    assign _2415 = _2396[1:1];
    assign _2414 = _2396[0:0];
    always @* begin
        case (_2408)
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
    assign _2413 = _2376[6:6];
    assign _2411 = { _4091,
                     _1958 };
    assign _2408 = _829 - _1954;
    assign _2409 = { gnd,
                     _2408 };
    assign _2412 = _2409 < _2411;
    assign _2423 = _2412 ? _2422 : _2413;
    assign _2404 = _2396[7:7];
    assign _2403 = _2396[6:6];
    assign _2402 = _2396[5:5];
    assign _2401 = _2396[4:4];
    assign _2400 = _2396[3:3];
    assign _2399 = _2396[2:2];
    assign _2398 = _2396[1:1];
    assign _2391 = _2389[3:2];
    assign _2392 = { _4091,
                     _2391 };
    assign _2387 = _2385[3:1];
    assign _2388 = { _565,
                     _2387 };
    assign _2385 = _117[12:9];
    assign _2384 = _2381[0:0];
    assign _2389 = _2384 ? _2388 : _2385;
    assign _2383 = _2381[1:1];
    assign _2393 = _2383 ? _2392 : _2389;
    assign _2380 = { gnd,
                     _1958 };
    assign _2381 = _4100 - _2380;
    assign _2382 = _2381[2:2];
    assign _2395 = _2382 ? _614 : _2393;
    assign _2396 = { _614,
                     _2395 };
    assign _2397 = _2396[0:0];
    always @* begin
        case (_1955)
        0:
            _2405 <= _2397;
        1:
            _2405 <= _2398;
        2:
            _2405 <= _2399;
        3:
            _2405 <= _2400;
        4:
            _2405 <= _2401;
        5:
            _2405 <= _2402;
        6:
            _2405 <= _2403;
        default:
            _2405 <= _2404;
        endcase
    end
    assign _2372 = _920[7:7];
    assign _2371 = _920[6:6];
    assign _2370 = _920[5:5];
    assign _2369 = _920[4:4];
    assign _2368 = _920[3:3];
    assign _2367 = _920[2:2];
    assign _2366 = _920[1:1];
    assign _2365 = _920[0:0];
    always @* begin
        case (_2361)
        0:
            _2373 <= _2365;
        1:
            _2373 <= _2366;
        2:
            _2373 <= _2367;
        3:
            _2373 <= _2368;
        4:
            _2373 <= _2369;
        5:
            _2373 <= _2370;
        6:
            _2373 <= _2371;
        default:
            _2373 <= _2372;
        endcase
    end
    assign _2364 = pin_out[0:0];
    assign _2361 = _458 - _2109;
    assign _2362 = { _4091,
                     _2361 };
    assign _2363 = _2362 < _735;
    assign _2374 = _2363 ? _2373 : _2364;
    assign _2356 = _920[7:7];
    assign _2355 = _920[6:6];
    assign _2354 = _920[5:5];
    assign _2353 = _920[4:4];
    assign _2352 = _920[3:3];
    assign _2351 = _920[2:2];
    assign _2350 = _920[1:1];
    assign _2349 = _920[0:0];
    always @* begin
        case (_2345)
        0:
            _2357 <= _2349;
        1:
            _2357 <= _2350;
        2:
            _2357 <= _2351;
        3:
            _2357 <= _2352;
        4:
            _2357 <= _2353;
        5:
            _2357 <= _2354;
        6:
            _2357 <= _2355;
        default:
            _2357 <= _2356;
        endcase
    end
    assign _2348 = pin_out[1:1];
    assign _2345 = _618 - _2109;
    assign _2346 = { _4091,
                     _2345 };
    assign _2347 = _2346 < _735;
    assign _2358 = _2347 ? _2357 : _2348;
    assign _2340 = _920[7:7];
    assign _2339 = _920[6:6];
    assign _2338 = _920[5:5];
    assign _2337 = _920[4:4];
    assign _2336 = _920[3:3];
    assign _2335 = _920[2:2];
    assign _2334 = _920[1:1];
    assign _2333 = _920[0:0];
    always @* begin
        case (_2329)
        0:
            _2341 <= _2333;
        1:
            _2341 <= _2334;
        2:
            _2341 <= _2335;
        3:
            _2341 <= _2336;
        4:
            _2341 <= _2337;
        5:
            _2341 <= _2338;
        6:
            _2341 <= _2339;
        default:
            _2341 <= _2340;
        endcase
    end
    assign _2332 = pin_out[2:2];
    assign _2329 = _3956 - _2109;
    assign _2330 = { _4091,
                     _2329 };
    assign _2331 = _2330 < _735;
    assign _2342 = _2331 ? _2341 : _2332;
    assign _2324 = _920[7:7];
    assign _2323 = _920[6:6];
    assign _2322 = _920[5:5];
    assign _2321 = _920[4:4];
    assign _2320 = _920[3:3];
    assign _2319 = _920[2:2];
    assign _2318 = _920[1:1];
    assign _2317 = _920[0:0];
    always @* begin
        case (_2313)
        0:
            _2325 <= _2317;
        1:
            _2325 <= _2318;
        2:
            _2325 <= _2319;
        3:
            _2325 <= _2320;
        4:
            _2325 <= _2321;
        5:
            _2325 <= _2322;
        6:
            _2325 <= _2323;
        default:
            _2325 <= _2324;
        endcase
    end
    assign _2316 = pin_out[3:3];
    assign _2313 = _843 - _2109;
    assign _2314 = { _4091,
                     _2313 };
    assign _2315 = _2314 < _735;
    assign _2326 = _2315 ? _2325 : _2316;
    assign _2308 = _920[7:7];
    assign _2307 = _920[6:6];
    assign _2306 = _920[5:5];
    assign _2305 = _920[4:4];
    assign _2304 = _920[3:3];
    assign _2303 = _920[2:2];
    assign _2302 = _920[1:1];
    assign _2301 = _920[0:0];
    always @* begin
        case (_2297)
        0:
            _2309 <= _2301;
        1:
            _2309 <= _2302;
        2:
            _2309 <= _2303;
        3:
            _2309 <= _2304;
        4:
            _2309 <= _2305;
        5:
            _2309 <= _2306;
        6:
            _2309 <= _2307;
        default:
            _2309 <= _2308;
        endcase
    end
    assign _2300 = pin_out[4:4];
    assign _2297 = _4100 - _2109;
    assign _2298 = { _4091,
                     _2297 };
    assign _2299 = _2298 < _735;
    assign _2310 = _2299 ? _2309 : _2300;
    assign _2292 = _920[7:7];
    assign _2291 = _920[6:6];
    assign _2290 = _920[5:5];
    assign _2289 = _920[4:4];
    assign _2288 = _920[3:3];
    assign _2287 = _920[2:2];
    assign _2286 = _920[1:1];
    assign _2285 = _920[0:0];
    always @* begin
        case (_2281)
        0:
            _2293 <= _2285;
        1:
            _2293 <= _2286;
        2:
            _2293 <= _2287;
        3:
            _2293 <= _2288;
        4:
            _2293 <= _2289;
        5:
            _2293 <= _2290;
        6:
            _2293 <= _2291;
        default:
            _2293 <= _2292;
        endcase
    end
    assign _2284 = pin_out[5:5];
    assign _2281 = _1476 - _2109;
    assign _2282 = { _4091,
                     _2281 };
    assign _2283 = _2282 < _735;
    assign _2294 = _2283 ? _2293 : _2284;
    assign _2276 = _920[7:7];
    assign _2275 = _920[6:6];
    assign _2274 = _920[5:5];
    assign _2273 = _920[4:4];
    assign _2272 = _920[3:3];
    assign _2271 = _920[2:2];
    assign _2270 = _920[1:1];
    assign _2269 = _920[0:0];
    always @* begin
        case (_2265)
        0:
            _2277 <= _2269;
        1:
            _2277 <= _2270;
        2:
            _2277 <= _2271;
        3:
            _2277 <= _2272;
        4:
            _2277 <= _2273;
        5:
            _2277 <= _2274;
        6:
            _2277 <= _2275;
        default:
            _2277 <= _2276;
        endcase
    end
    assign _2268 = pin_out[6:6];
    assign _2265 = _829 - _2109;
    assign _2266 = { _4091,
                     _2265 };
    assign _2267 = _2266 < _735;
    assign _2278 = _2267 ? _2277 : _2268;
    assign _2260 = _920[7:7];
    assign _2259 = _920[6:6];
    assign _2258 = _920[5:5];
    assign _2257 = _920[4:4];
    assign _2256 = _920[3:3];
    assign _2255 = _920[2:2];
    assign _2254 = _920[1:1];
    assign _2253 = _920[0:0];
    always @* begin
        case (_2249)
        0:
            _2261 <= _2253;
        1:
            _2261 <= _2254;
        2:
            _2261 <= _2255;
        3:
            _2261 <= _2256;
        4:
            _2261 <= _2257;
        5:
            _2261 <= _2258;
        6:
            _2261 <= _2259;
        default:
            _2261 <= _2260;
        endcase
    end
    assign _2252 = pin_out[7:7];
    assign _2249 = _1448 - _2109;
    assign _2250 = { _4091,
                     _2249 };
    assign _2251 = _2250 < _735;
    assign _2262 = _2251 ? _2261 : _2252;
    assign _2375 = { _2262,
                     _2278,
                     _2294,
                     _2310,
                     _2326,
                     _2342,
                     _2358,
                     _2374 };
    assign _2242 = _2129[7:7];
    assign _2241 = _2129[6:6];
    assign _2240 = _2129[5:5];
    assign _2239 = _2129[4:4];
    assign _2238 = _2129[3:3];
    assign _2237 = _2129[2:2];
    assign _2236 = _2129[1:1];
    assign _2235 = _2129[0:0];
    always @* begin
        case (_2231)
        0:
            _2243 <= _2235;
        1:
            _2243 <= _2236;
        2:
            _2243 <= _2237;
        3:
            _2243 <= _2238;
        4:
            _2243 <= _2239;
        5:
            _2243 <= _2240;
        6:
            _2243 <= _2241;
        default:
            _2243 <= _2242;
        endcase
    end
    assign _2234 = pin_out[0:0];
    assign _2231 = _458 - _2109;
    assign _2232 = { gnd,
                     _2231 };
    assign _2233 = _2232 < _2112;
    assign _2244 = _2233 ? _2243 : _2234;
    assign _2227 = _2129[7:7];
    assign _2226 = _2129[6:6];
    assign _2225 = _2129[5:5];
    assign _2224 = _2129[4:4];
    assign _2223 = _2129[3:3];
    assign _2222 = _2129[2:2];
    assign _2221 = _2129[1:1];
    assign _2220 = _2129[0:0];
    always @* begin
        case (_2216)
        0:
            _2228 <= _2220;
        1:
            _2228 <= _2221;
        2:
            _2228 <= _2222;
        3:
            _2228 <= _2223;
        4:
            _2228 <= _2224;
        5:
            _2228 <= _2225;
        6:
            _2228 <= _2226;
        default:
            _2228 <= _2227;
        endcase
    end
    assign _2219 = pin_out[1:1];
    assign _2216 = _618 - _2109;
    assign _2217 = { gnd,
                     _2216 };
    assign _2218 = _2217 < _2112;
    assign _2229 = _2218 ? _2228 : _2219;
    assign _2212 = _2129[7:7];
    assign _2211 = _2129[6:6];
    assign _2210 = _2129[5:5];
    assign _2209 = _2129[4:4];
    assign _2208 = _2129[3:3];
    assign _2207 = _2129[2:2];
    assign _2206 = _2129[1:1];
    assign _2205 = _2129[0:0];
    always @* begin
        case (_2201)
        0:
            _2213 <= _2205;
        1:
            _2213 <= _2206;
        2:
            _2213 <= _2207;
        3:
            _2213 <= _2208;
        4:
            _2213 <= _2209;
        5:
            _2213 <= _2210;
        6:
            _2213 <= _2211;
        default:
            _2213 <= _2212;
        endcase
    end
    assign _2204 = pin_out[2:2];
    assign _2201 = _3956 - _2109;
    assign _2202 = { gnd,
                     _2201 };
    assign _2203 = _2202 < _2112;
    assign _2214 = _2203 ? _2213 : _2204;
    assign _2197 = _2129[7:7];
    assign _2196 = _2129[6:6];
    assign _2195 = _2129[5:5];
    assign _2194 = _2129[4:4];
    assign _2193 = _2129[3:3];
    assign _2192 = _2129[2:2];
    assign _2191 = _2129[1:1];
    assign _2190 = _2129[0:0];
    always @* begin
        case (_2186)
        0:
            _2198 <= _2190;
        1:
            _2198 <= _2191;
        2:
            _2198 <= _2192;
        3:
            _2198 <= _2193;
        4:
            _2198 <= _2194;
        5:
            _2198 <= _2195;
        6:
            _2198 <= _2196;
        default:
            _2198 <= _2197;
        endcase
    end
    assign _2189 = pin_out[3:3];
    assign _2186 = _843 - _2109;
    assign _2187 = { gnd,
                     _2186 };
    assign _2188 = _2187 < _2112;
    assign _2199 = _2188 ? _2198 : _2189;
    assign _2182 = _2129[7:7];
    assign _2181 = _2129[6:6];
    assign _2180 = _2129[5:5];
    assign _2179 = _2129[4:4];
    assign _2178 = _2129[3:3];
    assign _2177 = _2129[2:2];
    assign _2176 = _2129[1:1];
    assign _2175 = _2129[0:0];
    always @* begin
        case (_2171)
        0:
            _2183 <= _2175;
        1:
            _2183 <= _2176;
        2:
            _2183 <= _2177;
        3:
            _2183 <= _2178;
        4:
            _2183 <= _2179;
        5:
            _2183 <= _2180;
        6:
            _2183 <= _2181;
        default:
            _2183 <= _2182;
        endcase
    end
    assign _2174 = pin_out[4:4];
    assign _2171 = _4100 - _2109;
    assign _2172 = { gnd,
                     _2171 };
    assign _2173 = _2172 < _2112;
    assign _2184 = _2173 ? _2183 : _2174;
    assign _2167 = _2129[7:7];
    assign _2166 = _2129[6:6];
    assign _2165 = _2129[5:5];
    assign _2164 = _2129[4:4];
    assign _2163 = _2129[3:3];
    assign _2162 = _2129[2:2];
    assign _2161 = _2129[1:1];
    assign _2160 = _2129[0:0];
    always @* begin
        case (_2156)
        0:
            _2168 <= _2160;
        1:
            _2168 <= _2161;
        2:
            _2168 <= _2162;
        3:
            _2168 <= _2163;
        4:
            _2168 <= _2164;
        5:
            _2168 <= _2165;
        6:
            _2168 <= _2166;
        default:
            _2168 <= _2167;
        endcase
    end
    assign _2159 = pin_out[5:5];
    assign _2156 = _1476 - _2109;
    assign _2157 = { gnd,
                     _2156 };
    assign _2158 = _2157 < _2112;
    assign _2169 = _2158 ? _2168 : _2159;
    assign _2152 = _2129[7:7];
    assign _2151 = _2129[6:6];
    assign _2150 = _2129[5:5];
    assign _2149 = _2129[4:4];
    assign _2148 = _2129[3:3];
    assign _2147 = _2129[2:2];
    assign _2146 = _2129[1:1];
    assign _2145 = _2129[0:0];
    always @* begin
        case (_2141)
        0:
            _2153 <= _2145;
        1:
            _2153 <= _2146;
        2:
            _2153 <= _2147;
        3:
            _2153 <= _2148;
        4:
            _2153 <= _2149;
        5:
            _2153 <= _2150;
        6:
            _2153 <= _2151;
        default:
            _2153 <= _2152;
        endcase
    end
    assign _2144 = pin_out[6:6];
    assign _2141 = _829 - _2109;
    assign _2142 = { gnd,
                     _2141 };
    assign _2143 = _2142 < _2112;
    assign _2154 = _2143 ? _2153 : _2144;
    assign _2137 = _2129[7:7];
    assign _2136 = _2129[6:6];
    assign _2135 = _2129[5:5];
    assign _2134 = _2129[4:4];
    assign _2133 = _2129[3:3];
    assign _2132 = _2129[2:2];
    assign _2131 = _2129[1:1];
    assign _2130 = _2129[0:0];
    always @* begin
        case (_2110)
        0:
            _2138 <= _2130;
        1:
            _2138 <= _2131;
        2:
            _2138 <= _2132;
        3:
            _2138 <= _2133;
        4:
            _2138 <= _2134;
        5:
            _2138 <= _2135;
        6:
            _2138 <= _2136;
        default:
            _2138 <= _2137;
        endcase
    end
    assign _2114 = pin_out[7:7];
    assign _2112 = cfg_t0_out_cfg[7:4];
    assign _1939 = _581[7:0];
    assign _1936 = 7'b1000010;
    assign _1937 = _577 == _1936;
    assign _1935 = _571 & _575;
    assign _1938 = _1935 & _1937;
    assign _1940 = _1938 ? _1939 : cfg_t0_out_cfg;
    assign _56 = _1940;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_out_cfg <= _432;
        else
            cfg_t0_out_cfg <= _56;
    end
    assign _2109 = cfg_t0_out_cfg[2:0];
    assign _2110 = _1448 - _2109;
    assign _2111 = { gnd,
                     _2110 };
    assign _2113 = _2111 < _2112;
    assign _2139 = _2113 ? _2138 : _2114;
    assign _2245 = { _2139,
                     _2154,
                     _2169,
                     _2184,
                     _2199,
                     _2214,
                     _2229,
                     _2244 };
    assign _2103 = _1990[7:7];
    assign _2102 = _1990[6:6];
    assign _2101 = _1990[5:5];
    assign _2100 = _1990[4:4];
    assign _2099 = _1990[3:3];
    assign _2098 = _1990[2:2];
    assign _2097 = _1990[1:1];
    assign _2096 = _1990[0:0];
    always @* begin
        case (_2092)
        0:
            _2104 <= _2096;
        1:
            _2104 <= _2097;
        2:
            _2104 <= _2098;
        3:
            _2104 <= _2099;
        4:
            _2104 <= _2100;
        5:
            _2104 <= _2101;
        6:
            _2104 <= _2102;
        default:
            _2104 <= _2103;
        endcase
    end
    assign _2095 = pin_out[0:0];
    assign _2092 = _458 - _1982;
    assign _2093 = { gnd,
                     _2092 };
    assign _2094 = _2093 < _1985;
    assign _2105 = _2094 ? _2104 : _2095;
    assign _2088 = _1990[7:7];
    assign _2087 = _1990[6:6];
    assign _2086 = _1990[5:5];
    assign _2085 = _1990[4:4];
    assign _2084 = _1990[3:3];
    assign _2083 = _1990[2:2];
    assign _2082 = _1990[1:1];
    assign _2081 = _1990[0:0];
    always @* begin
        case (_2077)
        0:
            _2089 <= _2081;
        1:
            _2089 <= _2082;
        2:
            _2089 <= _2083;
        3:
            _2089 <= _2084;
        4:
            _2089 <= _2085;
        5:
            _2089 <= _2086;
        6:
            _2089 <= _2087;
        default:
            _2089 <= _2088;
        endcase
    end
    assign _2080 = pin_out[1:1];
    assign _2077 = _618 - _1982;
    assign _2078 = { gnd,
                     _2077 };
    assign _2079 = _2078 < _1985;
    assign _2090 = _2079 ? _2089 : _2080;
    assign _2073 = _1990[7:7];
    assign _2072 = _1990[6:6];
    assign _2071 = _1990[5:5];
    assign _2070 = _1990[4:4];
    assign _2069 = _1990[3:3];
    assign _2068 = _1990[2:2];
    assign _2067 = _1990[1:1];
    assign _2066 = _1990[0:0];
    always @* begin
        case (_2062)
        0:
            _2074 <= _2066;
        1:
            _2074 <= _2067;
        2:
            _2074 <= _2068;
        3:
            _2074 <= _2069;
        4:
            _2074 <= _2070;
        5:
            _2074 <= _2071;
        6:
            _2074 <= _2072;
        default:
            _2074 <= _2073;
        endcase
    end
    assign _2065 = pin_out[2:2];
    assign _2062 = _3956 - _1982;
    assign _2063 = { gnd,
                     _2062 };
    assign _2064 = _2063 < _1985;
    assign _2075 = _2064 ? _2074 : _2065;
    assign _2058 = _1990[7:7];
    assign _2057 = _1990[6:6];
    assign _2056 = _1990[5:5];
    assign _2055 = _1990[4:4];
    assign _2054 = _1990[3:3];
    assign _2053 = _1990[2:2];
    assign _2052 = _1990[1:1];
    assign _2051 = _1990[0:0];
    always @* begin
        case (_2047)
        0:
            _2059 <= _2051;
        1:
            _2059 <= _2052;
        2:
            _2059 <= _2053;
        3:
            _2059 <= _2054;
        4:
            _2059 <= _2055;
        5:
            _2059 <= _2056;
        6:
            _2059 <= _2057;
        default:
            _2059 <= _2058;
        endcase
    end
    assign _2050 = pin_out[3:3];
    assign _2047 = _843 - _1982;
    assign _2048 = { gnd,
                     _2047 };
    assign _2049 = _2048 < _1985;
    assign _2060 = _2049 ? _2059 : _2050;
    assign _2043 = _1990[7:7];
    assign _2042 = _1990[6:6];
    assign _2041 = _1990[5:5];
    assign _2040 = _1990[4:4];
    assign _2039 = _1990[3:3];
    assign _2038 = _1990[2:2];
    assign _2037 = _1990[1:1];
    assign _2036 = _1990[0:0];
    always @* begin
        case (_2032)
        0:
            _2044 <= _2036;
        1:
            _2044 <= _2037;
        2:
            _2044 <= _2038;
        3:
            _2044 <= _2039;
        4:
            _2044 <= _2040;
        5:
            _2044 <= _2041;
        6:
            _2044 <= _2042;
        default:
            _2044 <= _2043;
        endcase
    end
    assign _2035 = pin_out[4:4];
    assign _2032 = _4100 - _1982;
    assign _2033 = { gnd,
                     _2032 };
    assign _2034 = _2033 < _1985;
    assign _2045 = _2034 ? _2044 : _2035;
    assign _2028 = _1990[7:7];
    assign _2027 = _1990[6:6];
    assign _2026 = _1990[5:5];
    assign _2025 = _1990[4:4];
    assign _2024 = _1990[3:3];
    assign _2023 = _1990[2:2];
    assign _2022 = _1990[1:1];
    assign _2021 = _1990[0:0];
    always @* begin
        case (_2017)
        0:
            _2029 <= _2021;
        1:
            _2029 <= _2022;
        2:
            _2029 <= _2023;
        3:
            _2029 <= _2024;
        4:
            _2029 <= _2025;
        5:
            _2029 <= _2026;
        6:
            _2029 <= _2027;
        default:
            _2029 <= _2028;
        endcase
    end
    assign _2020 = pin_out[5:5];
    assign _2017 = _1476 - _1982;
    assign _2018 = { gnd,
                     _2017 };
    assign _2019 = _2018 < _1985;
    assign _2030 = _2019 ? _2029 : _2020;
    assign _2013 = _1990[7:7];
    assign _2012 = _1990[6:6];
    assign _2011 = _1990[5:5];
    assign _2010 = _1990[4:4];
    assign _2009 = _1990[3:3];
    assign _2008 = _1990[2:2];
    assign _2007 = _1990[1:1];
    assign _2006 = _1990[0:0];
    always @* begin
        case (_2002)
        0:
            _2014 <= _2006;
        1:
            _2014 <= _2007;
        2:
            _2014 <= _2008;
        3:
            _2014 <= _2009;
        4:
            _2014 <= _2010;
        5:
            _2014 <= _2011;
        6:
            _2014 <= _2012;
        default:
            _2014 <= _2013;
        endcase
    end
    assign _2005 = pin_out[6:6];
    assign _2002 = _829 - _1982;
    assign _2003 = { gnd,
                     _2002 };
    assign _2004 = _2003 < _1985;
    assign _2015 = _2004 ? _2014 : _2005;
    assign _1998 = _1990[7:7];
    assign _1997 = _1990[6:6];
    assign _1996 = _1990[5:5];
    assign _1995 = _1990[4:4];
    assign _1994 = _1990[3:3];
    assign _1993 = _1990[2:2];
    assign _1992 = _1990[1:1];
    assign _1991 = _1990[0:0];
    always @* begin
        case (_1983)
        0:
            _1999 <= _1991;
        1:
            _1999 <= _1992;
        2:
            _1999 <= _1993;
        3:
            _1999 <= _1994;
        4:
            _1999 <= _1995;
        5:
            _1999 <= _1996;
        6:
            _1999 <= _1997;
        default:
            _1999 <= _1998;
        endcase
    end
    assign _1987 = pin_out[7:7];
    assign _1985 = cfg_t0_set_cfg[7:4];
    assign _1945 = _581[7:0];
    assign _1942 = 7'b1000011;
    assign _1943 = _577 == _1942;
    assign _1941 = _571 & _575;
    assign _1944 = _1941 & _1943;
    assign _1946 = _1944 ? _1945 : cfg_t0_set_cfg;
    assign _57 = _1946;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_set_cfg <= _432;
        else
            cfg_t0_set_cfg <= _57;
    end
    assign _1982 = cfg_t0_set_cfg[2:0];
    assign _1983 = _1448 - _1982;
    assign _1984 = { gnd,
                     _1983 };
    assign _1986 = _1984 < _1985;
    assign _2000 = _1986 ? _1999 : _1987;
    assign _2106 = { _2000,
                     _2015,
                     _2030,
                     _2045,
                     _2060,
                     _2075,
                     _2090,
                     _2105 };
    assign _1979 = _751 == _4091;
    assign _1976 = _617 == _829;
    assign _1977 = _745 & _1976;
    assign _1980 = _1977 & _1979;
    assign _2107 = _1980 ? _2106 : pin_out;
    assign _1972 = _820 == _3956;
    assign _1973 = _826 & _1972;
    assign _1969 = _617 == _1476;
    assign _1970 = _745 & _1969;
    assign _1974 = _1970 & _1973;
    assign _2246 = _1974 ? _2245 : _2107;
    assign _1964 = _117[8:7];
    assign _1966 = _1964 == _4091;
    assign _1962 = _617 == _843;
    assign _1963 = _745 & _1962;
    assign _1967 = _1963 & _1966;
    assign _2376 = _1967 ? _2375 : _2246;
    assign _2377 = _2376[7:7];
    assign _1958 = cfg_t0_sideset[5:4];
    assign _1959 = { _4091,
                     _1958 };
    assign _1951 = _581[5:0];
    assign _1948 = 7'b1001100;
    assign _1949 = _577 == _1948;
    assign _1947 = _571 & _575;
    assign _1950 = _1947 & _1949;
    assign _1952 = _1950 ? _1951 : cfg_t0_sideset;
    assign _58 = _1952;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_sideset <= _544;
        else
            cfg_t0_sideset <= _58;
    end
    assign _1954 = cfg_t0_sideset[2:0];
    assign _1955 = _1448 - _1954;
    assign _1956 = { gnd,
                     _1955 };
    assign _1960 = _1956 < _1959;
    assign _2406 = _1960 ? _2405 : _2377;
    assign _2526 = { _2406,
                     _2423,
                     _2440,
                     _2457,
                     _2474,
                     _2491,
                     _2508,
                     _2525 };
    assign _2527 = _612 ? pin_out : _2526;
    assign _2528 = _606 ? pin_out : _2527;
    assign _2529 = _600 ? pin_out : _2528;
    assign _59 = _2529;
    assign _2562 = _1276 == _4091;
    assign _2559 = _1192 == _829;
    assign _2560 = _1270 & _2559;
    assign _2563 = _2560 & _2562;
    assign _2690 = _2563 ? _2689 : _59;
    assign _2555 = _1345 == _3956;
    assign _2556 = _1351 & _2555;
    assign _2552 = _1192 == _1476;
    assign _2553 = _1270 & _2552;
    assign _2557 = _2553 & _2556;
    assign _2814 = _2557 ? _2813 : _2690;
    assign _2547 = _92[8:7];
    assign _2549 = _2547 == _4091;
    assign _2545 = _1192 == _843;
    assign _2546 = _1270 & _2545;
    assign _2550 = _2546 & _2549;
    assign _2944 = _2550 ? _2943 : _2814;
    assign _2945 = _2944[7:7];
    assign _2541 = cfg_t1_sideset[5:4];
    assign _2542 = { _4091,
                     _2541 };
    assign _2534 = _581[5:0];
    assign _2531 = 7'b1011100;
    assign _2532 = _577 == _2531;
    assign _2530 = _571 & _575;
    assign _2533 = _2530 & _2532;
    assign _2535 = _2533 ? _2534 : cfg_t1_sideset;
    assign _60 = _2535;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_sideset <= _544;
        else
            cfg_t1_sideset <= _60;
    end
    assign _2537 = cfg_t1_sideset[2:0];
    assign _2538 = _1448 - _2537;
    assign _2539 = { gnd,
                     _2538 };
    assign _2543 = _2539 < _2542;
    assign _2974 = _2543 ? _2973 : _2945;
    assign _3094 = { _2974,
                     _2991,
                     _3008,
                     _3025,
                     _3042,
                     _3059,
                     _3076,
                     _3093 };
    assign _3095 = _1187 ? _59 : _3094;
    assign _3096 = _1181 ? _59 : _3095;
    assign _3097 = _1175 ? _59 : _3096;
    assign _61 = _3097;
    assign _62 = _61;
    always @(posedge _131) begin
        if (_129)
            pin_out <= _149;
        else
            pin_out <= _62;
    end
    assign _632 = pin_out[7:7];
    assign _628 = ~ cfg_sync_bypass;
    always @(posedge _131) begin
        if (_129)
            pins_sync1 <= _149;
        else
            pins_sync1 <= _65;
    end
    always @(posedge _131) begin
        if (_129)
            pins_sync2 <= _149;
        else
            pins_sync2 <= pins_sync1;
    end
    assign _629 = pins_sync2 & _628;
    assign _3102 = _581[7:0];
    assign _3099 = 7'b1001110;
    assign _3100 = _577 == _3099;
    assign _3098 = _571 & _575;
    assign _3101 = _3098 & _3100;
    assign _3103 = _3101 ? _3102 : cfg_sync_bypass;
    assign _63 = _3103;
    always @(posedge _131) begin
        if (_129)
            cfg_sync_bypass <= _450;
        else
            cfg_sync_bypass <= _63;
    end
    assign _65 = uio_in;
    assign _622 = _65 & cfg_sync_bypass;
    assign _630 = _622 | _629;
    assign _631 = _630[7:7];
    assign _3105 = 7'b1000111;
    assign _3106 = _577 == _3105;
    assign _3104 = _571 & _575;
    assign _3107 = _3104 & _3106;
    assign _3108 = _3107 ? _581 : cfg_pin_modes;
    assign _66 = _3108;
    always @(posedge _131) begin
        if (_129)
            cfg_pin_modes <= _297;
        else
            cfg_pin_modes <= _66;
    end
    assign _621 = cfg_pin_modes[15:14];
    always @* begin
        case (_621)
        0:
            _634 <= _631;
        1:
            _634 <= _632;
        2:
            _634 <= _633;
        default:
            _634 <= _631;
        endcase
    end
    assign _670 = { _634,
                    _639,
                    _644,
                    _649,
                    _654,
                    _659,
                    _664,
                    _669 };
    assign _925 = _670[0:0];
    assign _3113 = _581[2:0];
    assign _3110 = 7'b1000100;
    assign _3111 = _577 == _3110;
    assign _3109 = _571 & _575;
    assign _3112 = _3109 & _3111;
    assign _3114 = _3112 ? _3113 : cfg_t0_in_base;
    assign _67 = _3114;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_in_base <= _458;
        else
            cfg_t0_in_base <= _67;
    end
    assign _924 = cfg_t0_in_base + _1448;
    always @* begin
        case (_924)
        0:
            _933 <= _925;
        1:
            _933 <= _926;
        2:
            _933 <= _927;
        3:
            _933 <= _928;
        4:
            _933 <= _929;
        5:
            _933 <= _930;
        6:
            _933 <= _931;
        default:
            _933 <= _932;
        endcase
    end
    assign _936 = _933 & _935;
    assign _1033 = { _936,
                     _950,
                     _964,
                     _978,
                     _992,
                     _1006,
                     _1020,
                     _1032 };
    assign _1034 = { _450,
                     _1033 };
    assign _921 = _117[8:7];
    always @* begin
        case (_921)
        0:
            _1042 <= _1034;
        1:
            _1042 <= t0_x;
        2:
            _1042 <= t0_y;
        default:
            _1042 <= _297;
        endcase
    end
    assign _3133 = { _1042,
                     t0_isr };
    assign _3132 = _735[0:0];
    assign _3137 = _3132 ? _3136 : _3133;
    assign _3131 = _735[1:1];
    assign _3141 = _3131 ? _3140 : _3137;
    assign _3130 = _735[2:2];
    assign _3145 = _3130 ? _3144 : _3141;
    assign _3129 = _735[3:3];
    assign _3149 = _3129 ? _3148 : _3145;
    assign _3128 = _735[4:4];
    assign _3153 = _3128 ? _3152 : _3149;
    assign _3154 = _3153[15:0];
    assign _3185 = _858 ? _3184 : _3154;
    assign _3187 = _741 ? _297 : _3185;
    assign _3126 = _699 ? t0_isr : _297;
    assign _3121 = _820 == _843;
    assign _3122 = _3121 ? _2129 : t0_isr;
    assign _3123 = _826 ? _3122 : t0_isr;
    assign _3119 = _617 == _1476;
    assign _3124 = _3119 ? _3123 : t0_isr;
    assign _3118 = _617 == _4100;
    assign _3127 = _3118 ? _3126 : _3124;
    assign _3116 = _617 == _3956;
    assign _3188 = _3116 ? _3187 : _3127;
    assign _3189 = _745 ? _3188 : t0_isr;
    assign _3190 = _612 ? t0_isr : _3189;
    assign _3191 = _606 ? t0_isr : _3190;
    assign _3193 = _600 ? _297 : _3191;
    assign _68 = _3193;
    assign _69 = _68;
    always @(posedge _131) begin
        if (_129)
            t0_isr <= _297;
        else
            t0_isr <= _69;
    end
    assign _3231 = { _297,
                     t0_isr };
    assign _3229 = _3224[0:0];
    assign _3235 = _3229 ? _3234 : _3231;
    assign _3228 = _3224[1:1];
    assign _3239 = _3228 ? _3238 : _3235;
    assign _3227 = _3224[2:2];
    assign _3243 = _3227 ? _3242 : _3239;
    assign _3226 = _3224[3:3];
    assign _3247 = _3226 ? _3246 : _3243;
    assign _3210 = _3208[4:0];
    assign _3207 = { gnd,
                     _735 };
    assign _3206 = { gnd,
                     t0_isr_count };
    assign _3208 = _3206 + _3207;
    assign _3209 = _1757 < _3208;
    assign _3212 = _3209 ? _890 : _3210;
    assign _738 = { gnd,
                    cfg_t0_threshold };
    assign _736 = { gnd,
                    _735 };
    assign _729 = { gnd,
                    t0_isr_count };
    assign _737 = _729 + _736;
    assign _739 = _737 < _738;
    assign _740 = ~ _739;
    assign _724 = cfg_t0_shift[3:3];
    assign _723 = _617 == _3956;
    assign _725 = _723 & _724;
    assign _741 = _725 & _740;
    assign _3214 = _741 ? _716 : _3212;
    assign _3203 = _699 ? t0_isr_count : _716;
    assign _3197 = _820 == _843;
    assign _3199 = _3197 ? _716 : t0_isr_count;
    assign _3200 = _826 ? _3199 : t0_isr_count;
    assign _3196 = _617 == _1476;
    assign _3201 = _3196 ? _3200 : t0_isr_count;
    assign _3195 = _617 == _4100;
    assign _3204 = _3195 ? _3203 : _3201;
    assign _3194 = _617 == _3956;
    assign _3215 = _3194 ? _3214 : _3204;
    assign _3216 = _745 ? _3215 : t0_isr_count;
    assign _3217 = _612 ? t0_isr_count : _3216;
    assign _3218 = _606 ? t0_isr_count : _3217;
    assign _3220 = _600 ? _716 : _3218;
    assign _70 = _3220;
    assign _71 = _70;
    always @(posedge _131) begin
        if (_129)
            t0_isr_count <= _716;
        else
            t0_isr_count <= _71;
    end
    assign _3224 = _890 - t0_isr_count;
    assign _3225 = _3224[4:4];
    assign _3251 = _3225 ? _3250 : _3247;
    assign _3252 = _3251[15:0];
    assign _858 = cfg_t0_shift[1:1];
    assign _3280 = _858 ? _3279 : _3252;
    assign _3222 = _617 == _3956;
    assign _3339 = _3222 ? _3338 : _3280;
    assign _72 = _3339;
    always @(posedge _131) begin
        if (_129)
            t0_rx_mem_0 <= _297;
        else
            if (_369)
                t0_rx_mem_0 <= _72;
    end
    assign _3369 = t0_rx_rd + _216;
    assign _3366 = ~ _3365;
    assign _3361 = _1089 == _565;
    assign _3362 = _100 & _3361;
    assign _3357 = ~ _1629;
    assign _3353 = _1089 == _565;
    assign _3351 = _1097 == _219;
    assign _3354 = _3351 & _3353;
    assign _3355 = ~ _3354;
    assign _3347 = t0_rx_level == _458;
    assign _3348 = ~ _3347;
    assign _3343 = 7'b1001001;
    assign _311 = _310[6:0];
    assign _3344 = _311 == _3343;
    assign _3340 = _310[7:7];
    assign _3341 = ~ _3340;
    assign _1152 = host_bit_count == _1459;
    assign _1153 = _295 & _1152;
    assign _3342 = _1153 & _3341;
    assign _3345 = _3342 & _3344;
    assign _3349 = _3345 & _3348;
    assign _73 = _3349;
    assign _3356 = _73 & _3355;
    assign _3358 = _3356 & _3357;
    assign _3359 = _135 | _3358;
    assign _3363 = _3359 | _3362;
    assign _3367 = _3363 & _3366;
    assign _3370 = _3367 ? _3369 : t0_rx_rd;
    assign _74 = _3370;
    always @(posedge _131) begin
        if (_129)
            t0_rx_rd <= _4091;
        else
            t0_rx_rd <= _74;
    end
    always @* begin
        case (t0_rx_rd)
        0:
            _389 <= t0_rx_mem_0;
        1:
            _389 <= t0_rx_mem_1;
        2:
            _389 <= t0_rx_mem_2;
        default:
            _389 <= t0_rx_mem_3;
        endcase
    end
    assign _3384 = _1089 ? _496 : _389;
    assign _3385 = _100 ? _3384 : _581;
    assign _3383 = _75 ? buf_ptr : _101;
    assign _3382 = ~ _75;
    assign _3378 = _1097 == _752;
    assign _3376 = _1097 == _4091;
    assign _3379 = _3376 | _3378;
    assign _3373 = _577 == _1157;
    assign _3371 = _571 & _575;
    assign _3374 = _3371 & _3373;
    assign _3380 = _3374 & _3379;
    assign _3381 = _100 | _3380;
    assign _75 = _3381;
    RM_IHPSG13_1P_1024x16_c2_bm_bist
        sram_buf
        ( .A_CLK(_131),
          .A_MEN(vdd),
          .A_WEN(_75),
          .A_REN(_3382),
          .A_ADDR(_3383),
          .A_DIN(_3385),
          .A_DLY(vdd),
          .A_BM(_4003),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_517),
          .A_BIST_DIN(_297),
          .A_BIST_BM(_297),
          .A_DOUT(_3391[15:0]) );
    assign _76 = _3391;
    assign _77 = _76;
    assign _1615 = _1089 == _1624;
    assign _1616 = _103 & _1615;
    assign _3455 = _1616 ? _77 : _581;
    assign _3456 = _135 ? _43 : _3455;
    always @(posedge _131) begin
        if (_129)
            t1_tx_mem_0 <= _297;
        else
            if (_3461)
                t1_tx_mem_0 <= _3456;
    end
    assign _3425 = t1_tx_rd + _216;
    assign _3419 = ~ _1227;
    assign _3396 = ~ _1227;
    assign _3393 = _1192 == _4100;
    assign _3394 = _1191 & _3393;
    assign _3395 = _3394 & _1224;
    assign _3397 = _3395 & _3396;
    assign _3415 = _3397 | _3414;
    assign _3418 = _3415 | _3417;
    assign _78 = _3418;
    assign _3420 = _78 & _3419;
    assign _3426 = _3420 ? _3425 : t1_tx_rd;
    assign _79 = _3426;
    always @(posedge _131) begin
        if (_129)
            t1_tx_rd <= _4091;
        else
            t1_tx_rd <= _79;
    end
    always @* begin
        case (t1_tx_rd)
        0:
            _3481 <= t1_tx_mem_0;
        1:
            _3481 <= t1_tx_mem_1;
        2:
            _3481 <= t1_tx_mem_2;
        default:
            _3481 <= t1_tx_mem_3;
        endcase
    end
    assign _1227 = t1_tx_level == _458;
    assign _3413 = ~ _1227;
    assign _447 = 5'b01000;
    assign _3431 = _581[4:0];
    assign _3428 = 7'b1010101;
    assign _3429 = _577 == _3428;
    assign _3427 = _571 & _575;
    assign _3430 = _3427 & _3429;
    assign _3432 = _3430 ? _3431 : cfg_t1_threshold;
    assign _80 = _3432;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_threshold <= _447;
        else
            cfg_t1_threshold <= _80;
    end
    assign _3407 = _3405[4:0];
    assign _1258 = { gnd,
                     _1255 };
    assign _1255 = _92[3:0];
    assign _1257 = _1255 == _614;
    assign _1260 = _1257 ? _890 : _1258;
    assign _3404 = { gnd,
                     _1260 };
    assign _3403 = { gnd,
                     t1_osr_count };
    assign _3405 = _3403 + _3404;
    assign _3406 = _1757 < _3405;
    assign _3409 = _3406 ? _890 : _3407;
    assign _3410 = _3409 < cfg_t1_threshold;
    assign _3411 = ~ _3410;
    assign _3399 = _1192 == _843;
    assign _3400 = _1270 & _3399;
    assign _3401 = _3400 & _1238;
    assign _3412 = _3401 & _3411;
    assign _3414 = _3412 & _3413;
    assign _3449 = _3414 ? _716 : _3409;
    assign _1224 = _92[8:8];
    assign _3446 = _1224 ? _716 : _3434;
    assign _3440 = _1345 == _4100;
    assign _3442 = _3440 ? _716 : _3434;
    assign _3443 = _1351 ? _3442 : _3434;
    assign _3438 = _1192 == _1476;
    assign _3444 = _3438 ? _3443 : _3434;
    assign _3437 = _1192 == _4100;
    assign _3447 = _3437 ? _3446 : _3444;
    assign _3436 = _1192 == _843;
    assign _3450 = _3436 ? _3449 : _3447;
    assign _3434 = _3417 ? _716 : t1_osr_count;
    assign _3451 = _1270 ? _3450 : _3434;
    assign _3452 = _1187 ? t1_osr_count : _3451;
    assign _3453 = _1181 ? t1_osr_count : _3452;
    assign _3454 = _1175 ? cfg_t1_threshold : _3453;
    assign _81 = _3454;
    assign _82 = _81;
    always @(posedge _131) begin
        if (_129)
            t1_osr_count <= _716;
        else
            t1_osr_count <= _82;
    end
    assign _1243 = t1_osr_count < cfg_t1_threshold;
    assign _1244 = ~ _1243;
    assign _1238 = cfg_t1_shift[2:2];
    assign _1237 = _1192 == _843;
    assign _1239 = _1237 & _1238;
    assign _1245 = _1239 & _1244;
    assign _3416 = _1191 & _1245;
    assign _3417 = _3416 & _3413;
    assign _3482 = _3417 ? _3481 : t1_osr;
    assign _3551 = _1270 ? _3550 : _3482;
    assign _3552 = _1187 ? t1_osr : _3551;
    assign _3553 = _1181 ? t1_osr : _3552;
    assign _3555 = _1175 ? _297 : _3553;
    assign _83 = _3555;
    assign _84 = _83;
    always @(posedge _131) begin
        if (_129)
            t1_osr <= _297;
        else
            t1_osr <= _84;
    end
    assign _1414 = t1_osr & _1413;
    assign _3560 = _581[5:0];
    assign _3557 = 7'b1011111;
    assign _3558 = _577 == _3557;
    assign _3556 = _571 & _575;
    assign _3559 = _3556 & _3558;
    assign _3561 = _3559 ? _3560 : cfg_t1_shift;
    assign _85 = _3561;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_shift <= _544;
        else
            cfg_t1_shift <= _85;
    end
    assign _1382 = cfg_t1_shift[0:0];
    assign _1445 = _1382 ? _1444 : _1414;
    assign _3576 = _92[8:7];
    assign _3578 = _3576 == _219;
    assign _3579 = _3578 ? _1445 : t1_y;
    assign _3572 = _1345 == _618;
    assign _3573 = _3572 ? _1673 : t1_y;
    assign _3574 = _1351 ? _3573 : t1_y;
    assign _3568 = _1276 == _219;
    assign _3569 = _3568 ? _2573 : t1_y;
    assign _3566 = _1192 == _829;
    assign _3570 = _3566 ? _3569 : t1_y;
    assign _3565 = _1192 == _1476;
    assign _3575 = _3565 ? _3574 : _3570;
    assign _3564 = _1192 == _843;
    assign _3580 = _3564 ? _3579 : _3575;
    assign _3563 = _1192 == _458;
    assign _3587 = _3563 ? _3586 : _3580;
    assign _3588 = _1270 ? _3587 : t1_y;
    assign _3589 = _1187 ? t1_y : _3588;
    assign _3590 = _1181 ? t1_y : _3589;
    assign _3592 = _1175 ? _297 : _3590;
    assign _86 = _3592;
    assign _87 = _86;
    always @(posedge _131) begin
        if (_129)
            t1_y <= _297;
        else
            t1_y <= _87;
    end
    always @* begin
        case (_1348)
        0:
            _1673 <= t1_x;
        1:
            _1673 <= t1_y;
        2:
            _1673 <= _1663;
        3:
            _1673 <= t1_isr;
        4:
            _1673 <= t1_osr;
        5:
            _1673 <= _297;
        default:
            _1673 <= _1672;
        endcase
    end
    assign _3602 = _1345 == _458;
    assign _3603 = _3602 ? _1673 : t1_x;
    assign _1348 = _92[5:3];
    assign _1350 = _1348 < _1448;
    assign _1345 = _92[8:6];
    assign _1347 = _1345 < _1448;
    assign _1351 = _1347 & _1350;
    assign _3604 = _1351 ? _3603 : t1_x;
    assign _2572 = _92[4:0];
    assign _2573 = { _445,
                     _2572 };
    assign _1276 = _92[8:7];
    assign _3598 = _1276 == _216;
    assign _3599 = _3598 ? _2573 : t1_x;
    assign _3596 = _1192 == _829;
    assign _3600 = _3596 ? _3599 : t1_x;
    assign _3595 = _1192 == _1476;
    assign _3605 = _3595 ? _3604 : _3600;
    assign _3594 = _1192 == _843;
    assign _3609 = _3594 ? _3608 : _3605;
    assign _3593 = _1192 == _458;
    assign _3615 = _3593 ? _3614 : _3609;
    assign _3616 = _1270 ? _3615 : t1_x;
    assign _3617 = _1187 ? t1_x : _3616;
    assign _3618 = _1181 ? t1_x : _3617;
    assign _3620 = _1175 ? _297 : _3618;
    assign _88 = _3620;
    assign _89 = _88;
    always @(posedge _131) begin
        if (_129)
            t1_x <= _297;
        else
            t1_x <= _89;
    end
    assign _3624 = t1_x == _297;
    assign _3625 = ~ _3624;
    assign _3626 = ~ _3625;
    assign _3581 = _92[8:6];
    always @* begin
        case (_3581)
        0:
            _3635 <= vdd;
        1:
            _3635 <= _3626;
        2:
            _3635 <= _3625;
        3:
            _3635 <= _3630;
        4:
            _3635 <= _3629;
        5:
            _3635 <= _3632;
        6:
            _3635 <= _3633;
        default:
            _3635 <= _3634;
        endcase
    end
    assign _3622 = _1192 == _458;
    assign _3636 = _3622 & _3635;
    assign _3642 = _3636 | _3641;
    assign _3650 = _3642 ? _3649 : _3644;
    always @(posedge _131) begin
        if (_129)
            t1_pc <= _450;
        else
            t1_pc <= _91;
    end
    assign _3651 = _1270 ? _3650 : t1_pc;
    assign _3652 = _1187 ? t1_pc : _3651;
    assign _3653 = _1181 ? t1_pc : _3652;
    assign _3654 = _1175 ? cfg_t1_start : _3653;
    assign _90 = _3654;
    assign _91 = _90;
    assign _3659 = _1169 ? _3658 : _91;
    assign _3655 = ~ _1169;
    RM_IHPSG13_1P_256x16_c2_bm_bist
        sram1
        ( .A_CLK(_131),
          .A_MEN(vdd),
          .A_WEN(_1169),
          .A_REN(_3655),
          .A_ADDR(_3659),
          .A_DIN(_581),
          .A_DLY(vdd),
          .A_BM(_4003),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_450),
          .A_BIST_DIN(_297),
          .A_BIST_BM(_297),
          .A_DOUT(_3665[15:0]) );
    assign _92 = _3665;
    assign _1192 = _92[15:13];
    assign _1194 = _1192 == _618;
    assign _1208 = _1194 & _1207;
    assign _1221 = _1208 & _1220;
    assign _1229 = _1221 | _1228;
    assign _1235 = _1229 | _1234;
    assign _1246 = _1235 | _1245;
    assign _1268 = _1246 | _1267;
    assign _1269 = ~ _1268;
    assign _1270 = _1191 & _1269;
    assign _3676 = _1270 ? _3675 : t1_delay_left;
    assign _1186 = t1_delay_left == _614;
    assign _1187 = ~ _1186;
    assign _3679 = _1187 ? _3678 : _3676;
    assign _1181 = ~ _1180;
    assign _3680 = _1181 ? t1_delay_left : _3679;
    assign _1175 = ~ _1174;
    assign _3682 = _1175 ? _614 : _3680;
    assign _93 = _3682;
    assign _94 = _93;
    always @(posedge _131) begin
        if (_129)
            t1_delay_left <= _614;
        else
            t1_delay_left <= _94;
    end
    assign _1190 = t1_delay_left == _614;
    assign _3694 = cfg_t1_clkdiv - _775;
    assign _3684 = 7'b1011101;
    assign _3685 = _577 == _3684;
    assign _3683 = _571 & _575;
    assign _3686 = _3683 & _3685;
    assign _3687 = _3686 ? _581 : cfg_t1_clkdiv;
    assign _95 = _3687;
    always @(posedge _131) begin
        if (_129)
            cfg_t1_clkdiv <= _297;
        else
            cfg_t1_clkdiv <= _95;
    end
    assign _3692 = cfg_t1_clkdiv == _297;
    assign _3696 = _3692 ? _297 : _3694;
    assign _3690 = t1_div_count - _775;
    assign _3697 = _1180 ? _3696 : _3690;
    assign _3688 = ~ _1174;
    assign _3699 = _3688 ? _297 : _3697;
    assign _96 = _3699;
    always @(posedge _131) begin
        if (_129)
            t1_div_count <= _297;
        else
            t1_div_count <= _96;
    end
    assign _1180 = t1_div_count == _297;
    assign _1168 = ~ _1166;
    assign _1167 = _591[1:1];
    assign _1169 = _1167 & _1168;
    always @(posedge _131) begin
        if (_129)
            t1_loaded <= _565;
        else
            t1_loaded <= _1169;
    end
    assign _1173 = ~ t1_loaded;
    assign _1166 = cfg_ctrl[1:1];
    assign _1174 = _1166 & _1173;
    assign _1188 = _1174 & _1180;
    assign _1191 = _1188 & _1190;
    assign _3702 = _1191 & _3701;
    assign _3704 = _3702 & _3703;
    assign _3706 = _3704 & _3705;
    assign _3708 = _3706 | _3707;
    assign _97 = _3708;
    assign _470 = _97 & _469;
    assign _3710 = { _4091,
                     _470 };
    assign _3711 = t1_rx_level + _3710;
    assign _3714 = _3711 - _3713;
    assign _98 = _3714;
    always @(posedge _131) begin
        if (_129)
            t1_rx_level <= _458;
        else
            t1_rx_level <= _98;
    end
    assign _1914 = t1_rx_level == _458;
    assign _3730 = _1089 ? _1914 : _3365;
    assign _3731 = ~ _3730;
    assign _1089 = cfg_buf_ctrl[2:2];
    assign _3726 = ~ _1089;
    assign _3727 = _1629 & _3726;
    assign _3728 = ~ _3727;
    assign _3719 = _581[9:0];
    assign _3716 = 7'b1101010;
    assign _3717 = _577 == _3716;
    assign _3715 = _571 & _575;
    assign _3718 = _3715 & _3717;
    assign _3720 = _3718 ? _3719 : cfg_buf_end;
    assign _99 = _3720;
    always @(posedge _131) begin
        if (_129)
            cfg_buf_end <= _517;
        else
            cfg_buf_end <= _99;
    end
    assign _3723 = buf_ptr == cfg_buf_end;
    assign _3724 = ~ _3723;
    assign _3722 = _1097 == _219;
    assign _3725 = _3722 & _3724;
    assign _3729 = _3725 & _3728;
    assign _3732 = _3729 & _3731;
    assign _100 = _3732;
    assign _3737 = _103 | _100;
    assign _3738 = _3737 | _3380;
    assign _3740 = _3738 | _3739;
    assign _3743 = _3740 ? _3742 : buf_ptr;
    assign _3734 = 7'b1101001;
    assign _3735 = _577 == _3734;
    assign _3733 = _571 & _575;
    assign _3736 = _3733 & _3735;
    assign _3745 = _3736 ? _3744 : _3743;
    assign _101 = _3745;
    always @(posedge _131) begin
        if (_129)
            buf_ptr <= _517;
        else
            buf_ptr <= _101;
    end
    assign _3754 = buf_ptr == cfg_buf_end;
    assign _3755 = ~ _3754;
    assign _3750 = _581[2:0];
    assign _3747 = 7'b1101000;
    assign _3748 = _577 == _3747;
    assign _3746 = _571 & _575;
    assign _3749 = _3746 & _3748;
    assign _3751 = _3749 ? _3750 : cfg_buf_ctrl;
    assign _102 = _3751;
    always @(posedge _131) begin
        if (_129)
            cfg_buf_ctrl <= _458;
        else
            cfg_buf_ctrl <= _102;
    end
    assign _1097 = cfg_buf_ctrl[1:0];
    assign _3753 = _1097 == _216;
    assign _3756 = _3753 & _3755;
    assign _3761 = _3756 & _3760;
    assign _3764 = _3761 & _3763;
    assign _3767 = _3764 & _3766;
    assign _103 = _3767;
    assign _1092 = _103 & _1091;
    assign _1105 = _1092 | _1104;
    assign _1109 = _1105 & _1108;
    assign _3769 = { _4091,
                     _1109 };
    assign _3770 = t0_tx_level + _3769;
    assign _3773 = _3770 - _3772;
    assign _104 = _3773;
    always @(posedge _131) begin
        if (_129)
            t0_tx_level <= _458;
        else
            t0_tx_level <= _104;
    end
    assign _702 = t0_tx_level == _458;
    assign _1145 = ~ _702;
    assign _3778 = _581[4:0];
    assign _3775 = 7'b1000101;
    assign _3776 = _577 == _3775;
    assign _3774 = _571 & _575;
    assign _3777 = _3774 & _3776;
    assign _3779 = _3777 ? _3778 : cfg_t0_threshold;
    assign _105 = _3779;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_threshold <= _447;
        else
            cfg_t0_threshold <= _105;
    end
    assign _1139 = _1137[4:0];
    assign _733 = { gnd,
                    _730 };
    assign _730 = _117[3:0];
    assign _732 = _730 == _614;
    assign _735 = _732 ? _890 : _733;
    assign _1136 = { gnd,
                     _735 };
    assign _1135 = { gnd,
                     t0_osr_count };
    assign _1137 = _1135 + _1136;
    assign _1138 = _1757 < _1137;
    assign _1141 = _1138 ? _890 : _1139;
    assign _1142 = _1141 < cfg_t0_threshold;
    assign _1143 = ~ _1142;
    assign _1131 = _617 == _843;
    assign _1132 = _745 & _1131;
    assign _1133 = _1132 & _713;
    assign _1144 = _1133 & _1143;
    assign _1146 = _1144 & _1145;
    assign _3796 = _1146 ? _716 : _1141;
    assign _699 = _117[8:8];
    assign _3793 = _699 ? _716 : _3781;
    assign _3787 = _820 == _4100;
    assign _3789 = _3787 ? _716 : _3781;
    assign _3790 = _826 ? _3789 : _3781;
    assign _3785 = _617 == _1476;
    assign _3791 = _3785 ? _3790 : _3781;
    assign _3784 = _617 == _4100;
    assign _3794 = _3784 ? _3793 : _3791;
    assign _3783 = _617 == _843;
    assign _3797 = _3783 ? _3796 : _3794;
    assign _3781 = _1149 ? _716 : t0_osr_count;
    assign _3798 = _745 ? _3797 : _3781;
    assign _3799 = _612 ? t0_osr_count : _3798;
    assign _3800 = _606 ? t0_osr_count : _3799;
    assign _3801 = _600 ? cfg_t0_threshold : _3800;
    assign _106 = _3801;
    assign _107 = _106;
    always @(posedge _131) begin
        if (_129)
            t0_osr_count <= _716;
        else
            t0_osr_count <= _107;
    end
    assign _718 = t0_osr_count < cfg_t0_threshold;
    assign _719 = ~ _718;
    assign _713 = cfg_t0_shift[2:2];
    assign _712 = _617 == _843;
    assign _714 = _712 & _713;
    assign _720 = _714 & _719;
    assign _1148 = _616 & _720;
    assign _1149 = _1148 & _1145;
    assign _3828 = _1149 ? _3827 : t0_osr;
    assign _3897 = _745 ? _3896 : _3828;
    assign _3898 = _612 ? t0_osr : _3897;
    assign _3899 = _606 ? t0_osr : _3898;
    assign _3901 = _600 ? _297 : _3899;
    assign _108 = _3901;
    assign _109 = _108;
    always @(posedge _131) begin
        if (_129)
            t0_osr <= _297;
        else
            t0_osr <= _109;
    end
    assign _889 = t0_osr & _888;
    assign _3906 = _581[5:0];
    assign _3903 = 7'b1001111;
    assign _3904 = _577 == _3903;
    assign _3902 = _571 & _575;
    assign _3905 = _3902 & _3904;
    assign _3907 = _3905 ? _3906 : cfg_t0_shift;
    assign _110 = _3907;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_shift <= _544;
        else
            cfg_t0_shift <= _110;
    end
    assign _857 = cfg_t0_shift[0:0];
    assign _920 = _857 ? _919 : _889;
    assign _3922 = _117[8:7];
    assign _3924 = _3922 == _219;
    assign _3925 = _3924 ? _920 : t0_y;
    assign _3918 = _820 == _618;
    assign _3919 = _3918 ? _2129 : t0_y;
    assign _3920 = _826 ? _3919 : t0_y;
    assign _3914 = _751 == _219;
    assign _3915 = _3914 ? _1990 : t0_y;
    assign _3912 = _617 == _829;
    assign _3916 = _3912 ? _3915 : t0_y;
    assign _3911 = _617 == _1476;
    assign _3921 = _3911 ? _3920 : _3916;
    assign _3910 = _617 == _843;
    assign _3926 = _3910 ? _3925 : _3921;
    assign _3909 = _617 == _458;
    assign _3933 = _3909 ? _3932 : _3926;
    assign _3934 = _745 ? _3933 : t0_y;
    assign _3935 = _612 ? t0_y : _3934;
    assign _3936 = _606 ? t0_y : _3935;
    assign _3938 = _600 ? _297 : _3936;
    assign _111 = _3938;
    assign _112 = _111;
    always @(posedge _131) begin
        if (_129)
            t0_y <= _297;
        else
            t0_y <= _112;
    end
    always @* begin
        case (_823)
        0:
            _2129 <= t0_x;
        1:
            _2129 <= t0_y;
        2:
            _2129 <= _2116;
        3:
            _2129 <= t0_isr;
        4:
            _2129 <= t0_osr;
        5:
            _2129 <= _297;
        default:
            _2129 <= _2128;
        endcase
    end
    assign _3948 = _820 == _458;
    assign _3949 = _3948 ? _2129 : t0_x;
    assign _823 = _117[5:3];
    assign _825 = _823 < _1448;
    assign _820 = _117[8:6];
    assign _822 = _820 < _1448;
    assign _826 = _822 & _825;
    assign _3950 = _826 ? _3949 : t0_x;
    assign _1989 = _117[4:0];
    assign _1990 = { _445,
                     _1989 };
    assign _751 = _117[8:7];
    assign _3944 = _751 == _216;
    assign _3945 = _3944 ? _1990 : t0_x;
    assign _3942 = _617 == _829;
    assign _3946 = _3942 ? _3945 : t0_x;
    assign _3941 = _617 == _1476;
    assign _3951 = _3941 ? _3950 : _3946;
    assign _3940 = _617 == _843;
    assign _3955 = _3940 ? _3954 : _3951;
    assign _3939 = _617 == _458;
    assign _3961 = _3939 ? _3960 : _3955;
    assign _3962 = _745 ? _3961 : t0_x;
    assign _3963 = _612 ? t0_x : _3962;
    assign _3964 = _606 ? t0_x : _3963;
    assign _3966 = _600 ? _297 : _3964;
    assign _113 = _3966;
    assign _114 = _113;
    always @(posedge _131) begin
        if (_129)
            t0_x <= _297;
        else
            t0_x <= _114;
    end
    assign _3970 = t0_x == _297;
    assign _3971 = ~ _3970;
    assign _3972 = ~ _3971;
    assign _3927 = _117[8:6];
    always @* begin
        case (_3927)
        0:
            _3981 <= vdd;
        1:
            _3981 <= _3972;
        2:
            _3981 <= _3971;
        3:
            _3981 <= _3976;
        4:
            _3981 <= _3975;
        5:
            _3981 <= _3978;
        6:
            _3981 <= _3979;
        default:
            _3981 <= _3980;
        endcase
    end
    assign _3968 = _617 == _458;
    assign _3982 = _3968 & _3981;
    assign _3988 = _3982 | _3987;
    assign _3996 = _3988 ? _3995 : _3990;
    always @(posedge _131) begin
        if (_129)
            t0_pc <= _450;
        else
            t0_pc <= _116;
    end
    assign _3997 = _745 ? _3996 : t0_pc;
    assign _3998 = _612 ? t0_pc : _3997;
    assign _3999 = _606 ? t0_pc : _3998;
    assign _4000 = _600 ? cfg_t0_start : _3999;
    assign _115 = _4000;
    assign _116 = _115;
    assign _4002 = _594 ? _3658 : _116;
    assign _4001 = ~ _594;
    RM_IHPSG13_1P_256x16_c2_bm_bist
        sram0
        ( .A_CLK(_131),
          .A_MEN(vdd),
          .A_WEN(_594),
          .A_REN(_4001),
          .A_ADDR(_4002),
          .A_DIN(_581),
          .A_DLY(vdd),
          .A_BM(_4003),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_450),
          .A_BIST_DIN(_297),
          .A_BIST_BM(_297),
          .A_DOUT(_4008[15:0]) );
    assign _117 = _4008;
    assign _617 = _117[15:13];
    assign _619 = _617 == _618;
    assign _683 = _619 & _682;
    assign _696 = _683 & _695;
    assign _704 = _696 | _703;
    assign _710 = _704 | _709;
    assign _721 = _710 | _720;
    assign _743 = _721 | _742;
    assign _744 = ~ _743;
    assign _745 = _616 & _744;
    assign _4019 = _745 ? _4018 : t0_delay_left;
    assign _611 = t0_delay_left == _614;
    assign _612 = ~ _611;
    assign _4022 = _612 ? _4021 : _4019;
    assign _606 = ~ _605;
    assign _4023 = _606 ? t0_delay_left : _4022;
    assign _600 = ~ _599;
    assign _4025 = _600 ? _614 : _4023;
    assign _118 = _4025;
    assign _119 = _118;
    always @(posedge _131) begin
        if (_129)
            t0_delay_left <= _614;
        else
            t0_delay_left <= _119;
    end
    assign _615 = t0_delay_left == _614;
    assign _4037 = cfg_t0_clkdiv - _775;
    assign _4027 = 7'b1001101;
    assign _4028 = _577 == _4027;
    assign _4026 = _571 & _575;
    assign _4029 = _4026 & _4028;
    assign _4030 = _4029 ? _581 : cfg_t0_clkdiv;
    assign _120 = _4030;
    always @(posedge _131) begin
        if (_129)
            cfg_t0_clkdiv <= _297;
        else
            cfg_t0_clkdiv <= _120;
    end
    assign _4035 = cfg_t0_clkdiv == _297;
    assign _4039 = _4035 ? _297 : _4037;
    assign _4033 = t0_div_count - _775;
    assign _4040 = _605 ? _4039 : _4033;
    assign _4031 = ~ _599;
    assign _4042 = _4031 ? _297 : _4040;
    assign _121 = _4042;
    always @(posedge _131) begin
        if (_129)
            t0_div_count <= _297;
        else
            t0_div_count <= _121;
    end
    assign _605 = t0_div_count == _297;
    assign _593 = ~ _584;
    assign _422 = 6'b110000;
    assign _4047 = _581[5:0];
    assign _4044 = 7'b1010000;
    assign _4045 = _577 == _4044;
    assign _4043 = _571 & _575;
    assign _4046 = _4043 & _4045;
    assign _4048 = _4046 ? _4047 : cfg_load;
    assign _122 = _4048;
    always @(posedge _131) begin
        if (_129)
            cfg_load <= _422;
        else
            cfg_load <= _122;
    end
    assign _590 = cfg_load[5:4];
    assign _586 = 7'b1000000;
    assign _587 = _577 < _586;
    assign _585 = _571 & _575;
    assign _588 = _585 & _587;
    assign _589 = { _588,
                    _588 };
    assign _591 = _589 & _590;
    assign _592 = _591[0:0];
    assign _594 = _592 & _593;
    always @(posedge _131) begin
        if (_129)
            t0_loaded <= _565;
        else
            t0_loaded <= _594;
    end
    assign _598 = ~ t0_loaded;
    assign _584 = cfg_ctrl[0:0];
    assign _599 = _584 & _598;
    assign _613 = _599 & _605;
    assign _616 = _613 & _615;
    assign _4051 = _616 & _4050;
    assign _4053 = _4051 & _4052;
    assign _4055 = _4053 & _4054;
    assign _4057 = _4055 | _4056;
    assign _123 = _4057;
    assign _363 = _123 & _362;
    assign _4059 = { _4091,
                     _363 };
    assign _4060 = t0_rx_level + _4059;
    assign _4063 = _4060 - _4062;
    assign _124 = _4063;
    always @(posedge _131) begin
        if (_129)
            t0_rx_level <= _458;
        else
            t0_rx_level <= _124;
    end
    assign _3365 = t0_rx_level == _458;
    assign _4084 = ~ _3365;
    assign _581 = _309[15:0];
    assign _4082 = _581[2:0];
    assign _577 = host_cmd[6:0];
    assign _4080 = _577 == _586;
    assign _304 = _133[2:2];
    always @(posedge _131) begin
        if (_129)
            host_mosi_s1 <= gnd;
        else
            host_mosi_s1 <= _304;
    end
    always @(posedge _131) begin
        if (_129)
            host_mosi_s2 <= gnd;
        else
            host_mosi_s2 <= host_mosi_s1;
    end
    assign _302 = 23'b00000000000000000000000;
    assign _4064 = _309[22:0];
    assign _4065 = _295 ? _4064 : host_shift_in;
    assign _4066 = host_cs_n_s2 ? host_shift_in : _4065;
    assign _125 = _4066;
    always @(posedge _131) begin
        if (_129)
            host_shift_in <= _302;
        else
            host_shift_in <= _125;
    end
    assign _309 = { host_shift_in,
                    host_mosi_s2 };
    assign _310 = _309[7:0];
    assign _300 = host_bit_count == _1459;
    assign _4067 = _300 ? _310 : host_cmd;
    assign _4068 = _295 ? _4067 : host_cmd;
    assign _4069 = host_cs_n_s2 ? host_cmd : _4068;
    assign _126 = _4069;
    always @(posedge _131) begin
        if (_129)
            host_cmd <= _450;
        else
            host_cmd <= _126;
    end
    assign _575 = host_cmd[7:7];
    assign _569 = 5'b10111;
    assign _4073 = host_bit_count + _1046;
    assign _4070 = 5'b11000;
    assign _4071 = host_bit_count < _4070;
    assign _4074 = _4071 ? _4073 : host_bit_count;
    assign _4075 = _295 ? _4074 : host_bit_count;
    assign _4077 = host_cs_n_s2 ? _716 : _4075;
    assign _127 = _4077;
    always @(posedge _131) begin
        if (_129)
            host_bit_count <= _716;
        else
            host_bit_count <= _127;
    end
    assign _570 = host_bit_count == _569;
    assign _267 = _133[1:1];
    always @(posedge _131) begin
        if (_129)
            host_cs_n_s1 <= vdd;
        else
            host_cs_n_s1 <= _267;
    end
    always @(posedge _131) begin
        if (_129)
            host_cs_n_s2 <= vdd;
        else
            host_cs_n_s2 <= host_cs_n_s1;
    end
    assign _294 = ~ host_cs_n_s2;
    always @(posedge _131) begin
        if (_129)
            host_sck_prev <= _565;
        else
            host_sck_prev <= host_sck_s2;
    end
    assign _292 = ~ host_sck_prev;
    assign vdd = 1'b1;
    assign _129 = clear;
    assign _131 = clock;
    assign _133 = ui_in;
    assign _272 = _133[0:0];
    always @(posedge _131) begin
        if (_129)
            host_sck_s1 <= gnd;
        else
            host_sck_s1 <= _272;
    end
    always @(posedge _131) begin
        if (_129)
            host_sck_s2 <= gnd;
        else
            host_sck_s2 <= host_sck_s1;
    end
    assign _293 = host_sck_s2 & _292;
    assign _295 = _293 & _294;
    assign _571 = _295 & _570;
    assign _4078 = _571 & _575;
    assign _4081 = _4078 & _4080;
    assign _4083 = _4081 ? _4082 : cfg_ctrl;
    assign _134 = _4083;
    always @(posedge _131) begin
        if (_129)
            cfg_ctrl <= _458;
        else
            cfg_ctrl <= _134;
    end
    assign _1629 = cfg_ctrl[2:2];
    assign _4085 = _1629 & _4084;
    assign _4087 = _4085 & _4086;
    assign _135 = _4087;
    assign _1617 = _135 | _1616;
    assign _1632 = _1617 | _1631;
    assign _1636 = _1632 & _1635;
    assign _4089 = { _4091,
                     _1636 };
    assign _4090 = t1_tx_level + _4089;
    assign _4093 = _4090 - _4092;
    assign _136 = _4093;
    always @(posedge _131) begin
        if (_129)
            t1_tx_level <= _458;
        else
            t1_tx_level <= _136;
    end
    assign _4095 = t1_tx_level == _4100;
    assign gnd = 1'b0;
    assign _4107 = { gnd,
                     _4095,
                     _4098,
                     _4099,
                     _4101,
                     _4104,
                     _4105,
                     _4106 };
    assign uo_out = _4107;
    assign uio_out = _266;
    assign uio_oe = _225;

endmodule
