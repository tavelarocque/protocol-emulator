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
    wire _574;
    wire [14:0] _573;
    wire [15:0] _575;
    wire [13:0] _568;
    wire [15:0] _569;
    wire [9:0] _560;
    wire [15:0] _564;
    wire _554;
    wire [14:0] _553;
    wire [15:0] _555;
    wire [12:0] _551;
    wire [2:0] _544;
    wire [15:0] _552;
    wire [15:0] _556;
    wire [1:0] _538;
    wire _539;
    wire _540;
    reg [15:0] t1_rx_mem_3;
    wire _533;
    wire _534;
    reg [15:0] t1_rx_mem_2;
    wire _527;
    wire _528;
    reg [15:0] t1_rx_mem_1;
    wire [1:0] _520;
    wire [1:0] _246;
    wire [1:0] _247;
    wire [1:0] _3;
    reg [1:0] t1_rx_wr;
    wire _521;
    wire _522;
    wire [15:0] _308;
    wire [31:0] _310;
    wire [7:0] _305;
    wire [23:0] _304;
    wire [31:0] _306;
    wire [3:0] _301;
    wire [27:0] _300;
    wire [31:0] _302;
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
    wire [1:0] _324;
    wire [1:0] _325;
    wire [1:0] _5;
    reg [1:0] t1_rx_rd;
    reg [15:0] _542;
    wire _515;
    wire _516;
    wire [15:0] _543;
    wire [8:0] _509;
    wire [15:0] _513;
    wire [10:0] _504;
    wire [15:0] _508;
    wire [12:0] _499;
    wire [15:0] _503;
    wire [15:0] _498;
    wire [15:0] _493;
    wire [15:0] _488;
    wire [15:0] _483;
    wire [15:0] _478;
    wire [15:0] _470;
    wire _460;
    wire [15:0] _461;
    wire [12:0] _457;
    wire [15:0] _458;
    wire [15:0] _462;
    wire _411;
    wire _412;
    wire [15:0] _449;
    wire [15:0] _406;
    wire [15:0] _401;
    wire [15:0] _396;
    wire [15:0] _391;
    wire [15:0] _386;
    wire [15:0] _381;
    wire [11:0] _372;
    wire [15:0] _376;
    reg [15:0] _570;
    wire [15:0] _571;
    wire [15:0] _572;
    wire [4:0] _347;
    wire _348;
    wire _349;
    wire _342;
    wire _337;
    wire _341;
    wire _343;
    wire _350;
    wire [15:0] _576;
    wire [15:0] _577;
    wire [15:0] _6;
    reg [15:0] host_miso_shift;
    wire _4183;
    wire _4182;
    wire _4180;
    wire _4181;
    wire [2:0] _4177;
    wire _4178;
    wire _4176;
    wire _4174;
    wire _4175;
    wire [2:0] _4169;
    wire _2692;
    wire _2687;
    wire [6:0] _2683;
    wire _2684;
    wire _2682;
    wire _2685;
    wire _2688;
    wire _2691;
    wire _4163;
    wire [2:0] _4139;
    wire _421;
    wire _4133;
    wire _4131;
    wire _4129;
    wire [3:0] _4105;
    wire [3:0] _4106;
    wire [1:0] _4100;
    wire [3:0] _4101;
    wire [3:0] _4097;
    wire [3:0] _4096;
    wire _4095;
    wire [3:0] _4098;
    wire _4094;
    wire [3:0] _4102;
    wire [3:0] _4103;
    wire _420;
    wire _1502;
    wire _1501;
    wire _1503;
    wire _1504;
    wire _1493;
    wire _1495;
    wire _1498;
    wire _1490;
    wire _1487;
    wire [2:0] _1485;
    wire [6:0] _452;
    wire [6:0] _591;
    wire [6:0] _587;
    wire _588;
    wire _585;
    wire _589;
    wire [6:0] _592;
    wire [6:0] _7;
    reg [6:0] cfg_t0_start;
    wire [5:0] _4086;
    wire _4085;
    wire [6:0] _4087;
    wire [6:0] _597;
    wire [6:0] _594;
    wire _595;
    wire _593;
    wire _596;
    wire [6:0] _598;
    wire [6:0] _8;
    reg [6:0] cfg_t0_timeout_vector;
    wire _4084;
    wire [6:0] _4088;
    wire [6:0] _4081;
    wire [6:0] _4082;
    wire [15:0] _1469;
    wire [15:0] _1470;
    wire [15:0] _1471;
    wire [15:0] _1472;
    wire [15:0] _1473;
    wire [15:0] _1475;
    wire [15:0] _9;
    wire [15:0] _10;
    reg [15:0] t0_wait_count;
    wire [6:0] _1477;
    wire _1478;
    wire _1476;
    wire _1479;
    wire [15:0] _1480;
    wire [15:0] _11;
    reg [15:0] cfg_t0_timeout;
    wire _1508;
    wire _1467;
    wire _1454;
    wire _1391;
    wire _1455;
    wire _1457;
    wire _1468;
    wire _1509;
    wire _1511;
    wire _1512;
    wire _1513;
    wire _1515;
    wire _12;
    wire _13;
    reg t0_waiting;
    wire [15:0] _1464;
    wire _1466;
    wire _1456;
    wire _1489;
    wire _1452;
    wire _1450;
    wire _1449;
    wire _1448;
    wire _1447;
    wire _1446;
    wire _1445;
    wire _1444;
    wire _1443;
    wire [2:0] _1392;
    reg _1451;
    wire _1453;
    wire _4077;
    wire _4076;
    wire _4078;
    wire _4079;
    wire _4072;
    wire [4:0] _1523;
    wire [4:0] _399;
    wire [4:0] _1520;
    wire [6:0] _1517;
    wire _1518;
    wire _1516;
    wire _1519;
    wire [4:0] _1521;
    wire [4:0] _14;
    reg [4:0] cfg_t0_threshold;
    wire [4:0] _1558;
    wire [5:0] _1555;
    wire [5:0] _1548;
    wire [5:0] _1556;
    wire [5:0] _1547;
    wire _1557;
    wire [4:0] _1560;
    wire [4:0] _1545;
    wire _1539;
    wire [4:0] _1541;
    wire [4:0] _1542;
    wire _1530;
    wire [4:0] _1543;
    wire _1528;
    wire [4:0] _1546;
    wire _1526;
    wire [4:0] _1561;
    wire [4:0] _1562;
    wire [4:0] _1563;
    wire [4:0] _1564;
    wire [4:0] _1565;
    wire [4:0] _15;
    wire [4:0] _16;
    reg [4:0] t0_osr_count;
    wire _4071;
    wire _4069;
    wire _4070;
    wire _4066;
    wire _4067;
    wire _4068;
    wire [15:0] _4051;
    wire [2:0] _4048;
    wire _4049;
    wire [15:0] _4052;
    wire _4045;
    wire [15:0] _4046;
    wire _1440;
    wire _1439;
    wire _1438;
    wire [1:0] _1437;
    reg _1441;
    wire _1435;
    wire _1434;
    wire _1433;
    wire [1:0] _1432;
    reg _1436;
    wire _1430;
    wire _1429;
    wire _1428;
    wire [1:0] _1427;
    reg _1431;
    wire _1425;
    wire _1424;
    wire _1423;
    wire [1:0] _1422;
    reg _1426;
    wire _1420;
    wire _1419;
    wire _1418;
    wire [1:0] _1417;
    reg _1421;
    wire _1415;
    wire _1414;
    wire _1413;
    wire [1:0] _1412;
    reg _1416;
    wire _1410;
    wire _1409;
    wire _1408;
    wire [1:0] _1407;
    reg _1411;
    wire _1405;
    wire [7:0] _117;
    wire _3844;
    wire _3843;
    wire _3842;
    wire _3841;
    wire _3840;
    wire _3839;
    wire _3838;
    wire _3837;
    reg _3845;
    wire _3836;
    wire [3:0] _3834;
    wire [2:0] _3831;
    wire [3:0] _3832;
    wire _3835;
    wire _3846;
    wire _3827;
    wire _3826;
    wire _3825;
    wire _3824;
    wire _3823;
    wire _3822;
    wire _3821;
    wire _3820;
    reg _3828;
    wire _3819;
    wire [3:0] _3817;
    wire [2:0] _3814;
    wire [3:0] _3815;
    wire _3818;
    wire _3829;
    wire _3810;
    wire _3809;
    wire _3808;
    wire _3807;
    wire _3806;
    wire _3805;
    wire _3804;
    wire _3803;
    reg _3811;
    wire _3802;
    wire [3:0] _3800;
    wire [2:0] _3797;
    wire [3:0] _3798;
    wire _3801;
    wire _3812;
    wire _3793;
    wire _3792;
    wire _3791;
    wire _3790;
    wire _3789;
    wire _3788;
    wire _3787;
    wire _3786;
    reg _3794;
    wire _3785;
    wire [3:0] _3783;
    wire [2:0] _3779;
    wire [2:0] _3780;
    wire [3:0] _3781;
    wire _3784;
    wire _3795;
    wire _3776;
    wire _3775;
    wire _3774;
    wire _3773;
    wire _3772;
    wire _3771;
    wire _3770;
    wire _3769;
    reg _3777;
    wire _3768;
    wire [3:0] _3766;
    wire [2:0] _3763;
    wire [3:0] _3764;
    wire _3767;
    wire _3778;
    wire _3759;
    wire _3758;
    wire _3757;
    wire _3756;
    wire _3755;
    wire _3754;
    wire _3753;
    wire _3752;
    reg _3760;
    wire _3751;
    wire [3:0] _3749;
    wire [2:0] _3745;
    wire [2:0] _3746;
    wire [3:0] _3747;
    wire _3750;
    wire _3761;
    wire _3742;
    wire _3741;
    wire _3740;
    wire _3739;
    wire _3738;
    wire _3737;
    wire _3736;
    wire _3735;
    reg _3743;
    wire _3734;
    wire [3:0] _3732;
    wire [2:0] _3728;
    wire [2:0] _3729;
    wire [3:0] _3730;
    wire _3733;
    wire _3744;
    wire _3725;
    wire _3724;
    wire _3723;
    wire _3722;
    wire _3721;
    wire _3720;
    wire _3719;
    wire [1:0] _3712;
    wire [3:0] _3713;
    wire [2:0] _3708;
    wire [3:0] _3709;
    wire _3706;
    wire [3:0] _3710;
    wire _3705;
    wire [3:0] _3714;
    wire [2:0] _3702;
    wire [2:0] _3703;
    wire _3704;
    wire [3:0] _3716;
    wire [7:0] _3717;
    wire _3718;
    reg _3726;
    wire _3694;
    wire _3693;
    wire _3692;
    wire _3691;
    wire _3690;
    wire _3689;
    wire _3688;
    wire _3687;
    reg _3695;
    wire _3686;
    wire [2:0] _3683;
    wire [4:0] _3684;
    wire _3685;
    wire _3696;
    wire _3678;
    wire _3677;
    wire _3676;
    wire _3675;
    wire _3674;
    wire _3673;
    wire _3672;
    wire _3671;
    reg _3679;
    wire _3670;
    wire [2:0] _3667;
    wire [4:0] _3668;
    wire _3669;
    wire _3680;
    wire _3662;
    wire _3661;
    wire _3660;
    wire _3659;
    wire _3658;
    wire _3657;
    wire _3656;
    wire _3655;
    reg _3663;
    wire _3654;
    wire [2:0] _3651;
    wire [4:0] _3652;
    wire _3653;
    wire _3664;
    wire _3646;
    wire _3645;
    wire _3644;
    wire _3643;
    wire _3642;
    wire _3641;
    wire _3640;
    wire _3639;
    reg _3647;
    wire _3638;
    wire [2:0] _3635;
    wire [4:0] _3636;
    wire _3637;
    wire _3648;
    wire _3630;
    wire _3629;
    wire _3628;
    wire _3627;
    wire _3626;
    wire _3625;
    wire _3624;
    wire _3623;
    reg _3631;
    wire _3622;
    wire [2:0] _3619;
    wire [4:0] _3620;
    wire _3621;
    wire _3632;
    wire _3614;
    wire _3613;
    wire _3612;
    wire _3611;
    wire _3610;
    wire _3609;
    wire _3608;
    wire _3607;
    reg _3615;
    wire _3606;
    wire [2:0] _3603;
    wire [4:0] _3604;
    wire _3605;
    wire _3616;
    wire _3598;
    wire _3597;
    wire _3596;
    wire _3595;
    wire _3594;
    wire _3593;
    wire _3592;
    wire _3591;
    reg _3599;
    wire _3590;
    wire [2:0] _3587;
    wire [4:0] _3588;
    wire _3589;
    wire _3600;
    wire _3582;
    wire _3581;
    wire _3580;
    wire _3579;
    wire _3578;
    wire _3577;
    wire _3576;
    wire _3575;
    reg _3583;
    wire _3574;
    wire [2:0] _3570;
    wire [2:0] _3571;
    wire [4:0] _3572;
    wire _3573;
    wire _3584;
    wire [7:0] _3697;
    wire _3564;
    wire _3563;
    wire _3562;
    wire _3561;
    wire _3560;
    wire _3559;
    wire _3558;
    wire _3557;
    reg _3565;
    wire _3556;
    wire [2:0] _3553;
    wire [3:0] _3554;
    wire _3555;
    wire _3566;
    wire _3549;
    wire _3548;
    wire _3547;
    wire _3546;
    wire _3545;
    wire _3544;
    wire _3543;
    wire _3542;
    reg _3550;
    wire _3541;
    wire [2:0] _3538;
    wire [3:0] _3539;
    wire _3540;
    wire _3551;
    wire _3534;
    wire _3533;
    wire _3532;
    wire _3531;
    wire _3530;
    wire _3529;
    wire _3528;
    wire _3527;
    reg _3535;
    wire _3526;
    wire [2:0] _3523;
    wire [3:0] _3524;
    wire _3525;
    wire _3536;
    wire _3519;
    wire _3518;
    wire _3517;
    wire _3516;
    wire _3515;
    wire _3514;
    wire _3513;
    wire _3512;
    reg _3520;
    wire _3511;
    wire [2:0] _3508;
    wire [3:0] _3509;
    wire _3510;
    wire _3521;
    wire _3504;
    wire _3503;
    wire _3502;
    wire _3501;
    wire _3500;
    wire _3499;
    wire _3498;
    wire _3497;
    reg _3505;
    wire _3496;
    wire [2:0] _3493;
    wire [3:0] _3494;
    wire _3495;
    wire _3506;
    wire _3489;
    wire _3488;
    wire _3487;
    wire _3486;
    wire _3485;
    wire _3484;
    wire _3483;
    wire _3482;
    reg _3490;
    wire _3481;
    wire [2:0] _3478;
    wire [3:0] _3479;
    wire _3480;
    wire _3491;
    wire _3474;
    wire _3473;
    wire _3472;
    wire _3471;
    wire _3470;
    wire _3469;
    wire _3468;
    wire _3467;
    reg _3475;
    wire _3466;
    wire [2:0] _3463;
    wire [3:0] _3464;
    wire _3465;
    wire _3476;
    wire _3459;
    wire _3458;
    wire _3457;
    wire _3456;
    wire _3455;
    wire _3454;
    wire _3453;
    wire _3452;
    reg _3460;
    wire _3451;
    wire [3:0] _3449;
    wire [7:0] _491;
    wire [7:0] _1570;
    wire [6:0] _1567;
    wire _1568;
    wire _1566;
    wire _1569;
    wire [7:0] _1571;
    wire [7:0] _17;
    reg [7:0] cfg_t1_out_cfg;
    wire [2:0] _3446;
    wire [2:0] _3447;
    wire [3:0] _3448;
    wire _3450;
    wire _3461;
    wire [7:0] _3567;
    wire _3440;
    wire _3439;
    wire _3438;
    wire _3437;
    wire _3436;
    wire _3435;
    wire _3434;
    wire _3433;
    reg _3441;
    wire _3432;
    wire [2:0] _3429;
    wire [3:0] _3430;
    wire _3431;
    wire _3442;
    wire _3425;
    wire _3424;
    wire _3423;
    wire _3422;
    wire _3421;
    wire _3420;
    wire _3419;
    wire _3418;
    reg _3426;
    wire _3417;
    wire [2:0] _3414;
    wire [3:0] _3415;
    wire _3416;
    wire _3427;
    wire _3410;
    wire _3409;
    wire _3408;
    wire _3407;
    wire _3406;
    wire _3405;
    wire _3404;
    wire _3403;
    reg _3411;
    wire _3402;
    wire [2:0] _3399;
    wire [3:0] _3400;
    wire _3401;
    wire _3412;
    wire _3395;
    wire _3394;
    wire _3393;
    wire _3392;
    wire _3391;
    wire _3390;
    wire _3389;
    wire _3388;
    reg _3396;
    wire _3387;
    wire [2:0] _3384;
    wire [3:0] _3385;
    wire _3386;
    wire _3397;
    wire _3380;
    wire _3379;
    wire _3378;
    wire _3377;
    wire _3376;
    wire _3375;
    wire _3374;
    wire _3373;
    reg _3381;
    wire _3372;
    wire [2:0] _3369;
    wire [3:0] _3370;
    wire _3371;
    wire _3382;
    wire _3365;
    wire _3364;
    wire _3363;
    wire _3362;
    wire _3361;
    wire _3360;
    wire _3359;
    wire _3358;
    reg _3366;
    wire _3357;
    wire [2:0] _3354;
    wire [3:0] _3355;
    wire _3356;
    wire _3367;
    wire _3350;
    wire _3349;
    wire _3348;
    wire _3347;
    wire _3346;
    wire _3345;
    wire _3344;
    wire _3343;
    reg _3351;
    wire _3342;
    wire [2:0] _3339;
    wire [3:0] _3340;
    wire _3341;
    wire _3352;
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
    wire [7:0] _1576;
    wire [6:0] _1573;
    wire _1574;
    wire _1572;
    wire _1575;
    wire [7:0] _1577;
    wire [7:0] _18;
    reg [7:0] cfg_t1_set_cfg;
    wire [2:0] _3322;
    wire [2:0] _3323;
    wire [3:0] _3324;
    wire _3326;
    wire _3337;
    wire [7:0] _3443;
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
    wire [3:0] _2217;
    wire [2:0] _2214;
    wire [3:0] _2215;
    wire _2218;
    wire _2229;
    wire _2210;
    wire _2209;
    wire _2208;
    wire _2207;
    wire _2206;
    wire _2205;
    wire _2204;
    wire _2203;
    reg _2211;
    wire _2202;
    wire [3:0] _2200;
    wire [2:0] _2197;
    wire [3:0] _2198;
    wire _2201;
    wire _2212;
    wire _2193;
    wire _2192;
    wire _2191;
    wire _2190;
    wire _2189;
    wire _2188;
    wire _2187;
    wire _2186;
    reg _2194;
    wire _2185;
    wire [3:0] _2183;
    wire [2:0] _2180;
    wire [3:0] _2181;
    wire _2184;
    wire _2195;
    wire _2176;
    wire _2175;
    wire _2174;
    wire _2173;
    wire _2172;
    wire _2171;
    wire _2170;
    wire _2169;
    reg _2177;
    wire _2168;
    wire [3:0] _2166;
    wire [2:0] _2163;
    wire [3:0] _2164;
    wire _2167;
    wire _2178;
    wire _2159;
    wire _2158;
    wire _2157;
    wire _2156;
    wire _2155;
    wire _2154;
    wire _2153;
    wire _2152;
    reg _2160;
    wire _2151;
    wire [3:0] _2149;
    wire [2:0] _2146;
    wire [3:0] _2147;
    wire _2150;
    wire _2161;
    wire _2142;
    wire _2141;
    wire _2140;
    wire _2139;
    wire _2138;
    wire _2137;
    wire _2136;
    wire _2135;
    reg _2143;
    wire _2134;
    wire [3:0] _2132;
    wire [2:0] _2129;
    wire [3:0] _2130;
    wire _2133;
    wire _2144;
    wire _2125;
    wire _2124;
    wire _2123;
    wire _2122;
    wire _2121;
    wire _2120;
    wire _2119;
    wire _2118;
    reg _2126;
    wire _2117;
    wire [3:0] _2115;
    wire [2:0] _2112;
    wire [3:0] _2113;
    wire _2116;
    wire _2127;
    wire _2108;
    wire _2107;
    wire _2106;
    wire _2105;
    wire _2104;
    wire _2103;
    wire _2102;
    wire [1:0] _2095;
    wire [3:0] _2096;
    wire [2:0] _2091;
    wire [3:0] _2092;
    wire [3:0] _2089;
    wire _2088;
    wire [3:0] _2093;
    wire _2087;
    wire [3:0] _2097;
    wire [2:0] _2084;
    wire [2:0] _2085;
    wire _2086;
    wire [3:0] _2099;
    wire [7:0] _2100;
    wire _2101;
    reg _2109;
    wire _2076;
    wire _2075;
    wire _2074;
    wire _2073;
    wire _2072;
    wire _2071;
    wire _2070;
    wire _2069;
    reg _2077;
    wire _2068;
    wire [2:0] _2065;
    wire [4:0] _2066;
    wire _2067;
    wire _2078;
    wire _2060;
    wire _2059;
    wire _2058;
    wire _2057;
    wire _2056;
    wire _2055;
    wire _2054;
    wire _2053;
    reg _2061;
    wire _2052;
    wire [2:0] _2049;
    wire [4:0] _2050;
    wire _2051;
    wire _2062;
    wire _2044;
    wire _2043;
    wire _2042;
    wire _2041;
    wire _2040;
    wire _2039;
    wire _2038;
    wire _2037;
    reg _2045;
    wire _2036;
    wire [2:0] _2033;
    wire [4:0] _2034;
    wire _2035;
    wire _2046;
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
    wire [4:0] _2018;
    wire _2019;
    wire _2030;
    wire _2012;
    wire _2011;
    wire _2010;
    wire _2009;
    wire _2008;
    wire _2007;
    wire _2006;
    wire _2005;
    reg _2013;
    wire _2004;
    wire [2:0] _2001;
    wire [4:0] _2002;
    wire _2003;
    wire _2014;
    wire _1996;
    wire _1995;
    wire _1994;
    wire _1993;
    wire _1992;
    wire _1991;
    wire _1990;
    wire _1989;
    reg _1997;
    wire _1988;
    wire [2:0] _1985;
    wire [4:0] _1986;
    wire _1987;
    wire _1998;
    wire _1980;
    wire _1979;
    wire _1978;
    wire _1977;
    wire _1976;
    wire _1975;
    wire _1974;
    wire _1973;
    reg _1981;
    wire _1972;
    wire [2:0] _1969;
    wire [4:0] _1970;
    wire _1971;
    wire _1982;
    wire _1964;
    wire _1963;
    wire _1962;
    wire _1961;
    wire _1960;
    wire _1959;
    wire _1958;
    wire _1957;
    reg _1965;
    wire _1897;
    wire [2:0] _1894;
    wire [4:0] _1895;
    wire _1896;
    wire _1966;
    wire [7:0] _2079;
    wire _1887;
    wire _1886;
    wire _1885;
    wire _1884;
    wire _1883;
    wire _1882;
    wire _1881;
    wire _1880;
    reg _1888;
    wire _1879;
    wire [2:0] _1876;
    wire [3:0] _1877;
    wire _1878;
    wire _1889;
    wire _1872;
    wire _1871;
    wire _1870;
    wire _1869;
    wire _1868;
    wire _1867;
    wire _1866;
    wire _1865;
    reg _1873;
    wire _1864;
    wire [2:0] _1861;
    wire [3:0] _1862;
    wire _1863;
    wire _1874;
    wire _1857;
    wire _1856;
    wire _1855;
    wire _1854;
    wire _1853;
    wire _1852;
    wire _1851;
    wire _1850;
    reg _1858;
    wire _1849;
    wire [2:0] _1846;
    wire [3:0] _1847;
    wire _1848;
    wire _1859;
    wire _1842;
    wire _1841;
    wire _1840;
    wire _1839;
    wire _1838;
    wire _1837;
    wire _1836;
    wire _1835;
    reg _1843;
    wire _1834;
    wire [2:0] _1831;
    wire [3:0] _1832;
    wire _1833;
    wire _1844;
    wire _1827;
    wire _1826;
    wire _1825;
    wire _1824;
    wire _1823;
    wire _1822;
    wire _1821;
    wire _1820;
    reg _1828;
    wire _1819;
    wire [2:0] _1816;
    wire [3:0] _1817;
    wire _1818;
    wire _1829;
    wire _1812;
    wire _1811;
    wire _1810;
    wire _1809;
    wire _1808;
    wire _1807;
    wire _1806;
    wire _1805;
    reg _1813;
    wire _1804;
    wire [2:0] _1801;
    wire [3:0] _1802;
    wire _1803;
    wire _1814;
    wire _1797;
    wire _1796;
    wire _1795;
    wire _1794;
    wire _1793;
    wire _1792;
    wire _1791;
    wire _1790;
    reg _1798;
    wire _1789;
    wire [2:0] _1786;
    wire [3:0] _1787;
    wire _1788;
    wire _1799;
    wire _1782;
    wire _1781;
    wire _1780;
    wire _1779;
    wire _1778;
    wire _1777;
    wire _1776;
    wire _1775;
    reg _1783;
    wire _1758;
    wire [3:0] _1756;
    wire [7:0] _1582;
    wire [6:0] _1579;
    wire _1580;
    wire _1578;
    wire _1581;
    wire [7:0] _1583;
    wire [7:0] _19;
    reg [7:0] cfg_t0_out_cfg;
    wire [2:0] _1753;
    wire [2:0] _1754;
    wire [3:0] _1755;
    wire _1757;
    wire _1784;
    wire [7:0] _1890;
    wire _1747;
    wire _1746;
    wire _1745;
    wire _1744;
    wire _1743;
    wire _1742;
    wire _1741;
    wire _1740;
    reg _1748;
    wire _1739;
    wire [2:0] _1736;
    wire [3:0] _1737;
    wire _1738;
    wire _1749;
    wire _1732;
    wire _1731;
    wire _1730;
    wire _1729;
    wire _1728;
    wire _1727;
    wire _1726;
    wire _1725;
    reg _1733;
    wire _1724;
    wire [2:0] _1721;
    wire [3:0] _1722;
    wire _1723;
    wire _1734;
    wire _1717;
    wire _1716;
    wire _1715;
    wire _1714;
    wire _1713;
    wire _1712;
    wire _1711;
    wire _1710;
    reg _1718;
    wire _1709;
    wire [2:0] _1706;
    wire [3:0] _1707;
    wire _1708;
    wire _1719;
    wire _1702;
    wire _1701;
    wire _1700;
    wire _1699;
    wire _1698;
    wire _1697;
    wire _1696;
    wire _1695;
    reg _1703;
    wire _1694;
    wire [2:0] _1691;
    wire [3:0] _1692;
    wire _1693;
    wire _1704;
    wire _1687;
    wire _1686;
    wire _1685;
    wire _1684;
    wire _1683;
    wire _1682;
    wire _1681;
    wire _1680;
    reg _1688;
    wire _1679;
    wire [2:0] _1676;
    wire [3:0] _1677;
    wire _1678;
    wire _1689;
    wire _1672;
    wire _1671;
    wire _1670;
    wire _1669;
    wire _1668;
    wire _1667;
    wire _1666;
    wire _1665;
    reg _1673;
    wire _1664;
    wire [2:0] _1661;
    wire [3:0] _1662;
    wire _1663;
    wire _1674;
    wire _1657;
    wire _1656;
    wire _1655;
    wire _1654;
    wire _1653;
    wire _1652;
    wire _1651;
    wire _1650;
    reg _1658;
    wire _1649;
    wire [2:0] _1646;
    wire [3:0] _1647;
    wire _1648;
    wire _1659;
    wire _1642;
    wire _1641;
    wire _1640;
    wire _1639;
    wire _1638;
    wire _1637;
    wire _1636;
    wire _1635;
    reg _1643;
    wire _1631;
    wire [3:0] _1629;
    wire [7:0] _1588;
    wire [6:0] _1585;
    wire _1586;
    wire _1584;
    wire _1587;
    wire [7:0] _1589;
    wire [7:0] _20;
    reg [7:0] cfg_t0_set_cfg;
    wire [2:0] _1626;
    wire [2:0] _1627;
    wire [3:0] _1628;
    wire _1630;
    wire _1644;
    wire [7:0] _1750;
    wire _1623;
    wire _1619;
    wire _1620;
    wire _1624;
    wire [7:0] _1751;
    wire _1615;
    wire _1616;
    wire _1612;
    wire _1613;
    wire _1617;
    wire [7:0] _1891;
    wire [1:0] _1607;
    wire _1609;
    wire _1605;
    wire _1606;
    wire _1610;
    wire [7:0] _2080;
    wire _2081;
    wire [1:0] _1601;
    wire [3:0] _1602;
    wire [5:0] _468;
    wire [5:0] _1594;
    wire [6:0] _1591;
    wire _1592;
    wire _1590;
    wire _1593;
    wire [5:0] _1595;
    wire [5:0] _21;
    reg [5:0] cfg_t0_sideset;
    wire [2:0] _1597;
    wire [2:0] _1598;
    wire [3:0] _1599;
    wire _1603;
    wire _2110;
    wire [7:0] _2230;
    wire [7:0] _2231;
    wire [7:0] _2232;
    wire [7:0] _2233;
    wire [7:0] _22;
    wire _3319;
    wire _3316;
    wire _3317;
    wire _3320;
    wire [7:0] _3444;
    wire _3312;
    wire _3313;
    wire _3309;
    wire _3310;
    wire _3314;
    wire [7:0] _3568;
    wire [1:0] _3304;
    wire _3306;
    wire _3302;
    wire _3303;
    wire _3307;
    wire [7:0] _3698;
    wire _3699;
    wire [3:0] _3299;
    wire [2:0] _3295;
    wire [2:0] _3296;
    wire [3:0] _3297;
    wire _3300;
    wire _3727;
    wire [7:0] _3847;
    wire [3:0] _3272;
    wire [1:0] _3266;
    wire [3:0] _3267;
    wire _3261;
    wire [3:0] _3264;
    wire [5:0] _2238;
    wire [6:0] _2235;
    wire _2236;
    wire _2234;
    wire _2237;
    wire [5:0] _2239;
    wire [5:0] _23;
    reg [5:0] cfg_t1_sideset;
    wire [1:0] _3259;
    wire _3260;
    wire [3:0] _3268;
    wire [3:0] _3258;
    wire [3:0] _3269;
    wire _317;
    wire _318;
    wire _2250;
    wire _2251;
    wire [6:0] _2246;
    wire _2247;
    wire _2243;
    wire _2244;
    wire _2245;
    wire _2248;
    wire _2252;
    wire _24;
    wire _319;
    wire [2:0] _2280;
    wire _240;
    wire _2274;
    wire _2272;
    wire _2269;
    wire _2270;
    wire _2273;
    wire _2275;
    wire _25;
    wire _241;
    wire [2:0] _2277;
    wire [2:0] _2278;
    wire [2:0] _2281;
    wire [2:0] _26;
    reg [2:0] t1_rx_level;
    wire _239;
    wire _2356;
    wire _2355;
    wire _2357;
    wire _2358;
    wire _2348;
    wire _2349;
    wire _2352;
    wire _2345;
    wire _2342;
    wire [6:0] _1384;
    wire _1385;
    wire _1386;
    reg [15:0] prog_127;
    wire [6:0] _1378;
    wire _1379;
    wire _1380;
    reg [15:0] prog_126;
    wire [6:0] _1372;
    wire _1373;
    wire _1374;
    reg [15:0] prog_125;
    wire [6:0] _1366;
    wire _1367;
    wire _1368;
    reg [15:0] prog_124;
    wire [6:0] _1360;
    wire _1361;
    wire _1362;
    reg [15:0] prog_123;
    wire [6:0] _1354;
    wire _1355;
    wire _1356;
    reg [15:0] prog_122;
    wire [6:0] _1348;
    wire _1349;
    wire _1350;
    reg [15:0] prog_121;
    wire [6:0] _1342;
    wire _1343;
    wire _1344;
    reg [15:0] prog_120;
    wire [6:0] _1336;
    wire _1337;
    wire _1338;
    reg [15:0] prog_119;
    wire [6:0] _1330;
    wire _1331;
    wire _1332;
    reg [15:0] prog_118;
    wire [6:0] _1324;
    wire _1325;
    wire _1326;
    reg [15:0] prog_117;
    wire [6:0] _1318;
    wire _1319;
    wire _1320;
    reg [15:0] prog_116;
    wire [6:0] _1312;
    wire _1313;
    wire _1314;
    reg [15:0] prog_115;
    wire [6:0] _1306;
    wire _1307;
    wire _1308;
    reg [15:0] prog_114;
    wire [6:0] _1300;
    wire _1301;
    wire _1302;
    reg [15:0] prog_113;
    wire [6:0] _1294;
    wire _1295;
    wire _1296;
    reg [15:0] prog_112;
    wire [6:0] _1288;
    wire _1289;
    wire _1290;
    reg [15:0] prog_111;
    wire [6:0] _1282;
    wire _1283;
    wire _1284;
    reg [15:0] prog_110;
    wire [6:0] _1276;
    wire _1277;
    wire _1278;
    reg [15:0] prog_109;
    wire [6:0] _1270;
    wire _1271;
    wire _1272;
    reg [15:0] prog_108;
    wire [6:0] _1264;
    wire _1265;
    wire _1266;
    reg [15:0] prog_107;
    wire [6:0] _1258;
    wire _1259;
    wire _1260;
    reg [15:0] prog_106;
    wire [6:0] _1252;
    wire _1253;
    wire _1254;
    reg [15:0] prog_105;
    wire [6:0] _1246;
    wire _1247;
    wire _1248;
    reg [15:0] prog_104;
    wire [6:0] _1240;
    wire _1241;
    wire _1242;
    reg [15:0] prog_103;
    wire [6:0] _1234;
    wire _1235;
    wire _1236;
    reg [15:0] prog_102;
    wire [6:0] _1228;
    wire _1229;
    wire _1230;
    reg [15:0] prog_101;
    wire [6:0] _1222;
    wire _1223;
    wire _1224;
    reg [15:0] prog_100;
    wire [6:0] _1216;
    wire _1217;
    wire _1218;
    reg [15:0] prog_99;
    wire [6:0] _1210;
    wire _1211;
    wire _1212;
    reg [15:0] prog_98;
    wire [6:0] _1204;
    wire _1205;
    wire _1206;
    reg [15:0] prog_97;
    wire [6:0] _1198;
    wire _1199;
    wire _1200;
    reg [15:0] prog_96;
    wire [6:0] _1192;
    wire _1193;
    wire _1194;
    reg [15:0] prog_95;
    wire [6:0] _1186;
    wire _1187;
    wire _1188;
    reg [15:0] prog_94;
    wire [6:0] _1180;
    wire _1181;
    wire _1182;
    reg [15:0] prog_93;
    wire _1175;
    wire _1176;
    reg [15:0] prog_92;
    wire [6:0] _1168;
    wire _1169;
    wire _1170;
    reg [15:0] prog_91;
    wire [6:0] _1162;
    wire _1163;
    wire _1164;
    reg [15:0] prog_90;
    wire _1157;
    wire _1158;
    reg [15:0] prog_89;
    wire _1151;
    wire _1152;
    reg [15:0] prog_88;
    wire [6:0] _1144;
    wire _1145;
    wire _1146;
    reg [15:0] prog_87;
    wire [6:0] _1138;
    wire _1139;
    wire _1140;
    reg [15:0] prog_86;
    wire [6:0] _1132;
    wire _1133;
    wire _1134;
    reg [15:0] prog_85;
    wire [6:0] _1126;
    wire _1127;
    wire _1128;
    reg [15:0] prog_84;
    wire _1121;
    wire _1122;
    reg [15:0] prog_83;
    wire _1115;
    wire _1116;
    reg [15:0] prog_82;
    wire [6:0] _1108;
    wire _1109;
    wire _1110;
    reg [15:0] prog_81;
    wire [6:0] _1102;
    wire _1103;
    wire _1104;
    reg [15:0] prog_80;
    wire [6:0] _1096;
    wire _1097;
    wire _1098;
    reg [15:0] prog_79;
    wire [6:0] _1090;
    wire _1091;
    wire _1092;
    reg [15:0] prog_78;
    wire [6:0] _1084;
    wire _1085;
    wire _1086;
    reg [15:0] prog_77;
    wire _1079;
    wire _1080;
    reg [15:0] prog_76;
    wire _1073;
    wire _1074;
    reg [15:0] prog_75;
    wire [6:0] _1066;
    wire _1067;
    wire _1068;
    reg [15:0] prog_74;
    wire [6:0] _1060;
    wire _1061;
    wire _1062;
    reg [15:0] prog_73;
    wire [6:0] _1054;
    wire _1055;
    wire _1056;
    reg [15:0] prog_72;
    wire [6:0] _1048;
    wire _1049;
    wire _1050;
    reg [15:0] prog_71;
    wire _1043;
    wire _1044;
    reg [15:0] prog_70;
    wire _1037;
    wire _1038;
    reg [15:0] prog_69;
    wire [6:0] _1030;
    wire _1031;
    wire _1032;
    reg [15:0] prog_68;
    wire _1025;
    wire _1026;
    reg [15:0] prog_67;
    wire _1019;
    wire _1020;
    reg [15:0] prog_66;
    wire _1013;
    wire _1014;
    reg [15:0] prog_65;
    wire [6:0] _1006;
    wire _1007;
    wire _1008;
    reg [15:0] prog_64;
    wire [6:0] _1000;
    wire _1001;
    wire _1002;
    reg [15:0] prog_63;
    wire [6:0] _994;
    wire _995;
    wire _996;
    reg [15:0] prog_62;
    wire [6:0] _988;
    wire _989;
    wire _990;
    reg [15:0] prog_61;
    wire [6:0] _982;
    wire _983;
    wire _984;
    reg [15:0] prog_60;
    wire [6:0] _976;
    wire _977;
    wire _978;
    reg [15:0] prog_59;
    wire [6:0] _970;
    wire _971;
    wire _972;
    reg [15:0] prog_58;
    wire [6:0] _964;
    wire _965;
    wire _966;
    reg [15:0] prog_57;
    wire [6:0] _958;
    wire _959;
    wire _960;
    reg [15:0] prog_56;
    wire [6:0] _952;
    wire _953;
    wire _954;
    reg [15:0] prog_55;
    wire [6:0] _946;
    wire _947;
    wire _948;
    reg [15:0] prog_54;
    wire [6:0] _940;
    wire _941;
    wire _942;
    reg [15:0] prog_53;
    wire [6:0] _934;
    wire _935;
    wire _936;
    reg [15:0] prog_52;
    wire [6:0] _928;
    wire _929;
    wire _930;
    reg [15:0] prog_51;
    wire [6:0] _922;
    wire _923;
    wire _924;
    reg [15:0] prog_50;
    wire [6:0] _916;
    wire _917;
    wire _918;
    reg [15:0] prog_49;
    wire [6:0] _910;
    wire _911;
    wire _912;
    reg [15:0] prog_48;
    wire [6:0] _904;
    wire _905;
    wire _906;
    reg [15:0] prog_47;
    wire [6:0] _898;
    wire _899;
    wire _900;
    reg [15:0] prog_46;
    wire [6:0] _892;
    wire _893;
    wire _894;
    reg [15:0] prog_45;
    wire [6:0] _886;
    wire _887;
    wire _888;
    reg [15:0] prog_44;
    wire [6:0] _880;
    wire _881;
    wire _882;
    reg [15:0] prog_43;
    wire [6:0] _874;
    wire _875;
    wire _876;
    reg [15:0] prog_42;
    wire [6:0] _868;
    wire _869;
    wire _870;
    reg [15:0] prog_41;
    wire [6:0] _862;
    wire _863;
    wire _864;
    reg [15:0] prog_40;
    wire [6:0] _856;
    wire _857;
    wire _858;
    reg [15:0] prog_39;
    wire [6:0] _850;
    wire _851;
    wire _852;
    reg [15:0] prog_38;
    wire [6:0] _844;
    wire _845;
    wire _846;
    reg [15:0] prog_37;
    wire [6:0] _838;
    wire _839;
    wire _840;
    reg [15:0] prog_36;
    wire [6:0] _832;
    wire _833;
    wire _834;
    reg [15:0] prog_35;
    wire [6:0] _826;
    wire _827;
    wire _828;
    reg [15:0] prog_34;
    wire [6:0] _820;
    wire _821;
    wire _822;
    reg [15:0] prog_33;
    wire [6:0] _814;
    wire _815;
    wire _816;
    reg [15:0] prog_32;
    wire [6:0] _808;
    wire _809;
    wire _810;
    reg [15:0] prog_31;
    wire [6:0] _802;
    wire _803;
    wire _804;
    reg [15:0] prog_30;
    wire [6:0] _796;
    wire _797;
    wire _798;
    reg [15:0] prog_29;
    wire [6:0] _790;
    wire _791;
    wire _792;
    reg [15:0] prog_28;
    wire [6:0] _784;
    wire _785;
    wire _786;
    reg [15:0] prog_27;
    wire [6:0] _778;
    wire _779;
    wire _780;
    reg [15:0] prog_26;
    wire [6:0] _772;
    wire _773;
    wire _774;
    reg [15:0] prog_25;
    wire [6:0] _766;
    wire _767;
    wire _768;
    reg [15:0] prog_24;
    wire [6:0] _760;
    wire _761;
    wire _762;
    reg [15:0] prog_23;
    wire [6:0] _754;
    wire _755;
    wire _756;
    reg [15:0] prog_22;
    wire [6:0] _748;
    wire _749;
    wire _750;
    reg [15:0] prog_21;
    wire [6:0] _742;
    wire _743;
    wire _744;
    reg [15:0] prog_20;
    wire [6:0] _736;
    wire _737;
    wire _738;
    reg [15:0] prog_19;
    wire [6:0] _730;
    wire _731;
    wire _732;
    reg [15:0] prog_18;
    wire [6:0] _724;
    wire _725;
    wire _726;
    reg [15:0] prog_17;
    wire [6:0] _718;
    wire _719;
    wire _720;
    reg [15:0] prog_16;
    wire [6:0] _712;
    wire _713;
    wire _714;
    reg [15:0] prog_15;
    wire [6:0] _706;
    wire _707;
    wire _708;
    reg [15:0] prog_14;
    wire [6:0] _700;
    wire _701;
    wire _702;
    reg [15:0] prog_13;
    wire [6:0] _694;
    wire _695;
    wire _696;
    reg [15:0] prog_12;
    wire [6:0] _688;
    wire _689;
    wire _690;
    reg [15:0] prog_11;
    wire [6:0] _682;
    wire _683;
    wire _684;
    reg [15:0] prog_10;
    wire [6:0] _676;
    wire _677;
    wire _678;
    reg [15:0] prog_9;
    wire [6:0] _670;
    wire _671;
    wire _672;
    reg [15:0] prog_8;
    wire [6:0] _664;
    wire _665;
    wire _666;
    reg [15:0] prog_7;
    wire [6:0] _658;
    wire _659;
    wire _660;
    reg [15:0] prog_6;
    wire [6:0] _652;
    wire _653;
    wire _654;
    reg [15:0] prog_5;
    wire [6:0] _646;
    wire _647;
    wire _648;
    reg [15:0] prog_4;
    wire [6:0] _640;
    wire _641;
    wire _642;
    reg [15:0] prog_3;
    wire [6:0] _634;
    wire _635;
    wire _636;
    reg [15:0] prog_2;
    wire _629;
    wire _630;
    reg [15:0] prog_1;
    wire [5:0] _620;
    wire _619;
    wire [6:0] _621;
    wire _623;
    wire _617;
    wire _615;
    wire _618;
    wire _624;
    reg [15:0] prog_0;
    wire [6:0] _2286;
    wire _2284;
    wire _2282;
    wire _2285;
    wire [6:0] _2287;
    wire [6:0] _27;
    reg [6:0] cfg_t1_start;
    wire [5:0] _3250;
    wire _3249;
    wire [6:0] _3251;
    wire [6:0] _2292;
    wire _2290;
    wire _2288;
    wire _2291;
    wire [6:0] _2293;
    wire [6:0] _28;
    reg [6:0] cfg_t1_timeout_vector;
    wire _3248;
    wire [6:0] _3252;
    wire [6:0] _3246;
    wire [15:0] _2329;
    wire [15:0] _2330;
    wire [15:0] _2331;
    wire [15:0] _2332;
    wire [15:0] _2334;
    wire [15:0] _29;
    wire [15:0] _30;
    reg [15:0] t1_wait_count;
    wire _2337;
    wire _2335;
    wire _2338;
    wire [15:0] _2339;
    wire [15:0] _31;
    reg [15:0] cfg_t1_timeout;
    wire _2326;
    wire _2313;
    wire _2300;
    wire _2314;
    wire _2316;
    wire _2327;
    wire _2363;
    wire _2365;
    wire _2366;
    wire _2367;
    wire _2369;
    wire _32;
    wire _33;
    reg t1_waiting;
    wire [15:0] _2323;
    wire _2325;
    wire _2315;
    wire _2344;
    wire _2311;
    wire _2309;
    wire _2308;
    wire _2307;
    wire _2306;
    wire _2305;
    wire _2304;
    wire _2303;
    wire _2302;
    wire [2:0] _2301;
    reg _2310;
    wire _2312;
    wire _3241;
    wire _3240;
    wire _3242;
    wire _3243;
    wire [4:0] _2403;
    wire [5:0] _2400;
    wire [5:0] _2393;
    wire [5:0] _2401;
    wire _2402;
    wire [4:0] _2405;
    wire [4:0] _2390;
    wire _2384;
    wire [4:0] _2386;
    wire [4:0] _2387;
    wire _2375;
    wire [4:0] _2388;
    wire _2373;
    wire [4:0] _2391;
    wire _2371;
    wire [4:0] _2406;
    wire [4:0] _2407;
    wire [4:0] _2408;
    wire [4:0] _2409;
    wire [4:0] _2411;
    wire [4:0] _34;
    wire [4:0] _35;
    reg [4:0] t1_isr_count;
    wire _3236;
    wire [4:0] _2416;
    wire _2414;
    wire _2412;
    wire _2415;
    wire [4:0] _2417;
    wire [4:0] _36;
    reg [4:0] cfg_t1_threshold;
    wire [4:0] _2439;
    wire [5:0] _2436;
    wire [5:0] _2435;
    wire [5:0] _2437;
    wire _2438;
    wire [4:0] _2441;
    wire [4:0] _2432;
    wire _2426;
    wire [4:0] _2428;
    wire [4:0] _2429;
    wire _2424;
    wire [4:0] _2430;
    wire _2423;
    wire [4:0] _2433;
    wire _2422;
    wire [4:0] _2442;
    wire [4:0] _2443;
    wire [4:0] _2444;
    wire [4:0] _2445;
    wire [4:0] _2446;
    wire [4:0] _37;
    wire [4:0] _38;
    reg [4:0] t1_osr_count;
    wire _3235;
    wire _3233;
    wire _3234;
    wire _3230;
    wire _3231;
    wire _3232;
    wire [15:0] _3215;
    wire _3213;
    wire [15:0] _3216;
    wire _3209;
    wire [15:0] _3210;
    wire [15:0] _2673;
    wire [15:0] _2642;
    wire [31:0] _2644;
    wire [23:0] _2638;
    wire [31:0] _2640;
    wire [27:0] _2634;
    wire [31:0] _2636;
    wire [29:0] _2630;
    wire [31:0] _2632;
    wire [30:0] _2626;
    wire [31:0] _2628;
    wire [31:0] _2625;
    wire _2623;
    wire [31:0] _2629;
    wire _2622;
    wire [31:0] _2633;
    wire _2621;
    wire [31:0] _2637;
    wire _2620;
    wire [31:0] _2641;
    wire _2619;
    wire [31:0] _2645;
    wire [15:0] _2646;
    wire [15:0] _2674;
    wire [15:0] _2615;
    wire [31:0] _2616;
    wire [23:0] _2611;
    wire [31:0] _2612;
    wire [27:0] _2607;
    wire [31:0] _2608;
    wire [29:0] _2603;
    wire [31:0] _2604;
    wire [30:0] _2599;
    wire [31:0] _2600;
    wire _2591;
    wire _2588;
    wire _2587;
    wire _2586;
    wire _2585;
    wire _2584;
    wire _2583;
    wire _2582;
    wire _2581;
    reg _2589;
    wire _2592;
    wire [4:0] _2578;
    wire _2579;
    wire _2576;
    wire _2575;
    wire _2574;
    wire _2573;
    wire _2572;
    wire _2571;
    wire _2570;
    wire _2569;
    wire [2:0] _2568;
    reg _2577;
    wire _2580;
    wire [4:0] _2564;
    wire _2565;
    wire _2562;
    wire _2561;
    wire _2560;
    wire _2559;
    wire _2558;
    wire _2557;
    wire _2556;
    wire _2555;
    wire [2:0] _2554;
    reg _2563;
    wire _2566;
    wire [4:0] _2550;
    wire _2551;
    wire _2548;
    wire _2547;
    wire _2546;
    wire _2545;
    wire _2544;
    wire _2543;
    wire _2542;
    wire _2541;
    wire [2:0] _2540;
    reg _2549;
    wire _2552;
    wire [4:0] _2536;
    wire _2537;
    wire _2534;
    wire _2533;
    wire _2532;
    wire _2531;
    wire _2530;
    wire _2529;
    wire _2528;
    wire _2527;
    wire [2:0] _2526;
    reg _2535;
    wire _2538;
    wire [4:0] _2522;
    wire _2523;
    wire _2520;
    wire _2519;
    wire _2518;
    wire _2517;
    wire _2516;
    wire _2515;
    wire _2514;
    wire _2513;
    wire [2:0] _2512;
    reg _2521;
    wire _2524;
    wire [4:0] _2508;
    wire _2509;
    wire _2506;
    wire _2505;
    wire _2504;
    wire _2503;
    wire _2502;
    wire _2501;
    wire _2500;
    wire _2499;
    wire [2:0] _2498;
    reg _2507;
    wire _2510;
    wire [4:0] _2494;
    wire _2495;
    wire _2492;
    wire _2491;
    wire _2490;
    wire _2489;
    wire _2488;
    wire _2487;
    wire _2486;
    wire _2485;
    wire [2:0] _2451;
    wire _2449;
    wire _2447;
    wire _2450;
    wire [2:0] _2452;
    wire [2:0] _39;
    reg [2:0] cfg_t1_in_base;
    wire [2:0] _2484;
    reg _2493;
    wire _2496;
    wire [7:0] _2593;
    wire [15:0] _2594;
    wire [1:0] _2481;
    reg [15:0] _2596;
    wire [31:0] _2597;
    wire _2480;
    wire [31:0] _2601;
    wire _2479;
    wire [31:0] _2605;
    wire _2478;
    wire [31:0] _2609;
    wire _2477;
    wire [31:0] _2613;
    wire _2476;
    wire [31:0] _2617;
    wire [15:0] _2618;
    wire _251;
    wire [15:0] _2675;
    wire [15:0] _2474;
    wire _2456;
    wire [15:0] _2470;
    wire [15:0] _2471;
    wire _2455;
    wire [15:0] _2472;
    wire _2454;
    wire [15:0] _2475;
    wire _2453;
    wire [15:0] _2676;
    wire [15:0] _2677;
    wire [15:0] _2678;
    wire [15:0] _2679;
    wire [15:0] _2681;
    wire [15:0] _40;
    wire [15:0] _41;
    reg [15:0] t1_isr;
    wire [15:0] _2464;
    wire [15:0] _3187;
    wire _3185;
    wire [15:0] _3188;
    wire [15:0] _3176;
    wire [31:0] _3177;
    wire [23:0] _3172;
    wire [31:0] _3173;
    wire [27:0] _3168;
    wire [31:0] _3169;
    wire [29:0] _3164;
    wire [31:0] _3165;
    wire [30:0] _3160;
    wire [31:0] _3161;
    wire [31:0] _3158;
    wire _3156;
    wire [31:0] _3162;
    wire _3155;
    wire [31:0] _3166;
    wire _3154;
    wire [31:0] _3170;
    wire _3153;
    wire [31:0] _3174;
    wire [4:0] _3151;
    wire _3152;
    wire [31:0] _3178;
    wire [15:0] _3179;
    wire [15:0] _2667;
    wire [31:0] _2669;
    wire [23:0] _2663;
    wire [31:0] _2665;
    wire [27:0] _2659;
    wire [31:0] _2661;
    wire [29:0] _2655;
    wire [31:0] _2657;
    wire _2651;
    wire [31:0] _2654;
    wire _2650;
    wire [31:0] _2658;
    wire _2649;
    wire [31:0] _2662;
    wire _2648;
    wire [31:0] _2666;
    wire _2647;
    wire [31:0] _2670;
    wire [15:0] _2671;
    wire [15:0] _2672;
    wire [15:0] _3109;
    wire [31:0] _3111;
    wire [23:0] _3105;
    wire [31:0] _3107;
    wire [27:0] _3101;
    wire [31:0] _3103;
    wire [29:0] _3097;
    wire [31:0] _3099;
    wire [30:0] _3093;
    wire [31:0] _3095;
    wire [31:0] _3092;
    wire _3090;
    wire [31:0] _3096;
    wire _3089;
    wire [31:0] _3100;
    wire _3088;
    wire [31:0] _3104;
    wire _3087;
    wire [31:0] _3108;
    wire _3086;
    wire [31:0] _3112;
    wire [15:0] _3113;
    wire [15:0] _3082;
    wire [31:0] _3083;
    wire [23:0] _3078;
    wire [31:0] _3079;
    wire [27:0] _3074;
    wire [31:0] _3075;
    wire [29:0] _3070;
    wire [31:0] _3071;
    wire [30:0] _3066;
    wire [31:0] _3067;
    wire [31:0] _3064;
    wire _3062;
    wire [31:0] _3068;
    wire _3061;
    wire [31:0] _3072;
    wire _3060;
    wire [31:0] _3076;
    wire _3059;
    wire [31:0] _3080;
    wire [4:0] _2397;
    wire [3:0] _2394;
    wire _2396;
    wire [4:0] _2399;
    wire _3058;
    wire [31:0] _3084;
    wire [15:0] _3085;
    wire [15:0] _3114;
    wire _3051;
    wire _3052;
    reg [15:0] t1_tx_mem_3;
    wire _3045;
    wire _3046;
    reg [15:0] t1_tx_mem_2;
    wire _3039;
    wire _3040;
    reg [15:0] t1_tx_mem_1;
    wire [1:0] _2698;
    wire [1:0] _2699;
    wire [1:0] _42;
    reg [1:0] t1_tx_wr;
    wire _3033;
    wire _3034;
    wire _445;
    wire _446;
    reg [15:0] t0_rx_mem_3;
    wire _439;
    wire _440;
    reg [15:0] t0_rx_mem_2;
    wire _433;
    wire _434;
    reg [15:0] t0_rx_mem_1;
    wire [1:0] _2701;
    wire [1:0] _2702;
    wire [1:0] _43;
    reg [1:0] t0_rx_wr;
    wire _427;
    wire _428;
    wire [15:0] _2980;
    wire [31:0] _2982;
    wire [23:0] _2976;
    wire [31:0] _2978;
    wire [27:0] _2972;
    wire [31:0] _2974;
    wire [29:0] _2968;
    wire [31:0] _2970;
    wire _2964;
    wire [31:0] _2967;
    wire _2963;
    wire [31:0] _2971;
    wire _2962;
    wire [31:0] _2975;
    wire _2961;
    wire [31:0] _2979;
    wire _2960;
    wire [31:0] _2983;
    wire [15:0] _2984;
    wire [15:0] _2985;
    wire [15:0] _2986;
    wire [15:0] _2956;
    wire [31:0] _2957;
    wire [23:0] _2952;
    wire [31:0] _2953;
    wire [27:0] _2948;
    wire [31:0] _2949;
    wire [29:0] _2944;
    wire [31:0] _2945;
    wire [30:0] _2940;
    wire [31:0] _2941;
    wire [15:0] _2893;
    wire [15:0] _2888;
    wire [31:0] _2890;
    wire [23:0] _2884;
    wire [31:0] _2886;
    wire [27:0] _2880;
    wire [31:0] _2882;
    wire [29:0] _2876;
    wire [31:0] _2878;
    wire [30:0] _2872;
    wire [31:0] _2874;
    wire [31:0] _2871;
    wire _2869;
    wire [31:0] _2875;
    wire _2868;
    wire [31:0] _2879;
    wire _2867;
    wire [31:0] _2883;
    wire _2866;
    wire [31:0] _2887;
    wire _2865;
    wire [31:0] _2891;
    wire [15:0] _2892;
    wire [15:0] _2894;
    wire [15:0] _2861;
    wire [31:0] _2862;
    wire [23:0] _2857;
    wire [31:0] _2858;
    wire [27:0] _2853;
    wire [31:0] _2854;
    wire [29:0] _2849;
    wire [31:0] _2850;
    wire [30:0] _2845;
    wire [31:0] _2846;
    wire _2837;
    wire _2834;
    wire _2833;
    wire _2832;
    wire _2831;
    wire _2830;
    wire _2829;
    wire _2828;
    wire _2827;
    reg _2835;
    wire _2838;
    wire _2825;
    wire _2822;
    wire _2821;
    wire _2820;
    wire _2819;
    wire _2818;
    wire _2817;
    wire _2816;
    wire _2815;
    wire [2:0] _2814;
    reg _2823;
    wire _2826;
    wire _2811;
    wire _2808;
    wire _2807;
    wire _2806;
    wire _2805;
    wire _2804;
    wire _2803;
    wire _2802;
    wire _2801;
    wire [2:0] _2800;
    reg _2809;
    wire _2812;
    wire _2797;
    wire _2794;
    wire _2793;
    wire _2792;
    wire _2791;
    wire _2790;
    wire _2789;
    wire _2788;
    wire _2787;
    wire [2:0] _2786;
    reg _2795;
    wire _2798;
    wire _2783;
    wire _2780;
    wire _2779;
    wire _2778;
    wire _2777;
    wire _2776;
    wire _2775;
    wire _2774;
    wire _2773;
    wire [2:0] _2772;
    reg _2781;
    wire _2784;
    wire _2769;
    wire _2766;
    wire _2765;
    wire _2764;
    wire _2763;
    wire _2762;
    wire _2761;
    wire _2760;
    wire _2759;
    wire [2:0] _2758;
    reg _2767;
    wire _2770;
    wire _2755;
    wire _2752;
    wire _2751;
    wire _2750;
    wire _2749;
    wire _2748;
    wire _2747;
    wire _2746;
    wire _2745;
    wire [2:0] _2744;
    reg _2753;
    wire _2756;
    wire _2741;
    wire _2738;
    wire _2737;
    wire _2736;
    wire _2735;
    wire _2734;
    wire _2733;
    wire _2732;
    wire _2731;
    wire [2:0] _2707;
    wire _2705;
    wire _2703;
    wire _2706;
    wire [2:0] _2708;
    wire [2:0] _44;
    reg [2:0] cfg_t0_in_base;
    wire [2:0] _2730;
    reg _2739;
    wire _2742;
    wire [7:0] _2839;
    wire [15:0] _2840;
    wire [1:0] _2727;
    reg [15:0] _2842;
    wire [31:0] _2843;
    wire _2726;
    wire [31:0] _2847;
    wire _2725;
    wire [31:0] _2851;
    wire _2724;
    wire [31:0] _2855;
    wire _2723;
    wire [31:0] _2859;
    wire _2722;
    wire [31:0] _2863;
    wire [15:0] _2864;
    wire [15:0] _2895;
    wire [15:0] _2719;
    wire _2714;
    wire [15:0] _2715;
    wire [15:0] _2716;
    wire _2712;
    wire [15:0] _2717;
    wire _2711;
    wire [15:0] _2720;
    wire _2710;
    wire [15:0] _2896;
    wire [15:0] _2897;
    wire [15:0] _2898;
    wire [15:0] _2899;
    wire [15:0] _2901;
    wire [15:0] _45;
    wire [15:0] _46;
    reg [15:0] t0_isr;
    wire [31:0] _2938;
    wire _2936;
    wire [31:0] _2942;
    wire _2935;
    wire [31:0] _2946;
    wire _2934;
    wire [31:0] _2950;
    wire _2933;
    wire [31:0] _2954;
    wire [4:0] _2921;
    wire [5:0] _2918;
    wire [5:0] _2917;
    wire [5:0] _2919;
    wire _2920;
    wire [4:0] _2923;
    wire [4:0] _2914;
    wire _2908;
    wire [4:0] _2910;
    wire [4:0] _2911;
    wire _2907;
    wire [4:0] _2912;
    wire _2906;
    wire [4:0] _2915;
    wire _2905;
    wire [4:0] _2924;
    wire [4:0] _2925;
    wire [4:0] _2926;
    wire [4:0] _2927;
    wire [4:0] _2929;
    wire [4:0] _47;
    wire [4:0] _48;
    reg [4:0] t0_isr_count;
    wire [4:0] _2931;
    wire _2932;
    wire [31:0] _2958;
    wire [15:0] _2959;
    wire _2721;
    wire [15:0] _2987;
    wire [15:0] _49;
    reg [15:0] t0_rx_mem_0;
    wire [1:0] _3006;
    wire _3003;
    wire _2998;
    wire _2995;
    wire _2996;
    wire [6:0] _370;
    wire _2992;
    wire _2988;
    wire _2989;
    wire _2241;
    wire _2242;
    wire _2990;
    wire _2993;
    wire _2997;
    wire _50;
    wire _2999;
    wire _3000;
    wire _3004;
    wire [1:0] _3007;
    wire [1:0] _51;
    reg [1:0] t0_rx_rd;
    reg [15:0] _448;
    wire [15:0] _52;
    wire [15:0] _3029;
    reg [15:0] t1_tx_mem_0;
    wire [1:0] _3020;
    wire _3014;
    wire _2351;
    wire _3012;
    wire _3009;
    wire _3010;
    wire _3011;
    wire _3013;
    wire _53;
    wire _3015;
    wire [1:0] _3021;
    wire [1:0] _54;
    reg [1:0] t1_tx_rd;
    reg [15:0] _3054;
    wire _2271;
    wire [15:0] _3055;
    wire _3025;
    wire [15:0] _3026;
    wire [15:0] _3027;
    wire _3024;
    wire [15:0] _3028;
    wire _3023;
    wire [15:0] _3056;
    wire _3022;
    wire [15:0] _3115;
    wire [15:0] _3116;
    wire [15:0] _3117;
    wire [15:0] _3118;
    wire [15:0] _3120;
    wire [15:0] _55;
    wire [15:0] _56;
    reg [15:0] t1_osr;
    wire [15:0] _3149;
    wire [1:0] _3125;
    wire _3123;
    wire _3121;
    wire _3124;
    wire [1:0] _3126;
    wire [1:0] _57;
    reg [1:0] cfg_t1_shift;
    wire _3057;
    wire [15:0] _3180;
    wire [1:0] _3146;
    wire _3148;
    wire [15:0] _3181;
    wire _3142;
    wire [15:0] _3143;
    wire [15:0] _3144;
    wire _3135;
    wire [15:0] _3139;
    wire _3132;
    wire [15:0] _3140;
    wire _3130;
    wire [15:0] _3145;
    wire _3129;
    wire [15:0] _3182;
    wire _3128;
    wire [15:0] _3189;
    wire [15:0] _3190;
    wire [15:0] _3191;
    wire [15:0] _3192;
    wire [15:0] _3194;
    wire [15:0] _58;
    wire [15:0] _59;
    reg [15:0] t1_y;
    reg [15:0] _2469;
    wire _3204;
    wire [15:0] _3205;
    wire [2:0] _2379;
    wire _2381;
    wire [2:0] _2376;
    wire _2378;
    wire _2382;
    wire [15:0] _3206;
    wire [4:0] _3137;
    wire [15:0] _3138;
    wire [1:0] _3133;
    wire _3200;
    wire [15:0] _3201;
    wire _3198;
    wire [15:0] _3202;
    wire _3197;
    wire [15:0] _3207;
    wire _3196;
    wire [15:0] _3211;
    wire _3195;
    wire [15:0] _3217;
    wire [15:0] _3218;
    wire [15:0] _3219;
    wire [15:0] _3220;
    wire [15:0] _3222;
    wire [15:0] _60;
    wire [15:0] _61;
    reg [15:0] t1_x;
    wire _3226;
    wire _3227;
    wire _3228;
    wire [2:0] _3183;
    reg _3237;
    wire _3224;
    wire _3238;
    wire _3244;
    wire [6:0] _3253;
    wire [6:0] _3254;
    wire [6:0] _3255;
    wire [6:0] _3256;
    wire [6:0] _3257;
    wire [6:0] _62;
    wire [6:0] _63;
    reg [6:0] t1_pc;
    reg [15:0] _2266;
    wire [2:0] _2267;
    wire _2341;
    wire _2343;
    wire _2346;
    wire _2353;
    wire _2359;
    wire _2360;
    wire _2264;
    wire _2259;
    wire _2265;
    wire _2361;
    wire [3:0] _3270;
    wire [3:0] _3273;
    wire [3:0] _3274;
    wire [3:0] _3276;
    wire [3:0] _64;
    wire [3:0] _65;
    reg [3:0] t1_delay_left;
    wire _2297;
    wire _2298;
    wire [7:0] _3848;
    wire [15:0] _3288;
    wire _3279;
    wire _3277;
    wire _3280;
    wire [15:0] _3281;
    wire [15:0] _66;
    reg [15:0] cfg_t1_clkdiv;
    wire _3286;
    wire [15:0] _3290;
    wire [15:0] _3284;
    wire [15:0] _3291;
    wire _3282;
    wire [15:0] _3293;
    wire [15:0] _67;
    reg [15:0] t1_div_count;
    wire _2258;
    wire _2295;
    wire [7:0] _3849;
    wire _2253;
    wire _2294;
    wire [7:0] _3850;
    wire [7:0] _68;
    wire [7:0] _69;
    reg [7:0] pin_out;
    wire _1404;
    wire [7:0] _1400;
    reg [7:0] pins_sync1;
    reg [7:0] pins_sync2;
    wire [7:0] _1401;
    wire [7:0] _3855;
    wire _3853;
    wire _3851;
    wire _3854;
    wire [7:0] _3856;
    wire [7:0] _70;
    reg [7:0] cfg_sync_bypass;
    wire [7:0] _72;
    wire [7:0] _1394;
    wire [7:0] _1402;
    wire _1403;
    wire _3859;
    wire _3857;
    wire _3860;
    wire [15:0] _3861;
    wire [15:0] _73;
    reg [15:0] cfg_pin_modes;
    wire [1:0] _1393;
    reg _1406;
    wire [7:0] _1442;
    wire [15:0] _1766;
    wire [15:0] _4023;
    wire _4021;
    wire [15:0] _4024;
    wire [15:0] _1952;
    wire [31:0] _1953;
    wire [23:0] _1948;
    wire [31:0] _1949;
    wire [27:0] _1944;
    wire [31:0] _1945;
    wire [29:0] _1940;
    wire [31:0] _1941;
    wire [30:0] _1936;
    wire [31:0] _1937;
    wire [31:0] _1934;
    wire _1932;
    wire [31:0] _1938;
    wire _1931;
    wire [31:0] _1942;
    wire _1930;
    wire [31:0] _1946;
    wire _1929;
    wire [31:0] _1950;
    wire [4:0] _1927;
    wire _1928;
    wire [31:0] _1954;
    wire [15:0] _1955;
    wire [15:0] _1919;
    wire [31:0] _1921;
    wire [23:0] _1915;
    wire [31:0] _1917;
    wire [27:0] _1911;
    wire [31:0] _1913;
    wire [29:0] _1907;
    wire [31:0] _1909;
    wire _1903;
    wire [31:0] _1906;
    wire _1902;
    wire [31:0] _1910;
    wire _1901;
    wire [31:0] _1914;
    wire _1900;
    wire [31:0] _1918;
    wire _1899;
    wire [31:0] _1922;
    wire [15:0] _1923;
    wire [15:0] _1924;
    wire [15:0] _3981;
    wire [31:0] _3983;
    wire [23:0] _3977;
    wire [31:0] _3979;
    wire [27:0] _3973;
    wire [31:0] _3975;
    wire [29:0] _3969;
    wire [31:0] _3971;
    wire [30:0] _3965;
    wire [31:0] _3967;
    wire [31:0] _3964;
    wire _3962;
    wire [31:0] _3968;
    wire _3961;
    wire [31:0] _3972;
    wire _3960;
    wire [31:0] _3976;
    wire _3959;
    wire [31:0] _3980;
    wire _3958;
    wire [31:0] _3984;
    wire [15:0] _3985;
    wire [15:0] _3954;
    wire [31:0] _3955;
    wire [23:0] _3950;
    wire [31:0] _3951;
    wire [27:0] _3946;
    wire [31:0] _3947;
    wire [29:0] _3942;
    wire [31:0] _3943;
    wire [30:0] _3938;
    wire [31:0] _3939;
    wire [31:0] _3936;
    wire _3934;
    wire [31:0] _3940;
    wire _3933;
    wire [31:0] _3944;
    wire _3932;
    wire [31:0] _3948;
    wire _3931;
    wire [31:0] _3952;
    wire [4:0] _1552;
    wire [3:0] _1549;
    wire _1551;
    wire [4:0] _1554;
    wire _3930;
    wire [31:0] _3956;
    wire [15:0] _3957;
    wire [15:0] _3986;
    wire _3924;
    wire _3925;
    reg [15:0] t0_tx_mem_3;
    wire _3918;
    wire _3919;
    reg [15:0] t0_tx_mem_2;
    wire _3912;
    wire _3913;
    reg [15:0] t0_tx_mem_1;
    wire [1:0] _3874;
    wire [1:0] _3875;
    wire [1:0] _74;
    reg [1:0] t0_tx_wr;
    wire _3906;
    wire _3907;
    reg [15:0] t0_tx_mem_0;
    wire [1:0] _3894;
    wire _3880;
    wire [2:0] _3882;
    wire _3867;
    wire _3868;
    wire _3864;
    wire _3862;
    wire _3865;
    wire _3869;
    wire [2:0] _3877;
    wire [2:0] _3878;
    wire [2:0] _3883;
    wire [2:0] _75;
    reg [2:0] t0_tx_level;
    wire _1497;
    wire _3888;
    wire _3885;
    wire _3886;
    wire _3887;
    wire _3889;
    wire _76;
    wire _3881;
    wire [1:0] _3895;
    wire [1:0] _77;
    reg [1:0] t0_tx_rd;
    reg [15:0] _3927;
    wire _1494;
    wire [15:0] _3928;
    wire _3899;
    wire [15:0] _3900;
    wire [15:0] _3901;
    wire _3898;
    wire [15:0] _3902;
    wire _3897;
    wire [15:0] _3929;
    wire _3896;
    wire [15:0] _3987;
    wire [15:0] _3988;
    wire [15:0] _3989;
    wire [15:0] _3990;
    wire [15:0] _3992;
    wire [15:0] _78;
    wire [15:0] _79;
    reg [15:0] t0_osr;
    wire [15:0] _1925;
    wire [1:0] _3997;
    wire _3995;
    wire _3993;
    wire _3996;
    wire [1:0] _3998;
    wire [1:0] _80;
    reg [1:0] cfg_t0_shift;
    wire _1898;
    wire [15:0] _1956;
    wire [1:0] _4014;
    wire _4016;
    wire [15:0] _4017;
    wire _4010;
    wire [15:0] _4011;
    wire [15:0] _4012;
    wire _4006;
    wire [15:0] _4007;
    wire _4004;
    wire [15:0] _4008;
    wire _4002;
    wire [15:0] _4013;
    wire _4001;
    wire [15:0] _4018;
    wire _4000;
    wire [15:0] _4025;
    wire [15:0] _4026;
    wire [15:0] _4027;
    wire [15:0] _4028;
    wire [15:0] _4030;
    wire [15:0] _81;
    wire [15:0] _82;
    reg [15:0] t0_y;
    reg [15:0] _1774;
    wire _4040;
    wire [15:0] _4041;
    wire [2:0] _1534;
    wire _1536;
    wire [2:0] _1531;
    wire _1533;
    wire _1537;
    wire [15:0] _4042;
    wire [4:0] _1633;
    wire [15:0] _1634;
    wire [1:0] _1621;
    wire _4036;
    wire [15:0] _4037;
    wire _4034;
    wire [15:0] _4038;
    wire _4033;
    wire [15:0] _4043;
    wire _4032;
    wire [15:0] _4047;
    wire _4031;
    wire [15:0] _4053;
    wire [15:0] _4054;
    wire [15:0] _4055;
    wire [15:0] _4056;
    wire [15:0] _4058;
    wire [15:0] _83;
    wire [15:0] _84;
    reg [15:0] t0_x;
    wire _4062;
    wire _4063;
    wire _4064;
    wire [2:0] _4019;
    reg _4073;
    wire _4060;
    wire _4074;
    wire _4080;
    wire [6:0] _4089;
    wire [6:0] _4090;
    wire [6:0] _4091;
    wire [6:0] _4092;
    wire [6:0] _4093;
    wire [6:0] _85;
    wire [6:0] _86;
    reg [6:0] t0_pc;
    reg [15:0] _1388;
    wire [2:0] _1389;
    wire _1486;
    wire _1488;
    wire _1491;
    wire _1499;
    wire _1505;
    wire _1506;
    wire _1507;
    wire [3:0] _4104;
    wire _611;
    wire _612;
    wire [3:0] _4107;
    wire _606;
    wire [3:0] _4108;
    wire _600;
    wire [3:0] _4110;
    wire [3:0] _87;
    wire [3:0] _88;
    reg [3:0] t0_delay_left;
    wire _1483;
    wire [15:0] _4122;
    wire _4113;
    wire _4111;
    wire _4114;
    wire [15:0] _4115;
    wire [15:0] _89;
    reg [15:0] cfg_t0_clkdiv;
    wire _4120;
    wire [15:0] _4124;
    wire [15:0] _4118;
    wire [15:0] _4125;
    wire _4116;
    wire [15:0] _4127;
    wire [15:0] _90;
    reg [15:0] t0_div_count;
    wire _605;
    wire _599;
    wire _1481;
    wire _1484;
    wire _4130;
    wire _4132;
    wire _4134;
    wire _91;
    wire _422;
    wire [2:0] _4136;
    wire [2:0] _4137;
    wire [2:0] _4140;
    wire [2:0] _92;
    reg [2:0] t0_rx_level;
    wire _3002;
    wire _4161;
    wire [15:0] _590;
    wire [3:0] _4159;
    wire [6:0] _586;
    wire _4157;
    wire _363;
    reg host_mosi_s1;
    reg host_mosi_s2;
    wire [22:0] _361;
    wire [22:0] _4141;
    wire [22:0] _4142;
    wire [22:0] _4143;
    wire [22:0] _93;
    reg [22:0] host_shift_in;
    wire [23:0] _368;
    wire [7:0] _369;
    wire _359;
    wire [7:0] _4144;
    wire [7:0] _4145;
    wire [7:0] _4146;
    wire [7:0] _94;
    reg [7:0] host_cmd;
    wire _584;
    wire [4:0] _578;
    wire [4:0] _4150;
    wire [4:0] _4147;
    wire _4148;
    wire [4:0] _4151;
    wire [4:0] _4152;
    wire [4:0] _4154;
    wire [4:0] _95;
    reg [4:0] host_bit_count;
    wire _579;
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
    wire _580;
    wire _4155;
    wire _4158;
    wire [3:0] _4160;
    wire [3:0] _102;
    reg [3:0] cfg_ctrl;
    wire _2686;
    wire _4162;
    wire _4164;
    wire _103;
    wire _2689;
    wire _2693;
    wire [2:0] _4166;
    wire [2:0] _4167;
    wire [2:0] _4170;
    wire [2:0] _104;
    reg [2:0] t1_tx_level;
    wire _4172;
    wire gnd;
    wire [7:0] _4184;
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
    assign _574 = 1'b0;
    assign _573 = host_miso_shift[14:0];
    assign _575 = { _573,
                    _574 };
    assign _568 = 14'b00000000000000;
    assign _569 = { _568,
                    cfg_t1_shift };
    assign _560 = 10'b0000000000;
    assign _564 = { _560,
                    cfg_t1_sideset };
    assign _554 = cfg_ctrl[1:1];
    assign _553 = 15'b000000000000000;
    assign _555 = { _553,
                    _554 };
    assign _551 = { t1_pc,
                    t1_rx_level,
                    t1_tx_level };
    assign _544 = 3'b000;
    assign _552 = { _544,
                    _551 };
    assign _556 = _552 ^ _555;
    assign _538 = 2'b11;
    assign _539 = t1_rx_wr == _538;
    assign _540 = _241 & _539;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_3 <= _356;
        else
            if (_540)
                t1_rx_mem_3 <= _4;
    end
    assign _533 = t1_rx_wr == _187;
    assign _534 = _241 & _533;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_2 <= _356;
        else
            if (_534)
                t1_rx_mem_2 <= _4;
    end
    assign _527 = t1_rx_wr == _184;
    assign _528 = _241 & _527;
    always @(posedge _99) begin
        if (_97)
            t1_rx_mem_1 <= _356;
        else
            if (_528)
                t1_rx_mem_1 <= _4;
    end
    assign _520 = 2'b00;
    assign _246 = t1_rx_wr + _184;
    assign _247 = _241 ? _246 : t1_rx_wr;
    assign _3 = _247;
    always @(posedge _99) begin
        if (_97)
            t1_rx_wr <= _520;
        else
            t1_rx_wr <= _3;
    end
    assign _521 = t1_rx_wr == _520;
    assign _522 = _241 & _521;
    assign _308 = _307[15:0];
    assign _310 = { _308,
                    _356 };
    assign _305 = 8'b00000000;
    assign _304 = _303[23:0];
    assign _306 = { _304,
                    _305 };
    assign _301 = 4'b0000;
    assign _300 = _299[27:0];
    assign _302 = { _300,
                    _301 };
    assign _296 = _295[29:0];
    assign _298 = { _296,
                    _520 };
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
    assign _277 = { _301,
                    _276 };
    assign _272 = _270[31:2];
    assign _273 = { _520,
                    _272 };
    assign _268 = _266[31:1];
    assign _269 = { _574,
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
            if (_522)
                t1_rx_mem_0 <= _4;
    end
    assign _324 = t1_rx_rd + _184;
    assign _325 = _319 ? _324 : t1_rx_rd;
    assign _5 = _325;
    always @(posedge _99) begin
        if (_97)
            t1_rx_rd <= _520;
        else
            t1_rx_rd <= _5;
    end
    always @* begin
        case (t1_rx_rd)
        0:
            _542 <= t1_rx_mem_0;
        1:
            _542 <= t1_rx_mem_1;
        2:
            _542 <= t1_rx_mem_2;
        default:
            _542 <= t1_rx_mem_3;
        endcase
    end
    assign _515 = t1_rx_level == _544;
    assign _516 = ~ _515;
    assign _543 = _516 ? _542 : _356;
    assign _509 = 9'b000000000;
    assign _513 = { _509,
                    cfg_t1_timeout_vector };
    assign _504 = 11'b00000000000;
    assign _508 = { _504,
                    cfg_t1_threshold };
    assign _499 = 13'b0000000000000;
    assign _503 = { _499,
                    cfg_t1_in_base };
    assign _498 = { _305,
                    cfg_t1_set_cfg };
    assign _493 = { _305,
                    cfg_t1_out_cfg };
    assign _488 = { _509,
                    cfg_t1_start };
    assign _483 = { _568,
                    cfg_t0_shift };
    assign _478 = { _305,
                    cfg_sync_bypass };
    assign _470 = { _560,
                    cfg_t0_sideset };
    assign _460 = cfg_ctrl[0:0];
    assign _461 = { _553,
                    _460 };
    assign _457 = { t0_pc,
                    t0_rx_level,
                    t0_tx_level };
    assign _458 = { _544,
                    _457 };
    assign _462 = _458 ^ _461;
    assign _411 = t0_rx_level == _544;
    assign _412 = ~ _411;
    assign _449 = _412 ? _448 : _356;
    assign _406 = { _509,
                    cfg_t0_timeout_vector };
    assign _401 = { _504,
                    cfg_t0_threshold };
    assign _396 = { _499,
                    cfg_t0_in_base };
    assign _391 = { _305,
                    cfg_t0_set_cfg };
    assign _386 = { _305,
                    cfg_t0_out_cfg };
    assign _381 = { _509,
                    cfg_t0_start };
    assign _372 = 12'b000000000000;
    assign _376 = { _372,
                    cfg_ctrl };
    always @* begin
        case (_370)
        0:
            _570 <= _356;
        1:
            _570 <= _356;
        2:
            _570 <= _356;
        3:
            _570 <= _356;
        4:
            _570 <= _356;
        5:
            _570 <= _356;
        6:
            _570 <= _356;
        7:
            _570 <= _356;
        8:
            _570 <= _356;
        9:
            _570 <= _356;
        10:
            _570 <= _356;
        11:
            _570 <= _356;
        12:
            _570 <= _356;
        13:
            _570 <= _356;
        14:
            _570 <= _356;
        15:
            _570 <= _356;
        16:
            _570 <= _356;
        17:
            _570 <= _356;
        18:
            _570 <= _356;
        19:
            _570 <= _356;
        20:
            _570 <= _356;
        21:
            _570 <= _356;
        22:
            _570 <= _356;
        23:
            _570 <= _356;
        24:
            _570 <= _356;
        25:
            _570 <= _356;
        26:
            _570 <= _356;
        27:
            _570 <= _356;
        28:
            _570 <= _356;
        29:
            _570 <= _356;
        30:
            _570 <= _356;
        31:
            _570 <= _356;
        32:
            _570 <= _356;
        33:
            _570 <= _356;
        34:
            _570 <= _356;
        35:
            _570 <= _356;
        36:
            _570 <= _356;
        37:
            _570 <= _356;
        38:
            _570 <= _356;
        39:
            _570 <= _356;
        40:
            _570 <= _356;
        41:
            _570 <= _356;
        42:
            _570 <= _356;
        43:
            _570 <= _356;
        44:
            _570 <= _356;
        45:
            _570 <= _356;
        46:
            _570 <= _356;
        47:
            _570 <= _356;
        48:
            _570 <= _356;
        49:
            _570 <= _356;
        50:
            _570 <= _356;
        51:
            _570 <= _356;
        52:
            _570 <= _356;
        53:
            _570 <= _356;
        54:
            _570 <= _356;
        55:
            _570 <= _356;
        56:
            _570 <= _356;
        57:
            _570 <= _356;
        58:
            _570 <= _356;
        59:
            _570 <= _356;
        60:
            _570 <= _356;
        61:
            _570 <= _356;
        62:
            _570 <= _356;
        63:
            _570 <= _356;
        64:
            _570 <= _376;
        65:
            _570 <= _381;
        66:
            _570 <= _386;
        67:
            _570 <= _391;
        68:
            _570 <= _396;
        69:
            _570 <= _401;
        70:
            _570 <= _406;
        71:
            _570 <= cfg_pin_modes;
        72:
            _570 <= _356;
        73:
            _570 <= _449;
        74:
            _570 <= _462;
        75:
            _570 <= cfg_t0_timeout;
        76:
            _570 <= _470;
        77:
            _570 <= cfg_t0_clkdiv;
        78:
            _570 <= _478;
        79:
            _570 <= _483;
        80:
            _570 <= _356;
        81:
            _570 <= _488;
        82:
            _570 <= _493;
        83:
            _570 <= _498;
        84:
            _570 <= _503;
        85:
            _570 <= _508;
        86:
            _570 <= _513;
        87:
            _570 <= _356;
        88:
            _570 <= _356;
        89:
            _570 <= _543;
        90:
            _570 <= _556;
        91:
            _570 <= cfg_t1_timeout;
        92:
            _570 <= _564;
        93:
            _570 <= cfg_t1_clkdiv;
        94:
            _570 <= _356;
        95:
            _570 <= _569;
        default:
            _570 <= _356;
        endcase
    end
    assign _571 = _359 ? _570 : host_miso_shift;
    assign _572 = _354 ? _571 : host_miso_shift;
    assign _347 = 5'b01001;
    assign _348 = host_bit_count < _347;
    assign _349 = ~ _348;
    assign _342 = ~ host_cs_n_s2;
    assign _337 = ~ host_sck_s2;
    assign _341 = _337 & host_sck_prev;
    assign _343 = _341 & _342;
    assign _350 = _343 & _349;
    assign _576 = _350 ? _575 : _572;
    assign _577 = host_cs_n_s2 ? host_miso_shift : _576;
    assign _6 = _577;
    always @(posedge _99) begin
        if (_97)
            host_miso_shift <= _356;
        else
            host_miso_shift <= _6;
    end
    assign _4183 = host_miso_shift[15:15];
    assign _4182 = cfg_ctrl[0:0];
    assign _4180 = t0_rx_level == _544;
    assign _4181 = ~ _4180;
    assign _4177 = 3'b100;
    assign _4178 = t0_tx_level == _4177;
    assign _4176 = cfg_ctrl[1:1];
    assign _4174 = t1_rx_level == _544;
    assign _4175 = ~ _4174;
    assign _4169 = { _520,
                     _3015 };
    assign _2692 = ~ _2691;
    assign _2687 = ~ _2686;
    assign _2683 = 7'b1011000;
    assign _2684 = _586 == _2683;
    assign _2682 = _580 & _584;
    assign _2685 = _2682 & _2684;
    assign _2688 = _2685 & _2687;
    assign _2691 = t1_tx_level == _4177;
    assign _4163 = ~ _2691;
    assign _4139 = { _520,
                     _3004 };
    assign _421 = ~ _420;
    assign _4133 = ~ _420;
    assign _4131 = ~ _1494;
    assign _4129 = _1389 == _4177;
    assign _4105 = 4'b0001;
    assign _4106 = t0_delay_left - _4105;
    assign _4100 = _4098[3:2];
    assign _4101 = { _520,
                     _4100 };
    assign _4097 = 4'b0111;
    assign _4096 = 4'b1111;
    assign _4095 = _1601[0:0];
    assign _4098 = _4095 ? _4097 : _4096;
    assign _4094 = _1601[1:1];
    assign _4102 = _4094 ? _4101 : _4098;
    assign _4103 = _2089 & _4102;
    assign _420 = t0_rx_level == _4177;
    assign _1502 = ~ _1494;
    assign _1501 = _1389 == _4177;
    assign _1503 = _1501 & _1502;
    assign _1504 = _1503 & _420;
    assign _1493 = _1389 == _4177;
    assign _1495 = _1493 & _1494;
    assign _1498 = _1495 & _1497;
    assign _1490 = ~ _1489;
    assign _1487 = ~ _1453;
    assign _1485 = 3'b001;
    assign _452 = 7'b0000000;
    assign _591 = _590[6:0];
    assign _587 = 7'b1000001;
    assign _588 = _586 == _587;
    assign _585 = _580 & _584;
    assign _589 = _585 & _588;
    assign _592 = _589 ? _591 : cfg_t0_start;
    assign _7 = _592;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_start <= _452;
        else
            cfg_t0_start <= _7;
    end
    assign _4086 = _1388[5:0];
    assign _4085 = t0_pc[6:6];
    assign _4087 = { _4085,
                     _4086 };
    assign _597 = _590[6:0];
    assign _594 = 7'b1000110;
    assign _595 = _586 == _594;
    assign _593 = _580 & _584;
    assign _596 = _593 & _595;
    assign _598 = _596 ? _597 : cfg_t0_timeout_vector;
    assign _8 = _598;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_timeout_vector <= _452;
        else
            cfg_t0_timeout_vector <= _8;
    end
    assign _4084 = _1389 == _544;
    assign _4088 = _4084 ? _4087 : cfg_t0_timeout_vector;
    assign _4081 = 7'b0000001;
    assign _4082 = t0_pc + _4081;
    assign _1469 = 16'b0000000000000001;
    assign _1470 = _1464 - _1469;
    assign _1471 = _1468 ? _1470 : t0_wait_count;
    assign _1472 = _612 ? t0_wait_count : _1471;
    assign _1473 = _606 ? t0_wait_count : _1472;
    assign _1475 = _600 ? _356 : _1473;
    assign _9 = _1475;
    assign _10 = _9;
    always @(posedge _99) begin
        if (_97)
            t0_wait_count <= _356;
        else
            t0_wait_count <= _10;
    end
    assign _1477 = 7'b1001011;
    assign _1478 = _586 == _1477;
    assign _1476 = _580 & _584;
    assign _1479 = _1476 & _1478;
    assign _1480 = _1479 ? _590 : cfg_t0_timeout;
    assign _11 = _1480;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_timeout <= _356;
        else
            cfg_t0_timeout <= _11;
    end
    assign _1508 = 1'b1;
    assign _1467 = ~ _1466;
    assign _1454 = ~ _1453;
    assign _1391 = _1389 == _1485;
    assign _1455 = _1391 & _1454;
    assign _1457 = _1455 & _1456;
    assign _1468 = _1457 & _1467;
    assign _1509 = _1468 ? _1508 : t0_waiting;
    assign _1511 = _1507 ? _574 : _1509;
    assign _1512 = _612 ? t0_waiting : _1511;
    assign _1513 = _606 ? t0_waiting : _1512;
    assign _1515 = _600 ? _574 : _1513;
    assign _12 = _1515;
    assign _13 = _12;
    always @(posedge _99) begin
        if (_97)
            t0_waiting <= _574;
        else
            t0_waiting <= _13;
    end
    assign _1464 = t0_waiting ? t0_wait_count : cfg_t0_timeout;
    assign _1466 = _1464 == _356;
    assign _1456 = _1388[4:4];
    assign _1489 = _1456 & _1466;
    assign _1452 = _1388[8:8];
    assign _1450 = _1442[7:7];
    assign _1449 = _1442[6:6];
    assign _1448 = _1442[5:5];
    assign _1447 = _1442[4:4];
    assign _1446 = _1442[3:3];
    assign _1445 = _1442[2:2];
    assign _1444 = _1442[1:1];
    assign _1443 = _1442[0:0];
    assign _1392 = _1388[7:5];
    always @* begin
        case (_1392)
        0:
            _1451 <= _1443;
        1:
            _1451 <= _1444;
        2:
            _1451 <= _1445;
        3:
            _1451 <= _1446;
        4:
            _1451 <= _1447;
        5:
            _1451 <= _1448;
        6:
            _1451 <= _1449;
        default:
            _1451 <= _1450;
        endcase
    end
    assign _1453 = _1451 == _1452;
    assign _4077 = ~ _1453;
    assign _4076 = _1389 == _1485;
    assign _4078 = _4076 & _4077;
    assign _4079 = _4078 & _1489;
    assign _4072 = t0_isr_count < cfg_t0_threshold;
    assign _1523 = 5'b00000;
    assign _399 = 5'b01000;
    assign _1520 = _590[4:0];
    assign _1517 = 7'b1000101;
    assign _1518 = _586 == _1517;
    assign _1516 = _580 & _584;
    assign _1519 = _1516 & _1518;
    assign _1521 = _1519 ? _1520 : cfg_t0_threshold;
    assign _14 = _1521;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_threshold <= _399;
        else
            cfg_t0_threshold <= _14;
    end
    assign _1558 = _1556[4:0];
    assign _1555 = { gnd,
                     _1554 };
    assign _1548 = { gnd,
                     t0_osr_count };
    assign _1556 = _1548 + _1555;
    assign _1547 = 6'b010000;
    assign _1557 = _1547 < _1556;
    assign _1560 = _1557 ? _252 : _1558;
    assign _1545 = _1494 ? _1523 : t0_osr_count;
    assign _1539 = _1531 == _4177;
    assign _1541 = _1539 ? _1523 : t0_osr_count;
    assign _1542 = _1537 ? _1541 : t0_osr_count;
    assign _1530 = _1389 == _3745;
    assign _1543 = _1530 ? _1542 : t0_osr_count;
    assign _1528 = _1389 == _4177;
    assign _1546 = _1528 ? _1545 : _1543;
    assign _1526 = _1389 == _3779;
    assign _1561 = _1526 ? _1560 : _1546;
    assign _1562 = _1507 ? _1561 : t0_osr_count;
    assign _1563 = _612 ? t0_osr_count : _1562;
    assign _1564 = _606 ? t0_osr_count : _1563;
    assign _1565 = _600 ? cfg_t0_threshold : _1564;
    assign _15 = _1565;
    assign _16 = _15;
    always @(posedge _99) begin
        if (_97)
            t0_osr_count <= _1523;
        else
            t0_osr_count <= _16;
    end
    assign _4071 = t0_osr_count < cfg_t0_threshold;
    assign _4069 = t0_x == t0_y;
    assign _4070 = ~ _4069;
    assign _4066 = t0_y == _356;
    assign _4067 = ~ _4066;
    assign _4068 = ~ _4067;
    assign _4051 = t0_x - _1469;
    assign _4048 = 3'b010;
    assign _4049 = _4019 == _4048;
    assign _4052 = _4049 ? _4051 : t0_x;
    assign _4045 = _4014 == _184;
    assign _4046 = _4045 ? _1956 : t0_x;
    assign _1440 = _1439 & _1438;
    assign _1439 = pin_out[0:0];
    assign _1438 = _1402[0:0];
    assign _1437 = cfg_pin_modes[1:0];
    always @* begin
        case (_1437)
        0:
            _1441 <= _1438;
        1:
            _1441 <= _1439;
        2:
            _1441 <= _1440;
        default:
            _1441 <= _1438;
        endcase
    end
    assign _1435 = _1434 & _1433;
    assign _1434 = pin_out[1:1];
    assign _1433 = _1402[1:1];
    assign _1432 = cfg_pin_modes[3:2];
    always @* begin
        case (_1432)
        0:
            _1436 <= _1433;
        1:
            _1436 <= _1434;
        2:
            _1436 <= _1435;
        default:
            _1436 <= _1433;
        endcase
    end
    assign _1430 = _1429 & _1428;
    assign _1429 = pin_out[2:2];
    assign _1428 = _1402[2:2];
    assign _1427 = cfg_pin_modes[5:4];
    always @* begin
        case (_1427)
        0:
            _1431 <= _1428;
        1:
            _1431 <= _1429;
        2:
            _1431 <= _1430;
        default:
            _1431 <= _1428;
        endcase
    end
    assign _1425 = _1424 & _1423;
    assign _1424 = pin_out[3:3];
    assign _1423 = _1402[3:3];
    assign _1422 = cfg_pin_modes[7:6];
    always @* begin
        case (_1422)
        0:
            _1426 <= _1423;
        1:
            _1426 <= _1424;
        2:
            _1426 <= _1425;
        default:
            _1426 <= _1423;
        endcase
    end
    assign _1420 = _1419 & _1418;
    assign _1419 = pin_out[4:4];
    assign _1418 = _1402[4:4];
    assign _1417 = cfg_pin_modes[9:8];
    always @* begin
        case (_1417)
        0:
            _1421 <= _1418;
        1:
            _1421 <= _1419;
        2:
            _1421 <= _1420;
        default:
            _1421 <= _1418;
        endcase
    end
    assign _1415 = _1414 & _1413;
    assign _1414 = pin_out[5:5];
    assign _1413 = _1402[5:5];
    assign _1412 = cfg_pin_modes[11:10];
    always @* begin
        case (_1412)
        0:
            _1416 <= _1413;
        1:
            _1416 <= _1414;
        2:
            _1416 <= _1415;
        default:
            _1416 <= _1413;
        endcase
    end
    assign _1410 = _1409 & _1408;
    assign _1409 = pin_out[6:6];
    assign _1408 = _1402[6:6];
    assign _1407 = cfg_pin_modes[13:12];
    always @* begin
        case (_1407)
        0:
            _1411 <= _1408;
        1:
            _1411 <= _1409;
        2:
            _1411 <= _1410;
        default:
            _1411 <= _1408;
        endcase
    end
    assign _1405 = _1404 & _1403;
    assign _117 = 8'b11111111;
    assign _3844 = _3717[7:7];
    assign _3843 = _3717[6:6];
    assign _3842 = _3717[5:5];
    assign _3841 = _3717[4:4];
    assign _3840 = _3717[3:3];
    assign _3839 = _3717[2:2];
    assign _3838 = _3717[1:1];
    assign _3837 = _3717[0:0];
    always @* begin
        case (_3831)
        0:
            _3845 <= _3837;
        1:
            _3845 <= _3838;
        2:
            _3845 <= _3839;
        3:
            _3845 <= _3840;
        4:
            _3845 <= _3841;
        5:
            _3845 <= _3842;
        6:
            _3845 <= _3843;
        default:
            _3845 <= _3844;
        endcase
    end
    assign _3836 = _3698[0:0];
    assign _3834 = { _520,
                     _3259 };
    assign _3831 = _544 - _3295;
    assign _3832 = { gnd,
                     _3831 };
    assign _3835 = _3832 < _3834;
    assign _3846 = _3835 ? _3845 : _3836;
    assign _3827 = _3717[7:7];
    assign _3826 = _3717[6:6];
    assign _3825 = _3717[5:5];
    assign _3824 = _3717[4:4];
    assign _3823 = _3717[3:3];
    assign _3822 = _3717[2:2];
    assign _3821 = _3717[1:1];
    assign _3820 = _3717[0:0];
    always @* begin
        case (_3814)
        0:
            _3828 <= _3820;
        1:
            _3828 <= _3821;
        2:
            _3828 <= _3822;
        3:
            _3828 <= _3823;
        4:
            _3828 <= _3824;
        5:
            _3828 <= _3825;
        6:
            _3828 <= _3826;
        default:
            _3828 <= _3827;
        endcase
    end
    assign _3819 = _3698[1:1];
    assign _3817 = { _520,
                     _3259 };
    assign _3814 = _1485 - _3295;
    assign _3815 = { gnd,
                     _3814 };
    assign _3818 = _3815 < _3817;
    assign _3829 = _3818 ? _3828 : _3819;
    assign _3810 = _3717[7:7];
    assign _3809 = _3717[6:6];
    assign _3808 = _3717[5:5];
    assign _3807 = _3717[4:4];
    assign _3806 = _3717[3:3];
    assign _3805 = _3717[2:2];
    assign _3804 = _3717[1:1];
    assign _3803 = _3717[0:0];
    always @* begin
        case (_3797)
        0:
            _3811 <= _3803;
        1:
            _3811 <= _3804;
        2:
            _3811 <= _3805;
        3:
            _3811 <= _3806;
        4:
            _3811 <= _3807;
        5:
            _3811 <= _3808;
        6:
            _3811 <= _3809;
        default:
            _3811 <= _3810;
        endcase
    end
    assign _3802 = _3698[2:2];
    assign _3800 = { _520,
                     _3259 };
    assign _3797 = _4048 - _3295;
    assign _3798 = { gnd,
                     _3797 };
    assign _3801 = _3798 < _3800;
    assign _3812 = _3801 ? _3811 : _3802;
    assign _3793 = _3717[7:7];
    assign _3792 = _3717[6:6];
    assign _3791 = _3717[5:5];
    assign _3790 = _3717[4:4];
    assign _3789 = _3717[3:3];
    assign _3788 = _3717[2:2];
    assign _3787 = _3717[1:1];
    assign _3786 = _3717[0:0];
    always @* begin
        case (_3780)
        0:
            _3794 <= _3786;
        1:
            _3794 <= _3787;
        2:
            _3794 <= _3788;
        3:
            _3794 <= _3789;
        4:
            _3794 <= _3790;
        5:
            _3794 <= _3791;
        6:
            _3794 <= _3792;
        default:
            _3794 <= _3793;
        endcase
    end
    assign _3785 = _3698[3:3];
    assign _3783 = { _520,
                     _3259 };
    assign _3779 = 3'b011;
    assign _3780 = _3779 - _3295;
    assign _3781 = { gnd,
                     _3780 };
    assign _3784 = _3781 < _3783;
    assign _3795 = _3784 ? _3794 : _3785;
    assign _3776 = _3717[7:7];
    assign _3775 = _3717[6:6];
    assign _3774 = _3717[5:5];
    assign _3773 = _3717[4:4];
    assign _3772 = _3717[3:3];
    assign _3771 = _3717[2:2];
    assign _3770 = _3717[1:1];
    assign _3769 = _3717[0:0];
    always @* begin
        case (_3763)
        0:
            _3777 <= _3769;
        1:
            _3777 <= _3770;
        2:
            _3777 <= _3771;
        3:
            _3777 <= _3772;
        4:
            _3777 <= _3773;
        5:
            _3777 <= _3774;
        6:
            _3777 <= _3775;
        default:
            _3777 <= _3776;
        endcase
    end
    assign _3768 = _3698[4:4];
    assign _3766 = { _520,
                     _3259 };
    assign _3763 = _4177 - _3295;
    assign _3764 = { gnd,
                     _3763 };
    assign _3767 = _3764 < _3766;
    assign _3778 = _3767 ? _3777 : _3768;
    assign _3759 = _3717[7:7];
    assign _3758 = _3717[6:6];
    assign _3757 = _3717[5:5];
    assign _3756 = _3717[4:4];
    assign _3755 = _3717[3:3];
    assign _3754 = _3717[2:2];
    assign _3753 = _3717[1:1];
    assign _3752 = _3717[0:0];
    always @* begin
        case (_3746)
        0:
            _3760 <= _3752;
        1:
            _3760 <= _3753;
        2:
            _3760 <= _3754;
        3:
            _3760 <= _3755;
        4:
            _3760 <= _3756;
        5:
            _3760 <= _3757;
        6:
            _3760 <= _3758;
        default:
            _3760 <= _3759;
        endcase
    end
    assign _3751 = _3698[5:5];
    assign _3749 = { _520,
                     _3259 };
    assign _3745 = 3'b101;
    assign _3746 = _3745 - _3295;
    assign _3747 = { gnd,
                     _3746 };
    assign _3750 = _3747 < _3749;
    assign _3761 = _3750 ? _3760 : _3751;
    assign _3742 = _3717[7:7];
    assign _3741 = _3717[6:6];
    assign _3740 = _3717[5:5];
    assign _3739 = _3717[4:4];
    assign _3738 = _3717[3:3];
    assign _3737 = _3717[2:2];
    assign _3736 = _3717[1:1];
    assign _3735 = _3717[0:0];
    always @* begin
        case (_3729)
        0:
            _3743 <= _3735;
        1:
            _3743 <= _3736;
        2:
            _3743 <= _3737;
        3:
            _3743 <= _3738;
        4:
            _3743 <= _3739;
        5:
            _3743 <= _3740;
        6:
            _3743 <= _3741;
        default:
            _3743 <= _3742;
        endcase
    end
    assign _3734 = _3698[6:6];
    assign _3732 = { _520,
                     _3259 };
    assign _3728 = 3'b110;
    assign _3729 = _3728 - _3295;
    assign _3730 = { gnd,
                     _3729 };
    assign _3733 = _3730 < _3732;
    assign _3744 = _3733 ? _3743 : _3734;
    assign _3725 = _3717[7:7];
    assign _3724 = _3717[6:6];
    assign _3723 = _3717[5:5];
    assign _3722 = _3717[4:4];
    assign _3721 = _3717[3:3];
    assign _3720 = _3717[2:2];
    assign _3719 = _3717[1:1];
    assign _3712 = _3710[3:2];
    assign _3713 = { _520,
                     _3712 };
    assign _3708 = _3258[3:1];
    assign _3709 = { _574,
                     _3708 };
    assign _3706 = _3703[0:0];
    assign _3710 = _3706 ? _3709 : _3258;
    assign _3705 = _3703[1:1];
    assign _3714 = _3705 ? _3713 : _3710;
    assign _3702 = { gnd,
                     _3259 };
    assign _3703 = _4177 - _3702;
    assign _3704 = _3703[2:2];
    assign _3716 = _3704 ? _301 : _3714;
    assign _3717 = { _301,
                     _3716 };
    assign _3718 = _3717[0:0];
    always @* begin
        case (_3296)
        0:
            _3726 <= _3718;
        1:
            _3726 <= _3719;
        2:
            _3726 <= _3720;
        3:
            _3726 <= _3721;
        4:
            _3726 <= _3722;
        5:
            _3726 <= _3723;
        6:
            _3726 <= _3724;
        default:
            _3726 <= _3725;
        endcase
    end
    assign _3694 = _3180[7:7];
    assign _3693 = _3180[6:6];
    assign _3692 = _3180[5:5];
    assign _3691 = _3180[4:4];
    assign _3690 = _3180[3:3];
    assign _3689 = _3180[2:2];
    assign _3688 = _3180[1:1];
    assign _3687 = _3180[0:0];
    always @* begin
        case (_3683)
        0:
            _3695 <= _3687;
        1:
            _3695 <= _3688;
        2:
            _3695 <= _3689;
        3:
            _3695 <= _3690;
        4:
            _3695 <= _3691;
        5:
            _3695 <= _3692;
        6:
            _3695 <= _3693;
        default:
            _3695 <= _3694;
        endcase
    end
    assign _3686 = _22[0:0];
    assign _3683 = _544 - _3446;
    assign _3684 = { _520,
                     _3683 };
    assign _3685 = _3684 < _2399;
    assign _3696 = _3685 ? _3695 : _3686;
    assign _3678 = _3180[7:7];
    assign _3677 = _3180[6:6];
    assign _3676 = _3180[5:5];
    assign _3675 = _3180[4:4];
    assign _3674 = _3180[3:3];
    assign _3673 = _3180[2:2];
    assign _3672 = _3180[1:1];
    assign _3671 = _3180[0:0];
    always @* begin
        case (_3667)
        0:
            _3679 <= _3671;
        1:
            _3679 <= _3672;
        2:
            _3679 <= _3673;
        3:
            _3679 <= _3674;
        4:
            _3679 <= _3675;
        5:
            _3679 <= _3676;
        6:
            _3679 <= _3677;
        default:
            _3679 <= _3678;
        endcase
    end
    assign _3670 = _22[1:1];
    assign _3667 = _1485 - _3446;
    assign _3668 = { _520,
                     _3667 };
    assign _3669 = _3668 < _2399;
    assign _3680 = _3669 ? _3679 : _3670;
    assign _3662 = _3180[7:7];
    assign _3661 = _3180[6:6];
    assign _3660 = _3180[5:5];
    assign _3659 = _3180[4:4];
    assign _3658 = _3180[3:3];
    assign _3657 = _3180[2:2];
    assign _3656 = _3180[1:1];
    assign _3655 = _3180[0:0];
    always @* begin
        case (_3651)
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
    assign _3654 = _22[2:2];
    assign _3651 = _4048 - _3446;
    assign _3652 = { _520,
                     _3651 };
    assign _3653 = _3652 < _2399;
    assign _3664 = _3653 ? _3663 : _3654;
    assign _3646 = _3180[7:7];
    assign _3645 = _3180[6:6];
    assign _3644 = _3180[5:5];
    assign _3643 = _3180[4:4];
    assign _3642 = _3180[3:3];
    assign _3641 = _3180[2:2];
    assign _3640 = _3180[1:1];
    assign _3639 = _3180[0:0];
    always @* begin
        case (_3635)
        0:
            _3647 <= _3639;
        1:
            _3647 <= _3640;
        2:
            _3647 <= _3641;
        3:
            _3647 <= _3642;
        4:
            _3647 <= _3643;
        5:
            _3647 <= _3644;
        6:
            _3647 <= _3645;
        default:
            _3647 <= _3646;
        endcase
    end
    assign _3638 = _22[3:3];
    assign _3635 = _3779 - _3446;
    assign _3636 = { _520,
                     _3635 };
    assign _3637 = _3636 < _2399;
    assign _3648 = _3637 ? _3647 : _3638;
    assign _3630 = _3180[7:7];
    assign _3629 = _3180[6:6];
    assign _3628 = _3180[5:5];
    assign _3627 = _3180[4:4];
    assign _3626 = _3180[3:3];
    assign _3625 = _3180[2:2];
    assign _3624 = _3180[1:1];
    assign _3623 = _3180[0:0];
    always @* begin
        case (_3619)
        0:
            _3631 <= _3623;
        1:
            _3631 <= _3624;
        2:
            _3631 <= _3625;
        3:
            _3631 <= _3626;
        4:
            _3631 <= _3627;
        5:
            _3631 <= _3628;
        6:
            _3631 <= _3629;
        default:
            _3631 <= _3630;
        endcase
    end
    assign _3622 = _22[4:4];
    assign _3619 = _4177 - _3446;
    assign _3620 = { _520,
                     _3619 };
    assign _3621 = _3620 < _2399;
    assign _3632 = _3621 ? _3631 : _3622;
    assign _3614 = _3180[7:7];
    assign _3613 = _3180[6:6];
    assign _3612 = _3180[5:5];
    assign _3611 = _3180[4:4];
    assign _3610 = _3180[3:3];
    assign _3609 = _3180[2:2];
    assign _3608 = _3180[1:1];
    assign _3607 = _3180[0:0];
    always @* begin
        case (_3603)
        0:
            _3615 <= _3607;
        1:
            _3615 <= _3608;
        2:
            _3615 <= _3609;
        3:
            _3615 <= _3610;
        4:
            _3615 <= _3611;
        5:
            _3615 <= _3612;
        6:
            _3615 <= _3613;
        default:
            _3615 <= _3614;
        endcase
    end
    assign _3606 = _22[5:5];
    assign _3603 = _3745 - _3446;
    assign _3604 = { _520,
                     _3603 };
    assign _3605 = _3604 < _2399;
    assign _3616 = _3605 ? _3615 : _3606;
    assign _3598 = _3180[7:7];
    assign _3597 = _3180[6:6];
    assign _3596 = _3180[5:5];
    assign _3595 = _3180[4:4];
    assign _3594 = _3180[3:3];
    assign _3593 = _3180[2:2];
    assign _3592 = _3180[1:1];
    assign _3591 = _3180[0:0];
    always @* begin
        case (_3587)
        0:
            _3599 <= _3591;
        1:
            _3599 <= _3592;
        2:
            _3599 <= _3593;
        3:
            _3599 <= _3594;
        4:
            _3599 <= _3595;
        5:
            _3599 <= _3596;
        6:
            _3599 <= _3597;
        default:
            _3599 <= _3598;
        endcase
    end
    assign _3590 = _22[6:6];
    assign _3587 = _3728 - _3446;
    assign _3588 = { _520,
                     _3587 };
    assign _3589 = _3588 < _2399;
    assign _3600 = _3589 ? _3599 : _3590;
    assign _3582 = _3180[7:7];
    assign _3581 = _3180[6:6];
    assign _3580 = _3180[5:5];
    assign _3579 = _3180[4:4];
    assign _3578 = _3180[3:3];
    assign _3577 = _3180[2:2];
    assign _3576 = _3180[1:1];
    assign _3575 = _3180[0:0];
    always @* begin
        case (_3571)
        0:
            _3583 <= _3575;
        1:
            _3583 <= _3576;
        2:
            _3583 <= _3577;
        3:
            _3583 <= _3578;
        4:
            _3583 <= _3579;
        5:
            _3583 <= _3580;
        6:
            _3583 <= _3581;
        default:
            _3583 <= _3582;
        endcase
    end
    assign _3574 = _22[7:7];
    assign _3570 = 3'b111;
    assign _3571 = _3570 - _3446;
    assign _3572 = { _520,
                     _3571 };
    assign _3573 = _3572 < _2399;
    assign _3584 = _3573 ? _3583 : _3574;
    assign _3697 = { _3584,
                     _3600,
                     _3616,
                     _3632,
                     _3648,
                     _3664,
                     _3680,
                     _3696 };
    assign _3564 = _2469[7:7];
    assign _3563 = _2469[6:6];
    assign _3562 = _2469[5:5];
    assign _3561 = _2469[4:4];
    assign _3560 = _2469[3:3];
    assign _3559 = _2469[2:2];
    assign _3558 = _2469[1:1];
    assign _3557 = _2469[0:0];
    always @* begin
        case (_3553)
        0:
            _3565 <= _3557;
        1:
            _3565 <= _3558;
        2:
            _3565 <= _3559;
        3:
            _3565 <= _3560;
        4:
            _3565 <= _3561;
        5:
            _3565 <= _3562;
        6:
            _3565 <= _3563;
        default:
            _3565 <= _3564;
        endcase
    end
    assign _3556 = _22[0:0];
    assign _3553 = _544 - _3446;
    assign _3554 = { gnd,
                     _3553 };
    assign _3555 = _3554 < _3449;
    assign _3566 = _3555 ? _3565 : _3556;
    assign _3549 = _2469[7:7];
    assign _3548 = _2469[6:6];
    assign _3547 = _2469[5:5];
    assign _3546 = _2469[4:4];
    assign _3545 = _2469[3:3];
    assign _3544 = _2469[2:2];
    assign _3543 = _2469[1:1];
    assign _3542 = _2469[0:0];
    always @* begin
        case (_3538)
        0:
            _3550 <= _3542;
        1:
            _3550 <= _3543;
        2:
            _3550 <= _3544;
        3:
            _3550 <= _3545;
        4:
            _3550 <= _3546;
        5:
            _3550 <= _3547;
        6:
            _3550 <= _3548;
        default:
            _3550 <= _3549;
        endcase
    end
    assign _3541 = _22[1:1];
    assign _3538 = _1485 - _3446;
    assign _3539 = { gnd,
                     _3538 };
    assign _3540 = _3539 < _3449;
    assign _3551 = _3540 ? _3550 : _3541;
    assign _3534 = _2469[7:7];
    assign _3533 = _2469[6:6];
    assign _3532 = _2469[5:5];
    assign _3531 = _2469[4:4];
    assign _3530 = _2469[3:3];
    assign _3529 = _2469[2:2];
    assign _3528 = _2469[1:1];
    assign _3527 = _2469[0:0];
    always @* begin
        case (_3523)
        0:
            _3535 <= _3527;
        1:
            _3535 <= _3528;
        2:
            _3535 <= _3529;
        3:
            _3535 <= _3530;
        4:
            _3535 <= _3531;
        5:
            _3535 <= _3532;
        6:
            _3535 <= _3533;
        default:
            _3535 <= _3534;
        endcase
    end
    assign _3526 = _22[2:2];
    assign _3523 = _4048 - _3446;
    assign _3524 = { gnd,
                     _3523 };
    assign _3525 = _3524 < _3449;
    assign _3536 = _3525 ? _3535 : _3526;
    assign _3519 = _2469[7:7];
    assign _3518 = _2469[6:6];
    assign _3517 = _2469[5:5];
    assign _3516 = _2469[4:4];
    assign _3515 = _2469[3:3];
    assign _3514 = _2469[2:2];
    assign _3513 = _2469[1:1];
    assign _3512 = _2469[0:0];
    always @* begin
        case (_3508)
        0:
            _3520 <= _3512;
        1:
            _3520 <= _3513;
        2:
            _3520 <= _3514;
        3:
            _3520 <= _3515;
        4:
            _3520 <= _3516;
        5:
            _3520 <= _3517;
        6:
            _3520 <= _3518;
        default:
            _3520 <= _3519;
        endcase
    end
    assign _3511 = _22[3:3];
    assign _3508 = _3779 - _3446;
    assign _3509 = { gnd,
                     _3508 };
    assign _3510 = _3509 < _3449;
    assign _3521 = _3510 ? _3520 : _3511;
    assign _3504 = _2469[7:7];
    assign _3503 = _2469[6:6];
    assign _3502 = _2469[5:5];
    assign _3501 = _2469[4:4];
    assign _3500 = _2469[3:3];
    assign _3499 = _2469[2:2];
    assign _3498 = _2469[1:1];
    assign _3497 = _2469[0:0];
    always @* begin
        case (_3493)
        0:
            _3505 <= _3497;
        1:
            _3505 <= _3498;
        2:
            _3505 <= _3499;
        3:
            _3505 <= _3500;
        4:
            _3505 <= _3501;
        5:
            _3505 <= _3502;
        6:
            _3505 <= _3503;
        default:
            _3505 <= _3504;
        endcase
    end
    assign _3496 = _22[4:4];
    assign _3493 = _4177 - _3446;
    assign _3494 = { gnd,
                     _3493 };
    assign _3495 = _3494 < _3449;
    assign _3506 = _3495 ? _3505 : _3496;
    assign _3489 = _2469[7:7];
    assign _3488 = _2469[6:6];
    assign _3487 = _2469[5:5];
    assign _3486 = _2469[4:4];
    assign _3485 = _2469[3:3];
    assign _3484 = _2469[2:2];
    assign _3483 = _2469[1:1];
    assign _3482 = _2469[0:0];
    always @* begin
        case (_3478)
        0:
            _3490 <= _3482;
        1:
            _3490 <= _3483;
        2:
            _3490 <= _3484;
        3:
            _3490 <= _3485;
        4:
            _3490 <= _3486;
        5:
            _3490 <= _3487;
        6:
            _3490 <= _3488;
        default:
            _3490 <= _3489;
        endcase
    end
    assign _3481 = _22[5:5];
    assign _3478 = _3745 - _3446;
    assign _3479 = { gnd,
                     _3478 };
    assign _3480 = _3479 < _3449;
    assign _3491 = _3480 ? _3490 : _3481;
    assign _3474 = _2469[7:7];
    assign _3473 = _2469[6:6];
    assign _3472 = _2469[5:5];
    assign _3471 = _2469[4:4];
    assign _3470 = _2469[3:3];
    assign _3469 = _2469[2:2];
    assign _3468 = _2469[1:1];
    assign _3467 = _2469[0:0];
    always @* begin
        case (_3463)
        0:
            _3475 <= _3467;
        1:
            _3475 <= _3468;
        2:
            _3475 <= _3469;
        3:
            _3475 <= _3470;
        4:
            _3475 <= _3471;
        5:
            _3475 <= _3472;
        6:
            _3475 <= _3473;
        default:
            _3475 <= _3474;
        endcase
    end
    assign _3466 = _22[6:6];
    assign _3463 = _3728 - _3446;
    assign _3464 = { gnd,
                     _3463 };
    assign _3465 = _3464 < _3449;
    assign _3476 = _3465 ? _3475 : _3466;
    assign _3459 = _2469[7:7];
    assign _3458 = _2469[6:6];
    assign _3457 = _2469[5:5];
    assign _3456 = _2469[4:4];
    assign _3455 = _2469[3:3];
    assign _3454 = _2469[2:2];
    assign _3453 = _2469[1:1];
    assign _3452 = _2469[0:0];
    always @* begin
        case (_3447)
        0:
            _3460 <= _3452;
        1:
            _3460 <= _3453;
        2:
            _3460 <= _3454;
        3:
            _3460 <= _3455;
        4:
            _3460 <= _3456;
        5:
            _3460 <= _3457;
        6:
            _3460 <= _3458;
        default:
            _3460 <= _3459;
        endcase
    end
    assign _3451 = _22[7:7];
    assign _3449 = cfg_t1_out_cfg[7:4];
    assign _491 = 8'b00010000;
    assign _1570 = _590[7:0];
    assign _1567 = 7'b1010010;
    assign _1568 = _586 == _1567;
    assign _1566 = _580 & _584;
    assign _1569 = _1566 & _1568;
    assign _1571 = _1569 ? _1570 : cfg_t1_out_cfg;
    assign _17 = _1571;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_out_cfg <= _491;
        else
            cfg_t1_out_cfg <= _17;
    end
    assign _3446 = cfg_t1_out_cfg[2:0];
    assign _3447 = _3570 - _3446;
    assign _3448 = { gnd,
                     _3447 };
    assign _3450 = _3448 < _3449;
    assign _3461 = _3450 ? _3460 : _3451;
    assign _3567 = { _3461,
                     _3476,
                     _3491,
                     _3506,
                     _3521,
                     _3536,
                     _3551,
                     _3566 };
    assign _3440 = _3138[7:7];
    assign _3439 = _3138[6:6];
    assign _3438 = _3138[5:5];
    assign _3437 = _3138[4:4];
    assign _3436 = _3138[3:3];
    assign _3435 = _3138[2:2];
    assign _3434 = _3138[1:1];
    assign _3433 = _3138[0:0];
    always @* begin
        case (_3429)
        0:
            _3441 <= _3433;
        1:
            _3441 <= _3434;
        2:
            _3441 <= _3435;
        3:
            _3441 <= _3436;
        4:
            _3441 <= _3437;
        5:
            _3441 <= _3438;
        6:
            _3441 <= _3439;
        default:
            _3441 <= _3440;
        endcase
    end
    assign _3432 = _22[0:0];
    assign _3429 = _544 - _3322;
    assign _3430 = { gnd,
                     _3429 };
    assign _3431 = _3430 < _3325;
    assign _3442 = _3431 ? _3441 : _3432;
    assign _3425 = _3138[7:7];
    assign _3424 = _3138[6:6];
    assign _3423 = _3138[5:5];
    assign _3422 = _3138[4:4];
    assign _3421 = _3138[3:3];
    assign _3420 = _3138[2:2];
    assign _3419 = _3138[1:1];
    assign _3418 = _3138[0:0];
    always @* begin
        case (_3414)
        0:
            _3426 <= _3418;
        1:
            _3426 <= _3419;
        2:
            _3426 <= _3420;
        3:
            _3426 <= _3421;
        4:
            _3426 <= _3422;
        5:
            _3426 <= _3423;
        6:
            _3426 <= _3424;
        default:
            _3426 <= _3425;
        endcase
    end
    assign _3417 = _22[1:1];
    assign _3414 = _1485 - _3322;
    assign _3415 = { gnd,
                     _3414 };
    assign _3416 = _3415 < _3325;
    assign _3427 = _3416 ? _3426 : _3417;
    assign _3410 = _3138[7:7];
    assign _3409 = _3138[6:6];
    assign _3408 = _3138[5:5];
    assign _3407 = _3138[4:4];
    assign _3406 = _3138[3:3];
    assign _3405 = _3138[2:2];
    assign _3404 = _3138[1:1];
    assign _3403 = _3138[0:0];
    always @* begin
        case (_3399)
        0:
            _3411 <= _3403;
        1:
            _3411 <= _3404;
        2:
            _3411 <= _3405;
        3:
            _3411 <= _3406;
        4:
            _3411 <= _3407;
        5:
            _3411 <= _3408;
        6:
            _3411 <= _3409;
        default:
            _3411 <= _3410;
        endcase
    end
    assign _3402 = _22[2:2];
    assign _3399 = _4048 - _3322;
    assign _3400 = { gnd,
                     _3399 };
    assign _3401 = _3400 < _3325;
    assign _3412 = _3401 ? _3411 : _3402;
    assign _3395 = _3138[7:7];
    assign _3394 = _3138[6:6];
    assign _3393 = _3138[5:5];
    assign _3392 = _3138[4:4];
    assign _3391 = _3138[3:3];
    assign _3390 = _3138[2:2];
    assign _3389 = _3138[1:1];
    assign _3388 = _3138[0:0];
    always @* begin
        case (_3384)
        0:
            _3396 <= _3388;
        1:
            _3396 <= _3389;
        2:
            _3396 <= _3390;
        3:
            _3396 <= _3391;
        4:
            _3396 <= _3392;
        5:
            _3396 <= _3393;
        6:
            _3396 <= _3394;
        default:
            _3396 <= _3395;
        endcase
    end
    assign _3387 = _22[3:3];
    assign _3384 = _3779 - _3322;
    assign _3385 = { gnd,
                     _3384 };
    assign _3386 = _3385 < _3325;
    assign _3397 = _3386 ? _3396 : _3387;
    assign _3380 = _3138[7:7];
    assign _3379 = _3138[6:6];
    assign _3378 = _3138[5:5];
    assign _3377 = _3138[4:4];
    assign _3376 = _3138[3:3];
    assign _3375 = _3138[2:2];
    assign _3374 = _3138[1:1];
    assign _3373 = _3138[0:0];
    always @* begin
        case (_3369)
        0:
            _3381 <= _3373;
        1:
            _3381 <= _3374;
        2:
            _3381 <= _3375;
        3:
            _3381 <= _3376;
        4:
            _3381 <= _3377;
        5:
            _3381 <= _3378;
        6:
            _3381 <= _3379;
        default:
            _3381 <= _3380;
        endcase
    end
    assign _3372 = _22[4:4];
    assign _3369 = _4177 - _3322;
    assign _3370 = { gnd,
                     _3369 };
    assign _3371 = _3370 < _3325;
    assign _3382 = _3371 ? _3381 : _3372;
    assign _3365 = _3138[7:7];
    assign _3364 = _3138[6:6];
    assign _3363 = _3138[5:5];
    assign _3362 = _3138[4:4];
    assign _3361 = _3138[3:3];
    assign _3360 = _3138[2:2];
    assign _3359 = _3138[1:1];
    assign _3358 = _3138[0:0];
    always @* begin
        case (_3354)
        0:
            _3366 <= _3358;
        1:
            _3366 <= _3359;
        2:
            _3366 <= _3360;
        3:
            _3366 <= _3361;
        4:
            _3366 <= _3362;
        5:
            _3366 <= _3363;
        6:
            _3366 <= _3364;
        default:
            _3366 <= _3365;
        endcase
    end
    assign _3357 = _22[5:5];
    assign _3354 = _3745 - _3322;
    assign _3355 = { gnd,
                     _3354 };
    assign _3356 = _3355 < _3325;
    assign _3367 = _3356 ? _3366 : _3357;
    assign _3350 = _3138[7:7];
    assign _3349 = _3138[6:6];
    assign _3348 = _3138[5:5];
    assign _3347 = _3138[4:4];
    assign _3346 = _3138[3:3];
    assign _3345 = _3138[2:2];
    assign _3344 = _3138[1:1];
    assign _3343 = _3138[0:0];
    always @* begin
        case (_3339)
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
    assign _3342 = _22[6:6];
    assign _3339 = _3728 - _3322;
    assign _3340 = { gnd,
                     _3339 };
    assign _3341 = _3340 < _3325;
    assign _3352 = _3341 ? _3351 : _3342;
    assign _3335 = _3138[7:7];
    assign _3334 = _3138[6:6];
    assign _3333 = _3138[5:5];
    assign _3332 = _3138[4:4];
    assign _3331 = _3138[3:3];
    assign _3330 = _3138[2:2];
    assign _3329 = _3138[1:1];
    assign _3328 = _3138[0:0];
    always @* begin
        case (_3323)
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
    assign _3327 = _22[7:7];
    assign _3325 = cfg_t1_set_cfg[7:4];
    assign _1576 = _590[7:0];
    assign _1573 = 7'b1010011;
    assign _1574 = _586 == _1573;
    assign _1572 = _580 & _584;
    assign _1575 = _1572 & _1574;
    assign _1577 = _1575 ? _1576 : cfg_t1_set_cfg;
    assign _18 = _1577;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_set_cfg <= _491;
        else
            cfg_t1_set_cfg <= _18;
    end
    assign _3322 = cfg_t1_set_cfg[2:0];
    assign _3323 = _3570 - _3322;
    assign _3324 = { gnd,
                     _3323 };
    assign _3326 = _3324 < _3325;
    assign _3337 = _3326 ? _3336 : _3327;
    assign _3443 = { _3337,
                     _3352,
                     _3367,
                     _3382,
                     _3397,
                     _3412,
                     _3427,
                     _3442 };
    assign _2227 = _2100[7:7];
    assign _2226 = _2100[6:6];
    assign _2225 = _2100[5:5];
    assign _2224 = _2100[4:4];
    assign _2223 = _2100[3:3];
    assign _2222 = _2100[2:2];
    assign _2221 = _2100[1:1];
    assign _2220 = _2100[0:0];
    always @* begin
        case (_2214)
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
    assign _2219 = _2080[0:0];
    assign _2217 = { _520,
                     _1601 };
    assign _2214 = _544 - _1597;
    assign _2215 = { gnd,
                     _2214 };
    assign _2218 = _2215 < _2217;
    assign _2229 = _2218 ? _2228 : _2219;
    assign _2210 = _2100[7:7];
    assign _2209 = _2100[6:6];
    assign _2208 = _2100[5:5];
    assign _2207 = _2100[4:4];
    assign _2206 = _2100[3:3];
    assign _2205 = _2100[2:2];
    assign _2204 = _2100[1:1];
    assign _2203 = _2100[0:0];
    always @* begin
        case (_2197)
        0:
            _2211 <= _2203;
        1:
            _2211 <= _2204;
        2:
            _2211 <= _2205;
        3:
            _2211 <= _2206;
        4:
            _2211 <= _2207;
        5:
            _2211 <= _2208;
        6:
            _2211 <= _2209;
        default:
            _2211 <= _2210;
        endcase
    end
    assign _2202 = _2080[1:1];
    assign _2200 = { _520,
                     _1601 };
    assign _2197 = _1485 - _1597;
    assign _2198 = { gnd,
                     _2197 };
    assign _2201 = _2198 < _2200;
    assign _2212 = _2201 ? _2211 : _2202;
    assign _2193 = _2100[7:7];
    assign _2192 = _2100[6:6];
    assign _2191 = _2100[5:5];
    assign _2190 = _2100[4:4];
    assign _2189 = _2100[3:3];
    assign _2188 = _2100[2:2];
    assign _2187 = _2100[1:1];
    assign _2186 = _2100[0:0];
    always @* begin
        case (_2180)
        0:
            _2194 <= _2186;
        1:
            _2194 <= _2187;
        2:
            _2194 <= _2188;
        3:
            _2194 <= _2189;
        4:
            _2194 <= _2190;
        5:
            _2194 <= _2191;
        6:
            _2194 <= _2192;
        default:
            _2194 <= _2193;
        endcase
    end
    assign _2185 = _2080[2:2];
    assign _2183 = { _520,
                     _1601 };
    assign _2180 = _4048 - _1597;
    assign _2181 = { gnd,
                     _2180 };
    assign _2184 = _2181 < _2183;
    assign _2195 = _2184 ? _2194 : _2185;
    assign _2176 = _2100[7:7];
    assign _2175 = _2100[6:6];
    assign _2174 = _2100[5:5];
    assign _2173 = _2100[4:4];
    assign _2172 = _2100[3:3];
    assign _2171 = _2100[2:2];
    assign _2170 = _2100[1:1];
    assign _2169 = _2100[0:0];
    always @* begin
        case (_2163)
        0:
            _2177 <= _2169;
        1:
            _2177 <= _2170;
        2:
            _2177 <= _2171;
        3:
            _2177 <= _2172;
        4:
            _2177 <= _2173;
        5:
            _2177 <= _2174;
        6:
            _2177 <= _2175;
        default:
            _2177 <= _2176;
        endcase
    end
    assign _2168 = _2080[3:3];
    assign _2166 = { _520,
                     _1601 };
    assign _2163 = _3779 - _1597;
    assign _2164 = { gnd,
                     _2163 };
    assign _2167 = _2164 < _2166;
    assign _2178 = _2167 ? _2177 : _2168;
    assign _2159 = _2100[7:7];
    assign _2158 = _2100[6:6];
    assign _2157 = _2100[5:5];
    assign _2156 = _2100[4:4];
    assign _2155 = _2100[3:3];
    assign _2154 = _2100[2:2];
    assign _2153 = _2100[1:1];
    assign _2152 = _2100[0:0];
    always @* begin
        case (_2146)
        0:
            _2160 <= _2152;
        1:
            _2160 <= _2153;
        2:
            _2160 <= _2154;
        3:
            _2160 <= _2155;
        4:
            _2160 <= _2156;
        5:
            _2160 <= _2157;
        6:
            _2160 <= _2158;
        default:
            _2160 <= _2159;
        endcase
    end
    assign _2151 = _2080[4:4];
    assign _2149 = { _520,
                     _1601 };
    assign _2146 = _4177 - _1597;
    assign _2147 = { gnd,
                     _2146 };
    assign _2150 = _2147 < _2149;
    assign _2161 = _2150 ? _2160 : _2151;
    assign _2142 = _2100[7:7];
    assign _2141 = _2100[6:6];
    assign _2140 = _2100[5:5];
    assign _2139 = _2100[4:4];
    assign _2138 = _2100[3:3];
    assign _2137 = _2100[2:2];
    assign _2136 = _2100[1:1];
    assign _2135 = _2100[0:0];
    always @* begin
        case (_2129)
        0:
            _2143 <= _2135;
        1:
            _2143 <= _2136;
        2:
            _2143 <= _2137;
        3:
            _2143 <= _2138;
        4:
            _2143 <= _2139;
        5:
            _2143 <= _2140;
        6:
            _2143 <= _2141;
        default:
            _2143 <= _2142;
        endcase
    end
    assign _2134 = _2080[5:5];
    assign _2132 = { _520,
                     _1601 };
    assign _2129 = _3745 - _1597;
    assign _2130 = { gnd,
                     _2129 };
    assign _2133 = _2130 < _2132;
    assign _2144 = _2133 ? _2143 : _2134;
    assign _2125 = _2100[7:7];
    assign _2124 = _2100[6:6];
    assign _2123 = _2100[5:5];
    assign _2122 = _2100[4:4];
    assign _2121 = _2100[3:3];
    assign _2120 = _2100[2:2];
    assign _2119 = _2100[1:1];
    assign _2118 = _2100[0:0];
    always @* begin
        case (_2112)
        0:
            _2126 <= _2118;
        1:
            _2126 <= _2119;
        2:
            _2126 <= _2120;
        3:
            _2126 <= _2121;
        4:
            _2126 <= _2122;
        5:
            _2126 <= _2123;
        6:
            _2126 <= _2124;
        default:
            _2126 <= _2125;
        endcase
    end
    assign _2117 = _2080[6:6];
    assign _2115 = { _520,
                     _1601 };
    assign _2112 = _3728 - _1597;
    assign _2113 = { gnd,
                     _2112 };
    assign _2116 = _2113 < _2115;
    assign _2127 = _2116 ? _2126 : _2117;
    assign _2108 = _2100[7:7];
    assign _2107 = _2100[6:6];
    assign _2106 = _2100[5:5];
    assign _2105 = _2100[4:4];
    assign _2104 = _2100[3:3];
    assign _2103 = _2100[2:2];
    assign _2102 = _2100[1:1];
    assign _2095 = _2093[3:2];
    assign _2096 = { _520,
                     _2095 };
    assign _2091 = _2089[3:1];
    assign _2092 = { _574,
                     _2091 };
    assign _2089 = _1388[12:9];
    assign _2088 = _2085[0:0];
    assign _2093 = _2088 ? _2092 : _2089;
    assign _2087 = _2085[1:1];
    assign _2097 = _2087 ? _2096 : _2093;
    assign _2084 = { gnd,
                     _1601 };
    assign _2085 = _4177 - _2084;
    assign _2086 = _2085[2:2];
    assign _2099 = _2086 ? _301 : _2097;
    assign _2100 = { _301,
                     _2099 };
    assign _2101 = _2100[0:0];
    always @* begin
        case (_1598)
        0:
            _2109 <= _2101;
        1:
            _2109 <= _2102;
        2:
            _2109 <= _2103;
        3:
            _2109 <= _2104;
        4:
            _2109 <= _2105;
        5:
            _2109 <= _2106;
        6:
            _2109 <= _2107;
        default:
            _2109 <= _2108;
        endcase
    end
    assign _2076 = _1956[7:7];
    assign _2075 = _1956[6:6];
    assign _2074 = _1956[5:5];
    assign _2073 = _1956[4:4];
    assign _2072 = _1956[3:3];
    assign _2071 = _1956[2:2];
    assign _2070 = _1956[1:1];
    assign _2069 = _1956[0:0];
    always @* begin
        case (_2065)
        0:
            _2077 <= _2069;
        1:
            _2077 <= _2070;
        2:
            _2077 <= _2071;
        3:
            _2077 <= _2072;
        4:
            _2077 <= _2073;
        5:
            _2077 <= _2074;
        6:
            _2077 <= _2075;
        default:
            _2077 <= _2076;
        endcase
    end
    assign _2068 = pin_out[0:0];
    assign _2065 = _544 - _1753;
    assign _2066 = { _520,
                     _2065 };
    assign _2067 = _2066 < _1554;
    assign _2078 = _2067 ? _2077 : _2068;
    assign _2060 = _1956[7:7];
    assign _2059 = _1956[6:6];
    assign _2058 = _1956[5:5];
    assign _2057 = _1956[4:4];
    assign _2056 = _1956[3:3];
    assign _2055 = _1956[2:2];
    assign _2054 = _1956[1:1];
    assign _2053 = _1956[0:0];
    always @* begin
        case (_2049)
        0:
            _2061 <= _2053;
        1:
            _2061 <= _2054;
        2:
            _2061 <= _2055;
        3:
            _2061 <= _2056;
        4:
            _2061 <= _2057;
        5:
            _2061 <= _2058;
        6:
            _2061 <= _2059;
        default:
            _2061 <= _2060;
        endcase
    end
    assign _2052 = pin_out[1:1];
    assign _2049 = _1485 - _1753;
    assign _2050 = { _520,
                     _2049 };
    assign _2051 = _2050 < _1554;
    assign _2062 = _2051 ? _2061 : _2052;
    assign _2044 = _1956[7:7];
    assign _2043 = _1956[6:6];
    assign _2042 = _1956[5:5];
    assign _2041 = _1956[4:4];
    assign _2040 = _1956[3:3];
    assign _2039 = _1956[2:2];
    assign _2038 = _1956[1:1];
    assign _2037 = _1956[0:0];
    always @* begin
        case (_2033)
        0:
            _2045 <= _2037;
        1:
            _2045 <= _2038;
        2:
            _2045 <= _2039;
        3:
            _2045 <= _2040;
        4:
            _2045 <= _2041;
        5:
            _2045 <= _2042;
        6:
            _2045 <= _2043;
        default:
            _2045 <= _2044;
        endcase
    end
    assign _2036 = pin_out[2:2];
    assign _2033 = _4048 - _1753;
    assign _2034 = { _520,
                     _2033 };
    assign _2035 = _2034 < _1554;
    assign _2046 = _2035 ? _2045 : _2036;
    assign _2028 = _1956[7:7];
    assign _2027 = _1956[6:6];
    assign _2026 = _1956[5:5];
    assign _2025 = _1956[4:4];
    assign _2024 = _1956[3:3];
    assign _2023 = _1956[2:2];
    assign _2022 = _1956[1:1];
    assign _2021 = _1956[0:0];
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
    assign _2020 = pin_out[3:3];
    assign _2017 = _3779 - _1753;
    assign _2018 = { _520,
                     _2017 };
    assign _2019 = _2018 < _1554;
    assign _2030 = _2019 ? _2029 : _2020;
    assign _2012 = _1956[7:7];
    assign _2011 = _1956[6:6];
    assign _2010 = _1956[5:5];
    assign _2009 = _1956[4:4];
    assign _2008 = _1956[3:3];
    assign _2007 = _1956[2:2];
    assign _2006 = _1956[1:1];
    assign _2005 = _1956[0:0];
    always @* begin
        case (_2001)
        0:
            _2013 <= _2005;
        1:
            _2013 <= _2006;
        2:
            _2013 <= _2007;
        3:
            _2013 <= _2008;
        4:
            _2013 <= _2009;
        5:
            _2013 <= _2010;
        6:
            _2013 <= _2011;
        default:
            _2013 <= _2012;
        endcase
    end
    assign _2004 = pin_out[4:4];
    assign _2001 = _4177 - _1753;
    assign _2002 = { _520,
                     _2001 };
    assign _2003 = _2002 < _1554;
    assign _2014 = _2003 ? _2013 : _2004;
    assign _1996 = _1956[7:7];
    assign _1995 = _1956[6:6];
    assign _1994 = _1956[5:5];
    assign _1993 = _1956[4:4];
    assign _1992 = _1956[3:3];
    assign _1991 = _1956[2:2];
    assign _1990 = _1956[1:1];
    assign _1989 = _1956[0:0];
    always @* begin
        case (_1985)
        0:
            _1997 <= _1989;
        1:
            _1997 <= _1990;
        2:
            _1997 <= _1991;
        3:
            _1997 <= _1992;
        4:
            _1997 <= _1993;
        5:
            _1997 <= _1994;
        6:
            _1997 <= _1995;
        default:
            _1997 <= _1996;
        endcase
    end
    assign _1988 = pin_out[5:5];
    assign _1985 = _3745 - _1753;
    assign _1986 = { _520,
                     _1985 };
    assign _1987 = _1986 < _1554;
    assign _1998 = _1987 ? _1997 : _1988;
    assign _1980 = _1956[7:7];
    assign _1979 = _1956[6:6];
    assign _1978 = _1956[5:5];
    assign _1977 = _1956[4:4];
    assign _1976 = _1956[3:3];
    assign _1975 = _1956[2:2];
    assign _1974 = _1956[1:1];
    assign _1973 = _1956[0:0];
    always @* begin
        case (_1969)
        0:
            _1981 <= _1973;
        1:
            _1981 <= _1974;
        2:
            _1981 <= _1975;
        3:
            _1981 <= _1976;
        4:
            _1981 <= _1977;
        5:
            _1981 <= _1978;
        6:
            _1981 <= _1979;
        default:
            _1981 <= _1980;
        endcase
    end
    assign _1972 = pin_out[6:6];
    assign _1969 = _3728 - _1753;
    assign _1970 = { _520,
                     _1969 };
    assign _1971 = _1970 < _1554;
    assign _1982 = _1971 ? _1981 : _1972;
    assign _1964 = _1956[7:7];
    assign _1963 = _1956[6:6];
    assign _1962 = _1956[5:5];
    assign _1961 = _1956[4:4];
    assign _1960 = _1956[3:3];
    assign _1959 = _1956[2:2];
    assign _1958 = _1956[1:1];
    assign _1957 = _1956[0:0];
    always @* begin
        case (_1894)
        0:
            _1965 <= _1957;
        1:
            _1965 <= _1958;
        2:
            _1965 <= _1959;
        3:
            _1965 <= _1960;
        4:
            _1965 <= _1961;
        5:
            _1965 <= _1962;
        6:
            _1965 <= _1963;
        default:
            _1965 <= _1964;
        endcase
    end
    assign _1897 = pin_out[7:7];
    assign _1894 = _3570 - _1753;
    assign _1895 = { _520,
                     _1894 };
    assign _1896 = _1895 < _1554;
    assign _1966 = _1896 ? _1965 : _1897;
    assign _2079 = { _1966,
                     _1982,
                     _1998,
                     _2014,
                     _2030,
                     _2046,
                     _2062,
                     _2078 };
    assign _1887 = _1774[7:7];
    assign _1886 = _1774[6:6];
    assign _1885 = _1774[5:5];
    assign _1884 = _1774[4:4];
    assign _1883 = _1774[3:3];
    assign _1882 = _1774[2:2];
    assign _1881 = _1774[1:1];
    assign _1880 = _1774[0:0];
    always @* begin
        case (_1876)
        0:
            _1888 <= _1880;
        1:
            _1888 <= _1881;
        2:
            _1888 <= _1882;
        3:
            _1888 <= _1883;
        4:
            _1888 <= _1884;
        5:
            _1888 <= _1885;
        6:
            _1888 <= _1886;
        default:
            _1888 <= _1887;
        endcase
    end
    assign _1879 = pin_out[0:0];
    assign _1876 = _544 - _1753;
    assign _1877 = { gnd,
                     _1876 };
    assign _1878 = _1877 < _1756;
    assign _1889 = _1878 ? _1888 : _1879;
    assign _1872 = _1774[7:7];
    assign _1871 = _1774[6:6];
    assign _1870 = _1774[5:5];
    assign _1869 = _1774[4:4];
    assign _1868 = _1774[3:3];
    assign _1867 = _1774[2:2];
    assign _1866 = _1774[1:1];
    assign _1865 = _1774[0:0];
    always @* begin
        case (_1861)
        0:
            _1873 <= _1865;
        1:
            _1873 <= _1866;
        2:
            _1873 <= _1867;
        3:
            _1873 <= _1868;
        4:
            _1873 <= _1869;
        5:
            _1873 <= _1870;
        6:
            _1873 <= _1871;
        default:
            _1873 <= _1872;
        endcase
    end
    assign _1864 = pin_out[1:1];
    assign _1861 = _1485 - _1753;
    assign _1862 = { gnd,
                     _1861 };
    assign _1863 = _1862 < _1756;
    assign _1874 = _1863 ? _1873 : _1864;
    assign _1857 = _1774[7:7];
    assign _1856 = _1774[6:6];
    assign _1855 = _1774[5:5];
    assign _1854 = _1774[4:4];
    assign _1853 = _1774[3:3];
    assign _1852 = _1774[2:2];
    assign _1851 = _1774[1:1];
    assign _1850 = _1774[0:0];
    always @* begin
        case (_1846)
        0:
            _1858 <= _1850;
        1:
            _1858 <= _1851;
        2:
            _1858 <= _1852;
        3:
            _1858 <= _1853;
        4:
            _1858 <= _1854;
        5:
            _1858 <= _1855;
        6:
            _1858 <= _1856;
        default:
            _1858 <= _1857;
        endcase
    end
    assign _1849 = pin_out[2:2];
    assign _1846 = _4048 - _1753;
    assign _1847 = { gnd,
                     _1846 };
    assign _1848 = _1847 < _1756;
    assign _1859 = _1848 ? _1858 : _1849;
    assign _1842 = _1774[7:7];
    assign _1841 = _1774[6:6];
    assign _1840 = _1774[5:5];
    assign _1839 = _1774[4:4];
    assign _1838 = _1774[3:3];
    assign _1837 = _1774[2:2];
    assign _1836 = _1774[1:1];
    assign _1835 = _1774[0:0];
    always @* begin
        case (_1831)
        0:
            _1843 <= _1835;
        1:
            _1843 <= _1836;
        2:
            _1843 <= _1837;
        3:
            _1843 <= _1838;
        4:
            _1843 <= _1839;
        5:
            _1843 <= _1840;
        6:
            _1843 <= _1841;
        default:
            _1843 <= _1842;
        endcase
    end
    assign _1834 = pin_out[3:3];
    assign _1831 = _3779 - _1753;
    assign _1832 = { gnd,
                     _1831 };
    assign _1833 = _1832 < _1756;
    assign _1844 = _1833 ? _1843 : _1834;
    assign _1827 = _1774[7:7];
    assign _1826 = _1774[6:6];
    assign _1825 = _1774[5:5];
    assign _1824 = _1774[4:4];
    assign _1823 = _1774[3:3];
    assign _1822 = _1774[2:2];
    assign _1821 = _1774[1:1];
    assign _1820 = _1774[0:0];
    always @* begin
        case (_1816)
        0:
            _1828 <= _1820;
        1:
            _1828 <= _1821;
        2:
            _1828 <= _1822;
        3:
            _1828 <= _1823;
        4:
            _1828 <= _1824;
        5:
            _1828 <= _1825;
        6:
            _1828 <= _1826;
        default:
            _1828 <= _1827;
        endcase
    end
    assign _1819 = pin_out[4:4];
    assign _1816 = _4177 - _1753;
    assign _1817 = { gnd,
                     _1816 };
    assign _1818 = _1817 < _1756;
    assign _1829 = _1818 ? _1828 : _1819;
    assign _1812 = _1774[7:7];
    assign _1811 = _1774[6:6];
    assign _1810 = _1774[5:5];
    assign _1809 = _1774[4:4];
    assign _1808 = _1774[3:3];
    assign _1807 = _1774[2:2];
    assign _1806 = _1774[1:1];
    assign _1805 = _1774[0:0];
    always @* begin
        case (_1801)
        0:
            _1813 <= _1805;
        1:
            _1813 <= _1806;
        2:
            _1813 <= _1807;
        3:
            _1813 <= _1808;
        4:
            _1813 <= _1809;
        5:
            _1813 <= _1810;
        6:
            _1813 <= _1811;
        default:
            _1813 <= _1812;
        endcase
    end
    assign _1804 = pin_out[5:5];
    assign _1801 = _3745 - _1753;
    assign _1802 = { gnd,
                     _1801 };
    assign _1803 = _1802 < _1756;
    assign _1814 = _1803 ? _1813 : _1804;
    assign _1797 = _1774[7:7];
    assign _1796 = _1774[6:6];
    assign _1795 = _1774[5:5];
    assign _1794 = _1774[4:4];
    assign _1793 = _1774[3:3];
    assign _1792 = _1774[2:2];
    assign _1791 = _1774[1:1];
    assign _1790 = _1774[0:0];
    always @* begin
        case (_1786)
        0:
            _1798 <= _1790;
        1:
            _1798 <= _1791;
        2:
            _1798 <= _1792;
        3:
            _1798 <= _1793;
        4:
            _1798 <= _1794;
        5:
            _1798 <= _1795;
        6:
            _1798 <= _1796;
        default:
            _1798 <= _1797;
        endcase
    end
    assign _1789 = pin_out[6:6];
    assign _1786 = _3728 - _1753;
    assign _1787 = { gnd,
                     _1786 };
    assign _1788 = _1787 < _1756;
    assign _1799 = _1788 ? _1798 : _1789;
    assign _1782 = _1774[7:7];
    assign _1781 = _1774[6:6];
    assign _1780 = _1774[5:5];
    assign _1779 = _1774[4:4];
    assign _1778 = _1774[3:3];
    assign _1777 = _1774[2:2];
    assign _1776 = _1774[1:1];
    assign _1775 = _1774[0:0];
    always @* begin
        case (_1754)
        0:
            _1783 <= _1775;
        1:
            _1783 <= _1776;
        2:
            _1783 <= _1777;
        3:
            _1783 <= _1778;
        4:
            _1783 <= _1779;
        5:
            _1783 <= _1780;
        6:
            _1783 <= _1781;
        default:
            _1783 <= _1782;
        endcase
    end
    assign _1758 = pin_out[7:7];
    assign _1756 = cfg_t0_out_cfg[7:4];
    assign _1582 = _590[7:0];
    assign _1579 = 7'b1000010;
    assign _1580 = _586 == _1579;
    assign _1578 = _580 & _584;
    assign _1581 = _1578 & _1580;
    assign _1583 = _1581 ? _1582 : cfg_t0_out_cfg;
    assign _19 = _1583;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_out_cfg <= _491;
        else
            cfg_t0_out_cfg <= _19;
    end
    assign _1753 = cfg_t0_out_cfg[2:0];
    assign _1754 = _3570 - _1753;
    assign _1755 = { gnd,
                     _1754 };
    assign _1757 = _1755 < _1756;
    assign _1784 = _1757 ? _1783 : _1758;
    assign _1890 = { _1784,
                     _1799,
                     _1814,
                     _1829,
                     _1844,
                     _1859,
                     _1874,
                     _1889 };
    assign _1747 = _1634[7:7];
    assign _1746 = _1634[6:6];
    assign _1745 = _1634[5:5];
    assign _1744 = _1634[4:4];
    assign _1743 = _1634[3:3];
    assign _1742 = _1634[2:2];
    assign _1741 = _1634[1:1];
    assign _1740 = _1634[0:0];
    always @* begin
        case (_1736)
        0:
            _1748 <= _1740;
        1:
            _1748 <= _1741;
        2:
            _1748 <= _1742;
        3:
            _1748 <= _1743;
        4:
            _1748 <= _1744;
        5:
            _1748 <= _1745;
        6:
            _1748 <= _1746;
        default:
            _1748 <= _1747;
        endcase
    end
    assign _1739 = pin_out[0:0];
    assign _1736 = _544 - _1626;
    assign _1737 = { gnd,
                     _1736 };
    assign _1738 = _1737 < _1629;
    assign _1749 = _1738 ? _1748 : _1739;
    assign _1732 = _1634[7:7];
    assign _1731 = _1634[6:6];
    assign _1730 = _1634[5:5];
    assign _1729 = _1634[4:4];
    assign _1728 = _1634[3:3];
    assign _1727 = _1634[2:2];
    assign _1726 = _1634[1:1];
    assign _1725 = _1634[0:0];
    always @* begin
        case (_1721)
        0:
            _1733 <= _1725;
        1:
            _1733 <= _1726;
        2:
            _1733 <= _1727;
        3:
            _1733 <= _1728;
        4:
            _1733 <= _1729;
        5:
            _1733 <= _1730;
        6:
            _1733 <= _1731;
        default:
            _1733 <= _1732;
        endcase
    end
    assign _1724 = pin_out[1:1];
    assign _1721 = _1485 - _1626;
    assign _1722 = { gnd,
                     _1721 };
    assign _1723 = _1722 < _1629;
    assign _1734 = _1723 ? _1733 : _1724;
    assign _1717 = _1634[7:7];
    assign _1716 = _1634[6:6];
    assign _1715 = _1634[5:5];
    assign _1714 = _1634[4:4];
    assign _1713 = _1634[3:3];
    assign _1712 = _1634[2:2];
    assign _1711 = _1634[1:1];
    assign _1710 = _1634[0:0];
    always @* begin
        case (_1706)
        0:
            _1718 <= _1710;
        1:
            _1718 <= _1711;
        2:
            _1718 <= _1712;
        3:
            _1718 <= _1713;
        4:
            _1718 <= _1714;
        5:
            _1718 <= _1715;
        6:
            _1718 <= _1716;
        default:
            _1718 <= _1717;
        endcase
    end
    assign _1709 = pin_out[2:2];
    assign _1706 = _4048 - _1626;
    assign _1707 = { gnd,
                     _1706 };
    assign _1708 = _1707 < _1629;
    assign _1719 = _1708 ? _1718 : _1709;
    assign _1702 = _1634[7:7];
    assign _1701 = _1634[6:6];
    assign _1700 = _1634[5:5];
    assign _1699 = _1634[4:4];
    assign _1698 = _1634[3:3];
    assign _1697 = _1634[2:2];
    assign _1696 = _1634[1:1];
    assign _1695 = _1634[0:0];
    always @* begin
        case (_1691)
        0:
            _1703 <= _1695;
        1:
            _1703 <= _1696;
        2:
            _1703 <= _1697;
        3:
            _1703 <= _1698;
        4:
            _1703 <= _1699;
        5:
            _1703 <= _1700;
        6:
            _1703 <= _1701;
        default:
            _1703 <= _1702;
        endcase
    end
    assign _1694 = pin_out[3:3];
    assign _1691 = _3779 - _1626;
    assign _1692 = { gnd,
                     _1691 };
    assign _1693 = _1692 < _1629;
    assign _1704 = _1693 ? _1703 : _1694;
    assign _1687 = _1634[7:7];
    assign _1686 = _1634[6:6];
    assign _1685 = _1634[5:5];
    assign _1684 = _1634[4:4];
    assign _1683 = _1634[3:3];
    assign _1682 = _1634[2:2];
    assign _1681 = _1634[1:1];
    assign _1680 = _1634[0:0];
    always @* begin
        case (_1676)
        0:
            _1688 <= _1680;
        1:
            _1688 <= _1681;
        2:
            _1688 <= _1682;
        3:
            _1688 <= _1683;
        4:
            _1688 <= _1684;
        5:
            _1688 <= _1685;
        6:
            _1688 <= _1686;
        default:
            _1688 <= _1687;
        endcase
    end
    assign _1679 = pin_out[4:4];
    assign _1676 = _4177 - _1626;
    assign _1677 = { gnd,
                     _1676 };
    assign _1678 = _1677 < _1629;
    assign _1689 = _1678 ? _1688 : _1679;
    assign _1672 = _1634[7:7];
    assign _1671 = _1634[6:6];
    assign _1670 = _1634[5:5];
    assign _1669 = _1634[4:4];
    assign _1668 = _1634[3:3];
    assign _1667 = _1634[2:2];
    assign _1666 = _1634[1:1];
    assign _1665 = _1634[0:0];
    always @* begin
        case (_1661)
        0:
            _1673 <= _1665;
        1:
            _1673 <= _1666;
        2:
            _1673 <= _1667;
        3:
            _1673 <= _1668;
        4:
            _1673 <= _1669;
        5:
            _1673 <= _1670;
        6:
            _1673 <= _1671;
        default:
            _1673 <= _1672;
        endcase
    end
    assign _1664 = pin_out[5:5];
    assign _1661 = _3745 - _1626;
    assign _1662 = { gnd,
                     _1661 };
    assign _1663 = _1662 < _1629;
    assign _1674 = _1663 ? _1673 : _1664;
    assign _1657 = _1634[7:7];
    assign _1656 = _1634[6:6];
    assign _1655 = _1634[5:5];
    assign _1654 = _1634[4:4];
    assign _1653 = _1634[3:3];
    assign _1652 = _1634[2:2];
    assign _1651 = _1634[1:1];
    assign _1650 = _1634[0:0];
    always @* begin
        case (_1646)
        0:
            _1658 <= _1650;
        1:
            _1658 <= _1651;
        2:
            _1658 <= _1652;
        3:
            _1658 <= _1653;
        4:
            _1658 <= _1654;
        5:
            _1658 <= _1655;
        6:
            _1658 <= _1656;
        default:
            _1658 <= _1657;
        endcase
    end
    assign _1649 = pin_out[6:6];
    assign _1646 = _3728 - _1626;
    assign _1647 = { gnd,
                     _1646 };
    assign _1648 = _1647 < _1629;
    assign _1659 = _1648 ? _1658 : _1649;
    assign _1642 = _1634[7:7];
    assign _1641 = _1634[6:6];
    assign _1640 = _1634[5:5];
    assign _1639 = _1634[4:4];
    assign _1638 = _1634[3:3];
    assign _1637 = _1634[2:2];
    assign _1636 = _1634[1:1];
    assign _1635 = _1634[0:0];
    always @* begin
        case (_1627)
        0:
            _1643 <= _1635;
        1:
            _1643 <= _1636;
        2:
            _1643 <= _1637;
        3:
            _1643 <= _1638;
        4:
            _1643 <= _1639;
        5:
            _1643 <= _1640;
        6:
            _1643 <= _1641;
        default:
            _1643 <= _1642;
        endcase
    end
    assign _1631 = pin_out[7:7];
    assign _1629 = cfg_t0_set_cfg[7:4];
    assign _1588 = _590[7:0];
    assign _1585 = 7'b1000011;
    assign _1586 = _586 == _1585;
    assign _1584 = _580 & _584;
    assign _1587 = _1584 & _1586;
    assign _1589 = _1587 ? _1588 : cfg_t0_set_cfg;
    assign _20 = _1589;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_set_cfg <= _491;
        else
            cfg_t0_set_cfg <= _20;
    end
    assign _1626 = cfg_t0_set_cfg[2:0];
    assign _1627 = _3570 - _1626;
    assign _1628 = { gnd,
                     _1627 };
    assign _1630 = _1628 < _1629;
    assign _1644 = _1630 ? _1643 : _1631;
    assign _1750 = { _1644,
                     _1659,
                     _1674,
                     _1689,
                     _1704,
                     _1719,
                     _1734,
                     _1749 };
    assign _1623 = _1621 == _520;
    assign _1619 = _1389 == _3728;
    assign _1620 = _1507 & _1619;
    assign _1624 = _1620 & _1623;
    assign _1751 = _1624 ? _1750 : pin_out;
    assign _1615 = _1531 == _4048;
    assign _1616 = _1537 & _1615;
    assign _1612 = _1389 == _3745;
    assign _1613 = _1507 & _1612;
    assign _1617 = _1613 & _1616;
    assign _1891 = _1617 ? _1890 : _1751;
    assign _1607 = _1388[8:7];
    assign _1609 = _1607 == _520;
    assign _1605 = _1389 == _3779;
    assign _1606 = _1507 & _1605;
    assign _1610 = _1606 & _1609;
    assign _2080 = _1610 ? _2079 : _1891;
    assign _2081 = _2080[7:7];
    assign _1601 = cfg_t0_sideset[5:4];
    assign _1602 = { _520,
                     _1601 };
    assign _468 = 6'b000000;
    assign _1594 = _590[5:0];
    assign _1591 = 7'b1001100;
    assign _1592 = _586 == _1591;
    assign _1590 = _580 & _584;
    assign _1593 = _1590 & _1592;
    assign _1595 = _1593 ? _1594 : cfg_t0_sideset;
    assign _21 = _1595;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_sideset <= _468;
        else
            cfg_t0_sideset <= _21;
    end
    assign _1597 = cfg_t0_sideset[2:0];
    assign _1598 = _3570 - _1597;
    assign _1599 = { gnd,
                     _1598 };
    assign _1603 = _1599 < _1602;
    assign _2110 = _1603 ? _2109 : _2081;
    assign _2230 = { _2110,
                     _2127,
                     _2144,
                     _2161,
                     _2178,
                     _2195,
                     _2212,
                     _2229 };
    assign _2231 = _612 ? pin_out : _2230;
    assign _2232 = _606 ? pin_out : _2231;
    assign _2233 = _600 ? pin_out : _2232;
    assign _22 = _2233;
    assign _3319 = _3133 == _520;
    assign _3316 = _2267 == _3728;
    assign _3317 = _2361 & _3316;
    assign _3320 = _3317 & _3319;
    assign _3444 = _3320 ? _3443 : _22;
    assign _3312 = _2376 == _4048;
    assign _3313 = _2382 & _3312;
    assign _3309 = _2267 == _3745;
    assign _3310 = _2361 & _3309;
    assign _3314 = _3310 & _3313;
    assign _3568 = _3314 ? _3567 : _3444;
    assign _3304 = _2266[8:7];
    assign _3306 = _3304 == _520;
    assign _3302 = _2267 == _3779;
    assign _3303 = _2361 & _3302;
    assign _3307 = _3303 & _3306;
    assign _3698 = _3307 ? _3697 : _3568;
    assign _3699 = _3698[7:7];
    assign _3299 = { _520,
                     _3259 };
    assign _3295 = cfg_t1_sideset[2:0];
    assign _3296 = _3570 - _3295;
    assign _3297 = { gnd,
                     _3296 };
    assign _3300 = _3297 < _3299;
    assign _3727 = _3300 ? _3726 : _3699;
    assign _3847 = { _3727,
                     _3744,
                     _3761,
                     _3778,
                     _3795,
                     _3812,
                     _3829,
                     _3846 };
    assign _3272 = t1_delay_left - _4105;
    assign _3266 = _3264[3:2];
    assign _3267 = { _520,
                     _3266 };
    assign _3261 = _3259[0:0];
    assign _3264 = _3261 ? _4097 : _4096;
    assign _2238 = _590[5:0];
    assign _2235 = 7'b1011100;
    assign _2236 = _586 == _2235;
    assign _2234 = _580 & _584;
    assign _2237 = _2234 & _2236;
    assign _2239 = _2237 ? _2238 : cfg_t1_sideset;
    assign _23 = _2239;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_sideset <= _468;
        else
            cfg_t1_sideset <= _23;
    end
    assign _3259 = cfg_t1_sideset[5:4];
    assign _3260 = _3259[1:1];
    assign _3268 = _3260 ? _3267 : _3264;
    assign _3258 = _2266[12:9];
    assign _3269 = _3258 & _3268;
    assign _317 = t1_rx_level == _544;
    assign _318 = ~ _317;
    assign _2250 = t1_rx_level == _544;
    assign _2251 = ~ _2250;
    assign _2246 = 7'b1011001;
    assign _2247 = _370 == _2246;
    assign _2243 = _369[7:7];
    assign _2244 = ~ _2243;
    assign _2245 = _2242 & _2244;
    assign _2248 = _2245 & _2247;
    assign _2252 = _2248 & _2251;
    assign _24 = _2252;
    assign _319 = _24 & _318;
    assign _2280 = { _520,
                     _319 };
    assign _240 = ~ _239;
    assign _2274 = ~ _239;
    assign _2272 = ~ _2271;
    assign _2269 = _2267 == _4177;
    assign _2270 = _2265 & _2269;
    assign _2273 = _2270 & _2272;
    assign _2275 = _2273 & _2274;
    assign _25 = _2275;
    assign _241 = _25 & _240;
    assign _2277 = { _520,
                     _241 };
    assign _2278 = t1_rx_level + _2277;
    assign _2281 = _2278 - _2280;
    assign _26 = _2281;
    always @(posedge _99) begin
        if (_97)
            t1_rx_level <= _544;
        else
            t1_rx_level <= _26;
    end
    assign _239 = t1_rx_level == _4177;
    assign _2356 = ~ _2271;
    assign _2355 = _2267 == _4177;
    assign _2357 = _2355 & _2356;
    assign _2358 = _2357 & _239;
    assign _2348 = _2267 == _4177;
    assign _2349 = _2348 & _2271;
    assign _2352 = _2349 & _2351;
    assign _2345 = ~ _2344;
    assign _2342 = ~ _2312;
    assign _1384 = 7'b1111111;
    assign _1385 = _621 == _1384;
    assign _1386 = _618 & _1385;
    always @(posedge _99) begin
        if (_97)
            prog_127 <= _356;
        else
            if (_1386)
                prog_127 <= _590;
    end
    assign _1378 = 7'b1111110;
    assign _1379 = _621 == _1378;
    assign _1380 = _618 & _1379;
    always @(posedge _99) begin
        if (_97)
            prog_126 <= _356;
        else
            if (_1380)
                prog_126 <= _590;
    end
    assign _1372 = 7'b1111101;
    assign _1373 = _621 == _1372;
    assign _1374 = _618 & _1373;
    always @(posedge _99) begin
        if (_97)
            prog_125 <= _356;
        else
            if (_1374)
                prog_125 <= _590;
    end
    assign _1366 = 7'b1111100;
    assign _1367 = _621 == _1366;
    assign _1368 = _618 & _1367;
    always @(posedge _99) begin
        if (_97)
            prog_124 <= _356;
        else
            if (_1368)
                prog_124 <= _590;
    end
    assign _1360 = 7'b1111011;
    assign _1361 = _621 == _1360;
    assign _1362 = _618 & _1361;
    always @(posedge _99) begin
        if (_97)
            prog_123 <= _356;
        else
            if (_1362)
                prog_123 <= _590;
    end
    assign _1354 = 7'b1111010;
    assign _1355 = _621 == _1354;
    assign _1356 = _618 & _1355;
    always @(posedge _99) begin
        if (_97)
            prog_122 <= _356;
        else
            if (_1356)
                prog_122 <= _590;
    end
    assign _1348 = 7'b1111001;
    assign _1349 = _621 == _1348;
    assign _1350 = _618 & _1349;
    always @(posedge _99) begin
        if (_97)
            prog_121 <= _356;
        else
            if (_1350)
                prog_121 <= _590;
    end
    assign _1342 = 7'b1111000;
    assign _1343 = _621 == _1342;
    assign _1344 = _618 & _1343;
    always @(posedge _99) begin
        if (_97)
            prog_120 <= _356;
        else
            if (_1344)
                prog_120 <= _590;
    end
    assign _1336 = 7'b1110111;
    assign _1337 = _621 == _1336;
    assign _1338 = _618 & _1337;
    always @(posedge _99) begin
        if (_97)
            prog_119 <= _356;
        else
            if (_1338)
                prog_119 <= _590;
    end
    assign _1330 = 7'b1110110;
    assign _1331 = _621 == _1330;
    assign _1332 = _618 & _1331;
    always @(posedge _99) begin
        if (_97)
            prog_118 <= _356;
        else
            if (_1332)
                prog_118 <= _590;
    end
    assign _1324 = 7'b1110101;
    assign _1325 = _621 == _1324;
    assign _1326 = _618 & _1325;
    always @(posedge _99) begin
        if (_97)
            prog_117 <= _356;
        else
            if (_1326)
                prog_117 <= _590;
    end
    assign _1318 = 7'b1110100;
    assign _1319 = _621 == _1318;
    assign _1320 = _618 & _1319;
    always @(posedge _99) begin
        if (_97)
            prog_116 <= _356;
        else
            if (_1320)
                prog_116 <= _590;
    end
    assign _1312 = 7'b1110011;
    assign _1313 = _621 == _1312;
    assign _1314 = _618 & _1313;
    always @(posedge _99) begin
        if (_97)
            prog_115 <= _356;
        else
            if (_1314)
                prog_115 <= _590;
    end
    assign _1306 = 7'b1110010;
    assign _1307 = _621 == _1306;
    assign _1308 = _618 & _1307;
    always @(posedge _99) begin
        if (_97)
            prog_114 <= _356;
        else
            if (_1308)
                prog_114 <= _590;
    end
    assign _1300 = 7'b1110001;
    assign _1301 = _621 == _1300;
    assign _1302 = _618 & _1301;
    always @(posedge _99) begin
        if (_97)
            prog_113 <= _356;
        else
            if (_1302)
                prog_113 <= _590;
    end
    assign _1294 = 7'b1110000;
    assign _1295 = _621 == _1294;
    assign _1296 = _618 & _1295;
    always @(posedge _99) begin
        if (_97)
            prog_112 <= _356;
        else
            if (_1296)
                prog_112 <= _590;
    end
    assign _1288 = 7'b1101111;
    assign _1289 = _621 == _1288;
    assign _1290 = _618 & _1289;
    always @(posedge _99) begin
        if (_97)
            prog_111 <= _356;
        else
            if (_1290)
                prog_111 <= _590;
    end
    assign _1282 = 7'b1101110;
    assign _1283 = _621 == _1282;
    assign _1284 = _618 & _1283;
    always @(posedge _99) begin
        if (_97)
            prog_110 <= _356;
        else
            if (_1284)
                prog_110 <= _590;
    end
    assign _1276 = 7'b1101101;
    assign _1277 = _621 == _1276;
    assign _1278 = _618 & _1277;
    always @(posedge _99) begin
        if (_97)
            prog_109 <= _356;
        else
            if (_1278)
                prog_109 <= _590;
    end
    assign _1270 = 7'b1101100;
    assign _1271 = _621 == _1270;
    assign _1272 = _618 & _1271;
    always @(posedge _99) begin
        if (_97)
            prog_108 <= _356;
        else
            if (_1272)
                prog_108 <= _590;
    end
    assign _1264 = 7'b1101011;
    assign _1265 = _621 == _1264;
    assign _1266 = _618 & _1265;
    always @(posedge _99) begin
        if (_97)
            prog_107 <= _356;
        else
            if (_1266)
                prog_107 <= _590;
    end
    assign _1258 = 7'b1101010;
    assign _1259 = _621 == _1258;
    assign _1260 = _618 & _1259;
    always @(posedge _99) begin
        if (_97)
            prog_106 <= _356;
        else
            if (_1260)
                prog_106 <= _590;
    end
    assign _1252 = 7'b1101001;
    assign _1253 = _621 == _1252;
    assign _1254 = _618 & _1253;
    always @(posedge _99) begin
        if (_97)
            prog_105 <= _356;
        else
            if (_1254)
                prog_105 <= _590;
    end
    assign _1246 = 7'b1101000;
    assign _1247 = _621 == _1246;
    assign _1248 = _618 & _1247;
    always @(posedge _99) begin
        if (_97)
            prog_104 <= _356;
        else
            if (_1248)
                prog_104 <= _590;
    end
    assign _1240 = 7'b1100111;
    assign _1241 = _621 == _1240;
    assign _1242 = _618 & _1241;
    always @(posedge _99) begin
        if (_97)
            prog_103 <= _356;
        else
            if (_1242)
                prog_103 <= _590;
    end
    assign _1234 = 7'b1100110;
    assign _1235 = _621 == _1234;
    assign _1236 = _618 & _1235;
    always @(posedge _99) begin
        if (_97)
            prog_102 <= _356;
        else
            if (_1236)
                prog_102 <= _590;
    end
    assign _1228 = 7'b1100101;
    assign _1229 = _621 == _1228;
    assign _1230 = _618 & _1229;
    always @(posedge _99) begin
        if (_97)
            prog_101 <= _356;
        else
            if (_1230)
                prog_101 <= _590;
    end
    assign _1222 = 7'b1100100;
    assign _1223 = _621 == _1222;
    assign _1224 = _618 & _1223;
    always @(posedge _99) begin
        if (_97)
            prog_100 <= _356;
        else
            if (_1224)
                prog_100 <= _590;
    end
    assign _1216 = 7'b1100011;
    assign _1217 = _621 == _1216;
    assign _1218 = _618 & _1217;
    always @(posedge _99) begin
        if (_97)
            prog_99 <= _356;
        else
            if (_1218)
                prog_99 <= _590;
    end
    assign _1210 = 7'b1100010;
    assign _1211 = _621 == _1210;
    assign _1212 = _618 & _1211;
    always @(posedge _99) begin
        if (_97)
            prog_98 <= _356;
        else
            if (_1212)
                prog_98 <= _590;
    end
    assign _1204 = 7'b1100001;
    assign _1205 = _621 == _1204;
    assign _1206 = _618 & _1205;
    always @(posedge _99) begin
        if (_97)
            prog_97 <= _356;
        else
            if (_1206)
                prog_97 <= _590;
    end
    assign _1198 = 7'b1100000;
    assign _1199 = _621 == _1198;
    assign _1200 = _618 & _1199;
    always @(posedge _99) begin
        if (_97)
            prog_96 <= _356;
        else
            if (_1200)
                prog_96 <= _590;
    end
    assign _1192 = 7'b1011111;
    assign _1193 = _621 == _1192;
    assign _1194 = _618 & _1193;
    always @(posedge _99) begin
        if (_97)
            prog_95 <= _356;
        else
            if (_1194)
                prog_95 <= _590;
    end
    assign _1186 = 7'b1011110;
    assign _1187 = _621 == _1186;
    assign _1188 = _618 & _1187;
    always @(posedge _99) begin
        if (_97)
            prog_94 <= _356;
        else
            if (_1188)
                prog_94 <= _590;
    end
    assign _1180 = 7'b1011101;
    assign _1181 = _621 == _1180;
    assign _1182 = _618 & _1181;
    always @(posedge _99) begin
        if (_97)
            prog_93 <= _356;
        else
            if (_1182)
                prog_93 <= _590;
    end
    assign _1175 = _621 == _2235;
    assign _1176 = _618 & _1175;
    always @(posedge _99) begin
        if (_97)
            prog_92 <= _356;
        else
            if (_1176)
                prog_92 <= _590;
    end
    assign _1168 = 7'b1011011;
    assign _1169 = _621 == _1168;
    assign _1170 = _618 & _1169;
    always @(posedge _99) begin
        if (_97)
            prog_91 <= _356;
        else
            if (_1170)
                prog_91 <= _590;
    end
    assign _1162 = 7'b1011010;
    assign _1163 = _621 == _1162;
    assign _1164 = _618 & _1163;
    always @(posedge _99) begin
        if (_97)
            prog_90 <= _356;
        else
            if (_1164)
                prog_90 <= _590;
    end
    assign _1157 = _621 == _2246;
    assign _1158 = _618 & _1157;
    always @(posedge _99) begin
        if (_97)
            prog_89 <= _356;
        else
            if (_1158)
                prog_89 <= _590;
    end
    assign _1151 = _621 == _2683;
    assign _1152 = _618 & _1151;
    always @(posedge _99) begin
        if (_97)
            prog_88 <= _356;
        else
            if (_1152)
                prog_88 <= _590;
    end
    assign _1144 = 7'b1010111;
    assign _1145 = _621 == _1144;
    assign _1146 = _618 & _1145;
    always @(posedge _99) begin
        if (_97)
            prog_87 <= _356;
        else
            if (_1146)
                prog_87 <= _590;
    end
    assign _1138 = 7'b1010110;
    assign _1139 = _621 == _1138;
    assign _1140 = _618 & _1139;
    always @(posedge _99) begin
        if (_97)
            prog_86 <= _356;
        else
            if (_1140)
                prog_86 <= _590;
    end
    assign _1132 = 7'b1010101;
    assign _1133 = _621 == _1132;
    assign _1134 = _618 & _1133;
    always @(posedge _99) begin
        if (_97)
            prog_85 <= _356;
        else
            if (_1134)
                prog_85 <= _590;
    end
    assign _1126 = 7'b1010100;
    assign _1127 = _621 == _1126;
    assign _1128 = _618 & _1127;
    always @(posedge _99) begin
        if (_97)
            prog_84 <= _356;
        else
            if (_1128)
                prog_84 <= _590;
    end
    assign _1121 = _621 == _1573;
    assign _1122 = _618 & _1121;
    always @(posedge _99) begin
        if (_97)
            prog_83 <= _356;
        else
            if (_1122)
                prog_83 <= _590;
    end
    assign _1115 = _621 == _1567;
    assign _1116 = _618 & _1115;
    always @(posedge _99) begin
        if (_97)
            prog_82 <= _356;
        else
            if (_1116)
                prog_82 <= _590;
    end
    assign _1108 = 7'b1010001;
    assign _1109 = _621 == _1108;
    assign _1110 = _618 & _1109;
    always @(posedge _99) begin
        if (_97)
            prog_81 <= _356;
        else
            if (_1110)
                prog_81 <= _590;
    end
    assign _1102 = 7'b1010000;
    assign _1103 = _621 == _1102;
    assign _1104 = _618 & _1103;
    always @(posedge _99) begin
        if (_97)
            prog_80 <= _356;
        else
            if (_1104)
                prog_80 <= _590;
    end
    assign _1096 = 7'b1001111;
    assign _1097 = _621 == _1096;
    assign _1098 = _618 & _1097;
    always @(posedge _99) begin
        if (_97)
            prog_79 <= _356;
        else
            if (_1098)
                prog_79 <= _590;
    end
    assign _1090 = 7'b1001110;
    assign _1091 = _621 == _1090;
    assign _1092 = _618 & _1091;
    always @(posedge _99) begin
        if (_97)
            prog_78 <= _356;
        else
            if (_1092)
                prog_78 <= _590;
    end
    assign _1084 = 7'b1001101;
    assign _1085 = _621 == _1084;
    assign _1086 = _618 & _1085;
    always @(posedge _99) begin
        if (_97)
            prog_77 <= _356;
        else
            if (_1086)
                prog_77 <= _590;
    end
    assign _1079 = _621 == _1591;
    assign _1080 = _618 & _1079;
    always @(posedge _99) begin
        if (_97)
            prog_76 <= _356;
        else
            if (_1080)
                prog_76 <= _590;
    end
    assign _1073 = _621 == _1477;
    assign _1074 = _618 & _1073;
    always @(posedge _99) begin
        if (_97)
            prog_75 <= _356;
        else
            if (_1074)
                prog_75 <= _590;
    end
    assign _1066 = 7'b1001010;
    assign _1067 = _621 == _1066;
    assign _1068 = _618 & _1067;
    always @(posedge _99) begin
        if (_97)
            prog_74 <= _356;
        else
            if (_1068)
                prog_74 <= _590;
    end
    assign _1060 = 7'b1001001;
    assign _1061 = _621 == _1060;
    assign _1062 = _618 & _1061;
    always @(posedge _99) begin
        if (_97)
            prog_73 <= _356;
        else
            if (_1062)
                prog_73 <= _590;
    end
    assign _1054 = 7'b1001000;
    assign _1055 = _621 == _1054;
    assign _1056 = _618 & _1055;
    always @(posedge _99) begin
        if (_97)
            prog_72 <= _356;
        else
            if (_1056)
                prog_72 <= _590;
    end
    assign _1048 = 7'b1000111;
    assign _1049 = _621 == _1048;
    assign _1050 = _618 & _1049;
    always @(posedge _99) begin
        if (_97)
            prog_71 <= _356;
        else
            if (_1050)
                prog_71 <= _590;
    end
    assign _1043 = _621 == _594;
    assign _1044 = _618 & _1043;
    always @(posedge _99) begin
        if (_97)
            prog_70 <= _356;
        else
            if (_1044)
                prog_70 <= _590;
    end
    assign _1037 = _621 == _1517;
    assign _1038 = _618 & _1037;
    always @(posedge _99) begin
        if (_97)
            prog_69 <= _356;
        else
            if (_1038)
                prog_69 <= _590;
    end
    assign _1030 = 7'b1000100;
    assign _1031 = _621 == _1030;
    assign _1032 = _618 & _1031;
    always @(posedge _99) begin
        if (_97)
            prog_68 <= _356;
        else
            if (_1032)
                prog_68 <= _590;
    end
    assign _1025 = _621 == _1585;
    assign _1026 = _618 & _1025;
    always @(posedge _99) begin
        if (_97)
            prog_67 <= _356;
        else
            if (_1026)
                prog_67 <= _590;
    end
    assign _1019 = _621 == _1579;
    assign _1020 = _618 & _1019;
    always @(posedge _99) begin
        if (_97)
            prog_66 <= _356;
        else
            if (_1020)
                prog_66 <= _590;
    end
    assign _1013 = _621 == _587;
    assign _1014 = _618 & _1013;
    always @(posedge _99) begin
        if (_97)
            prog_65 <= _356;
        else
            if (_1014)
                prog_65 <= _590;
    end
    assign _1006 = 7'b1000000;
    assign _1007 = _621 == _1006;
    assign _1008 = _618 & _1007;
    always @(posedge _99) begin
        if (_97)
            prog_64 <= _356;
        else
            if (_1008)
                prog_64 <= _590;
    end
    assign _1000 = 7'b0111111;
    assign _1001 = _621 == _1000;
    assign _1002 = _618 & _1001;
    always @(posedge _99) begin
        if (_97)
            prog_63 <= _356;
        else
            if (_1002)
                prog_63 <= _590;
    end
    assign _994 = 7'b0111110;
    assign _995 = _621 == _994;
    assign _996 = _618 & _995;
    always @(posedge _99) begin
        if (_97)
            prog_62 <= _356;
        else
            if (_996)
                prog_62 <= _590;
    end
    assign _988 = 7'b0111101;
    assign _989 = _621 == _988;
    assign _990 = _618 & _989;
    always @(posedge _99) begin
        if (_97)
            prog_61 <= _356;
        else
            if (_990)
                prog_61 <= _590;
    end
    assign _982 = 7'b0111100;
    assign _983 = _621 == _982;
    assign _984 = _618 & _983;
    always @(posedge _99) begin
        if (_97)
            prog_60 <= _356;
        else
            if (_984)
                prog_60 <= _590;
    end
    assign _976 = 7'b0111011;
    assign _977 = _621 == _976;
    assign _978 = _618 & _977;
    always @(posedge _99) begin
        if (_97)
            prog_59 <= _356;
        else
            if (_978)
                prog_59 <= _590;
    end
    assign _970 = 7'b0111010;
    assign _971 = _621 == _970;
    assign _972 = _618 & _971;
    always @(posedge _99) begin
        if (_97)
            prog_58 <= _356;
        else
            if (_972)
                prog_58 <= _590;
    end
    assign _964 = 7'b0111001;
    assign _965 = _621 == _964;
    assign _966 = _618 & _965;
    always @(posedge _99) begin
        if (_97)
            prog_57 <= _356;
        else
            if (_966)
                prog_57 <= _590;
    end
    assign _958 = 7'b0111000;
    assign _959 = _621 == _958;
    assign _960 = _618 & _959;
    always @(posedge _99) begin
        if (_97)
            prog_56 <= _356;
        else
            if (_960)
                prog_56 <= _590;
    end
    assign _952 = 7'b0110111;
    assign _953 = _621 == _952;
    assign _954 = _618 & _953;
    always @(posedge _99) begin
        if (_97)
            prog_55 <= _356;
        else
            if (_954)
                prog_55 <= _590;
    end
    assign _946 = 7'b0110110;
    assign _947 = _621 == _946;
    assign _948 = _618 & _947;
    always @(posedge _99) begin
        if (_97)
            prog_54 <= _356;
        else
            if (_948)
                prog_54 <= _590;
    end
    assign _940 = 7'b0110101;
    assign _941 = _621 == _940;
    assign _942 = _618 & _941;
    always @(posedge _99) begin
        if (_97)
            prog_53 <= _356;
        else
            if (_942)
                prog_53 <= _590;
    end
    assign _934 = 7'b0110100;
    assign _935 = _621 == _934;
    assign _936 = _618 & _935;
    always @(posedge _99) begin
        if (_97)
            prog_52 <= _356;
        else
            if (_936)
                prog_52 <= _590;
    end
    assign _928 = 7'b0110011;
    assign _929 = _621 == _928;
    assign _930 = _618 & _929;
    always @(posedge _99) begin
        if (_97)
            prog_51 <= _356;
        else
            if (_930)
                prog_51 <= _590;
    end
    assign _922 = 7'b0110010;
    assign _923 = _621 == _922;
    assign _924 = _618 & _923;
    always @(posedge _99) begin
        if (_97)
            prog_50 <= _356;
        else
            if (_924)
                prog_50 <= _590;
    end
    assign _916 = 7'b0110001;
    assign _917 = _621 == _916;
    assign _918 = _618 & _917;
    always @(posedge _99) begin
        if (_97)
            prog_49 <= _356;
        else
            if (_918)
                prog_49 <= _590;
    end
    assign _910 = 7'b0110000;
    assign _911 = _621 == _910;
    assign _912 = _618 & _911;
    always @(posedge _99) begin
        if (_97)
            prog_48 <= _356;
        else
            if (_912)
                prog_48 <= _590;
    end
    assign _904 = 7'b0101111;
    assign _905 = _621 == _904;
    assign _906 = _618 & _905;
    always @(posedge _99) begin
        if (_97)
            prog_47 <= _356;
        else
            if (_906)
                prog_47 <= _590;
    end
    assign _898 = 7'b0101110;
    assign _899 = _621 == _898;
    assign _900 = _618 & _899;
    always @(posedge _99) begin
        if (_97)
            prog_46 <= _356;
        else
            if (_900)
                prog_46 <= _590;
    end
    assign _892 = 7'b0101101;
    assign _893 = _621 == _892;
    assign _894 = _618 & _893;
    always @(posedge _99) begin
        if (_97)
            prog_45 <= _356;
        else
            if (_894)
                prog_45 <= _590;
    end
    assign _886 = 7'b0101100;
    assign _887 = _621 == _886;
    assign _888 = _618 & _887;
    always @(posedge _99) begin
        if (_97)
            prog_44 <= _356;
        else
            if (_888)
                prog_44 <= _590;
    end
    assign _880 = 7'b0101011;
    assign _881 = _621 == _880;
    assign _882 = _618 & _881;
    always @(posedge _99) begin
        if (_97)
            prog_43 <= _356;
        else
            if (_882)
                prog_43 <= _590;
    end
    assign _874 = 7'b0101010;
    assign _875 = _621 == _874;
    assign _876 = _618 & _875;
    always @(posedge _99) begin
        if (_97)
            prog_42 <= _356;
        else
            if (_876)
                prog_42 <= _590;
    end
    assign _868 = 7'b0101001;
    assign _869 = _621 == _868;
    assign _870 = _618 & _869;
    always @(posedge _99) begin
        if (_97)
            prog_41 <= _356;
        else
            if (_870)
                prog_41 <= _590;
    end
    assign _862 = 7'b0101000;
    assign _863 = _621 == _862;
    assign _864 = _618 & _863;
    always @(posedge _99) begin
        if (_97)
            prog_40 <= _356;
        else
            if (_864)
                prog_40 <= _590;
    end
    assign _856 = 7'b0100111;
    assign _857 = _621 == _856;
    assign _858 = _618 & _857;
    always @(posedge _99) begin
        if (_97)
            prog_39 <= _356;
        else
            if (_858)
                prog_39 <= _590;
    end
    assign _850 = 7'b0100110;
    assign _851 = _621 == _850;
    assign _852 = _618 & _851;
    always @(posedge _99) begin
        if (_97)
            prog_38 <= _356;
        else
            if (_852)
                prog_38 <= _590;
    end
    assign _844 = 7'b0100101;
    assign _845 = _621 == _844;
    assign _846 = _618 & _845;
    always @(posedge _99) begin
        if (_97)
            prog_37 <= _356;
        else
            if (_846)
                prog_37 <= _590;
    end
    assign _838 = 7'b0100100;
    assign _839 = _621 == _838;
    assign _840 = _618 & _839;
    always @(posedge _99) begin
        if (_97)
            prog_36 <= _356;
        else
            if (_840)
                prog_36 <= _590;
    end
    assign _832 = 7'b0100011;
    assign _833 = _621 == _832;
    assign _834 = _618 & _833;
    always @(posedge _99) begin
        if (_97)
            prog_35 <= _356;
        else
            if (_834)
                prog_35 <= _590;
    end
    assign _826 = 7'b0100010;
    assign _827 = _621 == _826;
    assign _828 = _618 & _827;
    always @(posedge _99) begin
        if (_97)
            prog_34 <= _356;
        else
            if (_828)
                prog_34 <= _590;
    end
    assign _820 = 7'b0100001;
    assign _821 = _621 == _820;
    assign _822 = _618 & _821;
    always @(posedge _99) begin
        if (_97)
            prog_33 <= _356;
        else
            if (_822)
                prog_33 <= _590;
    end
    assign _814 = 7'b0100000;
    assign _815 = _621 == _814;
    assign _816 = _618 & _815;
    always @(posedge _99) begin
        if (_97)
            prog_32 <= _356;
        else
            if (_816)
                prog_32 <= _590;
    end
    assign _808 = 7'b0011111;
    assign _809 = _621 == _808;
    assign _810 = _618 & _809;
    always @(posedge _99) begin
        if (_97)
            prog_31 <= _356;
        else
            if (_810)
                prog_31 <= _590;
    end
    assign _802 = 7'b0011110;
    assign _803 = _621 == _802;
    assign _804 = _618 & _803;
    always @(posedge _99) begin
        if (_97)
            prog_30 <= _356;
        else
            if (_804)
                prog_30 <= _590;
    end
    assign _796 = 7'b0011101;
    assign _797 = _621 == _796;
    assign _798 = _618 & _797;
    always @(posedge _99) begin
        if (_97)
            prog_29 <= _356;
        else
            if (_798)
                prog_29 <= _590;
    end
    assign _790 = 7'b0011100;
    assign _791 = _621 == _790;
    assign _792 = _618 & _791;
    always @(posedge _99) begin
        if (_97)
            prog_28 <= _356;
        else
            if (_792)
                prog_28 <= _590;
    end
    assign _784 = 7'b0011011;
    assign _785 = _621 == _784;
    assign _786 = _618 & _785;
    always @(posedge _99) begin
        if (_97)
            prog_27 <= _356;
        else
            if (_786)
                prog_27 <= _590;
    end
    assign _778 = 7'b0011010;
    assign _779 = _621 == _778;
    assign _780 = _618 & _779;
    always @(posedge _99) begin
        if (_97)
            prog_26 <= _356;
        else
            if (_780)
                prog_26 <= _590;
    end
    assign _772 = 7'b0011001;
    assign _773 = _621 == _772;
    assign _774 = _618 & _773;
    always @(posedge _99) begin
        if (_97)
            prog_25 <= _356;
        else
            if (_774)
                prog_25 <= _590;
    end
    assign _766 = 7'b0011000;
    assign _767 = _621 == _766;
    assign _768 = _618 & _767;
    always @(posedge _99) begin
        if (_97)
            prog_24 <= _356;
        else
            if (_768)
                prog_24 <= _590;
    end
    assign _760 = 7'b0010111;
    assign _761 = _621 == _760;
    assign _762 = _618 & _761;
    always @(posedge _99) begin
        if (_97)
            prog_23 <= _356;
        else
            if (_762)
                prog_23 <= _590;
    end
    assign _754 = 7'b0010110;
    assign _755 = _621 == _754;
    assign _756 = _618 & _755;
    always @(posedge _99) begin
        if (_97)
            prog_22 <= _356;
        else
            if (_756)
                prog_22 <= _590;
    end
    assign _748 = 7'b0010101;
    assign _749 = _621 == _748;
    assign _750 = _618 & _749;
    always @(posedge _99) begin
        if (_97)
            prog_21 <= _356;
        else
            if (_750)
                prog_21 <= _590;
    end
    assign _742 = 7'b0010100;
    assign _743 = _621 == _742;
    assign _744 = _618 & _743;
    always @(posedge _99) begin
        if (_97)
            prog_20 <= _356;
        else
            if (_744)
                prog_20 <= _590;
    end
    assign _736 = 7'b0010011;
    assign _737 = _621 == _736;
    assign _738 = _618 & _737;
    always @(posedge _99) begin
        if (_97)
            prog_19 <= _356;
        else
            if (_738)
                prog_19 <= _590;
    end
    assign _730 = 7'b0010010;
    assign _731 = _621 == _730;
    assign _732 = _618 & _731;
    always @(posedge _99) begin
        if (_97)
            prog_18 <= _356;
        else
            if (_732)
                prog_18 <= _590;
    end
    assign _724 = 7'b0010001;
    assign _725 = _621 == _724;
    assign _726 = _618 & _725;
    always @(posedge _99) begin
        if (_97)
            prog_17 <= _356;
        else
            if (_726)
                prog_17 <= _590;
    end
    assign _718 = 7'b0010000;
    assign _719 = _621 == _718;
    assign _720 = _618 & _719;
    always @(posedge _99) begin
        if (_97)
            prog_16 <= _356;
        else
            if (_720)
                prog_16 <= _590;
    end
    assign _712 = 7'b0001111;
    assign _713 = _621 == _712;
    assign _714 = _618 & _713;
    always @(posedge _99) begin
        if (_97)
            prog_15 <= _356;
        else
            if (_714)
                prog_15 <= _590;
    end
    assign _706 = 7'b0001110;
    assign _707 = _621 == _706;
    assign _708 = _618 & _707;
    always @(posedge _99) begin
        if (_97)
            prog_14 <= _356;
        else
            if (_708)
                prog_14 <= _590;
    end
    assign _700 = 7'b0001101;
    assign _701 = _621 == _700;
    assign _702 = _618 & _701;
    always @(posedge _99) begin
        if (_97)
            prog_13 <= _356;
        else
            if (_702)
                prog_13 <= _590;
    end
    assign _694 = 7'b0001100;
    assign _695 = _621 == _694;
    assign _696 = _618 & _695;
    always @(posedge _99) begin
        if (_97)
            prog_12 <= _356;
        else
            if (_696)
                prog_12 <= _590;
    end
    assign _688 = 7'b0001011;
    assign _689 = _621 == _688;
    assign _690 = _618 & _689;
    always @(posedge _99) begin
        if (_97)
            prog_11 <= _356;
        else
            if (_690)
                prog_11 <= _590;
    end
    assign _682 = 7'b0001010;
    assign _683 = _621 == _682;
    assign _684 = _618 & _683;
    always @(posedge _99) begin
        if (_97)
            prog_10 <= _356;
        else
            if (_684)
                prog_10 <= _590;
    end
    assign _676 = 7'b0001001;
    assign _677 = _621 == _676;
    assign _678 = _618 & _677;
    always @(posedge _99) begin
        if (_97)
            prog_9 <= _356;
        else
            if (_678)
                prog_9 <= _590;
    end
    assign _670 = 7'b0001000;
    assign _671 = _621 == _670;
    assign _672 = _618 & _671;
    always @(posedge _99) begin
        if (_97)
            prog_8 <= _356;
        else
            if (_672)
                prog_8 <= _590;
    end
    assign _664 = 7'b0000111;
    assign _665 = _621 == _664;
    assign _666 = _618 & _665;
    always @(posedge _99) begin
        if (_97)
            prog_7 <= _356;
        else
            if (_666)
                prog_7 <= _590;
    end
    assign _658 = 7'b0000110;
    assign _659 = _621 == _658;
    assign _660 = _618 & _659;
    always @(posedge _99) begin
        if (_97)
            prog_6 <= _356;
        else
            if (_660)
                prog_6 <= _590;
    end
    assign _652 = 7'b0000101;
    assign _653 = _621 == _652;
    assign _654 = _618 & _653;
    always @(posedge _99) begin
        if (_97)
            prog_5 <= _356;
        else
            if (_654)
                prog_5 <= _590;
    end
    assign _646 = 7'b0000100;
    assign _647 = _621 == _646;
    assign _648 = _618 & _647;
    always @(posedge _99) begin
        if (_97)
            prog_4 <= _356;
        else
            if (_648)
                prog_4 <= _590;
    end
    assign _640 = 7'b0000011;
    assign _641 = _621 == _640;
    assign _642 = _618 & _641;
    always @(posedge _99) begin
        if (_97)
            prog_3 <= _356;
        else
            if (_642)
                prog_3 <= _590;
    end
    assign _634 = 7'b0000010;
    assign _635 = _621 == _634;
    assign _636 = _618 & _635;
    always @(posedge _99) begin
        if (_97)
            prog_2 <= _356;
        else
            if (_636)
                prog_2 <= _590;
    end
    assign _629 = _621 == _4081;
    assign _630 = _618 & _629;
    always @(posedge _99) begin
        if (_97)
            prog_1 <= _356;
        else
            if (_630)
                prog_1 <= _590;
    end
    assign _620 = _586[5:0];
    assign _619 = cfg_ctrl[3:3];
    assign _621 = { _619,
                    _620 };
    assign _623 = _621 == _452;
    assign _617 = _586 < _1006;
    assign _615 = _580 & _584;
    assign _618 = _615 & _617;
    assign _624 = _618 & _623;
    always @(posedge _99) begin
        if (_97)
            prog_0 <= _356;
        else
            if (_624)
                prog_0 <= _590;
    end
    assign _2286 = _590[6:0];
    assign _2284 = _586 == _1108;
    assign _2282 = _580 & _584;
    assign _2285 = _2282 & _2284;
    assign _2287 = _2285 ? _2286 : cfg_t1_start;
    assign _27 = _2287;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_start <= _452;
        else
            cfg_t1_start <= _27;
    end
    assign _3250 = _2266[5:0];
    assign _3249 = t1_pc[6:6];
    assign _3251 = { _3249,
                     _3250 };
    assign _2292 = _590[6:0];
    assign _2290 = _586 == _1138;
    assign _2288 = _580 & _584;
    assign _2291 = _2288 & _2290;
    assign _2293 = _2291 ? _2292 : cfg_t1_timeout_vector;
    assign _28 = _2293;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_timeout_vector <= _452;
        else
            cfg_t1_timeout_vector <= _28;
    end
    assign _3248 = _2267 == _544;
    assign _3252 = _3248 ? _3251 : cfg_t1_timeout_vector;
    assign _3246 = t1_pc + _4081;
    assign _2329 = _2323 - _1469;
    assign _2330 = _2327 ? _2329 : t1_wait_count;
    assign _2331 = _2298 ? t1_wait_count : _2330;
    assign _2332 = _2295 ? t1_wait_count : _2331;
    assign _2334 = _2294 ? _356 : _2332;
    assign _29 = _2334;
    assign _30 = _29;
    always @(posedge _99) begin
        if (_97)
            t1_wait_count <= _356;
        else
            t1_wait_count <= _30;
    end
    assign _2337 = _586 == _1168;
    assign _2335 = _580 & _584;
    assign _2338 = _2335 & _2337;
    assign _2339 = _2338 ? _590 : cfg_t1_timeout;
    assign _31 = _2339;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_timeout <= _356;
        else
            cfg_t1_timeout <= _31;
    end
    assign _2326 = ~ _2325;
    assign _2313 = ~ _2312;
    assign _2300 = _2267 == _1485;
    assign _2314 = _2300 & _2313;
    assign _2316 = _2314 & _2315;
    assign _2327 = _2316 & _2326;
    assign _2363 = _2327 ? _1508 : t1_waiting;
    assign _2365 = _2361 ? _574 : _2363;
    assign _2366 = _2298 ? t1_waiting : _2365;
    assign _2367 = _2295 ? t1_waiting : _2366;
    assign _2369 = _2294 ? _574 : _2367;
    assign _32 = _2369;
    assign _33 = _32;
    always @(posedge _99) begin
        if (_97)
            t1_waiting <= _574;
        else
            t1_waiting <= _33;
    end
    assign _2323 = t1_waiting ? t1_wait_count : cfg_t1_timeout;
    assign _2325 = _2323 == _356;
    assign _2315 = _2266[4:4];
    assign _2344 = _2315 & _2325;
    assign _2311 = _2266[8:8];
    assign _2309 = _1442[7:7];
    assign _2308 = _1442[6:6];
    assign _2307 = _1442[5:5];
    assign _2306 = _1442[4:4];
    assign _2305 = _1442[3:3];
    assign _2304 = _1442[2:2];
    assign _2303 = _1442[1:1];
    assign _2302 = _1442[0:0];
    assign _2301 = _2266[7:5];
    always @* begin
        case (_2301)
        0:
            _2310 <= _2302;
        1:
            _2310 <= _2303;
        2:
            _2310 <= _2304;
        3:
            _2310 <= _2305;
        4:
            _2310 <= _2306;
        5:
            _2310 <= _2307;
        6:
            _2310 <= _2308;
        default:
            _2310 <= _2309;
        endcase
    end
    assign _2312 = _2310 == _2311;
    assign _3241 = ~ _2312;
    assign _3240 = _2267 == _1485;
    assign _3242 = _3240 & _3241;
    assign _3243 = _3242 & _2344;
    assign _2403 = _2401[4:0];
    assign _2400 = { gnd,
                     _2399 };
    assign _2393 = { gnd,
                     t1_isr_count };
    assign _2401 = _2393 + _2400;
    assign _2402 = _1547 < _2401;
    assign _2405 = _2402 ? _252 : _2403;
    assign _2390 = _2271 ? t1_isr_count : _1523;
    assign _2384 = _2376 == _3779;
    assign _2386 = _2384 ? _1523 : t1_isr_count;
    assign _2387 = _2382 ? _2386 : t1_isr_count;
    assign _2375 = _2267 == _3745;
    assign _2388 = _2375 ? _2387 : t1_isr_count;
    assign _2373 = _2267 == _4177;
    assign _2391 = _2373 ? _2390 : _2388;
    assign _2371 = _2267 == _4048;
    assign _2406 = _2371 ? _2405 : _2391;
    assign _2407 = _2361 ? _2406 : t1_isr_count;
    assign _2408 = _2298 ? t1_isr_count : _2407;
    assign _2409 = _2295 ? t1_isr_count : _2408;
    assign _2411 = _2294 ? _1523 : _2409;
    assign _34 = _2411;
    assign _35 = _34;
    always @(posedge _99) begin
        if (_97)
            t1_isr_count <= _1523;
        else
            t1_isr_count <= _35;
    end
    assign _3236 = t1_isr_count < cfg_t1_threshold;
    assign _2416 = _590[4:0];
    assign _2414 = _586 == _1132;
    assign _2412 = _580 & _584;
    assign _2415 = _2412 & _2414;
    assign _2417 = _2415 ? _2416 : cfg_t1_threshold;
    assign _36 = _2417;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_threshold <= _399;
        else
            cfg_t1_threshold <= _36;
    end
    assign _2439 = _2437[4:0];
    assign _2436 = { gnd,
                     _2399 };
    assign _2435 = { gnd,
                     t1_osr_count };
    assign _2437 = _2435 + _2436;
    assign _2438 = _1547 < _2437;
    assign _2441 = _2438 ? _252 : _2439;
    assign _2432 = _2271 ? _1523 : t1_osr_count;
    assign _2426 = _2376 == _4177;
    assign _2428 = _2426 ? _1523 : t1_osr_count;
    assign _2429 = _2382 ? _2428 : t1_osr_count;
    assign _2424 = _2267 == _3745;
    assign _2430 = _2424 ? _2429 : t1_osr_count;
    assign _2423 = _2267 == _4177;
    assign _2433 = _2423 ? _2432 : _2430;
    assign _2422 = _2267 == _3779;
    assign _2442 = _2422 ? _2441 : _2433;
    assign _2443 = _2361 ? _2442 : t1_osr_count;
    assign _2444 = _2298 ? t1_osr_count : _2443;
    assign _2445 = _2295 ? t1_osr_count : _2444;
    assign _2446 = _2294 ? cfg_t1_threshold : _2445;
    assign _37 = _2446;
    assign _38 = _37;
    always @(posedge _99) begin
        if (_97)
            t1_osr_count <= _1523;
        else
            t1_osr_count <= _38;
    end
    assign _3235 = t1_osr_count < cfg_t1_threshold;
    assign _3233 = t1_x == t1_y;
    assign _3234 = ~ _3233;
    assign _3230 = t1_y == _356;
    assign _3231 = ~ _3230;
    assign _3232 = ~ _3231;
    assign _3215 = t1_x - _1469;
    assign _3213 = _3183 == _4048;
    assign _3216 = _3213 ? _3215 : t1_x;
    assign _3209 = _3146 == _184;
    assign _3210 = _3209 ? _3180 : t1_x;
    assign _2673 = _2596 & _2672;
    assign _2642 = _2641[15:0];
    assign _2644 = { _2642,
                     _356 };
    assign _2638 = _2637[23:0];
    assign _2640 = { _2638,
                     _305 };
    assign _2634 = _2633[27:0];
    assign _2636 = { _2634,
                     _301 };
    assign _2630 = _2629[29:0];
    assign _2632 = { _2630,
                     _520 };
    assign _2626 = _2625[30:0];
    assign _2628 = { _2626,
                     _574 };
    assign _2625 = { _356,
                     t1_isr };
    assign _2623 = _2399[0:0];
    assign _2629 = _2623 ? _2628 : _2625;
    assign _2622 = _2399[1:1];
    assign _2633 = _2622 ? _2632 : _2629;
    assign _2621 = _2399[2:2];
    assign _2637 = _2621 ? _2636 : _2633;
    assign _2620 = _2399[3:3];
    assign _2641 = _2620 ? _2640 : _2637;
    assign _2619 = _2399[4:4];
    assign _2645 = _2619 ? _2644 : _2641;
    assign _2646 = _2645[15:0];
    assign _2674 = _2646 | _2673;
    assign _2615 = _2613[31:16];
    assign _2616 = { _356,
                     _2615 };
    assign _2611 = _2609[31:8];
    assign _2612 = { _305,
                     _2611 };
    assign _2607 = _2605[31:4];
    assign _2608 = { _301,
                     _2607 };
    assign _2603 = _2601[31:2];
    assign _2604 = { _520,
                     _2603 };
    assign _2599 = _2597[31:1];
    assign _2600 = { _574,
                     _2599 };
    assign _2591 = _1523 < _2399;
    assign _2588 = _1442[7:7];
    assign _2587 = _1442[6:6];
    assign _2586 = _1442[5:5];
    assign _2585 = _1442[4:4];
    assign _2584 = _1442[3:3];
    assign _2583 = _1442[2:2];
    assign _2582 = _1442[1:1];
    assign _2581 = _1442[0:0];
    always @* begin
        case (cfg_t1_in_base)
        0:
            _2589 <= _2581;
        1:
            _2589 <= _2582;
        2:
            _2589 <= _2583;
        3:
            _2589 <= _2584;
        4:
            _2589 <= _2585;
        5:
            _2589 <= _2586;
        6:
            _2589 <= _2587;
        default:
            _2589 <= _2588;
        endcase
    end
    assign _2592 = _2589 & _2591;
    assign _2578 = 5'b00001;
    assign _2579 = _2578 < _2399;
    assign _2576 = _1442[7:7];
    assign _2575 = _1442[6:6];
    assign _2574 = _1442[5:5];
    assign _2573 = _1442[4:4];
    assign _2572 = _1442[3:3];
    assign _2571 = _1442[2:2];
    assign _2570 = _1442[1:1];
    assign _2569 = _1442[0:0];
    assign _2568 = cfg_t1_in_base + _1485;
    always @* begin
        case (_2568)
        0:
            _2577 <= _2569;
        1:
            _2577 <= _2570;
        2:
            _2577 <= _2571;
        3:
            _2577 <= _2572;
        4:
            _2577 <= _2573;
        5:
            _2577 <= _2574;
        6:
            _2577 <= _2575;
        default:
            _2577 <= _2576;
        endcase
    end
    assign _2580 = _2577 & _2579;
    assign _2564 = 5'b00010;
    assign _2565 = _2564 < _2399;
    assign _2562 = _1442[7:7];
    assign _2561 = _1442[6:6];
    assign _2560 = _1442[5:5];
    assign _2559 = _1442[4:4];
    assign _2558 = _1442[3:3];
    assign _2557 = _1442[2:2];
    assign _2556 = _1442[1:1];
    assign _2555 = _1442[0:0];
    assign _2554 = cfg_t1_in_base + _4048;
    always @* begin
        case (_2554)
        0:
            _2563 <= _2555;
        1:
            _2563 <= _2556;
        2:
            _2563 <= _2557;
        3:
            _2563 <= _2558;
        4:
            _2563 <= _2559;
        5:
            _2563 <= _2560;
        6:
            _2563 <= _2561;
        default:
            _2563 <= _2562;
        endcase
    end
    assign _2566 = _2563 & _2565;
    assign _2550 = 5'b00011;
    assign _2551 = _2550 < _2399;
    assign _2548 = _1442[7:7];
    assign _2547 = _1442[6:6];
    assign _2546 = _1442[5:5];
    assign _2545 = _1442[4:4];
    assign _2544 = _1442[3:3];
    assign _2543 = _1442[2:2];
    assign _2542 = _1442[1:1];
    assign _2541 = _1442[0:0];
    assign _2540 = cfg_t1_in_base + _3779;
    always @* begin
        case (_2540)
        0:
            _2549 <= _2541;
        1:
            _2549 <= _2542;
        2:
            _2549 <= _2543;
        3:
            _2549 <= _2544;
        4:
            _2549 <= _2545;
        5:
            _2549 <= _2546;
        6:
            _2549 <= _2547;
        default:
            _2549 <= _2548;
        endcase
    end
    assign _2552 = _2549 & _2551;
    assign _2536 = 5'b00100;
    assign _2537 = _2536 < _2399;
    assign _2534 = _1442[7:7];
    assign _2533 = _1442[6:6];
    assign _2532 = _1442[5:5];
    assign _2531 = _1442[4:4];
    assign _2530 = _1442[3:3];
    assign _2529 = _1442[2:2];
    assign _2528 = _1442[1:1];
    assign _2527 = _1442[0:0];
    assign _2526 = cfg_t1_in_base + _4177;
    always @* begin
        case (_2526)
        0:
            _2535 <= _2527;
        1:
            _2535 <= _2528;
        2:
            _2535 <= _2529;
        3:
            _2535 <= _2530;
        4:
            _2535 <= _2531;
        5:
            _2535 <= _2532;
        6:
            _2535 <= _2533;
        default:
            _2535 <= _2534;
        endcase
    end
    assign _2538 = _2535 & _2537;
    assign _2522 = 5'b00101;
    assign _2523 = _2522 < _2399;
    assign _2520 = _1442[7:7];
    assign _2519 = _1442[6:6];
    assign _2518 = _1442[5:5];
    assign _2517 = _1442[4:4];
    assign _2516 = _1442[3:3];
    assign _2515 = _1442[2:2];
    assign _2514 = _1442[1:1];
    assign _2513 = _1442[0:0];
    assign _2512 = cfg_t1_in_base + _3745;
    always @* begin
        case (_2512)
        0:
            _2521 <= _2513;
        1:
            _2521 <= _2514;
        2:
            _2521 <= _2515;
        3:
            _2521 <= _2516;
        4:
            _2521 <= _2517;
        5:
            _2521 <= _2518;
        6:
            _2521 <= _2519;
        default:
            _2521 <= _2520;
        endcase
    end
    assign _2524 = _2521 & _2523;
    assign _2508 = 5'b00110;
    assign _2509 = _2508 < _2399;
    assign _2506 = _1442[7:7];
    assign _2505 = _1442[6:6];
    assign _2504 = _1442[5:5];
    assign _2503 = _1442[4:4];
    assign _2502 = _1442[3:3];
    assign _2501 = _1442[2:2];
    assign _2500 = _1442[1:1];
    assign _2499 = _1442[0:0];
    assign _2498 = cfg_t1_in_base + _3728;
    always @* begin
        case (_2498)
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
    assign _2510 = _2507 & _2509;
    assign _2494 = 5'b00111;
    assign _2495 = _2494 < _2399;
    assign _2492 = _1442[7:7];
    assign _2491 = _1442[6:6];
    assign _2490 = _1442[5:5];
    assign _2489 = _1442[4:4];
    assign _2488 = _1442[3:3];
    assign _2487 = _1442[2:2];
    assign _2486 = _1442[1:1];
    assign _2485 = _1442[0:0];
    assign _2451 = _590[2:0];
    assign _2449 = _586 == _1126;
    assign _2447 = _580 & _584;
    assign _2450 = _2447 & _2449;
    assign _2452 = _2450 ? _2451 : cfg_t1_in_base;
    assign _39 = _2452;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_in_base <= _544;
        else
            cfg_t1_in_base <= _39;
    end
    assign _2484 = cfg_t1_in_base + _3570;
    always @* begin
        case (_2484)
        0:
            _2493 <= _2485;
        1:
            _2493 <= _2486;
        2:
            _2493 <= _2487;
        3:
            _2493 <= _2488;
        4:
            _2493 <= _2489;
        5:
            _2493 <= _2490;
        6:
            _2493 <= _2491;
        default:
            _2493 <= _2492;
        endcase
    end
    assign _2496 = _2493 & _2495;
    assign _2593 = { _2496,
                     _2510,
                     _2524,
                     _2538,
                     _2552,
                     _2566,
                     _2580,
                     _2592 };
    assign _2594 = { _305,
                     _2593 };
    assign _2481 = _2266[8:7];
    always @* begin
        case (_2481)
        0:
            _2596 <= _2594;
        1:
            _2596 <= t1_x;
        2:
            _2596 <= t1_y;
        default:
            _2596 <= _356;
        endcase
    end
    assign _2597 = { _2596,
                     t1_isr };
    assign _2480 = _2399[0:0];
    assign _2601 = _2480 ? _2600 : _2597;
    assign _2479 = _2399[1:1];
    assign _2605 = _2479 ? _2604 : _2601;
    assign _2478 = _2399[2:2];
    assign _2609 = _2478 ? _2608 : _2605;
    assign _2477 = _2399[3:3];
    assign _2613 = _2477 ? _2612 : _2609;
    assign _2476 = _2399[4:4];
    assign _2617 = _2476 ? _2616 : _2613;
    assign _2618 = _2617[15:0];
    assign _251 = cfg_t1_shift[1:1];
    assign _2675 = _251 ? _2674 : _2618;
    assign _2474 = _2271 ? t1_isr : _356;
    assign _2456 = _2376 == _3779;
    assign _2470 = _2456 ? _2469 : t1_isr;
    assign _2471 = _2382 ? _2470 : t1_isr;
    assign _2455 = _2267 == _3745;
    assign _2472 = _2455 ? _2471 : t1_isr;
    assign _2454 = _2267 == _4177;
    assign _2475 = _2454 ? _2474 : _2472;
    assign _2453 = _2267 == _4048;
    assign _2676 = _2453 ? _2675 : _2475;
    assign _2677 = _2361 ? _2676 : t1_isr;
    assign _2678 = _2298 ? t1_isr : _2677;
    assign _2679 = _2295 ? t1_isr : _2678;
    assign _2681 = _2294 ? _356 : _2679;
    assign _40 = _2681;
    assign _41 = _40;
    always @(posedge _99) begin
        if (_97)
            t1_isr <= _356;
        else
            t1_isr <= _41;
    end
    assign _2464 = { _305,
                     _1442 };
    assign _3187 = t1_y - _1469;
    assign _3185 = _3183 == _4177;
    assign _3188 = _3185 ? _3187 : t1_y;
    assign _3176 = _3174[31:16];
    assign _3177 = { _356,
                     _3176 };
    assign _3172 = _3170[31:8];
    assign _3173 = { _305,
                     _3172 };
    assign _3168 = _3166[31:4];
    assign _3169 = { _301,
                     _3168 };
    assign _3164 = _3162[31:2];
    assign _3165 = { _520,
                     _3164 };
    assign _3160 = _3158[31:1];
    assign _3161 = { _574,
                     _3160 };
    assign _3158 = { _356,
                     t1_osr };
    assign _3156 = _3151[0:0];
    assign _3162 = _3156 ? _3161 : _3158;
    assign _3155 = _3151[1:1];
    assign _3166 = _3155 ? _3165 : _3162;
    assign _3154 = _3151[2:2];
    assign _3170 = _3154 ? _3169 : _3166;
    assign _3153 = _3151[3:3];
    assign _3174 = _3153 ? _3173 : _3170;
    assign _3151 = _252 - _2399;
    assign _3152 = _3151[4:4];
    assign _3178 = _3152 ? _3177 : _3174;
    assign _3179 = _3178[15:0];
    assign _2667 = _2666[15:0];
    assign _2669 = { _2667,
                     _356 };
    assign _2663 = _2662[23:0];
    assign _2665 = { _2663,
                     _305 };
    assign _2659 = _2658[27:0];
    assign _2661 = { _2659,
                     _301 };
    assign _2655 = _2654[29:0];
    assign _2657 = { _2655,
                     _520 };
    assign _2651 = _2399[0:0];
    assign _2654 = _2651 ? _294 : _293;
    assign _2650 = _2399[1:1];
    assign _2658 = _2650 ? _2657 : _2654;
    assign _2649 = _2399[2:2];
    assign _2662 = _2649 ? _2661 : _2658;
    assign _2648 = _2399[3:3];
    assign _2666 = _2648 ? _2665 : _2662;
    assign _2647 = _2399[4:4];
    assign _2670 = _2647 ? _2669 : _2666;
    assign _2671 = _2670[15:0];
    assign _2672 = ~ _2671;
    assign _3109 = _3108[15:0];
    assign _3111 = { _3109,
                     _356 };
    assign _3105 = _3104[23:0];
    assign _3107 = { _3105,
                     _305 };
    assign _3101 = _3100[27:0];
    assign _3103 = { _3101,
                     _301 };
    assign _3097 = _3096[29:0];
    assign _3099 = { _3097,
                     _520 };
    assign _3093 = _3092[30:0];
    assign _3095 = { _3093,
                     _574 };
    assign _3092 = { _356,
                     t1_osr };
    assign _3090 = _2399[0:0];
    assign _3096 = _3090 ? _3095 : _3092;
    assign _3089 = _2399[1:1];
    assign _3100 = _3089 ? _3099 : _3096;
    assign _3088 = _2399[2:2];
    assign _3104 = _3088 ? _3103 : _3100;
    assign _3087 = _2399[3:3];
    assign _3108 = _3087 ? _3107 : _3104;
    assign _3086 = _2399[4:4];
    assign _3112 = _3086 ? _3111 : _3108;
    assign _3113 = _3112[15:0];
    assign _3082 = _3080[31:16];
    assign _3083 = { _356,
                     _3082 };
    assign _3078 = _3076[31:8];
    assign _3079 = { _305,
                     _3078 };
    assign _3074 = _3072[31:4];
    assign _3075 = { _301,
                     _3074 };
    assign _3070 = _3068[31:2];
    assign _3071 = { _520,
                     _3070 };
    assign _3066 = _3064[31:1];
    assign _3067 = { _574,
                     _3066 };
    assign _3064 = { _356,
                     t1_osr };
    assign _3062 = _2399[0:0];
    assign _3068 = _3062 ? _3067 : _3064;
    assign _3061 = _2399[1:1];
    assign _3072 = _3061 ? _3071 : _3068;
    assign _3060 = _2399[2:2];
    assign _3076 = _3060 ? _3075 : _3072;
    assign _3059 = _2399[3:3];
    assign _3080 = _3059 ? _3079 : _3076;
    assign _2397 = { gnd,
                     _2394 };
    assign _2394 = _2266[3:0];
    assign _2396 = _2394 == _301;
    assign _2399 = _2396 ? _252 : _2397;
    assign _3058 = _2399[4:4];
    assign _3084 = _3058 ? _3083 : _3080;
    assign _3085 = _3084[15:0];
    assign _3114 = _3057 ? _3113 : _3085;
    assign _3051 = t1_tx_wr == _538;
    assign _3052 = _2693 & _3051;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_3 <= _356;
        else
            if (_3052)
                t1_tx_mem_3 <= _3029;
    end
    assign _3045 = t1_tx_wr == _187;
    assign _3046 = _2693 & _3045;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_2 <= _356;
        else
            if (_3046)
                t1_tx_mem_2 <= _3029;
    end
    assign _3039 = t1_tx_wr == _184;
    assign _3040 = _2693 & _3039;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_1 <= _356;
        else
            if (_3040)
                t1_tx_mem_1 <= _3029;
    end
    assign _2698 = t1_tx_wr + _184;
    assign _2699 = _2693 ? _2698 : t1_tx_wr;
    assign _42 = _2699;
    always @(posedge _99) begin
        if (_97)
            t1_tx_wr <= _520;
        else
            t1_tx_wr <= _42;
    end
    assign _3033 = t1_tx_wr == _520;
    assign _3034 = _2693 & _3033;
    assign _445 = t0_rx_wr == _538;
    assign _446 = _422 & _445;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_3 <= _356;
        else
            if (_446)
                t0_rx_mem_3 <= _49;
    end
    assign _439 = t0_rx_wr == _187;
    assign _440 = _422 & _439;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_2 <= _356;
        else
            if (_440)
                t0_rx_mem_2 <= _49;
    end
    assign _433 = t0_rx_wr == _184;
    assign _434 = _422 & _433;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_1 <= _356;
        else
            if (_434)
                t0_rx_mem_1 <= _49;
    end
    assign _2701 = t0_rx_wr + _184;
    assign _2702 = _422 ? _2701 : t0_rx_wr;
    assign _43 = _2702;
    always @(posedge _99) begin
        if (_97)
            t0_rx_wr <= _520;
        else
            t0_rx_wr <= _43;
    end
    assign _427 = t0_rx_wr == _520;
    assign _428 = _422 & _427;
    assign _2980 = _2979[15:0];
    assign _2982 = { _2980,
                     _356 };
    assign _2976 = _2975[23:0];
    assign _2978 = { _2976,
                     _305 };
    assign _2972 = _2971[27:0];
    assign _2974 = { _2972,
                     _301 };
    assign _2968 = _2967[29:0];
    assign _2970 = { _2968,
                     _520 };
    assign _2964 = t0_isr_count[0:0];
    assign _2967 = _2964 ? _294 : _293;
    assign _2963 = t0_isr_count[1:1];
    assign _2971 = _2963 ? _2970 : _2967;
    assign _2962 = t0_isr_count[2:2];
    assign _2975 = _2962 ? _2974 : _2971;
    assign _2961 = t0_isr_count[3:3];
    assign _2979 = _2961 ? _2978 : _2975;
    assign _2960 = t0_isr_count[4:4];
    assign _2983 = _2960 ? _2982 : _2979;
    assign _2984 = _2983[15:0];
    assign _2985 = ~ _2984;
    assign _2986 = t0_isr & _2985;
    assign _2956 = _2954[31:16];
    assign _2957 = { _356,
                     _2956 };
    assign _2952 = _2950[31:8];
    assign _2953 = { _305,
                     _2952 };
    assign _2948 = _2946[31:4];
    assign _2949 = { _301,
                     _2948 };
    assign _2944 = _2942[31:2];
    assign _2945 = { _520,
                     _2944 };
    assign _2940 = _2938[31:1];
    assign _2941 = { _574,
                     _2940 };
    assign _2893 = _2842 & _1924;
    assign _2888 = _2887[15:0];
    assign _2890 = { _2888,
                     _356 };
    assign _2884 = _2883[23:0];
    assign _2886 = { _2884,
                     _305 };
    assign _2880 = _2879[27:0];
    assign _2882 = { _2880,
                     _301 };
    assign _2876 = _2875[29:0];
    assign _2878 = { _2876,
                     _520 };
    assign _2872 = _2871[30:0];
    assign _2874 = { _2872,
                     _574 };
    assign _2871 = { _356,
                     t0_isr };
    assign _2869 = _1554[0:0];
    assign _2875 = _2869 ? _2874 : _2871;
    assign _2868 = _1554[1:1];
    assign _2879 = _2868 ? _2878 : _2875;
    assign _2867 = _1554[2:2];
    assign _2883 = _2867 ? _2882 : _2879;
    assign _2866 = _1554[3:3];
    assign _2887 = _2866 ? _2886 : _2883;
    assign _2865 = _1554[4:4];
    assign _2891 = _2865 ? _2890 : _2887;
    assign _2892 = _2891[15:0];
    assign _2894 = _2892 | _2893;
    assign _2861 = _2859[31:16];
    assign _2862 = { _356,
                     _2861 };
    assign _2857 = _2855[31:8];
    assign _2858 = { _305,
                     _2857 };
    assign _2853 = _2851[31:4];
    assign _2854 = { _301,
                     _2853 };
    assign _2849 = _2847[31:2];
    assign _2850 = { _520,
                     _2849 };
    assign _2845 = _2843[31:1];
    assign _2846 = { _574,
                     _2845 };
    assign _2837 = _1523 < _1554;
    assign _2834 = _1442[7:7];
    assign _2833 = _1442[6:6];
    assign _2832 = _1442[5:5];
    assign _2831 = _1442[4:4];
    assign _2830 = _1442[3:3];
    assign _2829 = _1442[2:2];
    assign _2828 = _1442[1:1];
    assign _2827 = _1442[0:0];
    always @* begin
        case (cfg_t0_in_base)
        0:
            _2835 <= _2827;
        1:
            _2835 <= _2828;
        2:
            _2835 <= _2829;
        3:
            _2835 <= _2830;
        4:
            _2835 <= _2831;
        5:
            _2835 <= _2832;
        6:
            _2835 <= _2833;
        default:
            _2835 <= _2834;
        endcase
    end
    assign _2838 = _2835 & _2837;
    assign _2825 = _2578 < _1554;
    assign _2822 = _1442[7:7];
    assign _2821 = _1442[6:6];
    assign _2820 = _1442[5:5];
    assign _2819 = _1442[4:4];
    assign _2818 = _1442[3:3];
    assign _2817 = _1442[2:2];
    assign _2816 = _1442[1:1];
    assign _2815 = _1442[0:0];
    assign _2814 = cfg_t0_in_base + _1485;
    always @* begin
        case (_2814)
        0:
            _2823 <= _2815;
        1:
            _2823 <= _2816;
        2:
            _2823 <= _2817;
        3:
            _2823 <= _2818;
        4:
            _2823 <= _2819;
        5:
            _2823 <= _2820;
        6:
            _2823 <= _2821;
        default:
            _2823 <= _2822;
        endcase
    end
    assign _2826 = _2823 & _2825;
    assign _2811 = _2564 < _1554;
    assign _2808 = _1442[7:7];
    assign _2807 = _1442[6:6];
    assign _2806 = _1442[5:5];
    assign _2805 = _1442[4:4];
    assign _2804 = _1442[3:3];
    assign _2803 = _1442[2:2];
    assign _2802 = _1442[1:1];
    assign _2801 = _1442[0:0];
    assign _2800 = cfg_t0_in_base + _4048;
    always @* begin
        case (_2800)
        0:
            _2809 <= _2801;
        1:
            _2809 <= _2802;
        2:
            _2809 <= _2803;
        3:
            _2809 <= _2804;
        4:
            _2809 <= _2805;
        5:
            _2809 <= _2806;
        6:
            _2809 <= _2807;
        default:
            _2809 <= _2808;
        endcase
    end
    assign _2812 = _2809 & _2811;
    assign _2797 = _2550 < _1554;
    assign _2794 = _1442[7:7];
    assign _2793 = _1442[6:6];
    assign _2792 = _1442[5:5];
    assign _2791 = _1442[4:4];
    assign _2790 = _1442[3:3];
    assign _2789 = _1442[2:2];
    assign _2788 = _1442[1:1];
    assign _2787 = _1442[0:0];
    assign _2786 = cfg_t0_in_base + _3779;
    always @* begin
        case (_2786)
        0:
            _2795 <= _2787;
        1:
            _2795 <= _2788;
        2:
            _2795 <= _2789;
        3:
            _2795 <= _2790;
        4:
            _2795 <= _2791;
        5:
            _2795 <= _2792;
        6:
            _2795 <= _2793;
        default:
            _2795 <= _2794;
        endcase
    end
    assign _2798 = _2795 & _2797;
    assign _2783 = _2536 < _1554;
    assign _2780 = _1442[7:7];
    assign _2779 = _1442[6:6];
    assign _2778 = _1442[5:5];
    assign _2777 = _1442[4:4];
    assign _2776 = _1442[3:3];
    assign _2775 = _1442[2:2];
    assign _2774 = _1442[1:1];
    assign _2773 = _1442[0:0];
    assign _2772 = cfg_t0_in_base + _4177;
    always @* begin
        case (_2772)
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
    assign _2784 = _2781 & _2783;
    assign _2769 = _2522 < _1554;
    assign _2766 = _1442[7:7];
    assign _2765 = _1442[6:6];
    assign _2764 = _1442[5:5];
    assign _2763 = _1442[4:4];
    assign _2762 = _1442[3:3];
    assign _2761 = _1442[2:2];
    assign _2760 = _1442[1:1];
    assign _2759 = _1442[0:0];
    assign _2758 = cfg_t0_in_base + _3745;
    always @* begin
        case (_2758)
        0:
            _2767 <= _2759;
        1:
            _2767 <= _2760;
        2:
            _2767 <= _2761;
        3:
            _2767 <= _2762;
        4:
            _2767 <= _2763;
        5:
            _2767 <= _2764;
        6:
            _2767 <= _2765;
        default:
            _2767 <= _2766;
        endcase
    end
    assign _2770 = _2767 & _2769;
    assign _2755 = _2508 < _1554;
    assign _2752 = _1442[7:7];
    assign _2751 = _1442[6:6];
    assign _2750 = _1442[5:5];
    assign _2749 = _1442[4:4];
    assign _2748 = _1442[3:3];
    assign _2747 = _1442[2:2];
    assign _2746 = _1442[1:1];
    assign _2745 = _1442[0:0];
    assign _2744 = cfg_t0_in_base + _3728;
    always @* begin
        case (_2744)
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
    assign _2756 = _2753 & _2755;
    assign _2741 = _2494 < _1554;
    assign _2738 = _1442[7:7];
    assign _2737 = _1442[6:6];
    assign _2736 = _1442[5:5];
    assign _2735 = _1442[4:4];
    assign _2734 = _1442[3:3];
    assign _2733 = _1442[2:2];
    assign _2732 = _1442[1:1];
    assign _2731 = _1442[0:0];
    assign _2707 = _590[2:0];
    assign _2705 = _586 == _1030;
    assign _2703 = _580 & _584;
    assign _2706 = _2703 & _2705;
    assign _2708 = _2706 ? _2707 : cfg_t0_in_base;
    assign _44 = _2708;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_in_base <= _544;
        else
            cfg_t0_in_base <= _44;
    end
    assign _2730 = cfg_t0_in_base + _3570;
    always @* begin
        case (_2730)
        0:
            _2739 <= _2731;
        1:
            _2739 <= _2732;
        2:
            _2739 <= _2733;
        3:
            _2739 <= _2734;
        4:
            _2739 <= _2735;
        5:
            _2739 <= _2736;
        6:
            _2739 <= _2737;
        default:
            _2739 <= _2738;
        endcase
    end
    assign _2742 = _2739 & _2741;
    assign _2839 = { _2742,
                     _2756,
                     _2770,
                     _2784,
                     _2798,
                     _2812,
                     _2826,
                     _2838 };
    assign _2840 = { _305,
                     _2839 };
    assign _2727 = _1388[8:7];
    always @* begin
        case (_2727)
        0:
            _2842 <= _2840;
        1:
            _2842 <= t0_x;
        2:
            _2842 <= t0_y;
        default:
            _2842 <= _356;
        endcase
    end
    assign _2843 = { _2842,
                     t0_isr };
    assign _2726 = _1554[0:0];
    assign _2847 = _2726 ? _2846 : _2843;
    assign _2725 = _1554[1:1];
    assign _2851 = _2725 ? _2850 : _2847;
    assign _2724 = _1554[2:2];
    assign _2855 = _2724 ? _2854 : _2851;
    assign _2723 = _1554[3:3];
    assign _2859 = _2723 ? _2858 : _2855;
    assign _2722 = _1554[4:4];
    assign _2863 = _2722 ? _2862 : _2859;
    assign _2864 = _2863[15:0];
    assign _2895 = _2721 ? _2894 : _2864;
    assign _2719 = _1494 ? t0_isr : _356;
    assign _2714 = _1531 == _3779;
    assign _2715 = _2714 ? _1774 : t0_isr;
    assign _2716 = _1537 ? _2715 : t0_isr;
    assign _2712 = _1389 == _3745;
    assign _2717 = _2712 ? _2716 : t0_isr;
    assign _2711 = _1389 == _4177;
    assign _2720 = _2711 ? _2719 : _2717;
    assign _2710 = _1389 == _4048;
    assign _2896 = _2710 ? _2895 : _2720;
    assign _2897 = _1507 ? _2896 : t0_isr;
    assign _2898 = _612 ? t0_isr : _2897;
    assign _2899 = _606 ? t0_isr : _2898;
    assign _2901 = _600 ? _356 : _2899;
    assign _45 = _2901;
    assign _46 = _45;
    always @(posedge _99) begin
        if (_97)
            t0_isr <= _356;
        else
            t0_isr <= _46;
    end
    assign _2938 = { _356,
                     t0_isr };
    assign _2936 = _2931[0:0];
    assign _2942 = _2936 ? _2941 : _2938;
    assign _2935 = _2931[1:1];
    assign _2946 = _2935 ? _2945 : _2942;
    assign _2934 = _2931[2:2];
    assign _2950 = _2934 ? _2949 : _2946;
    assign _2933 = _2931[3:3];
    assign _2954 = _2933 ? _2953 : _2950;
    assign _2921 = _2919[4:0];
    assign _2918 = { gnd,
                     _1554 };
    assign _2917 = { gnd,
                     t0_isr_count };
    assign _2919 = _2917 + _2918;
    assign _2920 = _1547 < _2919;
    assign _2923 = _2920 ? _252 : _2921;
    assign _2914 = _1494 ? t0_isr_count : _1523;
    assign _2908 = _1531 == _3779;
    assign _2910 = _2908 ? _1523 : t0_isr_count;
    assign _2911 = _1537 ? _2910 : t0_isr_count;
    assign _2907 = _1389 == _3745;
    assign _2912 = _2907 ? _2911 : t0_isr_count;
    assign _2906 = _1389 == _4177;
    assign _2915 = _2906 ? _2914 : _2912;
    assign _2905 = _1389 == _4048;
    assign _2924 = _2905 ? _2923 : _2915;
    assign _2925 = _1507 ? _2924 : t0_isr_count;
    assign _2926 = _612 ? t0_isr_count : _2925;
    assign _2927 = _606 ? t0_isr_count : _2926;
    assign _2929 = _600 ? _1523 : _2927;
    assign _47 = _2929;
    assign _48 = _47;
    always @(posedge _99) begin
        if (_97)
            t0_isr_count <= _1523;
        else
            t0_isr_count <= _48;
    end
    assign _2931 = _252 - t0_isr_count;
    assign _2932 = _2931[4:4];
    assign _2958 = _2932 ? _2957 : _2954;
    assign _2959 = _2958[15:0];
    assign _2721 = cfg_t0_shift[1:1];
    assign _2987 = _2721 ? _2986 : _2959;
    assign _49 = _2987;
    always @(posedge _99) begin
        if (_97)
            t0_rx_mem_0 <= _356;
        else
            if (_428)
                t0_rx_mem_0 <= _49;
    end
    assign _3006 = t0_rx_rd + _184;
    assign _3003 = ~ _3002;
    assign _2998 = ~ _2686;
    assign _2995 = t0_rx_level == _544;
    assign _2996 = ~ _2995;
    assign _370 = _369[6:0];
    assign _2992 = _370 == _1060;
    assign _2988 = _369[7:7];
    assign _2989 = ~ _2988;
    assign _2241 = host_bit_count == _2494;
    assign _2242 = _354 & _2241;
    assign _2990 = _2242 & _2989;
    assign _2993 = _2990 & _2992;
    assign _2997 = _2993 & _2996;
    assign _50 = _2997;
    assign _2999 = _50 & _2998;
    assign _3000 = _103 | _2999;
    assign _3004 = _3000 & _3003;
    assign _3007 = _3004 ? _3006 : t0_rx_rd;
    assign _51 = _3007;
    always @(posedge _99) begin
        if (_97)
            t0_rx_rd <= _520;
        else
            t0_rx_rd <= _51;
    end
    always @* begin
        case (t0_rx_rd)
        0:
            _448 <= t0_rx_mem_0;
        1:
            _448 <= t0_rx_mem_1;
        2:
            _448 <= t0_rx_mem_2;
        default:
            _448 <= t0_rx_mem_3;
        endcase
    end
    assign _52 = _448;
    assign _3029 = _103 ? _52 : _590;
    always @(posedge _99) begin
        if (_97)
            t1_tx_mem_0 <= _356;
        else
            if (_3034)
                t1_tx_mem_0 <= _3029;
    end
    assign _3020 = t1_tx_rd + _184;
    assign _3014 = ~ _2351;
    assign _2351 = t1_tx_level == _544;
    assign _3012 = ~ _2351;
    assign _3009 = _2267 == _4177;
    assign _3010 = _2265 & _3009;
    assign _3011 = _3010 & _2271;
    assign _3013 = _3011 & _3012;
    assign _53 = _3013;
    assign _3015 = _53 & _3014;
    assign _3021 = _3015 ? _3020 : t1_tx_rd;
    assign _54 = _3021;
    always @(posedge _99) begin
        if (_97)
            t1_tx_rd <= _520;
        else
            t1_tx_rd <= _54;
    end
    always @* begin
        case (t1_tx_rd)
        0:
            _3054 <= t1_tx_mem_0;
        1:
            _3054 <= t1_tx_mem_1;
        2:
            _3054 <= t1_tx_mem_2;
        default:
            _3054 <= t1_tx_mem_3;
        endcase
    end
    assign _2271 = _2266[8:8];
    assign _3055 = _2271 ? _3054 : t1_osr;
    assign _3025 = _2376 == _4177;
    assign _3026 = _3025 ? _2469 : t1_osr;
    assign _3027 = _2382 ? _3026 : t1_osr;
    assign _3024 = _2267 == _3745;
    assign _3028 = _3024 ? _3027 : t1_osr;
    assign _3023 = _2267 == _4177;
    assign _3056 = _3023 ? _3055 : _3028;
    assign _3022 = _2267 == _3779;
    assign _3115 = _3022 ? _3114 : _3056;
    assign _3116 = _2361 ? _3115 : t1_osr;
    assign _3117 = _2298 ? t1_osr : _3116;
    assign _3118 = _2295 ? t1_osr : _3117;
    assign _3120 = _2294 ? _356 : _3118;
    assign _55 = _3120;
    assign _56 = _55;
    always @(posedge _99) begin
        if (_97)
            t1_osr <= _356;
        else
            t1_osr <= _56;
    end
    assign _3149 = t1_osr & _2672;
    assign _3125 = _590[1:0];
    assign _3123 = _586 == _1192;
    assign _3121 = _580 & _584;
    assign _3124 = _3121 & _3123;
    assign _3126 = _3124 ? _3125 : cfg_t1_shift;
    assign _57 = _3126;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_shift <= _520;
        else
            cfg_t1_shift <= _57;
    end
    assign _3057 = cfg_t1_shift[0:0];
    assign _3180 = _3057 ? _3179 : _3149;
    assign _3146 = _2266[8:7];
    assign _3148 = _3146 == _187;
    assign _3181 = _3148 ? _3180 : t1_y;
    assign _3142 = _2376 == _1485;
    assign _3143 = _3142 ? _2469 : t1_y;
    assign _3144 = _2382 ? _3143 : t1_y;
    assign _3135 = _3133 == _187;
    assign _3139 = _3135 ? _3138 : t1_y;
    assign _3132 = _2267 == _3728;
    assign _3140 = _3132 ? _3139 : t1_y;
    assign _3130 = _2267 == _3745;
    assign _3145 = _3130 ? _3144 : _3140;
    assign _3129 = _2267 == _3779;
    assign _3182 = _3129 ? _3181 : _3145;
    assign _3128 = _2267 == _544;
    assign _3189 = _3128 ? _3188 : _3182;
    assign _3190 = _2361 ? _3189 : t1_y;
    assign _3191 = _2298 ? t1_y : _3190;
    assign _3192 = _2295 ? t1_y : _3191;
    assign _3194 = _2294 ? _356 : _3192;
    assign _58 = _3194;
    assign _59 = _58;
    always @(posedge _99) begin
        if (_97)
            t1_y <= _356;
        else
            t1_y <= _59;
    end
    always @* begin
        case (_2379)
        0:
            _2469 <= t1_x;
        1:
            _2469 <= t1_y;
        2:
            _2469 <= _2464;
        3:
            _2469 <= t1_isr;
        4:
            _2469 <= t1_osr;
        default:
            _2469 <= _356;
        endcase
    end
    assign _3204 = _2376 == _544;
    assign _3205 = _3204 ? _2469 : t1_x;
    assign _2379 = _2266[5:3];
    assign _2381 = _2379 < _3728;
    assign _2376 = _2266[8:6];
    assign _2378 = _2376 < _3728;
    assign _2382 = _2378 & _2381;
    assign _3206 = _2382 ? _3205 : t1_x;
    assign _3137 = _2266[4:0];
    assign _3138 = { _504,
                     _3137 };
    assign _3133 = _2266[8:7];
    assign _3200 = _3133 == _184;
    assign _3201 = _3200 ? _3138 : t1_x;
    assign _3198 = _2267 == _3728;
    assign _3202 = _3198 ? _3201 : t1_x;
    assign _3197 = _2267 == _3745;
    assign _3207 = _3197 ? _3206 : _3202;
    assign _3196 = _2267 == _3779;
    assign _3211 = _3196 ? _3210 : _3207;
    assign _3195 = _2267 == _544;
    assign _3217 = _3195 ? _3216 : _3211;
    assign _3218 = _2361 ? _3217 : t1_x;
    assign _3219 = _2298 ? t1_x : _3218;
    assign _3220 = _2295 ? t1_x : _3219;
    assign _3222 = _2294 ? _356 : _3220;
    assign _60 = _3222;
    assign _61 = _60;
    always @(posedge _99) begin
        if (_97)
            t1_x <= _356;
        else
            t1_x <= _61;
    end
    assign _3226 = t1_x == _356;
    assign _3227 = ~ _3226;
    assign _3228 = ~ _3227;
    assign _3183 = _2266[8:6];
    always @* begin
        case (_3183)
        0:
            _3237 <= vdd;
        1:
            _3237 <= _3228;
        2:
            _3237 <= _3227;
        3:
            _3237 <= _3232;
        4:
            _3237 <= _3231;
        5:
            _3237 <= _3234;
        6:
            _3237 <= _3235;
        default:
            _3237 <= _3236;
        endcase
    end
    assign _3224 = _2267 == _544;
    assign _3238 = _3224 & _3237;
    assign _3244 = _3238 | _3243;
    assign _3253 = _3244 ? _3252 : _3246;
    assign _3254 = _2361 ? _3253 : t1_pc;
    assign _3255 = _2298 ? t1_pc : _3254;
    assign _3256 = _2295 ? t1_pc : _3255;
    assign _3257 = _2294 ? cfg_t1_start : _3256;
    assign _62 = _3257;
    assign _63 = _62;
    always @(posedge _99) begin
        if (_97)
            t1_pc <= _452;
        else
            t1_pc <= _63;
    end
    always @* begin
        case (t1_pc)
        0:
            _2266 <= prog_0;
        1:
            _2266 <= prog_1;
        2:
            _2266 <= prog_2;
        3:
            _2266 <= prog_3;
        4:
            _2266 <= prog_4;
        5:
            _2266 <= prog_5;
        6:
            _2266 <= prog_6;
        7:
            _2266 <= prog_7;
        8:
            _2266 <= prog_8;
        9:
            _2266 <= prog_9;
        10:
            _2266 <= prog_10;
        11:
            _2266 <= prog_11;
        12:
            _2266 <= prog_12;
        13:
            _2266 <= prog_13;
        14:
            _2266 <= prog_14;
        15:
            _2266 <= prog_15;
        16:
            _2266 <= prog_16;
        17:
            _2266 <= prog_17;
        18:
            _2266 <= prog_18;
        19:
            _2266 <= prog_19;
        20:
            _2266 <= prog_20;
        21:
            _2266 <= prog_21;
        22:
            _2266 <= prog_22;
        23:
            _2266 <= prog_23;
        24:
            _2266 <= prog_24;
        25:
            _2266 <= prog_25;
        26:
            _2266 <= prog_26;
        27:
            _2266 <= prog_27;
        28:
            _2266 <= prog_28;
        29:
            _2266 <= prog_29;
        30:
            _2266 <= prog_30;
        31:
            _2266 <= prog_31;
        32:
            _2266 <= prog_32;
        33:
            _2266 <= prog_33;
        34:
            _2266 <= prog_34;
        35:
            _2266 <= prog_35;
        36:
            _2266 <= prog_36;
        37:
            _2266 <= prog_37;
        38:
            _2266 <= prog_38;
        39:
            _2266 <= prog_39;
        40:
            _2266 <= prog_40;
        41:
            _2266 <= prog_41;
        42:
            _2266 <= prog_42;
        43:
            _2266 <= prog_43;
        44:
            _2266 <= prog_44;
        45:
            _2266 <= prog_45;
        46:
            _2266 <= prog_46;
        47:
            _2266 <= prog_47;
        48:
            _2266 <= prog_48;
        49:
            _2266 <= prog_49;
        50:
            _2266 <= prog_50;
        51:
            _2266 <= prog_51;
        52:
            _2266 <= prog_52;
        53:
            _2266 <= prog_53;
        54:
            _2266 <= prog_54;
        55:
            _2266 <= prog_55;
        56:
            _2266 <= prog_56;
        57:
            _2266 <= prog_57;
        58:
            _2266 <= prog_58;
        59:
            _2266 <= prog_59;
        60:
            _2266 <= prog_60;
        61:
            _2266 <= prog_61;
        62:
            _2266 <= prog_62;
        63:
            _2266 <= prog_63;
        64:
            _2266 <= prog_64;
        65:
            _2266 <= prog_65;
        66:
            _2266 <= prog_66;
        67:
            _2266 <= prog_67;
        68:
            _2266 <= prog_68;
        69:
            _2266 <= prog_69;
        70:
            _2266 <= prog_70;
        71:
            _2266 <= prog_71;
        72:
            _2266 <= prog_72;
        73:
            _2266 <= prog_73;
        74:
            _2266 <= prog_74;
        75:
            _2266 <= prog_75;
        76:
            _2266 <= prog_76;
        77:
            _2266 <= prog_77;
        78:
            _2266 <= prog_78;
        79:
            _2266 <= prog_79;
        80:
            _2266 <= prog_80;
        81:
            _2266 <= prog_81;
        82:
            _2266 <= prog_82;
        83:
            _2266 <= prog_83;
        84:
            _2266 <= prog_84;
        85:
            _2266 <= prog_85;
        86:
            _2266 <= prog_86;
        87:
            _2266 <= prog_87;
        88:
            _2266 <= prog_88;
        89:
            _2266 <= prog_89;
        90:
            _2266 <= prog_90;
        91:
            _2266 <= prog_91;
        92:
            _2266 <= prog_92;
        93:
            _2266 <= prog_93;
        94:
            _2266 <= prog_94;
        95:
            _2266 <= prog_95;
        96:
            _2266 <= prog_96;
        97:
            _2266 <= prog_97;
        98:
            _2266 <= prog_98;
        99:
            _2266 <= prog_99;
        100:
            _2266 <= prog_100;
        101:
            _2266 <= prog_101;
        102:
            _2266 <= prog_102;
        103:
            _2266 <= prog_103;
        104:
            _2266 <= prog_104;
        105:
            _2266 <= prog_105;
        106:
            _2266 <= prog_106;
        107:
            _2266 <= prog_107;
        108:
            _2266 <= prog_108;
        109:
            _2266 <= prog_109;
        110:
            _2266 <= prog_110;
        111:
            _2266 <= prog_111;
        112:
            _2266 <= prog_112;
        113:
            _2266 <= prog_113;
        114:
            _2266 <= prog_114;
        115:
            _2266 <= prog_115;
        116:
            _2266 <= prog_116;
        117:
            _2266 <= prog_117;
        118:
            _2266 <= prog_118;
        119:
            _2266 <= prog_119;
        120:
            _2266 <= prog_120;
        121:
            _2266 <= prog_121;
        122:
            _2266 <= prog_122;
        123:
            _2266 <= prog_123;
        124:
            _2266 <= prog_124;
        125:
            _2266 <= prog_125;
        126:
            _2266 <= prog_126;
        default:
            _2266 <= prog_127;
        endcase
    end
    assign _2267 = _2266[15:13];
    assign _2341 = _2267 == _1485;
    assign _2343 = _2341 & _2342;
    assign _2346 = _2343 & _2345;
    assign _2353 = _2346 | _2352;
    assign _2359 = _2353 | _2358;
    assign _2360 = ~ _2359;
    assign _2264 = t1_delay_left == _301;
    assign _2259 = _2253 & _2258;
    assign _2265 = _2259 & _2264;
    assign _2361 = _2265 & _2360;
    assign _3270 = _2361 ? _3269 : t1_delay_left;
    assign _3273 = _2298 ? _3272 : _3270;
    assign _3274 = _2295 ? t1_delay_left : _3273;
    assign _3276 = _2294 ? _301 : _3274;
    assign _64 = _3276;
    assign _65 = _64;
    always @(posedge _99) begin
        if (_97)
            t1_delay_left <= _301;
        else
            t1_delay_left <= _65;
    end
    assign _2297 = t1_delay_left == _301;
    assign _2298 = ~ _2297;
    assign _3848 = _2298 ? _22 : _3847;
    assign _3288 = cfg_t1_clkdiv - _1469;
    assign _3279 = _586 == _1180;
    assign _3277 = _580 & _584;
    assign _3280 = _3277 & _3279;
    assign _3281 = _3280 ? _590 : cfg_t1_clkdiv;
    assign _66 = _3281;
    always @(posedge _99) begin
        if (_97)
            cfg_t1_clkdiv <= _356;
        else
            cfg_t1_clkdiv <= _66;
    end
    assign _3286 = cfg_t1_clkdiv == _356;
    assign _3290 = _3286 ? _356 : _3288;
    assign _3284 = t1_div_count - _1469;
    assign _3291 = _2258 ? _3290 : _3284;
    assign _3282 = ~ _2253;
    assign _3293 = _3282 ? _356 : _3291;
    assign _67 = _3293;
    always @(posedge _99) begin
        if (_97)
            t1_div_count <= _356;
        else
            t1_div_count <= _67;
    end
    assign _2258 = t1_div_count == _356;
    assign _2295 = ~ _2258;
    assign _3849 = _2295 ? _22 : _3848;
    assign _2253 = cfg_ctrl[1:1];
    assign _2294 = ~ _2253;
    assign _3850 = _2294 ? _22 : _3849;
    assign _68 = _3850;
    assign _69 = _68;
    always @(posedge _99) begin
        if (_97)
            pin_out <= _117;
        else
            pin_out <= _69;
    end
    assign _1404 = pin_out[7:7];
    assign _1400 = ~ cfg_sync_bypass;
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
    assign _1401 = pins_sync2 & _1400;
    assign _3855 = _590[7:0];
    assign _3853 = _586 == _1090;
    assign _3851 = _580 & _584;
    assign _3854 = _3851 & _3853;
    assign _3856 = _3854 ? _3855 : cfg_sync_bypass;
    assign _70 = _3856;
    always @(posedge _99) begin
        if (_97)
            cfg_sync_bypass <= _305;
        else
            cfg_sync_bypass <= _70;
    end
    assign _72 = uio_in;
    assign _1394 = _72 & cfg_sync_bypass;
    assign _1402 = _1394 | _1401;
    assign _1403 = _1402[7:7];
    assign _3859 = _586 == _1048;
    assign _3857 = _580 & _584;
    assign _3860 = _3857 & _3859;
    assign _3861 = _3860 ? _590 : cfg_pin_modes;
    assign _73 = _3861;
    always @(posedge _99) begin
        if (_97)
            cfg_pin_modes <= _356;
        else
            cfg_pin_modes <= _73;
    end
    assign _1393 = cfg_pin_modes[15:14];
    always @* begin
        case (_1393)
        0:
            _1406 <= _1403;
        1:
            _1406 <= _1404;
        2:
            _1406 <= _1405;
        default:
            _1406 <= _1403;
        endcase
    end
    assign _1442 = { _1406,
                     _1411,
                     _1416,
                     _1421,
                     _1426,
                     _1431,
                     _1436,
                     _1441 };
    assign _1766 = { _305,
                     _1442 };
    assign _4023 = t0_y - _1469;
    assign _4021 = _4019 == _4177;
    assign _4024 = _4021 ? _4023 : t0_y;
    assign _1952 = _1950[31:16];
    assign _1953 = { _356,
                     _1952 };
    assign _1948 = _1946[31:8];
    assign _1949 = { _305,
                     _1948 };
    assign _1944 = _1942[31:4];
    assign _1945 = { _301,
                     _1944 };
    assign _1940 = _1938[31:2];
    assign _1941 = { _520,
                     _1940 };
    assign _1936 = _1934[31:1];
    assign _1937 = { _574,
                     _1936 };
    assign _1934 = { _356,
                     t0_osr };
    assign _1932 = _1927[0:0];
    assign _1938 = _1932 ? _1937 : _1934;
    assign _1931 = _1927[1:1];
    assign _1942 = _1931 ? _1941 : _1938;
    assign _1930 = _1927[2:2];
    assign _1946 = _1930 ? _1945 : _1942;
    assign _1929 = _1927[3:3];
    assign _1950 = _1929 ? _1949 : _1946;
    assign _1927 = _252 - _1554;
    assign _1928 = _1927[4:4];
    assign _1954 = _1928 ? _1953 : _1950;
    assign _1955 = _1954[15:0];
    assign _1919 = _1918[15:0];
    assign _1921 = { _1919,
                     _356 };
    assign _1915 = _1914[23:0];
    assign _1917 = { _1915,
                     _305 };
    assign _1911 = _1910[27:0];
    assign _1913 = { _1911,
                     _301 };
    assign _1907 = _1906[29:0];
    assign _1909 = { _1907,
                     _520 };
    assign _1903 = _1554[0:0];
    assign _1906 = _1903 ? _294 : _293;
    assign _1902 = _1554[1:1];
    assign _1910 = _1902 ? _1909 : _1906;
    assign _1901 = _1554[2:2];
    assign _1914 = _1901 ? _1913 : _1910;
    assign _1900 = _1554[3:3];
    assign _1918 = _1900 ? _1917 : _1914;
    assign _1899 = _1554[4:4];
    assign _1922 = _1899 ? _1921 : _1918;
    assign _1923 = _1922[15:0];
    assign _1924 = ~ _1923;
    assign _3981 = _3980[15:0];
    assign _3983 = { _3981,
                     _356 };
    assign _3977 = _3976[23:0];
    assign _3979 = { _3977,
                     _305 };
    assign _3973 = _3972[27:0];
    assign _3975 = { _3973,
                     _301 };
    assign _3969 = _3968[29:0];
    assign _3971 = { _3969,
                     _520 };
    assign _3965 = _3964[30:0];
    assign _3967 = { _3965,
                     _574 };
    assign _3964 = { _356,
                     t0_osr };
    assign _3962 = _1554[0:0];
    assign _3968 = _3962 ? _3967 : _3964;
    assign _3961 = _1554[1:1];
    assign _3972 = _3961 ? _3971 : _3968;
    assign _3960 = _1554[2:2];
    assign _3976 = _3960 ? _3975 : _3972;
    assign _3959 = _1554[3:3];
    assign _3980 = _3959 ? _3979 : _3976;
    assign _3958 = _1554[4:4];
    assign _3984 = _3958 ? _3983 : _3980;
    assign _3985 = _3984[15:0];
    assign _3954 = _3952[31:16];
    assign _3955 = { _356,
                     _3954 };
    assign _3950 = _3948[31:8];
    assign _3951 = { _305,
                     _3950 };
    assign _3946 = _3944[31:4];
    assign _3947 = { _301,
                     _3946 };
    assign _3942 = _3940[31:2];
    assign _3943 = { _520,
                     _3942 };
    assign _3938 = _3936[31:1];
    assign _3939 = { _574,
                     _3938 };
    assign _3936 = { _356,
                     t0_osr };
    assign _3934 = _1554[0:0];
    assign _3940 = _3934 ? _3939 : _3936;
    assign _3933 = _1554[1:1];
    assign _3944 = _3933 ? _3943 : _3940;
    assign _3932 = _1554[2:2];
    assign _3948 = _3932 ? _3947 : _3944;
    assign _3931 = _1554[3:3];
    assign _3952 = _3931 ? _3951 : _3948;
    assign _1552 = { gnd,
                     _1549 };
    assign _1549 = _1388[3:0];
    assign _1551 = _1549 == _301;
    assign _1554 = _1551 ? _252 : _1552;
    assign _3930 = _1554[4:4];
    assign _3956 = _3930 ? _3955 : _3952;
    assign _3957 = _3956[15:0];
    assign _3986 = _1898 ? _3985 : _3957;
    assign _3924 = t0_tx_wr == _538;
    assign _3925 = _3869 & _3924;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_3 <= _356;
        else
            if (_3925)
                t0_tx_mem_3 <= _590;
    end
    assign _3918 = t0_tx_wr == _187;
    assign _3919 = _3869 & _3918;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_2 <= _356;
        else
            if (_3919)
                t0_tx_mem_2 <= _590;
    end
    assign _3912 = t0_tx_wr == _184;
    assign _3913 = _3869 & _3912;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_1 <= _356;
        else
            if (_3913)
                t0_tx_mem_1 <= _590;
    end
    assign _3874 = t0_tx_wr + _184;
    assign _3875 = _3869 ? _3874 : t0_tx_wr;
    assign _74 = _3875;
    always @(posedge _99) begin
        if (_97)
            t0_tx_wr <= _520;
        else
            t0_tx_wr <= _74;
    end
    assign _3906 = t0_tx_wr == _520;
    assign _3907 = _3869 & _3906;
    always @(posedge _99) begin
        if (_97)
            t0_tx_mem_0 <= _356;
        else
            if (_3907)
                t0_tx_mem_0 <= _590;
    end
    assign _3894 = t0_tx_rd + _184;
    assign _3880 = ~ _1497;
    assign _3882 = { _520,
                     _3881 };
    assign _3867 = t0_tx_level == _4177;
    assign _3868 = ~ _3867;
    assign _3864 = _586 == _1054;
    assign _3862 = _580 & _584;
    assign _3865 = _3862 & _3864;
    assign _3869 = _3865 & _3868;
    assign _3877 = { _520,
                     _3869 };
    assign _3878 = t0_tx_level + _3877;
    assign _3883 = _3878 - _3882;
    assign _75 = _3883;
    always @(posedge _99) begin
        if (_97)
            t0_tx_level <= _544;
        else
            t0_tx_level <= _75;
    end
    assign _1497 = t0_tx_level == _544;
    assign _3888 = ~ _1497;
    assign _3885 = _1389 == _4177;
    assign _3886 = _1484 & _3885;
    assign _3887 = _3886 & _1494;
    assign _3889 = _3887 & _3888;
    assign _76 = _3889;
    assign _3881 = _76 & _3880;
    assign _3895 = _3881 ? _3894 : t0_tx_rd;
    assign _77 = _3895;
    always @(posedge _99) begin
        if (_97)
            t0_tx_rd <= _520;
        else
            t0_tx_rd <= _77;
    end
    always @* begin
        case (t0_tx_rd)
        0:
            _3927 <= t0_tx_mem_0;
        1:
            _3927 <= t0_tx_mem_1;
        2:
            _3927 <= t0_tx_mem_2;
        default:
            _3927 <= t0_tx_mem_3;
        endcase
    end
    assign _1494 = _1388[8:8];
    assign _3928 = _1494 ? _3927 : t0_osr;
    assign _3899 = _1531 == _4177;
    assign _3900 = _3899 ? _1774 : t0_osr;
    assign _3901 = _1537 ? _3900 : t0_osr;
    assign _3898 = _1389 == _3745;
    assign _3902 = _3898 ? _3901 : t0_osr;
    assign _3897 = _1389 == _4177;
    assign _3929 = _3897 ? _3928 : _3902;
    assign _3896 = _1389 == _3779;
    assign _3987 = _3896 ? _3986 : _3929;
    assign _3988 = _1507 ? _3987 : t0_osr;
    assign _3989 = _612 ? t0_osr : _3988;
    assign _3990 = _606 ? t0_osr : _3989;
    assign _3992 = _600 ? _356 : _3990;
    assign _78 = _3992;
    assign _79 = _78;
    always @(posedge _99) begin
        if (_97)
            t0_osr <= _356;
        else
            t0_osr <= _79;
    end
    assign _1925 = t0_osr & _1924;
    assign _3997 = _590[1:0];
    assign _3995 = _586 == _1096;
    assign _3993 = _580 & _584;
    assign _3996 = _3993 & _3995;
    assign _3998 = _3996 ? _3997 : cfg_t0_shift;
    assign _80 = _3998;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_shift <= _520;
        else
            cfg_t0_shift <= _80;
    end
    assign _1898 = cfg_t0_shift[0:0];
    assign _1956 = _1898 ? _1955 : _1925;
    assign _4014 = _1388[8:7];
    assign _4016 = _4014 == _187;
    assign _4017 = _4016 ? _1956 : t0_y;
    assign _4010 = _1531 == _1485;
    assign _4011 = _4010 ? _1774 : t0_y;
    assign _4012 = _1537 ? _4011 : t0_y;
    assign _4006 = _1621 == _187;
    assign _4007 = _4006 ? _1634 : t0_y;
    assign _4004 = _1389 == _3728;
    assign _4008 = _4004 ? _4007 : t0_y;
    assign _4002 = _1389 == _3745;
    assign _4013 = _4002 ? _4012 : _4008;
    assign _4001 = _1389 == _3779;
    assign _4018 = _4001 ? _4017 : _4013;
    assign _4000 = _1389 == _544;
    assign _4025 = _4000 ? _4024 : _4018;
    assign _4026 = _1507 ? _4025 : t0_y;
    assign _4027 = _612 ? t0_y : _4026;
    assign _4028 = _606 ? t0_y : _4027;
    assign _4030 = _600 ? _356 : _4028;
    assign _81 = _4030;
    assign _82 = _81;
    always @(posedge _99) begin
        if (_97)
            t0_y <= _356;
        else
            t0_y <= _82;
    end
    always @* begin
        case (_1534)
        0:
            _1774 <= t0_x;
        1:
            _1774 <= t0_y;
        2:
            _1774 <= _1766;
        3:
            _1774 <= t0_isr;
        4:
            _1774 <= t0_osr;
        default:
            _1774 <= _356;
        endcase
    end
    assign _4040 = _1531 == _544;
    assign _4041 = _4040 ? _1774 : t0_x;
    assign _1534 = _1388[5:3];
    assign _1536 = _1534 < _3728;
    assign _1531 = _1388[8:6];
    assign _1533 = _1531 < _3728;
    assign _1537 = _1533 & _1536;
    assign _4042 = _1537 ? _4041 : t0_x;
    assign _1633 = _1388[4:0];
    assign _1634 = { _504,
                     _1633 };
    assign _1621 = _1388[8:7];
    assign _4036 = _1621 == _184;
    assign _4037 = _4036 ? _1634 : t0_x;
    assign _4034 = _1389 == _3728;
    assign _4038 = _4034 ? _4037 : t0_x;
    assign _4033 = _1389 == _3745;
    assign _4043 = _4033 ? _4042 : _4038;
    assign _4032 = _1389 == _3779;
    assign _4047 = _4032 ? _4046 : _4043;
    assign _4031 = _1389 == _544;
    assign _4053 = _4031 ? _4052 : _4047;
    assign _4054 = _1507 ? _4053 : t0_x;
    assign _4055 = _612 ? t0_x : _4054;
    assign _4056 = _606 ? t0_x : _4055;
    assign _4058 = _600 ? _356 : _4056;
    assign _83 = _4058;
    assign _84 = _83;
    always @(posedge _99) begin
        if (_97)
            t0_x <= _356;
        else
            t0_x <= _84;
    end
    assign _4062 = t0_x == _356;
    assign _4063 = ~ _4062;
    assign _4064 = ~ _4063;
    assign _4019 = _1388[8:6];
    always @* begin
        case (_4019)
        0:
            _4073 <= vdd;
        1:
            _4073 <= _4064;
        2:
            _4073 <= _4063;
        3:
            _4073 <= _4068;
        4:
            _4073 <= _4067;
        5:
            _4073 <= _4070;
        6:
            _4073 <= _4071;
        default:
            _4073 <= _4072;
        endcase
    end
    assign _4060 = _1389 == _544;
    assign _4074 = _4060 & _4073;
    assign _4080 = _4074 | _4079;
    assign _4089 = _4080 ? _4088 : _4082;
    assign _4090 = _1507 ? _4089 : t0_pc;
    assign _4091 = _612 ? t0_pc : _4090;
    assign _4092 = _606 ? t0_pc : _4091;
    assign _4093 = _600 ? cfg_t0_start : _4092;
    assign _85 = _4093;
    assign _86 = _85;
    always @(posedge _99) begin
        if (_97)
            t0_pc <= _452;
        else
            t0_pc <= _86;
    end
    always @* begin
        case (t0_pc)
        0:
            _1388 <= prog_0;
        1:
            _1388 <= prog_1;
        2:
            _1388 <= prog_2;
        3:
            _1388 <= prog_3;
        4:
            _1388 <= prog_4;
        5:
            _1388 <= prog_5;
        6:
            _1388 <= prog_6;
        7:
            _1388 <= prog_7;
        8:
            _1388 <= prog_8;
        9:
            _1388 <= prog_9;
        10:
            _1388 <= prog_10;
        11:
            _1388 <= prog_11;
        12:
            _1388 <= prog_12;
        13:
            _1388 <= prog_13;
        14:
            _1388 <= prog_14;
        15:
            _1388 <= prog_15;
        16:
            _1388 <= prog_16;
        17:
            _1388 <= prog_17;
        18:
            _1388 <= prog_18;
        19:
            _1388 <= prog_19;
        20:
            _1388 <= prog_20;
        21:
            _1388 <= prog_21;
        22:
            _1388 <= prog_22;
        23:
            _1388 <= prog_23;
        24:
            _1388 <= prog_24;
        25:
            _1388 <= prog_25;
        26:
            _1388 <= prog_26;
        27:
            _1388 <= prog_27;
        28:
            _1388 <= prog_28;
        29:
            _1388 <= prog_29;
        30:
            _1388 <= prog_30;
        31:
            _1388 <= prog_31;
        32:
            _1388 <= prog_32;
        33:
            _1388 <= prog_33;
        34:
            _1388 <= prog_34;
        35:
            _1388 <= prog_35;
        36:
            _1388 <= prog_36;
        37:
            _1388 <= prog_37;
        38:
            _1388 <= prog_38;
        39:
            _1388 <= prog_39;
        40:
            _1388 <= prog_40;
        41:
            _1388 <= prog_41;
        42:
            _1388 <= prog_42;
        43:
            _1388 <= prog_43;
        44:
            _1388 <= prog_44;
        45:
            _1388 <= prog_45;
        46:
            _1388 <= prog_46;
        47:
            _1388 <= prog_47;
        48:
            _1388 <= prog_48;
        49:
            _1388 <= prog_49;
        50:
            _1388 <= prog_50;
        51:
            _1388 <= prog_51;
        52:
            _1388 <= prog_52;
        53:
            _1388 <= prog_53;
        54:
            _1388 <= prog_54;
        55:
            _1388 <= prog_55;
        56:
            _1388 <= prog_56;
        57:
            _1388 <= prog_57;
        58:
            _1388 <= prog_58;
        59:
            _1388 <= prog_59;
        60:
            _1388 <= prog_60;
        61:
            _1388 <= prog_61;
        62:
            _1388 <= prog_62;
        63:
            _1388 <= prog_63;
        64:
            _1388 <= prog_64;
        65:
            _1388 <= prog_65;
        66:
            _1388 <= prog_66;
        67:
            _1388 <= prog_67;
        68:
            _1388 <= prog_68;
        69:
            _1388 <= prog_69;
        70:
            _1388 <= prog_70;
        71:
            _1388 <= prog_71;
        72:
            _1388 <= prog_72;
        73:
            _1388 <= prog_73;
        74:
            _1388 <= prog_74;
        75:
            _1388 <= prog_75;
        76:
            _1388 <= prog_76;
        77:
            _1388 <= prog_77;
        78:
            _1388 <= prog_78;
        79:
            _1388 <= prog_79;
        80:
            _1388 <= prog_80;
        81:
            _1388 <= prog_81;
        82:
            _1388 <= prog_82;
        83:
            _1388 <= prog_83;
        84:
            _1388 <= prog_84;
        85:
            _1388 <= prog_85;
        86:
            _1388 <= prog_86;
        87:
            _1388 <= prog_87;
        88:
            _1388 <= prog_88;
        89:
            _1388 <= prog_89;
        90:
            _1388 <= prog_90;
        91:
            _1388 <= prog_91;
        92:
            _1388 <= prog_92;
        93:
            _1388 <= prog_93;
        94:
            _1388 <= prog_94;
        95:
            _1388 <= prog_95;
        96:
            _1388 <= prog_96;
        97:
            _1388 <= prog_97;
        98:
            _1388 <= prog_98;
        99:
            _1388 <= prog_99;
        100:
            _1388 <= prog_100;
        101:
            _1388 <= prog_101;
        102:
            _1388 <= prog_102;
        103:
            _1388 <= prog_103;
        104:
            _1388 <= prog_104;
        105:
            _1388 <= prog_105;
        106:
            _1388 <= prog_106;
        107:
            _1388 <= prog_107;
        108:
            _1388 <= prog_108;
        109:
            _1388 <= prog_109;
        110:
            _1388 <= prog_110;
        111:
            _1388 <= prog_111;
        112:
            _1388 <= prog_112;
        113:
            _1388 <= prog_113;
        114:
            _1388 <= prog_114;
        115:
            _1388 <= prog_115;
        116:
            _1388 <= prog_116;
        117:
            _1388 <= prog_117;
        118:
            _1388 <= prog_118;
        119:
            _1388 <= prog_119;
        120:
            _1388 <= prog_120;
        121:
            _1388 <= prog_121;
        122:
            _1388 <= prog_122;
        123:
            _1388 <= prog_123;
        124:
            _1388 <= prog_124;
        125:
            _1388 <= prog_125;
        126:
            _1388 <= prog_126;
        default:
            _1388 <= prog_127;
        endcase
    end
    assign _1389 = _1388[15:13];
    assign _1486 = _1389 == _1485;
    assign _1488 = _1486 & _1487;
    assign _1491 = _1488 & _1490;
    assign _1499 = _1491 | _1498;
    assign _1505 = _1499 | _1504;
    assign _1506 = ~ _1505;
    assign _1507 = _1484 & _1506;
    assign _4104 = _1507 ? _4103 : t0_delay_left;
    assign _611 = t0_delay_left == _301;
    assign _612 = ~ _611;
    assign _4107 = _612 ? _4106 : _4104;
    assign _606 = ~ _605;
    assign _4108 = _606 ? t0_delay_left : _4107;
    assign _600 = ~ _599;
    assign _4110 = _600 ? _301 : _4108;
    assign _87 = _4110;
    assign _88 = _87;
    always @(posedge _99) begin
        if (_97)
            t0_delay_left <= _301;
        else
            t0_delay_left <= _88;
    end
    assign _1483 = t0_delay_left == _301;
    assign _4122 = cfg_t0_clkdiv - _1469;
    assign _4113 = _586 == _1084;
    assign _4111 = _580 & _584;
    assign _4114 = _4111 & _4113;
    assign _4115 = _4114 ? _590 : cfg_t0_clkdiv;
    assign _89 = _4115;
    always @(posedge _99) begin
        if (_97)
            cfg_t0_clkdiv <= _356;
        else
            cfg_t0_clkdiv <= _89;
    end
    assign _4120 = cfg_t0_clkdiv == _356;
    assign _4124 = _4120 ? _356 : _4122;
    assign _4118 = t0_div_count - _1469;
    assign _4125 = _605 ? _4124 : _4118;
    assign _4116 = ~ _599;
    assign _4127 = _4116 ? _356 : _4125;
    assign _90 = _4127;
    always @(posedge _99) begin
        if (_97)
            t0_div_count <= _356;
        else
            t0_div_count <= _90;
    end
    assign _605 = t0_div_count == _356;
    assign _599 = cfg_ctrl[0:0];
    assign _1481 = _599 & _605;
    assign _1484 = _1481 & _1483;
    assign _4130 = _1484 & _4129;
    assign _4132 = _4130 & _4131;
    assign _4134 = _4132 & _4133;
    assign _91 = _4134;
    assign _422 = _91 & _421;
    assign _4136 = { _520,
                     _422 };
    assign _4137 = t0_rx_level + _4136;
    assign _4140 = _4137 - _4139;
    assign _92 = _4140;
    always @(posedge _99) begin
        if (_97)
            t0_rx_level <= _544;
        else
            t0_rx_level <= _92;
    end
    assign _3002 = t0_rx_level == _544;
    assign _4161 = ~ _3002;
    assign _590 = _368[15:0];
    assign _4159 = _590[3:0];
    assign _586 = host_cmd[6:0];
    assign _4157 = _586 == _1006;
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
    assign _4141 = _368[22:0];
    assign _4142 = _354 ? _4141 : host_shift_in;
    assign _4143 = host_cs_n_s2 ? host_shift_in : _4142;
    assign _93 = _4143;
    always @(posedge _99) begin
        if (_97)
            host_shift_in <= _361;
        else
            host_shift_in <= _93;
    end
    assign _368 = { host_shift_in,
                    host_mosi_s2 };
    assign _369 = _368[7:0];
    assign _359 = host_bit_count == _2494;
    assign _4144 = _359 ? _369 : host_cmd;
    assign _4145 = _354 ? _4144 : host_cmd;
    assign _4146 = host_cs_n_s2 ? host_cmd : _4145;
    assign _94 = _4146;
    always @(posedge _99) begin
        if (_97)
            host_cmd <= _305;
        else
            host_cmd <= _94;
    end
    assign _584 = host_cmd[7:7];
    assign _578 = 5'b10111;
    assign _4150 = host_bit_count + _2578;
    assign _4147 = 5'b11000;
    assign _4148 = host_bit_count < _4147;
    assign _4151 = _4148 ? _4150 : host_bit_count;
    assign _4152 = _354 ? _4151 : host_bit_count;
    assign _4154 = host_cs_n_s2 ? _1523 : _4152;
    assign _95 = _4154;
    always @(posedge _99) begin
        if (_97)
            host_bit_count <= _1523;
        else
            host_bit_count <= _95;
    end
    assign _579 = host_bit_count == _578;
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
            host_sck_prev <= _574;
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
    assign _580 = _354 & _579;
    assign _4155 = _580 & _584;
    assign _4158 = _4155 & _4157;
    assign _4160 = _4158 ? _4159 : cfg_ctrl;
    assign _102 = _4160;
    always @(posedge _99) begin
        if (_97)
            cfg_ctrl <= _301;
        else
            cfg_ctrl <= _102;
    end
    assign _2686 = cfg_ctrl[2:2];
    assign _4162 = _2686 & _4161;
    assign _4164 = _4162 & _4163;
    assign _103 = _4164;
    assign _2689 = _103 | _2688;
    assign _2693 = _2689 & _2692;
    assign _4166 = { _520,
                     _2693 };
    assign _4167 = t1_tx_level + _4166;
    assign _4170 = _4167 - _4169;
    assign _104 = _4170;
    always @(posedge _99) begin
        if (_97)
            t1_tx_level <= _544;
        else
            t1_tx_level <= _104;
    end
    assign _4172 = t1_tx_level == _4177;
    assign gnd = 1'b0;
    assign _4184 = { gnd,
                     _4172,
                     _4175,
                     _4176,
                     _4178,
                     _4181,
                     _4182,
                     _4183 };
    assign uo_out = _4184;
    assign uio_out = _234;
    assign uio_oe = _193;

endmodule
