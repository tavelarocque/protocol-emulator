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

    wire _121;
    wire _122;
    wire [1:0] _119;
    wire _120;
    wire _123;
    wire [1:0] _117;
    wire [1:0] _116;
    wire _118;
    wire _124;
    wire _112;
    wire _113;
    wire _111;
    wire _114;
    wire [1:0] _107;
    wire _109;
    wire _115;
    wire _103;
    wire _104;
    wire _102;
    wire _105;
    wire [1:0] _98;
    wire _100;
    wire _106;
    wire _94;
    wire _95;
    wire _93;
    wire _96;
    wire [1:0] _89;
    wire _91;
    wire _97;
    wire _85;
    wire _86;
    wire _84;
    wire _87;
    wire [1:0] _80;
    wire _82;
    wire _88;
    wire _76;
    wire _77;
    wire _75;
    wire _78;
    wire [1:0] _71;
    wire _73;
    wire _79;
    wire _67;
    wire _68;
    wire _66;
    wire _69;
    wire [1:0] _62;
    wire _64;
    wire _70;
    wire _58;
    wire _59;
    wire _54;
    wire _60;
    wire [1:0] _50;
    wire _52;
    wire _61;
    wire [7:0] _125;
    wire _164;
    wire [1:0] _161;
    wire _163;
    wire _165;
    wire _159;
    wire [1:0] _156;
    wire _158;
    wire _160;
    wire _154;
    wire [1:0] _151;
    wire _153;
    wire _155;
    wire _149;
    wire [1:0] _146;
    wire _148;
    wire _150;
    wire _144;
    wire [1:0] _141;
    wire _143;
    wire _145;
    wire _139;
    wire [1:0] _136;
    wire _138;
    wire _140;
    wire _134;
    wire [1:0] _131;
    wire _133;
    wire _135;
    wire _129;
    wire [1:0] _126;
    wire _128;
    wire _130;
    wire [7:0] _166;
    wire [15:0] _256;
    wire _356;
    wire [14:0] _355;
    wire [15:0] _357;
    wire [1:0] _339;
    wire [15:0] _346;
    wire [1:0] _334;
    wire _335;
    wire _336;
    reg [15:0] rx_mem_3;
    wire _329;
    wire _330;
    reg [15:0] rx_mem_2;
    wire _323;
    wire _324;
    reg [15:0] rx_mem_1;
    wire [1:0] _178;
    wire [1:0] _179;
    wire [1:0] _3;
    reg [1:0] rx_wr;
    wire _317;
    wire _318;
    wire [15:0] _212;
    wire [31:0] _213;
    wire [23:0] _208;
    wire [7:0] _207;
    wire [31:0] _209;
    wire [27:0] _204;
    wire [3:0] _203;
    wire [31:0] _205;
    wire [29:0] _200;
    wire [31:0] _201;
    wire [30:0] _196;
    wire [31:0] _197;
    wire [31:0] _194;
    wire _189;
    wire [31:0] _198;
    wire _188;
    wire [31:0] _202;
    wire _187;
    wire [31:0] _206;
    wire _186;
    wire [31:0] _210;
    wire [4:0] _180;
    wire [4:0] _184;
    wire _185;
    wire [31:0] _214;
    wire [15:0] _215;
    wire [15:0] _4;
    reg [15:0] rx_mem_0;
    wire [1:0] _224;
    wire [1:0] _225;
    wire [1:0] _5;
    reg [1:0] rx_rd;
    reg [15:0] _338;
    wire [9:0] _309;
    wire [15:0] _313;
    wire [10:0] _304;
    wire [15:0] _308;
    wire [12:0] _299;
    wire [15:0] _303;
    wire [15:0] _298;
    wire [15:0] _293;
    wire [15:0] _288;
    wire [14:0] _279;
    wire [15:0] _283;
    reg [15:0] _350;
    wire _276;
    wire [6:0] _271;
    wire _272;
    wire _277;
    wire [15:0] _352;
    wire [15:0] _353;
    wire [15:0] _354;
    wire [4:0] _247;
    wire _248;
    wire _249;
    wire _242;
    wire _237;
    wire _241;
    wire _243;
    wire _250;
    wire [15:0] _358;
    wire [15:0] _359;
    wire [15:0] _6;
    reg [15:0] _257;
    wire _1831;
    wire [2:0] _1829;
    wire [2:0] _344;
    wire _1626;
    wire _1806;
    wire _1803;
    wire [3:0] _1791;
    wire [3:0] _1792;
    wire [3:0] _1789;
    wire _217;
    wire _218;
    wire _274;
    wire _275;
    wire [6:0] _270;
    wire _367;
    wire _363;
    wire _364;
    wire [4:0] _360;
    wire _361;
    wire _362;
    wire _365;
    wire _368;
    wire _369;
    wire _7;
    wire _219;
    wire [2:0] _788;
    wire _172;
    wire _782;
    wire _780;
    wire _777;
    wire _778;
    wire _781;
    wire _783;
    wire _8;
    wire _173;
    wire [2:0] _785;
    wire [2:0] _786;
    wire [2:0] _789;
    wire [2:0] _9;
    reg [2:0] rx_level;
    wire _171;
    wire _903;
    wire _902;
    wire _904;
    wire _905;
    wire _898;
    wire _895;
    wire _896;
    wire _899;
    wire _892;
    wire _889;
    wire [2:0] _887;
    wire [5:0] _770;
    wire _771;
    wire _772;
    reg [15:0] prog_63;
    wire [5:0] _764;
    wire _765;
    wire _766;
    reg [15:0] prog_62;
    wire [5:0] _758;
    wire _759;
    wire _760;
    reg [15:0] prog_61;
    wire [5:0] _752;
    wire _753;
    wire _754;
    reg [15:0] prog_60;
    wire [5:0] _746;
    wire _747;
    wire _748;
    reg [15:0] prog_59;
    wire [5:0] _740;
    wire _741;
    wire _742;
    reg [15:0] prog_58;
    wire [5:0] _734;
    wire _735;
    wire _736;
    reg [15:0] prog_57;
    wire [5:0] _728;
    wire _729;
    wire _730;
    reg [15:0] prog_56;
    wire [5:0] _722;
    wire _723;
    wire _724;
    reg [15:0] prog_55;
    wire [5:0] _716;
    wire _717;
    wire _718;
    reg [15:0] prog_54;
    wire [5:0] _710;
    wire _711;
    wire _712;
    reg [15:0] prog_53;
    wire [5:0] _704;
    wire _705;
    wire _706;
    reg [15:0] prog_52;
    wire [5:0] _698;
    wire _699;
    wire _700;
    reg [15:0] prog_51;
    wire [5:0] _692;
    wire _693;
    wire _694;
    reg [15:0] prog_50;
    wire [5:0] _686;
    wire _687;
    wire _688;
    reg [15:0] prog_49;
    wire [5:0] _680;
    wire _681;
    wire _682;
    reg [15:0] prog_48;
    wire [5:0] _674;
    wire _675;
    wire _676;
    reg [15:0] prog_47;
    wire [5:0] _668;
    wire _669;
    wire _670;
    reg [15:0] prog_46;
    wire [5:0] _662;
    wire _663;
    wire _664;
    reg [15:0] prog_45;
    wire [5:0] _656;
    wire _657;
    wire _658;
    reg [15:0] prog_44;
    wire [5:0] _650;
    wire _651;
    wire _652;
    reg [15:0] prog_43;
    wire [5:0] _644;
    wire _645;
    wire _646;
    reg [15:0] prog_42;
    wire [5:0] _638;
    wire _639;
    wire _640;
    reg [15:0] prog_41;
    wire [5:0] _632;
    wire _633;
    wire _634;
    reg [15:0] prog_40;
    wire [5:0] _626;
    wire _627;
    wire _628;
    reg [15:0] prog_39;
    wire [5:0] _620;
    wire _621;
    wire _622;
    reg [15:0] prog_38;
    wire [5:0] _614;
    wire _615;
    wire _616;
    reg [15:0] prog_37;
    wire [5:0] _608;
    wire _609;
    wire _610;
    reg [15:0] prog_36;
    wire [5:0] _602;
    wire _603;
    wire _604;
    reg [15:0] prog_35;
    wire [5:0] _596;
    wire _597;
    wire _598;
    reg [15:0] prog_34;
    wire [5:0] _590;
    wire _591;
    wire _592;
    reg [15:0] prog_33;
    wire [5:0] _584;
    wire _585;
    wire _586;
    reg [15:0] prog_32;
    wire [5:0] _578;
    wire _579;
    wire _580;
    reg [15:0] prog_31;
    wire [5:0] _572;
    wire _573;
    wire _574;
    reg [15:0] prog_30;
    wire [5:0] _566;
    wire _567;
    wire _568;
    reg [15:0] prog_29;
    wire [5:0] _560;
    wire _561;
    wire _562;
    reg [15:0] prog_28;
    wire [5:0] _554;
    wire _555;
    wire _556;
    reg [15:0] prog_27;
    wire [5:0] _548;
    wire _549;
    wire _550;
    reg [15:0] prog_26;
    wire [5:0] _542;
    wire _543;
    wire _544;
    reg [15:0] prog_25;
    wire [5:0] _536;
    wire _537;
    wire _538;
    reg [15:0] prog_24;
    wire [5:0] _530;
    wire _531;
    wire _532;
    reg [15:0] prog_23;
    wire [5:0] _524;
    wire _525;
    wire _526;
    reg [15:0] prog_22;
    wire [5:0] _518;
    wire _519;
    wire _520;
    reg [15:0] prog_21;
    wire [5:0] _512;
    wire _513;
    wire _514;
    reg [15:0] prog_20;
    wire [5:0] _506;
    wire _507;
    wire _508;
    reg [15:0] prog_19;
    wire [5:0] _500;
    wire _501;
    wire _502;
    reg [15:0] prog_18;
    wire [5:0] _494;
    wire _495;
    wire _496;
    reg [15:0] prog_17;
    wire [5:0] _488;
    wire _489;
    wire _490;
    reg [15:0] prog_16;
    wire [5:0] _482;
    wire _483;
    wire _484;
    reg [15:0] prog_15;
    wire [5:0] _476;
    wire _477;
    wire _478;
    reg [15:0] prog_14;
    wire [5:0] _470;
    wire _471;
    wire _472;
    reg [15:0] prog_13;
    wire [5:0] _464;
    wire _465;
    wire _466;
    reg [15:0] prog_12;
    wire [5:0] _458;
    wire _459;
    wire _460;
    reg [15:0] prog_11;
    wire [5:0] _452;
    wire _453;
    wire _454;
    reg [15:0] prog_10;
    wire [5:0] _446;
    wire _447;
    wire _448;
    reg [15:0] prog_9;
    wire [5:0] _440;
    wire _441;
    wire _442;
    reg [15:0] prog_8;
    wire [5:0] _434;
    wire _435;
    wire _436;
    reg [15:0] prog_7;
    wire [5:0] _428;
    wire _429;
    wire _430;
    reg [15:0] prog_6;
    wire [5:0] _422;
    wire _423;
    wire _424;
    reg [15:0] prog_5;
    wire [5:0] _416;
    wire _417;
    wire _418;
    reg [15:0] prog_4;
    wire [5:0] _410;
    wire _411;
    wire _412;
    reg [15:0] prog_3;
    wire [5:0] _404;
    wire _405;
    wire _406;
    reg [15:0] prog_2;
    wire [5:0] _398;
    wire _399;
    wire _400;
    reg [15:0] prog_1;
    wire [5:0] _392;
    wire [5:0] _391;
    wire _393;
    wire [6:0] _388;
    wire _389;
    wire _386;
    wire _390;
    wire _394;
    reg [15:0] prog_0;
    wire [5:0] _794;
    wire [6:0] _791;
    wire _792;
    wire _790;
    wire _793;
    wire [5:0] _795;
    wire [5:0] _10;
    reg [5:0] _287;
    wire [5:0] _1783;
    wire [5:0] _800;
    wire [6:0] _797;
    wire _798;
    wire _796;
    wire _799;
    wire [5:0] _801;
    wire [5:0] _11;
    reg [5:0] _312;
    wire _1782;
    wire [5:0] _1784;
    wire [5:0] _1780;
    wire [15:0] _876;
    wire [15:0] _877;
    wire [15:0] _878;
    wire [15:0] _879;
    wire [15:0] _881;
    wire [15:0] _12;
    reg [15:0] wait_count;
    wire [6:0] _883;
    wire _884;
    wire _882;
    wire _885;
    wire [15:0] _886;
    wire [15:0] _13;
    reg [15:0] _349;
    wire _909;
    wire _874;
    wire _861;
    wire _807;
    wire _862;
    wire _864;
    wire _875;
    wire _910;
    wire _912;
    wire _913;
    wire _915;
    wire _14;
    reg waiting;
    wire [15:0] _871;
    wire _873;
    wire _863;
    wire _891;
    wire _859;
    wire _857;
    wire _856;
    wire _855;
    wire _854;
    wire _853;
    wire _852;
    wire _851;
    wire _850;
    wire [2:0] _808;
    reg _858;
    wire _860;
    wire _1775;
    wire _1774;
    wire _1776;
    wire _1777;
    wire [4:0] _182;
    wire [4:0] _949;
    wire [5:0] _946;
    wire [5:0] _939;
    wire [5:0] _947;
    wire _948;
    wire [4:0] _951;
    wire [4:0] _936;
    wire _930;
    wire [4:0] _932;
    wire [4:0] _933;
    wire _921;
    wire [4:0] _934;
    wire _919;
    wire [4:0] _937;
    wire _917;
    wire [4:0] _952;
    wire [4:0] _953;
    wire [4:0] _954;
    wire [4:0] _956;
    wire [4:0] _15;
    reg [4:0] isr_count;
    wire _1770;
    wire [4:0] _306;
    wire [4:0] _961;
    wire [6:0] _958;
    wire _959;
    wire _957;
    wire _960;
    wire [4:0] _962;
    wire [4:0] _16;
    reg [4:0] _307;
    wire [4:0] _984;
    wire [5:0] _981;
    wire [5:0] _980;
    wire [5:0] _982;
    wire _983;
    wire [4:0] _986;
    wire [4:0] _977;
    wire _971;
    wire [4:0] _973;
    wire [4:0] _974;
    wire _969;
    wire [4:0] _975;
    wire _968;
    wire [4:0] _978;
    wire _967;
    wire [4:0] _987;
    wire [4:0] _988;
    wire [4:0] _989;
    wire [4:0] _990;
    wire [4:0] _17;
    reg [4:0] osr_count;
    wire _1769;
    wire _1767;
    wire _1768;
    wire _1764;
    wire _1765;
    wire _1766;
    wire [15:0] _1750;
    wire [2:0] _1747;
    wire _1748;
    wire [15:0] _1751;
    wire _1744;
    wire [15:0] _1745;
    wire [15:0] _1159;
    wire [31:0] _1160;
    wire [23:0] _1155;
    wire [31:0] _1156;
    wire [27:0] _1151;
    wire [31:0] _1152;
    wire [29:0] _1147;
    wire [31:0] _1148;
    wire [30:0] _1143;
    wire [31:0] _1144;
    wire _1135;
    wire _1132;
    wire _1131;
    wire _1130;
    wire _1129;
    wire _1128;
    wire _1127;
    wire _1126;
    wire _1125;
    reg _1133;
    wire _1136;
    wire [4:0] _1122;
    wire _1123;
    wire _1120;
    wire _1119;
    wire _1118;
    wire _1117;
    wire _1116;
    wire _1115;
    wire _1114;
    wire _1113;
    wire [2:0] _1112;
    reg _1121;
    wire _1124;
    wire [4:0] _1108;
    wire _1109;
    wire _1106;
    wire _1105;
    wire _1104;
    wire _1103;
    wire _1102;
    wire _1101;
    wire _1100;
    wire _1099;
    wire [2:0] _1098;
    reg _1107;
    wire _1110;
    wire [4:0] _1094;
    wire _1095;
    wire _1092;
    wire _1091;
    wire _1090;
    wire _1089;
    wire _1088;
    wire _1087;
    wire _1086;
    wire _1085;
    wire [2:0] _1083;
    wire [2:0] _1084;
    reg _1093;
    wire _1096;
    wire [4:0] _1080;
    wire _1081;
    wire _1078;
    wire _1077;
    wire _1076;
    wire _1075;
    wire _1074;
    wire _1073;
    wire _1072;
    wire _1071;
    wire [2:0] _1070;
    reg _1079;
    wire _1082;
    wire [4:0] _1066;
    wire _1067;
    wire _1064;
    wire _1063;
    wire _1062;
    wire _1061;
    wire _1060;
    wire _1059;
    wire _1058;
    wire _1057;
    wire [2:0] _1055;
    wire [2:0] _1056;
    reg _1065;
    wire _1068;
    wire [4:0] _1052;
    wire _1053;
    wire _1050;
    wire _1049;
    wire _1048;
    wire _1047;
    wire _1046;
    wire _1045;
    wire _1044;
    wire _1043;
    wire [2:0] _1041;
    wire [2:0] _1042;
    reg _1051;
    wire _1054;
    wire _1039;
    wire _1036;
    wire _1035;
    wire _1034;
    wire _1033;
    wire _1032;
    wire _1031;
    wire _1030;
    wire _1029;
    wire [2:0] _1027;
    wire [2:0] _995;
    wire [6:0] _992;
    wire _993;
    wire _991;
    wire _994;
    wire [2:0] _996;
    wire [2:0] _18;
    reg [2:0] _302;
    wire [2:0] _1028;
    reg _1037;
    wire _1040;
    wire [7:0] _1137;
    wire [15:0] _1138;
    wire [1:0] _1025;
    reg [15:0] _1140;
    wire [31:0] _1141;
    wire _1024;
    wire [31:0] _1145;
    wire _1023;
    wire [31:0] _1149;
    wire _1022;
    wire [31:0] _1153;
    wire _1021;
    wire [31:0] _1157;
    wire _1020;
    wire [31:0] _1161;
    wire [15:0] _1162;
    wire [15:0] _1018;
    wire _1000;
    wire [15:0] _1014;
    wire [15:0] _1015;
    wire _999;
    wire [15:0] _1016;
    wire _998;
    wire [15:0] _1019;
    wire _997;
    wire [15:0] _1163;
    wire [15:0] _1164;
    wire [15:0] _1165;
    wire [15:0] _1167;
    wire [15:0] _19;
    reg [15:0] isr;
    wire _847;
    wire _846;
    wire _845;
    wire [1:0] _844;
    reg _848;
    wire _842;
    wire _841;
    wire _840;
    wire [1:0] _839;
    reg _843;
    wire _837;
    wire _836;
    wire _835;
    wire [1:0] _834;
    reg _838;
    wire _832;
    wire _831;
    wire _830;
    wire [1:0] _829;
    reg _833;
    wire _827;
    wire _826;
    wire _825;
    wire [1:0] _824;
    reg _828;
    wire _822;
    wire _821;
    wire _820;
    wire [1:0] _819;
    reg _823;
    wire _817;
    wire _816;
    wire _815;
    wire [1:0] _814;
    reg _818;
    wire _812;
    wire [7:0] _56;
    wire _1598;
    wire _1597;
    wire _1596;
    wire _1595;
    wire _1594;
    wire _1593;
    wire _1592;
    wire _1591;
    reg _1599;
    wire _1590;
    wire [2:0] _1587;
    wire [4:0] _1588;
    wire _1589;
    wire _1600;
    wire _1582;
    wire _1581;
    wire _1580;
    wire _1579;
    wire _1578;
    wire _1577;
    wire _1576;
    wire _1575;
    reg _1583;
    wire _1574;
    wire [2:0] _1571;
    wire [4:0] _1572;
    wire _1573;
    wire _1584;
    wire _1566;
    wire _1565;
    wire _1564;
    wire _1563;
    wire _1562;
    wire _1561;
    wire _1560;
    wire _1559;
    reg _1567;
    wire _1558;
    wire [2:0] _1555;
    wire [4:0] _1556;
    wire _1557;
    wire _1568;
    wire _1550;
    wire _1549;
    wire _1548;
    wire _1547;
    wire _1546;
    wire _1545;
    wire _1544;
    wire _1543;
    reg _1551;
    wire _1542;
    wire [2:0] _1539;
    wire [4:0] _1540;
    wire _1541;
    wire _1552;
    wire _1534;
    wire _1533;
    wire _1532;
    wire _1531;
    wire _1530;
    wire _1529;
    wire _1528;
    wire _1527;
    reg _1535;
    wire _1526;
    wire [2:0] _1523;
    wire [4:0] _1524;
    wire _1525;
    wire _1536;
    wire _1518;
    wire _1517;
    wire _1516;
    wire _1515;
    wire _1514;
    wire _1513;
    wire _1512;
    wire _1511;
    reg _1519;
    wire _1510;
    wire [2:0] _1507;
    wire [4:0] _1508;
    wire _1509;
    wire _1520;
    wire _1502;
    wire _1501;
    wire _1500;
    wire _1499;
    wire _1498;
    wire _1497;
    wire _1496;
    wire _1495;
    reg _1503;
    wire _1494;
    wire [2:0] _1491;
    wire [4:0] _1492;
    wire _1493;
    wire _1504;
    wire _1486;
    wire _1485;
    wire _1484;
    wire _1483;
    wire _1482;
    wire _1481;
    wire _1480;
    wire _1479;
    reg _1487;
    wire _1451;
    wire [2:0] _1448;
    wire [4:0] _1449;
    wire _1450;
    wire _1488;
    wire [7:0] _1601;
    wire _1445;
    wire [7:0] _1602;
    wire _1436;
    wire _1435;
    wire _1434;
    wire _1433;
    wire _1432;
    wire _1431;
    wire _1430;
    wire _1429;
    reg _1437;
    wire _1428;
    wire [2:0] _1425;
    wire [3:0] _1426;
    wire _1427;
    wire _1438;
    wire _1421;
    wire _1420;
    wire _1419;
    wire _1418;
    wire _1417;
    wire _1416;
    wire _1415;
    wire _1414;
    reg _1422;
    wire _1413;
    wire [2:0] _1410;
    wire [3:0] _1411;
    wire _1412;
    wire _1423;
    wire _1406;
    wire _1405;
    wire _1404;
    wire _1403;
    wire _1402;
    wire _1401;
    wire _1400;
    wire _1399;
    reg _1407;
    wire _1398;
    wire [2:0] _1395;
    wire [3:0] _1396;
    wire _1397;
    wire _1408;
    wire _1391;
    wire _1390;
    wire _1389;
    wire _1388;
    wire _1387;
    wire _1386;
    wire _1385;
    wire _1384;
    reg _1392;
    wire _1383;
    wire [2:0] _1380;
    wire [3:0] _1381;
    wire _1382;
    wire _1393;
    wire _1376;
    wire _1375;
    wire _1374;
    wire _1373;
    wire _1372;
    wire _1371;
    wire _1370;
    wire _1369;
    reg _1377;
    wire _1368;
    wire [2:0] _1365;
    wire [3:0] _1366;
    wire _1367;
    wire _1378;
    wire _1361;
    wire _1360;
    wire _1359;
    wire _1358;
    wire _1357;
    wire _1356;
    wire _1355;
    wire _1354;
    reg _1362;
    wire _1353;
    wire [2:0] _1350;
    wire [3:0] _1351;
    wire _1352;
    wire _1363;
    wire _1346;
    wire _1345;
    wire _1344;
    wire _1343;
    wire _1342;
    wire _1341;
    wire _1340;
    wire _1339;
    reg _1347;
    wire _1338;
    wire [2:0] _1335;
    wire [3:0] _1336;
    wire _1337;
    wire _1348;
    wire _1331;
    wire _1330;
    wire _1329;
    wire _1328;
    wire _1327;
    wire _1326;
    wire _1325;
    wire _1324;
    reg _1332;
    wire _1323;
    wire [3:0] _1321;
    wire [7:0] _291;
    wire [7:0] _1172;
    wire [6:0] _1169;
    wire _1170;
    wire _1168;
    wire _1171;
    wire [7:0] _1173;
    wire [7:0] _20;
    reg [7:0] _292;
    wire [2:0] _1318;
    wire [2:0] _1319;
    wire [3:0] _1320;
    wire _1322;
    wire _1333;
    wire [7:0] _1439;
    wire _1316;
    wire [7:0] _1440;
    wire [7:0] _1441;
    wire _1309;
    wire _1308;
    wire _1307;
    wire _1306;
    wire _1305;
    wire _1304;
    wire _1303;
    wire _1302;
    reg _1310;
    wire _1301;
    wire [2:0] _1298;
    wire [3:0] _1299;
    wire _1300;
    wire _1311;
    wire _1294;
    wire _1293;
    wire _1292;
    wire _1291;
    wire _1290;
    wire _1289;
    wire _1288;
    wire _1287;
    reg _1295;
    wire _1286;
    wire [2:0] _1283;
    wire [3:0] _1284;
    wire _1285;
    wire _1296;
    wire _1279;
    wire _1278;
    wire _1277;
    wire _1276;
    wire _1275;
    wire _1274;
    wire _1273;
    wire _1272;
    reg _1280;
    wire _1271;
    wire [2:0] _1268;
    wire [3:0] _1269;
    wire _1270;
    wire _1281;
    wire _1264;
    wire _1263;
    wire _1262;
    wire _1261;
    wire _1260;
    wire _1259;
    wire _1258;
    wire _1257;
    reg _1265;
    wire _1256;
    wire [2:0] _1253;
    wire [3:0] _1254;
    wire _1255;
    wire _1266;
    wire _1249;
    wire _1248;
    wire _1247;
    wire _1246;
    wire _1245;
    wire _1244;
    wire _1243;
    wire _1242;
    reg _1250;
    wire _1241;
    wire [2:0] _1238;
    wire [3:0] _1239;
    wire _1240;
    wire _1251;
    wire _1234;
    wire _1233;
    wire _1232;
    wire _1231;
    wire _1230;
    wire _1229;
    wire _1228;
    wire _1227;
    reg _1235;
    wire _1226;
    wire [2:0] _1223;
    wire [3:0] _1224;
    wire _1225;
    wire _1236;
    wire _1219;
    wire _1218;
    wire _1217;
    wire _1216;
    wire _1215;
    wire _1214;
    wire _1213;
    wire _1212;
    reg _1220;
    wire _1211;
    wire [2:0] _1208;
    wire [3:0] _1209;
    wire _1210;
    wire _1221;
    wire _1204;
    wire _1203;
    wire _1202;
    wire _1201;
    wire _1200;
    wire _1199;
    wire _1198;
    wire _1197;
    reg _1205;
    wire _1193;
    wire [3:0] _1191;
    wire [7:0] _1178;
    wire [6:0] _1175;
    wire _1176;
    wire _1174;
    wire _1177;
    wire [7:0] _1179;
    wire [7:0] _21;
    reg [7:0] _297;
    wire [2:0] _1188;
    wire [2:0] _1189;
    wire [3:0] _1190;
    wire _1192;
    wire _1206;
    wire [7:0] _1312;
    wire _1186;
    wire [7:0] _1313;
    wire _1183;
    wire [7:0] _1314;
    wire _1181;
    wire [7:0] _1442;
    wire _1180;
    wire [7:0] _1603;
    wire [7:0] _1604;
    wire [7:0] _1605;
    wire [7:0] _1606;
    wire [7:0] _22;
    reg [7:0] pin_out;
    wire _811;
    wire [7:0] _24;
    wire _810;
    wire [6:0] _1608;
    wire _1609;
    wire _1607;
    wire _1610;
    wire [15:0] _1611;
    wire [15:0] _25;
    reg [15:0] _49;
    wire [1:0] _809;
    reg _813;
    wire [7:0] _849;
    wire [15:0] _1008;
    wire [15:0] _1723;
    wire _1721;
    wire [15:0] _1724;
    wire [15:0] _1472;
    wire [31:0] _1474;
    wire [23:0] _1468;
    wire [31:0] _1470;
    wire [27:0] _1464;
    wire [31:0] _1466;
    wire [29:0] _1460;
    wire [31:0] _1462;
    wire [31:0] _1458;
    wire [31:0] _1457;
    wire _1456;
    wire [31:0] _1459;
    wire _1455;
    wire [31:0] _1463;
    wire _1454;
    wire [31:0] _1467;
    wire _1453;
    wire [31:0] _1471;
    wire _1452;
    wire [31:0] _1475;
    wire [15:0] _1476;
    wire [15:0] _1477;
    wire [15:0] _1692;
    wire [31:0] _1693;
    wire [23:0] _1688;
    wire [31:0] _1689;
    wire [27:0] _1684;
    wire [31:0] _1685;
    wire [29:0] _1680;
    wire [31:0] _1681;
    wire [30:0] _1676;
    wire [31:0] _1677;
    wire [31:0] _1674;
    wire _1672;
    wire [31:0] _1678;
    wire _1671;
    wire [31:0] _1682;
    wire _1670;
    wire [31:0] _1686;
    wire _1669;
    wire [31:0] _1690;
    wire [4:0] _943;
    wire [3:0] _940;
    wire _942;
    wire [4:0] _945;
    wire _1668;
    wire [31:0] _1694;
    wire [15:0] _1695;
    wire _1662;
    wire _1663;
    reg [15:0] tx_mem_3;
    wire _1656;
    wire _1657;
    reg [15:0] tx_mem_2;
    wire _1650;
    wire _1651;
    reg [15:0] tx_mem_1;
    wire [1:0] _1624;
    wire [1:0] _1625;
    wire [1:0] _26;
    reg [1:0] tx_wr;
    wire _1644;
    wire _1645;
    reg [15:0] tx_mem_0;
    wire [1:0] _1632;
    wire [1:0] _1633;
    wire [1:0] _27;
    reg [1:0] tx_rd;
    reg [15:0] _1665;
    wire _779;
    wire [15:0] _1666;
    wire _1637;
    wire [15:0] _1638;
    wire [15:0] _1639;
    wire _1636;
    wire [15:0] _1640;
    wire _1635;
    wire [15:0] _1667;
    wire _1634;
    wire [15:0] _1696;
    wire [15:0] _1697;
    wire [15:0] _1698;
    wire [15:0] _1700;
    wire [15:0] _28;
    reg [15:0] osr;
    wire [15:0] _1478;
    wire [1:0] _1443;
    wire _1716;
    wire [15:0] _1717;
    wire _1711;
    wire [15:0] _1712;
    wire [15:0] _1713;
    wire _1707;
    wire [15:0] _1708;
    wire _1705;
    wire [15:0] _1709;
    wire _1704;
    wire [15:0] _1714;
    wire _1703;
    wire [15:0] _1718;
    wire _1702;
    wire [15:0] _1725;
    wire [15:0] _1726;
    wire [15:0] _1727;
    wire [15:0] _1729;
    wire [15:0] _29;
    reg [15:0] y;
    reg [15:0] _1013;
    wire _1739;
    wire [15:0] _1740;
    wire [2:0] _925;
    wire _927;
    wire [2:0] _922;
    wire _924;
    wire _928;
    wire [15:0] _1741;
    wire [4:0] _1195;
    wire [15:0] _1196;
    wire [1:0] _1184;
    wire _1735;
    wire [15:0] _1736;
    wire _1733;
    wire [15:0] _1737;
    wire _1732;
    wire [15:0] _1742;
    wire _1731;
    wire [15:0] _1746;
    wire _1730;
    wire [15:0] _1752;
    wire [15:0] _1753;
    wire [15:0] _1754;
    wire [15:0] _1756;
    wire [15:0] _30;
    reg [15:0] x;
    wire _1760;
    wire _1761;
    wire _1762;
    wire [2:0] _1719;
    reg _1771;
    wire _1758;
    wire _1772;
    wire _1778;
    wire [5:0] _1785;
    wire [5:0] _1786;
    wire [5:0] _1787;
    wire [5:0] _1788;
    wire [5:0] _31;
    reg [5:0] pc;
    reg [15:0] _774;
    wire [2:0] _775;
    wire _888;
    wire _890;
    wire _893;
    wire _900;
    wire _906;
    wire _907;
    wire _908;
    wire [3:0] _1790;
    wire _804;
    wire _805;
    wire [3:0] _1793;
    wire _802;
    wire [3:0] _1795;
    wire [3:0] _32;
    reg [3:0] delay_left;
    wire _374;
    wire [15:0] _376;
    wire _1800;
    wire _1798;
    wire _1796;
    wire _1799;
    wire _1801;
    wire _33;
    reg _282;
    wire _375;
    wire _1804;
    wire _1805;
    wire _1807;
    wire _34;
    wire _1627;
    wire [2:0] _1826;
    wire _1617;
    wire _1618;
    wire [6:0] _1613;
    wire [6:0] _387;
    wire _1614;
    wire _263;
    reg _265;
    reg _267;
    wire [22:0] _261;
    wire [22:0] _1808;
    wire [22:0] _1809;
    wire [22:0] _1810;
    wire [22:0] _35;
    reg [22:0] _262;
    wire [23:0] _268;
    wire [7:0] _269;
    wire _259;
    wire [7:0] _1811;
    wire [7:0] _1812;
    wire [7:0] _1813;
    wire [7:0] _36;
    reg [7:0] _384;
    wire _385;
    wire [4:0] _379;
    wire [4:0] _1817;
    wire [4:0] _1814;
    wire _1815;
    wire [4:0] _1818;
    wire [4:0] _1819;
    wire [4:0] _1821;
    wire [4:0] _37;
    reg [4:0] _246;
    wire _380;
    wire _226;
    reg _228;
    reg _230;
    wire _253;
    reg _240;
    wire _251;
    wire vdd;
    wire gnd;
    wire _39;
    wire _41;
    wire [7:0] _43;
    wire _231;
    reg _234;
    reg _236;
    wire _252;
    wire _254;
    wire _381;
    wire _1612;
    wire _1615;
    wire _1619;
    wire [2:0] _1823;
    wire [2:0] _1824;
    wire [2:0] _1827;
    wire [2:0] _44;
    reg [2:0] tx_level;
    wire _1830;
    wire [7:0] _1832;
    assign _121 = pin_out[0:0];
    assign _122 = ~ _121;
    assign _119 = 2'b10;
    assign _120 = _116 == _119;
    assign _123 = _120 & _122;
    assign _117 = 2'b01;
    assign _116 = _49[1:0];
    assign _118 = _116 == _117;
    assign _124 = _118 | _123;
    assign _112 = pin_out[1:1];
    assign _113 = ~ _112;
    assign _111 = _107 == _119;
    assign _114 = _111 & _113;
    assign _107 = _49[3:2];
    assign _109 = _107 == _117;
    assign _115 = _109 | _114;
    assign _103 = pin_out[2:2];
    assign _104 = ~ _103;
    assign _102 = _98 == _119;
    assign _105 = _102 & _104;
    assign _98 = _49[5:4];
    assign _100 = _98 == _117;
    assign _106 = _100 | _105;
    assign _94 = pin_out[3:3];
    assign _95 = ~ _94;
    assign _93 = _89 == _119;
    assign _96 = _93 & _95;
    assign _89 = _49[7:6];
    assign _91 = _89 == _117;
    assign _97 = _91 | _96;
    assign _85 = pin_out[4:4];
    assign _86 = ~ _85;
    assign _84 = _80 == _119;
    assign _87 = _84 & _86;
    assign _80 = _49[9:8];
    assign _82 = _80 == _117;
    assign _88 = _82 | _87;
    assign _76 = pin_out[5:5];
    assign _77 = ~ _76;
    assign _75 = _71 == _119;
    assign _78 = _75 & _77;
    assign _71 = _49[11:10];
    assign _73 = _71 == _117;
    assign _79 = _73 | _78;
    assign _67 = pin_out[6:6];
    assign _68 = ~ _67;
    assign _66 = _62 == _119;
    assign _69 = _66 & _68;
    assign _62 = _49[13:12];
    assign _64 = _62 == _117;
    assign _70 = _64 | _69;
    assign _58 = pin_out[7:7];
    assign _59 = ~ _58;
    assign _54 = _50 == _119;
    assign _60 = _54 & _59;
    assign _50 = _49[15:14];
    assign _52 = _50 == _117;
    assign _61 = _52 | _60;
    assign _125 = { _61,
                    _70,
                    _79,
                    _88,
                    _97,
                    _106,
                    _115,
                    _124 };
    assign _164 = pin_out[0:0];
    assign _161 = _49[1:0];
    assign _163 = _161 == _117;
    assign _165 = _163 & _164;
    assign _159 = pin_out[1:1];
    assign _156 = _49[3:2];
    assign _158 = _156 == _117;
    assign _160 = _158 & _159;
    assign _154 = pin_out[2:2];
    assign _151 = _49[5:4];
    assign _153 = _151 == _117;
    assign _155 = _153 & _154;
    assign _149 = pin_out[3:3];
    assign _146 = _49[7:6];
    assign _148 = _146 == _117;
    assign _150 = _148 & _149;
    assign _144 = pin_out[4:4];
    assign _141 = _49[9:8];
    assign _143 = _141 == _117;
    assign _145 = _143 & _144;
    assign _139 = pin_out[5:5];
    assign _136 = _49[11:10];
    assign _138 = _136 == _117;
    assign _140 = _138 & _139;
    assign _134 = pin_out[6:6];
    assign _131 = _49[13:12];
    assign _133 = _131 == _117;
    assign _135 = _133 & _134;
    assign _129 = pin_out[7:7];
    assign _126 = _49[15:14];
    assign _128 = _126 == _117;
    assign _130 = _128 & _129;
    assign _166 = { _130,
                    _135,
                    _140,
                    _145,
                    _150,
                    _155,
                    _160,
                    _165 };
    assign _256 = 16'b0000000000000000;
    assign _356 = 1'b0;
    assign _355 = _257[14:0];
    assign _357 = { _355,
                    _356 };
    assign _339 = 2'b00;
    assign _346 = { _339,
                    pc,
                    _282,
                    rx_level,
                    gnd,
                    tx_level };
    assign _334 = 2'b11;
    assign _335 = rx_wr == _334;
    assign _336 = _173 & _335;
    always @(posedge _41) begin
        if (_39)
            rx_mem_3 <= _256;
        else
            if (_336)
                rx_mem_3 <= _4;
    end
    assign _329 = rx_wr == _119;
    assign _330 = _173 & _329;
    always @(posedge _41) begin
        if (_39)
            rx_mem_2 <= _256;
        else
            if (_330)
                rx_mem_2 <= _4;
    end
    assign _323 = rx_wr == _117;
    assign _324 = _173 & _323;
    always @(posedge _41) begin
        if (_39)
            rx_mem_1 <= _256;
        else
            if (_324)
                rx_mem_1 <= _4;
    end
    assign _178 = rx_wr + _117;
    assign _179 = _173 ? _178 : rx_wr;
    assign _3 = _179;
    always @(posedge _41) begin
        if (_39)
            rx_wr <= _339;
        else
            rx_wr <= _3;
    end
    assign _317 = rx_wr == _339;
    assign _318 = _173 & _317;
    assign _212 = _210[31:16];
    assign _213 = { _256,
                    _212 };
    assign _208 = _206[31:8];
    assign _207 = 8'b00000000;
    assign _209 = { _207,
                    _208 };
    assign _204 = _202[31:4];
    assign _203 = 4'b0000;
    assign _205 = { _203,
                    _204 };
    assign _200 = _198[31:2];
    assign _201 = { _339,
                    _200 };
    assign _196 = _194[31:1];
    assign _197 = { _356,
                    _196 };
    assign _194 = { _256,
                    isr };
    assign _189 = _184[0:0];
    assign _198 = _189 ? _197 : _194;
    assign _188 = _184[1:1];
    assign _202 = _188 ? _201 : _198;
    assign _187 = _184[2:2];
    assign _206 = _187 ? _205 : _202;
    assign _186 = _184[3:3];
    assign _210 = _186 ? _209 : _206;
    assign _180 = 5'b10000;
    assign _184 = _180 - isr_count;
    assign _185 = _184[4:4];
    assign _214 = _185 ? _213 : _210;
    assign _215 = _214[15:0];
    assign _4 = _215;
    always @(posedge _41) begin
        if (_39)
            rx_mem_0 <= _256;
        else
            if (_318)
                rx_mem_0 <= _4;
    end
    assign _224 = rx_rd + _117;
    assign _225 = _219 ? _224 : rx_rd;
    assign _5 = _225;
    always @(posedge _41) begin
        if (_39)
            rx_rd <= _339;
        else
            rx_rd <= _5;
    end
    always @* begin
        case (rx_rd)
        0:
            _338 <= rx_mem_0;
        1:
            _338 <= rx_mem_1;
        2:
            _338 <= rx_mem_2;
        default:
            _338 <= rx_mem_3;
        endcase
    end
    assign _309 = 10'b0000000000;
    assign _313 = { _309,
                    _312 };
    assign _304 = 11'b00000000000;
    assign _308 = { _304,
                    _307 };
    assign _299 = 13'b0000000000000;
    assign _303 = { _299,
                    _302 };
    assign _298 = { _207,
                    _297 };
    assign _293 = { _207,
                    _292 };
    assign _288 = { _309,
                    _287 };
    assign _279 = 15'b000000000000000;
    assign _283 = { _279,
                    _282 };
    always @* begin
        case (_270)
        0:
            _350 <= _256;
        1:
            _350 <= _256;
        2:
            _350 <= _256;
        3:
            _350 <= _256;
        4:
            _350 <= _256;
        5:
            _350 <= _256;
        6:
            _350 <= _256;
        7:
            _350 <= _256;
        8:
            _350 <= _256;
        9:
            _350 <= _256;
        10:
            _350 <= _256;
        11:
            _350 <= _256;
        12:
            _350 <= _256;
        13:
            _350 <= _256;
        14:
            _350 <= _256;
        15:
            _350 <= _256;
        16:
            _350 <= _256;
        17:
            _350 <= _256;
        18:
            _350 <= _256;
        19:
            _350 <= _256;
        20:
            _350 <= _256;
        21:
            _350 <= _256;
        22:
            _350 <= _256;
        23:
            _350 <= _256;
        24:
            _350 <= _256;
        25:
            _350 <= _256;
        26:
            _350 <= _256;
        27:
            _350 <= _256;
        28:
            _350 <= _256;
        29:
            _350 <= _256;
        30:
            _350 <= _256;
        31:
            _350 <= _256;
        32:
            _350 <= _256;
        33:
            _350 <= _256;
        34:
            _350 <= _256;
        35:
            _350 <= _256;
        36:
            _350 <= _256;
        37:
            _350 <= _256;
        38:
            _350 <= _256;
        39:
            _350 <= _256;
        40:
            _350 <= _256;
        41:
            _350 <= _256;
        42:
            _350 <= _256;
        43:
            _350 <= _256;
        44:
            _350 <= _256;
        45:
            _350 <= _256;
        46:
            _350 <= _256;
        47:
            _350 <= _256;
        48:
            _350 <= _256;
        49:
            _350 <= _256;
        50:
            _350 <= _256;
        51:
            _350 <= _256;
        52:
            _350 <= _256;
        53:
            _350 <= _256;
        54:
            _350 <= _256;
        55:
            _350 <= _256;
        56:
            _350 <= _256;
        57:
            _350 <= _256;
        58:
            _350 <= _256;
        59:
            _350 <= _256;
        60:
            _350 <= _256;
        61:
            _350 <= _256;
        62:
            _350 <= _256;
        63:
            _350 <= _256;
        64:
            _350 <= _283;
        65:
            _350 <= _288;
        66:
            _350 <= _293;
        67:
            _350 <= _298;
        68:
            _350 <= _303;
        69:
            _350 <= _308;
        70:
            _350 <= _313;
        71:
            _350 <= _49;
        72:
            _350 <= _256;
        73:
            _350 <= _338;
        74:
            _350 <= _346;
        75:
            _350 <= _349;
        default:
            _350 <= _256;
        endcase
    end
    assign _276 = ~ _275;
    assign _271 = 7'b1001001;
    assign _272 = _270 == _271;
    assign _277 = _272 & _276;
    assign _352 = _277 ? _256 : _350;
    assign _353 = _259 ? _352 : _257;
    assign _354 = _254 ? _353 : _257;
    assign _247 = 5'b01001;
    assign _248 = _246 < _247;
    assign _249 = ~ _248;
    assign _242 = ~ _230;
    assign _237 = ~ _236;
    assign _241 = _237 & _240;
    assign _243 = _241 & _242;
    assign _250 = _243 & _249;
    assign _358 = _250 ? _357 : _354;
    assign _359 = _230 ? _257 : _358;
    assign _6 = _359;
    always @(posedge _41) begin
        if (_39)
            _257 <= _256;
        else
            _257 <= _6;
    end
    assign _1831 = _257[15:15];
    assign _1829 = 3'b100;
    assign _344 = 3'b000;
    assign _1626 = ~ _898;
    assign _1806 = ~ _898;
    assign _1803 = _775 == _1829;
    assign _1791 = 4'b0001;
    assign _1792 = delay_left - _1791;
    assign _1789 = _774[12:9];
    assign _217 = rx_level == _344;
    assign _218 = ~ _217;
    assign _274 = rx_level == _344;
    assign _275 = ~ _274;
    assign _270 = _269[6:0];
    assign _367 = _270 == _271;
    assign _363 = _269[7:7];
    assign _364 = ~ _363;
    assign _360 = 5'b00111;
    assign _361 = _246 == _360;
    assign _362 = _254 & _361;
    assign _365 = _362 & _364;
    assign _368 = _365 & _367;
    assign _369 = _368 & _275;
    assign _7 = _369;
    assign _219 = _7 & _218;
    assign _788 = { _339,
                    _219 };
    assign _172 = ~ _171;
    assign _782 = ~ _171;
    assign _780 = ~ _779;
    assign _777 = _775 == _1829;
    assign _778 = _375 & _777;
    assign _781 = _778 & _780;
    assign _783 = _781 & _782;
    assign _8 = _783;
    assign _173 = _8 & _172;
    assign _785 = { _339,
                    _173 };
    assign _786 = rx_level + _785;
    assign _789 = _786 - _788;
    assign _9 = _789;
    always @(posedge _41) begin
        if (_39)
            rx_level <= _344;
        else
            rx_level <= _9;
    end
    assign _171 = rx_level == _1829;
    assign _903 = ~ _779;
    assign _902 = _775 == _1829;
    assign _904 = _902 & _903;
    assign _905 = _904 & _171;
    assign _898 = tx_level == _344;
    assign _895 = _775 == _1829;
    assign _896 = _895 & _779;
    assign _899 = _896 & _898;
    assign _892 = ~ _891;
    assign _889 = ~ _860;
    assign _887 = 3'b001;
    assign _770 = 6'b111111;
    assign _771 = _391 == _770;
    assign _772 = _390 & _771;
    always @(posedge _41) begin
        if (_39)
            prog_63 <= _256;
        else
            if (_772)
                prog_63 <= _376;
    end
    assign _764 = 6'b111110;
    assign _765 = _391 == _764;
    assign _766 = _390 & _765;
    always @(posedge _41) begin
        if (_39)
            prog_62 <= _256;
        else
            if (_766)
                prog_62 <= _376;
    end
    assign _758 = 6'b111101;
    assign _759 = _391 == _758;
    assign _760 = _390 & _759;
    always @(posedge _41) begin
        if (_39)
            prog_61 <= _256;
        else
            if (_760)
                prog_61 <= _376;
    end
    assign _752 = 6'b111100;
    assign _753 = _391 == _752;
    assign _754 = _390 & _753;
    always @(posedge _41) begin
        if (_39)
            prog_60 <= _256;
        else
            if (_754)
                prog_60 <= _376;
    end
    assign _746 = 6'b111011;
    assign _747 = _391 == _746;
    assign _748 = _390 & _747;
    always @(posedge _41) begin
        if (_39)
            prog_59 <= _256;
        else
            if (_748)
                prog_59 <= _376;
    end
    assign _740 = 6'b111010;
    assign _741 = _391 == _740;
    assign _742 = _390 & _741;
    always @(posedge _41) begin
        if (_39)
            prog_58 <= _256;
        else
            if (_742)
                prog_58 <= _376;
    end
    assign _734 = 6'b111001;
    assign _735 = _391 == _734;
    assign _736 = _390 & _735;
    always @(posedge _41) begin
        if (_39)
            prog_57 <= _256;
        else
            if (_736)
                prog_57 <= _376;
    end
    assign _728 = 6'b111000;
    assign _729 = _391 == _728;
    assign _730 = _390 & _729;
    always @(posedge _41) begin
        if (_39)
            prog_56 <= _256;
        else
            if (_730)
                prog_56 <= _376;
    end
    assign _722 = 6'b110111;
    assign _723 = _391 == _722;
    assign _724 = _390 & _723;
    always @(posedge _41) begin
        if (_39)
            prog_55 <= _256;
        else
            if (_724)
                prog_55 <= _376;
    end
    assign _716 = 6'b110110;
    assign _717 = _391 == _716;
    assign _718 = _390 & _717;
    always @(posedge _41) begin
        if (_39)
            prog_54 <= _256;
        else
            if (_718)
                prog_54 <= _376;
    end
    assign _710 = 6'b110101;
    assign _711 = _391 == _710;
    assign _712 = _390 & _711;
    always @(posedge _41) begin
        if (_39)
            prog_53 <= _256;
        else
            if (_712)
                prog_53 <= _376;
    end
    assign _704 = 6'b110100;
    assign _705 = _391 == _704;
    assign _706 = _390 & _705;
    always @(posedge _41) begin
        if (_39)
            prog_52 <= _256;
        else
            if (_706)
                prog_52 <= _376;
    end
    assign _698 = 6'b110011;
    assign _699 = _391 == _698;
    assign _700 = _390 & _699;
    always @(posedge _41) begin
        if (_39)
            prog_51 <= _256;
        else
            if (_700)
                prog_51 <= _376;
    end
    assign _692 = 6'b110010;
    assign _693 = _391 == _692;
    assign _694 = _390 & _693;
    always @(posedge _41) begin
        if (_39)
            prog_50 <= _256;
        else
            if (_694)
                prog_50 <= _376;
    end
    assign _686 = 6'b110001;
    assign _687 = _391 == _686;
    assign _688 = _390 & _687;
    always @(posedge _41) begin
        if (_39)
            prog_49 <= _256;
        else
            if (_688)
                prog_49 <= _376;
    end
    assign _680 = 6'b110000;
    assign _681 = _391 == _680;
    assign _682 = _390 & _681;
    always @(posedge _41) begin
        if (_39)
            prog_48 <= _256;
        else
            if (_682)
                prog_48 <= _376;
    end
    assign _674 = 6'b101111;
    assign _675 = _391 == _674;
    assign _676 = _390 & _675;
    always @(posedge _41) begin
        if (_39)
            prog_47 <= _256;
        else
            if (_676)
                prog_47 <= _376;
    end
    assign _668 = 6'b101110;
    assign _669 = _391 == _668;
    assign _670 = _390 & _669;
    always @(posedge _41) begin
        if (_39)
            prog_46 <= _256;
        else
            if (_670)
                prog_46 <= _376;
    end
    assign _662 = 6'b101101;
    assign _663 = _391 == _662;
    assign _664 = _390 & _663;
    always @(posedge _41) begin
        if (_39)
            prog_45 <= _256;
        else
            if (_664)
                prog_45 <= _376;
    end
    assign _656 = 6'b101100;
    assign _657 = _391 == _656;
    assign _658 = _390 & _657;
    always @(posedge _41) begin
        if (_39)
            prog_44 <= _256;
        else
            if (_658)
                prog_44 <= _376;
    end
    assign _650 = 6'b101011;
    assign _651 = _391 == _650;
    assign _652 = _390 & _651;
    always @(posedge _41) begin
        if (_39)
            prog_43 <= _256;
        else
            if (_652)
                prog_43 <= _376;
    end
    assign _644 = 6'b101010;
    assign _645 = _391 == _644;
    assign _646 = _390 & _645;
    always @(posedge _41) begin
        if (_39)
            prog_42 <= _256;
        else
            if (_646)
                prog_42 <= _376;
    end
    assign _638 = 6'b101001;
    assign _639 = _391 == _638;
    assign _640 = _390 & _639;
    always @(posedge _41) begin
        if (_39)
            prog_41 <= _256;
        else
            if (_640)
                prog_41 <= _376;
    end
    assign _632 = 6'b101000;
    assign _633 = _391 == _632;
    assign _634 = _390 & _633;
    always @(posedge _41) begin
        if (_39)
            prog_40 <= _256;
        else
            if (_634)
                prog_40 <= _376;
    end
    assign _626 = 6'b100111;
    assign _627 = _391 == _626;
    assign _628 = _390 & _627;
    always @(posedge _41) begin
        if (_39)
            prog_39 <= _256;
        else
            if (_628)
                prog_39 <= _376;
    end
    assign _620 = 6'b100110;
    assign _621 = _391 == _620;
    assign _622 = _390 & _621;
    always @(posedge _41) begin
        if (_39)
            prog_38 <= _256;
        else
            if (_622)
                prog_38 <= _376;
    end
    assign _614 = 6'b100101;
    assign _615 = _391 == _614;
    assign _616 = _390 & _615;
    always @(posedge _41) begin
        if (_39)
            prog_37 <= _256;
        else
            if (_616)
                prog_37 <= _376;
    end
    assign _608 = 6'b100100;
    assign _609 = _391 == _608;
    assign _610 = _390 & _609;
    always @(posedge _41) begin
        if (_39)
            prog_36 <= _256;
        else
            if (_610)
                prog_36 <= _376;
    end
    assign _602 = 6'b100011;
    assign _603 = _391 == _602;
    assign _604 = _390 & _603;
    always @(posedge _41) begin
        if (_39)
            prog_35 <= _256;
        else
            if (_604)
                prog_35 <= _376;
    end
    assign _596 = 6'b100010;
    assign _597 = _391 == _596;
    assign _598 = _390 & _597;
    always @(posedge _41) begin
        if (_39)
            prog_34 <= _256;
        else
            if (_598)
                prog_34 <= _376;
    end
    assign _590 = 6'b100001;
    assign _591 = _391 == _590;
    assign _592 = _390 & _591;
    always @(posedge _41) begin
        if (_39)
            prog_33 <= _256;
        else
            if (_592)
                prog_33 <= _376;
    end
    assign _584 = 6'b100000;
    assign _585 = _391 == _584;
    assign _586 = _390 & _585;
    always @(posedge _41) begin
        if (_39)
            prog_32 <= _256;
        else
            if (_586)
                prog_32 <= _376;
    end
    assign _578 = 6'b011111;
    assign _579 = _391 == _578;
    assign _580 = _390 & _579;
    always @(posedge _41) begin
        if (_39)
            prog_31 <= _256;
        else
            if (_580)
                prog_31 <= _376;
    end
    assign _572 = 6'b011110;
    assign _573 = _391 == _572;
    assign _574 = _390 & _573;
    always @(posedge _41) begin
        if (_39)
            prog_30 <= _256;
        else
            if (_574)
                prog_30 <= _376;
    end
    assign _566 = 6'b011101;
    assign _567 = _391 == _566;
    assign _568 = _390 & _567;
    always @(posedge _41) begin
        if (_39)
            prog_29 <= _256;
        else
            if (_568)
                prog_29 <= _376;
    end
    assign _560 = 6'b011100;
    assign _561 = _391 == _560;
    assign _562 = _390 & _561;
    always @(posedge _41) begin
        if (_39)
            prog_28 <= _256;
        else
            if (_562)
                prog_28 <= _376;
    end
    assign _554 = 6'b011011;
    assign _555 = _391 == _554;
    assign _556 = _390 & _555;
    always @(posedge _41) begin
        if (_39)
            prog_27 <= _256;
        else
            if (_556)
                prog_27 <= _376;
    end
    assign _548 = 6'b011010;
    assign _549 = _391 == _548;
    assign _550 = _390 & _549;
    always @(posedge _41) begin
        if (_39)
            prog_26 <= _256;
        else
            if (_550)
                prog_26 <= _376;
    end
    assign _542 = 6'b011001;
    assign _543 = _391 == _542;
    assign _544 = _390 & _543;
    always @(posedge _41) begin
        if (_39)
            prog_25 <= _256;
        else
            if (_544)
                prog_25 <= _376;
    end
    assign _536 = 6'b011000;
    assign _537 = _391 == _536;
    assign _538 = _390 & _537;
    always @(posedge _41) begin
        if (_39)
            prog_24 <= _256;
        else
            if (_538)
                prog_24 <= _376;
    end
    assign _530 = 6'b010111;
    assign _531 = _391 == _530;
    assign _532 = _390 & _531;
    always @(posedge _41) begin
        if (_39)
            prog_23 <= _256;
        else
            if (_532)
                prog_23 <= _376;
    end
    assign _524 = 6'b010110;
    assign _525 = _391 == _524;
    assign _526 = _390 & _525;
    always @(posedge _41) begin
        if (_39)
            prog_22 <= _256;
        else
            if (_526)
                prog_22 <= _376;
    end
    assign _518 = 6'b010101;
    assign _519 = _391 == _518;
    assign _520 = _390 & _519;
    always @(posedge _41) begin
        if (_39)
            prog_21 <= _256;
        else
            if (_520)
                prog_21 <= _376;
    end
    assign _512 = 6'b010100;
    assign _513 = _391 == _512;
    assign _514 = _390 & _513;
    always @(posedge _41) begin
        if (_39)
            prog_20 <= _256;
        else
            if (_514)
                prog_20 <= _376;
    end
    assign _506 = 6'b010011;
    assign _507 = _391 == _506;
    assign _508 = _390 & _507;
    always @(posedge _41) begin
        if (_39)
            prog_19 <= _256;
        else
            if (_508)
                prog_19 <= _376;
    end
    assign _500 = 6'b010010;
    assign _501 = _391 == _500;
    assign _502 = _390 & _501;
    always @(posedge _41) begin
        if (_39)
            prog_18 <= _256;
        else
            if (_502)
                prog_18 <= _376;
    end
    assign _494 = 6'b010001;
    assign _495 = _391 == _494;
    assign _496 = _390 & _495;
    always @(posedge _41) begin
        if (_39)
            prog_17 <= _256;
        else
            if (_496)
                prog_17 <= _376;
    end
    assign _488 = 6'b010000;
    assign _489 = _391 == _488;
    assign _490 = _390 & _489;
    always @(posedge _41) begin
        if (_39)
            prog_16 <= _256;
        else
            if (_490)
                prog_16 <= _376;
    end
    assign _482 = 6'b001111;
    assign _483 = _391 == _482;
    assign _484 = _390 & _483;
    always @(posedge _41) begin
        if (_39)
            prog_15 <= _256;
        else
            if (_484)
                prog_15 <= _376;
    end
    assign _476 = 6'b001110;
    assign _477 = _391 == _476;
    assign _478 = _390 & _477;
    always @(posedge _41) begin
        if (_39)
            prog_14 <= _256;
        else
            if (_478)
                prog_14 <= _376;
    end
    assign _470 = 6'b001101;
    assign _471 = _391 == _470;
    assign _472 = _390 & _471;
    always @(posedge _41) begin
        if (_39)
            prog_13 <= _256;
        else
            if (_472)
                prog_13 <= _376;
    end
    assign _464 = 6'b001100;
    assign _465 = _391 == _464;
    assign _466 = _390 & _465;
    always @(posedge _41) begin
        if (_39)
            prog_12 <= _256;
        else
            if (_466)
                prog_12 <= _376;
    end
    assign _458 = 6'b001011;
    assign _459 = _391 == _458;
    assign _460 = _390 & _459;
    always @(posedge _41) begin
        if (_39)
            prog_11 <= _256;
        else
            if (_460)
                prog_11 <= _376;
    end
    assign _452 = 6'b001010;
    assign _453 = _391 == _452;
    assign _454 = _390 & _453;
    always @(posedge _41) begin
        if (_39)
            prog_10 <= _256;
        else
            if (_454)
                prog_10 <= _376;
    end
    assign _446 = 6'b001001;
    assign _447 = _391 == _446;
    assign _448 = _390 & _447;
    always @(posedge _41) begin
        if (_39)
            prog_9 <= _256;
        else
            if (_448)
                prog_9 <= _376;
    end
    assign _440 = 6'b001000;
    assign _441 = _391 == _440;
    assign _442 = _390 & _441;
    always @(posedge _41) begin
        if (_39)
            prog_8 <= _256;
        else
            if (_442)
                prog_8 <= _376;
    end
    assign _434 = 6'b000111;
    assign _435 = _391 == _434;
    assign _436 = _390 & _435;
    always @(posedge _41) begin
        if (_39)
            prog_7 <= _256;
        else
            if (_436)
                prog_7 <= _376;
    end
    assign _428 = 6'b000110;
    assign _429 = _391 == _428;
    assign _430 = _390 & _429;
    always @(posedge _41) begin
        if (_39)
            prog_6 <= _256;
        else
            if (_430)
                prog_6 <= _376;
    end
    assign _422 = 6'b000101;
    assign _423 = _391 == _422;
    assign _424 = _390 & _423;
    always @(posedge _41) begin
        if (_39)
            prog_5 <= _256;
        else
            if (_424)
                prog_5 <= _376;
    end
    assign _416 = 6'b000100;
    assign _417 = _391 == _416;
    assign _418 = _390 & _417;
    always @(posedge _41) begin
        if (_39)
            prog_4 <= _256;
        else
            if (_418)
                prog_4 <= _376;
    end
    assign _410 = 6'b000011;
    assign _411 = _391 == _410;
    assign _412 = _390 & _411;
    always @(posedge _41) begin
        if (_39)
            prog_3 <= _256;
        else
            if (_412)
                prog_3 <= _376;
    end
    assign _404 = 6'b000010;
    assign _405 = _391 == _404;
    assign _406 = _390 & _405;
    always @(posedge _41) begin
        if (_39)
            prog_2 <= _256;
        else
            if (_406)
                prog_2 <= _376;
    end
    assign _398 = 6'b000001;
    assign _399 = _391 == _398;
    assign _400 = _390 & _399;
    always @(posedge _41) begin
        if (_39)
            prog_1 <= _256;
        else
            if (_400)
                prog_1 <= _376;
    end
    assign _392 = 6'b000000;
    assign _391 = _387[5:0];
    assign _393 = _391 == _392;
    assign _388 = 7'b1000000;
    assign _389 = _387 < _388;
    assign _386 = _381 & _385;
    assign _390 = _386 & _389;
    assign _394 = _390 & _393;
    always @(posedge _41) begin
        if (_39)
            prog_0 <= _256;
        else
            if (_394)
                prog_0 <= _376;
    end
    assign _794 = _376[5:0];
    assign _791 = 7'b1000001;
    assign _792 = _387 == _791;
    assign _790 = _381 & _385;
    assign _793 = _790 & _792;
    assign _795 = _793 ? _794 : _287;
    assign _10 = _795;
    always @(posedge _41) begin
        if (_39)
            _287 <= _392;
        else
            _287 <= _10;
    end
    assign _1783 = _774[5:0];
    assign _800 = _376[5:0];
    assign _797 = 7'b1000110;
    assign _798 = _387 == _797;
    assign _796 = _381 & _385;
    assign _799 = _796 & _798;
    assign _801 = _799 ? _800 : _312;
    assign _11 = _801;
    always @(posedge _41) begin
        if (_39)
            _312 <= _392;
        else
            _312 <= _11;
    end
    assign _1782 = _775 == _344;
    assign _1784 = _1782 ? _1783 : _312;
    assign _1780 = pc + _398;
    assign _876 = 16'b0000000000000001;
    assign _877 = _871 - _876;
    assign _878 = _875 ? _877 : wait_count;
    assign _879 = _805 ? wait_count : _878;
    assign _881 = _802 ? _256 : _879;
    assign _12 = _881;
    always @(posedge _41) begin
        if (_39)
            wait_count <= _256;
        else
            wait_count <= _12;
    end
    assign _883 = 7'b1001011;
    assign _884 = _387 == _883;
    assign _882 = _381 & _385;
    assign _885 = _882 & _884;
    assign _886 = _885 ? _376 : _349;
    assign _13 = _886;
    always @(posedge _41) begin
        if (_39)
            _349 <= _256;
        else
            _349 <= _13;
    end
    assign _909 = 1'b1;
    assign _874 = ~ _873;
    assign _861 = ~ _860;
    assign _807 = _775 == _887;
    assign _862 = _807 & _861;
    assign _864 = _862 & _863;
    assign _875 = _864 & _874;
    assign _910 = _875 ? _909 : waiting;
    assign _912 = _908 ? _356 : _910;
    assign _913 = _805 ? waiting : _912;
    assign _915 = _802 ? _356 : _913;
    assign _14 = _915;
    always @(posedge _41) begin
        if (_39)
            waiting <= _356;
        else
            waiting <= _14;
    end
    assign _871 = waiting ? wait_count : _349;
    assign _873 = _871 == _256;
    assign _863 = _774[4:4];
    assign _891 = _863 & _873;
    assign _859 = _774[8:8];
    assign _857 = _849[7:7];
    assign _856 = _849[6:6];
    assign _855 = _849[5:5];
    assign _854 = _849[4:4];
    assign _853 = _849[3:3];
    assign _852 = _849[2:2];
    assign _851 = _849[1:1];
    assign _850 = _849[0:0];
    assign _808 = _774[7:5];
    always @* begin
        case (_808)
        0:
            _858 <= _850;
        1:
            _858 <= _851;
        2:
            _858 <= _852;
        3:
            _858 <= _853;
        4:
            _858 <= _854;
        5:
            _858 <= _855;
        6:
            _858 <= _856;
        default:
            _858 <= _857;
        endcase
    end
    assign _860 = _858 == _859;
    assign _1775 = ~ _860;
    assign _1774 = _775 == _887;
    assign _1776 = _1774 & _1775;
    assign _1777 = _1776 & _891;
    assign _182 = 5'b00000;
    assign _949 = _947[4:0];
    assign _946 = { gnd,
                    _945 };
    assign _939 = { gnd,
                    isr_count };
    assign _947 = _939 + _946;
    assign _948 = _488 < _947;
    assign _951 = _948 ? _180 : _949;
    assign _936 = _779 ? isr_count : _182;
    assign _930 = _922 == _1083;
    assign _932 = _930 ? _182 : isr_count;
    assign _933 = _928 ? _932 : isr_count;
    assign _921 = _775 == _1055;
    assign _934 = _921 ? _933 : isr_count;
    assign _919 = _775 == _1829;
    assign _937 = _919 ? _936 : _934;
    assign _917 = _775 == _1747;
    assign _952 = _917 ? _951 : _937;
    assign _953 = _908 ? _952 : isr_count;
    assign _954 = _805 ? isr_count : _953;
    assign _956 = _802 ? _182 : _954;
    assign _15 = _956;
    always @(posedge _41) begin
        if (_39)
            isr_count <= _182;
        else
            isr_count <= _15;
    end
    assign _1770 = isr_count < _307;
    assign _306 = 5'b01000;
    assign _961 = _376[4:0];
    assign _958 = 7'b1000101;
    assign _959 = _387 == _958;
    assign _957 = _381 & _385;
    assign _960 = _957 & _959;
    assign _962 = _960 ? _961 : _307;
    assign _16 = _962;
    always @(posedge _41) begin
        if (_39)
            _307 <= _306;
        else
            _307 <= _16;
    end
    assign _984 = _982[4:0];
    assign _981 = { gnd,
                    _945 };
    assign _980 = { gnd,
                    osr_count };
    assign _982 = _980 + _981;
    assign _983 = _488 < _982;
    assign _986 = _983 ? _180 : _984;
    assign _977 = _779 ? _182 : osr_count;
    assign _971 = _922 == _1829;
    assign _973 = _971 ? _182 : osr_count;
    assign _974 = _928 ? _973 : osr_count;
    assign _969 = _775 == _1055;
    assign _975 = _969 ? _974 : osr_count;
    assign _968 = _775 == _1829;
    assign _978 = _968 ? _977 : _975;
    assign _967 = _775 == _1083;
    assign _987 = _967 ? _986 : _978;
    assign _988 = _908 ? _987 : osr_count;
    assign _989 = _805 ? osr_count : _988;
    assign _990 = _802 ? _307 : _989;
    assign _17 = _990;
    always @(posedge _41) begin
        if (_39)
            osr_count <= _182;
        else
            osr_count <= _17;
    end
    assign _1769 = osr_count < _307;
    assign _1767 = x == y;
    assign _1768 = ~ _1767;
    assign _1764 = y == _256;
    assign _1765 = ~ _1764;
    assign _1766 = ~ _1765;
    assign _1750 = x - _876;
    assign _1747 = 3'b010;
    assign _1748 = _1719 == _1747;
    assign _1751 = _1748 ? _1750 : x;
    assign _1744 = _1443 == _117;
    assign _1745 = _1744 ? _1478 : x;
    assign _1159 = _1157[31:16];
    assign _1160 = { _256,
                     _1159 };
    assign _1155 = _1153[31:8];
    assign _1156 = { _207,
                     _1155 };
    assign _1151 = _1149[31:4];
    assign _1152 = { _203,
                     _1151 };
    assign _1147 = _1145[31:2];
    assign _1148 = { _339,
                     _1147 };
    assign _1143 = _1141[31:1];
    assign _1144 = { _356,
                     _1143 };
    assign _1135 = _182 < _945;
    assign _1132 = _849[7:7];
    assign _1131 = _849[6:6];
    assign _1130 = _849[5:5];
    assign _1129 = _849[4:4];
    assign _1128 = _849[3:3];
    assign _1127 = _849[2:2];
    assign _1126 = _849[1:1];
    assign _1125 = _849[0:0];
    always @* begin
        case (_302)
        0:
            _1133 <= _1125;
        1:
            _1133 <= _1126;
        2:
            _1133 <= _1127;
        3:
            _1133 <= _1128;
        4:
            _1133 <= _1129;
        5:
            _1133 <= _1130;
        6:
            _1133 <= _1131;
        default:
            _1133 <= _1132;
        endcase
    end
    assign _1136 = _1133 & _1135;
    assign _1122 = 5'b00001;
    assign _1123 = _1122 < _945;
    assign _1120 = _849[7:7];
    assign _1119 = _849[6:6];
    assign _1118 = _849[5:5];
    assign _1117 = _849[4:4];
    assign _1116 = _849[3:3];
    assign _1115 = _849[2:2];
    assign _1114 = _849[1:1];
    assign _1113 = _849[0:0];
    assign _1112 = _302 + _887;
    always @* begin
        case (_1112)
        0:
            _1121 <= _1113;
        1:
            _1121 <= _1114;
        2:
            _1121 <= _1115;
        3:
            _1121 <= _1116;
        4:
            _1121 <= _1117;
        5:
            _1121 <= _1118;
        6:
            _1121 <= _1119;
        default:
            _1121 <= _1120;
        endcase
    end
    assign _1124 = _1121 & _1123;
    assign _1108 = 5'b00010;
    assign _1109 = _1108 < _945;
    assign _1106 = _849[7:7];
    assign _1105 = _849[6:6];
    assign _1104 = _849[5:5];
    assign _1103 = _849[4:4];
    assign _1102 = _849[3:3];
    assign _1101 = _849[2:2];
    assign _1100 = _849[1:1];
    assign _1099 = _849[0:0];
    assign _1098 = _302 + _1747;
    always @* begin
        case (_1098)
        0:
            _1107 <= _1099;
        1:
            _1107 <= _1100;
        2:
            _1107 <= _1101;
        3:
            _1107 <= _1102;
        4:
            _1107 <= _1103;
        5:
            _1107 <= _1104;
        6:
            _1107 <= _1105;
        default:
            _1107 <= _1106;
        endcase
    end
    assign _1110 = _1107 & _1109;
    assign _1094 = 5'b00011;
    assign _1095 = _1094 < _945;
    assign _1092 = _849[7:7];
    assign _1091 = _849[6:6];
    assign _1090 = _849[5:5];
    assign _1089 = _849[4:4];
    assign _1088 = _849[3:3];
    assign _1087 = _849[2:2];
    assign _1086 = _849[1:1];
    assign _1085 = _849[0:0];
    assign _1083 = 3'b011;
    assign _1084 = _302 + _1083;
    always @* begin
        case (_1084)
        0:
            _1093 <= _1085;
        1:
            _1093 <= _1086;
        2:
            _1093 <= _1087;
        3:
            _1093 <= _1088;
        4:
            _1093 <= _1089;
        5:
            _1093 <= _1090;
        6:
            _1093 <= _1091;
        default:
            _1093 <= _1092;
        endcase
    end
    assign _1096 = _1093 & _1095;
    assign _1080 = 5'b00100;
    assign _1081 = _1080 < _945;
    assign _1078 = _849[7:7];
    assign _1077 = _849[6:6];
    assign _1076 = _849[5:5];
    assign _1075 = _849[4:4];
    assign _1074 = _849[3:3];
    assign _1073 = _849[2:2];
    assign _1072 = _849[1:1];
    assign _1071 = _849[0:0];
    assign _1070 = _302 + _1829;
    always @* begin
        case (_1070)
        0:
            _1079 <= _1071;
        1:
            _1079 <= _1072;
        2:
            _1079 <= _1073;
        3:
            _1079 <= _1074;
        4:
            _1079 <= _1075;
        5:
            _1079 <= _1076;
        6:
            _1079 <= _1077;
        default:
            _1079 <= _1078;
        endcase
    end
    assign _1082 = _1079 & _1081;
    assign _1066 = 5'b00101;
    assign _1067 = _1066 < _945;
    assign _1064 = _849[7:7];
    assign _1063 = _849[6:6];
    assign _1062 = _849[5:5];
    assign _1061 = _849[4:4];
    assign _1060 = _849[3:3];
    assign _1059 = _849[2:2];
    assign _1058 = _849[1:1];
    assign _1057 = _849[0:0];
    assign _1055 = 3'b101;
    assign _1056 = _302 + _1055;
    always @* begin
        case (_1056)
        0:
            _1065 <= _1057;
        1:
            _1065 <= _1058;
        2:
            _1065 <= _1059;
        3:
            _1065 <= _1060;
        4:
            _1065 <= _1061;
        5:
            _1065 <= _1062;
        6:
            _1065 <= _1063;
        default:
            _1065 <= _1064;
        endcase
    end
    assign _1068 = _1065 & _1067;
    assign _1052 = 5'b00110;
    assign _1053 = _1052 < _945;
    assign _1050 = _849[7:7];
    assign _1049 = _849[6:6];
    assign _1048 = _849[5:5];
    assign _1047 = _849[4:4];
    assign _1046 = _849[3:3];
    assign _1045 = _849[2:2];
    assign _1044 = _849[1:1];
    assign _1043 = _849[0:0];
    assign _1041 = 3'b110;
    assign _1042 = _302 + _1041;
    always @* begin
        case (_1042)
        0:
            _1051 <= _1043;
        1:
            _1051 <= _1044;
        2:
            _1051 <= _1045;
        3:
            _1051 <= _1046;
        4:
            _1051 <= _1047;
        5:
            _1051 <= _1048;
        6:
            _1051 <= _1049;
        default:
            _1051 <= _1050;
        endcase
    end
    assign _1054 = _1051 & _1053;
    assign _1039 = _360 < _945;
    assign _1036 = _849[7:7];
    assign _1035 = _849[6:6];
    assign _1034 = _849[5:5];
    assign _1033 = _849[4:4];
    assign _1032 = _849[3:3];
    assign _1031 = _849[2:2];
    assign _1030 = _849[1:1];
    assign _1029 = _849[0:0];
    assign _1027 = 3'b111;
    assign _995 = _376[2:0];
    assign _992 = 7'b1000100;
    assign _993 = _387 == _992;
    assign _991 = _381 & _385;
    assign _994 = _991 & _993;
    assign _996 = _994 ? _995 : _302;
    assign _18 = _996;
    always @(posedge _41) begin
        if (_39)
            _302 <= _344;
        else
            _302 <= _18;
    end
    assign _1028 = _302 + _1027;
    always @* begin
        case (_1028)
        0:
            _1037 <= _1029;
        1:
            _1037 <= _1030;
        2:
            _1037 <= _1031;
        3:
            _1037 <= _1032;
        4:
            _1037 <= _1033;
        5:
            _1037 <= _1034;
        6:
            _1037 <= _1035;
        default:
            _1037 <= _1036;
        endcase
    end
    assign _1040 = _1037 & _1039;
    assign _1137 = { _1040,
                     _1054,
                     _1068,
                     _1082,
                     _1096,
                     _1110,
                     _1124,
                     _1136 };
    assign _1138 = { _207,
                     _1137 };
    assign _1025 = _774[8:7];
    always @* begin
        case (_1025)
        0:
            _1140 <= _1138;
        1:
            _1140 <= x;
        2:
            _1140 <= y;
        default:
            _1140 <= _256;
        endcase
    end
    assign _1141 = { _1140,
                     isr };
    assign _1024 = _945[0:0];
    assign _1145 = _1024 ? _1144 : _1141;
    assign _1023 = _945[1:1];
    assign _1149 = _1023 ? _1148 : _1145;
    assign _1022 = _945[2:2];
    assign _1153 = _1022 ? _1152 : _1149;
    assign _1021 = _945[3:3];
    assign _1157 = _1021 ? _1156 : _1153;
    assign _1020 = _945[4:4];
    assign _1161 = _1020 ? _1160 : _1157;
    assign _1162 = _1161[15:0];
    assign _1018 = _779 ? isr : _256;
    assign _1000 = _922 == _1083;
    assign _1014 = _1000 ? _1013 : isr;
    assign _1015 = _928 ? _1014 : isr;
    assign _999 = _775 == _1055;
    assign _1016 = _999 ? _1015 : isr;
    assign _998 = _775 == _1829;
    assign _1019 = _998 ? _1018 : _1016;
    assign _997 = _775 == _1747;
    assign _1163 = _997 ? _1162 : _1019;
    assign _1164 = _908 ? _1163 : isr;
    assign _1165 = _805 ? isr : _1164;
    assign _1167 = _802 ? _256 : _1165;
    assign _19 = _1167;
    always @(posedge _41) begin
        if (_39)
            isr <= _256;
        else
            isr <= _19;
    end
    assign _847 = _846 & _845;
    assign _846 = pin_out[0:0];
    assign _845 = _24[0:0];
    assign _844 = _49[1:0];
    always @* begin
        case (_844)
        0:
            _848 <= _845;
        1:
            _848 <= _846;
        2:
            _848 <= _847;
        default:
            _848 <= _845;
        endcase
    end
    assign _842 = _841 & _840;
    assign _841 = pin_out[1:1];
    assign _840 = _24[1:1];
    assign _839 = _49[3:2];
    always @* begin
        case (_839)
        0:
            _843 <= _840;
        1:
            _843 <= _841;
        2:
            _843 <= _842;
        default:
            _843 <= _840;
        endcase
    end
    assign _837 = _836 & _835;
    assign _836 = pin_out[2:2];
    assign _835 = _24[2:2];
    assign _834 = _49[5:4];
    always @* begin
        case (_834)
        0:
            _838 <= _835;
        1:
            _838 <= _836;
        2:
            _838 <= _837;
        default:
            _838 <= _835;
        endcase
    end
    assign _832 = _831 & _830;
    assign _831 = pin_out[3:3];
    assign _830 = _24[3:3];
    assign _829 = _49[7:6];
    always @* begin
        case (_829)
        0:
            _833 <= _830;
        1:
            _833 <= _831;
        2:
            _833 <= _832;
        default:
            _833 <= _830;
        endcase
    end
    assign _827 = _826 & _825;
    assign _826 = pin_out[4:4];
    assign _825 = _24[4:4];
    assign _824 = _49[9:8];
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
    assign _822 = _821 & _820;
    assign _821 = pin_out[5:5];
    assign _820 = _24[5:5];
    assign _819 = _49[11:10];
    always @* begin
        case (_819)
        0:
            _823 <= _820;
        1:
            _823 <= _821;
        2:
            _823 <= _822;
        default:
            _823 <= _820;
        endcase
    end
    assign _817 = _816 & _815;
    assign _816 = pin_out[6:6];
    assign _815 = _24[6:6];
    assign _814 = _49[13:12];
    always @* begin
        case (_814)
        0:
            _818 <= _815;
        1:
            _818 <= _816;
        2:
            _818 <= _817;
        default:
            _818 <= _815;
        endcase
    end
    assign _812 = _811 & _810;
    assign _56 = 8'b11111111;
    assign _1598 = _1478[7:7];
    assign _1597 = _1478[6:6];
    assign _1596 = _1478[5:5];
    assign _1595 = _1478[4:4];
    assign _1594 = _1478[3:3];
    assign _1593 = _1478[2:2];
    assign _1592 = _1478[1:1];
    assign _1591 = _1478[0:0];
    always @* begin
        case (_1587)
        0:
            _1599 <= _1591;
        1:
            _1599 <= _1592;
        2:
            _1599 <= _1593;
        3:
            _1599 <= _1594;
        4:
            _1599 <= _1595;
        5:
            _1599 <= _1596;
        6:
            _1599 <= _1597;
        default:
            _1599 <= _1598;
        endcase
    end
    assign _1590 = pin_out[0:0];
    assign _1587 = _344 - _1318;
    assign _1588 = { _339,
                     _1587 };
    assign _1589 = _1588 < _945;
    assign _1600 = _1589 ? _1599 : _1590;
    assign _1582 = _1478[7:7];
    assign _1581 = _1478[6:6];
    assign _1580 = _1478[5:5];
    assign _1579 = _1478[4:4];
    assign _1578 = _1478[3:3];
    assign _1577 = _1478[2:2];
    assign _1576 = _1478[1:1];
    assign _1575 = _1478[0:0];
    always @* begin
        case (_1571)
        0:
            _1583 <= _1575;
        1:
            _1583 <= _1576;
        2:
            _1583 <= _1577;
        3:
            _1583 <= _1578;
        4:
            _1583 <= _1579;
        5:
            _1583 <= _1580;
        6:
            _1583 <= _1581;
        default:
            _1583 <= _1582;
        endcase
    end
    assign _1574 = pin_out[1:1];
    assign _1571 = _887 - _1318;
    assign _1572 = { _339,
                     _1571 };
    assign _1573 = _1572 < _945;
    assign _1584 = _1573 ? _1583 : _1574;
    assign _1566 = _1478[7:7];
    assign _1565 = _1478[6:6];
    assign _1564 = _1478[5:5];
    assign _1563 = _1478[4:4];
    assign _1562 = _1478[3:3];
    assign _1561 = _1478[2:2];
    assign _1560 = _1478[1:1];
    assign _1559 = _1478[0:0];
    always @* begin
        case (_1555)
        0:
            _1567 <= _1559;
        1:
            _1567 <= _1560;
        2:
            _1567 <= _1561;
        3:
            _1567 <= _1562;
        4:
            _1567 <= _1563;
        5:
            _1567 <= _1564;
        6:
            _1567 <= _1565;
        default:
            _1567 <= _1566;
        endcase
    end
    assign _1558 = pin_out[2:2];
    assign _1555 = _1747 - _1318;
    assign _1556 = { _339,
                     _1555 };
    assign _1557 = _1556 < _945;
    assign _1568 = _1557 ? _1567 : _1558;
    assign _1550 = _1478[7:7];
    assign _1549 = _1478[6:6];
    assign _1548 = _1478[5:5];
    assign _1547 = _1478[4:4];
    assign _1546 = _1478[3:3];
    assign _1545 = _1478[2:2];
    assign _1544 = _1478[1:1];
    assign _1543 = _1478[0:0];
    always @* begin
        case (_1539)
        0:
            _1551 <= _1543;
        1:
            _1551 <= _1544;
        2:
            _1551 <= _1545;
        3:
            _1551 <= _1546;
        4:
            _1551 <= _1547;
        5:
            _1551 <= _1548;
        6:
            _1551 <= _1549;
        default:
            _1551 <= _1550;
        endcase
    end
    assign _1542 = pin_out[3:3];
    assign _1539 = _1083 - _1318;
    assign _1540 = { _339,
                     _1539 };
    assign _1541 = _1540 < _945;
    assign _1552 = _1541 ? _1551 : _1542;
    assign _1534 = _1478[7:7];
    assign _1533 = _1478[6:6];
    assign _1532 = _1478[5:5];
    assign _1531 = _1478[4:4];
    assign _1530 = _1478[3:3];
    assign _1529 = _1478[2:2];
    assign _1528 = _1478[1:1];
    assign _1527 = _1478[0:0];
    always @* begin
        case (_1523)
        0:
            _1535 <= _1527;
        1:
            _1535 <= _1528;
        2:
            _1535 <= _1529;
        3:
            _1535 <= _1530;
        4:
            _1535 <= _1531;
        5:
            _1535 <= _1532;
        6:
            _1535 <= _1533;
        default:
            _1535 <= _1534;
        endcase
    end
    assign _1526 = pin_out[4:4];
    assign _1523 = _1829 - _1318;
    assign _1524 = { _339,
                     _1523 };
    assign _1525 = _1524 < _945;
    assign _1536 = _1525 ? _1535 : _1526;
    assign _1518 = _1478[7:7];
    assign _1517 = _1478[6:6];
    assign _1516 = _1478[5:5];
    assign _1515 = _1478[4:4];
    assign _1514 = _1478[3:3];
    assign _1513 = _1478[2:2];
    assign _1512 = _1478[1:1];
    assign _1511 = _1478[0:0];
    always @* begin
        case (_1507)
        0:
            _1519 <= _1511;
        1:
            _1519 <= _1512;
        2:
            _1519 <= _1513;
        3:
            _1519 <= _1514;
        4:
            _1519 <= _1515;
        5:
            _1519 <= _1516;
        6:
            _1519 <= _1517;
        default:
            _1519 <= _1518;
        endcase
    end
    assign _1510 = pin_out[5:5];
    assign _1507 = _1055 - _1318;
    assign _1508 = { _339,
                     _1507 };
    assign _1509 = _1508 < _945;
    assign _1520 = _1509 ? _1519 : _1510;
    assign _1502 = _1478[7:7];
    assign _1501 = _1478[6:6];
    assign _1500 = _1478[5:5];
    assign _1499 = _1478[4:4];
    assign _1498 = _1478[3:3];
    assign _1497 = _1478[2:2];
    assign _1496 = _1478[1:1];
    assign _1495 = _1478[0:0];
    always @* begin
        case (_1491)
        0:
            _1503 <= _1495;
        1:
            _1503 <= _1496;
        2:
            _1503 <= _1497;
        3:
            _1503 <= _1498;
        4:
            _1503 <= _1499;
        5:
            _1503 <= _1500;
        6:
            _1503 <= _1501;
        default:
            _1503 <= _1502;
        endcase
    end
    assign _1494 = pin_out[6:6];
    assign _1491 = _1041 - _1318;
    assign _1492 = { _339,
                     _1491 };
    assign _1493 = _1492 < _945;
    assign _1504 = _1493 ? _1503 : _1494;
    assign _1486 = _1478[7:7];
    assign _1485 = _1478[6:6];
    assign _1484 = _1478[5:5];
    assign _1483 = _1478[4:4];
    assign _1482 = _1478[3:3];
    assign _1481 = _1478[2:2];
    assign _1480 = _1478[1:1];
    assign _1479 = _1478[0:0];
    always @* begin
        case (_1448)
        0:
            _1487 <= _1479;
        1:
            _1487 <= _1480;
        2:
            _1487 <= _1481;
        3:
            _1487 <= _1482;
        4:
            _1487 <= _1483;
        5:
            _1487 <= _1484;
        6:
            _1487 <= _1485;
        default:
            _1487 <= _1486;
        endcase
    end
    assign _1451 = pin_out[7:7];
    assign _1448 = _1027 - _1318;
    assign _1449 = { _339,
                     _1448 };
    assign _1450 = _1449 < _945;
    assign _1488 = _1450 ? _1487 : _1451;
    assign _1601 = { _1488,
                     _1504,
                     _1520,
                     _1536,
                     _1552,
                     _1568,
                     _1584,
                     _1600 };
    assign _1445 = _1443 == _339;
    assign _1602 = _1445 ? _1601 : pin_out;
    assign _1436 = _1013[7:7];
    assign _1435 = _1013[6:6];
    assign _1434 = _1013[5:5];
    assign _1433 = _1013[4:4];
    assign _1432 = _1013[3:3];
    assign _1431 = _1013[2:2];
    assign _1430 = _1013[1:1];
    assign _1429 = _1013[0:0];
    always @* begin
        case (_1425)
        0:
            _1437 <= _1429;
        1:
            _1437 <= _1430;
        2:
            _1437 <= _1431;
        3:
            _1437 <= _1432;
        4:
            _1437 <= _1433;
        5:
            _1437 <= _1434;
        6:
            _1437 <= _1435;
        default:
            _1437 <= _1436;
        endcase
    end
    assign _1428 = pin_out[0:0];
    assign _1425 = _344 - _1318;
    assign _1426 = { gnd,
                     _1425 };
    assign _1427 = _1426 < _1321;
    assign _1438 = _1427 ? _1437 : _1428;
    assign _1421 = _1013[7:7];
    assign _1420 = _1013[6:6];
    assign _1419 = _1013[5:5];
    assign _1418 = _1013[4:4];
    assign _1417 = _1013[3:3];
    assign _1416 = _1013[2:2];
    assign _1415 = _1013[1:1];
    assign _1414 = _1013[0:0];
    always @* begin
        case (_1410)
        0:
            _1422 <= _1414;
        1:
            _1422 <= _1415;
        2:
            _1422 <= _1416;
        3:
            _1422 <= _1417;
        4:
            _1422 <= _1418;
        5:
            _1422 <= _1419;
        6:
            _1422 <= _1420;
        default:
            _1422 <= _1421;
        endcase
    end
    assign _1413 = pin_out[1:1];
    assign _1410 = _887 - _1318;
    assign _1411 = { gnd,
                     _1410 };
    assign _1412 = _1411 < _1321;
    assign _1423 = _1412 ? _1422 : _1413;
    assign _1406 = _1013[7:7];
    assign _1405 = _1013[6:6];
    assign _1404 = _1013[5:5];
    assign _1403 = _1013[4:4];
    assign _1402 = _1013[3:3];
    assign _1401 = _1013[2:2];
    assign _1400 = _1013[1:1];
    assign _1399 = _1013[0:0];
    always @* begin
        case (_1395)
        0:
            _1407 <= _1399;
        1:
            _1407 <= _1400;
        2:
            _1407 <= _1401;
        3:
            _1407 <= _1402;
        4:
            _1407 <= _1403;
        5:
            _1407 <= _1404;
        6:
            _1407 <= _1405;
        default:
            _1407 <= _1406;
        endcase
    end
    assign _1398 = pin_out[2:2];
    assign _1395 = _1747 - _1318;
    assign _1396 = { gnd,
                     _1395 };
    assign _1397 = _1396 < _1321;
    assign _1408 = _1397 ? _1407 : _1398;
    assign _1391 = _1013[7:7];
    assign _1390 = _1013[6:6];
    assign _1389 = _1013[5:5];
    assign _1388 = _1013[4:4];
    assign _1387 = _1013[3:3];
    assign _1386 = _1013[2:2];
    assign _1385 = _1013[1:1];
    assign _1384 = _1013[0:0];
    always @* begin
        case (_1380)
        0:
            _1392 <= _1384;
        1:
            _1392 <= _1385;
        2:
            _1392 <= _1386;
        3:
            _1392 <= _1387;
        4:
            _1392 <= _1388;
        5:
            _1392 <= _1389;
        6:
            _1392 <= _1390;
        default:
            _1392 <= _1391;
        endcase
    end
    assign _1383 = pin_out[3:3];
    assign _1380 = _1083 - _1318;
    assign _1381 = { gnd,
                     _1380 };
    assign _1382 = _1381 < _1321;
    assign _1393 = _1382 ? _1392 : _1383;
    assign _1376 = _1013[7:7];
    assign _1375 = _1013[6:6];
    assign _1374 = _1013[5:5];
    assign _1373 = _1013[4:4];
    assign _1372 = _1013[3:3];
    assign _1371 = _1013[2:2];
    assign _1370 = _1013[1:1];
    assign _1369 = _1013[0:0];
    always @* begin
        case (_1365)
        0:
            _1377 <= _1369;
        1:
            _1377 <= _1370;
        2:
            _1377 <= _1371;
        3:
            _1377 <= _1372;
        4:
            _1377 <= _1373;
        5:
            _1377 <= _1374;
        6:
            _1377 <= _1375;
        default:
            _1377 <= _1376;
        endcase
    end
    assign _1368 = pin_out[4:4];
    assign _1365 = _1829 - _1318;
    assign _1366 = { gnd,
                     _1365 };
    assign _1367 = _1366 < _1321;
    assign _1378 = _1367 ? _1377 : _1368;
    assign _1361 = _1013[7:7];
    assign _1360 = _1013[6:6];
    assign _1359 = _1013[5:5];
    assign _1358 = _1013[4:4];
    assign _1357 = _1013[3:3];
    assign _1356 = _1013[2:2];
    assign _1355 = _1013[1:1];
    assign _1354 = _1013[0:0];
    always @* begin
        case (_1350)
        0:
            _1362 <= _1354;
        1:
            _1362 <= _1355;
        2:
            _1362 <= _1356;
        3:
            _1362 <= _1357;
        4:
            _1362 <= _1358;
        5:
            _1362 <= _1359;
        6:
            _1362 <= _1360;
        default:
            _1362 <= _1361;
        endcase
    end
    assign _1353 = pin_out[5:5];
    assign _1350 = _1055 - _1318;
    assign _1351 = { gnd,
                     _1350 };
    assign _1352 = _1351 < _1321;
    assign _1363 = _1352 ? _1362 : _1353;
    assign _1346 = _1013[7:7];
    assign _1345 = _1013[6:6];
    assign _1344 = _1013[5:5];
    assign _1343 = _1013[4:4];
    assign _1342 = _1013[3:3];
    assign _1341 = _1013[2:2];
    assign _1340 = _1013[1:1];
    assign _1339 = _1013[0:0];
    always @* begin
        case (_1335)
        0:
            _1347 <= _1339;
        1:
            _1347 <= _1340;
        2:
            _1347 <= _1341;
        3:
            _1347 <= _1342;
        4:
            _1347 <= _1343;
        5:
            _1347 <= _1344;
        6:
            _1347 <= _1345;
        default:
            _1347 <= _1346;
        endcase
    end
    assign _1338 = pin_out[6:6];
    assign _1335 = _1041 - _1318;
    assign _1336 = { gnd,
                     _1335 };
    assign _1337 = _1336 < _1321;
    assign _1348 = _1337 ? _1347 : _1338;
    assign _1331 = _1013[7:7];
    assign _1330 = _1013[6:6];
    assign _1329 = _1013[5:5];
    assign _1328 = _1013[4:4];
    assign _1327 = _1013[3:3];
    assign _1326 = _1013[2:2];
    assign _1325 = _1013[1:1];
    assign _1324 = _1013[0:0];
    always @* begin
        case (_1319)
        0:
            _1332 <= _1324;
        1:
            _1332 <= _1325;
        2:
            _1332 <= _1326;
        3:
            _1332 <= _1327;
        4:
            _1332 <= _1328;
        5:
            _1332 <= _1329;
        6:
            _1332 <= _1330;
        default:
            _1332 <= _1331;
        endcase
    end
    assign _1323 = pin_out[7:7];
    assign _1321 = _292[7:4];
    assign _291 = 8'b00010000;
    assign _1172 = _376[7:0];
    assign _1169 = 7'b1000010;
    assign _1170 = _387 == _1169;
    assign _1168 = _381 & _385;
    assign _1171 = _1168 & _1170;
    assign _1173 = _1171 ? _1172 : _292;
    assign _20 = _1173;
    always @(posedge _41) begin
        if (_39)
            _292 <= _291;
        else
            _292 <= _20;
    end
    assign _1318 = _292[2:0];
    assign _1319 = _1027 - _1318;
    assign _1320 = { gnd,
                     _1319 };
    assign _1322 = _1320 < _1321;
    assign _1333 = _1322 ? _1332 : _1323;
    assign _1439 = { _1333,
                     _1348,
                     _1363,
                     _1378,
                     _1393,
                     _1408,
                     _1423,
                     _1438 };
    assign _1316 = _922 == _1747;
    assign _1440 = _1316 ? _1439 : pin_out;
    assign _1441 = _928 ? _1440 : pin_out;
    assign _1309 = _1196[7:7];
    assign _1308 = _1196[6:6];
    assign _1307 = _1196[5:5];
    assign _1306 = _1196[4:4];
    assign _1305 = _1196[3:3];
    assign _1304 = _1196[2:2];
    assign _1303 = _1196[1:1];
    assign _1302 = _1196[0:0];
    always @* begin
        case (_1298)
        0:
            _1310 <= _1302;
        1:
            _1310 <= _1303;
        2:
            _1310 <= _1304;
        3:
            _1310 <= _1305;
        4:
            _1310 <= _1306;
        5:
            _1310 <= _1307;
        6:
            _1310 <= _1308;
        default:
            _1310 <= _1309;
        endcase
    end
    assign _1301 = pin_out[0:0];
    assign _1298 = _344 - _1188;
    assign _1299 = { gnd,
                     _1298 };
    assign _1300 = _1299 < _1191;
    assign _1311 = _1300 ? _1310 : _1301;
    assign _1294 = _1196[7:7];
    assign _1293 = _1196[6:6];
    assign _1292 = _1196[5:5];
    assign _1291 = _1196[4:4];
    assign _1290 = _1196[3:3];
    assign _1289 = _1196[2:2];
    assign _1288 = _1196[1:1];
    assign _1287 = _1196[0:0];
    always @* begin
        case (_1283)
        0:
            _1295 <= _1287;
        1:
            _1295 <= _1288;
        2:
            _1295 <= _1289;
        3:
            _1295 <= _1290;
        4:
            _1295 <= _1291;
        5:
            _1295 <= _1292;
        6:
            _1295 <= _1293;
        default:
            _1295 <= _1294;
        endcase
    end
    assign _1286 = pin_out[1:1];
    assign _1283 = _887 - _1188;
    assign _1284 = { gnd,
                     _1283 };
    assign _1285 = _1284 < _1191;
    assign _1296 = _1285 ? _1295 : _1286;
    assign _1279 = _1196[7:7];
    assign _1278 = _1196[6:6];
    assign _1277 = _1196[5:5];
    assign _1276 = _1196[4:4];
    assign _1275 = _1196[3:3];
    assign _1274 = _1196[2:2];
    assign _1273 = _1196[1:1];
    assign _1272 = _1196[0:0];
    always @* begin
        case (_1268)
        0:
            _1280 <= _1272;
        1:
            _1280 <= _1273;
        2:
            _1280 <= _1274;
        3:
            _1280 <= _1275;
        4:
            _1280 <= _1276;
        5:
            _1280 <= _1277;
        6:
            _1280 <= _1278;
        default:
            _1280 <= _1279;
        endcase
    end
    assign _1271 = pin_out[2:2];
    assign _1268 = _1747 - _1188;
    assign _1269 = { gnd,
                     _1268 };
    assign _1270 = _1269 < _1191;
    assign _1281 = _1270 ? _1280 : _1271;
    assign _1264 = _1196[7:7];
    assign _1263 = _1196[6:6];
    assign _1262 = _1196[5:5];
    assign _1261 = _1196[4:4];
    assign _1260 = _1196[3:3];
    assign _1259 = _1196[2:2];
    assign _1258 = _1196[1:1];
    assign _1257 = _1196[0:0];
    always @* begin
        case (_1253)
        0:
            _1265 <= _1257;
        1:
            _1265 <= _1258;
        2:
            _1265 <= _1259;
        3:
            _1265 <= _1260;
        4:
            _1265 <= _1261;
        5:
            _1265 <= _1262;
        6:
            _1265 <= _1263;
        default:
            _1265 <= _1264;
        endcase
    end
    assign _1256 = pin_out[3:3];
    assign _1253 = _1083 - _1188;
    assign _1254 = { gnd,
                     _1253 };
    assign _1255 = _1254 < _1191;
    assign _1266 = _1255 ? _1265 : _1256;
    assign _1249 = _1196[7:7];
    assign _1248 = _1196[6:6];
    assign _1247 = _1196[5:5];
    assign _1246 = _1196[4:4];
    assign _1245 = _1196[3:3];
    assign _1244 = _1196[2:2];
    assign _1243 = _1196[1:1];
    assign _1242 = _1196[0:0];
    always @* begin
        case (_1238)
        0:
            _1250 <= _1242;
        1:
            _1250 <= _1243;
        2:
            _1250 <= _1244;
        3:
            _1250 <= _1245;
        4:
            _1250 <= _1246;
        5:
            _1250 <= _1247;
        6:
            _1250 <= _1248;
        default:
            _1250 <= _1249;
        endcase
    end
    assign _1241 = pin_out[4:4];
    assign _1238 = _1829 - _1188;
    assign _1239 = { gnd,
                     _1238 };
    assign _1240 = _1239 < _1191;
    assign _1251 = _1240 ? _1250 : _1241;
    assign _1234 = _1196[7:7];
    assign _1233 = _1196[6:6];
    assign _1232 = _1196[5:5];
    assign _1231 = _1196[4:4];
    assign _1230 = _1196[3:3];
    assign _1229 = _1196[2:2];
    assign _1228 = _1196[1:1];
    assign _1227 = _1196[0:0];
    always @* begin
        case (_1223)
        0:
            _1235 <= _1227;
        1:
            _1235 <= _1228;
        2:
            _1235 <= _1229;
        3:
            _1235 <= _1230;
        4:
            _1235 <= _1231;
        5:
            _1235 <= _1232;
        6:
            _1235 <= _1233;
        default:
            _1235 <= _1234;
        endcase
    end
    assign _1226 = pin_out[5:5];
    assign _1223 = _1055 - _1188;
    assign _1224 = { gnd,
                     _1223 };
    assign _1225 = _1224 < _1191;
    assign _1236 = _1225 ? _1235 : _1226;
    assign _1219 = _1196[7:7];
    assign _1218 = _1196[6:6];
    assign _1217 = _1196[5:5];
    assign _1216 = _1196[4:4];
    assign _1215 = _1196[3:3];
    assign _1214 = _1196[2:2];
    assign _1213 = _1196[1:1];
    assign _1212 = _1196[0:0];
    always @* begin
        case (_1208)
        0:
            _1220 <= _1212;
        1:
            _1220 <= _1213;
        2:
            _1220 <= _1214;
        3:
            _1220 <= _1215;
        4:
            _1220 <= _1216;
        5:
            _1220 <= _1217;
        6:
            _1220 <= _1218;
        default:
            _1220 <= _1219;
        endcase
    end
    assign _1211 = pin_out[6:6];
    assign _1208 = _1041 - _1188;
    assign _1209 = { gnd,
                     _1208 };
    assign _1210 = _1209 < _1191;
    assign _1221 = _1210 ? _1220 : _1211;
    assign _1204 = _1196[7:7];
    assign _1203 = _1196[6:6];
    assign _1202 = _1196[5:5];
    assign _1201 = _1196[4:4];
    assign _1200 = _1196[3:3];
    assign _1199 = _1196[2:2];
    assign _1198 = _1196[1:1];
    assign _1197 = _1196[0:0];
    always @* begin
        case (_1189)
        0:
            _1205 <= _1197;
        1:
            _1205 <= _1198;
        2:
            _1205 <= _1199;
        3:
            _1205 <= _1200;
        4:
            _1205 <= _1201;
        5:
            _1205 <= _1202;
        6:
            _1205 <= _1203;
        default:
            _1205 <= _1204;
        endcase
    end
    assign _1193 = pin_out[7:7];
    assign _1191 = _297[7:4];
    assign _1178 = _376[7:0];
    assign _1175 = 7'b1000011;
    assign _1176 = _387 == _1175;
    assign _1174 = _381 & _385;
    assign _1177 = _1174 & _1176;
    assign _1179 = _1177 ? _1178 : _297;
    assign _21 = _1179;
    always @(posedge _41) begin
        if (_39)
            _297 <= _291;
        else
            _297 <= _21;
    end
    assign _1188 = _297[2:0];
    assign _1189 = _1027 - _1188;
    assign _1190 = { gnd,
                     _1189 };
    assign _1192 = _1190 < _1191;
    assign _1206 = _1192 ? _1205 : _1193;
    assign _1312 = { _1206,
                     _1221,
                     _1236,
                     _1251,
                     _1266,
                     _1281,
                     _1296,
                     _1311 };
    assign _1186 = _1184 == _339;
    assign _1313 = _1186 ? _1312 : pin_out;
    assign _1183 = _775 == _1041;
    assign _1314 = _1183 ? _1313 : pin_out;
    assign _1181 = _775 == _1055;
    assign _1442 = _1181 ? _1441 : _1314;
    assign _1180 = _775 == _1083;
    assign _1603 = _1180 ? _1602 : _1442;
    assign _1604 = _908 ? _1603 : pin_out;
    assign _1605 = _805 ? pin_out : _1604;
    assign _1606 = _802 ? pin_out : _1605;
    assign _22 = _1606;
    always @(posedge _41) begin
        if (_39)
            pin_out <= _56;
        else
            pin_out <= _22;
    end
    assign _811 = pin_out[7:7];
    assign _24 = uio_in;
    assign _810 = _24[7:7];
    assign _1608 = 7'b1000111;
    assign _1609 = _387 == _1608;
    assign _1607 = _381 & _385;
    assign _1610 = _1607 & _1609;
    assign _1611 = _1610 ? _376 : _49;
    assign _25 = _1611;
    always @(posedge _41) begin
        if (_39)
            _49 <= _256;
        else
            _49 <= _25;
    end
    assign _809 = _49[15:14];
    always @* begin
        case (_809)
        0:
            _813 <= _810;
        1:
            _813 <= _811;
        2:
            _813 <= _812;
        default:
            _813 <= _810;
        endcase
    end
    assign _849 = { _813,
                    _818,
                    _823,
                    _828,
                    _833,
                    _838,
                    _843,
                    _848 };
    assign _1008 = { _207,
                     _849 };
    assign _1723 = y - _876;
    assign _1721 = _1719 == _1829;
    assign _1724 = _1721 ? _1723 : y;
    assign _1472 = _1471[15:0];
    assign _1474 = { _1472,
                     _256 };
    assign _1468 = _1467[23:0];
    assign _1470 = { _1468,
                     _207 };
    assign _1464 = _1463[27:0];
    assign _1466 = { _1464,
                     _203 };
    assign _1460 = _1459[29:0];
    assign _1462 = { _1460,
                     _339 };
    assign _1458 = 32'b11111111111111111111111111111110;
    assign _1457 = 32'b11111111111111111111111111111111;
    assign _1456 = _945[0:0];
    assign _1459 = _1456 ? _1458 : _1457;
    assign _1455 = _945[1:1];
    assign _1463 = _1455 ? _1462 : _1459;
    assign _1454 = _945[2:2];
    assign _1467 = _1454 ? _1466 : _1463;
    assign _1453 = _945[3:3];
    assign _1471 = _1453 ? _1470 : _1467;
    assign _1452 = _945[4:4];
    assign _1475 = _1452 ? _1474 : _1471;
    assign _1476 = _1475[15:0];
    assign _1477 = ~ _1476;
    assign _1692 = _1690[31:16];
    assign _1693 = { _256,
                     _1692 };
    assign _1688 = _1686[31:8];
    assign _1689 = { _207,
                     _1688 };
    assign _1684 = _1682[31:4];
    assign _1685 = { _203,
                     _1684 };
    assign _1680 = _1678[31:2];
    assign _1681 = { _339,
                     _1680 };
    assign _1676 = _1674[31:1];
    assign _1677 = { _356,
                     _1676 };
    assign _1674 = { _256,
                     osr };
    assign _1672 = _945[0:0];
    assign _1678 = _1672 ? _1677 : _1674;
    assign _1671 = _945[1:1];
    assign _1682 = _1671 ? _1681 : _1678;
    assign _1670 = _945[2:2];
    assign _1686 = _1670 ? _1685 : _1682;
    assign _1669 = _945[3:3];
    assign _1690 = _1669 ? _1689 : _1686;
    assign _943 = { gnd,
                    _940 };
    assign _940 = _774[3:0];
    assign _942 = _940 == _203;
    assign _945 = _942 ? _180 : _943;
    assign _1668 = _945[4:4];
    assign _1694 = _1668 ? _1693 : _1690;
    assign _1695 = _1694[15:0];
    assign _1662 = tx_wr == _334;
    assign _1663 = _1619 & _1662;
    always @(posedge _41) begin
        if (_39)
            tx_mem_3 <= _256;
        else
            if (_1663)
                tx_mem_3 <= _376;
    end
    assign _1656 = tx_wr == _119;
    assign _1657 = _1619 & _1656;
    always @(posedge _41) begin
        if (_39)
            tx_mem_2 <= _256;
        else
            if (_1657)
                tx_mem_2 <= _376;
    end
    assign _1650 = tx_wr == _117;
    assign _1651 = _1619 & _1650;
    always @(posedge _41) begin
        if (_39)
            tx_mem_1 <= _256;
        else
            if (_1651)
                tx_mem_1 <= _376;
    end
    assign _1624 = tx_wr + _117;
    assign _1625 = _1619 ? _1624 : tx_wr;
    assign _26 = _1625;
    always @(posedge _41) begin
        if (_39)
            tx_wr <= _339;
        else
            tx_wr <= _26;
    end
    assign _1644 = tx_wr == _339;
    assign _1645 = _1619 & _1644;
    always @(posedge _41) begin
        if (_39)
            tx_mem_0 <= _256;
        else
            if (_1645)
                tx_mem_0 <= _376;
    end
    assign _1632 = tx_rd + _117;
    assign _1633 = _1627 ? _1632 : tx_rd;
    assign _27 = _1633;
    always @(posedge _41) begin
        if (_39)
            tx_rd <= _339;
        else
            tx_rd <= _27;
    end
    always @* begin
        case (tx_rd)
        0:
            _1665 <= tx_mem_0;
        1:
            _1665 <= tx_mem_1;
        2:
            _1665 <= tx_mem_2;
        default:
            _1665 <= tx_mem_3;
        endcase
    end
    assign _779 = _774[8:8];
    assign _1666 = _779 ? _1665 : osr;
    assign _1637 = _922 == _1829;
    assign _1638 = _1637 ? _1013 : osr;
    assign _1639 = _928 ? _1638 : osr;
    assign _1636 = _775 == _1055;
    assign _1640 = _1636 ? _1639 : osr;
    assign _1635 = _775 == _1829;
    assign _1667 = _1635 ? _1666 : _1640;
    assign _1634 = _775 == _1083;
    assign _1696 = _1634 ? _1695 : _1667;
    assign _1697 = _908 ? _1696 : osr;
    assign _1698 = _805 ? osr : _1697;
    assign _1700 = _802 ? _256 : _1698;
    assign _28 = _1700;
    always @(posedge _41) begin
        if (_39)
            osr <= _256;
        else
            osr <= _28;
    end
    assign _1478 = osr & _1477;
    assign _1443 = _774[8:7];
    assign _1716 = _1443 == _119;
    assign _1717 = _1716 ? _1478 : y;
    assign _1711 = _922 == _887;
    assign _1712 = _1711 ? _1013 : y;
    assign _1713 = _928 ? _1712 : y;
    assign _1707 = _1184 == _119;
    assign _1708 = _1707 ? _1196 : y;
    assign _1705 = _775 == _1041;
    assign _1709 = _1705 ? _1708 : y;
    assign _1704 = _775 == _1055;
    assign _1714 = _1704 ? _1713 : _1709;
    assign _1703 = _775 == _1083;
    assign _1718 = _1703 ? _1717 : _1714;
    assign _1702 = _775 == _344;
    assign _1725 = _1702 ? _1724 : _1718;
    assign _1726 = _908 ? _1725 : y;
    assign _1727 = _805 ? y : _1726;
    assign _1729 = _802 ? _256 : _1727;
    assign _29 = _1729;
    always @(posedge _41) begin
        if (_39)
            y <= _256;
        else
            y <= _29;
    end
    always @* begin
        case (_925)
        0:
            _1013 <= x;
        1:
            _1013 <= y;
        2:
            _1013 <= _1008;
        3:
            _1013 <= isr;
        4:
            _1013 <= osr;
        default:
            _1013 <= _256;
        endcase
    end
    assign _1739 = _922 == _344;
    assign _1740 = _1739 ? _1013 : x;
    assign _925 = _774[5:3];
    assign _927 = _925 < _1041;
    assign _922 = _774[8:6];
    assign _924 = _922 < _1041;
    assign _928 = _924 & _927;
    assign _1741 = _928 ? _1740 : x;
    assign _1195 = _774[4:0];
    assign _1196 = { _304,
                     _1195 };
    assign _1184 = _774[8:7];
    assign _1735 = _1184 == _117;
    assign _1736 = _1735 ? _1196 : x;
    assign _1733 = _775 == _1041;
    assign _1737 = _1733 ? _1736 : x;
    assign _1732 = _775 == _1055;
    assign _1742 = _1732 ? _1741 : _1737;
    assign _1731 = _775 == _1083;
    assign _1746 = _1731 ? _1745 : _1742;
    assign _1730 = _775 == _344;
    assign _1752 = _1730 ? _1751 : _1746;
    assign _1753 = _908 ? _1752 : x;
    assign _1754 = _805 ? x : _1753;
    assign _1756 = _802 ? _256 : _1754;
    assign _30 = _1756;
    always @(posedge _41) begin
        if (_39)
            x <= _256;
        else
            x <= _30;
    end
    assign _1760 = x == _256;
    assign _1761 = ~ _1760;
    assign _1762 = ~ _1761;
    assign _1719 = _774[8:6];
    always @* begin
        case (_1719)
        0:
            _1771 <= vdd;
        1:
            _1771 <= _1762;
        2:
            _1771 <= _1761;
        3:
            _1771 <= _1766;
        4:
            _1771 <= _1765;
        5:
            _1771 <= _1768;
        6:
            _1771 <= _1769;
        default:
            _1771 <= _1770;
        endcase
    end
    assign _1758 = _775 == _344;
    assign _1772 = _1758 & _1771;
    assign _1778 = _1772 | _1777;
    assign _1785 = _1778 ? _1784 : _1780;
    assign _1786 = _908 ? _1785 : pc;
    assign _1787 = _805 ? pc : _1786;
    assign _1788 = _802 ? _287 : _1787;
    assign _31 = _1788;
    always @(posedge _41) begin
        if (_39)
            pc <= _392;
        else
            pc <= _31;
    end
    always @* begin
        case (pc)
        0:
            _774 <= prog_0;
        1:
            _774 <= prog_1;
        2:
            _774 <= prog_2;
        3:
            _774 <= prog_3;
        4:
            _774 <= prog_4;
        5:
            _774 <= prog_5;
        6:
            _774 <= prog_6;
        7:
            _774 <= prog_7;
        8:
            _774 <= prog_8;
        9:
            _774 <= prog_9;
        10:
            _774 <= prog_10;
        11:
            _774 <= prog_11;
        12:
            _774 <= prog_12;
        13:
            _774 <= prog_13;
        14:
            _774 <= prog_14;
        15:
            _774 <= prog_15;
        16:
            _774 <= prog_16;
        17:
            _774 <= prog_17;
        18:
            _774 <= prog_18;
        19:
            _774 <= prog_19;
        20:
            _774 <= prog_20;
        21:
            _774 <= prog_21;
        22:
            _774 <= prog_22;
        23:
            _774 <= prog_23;
        24:
            _774 <= prog_24;
        25:
            _774 <= prog_25;
        26:
            _774 <= prog_26;
        27:
            _774 <= prog_27;
        28:
            _774 <= prog_28;
        29:
            _774 <= prog_29;
        30:
            _774 <= prog_30;
        31:
            _774 <= prog_31;
        32:
            _774 <= prog_32;
        33:
            _774 <= prog_33;
        34:
            _774 <= prog_34;
        35:
            _774 <= prog_35;
        36:
            _774 <= prog_36;
        37:
            _774 <= prog_37;
        38:
            _774 <= prog_38;
        39:
            _774 <= prog_39;
        40:
            _774 <= prog_40;
        41:
            _774 <= prog_41;
        42:
            _774 <= prog_42;
        43:
            _774 <= prog_43;
        44:
            _774 <= prog_44;
        45:
            _774 <= prog_45;
        46:
            _774 <= prog_46;
        47:
            _774 <= prog_47;
        48:
            _774 <= prog_48;
        49:
            _774 <= prog_49;
        50:
            _774 <= prog_50;
        51:
            _774 <= prog_51;
        52:
            _774 <= prog_52;
        53:
            _774 <= prog_53;
        54:
            _774 <= prog_54;
        55:
            _774 <= prog_55;
        56:
            _774 <= prog_56;
        57:
            _774 <= prog_57;
        58:
            _774 <= prog_58;
        59:
            _774 <= prog_59;
        60:
            _774 <= prog_60;
        61:
            _774 <= prog_61;
        62:
            _774 <= prog_62;
        default:
            _774 <= prog_63;
        endcase
    end
    assign _775 = _774[15:13];
    assign _888 = _775 == _887;
    assign _890 = _888 & _889;
    assign _893 = _890 & _892;
    assign _900 = _893 | _899;
    assign _906 = _900 | _905;
    assign _907 = ~ _906;
    assign _908 = _375 & _907;
    assign _1790 = _908 ? _1789 : delay_left;
    assign _804 = delay_left == _203;
    assign _805 = ~ _804;
    assign _1793 = _805 ? _1792 : _1790;
    assign _802 = ~ _282;
    assign _1795 = _802 ? _203 : _1793;
    assign _32 = _1795;
    always @(posedge _41) begin
        if (_39)
            delay_left <= _203;
        else
            delay_left <= _32;
    end
    assign _374 = delay_left == _203;
    assign _376 = _268[15:0];
    assign _1800 = _376[0:0];
    assign _1798 = _387 == _388;
    assign _1796 = _381 & _385;
    assign _1799 = _1796 & _1798;
    assign _1801 = _1799 ? _1800 : _282;
    assign _33 = _1801;
    always @(posedge _41) begin
        if (_39)
            _282 <= _356;
        else
            _282 <= _33;
    end
    assign _375 = _282 & _374;
    assign _1804 = _375 & _1803;
    assign _1805 = _1804 & _779;
    assign _1807 = _1805 & _1806;
    assign _34 = _1807;
    assign _1627 = _34 & _1626;
    assign _1826 = { _339,
                     _1627 };
    assign _1617 = tx_level == _1829;
    assign _1618 = ~ _1617;
    assign _1613 = 7'b1001000;
    assign _387 = _384[6:0];
    assign _1614 = _387 == _1613;
    assign _263 = _43[2:2];
    always @(posedge _41) begin
        if (_39)
            _265 <= gnd;
        else
            _265 <= _263;
    end
    always @(posedge _41) begin
        if (_39)
            _267 <= gnd;
        else
            _267 <= _265;
    end
    assign _261 = 23'b00000000000000000000000;
    assign _1808 = _268[22:0];
    assign _1809 = _254 ? _1808 : _262;
    assign _1810 = _230 ? _262 : _1809;
    assign _35 = _1810;
    always @(posedge _41) begin
        if (_39)
            _262 <= _261;
        else
            _262 <= _35;
    end
    assign _268 = { _262,
                    _267 };
    assign _269 = _268[7:0];
    assign _259 = _246 == _360;
    assign _1811 = _259 ? _269 : _384;
    assign _1812 = _254 ? _1811 : _384;
    assign _1813 = _230 ? _384 : _1812;
    assign _36 = _1813;
    always @(posedge _41) begin
        if (_39)
            _384 <= _207;
        else
            _384 <= _36;
    end
    assign _385 = _384[7:7];
    assign _379 = 5'b10111;
    assign _1817 = _246 + _1122;
    assign _1814 = 5'b11000;
    assign _1815 = _246 < _1814;
    assign _1818 = _1815 ? _1817 : _246;
    assign _1819 = _254 ? _1818 : _246;
    assign _1821 = _230 ? _182 : _1819;
    assign _37 = _1821;
    always @(posedge _41) begin
        if (_39)
            _246 <= _182;
        else
            _246 <= _37;
    end
    assign _380 = _246 == _379;
    assign _226 = _43[1:1];
    always @(posedge _41) begin
        if (_39)
            _228 <= vdd;
        else
            _228 <= _226;
    end
    always @(posedge _41) begin
        if (_39)
            _230 <= vdd;
        else
            _230 <= _228;
    end
    assign _253 = ~ _230;
    always @(posedge _41) begin
        if (_39)
            _240 <= _356;
        else
            _240 <= _236;
    end
    assign _251 = ~ _240;
    assign vdd = 1'b1;
    assign gnd = 1'b0;
    assign _39 = clear;
    assign _41 = clock;
    assign _43 = ui_in;
    assign _231 = _43[0:0];
    always @(posedge _41) begin
        if (_39)
            _234 <= gnd;
        else
            _234 <= _231;
    end
    always @(posedge _41) begin
        if (_39)
            _236 <= gnd;
        else
            _236 <= _234;
    end
    assign _252 = _236 & _251;
    assign _254 = _252 & _253;
    assign _381 = _254 & _380;
    assign _1612 = _381 & _385;
    assign _1615 = _1612 & _1614;
    assign _1619 = _1615 & _1618;
    assign _1823 = { _339,
                     _1619 };
    assign _1824 = tx_level + _1823;
    assign _1827 = _1824 - _1826;
    assign _44 = _1827;
    always @(posedge _41) begin
        if (_39)
            tx_level <= _344;
        else
            tx_level <= _44;
    end
    assign _1830 = tx_level == _1829;
    assign _1832 = { _203,
                     _1830,
                     _275,
                     _282,
                     _1831 };
    assign uo_out = _1832;
    assign uio_out = _166;
    assign uio_oe = _125;

endmodule
