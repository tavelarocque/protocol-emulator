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

    wire _196;
    wire _197;
    wire [1:0] _194;
    wire [1:0] _193;
    wire _195;
    wire _198;
    wire [1:0] _191;
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
    wire [1:0] _163;
    wire _165;
    wire _168;
    wire [1:0] _160;
    wire _162;
    wire _169;
    wire _156;
    wire _157;
    wire [1:0] _153;
    wire _155;
    wire _158;
    wire [1:0] _150;
    wire _152;
    wire _159;
    wire _146;
    wire _147;
    wire [1:0] _143;
    wire _145;
    wire _148;
    wire [1:0] _140;
    wire _142;
    wire _149;
    wire _136;
    wire _137;
    wire [1:0] _133;
    wire _135;
    wire _138;
    wire [1:0] _130;
    wire _132;
    wire _139;
    wire _126;
    wire _127;
    wire [1:0] _120;
    wire _122;
    wire _128;
    wire [1:0] _117;
    wire _119;
    wire _129;
    wire [7:0] _200;
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
    wire _224;
    wire [1:0] _221;
    wire _223;
    wire _225;
    wire _219;
    wire [1:0] _216;
    wire _218;
    wire _220;
    wire _214;
    wire [1:0] _211;
    wire _213;
    wire _215;
    wire _209;
    wire [1:0] _206;
    wire _208;
    wire _210;
    wire _204;
    wire [1:0] _201;
    wire _203;
    wire _205;
    wire [7:0] _241;
    wire [15:0] _363;
    wire _576;
    wire [14:0] _575;
    wire [15:0] _577;
    wire [13:0] _570;
    wire [15:0] _571;
    wire [9:0] _562;
    wire [15:0] _566;
    wire _554;
    wire [15:0] _558;
    wire [1:0] _545;
    wire _546;
    wire _547;
    reg [15:0] t1_rx_mem_3;
    wire _540;
    wire _541;
    reg [15:0] t1_rx_mem_2;
    wire _534;
    wire _535;
    reg [15:0] t1_rx_mem_1;
    wire [1:0] _527;
    wire [1:0] _253;
    wire [1:0] _254;
    wire [1:0] _3;
    reg [1:0] t1_rx_wr;
    wire _528;
    wire _529;
    wire [15:0] _315;
    wire [31:0] _317;
    wire [7:0] _312;
    wire [23:0] _311;
    wire [31:0] _313;
    wire [3:0] _308;
    wire [27:0] _307;
    wire [31:0] _309;
    wire [29:0] _303;
    wire [31:0] _305;
    wire [31:0] _301;
    wire [31:0] _300;
    wire _299;
    wire [31:0] _302;
    wire _298;
    wire [31:0] _306;
    wire _297;
    wire [31:0] _310;
    wire _296;
    wire [31:0] _314;
    wire _295;
    wire [31:0] _318;
    wire [15:0] _319;
    wire [15:0] _320;
    wire [15:0] _321;
    wire [15:0] _291;
    wire [31:0] _292;
    wire [23:0] _287;
    wire [31:0] _288;
    wire [27:0] _283;
    wire [31:0] _284;
    wire [29:0] _279;
    wire [31:0] _280;
    wire [30:0] _275;
    wire [31:0] _276;
    wire [31:0] _273;
    wire _268;
    wire [31:0] _277;
    wire _267;
    wire [31:0] _281;
    wire _266;
    wire [31:0] _285;
    wire _265;
    wire [31:0] _289;
    wire [4:0] _259;
    wire [4:0] _263;
    wire _264;
    wire [31:0] _293;
    wire [15:0] _294;
    wire [15:0] _322;
    wire [15:0] _4;
    reg [15:0] t1_rx_mem_0;
    wire [1:0] _331;
    wire [1:0] _332;
    wire [1:0] _5;
    reg [1:0] t1_rx_rd;
    reg [15:0] _549;
    wire [2:0] _521;
    wire _522;
    wire _523;
    wire [15:0] _550;
    wire [15:0] _520;
    wire [10:0] _511;
    wire [15:0] _515;
    wire [12:0] _506;
    wire [15:0] _510;
    wire [15:0] _505;
    wire [15:0] _500;
    wire [15:0] _495;
    wire [15:0] _490;
    wire [15:0] _485;
    wire [15:0] _480;
    wire [15:0] _472;
    wire _460;
    wire [15:0] _464;
    wire _418;
    wire _419;
    wire [15:0] _456;
    wire [15:0] _413;
    wire [15:0] _408;
    wire [15:0] _403;
    wire [15:0] _398;
    wire [15:0] _393;
    wire [15:0] _388;
    wire [15:0] _383;
    reg [15:0] _572;
    wire [15:0] _573;
    wire [15:0] _574;
    wire [4:0] _354;
    wire _355;
    wire _356;
    wire _349;
    wire _344;
    wire _348;
    wire _350;
    wire _357;
    wire [15:0] _578;
    wire [15:0] _579;
    wire [15:0] _6;
    reg [15:0] host_miso_shift;
    wire _3482;
    wire _3481;
    wire _3479;
    wire _3480;
    wire [2:0] _3476;
    wire _3477;
    wire _3475;
    wire _3473;
    wire _3474;
    wire [2:0] _3468;
    wire _1971;
    wire _1966;
    wire [6:0] _1962;
    wire _1963;
    wire _1961;
    wire _1964;
    wire _1967;
    wire _1970;
    wire _3462;
    wire [2:0] _3438;
    wire _428;
    wire _3432;
    wire _3430;
    wire _3428;
    wire [3:0] _3398;
    wire [3:0] _3399;
    wire [1:0] _3393;
    wire [3:0] _3394;
    wire [3:0] _3390;
    wire [3:0] _3389;
    wire _3388;
    wire [3:0] _3391;
    wire _3387;
    wire [3:0] _3395;
    wire [3:0] _3396;
    wire _427;
    wire _718;
    wire _717;
    wire _719;
    wire _720;
    wire _709;
    wire _711;
    wire _714;
    wire _706;
    wire _693;
    wire [2:0] _629;
    wire [15:0] _3381;
    wire [5:0] _3371;
    wire [7:0] _593;
    wire [6:0] _589;
    wire _590;
    wire _587;
    wire _591;
    wire [7:0] _594;
    wire [7:0] _7;
    reg [7:0] cfg_t0_start;
    wire [1:0] _738;
    wire [1:0] _732;
    wire _731;
    wire [1:0] _733;
    wire _728;
    wire [1:0] _734;
    wire [1:0] _735;
    wire [1:0] _736;
    wire [1:0] _737;
    wire [1:0] _739;
    wire [1:0] _8;
    wire [1:0] _9;
    reg [1:0] t0_page;
    wire [7:0] _3372;
    wire [7:0] _744;
    wire [6:0] _741;
    wire _742;
    wire _740;
    wire _743;
    wire [7:0] _745;
    wire [7:0] _10;
    reg [7:0] cfg_t0_timeout_vector;
    wire _3370;
    wire [7:0] _3373;
    wire [7:0] _3367;
    wire [7:0] _3368;
    wire [15:0] _753;
    wire [15:0] _754;
    wire [15:0] _755;
    wire [15:0] _756;
    wire [15:0] _757;
    wire [15:0] _759;
    wire [15:0] _11;
    wire [15:0] _12;
    reg [15:0] t0_wait_count;
    wire [6:0] _761;
    wire _762;
    wire _760;
    wire _763;
    wire [15:0] _764;
    wire [15:0] _13;
    reg [15:0] cfg_t0_timeout;
    wire _765;
    wire _751;
    wire _748;
    wire _747;
    wire _749;
    wire _750;
    wire _752;
    wire _766;
    wire _768;
    wire _769;
    wire _770;
    wire _772;
    wire _14;
    wire _15;
    reg t0_waiting;
    wire [15:0] _702;
    wire _704;
    wire _695;
    wire _705;
    wire _691;
    wire _689;
    wire _688;
    wire _687;
    wire _686;
    wire _685;
    wire _684;
    wire _683;
    wire _682;
    wire [2:0] _631;
    reg _690;
    wire _692;
    wire _3363;
    wire _3362;
    wire _3364;
    wire _3365;
    wire _3358;
    wire [4:0] _780;
    wire [4:0] _406;
    wire [4:0] _777;
    wire [6:0] _774;
    wire _775;
    wire _773;
    wire _776;
    wire [4:0] _778;
    wire [4:0] _16;
    reg [4:0] cfg_t0_threshold;
    wire [4:0] _815;
    wire [5:0] _812;
    wire [5:0] _805;
    wire [5:0] _813;
    wire [5:0] _804;
    wire _814;
    wire [4:0] _817;
    wire [4:0] _802;
    wire _796;
    wire [4:0] _798;
    wire [4:0] _799;
    wire _787;
    wire [4:0] _800;
    wire _785;
    wire [4:0] _803;
    wire _783;
    wire [4:0] _818;
    wire [4:0] _819;
    wire [4:0] _820;
    wire [4:0] _821;
    wire [4:0] _822;
    wire [4:0] _17;
    wire [4:0] _18;
    reg [4:0] t0_osr_count;
    wire _3357;
    wire _3355;
    wire _3356;
    wire _3352;
    wire _3353;
    wire _3354;
    wire [15:0] _3337;
    wire [2:0] _3334;
    wire _3335;
    wire [15:0] _3338;
    wire _3331;
    wire [15:0] _3332;
    wire _679;
    wire _678;
    wire _677;
    wire [1:0] _676;
    reg _680;
    wire _674;
    wire _673;
    wire _672;
    wire [1:0] _671;
    reg _675;
    wire _669;
    wire _668;
    wire _667;
    wire [1:0] _666;
    reg _670;
    wire _664;
    wire _663;
    wire _662;
    wire [1:0] _661;
    reg _665;
    wire _659;
    wire _658;
    wire _657;
    wire [1:0] _656;
    reg _660;
    wire _654;
    wire _653;
    wire _652;
    wire [1:0] _651;
    reg _655;
    wire _649;
    wire _648;
    wire _647;
    wire [1:0] _646;
    reg _650;
    wire _644;
    wire [7:0] _124;
    wire _3131;
    wire _3130;
    wire _3129;
    wire _3128;
    wire _3127;
    wire _3126;
    wire _3125;
    wire _3124;
    reg _3132;
    wire _3123;
    wire [3:0] _3121;
    wire [2:0] _3118;
    wire [3:0] _3119;
    wire _3122;
    wire _3133;
    wire _3114;
    wire _3113;
    wire _3112;
    wire _3111;
    wire _3110;
    wire _3109;
    wire _3108;
    wire _3107;
    reg _3115;
    wire _3106;
    wire [3:0] _3104;
    wire [2:0] _3101;
    wire [3:0] _3102;
    wire _3105;
    wire _3116;
    wire _3097;
    wire _3096;
    wire _3095;
    wire _3094;
    wire _3093;
    wire _3092;
    wire _3091;
    wire _3090;
    reg _3098;
    wire _3089;
    wire [3:0] _3087;
    wire [2:0] _3084;
    wire [3:0] _3085;
    wire _3088;
    wire _3099;
    wire _3080;
    wire _3079;
    wire _3078;
    wire _3077;
    wire _3076;
    wire _3075;
    wire _3074;
    wire _3073;
    reg _3081;
    wire _3072;
    wire [3:0] _3070;
    wire [2:0] _3066;
    wire [2:0] _3067;
    wire [3:0] _3068;
    wire _3071;
    wire _3082;
    wire _3063;
    wire _3062;
    wire _3061;
    wire _3060;
    wire _3059;
    wire _3058;
    wire _3057;
    wire _3056;
    reg _3064;
    wire _3055;
    wire [3:0] _3053;
    wire [2:0] _3050;
    wire [3:0] _3051;
    wire _3054;
    wire _3065;
    wire _3046;
    wire _3045;
    wire _3044;
    wire _3043;
    wire _3042;
    wire _3041;
    wire _3040;
    wire _3039;
    reg _3047;
    wire _3038;
    wire [3:0] _3036;
    wire [2:0] _3032;
    wire [2:0] _3033;
    wire [3:0] _3034;
    wire _3037;
    wire _3048;
    wire _3029;
    wire _3028;
    wire _3027;
    wire _3026;
    wire _3025;
    wire _3024;
    wire _3023;
    wire _3022;
    reg _3030;
    wire _3021;
    wire [3:0] _3019;
    wire [2:0] _3015;
    wire [2:0] _3016;
    wire [3:0] _3017;
    wire _3020;
    wire _3031;
    wire _3012;
    wire _3011;
    wire _3010;
    wire _3009;
    wire _3008;
    wire _3007;
    wire _3006;
    wire [1:0] _2999;
    wire [3:0] _3000;
    wire [2:0] _2995;
    wire [3:0] _2996;
    wire _2993;
    wire [3:0] _2997;
    wire _2992;
    wire [3:0] _3001;
    wire [2:0] _2989;
    wire [2:0] _2990;
    wire _2991;
    wire [3:0] _3003;
    wire [7:0] _3004;
    wire _3005;
    reg _3013;
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
    wire [4:0] _2971;
    wire _2972;
    wire _2983;
    wire _2965;
    wire _2964;
    wire _2963;
    wire _2962;
    wire _2961;
    wire _2960;
    wire _2959;
    wire _2958;
    reg _2966;
    wire _2957;
    wire [2:0] _2954;
    wire [4:0] _2955;
    wire _2956;
    wire _2967;
    wire _2949;
    wire _2948;
    wire _2947;
    wire _2946;
    wire _2945;
    wire _2944;
    wire _2943;
    wire _2942;
    reg _2950;
    wire _2941;
    wire [2:0] _2938;
    wire [4:0] _2939;
    wire _2940;
    wire _2951;
    wire _2933;
    wire _2932;
    wire _2931;
    wire _2930;
    wire _2929;
    wire _2928;
    wire _2927;
    wire _2926;
    reg _2934;
    wire _2925;
    wire [2:0] _2922;
    wire [4:0] _2923;
    wire _2924;
    wire _2935;
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
    wire [4:0] _2907;
    wire _2908;
    wire _2919;
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
    wire [2:0] _2890;
    wire [4:0] _2891;
    wire _2892;
    wire _2903;
    wire _2885;
    wire _2884;
    wire _2883;
    wire _2882;
    wire _2881;
    wire _2880;
    wire _2879;
    wire _2878;
    reg _2886;
    wire _2877;
    wire [2:0] _2874;
    wire [4:0] _2875;
    wire _2876;
    wire _2887;
    wire _2869;
    wire _2868;
    wire _2867;
    wire _2866;
    wire _2865;
    wire _2864;
    wire _2863;
    wire _2862;
    reg _2870;
    wire _2861;
    wire [2:0] _2857;
    wire [2:0] _2858;
    wire [4:0] _2859;
    wire _2860;
    wire _2871;
    wire [7:0] _2984;
    wire _2851;
    wire _2850;
    wire _2849;
    wire _2848;
    wire _2847;
    wire _2846;
    wire _2845;
    wire _2844;
    reg _2852;
    wire _2843;
    wire [2:0] _2840;
    wire [3:0] _2841;
    wire _2842;
    wire _2853;
    wire _2836;
    wire _2835;
    wire _2834;
    wire _2833;
    wire _2832;
    wire _2831;
    wire _2830;
    wire _2829;
    reg _2837;
    wire _2828;
    wire [2:0] _2825;
    wire [3:0] _2826;
    wire _2827;
    wire _2838;
    wire _2821;
    wire _2820;
    wire _2819;
    wire _2818;
    wire _2817;
    wire _2816;
    wire _2815;
    wire _2814;
    reg _2822;
    wire _2813;
    wire [2:0] _2810;
    wire [3:0] _2811;
    wire _2812;
    wire _2823;
    wire _2806;
    wire _2805;
    wire _2804;
    wire _2803;
    wire _2802;
    wire _2801;
    wire _2800;
    wire _2799;
    reg _2807;
    wire _2798;
    wire [2:0] _2795;
    wire [3:0] _2796;
    wire _2797;
    wire _2808;
    wire _2791;
    wire _2790;
    wire _2789;
    wire _2788;
    wire _2787;
    wire _2786;
    wire _2785;
    wire _2784;
    reg _2792;
    wire _2783;
    wire [2:0] _2780;
    wire [3:0] _2781;
    wire _2782;
    wire _2793;
    wire _2776;
    wire _2775;
    wire _2774;
    wire _2773;
    wire _2772;
    wire _2771;
    wire _2770;
    wire _2769;
    reg _2777;
    wire _2768;
    wire [2:0] _2765;
    wire [3:0] _2766;
    wire _2767;
    wire _2778;
    wire _2761;
    wire _2760;
    wire _2759;
    wire _2758;
    wire _2757;
    wire _2756;
    wire _2755;
    wire _2754;
    reg _2762;
    wire _2753;
    wire [2:0] _2750;
    wire [3:0] _2751;
    wire _2752;
    wire _2763;
    wire _2746;
    wire _2745;
    wire _2744;
    wire _2743;
    wire _2742;
    wire _2741;
    wire _2740;
    wire _2739;
    reg _2747;
    wire _2738;
    wire [3:0] _2736;
    wire [7:0] _498;
    wire [7:0] _827;
    wire [6:0] _824;
    wire _825;
    wire _823;
    wire _826;
    wire [7:0] _828;
    wire [7:0] _19;
    reg [7:0] cfg_t1_out_cfg;
    wire [2:0] _2733;
    wire [2:0] _2734;
    wire [3:0] _2735;
    wire _2737;
    wire _2748;
    wire [7:0] _2854;
    wire _2727;
    wire _2726;
    wire _2725;
    wire _2724;
    wire _2723;
    wire _2722;
    wire _2721;
    wire _2720;
    reg _2728;
    wire _2719;
    wire [2:0] _2716;
    wire [3:0] _2717;
    wire _2718;
    wire _2729;
    wire _2712;
    wire _2711;
    wire _2710;
    wire _2709;
    wire _2708;
    wire _2707;
    wire _2706;
    wire _2705;
    reg _2713;
    wire _2704;
    wire [2:0] _2701;
    wire [3:0] _2702;
    wire _2703;
    wire _2714;
    wire _2697;
    wire _2696;
    wire _2695;
    wire _2694;
    wire _2693;
    wire _2692;
    wire _2691;
    wire _2690;
    reg _2698;
    wire _2689;
    wire [2:0] _2686;
    wire [3:0] _2687;
    wire _2688;
    wire _2699;
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
    wire [2:0] _2671;
    wire [3:0] _2672;
    wire _2673;
    wire _2684;
    wire _2667;
    wire _2666;
    wire _2665;
    wire _2664;
    wire _2663;
    wire _2662;
    wire _2661;
    wire _2660;
    reg _2668;
    wire _2659;
    wire [2:0] _2656;
    wire [3:0] _2657;
    wire _2658;
    wire _2669;
    wire _2652;
    wire _2651;
    wire _2650;
    wire _2649;
    wire _2648;
    wire _2647;
    wire _2646;
    wire _2645;
    reg _2653;
    wire _2644;
    wire [2:0] _2641;
    wire [3:0] _2642;
    wire _2643;
    wire _2654;
    wire _2637;
    wire _2636;
    wire _2635;
    wire _2634;
    wire _2633;
    wire _2632;
    wire _2631;
    wire _2630;
    reg _2638;
    wire _2629;
    wire [2:0] _2626;
    wire [3:0] _2627;
    wire _2628;
    wire _2639;
    wire _2622;
    wire _2621;
    wire _2620;
    wire _2619;
    wire _2618;
    wire _2617;
    wire _2616;
    wire _2615;
    reg _2623;
    wire _2614;
    wire [3:0] _2612;
    wire [7:0] _833;
    wire [6:0] _830;
    wire _831;
    wire _829;
    wire _832;
    wire [7:0] _834;
    wire [7:0] _20;
    reg [7:0] cfg_t1_set_cfg;
    wire [2:0] _2609;
    wire [2:0] _2610;
    wire [3:0] _2611;
    wire _2613;
    wire _2624;
    wire [7:0] _2730;
    wire _1483;
    wire _1482;
    wire _1481;
    wire _1480;
    wire _1479;
    wire _1478;
    wire _1477;
    wire _1476;
    reg _1484;
    wire _1475;
    wire [3:0] _1473;
    wire [2:0] _1470;
    wire [3:0] _1471;
    wire _1474;
    wire _1485;
    wire _1466;
    wire _1465;
    wire _1464;
    wire _1463;
    wire _1462;
    wire _1461;
    wire _1460;
    wire _1459;
    reg _1467;
    wire _1458;
    wire [3:0] _1456;
    wire [2:0] _1453;
    wire [3:0] _1454;
    wire _1457;
    wire _1468;
    wire _1449;
    wire _1448;
    wire _1447;
    wire _1446;
    wire _1445;
    wire _1444;
    wire _1443;
    wire _1442;
    reg _1450;
    wire _1441;
    wire [3:0] _1439;
    wire [2:0] _1436;
    wire [3:0] _1437;
    wire _1440;
    wire _1451;
    wire _1432;
    wire _1431;
    wire _1430;
    wire _1429;
    wire _1428;
    wire _1427;
    wire _1426;
    wire _1425;
    reg _1433;
    wire _1424;
    wire [3:0] _1422;
    wire [2:0] _1419;
    wire [3:0] _1420;
    wire _1423;
    wire _1434;
    wire _1415;
    wire _1414;
    wire _1413;
    wire _1412;
    wire _1411;
    wire _1410;
    wire _1409;
    wire _1408;
    reg _1416;
    wire _1407;
    wire [3:0] _1405;
    wire [2:0] _1402;
    wire [3:0] _1403;
    wire _1406;
    wire _1417;
    wire _1398;
    wire _1397;
    wire _1396;
    wire _1395;
    wire _1394;
    wire _1393;
    wire _1392;
    wire _1391;
    reg _1399;
    wire _1390;
    wire [3:0] _1388;
    wire [2:0] _1385;
    wire [3:0] _1386;
    wire _1389;
    wire _1400;
    wire _1381;
    wire _1380;
    wire _1379;
    wire _1378;
    wire _1377;
    wire _1376;
    wire _1375;
    wire _1374;
    reg _1382;
    wire _1373;
    wire [3:0] _1371;
    wire [2:0] _1368;
    wire [3:0] _1369;
    wire _1372;
    wire _1383;
    wire _1364;
    wire _1363;
    wire _1362;
    wire _1361;
    wire _1360;
    wire _1359;
    wire _1358;
    wire [1:0] _1351;
    wire [3:0] _1352;
    wire [2:0] _1347;
    wire [3:0] _1348;
    wire [3:0] _1345;
    wire _1344;
    wire [3:0] _1349;
    wire _1343;
    wire [3:0] _1353;
    wire [2:0] _1340;
    wire [2:0] _1341;
    wire _1342;
    wire [3:0] _1355;
    wire [7:0] _1356;
    wire _1357;
    reg _1365;
    wire _1332;
    wire _1331;
    wire _1330;
    wire _1329;
    wire _1328;
    wire _1327;
    wire _1326;
    wire _1325;
    reg _1333;
    wire _1324;
    wire [2:0] _1321;
    wire [4:0] _1322;
    wire _1323;
    wire _1334;
    wire _1316;
    wire _1315;
    wire _1314;
    wire _1313;
    wire _1312;
    wire _1311;
    wire _1310;
    wire _1309;
    reg _1317;
    wire _1308;
    wire [2:0] _1305;
    wire [4:0] _1306;
    wire _1307;
    wire _1318;
    wire _1300;
    wire _1299;
    wire _1298;
    wire _1297;
    wire _1296;
    wire _1295;
    wire _1294;
    wire _1293;
    reg _1301;
    wire _1292;
    wire [2:0] _1289;
    wire [4:0] _1290;
    wire _1291;
    wire _1302;
    wire _1284;
    wire _1283;
    wire _1282;
    wire _1281;
    wire _1280;
    wire _1279;
    wire _1278;
    wire _1277;
    reg _1285;
    wire _1276;
    wire [2:0] _1273;
    wire [4:0] _1274;
    wire _1275;
    wire _1286;
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
    wire [4:0] _1258;
    wire _1259;
    wire _1270;
    wire _1252;
    wire _1251;
    wire _1250;
    wire _1249;
    wire _1248;
    wire _1247;
    wire _1246;
    wire _1245;
    reg _1253;
    wire _1244;
    wire [2:0] _1241;
    wire [4:0] _1242;
    wire _1243;
    wire _1254;
    wire _1236;
    wire _1235;
    wire _1234;
    wire _1233;
    wire _1232;
    wire _1231;
    wire _1230;
    wire _1229;
    reg _1237;
    wire _1228;
    wire [2:0] _1225;
    wire [4:0] _1226;
    wire _1227;
    wire _1238;
    wire _1220;
    wire _1219;
    wire _1218;
    wire _1217;
    wire _1216;
    wire _1215;
    wire _1214;
    wire _1213;
    reg _1221;
    wire _1153;
    wire [2:0] _1150;
    wire [4:0] _1151;
    wire _1152;
    wire _1222;
    wire [7:0] _1335;
    wire _1143;
    wire _1142;
    wire _1141;
    wire _1140;
    wire _1139;
    wire _1138;
    wire _1137;
    wire _1136;
    reg _1144;
    wire _1135;
    wire [2:0] _1132;
    wire [3:0] _1133;
    wire _1134;
    wire _1145;
    wire _1128;
    wire _1127;
    wire _1126;
    wire _1125;
    wire _1124;
    wire _1123;
    wire _1122;
    wire _1121;
    reg _1129;
    wire _1120;
    wire [2:0] _1117;
    wire [3:0] _1118;
    wire _1119;
    wire _1130;
    wire _1113;
    wire _1112;
    wire _1111;
    wire _1110;
    wire _1109;
    wire _1108;
    wire _1107;
    wire _1106;
    reg _1114;
    wire _1105;
    wire [2:0] _1102;
    wire [3:0] _1103;
    wire _1104;
    wire _1115;
    wire _1098;
    wire _1097;
    wire _1096;
    wire _1095;
    wire _1094;
    wire _1093;
    wire _1092;
    wire _1091;
    reg _1099;
    wire _1090;
    wire [2:0] _1087;
    wire [3:0] _1088;
    wire _1089;
    wire _1100;
    wire _1083;
    wire _1082;
    wire _1081;
    wire _1080;
    wire _1079;
    wire _1078;
    wire _1077;
    wire _1076;
    reg _1084;
    wire _1075;
    wire [2:0] _1072;
    wire [3:0] _1073;
    wire _1074;
    wire _1085;
    wire _1068;
    wire _1067;
    wire _1066;
    wire _1065;
    wire _1064;
    wire _1063;
    wire _1062;
    wire _1061;
    reg _1069;
    wire _1060;
    wire [2:0] _1057;
    wire [3:0] _1058;
    wire _1059;
    wire _1070;
    wire _1053;
    wire _1052;
    wire _1051;
    wire _1050;
    wire _1049;
    wire _1048;
    wire _1047;
    wire _1046;
    reg _1054;
    wire _1045;
    wire [2:0] _1042;
    wire [3:0] _1043;
    wire _1044;
    wire _1055;
    wire _1038;
    wire _1037;
    wire _1036;
    wire _1035;
    wire _1034;
    wire _1033;
    wire _1032;
    wire _1031;
    reg _1039;
    wire _1014;
    wire [3:0] _1012;
    wire [7:0] _839;
    wire [6:0] _836;
    wire _837;
    wire _835;
    wire _838;
    wire [7:0] _840;
    wire [7:0] _21;
    reg [7:0] cfg_t0_out_cfg;
    wire [2:0] _1009;
    wire [2:0] _1010;
    wire [3:0] _1011;
    wire _1013;
    wire _1040;
    wire [7:0] _1146;
    wire _1003;
    wire _1002;
    wire _1001;
    wire _1000;
    wire _999;
    wire _998;
    wire _997;
    wire _996;
    reg _1004;
    wire _995;
    wire [2:0] _992;
    wire [3:0] _993;
    wire _994;
    wire _1005;
    wire _988;
    wire _987;
    wire _986;
    wire _985;
    wire _984;
    wire _983;
    wire _982;
    wire _981;
    reg _989;
    wire _980;
    wire [2:0] _977;
    wire [3:0] _978;
    wire _979;
    wire _990;
    wire _973;
    wire _972;
    wire _971;
    wire _970;
    wire _969;
    wire _968;
    wire _967;
    wire _966;
    reg _974;
    wire _965;
    wire [2:0] _962;
    wire [3:0] _963;
    wire _964;
    wire _975;
    wire _958;
    wire _957;
    wire _956;
    wire _955;
    wire _954;
    wire _953;
    wire _952;
    wire _951;
    reg _959;
    wire _950;
    wire [2:0] _947;
    wire [3:0] _948;
    wire _949;
    wire _960;
    wire _943;
    wire _942;
    wire _941;
    wire _940;
    wire _939;
    wire _938;
    wire _937;
    wire _936;
    reg _944;
    wire _935;
    wire [2:0] _932;
    wire [3:0] _933;
    wire _934;
    wire _945;
    wire _928;
    wire _927;
    wire _926;
    wire _925;
    wire _924;
    wire _923;
    wire _922;
    wire _921;
    reg _929;
    wire _920;
    wire [2:0] _917;
    wire [3:0] _918;
    wire _919;
    wire _930;
    wire _913;
    wire _912;
    wire _911;
    wire _910;
    wire _909;
    wire _908;
    wire _907;
    wire _906;
    reg _914;
    wire _905;
    wire [2:0] _902;
    wire [3:0] _903;
    wire _904;
    wire _915;
    wire _898;
    wire _897;
    wire _896;
    wire _895;
    wire _894;
    wire _893;
    wire _892;
    wire _891;
    reg _899;
    wire _887;
    wire [3:0] _885;
    wire [7:0] _845;
    wire [6:0] _842;
    wire _843;
    wire _841;
    wire _844;
    wire [7:0] _846;
    wire [7:0] _22;
    reg [7:0] cfg_t0_set_cfg;
    wire [2:0] _882;
    wire [2:0] _883;
    wire [3:0] _884;
    wire _886;
    wire _900;
    wire [7:0] _1006;
    wire _879;
    wire _876;
    wire _877;
    wire _880;
    wire [7:0] _1007;
    wire _872;
    wire _873;
    wire _869;
    wire _870;
    wire _874;
    wire [7:0] _1147;
    wire [1:0] _864;
    wire _866;
    wire _862;
    wire _863;
    wire _867;
    wire [7:0] _1336;
    wire _1337;
    wire [1:0] _858;
    wire [3:0] _859;
    wire [5:0] _470;
    wire [5:0] _851;
    wire [6:0] _848;
    wire _849;
    wire _847;
    wire _850;
    wire [5:0] _852;
    wire [5:0] _23;
    reg [5:0] cfg_t0_sideset;
    wire [2:0] _854;
    wire [2:0] _855;
    wire [3:0] _856;
    wire _860;
    wire _1366;
    wire [7:0] _1486;
    wire [7:0] _1487;
    wire [7:0] _1488;
    wire [7:0] _1489;
    wire [7:0] _24;
    wire _2606;
    wire _2603;
    wire _2604;
    wire _2607;
    wire [7:0] _2731;
    wire _2599;
    wire _2600;
    wire _2596;
    wire _2597;
    wire _2601;
    wire [7:0] _2855;
    wire [1:0] _2591;
    wire _2593;
    wire _2589;
    wire _2590;
    wire _2594;
    wire [7:0] _2985;
    wire _2986;
    wire [3:0] _2586;
    wire [2:0] _2582;
    wire [2:0] _2583;
    wire [3:0] _2584;
    wire _2587;
    wire _3014;
    wire [7:0] _3134;
    wire [3:0] _2559;
    wire [1:0] _2553;
    wire [3:0] _2554;
    wire _2548;
    wire [3:0] _2551;
    wire [5:0] _1494;
    wire [6:0] _1491;
    wire _1492;
    wire _1490;
    wire _1493;
    wire [5:0] _1495;
    wire [5:0] _25;
    reg [5:0] cfg_t1_sideset;
    wire [1:0] _2546;
    wire _2547;
    wire [3:0] _2555;
    wire [3:0] _2545;
    wire [3:0] _2556;
    wire _324;
    wire _325;
    wire _1506;
    wire _1507;
    wire [6:0] _1502;
    wire _1503;
    wire _1499;
    wire _1500;
    wire _1501;
    wire _1504;
    wire _1508;
    wire _26;
    wire _326;
    wire [2:0] _1543;
    wire _247;
    wire _1537;
    wire _1535;
    wire _1532;
    wire _1533;
    wire _1536;
    wire _1538;
    wire _27;
    wire _248;
    wire [2:0] _1540;
    wire [2:0] _1541;
    wire [2:0] _1544;
    wire [2:0] _28;
    reg [2:0] t1_rx_level;
    wire _246;
    wire _1594;
    wire _1593;
    wire _1595;
    wire _1596;
    wire _1586;
    wire _1587;
    wire _1590;
    wire _1583;
    wire _1570;
    wire [5:0] _2536;
    wire [1:0] _2535;
    wire [7:0] _2537;
    wire [5:0] _2526;
    wire [7:0] _1549;
    wire [6:0] _1546;
    wire _1547;
    wire _1545;
    wire _1548;
    wire [7:0] _1550;
    wire [7:0] _29;
    reg [7:0] cfg_t1_start;
    wire [1:0] _1614;
    wire [1:0] _1608;
    wire _1607;
    wire [1:0] _1609;
    wire _1604;
    wire [1:0] _1610;
    wire [1:0] _1611;
    wire [1:0] _1612;
    wire [1:0] _1613;
    wire [1:0] _1615;
    wire [1:0] _30;
    wire [1:0] _31;
    reg [1:0] t1_page;
    wire [7:0] _2527;
    wire [7:0] _1620;
    wire [6:0] _1617;
    wire _1618;
    wire _1616;
    wire _1619;
    wire [7:0] _1621;
    wire [7:0] _32;
    reg [7:0] cfg_t1_timeout_vector;
    wire _2525;
    wire [7:0] _2528;
    wire [7:0] _2523;
    wire [15:0] _1630;
    wire [15:0] _1631;
    wire [15:0] _1632;
    wire [15:0] _1633;
    wire [15:0] _1635;
    wire [15:0] _33;
    wire [15:0] _34;
    reg [15:0] t1_wait_count;
    wire [6:0] _1637;
    wire _1638;
    wire _1636;
    wire _1639;
    wire [15:0] _1640;
    wire [15:0] _35;
    reg [15:0] cfg_t1_timeout;
    wire _1627;
    wire _1624;
    wire _1623;
    wire _1625;
    wire _1626;
    wire _1628;
    wire _1642;
    wire _1644;
    wire _1645;
    wire _1646;
    wire _1648;
    wire _36;
    wire _37;
    reg t1_waiting;
    wire [15:0] _1579;
    wire _1581;
    wire _1572;
    wire _1582;
    wire _1568;
    wire _1566;
    wire _1565;
    wire _1564;
    wire _1563;
    wire _1562;
    wire _1561;
    wire _1560;
    wire _1559;
    wire [2:0] _1558;
    reg _1567;
    wire _1569;
    wire _2518;
    wire _2517;
    wire _2519;
    wire _2520;
    wire [4:0] _1682;
    wire [5:0] _1679;
    wire [5:0] _1672;
    wire [5:0] _1680;
    wire _1681;
    wire [4:0] _1684;
    wire [4:0] _1669;
    wire _1663;
    wire [4:0] _1665;
    wire [4:0] _1666;
    wire _1654;
    wire [4:0] _1667;
    wire _1652;
    wire [4:0] _1670;
    wire _1650;
    wire [4:0] _1685;
    wire [4:0] _1686;
    wire [4:0] _1687;
    wire [4:0] _1688;
    wire [4:0] _1690;
    wire [4:0] _38;
    wire [4:0] _39;
    reg [4:0] t1_isr_count;
    wire _2513;
    wire [4:0] _1695;
    wire [6:0] _1692;
    wire _1693;
    wire _1691;
    wire _1694;
    wire [4:0] _1696;
    wire [4:0] _40;
    reg [4:0] cfg_t1_threshold;
    wire [4:0] _1718;
    wire [5:0] _1715;
    wire [5:0] _1714;
    wire [5:0] _1716;
    wire _1717;
    wire [4:0] _1720;
    wire [4:0] _1711;
    wire _1705;
    wire [4:0] _1707;
    wire [4:0] _1708;
    wire _1703;
    wire [4:0] _1709;
    wire _1702;
    wire [4:0] _1712;
    wire _1701;
    wire [4:0] _1721;
    wire [4:0] _1722;
    wire [4:0] _1723;
    wire [4:0] _1724;
    wire [4:0] _1725;
    wire [4:0] _41;
    wire [4:0] _42;
    reg [4:0] t1_osr_count;
    wire _2512;
    wire _2510;
    wire _2511;
    wire _2507;
    wire _2508;
    wire _2509;
    wire [15:0] _2492;
    wire _2490;
    wire [15:0] _2493;
    wire _2486;
    wire [15:0] _2487;
    wire [15:0] _1952;
    wire [15:0] _1921;
    wire [31:0] _1923;
    wire [23:0] _1917;
    wire [31:0] _1919;
    wire [27:0] _1913;
    wire [31:0] _1915;
    wire [29:0] _1909;
    wire [31:0] _1911;
    wire [30:0] _1905;
    wire [31:0] _1907;
    wire [31:0] _1904;
    wire _1902;
    wire [31:0] _1908;
    wire _1901;
    wire [31:0] _1912;
    wire _1900;
    wire [31:0] _1916;
    wire _1899;
    wire [31:0] _1920;
    wire _1898;
    wire [31:0] _1924;
    wire [15:0] _1925;
    wire [15:0] _1953;
    wire [15:0] _1894;
    wire [31:0] _1895;
    wire [23:0] _1890;
    wire [31:0] _1891;
    wire [27:0] _1886;
    wire [31:0] _1887;
    wire [29:0] _1882;
    wire [31:0] _1883;
    wire [30:0] _1878;
    wire [31:0] _1879;
    wire _1870;
    wire _1867;
    wire _1866;
    wire _1865;
    wire _1864;
    wire _1863;
    wire _1862;
    wire _1861;
    wire _1860;
    reg _1868;
    wire _1871;
    wire [4:0] _1857;
    wire _1858;
    wire _1855;
    wire _1854;
    wire _1853;
    wire _1852;
    wire _1851;
    wire _1850;
    wire _1849;
    wire _1848;
    wire [2:0] _1847;
    reg _1856;
    wire _1859;
    wire [4:0] _1843;
    wire _1844;
    wire _1841;
    wire _1840;
    wire _1839;
    wire _1838;
    wire _1837;
    wire _1836;
    wire _1835;
    wire _1834;
    wire [2:0] _1833;
    reg _1842;
    wire _1845;
    wire [4:0] _1829;
    wire _1830;
    wire _1827;
    wire _1826;
    wire _1825;
    wire _1824;
    wire _1823;
    wire _1822;
    wire _1821;
    wire _1820;
    wire [2:0] _1819;
    reg _1828;
    wire _1831;
    wire [4:0] _1815;
    wire _1816;
    wire _1813;
    wire _1812;
    wire _1811;
    wire _1810;
    wire _1809;
    wire _1808;
    wire _1807;
    wire _1806;
    wire [2:0] _1805;
    reg _1814;
    wire _1817;
    wire [4:0] _1801;
    wire _1802;
    wire _1799;
    wire _1798;
    wire _1797;
    wire _1796;
    wire _1795;
    wire _1794;
    wire _1793;
    wire _1792;
    wire [2:0] _1791;
    reg _1800;
    wire _1803;
    wire [4:0] _1787;
    wire _1788;
    wire _1785;
    wire _1784;
    wire _1783;
    wire _1782;
    wire _1781;
    wire _1780;
    wire _1779;
    wire _1778;
    wire [2:0] _1777;
    reg _1786;
    wire _1789;
    wire [4:0] _1773;
    wire _1774;
    wire _1771;
    wire _1770;
    wire _1769;
    wire _1768;
    wire _1767;
    wire _1766;
    wire _1765;
    wire _1764;
    wire [2:0] _1730;
    wire [6:0] _1727;
    wire _1728;
    wire _1726;
    wire _1729;
    wire [2:0] _1731;
    wire [2:0] _43;
    reg [2:0] cfg_t1_in_base;
    wire [2:0] _1763;
    reg _1772;
    wire _1775;
    wire [7:0] _1872;
    wire [15:0] _1873;
    wire [1:0] _1760;
    reg [15:0] _1875;
    wire [31:0] _1876;
    wire _1759;
    wire [31:0] _1880;
    wire _1758;
    wire [31:0] _1884;
    wire _1757;
    wire [31:0] _1888;
    wire _1756;
    wire [31:0] _1892;
    wire _1755;
    wire [31:0] _1896;
    wire [15:0] _1897;
    wire _258;
    wire [15:0] _1954;
    wire [15:0] _1753;
    wire _1735;
    wire [15:0] _1749;
    wire [15:0] _1750;
    wire _1734;
    wire [15:0] _1751;
    wire _1733;
    wire [15:0] _1754;
    wire _1732;
    wire [15:0] _1955;
    wire [15:0] _1956;
    wire [15:0] _1957;
    wire [15:0] _1958;
    wire [15:0] _1960;
    wire [15:0] _44;
    wire [15:0] _45;
    reg [15:0] t1_isr;
    wire [15:0] _1743;
    wire [15:0] _2464;
    wire _2462;
    wire [15:0] _2465;
    wire [15:0] _2453;
    wire [31:0] _2454;
    wire [23:0] _2449;
    wire [31:0] _2450;
    wire [27:0] _2445;
    wire [31:0] _2446;
    wire [29:0] _2441;
    wire [31:0] _2442;
    wire [30:0] _2437;
    wire [31:0] _2438;
    wire [31:0] _2435;
    wire _2433;
    wire [31:0] _2439;
    wire _2432;
    wire [31:0] _2443;
    wire _2431;
    wire [31:0] _2447;
    wire _2430;
    wire [31:0] _2451;
    wire [4:0] _2428;
    wire _2429;
    wire [31:0] _2455;
    wire [15:0] _2456;
    wire [15:0] _1946;
    wire [31:0] _1948;
    wire [23:0] _1942;
    wire [31:0] _1944;
    wire [27:0] _1938;
    wire [31:0] _1940;
    wire [29:0] _1934;
    wire [31:0] _1936;
    wire _1930;
    wire [31:0] _1933;
    wire _1929;
    wire [31:0] _1937;
    wire _1928;
    wire [31:0] _1941;
    wire _1927;
    wire [31:0] _1945;
    wire _1926;
    wire [31:0] _1949;
    wire [15:0] _1950;
    wire [15:0] _1951;
    wire [15:0] _2388;
    wire [31:0] _2390;
    wire [23:0] _2384;
    wire [31:0] _2386;
    wire [27:0] _2380;
    wire [31:0] _2382;
    wire [29:0] _2376;
    wire [31:0] _2378;
    wire [30:0] _2372;
    wire [31:0] _2374;
    wire [31:0] _2371;
    wire _2369;
    wire [31:0] _2375;
    wire _2368;
    wire [31:0] _2379;
    wire _2367;
    wire [31:0] _2383;
    wire _2366;
    wire [31:0] _2387;
    wire _2365;
    wire [31:0] _2391;
    wire [15:0] _2392;
    wire [15:0] _2361;
    wire [31:0] _2362;
    wire [23:0] _2357;
    wire [31:0] _2358;
    wire [27:0] _2353;
    wire [31:0] _2354;
    wire [29:0] _2349;
    wire [31:0] _2350;
    wire [30:0] _2345;
    wire [31:0] _2346;
    wire [31:0] _2343;
    wire _2341;
    wire [31:0] _2347;
    wire _2340;
    wire [31:0] _2351;
    wire _2339;
    wire [31:0] _2355;
    wire _2338;
    wire [31:0] _2359;
    wire [4:0] _1676;
    wire [3:0] _1673;
    wire _1675;
    wire [4:0] _1678;
    wire _2337;
    wire [31:0] _2363;
    wire [15:0] _2364;
    wire [15:0] _2393;
    wire _2330;
    wire _2331;
    reg [15:0] t1_tx_mem_3;
    wire _2324;
    wire _2325;
    reg [15:0] t1_tx_mem_2;
    wire _2318;
    wire _2319;
    reg [15:0] t1_tx_mem_1;
    wire [1:0] _1977;
    wire [1:0] _1978;
    wire [1:0] _46;
    reg [1:0] t1_tx_wr;
    wire _2312;
    wire _2313;
    wire _452;
    wire _453;
    reg [15:0] t0_rx_mem_3;
    wire _446;
    wire _447;
    reg [15:0] t0_rx_mem_2;
    wire _440;
    wire _441;
    reg [15:0] t0_rx_mem_1;
    wire [1:0] _1980;
    wire [1:0] _1981;
    wire [1:0] _47;
    reg [1:0] t0_rx_wr;
    wire _434;
    wire _435;
    wire [15:0] _2259;
    wire [31:0] _2261;
    wire [23:0] _2255;
    wire [31:0] _2257;
    wire [27:0] _2251;
    wire [31:0] _2253;
    wire [29:0] _2247;
    wire [31:0] _2249;
    wire _2243;
    wire [31:0] _2246;
    wire _2242;
    wire [31:0] _2250;
    wire _2241;
    wire [31:0] _2254;
    wire _2240;
    wire [31:0] _2258;
    wire _2239;
    wire [31:0] _2262;
    wire [15:0] _2263;
    wire [15:0] _2264;
    wire [15:0] _2265;
    wire [15:0] _2235;
    wire [31:0] _2236;
    wire [23:0] _2231;
    wire [31:0] _2232;
    wire [27:0] _2227;
    wire [31:0] _2228;
    wire [29:0] _2223;
    wire [31:0] _2224;
    wire [30:0] _2219;
    wire [31:0] _2220;
    wire [15:0] _2172;
    wire [15:0] _2167;
    wire [31:0] _2169;
    wire [23:0] _2163;
    wire [31:0] _2165;
    wire [27:0] _2159;
    wire [31:0] _2161;
    wire [29:0] _2155;
    wire [31:0] _2157;
    wire [30:0] _2151;
    wire [31:0] _2153;
    wire [31:0] _2150;
    wire _2148;
    wire [31:0] _2154;
    wire _2147;
    wire [31:0] _2158;
    wire _2146;
    wire [31:0] _2162;
    wire _2145;
    wire [31:0] _2166;
    wire _2144;
    wire [31:0] _2170;
    wire [15:0] _2171;
    wire [15:0] _2173;
    wire [15:0] _2140;
    wire [31:0] _2141;
    wire [23:0] _2136;
    wire [31:0] _2137;
    wire [27:0] _2132;
    wire [31:0] _2133;
    wire [29:0] _2128;
    wire [31:0] _2129;
    wire [30:0] _2124;
    wire [31:0] _2125;
    wire _2116;
    wire _2113;
    wire _2112;
    wire _2111;
    wire _2110;
    wire _2109;
    wire _2108;
    wire _2107;
    wire _2106;
    reg _2114;
    wire _2117;
    wire _2104;
    wire _2101;
    wire _2100;
    wire _2099;
    wire _2098;
    wire _2097;
    wire _2096;
    wire _2095;
    wire _2094;
    wire [2:0] _2093;
    reg _2102;
    wire _2105;
    wire _2090;
    wire _2087;
    wire _2086;
    wire _2085;
    wire _2084;
    wire _2083;
    wire _2082;
    wire _2081;
    wire _2080;
    wire [2:0] _2079;
    reg _2088;
    wire _2091;
    wire _2076;
    wire _2073;
    wire _2072;
    wire _2071;
    wire _2070;
    wire _2069;
    wire _2068;
    wire _2067;
    wire _2066;
    wire [2:0] _2065;
    reg _2074;
    wire _2077;
    wire _2062;
    wire _2059;
    wire _2058;
    wire _2057;
    wire _2056;
    wire _2055;
    wire _2054;
    wire _2053;
    wire _2052;
    wire [2:0] _2051;
    reg _2060;
    wire _2063;
    wire _2048;
    wire _2045;
    wire _2044;
    wire _2043;
    wire _2042;
    wire _2041;
    wire _2040;
    wire _2039;
    wire _2038;
    wire [2:0] _2037;
    reg _2046;
    wire _2049;
    wire _2034;
    wire _2031;
    wire _2030;
    wire _2029;
    wire _2028;
    wire _2027;
    wire _2026;
    wire _2025;
    wire _2024;
    wire [2:0] _2023;
    reg _2032;
    wire _2035;
    wire _2020;
    wire _2017;
    wire _2016;
    wire _2015;
    wire _2014;
    wire _2013;
    wire _2012;
    wire _2011;
    wire _2010;
    wire [2:0] _1986;
    wire [6:0] _1983;
    wire _1984;
    wire _1982;
    wire _1985;
    wire [2:0] _1987;
    wire [2:0] _48;
    reg [2:0] cfg_t0_in_base;
    wire [2:0] _2009;
    reg _2018;
    wire _2021;
    wire [7:0] _2118;
    wire [15:0] _2119;
    wire [1:0] _2006;
    reg [15:0] _2121;
    wire [31:0] _2122;
    wire _2005;
    wire [31:0] _2126;
    wire _2004;
    wire [31:0] _2130;
    wire _2003;
    wire [31:0] _2134;
    wire _2002;
    wire [31:0] _2138;
    wire _2001;
    wire [31:0] _2142;
    wire [15:0] _2143;
    wire [15:0] _2174;
    wire [15:0] _1998;
    wire _1993;
    wire [15:0] _1994;
    wire [15:0] _1995;
    wire _1991;
    wire [15:0] _1996;
    wire _1990;
    wire [15:0] _1999;
    wire _1989;
    wire [15:0] _2175;
    wire [15:0] _2176;
    wire [15:0] _2177;
    wire [15:0] _2178;
    wire [15:0] _2180;
    wire [15:0] _49;
    wire [15:0] _50;
    reg [15:0] t0_isr;
    wire [31:0] _2217;
    wire _2215;
    wire [31:0] _2221;
    wire _2214;
    wire [31:0] _2225;
    wire _2213;
    wire [31:0] _2229;
    wire _2212;
    wire [31:0] _2233;
    wire [4:0] _2200;
    wire [5:0] _2197;
    wire [5:0] _2196;
    wire [5:0] _2198;
    wire _2199;
    wire [4:0] _2202;
    wire [4:0] _2193;
    wire _2187;
    wire [4:0] _2189;
    wire [4:0] _2190;
    wire _2186;
    wire [4:0] _2191;
    wire _2185;
    wire [4:0] _2194;
    wire _2184;
    wire [4:0] _2203;
    wire [4:0] _2204;
    wire [4:0] _2205;
    wire [4:0] _2206;
    wire [4:0] _2208;
    wire [4:0] _51;
    wire [4:0] _52;
    reg [4:0] t0_isr_count;
    wire [4:0] _2210;
    wire _2211;
    wire [31:0] _2237;
    wire [15:0] _2238;
    wire _2000;
    wire [15:0] _2266;
    wire [15:0] _53;
    reg [15:0] t0_rx_mem_0;
    wire [1:0] _2285;
    wire _2282;
    wire _2277;
    wire _2274;
    wire _2275;
    wire [6:0] _2270;
    wire [6:0] _377;
    wire _2271;
    wire _2267;
    wire _2268;
    wire _1497;
    wire _1498;
    wire _2269;
    wire _2272;
    wire _2276;
    wire _54;
    wire _2278;
    wire _2279;
    wire _2283;
    wire [1:0] _2286;
    wire [1:0] _55;
    reg [1:0] t0_rx_rd;
    reg [15:0] _455;
    wire [15:0] _56;
    wire [15:0] _2308;
    reg [15:0] t1_tx_mem_0;
    wire [1:0] _2299;
    wire _2293;
    wire _1589;
    wire _2291;
    wire _2288;
    wire _2289;
    wire _2290;
    wire _2292;
    wire _57;
    wire _2294;
    wire [1:0] _2300;
    wire [1:0] _58;
    reg [1:0] t1_tx_rd;
    reg [15:0] _2333;
    wire _1534;
    wire [15:0] _2334;
    wire _2304;
    wire [15:0] _2305;
    wire [15:0] _2306;
    wire _2303;
    wire [15:0] _2307;
    wire _2302;
    wire [15:0] _2335;
    wire _2301;
    wire [15:0] _2394;
    wire [15:0] _2395;
    wire [15:0] _2396;
    wire [15:0] _2397;
    wire [15:0] _2399;
    wire [15:0] _59;
    wire [15:0] _60;
    reg [15:0] t1_osr;
    wire [15:0] _2426;
    wire [1:0] _2404;
    wire [6:0] _2401;
    wire _2402;
    wire _2400;
    wire _2403;
    wire [1:0] _2405;
    wire [1:0] _61;
    reg [1:0] cfg_t1_shift;
    wire _2336;
    wire [15:0] _2457;
    wire [1:0] _2423;
    wire _2425;
    wire [15:0] _2458;
    wire _2419;
    wire [15:0] _2420;
    wire [15:0] _2421;
    wire _2412;
    wire [15:0] _2416;
    wire _2410;
    wire [15:0] _2417;
    wire _2409;
    wire [15:0] _2422;
    wire _2408;
    wire [15:0] _2459;
    wire _2407;
    wire [15:0] _2466;
    wire [15:0] _2467;
    wire [15:0] _2468;
    wire [15:0] _2469;
    wire [15:0] _2471;
    wire [15:0] _62;
    wire [15:0] _63;
    reg [15:0] t1_y;
    reg [15:0] _1748;
    wire _2481;
    wire [15:0] _2482;
    wire [2:0] _1658;
    wire _1660;
    wire [2:0] _1655;
    wire _1657;
    wire _1661;
    wire [15:0] _2483;
    wire [4:0] _2414;
    wire [15:0] _2415;
    wire [1:0] _1605;
    wire _2477;
    wire [15:0] _2478;
    wire _2475;
    wire [15:0] _2479;
    wire _2474;
    wire [15:0] _2484;
    wire _2473;
    wire [15:0] _2488;
    wire _2472;
    wire [15:0] _2494;
    wire [15:0] _2495;
    wire [15:0] _2496;
    wire [15:0] _2497;
    wire [15:0] _2499;
    wire [15:0] _64;
    wire [15:0] _65;
    reg [15:0] t1_x;
    wire _2503;
    wire _2504;
    wire _2505;
    wire [2:0] _2460;
    reg _2514;
    wire _2501;
    wire _2515;
    wire _2521;
    wire [7:0] _2529;
    reg [7:0] t1_pc;
    wire [7:0] _2530;
    wire [7:0] _2531;
    wire [7:0] _2532;
    wire [7:0] _2533;
    wire [7:0] _66;
    wire [7:0] _67;
    wire [7:0] _2538;
    wire _2534;
    wire [15:0] _2544;
    wire [15:0] _68;
    wire [2:0] _1530;
    wire _1557;
    wire _1571;
    wire _1584;
    wire _1591;
    wire _1597;
    wire _1598;
    wire _1528;
    wire _1523;
    wire _1529;
    wire _1599;
    wire [3:0] _2557;
    wire [3:0] _2560;
    wire [3:0] _2561;
    wire [3:0] _2563;
    wire [3:0] _69;
    wire [3:0] _70;
    reg [3:0] t1_delay_left;
    wire _1554;
    wire _1555;
    wire [7:0] _3135;
    wire [15:0] _2575;
    wire [6:0] _2565;
    wire _2566;
    wire _2564;
    wire _2567;
    wire [15:0] _2568;
    wire [15:0] _71;
    reg [15:0] cfg_t1_clkdiv;
    wire _2573;
    wire [15:0] _2577;
    wire [15:0] _2571;
    wire [15:0] _2578;
    wire _2569;
    wire [15:0] _2580;
    wire [15:0] _72;
    reg [15:0] t1_div_count;
    wire _1522;
    wire _1552;
    wire [7:0] _3136;
    wire _1511;
    wire _1510;
    wire _1512;
    reg t1_loaded;
    wire _1516;
    wire _1509;
    wire _1517;
    wire _1551;
    wire [7:0] _3137;
    wire [7:0] _73;
    wire [7:0] _74;
    reg [7:0] pin_out;
    wire _643;
    wire [7:0] _639;
    reg [7:0] pins_sync1;
    reg [7:0] pins_sync2;
    wire [7:0] _640;
    wire [7:0] _3142;
    wire [6:0] _3139;
    wire _3140;
    wire _3138;
    wire _3141;
    wire [7:0] _3143;
    wire [7:0] _75;
    reg [7:0] cfg_sync_bypass;
    wire [7:0] _77;
    wire [7:0] _633;
    wire [7:0] _641;
    wire _642;
    wire [6:0] _3145;
    wire _3146;
    wire _3144;
    wire _3147;
    wire [15:0] _3148;
    wire [15:0] _78;
    reg [15:0] cfg_pin_modes;
    wire [1:0] _632;
    reg _645;
    wire [7:0] _681;
    wire [15:0] _1022;
    wire [15:0] _3309;
    wire _3307;
    wire [15:0] _3310;
    wire [15:0] _1208;
    wire [31:0] _1209;
    wire [23:0] _1204;
    wire [31:0] _1205;
    wire [27:0] _1200;
    wire [31:0] _1201;
    wire [29:0] _1196;
    wire [31:0] _1197;
    wire [30:0] _1192;
    wire [31:0] _1193;
    wire [31:0] _1190;
    wire _1188;
    wire [31:0] _1194;
    wire _1187;
    wire [31:0] _1198;
    wire _1186;
    wire [31:0] _1202;
    wire _1185;
    wire [31:0] _1206;
    wire [4:0] _1183;
    wire _1184;
    wire [31:0] _1210;
    wire [15:0] _1211;
    wire [15:0] _1175;
    wire [31:0] _1177;
    wire [23:0] _1171;
    wire [31:0] _1173;
    wire [27:0] _1167;
    wire [31:0] _1169;
    wire [29:0] _1163;
    wire [31:0] _1165;
    wire _1159;
    wire [31:0] _1162;
    wire _1158;
    wire [31:0] _1166;
    wire _1157;
    wire [31:0] _1170;
    wire _1156;
    wire [31:0] _1174;
    wire _1155;
    wire [31:0] _1178;
    wire [15:0] _1179;
    wire [15:0] _1180;
    wire [15:0] _3268;
    wire [31:0] _3270;
    wire [23:0] _3264;
    wire [31:0] _3266;
    wire [27:0] _3260;
    wire [31:0] _3262;
    wire [29:0] _3256;
    wire [31:0] _3258;
    wire [30:0] _3252;
    wire [31:0] _3254;
    wire [31:0] _3251;
    wire _3249;
    wire [31:0] _3255;
    wire _3248;
    wire [31:0] _3259;
    wire _3247;
    wire [31:0] _3263;
    wire _3246;
    wire [31:0] _3267;
    wire _3245;
    wire [31:0] _3271;
    wire [15:0] _3272;
    wire [15:0] _3241;
    wire [31:0] _3242;
    wire [23:0] _3237;
    wire [31:0] _3238;
    wire [27:0] _3233;
    wire [31:0] _3234;
    wire [29:0] _3229;
    wire [31:0] _3230;
    wire [30:0] _3225;
    wire [31:0] _3226;
    wire [31:0] _3223;
    wire _3221;
    wire [31:0] _3227;
    wire _3220;
    wire [31:0] _3231;
    wire _3219;
    wire [31:0] _3235;
    wire _3218;
    wire [31:0] _3239;
    wire [4:0] _809;
    wire [3:0] _806;
    wire _808;
    wire [4:0] _811;
    wire _3217;
    wire [31:0] _3243;
    wire [15:0] _3244;
    wire [15:0] _3273;
    wire _3211;
    wire _3212;
    reg [15:0] t0_tx_mem_3;
    wire _3205;
    wire _3206;
    reg [15:0] t0_tx_mem_2;
    wire _3199;
    wire _3200;
    reg [15:0] t0_tx_mem_1;
    wire [1:0] _3161;
    wire [1:0] _3162;
    wire [1:0] _79;
    reg [1:0] t0_tx_wr;
    wire _3193;
    wire _3194;
    reg [15:0] t0_tx_mem_0;
    wire [1:0] _3181;
    wire _3167;
    wire [2:0] _3169;
    wire _3154;
    wire _3155;
    wire [6:0] _3150;
    wire _3151;
    wire _3149;
    wire _3152;
    wire _3156;
    wire [2:0] _3164;
    wire [2:0] _3165;
    wire [2:0] _3170;
    wire [2:0] _80;
    reg [2:0] t0_tx_level;
    wire _713;
    wire _3175;
    wire _3172;
    wire _3173;
    wire _3174;
    wire _3176;
    wire _81;
    wire _3168;
    wire [1:0] _3182;
    wire [1:0] _82;
    reg [1:0] t0_tx_rd;
    reg [15:0] _3214;
    wire _710;
    wire [15:0] _3215;
    wire _3186;
    wire [15:0] _3187;
    wire [15:0] _3188;
    wire _3185;
    wire [15:0] _3189;
    wire _3184;
    wire [15:0] _3216;
    wire _3183;
    wire [15:0] _3274;
    wire [15:0] _3275;
    wire [15:0] _3276;
    wire [15:0] _3277;
    wire [15:0] _3279;
    wire [15:0] _83;
    wire [15:0] _84;
    reg [15:0] t0_osr;
    wire [15:0] _1181;
    wire [1:0] _3284;
    wire [6:0] _3281;
    wire _3282;
    wire _3280;
    wire _3283;
    wire [1:0] _3285;
    wire [1:0] _85;
    reg [1:0] cfg_t0_shift;
    wire _1154;
    wire [15:0] _1212;
    wire [1:0] _3300;
    wire _3302;
    wire [15:0] _3303;
    wire _3296;
    wire [15:0] _3297;
    wire [15:0] _3298;
    wire _3292;
    wire [15:0] _3293;
    wire _3290;
    wire [15:0] _3294;
    wire _3289;
    wire [15:0] _3299;
    wire _3288;
    wire [15:0] _3304;
    wire _3287;
    wire [15:0] _3311;
    wire [15:0] _3312;
    wire [15:0] _3313;
    wire [15:0] _3314;
    wire [15:0] _3316;
    wire [15:0] _86;
    wire [15:0] _87;
    reg [15:0] t0_y;
    reg [15:0] _1030;
    wire _3326;
    wire [15:0] _3327;
    wire [2:0] _791;
    wire _793;
    wire [2:0] _788;
    wire _790;
    wire _794;
    wire [15:0] _3328;
    wire [4:0] _889;
    wire [15:0] _890;
    wire [1:0] _729;
    wire _3322;
    wire [15:0] _3323;
    wire _3320;
    wire [15:0] _3324;
    wire _3319;
    wire [15:0] _3329;
    wire _3318;
    wire [15:0] _3333;
    wire _3317;
    wire [15:0] _3339;
    wire [15:0] _3340;
    wire [15:0] _3341;
    wire [15:0] _3342;
    wire [15:0] _3344;
    wire [15:0] _88;
    wire [15:0] _89;
    reg [15:0] t0_x;
    wire _3348;
    wire _3349;
    wire _3350;
    wire [2:0] _3305;
    reg _3359;
    wire _3346;
    wire _3360;
    wire _3366;
    wire [7:0] _3374;
    reg [7:0] t0_pc;
    wire [7:0] _3375;
    wire [7:0] _3376;
    wire [7:0] _3377;
    wire [7:0] _3378;
    wire [7:0] _90;
    wire [7:0] _91;
    wire [7:0] _3380;
    wire _3379;
    wire [15:0] _3386;
    wire [15:0] _92;
    wire [2:0] _628;
    wire _630;
    wire _694;
    wire _707;
    wire _715;
    wire _721;
    wire _722;
    wire _723;
    wire [3:0] _3397;
    wire _622;
    wire _623;
    wire [3:0] _3400;
    wire _617;
    wire [3:0] _3401;
    wire _611;
    wire [3:0] _3403;
    wire [3:0] _93;
    wire [3:0] _94;
    reg [3:0] t0_delay_left;
    wire _626;
    wire [15:0] _3415;
    wire [6:0] _3405;
    wire _3406;
    wire _3404;
    wire _3407;
    wire [15:0] _3408;
    wire [15:0] _95;
    reg [15:0] cfg_t0_clkdiv;
    wire _3413;
    wire [15:0] _3417;
    wire [15:0] _3411;
    wire [15:0] _3418;
    wire _3409;
    wire [15:0] _3420;
    wire [15:0] _96;
    reg [15:0] t0_div_count;
    wire _616;
    wire _604;
    wire [5:0] _488;
    wire [5:0] _3425;
    wire [6:0] _3422;
    wire _3423;
    wire _3421;
    wire _3424;
    wire [5:0] _3426;
    wire [5:0] _97;
    reg [5:0] cfg_load;
    wire [1:0] _601;
    wire [6:0] _597;
    wire _598;
    wire _596;
    wire _599;
    wire [1:0] _600;
    wire [1:0] _602;
    wire _603;
    wire _605;
    reg t0_loaded;
    wire _609;
    wire _595;
    wire _610;
    wire _624;
    wire _627;
    wire _3429;
    wire _3431;
    wire _3433;
    wire _98;
    wire _429;
    wire [2:0] _3435;
    wire [2:0] _3436;
    wire [2:0] _3439;
    wire [2:0] _99;
    reg [2:0] t0_rx_level;
    wire _2281;
    wire _3460;
    wire [15:0] _592;
    wire [2:0] _3458;
    wire [6:0] _588;
    wire _3456;
    wire _370;
    reg host_mosi_s1;
    reg host_mosi_s2;
    wire [22:0] _368;
    wire [22:0] _3440;
    wire [22:0] _3441;
    wire [22:0] _3442;
    wire [22:0] _100;
    reg [22:0] host_shift_in;
    wire [23:0] _375;
    wire [7:0] _376;
    wire _366;
    wire [7:0] _3443;
    wire [7:0] _3444;
    wire [7:0] _3445;
    wire [7:0] _101;
    reg [7:0] host_cmd;
    wire _586;
    wire [4:0] _580;
    wire [4:0] _3449;
    wire [4:0] _3446;
    wire _3447;
    wire [4:0] _3450;
    wire [4:0] _3451;
    wire [4:0] _3453;
    wire [4:0] _102;
    reg [4:0] host_bit_count;
    wire _581;
    wire _333;
    reg host_cs_n_s1;
    reg host_cs_n_s2;
    wire _360;
    reg host_sck_prev;
    wire _358;
    wire vdd;
    wire _104;
    wire _106;
    wire [7:0] _108;
    wire _338;
    reg host_sck_s1;
    reg host_sck_s2;
    wire _359;
    wire _361;
    wire _582;
    wire _3454;
    wire _3457;
    wire [2:0] _3459;
    wire [2:0] _109;
    reg [2:0] cfg_ctrl;
    wire _1965;
    wire _3461;
    wire _3463;
    wire _110;
    wire _1968;
    wire _1972;
    wire [2:0] _3465;
    wire [2:0] _3466;
    wire [2:0] _3469;
    wire [2:0] _111;
    reg [2:0] t1_tx_level;
    wire _3471;
    wire gnd;
    wire [7:0] _3483;
    assign _196 = pin_out[0:0];
    assign _197 = ~ _196;
    assign _194 = 2'b10;
    assign _193 = cfg_pin_modes[1:0];
    assign _195 = _193 == _194;
    assign _198 = _195 & _197;
    assign _191 = 2'b01;
    assign _190 = cfg_pin_modes[1:0];
    assign _192 = _190 == _191;
    assign _199 = _192 | _198;
    assign _186 = pin_out[1:1];
    assign _187 = ~ _186;
    assign _183 = cfg_pin_modes[3:2];
    assign _185 = _183 == _194;
    assign _188 = _185 & _187;
    assign _180 = cfg_pin_modes[3:2];
    assign _182 = _180 == _191;
    assign _189 = _182 | _188;
    assign _176 = pin_out[2:2];
    assign _177 = ~ _176;
    assign _173 = cfg_pin_modes[5:4];
    assign _175 = _173 == _194;
    assign _178 = _175 & _177;
    assign _170 = cfg_pin_modes[5:4];
    assign _172 = _170 == _191;
    assign _179 = _172 | _178;
    assign _166 = pin_out[3:3];
    assign _167 = ~ _166;
    assign _163 = cfg_pin_modes[7:6];
    assign _165 = _163 == _194;
    assign _168 = _165 & _167;
    assign _160 = cfg_pin_modes[7:6];
    assign _162 = _160 == _191;
    assign _169 = _162 | _168;
    assign _156 = pin_out[4:4];
    assign _157 = ~ _156;
    assign _153 = cfg_pin_modes[9:8];
    assign _155 = _153 == _194;
    assign _158 = _155 & _157;
    assign _150 = cfg_pin_modes[9:8];
    assign _152 = _150 == _191;
    assign _159 = _152 | _158;
    assign _146 = pin_out[5:5];
    assign _147 = ~ _146;
    assign _143 = cfg_pin_modes[11:10];
    assign _145 = _143 == _194;
    assign _148 = _145 & _147;
    assign _140 = cfg_pin_modes[11:10];
    assign _142 = _140 == _191;
    assign _149 = _142 | _148;
    assign _136 = pin_out[6:6];
    assign _137 = ~ _136;
    assign _133 = cfg_pin_modes[13:12];
    assign _135 = _133 == _194;
    assign _138 = _135 & _137;
    assign _130 = cfg_pin_modes[13:12];
    assign _132 = _130 == _191;
    assign _139 = _132 | _138;
    assign _126 = pin_out[7:7];
    assign _127 = ~ _126;
    assign _120 = cfg_pin_modes[15:14];
    assign _122 = _120 == _194;
    assign _128 = _122 & _127;
    assign _117 = cfg_pin_modes[15:14];
    assign _119 = _117 == _191;
    assign _129 = _119 | _128;
    assign _200 = { _129,
                    _139,
                    _149,
                    _159,
                    _169,
                    _179,
                    _189,
                    _199 };
    assign _239 = pin_out[0:0];
    assign _236 = cfg_pin_modes[1:0];
    assign _238 = _236 == _191;
    assign _240 = _238 & _239;
    assign _234 = pin_out[1:1];
    assign _231 = cfg_pin_modes[3:2];
    assign _233 = _231 == _191;
    assign _235 = _233 & _234;
    assign _229 = pin_out[2:2];
    assign _226 = cfg_pin_modes[5:4];
    assign _228 = _226 == _191;
    assign _230 = _228 & _229;
    assign _224 = pin_out[3:3];
    assign _221 = cfg_pin_modes[7:6];
    assign _223 = _221 == _191;
    assign _225 = _223 & _224;
    assign _219 = pin_out[4:4];
    assign _216 = cfg_pin_modes[9:8];
    assign _218 = _216 == _191;
    assign _220 = _218 & _219;
    assign _214 = pin_out[5:5];
    assign _211 = cfg_pin_modes[11:10];
    assign _213 = _211 == _191;
    assign _215 = _213 & _214;
    assign _209 = pin_out[6:6];
    assign _206 = cfg_pin_modes[13:12];
    assign _208 = _206 == _191;
    assign _210 = _208 & _209;
    assign _204 = pin_out[7:7];
    assign _201 = cfg_pin_modes[15:14];
    assign _203 = _201 == _191;
    assign _205 = _203 & _204;
    assign _241 = { _205,
                    _210,
                    _215,
                    _220,
                    _225,
                    _230,
                    _235,
                    _240 };
    assign _363 = 16'b0000000000000000;
    assign _576 = 1'b0;
    assign _575 = host_miso_shift[14:0];
    assign _577 = { _575,
                    _576 };
    assign _570 = 14'b00000000000000;
    assign _571 = { _570,
                    cfg_t1_shift };
    assign _562 = 10'b0000000000;
    assign _566 = { _562,
                    cfg_t1_sideset };
    assign _554 = cfg_ctrl[1:1];
    assign _558 = { t1_pc,
                    _554,
                    t1_rx_level,
                    gnd,
                    t1_tx_level };
    assign _545 = 2'b11;
    assign _546 = t1_rx_wr == _545;
    assign _547 = _248 & _546;
    always @(posedge _106) begin
        if (_104)
            t1_rx_mem_3 <= _363;
        else
            if (_547)
                t1_rx_mem_3 <= _4;
    end
    assign _540 = t1_rx_wr == _194;
    assign _541 = _248 & _540;
    always @(posedge _106) begin
        if (_104)
            t1_rx_mem_2 <= _363;
        else
            if (_541)
                t1_rx_mem_2 <= _4;
    end
    assign _534 = t1_rx_wr == _191;
    assign _535 = _248 & _534;
    always @(posedge _106) begin
        if (_104)
            t1_rx_mem_1 <= _363;
        else
            if (_535)
                t1_rx_mem_1 <= _4;
    end
    assign _527 = 2'b00;
    assign _253 = t1_rx_wr + _191;
    assign _254 = _248 ? _253 : t1_rx_wr;
    assign _3 = _254;
    always @(posedge _106) begin
        if (_104)
            t1_rx_wr <= _527;
        else
            t1_rx_wr <= _3;
    end
    assign _528 = t1_rx_wr == _527;
    assign _529 = _248 & _528;
    assign _315 = _314[15:0];
    assign _317 = { _315,
                    _363 };
    assign _312 = 8'b00000000;
    assign _311 = _310[23:0];
    assign _313 = { _311,
                    _312 };
    assign _308 = 4'b0000;
    assign _307 = _306[27:0];
    assign _309 = { _307,
                    _308 };
    assign _303 = _302[29:0];
    assign _305 = { _303,
                    _527 };
    assign _301 = 32'b11111111111111111111111111111110;
    assign _300 = 32'b11111111111111111111111111111111;
    assign _299 = t1_isr_count[0:0];
    assign _302 = _299 ? _301 : _300;
    assign _298 = t1_isr_count[1:1];
    assign _306 = _298 ? _305 : _302;
    assign _297 = t1_isr_count[2:2];
    assign _310 = _297 ? _309 : _306;
    assign _296 = t1_isr_count[3:3];
    assign _314 = _296 ? _313 : _310;
    assign _295 = t1_isr_count[4:4];
    assign _318 = _295 ? _317 : _314;
    assign _319 = _318[15:0];
    assign _320 = ~ _319;
    assign _321 = t1_isr & _320;
    assign _291 = _289[31:16];
    assign _292 = { _363,
                    _291 };
    assign _287 = _285[31:8];
    assign _288 = { _312,
                    _287 };
    assign _283 = _281[31:4];
    assign _284 = { _308,
                    _283 };
    assign _279 = _277[31:2];
    assign _280 = { _527,
                    _279 };
    assign _275 = _273[31:1];
    assign _276 = { _576,
                    _275 };
    assign _273 = { _363,
                    t1_isr };
    assign _268 = _263[0:0];
    assign _277 = _268 ? _276 : _273;
    assign _267 = _263[1:1];
    assign _281 = _267 ? _280 : _277;
    assign _266 = _263[2:2];
    assign _285 = _266 ? _284 : _281;
    assign _265 = _263[3:3];
    assign _289 = _265 ? _288 : _285;
    assign _259 = 5'b10000;
    assign _263 = _259 - t1_isr_count;
    assign _264 = _263[4:4];
    assign _293 = _264 ? _292 : _289;
    assign _294 = _293[15:0];
    assign _322 = _258 ? _321 : _294;
    assign _4 = _322;
    always @(posedge _106) begin
        if (_104)
            t1_rx_mem_0 <= _363;
        else
            if (_529)
                t1_rx_mem_0 <= _4;
    end
    assign _331 = t1_rx_rd + _191;
    assign _332 = _326 ? _331 : t1_rx_rd;
    assign _5 = _332;
    always @(posedge _106) begin
        if (_104)
            t1_rx_rd <= _527;
        else
            t1_rx_rd <= _5;
    end
    always @* begin
        case (t1_rx_rd)
        0:
            _549 <= t1_rx_mem_0;
        1:
            _549 <= t1_rx_mem_1;
        2:
            _549 <= t1_rx_mem_2;
        default:
            _549 <= t1_rx_mem_3;
        endcase
    end
    assign _521 = 3'b000;
    assign _522 = t1_rx_level == _521;
    assign _523 = ~ _522;
    assign _550 = _523 ? _549 : _363;
    assign _520 = { _312,
                    cfg_t1_timeout_vector };
    assign _511 = 11'b00000000000;
    assign _515 = { _511,
                    cfg_t1_threshold };
    assign _506 = 13'b0000000000000;
    assign _510 = { _506,
                    cfg_t1_in_base };
    assign _505 = { _312,
                    cfg_t1_set_cfg };
    assign _500 = { _312,
                    cfg_t1_out_cfg };
    assign _495 = { _312,
                    cfg_t1_start };
    assign _490 = { _562,
                    cfg_load };
    assign _485 = { _570,
                    cfg_t0_shift };
    assign _480 = { _312,
                    cfg_sync_bypass };
    assign _472 = { _562,
                    cfg_t0_sideset };
    assign _460 = cfg_ctrl[0:0];
    assign _464 = { t0_pc,
                    _460,
                    t0_rx_level,
                    gnd,
                    t0_tx_level };
    assign _418 = t0_rx_level == _521;
    assign _419 = ~ _418;
    assign _456 = _419 ? _455 : _363;
    assign _413 = { _312,
                    cfg_t0_timeout_vector };
    assign _408 = { _511,
                    cfg_t0_threshold };
    assign _403 = { _506,
                    cfg_t0_in_base };
    assign _398 = { _312,
                    cfg_t0_set_cfg };
    assign _393 = { _312,
                    cfg_t0_out_cfg };
    assign _388 = { _312,
                    cfg_t0_start };
    assign _383 = { _506,
                    cfg_ctrl };
    always @* begin
        case (_377)
        0:
            _572 <= _363;
        1:
            _572 <= _363;
        2:
            _572 <= _363;
        3:
            _572 <= _363;
        4:
            _572 <= _363;
        5:
            _572 <= _363;
        6:
            _572 <= _363;
        7:
            _572 <= _363;
        8:
            _572 <= _363;
        9:
            _572 <= _363;
        10:
            _572 <= _363;
        11:
            _572 <= _363;
        12:
            _572 <= _363;
        13:
            _572 <= _363;
        14:
            _572 <= _363;
        15:
            _572 <= _363;
        16:
            _572 <= _363;
        17:
            _572 <= _363;
        18:
            _572 <= _363;
        19:
            _572 <= _363;
        20:
            _572 <= _363;
        21:
            _572 <= _363;
        22:
            _572 <= _363;
        23:
            _572 <= _363;
        24:
            _572 <= _363;
        25:
            _572 <= _363;
        26:
            _572 <= _363;
        27:
            _572 <= _363;
        28:
            _572 <= _363;
        29:
            _572 <= _363;
        30:
            _572 <= _363;
        31:
            _572 <= _363;
        32:
            _572 <= _363;
        33:
            _572 <= _363;
        34:
            _572 <= _363;
        35:
            _572 <= _363;
        36:
            _572 <= _363;
        37:
            _572 <= _363;
        38:
            _572 <= _363;
        39:
            _572 <= _363;
        40:
            _572 <= _363;
        41:
            _572 <= _363;
        42:
            _572 <= _363;
        43:
            _572 <= _363;
        44:
            _572 <= _363;
        45:
            _572 <= _363;
        46:
            _572 <= _363;
        47:
            _572 <= _363;
        48:
            _572 <= _363;
        49:
            _572 <= _363;
        50:
            _572 <= _363;
        51:
            _572 <= _363;
        52:
            _572 <= _363;
        53:
            _572 <= _363;
        54:
            _572 <= _363;
        55:
            _572 <= _363;
        56:
            _572 <= _363;
        57:
            _572 <= _363;
        58:
            _572 <= _363;
        59:
            _572 <= _363;
        60:
            _572 <= _363;
        61:
            _572 <= _363;
        62:
            _572 <= _363;
        63:
            _572 <= _363;
        64:
            _572 <= _383;
        65:
            _572 <= _388;
        66:
            _572 <= _393;
        67:
            _572 <= _398;
        68:
            _572 <= _403;
        69:
            _572 <= _408;
        70:
            _572 <= _413;
        71:
            _572 <= cfg_pin_modes;
        72:
            _572 <= _363;
        73:
            _572 <= _456;
        74:
            _572 <= _464;
        75:
            _572 <= cfg_t0_timeout;
        76:
            _572 <= _472;
        77:
            _572 <= cfg_t0_clkdiv;
        78:
            _572 <= _480;
        79:
            _572 <= _485;
        80:
            _572 <= _490;
        81:
            _572 <= _495;
        82:
            _572 <= _500;
        83:
            _572 <= _505;
        84:
            _572 <= _510;
        85:
            _572 <= _515;
        86:
            _572 <= _520;
        87:
            _572 <= _363;
        88:
            _572 <= _363;
        89:
            _572 <= _550;
        90:
            _572 <= _558;
        91:
            _572 <= cfg_t1_timeout;
        92:
            _572 <= _566;
        93:
            _572 <= cfg_t1_clkdiv;
        94:
            _572 <= _363;
        95:
            _572 <= _571;
        default:
            _572 <= _363;
        endcase
    end
    assign _573 = _366 ? _572 : host_miso_shift;
    assign _574 = _361 ? _573 : host_miso_shift;
    assign _354 = 5'b01001;
    assign _355 = host_bit_count < _354;
    assign _356 = ~ _355;
    assign _349 = ~ host_cs_n_s2;
    assign _344 = ~ host_sck_s2;
    assign _348 = _344 & host_sck_prev;
    assign _350 = _348 & _349;
    assign _357 = _350 & _356;
    assign _578 = _357 ? _577 : _574;
    assign _579 = host_cs_n_s2 ? host_miso_shift : _578;
    assign _6 = _579;
    always @(posedge _106) begin
        if (_104)
            host_miso_shift <= _363;
        else
            host_miso_shift <= _6;
    end
    assign _3482 = host_miso_shift[15:15];
    assign _3481 = cfg_ctrl[0:0];
    assign _3479 = t0_rx_level == _521;
    assign _3480 = ~ _3479;
    assign _3476 = 3'b100;
    assign _3477 = t0_tx_level == _3476;
    assign _3475 = cfg_ctrl[1:1];
    assign _3473 = t1_rx_level == _521;
    assign _3474 = ~ _3473;
    assign _3468 = { _527,
                     _2294 };
    assign _1971 = ~ _1970;
    assign _1966 = ~ _1965;
    assign _1962 = 7'b1011000;
    assign _1963 = _588 == _1962;
    assign _1961 = _582 & _586;
    assign _1964 = _1961 & _1963;
    assign _1967 = _1964 & _1966;
    assign _1970 = t1_tx_level == _3476;
    assign _3462 = ~ _1970;
    assign _3438 = { _527,
                     _2283 };
    assign _428 = ~ _427;
    assign _3432 = ~ _427;
    assign _3430 = ~ _710;
    assign _3428 = _628 == _3476;
    assign _3398 = 4'b0001;
    assign _3399 = t0_delay_left - _3398;
    assign _3393 = _3391[3:2];
    assign _3394 = { _527,
                     _3393 };
    assign _3390 = 4'b0111;
    assign _3389 = 4'b1111;
    assign _3388 = _858[0:0];
    assign _3391 = _3388 ? _3390 : _3389;
    assign _3387 = _858[1:1];
    assign _3395 = _3387 ? _3394 : _3391;
    assign _3396 = _1345 & _3395;
    assign _427 = t0_rx_level == _3476;
    assign _718 = ~ _710;
    assign _717 = _628 == _3476;
    assign _719 = _717 & _718;
    assign _720 = _719 & _427;
    assign _709 = _628 == _3476;
    assign _711 = _709 & _710;
    assign _714 = _711 & _713;
    assign _706 = ~ _705;
    assign _693 = ~ _692;
    assign _629 = 3'b001;
    assign _3381 = 16'b1111111111111111;
    assign _3371 = _92[5:0];
    assign _593 = _592[7:0];
    assign _589 = 7'b1000001;
    assign _590 = _588 == _589;
    assign _587 = _582 & _586;
    assign _591 = _587 & _590;
    assign _594 = _591 ? _593 : cfg_t0_start;
    assign _7 = _594;
    always @(posedge _106) begin
        if (_104)
            cfg_t0_start <= _312;
        else
            cfg_t0_start <= _7;
    end
    assign _738 = cfg_t0_start[7:6];
    assign _732 = _92[1:0];
    assign _731 = _729 == _545;
    assign _733 = _731 ? _732 : t0_page;
    assign _728 = _628 == _3015;
    assign _734 = _728 ? _733 : t0_page;
    assign _735 = _723 ? _734 : t0_page;
    assign _736 = _623 ? t0_page : _735;
    assign _737 = _617 ? t0_page : _736;
    assign _739 = _611 ? _738 : _737;
    assign _8 = _739;
    assign _9 = _8;
    always @(posedge _106) begin
        if (_104)
            t0_page <= _527;
        else
            t0_page <= _9;
    end
    assign _3372 = { t0_page,
                     _3371 };
    assign _744 = _592[7:0];
    assign _741 = 7'b1000110;
    assign _742 = _588 == _741;
    assign _740 = _582 & _586;
    assign _743 = _740 & _742;
    assign _745 = _743 ? _744 : cfg_t0_timeout_vector;
    assign _10 = _745;
    always @(posedge _106) begin
        if (_104)
            cfg_t0_timeout_vector <= _312;
        else
            cfg_t0_timeout_vector <= _10;
    end
    assign _3370 = _628 == _521;
    assign _3373 = _3370 ? _3372 : cfg_t0_timeout_vector;
    assign _3367 = 8'b00000001;
    assign _3368 = t0_pc + _3367;
    assign _753 = 16'b0000000000000001;
    assign _754 = _702 - _753;
    assign _755 = _752 ? _754 : t0_wait_count;
    assign _756 = _623 ? t0_wait_count : _755;
    assign _757 = _617 ? t0_wait_count : _756;
    assign _759 = _611 ? _363 : _757;
    assign _11 = _759;
    assign _12 = _11;
    always @(posedge _106) begin
        if (_104)
            t0_wait_count <= _363;
        else
            t0_wait_count <= _12;
    end
    assign _761 = 7'b1001011;
    assign _762 = _588 == _761;
    assign _760 = _582 & _586;
    assign _763 = _760 & _762;
    assign _764 = _763 ? _592 : cfg_t0_timeout;
    assign _13 = _764;
    always @(posedge _106) begin
        if (_104)
            cfg_t0_timeout <= _363;
        else
            cfg_t0_timeout <= _13;
    end
    assign _765 = 1'b1;
    assign _751 = ~ _704;
    assign _748 = ~ _692;
    assign _747 = _628 == _629;
    assign _749 = _747 & _748;
    assign _750 = _749 & _695;
    assign _752 = _750 & _751;
    assign _766 = _752 ? _765 : t0_waiting;
    assign _768 = _723 ? _576 : _766;
    assign _769 = _623 ? t0_waiting : _768;
    assign _770 = _617 ? t0_waiting : _769;
    assign _772 = _611 ? _576 : _770;
    assign _14 = _772;
    assign _15 = _14;
    always @(posedge _106) begin
        if (_104)
            t0_waiting <= _576;
        else
            t0_waiting <= _15;
    end
    assign _702 = t0_waiting ? t0_wait_count : cfg_t0_timeout;
    assign _704 = _702 == _363;
    assign _695 = _92[4:4];
    assign _705 = _695 & _704;
    assign _691 = _92[8:8];
    assign _689 = _681[7:7];
    assign _688 = _681[6:6];
    assign _687 = _681[5:5];
    assign _686 = _681[4:4];
    assign _685 = _681[3:3];
    assign _684 = _681[2:2];
    assign _683 = _681[1:1];
    assign _682 = _681[0:0];
    assign _631 = _92[7:5];
    always @* begin
        case (_631)
        0:
            _690 <= _682;
        1:
            _690 <= _683;
        2:
            _690 <= _684;
        3:
            _690 <= _685;
        4:
            _690 <= _686;
        5:
            _690 <= _687;
        6:
            _690 <= _688;
        default:
            _690 <= _689;
        endcase
    end
    assign _692 = _690 == _691;
    assign _3363 = ~ _692;
    assign _3362 = _628 == _629;
    assign _3364 = _3362 & _3363;
    assign _3365 = _3364 & _705;
    assign _3358 = t0_isr_count < cfg_t0_threshold;
    assign _780 = 5'b00000;
    assign _406 = 5'b01000;
    assign _777 = _592[4:0];
    assign _774 = 7'b1000101;
    assign _775 = _588 == _774;
    assign _773 = _582 & _586;
    assign _776 = _773 & _775;
    assign _778 = _776 ? _777 : cfg_t0_threshold;
    assign _16 = _778;
    always @(posedge _106) begin
        if (_104)
            cfg_t0_threshold <= _406;
        else
            cfg_t0_threshold <= _16;
    end
    assign _815 = _813[4:0];
    assign _812 = { gnd,
                    _811 };
    assign _805 = { gnd,
                    t0_osr_count };
    assign _813 = _805 + _812;
    assign _804 = 6'b010000;
    assign _814 = _804 < _813;
    assign _817 = _814 ? _259 : _815;
    assign _802 = _710 ? _780 : t0_osr_count;
    assign _796 = _788 == _3476;
    assign _798 = _796 ? _780 : t0_osr_count;
    assign _799 = _794 ? _798 : t0_osr_count;
    assign _787 = _628 == _3032;
    assign _800 = _787 ? _799 : t0_osr_count;
    assign _785 = _628 == _3476;
    assign _803 = _785 ? _802 : _800;
    assign _783 = _628 == _3066;
    assign _818 = _783 ? _817 : _803;
    assign _819 = _723 ? _818 : t0_osr_count;
    assign _820 = _623 ? t0_osr_count : _819;
    assign _821 = _617 ? t0_osr_count : _820;
    assign _822 = _611 ? cfg_t0_threshold : _821;
    assign _17 = _822;
    assign _18 = _17;
    always @(posedge _106) begin
        if (_104)
            t0_osr_count <= _780;
        else
            t0_osr_count <= _18;
    end
    assign _3357 = t0_osr_count < cfg_t0_threshold;
    assign _3355 = t0_x == t0_y;
    assign _3356 = ~ _3355;
    assign _3352 = t0_y == _363;
    assign _3353 = ~ _3352;
    assign _3354 = ~ _3353;
    assign _3337 = t0_x - _753;
    assign _3334 = 3'b010;
    assign _3335 = _3305 == _3334;
    assign _3338 = _3335 ? _3337 : t0_x;
    assign _3331 = _3300 == _191;
    assign _3332 = _3331 ? _1212 : t0_x;
    assign _679 = _678 & _677;
    assign _678 = pin_out[0:0];
    assign _677 = _641[0:0];
    assign _676 = cfg_pin_modes[1:0];
    always @* begin
        case (_676)
        0:
            _680 <= _677;
        1:
            _680 <= _678;
        2:
            _680 <= _679;
        default:
            _680 <= _677;
        endcase
    end
    assign _674 = _673 & _672;
    assign _673 = pin_out[1:1];
    assign _672 = _641[1:1];
    assign _671 = cfg_pin_modes[3:2];
    always @* begin
        case (_671)
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
    assign _669 = _668 & _667;
    assign _668 = pin_out[2:2];
    assign _667 = _641[2:2];
    assign _666 = cfg_pin_modes[5:4];
    always @* begin
        case (_666)
        0:
            _670 <= _667;
        1:
            _670 <= _668;
        2:
            _670 <= _669;
        default:
            _670 <= _667;
        endcase
    end
    assign _664 = _663 & _662;
    assign _663 = pin_out[3:3];
    assign _662 = _641[3:3];
    assign _661 = cfg_pin_modes[7:6];
    always @* begin
        case (_661)
        0:
            _665 <= _662;
        1:
            _665 <= _663;
        2:
            _665 <= _664;
        default:
            _665 <= _662;
        endcase
    end
    assign _659 = _658 & _657;
    assign _658 = pin_out[4:4];
    assign _657 = _641[4:4];
    assign _656 = cfg_pin_modes[9:8];
    always @* begin
        case (_656)
        0:
            _660 <= _657;
        1:
            _660 <= _658;
        2:
            _660 <= _659;
        default:
            _660 <= _657;
        endcase
    end
    assign _654 = _653 & _652;
    assign _653 = pin_out[5:5];
    assign _652 = _641[5:5];
    assign _651 = cfg_pin_modes[11:10];
    always @* begin
        case (_651)
        0:
            _655 <= _652;
        1:
            _655 <= _653;
        2:
            _655 <= _654;
        default:
            _655 <= _652;
        endcase
    end
    assign _649 = _648 & _647;
    assign _648 = pin_out[6:6];
    assign _647 = _641[6:6];
    assign _646 = cfg_pin_modes[13:12];
    always @* begin
        case (_646)
        0:
            _650 <= _647;
        1:
            _650 <= _648;
        2:
            _650 <= _649;
        default:
            _650 <= _647;
        endcase
    end
    assign _644 = _643 & _642;
    assign _124 = 8'b11111111;
    assign _3131 = _3004[7:7];
    assign _3130 = _3004[6:6];
    assign _3129 = _3004[5:5];
    assign _3128 = _3004[4:4];
    assign _3127 = _3004[3:3];
    assign _3126 = _3004[2:2];
    assign _3125 = _3004[1:1];
    assign _3124 = _3004[0:0];
    always @* begin
        case (_3118)
        0:
            _3132 <= _3124;
        1:
            _3132 <= _3125;
        2:
            _3132 <= _3126;
        3:
            _3132 <= _3127;
        4:
            _3132 <= _3128;
        5:
            _3132 <= _3129;
        6:
            _3132 <= _3130;
        default:
            _3132 <= _3131;
        endcase
    end
    assign _3123 = _2985[0:0];
    assign _3121 = { _527,
                     _2546 };
    assign _3118 = _521 - _2582;
    assign _3119 = { gnd,
                     _3118 };
    assign _3122 = _3119 < _3121;
    assign _3133 = _3122 ? _3132 : _3123;
    assign _3114 = _3004[7:7];
    assign _3113 = _3004[6:6];
    assign _3112 = _3004[5:5];
    assign _3111 = _3004[4:4];
    assign _3110 = _3004[3:3];
    assign _3109 = _3004[2:2];
    assign _3108 = _3004[1:1];
    assign _3107 = _3004[0:0];
    always @* begin
        case (_3101)
        0:
            _3115 <= _3107;
        1:
            _3115 <= _3108;
        2:
            _3115 <= _3109;
        3:
            _3115 <= _3110;
        4:
            _3115 <= _3111;
        5:
            _3115 <= _3112;
        6:
            _3115 <= _3113;
        default:
            _3115 <= _3114;
        endcase
    end
    assign _3106 = _2985[1:1];
    assign _3104 = { _527,
                     _2546 };
    assign _3101 = _629 - _2582;
    assign _3102 = { gnd,
                     _3101 };
    assign _3105 = _3102 < _3104;
    assign _3116 = _3105 ? _3115 : _3106;
    assign _3097 = _3004[7:7];
    assign _3096 = _3004[6:6];
    assign _3095 = _3004[5:5];
    assign _3094 = _3004[4:4];
    assign _3093 = _3004[3:3];
    assign _3092 = _3004[2:2];
    assign _3091 = _3004[1:1];
    assign _3090 = _3004[0:0];
    always @* begin
        case (_3084)
        0:
            _3098 <= _3090;
        1:
            _3098 <= _3091;
        2:
            _3098 <= _3092;
        3:
            _3098 <= _3093;
        4:
            _3098 <= _3094;
        5:
            _3098 <= _3095;
        6:
            _3098 <= _3096;
        default:
            _3098 <= _3097;
        endcase
    end
    assign _3089 = _2985[2:2];
    assign _3087 = { _527,
                     _2546 };
    assign _3084 = _3334 - _2582;
    assign _3085 = { gnd,
                     _3084 };
    assign _3088 = _3085 < _3087;
    assign _3099 = _3088 ? _3098 : _3089;
    assign _3080 = _3004[7:7];
    assign _3079 = _3004[6:6];
    assign _3078 = _3004[5:5];
    assign _3077 = _3004[4:4];
    assign _3076 = _3004[3:3];
    assign _3075 = _3004[2:2];
    assign _3074 = _3004[1:1];
    assign _3073 = _3004[0:0];
    always @* begin
        case (_3067)
        0:
            _3081 <= _3073;
        1:
            _3081 <= _3074;
        2:
            _3081 <= _3075;
        3:
            _3081 <= _3076;
        4:
            _3081 <= _3077;
        5:
            _3081 <= _3078;
        6:
            _3081 <= _3079;
        default:
            _3081 <= _3080;
        endcase
    end
    assign _3072 = _2985[3:3];
    assign _3070 = { _527,
                     _2546 };
    assign _3066 = 3'b011;
    assign _3067 = _3066 - _2582;
    assign _3068 = { gnd,
                     _3067 };
    assign _3071 = _3068 < _3070;
    assign _3082 = _3071 ? _3081 : _3072;
    assign _3063 = _3004[7:7];
    assign _3062 = _3004[6:6];
    assign _3061 = _3004[5:5];
    assign _3060 = _3004[4:4];
    assign _3059 = _3004[3:3];
    assign _3058 = _3004[2:2];
    assign _3057 = _3004[1:1];
    assign _3056 = _3004[0:0];
    always @* begin
        case (_3050)
        0:
            _3064 <= _3056;
        1:
            _3064 <= _3057;
        2:
            _3064 <= _3058;
        3:
            _3064 <= _3059;
        4:
            _3064 <= _3060;
        5:
            _3064 <= _3061;
        6:
            _3064 <= _3062;
        default:
            _3064 <= _3063;
        endcase
    end
    assign _3055 = _2985[4:4];
    assign _3053 = { _527,
                     _2546 };
    assign _3050 = _3476 - _2582;
    assign _3051 = { gnd,
                     _3050 };
    assign _3054 = _3051 < _3053;
    assign _3065 = _3054 ? _3064 : _3055;
    assign _3046 = _3004[7:7];
    assign _3045 = _3004[6:6];
    assign _3044 = _3004[5:5];
    assign _3043 = _3004[4:4];
    assign _3042 = _3004[3:3];
    assign _3041 = _3004[2:2];
    assign _3040 = _3004[1:1];
    assign _3039 = _3004[0:0];
    always @* begin
        case (_3033)
        0:
            _3047 <= _3039;
        1:
            _3047 <= _3040;
        2:
            _3047 <= _3041;
        3:
            _3047 <= _3042;
        4:
            _3047 <= _3043;
        5:
            _3047 <= _3044;
        6:
            _3047 <= _3045;
        default:
            _3047 <= _3046;
        endcase
    end
    assign _3038 = _2985[5:5];
    assign _3036 = { _527,
                     _2546 };
    assign _3032 = 3'b101;
    assign _3033 = _3032 - _2582;
    assign _3034 = { gnd,
                     _3033 };
    assign _3037 = _3034 < _3036;
    assign _3048 = _3037 ? _3047 : _3038;
    assign _3029 = _3004[7:7];
    assign _3028 = _3004[6:6];
    assign _3027 = _3004[5:5];
    assign _3026 = _3004[4:4];
    assign _3025 = _3004[3:3];
    assign _3024 = _3004[2:2];
    assign _3023 = _3004[1:1];
    assign _3022 = _3004[0:0];
    always @* begin
        case (_3016)
        0:
            _3030 <= _3022;
        1:
            _3030 <= _3023;
        2:
            _3030 <= _3024;
        3:
            _3030 <= _3025;
        4:
            _3030 <= _3026;
        5:
            _3030 <= _3027;
        6:
            _3030 <= _3028;
        default:
            _3030 <= _3029;
        endcase
    end
    assign _3021 = _2985[6:6];
    assign _3019 = { _527,
                     _2546 };
    assign _3015 = 3'b110;
    assign _3016 = _3015 - _2582;
    assign _3017 = { gnd,
                     _3016 };
    assign _3020 = _3017 < _3019;
    assign _3031 = _3020 ? _3030 : _3021;
    assign _3012 = _3004[7:7];
    assign _3011 = _3004[6:6];
    assign _3010 = _3004[5:5];
    assign _3009 = _3004[4:4];
    assign _3008 = _3004[3:3];
    assign _3007 = _3004[2:2];
    assign _3006 = _3004[1:1];
    assign _2999 = _2997[3:2];
    assign _3000 = { _527,
                     _2999 };
    assign _2995 = _2545[3:1];
    assign _2996 = { _576,
                     _2995 };
    assign _2993 = _2990[0:0];
    assign _2997 = _2993 ? _2996 : _2545;
    assign _2992 = _2990[1:1];
    assign _3001 = _2992 ? _3000 : _2997;
    assign _2989 = { gnd,
                     _2546 };
    assign _2990 = _3476 - _2989;
    assign _2991 = _2990[2:2];
    assign _3003 = _2991 ? _308 : _3001;
    assign _3004 = { _308,
                     _3003 };
    assign _3005 = _3004[0:0];
    always @* begin
        case (_2583)
        0:
            _3013 <= _3005;
        1:
            _3013 <= _3006;
        2:
            _3013 <= _3007;
        3:
            _3013 <= _3008;
        4:
            _3013 <= _3009;
        5:
            _3013 <= _3010;
        6:
            _3013 <= _3011;
        default:
            _3013 <= _3012;
        endcase
    end
    assign _2981 = _2457[7:7];
    assign _2980 = _2457[6:6];
    assign _2979 = _2457[5:5];
    assign _2978 = _2457[4:4];
    assign _2977 = _2457[3:3];
    assign _2976 = _2457[2:2];
    assign _2975 = _2457[1:1];
    assign _2974 = _2457[0:0];
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
    assign _2973 = _24[0:0];
    assign _2970 = _521 - _2733;
    assign _2971 = { _527,
                     _2970 };
    assign _2972 = _2971 < _1678;
    assign _2983 = _2972 ? _2982 : _2973;
    assign _2965 = _2457[7:7];
    assign _2964 = _2457[6:6];
    assign _2963 = _2457[5:5];
    assign _2962 = _2457[4:4];
    assign _2961 = _2457[3:3];
    assign _2960 = _2457[2:2];
    assign _2959 = _2457[1:1];
    assign _2958 = _2457[0:0];
    always @* begin
        case (_2954)
        0:
            _2966 <= _2958;
        1:
            _2966 <= _2959;
        2:
            _2966 <= _2960;
        3:
            _2966 <= _2961;
        4:
            _2966 <= _2962;
        5:
            _2966 <= _2963;
        6:
            _2966 <= _2964;
        default:
            _2966 <= _2965;
        endcase
    end
    assign _2957 = _24[1:1];
    assign _2954 = _629 - _2733;
    assign _2955 = { _527,
                     _2954 };
    assign _2956 = _2955 < _1678;
    assign _2967 = _2956 ? _2966 : _2957;
    assign _2949 = _2457[7:7];
    assign _2948 = _2457[6:6];
    assign _2947 = _2457[5:5];
    assign _2946 = _2457[4:4];
    assign _2945 = _2457[3:3];
    assign _2944 = _2457[2:2];
    assign _2943 = _2457[1:1];
    assign _2942 = _2457[0:0];
    always @* begin
        case (_2938)
        0:
            _2950 <= _2942;
        1:
            _2950 <= _2943;
        2:
            _2950 <= _2944;
        3:
            _2950 <= _2945;
        4:
            _2950 <= _2946;
        5:
            _2950 <= _2947;
        6:
            _2950 <= _2948;
        default:
            _2950 <= _2949;
        endcase
    end
    assign _2941 = _24[2:2];
    assign _2938 = _3334 - _2733;
    assign _2939 = { _527,
                     _2938 };
    assign _2940 = _2939 < _1678;
    assign _2951 = _2940 ? _2950 : _2941;
    assign _2933 = _2457[7:7];
    assign _2932 = _2457[6:6];
    assign _2931 = _2457[5:5];
    assign _2930 = _2457[4:4];
    assign _2929 = _2457[3:3];
    assign _2928 = _2457[2:2];
    assign _2927 = _2457[1:1];
    assign _2926 = _2457[0:0];
    always @* begin
        case (_2922)
        0:
            _2934 <= _2926;
        1:
            _2934 <= _2927;
        2:
            _2934 <= _2928;
        3:
            _2934 <= _2929;
        4:
            _2934 <= _2930;
        5:
            _2934 <= _2931;
        6:
            _2934 <= _2932;
        default:
            _2934 <= _2933;
        endcase
    end
    assign _2925 = _24[3:3];
    assign _2922 = _3066 - _2733;
    assign _2923 = { _527,
                     _2922 };
    assign _2924 = _2923 < _1678;
    assign _2935 = _2924 ? _2934 : _2925;
    assign _2917 = _2457[7:7];
    assign _2916 = _2457[6:6];
    assign _2915 = _2457[5:5];
    assign _2914 = _2457[4:4];
    assign _2913 = _2457[3:3];
    assign _2912 = _2457[2:2];
    assign _2911 = _2457[1:1];
    assign _2910 = _2457[0:0];
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
    assign _2909 = _24[4:4];
    assign _2906 = _3476 - _2733;
    assign _2907 = { _527,
                     _2906 };
    assign _2908 = _2907 < _1678;
    assign _2919 = _2908 ? _2918 : _2909;
    assign _2901 = _2457[7:7];
    assign _2900 = _2457[6:6];
    assign _2899 = _2457[5:5];
    assign _2898 = _2457[4:4];
    assign _2897 = _2457[3:3];
    assign _2896 = _2457[2:2];
    assign _2895 = _2457[1:1];
    assign _2894 = _2457[0:0];
    always @* begin
        case (_2890)
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
    assign _2893 = _24[5:5];
    assign _2890 = _3032 - _2733;
    assign _2891 = { _527,
                     _2890 };
    assign _2892 = _2891 < _1678;
    assign _2903 = _2892 ? _2902 : _2893;
    assign _2885 = _2457[7:7];
    assign _2884 = _2457[6:6];
    assign _2883 = _2457[5:5];
    assign _2882 = _2457[4:4];
    assign _2881 = _2457[3:3];
    assign _2880 = _2457[2:2];
    assign _2879 = _2457[1:1];
    assign _2878 = _2457[0:0];
    always @* begin
        case (_2874)
        0:
            _2886 <= _2878;
        1:
            _2886 <= _2879;
        2:
            _2886 <= _2880;
        3:
            _2886 <= _2881;
        4:
            _2886 <= _2882;
        5:
            _2886 <= _2883;
        6:
            _2886 <= _2884;
        default:
            _2886 <= _2885;
        endcase
    end
    assign _2877 = _24[6:6];
    assign _2874 = _3015 - _2733;
    assign _2875 = { _527,
                     _2874 };
    assign _2876 = _2875 < _1678;
    assign _2887 = _2876 ? _2886 : _2877;
    assign _2869 = _2457[7:7];
    assign _2868 = _2457[6:6];
    assign _2867 = _2457[5:5];
    assign _2866 = _2457[4:4];
    assign _2865 = _2457[3:3];
    assign _2864 = _2457[2:2];
    assign _2863 = _2457[1:1];
    assign _2862 = _2457[0:0];
    always @* begin
        case (_2858)
        0:
            _2870 <= _2862;
        1:
            _2870 <= _2863;
        2:
            _2870 <= _2864;
        3:
            _2870 <= _2865;
        4:
            _2870 <= _2866;
        5:
            _2870 <= _2867;
        6:
            _2870 <= _2868;
        default:
            _2870 <= _2869;
        endcase
    end
    assign _2861 = _24[7:7];
    assign _2857 = 3'b111;
    assign _2858 = _2857 - _2733;
    assign _2859 = { _527,
                     _2858 };
    assign _2860 = _2859 < _1678;
    assign _2871 = _2860 ? _2870 : _2861;
    assign _2984 = { _2871,
                     _2887,
                     _2903,
                     _2919,
                     _2935,
                     _2951,
                     _2967,
                     _2983 };
    assign _2851 = _1748[7:7];
    assign _2850 = _1748[6:6];
    assign _2849 = _1748[5:5];
    assign _2848 = _1748[4:4];
    assign _2847 = _1748[3:3];
    assign _2846 = _1748[2:2];
    assign _2845 = _1748[1:1];
    assign _2844 = _1748[0:0];
    always @* begin
        case (_2840)
        0:
            _2852 <= _2844;
        1:
            _2852 <= _2845;
        2:
            _2852 <= _2846;
        3:
            _2852 <= _2847;
        4:
            _2852 <= _2848;
        5:
            _2852 <= _2849;
        6:
            _2852 <= _2850;
        default:
            _2852 <= _2851;
        endcase
    end
    assign _2843 = _24[0:0];
    assign _2840 = _521 - _2733;
    assign _2841 = { gnd,
                     _2840 };
    assign _2842 = _2841 < _2736;
    assign _2853 = _2842 ? _2852 : _2843;
    assign _2836 = _1748[7:7];
    assign _2835 = _1748[6:6];
    assign _2834 = _1748[5:5];
    assign _2833 = _1748[4:4];
    assign _2832 = _1748[3:3];
    assign _2831 = _1748[2:2];
    assign _2830 = _1748[1:1];
    assign _2829 = _1748[0:0];
    always @* begin
        case (_2825)
        0:
            _2837 <= _2829;
        1:
            _2837 <= _2830;
        2:
            _2837 <= _2831;
        3:
            _2837 <= _2832;
        4:
            _2837 <= _2833;
        5:
            _2837 <= _2834;
        6:
            _2837 <= _2835;
        default:
            _2837 <= _2836;
        endcase
    end
    assign _2828 = _24[1:1];
    assign _2825 = _629 - _2733;
    assign _2826 = { gnd,
                     _2825 };
    assign _2827 = _2826 < _2736;
    assign _2838 = _2827 ? _2837 : _2828;
    assign _2821 = _1748[7:7];
    assign _2820 = _1748[6:6];
    assign _2819 = _1748[5:5];
    assign _2818 = _1748[4:4];
    assign _2817 = _1748[3:3];
    assign _2816 = _1748[2:2];
    assign _2815 = _1748[1:1];
    assign _2814 = _1748[0:0];
    always @* begin
        case (_2810)
        0:
            _2822 <= _2814;
        1:
            _2822 <= _2815;
        2:
            _2822 <= _2816;
        3:
            _2822 <= _2817;
        4:
            _2822 <= _2818;
        5:
            _2822 <= _2819;
        6:
            _2822 <= _2820;
        default:
            _2822 <= _2821;
        endcase
    end
    assign _2813 = _24[2:2];
    assign _2810 = _3334 - _2733;
    assign _2811 = { gnd,
                     _2810 };
    assign _2812 = _2811 < _2736;
    assign _2823 = _2812 ? _2822 : _2813;
    assign _2806 = _1748[7:7];
    assign _2805 = _1748[6:6];
    assign _2804 = _1748[5:5];
    assign _2803 = _1748[4:4];
    assign _2802 = _1748[3:3];
    assign _2801 = _1748[2:2];
    assign _2800 = _1748[1:1];
    assign _2799 = _1748[0:0];
    always @* begin
        case (_2795)
        0:
            _2807 <= _2799;
        1:
            _2807 <= _2800;
        2:
            _2807 <= _2801;
        3:
            _2807 <= _2802;
        4:
            _2807 <= _2803;
        5:
            _2807 <= _2804;
        6:
            _2807 <= _2805;
        default:
            _2807 <= _2806;
        endcase
    end
    assign _2798 = _24[3:3];
    assign _2795 = _3066 - _2733;
    assign _2796 = { gnd,
                     _2795 };
    assign _2797 = _2796 < _2736;
    assign _2808 = _2797 ? _2807 : _2798;
    assign _2791 = _1748[7:7];
    assign _2790 = _1748[6:6];
    assign _2789 = _1748[5:5];
    assign _2788 = _1748[4:4];
    assign _2787 = _1748[3:3];
    assign _2786 = _1748[2:2];
    assign _2785 = _1748[1:1];
    assign _2784 = _1748[0:0];
    always @* begin
        case (_2780)
        0:
            _2792 <= _2784;
        1:
            _2792 <= _2785;
        2:
            _2792 <= _2786;
        3:
            _2792 <= _2787;
        4:
            _2792 <= _2788;
        5:
            _2792 <= _2789;
        6:
            _2792 <= _2790;
        default:
            _2792 <= _2791;
        endcase
    end
    assign _2783 = _24[4:4];
    assign _2780 = _3476 - _2733;
    assign _2781 = { gnd,
                     _2780 };
    assign _2782 = _2781 < _2736;
    assign _2793 = _2782 ? _2792 : _2783;
    assign _2776 = _1748[7:7];
    assign _2775 = _1748[6:6];
    assign _2774 = _1748[5:5];
    assign _2773 = _1748[4:4];
    assign _2772 = _1748[3:3];
    assign _2771 = _1748[2:2];
    assign _2770 = _1748[1:1];
    assign _2769 = _1748[0:0];
    always @* begin
        case (_2765)
        0:
            _2777 <= _2769;
        1:
            _2777 <= _2770;
        2:
            _2777 <= _2771;
        3:
            _2777 <= _2772;
        4:
            _2777 <= _2773;
        5:
            _2777 <= _2774;
        6:
            _2777 <= _2775;
        default:
            _2777 <= _2776;
        endcase
    end
    assign _2768 = _24[5:5];
    assign _2765 = _3032 - _2733;
    assign _2766 = { gnd,
                     _2765 };
    assign _2767 = _2766 < _2736;
    assign _2778 = _2767 ? _2777 : _2768;
    assign _2761 = _1748[7:7];
    assign _2760 = _1748[6:6];
    assign _2759 = _1748[5:5];
    assign _2758 = _1748[4:4];
    assign _2757 = _1748[3:3];
    assign _2756 = _1748[2:2];
    assign _2755 = _1748[1:1];
    assign _2754 = _1748[0:0];
    always @* begin
        case (_2750)
        0:
            _2762 <= _2754;
        1:
            _2762 <= _2755;
        2:
            _2762 <= _2756;
        3:
            _2762 <= _2757;
        4:
            _2762 <= _2758;
        5:
            _2762 <= _2759;
        6:
            _2762 <= _2760;
        default:
            _2762 <= _2761;
        endcase
    end
    assign _2753 = _24[6:6];
    assign _2750 = _3015 - _2733;
    assign _2751 = { gnd,
                     _2750 };
    assign _2752 = _2751 < _2736;
    assign _2763 = _2752 ? _2762 : _2753;
    assign _2746 = _1748[7:7];
    assign _2745 = _1748[6:6];
    assign _2744 = _1748[5:5];
    assign _2743 = _1748[4:4];
    assign _2742 = _1748[3:3];
    assign _2741 = _1748[2:2];
    assign _2740 = _1748[1:1];
    assign _2739 = _1748[0:0];
    always @* begin
        case (_2734)
        0:
            _2747 <= _2739;
        1:
            _2747 <= _2740;
        2:
            _2747 <= _2741;
        3:
            _2747 <= _2742;
        4:
            _2747 <= _2743;
        5:
            _2747 <= _2744;
        6:
            _2747 <= _2745;
        default:
            _2747 <= _2746;
        endcase
    end
    assign _2738 = _24[7:7];
    assign _2736 = cfg_t1_out_cfg[7:4];
    assign _498 = 8'b00010000;
    assign _827 = _592[7:0];
    assign _824 = 7'b1010010;
    assign _825 = _588 == _824;
    assign _823 = _582 & _586;
    assign _826 = _823 & _825;
    assign _828 = _826 ? _827 : cfg_t1_out_cfg;
    assign _19 = _828;
    always @(posedge _106) begin
        if (_104)
            cfg_t1_out_cfg <= _498;
        else
            cfg_t1_out_cfg <= _19;
    end
    assign _2733 = cfg_t1_out_cfg[2:0];
    assign _2734 = _2857 - _2733;
    assign _2735 = { gnd,
                     _2734 };
    assign _2737 = _2735 < _2736;
    assign _2748 = _2737 ? _2747 : _2738;
    assign _2854 = { _2748,
                     _2763,
                     _2778,
                     _2793,
                     _2808,
                     _2823,
                     _2838,
                     _2853 };
    assign _2727 = _2415[7:7];
    assign _2726 = _2415[6:6];
    assign _2725 = _2415[5:5];
    assign _2724 = _2415[4:4];
    assign _2723 = _2415[3:3];
    assign _2722 = _2415[2:2];
    assign _2721 = _2415[1:1];
    assign _2720 = _2415[0:0];
    always @* begin
        case (_2716)
        0:
            _2728 <= _2720;
        1:
            _2728 <= _2721;
        2:
            _2728 <= _2722;
        3:
            _2728 <= _2723;
        4:
            _2728 <= _2724;
        5:
            _2728 <= _2725;
        6:
            _2728 <= _2726;
        default:
            _2728 <= _2727;
        endcase
    end
    assign _2719 = _24[0:0];
    assign _2716 = _521 - _2609;
    assign _2717 = { gnd,
                     _2716 };
    assign _2718 = _2717 < _2612;
    assign _2729 = _2718 ? _2728 : _2719;
    assign _2712 = _2415[7:7];
    assign _2711 = _2415[6:6];
    assign _2710 = _2415[5:5];
    assign _2709 = _2415[4:4];
    assign _2708 = _2415[3:3];
    assign _2707 = _2415[2:2];
    assign _2706 = _2415[1:1];
    assign _2705 = _2415[0:0];
    always @* begin
        case (_2701)
        0:
            _2713 <= _2705;
        1:
            _2713 <= _2706;
        2:
            _2713 <= _2707;
        3:
            _2713 <= _2708;
        4:
            _2713 <= _2709;
        5:
            _2713 <= _2710;
        6:
            _2713 <= _2711;
        default:
            _2713 <= _2712;
        endcase
    end
    assign _2704 = _24[1:1];
    assign _2701 = _629 - _2609;
    assign _2702 = { gnd,
                     _2701 };
    assign _2703 = _2702 < _2612;
    assign _2714 = _2703 ? _2713 : _2704;
    assign _2697 = _2415[7:7];
    assign _2696 = _2415[6:6];
    assign _2695 = _2415[5:5];
    assign _2694 = _2415[4:4];
    assign _2693 = _2415[3:3];
    assign _2692 = _2415[2:2];
    assign _2691 = _2415[1:1];
    assign _2690 = _2415[0:0];
    always @* begin
        case (_2686)
        0:
            _2698 <= _2690;
        1:
            _2698 <= _2691;
        2:
            _2698 <= _2692;
        3:
            _2698 <= _2693;
        4:
            _2698 <= _2694;
        5:
            _2698 <= _2695;
        6:
            _2698 <= _2696;
        default:
            _2698 <= _2697;
        endcase
    end
    assign _2689 = _24[2:2];
    assign _2686 = _3334 - _2609;
    assign _2687 = { gnd,
                     _2686 };
    assign _2688 = _2687 < _2612;
    assign _2699 = _2688 ? _2698 : _2689;
    assign _2682 = _2415[7:7];
    assign _2681 = _2415[6:6];
    assign _2680 = _2415[5:5];
    assign _2679 = _2415[4:4];
    assign _2678 = _2415[3:3];
    assign _2677 = _2415[2:2];
    assign _2676 = _2415[1:1];
    assign _2675 = _2415[0:0];
    always @* begin
        case (_2671)
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
    assign _2674 = _24[3:3];
    assign _2671 = _3066 - _2609;
    assign _2672 = { gnd,
                     _2671 };
    assign _2673 = _2672 < _2612;
    assign _2684 = _2673 ? _2683 : _2674;
    assign _2667 = _2415[7:7];
    assign _2666 = _2415[6:6];
    assign _2665 = _2415[5:5];
    assign _2664 = _2415[4:4];
    assign _2663 = _2415[3:3];
    assign _2662 = _2415[2:2];
    assign _2661 = _2415[1:1];
    assign _2660 = _2415[0:0];
    always @* begin
        case (_2656)
        0:
            _2668 <= _2660;
        1:
            _2668 <= _2661;
        2:
            _2668 <= _2662;
        3:
            _2668 <= _2663;
        4:
            _2668 <= _2664;
        5:
            _2668 <= _2665;
        6:
            _2668 <= _2666;
        default:
            _2668 <= _2667;
        endcase
    end
    assign _2659 = _24[4:4];
    assign _2656 = _3476 - _2609;
    assign _2657 = { gnd,
                     _2656 };
    assign _2658 = _2657 < _2612;
    assign _2669 = _2658 ? _2668 : _2659;
    assign _2652 = _2415[7:7];
    assign _2651 = _2415[6:6];
    assign _2650 = _2415[5:5];
    assign _2649 = _2415[4:4];
    assign _2648 = _2415[3:3];
    assign _2647 = _2415[2:2];
    assign _2646 = _2415[1:1];
    assign _2645 = _2415[0:0];
    always @* begin
        case (_2641)
        0:
            _2653 <= _2645;
        1:
            _2653 <= _2646;
        2:
            _2653 <= _2647;
        3:
            _2653 <= _2648;
        4:
            _2653 <= _2649;
        5:
            _2653 <= _2650;
        6:
            _2653 <= _2651;
        default:
            _2653 <= _2652;
        endcase
    end
    assign _2644 = _24[5:5];
    assign _2641 = _3032 - _2609;
    assign _2642 = { gnd,
                     _2641 };
    assign _2643 = _2642 < _2612;
    assign _2654 = _2643 ? _2653 : _2644;
    assign _2637 = _2415[7:7];
    assign _2636 = _2415[6:6];
    assign _2635 = _2415[5:5];
    assign _2634 = _2415[4:4];
    assign _2633 = _2415[3:3];
    assign _2632 = _2415[2:2];
    assign _2631 = _2415[1:1];
    assign _2630 = _2415[0:0];
    always @* begin
        case (_2626)
        0:
            _2638 <= _2630;
        1:
            _2638 <= _2631;
        2:
            _2638 <= _2632;
        3:
            _2638 <= _2633;
        4:
            _2638 <= _2634;
        5:
            _2638 <= _2635;
        6:
            _2638 <= _2636;
        default:
            _2638 <= _2637;
        endcase
    end
    assign _2629 = _24[6:6];
    assign _2626 = _3015 - _2609;
    assign _2627 = { gnd,
                     _2626 };
    assign _2628 = _2627 < _2612;
    assign _2639 = _2628 ? _2638 : _2629;
    assign _2622 = _2415[7:7];
    assign _2621 = _2415[6:6];
    assign _2620 = _2415[5:5];
    assign _2619 = _2415[4:4];
    assign _2618 = _2415[3:3];
    assign _2617 = _2415[2:2];
    assign _2616 = _2415[1:1];
    assign _2615 = _2415[0:0];
    always @* begin
        case (_2610)
        0:
            _2623 <= _2615;
        1:
            _2623 <= _2616;
        2:
            _2623 <= _2617;
        3:
            _2623 <= _2618;
        4:
            _2623 <= _2619;
        5:
            _2623 <= _2620;
        6:
            _2623 <= _2621;
        default:
            _2623 <= _2622;
        endcase
    end
    assign _2614 = _24[7:7];
    assign _2612 = cfg_t1_set_cfg[7:4];
    assign _833 = _592[7:0];
    assign _830 = 7'b1010011;
    assign _831 = _588 == _830;
    assign _829 = _582 & _586;
    assign _832 = _829 & _831;
    assign _834 = _832 ? _833 : cfg_t1_set_cfg;
    assign _20 = _834;
    always @(posedge _106) begin
        if (_104)
            cfg_t1_set_cfg <= _498;
        else
            cfg_t1_set_cfg <= _20;
    end
    assign _2609 = cfg_t1_set_cfg[2:0];
    assign _2610 = _2857 - _2609;
    assign _2611 = { gnd,
                     _2610 };
    assign _2613 = _2611 < _2612;
    assign _2624 = _2613 ? _2623 : _2614;
    assign _2730 = { _2624,
                     _2639,
                     _2654,
                     _2669,
                     _2684,
                     _2699,
                     _2714,
                     _2729 };
    assign _1483 = _1356[7:7];
    assign _1482 = _1356[6:6];
    assign _1481 = _1356[5:5];
    assign _1480 = _1356[4:4];
    assign _1479 = _1356[3:3];
    assign _1478 = _1356[2:2];
    assign _1477 = _1356[1:1];
    assign _1476 = _1356[0:0];
    always @* begin
        case (_1470)
        0:
            _1484 <= _1476;
        1:
            _1484 <= _1477;
        2:
            _1484 <= _1478;
        3:
            _1484 <= _1479;
        4:
            _1484 <= _1480;
        5:
            _1484 <= _1481;
        6:
            _1484 <= _1482;
        default:
            _1484 <= _1483;
        endcase
    end
    assign _1475 = _1336[0:0];
    assign _1473 = { _527,
                     _858 };
    assign _1470 = _521 - _854;
    assign _1471 = { gnd,
                     _1470 };
    assign _1474 = _1471 < _1473;
    assign _1485 = _1474 ? _1484 : _1475;
    assign _1466 = _1356[7:7];
    assign _1465 = _1356[6:6];
    assign _1464 = _1356[5:5];
    assign _1463 = _1356[4:4];
    assign _1462 = _1356[3:3];
    assign _1461 = _1356[2:2];
    assign _1460 = _1356[1:1];
    assign _1459 = _1356[0:0];
    always @* begin
        case (_1453)
        0:
            _1467 <= _1459;
        1:
            _1467 <= _1460;
        2:
            _1467 <= _1461;
        3:
            _1467 <= _1462;
        4:
            _1467 <= _1463;
        5:
            _1467 <= _1464;
        6:
            _1467 <= _1465;
        default:
            _1467 <= _1466;
        endcase
    end
    assign _1458 = _1336[1:1];
    assign _1456 = { _527,
                     _858 };
    assign _1453 = _629 - _854;
    assign _1454 = { gnd,
                     _1453 };
    assign _1457 = _1454 < _1456;
    assign _1468 = _1457 ? _1467 : _1458;
    assign _1449 = _1356[7:7];
    assign _1448 = _1356[6:6];
    assign _1447 = _1356[5:5];
    assign _1446 = _1356[4:4];
    assign _1445 = _1356[3:3];
    assign _1444 = _1356[2:2];
    assign _1443 = _1356[1:1];
    assign _1442 = _1356[0:0];
    always @* begin
        case (_1436)
        0:
            _1450 <= _1442;
        1:
            _1450 <= _1443;
        2:
            _1450 <= _1444;
        3:
            _1450 <= _1445;
        4:
            _1450 <= _1446;
        5:
            _1450 <= _1447;
        6:
            _1450 <= _1448;
        default:
            _1450 <= _1449;
        endcase
    end
    assign _1441 = _1336[2:2];
    assign _1439 = { _527,
                     _858 };
    assign _1436 = _3334 - _854;
    assign _1437 = { gnd,
                     _1436 };
    assign _1440 = _1437 < _1439;
    assign _1451 = _1440 ? _1450 : _1441;
    assign _1432 = _1356[7:7];
    assign _1431 = _1356[6:6];
    assign _1430 = _1356[5:5];
    assign _1429 = _1356[4:4];
    assign _1428 = _1356[3:3];
    assign _1427 = _1356[2:2];
    assign _1426 = _1356[1:1];
    assign _1425 = _1356[0:0];
    always @* begin
        case (_1419)
        0:
            _1433 <= _1425;
        1:
            _1433 <= _1426;
        2:
            _1433 <= _1427;
        3:
            _1433 <= _1428;
        4:
            _1433 <= _1429;
        5:
            _1433 <= _1430;
        6:
            _1433 <= _1431;
        default:
            _1433 <= _1432;
        endcase
    end
    assign _1424 = _1336[3:3];
    assign _1422 = { _527,
                     _858 };
    assign _1419 = _3066 - _854;
    assign _1420 = { gnd,
                     _1419 };
    assign _1423 = _1420 < _1422;
    assign _1434 = _1423 ? _1433 : _1424;
    assign _1415 = _1356[7:7];
    assign _1414 = _1356[6:6];
    assign _1413 = _1356[5:5];
    assign _1412 = _1356[4:4];
    assign _1411 = _1356[3:3];
    assign _1410 = _1356[2:2];
    assign _1409 = _1356[1:1];
    assign _1408 = _1356[0:0];
    always @* begin
        case (_1402)
        0:
            _1416 <= _1408;
        1:
            _1416 <= _1409;
        2:
            _1416 <= _1410;
        3:
            _1416 <= _1411;
        4:
            _1416 <= _1412;
        5:
            _1416 <= _1413;
        6:
            _1416 <= _1414;
        default:
            _1416 <= _1415;
        endcase
    end
    assign _1407 = _1336[4:4];
    assign _1405 = { _527,
                     _858 };
    assign _1402 = _3476 - _854;
    assign _1403 = { gnd,
                     _1402 };
    assign _1406 = _1403 < _1405;
    assign _1417 = _1406 ? _1416 : _1407;
    assign _1398 = _1356[7:7];
    assign _1397 = _1356[6:6];
    assign _1396 = _1356[5:5];
    assign _1395 = _1356[4:4];
    assign _1394 = _1356[3:3];
    assign _1393 = _1356[2:2];
    assign _1392 = _1356[1:1];
    assign _1391 = _1356[0:0];
    always @* begin
        case (_1385)
        0:
            _1399 <= _1391;
        1:
            _1399 <= _1392;
        2:
            _1399 <= _1393;
        3:
            _1399 <= _1394;
        4:
            _1399 <= _1395;
        5:
            _1399 <= _1396;
        6:
            _1399 <= _1397;
        default:
            _1399 <= _1398;
        endcase
    end
    assign _1390 = _1336[5:5];
    assign _1388 = { _527,
                     _858 };
    assign _1385 = _3032 - _854;
    assign _1386 = { gnd,
                     _1385 };
    assign _1389 = _1386 < _1388;
    assign _1400 = _1389 ? _1399 : _1390;
    assign _1381 = _1356[7:7];
    assign _1380 = _1356[6:6];
    assign _1379 = _1356[5:5];
    assign _1378 = _1356[4:4];
    assign _1377 = _1356[3:3];
    assign _1376 = _1356[2:2];
    assign _1375 = _1356[1:1];
    assign _1374 = _1356[0:0];
    always @* begin
        case (_1368)
        0:
            _1382 <= _1374;
        1:
            _1382 <= _1375;
        2:
            _1382 <= _1376;
        3:
            _1382 <= _1377;
        4:
            _1382 <= _1378;
        5:
            _1382 <= _1379;
        6:
            _1382 <= _1380;
        default:
            _1382 <= _1381;
        endcase
    end
    assign _1373 = _1336[6:6];
    assign _1371 = { _527,
                     _858 };
    assign _1368 = _3015 - _854;
    assign _1369 = { gnd,
                     _1368 };
    assign _1372 = _1369 < _1371;
    assign _1383 = _1372 ? _1382 : _1373;
    assign _1364 = _1356[7:7];
    assign _1363 = _1356[6:6];
    assign _1362 = _1356[5:5];
    assign _1361 = _1356[4:4];
    assign _1360 = _1356[3:3];
    assign _1359 = _1356[2:2];
    assign _1358 = _1356[1:1];
    assign _1351 = _1349[3:2];
    assign _1352 = { _527,
                     _1351 };
    assign _1347 = _1345[3:1];
    assign _1348 = { _576,
                     _1347 };
    assign _1345 = _92[12:9];
    assign _1344 = _1341[0:0];
    assign _1349 = _1344 ? _1348 : _1345;
    assign _1343 = _1341[1:1];
    assign _1353 = _1343 ? _1352 : _1349;
    assign _1340 = { gnd,
                     _858 };
    assign _1341 = _3476 - _1340;
    assign _1342 = _1341[2:2];
    assign _1355 = _1342 ? _308 : _1353;
    assign _1356 = { _308,
                     _1355 };
    assign _1357 = _1356[0:0];
    always @* begin
        case (_855)
        0:
            _1365 <= _1357;
        1:
            _1365 <= _1358;
        2:
            _1365 <= _1359;
        3:
            _1365 <= _1360;
        4:
            _1365 <= _1361;
        5:
            _1365 <= _1362;
        6:
            _1365 <= _1363;
        default:
            _1365 <= _1364;
        endcase
    end
    assign _1332 = _1212[7:7];
    assign _1331 = _1212[6:6];
    assign _1330 = _1212[5:5];
    assign _1329 = _1212[4:4];
    assign _1328 = _1212[3:3];
    assign _1327 = _1212[2:2];
    assign _1326 = _1212[1:1];
    assign _1325 = _1212[0:0];
    always @* begin
        case (_1321)
        0:
            _1333 <= _1325;
        1:
            _1333 <= _1326;
        2:
            _1333 <= _1327;
        3:
            _1333 <= _1328;
        4:
            _1333 <= _1329;
        5:
            _1333 <= _1330;
        6:
            _1333 <= _1331;
        default:
            _1333 <= _1332;
        endcase
    end
    assign _1324 = pin_out[0:0];
    assign _1321 = _521 - _1009;
    assign _1322 = { _527,
                     _1321 };
    assign _1323 = _1322 < _811;
    assign _1334 = _1323 ? _1333 : _1324;
    assign _1316 = _1212[7:7];
    assign _1315 = _1212[6:6];
    assign _1314 = _1212[5:5];
    assign _1313 = _1212[4:4];
    assign _1312 = _1212[3:3];
    assign _1311 = _1212[2:2];
    assign _1310 = _1212[1:1];
    assign _1309 = _1212[0:0];
    always @* begin
        case (_1305)
        0:
            _1317 <= _1309;
        1:
            _1317 <= _1310;
        2:
            _1317 <= _1311;
        3:
            _1317 <= _1312;
        4:
            _1317 <= _1313;
        5:
            _1317 <= _1314;
        6:
            _1317 <= _1315;
        default:
            _1317 <= _1316;
        endcase
    end
    assign _1308 = pin_out[1:1];
    assign _1305 = _629 - _1009;
    assign _1306 = { _527,
                     _1305 };
    assign _1307 = _1306 < _811;
    assign _1318 = _1307 ? _1317 : _1308;
    assign _1300 = _1212[7:7];
    assign _1299 = _1212[6:6];
    assign _1298 = _1212[5:5];
    assign _1297 = _1212[4:4];
    assign _1296 = _1212[3:3];
    assign _1295 = _1212[2:2];
    assign _1294 = _1212[1:1];
    assign _1293 = _1212[0:0];
    always @* begin
        case (_1289)
        0:
            _1301 <= _1293;
        1:
            _1301 <= _1294;
        2:
            _1301 <= _1295;
        3:
            _1301 <= _1296;
        4:
            _1301 <= _1297;
        5:
            _1301 <= _1298;
        6:
            _1301 <= _1299;
        default:
            _1301 <= _1300;
        endcase
    end
    assign _1292 = pin_out[2:2];
    assign _1289 = _3334 - _1009;
    assign _1290 = { _527,
                     _1289 };
    assign _1291 = _1290 < _811;
    assign _1302 = _1291 ? _1301 : _1292;
    assign _1284 = _1212[7:7];
    assign _1283 = _1212[6:6];
    assign _1282 = _1212[5:5];
    assign _1281 = _1212[4:4];
    assign _1280 = _1212[3:3];
    assign _1279 = _1212[2:2];
    assign _1278 = _1212[1:1];
    assign _1277 = _1212[0:0];
    always @* begin
        case (_1273)
        0:
            _1285 <= _1277;
        1:
            _1285 <= _1278;
        2:
            _1285 <= _1279;
        3:
            _1285 <= _1280;
        4:
            _1285 <= _1281;
        5:
            _1285 <= _1282;
        6:
            _1285 <= _1283;
        default:
            _1285 <= _1284;
        endcase
    end
    assign _1276 = pin_out[3:3];
    assign _1273 = _3066 - _1009;
    assign _1274 = { _527,
                     _1273 };
    assign _1275 = _1274 < _811;
    assign _1286 = _1275 ? _1285 : _1276;
    assign _1268 = _1212[7:7];
    assign _1267 = _1212[6:6];
    assign _1266 = _1212[5:5];
    assign _1265 = _1212[4:4];
    assign _1264 = _1212[3:3];
    assign _1263 = _1212[2:2];
    assign _1262 = _1212[1:1];
    assign _1261 = _1212[0:0];
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
    assign _1260 = pin_out[4:4];
    assign _1257 = _3476 - _1009;
    assign _1258 = { _527,
                     _1257 };
    assign _1259 = _1258 < _811;
    assign _1270 = _1259 ? _1269 : _1260;
    assign _1252 = _1212[7:7];
    assign _1251 = _1212[6:6];
    assign _1250 = _1212[5:5];
    assign _1249 = _1212[4:4];
    assign _1248 = _1212[3:3];
    assign _1247 = _1212[2:2];
    assign _1246 = _1212[1:1];
    assign _1245 = _1212[0:0];
    always @* begin
        case (_1241)
        0:
            _1253 <= _1245;
        1:
            _1253 <= _1246;
        2:
            _1253 <= _1247;
        3:
            _1253 <= _1248;
        4:
            _1253 <= _1249;
        5:
            _1253 <= _1250;
        6:
            _1253 <= _1251;
        default:
            _1253 <= _1252;
        endcase
    end
    assign _1244 = pin_out[5:5];
    assign _1241 = _3032 - _1009;
    assign _1242 = { _527,
                     _1241 };
    assign _1243 = _1242 < _811;
    assign _1254 = _1243 ? _1253 : _1244;
    assign _1236 = _1212[7:7];
    assign _1235 = _1212[6:6];
    assign _1234 = _1212[5:5];
    assign _1233 = _1212[4:4];
    assign _1232 = _1212[3:3];
    assign _1231 = _1212[2:2];
    assign _1230 = _1212[1:1];
    assign _1229 = _1212[0:0];
    always @* begin
        case (_1225)
        0:
            _1237 <= _1229;
        1:
            _1237 <= _1230;
        2:
            _1237 <= _1231;
        3:
            _1237 <= _1232;
        4:
            _1237 <= _1233;
        5:
            _1237 <= _1234;
        6:
            _1237 <= _1235;
        default:
            _1237 <= _1236;
        endcase
    end
    assign _1228 = pin_out[6:6];
    assign _1225 = _3015 - _1009;
    assign _1226 = { _527,
                     _1225 };
    assign _1227 = _1226 < _811;
    assign _1238 = _1227 ? _1237 : _1228;
    assign _1220 = _1212[7:7];
    assign _1219 = _1212[6:6];
    assign _1218 = _1212[5:5];
    assign _1217 = _1212[4:4];
    assign _1216 = _1212[3:3];
    assign _1215 = _1212[2:2];
    assign _1214 = _1212[1:1];
    assign _1213 = _1212[0:0];
    always @* begin
        case (_1150)
        0:
            _1221 <= _1213;
        1:
            _1221 <= _1214;
        2:
            _1221 <= _1215;
        3:
            _1221 <= _1216;
        4:
            _1221 <= _1217;
        5:
            _1221 <= _1218;
        6:
            _1221 <= _1219;
        default:
            _1221 <= _1220;
        endcase
    end
    assign _1153 = pin_out[7:7];
    assign _1150 = _2857 - _1009;
    assign _1151 = { _527,
                     _1150 };
    assign _1152 = _1151 < _811;
    assign _1222 = _1152 ? _1221 : _1153;
    assign _1335 = { _1222,
                     _1238,
                     _1254,
                     _1270,
                     _1286,
                     _1302,
                     _1318,
                     _1334 };
    assign _1143 = _1030[7:7];
    assign _1142 = _1030[6:6];
    assign _1141 = _1030[5:5];
    assign _1140 = _1030[4:4];
    assign _1139 = _1030[3:3];
    assign _1138 = _1030[2:2];
    assign _1137 = _1030[1:1];
    assign _1136 = _1030[0:0];
    always @* begin
        case (_1132)
        0:
            _1144 <= _1136;
        1:
            _1144 <= _1137;
        2:
            _1144 <= _1138;
        3:
            _1144 <= _1139;
        4:
            _1144 <= _1140;
        5:
            _1144 <= _1141;
        6:
            _1144 <= _1142;
        default:
            _1144 <= _1143;
        endcase
    end
    assign _1135 = pin_out[0:0];
    assign _1132 = _521 - _1009;
    assign _1133 = { gnd,
                     _1132 };
    assign _1134 = _1133 < _1012;
    assign _1145 = _1134 ? _1144 : _1135;
    assign _1128 = _1030[7:7];
    assign _1127 = _1030[6:6];
    assign _1126 = _1030[5:5];
    assign _1125 = _1030[4:4];
    assign _1124 = _1030[3:3];
    assign _1123 = _1030[2:2];
    assign _1122 = _1030[1:1];
    assign _1121 = _1030[0:0];
    always @* begin
        case (_1117)
        0:
            _1129 <= _1121;
        1:
            _1129 <= _1122;
        2:
            _1129 <= _1123;
        3:
            _1129 <= _1124;
        4:
            _1129 <= _1125;
        5:
            _1129 <= _1126;
        6:
            _1129 <= _1127;
        default:
            _1129 <= _1128;
        endcase
    end
    assign _1120 = pin_out[1:1];
    assign _1117 = _629 - _1009;
    assign _1118 = { gnd,
                     _1117 };
    assign _1119 = _1118 < _1012;
    assign _1130 = _1119 ? _1129 : _1120;
    assign _1113 = _1030[7:7];
    assign _1112 = _1030[6:6];
    assign _1111 = _1030[5:5];
    assign _1110 = _1030[4:4];
    assign _1109 = _1030[3:3];
    assign _1108 = _1030[2:2];
    assign _1107 = _1030[1:1];
    assign _1106 = _1030[0:0];
    always @* begin
        case (_1102)
        0:
            _1114 <= _1106;
        1:
            _1114 <= _1107;
        2:
            _1114 <= _1108;
        3:
            _1114 <= _1109;
        4:
            _1114 <= _1110;
        5:
            _1114 <= _1111;
        6:
            _1114 <= _1112;
        default:
            _1114 <= _1113;
        endcase
    end
    assign _1105 = pin_out[2:2];
    assign _1102 = _3334 - _1009;
    assign _1103 = { gnd,
                     _1102 };
    assign _1104 = _1103 < _1012;
    assign _1115 = _1104 ? _1114 : _1105;
    assign _1098 = _1030[7:7];
    assign _1097 = _1030[6:6];
    assign _1096 = _1030[5:5];
    assign _1095 = _1030[4:4];
    assign _1094 = _1030[3:3];
    assign _1093 = _1030[2:2];
    assign _1092 = _1030[1:1];
    assign _1091 = _1030[0:0];
    always @* begin
        case (_1087)
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
    assign _1090 = pin_out[3:3];
    assign _1087 = _3066 - _1009;
    assign _1088 = { gnd,
                     _1087 };
    assign _1089 = _1088 < _1012;
    assign _1100 = _1089 ? _1099 : _1090;
    assign _1083 = _1030[7:7];
    assign _1082 = _1030[6:6];
    assign _1081 = _1030[5:5];
    assign _1080 = _1030[4:4];
    assign _1079 = _1030[3:3];
    assign _1078 = _1030[2:2];
    assign _1077 = _1030[1:1];
    assign _1076 = _1030[0:0];
    always @* begin
        case (_1072)
        0:
            _1084 <= _1076;
        1:
            _1084 <= _1077;
        2:
            _1084 <= _1078;
        3:
            _1084 <= _1079;
        4:
            _1084 <= _1080;
        5:
            _1084 <= _1081;
        6:
            _1084 <= _1082;
        default:
            _1084 <= _1083;
        endcase
    end
    assign _1075 = pin_out[4:4];
    assign _1072 = _3476 - _1009;
    assign _1073 = { gnd,
                     _1072 };
    assign _1074 = _1073 < _1012;
    assign _1085 = _1074 ? _1084 : _1075;
    assign _1068 = _1030[7:7];
    assign _1067 = _1030[6:6];
    assign _1066 = _1030[5:5];
    assign _1065 = _1030[4:4];
    assign _1064 = _1030[3:3];
    assign _1063 = _1030[2:2];
    assign _1062 = _1030[1:1];
    assign _1061 = _1030[0:0];
    always @* begin
        case (_1057)
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
    assign _1060 = pin_out[5:5];
    assign _1057 = _3032 - _1009;
    assign _1058 = { gnd,
                     _1057 };
    assign _1059 = _1058 < _1012;
    assign _1070 = _1059 ? _1069 : _1060;
    assign _1053 = _1030[7:7];
    assign _1052 = _1030[6:6];
    assign _1051 = _1030[5:5];
    assign _1050 = _1030[4:4];
    assign _1049 = _1030[3:3];
    assign _1048 = _1030[2:2];
    assign _1047 = _1030[1:1];
    assign _1046 = _1030[0:0];
    always @* begin
        case (_1042)
        0:
            _1054 <= _1046;
        1:
            _1054 <= _1047;
        2:
            _1054 <= _1048;
        3:
            _1054 <= _1049;
        4:
            _1054 <= _1050;
        5:
            _1054 <= _1051;
        6:
            _1054 <= _1052;
        default:
            _1054 <= _1053;
        endcase
    end
    assign _1045 = pin_out[6:6];
    assign _1042 = _3015 - _1009;
    assign _1043 = { gnd,
                     _1042 };
    assign _1044 = _1043 < _1012;
    assign _1055 = _1044 ? _1054 : _1045;
    assign _1038 = _1030[7:7];
    assign _1037 = _1030[6:6];
    assign _1036 = _1030[5:5];
    assign _1035 = _1030[4:4];
    assign _1034 = _1030[3:3];
    assign _1033 = _1030[2:2];
    assign _1032 = _1030[1:1];
    assign _1031 = _1030[0:0];
    always @* begin
        case (_1010)
        0:
            _1039 <= _1031;
        1:
            _1039 <= _1032;
        2:
            _1039 <= _1033;
        3:
            _1039 <= _1034;
        4:
            _1039 <= _1035;
        5:
            _1039 <= _1036;
        6:
            _1039 <= _1037;
        default:
            _1039 <= _1038;
        endcase
    end
    assign _1014 = pin_out[7:7];
    assign _1012 = cfg_t0_out_cfg[7:4];
    assign _839 = _592[7:0];
    assign _836 = 7'b1000010;
    assign _837 = _588 == _836;
    assign _835 = _582 & _586;
    assign _838 = _835 & _837;
    assign _840 = _838 ? _839 : cfg_t0_out_cfg;
    assign _21 = _840;
    always @(posedge _106) begin
        if (_104)
            cfg_t0_out_cfg <= _498;
        else
            cfg_t0_out_cfg <= _21;
    end
    assign _1009 = cfg_t0_out_cfg[2:0];
    assign _1010 = _2857 - _1009;
    assign _1011 = { gnd,
                     _1010 };
    assign _1013 = _1011 < _1012;
    assign _1040 = _1013 ? _1039 : _1014;
    assign _1146 = { _1040,
                     _1055,
                     _1070,
                     _1085,
                     _1100,
                     _1115,
                     _1130,
                     _1145 };
    assign _1003 = _890[7:7];
    assign _1002 = _890[6:6];
    assign _1001 = _890[5:5];
    assign _1000 = _890[4:4];
    assign _999 = _890[3:3];
    assign _998 = _890[2:2];
    assign _997 = _890[1:1];
    assign _996 = _890[0:0];
    always @* begin
        case (_992)
        0:
            _1004 <= _996;
        1:
            _1004 <= _997;
        2:
            _1004 <= _998;
        3:
            _1004 <= _999;
        4:
            _1004 <= _1000;
        5:
            _1004 <= _1001;
        6:
            _1004 <= _1002;
        default:
            _1004 <= _1003;
        endcase
    end
    assign _995 = pin_out[0:0];
    assign _992 = _521 - _882;
    assign _993 = { gnd,
                    _992 };
    assign _994 = _993 < _885;
    assign _1005 = _994 ? _1004 : _995;
    assign _988 = _890[7:7];
    assign _987 = _890[6:6];
    assign _986 = _890[5:5];
    assign _985 = _890[4:4];
    assign _984 = _890[3:3];
    assign _983 = _890[2:2];
    assign _982 = _890[1:1];
    assign _981 = _890[0:0];
    always @* begin
        case (_977)
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
    assign _980 = pin_out[1:1];
    assign _977 = _629 - _882;
    assign _978 = { gnd,
                    _977 };
    assign _979 = _978 < _885;
    assign _990 = _979 ? _989 : _980;
    assign _973 = _890[7:7];
    assign _972 = _890[6:6];
    assign _971 = _890[5:5];
    assign _970 = _890[4:4];
    assign _969 = _890[3:3];
    assign _968 = _890[2:2];
    assign _967 = _890[1:1];
    assign _966 = _890[0:0];
    always @* begin
        case (_962)
        0:
            _974 <= _966;
        1:
            _974 <= _967;
        2:
            _974 <= _968;
        3:
            _974 <= _969;
        4:
            _974 <= _970;
        5:
            _974 <= _971;
        6:
            _974 <= _972;
        default:
            _974 <= _973;
        endcase
    end
    assign _965 = pin_out[2:2];
    assign _962 = _3334 - _882;
    assign _963 = { gnd,
                    _962 };
    assign _964 = _963 < _885;
    assign _975 = _964 ? _974 : _965;
    assign _958 = _890[7:7];
    assign _957 = _890[6:6];
    assign _956 = _890[5:5];
    assign _955 = _890[4:4];
    assign _954 = _890[3:3];
    assign _953 = _890[2:2];
    assign _952 = _890[1:1];
    assign _951 = _890[0:0];
    always @* begin
        case (_947)
        0:
            _959 <= _951;
        1:
            _959 <= _952;
        2:
            _959 <= _953;
        3:
            _959 <= _954;
        4:
            _959 <= _955;
        5:
            _959 <= _956;
        6:
            _959 <= _957;
        default:
            _959 <= _958;
        endcase
    end
    assign _950 = pin_out[3:3];
    assign _947 = _3066 - _882;
    assign _948 = { gnd,
                    _947 };
    assign _949 = _948 < _885;
    assign _960 = _949 ? _959 : _950;
    assign _943 = _890[7:7];
    assign _942 = _890[6:6];
    assign _941 = _890[5:5];
    assign _940 = _890[4:4];
    assign _939 = _890[3:3];
    assign _938 = _890[2:2];
    assign _937 = _890[1:1];
    assign _936 = _890[0:0];
    always @* begin
        case (_932)
        0:
            _944 <= _936;
        1:
            _944 <= _937;
        2:
            _944 <= _938;
        3:
            _944 <= _939;
        4:
            _944 <= _940;
        5:
            _944 <= _941;
        6:
            _944 <= _942;
        default:
            _944 <= _943;
        endcase
    end
    assign _935 = pin_out[4:4];
    assign _932 = _3476 - _882;
    assign _933 = { gnd,
                    _932 };
    assign _934 = _933 < _885;
    assign _945 = _934 ? _944 : _935;
    assign _928 = _890[7:7];
    assign _927 = _890[6:6];
    assign _926 = _890[5:5];
    assign _925 = _890[4:4];
    assign _924 = _890[3:3];
    assign _923 = _890[2:2];
    assign _922 = _890[1:1];
    assign _921 = _890[0:0];
    always @* begin
        case (_917)
        0:
            _929 <= _921;
        1:
            _929 <= _922;
        2:
            _929 <= _923;
        3:
            _929 <= _924;
        4:
            _929 <= _925;
        5:
            _929 <= _926;
        6:
            _929 <= _927;
        default:
            _929 <= _928;
        endcase
    end
    assign _920 = pin_out[5:5];
    assign _917 = _3032 - _882;
    assign _918 = { gnd,
                    _917 };
    assign _919 = _918 < _885;
    assign _930 = _919 ? _929 : _920;
    assign _913 = _890[7:7];
    assign _912 = _890[6:6];
    assign _911 = _890[5:5];
    assign _910 = _890[4:4];
    assign _909 = _890[3:3];
    assign _908 = _890[2:2];
    assign _907 = _890[1:1];
    assign _906 = _890[0:0];
    always @* begin
        case (_902)
        0:
            _914 <= _906;
        1:
            _914 <= _907;
        2:
            _914 <= _908;
        3:
            _914 <= _909;
        4:
            _914 <= _910;
        5:
            _914 <= _911;
        6:
            _914 <= _912;
        default:
            _914 <= _913;
        endcase
    end
    assign _905 = pin_out[6:6];
    assign _902 = _3015 - _882;
    assign _903 = { gnd,
                    _902 };
    assign _904 = _903 < _885;
    assign _915 = _904 ? _914 : _905;
    assign _898 = _890[7:7];
    assign _897 = _890[6:6];
    assign _896 = _890[5:5];
    assign _895 = _890[4:4];
    assign _894 = _890[3:3];
    assign _893 = _890[2:2];
    assign _892 = _890[1:1];
    assign _891 = _890[0:0];
    always @* begin
        case (_883)
        0:
            _899 <= _891;
        1:
            _899 <= _892;
        2:
            _899 <= _893;
        3:
            _899 <= _894;
        4:
            _899 <= _895;
        5:
            _899 <= _896;
        6:
            _899 <= _897;
        default:
            _899 <= _898;
        endcase
    end
    assign _887 = pin_out[7:7];
    assign _885 = cfg_t0_set_cfg[7:4];
    assign _845 = _592[7:0];
    assign _842 = 7'b1000011;
    assign _843 = _588 == _842;
    assign _841 = _582 & _586;
    assign _844 = _841 & _843;
    assign _846 = _844 ? _845 : cfg_t0_set_cfg;
    assign _22 = _846;
    always @(posedge _106) begin
        if (_104)
            cfg_t0_set_cfg <= _498;
        else
            cfg_t0_set_cfg <= _22;
    end
    assign _882 = cfg_t0_set_cfg[2:0];
    assign _883 = _2857 - _882;
    assign _884 = { gnd,
                    _883 };
    assign _886 = _884 < _885;
    assign _900 = _886 ? _899 : _887;
    assign _1006 = { _900,
                     _915,
                     _930,
                     _945,
                     _960,
                     _975,
                     _990,
                     _1005 };
    assign _879 = _729 == _527;
    assign _876 = _628 == _3015;
    assign _877 = _723 & _876;
    assign _880 = _877 & _879;
    assign _1007 = _880 ? _1006 : pin_out;
    assign _872 = _788 == _3334;
    assign _873 = _794 & _872;
    assign _869 = _628 == _3032;
    assign _870 = _723 & _869;
    assign _874 = _870 & _873;
    assign _1147 = _874 ? _1146 : _1007;
    assign _864 = _92[8:7];
    assign _866 = _864 == _527;
    assign _862 = _628 == _3066;
    assign _863 = _723 & _862;
    assign _867 = _863 & _866;
    assign _1336 = _867 ? _1335 : _1147;
    assign _1337 = _1336[7:7];
    assign _858 = cfg_t0_sideset[5:4];
    assign _859 = { _527,
                    _858 };
    assign _470 = 6'b000000;
    assign _851 = _592[5:0];
    assign _848 = 7'b1001100;
    assign _849 = _588 == _848;
    assign _847 = _582 & _586;
    assign _850 = _847 & _849;
    assign _852 = _850 ? _851 : cfg_t0_sideset;
    assign _23 = _852;
    always @(posedge _106) begin
        if (_104)
            cfg_t0_sideset <= _470;
        else
            cfg_t0_sideset <= _23;
    end
    assign _854 = cfg_t0_sideset[2:0];
    assign _855 = _2857 - _854;
    assign _856 = { gnd,
                    _855 };
    assign _860 = _856 < _859;
    assign _1366 = _860 ? _1365 : _1337;
    assign _1486 = { _1366,
                     _1383,
                     _1400,
                     _1417,
                     _1434,
                     _1451,
                     _1468,
                     _1485 };
    assign _1487 = _623 ? pin_out : _1486;
    assign _1488 = _617 ? pin_out : _1487;
    assign _1489 = _611 ? pin_out : _1488;
    assign _24 = _1489;
    assign _2606 = _1605 == _527;
    assign _2603 = _1530 == _3015;
    assign _2604 = _1599 & _2603;
    assign _2607 = _2604 & _2606;
    assign _2731 = _2607 ? _2730 : _24;
    assign _2599 = _1655 == _3334;
    assign _2600 = _1661 & _2599;
    assign _2596 = _1530 == _3032;
    assign _2597 = _1599 & _2596;
    assign _2601 = _2597 & _2600;
    assign _2855 = _2601 ? _2854 : _2731;
    assign _2591 = _68[8:7];
    assign _2593 = _2591 == _527;
    assign _2589 = _1530 == _3066;
    assign _2590 = _1599 & _2589;
    assign _2594 = _2590 & _2593;
    assign _2985 = _2594 ? _2984 : _2855;
    assign _2986 = _2985[7:7];
    assign _2586 = { _527,
                     _2546 };
    assign _2582 = cfg_t1_sideset[2:0];
    assign _2583 = _2857 - _2582;
    assign _2584 = { gnd,
                     _2583 };
    assign _2587 = _2584 < _2586;
    assign _3014 = _2587 ? _3013 : _2986;
    assign _3134 = { _3014,
                     _3031,
                     _3048,
                     _3065,
                     _3082,
                     _3099,
                     _3116,
                     _3133 };
    assign _2559 = t1_delay_left - _3398;
    assign _2553 = _2551[3:2];
    assign _2554 = { _527,
                     _2553 };
    assign _2548 = _2546[0:0];
    assign _2551 = _2548 ? _3390 : _3389;
    assign _1494 = _592[5:0];
    assign _1491 = 7'b1011100;
    assign _1492 = _588 == _1491;
    assign _1490 = _582 & _586;
    assign _1493 = _1490 & _1492;
    assign _1495 = _1493 ? _1494 : cfg_t1_sideset;
    assign _25 = _1495;
    always @(posedge _106) begin
        if (_104)
            cfg_t1_sideset <= _470;
        else
            cfg_t1_sideset <= _25;
    end
    assign _2546 = cfg_t1_sideset[5:4];
    assign _2547 = _2546[1:1];
    assign _2555 = _2547 ? _2554 : _2551;
    assign _2545 = _68[12:9];
    assign _2556 = _2545 & _2555;
    assign _324 = t1_rx_level == _521;
    assign _325 = ~ _324;
    assign _1506 = t1_rx_level == _521;
    assign _1507 = ~ _1506;
    assign _1502 = 7'b1011001;
    assign _1503 = _377 == _1502;
    assign _1499 = _376[7:7];
    assign _1500 = ~ _1499;
    assign _1501 = _1498 & _1500;
    assign _1504 = _1501 & _1503;
    assign _1508 = _1504 & _1507;
    assign _26 = _1508;
    assign _326 = _26 & _325;
    assign _1543 = { _527,
                     _326 };
    assign _247 = ~ _246;
    assign _1537 = ~ _246;
    assign _1535 = ~ _1534;
    assign _1532 = _1530 == _3476;
    assign _1533 = _1529 & _1532;
    assign _1536 = _1533 & _1535;
    assign _1538 = _1536 & _1537;
    assign _27 = _1538;
    assign _248 = _27 & _247;
    assign _1540 = { _527,
                     _248 };
    assign _1541 = t1_rx_level + _1540;
    assign _1544 = _1541 - _1543;
    assign _28 = _1544;
    always @(posedge _106) begin
        if (_104)
            t1_rx_level <= _521;
        else
            t1_rx_level <= _28;
    end
    assign _246 = t1_rx_level == _3476;
    assign _1594 = ~ _1534;
    assign _1593 = _1530 == _3476;
    assign _1595 = _1593 & _1594;
    assign _1596 = _1595 & _246;
    assign _1586 = _1530 == _3476;
    assign _1587 = _1586 & _1534;
    assign _1590 = _1587 & _1589;
    assign _1583 = ~ _1582;
    assign _1570 = ~ _1569;
    assign _2536 = _588[5:0];
    assign _2535 = cfg_load[1:0];
    assign _2537 = { _2535,
                     _2536 };
    assign _2526 = _68[5:0];
    assign _1549 = _592[7:0];
    assign _1546 = 7'b1010001;
    assign _1547 = _588 == _1546;
    assign _1545 = _582 & _586;
    assign _1548 = _1545 & _1547;
    assign _1550 = _1548 ? _1549 : cfg_t1_start;
    assign _29 = _1550;
    always @(posedge _106) begin
        if (_104)
            cfg_t1_start <= _312;
        else
            cfg_t1_start <= _29;
    end
    assign _1614 = cfg_t1_start[7:6];
    assign _1608 = _68[1:0];
    assign _1607 = _1605 == _545;
    assign _1609 = _1607 ? _1608 : t1_page;
    assign _1604 = _1530 == _3015;
    assign _1610 = _1604 ? _1609 : t1_page;
    assign _1611 = _1599 ? _1610 : t1_page;
    assign _1612 = _1555 ? t1_page : _1611;
    assign _1613 = _1552 ? t1_page : _1612;
    assign _1615 = _1551 ? _1614 : _1613;
    assign _30 = _1615;
    assign _31 = _30;
    always @(posedge _106) begin
        if (_104)
            t1_page <= _527;
        else
            t1_page <= _31;
    end
    assign _2527 = { t1_page,
                     _2526 };
    assign _1620 = _592[7:0];
    assign _1617 = 7'b1010110;
    assign _1618 = _588 == _1617;
    assign _1616 = _582 & _586;
    assign _1619 = _1616 & _1618;
    assign _1621 = _1619 ? _1620 : cfg_t1_timeout_vector;
    assign _32 = _1621;
    always @(posedge _106) begin
        if (_104)
            cfg_t1_timeout_vector <= _312;
        else
            cfg_t1_timeout_vector <= _32;
    end
    assign _2525 = _1530 == _521;
    assign _2528 = _2525 ? _2527 : cfg_t1_timeout_vector;
    assign _2523 = t1_pc + _3367;
    assign _1630 = _1579 - _753;
    assign _1631 = _1628 ? _1630 : t1_wait_count;
    assign _1632 = _1555 ? t1_wait_count : _1631;
    assign _1633 = _1552 ? t1_wait_count : _1632;
    assign _1635 = _1551 ? _363 : _1633;
    assign _33 = _1635;
    assign _34 = _33;
    always @(posedge _106) begin
        if (_104)
            t1_wait_count <= _363;
        else
            t1_wait_count <= _34;
    end
    assign _1637 = 7'b1011011;
    assign _1638 = _588 == _1637;
    assign _1636 = _582 & _586;
    assign _1639 = _1636 & _1638;
    assign _1640 = _1639 ? _592 : cfg_t1_timeout;
    assign _35 = _1640;
    always @(posedge _106) begin
        if (_104)
            cfg_t1_timeout <= _363;
        else
            cfg_t1_timeout <= _35;
    end
    assign _1627 = ~ _1581;
    assign _1624 = ~ _1569;
    assign _1623 = _1530 == _629;
    assign _1625 = _1623 & _1624;
    assign _1626 = _1625 & _1572;
    assign _1628 = _1626 & _1627;
    assign _1642 = _1628 ? _765 : t1_waiting;
    assign _1644 = _1599 ? _576 : _1642;
    assign _1645 = _1555 ? t1_waiting : _1644;
    assign _1646 = _1552 ? t1_waiting : _1645;
    assign _1648 = _1551 ? _576 : _1646;
    assign _36 = _1648;
    assign _37 = _36;
    always @(posedge _106) begin
        if (_104)
            t1_waiting <= _576;
        else
            t1_waiting <= _37;
    end
    assign _1579 = t1_waiting ? t1_wait_count : cfg_t1_timeout;
    assign _1581 = _1579 == _363;
    assign _1572 = _68[4:4];
    assign _1582 = _1572 & _1581;
    assign _1568 = _68[8:8];
    assign _1566 = _681[7:7];
    assign _1565 = _681[6:6];
    assign _1564 = _681[5:5];
    assign _1563 = _681[4:4];
    assign _1562 = _681[3:3];
    assign _1561 = _681[2:2];
    assign _1560 = _681[1:1];
    assign _1559 = _681[0:0];
    assign _1558 = _68[7:5];
    always @* begin
        case (_1558)
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
    assign _1569 = _1567 == _1568;
    assign _2518 = ~ _1569;
    assign _2517 = _1530 == _629;
    assign _2519 = _2517 & _2518;
    assign _2520 = _2519 & _1582;
    assign _1682 = _1680[4:0];
    assign _1679 = { gnd,
                     _1678 };
    assign _1672 = { gnd,
                     t1_isr_count };
    assign _1680 = _1672 + _1679;
    assign _1681 = _804 < _1680;
    assign _1684 = _1681 ? _259 : _1682;
    assign _1669 = _1534 ? t1_isr_count : _780;
    assign _1663 = _1655 == _3066;
    assign _1665 = _1663 ? _780 : t1_isr_count;
    assign _1666 = _1661 ? _1665 : t1_isr_count;
    assign _1654 = _1530 == _3032;
    assign _1667 = _1654 ? _1666 : t1_isr_count;
    assign _1652 = _1530 == _3476;
    assign _1670 = _1652 ? _1669 : _1667;
    assign _1650 = _1530 == _3334;
    assign _1685 = _1650 ? _1684 : _1670;
    assign _1686 = _1599 ? _1685 : t1_isr_count;
    assign _1687 = _1555 ? t1_isr_count : _1686;
    assign _1688 = _1552 ? t1_isr_count : _1687;
    assign _1690 = _1551 ? _780 : _1688;
    assign _38 = _1690;
    assign _39 = _38;
    always @(posedge _106) begin
        if (_104)
            t1_isr_count <= _780;
        else
            t1_isr_count <= _39;
    end
    assign _2513 = t1_isr_count < cfg_t1_threshold;
    assign _1695 = _592[4:0];
    assign _1692 = 7'b1010101;
    assign _1693 = _588 == _1692;
    assign _1691 = _582 & _586;
    assign _1694 = _1691 & _1693;
    assign _1696 = _1694 ? _1695 : cfg_t1_threshold;
    assign _40 = _1696;
    always @(posedge _106) begin
        if (_104)
            cfg_t1_threshold <= _406;
        else
            cfg_t1_threshold <= _40;
    end
    assign _1718 = _1716[4:0];
    assign _1715 = { gnd,
                     _1678 };
    assign _1714 = { gnd,
                     t1_osr_count };
    assign _1716 = _1714 + _1715;
    assign _1717 = _804 < _1716;
    assign _1720 = _1717 ? _259 : _1718;
    assign _1711 = _1534 ? _780 : t1_osr_count;
    assign _1705 = _1655 == _3476;
    assign _1707 = _1705 ? _780 : t1_osr_count;
    assign _1708 = _1661 ? _1707 : t1_osr_count;
    assign _1703 = _1530 == _3032;
    assign _1709 = _1703 ? _1708 : t1_osr_count;
    assign _1702 = _1530 == _3476;
    assign _1712 = _1702 ? _1711 : _1709;
    assign _1701 = _1530 == _3066;
    assign _1721 = _1701 ? _1720 : _1712;
    assign _1722 = _1599 ? _1721 : t1_osr_count;
    assign _1723 = _1555 ? t1_osr_count : _1722;
    assign _1724 = _1552 ? t1_osr_count : _1723;
    assign _1725 = _1551 ? cfg_t1_threshold : _1724;
    assign _41 = _1725;
    assign _42 = _41;
    always @(posedge _106) begin
        if (_104)
            t1_osr_count <= _780;
        else
            t1_osr_count <= _42;
    end
    assign _2512 = t1_osr_count < cfg_t1_threshold;
    assign _2510 = t1_x == t1_y;
    assign _2511 = ~ _2510;
    assign _2507 = t1_y == _363;
    assign _2508 = ~ _2507;
    assign _2509 = ~ _2508;
    assign _2492 = t1_x - _753;
    assign _2490 = _2460 == _3334;
    assign _2493 = _2490 ? _2492 : t1_x;
    assign _2486 = _2423 == _191;
    assign _2487 = _2486 ? _2457 : t1_x;
    assign _1952 = _1875 & _1951;
    assign _1921 = _1920[15:0];
    assign _1923 = { _1921,
                     _363 };
    assign _1917 = _1916[23:0];
    assign _1919 = { _1917,
                     _312 };
    assign _1913 = _1912[27:0];
    assign _1915 = { _1913,
                     _308 };
    assign _1909 = _1908[29:0];
    assign _1911 = { _1909,
                     _527 };
    assign _1905 = _1904[30:0];
    assign _1907 = { _1905,
                     _576 };
    assign _1904 = { _363,
                     t1_isr };
    assign _1902 = _1678[0:0];
    assign _1908 = _1902 ? _1907 : _1904;
    assign _1901 = _1678[1:1];
    assign _1912 = _1901 ? _1911 : _1908;
    assign _1900 = _1678[2:2];
    assign _1916 = _1900 ? _1915 : _1912;
    assign _1899 = _1678[3:3];
    assign _1920 = _1899 ? _1919 : _1916;
    assign _1898 = _1678[4:4];
    assign _1924 = _1898 ? _1923 : _1920;
    assign _1925 = _1924[15:0];
    assign _1953 = _1925 | _1952;
    assign _1894 = _1892[31:16];
    assign _1895 = { _363,
                     _1894 };
    assign _1890 = _1888[31:8];
    assign _1891 = { _312,
                     _1890 };
    assign _1886 = _1884[31:4];
    assign _1887 = { _308,
                     _1886 };
    assign _1882 = _1880[31:2];
    assign _1883 = { _527,
                     _1882 };
    assign _1878 = _1876[31:1];
    assign _1879 = { _576,
                     _1878 };
    assign _1870 = _780 < _1678;
    assign _1867 = _681[7:7];
    assign _1866 = _681[6:6];
    assign _1865 = _681[5:5];
    assign _1864 = _681[4:4];
    assign _1863 = _681[3:3];
    assign _1862 = _681[2:2];
    assign _1861 = _681[1:1];
    assign _1860 = _681[0:0];
    always @* begin
        case (cfg_t1_in_base)
        0:
            _1868 <= _1860;
        1:
            _1868 <= _1861;
        2:
            _1868 <= _1862;
        3:
            _1868 <= _1863;
        4:
            _1868 <= _1864;
        5:
            _1868 <= _1865;
        6:
            _1868 <= _1866;
        default:
            _1868 <= _1867;
        endcase
    end
    assign _1871 = _1868 & _1870;
    assign _1857 = 5'b00001;
    assign _1858 = _1857 < _1678;
    assign _1855 = _681[7:7];
    assign _1854 = _681[6:6];
    assign _1853 = _681[5:5];
    assign _1852 = _681[4:4];
    assign _1851 = _681[3:3];
    assign _1850 = _681[2:2];
    assign _1849 = _681[1:1];
    assign _1848 = _681[0:0];
    assign _1847 = cfg_t1_in_base + _629;
    always @* begin
        case (_1847)
        0:
            _1856 <= _1848;
        1:
            _1856 <= _1849;
        2:
            _1856 <= _1850;
        3:
            _1856 <= _1851;
        4:
            _1856 <= _1852;
        5:
            _1856 <= _1853;
        6:
            _1856 <= _1854;
        default:
            _1856 <= _1855;
        endcase
    end
    assign _1859 = _1856 & _1858;
    assign _1843 = 5'b00010;
    assign _1844 = _1843 < _1678;
    assign _1841 = _681[7:7];
    assign _1840 = _681[6:6];
    assign _1839 = _681[5:5];
    assign _1838 = _681[4:4];
    assign _1837 = _681[3:3];
    assign _1836 = _681[2:2];
    assign _1835 = _681[1:1];
    assign _1834 = _681[0:0];
    assign _1833 = cfg_t1_in_base + _3334;
    always @* begin
        case (_1833)
        0:
            _1842 <= _1834;
        1:
            _1842 <= _1835;
        2:
            _1842 <= _1836;
        3:
            _1842 <= _1837;
        4:
            _1842 <= _1838;
        5:
            _1842 <= _1839;
        6:
            _1842 <= _1840;
        default:
            _1842 <= _1841;
        endcase
    end
    assign _1845 = _1842 & _1844;
    assign _1829 = 5'b00011;
    assign _1830 = _1829 < _1678;
    assign _1827 = _681[7:7];
    assign _1826 = _681[6:6];
    assign _1825 = _681[5:5];
    assign _1824 = _681[4:4];
    assign _1823 = _681[3:3];
    assign _1822 = _681[2:2];
    assign _1821 = _681[1:1];
    assign _1820 = _681[0:0];
    assign _1819 = cfg_t1_in_base + _3066;
    always @* begin
        case (_1819)
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
    assign _1831 = _1828 & _1830;
    assign _1815 = 5'b00100;
    assign _1816 = _1815 < _1678;
    assign _1813 = _681[7:7];
    assign _1812 = _681[6:6];
    assign _1811 = _681[5:5];
    assign _1810 = _681[4:4];
    assign _1809 = _681[3:3];
    assign _1808 = _681[2:2];
    assign _1807 = _681[1:1];
    assign _1806 = _681[0:0];
    assign _1805 = cfg_t1_in_base + _3476;
    always @* begin
        case (_1805)
        0:
            _1814 <= _1806;
        1:
            _1814 <= _1807;
        2:
            _1814 <= _1808;
        3:
            _1814 <= _1809;
        4:
            _1814 <= _1810;
        5:
            _1814 <= _1811;
        6:
            _1814 <= _1812;
        default:
            _1814 <= _1813;
        endcase
    end
    assign _1817 = _1814 & _1816;
    assign _1801 = 5'b00101;
    assign _1802 = _1801 < _1678;
    assign _1799 = _681[7:7];
    assign _1798 = _681[6:6];
    assign _1797 = _681[5:5];
    assign _1796 = _681[4:4];
    assign _1795 = _681[3:3];
    assign _1794 = _681[2:2];
    assign _1793 = _681[1:1];
    assign _1792 = _681[0:0];
    assign _1791 = cfg_t1_in_base + _3032;
    always @* begin
        case (_1791)
        0:
            _1800 <= _1792;
        1:
            _1800 <= _1793;
        2:
            _1800 <= _1794;
        3:
            _1800 <= _1795;
        4:
            _1800 <= _1796;
        5:
            _1800 <= _1797;
        6:
            _1800 <= _1798;
        default:
            _1800 <= _1799;
        endcase
    end
    assign _1803 = _1800 & _1802;
    assign _1787 = 5'b00110;
    assign _1788 = _1787 < _1678;
    assign _1785 = _681[7:7];
    assign _1784 = _681[6:6];
    assign _1783 = _681[5:5];
    assign _1782 = _681[4:4];
    assign _1781 = _681[3:3];
    assign _1780 = _681[2:2];
    assign _1779 = _681[1:1];
    assign _1778 = _681[0:0];
    assign _1777 = cfg_t1_in_base + _3015;
    always @* begin
        case (_1777)
        0:
            _1786 <= _1778;
        1:
            _1786 <= _1779;
        2:
            _1786 <= _1780;
        3:
            _1786 <= _1781;
        4:
            _1786 <= _1782;
        5:
            _1786 <= _1783;
        6:
            _1786 <= _1784;
        default:
            _1786 <= _1785;
        endcase
    end
    assign _1789 = _1786 & _1788;
    assign _1773 = 5'b00111;
    assign _1774 = _1773 < _1678;
    assign _1771 = _681[7:7];
    assign _1770 = _681[6:6];
    assign _1769 = _681[5:5];
    assign _1768 = _681[4:4];
    assign _1767 = _681[3:3];
    assign _1766 = _681[2:2];
    assign _1765 = _681[1:1];
    assign _1764 = _681[0:0];
    assign _1730 = _592[2:0];
    assign _1727 = 7'b1010100;
    assign _1728 = _588 == _1727;
    assign _1726 = _582 & _586;
    assign _1729 = _1726 & _1728;
    assign _1731 = _1729 ? _1730 : cfg_t1_in_base;
    assign _43 = _1731;
    always @(posedge _106) begin
        if (_104)
            cfg_t1_in_base <= _521;
        else
            cfg_t1_in_base <= _43;
    end
    assign _1763 = cfg_t1_in_base + _2857;
    always @* begin
        case (_1763)
        0:
            _1772 <= _1764;
        1:
            _1772 <= _1765;
        2:
            _1772 <= _1766;
        3:
            _1772 <= _1767;
        4:
            _1772 <= _1768;
        5:
            _1772 <= _1769;
        6:
            _1772 <= _1770;
        default:
            _1772 <= _1771;
        endcase
    end
    assign _1775 = _1772 & _1774;
    assign _1872 = { _1775,
                     _1789,
                     _1803,
                     _1817,
                     _1831,
                     _1845,
                     _1859,
                     _1871 };
    assign _1873 = { _312,
                     _1872 };
    assign _1760 = _68[8:7];
    always @* begin
        case (_1760)
        0:
            _1875 <= _1873;
        1:
            _1875 <= t1_x;
        2:
            _1875 <= t1_y;
        default:
            _1875 <= _363;
        endcase
    end
    assign _1876 = { _1875,
                     t1_isr };
    assign _1759 = _1678[0:0];
    assign _1880 = _1759 ? _1879 : _1876;
    assign _1758 = _1678[1:1];
    assign _1884 = _1758 ? _1883 : _1880;
    assign _1757 = _1678[2:2];
    assign _1888 = _1757 ? _1887 : _1884;
    assign _1756 = _1678[3:3];
    assign _1892 = _1756 ? _1891 : _1888;
    assign _1755 = _1678[4:4];
    assign _1896 = _1755 ? _1895 : _1892;
    assign _1897 = _1896[15:0];
    assign _258 = cfg_t1_shift[1:1];
    assign _1954 = _258 ? _1953 : _1897;
    assign _1753 = _1534 ? t1_isr : _363;
    assign _1735 = _1655 == _3066;
    assign _1749 = _1735 ? _1748 : t1_isr;
    assign _1750 = _1661 ? _1749 : t1_isr;
    assign _1734 = _1530 == _3032;
    assign _1751 = _1734 ? _1750 : t1_isr;
    assign _1733 = _1530 == _3476;
    assign _1754 = _1733 ? _1753 : _1751;
    assign _1732 = _1530 == _3334;
    assign _1955 = _1732 ? _1954 : _1754;
    assign _1956 = _1599 ? _1955 : t1_isr;
    assign _1957 = _1555 ? t1_isr : _1956;
    assign _1958 = _1552 ? t1_isr : _1957;
    assign _1960 = _1551 ? _363 : _1958;
    assign _44 = _1960;
    assign _45 = _44;
    always @(posedge _106) begin
        if (_104)
            t1_isr <= _363;
        else
            t1_isr <= _45;
    end
    assign _1743 = { _312,
                     _681 };
    assign _2464 = t1_y - _753;
    assign _2462 = _2460 == _3476;
    assign _2465 = _2462 ? _2464 : t1_y;
    assign _2453 = _2451[31:16];
    assign _2454 = { _363,
                     _2453 };
    assign _2449 = _2447[31:8];
    assign _2450 = { _312,
                     _2449 };
    assign _2445 = _2443[31:4];
    assign _2446 = { _308,
                     _2445 };
    assign _2441 = _2439[31:2];
    assign _2442 = { _527,
                     _2441 };
    assign _2437 = _2435[31:1];
    assign _2438 = { _576,
                     _2437 };
    assign _2435 = { _363,
                     t1_osr };
    assign _2433 = _2428[0:0];
    assign _2439 = _2433 ? _2438 : _2435;
    assign _2432 = _2428[1:1];
    assign _2443 = _2432 ? _2442 : _2439;
    assign _2431 = _2428[2:2];
    assign _2447 = _2431 ? _2446 : _2443;
    assign _2430 = _2428[3:3];
    assign _2451 = _2430 ? _2450 : _2447;
    assign _2428 = _259 - _1678;
    assign _2429 = _2428[4:4];
    assign _2455 = _2429 ? _2454 : _2451;
    assign _2456 = _2455[15:0];
    assign _1946 = _1945[15:0];
    assign _1948 = { _1946,
                     _363 };
    assign _1942 = _1941[23:0];
    assign _1944 = { _1942,
                     _312 };
    assign _1938 = _1937[27:0];
    assign _1940 = { _1938,
                     _308 };
    assign _1934 = _1933[29:0];
    assign _1936 = { _1934,
                     _527 };
    assign _1930 = _1678[0:0];
    assign _1933 = _1930 ? _301 : _300;
    assign _1929 = _1678[1:1];
    assign _1937 = _1929 ? _1936 : _1933;
    assign _1928 = _1678[2:2];
    assign _1941 = _1928 ? _1940 : _1937;
    assign _1927 = _1678[3:3];
    assign _1945 = _1927 ? _1944 : _1941;
    assign _1926 = _1678[4:4];
    assign _1949 = _1926 ? _1948 : _1945;
    assign _1950 = _1949[15:0];
    assign _1951 = ~ _1950;
    assign _2388 = _2387[15:0];
    assign _2390 = { _2388,
                     _363 };
    assign _2384 = _2383[23:0];
    assign _2386 = { _2384,
                     _312 };
    assign _2380 = _2379[27:0];
    assign _2382 = { _2380,
                     _308 };
    assign _2376 = _2375[29:0];
    assign _2378 = { _2376,
                     _527 };
    assign _2372 = _2371[30:0];
    assign _2374 = { _2372,
                     _576 };
    assign _2371 = { _363,
                     t1_osr };
    assign _2369 = _1678[0:0];
    assign _2375 = _2369 ? _2374 : _2371;
    assign _2368 = _1678[1:1];
    assign _2379 = _2368 ? _2378 : _2375;
    assign _2367 = _1678[2:2];
    assign _2383 = _2367 ? _2382 : _2379;
    assign _2366 = _1678[3:3];
    assign _2387 = _2366 ? _2386 : _2383;
    assign _2365 = _1678[4:4];
    assign _2391 = _2365 ? _2390 : _2387;
    assign _2392 = _2391[15:0];
    assign _2361 = _2359[31:16];
    assign _2362 = { _363,
                     _2361 };
    assign _2357 = _2355[31:8];
    assign _2358 = { _312,
                     _2357 };
    assign _2353 = _2351[31:4];
    assign _2354 = { _308,
                     _2353 };
    assign _2349 = _2347[31:2];
    assign _2350 = { _527,
                     _2349 };
    assign _2345 = _2343[31:1];
    assign _2346 = { _576,
                     _2345 };
    assign _2343 = { _363,
                     t1_osr };
    assign _2341 = _1678[0:0];
    assign _2347 = _2341 ? _2346 : _2343;
    assign _2340 = _1678[1:1];
    assign _2351 = _2340 ? _2350 : _2347;
    assign _2339 = _1678[2:2];
    assign _2355 = _2339 ? _2354 : _2351;
    assign _2338 = _1678[3:3];
    assign _2359 = _2338 ? _2358 : _2355;
    assign _1676 = { gnd,
                     _1673 };
    assign _1673 = _68[3:0];
    assign _1675 = _1673 == _308;
    assign _1678 = _1675 ? _259 : _1676;
    assign _2337 = _1678[4:4];
    assign _2363 = _2337 ? _2362 : _2359;
    assign _2364 = _2363[15:0];
    assign _2393 = _2336 ? _2392 : _2364;
    assign _2330 = t1_tx_wr == _545;
    assign _2331 = _1972 & _2330;
    always @(posedge _106) begin
        if (_104)
            t1_tx_mem_3 <= _363;
        else
            if (_2331)
                t1_tx_mem_3 <= _2308;
    end
    assign _2324 = t1_tx_wr == _194;
    assign _2325 = _1972 & _2324;
    always @(posedge _106) begin
        if (_104)
            t1_tx_mem_2 <= _363;
        else
            if (_2325)
                t1_tx_mem_2 <= _2308;
    end
    assign _2318 = t1_tx_wr == _191;
    assign _2319 = _1972 & _2318;
    always @(posedge _106) begin
        if (_104)
            t1_tx_mem_1 <= _363;
        else
            if (_2319)
                t1_tx_mem_1 <= _2308;
    end
    assign _1977 = t1_tx_wr + _191;
    assign _1978 = _1972 ? _1977 : t1_tx_wr;
    assign _46 = _1978;
    always @(posedge _106) begin
        if (_104)
            t1_tx_wr <= _527;
        else
            t1_tx_wr <= _46;
    end
    assign _2312 = t1_tx_wr == _527;
    assign _2313 = _1972 & _2312;
    assign _452 = t0_rx_wr == _545;
    assign _453 = _429 & _452;
    always @(posedge _106) begin
        if (_104)
            t0_rx_mem_3 <= _363;
        else
            if (_453)
                t0_rx_mem_3 <= _53;
    end
    assign _446 = t0_rx_wr == _194;
    assign _447 = _429 & _446;
    always @(posedge _106) begin
        if (_104)
            t0_rx_mem_2 <= _363;
        else
            if (_447)
                t0_rx_mem_2 <= _53;
    end
    assign _440 = t0_rx_wr == _191;
    assign _441 = _429 & _440;
    always @(posedge _106) begin
        if (_104)
            t0_rx_mem_1 <= _363;
        else
            if (_441)
                t0_rx_mem_1 <= _53;
    end
    assign _1980 = t0_rx_wr + _191;
    assign _1981 = _429 ? _1980 : t0_rx_wr;
    assign _47 = _1981;
    always @(posedge _106) begin
        if (_104)
            t0_rx_wr <= _527;
        else
            t0_rx_wr <= _47;
    end
    assign _434 = t0_rx_wr == _527;
    assign _435 = _429 & _434;
    assign _2259 = _2258[15:0];
    assign _2261 = { _2259,
                     _363 };
    assign _2255 = _2254[23:0];
    assign _2257 = { _2255,
                     _312 };
    assign _2251 = _2250[27:0];
    assign _2253 = { _2251,
                     _308 };
    assign _2247 = _2246[29:0];
    assign _2249 = { _2247,
                     _527 };
    assign _2243 = t0_isr_count[0:0];
    assign _2246 = _2243 ? _301 : _300;
    assign _2242 = t0_isr_count[1:1];
    assign _2250 = _2242 ? _2249 : _2246;
    assign _2241 = t0_isr_count[2:2];
    assign _2254 = _2241 ? _2253 : _2250;
    assign _2240 = t0_isr_count[3:3];
    assign _2258 = _2240 ? _2257 : _2254;
    assign _2239 = t0_isr_count[4:4];
    assign _2262 = _2239 ? _2261 : _2258;
    assign _2263 = _2262[15:0];
    assign _2264 = ~ _2263;
    assign _2265 = t0_isr & _2264;
    assign _2235 = _2233[31:16];
    assign _2236 = { _363,
                     _2235 };
    assign _2231 = _2229[31:8];
    assign _2232 = { _312,
                     _2231 };
    assign _2227 = _2225[31:4];
    assign _2228 = { _308,
                     _2227 };
    assign _2223 = _2221[31:2];
    assign _2224 = { _527,
                     _2223 };
    assign _2219 = _2217[31:1];
    assign _2220 = { _576,
                     _2219 };
    assign _2172 = _2121 & _1180;
    assign _2167 = _2166[15:0];
    assign _2169 = { _2167,
                     _363 };
    assign _2163 = _2162[23:0];
    assign _2165 = { _2163,
                     _312 };
    assign _2159 = _2158[27:0];
    assign _2161 = { _2159,
                     _308 };
    assign _2155 = _2154[29:0];
    assign _2157 = { _2155,
                     _527 };
    assign _2151 = _2150[30:0];
    assign _2153 = { _2151,
                     _576 };
    assign _2150 = { _363,
                     t0_isr };
    assign _2148 = _811[0:0];
    assign _2154 = _2148 ? _2153 : _2150;
    assign _2147 = _811[1:1];
    assign _2158 = _2147 ? _2157 : _2154;
    assign _2146 = _811[2:2];
    assign _2162 = _2146 ? _2161 : _2158;
    assign _2145 = _811[3:3];
    assign _2166 = _2145 ? _2165 : _2162;
    assign _2144 = _811[4:4];
    assign _2170 = _2144 ? _2169 : _2166;
    assign _2171 = _2170[15:0];
    assign _2173 = _2171 | _2172;
    assign _2140 = _2138[31:16];
    assign _2141 = { _363,
                     _2140 };
    assign _2136 = _2134[31:8];
    assign _2137 = { _312,
                     _2136 };
    assign _2132 = _2130[31:4];
    assign _2133 = { _308,
                     _2132 };
    assign _2128 = _2126[31:2];
    assign _2129 = { _527,
                     _2128 };
    assign _2124 = _2122[31:1];
    assign _2125 = { _576,
                     _2124 };
    assign _2116 = _780 < _811;
    assign _2113 = _681[7:7];
    assign _2112 = _681[6:6];
    assign _2111 = _681[5:5];
    assign _2110 = _681[4:4];
    assign _2109 = _681[3:3];
    assign _2108 = _681[2:2];
    assign _2107 = _681[1:1];
    assign _2106 = _681[0:0];
    always @* begin
        case (cfg_t0_in_base)
        0:
            _2114 <= _2106;
        1:
            _2114 <= _2107;
        2:
            _2114 <= _2108;
        3:
            _2114 <= _2109;
        4:
            _2114 <= _2110;
        5:
            _2114 <= _2111;
        6:
            _2114 <= _2112;
        default:
            _2114 <= _2113;
        endcase
    end
    assign _2117 = _2114 & _2116;
    assign _2104 = _1857 < _811;
    assign _2101 = _681[7:7];
    assign _2100 = _681[6:6];
    assign _2099 = _681[5:5];
    assign _2098 = _681[4:4];
    assign _2097 = _681[3:3];
    assign _2096 = _681[2:2];
    assign _2095 = _681[1:1];
    assign _2094 = _681[0:0];
    assign _2093 = cfg_t0_in_base + _629;
    always @* begin
        case (_2093)
        0:
            _2102 <= _2094;
        1:
            _2102 <= _2095;
        2:
            _2102 <= _2096;
        3:
            _2102 <= _2097;
        4:
            _2102 <= _2098;
        5:
            _2102 <= _2099;
        6:
            _2102 <= _2100;
        default:
            _2102 <= _2101;
        endcase
    end
    assign _2105 = _2102 & _2104;
    assign _2090 = _1843 < _811;
    assign _2087 = _681[7:7];
    assign _2086 = _681[6:6];
    assign _2085 = _681[5:5];
    assign _2084 = _681[4:4];
    assign _2083 = _681[3:3];
    assign _2082 = _681[2:2];
    assign _2081 = _681[1:1];
    assign _2080 = _681[0:0];
    assign _2079 = cfg_t0_in_base + _3334;
    always @* begin
        case (_2079)
        0:
            _2088 <= _2080;
        1:
            _2088 <= _2081;
        2:
            _2088 <= _2082;
        3:
            _2088 <= _2083;
        4:
            _2088 <= _2084;
        5:
            _2088 <= _2085;
        6:
            _2088 <= _2086;
        default:
            _2088 <= _2087;
        endcase
    end
    assign _2091 = _2088 & _2090;
    assign _2076 = _1829 < _811;
    assign _2073 = _681[7:7];
    assign _2072 = _681[6:6];
    assign _2071 = _681[5:5];
    assign _2070 = _681[4:4];
    assign _2069 = _681[3:3];
    assign _2068 = _681[2:2];
    assign _2067 = _681[1:1];
    assign _2066 = _681[0:0];
    assign _2065 = cfg_t0_in_base + _3066;
    always @* begin
        case (_2065)
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
    assign _2077 = _2074 & _2076;
    assign _2062 = _1815 < _811;
    assign _2059 = _681[7:7];
    assign _2058 = _681[6:6];
    assign _2057 = _681[5:5];
    assign _2056 = _681[4:4];
    assign _2055 = _681[3:3];
    assign _2054 = _681[2:2];
    assign _2053 = _681[1:1];
    assign _2052 = _681[0:0];
    assign _2051 = cfg_t0_in_base + _3476;
    always @* begin
        case (_2051)
        0:
            _2060 <= _2052;
        1:
            _2060 <= _2053;
        2:
            _2060 <= _2054;
        3:
            _2060 <= _2055;
        4:
            _2060 <= _2056;
        5:
            _2060 <= _2057;
        6:
            _2060 <= _2058;
        default:
            _2060 <= _2059;
        endcase
    end
    assign _2063 = _2060 & _2062;
    assign _2048 = _1801 < _811;
    assign _2045 = _681[7:7];
    assign _2044 = _681[6:6];
    assign _2043 = _681[5:5];
    assign _2042 = _681[4:4];
    assign _2041 = _681[3:3];
    assign _2040 = _681[2:2];
    assign _2039 = _681[1:1];
    assign _2038 = _681[0:0];
    assign _2037 = cfg_t0_in_base + _3032;
    always @* begin
        case (_2037)
        0:
            _2046 <= _2038;
        1:
            _2046 <= _2039;
        2:
            _2046 <= _2040;
        3:
            _2046 <= _2041;
        4:
            _2046 <= _2042;
        5:
            _2046 <= _2043;
        6:
            _2046 <= _2044;
        default:
            _2046 <= _2045;
        endcase
    end
    assign _2049 = _2046 & _2048;
    assign _2034 = _1787 < _811;
    assign _2031 = _681[7:7];
    assign _2030 = _681[6:6];
    assign _2029 = _681[5:5];
    assign _2028 = _681[4:4];
    assign _2027 = _681[3:3];
    assign _2026 = _681[2:2];
    assign _2025 = _681[1:1];
    assign _2024 = _681[0:0];
    assign _2023 = cfg_t0_in_base + _3015;
    always @* begin
        case (_2023)
        0:
            _2032 <= _2024;
        1:
            _2032 <= _2025;
        2:
            _2032 <= _2026;
        3:
            _2032 <= _2027;
        4:
            _2032 <= _2028;
        5:
            _2032 <= _2029;
        6:
            _2032 <= _2030;
        default:
            _2032 <= _2031;
        endcase
    end
    assign _2035 = _2032 & _2034;
    assign _2020 = _1773 < _811;
    assign _2017 = _681[7:7];
    assign _2016 = _681[6:6];
    assign _2015 = _681[5:5];
    assign _2014 = _681[4:4];
    assign _2013 = _681[3:3];
    assign _2012 = _681[2:2];
    assign _2011 = _681[1:1];
    assign _2010 = _681[0:0];
    assign _1986 = _592[2:0];
    assign _1983 = 7'b1000100;
    assign _1984 = _588 == _1983;
    assign _1982 = _582 & _586;
    assign _1985 = _1982 & _1984;
    assign _1987 = _1985 ? _1986 : cfg_t0_in_base;
    assign _48 = _1987;
    always @(posedge _106) begin
        if (_104)
            cfg_t0_in_base <= _521;
        else
            cfg_t0_in_base <= _48;
    end
    assign _2009 = cfg_t0_in_base + _2857;
    always @* begin
        case (_2009)
        0:
            _2018 <= _2010;
        1:
            _2018 <= _2011;
        2:
            _2018 <= _2012;
        3:
            _2018 <= _2013;
        4:
            _2018 <= _2014;
        5:
            _2018 <= _2015;
        6:
            _2018 <= _2016;
        default:
            _2018 <= _2017;
        endcase
    end
    assign _2021 = _2018 & _2020;
    assign _2118 = { _2021,
                     _2035,
                     _2049,
                     _2063,
                     _2077,
                     _2091,
                     _2105,
                     _2117 };
    assign _2119 = { _312,
                     _2118 };
    assign _2006 = _92[8:7];
    always @* begin
        case (_2006)
        0:
            _2121 <= _2119;
        1:
            _2121 <= t0_x;
        2:
            _2121 <= t0_y;
        default:
            _2121 <= _363;
        endcase
    end
    assign _2122 = { _2121,
                     t0_isr };
    assign _2005 = _811[0:0];
    assign _2126 = _2005 ? _2125 : _2122;
    assign _2004 = _811[1:1];
    assign _2130 = _2004 ? _2129 : _2126;
    assign _2003 = _811[2:2];
    assign _2134 = _2003 ? _2133 : _2130;
    assign _2002 = _811[3:3];
    assign _2138 = _2002 ? _2137 : _2134;
    assign _2001 = _811[4:4];
    assign _2142 = _2001 ? _2141 : _2138;
    assign _2143 = _2142[15:0];
    assign _2174 = _2000 ? _2173 : _2143;
    assign _1998 = _710 ? t0_isr : _363;
    assign _1993 = _788 == _3066;
    assign _1994 = _1993 ? _1030 : t0_isr;
    assign _1995 = _794 ? _1994 : t0_isr;
    assign _1991 = _628 == _3032;
    assign _1996 = _1991 ? _1995 : t0_isr;
    assign _1990 = _628 == _3476;
    assign _1999 = _1990 ? _1998 : _1996;
    assign _1989 = _628 == _3334;
    assign _2175 = _1989 ? _2174 : _1999;
    assign _2176 = _723 ? _2175 : t0_isr;
    assign _2177 = _623 ? t0_isr : _2176;
    assign _2178 = _617 ? t0_isr : _2177;
    assign _2180 = _611 ? _363 : _2178;
    assign _49 = _2180;
    assign _50 = _49;
    always @(posedge _106) begin
        if (_104)
            t0_isr <= _363;
        else
            t0_isr <= _50;
    end
    assign _2217 = { _363,
                     t0_isr };
    assign _2215 = _2210[0:0];
    assign _2221 = _2215 ? _2220 : _2217;
    assign _2214 = _2210[1:1];
    assign _2225 = _2214 ? _2224 : _2221;
    assign _2213 = _2210[2:2];
    assign _2229 = _2213 ? _2228 : _2225;
    assign _2212 = _2210[3:3];
    assign _2233 = _2212 ? _2232 : _2229;
    assign _2200 = _2198[4:0];
    assign _2197 = { gnd,
                     _811 };
    assign _2196 = { gnd,
                     t0_isr_count };
    assign _2198 = _2196 + _2197;
    assign _2199 = _804 < _2198;
    assign _2202 = _2199 ? _259 : _2200;
    assign _2193 = _710 ? t0_isr_count : _780;
    assign _2187 = _788 == _3066;
    assign _2189 = _2187 ? _780 : t0_isr_count;
    assign _2190 = _794 ? _2189 : t0_isr_count;
    assign _2186 = _628 == _3032;
    assign _2191 = _2186 ? _2190 : t0_isr_count;
    assign _2185 = _628 == _3476;
    assign _2194 = _2185 ? _2193 : _2191;
    assign _2184 = _628 == _3334;
    assign _2203 = _2184 ? _2202 : _2194;
    assign _2204 = _723 ? _2203 : t0_isr_count;
    assign _2205 = _623 ? t0_isr_count : _2204;
    assign _2206 = _617 ? t0_isr_count : _2205;
    assign _2208 = _611 ? _780 : _2206;
    assign _51 = _2208;
    assign _52 = _51;
    always @(posedge _106) begin
        if (_104)
            t0_isr_count <= _780;
        else
            t0_isr_count <= _52;
    end
    assign _2210 = _259 - t0_isr_count;
    assign _2211 = _2210[4:4];
    assign _2237 = _2211 ? _2236 : _2233;
    assign _2238 = _2237[15:0];
    assign _2000 = cfg_t0_shift[1:1];
    assign _2266 = _2000 ? _2265 : _2238;
    assign _53 = _2266;
    always @(posedge _106) begin
        if (_104)
            t0_rx_mem_0 <= _363;
        else
            if (_435)
                t0_rx_mem_0 <= _53;
    end
    assign _2285 = t0_rx_rd + _191;
    assign _2282 = ~ _2281;
    assign _2277 = ~ _1965;
    assign _2274 = t0_rx_level == _521;
    assign _2275 = ~ _2274;
    assign _2270 = 7'b1001001;
    assign _377 = _376[6:0];
    assign _2271 = _377 == _2270;
    assign _2267 = _376[7:7];
    assign _2268 = ~ _2267;
    assign _1497 = host_bit_count == _1773;
    assign _1498 = _361 & _1497;
    assign _2269 = _1498 & _2268;
    assign _2272 = _2269 & _2271;
    assign _2276 = _2272 & _2275;
    assign _54 = _2276;
    assign _2278 = _54 & _2277;
    assign _2279 = _110 | _2278;
    assign _2283 = _2279 & _2282;
    assign _2286 = _2283 ? _2285 : t0_rx_rd;
    assign _55 = _2286;
    always @(posedge _106) begin
        if (_104)
            t0_rx_rd <= _527;
        else
            t0_rx_rd <= _55;
    end
    always @* begin
        case (t0_rx_rd)
        0:
            _455 <= t0_rx_mem_0;
        1:
            _455 <= t0_rx_mem_1;
        2:
            _455 <= t0_rx_mem_2;
        default:
            _455 <= t0_rx_mem_3;
        endcase
    end
    assign _56 = _455;
    assign _2308 = _110 ? _56 : _592;
    always @(posedge _106) begin
        if (_104)
            t1_tx_mem_0 <= _363;
        else
            if (_2313)
                t1_tx_mem_0 <= _2308;
    end
    assign _2299 = t1_tx_rd + _191;
    assign _2293 = ~ _1589;
    assign _1589 = t1_tx_level == _521;
    assign _2291 = ~ _1589;
    assign _2288 = _1530 == _3476;
    assign _2289 = _1529 & _2288;
    assign _2290 = _2289 & _1534;
    assign _2292 = _2290 & _2291;
    assign _57 = _2292;
    assign _2294 = _57 & _2293;
    assign _2300 = _2294 ? _2299 : t1_tx_rd;
    assign _58 = _2300;
    always @(posedge _106) begin
        if (_104)
            t1_tx_rd <= _527;
        else
            t1_tx_rd <= _58;
    end
    always @* begin
        case (t1_tx_rd)
        0:
            _2333 <= t1_tx_mem_0;
        1:
            _2333 <= t1_tx_mem_1;
        2:
            _2333 <= t1_tx_mem_2;
        default:
            _2333 <= t1_tx_mem_3;
        endcase
    end
    assign _1534 = _68[8:8];
    assign _2334 = _1534 ? _2333 : t1_osr;
    assign _2304 = _1655 == _3476;
    assign _2305 = _2304 ? _1748 : t1_osr;
    assign _2306 = _1661 ? _2305 : t1_osr;
    assign _2303 = _1530 == _3032;
    assign _2307 = _2303 ? _2306 : t1_osr;
    assign _2302 = _1530 == _3476;
    assign _2335 = _2302 ? _2334 : _2307;
    assign _2301 = _1530 == _3066;
    assign _2394 = _2301 ? _2393 : _2335;
    assign _2395 = _1599 ? _2394 : t1_osr;
    assign _2396 = _1555 ? t1_osr : _2395;
    assign _2397 = _1552 ? t1_osr : _2396;
    assign _2399 = _1551 ? _363 : _2397;
    assign _59 = _2399;
    assign _60 = _59;
    always @(posedge _106) begin
        if (_104)
            t1_osr <= _363;
        else
            t1_osr <= _60;
    end
    assign _2426 = t1_osr & _1951;
    assign _2404 = _592[1:0];
    assign _2401 = 7'b1011111;
    assign _2402 = _588 == _2401;
    assign _2400 = _582 & _586;
    assign _2403 = _2400 & _2402;
    assign _2405 = _2403 ? _2404 : cfg_t1_shift;
    assign _61 = _2405;
    always @(posedge _106) begin
        if (_104)
            cfg_t1_shift <= _527;
        else
            cfg_t1_shift <= _61;
    end
    assign _2336 = cfg_t1_shift[0:0];
    assign _2457 = _2336 ? _2456 : _2426;
    assign _2423 = _68[8:7];
    assign _2425 = _2423 == _194;
    assign _2458 = _2425 ? _2457 : t1_y;
    assign _2419 = _1655 == _629;
    assign _2420 = _2419 ? _1748 : t1_y;
    assign _2421 = _1661 ? _2420 : t1_y;
    assign _2412 = _1605 == _194;
    assign _2416 = _2412 ? _2415 : t1_y;
    assign _2410 = _1530 == _3015;
    assign _2417 = _2410 ? _2416 : t1_y;
    assign _2409 = _1530 == _3032;
    assign _2422 = _2409 ? _2421 : _2417;
    assign _2408 = _1530 == _3066;
    assign _2459 = _2408 ? _2458 : _2422;
    assign _2407 = _1530 == _521;
    assign _2466 = _2407 ? _2465 : _2459;
    assign _2467 = _1599 ? _2466 : t1_y;
    assign _2468 = _1555 ? t1_y : _2467;
    assign _2469 = _1552 ? t1_y : _2468;
    assign _2471 = _1551 ? _363 : _2469;
    assign _62 = _2471;
    assign _63 = _62;
    always @(posedge _106) begin
        if (_104)
            t1_y <= _363;
        else
            t1_y <= _63;
    end
    always @* begin
        case (_1658)
        0:
            _1748 <= t1_x;
        1:
            _1748 <= t1_y;
        2:
            _1748 <= _1743;
        3:
            _1748 <= t1_isr;
        4:
            _1748 <= t1_osr;
        default:
            _1748 <= _363;
        endcase
    end
    assign _2481 = _1655 == _521;
    assign _2482 = _2481 ? _1748 : t1_x;
    assign _1658 = _68[5:3];
    assign _1660 = _1658 < _3015;
    assign _1655 = _68[8:6];
    assign _1657 = _1655 < _3015;
    assign _1661 = _1657 & _1660;
    assign _2483 = _1661 ? _2482 : t1_x;
    assign _2414 = _68[4:0];
    assign _2415 = { _511,
                     _2414 };
    assign _1605 = _68[8:7];
    assign _2477 = _1605 == _191;
    assign _2478 = _2477 ? _2415 : t1_x;
    assign _2475 = _1530 == _3015;
    assign _2479 = _2475 ? _2478 : t1_x;
    assign _2474 = _1530 == _3032;
    assign _2484 = _2474 ? _2483 : _2479;
    assign _2473 = _1530 == _3066;
    assign _2488 = _2473 ? _2487 : _2484;
    assign _2472 = _1530 == _521;
    assign _2494 = _2472 ? _2493 : _2488;
    assign _2495 = _1599 ? _2494 : t1_x;
    assign _2496 = _1555 ? t1_x : _2495;
    assign _2497 = _1552 ? t1_x : _2496;
    assign _2499 = _1551 ? _363 : _2497;
    assign _64 = _2499;
    assign _65 = _64;
    always @(posedge _106) begin
        if (_104)
            t1_x <= _363;
        else
            t1_x <= _65;
    end
    assign _2503 = t1_x == _363;
    assign _2504 = ~ _2503;
    assign _2505 = ~ _2504;
    assign _2460 = _68[8:6];
    always @* begin
        case (_2460)
        0:
            _2514 <= vdd;
        1:
            _2514 <= _2505;
        2:
            _2514 <= _2504;
        3:
            _2514 <= _2509;
        4:
            _2514 <= _2508;
        5:
            _2514 <= _2511;
        6:
            _2514 <= _2512;
        default:
            _2514 <= _2513;
        endcase
    end
    assign _2501 = _1530 == _521;
    assign _2515 = _2501 & _2514;
    assign _2521 = _2515 | _2520;
    assign _2529 = _2521 ? _2528 : _2523;
    always @(posedge _106) begin
        if (_104)
            t1_pc <= _312;
        else
            t1_pc <= _67;
    end
    assign _2530 = _1599 ? _2529 : t1_pc;
    assign _2531 = _1555 ? t1_pc : _2530;
    assign _2532 = _1552 ? t1_pc : _2531;
    assign _2533 = _1551 ? cfg_t1_start : _2532;
    assign _66 = _2533;
    assign _67 = _66;
    assign _2538 = _1512 ? _2537 : _67;
    assign _2534 = ~ _1512;
    RM_IHPSG13_1P_256x16_c2_bm_bist
        sram1
        ( .A_CLK(_106),
          .A_MEN(vdd),
          .A_WEN(_1512),
          .A_REN(_2534),
          .A_ADDR(_2538),
          .A_DIN(_592),
          .A_DLY(vdd),
          .A_BM(_3381),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_312),
          .A_BIST_DIN(_363),
          .A_BIST_BM(_363),
          .A_DOUT(_2544[15:0]) );
    assign _68 = _2544;
    assign _1530 = _68[15:13];
    assign _1557 = _1530 == _629;
    assign _1571 = _1557 & _1570;
    assign _1584 = _1571 & _1583;
    assign _1591 = _1584 | _1590;
    assign _1597 = _1591 | _1596;
    assign _1598 = ~ _1597;
    assign _1528 = t1_delay_left == _308;
    assign _1523 = _1517 & _1522;
    assign _1529 = _1523 & _1528;
    assign _1599 = _1529 & _1598;
    assign _2557 = _1599 ? _2556 : t1_delay_left;
    assign _2560 = _1555 ? _2559 : _2557;
    assign _2561 = _1552 ? t1_delay_left : _2560;
    assign _2563 = _1551 ? _308 : _2561;
    assign _69 = _2563;
    assign _70 = _69;
    always @(posedge _106) begin
        if (_104)
            t1_delay_left <= _308;
        else
            t1_delay_left <= _70;
    end
    assign _1554 = t1_delay_left == _308;
    assign _1555 = ~ _1554;
    assign _3135 = _1555 ? _24 : _3134;
    assign _2575 = cfg_t1_clkdiv - _753;
    assign _2565 = 7'b1011101;
    assign _2566 = _588 == _2565;
    assign _2564 = _582 & _586;
    assign _2567 = _2564 & _2566;
    assign _2568 = _2567 ? _592 : cfg_t1_clkdiv;
    assign _71 = _2568;
    always @(posedge _106) begin
        if (_104)
            cfg_t1_clkdiv <= _363;
        else
            cfg_t1_clkdiv <= _71;
    end
    assign _2573 = cfg_t1_clkdiv == _363;
    assign _2577 = _2573 ? _363 : _2575;
    assign _2571 = t1_div_count - _753;
    assign _2578 = _1522 ? _2577 : _2571;
    assign _2569 = ~ _1517;
    assign _2580 = _2569 ? _363 : _2578;
    assign _72 = _2580;
    always @(posedge _106) begin
        if (_104)
            t1_div_count <= _363;
        else
            t1_div_count <= _72;
    end
    assign _1522 = t1_div_count == _363;
    assign _1552 = ~ _1522;
    assign _3136 = _1552 ? _24 : _3135;
    assign _1511 = ~ _1509;
    assign _1510 = _602[1:1];
    assign _1512 = _1510 & _1511;
    always @(posedge _106) begin
        if (_104)
            t1_loaded <= _576;
        else
            t1_loaded <= _1512;
    end
    assign _1516 = ~ t1_loaded;
    assign _1509 = cfg_ctrl[1:1];
    assign _1517 = _1509 & _1516;
    assign _1551 = ~ _1517;
    assign _3137 = _1551 ? _24 : _3136;
    assign _73 = _3137;
    assign _74 = _73;
    always @(posedge _106) begin
        if (_104)
            pin_out <= _124;
        else
            pin_out <= _74;
    end
    assign _643 = pin_out[7:7];
    assign _639 = ~ cfg_sync_bypass;
    always @(posedge _106) begin
        if (_104)
            pins_sync1 <= _124;
        else
            pins_sync1 <= _77;
    end
    always @(posedge _106) begin
        if (_104)
            pins_sync2 <= _124;
        else
            pins_sync2 <= pins_sync1;
    end
    assign _640 = pins_sync2 & _639;
    assign _3142 = _592[7:0];
    assign _3139 = 7'b1001110;
    assign _3140 = _588 == _3139;
    assign _3138 = _582 & _586;
    assign _3141 = _3138 & _3140;
    assign _3143 = _3141 ? _3142 : cfg_sync_bypass;
    assign _75 = _3143;
    always @(posedge _106) begin
        if (_104)
            cfg_sync_bypass <= _312;
        else
            cfg_sync_bypass <= _75;
    end
    assign _77 = uio_in;
    assign _633 = _77 & cfg_sync_bypass;
    assign _641 = _633 | _640;
    assign _642 = _641[7:7];
    assign _3145 = 7'b1000111;
    assign _3146 = _588 == _3145;
    assign _3144 = _582 & _586;
    assign _3147 = _3144 & _3146;
    assign _3148 = _3147 ? _592 : cfg_pin_modes;
    assign _78 = _3148;
    always @(posedge _106) begin
        if (_104)
            cfg_pin_modes <= _363;
        else
            cfg_pin_modes <= _78;
    end
    assign _632 = cfg_pin_modes[15:14];
    always @* begin
        case (_632)
        0:
            _645 <= _642;
        1:
            _645 <= _643;
        2:
            _645 <= _644;
        default:
            _645 <= _642;
        endcase
    end
    assign _681 = { _645,
                    _650,
                    _655,
                    _660,
                    _665,
                    _670,
                    _675,
                    _680 };
    assign _1022 = { _312,
                     _681 };
    assign _3309 = t0_y - _753;
    assign _3307 = _3305 == _3476;
    assign _3310 = _3307 ? _3309 : t0_y;
    assign _1208 = _1206[31:16];
    assign _1209 = { _363,
                     _1208 };
    assign _1204 = _1202[31:8];
    assign _1205 = { _312,
                     _1204 };
    assign _1200 = _1198[31:4];
    assign _1201 = { _308,
                     _1200 };
    assign _1196 = _1194[31:2];
    assign _1197 = { _527,
                     _1196 };
    assign _1192 = _1190[31:1];
    assign _1193 = { _576,
                     _1192 };
    assign _1190 = { _363,
                     t0_osr };
    assign _1188 = _1183[0:0];
    assign _1194 = _1188 ? _1193 : _1190;
    assign _1187 = _1183[1:1];
    assign _1198 = _1187 ? _1197 : _1194;
    assign _1186 = _1183[2:2];
    assign _1202 = _1186 ? _1201 : _1198;
    assign _1185 = _1183[3:3];
    assign _1206 = _1185 ? _1205 : _1202;
    assign _1183 = _259 - _811;
    assign _1184 = _1183[4:4];
    assign _1210 = _1184 ? _1209 : _1206;
    assign _1211 = _1210[15:0];
    assign _1175 = _1174[15:0];
    assign _1177 = { _1175,
                     _363 };
    assign _1171 = _1170[23:0];
    assign _1173 = { _1171,
                     _312 };
    assign _1167 = _1166[27:0];
    assign _1169 = { _1167,
                     _308 };
    assign _1163 = _1162[29:0];
    assign _1165 = { _1163,
                     _527 };
    assign _1159 = _811[0:0];
    assign _1162 = _1159 ? _301 : _300;
    assign _1158 = _811[1:1];
    assign _1166 = _1158 ? _1165 : _1162;
    assign _1157 = _811[2:2];
    assign _1170 = _1157 ? _1169 : _1166;
    assign _1156 = _811[3:3];
    assign _1174 = _1156 ? _1173 : _1170;
    assign _1155 = _811[4:4];
    assign _1178 = _1155 ? _1177 : _1174;
    assign _1179 = _1178[15:0];
    assign _1180 = ~ _1179;
    assign _3268 = _3267[15:0];
    assign _3270 = { _3268,
                     _363 };
    assign _3264 = _3263[23:0];
    assign _3266 = { _3264,
                     _312 };
    assign _3260 = _3259[27:0];
    assign _3262 = { _3260,
                     _308 };
    assign _3256 = _3255[29:0];
    assign _3258 = { _3256,
                     _527 };
    assign _3252 = _3251[30:0];
    assign _3254 = { _3252,
                     _576 };
    assign _3251 = { _363,
                     t0_osr };
    assign _3249 = _811[0:0];
    assign _3255 = _3249 ? _3254 : _3251;
    assign _3248 = _811[1:1];
    assign _3259 = _3248 ? _3258 : _3255;
    assign _3247 = _811[2:2];
    assign _3263 = _3247 ? _3262 : _3259;
    assign _3246 = _811[3:3];
    assign _3267 = _3246 ? _3266 : _3263;
    assign _3245 = _811[4:4];
    assign _3271 = _3245 ? _3270 : _3267;
    assign _3272 = _3271[15:0];
    assign _3241 = _3239[31:16];
    assign _3242 = { _363,
                     _3241 };
    assign _3237 = _3235[31:8];
    assign _3238 = { _312,
                     _3237 };
    assign _3233 = _3231[31:4];
    assign _3234 = { _308,
                     _3233 };
    assign _3229 = _3227[31:2];
    assign _3230 = { _527,
                     _3229 };
    assign _3225 = _3223[31:1];
    assign _3226 = { _576,
                     _3225 };
    assign _3223 = { _363,
                     t0_osr };
    assign _3221 = _811[0:0];
    assign _3227 = _3221 ? _3226 : _3223;
    assign _3220 = _811[1:1];
    assign _3231 = _3220 ? _3230 : _3227;
    assign _3219 = _811[2:2];
    assign _3235 = _3219 ? _3234 : _3231;
    assign _3218 = _811[3:3];
    assign _3239 = _3218 ? _3238 : _3235;
    assign _809 = { gnd,
                    _806 };
    assign _806 = _92[3:0];
    assign _808 = _806 == _308;
    assign _811 = _808 ? _259 : _809;
    assign _3217 = _811[4:4];
    assign _3243 = _3217 ? _3242 : _3239;
    assign _3244 = _3243[15:0];
    assign _3273 = _1154 ? _3272 : _3244;
    assign _3211 = t0_tx_wr == _545;
    assign _3212 = _3156 & _3211;
    always @(posedge _106) begin
        if (_104)
            t0_tx_mem_3 <= _363;
        else
            if (_3212)
                t0_tx_mem_3 <= _592;
    end
    assign _3205 = t0_tx_wr == _194;
    assign _3206 = _3156 & _3205;
    always @(posedge _106) begin
        if (_104)
            t0_tx_mem_2 <= _363;
        else
            if (_3206)
                t0_tx_mem_2 <= _592;
    end
    assign _3199 = t0_tx_wr == _191;
    assign _3200 = _3156 & _3199;
    always @(posedge _106) begin
        if (_104)
            t0_tx_mem_1 <= _363;
        else
            if (_3200)
                t0_tx_mem_1 <= _592;
    end
    assign _3161 = t0_tx_wr + _191;
    assign _3162 = _3156 ? _3161 : t0_tx_wr;
    assign _79 = _3162;
    always @(posedge _106) begin
        if (_104)
            t0_tx_wr <= _527;
        else
            t0_tx_wr <= _79;
    end
    assign _3193 = t0_tx_wr == _527;
    assign _3194 = _3156 & _3193;
    always @(posedge _106) begin
        if (_104)
            t0_tx_mem_0 <= _363;
        else
            if (_3194)
                t0_tx_mem_0 <= _592;
    end
    assign _3181 = t0_tx_rd + _191;
    assign _3167 = ~ _713;
    assign _3169 = { _527,
                     _3168 };
    assign _3154 = t0_tx_level == _3476;
    assign _3155 = ~ _3154;
    assign _3150 = 7'b1001000;
    assign _3151 = _588 == _3150;
    assign _3149 = _582 & _586;
    assign _3152 = _3149 & _3151;
    assign _3156 = _3152 & _3155;
    assign _3164 = { _527,
                     _3156 };
    assign _3165 = t0_tx_level + _3164;
    assign _3170 = _3165 - _3169;
    assign _80 = _3170;
    always @(posedge _106) begin
        if (_104)
            t0_tx_level <= _521;
        else
            t0_tx_level <= _80;
    end
    assign _713 = t0_tx_level == _521;
    assign _3175 = ~ _713;
    assign _3172 = _628 == _3476;
    assign _3173 = _627 & _3172;
    assign _3174 = _3173 & _710;
    assign _3176 = _3174 & _3175;
    assign _81 = _3176;
    assign _3168 = _81 & _3167;
    assign _3182 = _3168 ? _3181 : t0_tx_rd;
    assign _82 = _3182;
    always @(posedge _106) begin
        if (_104)
            t0_tx_rd <= _527;
        else
            t0_tx_rd <= _82;
    end
    always @* begin
        case (t0_tx_rd)
        0:
            _3214 <= t0_tx_mem_0;
        1:
            _3214 <= t0_tx_mem_1;
        2:
            _3214 <= t0_tx_mem_2;
        default:
            _3214 <= t0_tx_mem_3;
        endcase
    end
    assign _710 = _92[8:8];
    assign _3215 = _710 ? _3214 : t0_osr;
    assign _3186 = _788 == _3476;
    assign _3187 = _3186 ? _1030 : t0_osr;
    assign _3188 = _794 ? _3187 : t0_osr;
    assign _3185 = _628 == _3032;
    assign _3189 = _3185 ? _3188 : t0_osr;
    assign _3184 = _628 == _3476;
    assign _3216 = _3184 ? _3215 : _3189;
    assign _3183 = _628 == _3066;
    assign _3274 = _3183 ? _3273 : _3216;
    assign _3275 = _723 ? _3274 : t0_osr;
    assign _3276 = _623 ? t0_osr : _3275;
    assign _3277 = _617 ? t0_osr : _3276;
    assign _3279 = _611 ? _363 : _3277;
    assign _83 = _3279;
    assign _84 = _83;
    always @(posedge _106) begin
        if (_104)
            t0_osr <= _363;
        else
            t0_osr <= _84;
    end
    assign _1181 = t0_osr & _1180;
    assign _3284 = _592[1:0];
    assign _3281 = 7'b1001111;
    assign _3282 = _588 == _3281;
    assign _3280 = _582 & _586;
    assign _3283 = _3280 & _3282;
    assign _3285 = _3283 ? _3284 : cfg_t0_shift;
    assign _85 = _3285;
    always @(posedge _106) begin
        if (_104)
            cfg_t0_shift <= _527;
        else
            cfg_t0_shift <= _85;
    end
    assign _1154 = cfg_t0_shift[0:0];
    assign _1212 = _1154 ? _1211 : _1181;
    assign _3300 = _92[8:7];
    assign _3302 = _3300 == _194;
    assign _3303 = _3302 ? _1212 : t0_y;
    assign _3296 = _788 == _629;
    assign _3297 = _3296 ? _1030 : t0_y;
    assign _3298 = _794 ? _3297 : t0_y;
    assign _3292 = _729 == _194;
    assign _3293 = _3292 ? _890 : t0_y;
    assign _3290 = _628 == _3015;
    assign _3294 = _3290 ? _3293 : t0_y;
    assign _3289 = _628 == _3032;
    assign _3299 = _3289 ? _3298 : _3294;
    assign _3288 = _628 == _3066;
    assign _3304 = _3288 ? _3303 : _3299;
    assign _3287 = _628 == _521;
    assign _3311 = _3287 ? _3310 : _3304;
    assign _3312 = _723 ? _3311 : t0_y;
    assign _3313 = _623 ? t0_y : _3312;
    assign _3314 = _617 ? t0_y : _3313;
    assign _3316 = _611 ? _363 : _3314;
    assign _86 = _3316;
    assign _87 = _86;
    always @(posedge _106) begin
        if (_104)
            t0_y <= _363;
        else
            t0_y <= _87;
    end
    always @* begin
        case (_791)
        0:
            _1030 <= t0_x;
        1:
            _1030 <= t0_y;
        2:
            _1030 <= _1022;
        3:
            _1030 <= t0_isr;
        4:
            _1030 <= t0_osr;
        default:
            _1030 <= _363;
        endcase
    end
    assign _3326 = _788 == _521;
    assign _3327 = _3326 ? _1030 : t0_x;
    assign _791 = _92[5:3];
    assign _793 = _791 < _3015;
    assign _788 = _92[8:6];
    assign _790 = _788 < _3015;
    assign _794 = _790 & _793;
    assign _3328 = _794 ? _3327 : t0_x;
    assign _889 = _92[4:0];
    assign _890 = { _511,
                    _889 };
    assign _729 = _92[8:7];
    assign _3322 = _729 == _191;
    assign _3323 = _3322 ? _890 : t0_x;
    assign _3320 = _628 == _3015;
    assign _3324 = _3320 ? _3323 : t0_x;
    assign _3319 = _628 == _3032;
    assign _3329 = _3319 ? _3328 : _3324;
    assign _3318 = _628 == _3066;
    assign _3333 = _3318 ? _3332 : _3329;
    assign _3317 = _628 == _521;
    assign _3339 = _3317 ? _3338 : _3333;
    assign _3340 = _723 ? _3339 : t0_x;
    assign _3341 = _623 ? t0_x : _3340;
    assign _3342 = _617 ? t0_x : _3341;
    assign _3344 = _611 ? _363 : _3342;
    assign _88 = _3344;
    assign _89 = _88;
    always @(posedge _106) begin
        if (_104)
            t0_x <= _363;
        else
            t0_x <= _89;
    end
    assign _3348 = t0_x == _363;
    assign _3349 = ~ _3348;
    assign _3350 = ~ _3349;
    assign _3305 = _92[8:6];
    always @* begin
        case (_3305)
        0:
            _3359 <= vdd;
        1:
            _3359 <= _3350;
        2:
            _3359 <= _3349;
        3:
            _3359 <= _3354;
        4:
            _3359 <= _3353;
        5:
            _3359 <= _3356;
        6:
            _3359 <= _3357;
        default:
            _3359 <= _3358;
        endcase
    end
    assign _3346 = _628 == _521;
    assign _3360 = _3346 & _3359;
    assign _3366 = _3360 | _3365;
    assign _3374 = _3366 ? _3373 : _3368;
    always @(posedge _106) begin
        if (_104)
            t0_pc <= _312;
        else
            t0_pc <= _91;
    end
    assign _3375 = _723 ? _3374 : t0_pc;
    assign _3376 = _623 ? t0_pc : _3375;
    assign _3377 = _617 ? t0_pc : _3376;
    assign _3378 = _611 ? cfg_t0_start : _3377;
    assign _90 = _3378;
    assign _91 = _90;
    assign _3380 = _605 ? _2537 : _91;
    assign _3379 = ~ _605;
    RM_IHPSG13_1P_256x16_c2_bm_bist
        sram0
        ( .A_CLK(_106),
          .A_MEN(vdd),
          .A_WEN(_605),
          .A_REN(_3379),
          .A_ADDR(_3380),
          .A_DIN(_592),
          .A_DLY(vdd),
          .A_BM(_3381),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_312),
          .A_BIST_DIN(_363),
          .A_BIST_BM(_363),
          .A_DOUT(_3386[15:0]) );
    assign _92 = _3386;
    assign _628 = _92[15:13];
    assign _630 = _628 == _629;
    assign _694 = _630 & _693;
    assign _707 = _694 & _706;
    assign _715 = _707 | _714;
    assign _721 = _715 | _720;
    assign _722 = ~ _721;
    assign _723 = _627 & _722;
    assign _3397 = _723 ? _3396 : t0_delay_left;
    assign _622 = t0_delay_left == _308;
    assign _623 = ~ _622;
    assign _3400 = _623 ? _3399 : _3397;
    assign _617 = ~ _616;
    assign _3401 = _617 ? t0_delay_left : _3400;
    assign _611 = ~ _610;
    assign _3403 = _611 ? _308 : _3401;
    assign _93 = _3403;
    assign _94 = _93;
    always @(posedge _106) begin
        if (_104)
            t0_delay_left <= _308;
        else
            t0_delay_left <= _94;
    end
    assign _626 = t0_delay_left == _308;
    assign _3415 = cfg_t0_clkdiv - _753;
    assign _3405 = 7'b1001101;
    assign _3406 = _588 == _3405;
    assign _3404 = _582 & _586;
    assign _3407 = _3404 & _3406;
    assign _3408 = _3407 ? _592 : cfg_t0_clkdiv;
    assign _95 = _3408;
    always @(posedge _106) begin
        if (_104)
            cfg_t0_clkdiv <= _363;
        else
            cfg_t0_clkdiv <= _95;
    end
    assign _3413 = cfg_t0_clkdiv == _363;
    assign _3417 = _3413 ? _363 : _3415;
    assign _3411 = t0_div_count - _753;
    assign _3418 = _616 ? _3417 : _3411;
    assign _3409 = ~ _610;
    assign _3420 = _3409 ? _363 : _3418;
    assign _96 = _3420;
    always @(posedge _106) begin
        if (_104)
            t0_div_count <= _363;
        else
            t0_div_count <= _96;
    end
    assign _616 = t0_div_count == _363;
    assign _604 = ~ _595;
    assign _488 = 6'b110000;
    assign _3425 = _592[5:0];
    assign _3422 = 7'b1010000;
    assign _3423 = _588 == _3422;
    assign _3421 = _582 & _586;
    assign _3424 = _3421 & _3423;
    assign _3426 = _3424 ? _3425 : cfg_load;
    assign _97 = _3426;
    always @(posedge _106) begin
        if (_104)
            cfg_load <= _488;
        else
            cfg_load <= _97;
    end
    assign _601 = cfg_load[5:4];
    assign _597 = 7'b1000000;
    assign _598 = _588 < _597;
    assign _596 = _582 & _586;
    assign _599 = _596 & _598;
    assign _600 = { _599,
                    _599 };
    assign _602 = _600 & _601;
    assign _603 = _602[0:0];
    assign _605 = _603 & _604;
    always @(posedge _106) begin
        if (_104)
            t0_loaded <= _576;
        else
            t0_loaded <= _605;
    end
    assign _609 = ~ t0_loaded;
    assign _595 = cfg_ctrl[0:0];
    assign _610 = _595 & _609;
    assign _624 = _610 & _616;
    assign _627 = _624 & _626;
    assign _3429 = _627 & _3428;
    assign _3431 = _3429 & _3430;
    assign _3433 = _3431 & _3432;
    assign _98 = _3433;
    assign _429 = _98 & _428;
    assign _3435 = { _527,
                     _429 };
    assign _3436 = t0_rx_level + _3435;
    assign _3439 = _3436 - _3438;
    assign _99 = _3439;
    always @(posedge _106) begin
        if (_104)
            t0_rx_level <= _521;
        else
            t0_rx_level <= _99;
    end
    assign _2281 = t0_rx_level == _521;
    assign _3460 = ~ _2281;
    assign _592 = _375[15:0];
    assign _3458 = _592[2:0];
    assign _588 = host_cmd[6:0];
    assign _3456 = _588 == _597;
    assign _370 = _108[2:2];
    always @(posedge _106) begin
        if (_104)
            host_mosi_s1 <= gnd;
        else
            host_mosi_s1 <= _370;
    end
    always @(posedge _106) begin
        if (_104)
            host_mosi_s2 <= gnd;
        else
            host_mosi_s2 <= host_mosi_s1;
    end
    assign _368 = 23'b00000000000000000000000;
    assign _3440 = _375[22:0];
    assign _3441 = _361 ? _3440 : host_shift_in;
    assign _3442 = host_cs_n_s2 ? host_shift_in : _3441;
    assign _100 = _3442;
    always @(posedge _106) begin
        if (_104)
            host_shift_in <= _368;
        else
            host_shift_in <= _100;
    end
    assign _375 = { host_shift_in,
                    host_mosi_s2 };
    assign _376 = _375[7:0];
    assign _366 = host_bit_count == _1773;
    assign _3443 = _366 ? _376 : host_cmd;
    assign _3444 = _361 ? _3443 : host_cmd;
    assign _3445 = host_cs_n_s2 ? host_cmd : _3444;
    assign _101 = _3445;
    always @(posedge _106) begin
        if (_104)
            host_cmd <= _312;
        else
            host_cmd <= _101;
    end
    assign _586 = host_cmd[7:7];
    assign _580 = 5'b10111;
    assign _3449 = host_bit_count + _1857;
    assign _3446 = 5'b11000;
    assign _3447 = host_bit_count < _3446;
    assign _3450 = _3447 ? _3449 : host_bit_count;
    assign _3451 = _361 ? _3450 : host_bit_count;
    assign _3453 = host_cs_n_s2 ? _780 : _3451;
    assign _102 = _3453;
    always @(posedge _106) begin
        if (_104)
            host_bit_count <= _780;
        else
            host_bit_count <= _102;
    end
    assign _581 = host_bit_count == _580;
    assign _333 = _108[1:1];
    always @(posedge _106) begin
        if (_104)
            host_cs_n_s1 <= vdd;
        else
            host_cs_n_s1 <= _333;
    end
    always @(posedge _106) begin
        if (_104)
            host_cs_n_s2 <= vdd;
        else
            host_cs_n_s2 <= host_cs_n_s1;
    end
    assign _360 = ~ host_cs_n_s2;
    always @(posedge _106) begin
        if (_104)
            host_sck_prev <= _576;
        else
            host_sck_prev <= host_sck_s2;
    end
    assign _358 = ~ host_sck_prev;
    assign vdd = 1'b1;
    assign _104 = clear;
    assign _106 = clock;
    assign _108 = ui_in;
    assign _338 = _108[0:0];
    always @(posedge _106) begin
        if (_104)
            host_sck_s1 <= gnd;
        else
            host_sck_s1 <= _338;
    end
    always @(posedge _106) begin
        if (_104)
            host_sck_s2 <= gnd;
        else
            host_sck_s2 <= host_sck_s1;
    end
    assign _359 = host_sck_s2 & _358;
    assign _361 = _359 & _360;
    assign _582 = _361 & _581;
    assign _3454 = _582 & _586;
    assign _3457 = _3454 & _3456;
    assign _3459 = _3457 ? _3458 : cfg_ctrl;
    assign _109 = _3459;
    always @(posedge _106) begin
        if (_104)
            cfg_ctrl <= _521;
        else
            cfg_ctrl <= _109;
    end
    assign _1965 = cfg_ctrl[2:2];
    assign _3461 = _1965 & _3460;
    assign _3463 = _3461 & _3462;
    assign _110 = _3463;
    assign _1968 = _110 | _1967;
    assign _1972 = _1968 & _1971;
    assign _3465 = { _527,
                     _1972 };
    assign _3466 = t1_tx_level + _3465;
    assign _3469 = _3466 - _3468;
    assign _111 = _3469;
    always @(posedge _106) begin
        if (_104)
            t1_tx_level <= _521;
        else
            t1_tx_level <= _111;
    end
    assign _3471 = t1_tx_level == _3476;
    assign gnd = 1'b0;
    assign _3483 = { gnd,
                     _3471,
                     _3474,
                     _3475,
                     _3477,
                     _3480,
                     _3481,
                     _3482 };
    assign uo_out = _3483;
    assign uio_out = _241;
    assign uio_oe = _200;

endmodule
