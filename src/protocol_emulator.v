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

    wire _122;
    wire _123;
    wire [1:0] _120;
    wire _121;
    wire _124;
    wire [1:0] _118;
    wire [1:0] _117;
    wire _119;
    wire _125;
    wire _113;
    wire _114;
    wire _112;
    wire _115;
    wire [1:0] _108;
    wire _110;
    wire _116;
    wire _104;
    wire _105;
    wire _103;
    wire _106;
    wire [1:0] _99;
    wire _101;
    wire _107;
    wire _95;
    wire _96;
    wire _94;
    wire _97;
    wire [1:0] _90;
    wire _92;
    wire _98;
    wire _86;
    wire _87;
    wire _85;
    wire _88;
    wire [1:0] _81;
    wire _83;
    wire _89;
    wire _77;
    wire _78;
    wire _76;
    wire _79;
    wire [1:0] _72;
    wire _74;
    wire _80;
    wire _68;
    wire _69;
    wire _67;
    wire _70;
    wire [1:0] _63;
    wire _65;
    wire _71;
    wire _59;
    wire _60;
    wire _55;
    wire _61;
    wire [1:0] _51;
    wire _53;
    wire _62;
    wire [7:0] _126;
    wire _165;
    wire [1:0] _162;
    wire _164;
    wire _166;
    wire _160;
    wire [1:0] _157;
    wire _159;
    wire _161;
    wire _155;
    wire [1:0] _152;
    wire _154;
    wire _156;
    wire _150;
    wire [1:0] _147;
    wire _149;
    wire _151;
    wire _145;
    wire [1:0] _142;
    wire _144;
    wire _146;
    wire _140;
    wire [1:0] _137;
    wire _139;
    wire _141;
    wire _135;
    wire [1:0] _132;
    wire _134;
    wire _136;
    wire _130;
    wire [1:0] _127;
    wire _129;
    wire _131;
    wire [7:0] _167;
    wire [15:0] _257;
    wire _362;
    wire [14:0] _361;
    wire [15:0] _363;
    wire [9:0] _351;
    wire [15:0] _355;
    wire [1:0] _340;
    wire [15:0] _347;
    wire [1:0] _335;
    wire _336;
    wire _337;
    reg [15:0] rx_mem_3;
    wire _330;
    wire _331;
    reg [15:0] rx_mem_2;
    wire _324;
    wire _325;
    reg [15:0] rx_mem_1;
    wire [1:0] _179;
    wire [1:0] _180;
    wire [1:0] _3;
    reg [1:0] rx_wr;
    wire _318;
    wire _319;
    wire [15:0] _213;
    wire [31:0] _214;
    wire [23:0] _209;
    wire [7:0] _208;
    wire [31:0] _210;
    wire [27:0] _205;
    wire [3:0] _204;
    wire [31:0] _206;
    wire [29:0] _201;
    wire [31:0] _202;
    wire [30:0] _197;
    wire [31:0] _198;
    wire [31:0] _195;
    wire _190;
    wire [31:0] _199;
    wire _189;
    wire [31:0] _203;
    wire _188;
    wire [31:0] _207;
    wire _187;
    wire [31:0] _211;
    wire [4:0] _181;
    wire [4:0] _185;
    wire _186;
    wire [31:0] _215;
    wire [15:0] _216;
    wire [15:0] _4;
    reg [15:0] rx_mem_0;
    wire [1:0] _225;
    wire [1:0] _226;
    wire [1:0] _5;
    reg [1:0] rx_rd;
    reg [15:0] _339;
    wire [15:0] _314;
    wire [10:0] _305;
    wire [15:0] _309;
    wire [12:0] _300;
    wire [15:0] _304;
    wire [15:0] _299;
    wire [15:0] _294;
    wire [15:0] _289;
    wire [14:0] _280;
    wire [15:0] _284;
    reg [15:0] _356;
    wire _277;
    wire [6:0] _272;
    wire _273;
    wire _278;
    wire [15:0] _358;
    wire [15:0] _359;
    wire [15:0] _360;
    wire [4:0] _248;
    wire _249;
    wire _250;
    wire _243;
    wire _238;
    wire _242;
    wire _244;
    wire _251;
    wire [15:0] _364;
    wire [15:0] _365;
    wire [15:0] _6;
    reg [15:0] _258;
    wire _2016;
    wire [2:0] _2014;
    wire [2:0] _345;
    wire _1800;
    wire _1991;
    wire _1988;
    wire [3:0] _1976;
    wire [3:0] _1977;
    wire [1:0] _1971;
    wire [3:0] _1972;
    wire [3:0] _1968;
    wire [3:0] _1967;
    wire _1966;
    wire [3:0] _1969;
    wire _1965;
    wire [3:0] _1973;
    wire [3:0] _1974;
    wire _218;
    wire _219;
    wire _275;
    wire _276;
    wire [6:0] _271;
    wire _373;
    wire _369;
    wire _370;
    wire [4:0] _366;
    wire _367;
    wire _368;
    wire _371;
    wire _374;
    wire _375;
    wire _7;
    wire _220;
    wire [2:0] _794;
    wire _173;
    wire _788;
    wire _786;
    wire _783;
    wire _784;
    wire _787;
    wire _789;
    wire _8;
    wire _174;
    wire [2:0] _791;
    wire [2:0] _792;
    wire [2:0] _795;
    wire [2:0] _9;
    reg [2:0] rx_level;
    wire _172;
    wire _909;
    wire _908;
    wire _910;
    wire _911;
    wire _904;
    wire _901;
    wire _902;
    wire _905;
    wire _898;
    wire _895;
    wire [2:0] _893;
    wire [5:0] _776;
    wire _777;
    wire _778;
    reg [15:0] prog_63;
    wire [5:0] _770;
    wire _771;
    wire _772;
    reg [15:0] prog_62;
    wire [5:0] _764;
    wire _765;
    wire _766;
    reg [15:0] prog_61;
    wire [5:0] _758;
    wire _759;
    wire _760;
    reg [15:0] prog_60;
    wire [5:0] _752;
    wire _753;
    wire _754;
    reg [15:0] prog_59;
    wire [5:0] _746;
    wire _747;
    wire _748;
    reg [15:0] prog_58;
    wire [5:0] _740;
    wire _741;
    wire _742;
    reg [15:0] prog_57;
    wire [5:0] _734;
    wire _735;
    wire _736;
    reg [15:0] prog_56;
    wire [5:0] _728;
    wire _729;
    wire _730;
    reg [15:0] prog_55;
    wire [5:0] _722;
    wire _723;
    wire _724;
    reg [15:0] prog_54;
    wire [5:0] _716;
    wire _717;
    wire _718;
    reg [15:0] prog_53;
    wire [5:0] _710;
    wire _711;
    wire _712;
    reg [15:0] prog_52;
    wire [5:0] _704;
    wire _705;
    wire _706;
    reg [15:0] prog_51;
    wire [5:0] _698;
    wire _699;
    wire _700;
    reg [15:0] prog_50;
    wire [5:0] _692;
    wire _693;
    wire _694;
    reg [15:0] prog_49;
    wire [5:0] _686;
    wire _687;
    wire _688;
    reg [15:0] prog_48;
    wire [5:0] _680;
    wire _681;
    wire _682;
    reg [15:0] prog_47;
    wire [5:0] _674;
    wire _675;
    wire _676;
    reg [15:0] prog_46;
    wire [5:0] _668;
    wire _669;
    wire _670;
    reg [15:0] prog_45;
    wire [5:0] _662;
    wire _663;
    wire _664;
    reg [15:0] prog_44;
    wire [5:0] _656;
    wire _657;
    wire _658;
    reg [15:0] prog_43;
    wire [5:0] _650;
    wire _651;
    wire _652;
    reg [15:0] prog_42;
    wire [5:0] _644;
    wire _645;
    wire _646;
    reg [15:0] prog_41;
    wire [5:0] _638;
    wire _639;
    wire _640;
    reg [15:0] prog_40;
    wire [5:0] _632;
    wire _633;
    wire _634;
    reg [15:0] prog_39;
    wire [5:0] _626;
    wire _627;
    wire _628;
    reg [15:0] prog_38;
    wire [5:0] _620;
    wire _621;
    wire _622;
    reg [15:0] prog_37;
    wire [5:0] _614;
    wire _615;
    wire _616;
    reg [15:0] prog_36;
    wire [5:0] _608;
    wire _609;
    wire _610;
    reg [15:0] prog_35;
    wire [5:0] _602;
    wire _603;
    wire _604;
    reg [15:0] prog_34;
    wire [5:0] _596;
    wire _597;
    wire _598;
    reg [15:0] prog_33;
    wire [5:0] _590;
    wire _591;
    wire _592;
    reg [15:0] prog_32;
    wire [5:0] _584;
    wire _585;
    wire _586;
    reg [15:0] prog_31;
    wire [5:0] _578;
    wire _579;
    wire _580;
    reg [15:0] prog_30;
    wire [5:0] _572;
    wire _573;
    wire _574;
    reg [15:0] prog_29;
    wire [5:0] _566;
    wire _567;
    wire _568;
    reg [15:0] prog_28;
    wire [5:0] _560;
    wire _561;
    wire _562;
    reg [15:0] prog_27;
    wire [5:0] _554;
    wire _555;
    wire _556;
    reg [15:0] prog_26;
    wire [5:0] _548;
    wire _549;
    wire _550;
    reg [15:0] prog_25;
    wire [5:0] _542;
    wire _543;
    wire _544;
    reg [15:0] prog_24;
    wire [5:0] _536;
    wire _537;
    wire _538;
    reg [15:0] prog_23;
    wire [5:0] _530;
    wire _531;
    wire _532;
    reg [15:0] prog_22;
    wire [5:0] _524;
    wire _525;
    wire _526;
    reg [15:0] prog_21;
    wire [5:0] _518;
    wire _519;
    wire _520;
    reg [15:0] prog_20;
    wire [5:0] _512;
    wire _513;
    wire _514;
    reg [15:0] prog_19;
    wire [5:0] _506;
    wire _507;
    wire _508;
    reg [15:0] prog_18;
    wire [5:0] _500;
    wire _501;
    wire _502;
    reg [15:0] prog_17;
    wire [5:0] _494;
    wire _495;
    wire _496;
    reg [15:0] prog_16;
    wire [5:0] _488;
    wire _489;
    wire _490;
    reg [15:0] prog_15;
    wire [5:0] _482;
    wire _483;
    wire _484;
    reg [15:0] prog_14;
    wire [5:0] _476;
    wire _477;
    wire _478;
    reg [15:0] prog_13;
    wire [5:0] _470;
    wire _471;
    wire _472;
    reg [15:0] prog_12;
    wire [5:0] _464;
    wire _465;
    wire _466;
    reg [15:0] prog_11;
    wire [5:0] _458;
    wire _459;
    wire _460;
    reg [15:0] prog_10;
    wire [5:0] _452;
    wire _453;
    wire _454;
    reg [15:0] prog_9;
    wire [5:0] _446;
    wire _447;
    wire _448;
    reg [15:0] prog_8;
    wire [5:0] _440;
    wire _441;
    wire _442;
    reg [15:0] prog_7;
    wire [5:0] _434;
    wire _435;
    wire _436;
    reg [15:0] prog_6;
    wire [5:0] _428;
    wire _429;
    wire _430;
    reg [15:0] prog_5;
    wire [5:0] _422;
    wire _423;
    wire _424;
    reg [15:0] prog_4;
    wire [5:0] _416;
    wire _417;
    wire _418;
    reg [15:0] prog_3;
    wire [5:0] _410;
    wire _411;
    wire _412;
    reg [15:0] prog_2;
    wire [5:0] _404;
    wire _405;
    wire _406;
    reg [15:0] prog_1;
    wire [5:0] _398;
    wire [5:0] _397;
    wire _399;
    wire [6:0] _394;
    wire _395;
    wire _392;
    wire _396;
    wire _400;
    reg [15:0] prog_0;
    wire [5:0] _800;
    wire [6:0] _797;
    wire _798;
    wire _796;
    wire _799;
    wire [5:0] _801;
    wire [5:0] _10;
    reg [5:0] _288;
    wire [5:0] _1959;
    wire [5:0] _806;
    wire [6:0] _803;
    wire _804;
    wire _802;
    wire _805;
    wire [5:0] _807;
    wire [5:0] _11;
    reg [5:0] _313;
    wire _1958;
    wire [5:0] _1960;
    wire [5:0] _1956;
    wire [15:0] _882;
    wire [15:0] _883;
    wire [15:0] _884;
    wire [15:0] _885;
    wire [15:0] _887;
    wire [15:0] _12;
    reg [15:0] wait_count;
    wire [6:0] _889;
    wire _890;
    wire _888;
    wire _891;
    wire [15:0] _892;
    wire [15:0] _13;
    reg [15:0] _350;
    wire _915;
    wire _880;
    wire _867;
    wire _813;
    wire _868;
    wire _870;
    wire _881;
    wire _916;
    wire _918;
    wire _919;
    wire _921;
    wire _14;
    reg waiting;
    wire [15:0] _877;
    wire _879;
    wire _869;
    wire _897;
    wire _865;
    wire _863;
    wire _862;
    wire _861;
    wire _860;
    wire _859;
    wire _858;
    wire _857;
    wire _856;
    wire [2:0] _814;
    reg _864;
    wire _866;
    wire _1951;
    wire _1950;
    wire _1952;
    wire _1953;
    wire [4:0] _183;
    wire [4:0] _955;
    wire [5:0] _952;
    wire [5:0] _945;
    wire [5:0] _953;
    wire _954;
    wire [4:0] _957;
    wire [4:0] _942;
    wire _936;
    wire [4:0] _938;
    wire [4:0] _939;
    wire _927;
    wire [4:0] _940;
    wire _925;
    wire [4:0] _943;
    wire _923;
    wire [4:0] _958;
    wire [4:0] _959;
    wire [4:0] _960;
    wire [4:0] _962;
    wire [4:0] _15;
    reg [4:0] isr_count;
    wire _1946;
    wire [4:0] _307;
    wire [4:0] _967;
    wire [6:0] _964;
    wire _965;
    wire _963;
    wire _966;
    wire [4:0] _968;
    wire [4:0] _16;
    reg [4:0] _308;
    wire [4:0] _990;
    wire [5:0] _987;
    wire [5:0] _986;
    wire [5:0] _988;
    wire _989;
    wire [4:0] _992;
    wire [4:0] _983;
    wire _977;
    wire [4:0] _979;
    wire [4:0] _980;
    wire _975;
    wire [4:0] _981;
    wire _974;
    wire [4:0] _984;
    wire _973;
    wire [4:0] _993;
    wire [4:0] _994;
    wire [4:0] _995;
    wire [4:0] _996;
    wire [4:0] _17;
    reg [4:0] osr_count;
    wire _1945;
    wire _1943;
    wire _1944;
    wire _1940;
    wire _1941;
    wire _1942;
    wire [15:0] _1926;
    wire [2:0] _1923;
    wire _1924;
    wire [15:0] _1927;
    wire _1920;
    wire [15:0] _1921;
    wire [15:0] _1165;
    wire [31:0] _1166;
    wire [23:0] _1161;
    wire [31:0] _1162;
    wire [27:0] _1157;
    wire [31:0] _1158;
    wire [29:0] _1153;
    wire [31:0] _1154;
    wire [30:0] _1149;
    wire [31:0] _1150;
    wire _1141;
    wire _1138;
    wire _1137;
    wire _1136;
    wire _1135;
    wire _1134;
    wire _1133;
    wire _1132;
    wire _1131;
    reg _1139;
    wire _1142;
    wire [4:0] _1128;
    wire _1129;
    wire _1126;
    wire _1125;
    wire _1124;
    wire _1123;
    wire _1122;
    wire _1121;
    wire _1120;
    wire _1119;
    wire [2:0] _1118;
    reg _1127;
    wire _1130;
    wire [4:0] _1114;
    wire _1115;
    wire _1112;
    wire _1111;
    wire _1110;
    wire _1109;
    wire _1108;
    wire _1107;
    wire _1106;
    wire _1105;
    wire [2:0] _1104;
    reg _1113;
    wire _1116;
    wire [4:0] _1100;
    wire _1101;
    wire _1098;
    wire _1097;
    wire _1096;
    wire _1095;
    wire _1094;
    wire _1093;
    wire _1092;
    wire _1091;
    wire [2:0] _1089;
    wire [2:0] _1090;
    reg _1099;
    wire _1102;
    wire [4:0] _1086;
    wire _1087;
    wire _1084;
    wire _1083;
    wire _1082;
    wire _1081;
    wire _1080;
    wire _1079;
    wire _1078;
    wire _1077;
    wire [2:0] _1076;
    reg _1085;
    wire _1088;
    wire [4:0] _1072;
    wire _1073;
    wire _1070;
    wire _1069;
    wire _1068;
    wire _1067;
    wire _1066;
    wire _1065;
    wire _1064;
    wire _1063;
    wire [2:0] _1061;
    wire [2:0] _1062;
    reg _1071;
    wire _1074;
    wire [4:0] _1058;
    wire _1059;
    wire _1056;
    wire _1055;
    wire _1054;
    wire _1053;
    wire _1052;
    wire _1051;
    wire _1050;
    wire _1049;
    wire [2:0] _1047;
    wire [2:0] _1048;
    reg _1057;
    wire _1060;
    wire _1045;
    wire _1042;
    wire _1041;
    wire _1040;
    wire _1039;
    wire _1038;
    wire _1037;
    wire _1036;
    wire _1035;
    wire [2:0] _1033;
    wire [2:0] _1001;
    wire [6:0] _998;
    wire _999;
    wire _997;
    wire _1000;
    wire [2:0] _1002;
    wire [2:0] _18;
    reg [2:0] _303;
    wire [2:0] _1034;
    reg _1043;
    wire _1046;
    wire [7:0] _1143;
    wire [15:0] _1144;
    wire [1:0] _1031;
    reg [15:0] _1146;
    wire [31:0] _1147;
    wire _1030;
    wire [31:0] _1151;
    wire _1029;
    wire [31:0] _1155;
    wire _1028;
    wire [31:0] _1159;
    wire _1027;
    wire [31:0] _1163;
    wire _1026;
    wire [31:0] _1167;
    wire [15:0] _1168;
    wire [15:0] _1024;
    wire _1006;
    wire [15:0] _1020;
    wire [15:0] _1021;
    wire _1005;
    wire [15:0] _1022;
    wire _1004;
    wire [15:0] _1025;
    wire _1003;
    wire [15:0] _1169;
    wire [15:0] _1170;
    wire [15:0] _1171;
    wire [15:0] _1173;
    wire [15:0] _19;
    reg [15:0] isr;
    wire _853;
    wire _852;
    wire _851;
    wire [1:0] _850;
    reg _854;
    wire _848;
    wire _847;
    wire _846;
    wire [1:0] _845;
    reg _849;
    wire _843;
    wire _842;
    wire _841;
    wire [1:0] _840;
    reg _844;
    wire _838;
    wire _837;
    wire _836;
    wire [1:0] _835;
    reg _839;
    wire _833;
    wire _832;
    wire _831;
    wire [1:0] _830;
    reg _834;
    wire _828;
    wire _827;
    wire _826;
    wire [1:0] _825;
    reg _829;
    wire _823;
    wire _822;
    wire _821;
    wire [1:0] _820;
    reg _824;
    wire _818;
    wire [7:0] _57;
    wire _1775;
    wire _1774;
    wire _1773;
    wire _1772;
    wire _1771;
    wire _1770;
    wire _1769;
    wire _1768;
    reg _1776;
    wire _1767;
    wire [3:0] _1765;
    wire [2:0] _1762;
    wire [3:0] _1763;
    wire _1766;
    wire _1777;
    wire _1758;
    wire _1757;
    wire _1756;
    wire _1755;
    wire _1754;
    wire _1753;
    wire _1752;
    wire _1751;
    reg _1759;
    wire _1750;
    wire [3:0] _1748;
    wire [2:0] _1745;
    wire [3:0] _1746;
    wire _1749;
    wire _1760;
    wire _1741;
    wire _1740;
    wire _1739;
    wire _1738;
    wire _1737;
    wire _1736;
    wire _1735;
    wire _1734;
    reg _1742;
    wire _1733;
    wire [3:0] _1731;
    wire [2:0] _1728;
    wire [3:0] _1729;
    wire _1732;
    wire _1743;
    wire _1724;
    wire _1723;
    wire _1722;
    wire _1721;
    wire _1720;
    wire _1719;
    wire _1718;
    wire _1717;
    reg _1725;
    wire _1716;
    wire [3:0] _1714;
    wire [2:0] _1711;
    wire [3:0] _1712;
    wire _1715;
    wire _1726;
    wire _1707;
    wire _1706;
    wire _1705;
    wire _1704;
    wire _1703;
    wire _1702;
    wire _1701;
    wire _1700;
    reg _1708;
    wire _1699;
    wire [3:0] _1697;
    wire [2:0] _1694;
    wire [3:0] _1695;
    wire _1698;
    wire _1709;
    wire _1690;
    wire _1689;
    wire _1688;
    wire _1687;
    wire _1686;
    wire _1685;
    wire _1684;
    wire _1683;
    reg _1691;
    wire _1682;
    wire [3:0] _1680;
    wire [2:0] _1677;
    wire [3:0] _1678;
    wire _1681;
    wire _1692;
    wire _1673;
    wire _1672;
    wire _1671;
    wire _1670;
    wire _1669;
    wire _1668;
    wire _1667;
    wire _1666;
    reg _1674;
    wire _1665;
    wire [3:0] _1663;
    wire [2:0] _1660;
    wire [3:0] _1661;
    wire _1664;
    wire _1675;
    wire _1656;
    wire _1655;
    wire _1654;
    wire _1653;
    wire _1652;
    wire _1651;
    wire _1650;
    wire [1:0] _1643;
    wire [3:0] _1644;
    wire [2:0] _1639;
    wire [3:0] _1640;
    wire [3:0] _1637;
    wire _1636;
    wire [3:0] _1641;
    wire _1635;
    wire [3:0] _1645;
    wire [2:0] _1632;
    wire [2:0] _1633;
    wire _1634;
    wire [3:0] _1647;
    wire [7:0] _1648;
    wire _1649;
    reg _1657;
    wire _1624;
    wire _1623;
    wire _1622;
    wire _1621;
    wire _1620;
    wire _1619;
    wire _1618;
    wire _1617;
    reg _1625;
    wire _1616;
    wire [2:0] _1613;
    wire [4:0] _1614;
    wire _1615;
    wire _1626;
    wire _1608;
    wire _1607;
    wire _1606;
    wire _1605;
    wire _1604;
    wire _1603;
    wire _1602;
    wire _1601;
    reg _1609;
    wire _1600;
    wire [2:0] _1597;
    wire [4:0] _1598;
    wire _1599;
    wire _1610;
    wire _1592;
    wire _1591;
    wire _1590;
    wire _1589;
    wire _1588;
    wire _1587;
    wire _1586;
    wire _1585;
    reg _1593;
    wire _1584;
    wire [2:0] _1581;
    wire [4:0] _1582;
    wire _1583;
    wire _1594;
    wire _1576;
    wire _1575;
    wire _1574;
    wire _1573;
    wire _1572;
    wire _1571;
    wire _1570;
    wire _1569;
    reg _1577;
    wire _1568;
    wire [2:0] _1565;
    wire [4:0] _1566;
    wire _1567;
    wire _1578;
    wire _1560;
    wire _1559;
    wire _1558;
    wire _1557;
    wire _1556;
    wire _1555;
    wire _1554;
    wire _1553;
    reg _1561;
    wire _1552;
    wire [2:0] _1549;
    wire [4:0] _1550;
    wire _1551;
    wire _1562;
    wire _1544;
    wire _1543;
    wire _1542;
    wire _1541;
    wire _1540;
    wire _1539;
    wire _1538;
    wire _1537;
    reg _1545;
    wire _1536;
    wire [2:0] _1533;
    wire [4:0] _1534;
    wire _1535;
    wire _1546;
    wire _1528;
    wire _1527;
    wire _1526;
    wire _1525;
    wire _1524;
    wire _1523;
    wire _1522;
    wire _1521;
    reg _1529;
    wire _1520;
    wire [2:0] _1517;
    wire [4:0] _1518;
    wire _1519;
    wire _1530;
    wire _1512;
    wire _1511;
    wire _1510;
    wire _1509;
    wire _1508;
    wire _1507;
    wire _1506;
    wire _1505;
    reg _1513;
    wire _1477;
    wire [2:0] _1474;
    wire [4:0] _1475;
    wire _1476;
    wire _1514;
    wire [7:0] _1627;
    wire _1467;
    wire _1466;
    wire _1465;
    wire _1464;
    wire _1463;
    wire _1462;
    wire _1461;
    wire _1460;
    reg _1468;
    wire _1459;
    wire [2:0] _1456;
    wire [3:0] _1457;
    wire _1458;
    wire _1469;
    wire _1452;
    wire _1451;
    wire _1450;
    wire _1449;
    wire _1448;
    wire _1447;
    wire _1446;
    wire _1445;
    reg _1453;
    wire _1444;
    wire [2:0] _1441;
    wire [3:0] _1442;
    wire _1443;
    wire _1454;
    wire _1437;
    wire _1436;
    wire _1435;
    wire _1434;
    wire _1433;
    wire _1432;
    wire _1431;
    wire _1430;
    reg _1438;
    wire _1429;
    wire [2:0] _1426;
    wire [3:0] _1427;
    wire _1428;
    wire _1439;
    wire _1422;
    wire _1421;
    wire _1420;
    wire _1419;
    wire _1418;
    wire _1417;
    wire _1416;
    wire _1415;
    reg _1423;
    wire _1414;
    wire [2:0] _1411;
    wire [3:0] _1412;
    wire _1413;
    wire _1424;
    wire _1407;
    wire _1406;
    wire _1405;
    wire _1404;
    wire _1403;
    wire _1402;
    wire _1401;
    wire _1400;
    reg _1408;
    wire _1399;
    wire [2:0] _1396;
    wire [3:0] _1397;
    wire _1398;
    wire _1409;
    wire _1392;
    wire _1391;
    wire _1390;
    wire _1389;
    wire _1388;
    wire _1387;
    wire _1386;
    wire _1385;
    reg _1393;
    wire _1384;
    wire [2:0] _1381;
    wire [3:0] _1382;
    wire _1383;
    wire _1394;
    wire _1377;
    wire _1376;
    wire _1375;
    wire _1374;
    wire _1373;
    wire _1372;
    wire _1371;
    wire _1370;
    reg _1378;
    wire _1369;
    wire [2:0] _1366;
    wire [3:0] _1367;
    wire _1368;
    wire _1379;
    wire _1362;
    wire _1361;
    wire _1360;
    wire _1359;
    wire _1358;
    wire _1357;
    wire _1356;
    wire _1355;
    reg _1363;
    wire _1354;
    wire [3:0] _1352;
    wire [7:0] _292;
    wire [7:0] _1178;
    wire [6:0] _1175;
    wire _1176;
    wire _1174;
    wire _1177;
    wire [7:0] _1179;
    wire [7:0] _20;
    reg [7:0] _293;
    wire [2:0] _1349;
    wire [2:0] _1350;
    wire [3:0] _1351;
    wire _1353;
    wire _1364;
    wire [7:0] _1470;
    wire _1343;
    wire _1342;
    wire _1341;
    wire _1340;
    wire _1339;
    wire _1338;
    wire _1337;
    wire _1336;
    reg _1344;
    wire _1335;
    wire [2:0] _1332;
    wire [3:0] _1333;
    wire _1334;
    wire _1345;
    wire _1328;
    wire _1327;
    wire _1326;
    wire _1325;
    wire _1324;
    wire _1323;
    wire _1322;
    wire _1321;
    reg _1329;
    wire _1320;
    wire [2:0] _1317;
    wire [3:0] _1318;
    wire _1319;
    wire _1330;
    wire _1313;
    wire _1312;
    wire _1311;
    wire _1310;
    wire _1309;
    wire _1308;
    wire _1307;
    wire _1306;
    reg _1314;
    wire _1305;
    wire [2:0] _1302;
    wire [3:0] _1303;
    wire _1304;
    wire _1315;
    wire _1298;
    wire _1297;
    wire _1296;
    wire _1295;
    wire _1294;
    wire _1293;
    wire _1292;
    wire _1291;
    reg _1299;
    wire _1290;
    wire [2:0] _1287;
    wire [3:0] _1288;
    wire _1289;
    wire _1300;
    wire _1283;
    wire _1282;
    wire _1281;
    wire _1280;
    wire _1279;
    wire _1278;
    wire _1277;
    wire _1276;
    reg _1284;
    wire _1275;
    wire [2:0] _1272;
    wire [3:0] _1273;
    wire _1274;
    wire _1285;
    wire _1268;
    wire _1267;
    wire _1266;
    wire _1265;
    wire _1264;
    wire _1263;
    wire _1262;
    wire _1261;
    reg _1269;
    wire _1260;
    wire [2:0] _1257;
    wire [3:0] _1258;
    wire _1259;
    wire _1270;
    wire _1253;
    wire _1252;
    wire _1251;
    wire _1250;
    wire _1249;
    wire _1248;
    wire _1247;
    wire _1246;
    reg _1254;
    wire _1245;
    wire [2:0] _1242;
    wire [3:0] _1243;
    wire _1244;
    wire _1255;
    wire _1238;
    wire _1237;
    wire _1236;
    wire _1235;
    wire _1234;
    wire _1233;
    wire _1232;
    wire _1231;
    reg _1239;
    wire _1227;
    wire [3:0] _1225;
    wire [7:0] _1184;
    wire [6:0] _1181;
    wire _1182;
    wire _1180;
    wire _1183;
    wire [7:0] _1185;
    wire [7:0] _21;
    reg [7:0] _298;
    wire [2:0] _1222;
    wire [2:0] _1223;
    wire [3:0] _1224;
    wire _1226;
    wire _1240;
    wire [7:0] _1346;
    wire _1219;
    wire _1215;
    wire _1216;
    wire _1220;
    wire [7:0] _1347;
    wire _1211;
    wire _1212;
    wire _1208;
    wire _1209;
    wire _1213;
    wire [7:0] _1471;
    wire [1:0] _1203;
    wire _1205;
    wire _1201;
    wire _1202;
    wire _1206;
    wire [7:0] _1628;
    wire _1629;
    wire [1:0] _1197;
    wire [3:0] _1198;
    wire [5:0] _1190;
    wire [6:0] _1187;
    wire _1188;
    wire _1186;
    wire _1189;
    wire [5:0] _1191;
    wire [5:0] _22;
    reg [5:0] _354;
    wire [2:0] _1193;
    wire [2:0] _1194;
    wire [3:0] _1195;
    wire _1199;
    wire _1658;
    wire [7:0] _1778;
    wire [7:0] _1779;
    wire [7:0] _1780;
    wire [7:0] _23;
    reg [7:0] pin_out;
    wire _817;
    wire [7:0] _25;
    wire _816;
    wire [6:0] _1782;
    wire _1783;
    wire _1781;
    wire _1784;
    wire [15:0] _1785;
    wire [15:0] _26;
    reg [15:0] _50;
    wire [1:0] _815;
    reg _819;
    wire [7:0] _855;
    wire [15:0] _1014;
    wire [15:0] _1899;
    wire _1897;
    wire [15:0] _1900;
    wire [15:0] _1498;
    wire [31:0] _1500;
    wire [23:0] _1494;
    wire [31:0] _1496;
    wire [27:0] _1490;
    wire [31:0] _1492;
    wire [29:0] _1486;
    wire [31:0] _1488;
    wire [31:0] _1484;
    wire [31:0] _1483;
    wire _1482;
    wire [31:0] _1485;
    wire _1481;
    wire [31:0] _1489;
    wire _1480;
    wire [31:0] _1493;
    wire _1479;
    wire [31:0] _1497;
    wire _1478;
    wire [31:0] _1501;
    wire [15:0] _1502;
    wire [15:0] _1503;
    wire [15:0] _1866;
    wire [31:0] _1867;
    wire [23:0] _1862;
    wire [31:0] _1863;
    wire [27:0] _1858;
    wire [31:0] _1859;
    wire [29:0] _1854;
    wire [31:0] _1855;
    wire [30:0] _1850;
    wire [31:0] _1851;
    wire [31:0] _1848;
    wire _1846;
    wire [31:0] _1852;
    wire _1845;
    wire [31:0] _1856;
    wire _1844;
    wire [31:0] _1860;
    wire _1843;
    wire [31:0] _1864;
    wire [4:0] _949;
    wire [3:0] _946;
    wire _948;
    wire [4:0] _951;
    wire _1842;
    wire [31:0] _1868;
    wire [15:0] _1869;
    wire _1836;
    wire _1837;
    reg [15:0] tx_mem_3;
    wire _1830;
    wire _1831;
    reg [15:0] tx_mem_2;
    wire _1824;
    wire _1825;
    reg [15:0] tx_mem_1;
    wire [1:0] _1798;
    wire [1:0] _1799;
    wire [1:0] _27;
    reg [1:0] tx_wr;
    wire _1818;
    wire _1819;
    reg [15:0] tx_mem_0;
    wire [1:0] _1806;
    wire [1:0] _1807;
    wire [1:0] _28;
    reg [1:0] tx_rd;
    reg [15:0] _1839;
    wire _785;
    wire [15:0] _1840;
    wire _1811;
    wire [15:0] _1812;
    wire [15:0] _1813;
    wire _1810;
    wire [15:0] _1814;
    wire _1809;
    wire [15:0] _1841;
    wire _1808;
    wire [15:0] _1870;
    wire [15:0] _1871;
    wire [15:0] _1872;
    wire [15:0] _1874;
    wire [15:0] _29;
    reg [15:0] osr;
    wire [15:0] _1504;
    wire [1:0] _1890;
    wire _1892;
    wire [15:0] _1893;
    wire _1886;
    wire [15:0] _1887;
    wire [15:0] _1888;
    wire _1882;
    wire [15:0] _1883;
    wire _1880;
    wire [15:0] _1884;
    wire _1878;
    wire [15:0] _1889;
    wire _1877;
    wire [15:0] _1894;
    wire _1876;
    wire [15:0] _1901;
    wire [15:0] _1902;
    wire [15:0] _1903;
    wire [15:0] _1905;
    wire [15:0] _30;
    reg [15:0] y;
    reg [15:0] _1019;
    wire _1915;
    wire [15:0] _1916;
    wire [2:0] _931;
    wire _933;
    wire [2:0] _928;
    wire _930;
    wire _934;
    wire [15:0] _1917;
    wire [4:0] _1229;
    wire [15:0] _1230;
    wire [1:0] _1217;
    wire _1911;
    wire [15:0] _1912;
    wire _1909;
    wire [15:0] _1913;
    wire _1908;
    wire [15:0] _1918;
    wire _1907;
    wire [15:0] _1922;
    wire _1906;
    wire [15:0] _1928;
    wire [15:0] _1929;
    wire [15:0] _1930;
    wire [15:0] _1932;
    wire [15:0] _31;
    reg [15:0] x;
    wire _1936;
    wire _1937;
    wire _1938;
    wire [2:0] _1895;
    reg _1947;
    wire _1934;
    wire _1948;
    wire _1954;
    wire [5:0] _1961;
    wire [5:0] _1962;
    wire [5:0] _1963;
    wire [5:0] _1964;
    wire [5:0] _32;
    reg [5:0] pc;
    reg [15:0] _780;
    wire [2:0] _781;
    wire _894;
    wire _896;
    wire _899;
    wire _906;
    wire _912;
    wire _913;
    wire _914;
    wire [3:0] _1975;
    wire _810;
    wire _811;
    wire [3:0] _1978;
    wire _808;
    wire [3:0] _1980;
    wire [3:0] _33;
    reg [3:0] delay_left;
    wire _380;
    wire [15:0] _382;
    wire _1985;
    wire _1983;
    wire _1981;
    wire _1984;
    wire _1986;
    wire _34;
    reg _283;
    wire _381;
    wire _1989;
    wire _1990;
    wire _1992;
    wire _35;
    wire _1801;
    wire [2:0] _2011;
    wire _1791;
    wire _1792;
    wire [6:0] _1787;
    wire [6:0] _393;
    wire _1788;
    wire _264;
    reg _266;
    reg _268;
    wire [22:0] _262;
    wire [22:0] _1993;
    wire [22:0] _1994;
    wire [22:0] _1995;
    wire [22:0] _36;
    reg [22:0] _263;
    wire [23:0] _269;
    wire [7:0] _270;
    wire _260;
    wire [7:0] _1996;
    wire [7:0] _1997;
    wire [7:0] _1998;
    wire [7:0] _37;
    reg [7:0] _390;
    wire _391;
    wire [4:0] _385;
    wire [4:0] _2002;
    wire [4:0] _1999;
    wire _2000;
    wire [4:0] _2003;
    wire [4:0] _2004;
    wire [4:0] _2006;
    wire [4:0] _38;
    reg [4:0] _247;
    wire _386;
    wire _227;
    reg _229;
    reg _231;
    wire _254;
    reg _241;
    wire _252;
    wire vdd;
    wire gnd;
    wire _40;
    wire _42;
    wire [7:0] _44;
    wire _232;
    reg _235;
    reg _237;
    wire _253;
    wire _255;
    wire _387;
    wire _1786;
    wire _1789;
    wire _1793;
    wire [2:0] _2008;
    wire [2:0] _2009;
    wire [2:0] _2012;
    wire [2:0] _45;
    reg [2:0] tx_level;
    wire _2015;
    wire [7:0] _2017;
    assign _122 = pin_out[0:0];
    assign _123 = ~ _122;
    assign _120 = 2'b10;
    assign _121 = _117 == _120;
    assign _124 = _121 & _123;
    assign _118 = 2'b01;
    assign _117 = _50[1:0];
    assign _119 = _117 == _118;
    assign _125 = _119 | _124;
    assign _113 = pin_out[1:1];
    assign _114 = ~ _113;
    assign _112 = _108 == _120;
    assign _115 = _112 & _114;
    assign _108 = _50[3:2];
    assign _110 = _108 == _118;
    assign _116 = _110 | _115;
    assign _104 = pin_out[2:2];
    assign _105 = ~ _104;
    assign _103 = _99 == _120;
    assign _106 = _103 & _105;
    assign _99 = _50[5:4];
    assign _101 = _99 == _118;
    assign _107 = _101 | _106;
    assign _95 = pin_out[3:3];
    assign _96 = ~ _95;
    assign _94 = _90 == _120;
    assign _97 = _94 & _96;
    assign _90 = _50[7:6];
    assign _92 = _90 == _118;
    assign _98 = _92 | _97;
    assign _86 = pin_out[4:4];
    assign _87 = ~ _86;
    assign _85 = _81 == _120;
    assign _88 = _85 & _87;
    assign _81 = _50[9:8];
    assign _83 = _81 == _118;
    assign _89 = _83 | _88;
    assign _77 = pin_out[5:5];
    assign _78 = ~ _77;
    assign _76 = _72 == _120;
    assign _79 = _76 & _78;
    assign _72 = _50[11:10];
    assign _74 = _72 == _118;
    assign _80 = _74 | _79;
    assign _68 = pin_out[6:6];
    assign _69 = ~ _68;
    assign _67 = _63 == _120;
    assign _70 = _67 & _69;
    assign _63 = _50[13:12];
    assign _65 = _63 == _118;
    assign _71 = _65 | _70;
    assign _59 = pin_out[7:7];
    assign _60 = ~ _59;
    assign _55 = _51 == _120;
    assign _61 = _55 & _60;
    assign _51 = _50[15:14];
    assign _53 = _51 == _118;
    assign _62 = _53 | _61;
    assign _126 = { _62,
                    _71,
                    _80,
                    _89,
                    _98,
                    _107,
                    _116,
                    _125 };
    assign _165 = pin_out[0:0];
    assign _162 = _50[1:0];
    assign _164 = _162 == _118;
    assign _166 = _164 & _165;
    assign _160 = pin_out[1:1];
    assign _157 = _50[3:2];
    assign _159 = _157 == _118;
    assign _161 = _159 & _160;
    assign _155 = pin_out[2:2];
    assign _152 = _50[5:4];
    assign _154 = _152 == _118;
    assign _156 = _154 & _155;
    assign _150 = pin_out[3:3];
    assign _147 = _50[7:6];
    assign _149 = _147 == _118;
    assign _151 = _149 & _150;
    assign _145 = pin_out[4:4];
    assign _142 = _50[9:8];
    assign _144 = _142 == _118;
    assign _146 = _144 & _145;
    assign _140 = pin_out[5:5];
    assign _137 = _50[11:10];
    assign _139 = _137 == _118;
    assign _141 = _139 & _140;
    assign _135 = pin_out[6:6];
    assign _132 = _50[13:12];
    assign _134 = _132 == _118;
    assign _136 = _134 & _135;
    assign _130 = pin_out[7:7];
    assign _127 = _50[15:14];
    assign _129 = _127 == _118;
    assign _131 = _129 & _130;
    assign _167 = { _131,
                    _136,
                    _141,
                    _146,
                    _151,
                    _156,
                    _161,
                    _166 };
    assign _257 = 16'b0000000000000000;
    assign _362 = 1'b0;
    assign _361 = _258[14:0];
    assign _363 = { _361,
                    _362 };
    assign _351 = 10'b0000000000;
    assign _355 = { _351,
                    _354 };
    assign _340 = 2'b00;
    assign _347 = { _340,
                    pc,
                    _283,
                    rx_level,
                    gnd,
                    tx_level };
    assign _335 = 2'b11;
    assign _336 = rx_wr == _335;
    assign _337 = _174 & _336;
    always @(posedge _42) begin
        if (_40)
            rx_mem_3 <= _257;
        else
            if (_337)
                rx_mem_3 <= _4;
    end
    assign _330 = rx_wr == _120;
    assign _331 = _174 & _330;
    always @(posedge _42) begin
        if (_40)
            rx_mem_2 <= _257;
        else
            if (_331)
                rx_mem_2 <= _4;
    end
    assign _324 = rx_wr == _118;
    assign _325 = _174 & _324;
    always @(posedge _42) begin
        if (_40)
            rx_mem_1 <= _257;
        else
            if (_325)
                rx_mem_1 <= _4;
    end
    assign _179 = rx_wr + _118;
    assign _180 = _174 ? _179 : rx_wr;
    assign _3 = _180;
    always @(posedge _42) begin
        if (_40)
            rx_wr <= _340;
        else
            rx_wr <= _3;
    end
    assign _318 = rx_wr == _340;
    assign _319 = _174 & _318;
    assign _213 = _211[31:16];
    assign _214 = { _257,
                    _213 };
    assign _209 = _207[31:8];
    assign _208 = 8'b00000000;
    assign _210 = { _208,
                    _209 };
    assign _205 = _203[31:4];
    assign _204 = 4'b0000;
    assign _206 = { _204,
                    _205 };
    assign _201 = _199[31:2];
    assign _202 = { _340,
                    _201 };
    assign _197 = _195[31:1];
    assign _198 = { _362,
                    _197 };
    assign _195 = { _257,
                    isr };
    assign _190 = _185[0:0];
    assign _199 = _190 ? _198 : _195;
    assign _189 = _185[1:1];
    assign _203 = _189 ? _202 : _199;
    assign _188 = _185[2:2];
    assign _207 = _188 ? _206 : _203;
    assign _187 = _185[3:3];
    assign _211 = _187 ? _210 : _207;
    assign _181 = 5'b10000;
    assign _185 = _181 - isr_count;
    assign _186 = _185[4:4];
    assign _215 = _186 ? _214 : _211;
    assign _216 = _215[15:0];
    assign _4 = _216;
    always @(posedge _42) begin
        if (_40)
            rx_mem_0 <= _257;
        else
            if (_319)
                rx_mem_0 <= _4;
    end
    assign _225 = rx_rd + _118;
    assign _226 = _220 ? _225 : rx_rd;
    assign _5 = _226;
    always @(posedge _42) begin
        if (_40)
            rx_rd <= _340;
        else
            rx_rd <= _5;
    end
    always @* begin
        case (rx_rd)
        0:
            _339 <= rx_mem_0;
        1:
            _339 <= rx_mem_1;
        2:
            _339 <= rx_mem_2;
        default:
            _339 <= rx_mem_3;
        endcase
    end
    assign _314 = { _351,
                    _313 };
    assign _305 = 11'b00000000000;
    assign _309 = { _305,
                    _308 };
    assign _300 = 13'b0000000000000;
    assign _304 = { _300,
                    _303 };
    assign _299 = { _208,
                    _298 };
    assign _294 = { _208,
                    _293 };
    assign _289 = { _351,
                    _288 };
    assign _280 = 15'b000000000000000;
    assign _284 = { _280,
                    _283 };
    always @* begin
        case (_271)
        0:
            _356 <= _257;
        1:
            _356 <= _257;
        2:
            _356 <= _257;
        3:
            _356 <= _257;
        4:
            _356 <= _257;
        5:
            _356 <= _257;
        6:
            _356 <= _257;
        7:
            _356 <= _257;
        8:
            _356 <= _257;
        9:
            _356 <= _257;
        10:
            _356 <= _257;
        11:
            _356 <= _257;
        12:
            _356 <= _257;
        13:
            _356 <= _257;
        14:
            _356 <= _257;
        15:
            _356 <= _257;
        16:
            _356 <= _257;
        17:
            _356 <= _257;
        18:
            _356 <= _257;
        19:
            _356 <= _257;
        20:
            _356 <= _257;
        21:
            _356 <= _257;
        22:
            _356 <= _257;
        23:
            _356 <= _257;
        24:
            _356 <= _257;
        25:
            _356 <= _257;
        26:
            _356 <= _257;
        27:
            _356 <= _257;
        28:
            _356 <= _257;
        29:
            _356 <= _257;
        30:
            _356 <= _257;
        31:
            _356 <= _257;
        32:
            _356 <= _257;
        33:
            _356 <= _257;
        34:
            _356 <= _257;
        35:
            _356 <= _257;
        36:
            _356 <= _257;
        37:
            _356 <= _257;
        38:
            _356 <= _257;
        39:
            _356 <= _257;
        40:
            _356 <= _257;
        41:
            _356 <= _257;
        42:
            _356 <= _257;
        43:
            _356 <= _257;
        44:
            _356 <= _257;
        45:
            _356 <= _257;
        46:
            _356 <= _257;
        47:
            _356 <= _257;
        48:
            _356 <= _257;
        49:
            _356 <= _257;
        50:
            _356 <= _257;
        51:
            _356 <= _257;
        52:
            _356 <= _257;
        53:
            _356 <= _257;
        54:
            _356 <= _257;
        55:
            _356 <= _257;
        56:
            _356 <= _257;
        57:
            _356 <= _257;
        58:
            _356 <= _257;
        59:
            _356 <= _257;
        60:
            _356 <= _257;
        61:
            _356 <= _257;
        62:
            _356 <= _257;
        63:
            _356 <= _257;
        64:
            _356 <= _284;
        65:
            _356 <= _289;
        66:
            _356 <= _294;
        67:
            _356 <= _299;
        68:
            _356 <= _304;
        69:
            _356 <= _309;
        70:
            _356 <= _314;
        71:
            _356 <= _50;
        72:
            _356 <= _257;
        73:
            _356 <= _339;
        74:
            _356 <= _347;
        75:
            _356 <= _350;
        76:
            _356 <= _355;
        default:
            _356 <= _257;
        endcase
    end
    assign _277 = ~ _276;
    assign _272 = 7'b1001001;
    assign _273 = _271 == _272;
    assign _278 = _273 & _277;
    assign _358 = _278 ? _257 : _356;
    assign _359 = _260 ? _358 : _258;
    assign _360 = _255 ? _359 : _258;
    assign _248 = 5'b01001;
    assign _249 = _247 < _248;
    assign _250 = ~ _249;
    assign _243 = ~ _231;
    assign _238 = ~ _237;
    assign _242 = _238 & _241;
    assign _244 = _242 & _243;
    assign _251 = _244 & _250;
    assign _364 = _251 ? _363 : _360;
    assign _365 = _231 ? _258 : _364;
    assign _6 = _365;
    always @(posedge _42) begin
        if (_40)
            _258 <= _257;
        else
            _258 <= _6;
    end
    assign _2016 = _258[15:15];
    assign _2014 = 3'b100;
    assign _345 = 3'b000;
    assign _1800 = ~ _904;
    assign _1991 = ~ _904;
    assign _1988 = _781 == _2014;
    assign _1976 = 4'b0001;
    assign _1977 = delay_left - _1976;
    assign _1971 = _1969[3:2];
    assign _1972 = { _340,
                     _1971 };
    assign _1968 = 4'b0111;
    assign _1967 = 4'b1111;
    assign _1966 = _1197[0:0];
    assign _1969 = _1966 ? _1968 : _1967;
    assign _1965 = _1197[1:1];
    assign _1973 = _1965 ? _1972 : _1969;
    assign _1974 = _1637 & _1973;
    assign _218 = rx_level == _345;
    assign _219 = ~ _218;
    assign _275 = rx_level == _345;
    assign _276 = ~ _275;
    assign _271 = _270[6:0];
    assign _373 = _271 == _272;
    assign _369 = _270[7:7];
    assign _370 = ~ _369;
    assign _366 = 5'b00111;
    assign _367 = _247 == _366;
    assign _368 = _255 & _367;
    assign _371 = _368 & _370;
    assign _374 = _371 & _373;
    assign _375 = _374 & _276;
    assign _7 = _375;
    assign _220 = _7 & _219;
    assign _794 = { _340,
                    _220 };
    assign _173 = ~ _172;
    assign _788 = ~ _172;
    assign _786 = ~ _785;
    assign _783 = _781 == _2014;
    assign _784 = _381 & _783;
    assign _787 = _784 & _786;
    assign _789 = _787 & _788;
    assign _8 = _789;
    assign _174 = _8 & _173;
    assign _791 = { _340,
                    _174 };
    assign _792 = rx_level + _791;
    assign _795 = _792 - _794;
    assign _9 = _795;
    always @(posedge _42) begin
        if (_40)
            rx_level <= _345;
        else
            rx_level <= _9;
    end
    assign _172 = rx_level == _2014;
    assign _909 = ~ _785;
    assign _908 = _781 == _2014;
    assign _910 = _908 & _909;
    assign _911 = _910 & _172;
    assign _904 = tx_level == _345;
    assign _901 = _781 == _2014;
    assign _902 = _901 & _785;
    assign _905 = _902 & _904;
    assign _898 = ~ _897;
    assign _895 = ~ _866;
    assign _893 = 3'b001;
    assign _776 = 6'b111111;
    assign _777 = _397 == _776;
    assign _778 = _396 & _777;
    always @(posedge _42) begin
        if (_40)
            prog_63 <= _257;
        else
            if (_778)
                prog_63 <= _382;
    end
    assign _770 = 6'b111110;
    assign _771 = _397 == _770;
    assign _772 = _396 & _771;
    always @(posedge _42) begin
        if (_40)
            prog_62 <= _257;
        else
            if (_772)
                prog_62 <= _382;
    end
    assign _764 = 6'b111101;
    assign _765 = _397 == _764;
    assign _766 = _396 & _765;
    always @(posedge _42) begin
        if (_40)
            prog_61 <= _257;
        else
            if (_766)
                prog_61 <= _382;
    end
    assign _758 = 6'b111100;
    assign _759 = _397 == _758;
    assign _760 = _396 & _759;
    always @(posedge _42) begin
        if (_40)
            prog_60 <= _257;
        else
            if (_760)
                prog_60 <= _382;
    end
    assign _752 = 6'b111011;
    assign _753 = _397 == _752;
    assign _754 = _396 & _753;
    always @(posedge _42) begin
        if (_40)
            prog_59 <= _257;
        else
            if (_754)
                prog_59 <= _382;
    end
    assign _746 = 6'b111010;
    assign _747 = _397 == _746;
    assign _748 = _396 & _747;
    always @(posedge _42) begin
        if (_40)
            prog_58 <= _257;
        else
            if (_748)
                prog_58 <= _382;
    end
    assign _740 = 6'b111001;
    assign _741 = _397 == _740;
    assign _742 = _396 & _741;
    always @(posedge _42) begin
        if (_40)
            prog_57 <= _257;
        else
            if (_742)
                prog_57 <= _382;
    end
    assign _734 = 6'b111000;
    assign _735 = _397 == _734;
    assign _736 = _396 & _735;
    always @(posedge _42) begin
        if (_40)
            prog_56 <= _257;
        else
            if (_736)
                prog_56 <= _382;
    end
    assign _728 = 6'b110111;
    assign _729 = _397 == _728;
    assign _730 = _396 & _729;
    always @(posedge _42) begin
        if (_40)
            prog_55 <= _257;
        else
            if (_730)
                prog_55 <= _382;
    end
    assign _722 = 6'b110110;
    assign _723 = _397 == _722;
    assign _724 = _396 & _723;
    always @(posedge _42) begin
        if (_40)
            prog_54 <= _257;
        else
            if (_724)
                prog_54 <= _382;
    end
    assign _716 = 6'b110101;
    assign _717 = _397 == _716;
    assign _718 = _396 & _717;
    always @(posedge _42) begin
        if (_40)
            prog_53 <= _257;
        else
            if (_718)
                prog_53 <= _382;
    end
    assign _710 = 6'b110100;
    assign _711 = _397 == _710;
    assign _712 = _396 & _711;
    always @(posedge _42) begin
        if (_40)
            prog_52 <= _257;
        else
            if (_712)
                prog_52 <= _382;
    end
    assign _704 = 6'b110011;
    assign _705 = _397 == _704;
    assign _706 = _396 & _705;
    always @(posedge _42) begin
        if (_40)
            prog_51 <= _257;
        else
            if (_706)
                prog_51 <= _382;
    end
    assign _698 = 6'b110010;
    assign _699 = _397 == _698;
    assign _700 = _396 & _699;
    always @(posedge _42) begin
        if (_40)
            prog_50 <= _257;
        else
            if (_700)
                prog_50 <= _382;
    end
    assign _692 = 6'b110001;
    assign _693 = _397 == _692;
    assign _694 = _396 & _693;
    always @(posedge _42) begin
        if (_40)
            prog_49 <= _257;
        else
            if (_694)
                prog_49 <= _382;
    end
    assign _686 = 6'b110000;
    assign _687 = _397 == _686;
    assign _688 = _396 & _687;
    always @(posedge _42) begin
        if (_40)
            prog_48 <= _257;
        else
            if (_688)
                prog_48 <= _382;
    end
    assign _680 = 6'b101111;
    assign _681 = _397 == _680;
    assign _682 = _396 & _681;
    always @(posedge _42) begin
        if (_40)
            prog_47 <= _257;
        else
            if (_682)
                prog_47 <= _382;
    end
    assign _674 = 6'b101110;
    assign _675 = _397 == _674;
    assign _676 = _396 & _675;
    always @(posedge _42) begin
        if (_40)
            prog_46 <= _257;
        else
            if (_676)
                prog_46 <= _382;
    end
    assign _668 = 6'b101101;
    assign _669 = _397 == _668;
    assign _670 = _396 & _669;
    always @(posedge _42) begin
        if (_40)
            prog_45 <= _257;
        else
            if (_670)
                prog_45 <= _382;
    end
    assign _662 = 6'b101100;
    assign _663 = _397 == _662;
    assign _664 = _396 & _663;
    always @(posedge _42) begin
        if (_40)
            prog_44 <= _257;
        else
            if (_664)
                prog_44 <= _382;
    end
    assign _656 = 6'b101011;
    assign _657 = _397 == _656;
    assign _658 = _396 & _657;
    always @(posedge _42) begin
        if (_40)
            prog_43 <= _257;
        else
            if (_658)
                prog_43 <= _382;
    end
    assign _650 = 6'b101010;
    assign _651 = _397 == _650;
    assign _652 = _396 & _651;
    always @(posedge _42) begin
        if (_40)
            prog_42 <= _257;
        else
            if (_652)
                prog_42 <= _382;
    end
    assign _644 = 6'b101001;
    assign _645 = _397 == _644;
    assign _646 = _396 & _645;
    always @(posedge _42) begin
        if (_40)
            prog_41 <= _257;
        else
            if (_646)
                prog_41 <= _382;
    end
    assign _638 = 6'b101000;
    assign _639 = _397 == _638;
    assign _640 = _396 & _639;
    always @(posedge _42) begin
        if (_40)
            prog_40 <= _257;
        else
            if (_640)
                prog_40 <= _382;
    end
    assign _632 = 6'b100111;
    assign _633 = _397 == _632;
    assign _634 = _396 & _633;
    always @(posedge _42) begin
        if (_40)
            prog_39 <= _257;
        else
            if (_634)
                prog_39 <= _382;
    end
    assign _626 = 6'b100110;
    assign _627 = _397 == _626;
    assign _628 = _396 & _627;
    always @(posedge _42) begin
        if (_40)
            prog_38 <= _257;
        else
            if (_628)
                prog_38 <= _382;
    end
    assign _620 = 6'b100101;
    assign _621 = _397 == _620;
    assign _622 = _396 & _621;
    always @(posedge _42) begin
        if (_40)
            prog_37 <= _257;
        else
            if (_622)
                prog_37 <= _382;
    end
    assign _614 = 6'b100100;
    assign _615 = _397 == _614;
    assign _616 = _396 & _615;
    always @(posedge _42) begin
        if (_40)
            prog_36 <= _257;
        else
            if (_616)
                prog_36 <= _382;
    end
    assign _608 = 6'b100011;
    assign _609 = _397 == _608;
    assign _610 = _396 & _609;
    always @(posedge _42) begin
        if (_40)
            prog_35 <= _257;
        else
            if (_610)
                prog_35 <= _382;
    end
    assign _602 = 6'b100010;
    assign _603 = _397 == _602;
    assign _604 = _396 & _603;
    always @(posedge _42) begin
        if (_40)
            prog_34 <= _257;
        else
            if (_604)
                prog_34 <= _382;
    end
    assign _596 = 6'b100001;
    assign _597 = _397 == _596;
    assign _598 = _396 & _597;
    always @(posedge _42) begin
        if (_40)
            prog_33 <= _257;
        else
            if (_598)
                prog_33 <= _382;
    end
    assign _590 = 6'b100000;
    assign _591 = _397 == _590;
    assign _592 = _396 & _591;
    always @(posedge _42) begin
        if (_40)
            prog_32 <= _257;
        else
            if (_592)
                prog_32 <= _382;
    end
    assign _584 = 6'b011111;
    assign _585 = _397 == _584;
    assign _586 = _396 & _585;
    always @(posedge _42) begin
        if (_40)
            prog_31 <= _257;
        else
            if (_586)
                prog_31 <= _382;
    end
    assign _578 = 6'b011110;
    assign _579 = _397 == _578;
    assign _580 = _396 & _579;
    always @(posedge _42) begin
        if (_40)
            prog_30 <= _257;
        else
            if (_580)
                prog_30 <= _382;
    end
    assign _572 = 6'b011101;
    assign _573 = _397 == _572;
    assign _574 = _396 & _573;
    always @(posedge _42) begin
        if (_40)
            prog_29 <= _257;
        else
            if (_574)
                prog_29 <= _382;
    end
    assign _566 = 6'b011100;
    assign _567 = _397 == _566;
    assign _568 = _396 & _567;
    always @(posedge _42) begin
        if (_40)
            prog_28 <= _257;
        else
            if (_568)
                prog_28 <= _382;
    end
    assign _560 = 6'b011011;
    assign _561 = _397 == _560;
    assign _562 = _396 & _561;
    always @(posedge _42) begin
        if (_40)
            prog_27 <= _257;
        else
            if (_562)
                prog_27 <= _382;
    end
    assign _554 = 6'b011010;
    assign _555 = _397 == _554;
    assign _556 = _396 & _555;
    always @(posedge _42) begin
        if (_40)
            prog_26 <= _257;
        else
            if (_556)
                prog_26 <= _382;
    end
    assign _548 = 6'b011001;
    assign _549 = _397 == _548;
    assign _550 = _396 & _549;
    always @(posedge _42) begin
        if (_40)
            prog_25 <= _257;
        else
            if (_550)
                prog_25 <= _382;
    end
    assign _542 = 6'b011000;
    assign _543 = _397 == _542;
    assign _544 = _396 & _543;
    always @(posedge _42) begin
        if (_40)
            prog_24 <= _257;
        else
            if (_544)
                prog_24 <= _382;
    end
    assign _536 = 6'b010111;
    assign _537 = _397 == _536;
    assign _538 = _396 & _537;
    always @(posedge _42) begin
        if (_40)
            prog_23 <= _257;
        else
            if (_538)
                prog_23 <= _382;
    end
    assign _530 = 6'b010110;
    assign _531 = _397 == _530;
    assign _532 = _396 & _531;
    always @(posedge _42) begin
        if (_40)
            prog_22 <= _257;
        else
            if (_532)
                prog_22 <= _382;
    end
    assign _524 = 6'b010101;
    assign _525 = _397 == _524;
    assign _526 = _396 & _525;
    always @(posedge _42) begin
        if (_40)
            prog_21 <= _257;
        else
            if (_526)
                prog_21 <= _382;
    end
    assign _518 = 6'b010100;
    assign _519 = _397 == _518;
    assign _520 = _396 & _519;
    always @(posedge _42) begin
        if (_40)
            prog_20 <= _257;
        else
            if (_520)
                prog_20 <= _382;
    end
    assign _512 = 6'b010011;
    assign _513 = _397 == _512;
    assign _514 = _396 & _513;
    always @(posedge _42) begin
        if (_40)
            prog_19 <= _257;
        else
            if (_514)
                prog_19 <= _382;
    end
    assign _506 = 6'b010010;
    assign _507 = _397 == _506;
    assign _508 = _396 & _507;
    always @(posedge _42) begin
        if (_40)
            prog_18 <= _257;
        else
            if (_508)
                prog_18 <= _382;
    end
    assign _500 = 6'b010001;
    assign _501 = _397 == _500;
    assign _502 = _396 & _501;
    always @(posedge _42) begin
        if (_40)
            prog_17 <= _257;
        else
            if (_502)
                prog_17 <= _382;
    end
    assign _494 = 6'b010000;
    assign _495 = _397 == _494;
    assign _496 = _396 & _495;
    always @(posedge _42) begin
        if (_40)
            prog_16 <= _257;
        else
            if (_496)
                prog_16 <= _382;
    end
    assign _488 = 6'b001111;
    assign _489 = _397 == _488;
    assign _490 = _396 & _489;
    always @(posedge _42) begin
        if (_40)
            prog_15 <= _257;
        else
            if (_490)
                prog_15 <= _382;
    end
    assign _482 = 6'b001110;
    assign _483 = _397 == _482;
    assign _484 = _396 & _483;
    always @(posedge _42) begin
        if (_40)
            prog_14 <= _257;
        else
            if (_484)
                prog_14 <= _382;
    end
    assign _476 = 6'b001101;
    assign _477 = _397 == _476;
    assign _478 = _396 & _477;
    always @(posedge _42) begin
        if (_40)
            prog_13 <= _257;
        else
            if (_478)
                prog_13 <= _382;
    end
    assign _470 = 6'b001100;
    assign _471 = _397 == _470;
    assign _472 = _396 & _471;
    always @(posedge _42) begin
        if (_40)
            prog_12 <= _257;
        else
            if (_472)
                prog_12 <= _382;
    end
    assign _464 = 6'b001011;
    assign _465 = _397 == _464;
    assign _466 = _396 & _465;
    always @(posedge _42) begin
        if (_40)
            prog_11 <= _257;
        else
            if (_466)
                prog_11 <= _382;
    end
    assign _458 = 6'b001010;
    assign _459 = _397 == _458;
    assign _460 = _396 & _459;
    always @(posedge _42) begin
        if (_40)
            prog_10 <= _257;
        else
            if (_460)
                prog_10 <= _382;
    end
    assign _452 = 6'b001001;
    assign _453 = _397 == _452;
    assign _454 = _396 & _453;
    always @(posedge _42) begin
        if (_40)
            prog_9 <= _257;
        else
            if (_454)
                prog_9 <= _382;
    end
    assign _446 = 6'b001000;
    assign _447 = _397 == _446;
    assign _448 = _396 & _447;
    always @(posedge _42) begin
        if (_40)
            prog_8 <= _257;
        else
            if (_448)
                prog_8 <= _382;
    end
    assign _440 = 6'b000111;
    assign _441 = _397 == _440;
    assign _442 = _396 & _441;
    always @(posedge _42) begin
        if (_40)
            prog_7 <= _257;
        else
            if (_442)
                prog_7 <= _382;
    end
    assign _434 = 6'b000110;
    assign _435 = _397 == _434;
    assign _436 = _396 & _435;
    always @(posedge _42) begin
        if (_40)
            prog_6 <= _257;
        else
            if (_436)
                prog_6 <= _382;
    end
    assign _428 = 6'b000101;
    assign _429 = _397 == _428;
    assign _430 = _396 & _429;
    always @(posedge _42) begin
        if (_40)
            prog_5 <= _257;
        else
            if (_430)
                prog_5 <= _382;
    end
    assign _422 = 6'b000100;
    assign _423 = _397 == _422;
    assign _424 = _396 & _423;
    always @(posedge _42) begin
        if (_40)
            prog_4 <= _257;
        else
            if (_424)
                prog_4 <= _382;
    end
    assign _416 = 6'b000011;
    assign _417 = _397 == _416;
    assign _418 = _396 & _417;
    always @(posedge _42) begin
        if (_40)
            prog_3 <= _257;
        else
            if (_418)
                prog_3 <= _382;
    end
    assign _410 = 6'b000010;
    assign _411 = _397 == _410;
    assign _412 = _396 & _411;
    always @(posedge _42) begin
        if (_40)
            prog_2 <= _257;
        else
            if (_412)
                prog_2 <= _382;
    end
    assign _404 = 6'b000001;
    assign _405 = _397 == _404;
    assign _406 = _396 & _405;
    always @(posedge _42) begin
        if (_40)
            prog_1 <= _257;
        else
            if (_406)
                prog_1 <= _382;
    end
    assign _398 = 6'b000000;
    assign _397 = _393[5:0];
    assign _399 = _397 == _398;
    assign _394 = 7'b1000000;
    assign _395 = _393 < _394;
    assign _392 = _387 & _391;
    assign _396 = _392 & _395;
    assign _400 = _396 & _399;
    always @(posedge _42) begin
        if (_40)
            prog_0 <= _257;
        else
            if (_400)
                prog_0 <= _382;
    end
    assign _800 = _382[5:0];
    assign _797 = 7'b1000001;
    assign _798 = _393 == _797;
    assign _796 = _387 & _391;
    assign _799 = _796 & _798;
    assign _801 = _799 ? _800 : _288;
    assign _10 = _801;
    always @(posedge _42) begin
        if (_40)
            _288 <= _398;
        else
            _288 <= _10;
    end
    assign _1959 = _780[5:0];
    assign _806 = _382[5:0];
    assign _803 = 7'b1000110;
    assign _804 = _393 == _803;
    assign _802 = _387 & _391;
    assign _805 = _802 & _804;
    assign _807 = _805 ? _806 : _313;
    assign _11 = _807;
    always @(posedge _42) begin
        if (_40)
            _313 <= _398;
        else
            _313 <= _11;
    end
    assign _1958 = _781 == _345;
    assign _1960 = _1958 ? _1959 : _313;
    assign _1956 = pc + _404;
    assign _882 = 16'b0000000000000001;
    assign _883 = _877 - _882;
    assign _884 = _881 ? _883 : wait_count;
    assign _885 = _811 ? wait_count : _884;
    assign _887 = _808 ? _257 : _885;
    assign _12 = _887;
    always @(posedge _42) begin
        if (_40)
            wait_count <= _257;
        else
            wait_count <= _12;
    end
    assign _889 = 7'b1001011;
    assign _890 = _393 == _889;
    assign _888 = _387 & _391;
    assign _891 = _888 & _890;
    assign _892 = _891 ? _382 : _350;
    assign _13 = _892;
    always @(posedge _42) begin
        if (_40)
            _350 <= _257;
        else
            _350 <= _13;
    end
    assign _915 = 1'b1;
    assign _880 = ~ _879;
    assign _867 = ~ _866;
    assign _813 = _781 == _893;
    assign _868 = _813 & _867;
    assign _870 = _868 & _869;
    assign _881 = _870 & _880;
    assign _916 = _881 ? _915 : waiting;
    assign _918 = _914 ? _362 : _916;
    assign _919 = _811 ? waiting : _918;
    assign _921 = _808 ? _362 : _919;
    assign _14 = _921;
    always @(posedge _42) begin
        if (_40)
            waiting <= _362;
        else
            waiting <= _14;
    end
    assign _877 = waiting ? wait_count : _350;
    assign _879 = _877 == _257;
    assign _869 = _780[4:4];
    assign _897 = _869 & _879;
    assign _865 = _780[8:8];
    assign _863 = _855[7:7];
    assign _862 = _855[6:6];
    assign _861 = _855[5:5];
    assign _860 = _855[4:4];
    assign _859 = _855[3:3];
    assign _858 = _855[2:2];
    assign _857 = _855[1:1];
    assign _856 = _855[0:0];
    assign _814 = _780[7:5];
    always @* begin
        case (_814)
        0:
            _864 <= _856;
        1:
            _864 <= _857;
        2:
            _864 <= _858;
        3:
            _864 <= _859;
        4:
            _864 <= _860;
        5:
            _864 <= _861;
        6:
            _864 <= _862;
        default:
            _864 <= _863;
        endcase
    end
    assign _866 = _864 == _865;
    assign _1951 = ~ _866;
    assign _1950 = _781 == _893;
    assign _1952 = _1950 & _1951;
    assign _1953 = _1952 & _897;
    assign _183 = 5'b00000;
    assign _955 = _953[4:0];
    assign _952 = { gnd,
                    _951 };
    assign _945 = { gnd,
                    isr_count };
    assign _953 = _945 + _952;
    assign _954 = _494 < _953;
    assign _957 = _954 ? _181 : _955;
    assign _942 = _785 ? isr_count : _183;
    assign _936 = _928 == _1089;
    assign _938 = _936 ? _183 : isr_count;
    assign _939 = _934 ? _938 : isr_count;
    assign _927 = _781 == _1061;
    assign _940 = _927 ? _939 : isr_count;
    assign _925 = _781 == _2014;
    assign _943 = _925 ? _942 : _940;
    assign _923 = _781 == _1923;
    assign _958 = _923 ? _957 : _943;
    assign _959 = _914 ? _958 : isr_count;
    assign _960 = _811 ? isr_count : _959;
    assign _962 = _808 ? _183 : _960;
    assign _15 = _962;
    always @(posedge _42) begin
        if (_40)
            isr_count <= _183;
        else
            isr_count <= _15;
    end
    assign _1946 = isr_count < _308;
    assign _307 = 5'b01000;
    assign _967 = _382[4:0];
    assign _964 = 7'b1000101;
    assign _965 = _393 == _964;
    assign _963 = _387 & _391;
    assign _966 = _963 & _965;
    assign _968 = _966 ? _967 : _308;
    assign _16 = _968;
    always @(posedge _42) begin
        if (_40)
            _308 <= _307;
        else
            _308 <= _16;
    end
    assign _990 = _988[4:0];
    assign _987 = { gnd,
                    _951 };
    assign _986 = { gnd,
                    osr_count };
    assign _988 = _986 + _987;
    assign _989 = _494 < _988;
    assign _992 = _989 ? _181 : _990;
    assign _983 = _785 ? _183 : osr_count;
    assign _977 = _928 == _2014;
    assign _979 = _977 ? _183 : osr_count;
    assign _980 = _934 ? _979 : osr_count;
    assign _975 = _781 == _1061;
    assign _981 = _975 ? _980 : osr_count;
    assign _974 = _781 == _2014;
    assign _984 = _974 ? _983 : _981;
    assign _973 = _781 == _1089;
    assign _993 = _973 ? _992 : _984;
    assign _994 = _914 ? _993 : osr_count;
    assign _995 = _811 ? osr_count : _994;
    assign _996 = _808 ? _308 : _995;
    assign _17 = _996;
    always @(posedge _42) begin
        if (_40)
            osr_count <= _183;
        else
            osr_count <= _17;
    end
    assign _1945 = osr_count < _308;
    assign _1943 = x == y;
    assign _1944 = ~ _1943;
    assign _1940 = y == _257;
    assign _1941 = ~ _1940;
    assign _1942 = ~ _1941;
    assign _1926 = x - _882;
    assign _1923 = 3'b010;
    assign _1924 = _1895 == _1923;
    assign _1927 = _1924 ? _1926 : x;
    assign _1920 = _1890 == _118;
    assign _1921 = _1920 ? _1504 : x;
    assign _1165 = _1163[31:16];
    assign _1166 = { _257,
                     _1165 };
    assign _1161 = _1159[31:8];
    assign _1162 = { _208,
                     _1161 };
    assign _1157 = _1155[31:4];
    assign _1158 = { _204,
                     _1157 };
    assign _1153 = _1151[31:2];
    assign _1154 = { _340,
                     _1153 };
    assign _1149 = _1147[31:1];
    assign _1150 = { _362,
                     _1149 };
    assign _1141 = _183 < _951;
    assign _1138 = _855[7:7];
    assign _1137 = _855[6:6];
    assign _1136 = _855[5:5];
    assign _1135 = _855[4:4];
    assign _1134 = _855[3:3];
    assign _1133 = _855[2:2];
    assign _1132 = _855[1:1];
    assign _1131 = _855[0:0];
    always @* begin
        case (_303)
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
    assign _1128 = 5'b00001;
    assign _1129 = _1128 < _951;
    assign _1126 = _855[7:7];
    assign _1125 = _855[6:6];
    assign _1124 = _855[5:5];
    assign _1123 = _855[4:4];
    assign _1122 = _855[3:3];
    assign _1121 = _855[2:2];
    assign _1120 = _855[1:1];
    assign _1119 = _855[0:0];
    assign _1118 = _303 + _893;
    always @* begin
        case (_1118)
        0:
            _1127 <= _1119;
        1:
            _1127 <= _1120;
        2:
            _1127 <= _1121;
        3:
            _1127 <= _1122;
        4:
            _1127 <= _1123;
        5:
            _1127 <= _1124;
        6:
            _1127 <= _1125;
        default:
            _1127 <= _1126;
        endcase
    end
    assign _1130 = _1127 & _1129;
    assign _1114 = 5'b00010;
    assign _1115 = _1114 < _951;
    assign _1112 = _855[7:7];
    assign _1111 = _855[6:6];
    assign _1110 = _855[5:5];
    assign _1109 = _855[4:4];
    assign _1108 = _855[3:3];
    assign _1107 = _855[2:2];
    assign _1106 = _855[1:1];
    assign _1105 = _855[0:0];
    assign _1104 = _303 + _1923;
    always @* begin
        case (_1104)
        0:
            _1113 <= _1105;
        1:
            _1113 <= _1106;
        2:
            _1113 <= _1107;
        3:
            _1113 <= _1108;
        4:
            _1113 <= _1109;
        5:
            _1113 <= _1110;
        6:
            _1113 <= _1111;
        default:
            _1113 <= _1112;
        endcase
    end
    assign _1116 = _1113 & _1115;
    assign _1100 = 5'b00011;
    assign _1101 = _1100 < _951;
    assign _1098 = _855[7:7];
    assign _1097 = _855[6:6];
    assign _1096 = _855[5:5];
    assign _1095 = _855[4:4];
    assign _1094 = _855[3:3];
    assign _1093 = _855[2:2];
    assign _1092 = _855[1:1];
    assign _1091 = _855[0:0];
    assign _1089 = 3'b011;
    assign _1090 = _303 + _1089;
    always @* begin
        case (_1090)
        0:
            _1099 <= _1091;
        1:
            _1099 <= _1092;
        2:
            _1099 <= _1093;
        3:
            _1099 <= _1094;
        4:
            _1099 <= _1095;
        5:
            _1099 <= _1096;
        6:
            _1099 <= _1097;
        default:
            _1099 <= _1098;
        endcase
    end
    assign _1102 = _1099 & _1101;
    assign _1086 = 5'b00100;
    assign _1087 = _1086 < _951;
    assign _1084 = _855[7:7];
    assign _1083 = _855[6:6];
    assign _1082 = _855[5:5];
    assign _1081 = _855[4:4];
    assign _1080 = _855[3:3];
    assign _1079 = _855[2:2];
    assign _1078 = _855[1:1];
    assign _1077 = _855[0:0];
    assign _1076 = _303 + _2014;
    always @* begin
        case (_1076)
        0:
            _1085 <= _1077;
        1:
            _1085 <= _1078;
        2:
            _1085 <= _1079;
        3:
            _1085 <= _1080;
        4:
            _1085 <= _1081;
        5:
            _1085 <= _1082;
        6:
            _1085 <= _1083;
        default:
            _1085 <= _1084;
        endcase
    end
    assign _1088 = _1085 & _1087;
    assign _1072 = 5'b00101;
    assign _1073 = _1072 < _951;
    assign _1070 = _855[7:7];
    assign _1069 = _855[6:6];
    assign _1068 = _855[5:5];
    assign _1067 = _855[4:4];
    assign _1066 = _855[3:3];
    assign _1065 = _855[2:2];
    assign _1064 = _855[1:1];
    assign _1063 = _855[0:0];
    assign _1061 = 3'b101;
    assign _1062 = _303 + _1061;
    always @* begin
        case (_1062)
        0:
            _1071 <= _1063;
        1:
            _1071 <= _1064;
        2:
            _1071 <= _1065;
        3:
            _1071 <= _1066;
        4:
            _1071 <= _1067;
        5:
            _1071 <= _1068;
        6:
            _1071 <= _1069;
        default:
            _1071 <= _1070;
        endcase
    end
    assign _1074 = _1071 & _1073;
    assign _1058 = 5'b00110;
    assign _1059 = _1058 < _951;
    assign _1056 = _855[7:7];
    assign _1055 = _855[6:6];
    assign _1054 = _855[5:5];
    assign _1053 = _855[4:4];
    assign _1052 = _855[3:3];
    assign _1051 = _855[2:2];
    assign _1050 = _855[1:1];
    assign _1049 = _855[0:0];
    assign _1047 = 3'b110;
    assign _1048 = _303 + _1047;
    always @* begin
        case (_1048)
        0:
            _1057 <= _1049;
        1:
            _1057 <= _1050;
        2:
            _1057 <= _1051;
        3:
            _1057 <= _1052;
        4:
            _1057 <= _1053;
        5:
            _1057 <= _1054;
        6:
            _1057 <= _1055;
        default:
            _1057 <= _1056;
        endcase
    end
    assign _1060 = _1057 & _1059;
    assign _1045 = _366 < _951;
    assign _1042 = _855[7:7];
    assign _1041 = _855[6:6];
    assign _1040 = _855[5:5];
    assign _1039 = _855[4:4];
    assign _1038 = _855[3:3];
    assign _1037 = _855[2:2];
    assign _1036 = _855[1:1];
    assign _1035 = _855[0:0];
    assign _1033 = 3'b111;
    assign _1001 = _382[2:0];
    assign _998 = 7'b1000100;
    assign _999 = _393 == _998;
    assign _997 = _387 & _391;
    assign _1000 = _997 & _999;
    assign _1002 = _1000 ? _1001 : _303;
    assign _18 = _1002;
    always @(posedge _42) begin
        if (_40)
            _303 <= _345;
        else
            _303 <= _18;
    end
    assign _1034 = _303 + _1033;
    always @* begin
        case (_1034)
        0:
            _1043 <= _1035;
        1:
            _1043 <= _1036;
        2:
            _1043 <= _1037;
        3:
            _1043 <= _1038;
        4:
            _1043 <= _1039;
        5:
            _1043 <= _1040;
        6:
            _1043 <= _1041;
        default:
            _1043 <= _1042;
        endcase
    end
    assign _1046 = _1043 & _1045;
    assign _1143 = { _1046,
                     _1060,
                     _1074,
                     _1088,
                     _1102,
                     _1116,
                     _1130,
                     _1142 };
    assign _1144 = { _208,
                     _1143 };
    assign _1031 = _780[8:7];
    always @* begin
        case (_1031)
        0:
            _1146 <= _1144;
        1:
            _1146 <= x;
        2:
            _1146 <= y;
        default:
            _1146 <= _257;
        endcase
    end
    assign _1147 = { _1146,
                     isr };
    assign _1030 = _951[0:0];
    assign _1151 = _1030 ? _1150 : _1147;
    assign _1029 = _951[1:1];
    assign _1155 = _1029 ? _1154 : _1151;
    assign _1028 = _951[2:2];
    assign _1159 = _1028 ? _1158 : _1155;
    assign _1027 = _951[3:3];
    assign _1163 = _1027 ? _1162 : _1159;
    assign _1026 = _951[4:4];
    assign _1167 = _1026 ? _1166 : _1163;
    assign _1168 = _1167[15:0];
    assign _1024 = _785 ? isr : _257;
    assign _1006 = _928 == _1089;
    assign _1020 = _1006 ? _1019 : isr;
    assign _1021 = _934 ? _1020 : isr;
    assign _1005 = _781 == _1061;
    assign _1022 = _1005 ? _1021 : isr;
    assign _1004 = _781 == _2014;
    assign _1025 = _1004 ? _1024 : _1022;
    assign _1003 = _781 == _1923;
    assign _1169 = _1003 ? _1168 : _1025;
    assign _1170 = _914 ? _1169 : isr;
    assign _1171 = _811 ? isr : _1170;
    assign _1173 = _808 ? _257 : _1171;
    assign _19 = _1173;
    always @(posedge _42) begin
        if (_40)
            isr <= _257;
        else
            isr <= _19;
    end
    assign _853 = _852 & _851;
    assign _852 = pin_out[0:0];
    assign _851 = _25[0:0];
    assign _850 = _50[1:0];
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
    assign _848 = _847 & _846;
    assign _847 = pin_out[1:1];
    assign _846 = _25[1:1];
    assign _845 = _50[3:2];
    always @* begin
        case (_845)
        0:
            _849 <= _846;
        1:
            _849 <= _847;
        2:
            _849 <= _848;
        default:
            _849 <= _846;
        endcase
    end
    assign _843 = _842 & _841;
    assign _842 = pin_out[2:2];
    assign _841 = _25[2:2];
    assign _840 = _50[5:4];
    always @* begin
        case (_840)
        0:
            _844 <= _841;
        1:
            _844 <= _842;
        2:
            _844 <= _843;
        default:
            _844 <= _841;
        endcase
    end
    assign _838 = _837 & _836;
    assign _837 = pin_out[3:3];
    assign _836 = _25[3:3];
    assign _835 = _50[7:6];
    always @* begin
        case (_835)
        0:
            _839 <= _836;
        1:
            _839 <= _837;
        2:
            _839 <= _838;
        default:
            _839 <= _836;
        endcase
    end
    assign _833 = _832 & _831;
    assign _832 = pin_out[4:4];
    assign _831 = _25[4:4];
    assign _830 = _50[9:8];
    always @* begin
        case (_830)
        0:
            _834 <= _831;
        1:
            _834 <= _832;
        2:
            _834 <= _833;
        default:
            _834 <= _831;
        endcase
    end
    assign _828 = _827 & _826;
    assign _827 = pin_out[5:5];
    assign _826 = _25[5:5];
    assign _825 = _50[11:10];
    always @* begin
        case (_825)
        0:
            _829 <= _826;
        1:
            _829 <= _827;
        2:
            _829 <= _828;
        default:
            _829 <= _826;
        endcase
    end
    assign _823 = _822 & _821;
    assign _822 = pin_out[6:6];
    assign _821 = _25[6:6];
    assign _820 = _50[13:12];
    always @* begin
        case (_820)
        0:
            _824 <= _821;
        1:
            _824 <= _822;
        2:
            _824 <= _823;
        default:
            _824 <= _821;
        endcase
    end
    assign _818 = _817 & _816;
    assign _57 = 8'b11111111;
    assign _1775 = _1648[7:7];
    assign _1774 = _1648[6:6];
    assign _1773 = _1648[5:5];
    assign _1772 = _1648[4:4];
    assign _1771 = _1648[3:3];
    assign _1770 = _1648[2:2];
    assign _1769 = _1648[1:1];
    assign _1768 = _1648[0:0];
    always @* begin
        case (_1762)
        0:
            _1776 <= _1768;
        1:
            _1776 <= _1769;
        2:
            _1776 <= _1770;
        3:
            _1776 <= _1771;
        4:
            _1776 <= _1772;
        5:
            _1776 <= _1773;
        6:
            _1776 <= _1774;
        default:
            _1776 <= _1775;
        endcase
    end
    assign _1767 = _1628[0:0];
    assign _1765 = { _340,
                     _1197 };
    assign _1762 = _345 - _1193;
    assign _1763 = { gnd,
                     _1762 };
    assign _1766 = _1763 < _1765;
    assign _1777 = _1766 ? _1776 : _1767;
    assign _1758 = _1648[7:7];
    assign _1757 = _1648[6:6];
    assign _1756 = _1648[5:5];
    assign _1755 = _1648[4:4];
    assign _1754 = _1648[3:3];
    assign _1753 = _1648[2:2];
    assign _1752 = _1648[1:1];
    assign _1751 = _1648[0:0];
    always @* begin
        case (_1745)
        0:
            _1759 <= _1751;
        1:
            _1759 <= _1752;
        2:
            _1759 <= _1753;
        3:
            _1759 <= _1754;
        4:
            _1759 <= _1755;
        5:
            _1759 <= _1756;
        6:
            _1759 <= _1757;
        default:
            _1759 <= _1758;
        endcase
    end
    assign _1750 = _1628[1:1];
    assign _1748 = { _340,
                     _1197 };
    assign _1745 = _893 - _1193;
    assign _1746 = { gnd,
                     _1745 };
    assign _1749 = _1746 < _1748;
    assign _1760 = _1749 ? _1759 : _1750;
    assign _1741 = _1648[7:7];
    assign _1740 = _1648[6:6];
    assign _1739 = _1648[5:5];
    assign _1738 = _1648[4:4];
    assign _1737 = _1648[3:3];
    assign _1736 = _1648[2:2];
    assign _1735 = _1648[1:1];
    assign _1734 = _1648[0:0];
    always @* begin
        case (_1728)
        0:
            _1742 <= _1734;
        1:
            _1742 <= _1735;
        2:
            _1742 <= _1736;
        3:
            _1742 <= _1737;
        4:
            _1742 <= _1738;
        5:
            _1742 <= _1739;
        6:
            _1742 <= _1740;
        default:
            _1742 <= _1741;
        endcase
    end
    assign _1733 = _1628[2:2];
    assign _1731 = { _340,
                     _1197 };
    assign _1728 = _1923 - _1193;
    assign _1729 = { gnd,
                     _1728 };
    assign _1732 = _1729 < _1731;
    assign _1743 = _1732 ? _1742 : _1733;
    assign _1724 = _1648[7:7];
    assign _1723 = _1648[6:6];
    assign _1722 = _1648[5:5];
    assign _1721 = _1648[4:4];
    assign _1720 = _1648[3:3];
    assign _1719 = _1648[2:2];
    assign _1718 = _1648[1:1];
    assign _1717 = _1648[0:0];
    always @* begin
        case (_1711)
        0:
            _1725 <= _1717;
        1:
            _1725 <= _1718;
        2:
            _1725 <= _1719;
        3:
            _1725 <= _1720;
        4:
            _1725 <= _1721;
        5:
            _1725 <= _1722;
        6:
            _1725 <= _1723;
        default:
            _1725 <= _1724;
        endcase
    end
    assign _1716 = _1628[3:3];
    assign _1714 = { _340,
                     _1197 };
    assign _1711 = _1089 - _1193;
    assign _1712 = { gnd,
                     _1711 };
    assign _1715 = _1712 < _1714;
    assign _1726 = _1715 ? _1725 : _1716;
    assign _1707 = _1648[7:7];
    assign _1706 = _1648[6:6];
    assign _1705 = _1648[5:5];
    assign _1704 = _1648[4:4];
    assign _1703 = _1648[3:3];
    assign _1702 = _1648[2:2];
    assign _1701 = _1648[1:1];
    assign _1700 = _1648[0:0];
    always @* begin
        case (_1694)
        0:
            _1708 <= _1700;
        1:
            _1708 <= _1701;
        2:
            _1708 <= _1702;
        3:
            _1708 <= _1703;
        4:
            _1708 <= _1704;
        5:
            _1708 <= _1705;
        6:
            _1708 <= _1706;
        default:
            _1708 <= _1707;
        endcase
    end
    assign _1699 = _1628[4:4];
    assign _1697 = { _340,
                     _1197 };
    assign _1694 = _2014 - _1193;
    assign _1695 = { gnd,
                     _1694 };
    assign _1698 = _1695 < _1697;
    assign _1709 = _1698 ? _1708 : _1699;
    assign _1690 = _1648[7:7];
    assign _1689 = _1648[6:6];
    assign _1688 = _1648[5:5];
    assign _1687 = _1648[4:4];
    assign _1686 = _1648[3:3];
    assign _1685 = _1648[2:2];
    assign _1684 = _1648[1:1];
    assign _1683 = _1648[0:0];
    always @* begin
        case (_1677)
        0:
            _1691 <= _1683;
        1:
            _1691 <= _1684;
        2:
            _1691 <= _1685;
        3:
            _1691 <= _1686;
        4:
            _1691 <= _1687;
        5:
            _1691 <= _1688;
        6:
            _1691 <= _1689;
        default:
            _1691 <= _1690;
        endcase
    end
    assign _1682 = _1628[5:5];
    assign _1680 = { _340,
                     _1197 };
    assign _1677 = _1061 - _1193;
    assign _1678 = { gnd,
                     _1677 };
    assign _1681 = _1678 < _1680;
    assign _1692 = _1681 ? _1691 : _1682;
    assign _1673 = _1648[7:7];
    assign _1672 = _1648[6:6];
    assign _1671 = _1648[5:5];
    assign _1670 = _1648[4:4];
    assign _1669 = _1648[3:3];
    assign _1668 = _1648[2:2];
    assign _1667 = _1648[1:1];
    assign _1666 = _1648[0:0];
    always @* begin
        case (_1660)
        0:
            _1674 <= _1666;
        1:
            _1674 <= _1667;
        2:
            _1674 <= _1668;
        3:
            _1674 <= _1669;
        4:
            _1674 <= _1670;
        5:
            _1674 <= _1671;
        6:
            _1674 <= _1672;
        default:
            _1674 <= _1673;
        endcase
    end
    assign _1665 = _1628[6:6];
    assign _1663 = { _340,
                     _1197 };
    assign _1660 = _1047 - _1193;
    assign _1661 = { gnd,
                     _1660 };
    assign _1664 = _1661 < _1663;
    assign _1675 = _1664 ? _1674 : _1665;
    assign _1656 = _1648[7:7];
    assign _1655 = _1648[6:6];
    assign _1654 = _1648[5:5];
    assign _1653 = _1648[4:4];
    assign _1652 = _1648[3:3];
    assign _1651 = _1648[2:2];
    assign _1650 = _1648[1:1];
    assign _1643 = _1641[3:2];
    assign _1644 = { _340,
                     _1643 };
    assign _1639 = _1637[3:1];
    assign _1640 = { _362,
                     _1639 };
    assign _1637 = _780[12:9];
    assign _1636 = _1633[0:0];
    assign _1641 = _1636 ? _1640 : _1637;
    assign _1635 = _1633[1:1];
    assign _1645 = _1635 ? _1644 : _1641;
    assign _1632 = { gnd,
                     _1197 };
    assign _1633 = _2014 - _1632;
    assign _1634 = _1633[2:2];
    assign _1647 = _1634 ? _204 : _1645;
    assign _1648 = { _204,
                     _1647 };
    assign _1649 = _1648[0:0];
    always @* begin
        case (_1194)
        0:
            _1657 <= _1649;
        1:
            _1657 <= _1650;
        2:
            _1657 <= _1651;
        3:
            _1657 <= _1652;
        4:
            _1657 <= _1653;
        5:
            _1657 <= _1654;
        6:
            _1657 <= _1655;
        default:
            _1657 <= _1656;
        endcase
    end
    assign _1624 = _1504[7:7];
    assign _1623 = _1504[6:6];
    assign _1622 = _1504[5:5];
    assign _1621 = _1504[4:4];
    assign _1620 = _1504[3:3];
    assign _1619 = _1504[2:2];
    assign _1618 = _1504[1:1];
    assign _1617 = _1504[0:0];
    always @* begin
        case (_1613)
        0:
            _1625 <= _1617;
        1:
            _1625 <= _1618;
        2:
            _1625 <= _1619;
        3:
            _1625 <= _1620;
        4:
            _1625 <= _1621;
        5:
            _1625 <= _1622;
        6:
            _1625 <= _1623;
        default:
            _1625 <= _1624;
        endcase
    end
    assign _1616 = pin_out[0:0];
    assign _1613 = _345 - _1349;
    assign _1614 = { _340,
                     _1613 };
    assign _1615 = _1614 < _951;
    assign _1626 = _1615 ? _1625 : _1616;
    assign _1608 = _1504[7:7];
    assign _1607 = _1504[6:6];
    assign _1606 = _1504[5:5];
    assign _1605 = _1504[4:4];
    assign _1604 = _1504[3:3];
    assign _1603 = _1504[2:2];
    assign _1602 = _1504[1:1];
    assign _1601 = _1504[0:0];
    always @* begin
        case (_1597)
        0:
            _1609 <= _1601;
        1:
            _1609 <= _1602;
        2:
            _1609 <= _1603;
        3:
            _1609 <= _1604;
        4:
            _1609 <= _1605;
        5:
            _1609 <= _1606;
        6:
            _1609 <= _1607;
        default:
            _1609 <= _1608;
        endcase
    end
    assign _1600 = pin_out[1:1];
    assign _1597 = _893 - _1349;
    assign _1598 = { _340,
                     _1597 };
    assign _1599 = _1598 < _951;
    assign _1610 = _1599 ? _1609 : _1600;
    assign _1592 = _1504[7:7];
    assign _1591 = _1504[6:6];
    assign _1590 = _1504[5:5];
    assign _1589 = _1504[4:4];
    assign _1588 = _1504[3:3];
    assign _1587 = _1504[2:2];
    assign _1586 = _1504[1:1];
    assign _1585 = _1504[0:0];
    always @* begin
        case (_1581)
        0:
            _1593 <= _1585;
        1:
            _1593 <= _1586;
        2:
            _1593 <= _1587;
        3:
            _1593 <= _1588;
        4:
            _1593 <= _1589;
        5:
            _1593 <= _1590;
        6:
            _1593 <= _1591;
        default:
            _1593 <= _1592;
        endcase
    end
    assign _1584 = pin_out[2:2];
    assign _1581 = _1923 - _1349;
    assign _1582 = { _340,
                     _1581 };
    assign _1583 = _1582 < _951;
    assign _1594 = _1583 ? _1593 : _1584;
    assign _1576 = _1504[7:7];
    assign _1575 = _1504[6:6];
    assign _1574 = _1504[5:5];
    assign _1573 = _1504[4:4];
    assign _1572 = _1504[3:3];
    assign _1571 = _1504[2:2];
    assign _1570 = _1504[1:1];
    assign _1569 = _1504[0:0];
    always @* begin
        case (_1565)
        0:
            _1577 <= _1569;
        1:
            _1577 <= _1570;
        2:
            _1577 <= _1571;
        3:
            _1577 <= _1572;
        4:
            _1577 <= _1573;
        5:
            _1577 <= _1574;
        6:
            _1577 <= _1575;
        default:
            _1577 <= _1576;
        endcase
    end
    assign _1568 = pin_out[3:3];
    assign _1565 = _1089 - _1349;
    assign _1566 = { _340,
                     _1565 };
    assign _1567 = _1566 < _951;
    assign _1578 = _1567 ? _1577 : _1568;
    assign _1560 = _1504[7:7];
    assign _1559 = _1504[6:6];
    assign _1558 = _1504[5:5];
    assign _1557 = _1504[4:4];
    assign _1556 = _1504[3:3];
    assign _1555 = _1504[2:2];
    assign _1554 = _1504[1:1];
    assign _1553 = _1504[0:0];
    always @* begin
        case (_1549)
        0:
            _1561 <= _1553;
        1:
            _1561 <= _1554;
        2:
            _1561 <= _1555;
        3:
            _1561 <= _1556;
        4:
            _1561 <= _1557;
        5:
            _1561 <= _1558;
        6:
            _1561 <= _1559;
        default:
            _1561 <= _1560;
        endcase
    end
    assign _1552 = pin_out[4:4];
    assign _1549 = _2014 - _1349;
    assign _1550 = { _340,
                     _1549 };
    assign _1551 = _1550 < _951;
    assign _1562 = _1551 ? _1561 : _1552;
    assign _1544 = _1504[7:7];
    assign _1543 = _1504[6:6];
    assign _1542 = _1504[5:5];
    assign _1541 = _1504[4:4];
    assign _1540 = _1504[3:3];
    assign _1539 = _1504[2:2];
    assign _1538 = _1504[1:1];
    assign _1537 = _1504[0:0];
    always @* begin
        case (_1533)
        0:
            _1545 <= _1537;
        1:
            _1545 <= _1538;
        2:
            _1545 <= _1539;
        3:
            _1545 <= _1540;
        4:
            _1545 <= _1541;
        5:
            _1545 <= _1542;
        6:
            _1545 <= _1543;
        default:
            _1545 <= _1544;
        endcase
    end
    assign _1536 = pin_out[5:5];
    assign _1533 = _1061 - _1349;
    assign _1534 = { _340,
                     _1533 };
    assign _1535 = _1534 < _951;
    assign _1546 = _1535 ? _1545 : _1536;
    assign _1528 = _1504[7:7];
    assign _1527 = _1504[6:6];
    assign _1526 = _1504[5:5];
    assign _1525 = _1504[4:4];
    assign _1524 = _1504[3:3];
    assign _1523 = _1504[2:2];
    assign _1522 = _1504[1:1];
    assign _1521 = _1504[0:0];
    always @* begin
        case (_1517)
        0:
            _1529 <= _1521;
        1:
            _1529 <= _1522;
        2:
            _1529 <= _1523;
        3:
            _1529 <= _1524;
        4:
            _1529 <= _1525;
        5:
            _1529 <= _1526;
        6:
            _1529 <= _1527;
        default:
            _1529 <= _1528;
        endcase
    end
    assign _1520 = pin_out[6:6];
    assign _1517 = _1047 - _1349;
    assign _1518 = { _340,
                     _1517 };
    assign _1519 = _1518 < _951;
    assign _1530 = _1519 ? _1529 : _1520;
    assign _1512 = _1504[7:7];
    assign _1511 = _1504[6:6];
    assign _1510 = _1504[5:5];
    assign _1509 = _1504[4:4];
    assign _1508 = _1504[3:3];
    assign _1507 = _1504[2:2];
    assign _1506 = _1504[1:1];
    assign _1505 = _1504[0:0];
    always @* begin
        case (_1474)
        0:
            _1513 <= _1505;
        1:
            _1513 <= _1506;
        2:
            _1513 <= _1507;
        3:
            _1513 <= _1508;
        4:
            _1513 <= _1509;
        5:
            _1513 <= _1510;
        6:
            _1513 <= _1511;
        default:
            _1513 <= _1512;
        endcase
    end
    assign _1477 = pin_out[7:7];
    assign _1474 = _1033 - _1349;
    assign _1475 = { _340,
                     _1474 };
    assign _1476 = _1475 < _951;
    assign _1514 = _1476 ? _1513 : _1477;
    assign _1627 = { _1514,
                     _1530,
                     _1546,
                     _1562,
                     _1578,
                     _1594,
                     _1610,
                     _1626 };
    assign _1467 = _1019[7:7];
    assign _1466 = _1019[6:6];
    assign _1465 = _1019[5:5];
    assign _1464 = _1019[4:4];
    assign _1463 = _1019[3:3];
    assign _1462 = _1019[2:2];
    assign _1461 = _1019[1:1];
    assign _1460 = _1019[0:0];
    always @* begin
        case (_1456)
        0:
            _1468 <= _1460;
        1:
            _1468 <= _1461;
        2:
            _1468 <= _1462;
        3:
            _1468 <= _1463;
        4:
            _1468 <= _1464;
        5:
            _1468 <= _1465;
        6:
            _1468 <= _1466;
        default:
            _1468 <= _1467;
        endcase
    end
    assign _1459 = pin_out[0:0];
    assign _1456 = _345 - _1349;
    assign _1457 = { gnd,
                     _1456 };
    assign _1458 = _1457 < _1352;
    assign _1469 = _1458 ? _1468 : _1459;
    assign _1452 = _1019[7:7];
    assign _1451 = _1019[6:6];
    assign _1450 = _1019[5:5];
    assign _1449 = _1019[4:4];
    assign _1448 = _1019[3:3];
    assign _1447 = _1019[2:2];
    assign _1446 = _1019[1:1];
    assign _1445 = _1019[0:0];
    always @* begin
        case (_1441)
        0:
            _1453 <= _1445;
        1:
            _1453 <= _1446;
        2:
            _1453 <= _1447;
        3:
            _1453 <= _1448;
        4:
            _1453 <= _1449;
        5:
            _1453 <= _1450;
        6:
            _1453 <= _1451;
        default:
            _1453 <= _1452;
        endcase
    end
    assign _1444 = pin_out[1:1];
    assign _1441 = _893 - _1349;
    assign _1442 = { gnd,
                     _1441 };
    assign _1443 = _1442 < _1352;
    assign _1454 = _1443 ? _1453 : _1444;
    assign _1437 = _1019[7:7];
    assign _1436 = _1019[6:6];
    assign _1435 = _1019[5:5];
    assign _1434 = _1019[4:4];
    assign _1433 = _1019[3:3];
    assign _1432 = _1019[2:2];
    assign _1431 = _1019[1:1];
    assign _1430 = _1019[0:0];
    always @* begin
        case (_1426)
        0:
            _1438 <= _1430;
        1:
            _1438 <= _1431;
        2:
            _1438 <= _1432;
        3:
            _1438 <= _1433;
        4:
            _1438 <= _1434;
        5:
            _1438 <= _1435;
        6:
            _1438 <= _1436;
        default:
            _1438 <= _1437;
        endcase
    end
    assign _1429 = pin_out[2:2];
    assign _1426 = _1923 - _1349;
    assign _1427 = { gnd,
                     _1426 };
    assign _1428 = _1427 < _1352;
    assign _1439 = _1428 ? _1438 : _1429;
    assign _1422 = _1019[7:7];
    assign _1421 = _1019[6:6];
    assign _1420 = _1019[5:5];
    assign _1419 = _1019[4:4];
    assign _1418 = _1019[3:3];
    assign _1417 = _1019[2:2];
    assign _1416 = _1019[1:1];
    assign _1415 = _1019[0:0];
    always @* begin
        case (_1411)
        0:
            _1423 <= _1415;
        1:
            _1423 <= _1416;
        2:
            _1423 <= _1417;
        3:
            _1423 <= _1418;
        4:
            _1423 <= _1419;
        5:
            _1423 <= _1420;
        6:
            _1423 <= _1421;
        default:
            _1423 <= _1422;
        endcase
    end
    assign _1414 = pin_out[3:3];
    assign _1411 = _1089 - _1349;
    assign _1412 = { gnd,
                     _1411 };
    assign _1413 = _1412 < _1352;
    assign _1424 = _1413 ? _1423 : _1414;
    assign _1407 = _1019[7:7];
    assign _1406 = _1019[6:6];
    assign _1405 = _1019[5:5];
    assign _1404 = _1019[4:4];
    assign _1403 = _1019[3:3];
    assign _1402 = _1019[2:2];
    assign _1401 = _1019[1:1];
    assign _1400 = _1019[0:0];
    always @* begin
        case (_1396)
        0:
            _1408 <= _1400;
        1:
            _1408 <= _1401;
        2:
            _1408 <= _1402;
        3:
            _1408 <= _1403;
        4:
            _1408 <= _1404;
        5:
            _1408 <= _1405;
        6:
            _1408 <= _1406;
        default:
            _1408 <= _1407;
        endcase
    end
    assign _1399 = pin_out[4:4];
    assign _1396 = _2014 - _1349;
    assign _1397 = { gnd,
                     _1396 };
    assign _1398 = _1397 < _1352;
    assign _1409 = _1398 ? _1408 : _1399;
    assign _1392 = _1019[7:7];
    assign _1391 = _1019[6:6];
    assign _1390 = _1019[5:5];
    assign _1389 = _1019[4:4];
    assign _1388 = _1019[3:3];
    assign _1387 = _1019[2:2];
    assign _1386 = _1019[1:1];
    assign _1385 = _1019[0:0];
    always @* begin
        case (_1381)
        0:
            _1393 <= _1385;
        1:
            _1393 <= _1386;
        2:
            _1393 <= _1387;
        3:
            _1393 <= _1388;
        4:
            _1393 <= _1389;
        5:
            _1393 <= _1390;
        6:
            _1393 <= _1391;
        default:
            _1393 <= _1392;
        endcase
    end
    assign _1384 = pin_out[5:5];
    assign _1381 = _1061 - _1349;
    assign _1382 = { gnd,
                     _1381 };
    assign _1383 = _1382 < _1352;
    assign _1394 = _1383 ? _1393 : _1384;
    assign _1377 = _1019[7:7];
    assign _1376 = _1019[6:6];
    assign _1375 = _1019[5:5];
    assign _1374 = _1019[4:4];
    assign _1373 = _1019[3:3];
    assign _1372 = _1019[2:2];
    assign _1371 = _1019[1:1];
    assign _1370 = _1019[0:0];
    always @* begin
        case (_1366)
        0:
            _1378 <= _1370;
        1:
            _1378 <= _1371;
        2:
            _1378 <= _1372;
        3:
            _1378 <= _1373;
        4:
            _1378 <= _1374;
        5:
            _1378 <= _1375;
        6:
            _1378 <= _1376;
        default:
            _1378 <= _1377;
        endcase
    end
    assign _1369 = pin_out[6:6];
    assign _1366 = _1047 - _1349;
    assign _1367 = { gnd,
                     _1366 };
    assign _1368 = _1367 < _1352;
    assign _1379 = _1368 ? _1378 : _1369;
    assign _1362 = _1019[7:7];
    assign _1361 = _1019[6:6];
    assign _1360 = _1019[5:5];
    assign _1359 = _1019[4:4];
    assign _1358 = _1019[3:3];
    assign _1357 = _1019[2:2];
    assign _1356 = _1019[1:1];
    assign _1355 = _1019[0:0];
    always @* begin
        case (_1350)
        0:
            _1363 <= _1355;
        1:
            _1363 <= _1356;
        2:
            _1363 <= _1357;
        3:
            _1363 <= _1358;
        4:
            _1363 <= _1359;
        5:
            _1363 <= _1360;
        6:
            _1363 <= _1361;
        default:
            _1363 <= _1362;
        endcase
    end
    assign _1354 = pin_out[7:7];
    assign _1352 = _293[7:4];
    assign _292 = 8'b00010000;
    assign _1178 = _382[7:0];
    assign _1175 = 7'b1000010;
    assign _1176 = _393 == _1175;
    assign _1174 = _387 & _391;
    assign _1177 = _1174 & _1176;
    assign _1179 = _1177 ? _1178 : _293;
    assign _20 = _1179;
    always @(posedge _42) begin
        if (_40)
            _293 <= _292;
        else
            _293 <= _20;
    end
    assign _1349 = _293[2:0];
    assign _1350 = _1033 - _1349;
    assign _1351 = { gnd,
                     _1350 };
    assign _1353 = _1351 < _1352;
    assign _1364 = _1353 ? _1363 : _1354;
    assign _1470 = { _1364,
                     _1379,
                     _1394,
                     _1409,
                     _1424,
                     _1439,
                     _1454,
                     _1469 };
    assign _1343 = _1230[7:7];
    assign _1342 = _1230[6:6];
    assign _1341 = _1230[5:5];
    assign _1340 = _1230[4:4];
    assign _1339 = _1230[3:3];
    assign _1338 = _1230[2:2];
    assign _1337 = _1230[1:1];
    assign _1336 = _1230[0:0];
    always @* begin
        case (_1332)
        0:
            _1344 <= _1336;
        1:
            _1344 <= _1337;
        2:
            _1344 <= _1338;
        3:
            _1344 <= _1339;
        4:
            _1344 <= _1340;
        5:
            _1344 <= _1341;
        6:
            _1344 <= _1342;
        default:
            _1344 <= _1343;
        endcase
    end
    assign _1335 = pin_out[0:0];
    assign _1332 = _345 - _1222;
    assign _1333 = { gnd,
                     _1332 };
    assign _1334 = _1333 < _1225;
    assign _1345 = _1334 ? _1344 : _1335;
    assign _1328 = _1230[7:7];
    assign _1327 = _1230[6:6];
    assign _1326 = _1230[5:5];
    assign _1325 = _1230[4:4];
    assign _1324 = _1230[3:3];
    assign _1323 = _1230[2:2];
    assign _1322 = _1230[1:1];
    assign _1321 = _1230[0:0];
    always @* begin
        case (_1317)
        0:
            _1329 <= _1321;
        1:
            _1329 <= _1322;
        2:
            _1329 <= _1323;
        3:
            _1329 <= _1324;
        4:
            _1329 <= _1325;
        5:
            _1329 <= _1326;
        6:
            _1329 <= _1327;
        default:
            _1329 <= _1328;
        endcase
    end
    assign _1320 = pin_out[1:1];
    assign _1317 = _893 - _1222;
    assign _1318 = { gnd,
                     _1317 };
    assign _1319 = _1318 < _1225;
    assign _1330 = _1319 ? _1329 : _1320;
    assign _1313 = _1230[7:7];
    assign _1312 = _1230[6:6];
    assign _1311 = _1230[5:5];
    assign _1310 = _1230[4:4];
    assign _1309 = _1230[3:3];
    assign _1308 = _1230[2:2];
    assign _1307 = _1230[1:1];
    assign _1306 = _1230[0:0];
    always @* begin
        case (_1302)
        0:
            _1314 <= _1306;
        1:
            _1314 <= _1307;
        2:
            _1314 <= _1308;
        3:
            _1314 <= _1309;
        4:
            _1314 <= _1310;
        5:
            _1314 <= _1311;
        6:
            _1314 <= _1312;
        default:
            _1314 <= _1313;
        endcase
    end
    assign _1305 = pin_out[2:2];
    assign _1302 = _1923 - _1222;
    assign _1303 = { gnd,
                     _1302 };
    assign _1304 = _1303 < _1225;
    assign _1315 = _1304 ? _1314 : _1305;
    assign _1298 = _1230[7:7];
    assign _1297 = _1230[6:6];
    assign _1296 = _1230[5:5];
    assign _1295 = _1230[4:4];
    assign _1294 = _1230[3:3];
    assign _1293 = _1230[2:2];
    assign _1292 = _1230[1:1];
    assign _1291 = _1230[0:0];
    always @* begin
        case (_1287)
        0:
            _1299 <= _1291;
        1:
            _1299 <= _1292;
        2:
            _1299 <= _1293;
        3:
            _1299 <= _1294;
        4:
            _1299 <= _1295;
        5:
            _1299 <= _1296;
        6:
            _1299 <= _1297;
        default:
            _1299 <= _1298;
        endcase
    end
    assign _1290 = pin_out[3:3];
    assign _1287 = _1089 - _1222;
    assign _1288 = { gnd,
                     _1287 };
    assign _1289 = _1288 < _1225;
    assign _1300 = _1289 ? _1299 : _1290;
    assign _1283 = _1230[7:7];
    assign _1282 = _1230[6:6];
    assign _1281 = _1230[5:5];
    assign _1280 = _1230[4:4];
    assign _1279 = _1230[3:3];
    assign _1278 = _1230[2:2];
    assign _1277 = _1230[1:1];
    assign _1276 = _1230[0:0];
    always @* begin
        case (_1272)
        0:
            _1284 <= _1276;
        1:
            _1284 <= _1277;
        2:
            _1284 <= _1278;
        3:
            _1284 <= _1279;
        4:
            _1284 <= _1280;
        5:
            _1284 <= _1281;
        6:
            _1284 <= _1282;
        default:
            _1284 <= _1283;
        endcase
    end
    assign _1275 = pin_out[4:4];
    assign _1272 = _2014 - _1222;
    assign _1273 = { gnd,
                     _1272 };
    assign _1274 = _1273 < _1225;
    assign _1285 = _1274 ? _1284 : _1275;
    assign _1268 = _1230[7:7];
    assign _1267 = _1230[6:6];
    assign _1266 = _1230[5:5];
    assign _1265 = _1230[4:4];
    assign _1264 = _1230[3:3];
    assign _1263 = _1230[2:2];
    assign _1262 = _1230[1:1];
    assign _1261 = _1230[0:0];
    always @* begin
        case (_1257)
        0:
            _1269 <= _1261;
        1:
            _1269 <= _1262;
        2:
            _1269 <= _1263;
        3:
            _1269 <= _1264;
        4:
            _1269 <= _1265;
        5:
            _1269 <= _1266;
        6:
            _1269 <= _1267;
        default:
            _1269 <= _1268;
        endcase
    end
    assign _1260 = pin_out[5:5];
    assign _1257 = _1061 - _1222;
    assign _1258 = { gnd,
                     _1257 };
    assign _1259 = _1258 < _1225;
    assign _1270 = _1259 ? _1269 : _1260;
    assign _1253 = _1230[7:7];
    assign _1252 = _1230[6:6];
    assign _1251 = _1230[5:5];
    assign _1250 = _1230[4:4];
    assign _1249 = _1230[3:3];
    assign _1248 = _1230[2:2];
    assign _1247 = _1230[1:1];
    assign _1246 = _1230[0:0];
    always @* begin
        case (_1242)
        0:
            _1254 <= _1246;
        1:
            _1254 <= _1247;
        2:
            _1254 <= _1248;
        3:
            _1254 <= _1249;
        4:
            _1254 <= _1250;
        5:
            _1254 <= _1251;
        6:
            _1254 <= _1252;
        default:
            _1254 <= _1253;
        endcase
    end
    assign _1245 = pin_out[6:6];
    assign _1242 = _1047 - _1222;
    assign _1243 = { gnd,
                     _1242 };
    assign _1244 = _1243 < _1225;
    assign _1255 = _1244 ? _1254 : _1245;
    assign _1238 = _1230[7:7];
    assign _1237 = _1230[6:6];
    assign _1236 = _1230[5:5];
    assign _1235 = _1230[4:4];
    assign _1234 = _1230[3:3];
    assign _1233 = _1230[2:2];
    assign _1232 = _1230[1:1];
    assign _1231 = _1230[0:0];
    always @* begin
        case (_1223)
        0:
            _1239 <= _1231;
        1:
            _1239 <= _1232;
        2:
            _1239 <= _1233;
        3:
            _1239 <= _1234;
        4:
            _1239 <= _1235;
        5:
            _1239 <= _1236;
        6:
            _1239 <= _1237;
        default:
            _1239 <= _1238;
        endcase
    end
    assign _1227 = pin_out[7:7];
    assign _1225 = _298[7:4];
    assign _1184 = _382[7:0];
    assign _1181 = 7'b1000011;
    assign _1182 = _393 == _1181;
    assign _1180 = _387 & _391;
    assign _1183 = _1180 & _1182;
    assign _1185 = _1183 ? _1184 : _298;
    assign _21 = _1185;
    always @(posedge _42) begin
        if (_40)
            _298 <= _292;
        else
            _298 <= _21;
    end
    assign _1222 = _298[2:0];
    assign _1223 = _1033 - _1222;
    assign _1224 = { gnd,
                     _1223 };
    assign _1226 = _1224 < _1225;
    assign _1240 = _1226 ? _1239 : _1227;
    assign _1346 = { _1240,
                     _1255,
                     _1270,
                     _1285,
                     _1300,
                     _1315,
                     _1330,
                     _1345 };
    assign _1219 = _1217 == _340;
    assign _1215 = _781 == _1047;
    assign _1216 = _914 & _1215;
    assign _1220 = _1216 & _1219;
    assign _1347 = _1220 ? _1346 : pin_out;
    assign _1211 = _928 == _1923;
    assign _1212 = _934 & _1211;
    assign _1208 = _781 == _1061;
    assign _1209 = _914 & _1208;
    assign _1213 = _1209 & _1212;
    assign _1471 = _1213 ? _1470 : _1347;
    assign _1203 = _780[8:7];
    assign _1205 = _1203 == _340;
    assign _1201 = _781 == _1089;
    assign _1202 = _914 & _1201;
    assign _1206 = _1202 & _1205;
    assign _1628 = _1206 ? _1627 : _1471;
    assign _1629 = _1628[7:7];
    assign _1197 = _354[5:4];
    assign _1198 = { _340,
                     _1197 };
    assign _1190 = _382[5:0];
    assign _1187 = 7'b1001100;
    assign _1188 = _393 == _1187;
    assign _1186 = _387 & _391;
    assign _1189 = _1186 & _1188;
    assign _1191 = _1189 ? _1190 : _354;
    assign _22 = _1191;
    always @(posedge _42) begin
        if (_40)
            _354 <= _398;
        else
            _354 <= _22;
    end
    assign _1193 = _354[2:0];
    assign _1194 = _1033 - _1193;
    assign _1195 = { gnd,
                     _1194 };
    assign _1199 = _1195 < _1198;
    assign _1658 = _1199 ? _1657 : _1629;
    assign _1778 = { _1658,
                     _1675,
                     _1692,
                     _1709,
                     _1726,
                     _1743,
                     _1760,
                     _1777 };
    assign _1779 = _811 ? pin_out : _1778;
    assign _1780 = _808 ? pin_out : _1779;
    assign _23 = _1780;
    always @(posedge _42) begin
        if (_40)
            pin_out <= _57;
        else
            pin_out <= _23;
    end
    assign _817 = pin_out[7:7];
    assign _25 = uio_in;
    assign _816 = _25[7:7];
    assign _1782 = 7'b1000111;
    assign _1783 = _393 == _1782;
    assign _1781 = _387 & _391;
    assign _1784 = _1781 & _1783;
    assign _1785 = _1784 ? _382 : _50;
    assign _26 = _1785;
    always @(posedge _42) begin
        if (_40)
            _50 <= _257;
        else
            _50 <= _26;
    end
    assign _815 = _50[15:14];
    always @* begin
        case (_815)
        0:
            _819 <= _816;
        1:
            _819 <= _817;
        2:
            _819 <= _818;
        default:
            _819 <= _816;
        endcase
    end
    assign _855 = { _819,
                    _824,
                    _829,
                    _834,
                    _839,
                    _844,
                    _849,
                    _854 };
    assign _1014 = { _208,
                     _855 };
    assign _1899 = y - _882;
    assign _1897 = _1895 == _2014;
    assign _1900 = _1897 ? _1899 : y;
    assign _1498 = _1497[15:0];
    assign _1500 = { _1498,
                     _257 };
    assign _1494 = _1493[23:0];
    assign _1496 = { _1494,
                     _208 };
    assign _1490 = _1489[27:0];
    assign _1492 = { _1490,
                     _204 };
    assign _1486 = _1485[29:0];
    assign _1488 = { _1486,
                     _340 };
    assign _1484 = 32'b11111111111111111111111111111110;
    assign _1483 = 32'b11111111111111111111111111111111;
    assign _1482 = _951[0:0];
    assign _1485 = _1482 ? _1484 : _1483;
    assign _1481 = _951[1:1];
    assign _1489 = _1481 ? _1488 : _1485;
    assign _1480 = _951[2:2];
    assign _1493 = _1480 ? _1492 : _1489;
    assign _1479 = _951[3:3];
    assign _1497 = _1479 ? _1496 : _1493;
    assign _1478 = _951[4:4];
    assign _1501 = _1478 ? _1500 : _1497;
    assign _1502 = _1501[15:0];
    assign _1503 = ~ _1502;
    assign _1866 = _1864[31:16];
    assign _1867 = { _257,
                     _1866 };
    assign _1862 = _1860[31:8];
    assign _1863 = { _208,
                     _1862 };
    assign _1858 = _1856[31:4];
    assign _1859 = { _204,
                     _1858 };
    assign _1854 = _1852[31:2];
    assign _1855 = { _340,
                     _1854 };
    assign _1850 = _1848[31:1];
    assign _1851 = { _362,
                     _1850 };
    assign _1848 = { _257,
                     osr };
    assign _1846 = _951[0:0];
    assign _1852 = _1846 ? _1851 : _1848;
    assign _1845 = _951[1:1];
    assign _1856 = _1845 ? _1855 : _1852;
    assign _1844 = _951[2:2];
    assign _1860 = _1844 ? _1859 : _1856;
    assign _1843 = _951[3:3];
    assign _1864 = _1843 ? _1863 : _1860;
    assign _949 = { gnd,
                    _946 };
    assign _946 = _780[3:0];
    assign _948 = _946 == _204;
    assign _951 = _948 ? _181 : _949;
    assign _1842 = _951[4:4];
    assign _1868 = _1842 ? _1867 : _1864;
    assign _1869 = _1868[15:0];
    assign _1836 = tx_wr == _335;
    assign _1837 = _1793 & _1836;
    always @(posedge _42) begin
        if (_40)
            tx_mem_3 <= _257;
        else
            if (_1837)
                tx_mem_3 <= _382;
    end
    assign _1830 = tx_wr == _120;
    assign _1831 = _1793 & _1830;
    always @(posedge _42) begin
        if (_40)
            tx_mem_2 <= _257;
        else
            if (_1831)
                tx_mem_2 <= _382;
    end
    assign _1824 = tx_wr == _118;
    assign _1825 = _1793 & _1824;
    always @(posedge _42) begin
        if (_40)
            tx_mem_1 <= _257;
        else
            if (_1825)
                tx_mem_1 <= _382;
    end
    assign _1798 = tx_wr + _118;
    assign _1799 = _1793 ? _1798 : tx_wr;
    assign _27 = _1799;
    always @(posedge _42) begin
        if (_40)
            tx_wr <= _340;
        else
            tx_wr <= _27;
    end
    assign _1818 = tx_wr == _340;
    assign _1819 = _1793 & _1818;
    always @(posedge _42) begin
        if (_40)
            tx_mem_0 <= _257;
        else
            if (_1819)
                tx_mem_0 <= _382;
    end
    assign _1806 = tx_rd + _118;
    assign _1807 = _1801 ? _1806 : tx_rd;
    assign _28 = _1807;
    always @(posedge _42) begin
        if (_40)
            tx_rd <= _340;
        else
            tx_rd <= _28;
    end
    always @* begin
        case (tx_rd)
        0:
            _1839 <= tx_mem_0;
        1:
            _1839 <= tx_mem_1;
        2:
            _1839 <= tx_mem_2;
        default:
            _1839 <= tx_mem_3;
        endcase
    end
    assign _785 = _780[8:8];
    assign _1840 = _785 ? _1839 : osr;
    assign _1811 = _928 == _2014;
    assign _1812 = _1811 ? _1019 : osr;
    assign _1813 = _934 ? _1812 : osr;
    assign _1810 = _781 == _1061;
    assign _1814 = _1810 ? _1813 : osr;
    assign _1809 = _781 == _2014;
    assign _1841 = _1809 ? _1840 : _1814;
    assign _1808 = _781 == _1089;
    assign _1870 = _1808 ? _1869 : _1841;
    assign _1871 = _914 ? _1870 : osr;
    assign _1872 = _811 ? osr : _1871;
    assign _1874 = _808 ? _257 : _1872;
    assign _29 = _1874;
    always @(posedge _42) begin
        if (_40)
            osr <= _257;
        else
            osr <= _29;
    end
    assign _1504 = osr & _1503;
    assign _1890 = _780[8:7];
    assign _1892 = _1890 == _120;
    assign _1893 = _1892 ? _1504 : y;
    assign _1886 = _928 == _893;
    assign _1887 = _1886 ? _1019 : y;
    assign _1888 = _934 ? _1887 : y;
    assign _1882 = _1217 == _120;
    assign _1883 = _1882 ? _1230 : y;
    assign _1880 = _781 == _1047;
    assign _1884 = _1880 ? _1883 : y;
    assign _1878 = _781 == _1061;
    assign _1889 = _1878 ? _1888 : _1884;
    assign _1877 = _781 == _1089;
    assign _1894 = _1877 ? _1893 : _1889;
    assign _1876 = _781 == _345;
    assign _1901 = _1876 ? _1900 : _1894;
    assign _1902 = _914 ? _1901 : y;
    assign _1903 = _811 ? y : _1902;
    assign _1905 = _808 ? _257 : _1903;
    assign _30 = _1905;
    always @(posedge _42) begin
        if (_40)
            y <= _257;
        else
            y <= _30;
    end
    always @* begin
        case (_931)
        0:
            _1019 <= x;
        1:
            _1019 <= y;
        2:
            _1019 <= _1014;
        3:
            _1019 <= isr;
        4:
            _1019 <= osr;
        default:
            _1019 <= _257;
        endcase
    end
    assign _1915 = _928 == _345;
    assign _1916 = _1915 ? _1019 : x;
    assign _931 = _780[5:3];
    assign _933 = _931 < _1047;
    assign _928 = _780[8:6];
    assign _930 = _928 < _1047;
    assign _934 = _930 & _933;
    assign _1917 = _934 ? _1916 : x;
    assign _1229 = _780[4:0];
    assign _1230 = { _305,
                     _1229 };
    assign _1217 = _780[8:7];
    assign _1911 = _1217 == _118;
    assign _1912 = _1911 ? _1230 : x;
    assign _1909 = _781 == _1047;
    assign _1913 = _1909 ? _1912 : x;
    assign _1908 = _781 == _1061;
    assign _1918 = _1908 ? _1917 : _1913;
    assign _1907 = _781 == _1089;
    assign _1922 = _1907 ? _1921 : _1918;
    assign _1906 = _781 == _345;
    assign _1928 = _1906 ? _1927 : _1922;
    assign _1929 = _914 ? _1928 : x;
    assign _1930 = _811 ? x : _1929;
    assign _1932 = _808 ? _257 : _1930;
    assign _31 = _1932;
    always @(posedge _42) begin
        if (_40)
            x <= _257;
        else
            x <= _31;
    end
    assign _1936 = x == _257;
    assign _1937 = ~ _1936;
    assign _1938 = ~ _1937;
    assign _1895 = _780[8:6];
    always @* begin
        case (_1895)
        0:
            _1947 <= vdd;
        1:
            _1947 <= _1938;
        2:
            _1947 <= _1937;
        3:
            _1947 <= _1942;
        4:
            _1947 <= _1941;
        5:
            _1947 <= _1944;
        6:
            _1947 <= _1945;
        default:
            _1947 <= _1946;
        endcase
    end
    assign _1934 = _781 == _345;
    assign _1948 = _1934 & _1947;
    assign _1954 = _1948 | _1953;
    assign _1961 = _1954 ? _1960 : _1956;
    assign _1962 = _914 ? _1961 : pc;
    assign _1963 = _811 ? pc : _1962;
    assign _1964 = _808 ? _288 : _1963;
    assign _32 = _1964;
    always @(posedge _42) begin
        if (_40)
            pc <= _398;
        else
            pc <= _32;
    end
    always @* begin
        case (pc)
        0:
            _780 <= prog_0;
        1:
            _780 <= prog_1;
        2:
            _780 <= prog_2;
        3:
            _780 <= prog_3;
        4:
            _780 <= prog_4;
        5:
            _780 <= prog_5;
        6:
            _780 <= prog_6;
        7:
            _780 <= prog_7;
        8:
            _780 <= prog_8;
        9:
            _780 <= prog_9;
        10:
            _780 <= prog_10;
        11:
            _780 <= prog_11;
        12:
            _780 <= prog_12;
        13:
            _780 <= prog_13;
        14:
            _780 <= prog_14;
        15:
            _780 <= prog_15;
        16:
            _780 <= prog_16;
        17:
            _780 <= prog_17;
        18:
            _780 <= prog_18;
        19:
            _780 <= prog_19;
        20:
            _780 <= prog_20;
        21:
            _780 <= prog_21;
        22:
            _780 <= prog_22;
        23:
            _780 <= prog_23;
        24:
            _780 <= prog_24;
        25:
            _780 <= prog_25;
        26:
            _780 <= prog_26;
        27:
            _780 <= prog_27;
        28:
            _780 <= prog_28;
        29:
            _780 <= prog_29;
        30:
            _780 <= prog_30;
        31:
            _780 <= prog_31;
        32:
            _780 <= prog_32;
        33:
            _780 <= prog_33;
        34:
            _780 <= prog_34;
        35:
            _780 <= prog_35;
        36:
            _780 <= prog_36;
        37:
            _780 <= prog_37;
        38:
            _780 <= prog_38;
        39:
            _780 <= prog_39;
        40:
            _780 <= prog_40;
        41:
            _780 <= prog_41;
        42:
            _780 <= prog_42;
        43:
            _780 <= prog_43;
        44:
            _780 <= prog_44;
        45:
            _780 <= prog_45;
        46:
            _780 <= prog_46;
        47:
            _780 <= prog_47;
        48:
            _780 <= prog_48;
        49:
            _780 <= prog_49;
        50:
            _780 <= prog_50;
        51:
            _780 <= prog_51;
        52:
            _780 <= prog_52;
        53:
            _780 <= prog_53;
        54:
            _780 <= prog_54;
        55:
            _780 <= prog_55;
        56:
            _780 <= prog_56;
        57:
            _780 <= prog_57;
        58:
            _780 <= prog_58;
        59:
            _780 <= prog_59;
        60:
            _780 <= prog_60;
        61:
            _780 <= prog_61;
        62:
            _780 <= prog_62;
        default:
            _780 <= prog_63;
        endcase
    end
    assign _781 = _780[15:13];
    assign _894 = _781 == _893;
    assign _896 = _894 & _895;
    assign _899 = _896 & _898;
    assign _906 = _899 | _905;
    assign _912 = _906 | _911;
    assign _913 = ~ _912;
    assign _914 = _381 & _913;
    assign _1975 = _914 ? _1974 : delay_left;
    assign _810 = delay_left == _204;
    assign _811 = ~ _810;
    assign _1978 = _811 ? _1977 : _1975;
    assign _808 = ~ _283;
    assign _1980 = _808 ? _204 : _1978;
    assign _33 = _1980;
    always @(posedge _42) begin
        if (_40)
            delay_left <= _204;
        else
            delay_left <= _33;
    end
    assign _380 = delay_left == _204;
    assign _382 = _269[15:0];
    assign _1985 = _382[0:0];
    assign _1983 = _393 == _394;
    assign _1981 = _387 & _391;
    assign _1984 = _1981 & _1983;
    assign _1986 = _1984 ? _1985 : _283;
    assign _34 = _1986;
    always @(posedge _42) begin
        if (_40)
            _283 <= _362;
        else
            _283 <= _34;
    end
    assign _381 = _283 & _380;
    assign _1989 = _381 & _1988;
    assign _1990 = _1989 & _785;
    assign _1992 = _1990 & _1991;
    assign _35 = _1992;
    assign _1801 = _35 & _1800;
    assign _2011 = { _340,
                     _1801 };
    assign _1791 = tx_level == _2014;
    assign _1792 = ~ _1791;
    assign _1787 = 7'b1001000;
    assign _393 = _390[6:0];
    assign _1788 = _393 == _1787;
    assign _264 = _44[2:2];
    always @(posedge _42) begin
        if (_40)
            _266 <= gnd;
        else
            _266 <= _264;
    end
    always @(posedge _42) begin
        if (_40)
            _268 <= gnd;
        else
            _268 <= _266;
    end
    assign _262 = 23'b00000000000000000000000;
    assign _1993 = _269[22:0];
    assign _1994 = _255 ? _1993 : _263;
    assign _1995 = _231 ? _263 : _1994;
    assign _36 = _1995;
    always @(posedge _42) begin
        if (_40)
            _263 <= _262;
        else
            _263 <= _36;
    end
    assign _269 = { _263,
                    _268 };
    assign _270 = _269[7:0];
    assign _260 = _247 == _366;
    assign _1996 = _260 ? _270 : _390;
    assign _1997 = _255 ? _1996 : _390;
    assign _1998 = _231 ? _390 : _1997;
    assign _37 = _1998;
    always @(posedge _42) begin
        if (_40)
            _390 <= _208;
        else
            _390 <= _37;
    end
    assign _391 = _390[7:7];
    assign _385 = 5'b10111;
    assign _2002 = _247 + _1128;
    assign _1999 = 5'b11000;
    assign _2000 = _247 < _1999;
    assign _2003 = _2000 ? _2002 : _247;
    assign _2004 = _255 ? _2003 : _247;
    assign _2006 = _231 ? _183 : _2004;
    assign _38 = _2006;
    always @(posedge _42) begin
        if (_40)
            _247 <= _183;
        else
            _247 <= _38;
    end
    assign _386 = _247 == _385;
    assign _227 = _44[1:1];
    always @(posedge _42) begin
        if (_40)
            _229 <= vdd;
        else
            _229 <= _227;
    end
    always @(posedge _42) begin
        if (_40)
            _231 <= vdd;
        else
            _231 <= _229;
    end
    assign _254 = ~ _231;
    always @(posedge _42) begin
        if (_40)
            _241 <= _362;
        else
            _241 <= _237;
    end
    assign _252 = ~ _241;
    assign vdd = 1'b1;
    assign gnd = 1'b0;
    assign _40 = clear;
    assign _42 = clock;
    assign _44 = ui_in;
    assign _232 = _44[0:0];
    always @(posedge _42) begin
        if (_40)
            _235 <= gnd;
        else
            _235 <= _232;
    end
    always @(posedge _42) begin
        if (_40)
            _237 <= gnd;
        else
            _237 <= _235;
    end
    assign _253 = _237 & _252;
    assign _255 = _253 & _254;
    assign _387 = _255 & _386;
    assign _1786 = _387 & _391;
    assign _1789 = _1786 & _1788;
    assign _1793 = _1789 & _1792;
    assign _2008 = { _340,
                     _1793 };
    assign _2009 = tx_level + _2008;
    assign _2012 = _2009 - _2011;
    assign _45 = _2012;
    always @(posedge _42) begin
        if (_40)
            tx_level <= _345;
        else
            tx_level <= _45;
    end
    assign _2015 = tx_level == _2014;
    assign _2017 = { _204,
                     _2015,
                     _276,
                     _283,
                     _2016 };
    assign uo_out = _2017;
    assign uio_out = _167;
    assign uio_oe = _126;

endmodule
