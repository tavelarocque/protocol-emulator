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

    wire _191;
    wire _192;
    wire [1:0] _189;
    wire [1:0] _188;
    wire _190;
    wire _193;
    wire [1:0] _186;
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
    wire [1:0] _148;
    wire _150;
    wire _153;
    wire [1:0] _145;
    wire _147;
    wire _154;
    wire _141;
    wire _142;
    wire [1:0] _138;
    wire _140;
    wire _143;
    wire [1:0] _135;
    wire _137;
    wire _144;
    wire _131;
    wire _132;
    wire [1:0] _128;
    wire _130;
    wire _133;
    wire [1:0] _125;
    wire _127;
    wire _134;
    wire _121;
    wire _122;
    wire [1:0] _115;
    wire _117;
    wire _123;
    wire [1:0] _112;
    wire _114;
    wire _124;
    wire [7:0] _195;
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
    wire _199;
    wire [1:0] _196;
    wire _198;
    wire _200;
    wire [7:0] _236;
    wire [15:0] _358;
    wire _566;
    wire [14:0] _565;
    wire [15:0] _567;
    wire [13:0] _560;
    wire [15:0] _561;
    wire [9:0] _552;
    wire [15:0] _556;
    wire _544;
    wire [15:0] _548;
    wire [1:0] _535;
    wire _536;
    wire _537;
    reg [15:0] t1_rx_mem_3;
    wire _530;
    wire _531;
    reg [15:0] t1_rx_mem_2;
    wire _524;
    wire _525;
    reg [15:0] t1_rx_mem_1;
    wire [1:0] _517;
    wire [1:0] _248;
    wire [1:0] _249;
    wire [1:0] _3;
    reg [1:0] t1_rx_wr;
    wire _518;
    wire _519;
    wire [15:0] _310;
    wire [31:0] _312;
    wire [7:0] _307;
    wire [23:0] _306;
    wire [31:0] _308;
    wire [3:0] _303;
    wire [27:0] _302;
    wire [31:0] _304;
    wire [29:0] _298;
    wire [31:0] _300;
    wire [31:0] _296;
    wire [31:0] _295;
    wire _294;
    wire [31:0] _297;
    wire _293;
    wire [31:0] _301;
    wire _292;
    wire [31:0] _305;
    wire _291;
    wire [31:0] _309;
    wire _290;
    wire [31:0] _313;
    wire [15:0] _314;
    wire [15:0] _315;
    wire [15:0] _316;
    wire [15:0] _286;
    wire [31:0] _287;
    wire [23:0] _282;
    wire [31:0] _283;
    wire [27:0] _278;
    wire [31:0] _279;
    wire [29:0] _274;
    wire [31:0] _275;
    wire [30:0] _270;
    wire [31:0] _271;
    wire [31:0] _268;
    wire _263;
    wire [31:0] _272;
    wire _262;
    wire [31:0] _276;
    wire _261;
    wire [31:0] _280;
    wire _260;
    wire [31:0] _284;
    wire [4:0] _254;
    wire [4:0] _258;
    wire _259;
    wire [31:0] _288;
    wire [15:0] _289;
    wire [15:0] _317;
    wire [15:0] _4;
    reg [15:0] t1_rx_mem_0;
    wire [1:0] _326;
    wire [1:0] _327;
    wire [1:0] _5;
    reg [1:0] t1_rx_rd;
    reg [15:0] _539;
    wire [2:0] _511;
    wire _512;
    wire _513;
    wire [15:0] _540;
    wire [15:0] _510;
    wire [10:0] _501;
    wire [15:0] _505;
    wire [12:0] _496;
    wire [15:0] _500;
    wire [15:0] _495;
    wire [15:0] _490;
    wire [15:0] _485;
    wire [15:0] _480;
    wire [15:0] _475;
    wire [15:0] _467;
    wire _455;
    wire [15:0] _459;
    wire _413;
    wire _414;
    wire [15:0] _451;
    wire [15:0] _408;
    wire [15:0] _403;
    wire [15:0] _398;
    wire [15:0] _393;
    wire [15:0] _388;
    wire [15:0] _383;
    wire [15:0] _378;
    reg [15:0] _562;
    wire [15:0] _563;
    wire [15:0] _564;
    wire [4:0] _349;
    wire _350;
    wire _351;
    wire _344;
    wire _339;
    wire _343;
    wire _345;
    wire _352;
    wire [15:0] _568;
    wire [15:0] _569;
    wire [15:0] _6;
    reg [15:0] host_miso_shift;
    wire _3421;
    wire _3420;
    wire _3418;
    wire _3419;
    wire [2:0] _3415;
    wire _3416;
    wire _3414;
    wire _3412;
    wire _3413;
    wire [2:0] _3407;
    wire _1907;
    wire _1902;
    wire [6:0] _1898;
    wire _1899;
    wire _1897;
    wire _1900;
    wire _1903;
    wire _1906;
    wire _3401;
    wire [2:0] _3377;
    wire _423;
    wire _3371;
    wire _3369;
    wire _3367;
    wire [3:0] _3343;
    wire [3:0] _3344;
    wire [1:0] _3338;
    wire [3:0] _3339;
    wire [3:0] _3335;
    wire [3:0] _3334;
    wire _3333;
    wire [3:0] _3336;
    wire _3332;
    wire [3:0] _3340;
    wire [3:0] _3341;
    wire _422;
    wire _718;
    wire _717;
    wire _719;
    wire _720;
    wire _709;
    wire _711;
    wire _714;
    wire _706;
    wire _703;
    wire [2:0] _701;
    wire [15:0] _3326;
    wire [7:0] _583;
    wire [6:0] _579;
    wire _580;
    wire _577;
    wire _581;
    wire [7:0] _584;
    wire [7:0] _7;
    reg [7:0] cfg_t0_start;
    wire [5:0] _3316;
    wire [1:0] _3315;
    wire [7:0] _3317;
    wire [7:0] _589;
    wire [6:0] _586;
    wire _587;
    wire _585;
    wire _588;
    wire [7:0] _590;
    wire [7:0] _8;
    reg [7:0] cfg_t0_timeout_vector;
    wire _3314;
    wire [7:0] _3318;
    wire [7:0] _3311;
    wire [7:0] _3312;
    wire [15:0] _685;
    wire [15:0] _686;
    wire [15:0] _687;
    wire [15:0] _688;
    wire [15:0] _689;
    wire [15:0] _691;
    wire [15:0] _9;
    wire [15:0] _10;
    reg [15:0] t0_wait_count;
    wire [6:0] _693;
    wire _694;
    wire _692;
    wire _695;
    wire [15:0] _696;
    wire [15:0] _11;
    reg [15:0] cfg_t0_timeout;
    wire _724;
    wire _683;
    wire _670;
    wire _607;
    wire _671;
    wire _673;
    wire _684;
    wire _725;
    wire _727;
    wire _728;
    wire _729;
    wire _731;
    wire _12;
    wire _13;
    reg t0_waiting;
    wire [15:0] _680;
    wire _682;
    wire _672;
    wire _705;
    wire _668;
    wire _666;
    wire _665;
    wire _664;
    wire _663;
    wire _662;
    wire _661;
    wire _660;
    wire _659;
    wire [2:0] _608;
    reg _667;
    wire _669;
    wire _3307;
    wire _3306;
    wire _3308;
    wire _3309;
    wire _3302;
    wire [4:0] _739;
    wire [4:0] _401;
    wire [4:0] _736;
    wire [6:0] _733;
    wire _734;
    wire _732;
    wire _735;
    wire [4:0] _737;
    wire [4:0] _14;
    reg [4:0] cfg_t0_threshold;
    wire [4:0] _774;
    wire [5:0] _771;
    wire [5:0] _764;
    wire [5:0] _772;
    wire [5:0] _763;
    wire _773;
    wire [4:0] _776;
    wire [4:0] _761;
    wire _755;
    wire [4:0] _757;
    wire [4:0] _758;
    wire _746;
    wire [4:0] _759;
    wire _744;
    wire [4:0] _762;
    wire _742;
    wire [4:0] _777;
    wire [4:0] _778;
    wire [4:0] _779;
    wire [4:0] _780;
    wire [4:0] _781;
    wire [4:0] _15;
    wire [4:0] _16;
    reg [4:0] t0_osr_count;
    wire _3301;
    wire _3299;
    wire _3300;
    wire _3296;
    wire _3297;
    wire _3298;
    wire [15:0] _3281;
    wire [2:0] _3278;
    wire _3279;
    wire [15:0] _3282;
    wire _3275;
    wire [15:0] _3276;
    wire _656;
    wire _655;
    wire _654;
    wire [1:0] _653;
    reg _657;
    wire _651;
    wire _650;
    wire _649;
    wire [1:0] _648;
    reg _652;
    wire _646;
    wire _645;
    wire _644;
    wire [1:0] _643;
    reg _647;
    wire _641;
    wire _640;
    wire _639;
    wire [1:0] _638;
    reg _642;
    wire _636;
    wire _635;
    wire _634;
    wire [1:0] _633;
    reg _637;
    wire _631;
    wire _630;
    wire _629;
    wire [1:0] _628;
    reg _632;
    wire _626;
    wire _625;
    wire _624;
    wire [1:0] _623;
    reg _627;
    wire _621;
    wire [7:0] _119;
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
    wire [2:0] _3009;
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
    wire [2:0] _2975;
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
    wire _2965;
    reg _2973;
    wire _2964;
    wire [3:0] _2962;
    wire [2:0] _2958;
    wire [2:0] _2959;
    wire [3:0] _2960;
    wire _2963;
    wire _2974;
    wire _2955;
    wire _2954;
    wire _2953;
    wire _2952;
    wire _2951;
    wire _2950;
    wire _2949;
    wire [1:0] _2942;
    wire [3:0] _2943;
    wire [2:0] _2938;
    wire [3:0] _2939;
    wire _2936;
    wire [3:0] _2940;
    wire _2935;
    wire [3:0] _2944;
    wire [2:0] _2932;
    wire [2:0] _2933;
    wire _2934;
    wire [3:0] _2946;
    wire [7:0] _2947;
    wire _2948;
    reg _2956;
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
    wire _2812;
    wire _2811;
    wire _2810;
    wire _2809;
    wire _2808;
    wire _2807;
    wire _2806;
    wire _2805;
    reg _2813;
    wire _2804;
    wire [2:0] _2800;
    wire [2:0] _2801;
    wire [4:0] _2802;
    wire _2803;
    wire _2814;
    wire [7:0] _2927;
    wire _2794;
    wire _2793;
    wire _2792;
    wire _2791;
    wire _2790;
    wire _2789;
    wire _2788;
    wire _2787;
    reg _2795;
    wire _2786;
    wire [2:0] _2783;
    wire [3:0] _2784;
    wire _2785;
    wire _2796;
    wire _2779;
    wire _2778;
    wire _2777;
    wire _2776;
    wire _2775;
    wire _2774;
    wire _2773;
    wire _2772;
    reg _2780;
    wire _2771;
    wire [2:0] _2768;
    wire [3:0] _2769;
    wire _2770;
    wire _2781;
    wire _2764;
    wire _2763;
    wire _2762;
    wire _2761;
    wire _2760;
    wire _2759;
    wire _2758;
    wire _2757;
    reg _2765;
    wire _2756;
    wire [2:0] _2753;
    wire [3:0] _2754;
    wire _2755;
    wire _2766;
    wire _2749;
    wire _2748;
    wire _2747;
    wire _2746;
    wire _2745;
    wire _2744;
    wire _2743;
    wire _2742;
    reg _2750;
    wire _2741;
    wire [2:0] _2738;
    wire [3:0] _2739;
    wire _2740;
    wire _2751;
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
    wire [3:0] _2724;
    wire _2725;
    wire _2736;
    wire _2719;
    wire _2718;
    wire _2717;
    wire _2716;
    wire _2715;
    wire _2714;
    wire _2713;
    wire _2712;
    reg _2720;
    wire _2711;
    wire [2:0] _2708;
    wire [3:0] _2709;
    wire _2710;
    wire _2721;
    wire _2704;
    wire _2703;
    wire _2702;
    wire _2701;
    wire _2700;
    wire _2699;
    wire _2698;
    wire _2697;
    reg _2705;
    wire _2696;
    wire [2:0] _2693;
    wire [3:0] _2694;
    wire _2695;
    wire _2706;
    wire _2689;
    wire _2688;
    wire _2687;
    wire _2686;
    wire _2685;
    wire _2684;
    wire _2683;
    wire _2682;
    reg _2690;
    wire _2681;
    wire [3:0] _2679;
    wire [7:0] _488;
    wire [7:0] _786;
    wire [6:0] _783;
    wire _784;
    wire _782;
    wire _785;
    wire [7:0] _787;
    wire [7:0] _17;
    reg [7:0] cfg_t1_out_cfg;
    wire [2:0] _2676;
    wire [2:0] _2677;
    wire [3:0] _2678;
    wire _2680;
    wire _2691;
    wire [7:0] _2797;
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
    wire [3:0] _2660;
    wire _2661;
    wire _2672;
    wire _2655;
    wire _2654;
    wire _2653;
    wire _2652;
    wire _2651;
    wire _2650;
    wire _2649;
    wire _2648;
    reg _2656;
    wire _2647;
    wire [2:0] _2644;
    wire [3:0] _2645;
    wire _2646;
    wire _2657;
    wire _2640;
    wire _2639;
    wire _2638;
    wire _2637;
    wire _2636;
    wire _2635;
    wire _2634;
    wire _2633;
    reg _2641;
    wire _2632;
    wire [2:0] _2629;
    wire [3:0] _2630;
    wire _2631;
    wire _2642;
    wire _2625;
    wire _2624;
    wire _2623;
    wire _2622;
    wire _2621;
    wire _2620;
    wire _2619;
    wire _2618;
    reg _2626;
    wire _2617;
    wire [2:0] _2614;
    wire [3:0] _2615;
    wire _2616;
    wire _2627;
    wire _2610;
    wire _2609;
    wire _2608;
    wire _2607;
    wire _2606;
    wire _2605;
    wire _2604;
    wire _2603;
    reg _2611;
    wire _2602;
    wire [2:0] _2599;
    wire [3:0] _2600;
    wire _2601;
    wire _2612;
    wire _2595;
    wire _2594;
    wire _2593;
    wire _2592;
    wire _2591;
    wire _2590;
    wire _2589;
    wire _2588;
    reg _2596;
    wire _2587;
    wire [2:0] _2584;
    wire [3:0] _2585;
    wire _2586;
    wire _2597;
    wire _2580;
    wire _2579;
    wire _2578;
    wire _2577;
    wire _2576;
    wire _2575;
    wire _2574;
    wire _2573;
    reg _2581;
    wire _2572;
    wire [2:0] _2569;
    wire [3:0] _2570;
    wire _2571;
    wire _2582;
    wire _2565;
    wire _2564;
    wire _2563;
    wire _2562;
    wire _2561;
    wire _2560;
    wire _2559;
    wire _2558;
    reg _2566;
    wire _2557;
    wire [3:0] _2555;
    wire [7:0] _792;
    wire [6:0] _789;
    wire _790;
    wire _788;
    wire _791;
    wire [7:0] _793;
    wire [7:0] _18;
    reg [7:0] cfg_t1_set_cfg;
    wire [2:0] _2552;
    wire [2:0] _2553;
    wire [3:0] _2554;
    wire _2556;
    wire _2567;
    wire [7:0] _2673;
    wire _1443;
    wire _1442;
    wire _1441;
    wire _1440;
    wire _1439;
    wire _1438;
    wire _1437;
    wire _1436;
    reg _1444;
    wire _1435;
    wire [3:0] _1433;
    wire [2:0] _1430;
    wire [3:0] _1431;
    wire _1434;
    wire _1445;
    wire _1426;
    wire _1425;
    wire _1424;
    wire _1423;
    wire _1422;
    wire _1421;
    wire _1420;
    wire _1419;
    reg _1427;
    wire _1418;
    wire [3:0] _1416;
    wire [2:0] _1413;
    wire [3:0] _1414;
    wire _1417;
    wire _1428;
    wire _1409;
    wire _1408;
    wire _1407;
    wire _1406;
    wire _1405;
    wire _1404;
    wire _1403;
    wire _1402;
    reg _1410;
    wire _1401;
    wire [3:0] _1399;
    wire [2:0] _1396;
    wire [3:0] _1397;
    wire _1400;
    wire _1411;
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
    wire [3:0] _1382;
    wire [2:0] _1379;
    wire [3:0] _1380;
    wire _1383;
    wire _1394;
    wire _1375;
    wire _1374;
    wire _1373;
    wire _1372;
    wire _1371;
    wire _1370;
    wire _1369;
    wire _1368;
    reg _1376;
    wire _1367;
    wire [3:0] _1365;
    wire [2:0] _1362;
    wire [3:0] _1363;
    wire _1366;
    wire _1377;
    wire _1358;
    wire _1357;
    wire _1356;
    wire _1355;
    wire _1354;
    wire _1353;
    wire _1352;
    wire _1351;
    reg _1359;
    wire _1350;
    wire [3:0] _1348;
    wire [2:0] _1345;
    wire [3:0] _1346;
    wire _1349;
    wire _1360;
    wire _1341;
    wire _1340;
    wire _1339;
    wire _1338;
    wire _1337;
    wire _1336;
    wire _1335;
    wire _1334;
    reg _1342;
    wire _1333;
    wire [3:0] _1331;
    wire [2:0] _1328;
    wire [3:0] _1329;
    wire _1332;
    wire _1343;
    wire _1324;
    wire _1323;
    wire _1322;
    wire _1321;
    wire _1320;
    wire _1319;
    wire _1318;
    wire [1:0] _1311;
    wire [3:0] _1312;
    wire [2:0] _1307;
    wire [3:0] _1308;
    wire [3:0] _1305;
    wire _1304;
    wire [3:0] _1309;
    wire _1303;
    wire [3:0] _1313;
    wire [2:0] _1300;
    wire [2:0] _1301;
    wire _1302;
    wire [3:0] _1315;
    wire [7:0] _1316;
    wire _1317;
    reg _1325;
    wire _1292;
    wire _1291;
    wire _1290;
    wire _1289;
    wire _1288;
    wire _1287;
    wire _1286;
    wire _1285;
    reg _1293;
    wire _1284;
    wire [2:0] _1281;
    wire [4:0] _1282;
    wire _1283;
    wire _1294;
    wire _1276;
    wire _1275;
    wire _1274;
    wire _1273;
    wire _1272;
    wire _1271;
    wire _1270;
    wire _1269;
    reg _1277;
    wire _1268;
    wire [2:0] _1265;
    wire [4:0] _1266;
    wire _1267;
    wire _1278;
    wire _1260;
    wire _1259;
    wire _1258;
    wire _1257;
    wire _1256;
    wire _1255;
    wire _1254;
    wire _1253;
    reg _1261;
    wire _1252;
    wire [2:0] _1249;
    wire [4:0] _1250;
    wire _1251;
    wire _1262;
    wire _1244;
    wire _1243;
    wire _1242;
    wire _1241;
    wire _1240;
    wire _1239;
    wire _1238;
    wire _1237;
    reg _1245;
    wire _1236;
    wire [2:0] _1233;
    wire [4:0] _1234;
    wire _1235;
    wire _1246;
    wire _1228;
    wire _1227;
    wire _1226;
    wire _1225;
    wire _1224;
    wire _1223;
    wire _1222;
    wire _1221;
    reg _1229;
    wire _1220;
    wire [2:0] _1217;
    wire [4:0] _1218;
    wire _1219;
    wire _1230;
    wire _1212;
    wire _1211;
    wire _1210;
    wire _1209;
    wire _1208;
    wire _1207;
    wire _1206;
    wire _1205;
    reg _1213;
    wire _1204;
    wire [2:0] _1201;
    wire [4:0] _1202;
    wire _1203;
    wire _1214;
    wire _1196;
    wire _1195;
    wire _1194;
    wire _1193;
    wire _1192;
    wire _1191;
    wire _1190;
    wire _1189;
    reg _1197;
    wire _1188;
    wire [2:0] _1185;
    wire [4:0] _1186;
    wire _1187;
    wire _1198;
    wire _1180;
    wire _1179;
    wire _1178;
    wire _1177;
    wire _1176;
    wire _1175;
    wire _1174;
    wire _1173;
    reg _1181;
    wire _1113;
    wire [2:0] _1110;
    wire [4:0] _1111;
    wire _1112;
    wire _1182;
    wire [7:0] _1295;
    wire _1103;
    wire _1102;
    wire _1101;
    wire _1100;
    wire _1099;
    wire _1098;
    wire _1097;
    wire _1096;
    reg _1104;
    wire _1095;
    wire [2:0] _1092;
    wire [3:0] _1093;
    wire _1094;
    wire _1105;
    wire _1088;
    wire _1087;
    wire _1086;
    wire _1085;
    wire _1084;
    wire _1083;
    wire _1082;
    wire _1081;
    reg _1089;
    wire _1080;
    wire [2:0] _1077;
    wire [3:0] _1078;
    wire _1079;
    wire _1090;
    wire _1073;
    wire _1072;
    wire _1071;
    wire _1070;
    wire _1069;
    wire _1068;
    wire _1067;
    wire _1066;
    reg _1074;
    wire _1065;
    wire [2:0] _1062;
    wire [3:0] _1063;
    wire _1064;
    wire _1075;
    wire _1058;
    wire _1057;
    wire _1056;
    wire _1055;
    wire _1054;
    wire _1053;
    wire _1052;
    wire _1051;
    reg _1059;
    wire _1050;
    wire [2:0] _1047;
    wire [3:0] _1048;
    wire _1049;
    wire _1060;
    wire _1043;
    wire _1042;
    wire _1041;
    wire _1040;
    wire _1039;
    wire _1038;
    wire _1037;
    wire _1036;
    reg _1044;
    wire _1035;
    wire [2:0] _1032;
    wire [3:0] _1033;
    wire _1034;
    wire _1045;
    wire _1028;
    wire _1027;
    wire _1026;
    wire _1025;
    wire _1024;
    wire _1023;
    wire _1022;
    wire _1021;
    reg _1029;
    wire _1020;
    wire [2:0] _1017;
    wire [3:0] _1018;
    wire _1019;
    wire _1030;
    wire _1013;
    wire _1012;
    wire _1011;
    wire _1010;
    wire _1009;
    wire _1008;
    wire _1007;
    wire _1006;
    reg _1014;
    wire _1005;
    wire [2:0] _1002;
    wire [3:0] _1003;
    wire _1004;
    wire _1015;
    wire _998;
    wire _997;
    wire _996;
    wire _995;
    wire _994;
    wire _993;
    wire _992;
    wire _991;
    reg _999;
    wire _974;
    wire [3:0] _972;
    wire [7:0] _798;
    wire [6:0] _795;
    wire _796;
    wire _794;
    wire _797;
    wire [7:0] _799;
    wire [7:0] _19;
    reg [7:0] cfg_t0_out_cfg;
    wire [2:0] _969;
    wire [2:0] _970;
    wire [3:0] _971;
    wire _973;
    wire _1000;
    wire [7:0] _1106;
    wire _963;
    wire _962;
    wire _961;
    wire _960;
    wire _959;
    wire _958;
    wire _957;
    wire _956;
    reg _964;
    wire _955;
    wire [2:0] _952;
    wire [3:0] _953;
    wire _954;
    wire _965;
    wire _948;
    wire _947;
    wire _946;
    wire _945;
    wire _944;
    wire _943;
    wire _942;
    wire _941;
    reg _949;
    wire _940;
    wire [2:0] _937;
    wire [3:0] _938;
    wire _939;
    wire _950;
    wire _933;
    wire _932;
    wire _931;
    wire _930;
    wire _929;
    wire _928;
    wire _927;
    wire _926;
    reg _934;
    wire _925;
    wire [2:0] _922;
    wire [3:0] _923;
    wire _924;
    wire _935;
    wire _918;
    wire _917;
    wire _916;
    wire _915;
    wire _914;
    wire _913;
    wire _912;
    wire _911;
    reg _919;
    wire _910;
    wire [2:0] _907;
    wire [3:0] _908;
    wire _909;
    wire _920;
    wire _903;
    wire _902;
    wire _901;
    wire _900;
    wire _899;
    wire _898;
    wire _897;
    wire _896;
    reg _904;
    wire _895;
    wire [2:0] _892;
    wire [3:0] _893;
    wire _894;
    wire _905;
    wire _888;
    wire _887;
    wire _886;
    wire _885;
    wire _884;
    wire _883;
    wire _882;
    wire _881;
    reg _889;
    wire _880;
    wire [2:0] _877;
    wire [3:0] _878;
    wire _879;
    wire _890;
    wire _873;
    wire _872;
    wire _871;
    wire _870;
    wire _869;
    wire _868;
    wire _867;
    wire _866;
    reg _874;
    wire _865;
    wire [2:0] _862;
    wire [3:0] _863;
    wire _864;
    wire _875;
    wire _858;
    wire _857;
    wire _856;
    wire _855;
    wire _854;
    wire _853;
    wire _852;
    wire _851;
    reg _859;
    wire _847;
    wire [3:0] _845;
    wire [7:0] _804;
    wire [6:0] _801;
    wire _802;
    wire _800;
    wire _803;
    wire [7:0] _805;
    wire [7:0] _20;
    reg [7:0] cfg_t0_set_cfg;
    wire [2:0] _842;
    wire [2:0] _843;
    wire [3:0] _844;
    wire _846;
    wire _860;
    wire [7:0] _966;
    wire _839;
    wire _835;
    wire _836;
    wire _840;
    wire [7:0] _967;
    wire _831;
    wire _832;
    wire _828;
    wire _829;
    wire _833;
    wire [7:0] _1107;
    wire [1:0] _823;
    wire _825;
    wire _821;
    wire _822;
    wire _826;
    wire [7:0] _1296;
    wire _1297;
    wire [1:0] _817;
    wire [3:0] _818;
    wire [5:0] _465;
    wire [5:0] _810;
    wire [6:0] _807;
    wire _808;
    wire _806;
    wire _809;
    wire [5:0] _811;
    wire [5:0] _21;
    reg [5:0] cfg_t0_sideset;
    wire [2:0] _813;
    wire [2:0] _814;
    wire [3:0] _815;
    wire _819;
    wire _1326;
    wire [7:0] _1446;
    wire [7:0] _1447;
    wire [7:0] _1448;
    wire [7:0] _1449;
    wire [7:0] _22;
    wire _2549;
    wire _2546;
    wire _2547;
    wire _2550;
    wire [7:0] _2674;
    wire _2542;
    wire _2543;
    wire _2539;
    wire _2540;
    wire _2544;
    wire [7:0] _2798;
    wire [1:0] _2534;
    wire _2536;
    wire _2532;
    wire _2533;
    wire _2537;
    wire [7:0] _2928;
    wire _2929;
    wire [3:0] _2529;
    wire [2:0] _2525;
    wire [2:0] _2526;
    wire [3:0] _2527;
    wire _2530;
    wire _2957;
    wire [7:0] _3077;
    wire [3:0] _2502;
    wire [1:0] _2496;
    wire [3:0] _2497;
    wire _2491;
    wire [3:0] _2494;
    wire [5:0] _1454;
    wire [6:0] _1451;
    wire _1452;
    wire _1450;
    wire _1453;
    wire [5:0] _1455;
    wire [5:0] _23;
    reg [5:0] cfg_t1_sideset;
    wire [1:0] _2489;
    wire _2490;
    wire [3:0] _2498;
    wire [3:0] _2488;
    wire [3:0] _2499;
    wire _319;
    wire _320;
    wire _1466;
    wire _1467;
    wire [6:0] _1462;
    wire _1463;
    wire _1459;
    wire _1460;
    wire _1461;
    wire _1464;
    wire _1468;
    wire _24;
    wire _321;
    wire [2:0] _1495;
    wire _242;
    wire _1489;
    wire _1487;
    wire _1484;
    wire _1485;
    wire _1488;
    wire _1490;
    wire _25;
    wire _243;
    wire [2:0] _1492;
    wire [2:0] _1493;
    wire [2:0] _1496;
    wire [2:0] _26;
    reg [2:0] t1_rx_level;
    wire _241;
    wire _1571;
    wire _1570;
    wire _1572;
    wire _1573;
    wire _1563;
    wire _1564;
    wire _1567;
    wire _1560;
    wire _1557;
    wire [5:0] _2479;
    wire [1:0] _2478;
    wire [7:0] _2480;
    wire [7:0] _1501;
    wire [6:0] _1498;
    wire _1499;
    wire _1497;
    wire _1500;
    wire [7:0] _1502;
    wire [7:0] _27;
    reg [7:0] cfg_t1_start;
    wire [5:0] _2465;
    wire [1:0] _2464;
    wire [7:0] _2466;
    wire [7:0] _1507;
    wire [6:0] _1504;
    wire _1505;
    wire _1503;
    wire _1506;
    wire [7:0] _1508;
    wire [7:0] _28;
    reg [7:0] cfg_t1_timeout_vector;
    wire _2463;
    wire [7:0] _2467;
    wire [7:0] _2461;
    wire [15:0] _1544;
    wire [15:0] _1545;
    wire [15:0] _1546;
    wire [15:0] _1547;
    wire [15:0] _1549;
    wire [15:0] _29;
    wire [15:0] _30;
    reg [15:0] t1_wait_count;
    wire [6:0] _1551;
    wire _1552;
    wire _1550;
    wire _1553;
    wire [15:0] _1554;
    wire [15:0] _31;
    reg [15:0] cfg_t1_timeout;
    wire _1541;
    wire _1528;
    wire _1515;
    wire _1529;
    wire _1531;
    wire _1542;
    wire _1578;
    wire _1580;
    wire _1581;
    wire _1582;
    wire _1584;
    wire _32;
    wire _33;
    reg t1_waiting;
    wire [15:0] _1538;
    wire _1540;
    wire _1530;
    wire _1559;
    wire _1526;
    wire _1524;
    wire _1523;
    wire _1522;
    wire _1521;
    wire _1520;
    wire _1519;
    wire _1518;
    wire _1517;
    wire [2:0] _1516;
    reg _1525;
    wire _1527;
    wire _2456;
    wire _2455;
    wire _2457;
    wire _2458;
    wire [4:0] _1618;
    wire [5:0] _1615;
    wire [5:0] _1608;
    wire [5:0] _1616;
    wire _1617;
    wire [4:0] _1620;
    wire [4:0] _1605;
    wire _1599;
    wire [4:0] _1601;
    wire [4:0] _1602;
    wire _1590;
    wire [4:0] _1603;
    wire _1588;
    wire [4:0] _1606;
    wire _1586;
    wire [4:0] _1621;
    wire [4:0] _1622;
    wire [4:0] _1623;
    wire [4:0] _1624;
    wire [4:0] _1626;
    wire [4:0] _34;
    wire [4:0] _35;
    reg [4:0] t1_isr_count;
    wire _2451;
    wire [4:0] _1631;
    wire [6:0] _1628;
    wire _1629;
    wire _1627;
    wire _1630;
    wire [4:0] _1632;
    wire [4:0] _36;
    reg [4:0] cfg_t1_threshold;
    wire [4:0] _1654;
    wire [5:0] _1651;
    wire [5:0] _1650;
    wire [5:0] _1652;
    wire _1653;
    wire [4:0] _1656;
    wire [4:0] _1647;
    wire _1641;
    wire [4:0] _1643;
    wire [4:0] _1644;
    wire _1639;
    wire [4:0] _1645;
    wire _1638;
    wire [4:0] _1648;
    wire _1637;
    wire [4:0] _1657;
    wire [4:0] _1658;
    wire [4:0] _1659;
    wire [4:0] _1660;
    wire [4:0] _1661;
    wire [4:0] _37;
    wire [4:0] _38;
    reg [4:0] t1_osr_count;
    wire _2450;
    wire _2448;
    wire _2449;
    wire _2445;
    wire _2446;
    wire _2447;
    wire [15:0] _2430;
    wire _2428;
    wire [15:0] _2431;
    wire _2424;
    wire [15:0] _2425;
    wire [15:0] _1888;
    wire [15:0] _1857;
    wire [31:0] _1859;
    wire [23:0] _1853;
    wire [31:0] _1855;
    wire [27:0] _1849;
    wire [31:0] _1851;
    wire [29:0] _1845;
    wire [31:0] _1847;
    wire [30:0] _1841;
    wire [31:0] _1843;
    wire [31:0] _1840;
    wire _1838;
    wire [31:0] _1844;
    wire _1837;
    wire [31:0] _1848;
    wire _1836;
    wire [31:0] _1852;
    wire _1835;
    wire [31:0] _1856;
    wire _1834;
    wire [31:0] _1860;
    wire [15:0] _1861;
    wire [15:0] _1889;
    wire [15:0] _1830;
    wire [31:0] _1831;
    wire [23:0] _1826;
    wire [31:0] _1827;
    wire [27:0] _1822;
    wire [31:0] _1823;
    wire [29:0] _1818;
    wire [31:0] _1819;
    wire [30:0] _1814;
    wire [31:0] _1815;
    wire _1806;
    wire _1803;
    wire _1802;
    wire _1801;
    wire _1800;
    wire _1799;
    wire _1798;
    wire _1797;
    wire _1796;
    reg _1804;
    wire _1807;
    wire [4:0] _1793;
    wire _1794;
    wire _1791;
    wire _1790;
    wire _1789;
    wire _1788;
    wire _1787;
    wire _1786;
    wire _1785;
    wire _1784;
    wire [2:0] _1783;
    reg _1792;
    wire _1795;
    wire [4:0] _1779;
    wire _1780;
    wire _1777;
    wire _1776;
    wire _1775;
    wire _1774;
    wire _1773;
    wire _1772;
    wire _1771;
    wire _1770;
    wire [2:0] _1769;
    reg _1778;
    wire _1781;
    wire [4:0] _1765;
    wire _1766;
    wire _1763;
    wire _1762;
    wire _1761;
    wire _1760;
    wire _1759;
    wire _1758;
    wire _1757;
    wire _1756;
    wire [2:0] _1755;
    reg _1764;
    wire _1767;
    wire [4:0] _1751;
    wire _1752;
    wire _1749;
    wire _1748;
    wire _1747;
    wire _1746;
    wire _1745;
    wire _1744;
    wire _1743;
    wire _1742;
    wire [2:0] _1741;
    reg _1750;
    wire _1753;
    wire [4:0] _1737;
    wire _1738;
    wire _1735;
    wire _1734;
    wire _1733;
    wire _1732;
    wire _1731;
    wire _1730;
    wire _1729;
    wire _1728;
    wire [2:0] _1727;
    reg _1736;
    wire _1739;
    wire [4:0] _1723;
    wire _1724;
    wire _1721;
    wire _1720;
    wire _1719;
    wire _1718;
    wire _1717;
    wire _1716;
    wire _1715;
    wire _1714;
    wire [2:0] _1713;
    reg _1722;
    wire _1725;
    wire [4:0] _1709;
    wire _1710;
    wire _1707;
    wire _1706;
    wire _1705;
    wire _1704;
    wire _1703;
    wire _1702;
    wire _1701;
    wire _1700;
    wire [2:0] _1666;
    wire [6:0] _1663;
    wire _1664;
    wire _1662;
    wire _1665;
    wire [2:0] _1667;
    wire [2:0] _39;
    reg [2:0] cfg_t1_in_base;
    wire [2:0] _1699;
    reg _1708;
    wire _1711;
    wire [7:0] _1808;
    wire [15:0] _1809;
    wire [1:0] _1696;
    reg [15:0] _1811;
    wire [31:0] _1812;
    wire _1695;
    wire [31:0] _1816;
    wire _1694;
    wire [31:0] _1820;
    wire _1693;
    wire [31:0] _1824;
    wire _1692;
    wire [31:0] _1828;
    wire _1691;
    wire [31:0] _1832;
    wire [15:0] _1833;
    wire _253;
    wire [15:0] _1890;
    wire [15:0] _1689;
    wire _1671;
    wire [15:0] _1685;
    wire [15:0] _1686;
    wire _1670;
    wire [15:0] _1687;
    wire _1669;
    wire [15:0] _1690;
    wire _1668;
    wire [15:0] _1891;
    wire [15:0] _1892;
    wire [15:0] _1893;
    wire [15:0] _1894;
    wire [15:0] _1896;
    wire [15:0] _40;
    wire [15:0] _41;
    reg [15:0] t1_isr;
    wire [15:0] _1679;
    wire [15:0] _2402;
    wire _2400;
    wire [15:0] _2403;
    wire [15:0] _2391;
    wire [31:0] _2392;
    wire [23:0] _2387;
    wire [31:0] _2388;
    wire [27:0] _2383;
    wire [31:0] _2384;
    wire [29:0] _2379;
    wire [31:0] _2380;
    wire [30:0] _2375;
    wire [31:0] _2376;
    wire [31:0] _2373;
    wire _2371;
    wire [31:0] _2377;
    wire _2370;
    wire [31:0] _2381;
    wire _2369;
    wire [31:0] _2385;
    wire _2368;
    wire [31:0] _2389;
    wire [4:0] _2366;
    wire _2367;
    wire [31:0] _2393;
    wire [15:0] _2394;
    wire [15:0] _1882;
    wire [31:0] _1884;
    wire [23:0] _1878;
    wire [31:0] _1880;
    wire [27:0] _1874;
    wire [31:0] _1876;
    wire [29:0] _1870;
    wire [31:0] _1872;
    wire _1866;
    wire [31:0] _1869;
    wire _1865;
    wire [31:0] _1873;
    wire _1864;
    wire [31:0] _1877;
    wire _1863;
    wire [31:0] _1881;
    wire _1862;
    wire [31:0] _1885;
    wire [15:0] _1886;
    wire [15:0] _1887;
    wire [15:0] _2324;
    wire [31:0] _2326;
    wire [23:0] _2320;
    wire [31:0] _2322;
    wire [27:0] _2316;
    wire [31:0] _2318;
    wire [29:0] _2312;
    wire [31:0] _2314;
    wire [30:0] _2308;
    wire [31:0] _2310;
    wire [31:0] _2307;
    wire _2305;
    wire [31:0] _2311;
    wire _2304;
    wire [31:0] _2315;
    wire _2303;
    wire [31:0] _2319;
    wire _2302;
    wire [31:0] _2323;
    wire _2301;
    wire [31:0] _2327;
    wire [15:0] _2328;
    wire [15:0] _2297;
    wire [31:0] _2298;
    wire [23:0] _2293;
    wire [31:0] _2294;
    wire [27:0] _2289;
    wire [31:0] _2290;
    wire [29:0] _2285;
    wire [31:0] _2286;
    wire [30:0] _2281;
    wire [31:0] _2282;
    wire [31:0] _2279;
    wire _2277;
    wire [31:0] _2283;
    wire _2276;
    wire [31:0] _2287;
    wire _2275;
    wire [31:0] _2291;
    wire _2274;
    wire [31:0] _2295;
    wire [4:0] _1612;
    wire [3:0] _1609;
    wire _1611;
    wire [4:0] _1614;
    wire _2273;
    wire [31:0] _2299;
    wire [15:0] _2300;
    wire [15:0] _2329;
    wire _2266;
    wire _2267;
    reg [15:0] t1_tx_mem_3;
    wire _2260;
    wire _2261;
    reg [15:0] t1_tx_mem_2;
    wire _2254;
    wire _2255;
    reg [15:0] t1_tx_mem_1;
    wire [1:0] _1913;
    wire [1:0] _1914;
    wire [1:0] _42;
    reg [1:0] t1_tx_wr;
    wire _2248;
    wire _2249;
    wire _447;
    wire _448;
    reg [15:0] t0_rx_mem_3;
    wire _441;
    wire _442;
    reg [15:0] t0_rx_mem_2;
    wire _435;
    wire _436;
    reg [15:0] t0_rx_mem_1;
    wire [1:0] _1916;
    wire [1:0] _1917;
    wire [1:0] _43;
    reg [1:0] t0_rx_wr;
    wire _429;
    wire _430;
    wire [15:0] _2195;
    wire [31:0] _2197;
    wire [23:0] _2191;
    wire [31:0] _2193;
    wire [27:0] _2187;
    wire [31:0] _2189;
    wire [29:0] _2183;
    wire [31:0] _2185;
    wire _2179;
    wire [31:0] _2182;
    wire _2178;
    wire [31:0] _2186;
    wire _2177;
    wire [31:0] _2190;
    wire _2176;
    wire [31:0] _2194;
    wire _2175;
    wire [31:0] _2198;
    wire [15:0] _2199;
    wire [15:0] _2200;
    wire [15:0] _2201;
    wire [15:0] _2171;
    wire [31:0] _2172;
    wire [23:0] _2167;
    wire [31:0] _2168;
    wire [27:0] _2163;
    wire [31:0] _2164;
    wire [29:0] _2159;
    wire [31:0] _2160;
    wire [30:0] _2155;
    wire [31:0] _2156;
    wire [15:0] _2108;
    wire [15:0] _2103;
    wire [31:0] _2105;
    wire [23:0] _2099;
    wire [31:0] _2101;
    wire [27:0] _2095;
    wire [31:0] _2097;
    wire [29:0] _2091;
    wire [31:0] _2093;
    wire [30:0] _2087;
    wire [31:0] _2089;
    wire [31:0] _2086;
    wire _2084;
    wire [31:0] _2090;
    wire _2083;
    wire [31:0] _2094;
    wire _2082;
    wire [31:0] _2098;
    wire _2081;
    wire [31:0] _2102;
    wire _2080;
    wire [31:0] _2106;
    wire [15:0] _2107;
    wire [15:0] _2109;
    wire [15:0] _2076;
    wire [31:0] _2077;
    wire [23:0] _2072;
    wire [31:0] _2073;
    wire [27:0] _2068;
    wire [31:0] _2069;
    wire [29:0] _2064;
    wire [31:0] _2065;
    wire [30:0] _2060;
    wire [31:0] _2061;
    wire _2052;
    wire _2049;
    wire _2048;
    wire _2047;
    wire _2046;
    wire _2045;
    wire _2044;
    wire _2043;
    wire _2042;
    reg _2050;
    wire _2053;
    wire _2040;
    wire _2037;
    wire _2036;
    wire _2035;
    wire _2034;
    wire _2033;
    wire _2032;
    wire _2031;
    wire _2030;
    wire [2:0] _2029;
    reg _2038;
    wire _2041;
    wire _2026;
    wire _2023;
    wire _2022;
    wire _2021;
    wire _2020;
    wire _2019;
    wire _2018;
    wire _2017;
    wire _2016;
    wire [2:0] _2015;
    reg _2024;
    wire _2027;
    wire _2012;
    wire _2009;
    wire _2008;
    wire _2007;
    wire _2006;
    wire _2005;
    wire _2004;
    wire _2003;
    wire _2002;
    wire [2:0] _2001;
    reg _2010;
    wire _2013;
    wire _1998;
    wire _1995;
    wire _1994;
    wire _1993;
    wire _1992;
    wire _1991;
    wire _1990;
    wire _1989;
    wire _1988;
    wire [2:0] _1987;
    reg _1996;
    wire _1999;
    wire _1984;
    wire _1981;
    wire _1980;
    wire _1979;
    wire _1978;
    wire _1977;
    wire _1976;
    wire _1975;
    wire _1974;
    wire [2:0] _1973;
    reg _1982;
    wire _1985;
    wire _1970;
    wire _1967;
    wire _1966;
    wire _1965;
    wire _1964;
    wire _1963;
    wire _1962;
    wire _1961;
    wire _1960;
    wire [2:0] _1959;
    reg _1968;
    wire _1971;
    wire _1956;
    wire _1953;
    wire _1952;
    wire _1951;
    wire _1950;
    wire _1949;
    wire _1948;
    wire _1947;
    wire _1946;
    wire [2:0] _1922;
    wire [6:0] _1919;
    wire _1920;
    wire _1918;
    wire _1921;
    wire [2:0] _1923;
    wire [2:0] _44;
    reg [2:0] cfg_t0_in_base;
    wire [2:0] _1945;
    reg _1954;
    wire _1957;
    wire [7:0] _2054;
    wire [15:0] _2055;
    wire [1:0] _1942;
    reg [15:0] _2057;
    wire [31:0] _2058;
    wire _1941;
    wire [31:0] _2062;
    wire _1940;
    wire [31:0] _2066;
    wire _1939;
    wire [31:0] _2070;
    wire _1938;
    wire [31:0] _2074;
    wire _1937;
    wire [31:0] _2078;
    wire [15:0] _2079;
    wire [15:0] _2110;
    wire [15:0] _1934;
    wire _1929;
    wire [15:0] _1930;
    wire [15:0] _1931;
    wire _1927;
    wire [15:0] _1932;
    wire _1926;
    wire [15:0] _1935;
    wire _1925;
    wire [15:0] _2111;
    wire [15:0] _2112;
    wire [15:0] _2113;
    wire [15:0] _2114;
    wire [15:0] _2116;
    wire [15:0] _45;
    wire [15:0] _46;
    reg [15:0] t0_isr;
    wire [31:0] _2153;
    wire _2151;
    wire [31:0] _2157;
    wire _2150;
    wire [31:0] _2161;
    wire _2149;
    wire [31:0] _2165;
    wire _2148;
    wire [31:0] _2169;
    wire [4:0] _2136;
    wire [5:0] _2133;
    wire [5:0] _2132;
    wire [5:0] _2134;
    wire _2135;
    wire [4:0] _2138;
    wire [4:0] _2129;
    wire _2123;
    wire [4:0] _2125;
    wire [4:0] _2126;
    wire _2122;
    wire [4:0] _2127;
    wire _2121;
    wire [4:0] _2130;
    wire _2120;
    wire [4:0] _2139;
    wire [4:0] _2140;
    wire [4:0] _2141;
    wire [4:0] _2142;
    wire [4:0] _2144;
    wire [4:0] _47;
    wire [4:0] _48;
    reg [4:0] t0_isr_count;
    wire [4:0] _2146;
    wire _2147;
    wire [31:0] _2173;
    wire [15:0] _2174;
    wire _1936;
    wire [15:0] _2202;
    wire [15:0] _49;
    reg [15:0] t0_rx_mem_0;
    wire [1:0] _2221;
    wire _2218;
    wire _2213;
    wire _2210;
    wire _2211;
    wire [6:0] _2206;
    wire [6:0] _372;
    wire _2207;
    wire _2203;
    wire _2204;
    wire _1457;
    wire _1458;
    wire _2205;
    wire _2208;
    wire _2212;
    wire _50;
    wire _2214;
    wire _2215;
    wire _2219;
    wire [1:0] _2222;
    wire [1:0] _51;
    reg [1:0] t0_rx_rd;
    reg [15:0] _450;
    wire [15:0] _52;
    wire [15:0] _2244;
    reg [15:0] t1_tx_mem_0;
    wire [1:0] _2235;
    wire _2229;
    wire _1566;
    wire _2227;
    wire _2224;
    wire _2225;
    wire _2226;
    wire _2228;
    wire _53;
    wire _2230;
    wire [1:0] _2236;
    wire [1:0] _54;
    reg [1:0] t1_tx_rd;
    reg [15:0] _2269;
    wire _1486;
    wire [15:0] _2270;
    wire _2240;
    wire [15:0] _2241;
    wire [15:0] _2242;
    wire _2239;
    wire [15:0] _2243;
    wire _2238;
    wire [15:0] _2271;
    wire _2237;
    wire [15:0] _2330;
    wire [15:0] _2331;
    wire [15:0] _2332;
    wire [15:0] _2333;
    wire [15:0] _2335;
    wire [15:0] _55;
    wire [15:0] _56;
    reg [15:0] t1_osr;
    wire [15:0] _2364;
    wire [1:0] _2340;
    wire [6:0] _2337;
    wire _2338;
    wire _2336;
    wire _2339;
    wire [1:0] _2341;
    wire [1:0] _57;
    reg [1:0] cfg_t1_shift;
    wire _2272;
    wire [15:0] _2395;
    wire [1:0] _2361;
    wire _2363;
    wire [15:0] _2396;
    wire _2357;
    wire [15:0] _2358;
    wire [15:0] _2359;
    wire _2350;
    wire [15:0] _2354;
    wire _2347;
    wire [15:0] _2355;
    wire _2345;
    wire [15:0] _2360;
    wire _2344;
    wire [15:0] _2397;
    wire _2343;
    wire [15:0] _2404;
    wire [15:0] _2405;
    wire [15:0] _2406;
    wire [15:0] _2407;
    wire [15:0] _2409;
    wire [15:0] _58;
    wire [15:0] _59;
    reg [15:0] t1_y;
    reg [15:0] _1684;
    wire _2419;
    wire [15:0] _2420;
    wire [2:0] _1594;
    wire _1596;
    wire [2:0] _1591;
    wire _1593;
    wire _1597;
    wire [15:0] _2421;
    wire [4:0] _2352;
    wire [15:0] _2353;
    wire [1:0] _2348;
    wire _2415;
    wire [15:0] _2416;
    wire _2413;
    wire [15:0] _2417;
    wire _2412;
    wire [15:0] _2422;
    wire _2411;
    wire [15:0] _2426;
    wire _2410;
    wire [15:0] _2432;
    wire [15:0] _2433;
    wire [15:0] _2434;
    wire [15:0] _2435;
    wire [15:0] _2437;
    wire [15:0] _60;
    wire [15:0] _61;
    reg [15:0] t1_x;
    wire _2441;
    wire _2442;
    wire _2443;
    wire [2:0] _2398;
    reg _2452;
    wire _2439;
    wire _2453;
    wire _2459;
    wire [7:0] _2468;
    reg [7:0] t1_pc;
    wire [7:0] _2469;
    wire [7:0] _2470;
    wire [7:0] _2471;
    wire [7:0] _2472;
    wire [7:0] _62;
    wire [7:0] _63;
    wire [7:0] _2481;
    wire _2477;
    wire [15:0] _2487;
    wire [15:0] _64;
    wire [2:0] _1482;
    wire _1556;
    wire _1558;
    wire _1561;
    wire _1568;
    wire _1574;
    wire _1575;
    wire _1480;
    wire _1475;
    wire _1481;
    wire _1576;
    wire [3:0] _2500;
    wire [3:0] _2503;
    wire [3:0] _2504;
    wire [3:0] _2506;
    wire [3:0] _65;
    wire [3:0] _66;
    reg [3:0] t1_delay_left;
    wire _1512;
    wire _1513;
    wire [7:0] _3078;
    wire [15:0] _2518;
    wire [6:0] _2508;
    wire _2509;
    wire _2507;
    wire _2510;
    wire [15:0] _2511;
    wire [15:0] _67;
    reg [15:0] cfg_t1_clkdiv;
    wire _2516;
    wire [15:0] _2520;
    wire [15:0] _2514;
    wire [15:0] _2521;
    wire _2512;
    wire [15:0] _2523;
    wire [15:0] _68;
    reg [15:0] t1_div_count;
    wire _1474;
    wire _1510;
    wire [7:0] _3079;
    wire _1469;
    wire _1509;
    wire [7:0] _3080;
    wire [7:0] _69;
    wire [7:0] _70;
    reg [7:0] pin_out;
    wire _620;
    wire [7:0] _616;
    reg [7:0] pins_sync1;
    reg [7:0] pins_sync2;
    wire [7:0] _617;
    wire [7:0] _3085;
    wire [6:0] _3082;
    wire _3083;
    wire _3081;
    wire _3084;
    wire [7:0] _3086;
    wire [7:0] _71;
    reg [7:0] cfg_sync_bypass;
    wire [7:0] _73;
    wire [7:0] _610;
    wire [7:0] _618;
    wire _619;
    wire [6:0] _3088;
    wire _3089;
    wire _3087;
    wire _3090;
    wire [15:0] _3091;
    wire [15:0] _74;
    reg [15:0] cfg_pin_modes;
    wire [1:0] _609;
    reg _622;
    wire [7:0] _658;
    wire [15:0] _982;
    wire [15:0] _3253;
    wire _3251;
    wire [15:0] _3254;
    wire [15:0] _1168;
    wire [31:0] _1169;
    wire [23:0] _1164;
    wire [31:0] _1165;
    wire [27:0] _1160;
    wire [31:0] _1161;
    wire [29:0] _1156;
    wire [31:0] _1157;
    wire [30:0] _1152;
    wire [31:0] _1153;
    wire [31:0] _1150;
    wire _1148;
    wire [31:0] _1154;
    wire _1147;
    wire [31:0] _1158;
    wire _1146;
    wire [31:0] _1162;
    wire _1145;
    wire [31:0] _1166;
    wire [4:0] _1143;
    wire _1144;
    wire [31:0] _1170;
    wire [15:0] _1171;
    wire [15:0] _1135;
    wire [31:0] _1137;
    wire [23:0] _1131;
    wire [31:0] _1133;
    wire [27:0] _1127;
    wire [31:0] _1129;
    wire [29:0] _1123;
    wire [31:0] _1125;
    wire _1119;
    wire [31:0] _1122;
    wire _1118;
    wire [31:0] _1126;
    wire _1117;
    wire [31:0] _1130;
    wire _1116;
    wire [31:0] _1134;
    wire _1115;
    wire [31:0] _1138;
    wire [15:0] _1139;
    wire [15:0] _1140;
    wire [15:0] _3211;
    wire [31:0] _3213;
    wire [23:0] _3207;
    wire [31:0] _3209;
    wire [27:0] _3203;
    wire [31:0] _3205;
    wire [29:0] _3199;
    wire [31:0] _3201;
    wire [30:0] _3195;
    wire [31:0] _3197;
    wire [31:0] _3194;
    wire _3192;
    wire [31:0] _3198;
    wire _3191;
    wire [31:0] _3202;
    wire _3190;
    wire [31:0] _3206;
    wire _3189;
    wire [31:0] _3210;
    wire _3188;
    wire [31:0] _3214;
    wire [15:0] _3215;
    wire [15:0] _3184;
    wire [31:0] _3185;
    wire [23:0] _3180;
    wire [31:0] _3181;
    wire [27:0] _3176;
    wire [31:0] _3177;
    wire [29:0] _3172;
    wire [31:0] _3173;
    wire [30:0] _3168;
    wire [31:0] _3169;
    wire [31:0] _3166;
    wire _3164;
    wire [31:0] _3170;
    wire _3163;
    wire [31:0] _3174;
    wire _3162;
    wire [31:0] _3178;
    wire _3161;
    wire [31:0] _3182;
    wire [4:0] _768;
    wire [3:0] _765;
    wire _767;
    wire [4:0] _770;
    wire _3160;
    wire [31:0] _3186;
    wire [15:0] _3187;
    wire [15:0] _3216;
    wire _3154;
    wire _3155;
    reg [15:0] t0_tx_mem_3;
    wire _3148;
    wire _3149;
    reg [15:0] t0_tx_mem_2;
    wire _3142;
    wire _3143;
    reg [15:0] t0_tx_mem_1;
    wire [1:0] _3104;
    wire [1:0] _3105;
    wire [1:0] _75;
    reg [1:0] t0_tx_wr;
    wire _3136;
    wire _3137;
    reg [15:0] t0_tx_mem_0;
    wire [1:0] _3124;
    wire _3110;
    wire [2:0] _3112;
    wire _3097;
    wire _3098;
    wire [6:0] _3093;
    wire _3094;
    wire _3092;
    wire _3095;
    wire _3099;
    wire [2:0] _3107;
    wire [2:0] _3108;
    wire [2:0] _3113;
    wire [2:0] _76;
    reg [2:0] t0_tx_level;
    wire _713;
    wire _3118;
    wire _3115;
    wire _3116;
    wire _3117;
    wire _3119;
    wire _77;
    wire _3111;
    wire [1:0] _3125;
    wire [1:0] _78;
    reg [1:0] t0_tx_rd;
    reg [15:0] _3157;
    wire _710;
    wire [15:0] _3158;
    wire _3129;
    wire [15:0] _3130;
    wire [15:0] _3131;
    wire _3128;
    wire [15:0] _3132;
    wire _3127;
    wire [15:0] _3159;
    wire _3126;
    wire [15:0] _3217;
    wire [15:0] _3218;
    wire [15:0] _3219;
    wire [15:0] _3220;
    wire [15:0] _3222;
    wire [15:0] _79;
    wire [15:0] _80;
    reg [15:0] t0_osr;
    wire [15:0] _1141;
    wire [1:0] _3227;
    wire [6:0] _3224;
    wire _3225;
    wire _3223;
    wire _3226;
    wire [1:0] _3228;
    wire [1:0] _81;
    reg [1:0] cfg_t0_shift;
    wire _1114;
    wire [15:0] _1172;
    wire [1:0] _3244;
    wire _3246;
    wire [15:0] _3247;
    wire _3240;
    wire [15:0] _3241;
    wire [15:0] _3242;
    wire _3236;
    wire [15:0] _3237;
    wire _3234;
    wire [15:0] _3238;
    wire _3232;
    wire [15:0] _3243;
    wire _3231;
    wire [15:0] _3248;
    wire _3230;
    wire [15:0] _3255;
    wire [15:0] _3256;
    wire [15:0] _3257;
    wire [15:0] _3258;
    wire [15:0] _3260;
    wire [15:0] _82;
    wire [15:0] _83;
    reg [15:0] t0_y;
    reg [15:0] _990;
    wire _3270;
    wire [15:0] _3271;
    wire [2:0] _750;
    wire _752;
    wire [2:0] _747;
    wire _749;
    wire _753;
    wire [15:0] _3272;
    wire [4:0] _849;
    wire [15:0] _850;
    wire [1:0] _837;
    wire _3266;
    wire [15:0] _3267;
    wire _3264;
    wire [15:0] _3268;
    wire _3263;
    wire [15:0] _3273;
    wire _3262;
    wire [15:0] _3277;
    wire _3261;
    wire [15:0] _3283;
    wire [15:0] _3284;
    wire [15:0] _3285;
    wire [15:0] _3286;
    wire [15:0] _3288;
    wire [15:0] _84;
    wire [15:0] _85;
    reg [15:0] t0_x;
    wire _3292;
    wire _3293;
    wire _3294;
    wire [2:0] _3249;
    reg _3303;
    wire _3290;
    wire _3304;
    wire _3310;
    wire [7:0] _3319;
    reg [7:0] t0_pc;
    wire [7:0] _3320;
    wire [7:0] _3321;
    wire [7:0] _3322;
    wire [7:0] _3323;
    wire [7:0] _86;
    wire [7:0] _87;
    wire [7:0] _3325;
    wire _3324;
    wire [6:0] _2474;
    wire _2475;
    wire _2473;
    wire _2476;
    wire [15:0] _3331;
    wire [15:0] _88;
    wire [2:0] _605;
    wire _702;
    wire _704;
    wire _707;
    wire _715;
    wire _721;
    wire _722;
    wire _723;
    wire [3:0] _3342;
    wire _603;
    wire _604;
    wire [3:0] _3345;
    wire _598;
    wire [3:0] _3346;
    wire _592;
    wire [3:0] _3348;
    wire [3:0] _89;
    wire [3:0] _90;
    reg [3:0] t0_delay_left;
    wire _699;
    wire [15:0] _3360;
    wire [6:0] _3350;
    wire _3351;
    wire _3349;
    wire _3352;
    wire [15:0] _3353;
    wire [15:0] _91;
    reg [15:0] cfg_t0_clkdiv;
    wire _3358;
    wire [15:0] _3362;
    wire [15:0] _3356;
    wire [15:0] _3363;
    wire _3354;
    wire [15:0] _3365;
    wire [15:0] _92;
    reg [15:0] t0_div_count;
    wire _597;
    wire _591;
    wire _697;
    wire _700;
    wire _3368;
    wire _3370;
    wire _3372;
    wire _93;
    wire _424;
    wire [2:0] _3374;
    wire [2:0] _3375;
    wire [2:0] _3378;
    wire [2:0] _94;
    reg [2:0] t0_rx_level;
    wire _2217;
    wire _3399;
    wire [15:0] _582;
    wire [4:0] _3397;
    wire [6:0] _578;
    wire _3395;
    wire _365;
    reg host_mosi_s1;
    reg host_mosi_s2;
    wire [22:0] _363;
    wire [22:0] _3379;
    wire [22:0] _3380;
    wire [22:0] _3381;
    wire [22:0] _95;
    reg [22:0] host_shift_in;
    wire [23:0] _370;
    wire [7:0] _371;
    wire _361;
    wire [7:0] _3382;
    wire [7:0] _3383;
    wire [7:0] _3384;
    wire [7:0] _96;
    reg [7:0] host_cmd;
    wire _576;
    wire [4:0] _570;
    wire [4:0] _3388;
    wire [4:0] _3385;
    wire _3386;
    wire [4:0] _3389;
    wire [4:0] _3390;
    wire [4:0] _3392;
    wire [4:0] _97;
    reg [4:0] host_bit_count;
    wire _571;
    wire _328;
    reg host_cs_n_s1;
    reg host_cs_n_s2;
    wire _355;
    reg host_sck_prev;
    wire _353;
    wire vdd;
    wire _99;
    wire _101;
    wire [7:0] _103;
    wire _333;
    reg host_sck_s1;
    reg host_sck_s2;
    wire _354;
    wire _356;
    wire _572;
    wire _3393;
    wire _3396;
    wire [4:0] _3398;
    wire [4:0] _104;
    reg [4:0] cfg_ctrl;
    wire _1901;
    wire _3400;
    wire _3402;
    wire _105;
    wire _1904;
    wire _1908;
    wire [2:0] _3404;
    wire [2:0] _3405;
    wire [2:0] _3408;
    wire [2:0] _106;
    reg [2:0] t1_tx_level;
    wire _3410;
    wire gnd;
    wire [7:0] _3422;
    assign _191 = pin_out[0:0];
    assign _192 = ~ _191;
    assign _189 = 2'b10;
    assign _188 = cfg_pin_modes[1:0];
    assign _190 = _188 == _189;
    assign _193 = _190 & _192;
    assign _186 = 2'b01;
    assign _185 = cfg_pin_modes[1:0];
    assign _187 = _185 == _186;
    assign _194 = _187 | _193;
    assign _181 = pin_out[1:1];
    assign _182 = ~ _181;
    assign _178 = cfg_pin_modes[3:2];
    assign _180 = _178 == _189;
    assign _183 = _180 & _182;
    assign _175 = cfg_pin_modes[3:2];
    assign _177 = _175 == _186;
    assign _184 = _177 | _183;
    assign _171 = pin_out[2:2];
    assign _172 = ~ _171;
    assign _168 = cfg_pin_modes[5:4];
    assign _170 = _168 == _189;
    assign _173 = _170 & _172;
    assign _165 = cfg_pin_modes[5:4];
    assign _167 = _165 == _186;
    assign _174 = _167 | _173;
    assign _161 = pin_out[3:3];
    assign _162 = ~ _161;
    assign _158 = cfg_pin_modes[7:6];
    assign _160 = _158 == _189;
    assign _163 = _160 & _162;
    assign _155 = cfg_pin_modes[7:6];
    assign _157 = _155 == _186;
    assign _164 = _157 | _163;
    assign _151 = pin_out[4:4];
    assign _152 = ~ _151;
    assign _148 = cfg_pin_modes[9:8];
    assign _150 = _148 == _189;
    assign _153 = _150 & _152;
    assign _145 = cfg_pin_modes[9:8];
    assign _147 = _145 == _186;
    assign _154 = _147 | _153;
    assign _141 = pin_out[5:5];
    assign _142 = ~ _141;
    assign _138 = cfg_pin_modes[11:10];
    assign _140 = _138 == _189;
    assign _143 = _140 & _142;
    assign _135 = cfg_pin_modes[11:10];
    assign _137 = _135 == _186;
    assign _144 = _137 | _143;
    assign _131 = pin_out[6:6];
    assign _132 = ~ _131;
    assign _128 = cfg_pin_modes[13:12];
    assign _130 = _128 == _189;
    assign _133 = _130 & _132;
    assign _125 = cfg_pin_modes[13:12];
    assign _127 = _125 == _186;
    assign _134 = _127 | _133;
    assign _121 = pin_out[7:7];
    assign _122 = ~ _121;
    assign _115 = cfg_pin_modes[15:14];
    assign _117 = _115 == _189;
    assign _123 = _117 & _122;
    assign _112 = cfg_pin_modes[15:14];
    assign _114 = _112 == _186;
    assign _124 = _114 | _123;
    assign _195 = { _124,
                    _134,
                    _144,
                    _154,
                    _164,
                    _174,
                    _184,
                    _194 };
    assign _234 = pin_out[0:0];
    assign _231 = cfg_pin_modes[1:0];
    assign _233 = _231 == _186;
    assign _235 = _233 & _234;
    assign _229 = pin_out[1:1];
    assign _226 = cfg_pin_modes[3:2];
    assign _228 = _226 == _186;
    assign _230 = _228 & _229;
    assign _224 = pin_out[2:2];
    assign _221 = cfg_pin_modes[5:4];
    assign _223 = _221 == _186;
    assign _225 = _223 & _224;
    assign _219 = pin_out[3:3];
    assign _216 = cfg_pin_modes[7:6];
    assign _218 = _216 == _186;
    assign _220 = _218 & _219;
    assign _214 = pin_out[4:4];
    assign _211 = cfg_pin_modes[9:8];
    assign _213 = _211 == _186;
    assign _215 = _213 & _214;
    assign _209 = pin_out[5:5];
    assign _206 = cfg_pin_modes[11:10];
    assign _208 = _206 == _186;
    assign _210 = _208 & _209;
    assign _204 = pin_out[6:6];
    assign _201 = cfg_pin_modes[13:12];
    assign _203 = _201 == _186;
    assign _205 = _203 & _204;
    assign _199 = pin_out[7:7];
    assign _196 = cfg_pin_modes[15:14];
    assign _198 = _196 == _186;
    assign _200 = _198 & _199;
    assign _236 = { _200,
                    _205,
                    _210,
                    _215,
                    _220,
                    _225,
                    _230,
                    _235 };
    assign _358 = 16'b0000000000000000;
    assign _566 = 1'b0;
    assign _565 = host_miso_shift[14:0];
    assign _567 = { _565,
                    _566 };
    assign _560 = 14'b00000000000000;
    assign _561 = { _560,
                    cfg_t1_shift };
    assign _552 = 10'b0000000000;
    assign _556 = { _552,
                    cfg_t1_sideset };
    assign _544 = cfg_ctrl[1:1];
    assign _548 = { t1_pc,
                    _544,
                    t1_rx_level,
                    gnd,
                    t1_tx_level };
    assign _535 = 2'b11;
    assign _536 = t1_rx_wr == _535;
    assign _537 = _243 & _536;
    always @(posedge _101) begin
        if (_99)
            t1_rx_mem_3 <= _358;
        else
            if (_537)
                t1_rx_mem_3 <= _4;
    end
    assign _530 = t1_rx_wr == _189;
    assign _531 = _243 & _530;
    always @(posedge _101) begin
        if (_99)
            t1_rx_mem_2 <= _358;
        else
            if (_531)
                t1_rx_mem_2 <= _4;
    end
    assign _524 = t1_rx_wr == _186;
    assign _525 = _243 & _524;
    always @(posedge _101) begin
        if (_99)
            t1_rx_mem_1 <= _358;
        else
            if (_525)
                t1_rx_mem_1 <= _4;
    end
    assign _517 = 2'b00;
    assign _248 = t1_rx_wr + _186;
    assign _249 = _243 ? _248 : t1_rx_wr;
    assign _3 = _249;
    always @(posedge _101) begin
        if (_99)
            t1_rx_wr <= _517;
        else
            t1_rx_wr <= _3;
    end
    assign _518 = t1_rx_wr == _517;
    assign _519 = _243 & _518;
    assign _310 = _309[15:0];
    assign _312 = { _310,
                    _358 };
    assign _307 = 8'b00000000;
    assign _306 = _305[23:0];
    assign _308 = { _306,
                    _307 };
    assign _303 = 4'b0000;
    assign _302 = _301[27:0];
    assign _304 = { _302,
                    _303 };
    assign _298 = _297[29:0];
    assign _300 = { _298,
                    _517 };
    assign _296 = 32'b11111111111111111111111111111110;
    assign _295 = 32'b11111111111111111111111111111111;
    assign _294 = t1_isr_count[0:0];
    assign _297 = _294 ? _296 : _295;
    assign _293 = t1_isr_count[1:1];
    assign _301 = _293 ? _300 : _297;
    assign _292 = t1_isr_count[2:2];
    assign _305 = _292 ? _304 : _301;
    assign _291 = t1_isr_count[3:3];
    assign _309 = _291 ? _308 : _305;
    assign _290 = t1_isr_count[4:4];
    assign _313 = _290 ? _312 : _309;
    assign _314 = _313[15:0];
    assign _315 = ~ _314;
    assign _316 = t1_isr & _315;
    assign _286 = _284[31:16];
    assign _287 = { _358,
                    _286 };
    assign _282 = _280[31:8];
    assign _283 = { _307,
                    _282 };
    assign _278 = _276[31:4];
    assign _279 = { _303,
                    _278 };
    assign _274 = _272[31:2];
    assign _275 = { _517,
                    _274 };
    assign _270 = _268[31:1];
    assign _271 = { _566,
                    _270 };
    assign _268 = { _358,
                    t1_isr };
    assign _263 = _258[0:0];
    assign _272 = _263 ? _271 : _268;
    assign _262 = _258[1:1];
    assign _276 = _262 ? _275 : _272;
    assign _261 = _258[2:2];
    assign _280 = _261 ? _279 : _276;
    assign _260 = _258[3:3];
    assign _284 = _260 ? _283 : _280;
    assign _254 = 5'b10000;
    assign _258 = _254 - t1_isr_count;
    assign _259 = _258[4:4];
    assign _288 = _259 ? _287 : _284;
    assign _289 = _288[15:0];
    assign _317 = _253 ? _316 : _289;
    assign _4 = _317;
    always @(posedge _101) begin
        if (_99)
            t1_rx_mem_0 <= _358;
        else
            if (_519)
                t1_rx_mem_0 <= _4;
    end
    assign _326 = t1_rx_rd + _186;
    assign _327 = _321 ? _326 : t1_rx_rd;
    assign _5 = _327;
    always @(posedge _101) begin
        if (_99)
            t1_rx_rd <= _517;
        else
            t1_rx_rd <= _5;
    end
    always @* begin
        case (t1_rx_rd)
        0:
            _539 <= t1_rx_mem_0;
        1:
            _539 <= t1_rx_mem_1;
        2:
            _539 <= t1_rx_mem_2;
        default:
            _539 <= t1_rx_mem_3;
        endcase
    end
    assign _511 = 3'b000;
    assign _512 = t1_rx_level == _511;
    assign _513 = ~ _512;
    assign _540 = _513 ? _539 : _358;
    assign _510 = { _307,
                    cfg_t1_timeout_vector };
    assign _501 = 11'b00000000000;
    assign _505 = { _501,
                    cfg_t1_threshold };
    assign _496 = 13'b0000000000000;
    assign _500 = { _496,
                    cfg_t1_in_base };
    assign _495 = { _307,
                    cfg_t1_set_cfg };
    assign _490 = { _307,
                    cfg_t1_out_cfg };
    assign _485 = { _307,
                    cfg_t1_start };
    assign _480 = { _560,
                    cfg_t0_shift };
    assign _475 = { _307,
                    cfg_sync_bypass };
    assign _467 = { _552,
                    cfg_t0_sideset };
    assign _455 = cfg_ctrl[0:0];
    assign _459 = { t0_pc,
                    _455,
                    t0_rx_level,
                    gnd,
                    t0_tx_level };
    assign _413 = t0_rx_level == _511;
    assign _414 = ~ _413;
    assign _451 = _414 ? _450 : _358;
    assign _408 = { _307,
                    cfg_t0_timeout_vector };
    assign _403 = { _501,
                    cfg_t0_threshold };
    assign _398 = { _496,
                    cfg_t0_in_base };
    assign _393 = { _307,
                    cfg_t0_set_cfg };
    assign _388 = { _307,
                    cfg_t0_out_cfg };
    assign _383 = { _307,
                    cfg_t0_start };
    assign _378 = { _501,
                    cfg_ctrl };
    always @* begin
        case (_372)
        0:
            _562 <= _358;
        1:
            _562 <= _358;
        2:
            _562 <= _358;
        3:
            _562 <= _358;
        4:
            _562 <= _358;
        5:
            _562 <= _358;
        6:
            _562 <= _358;
        7:
            _562 <= _358;
        8:
            _562 <= _358;
        9:
            _562 <= _358;
        10:
            _562 <= _358;
        11:
            _562 <= _358;
        12:
            _562 <= _358;
        13:
            _562 <= _358;
        14:
            _562 <= _358;
        15:
            _562 <= _358;
        16:
            _562 <= _358;
        17:
            _562 <= _358;
        18:
            _562 <= _358;
        19:
            _562 <= _358;
        20:
            _562 <= _358;
        21:
            _562 <= _358;
        22:
            _562 <= _358;
        23:
            _562 <= _358;
        24:
            _562 <= _358;
        25:
            _562 <= _358;
        26:
            _562 <= _358;
        27:
            _562 <= _358;
        28:
            _562 <= _358;
        29:
            _562 <= _358;
        30:
            _562 <= _358;
        31:
            _562 <= _358;
        32:
            _562 <= _358;
        33:
            _562 <= _358;
        34:
            _562 <= _358;
        35:
            _562 <= _358;
        36:
            _562 <= _358;
        37:
            _562 <= _358;
        38:
            _562 <= _358;
        39:
            _562 <= _358;
        40:
            _562 <= _358;
        41:
            _562 <= _358;
        42:
            _562 <= _358;
        43:
            _562 <= _358;
        44:
            _562 <= _358;
        45:
            _562 <= _358;
        46:
            _562 <= _358;
        47:
            _562 <= _358;
        48:
            _562 <= _358;
        49:
            _562 <= _358;
        50:
            _562 <= _358;
        51:
            _562 <= _358;
        52:
            _562 <= _358;
        53:
            _562 <= _358;
        54:
            _562 <= _358;
        55:
            _562 <= _358;
        56:
            _562 <= _358;
        57:
            _562 <= _358;
        58:
            _562 <= _358;
        59:
            _562 <= _358;
        60:
            _562 <= _358;
        61:
            _562 <= _358;
        62:
            _562 <= _358;
        63:
            _562 <= _358;
        64:
            _562 <= _378;
        65:
            _562 <= _383;
        66:
            _562 <= _388;
        67:
            _562 <= _393;
        68:
            _562 <= _398;
        69:
            _562 <= _403;
        70:
            _562 <= _408;
        71:
            _562 <= cfg_pin_modes;
        72:
            _562 <= _358;
        73:
            _562 <= _451;
        74:
            _562 <= _459;
        75:
            _562 <= cfg_t0_timeout;
        76:
            _562 <= _467;
        77:
            _562 <= cfg_t0_clkdiv;
        78:
            _562 <= _475;
        79:
            _562 <= _480;
        80:
            _562 <= _358;
        81:
            _562 <= _485;
        82:
            _562 <= _490;
        83:
            _562 <= _495;
        84:
            _562 <= _500;
        85:
            _562 <= _505;
        86:
            _562 <= _510;
        87:
            _562 <= _358;
        88:
            _562 <= _358;
        89:
            _562 <= _540;
        90:
            _562 <= _548;
        91:
            _562 <= cfg_t1_timeout;
        92:
            _562 <= _556;
        93:
            _562 <= cfg_t1_clkdiv;
        94:
            _562 <= _358;
        95:
            _562 <= _561;
        default:
            _562 <= _358;
        endcase
    end
    assign _563 = _361 ? _562 : host_miso_shift;
    assign _564 = _356 ? _563 : host_miso_shift;
    assign _349 = 5'b01001;
    assign _350 = host_bit_count < _349;
    assign _351 = ~ _350;
    assign _344 = ~ host_cs_n_s2;
    assign _339 = ~ host_sck_s2;
    assign _343 = _339 & host_sck_prev;
    assign _345 = _343 & _344;
    assign _352 = _345 & _351;
    assign _568 = _352 ? _567 : _564;
    assign _569 = host_cs_n_s2 ? host_miso_shift : _568;
    assign _6 = _569;
    always @(posedge _101) begin
        if (_99)
            host_miso_shift <= _358;
        else
            host_miso_shift <= _6;
    end
    assign _3421 = host_miso_shift[15:15];
    assign _3420 = cfg_ctrl[0:0];
    assign _3418 = t0_rx_level == _511;
    assign _3419 = ~ _3418;
    assign _3415 = 3'b100;
    assign _3416 = t0_tx_level == _3415;
    assign _3414 = cfg_ctrl[1:1];
    assign _3412 = t1_rx_level == _511;
    assign _3413 = ~ _3412;
    assign _3407 = { _517,
                     _2230 };
    assign _1907 = ~ _1906;
    assign _1902 = ~ _1901;
    assign _1898 = 7'b1011000;
    assign _1899 = _578 == _1898;
    assign _1897 = _572 & _576;
    assign _1900 = _1897 & _1899;
    assign _1903 = _1900 & _1902;
    assign _1906 = t1_tx_level == _3415;
    assign _3401 = ~ _1906;
    assign _3377 = { _517,
                     _2219 };
    assign _423 = ~ _422;
    assign _3371 = ~ _422;
    assign _3369 = ~ _710;
    assign _3367 = _605 == _3415;
    assign _3343 = 4'b0001;
    assign _3344 = t0_delay_left - _3343;
    assign _3338 = _3336[3:2];
    assign _3339 = { _517,
                     _3338 };
    assign _3335 = 4'b0111;
    assign _3334 = 4'b1111;
    assign _3333 = _817[0:0];
    assign _3336 = _3333 ? _3335 : _3334;
    assign _3332 = _817[1:1];
    assign _3340 = _3332 ? _3339 : _3336;
    assign _3341 = _1305 & _3340;
    assign _422 = t0_rx_level == _3415;
    assign _718 = ~ _710;
    assign _717 = _605 == _3415;
    assign _719 = _717 & _718;
    assign _720 = _719 & _422;
    assign _709 = _605 == _3415;
    assign _711 = _709 & _710;
    assign _714 = _711 & _713;
    assign _706 = ~ _705;
    assign _703 = ~ _669;
    assign _701 = 3'b001;
    assign _3326 = 16'b1111111111111111;
    assign _583 = _582[7:0];
    assign _579 = 7'b1000001;
    assign _580 = _578 == _579;
    assign _577 = _572 & _576;
    assign _581 = _577 & _580;
    assign _584 = _581 ? _583 : cfg_t0_start;
    assign _7 = _584;
    always @(posedge _101) begin
        if (_99)
            cfg_t0_start <= _307;
        else
            cfg_t0_start <= _7;
    end
    assign _3316 = _88[5:0];
    assign _3315 = t0_pc[7:6];
    assign _3317 = { _3315,
                     _3316 };
    assign _589 = _582[7:0];
    assign _586 = 7'b1000110;
    assign _587 = _578 == _586;
    assign _585 = _572 & _576;
    assign _588 = _585 & _587;
    assign _590 = _588 ? _589 : cfg_t0_timeout_vector;
    assign _8 = _590;
    always @(posedge _101) begin
        if (_99)
            cfg_t0_timeout_vector <= _307;
        else
            cfg_t0_timeout_vector <= _8;
    end
    assign _3314 = _605 == _511;
    assign _3318 = _3314 ? _3317 : cfg_t0_timeout_vector;
    assign _3311 = 8'b00000001;
    assign _3312 = t0_pc + _3311;
    assign _685 = 16'b0000000000000001;
    assign _686 = _680 - _685;
    assign _687 = _684 ? _686 : t0_wait_count;
    assign _688 = _604 ? t0_wait_count : _687;
    assign _689 = _598 ? t0_wait_count : _688;
    assign _691 = _592 ? _358 : _689;
    assign _9 = _691;
    assign _10 = _9;
    always @(posedge _101) begin
        if (_99)
            t0_wait_count <= _358;
        else
            t0_wait_count <= _10;
    end
    assign _693 = 7'b1001011;
    assign _694 = _578 == _693;
    assign _692 = _572 & _576;
    assign _695 = _692 & _694;
    assign _696 = _695 ? _582 : cfg_t0_timeout;
    assign _11 = _696;
    always @(posedge _101) begin
        if (_99)
            cfg_t0_timeout <= _358;
        else
            cfg_t0_timeout <= _11;
    end
    assign _724 = 1'b1;
    assign _683 = ~ _682;
    assign _670 = ~ _669;
    assign _607 = _605 == _701;
    assign _671 = _607 & _670;
    assign _673 = _671 & _672;
    assign _684 = _673 & _683;
    assign _725 = _684 ? _724 : t0_waiting;
    assign _727 = _723 ? _566 : _725;
    assign _728 = _604 ? t0_waiting : _727;
    assign _729 = _598 ? t0_waiting : _728;
    assign _731 = _592 ? _566 : _729;
    assign _12 = _731;
    assign _13 = _12;
    always @(posedge _101) begin
        if (_99)
            t0_waiting <= _566;
        else
            t0_waiting <= _13;
    end
    assign _680 = t0_waiting ? t0_wait_count : cfg_t0_timeout;
    assign _682 = _680 == _358;
    assign _672 = _88[4:4];
    assign _705 = _672 & _682;
    assign _668 = _88[8:8];
    assign _666 = _658[7:7];
    assign _665 = _658[6:6];
    assign _664 = _658[5:5];
    assign _663 = _658[4:4];
    assign _662 = _658[3:3];
    assign _661 = _658[2:2];
    assign _660 = _658[1:1];
    assign _659 = _658[0:0];
    assign _608 = _88[7:5];
    always @* begin
        case (_608)
        0:
            _667 <= _659;
        1:
            _667 <= _660;
        2:
            _667 <= _661;
        3:
            _667 <= _662;
        4:
            _667 <= _663;
        5:
            _667 <= _664;
        6:
            _667 <= _665;
        default:
            _667 <= _666;
        endcase
    end
    assign _669 = _667 == _668;
    assign _3307 = ~ _669;
    assign _3306 = _605 == _701;
    assign _3308 = _3306 & _3307;
    assign _3309 = _3308 & _705;
    assign _3302 = t0_isr_count < cfg_t0_threshold;
    assign _739 = 5'b00000;
    assign _401 = 5'b01000;
    assign _736 = _582[4:0];
    assign _733 = 7'b1000101;
    assign _734 = _578 == _733;
    assign _732 = _572 & _576;
    assign _735 = _732 & _734;
    assign _737 = _735 ? _736 : cfg_t0_threshold;
    assign _14 = _737;
    always @(posedge _101) begin
        if (_99)
            cfg_t0_threshold <= _401;
        else
            cfg_t0_threshold <= _14;
    end
    assign _774 = _772[4:0];
    assign _771 = { gnd,
                    _770 };
    assign _764 = { gnd,
                    t0_osr_count };
    assign _772 = _764 + _771;
    assign _763 = 6'b010000;
    assign _773 = _763 < _772;
    assign _776 = _773 ? _254 : _774;
    assign _761 = _710 ? _739 : t0_osr_count;
    assign _755 = _747 == _3415;
    assign _757 = _755 ? _739 : t0_osr_count;
    assign _758 = _753 ? _757 : t0_osr_count;
    assign _746 = _605 == _2975;
    assign _759 = _746 ? _758 : t0_osr_count;
    assign _744 = _605 == _3415;
    assign _762 = _744 ? _761 : _759;
    assign _742 = _605 == _3009;
    assign _777 = _742 ? _776 : _762;
    assign _778 = _723 ? _777 : t0_osr_count;
    assign _779 = _604 ? t0_osr_count : _778;
    assign _780 = _598 ? t0_osr_count : _779;
    assign _781 = _592 ? cfg_t0_threshold : _780;
    assign _15 = _781;
    assign _16 = _15;
    always @(posedge _101) begin
        if (_99)
            t0_osr_count <= _739;
        else
            t0_osr_count <= _16;
    end
    assign _3301 = t0_osr_count < cfg_t0_threshold;
    assign _3299 = t0_x == t0_y;
    assign _3300 = ~ _3299;
    assign _3296 = t0_y == _358;
    assign _3297 = ~ _3296;
    assign _3298 = ~ _3297;
    assign _3281 = t0_x - _685;
    assign _3278 = 3'b010;
    assign _3279 = _3249 == _3278;
    assign _3282 = _3279 ? _3281 : t0_x;
    assign _3275 = _3244 == _186;
    assign _3276 = _3275 ? _1172 : t0_x;
    assign _656 = _655 & _654;
    assign _655 = pin_out[0:0];
    assign _654 = _618[0:0];
    assign _653 = cfg_pin_modes[1:0];
    always @* begin
        case (_653)
        0:
            _657 <= _654;
        1:
            _657 <= _655;
        2:
            _657 <= _656;
        default:
            _657 <= _654;
        endcase
    end
    assign _651 = _650 & _649;
    assign _650 = pin_out[1:1];
    assign _649 = _618[1:1];
    assign _648 = cfg_pin_modes[3:2];
    always @* begin
        case (_648)
        0:
            _652 <= _649;
        1:
            _652 <= _650;
        2:
            _652 <= _651;
        default:
            _652 <= _649;
        endcase
    end
    assign _646 = _645 & _644;
    assign _645 = pin_out[2:2];
    assign _644 = _618[2:2];
    assign _643 = cfg_pin_modes[5:4];
    always @* begin
        case (_643)
        0:
            _647 <= _644;
        1:
            _647 <= _645;
        2:
            _647 <= _646;
        default:
            _647 <= _644;
        endcase
    end
    assign _641 = _640 & _639;
    assign _640 = pin_out[3:3];
    assign _639 = _618[3:3];
    assign _638 = cfg_pin_modes[7:6];
    always @* begin
        case (_638)
        0:
            _642 <= _639;
        1:
            _642 <= _640;
        2:
            _642 <= _641;
        default:
            _642 <= _639;
        endcase
    end
    assign _636 = _635 & _634;
    assign _635 = pin_out[4:4];
    assign _634 = _618[4:4];
    assign _633 = cfg_pin_modes[9:8];
    always @* begin
        case (_633)
        0:
            _637 <= _634;
        1:
            _637 <= _635;
        2:
            _637 <= _636;
        default:
            _637 <= _634;
        endcase
    end
    assign _631 = _630 & _629;
    assign _630 = pin_out[5:5];
    assign _629 = _618[5:5];
    assign _628 = cfg_pin_modes[11:10];
    always @* begin
        case (_628)
        0:
            _632 <= _629;
        1:
            _632 <= _630;
        2:
            _632 <= _631;
        default:
            _632 <= _629;
        endcase
    end
    assign _626 = _625 & _624;
    assign _625 = pin_out[6:6];
    assign _624 = _618[6:6];
    assign _623 = cfg_pin_modes[13:12];
    always @* begin
        case (_623)
        0:
            _627 <= _624;
        1:
            _627 <= _625;
        2:
            _627 <= _626;
        default:
            _627 <= _624;
        endcase
    end
    assign _621 = _620 & _619;
    assign _119 = 8'b11111111;
    assign _3074 = _2947[7:7];
    assign _3073 = _2947[6:6];
    assign _3072 = _2947[5:5];
    assign _3071 = _2947[4:4];
    assign _3070 = _2947[3:3];
    assign _3069 = _2947[2:2];
    assign _3068 = _2947[1:1];
    assign _3067 = _2947[0:0];
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
    assign _3066 = _2928[0:0];
    assign _3064 = { _517,
                     _2489 };
    assign _3061 = _511 - _2525;
    assign _3062 = { gnd,
                     _3061 };
    assign _3065 = _3062 < _3064;
    assign _3076 = _3065 ? _3075 : _3066;
    assign _3057 = _2947[7:7];
    assign _3056 = _2947[6:6];
    assign _3055 = _2947[5:5];
    assign _3054 = _2947[4:4];
    assign _3053 = _2947[3:3];
    assign _3052 = _2947[2:2];
    assign _3051 = _2947[1:1];
    assign _3050 = _2947[0:0];
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
    assign _3049 = _2928[1:1];
    assign _3047 = { _517,
                     _2489 };
    assign _3044 = _701 - _2525;
    assign _3045 = { gnd,
                     _3044 };
    assign _3048 = _3045 < _3047;
    assign _3059 = _3048 ? _3058 : _3049;
    assign _3040 = _2947[7:7];
    assign _3039 = _2947[6:6];
    assign _3038 = _2947[5:5];
    assign _3037 = _2947[4:4];
    assign _3036 = _2947[3:3];
    assign _3035 = _2947[2:2];
    assign _3034 = _2947[1:1];
    assign _3033 = _2947[0:0];
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
    assign _3032 = _2928[2:2];
    assign _3030 = { _517,
                     _2489 };
    assign _3027 = _3278 - _2525;
    assign _3028 = { gnd,
                     _3027 };
    assign _3031 = _3028 < _3030;
    assign _3042 = _3031 ? _3041 : _3032;
    assign _3023 = _2947[7:7];
    assign _3022 = _2947[6:6];
    assign _3021 = _2947[5:5];
    assign _3020 = _2947[4:4];
    assign _3019 = _2947[3:3];
    assign _3018 = _2947[2:2];
    assign _3017 = _2947[1:1];
    assign _3016 = _2947[0:0];
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
    assign _3015 = _2928[3:3];
    assign _3013 = { _517,
                     _2489 };
    assign _3009 = 3'b011;
    assign _3010 = _3009 - _2525;
    assign _3011 = { gnd,
                     _3010 };
    assign _3014 = _3011 < _3013;
    assign _3025 = _3014 ? _3024 : _3015;
    assign _3006 = _2947[7:7];
    assign _3005 = _2947[6:6];
    assign _3004 = _2947[5:5];
    assign _3003 = _2947[4:4];
    assign _3002 = _2947[3:3];
    assign _3001 = _2947[2:2];
    assign _3000 = _2947[1:1];
    assign _2999 = _2947[0:0];
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
    assign _2998 = _2928[4:4];
    assign _2996 = { _517,
                     _2489 };
    assign _2993 = _3415 - _2525;
    assign _2994 = { gnd,
                     _2993 };
    assign _2997 = _2994 < _2996;
    assign _3008 = _2997 ? _3007 : _2998;
    assign _2989 = _2947[7:7];
    assign _2988 = _2947[6:6];
    assign _2987 = _2947[5:5];
    assign _2986 = _2947[4:4];
    assign _2985 = _2947[3:3];
    assign _2984 = _2947[2:2];
    assign _2983 = _2947[1:1];
    assign _2982 = _2947[0:0];
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
    assign _2981 = _2928[5:5];
    assign _2979 = { _517,
                     _2489 };
    assign _2975 = 3'b101;
    assign _2976 = _2975 - _2525;
    assign _2977 = { gnd,
                     _2976 };
    assign _2980 = _2977 < _2979;
    assign _2991 = _2980 ? _2990 : _2981;
    assign _2972 = _2947[7:7];
    assign _2971 = _2947[6:6];
    assign _2970 = _2947[5:5];
    assign _2969 = _2947[4:4];
    assign _2968 = _2947[3:3];
    assign _2967 = _2947[2:2];
    assign _2966 = _2947[1:1];
    assign _2965 = _2947[0:0];
    always @* begin
        case (_2959)
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
    assign _2964 = _2928[6:6];
    assign _2962 = { _517,
                     _2489 };
    assign _2958 = 3'b110;
    assign _2959 = _2958 - _2525;
    assign _2960 = { gnd,
                     _2959 };
    assign _2963 = _2960 < _2962;
    assign _2974 = _2963 ? _2973 : _2964;
    assign _2955 = _2947[7:7];
    assign _2954 = _2947[6:6];
    assign _2953 = _2947[5:5];
    assign _2952 = _2947[4:4];
    assign _2951 = _2947[3:3];
    assign _2950 = _2947[2:2];
    assign _2949 = _2947[1:1];
    assign _2942 = _2940[3:2];
    assign _2943 = { _517,
                     _2942 };
    assign _2938 = _2488[3:1];
    assign _2939 = { _566,
                     _2938 };
    assign _2936 = _2933[0:0];
    assign _2940 = _2936 ? _2939 : _2488;
    assign _2935 = _2933[1:1];
    assign _2944 = _2935 ? _2943 : _2940;
    assign _2932 = { gnd,
                     _2489 };
    assign _2933 = _3415 - _2932;
    assign _2934 = _2933[2:2];
    assign _2946 = _2934 ? _303 : _2944;
    assign _2947 = { _303,
                     _2946 };
    assign _2948 = _2947[0:0];
    always @* begin
        case (_2526)
        0:
            _2956 <= _2948;
        1:
            _2956 <= _2949;
        2:
            _2956 <= _2950;
        3:
            _2956 <= _2951;
        4:
            _2956 <= _2952;
        5:
            _2956 <= _2953;
        6:
            _2956 <= _2954;
        default:
            _2956 <= _2955;
        endcase
    end
    assign _2924 = _2395[7:7];
    assign _2923 = _2395[6:6];
    assign _2922 = _2395[5:5];
    assign _2921 = _2395[4:4];
    assign _2920 = _2395[3:3];
    assign _2919 = _2395[2:2];
    assign _2918 = _2395[1:1];
    assign _2917 = _2395[0:0];
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
    assign _2916 = _22[0:0];
    assign _2913 = _511 - _2676;
    assign _2914 = { _517,
                     _2913 };
    assign _2915 = _2914 < _1614;
    assign _2926 = _2915 ? _2925 : _2916;
    assign _2908 = _2395[7:7];
    assign _2907 = _2395[6:6];
    assign _2906 = _2395[5:5];
    assign _2905 = _2395[4:4];
    assign _2904 = _2395[3:3];
    assign _2903 = _2395[2:2];
    assign _2902 = _2395[1:1];
    assign _2901 = _2395[0:0];
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
    assign _2900 = _22[1:1];
    assign _2897 = _701 - _2676;
    assign _2898 = { _517,
                     _2897 };
    assign _2899 = _2898 < _1614;
    assign _2910 = _2899 ? _2909 : _2900;
    assign _2892 = _2395[7:7];
    assign _2891 = _2395[6:6];
    assign _2890 = _2395[5:5];
    assign _2889 = _2395[4:4];
    assign _2888 = _2395[3:3];
    assign _2887 = _2395[2:2];
    assign _2886 = _2395[1:1];
    assign _2885 = _2395[0:0];
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
    assign _2884 = _22[2:2];
    assign _2881 = _3278 - _2676;
    assign _2882 = { _517,
                     _2881 };
    assign _2883 = _2882 < _1614;
    assign _2894 = _2883 ? _2893 : _2884;
    assign _2876 = _2395[7:7];
    assign _2875 = _2395[6:6];
    assign _2874 = _2395[5:5];
    assign _2873 = _2395[4:4];
    assign _2872 = _2395[3:3];
    assign _2871 = _2395[2:2];
    assign _2870 = _2395[1:1];
    assign _2869 = _2395[0:0];
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
    assign _2868 = _22[3:3];
    assign _2865 = _3009 - _2676;
    assign _2866 = { _517,
                     _2865 };
    assign _2867 = _2866 < _1614;
    assign _2878 = _2867 ? _2877 : _2868;
    assign _2860 = _2395[7:7];
    assign _2859 = _2395[6:6];
    assign _2858 = _2395[5:5];
    assign _2857 = _2395[4:4];
    assign _2856 = _2395[3:3];
    assign _2855 = _2395[2:2];
    assign _2854 = _2395[1:1];
    assign _2853 = _2395[0:0];
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
    assign _2852 = _22[4:4];
    assign _2849 = _3415 - _2676;
    assign _2850 = { _517,
                     _2849 };
    assign _2851 = _2850 < _1614;
    assign _2862 = _2851 ? _2861 : _2852;
    assign _2844 = _2395[7:7];
    assign _2843 = _2395[6:6];
    assign _2842 = _2395[5:5];
    assign _2841 = _2395[4:4];
    assign _2840 = _2395[3:3];
    assign _2839 = _2395[2:2];
    assign _2838 = _2395[1:1];
    assign _2837 = _2395[0:0];
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
    assign _2836 = _22[5:5];
    assign _2833 = _2975 - _2676;
    assign _2834 = { _517,
                     _2833 };
    assign _2835 = _2834 < _1614;
    assign _2846 = _2835 ? _2845 : _2836;
    assign _2828 = _2395[7:7];
    assign _2827 = _2395[6:6];
    assign _2826 = _2395[5:5];
    assign _2825 = _2395[4:4];
    assign _2824 = _2395[3:3];
    assign _2823 = _2395[2:2];
    assign _2822 = _2395[1:1];
    assign _2821 = _2395[0:0];
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
    assign _2820 = _22[6:6];
    assign _2817 = _2958 - _2676;
    assign _2818 = { _517,
                     _2817 };
    assign _2819 = _2818 < _1614;
    assign _2830 = _2819 ? _2829 : _2820;
    assign _2812 = _2395[7:7];
    assign _2811 = _2395[6:6];
    assign _2810 = _2395[5:5];
    assign _2809 = _2395[4:4];
    assign _2808 = _2395[3:3];
    assign _2807 = _2395[2:2];
    assign _2806 = _2395[1:1];
    assign _2805 = _2395[0:0];
    always @* begin
        case (_2801)
        0:
            _2813 <= _2805;
        1:
            _2813 <= _2806;
        2:
            _2813 <= _2807;
        3:
            _2813 <= _2808;
        4:
            _2813 <= _2809;
        5:
            _2813 <= _2810;
        6:
            _2813 <= _2811;
        default:
            _2813 <= _2812;
        endcase
    end
    assign _2804 = _22[7:7];
    assign _2800 = 3'b111;
    assign _2801 = _2800 - _2676;
    assign _2802 = { _517,
                     _2801 };
    assign _2803 = _2802 < _1614;
    assign _2814 = _2803 ? _2813 : _2804;
    assign _2927 = { _2814,
                     _2830,
                     _2846,
                     _2862,
                     _2878,
                     _2894,
                     _2910,
                     _2926 };
    assign _2794 = _1684[7:7];
    assign _2793 = _1684[6:6];
    assign _2792 = _1684[5:5];
    assign _2791 = _1684[4:4];
    assign _2790 = _1684[3:3];
    assign _2789 = _1684[2:2];
    assign _2788 = _1684[1:1];
    assign _2787 = _1684[0:0];
    always @* begin
        case (_2783)
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
    assign _2786 = _22[0:0];
    assign _2783 = _511 - _2676;
    assign _2784 = { gnd,
                     _2783 };
    assign _2785 = _2784 < _2679;
    assign _2796 = _2785 ? _2795 : _2786;
    assign _2779 = _1684[7:7];
    assign _2778 = _1684[6:6];
    assign _2777 = _1684[5:5];
    assign _2776 = _1684[4:4];
    assign _2775 = _1684[3:3];
    assign _2774 = _1684[2:2];
    assign _2773 = _1684[1:1];
    assign _2772 = _1684[0:0];
    always @* begin
        case (_2768)
        0:
            _2780 <= _2772;
        1:
            _2780 <= _2773;
        2:
            _2780 <= _2774;
        3:
            _2780 <= _2775;
        4:
            _2780 <= _2776;
        5:
            _2780 <= _2777;
        6:
            _2780 <= _2778;
        default:
            _2780 <= _2779;
        endcase
    end
    assign _2771 = _22[1:1];
    assign _2768 = _701 - _2676;
    assign _2769 = { gnd,
                     _2768 };
    assign _2770 = _2769 < _2679;
    assign _2781 = _2770 ? _2780 : _2771;
    assign _2764 = _1684[7:7];
    assign _2763 = _1684[6:6];
    assign _2762 = _1684[5:5];
    assign _2761 = _1684[4:4];
    assign _2760 = _1684[3:3];
    assign _2759 = _1684[2:2];
    assign _2758 = _1684[1:1];
    assign _2757 = _1684[0:0];
    always @* begin
        case (_2753)
        0:
            _2765 <= _2757;
        1:
            _2765 <= _2758;
        2:
            _2765 <= _2759;
        3:
            _2765 <= _2760;
        4:
            _2765 <= _2761;
        5:
            _2765 <= _2762;
        6:
            _2765 <= _2763;
        default:
            _2765 <= _2764;
        endcase
    end
    assign _2756 = _22[2:2];
    assign _2753 = _3278 - _2676;
    assign _2754 = { gnd,
                     _2753 };
    assign _2755 = _2754 < _2679;
    assign _2766 = _2755 ? _2765 : _2756;
    assign _2749 = _1684[7:7];
    assign _2748 = _1684[6:6];
    assign _2747 = _1684[5:5];
    assign _2746 = _1684[4:4];
    assign _2745 = _1684[3:3];
    assign _2744 = _1684[2:2];
    assign _2743 = _1684[1:1];
    assign _2742 = _1684[0:0];
    always @* begin
        case (_2738)
        0:
            _2750 <= _2742;
        1:
            _2750 <= _2743;
        2:
            _2750 <= _2744;
        3:
            _2750 <= _2745;
        4:
            _2750 <= _2746;
        5:
            _2750 <= _2747;
        6:
            _2750 <= _2748;
        default:
            _2750 <= _2749;
        endcase
    end
    assign _2741 = _22[3:3];
    assign _2738 = _3009 - _2676;
    assign _2739 = { gnd,
                     _2738 };
    assign _2740 = _2739 < _2679;
    assign _2751 = _2740 ? _2750 : _2741;
    assign _2734 = _1684[7:7];
    assign _2733 = _1684[6:6];
    assign _2732 = _1684[5:5];
    assign _2731 = _1684[4:4];
    assign _2730 = _1684[3:3];
    assign _2729 = _1684[2:2];
    assign _2728 = _1684[1:1];
    assign _2727 = _1684[0:0];
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
    assign _2726 = _22[4:4];
    assign _2723 = _3415 - _2676;
    assign _2724 = { gnd,
                     _2723 };
    assign _2725 = _2724 < _2679;
    assign _2736 = _2725 ? _2735 : _2726;
    assign _2719 = _1684[7:7];
    assign _2718 = _1684[6:6];
    assign _2717 = _1684[5:5];
    assign _2716 = _1684[4:4];
    assign _2715 = _1684[3:3];
    assign _2714 = _1684[2:2];
    assign _2713 = _1684[1:1];
    assign _2712 = _1684[0:0];
    always @* begin
        case (_2708)
        0:
            _2720 <= _2712;
        1:
            _2720 <= _2713;
        2:
            _2720 <= _2714;
        3:
            _2720 <= _2715;
        4:
            _2720 <= _2716;
        5:
            _2720 <= _2717;
        6:
            _2720 <= _2718;
        default:
            _2720 <= _2719;
        endcase
    end
    assign _2711 = _22[5:5];
    assign _2708 = _2975 - _2676;
    assign _2709 = { gnd,
                     _2708 };
    assign _2710 = _2709 < _2679;
    assign _2721 = _2710 ? _2720 : _2711;
    assign _2704 = _1684[7:7];
    assign _2703 = _1684[6:6];
    assign _2702 = _1684[5:5];
    assign _2701 = _1684[4:4];
    assign _2700 = _1684[3:3];
    assign _2699 = _1684[2:2];
    assign _2698 = _1684[1:1];
    assign _2697 = _1684[0:0];
    always @* begin
        case (_2693)
        0:
            _2705 <= _2697;
        1:
            _2705 <= _2698;
        2:
            _2705 <= _2699;
        3:
            _2705 <= _2700;
        4:
            _2705 <= _2701;
        5:
            _2705 <= _2702;
        6:
            _2705 <= _2703;
        default:
            _2705 <= _2704;
        endcase
    end
    assign _2696 = _22[6:6];
    assign _2693 = _2958 - _2676;
    assign _2694 = { gnd,
                     _2693 };
    assign _2695 = _2694 < _2679;
    assign _2706 = _2695 ? _2705 : _2696;
    assign _2689 = _1684[7:7];
    assign _2688 = _1684[6:6];
    assign _2687 = _1684[5:5];
    assign _2686 = _1684[4:4];
    assign _2685 = _1684[3:3];
    assign _2684 = _1684[2:2];
    assign _2683 = _1684[1:1];
    assign _2682 = _1684[0:0];
    always @* begin
        case (_2677)
        0:
            _2690 <= _2682;
        1:
            _2690 <= _2683;
        2:
            _2690 <= _2684;
        3:
            _2690 <= _2685;
        4:
            _2690 <= _2686;
        5:
            _2690 <= _2687;
        6:
            _2690 <= _2688;
        default:
            _2690 <= _2689;
        endcase
    end
    assign _2681 = _22[7:7];
    assign _2679 = cfg_t1_out_cfg[7:4];
    assign _488 = 8'b00010000;
    assign _786 = _582[7:0];
    assign _783 = 7'b1010010;
    assign _784 = _578 == _783;
    assign _782 = _572 & _576;
    assign _785 = _782 & _784;
    assign _787 = _785 ? _786 : cfg_t1_out_cfg;
    assign _17 = _787;
    always @(posedge _101) begin
        if (_99)
            cfg_t1_out_cfg <= _488;
        else
            cfg_t1_out_cfg <= _17;
    end
    assign _2676 = cfg_t1_out_cfg[2:0];
    assign _2677 = _2800 - _2676;
    assign _2678 = { gnd,
                     _2677 };
    assign _2680 = _2678 < _2679;
    assign _2691 = _2680 ? _2690 : _2681;
    assign _2797 = { _2691,
                     _2706,
                     _2721,
                     _2736,
                     _2751,
                     _2766,
                     _2781,
                     _2796 };
    assign _2670 = _2353[7:7];
    assign _2669 = _2353[6:6];
    assign _2668 = _2353[5:5];
    assign _2667 = _2353[4:4];
    assign _2666 = _2353[3:3];
    assign _2665 = _2353[2:2];
    assign _2664 = _2353[1:1];
    assign _2663 = _2353[0:0];
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
    assign _2662 = _22[0:0];
    assign _2659 = _511 - _2552;
    assign _2660 = { gnd,
                     _2659 };
    assign _2661 = _2660 < _2555;
    assign _2672 = _2661 ? _2671 : _2662;
    assign _2655 = _2353[7:7];
    assign _2654 = _2353[6:6];
    assign _2653 = _2353[5:5];
    assign _2652 = _2353[4:4];
    assign _2651 = _2353[3:3];
    assign _2650 = _2353[2:2];
    assign _2649 = _2353[1:1];
    assign _2648 = _2353[0:0];
    always @* begin
        case (_2644)
        0:
            _2656 <= _2648;
        1:
            _2656 <= _2649;
        2:
            _2656 <= _2650;
        3:
            _2656 <= _2651;
        4:
            _2656 <= _2652;
        5:
            _2656 <= _2653;
        6:
            _2656 <= _2654;
        default:
            _2656 <= _2655;
        endcase
    end
    assign _2647 = _22[1:1];
    assign _2644 = _701 - _2552;
    assign _2645 = { gnd,
                     _2644 };
    assign _2646 = _2645 < _2555;
    assign _2657 = _2646 ? _2656 : _2647;
    assign _2640 = _2353[7:7];
    assign _2639 = _2353[6:6];
    assign _2638 = _2353[5:5];
    assign _2637 = _2353[4:4];
    assign _2636 = _2353[3:3];
    assign _2635 = _2353[2:2];
    assign _2634 = _2353[1:1];
    assign _2633 = _2353[0:0];
    always @* begin
        case (_2629)
        0:
            _2641 <= _2633;
        1:
            _2641 <= _2634;
        2:
            _2641 <= _2635;
        3:
            _2641 <= _2636;
        4:
            _2641 <= _2637;
        5:
            _2641 <= _2638;
        6:
            _2641 <= _2639;
        default:
            _2641 <= _2640;
        endcase
    end
    assign _2632 = _22[2:2];
    assign _2629 = _3278 - _2552;
    assign _2630 = { gnd,
                     _2629 };
    assign _2631 = _2630 < _2555;
    assign _2642 = _2631 ? _2641 : _2632;
    assign _2625 = _2353[7:7];
    assign _2624 = _2353[6:6];
    assign _2623 = _2353[5:5];
    assign _2622 = _2353[4:4];
    assign _2621 = _2353[3:3];
    assign _2620 = _2353[2:2];
    assign _2619 = _2353[1:1];
    assign _2618 = _2353[0:0];
    always @* begin
        case (_2614)
        0:
            _2626 <= _2618;
        1:
            _2626 <= _2619;
        2:
            _2626 <= _2620;
        3:
            _2626 <= _2621;
        4:
            _2626 <= _2622;
        5:
            _2626 <= _2623;
        6:
            _2626 <= _2624;
        default:
            _2626 <= _2625;
        endcase
    end
    assign _2617 = _22[3:3];
    assign _2614 = _3009 - _2552;
    assign _2615 = { gnd,
                     _2614 };
    assign _2616 = _2615 < _2555;
    assign _2627 = _2616 ? _2626 : _2617;
    assign _2610 = _2353[7:7];
    assign _2609 = _2353[6:6];
    assign _2608 = _2353[5:5];
    assign _2607 = _2353[4:4];
    assign _2606 = _2353[3:3];
    assign _2605 = _2353[2:2];
    assign _2604 = _2353[1:1];
    assign _2603 = _2353[0:0];
    always @* begin
        case (_2599)
        0:
            _2611 <= _2603;
        1:
            _2611 <= _2604;
        2:
            _2611 <= _2605;
        3:
            _2611 <= _2606;
        4:
            _2611 <= _2607;
        5:
            _2611 <= _2608;
        6:
            _2611 <= _2609;
        default:
            _2611 <= _2610;
        endcase
    end
    assign _2602 = _22[4:4];
    assign _2599 = _3415 - _2552;
    assign _2600 = { gnd,
                     _2599 };
    assign _2601 = _2600 < _2555;
    assign _2612 = _2601 ? _2611 : _2602;
    assign _2595 = _2353[7:7];
    assign _2594 = _2353[6:6];
    assign _2593 = _2353[5:5];
    assign _2592 = _2353[4:4];
    assign _2591 = _2353[3:3];
    assign _2590 = _2353[2:2];
    assign _2589 = _2353[1:1];
    assign _2588 = _2353[0:0];
    always @* begin
        case (_2584)
        0:
            _2596 <= _2588;
        1:
            _2596 <= _2589;
        2:
            _2596 <= _2590;
        3:
            _2596 <= _2591;
        4:
            _2596 <= _2592;
        5:
            _2596 <= _2593;
        6:
            _2596 <= _2594;
        default:
            _2596 <= _2595;
        endcase
    end
    assign _2587 = _22[5:5];
    assign _2584 = _2975 - _2552;
    assign _2585 = { gnd,
                     _2584 };
    assign _2586 = _2585 < _2555;
    assign _2597 = _2586 ? _2596 : _2587;
    assign _2580 = _2353[7:7];
    assign _2579 = _2353[6:6];
    assign _2578 = _2353[5:5];
    assign _2577 = _2353[4:4];
    assign _2576 = _2353[3:3];
    assign _2575 = _2353[2:2];
    assign _2574 = _2353[1:1];
    assign _2573 = _2353[0:0];
    always @* begin
        case (_2569)
        0:
            _2581 <= _2573;
        1:
            _2581 <= _2574;
        2:
            _2581 <= _2575;
        3:
            _2581 <= _2576;
        4:
            _2581 <= _2577;
        5:
            _2581 <= _2578;
        6:
            _2581 <= _2579;
        default:
            _2581 <= _2580;
        endcase
    end
    assign _2572 = _22[6:6];
    assign _2569 = _2958 - _2552;
    assign _2570 = { gnd,
                     _2569 };
    assign _2571 = _2570 < _2555;
    assign _2582 = _2571 ? _2581 : _2572;
    assign _2565 = _2353[7:7];
    assign _2564 = _2353[6:6];
    assign _2563 = _2353[5:5];
    assign _2562 = _2353[4:4];
    assign _2561 = _2353[3:3];
    assign _2560 = _2353[2:2];
    assign _2559 = _2353[1:1];
    assign _2558 = _2353[0:0];
    always @* begin
        case (_2553)
        0:
            _2566 <= _2558;
        1:
            _2566 <= _2559;
        2:
            _2566 <= _2560;
        3:
            _2566 <= _2561;
        4:
            _2566 <= _2562;
        5:
            _2566 <= _2563;
        6:
            _2566 <= _2564;
        default:
            _2566 <= _2565;
        endcase
    end
    assign _2557 = _22[7:7];
    assign _2555 = cfg_t1_set_cfg[7:4];
    assign _792 = _582[7:0];
    assign _789 = 7'b1010011;
    assign _790 = _578 == _789;
    assign _788 = _572 & _576;
    assign _791 = _788 & _790;
    assign _793 = _791 ? _792 : cfg_t1_set_cfg;
    assign _18 = _793;
    always @(posedge _101) begin
        if (_99)
            cfg_t1_set_cfg <= _488;
        else
            cfg_t1_set_cfg <= _18;
    end
    assign _2552 = cfg_t1_set_cfg[2:0];
    assign _2553 = _2800 - _2552;
    assign _2554 = { gnd,
                     _2553 };
    assign _2556 = _2554 < _2555;
    assign _2567 = _2556 ? _2566 : _2557;
    assign _2673 = { _2567,
                     _2582,
                     _2597,
                     _2612,
                     _2627,
                     _2642,
                     _2657,
                     _2672 };
    assign _1443 = _1316[7:7];
    assign _1442 = _1316[6:6];
    assign _1441 = _1316[5:5];
    assign _1440 = _1316[4:4];
    assign _1439 = _1316[3:3];
    assign _1438 = _1316[2:2];
    assign _1437 = _1316[1:1];
    assign _1436 = _1316[0:0];
    always @* begin
        case (_1430)
        0:
            _1444 <= _1436;
        1:
            _1444 <= _1437;
        2:
            _1444 <= _1438;
        3:
            _1444 <= _1439;
        4:
            _1444 <= _1440;
        5:
            _1444 <= _1441;
        6:
            _1444 <= _1442;
        default:
            _1444 <= _1443;
        endcase
    end
    assign _1435 = _1296[0:0];
    assign _1433 = { _517,
                     _817 };
    assign _1430 = _511 - _813;
    assign _1431 = { gnd,
                     _1430 };
    assign _1434 = _1431 < _1433;
    assign _1445 = _1434 ? _1444 : _1435;
    assign _1426 = _1316[7:7];
    assign _1425 = _1316[6:6];
    assign _1424 = _1316[5:5];
    assign _1423 = _1316[4:4];
    assign _1422 = _1316[3:3];
    assign _1421 = _1316[2:2];
    assign _1420 = _1316[1:1];
    assign _1419 = _1316[0:0];
    always @* begin
        case (_1413)
        0:
            _1427 <= _1419;
        1:
            _1427 <= _1420;
        2:
            _1427 <= _1421;
        3:
            _1427 <= _1422;
        4:
            _1427 <= _1423;
        5:
            _1427 <= _1424;
        6:
            _1427 <= _1425;
        default:
            _1427 <= _1426;
        endcase
    end
    assign _1418 = _1296[1:1];
    assign _1416 = { _517,
                     _817 };
    assign _1413 = _701 - _813;
    assign _1414 = { gnd,
                     _1413 };
    assign _1417 = _1414 < _1416;
    assign _1428 = _1417 ? _1427 : _1418;
    assign _1409 = _1316[7:7];
    assign _1408 = _1316[6:6];
    assign _1407 = _1316[5:5];
    assign _1406 = _1316[4:4];
    assign _1405 = _1316[3:3];
    assign _1404 = _1316[2:2];
    assign _1403 = _1316[1:1];
    assign _1402 = _1316[0:0];
    always @* begin
        case (_1396)
        0:
            _1410 <= _1402;
        1:
            _1410 <= _1403;
        2:
            _1410 <= _1404;
        3:
            _1410 <= _1405;
        4:
            _1410 <= _1406;
        5:
            _1410 <= _1407;
        6:
            _1410 <= _1408;
        default:
            _1410 <= _1409;
        endcase
    end
    assign _1401 = _1296[2:2];
    assign _1399 = { _517,
                     _817 };
    assign _1396 = _3278 - _813;
    assign _1397 = { gnd,
                     _1396 };
    assign _1400 = _1397 < _1399;
    assign _1411 = _1400 ? _1410 : _1401;
    assign _1392 = _1316[7:7];
    assign _1391 = _1316[6:6];
    assign _1390 = _1316[5:5];
    assign _1389 = _1316[4:4];
    assign _1388 = _1316[3:3];
    assign _1387 = _1316[2:2];
    assign _1386 = _1316[1:1];
    assign _1385 = _1316[0:0];
    always @* begin
        case (_1379)
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
    assign _1384 = _1296[3:3];
    assign _1382 = { _517,
                     _817 };
    assign _1379 = _3009 - _813;
    assign _1380 = { gnd,
                     _1379 };
    assign _1383 = _1380 < _1382;
    assign _1394 = _1383 ? _1393 : _1384;
    assign _1375 = _1316[7:7];
    assign _1374 = _1316[6:6];
    assign _1373 = _1316[5:5];
    assign _1372 = _1316[4:4];
    assign _1371 = _1316[3:3];
    assign _1370 = _1316[2:2];
    assign _1369 = _1316[1:1];
    assign _1368 = _1316[0:0];
    always @* begin
        case (_1362)
        0:
            _1376 <= _1368;
        1:
            _1376 <= _1369;
        2:
            _1376 <= _1370;
        3:
            _1376 <= _1371;
        4:
            _1376 <= _1372;
        5:
            _1376 <= _1373;
        6:
            _1376 <= _1374;
        default:
            _1376 <= _1375;
        endcase
    end
    assign _1367 = _1296[4:4];
    assign _1365 = { _517,
                     _817 };
    assign _1362 = _3415 - _813;
    assign _1363 = { gnd,
                     _1362 };
    assign _1366 = _1363 < _1365;
    assign _1377 = _1366 ? _1376 : _1367;
    assign _1358 = _1316[7:7];
    assign _1357 = _1316[6:6];
    assign _1356 = _1316[5:5];
    assign _1355 = _1316[4:4];
    assign _1354 = _1316[3:3];
    assign _1353 = _1316[2:2];
    assign _1352 = _1316[1:1];
    assign _1351 = _1316[0:0];
    always @* begin
        case (_1345)
        0:
            _1359 <= _1351;
        1:
            _1359 <= _1352;
        2:
            _1359 <= _1353;
        3:
            _1359 <= _1354;
        4:
            _1359 <= _1355;
        5:
            _1359 <= _1356;
        6:
            _1359 <= _1357;
        default:
            _1359 <= _1358;
        endcase
    end
    assign _1350 = _1296[5:5];
    assign _1348 = { _517,
                     _817 };
    assign _1345 = _2975 - _813;
    assign _1346 = { gnd,
                     _1345 };
    assign _1349 = _1346 < _1348;
    assign _1360 = _1349 ? _1359 : _1350;
    assign _1341 = _1316[7:7];
    assign _1340 = _1316[6:6];
    assign _1339 = _1316[5:5];
    assign _1338 = _1316[4:4];
    assign _1337 = _1316[3:3];
    assign _1336 = _1316[2:2];
    assign _1335 = _1316[1:1];
    assign _1334 = _1316[0:0];
    always @* begin
        case (_1328)
        0:
            _1342 <= _1334;
        1:
            _1342 <= _1335;
        2:
            _1342 <= _1336;
        3:
            _1342 <= _1337;
        4:
            _1342 <= _1338;
        5:
            _1342 <= _1339;
        6:
            _1342 <= _1340;
        default:
            _1342 <= _1341;
        endcase
    end
    assign _1333 = _1296[6:6];
    assign _1331 = { _517,
                     _817 };
    assign _1328 = _2958 - _813;
    assign _1329 = { gnd,
                     _1328 };
    assign _1332 = _1329 < _1331;
    assign _1343 = _1332 ? _1342 : _1333;
    assign _1324 = _1316[7:7];
    assign _1323 = _1316[6:6];
    assign _1322 = _1316[5:5];
    assign _1321 = _1316[4:4];
    assign _1320 = _1316[3:3];
    assign _1319 = _1316[2:2];
    assign _1318 = _1316[1:1];
    assign _1311 = _1309[3:2];
    assign _1312 = { _517,
                     _1311 };
    assign _1307 = _1305[3:1];
    assign _1308 = { _566,
                     _1307 };
    assign _1305 = _88[12:9];
    assign _1304 = _1301[0:0];
    assign _1309 = _1304 ? _1308 : _1305;
    assign _1303 = _1301[1:1];
    assign _1313 = _1303 ? _1312 : _1309;
    assign _1300 = { gnd,
                     _817 };
    assign _1301 = _3415 - _1300;
    assign _1302 = _1301[2:2];
    assign _1315 = _1302 ? _303 : _1313;
    assign _1316 = { _303,
                     _1315 };
    assign _1317 = _1316[0:0];
    always @* begin
        case (_814)
        0:
            _1325 <= _1317;
        1:
            _1325 <= _1318;
        2:
            _1325 <= _1319;
        3:
            _1325 <= _1320;
        4:
            _1325 <= _1321;
        5:
            _1325 <= _1322;
        6:
            _1325 <= _1323;
        default:
            _1325 <= _1324;
        endcase
    end
    assign _1292 = _1172[7:7];
    assign _1291 = _1172[6:6];
    assign _1290 = _1172[5:5];
    assign _1289 = _1172[4:4];
    assign _1288 = _1172[3:3];
    assign _1287 = _1172[2:2];
    assign _1286 = _1172[1:1];
    assign _1285 = _1172[0:0];
    always @* begin
        case (_1281)
        0:
            _1293 <= _1285;
        1:
            _1293 <= _1286;
        2:
            _1293 <= _1287;
        3:
            _1293 <= _1288;
        4:
            _1293 <= _1289;
        5:
            _1293 <= _1290;
        6:
            _1293 <= _1291;
        default:
            _1293 <= _1292;
        endcase
    end
    assign _1284 = pin_out[0:0];
    assign _1281 = _511 - _969;
    assign _1282 = { _517,
                     _1281 };
    assign _1283 = _1282 < _770;
    assign _1294 = _1283 ? _1293 : _1284;
    assign _1276 = _1172[7:7];
    assign _1275 = _1172[6:6];
    assign _1274 = _1172[5:5];
    assign _1273 = _1172[4:4];
    assign _1272 = _1172[3:3];
    assign _1271 = _1172[2:2];
    assign _1270 = _1172[1:1];
    assign _1269 = _1172[0:0];
    always @* begin
        case (_1265)
        0:
            _1277 <= _1269;
        1:
            _1277 <= _1270;
        2:
            _1277 <= _1271;
        3:
            _1277 <= _1272;
        4:
            _1277 <= _1273;
        5:
            _1277 <= _1274;
        6:
            _1277 <= _1275;
        default:
            _1277 <= _1276;
        endcase
    end
    assign _1268 = pin_out[1:1];
    assign _1265 = _701 - _969;
    assign _1266 = { _517,
                     _1265 };
    assign _1267 = _1266 < _770;
    assign _1278 = _1267 ? _1277 : _1268;
    assign _1260 = _1172[7:7];
    assign _1259 = _1172[6:6];
    assign _1258 = _1172[5:5];
    assign _1257 = _1172[4:4];
    assign _1256 = _1172[3:3];
    assign _1255 = _1172[2:2];
    assign _1254 = _1172[1:1];
    assign _1253 = _1172[0:0];
    always @* begin
        case (_1249)
        0:
            _1261 <= _1253;
        1:
            _1261 <= _1254;
        2:
            _1261 <= _1255;
        3:
            _1261 <= _1256;
        4:
            _1261 <= _1257;
        5:
            _1261 <= _1258;
        6:
            _1261 <= _1259;
        default:
            _1261 <= _1260;
        endcase
    end
    assign _1252 = pin_out[2:2];
    assign _1249 = _3278 - _969;
    assign _1250 = { _517,
                     _1249 };
    assign _1251 = _1250 < _770;
    assign _1262 = _1251 ? _1261 : _1252;
    assign _1244 = _1172[7:7];
    assign _1243 = _1172[6:6];
    assign _1242 = _1172[5:5];
    assign _1241 = _1172[4:4];
    assign _1240 = _1172[3:3];
    assign _1239 = _1172[2:2];
    assign _1238 = _1172[1:1];
    assign _1237 = _1172[0:0];
    always @* begin
        case (_1233)
        0:
            _1245 <= _1237;
        1:
            _1245 <= _1238;
        2:
            _1245 <= _1239;
        3:
            _1245 <= _1240;
        4:
            _1245 <= _1241;
        5:
            _1245 <= _1242;
        6:
            _1245 <= _1243;
        default:
            _1245 <= _1244;
        endcase
    end
    assign _1236 = pin_out[3:3];
    assign _1233 = _3009 - _969;
    assign _1234 = { _517,
                     _1233 };
    assign _1235 = _1234 < _770;
    assign _1246 = _1235 ? _1245 : _1236;
    assign _1228 = _1172[7:7];
    assign _1227 = _1172[6:6];
    assign _1226 = _1172[5:5];
    assign _1225 = _1172[4:4];
    assign _1224 = _1172[3:3];
    assign _1223 = _1172[2:2];
    assign _1222 = _1172[1:1];
    assign _1221 = _1172[0:0];
    always @* begin
        case (_1217)
        0:
            _1229 <= _1221;
        1:
            _1229 <= _1222;
        2:
            _1229 <= _1223;
        3:
            _1229 <= _1224;
        4:
            _1229 <= _1225;
        5:
            _1229 <= _1226;
        6:
            _1229 <= _1227;
        default:
            _1229 <= _1228;
        endcase
    end
    assign _1220 = pin_out[4:4];
    assign _1217 = _3415 - _969;
    assign _1218 = { _517,
                     _1217 };
    assign _1219 = _1218 < _770;
    assign _1230 = _1219 ? _1229 : _1220;
    assign _1212 = _1172[7:7];
    assign _1211 = _1172[6:6];
    assign _1210 = _1172[5:5];
    assign _1209 = _1172[4:4];
    assign _1208 = _1172[3:3];
    assign _1207 = _1172[2:2];
    assign _1206 = _1172[1:1];
    assign _1205 = _1172[0:0];
    always @* begin
        case (_1201)
        0:
            _1213 <= _1205;
        1:
            _1213 <= _1206;
        2:
            _1213 <= _1207;
        3:
            _1213 <= _1208;
        4:
            _1213 <= _1209;
        5:
            _1213 <= _1210;
        6:
            _1213 <= _1211;
        default:
            _1213 <= _1212;
        endcase
    end
    assign _1204 = pin_out[5:5];
    assign _1201 = _2975 - _969;
    assign _1202 = { _517,
                     _1201 };
    assign _1203 = _1202 < _770;
    assign _1214 = _1203 ? _1213 : _1204;
    assign _1196 = _1172[7:7];
    assign _1195 = _1172[6:6];
    assign _1194 = _1172[5:5];
    assign _1193 = _1172[4:4];
    assign _1192 = _1172[3:3];
    assign _1191 = _1172[2:2];
    assign _1190 = _1172[1:1];
    assign _1189 = _1172[0:0];
    always @* begin
        case (_1185)
        0:
            _1197 <= _1189;
        1:
            _1197 <= _1190;
        2:
            _1197 <= _1191;
        3:
            _1197 <= _1192;
        4:
            _1197 <= _1193;
        5:
            _1197 <= _1194;
        6:
            _1197 <= _1195;
        default:
            _1197 <= _1196;
        endcase
    end
    assign _1188 = pin_out[6:6];
    assign _1185 = _2958 - _969;
    assign _1186 = { _517,
                     _1185 };
    assign _1187 = _1186 < _770;
    assign _1198 = _1187 ? _1197 : _1188;
    assign _1180 = _1172[7:7];
    assign _1179 = _1172[6:6];
    assign _1178 = _1172[5:5];
    assign _1177 = _1172[4:4];
    assign _1176 = _1172[3:3];
    assign _1175 = _1172[2:2];
    assign _1174 = _1172[1:1];
    assign _1173 = _1172[0:0];
    always @* begin
        case (_1110)
        0:
            _1181 <= _1173;
        1:
            _1181 <= _1174;
        2:
            _1181 <= _1175;
        3:
            _1181 <= _1176;
        4:
            _1181 <= _1177;
        5:
            _1181 <= _1178;
        6:
            _1181 <= _1179;
        default:
            _1181 <= _1180;
        endcase
    end
    assign _1113 = pin_out[7:7];
    assign _1110 = _2800 - _969;
    assign _1111 = { _517,
                     _1110 };
    assign _1112 = _1111 < _770;
    assign _1182 = _1112 ? _1181 : _1113;
    assign _1295 = { _1182,
                     _1198,
                     _1214,
                     _1230,
                     _1246,
                     _1262,
                     _1278,
                     _1294 };
    assign _1103 = _990[7:7];
    assign _1102 = _990[6:6];
    assign _1101 = _990[5:5];
    assign _1100 = _990[4:4];
    assign _1099 = _990[3:3];
    assign _1098 = _990[2:2];
    assign _1097 = _990[1:1];
    assign _1096 = _990[0:0];
    always @* begin
        case (_1092)
        0:
            _1104 <= _1096;
        1:
            _1104 <= _1097;
        2:
            _1104 <= _1098;
        3:
            _1104 <= _1099;
        4:
            _1104 <= _1100;
        5:
            _1104 <= _1101;
        6:
            _1104 <= _1102;
        default:
            _1104 <= _1103;
        endcase
    end
    assign _1095 = pin_out[0:0];
    assign _1092 = _511 - _969;
    assign _1093 = { gnd,
                     _1092 };
    assign _1094 = _1093 < _972;
    assign _1105 = _1094 ? _1104 : _1095;
    assign _1088 = _990[7:7];
    assign _1087 = _990[6:6];
    assign _1086 = _990[5:5];
    assign _1085 = _990[4:4];
    assign _1084 = _990[3:3];
    assign _1083 = _990[2:2];
    assign _1082 = _990[1:1];
    assign _1081 = _990[0:0];
    always @* begin
        case (_1077)
        0:
            _1089 <= _1081;
        1:
            _1089 <= _1082;
        2:
            _1089 <= _1083;
        3:
            _1089 <= _1084;
        4:
            _1089 <= _1085;
        5:
            _1089 <= _1086;
        6:
            _1089 <= _1087;
        default:
            _1089 <= _1088;
        endcase
    end
    assign _1080 = pin_out[1:1];
    assign _1077 = _701 - _969;
    assign _1078 = { gnd,
                     _1077 };
    assign _1079 = _1078 < _972;
    assign _1090 = _1079 ? _1089 : _1080;
    assign _1073 = _990[7:7];
    assign _1072 = _990[6:6];
    assign _1071 = _990[5:5];
    assign _1070 = _990[4:4];
    assign _1069 = _990[3:3];
    assign _1068 = _990[2:2];
    assign _1067 = _990[1:1];
    assign _1066 = _990[0:0];
    always @* begin
        case (_1062)
        0:
            _1074 <= _1066;
        1:
            _1074 <= _1067;
        2:
            _1074 <= _1068;
        3:
            _1074 <= _1069;
        4:
            _1074 <= _1070;
        5:
            _1074 <= _1071;
        6:
            _1074 <= _1072;
        default:
            _1074 <= _1073;
        endcase
    end
    assign _1065 = pin_out[2:2];
    assign _1062 = _3278 - _969;
    assign _1063 = { gnd,
                     _1062 };
    assign _1064 = _1063 < _972;
    assign _1075 = _1064 ? _1074 : _1065;
    assign _1058 = _990[7:7];
    assign _1057 = _990[6:6];
    assign _1056 = _990[5:5];
    assign _1055 = _990[4:4];
    assign _1054 = _990[3:3];
    assign _1053 = _990[2:2];
    assign _1052 = _990[1:1];
    assign _1051 = _990[0:0];
    always @* begin
        case (_1047)
        0:
            _1059 <= _1051;
        1:
            _1059 <= _1052;
        2:
            _1059 <= _1053;
        3:
            _1059 <= _1054;
        4:
            _1059 <= _1055;
        5:
            _1059 <= _1056;
        6:
            _1059 <= _1057;
        default:
            _1059 <= _1058;
        endcase
    end
    assign _1050 = pin_out[3:3];
    assign _1047 = _3009 - _969;
    assign _1048 = { gnd,
                     _1047 };
    assign _1049 = _1048 < _972;
    assign _1060 = _1049 ? _1059 : _1050;
    assign _1043 = _990[7:7];
    assign _1042 = _990[6:6];
    assign _1041 = _990[5:5];
    assign _1040 = _990[4:4];
    assign _1039 = _990[3:3];
    assign _1038 = _990[2:2];
    assign _1037 = _990[1:1];
    assign _1036 = _990[0:0];
    always @* begin
        case (_1032)
        0:
            _1044 <= _1036;
        1:
            _1044 <= _1037;
        2:
            _1044 <= _1038;
        3:
            _1044 <= _1039;
        4:
            _1044 <= _1040;
        5:
            _1044 <= _1041;
        6:
            _1044 <= _1042;
        default:
            _1044 <= _1043;
        endcase
    end
    assign _1035 = pin_out[4:4];
    assign _1032 = _3415 - _969;
    assign _1033 = { gnd,
                     _1032 };
    assign _1034 = _1033 < _972;
    assign _1045 = _1034 ? _1044 : _1035;
    assign _1028 = _990[7:7];
    assign _1027 = _990[6:6];
    assign _1026 = _990[5:5];
    assign _1025 = _990[4:4];
    assign _1024 = _990[3:3];
    assign _1023 = _990[2:2];
    assign _1022 = _990[1:1];
    assign _1021 = _990[0:0];
    always @* begin
        case (_1017)
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
    assign _1020 = pin_out[5:5];
    assign _1017 = _2975 - _969;
    assign _1018 = { gnd,
                     _1017 };
    assign _1019 = _1018 < _972;
    assign _1030 = _1019 ? _1029 : _1020;
    assign _1013 = _990[7:7];
    assign _1012 = _990[6:6];
    assign _1011 = _990[5:5];
    assign _1010 = _990[4:4];
    assign _1009 = _990[3:3];
    assign _1008 = _990[2:2];
    assign _1007 = _990[1:1];
    assign _1006 = _990[0:0];
    always @* begin
        case (_1002)
        0:
            _1014 <= _1006;
        1:
            _1014 <= _1007;
        2:
            _1014 <= _1008;
        3:
            _1014 <= _1009;
        4:
            _1014 <= _1010;
        5:
            _1014 <= _1011;
        6:
            _1014 <= _1012;
        default:
            _1014 <= _1013;
        endcase
    end
    assign _1005 = pin_out[6:6];
    assign _1002 = _2958 - _969;
    assign _1003 = { gnd,
                     _1002 };
    assign _1004 = _1003 < _972;
    assign _1015 = _1004 ? _1014 : _1005;
    assign _998 = _990[7:7];
    assign _997 = _990[6:6];
    assign _996 = _990[5:5];
    assign _995 = _990[4:4];
    assign _994 = _990[3:3];
    assign _993 = _990[2:2];
    assign _992 = _990[1:1];
    assign _991 = _990[0:0];
    always @* begin
        case (_970)
        0:
            _999 <= _991;
        1:
            _999 <= _992;
        2:
            _999 <= _993;
        3:
            _999 <= _994;
        4:
            _999 <= _995;
        5:
            _999 <= _996;
        6:
            _999 <= _997;
        default:
            _999 <= _998;
        endcase
    end
    assign _974 = pin_out[7:7];
    assign _972 = cfg_t0_out_cfg[7:4];
    assign _798 = _582[7:0];
    assign _795 = 7'b1000010;
    assign _796 = _578 == _795;
    assign _794 = _572 & _576;
    assign _797 = _794 & _796;
    assign _799 = _797 ? _798 : cfg_t0_out_cfg;
    assign _19 = _799;
    always @(posedge _101) begin
        if (_99)
            cfg_t0_out_cfg <= _488;
        else
            cfg_t0_out_cfg <= _19;
    end
    assign _969 = cfg_t0_out_cfg[2:0];
    assign _970 = _2800 - _969;
    assign _971 = { gnd,
                    _970 };
    assign _973 = _971 < _972;
    assign _1000 = _973 ? _999 : _974;
    assign _1106 = { _1000,
                     _1015,
                     _1030,
                     _1045,
                     _1060,
                     _1075,
                     _1090,
                     _1105 };
    assign _963 = _850[7:7];
    assign _962 = _850[6:6];
    assign _961 = _850[5:5];
    assign _960 = _850[4:4];
    assign _959 = _850[3:3];
    assign _958 = _850[2:2];
    assign _957 = _850[1:1];
    assign _956 = _850[0:0];
    always @* begin
        case (_952)
        0:
            _964 <= _956;
        1:
            _964 <= _957;
        2:
            _964 <= _958;
        3:
            _964 <= _959;
        4:
            _964 <= _960;
        5:
            _964 <= _961;
        6:
            _964 <= _962;
        default:
            _964 <= _963;
        endcase
    end
    assign _955 = pin_out[0:0];
    assign _952 = _511 - _842;
    assign _953 = { gnd,
                    _952 };
    assign _954 = _953 < _845;
    assign _965 = _954 ? _964 : _955;
    assign _948 = _850[7:7];
    assign _947 = _850[6:6];
    assign _946 = _850[5:5];
    assign _945 = _850[4:4];
    assign _944 = _850[3:3];
    assign _943 = _850[2:2];
    assign _942 = _850[1:1];
    assign _941 = _850[0:0];
    always @* begin
        case (_937)
        0:
            _949 <= _941;
        1:
            _949 <= _942;
        2:
            _949 <= _943;
        3:
            _949 <= _944;
        4:
            _949 <= _945;
        5:
            _949 <= _946;
        6:
            _949 <= _947;
        default:
            _949 <= _948;
        endcase
    end
    assign _940 = pin_out[1:1];
    assign _937 = _701 - _842;
    assign _938 = { gnd,
                    _937 };
    assign _939 = _938 < _845;
    assign _950 = _939 ? _949 : _940;
    assign _933 = _850[7:7];
    assign _932 = _850[6:6];
    assign _931 = _850[5:5];
    assign _930 = _850[4:4];
    assign _929 = _850[3:3];
    assign _928 = _850[2:2];
    assign _927 = _850[1:1];
    assign _926 = _850[0:0];
    always @* begin
        case (_922)
        0:
            _934 <= _926;
        1:
            _934 <= _927;
        2:
            _934 <= _928;
        3:
            _934 <= _929;
        4:
            _934 <= _930;
        5:
            _934 <= _931;
        6:
            _934 <= _932;
        default:
            _934 <= _933;
        endcase
    end
    assign _925 = pin_out[2:2];
    assign _922 = _3278 - _842;
    assign _923 = { gnd,
                    _922 };
    assign _924 = _923 < _845;
    assign _935 = _924 ? _934 : _925;
    assign _918 = _850[7:7];
    assign _917 = _850[6:6];
    assign _916 = _850[5:5];
    assign _915 = _850[4:4];
    assign _914 = _850[3:3];
    assign _913 = _850[2:2];
    assign _912 = _850[1:1];
    assign _911 = _850[0:0];
    always @* begin
        case (_907)
        0:
            _919 <= _911;
        1:
            _919 <= _912;
        2:
            _919 <= _913;
        3:
            _919 <= _914;
        4:
            _919 <= _915;
        5:
            _919 <= _916;
        6:
            _919 <= _917;
        default:
            _919 <= _918;
        endcase
    end
    assign _910 = pin_out[3:3];
    assign _907 = _3009 - _842;
    assign _908 = { gnd,
                    _907 };
    assign _909 = _908 < _845;
    assign _920 = _909 ? _919 : _910;
    assign _903 = _850[7:7];
    assign _902 = _850[6:6];
    assign _901 = _850[5:5];
    assign _900 = _850[4:4];
    assign _899 = _850[3:3];
    assign _898 = _850[2:2];
    assign _897 = _850[1:1];
    assign _896 = _850[0:0];
    always @* begin
        case (_892)
        0:
            _904 <= _896;
        1:
            _904 <= _897;
        2:
            _904 <= _898;
        3:
            _904 <= _899;
        4:
            _904 <= _900;
        5:
            _904 <= _901;
        6:
            _904 <= _902;
        default:
            _904 <= _903;
        endcase
    end
    assign _895 = pin_out[4:4];
    assign _892 = _3415 - _842;
    assign _893 = { gnd,
                    _892 };
    assign _894 = _893 < _845;
    assign _905 = _894 ? _904 : _895;
    assign _888 = _850[7:7];
    assign _887 = _850[6:6];
    assign _886 = _850[5:5];
    assign _885 = _850[4:4];
    assign _884 = _850[3:3];
    assign _883 = _850[2:2];
    assign _882 = _850[1:1];
    assign _881 = _850[0:0];
    always @* begin
        case (_877)
        0:
            _889 <= _881;
        1:
            _889 <= _882;
        2:
            _889 <= _883;
        3:
            _889 <= _884;
        4:
            _889 <= _885;
        5:
            _889 <= _886;
        6:
            _889 <= _887;
        default:
            _889 <= _888;
        endcase
    end
    assign _880 = pin_out[5:5];
    assign _877 = _2975 - _842;
    assign _878 = { gnd,
                    _877 };
    assign _879 = _878 < _845;
    assign _890 = _879 ? _889 : _880;
    assign _873 = _850[7:7];
    assign _872 = _850[6:6];
    assign _871 = _850[5:5];
    assign _870 = _850[4:4];
    assign _869 = _850[3:3];
    assign _868 = _850[2:2];
    assign _867 = _850[1:1];
    assign _866 = _850[0:0];
    always @* begin
        case (_862)
        0:
            _874 <= _866;
        1:
            _874 <= _867;
        2:
            _874 <= _868;
        3:
            _874 <= _869;
        4:
            _874 <= _870;
        5:
            _874 <= _871;
        6:
            _874 <= _872;
        default:
            _874 <= _873;
        endcase
    end
    assign _865 = pin_out[6:6];
    assign _862 = _2958 - _842;
    assign _863 = { gnd,
                    _862 };
    assign _864 = _863 < _845;
    assign _875 = _864 ? _874 : _865;
    assign _858 = _850[7:7];
    assign _857 = _850[6:6];
    assign _856 = _850[5:5];
    assign _855 = _850[4:4];
    assign _854 = _850[3:3];
    assign _853 = _850[2:2];
    assign _852 = _850[1:1];
    assign _851 = _850[0:0];
    always @* begin
        case (_843)
        0:
            _859 <= _851;
        1:
            _859 <= _852;
        2:
            _859 <= _853;
        3:
            _859 <= _854;
        4:
            _859 <= _855;
        5:
            _859 <= _856;
        6:
            _859 <= _857;
        default:
            _859 <= _858;
        endcase
    end
    assign _847 = pin_out[7:7];
    assign _845 = cfg_t0_set_cfg[7:4];
    assign _804 = _582[7:0];
    assign _801 = 7'b1000011;
    assign _802 = _578 == _801;
    assign _800 = _572 & _576;
    assign _803 = _800 & _802;
    assign _805 = _803 ? _804 : cfg_t0_set_cfg;
    assign _20 = _805;
    always @(posedge _101) begin
        if (_99)
            cfg_t0_set_cfg <= _488;
        else
            cfg_t0_set_cfg <= _20;
    end
    assign _842 = cfg_t0_set_cfg[2:0];
    assign _843 = _2800 - _842;
    assign _844 = { gnd,
                    _843 };
    assign _846 = _844 < _845;
    assign _860 = _846 ? _859 : _847;
    assign _966 = { _860,
                    _875,
                    _890,
                    _905,
                    _920,
                    _935,
                    _950,
                    _965 };
    assign _839 = _837 == _517;
    assign _835 = _605 == _2958;
    assign _836 = _723 & _835;
    assign _840 = _836 & _839;
    assign _967 = _840 ? _966 : pin_out;
    assign _831 = _747 == _3278;
    assign _832 = _753 & _831;
    assign _828 = _605 == _2975;
    assign _829 = _723 & _828;
    assign _833 = _829 & _832;
    assign _1107 = _833 ? _1106 : _967;
    assign _823 = _88[8:7];
    assign _825 = _823 == _517;
    assign _821 = _605 == _3009;
    assign _822 = _723 & _821;
    assign _826 = _822 & _825;
    assign _1296 = _826 ? _1295 : _1107;
    assign _1297 = _1296[7:7];
    assign _817 = cfg_t0_sideset[5:4];
    assign _818 = { _517,
                    _817 };
    assign _465 = 6'b000000;
    assign _810 = _582[5:0];
    assign _807 = 7'b1001100;
    assign _808 = _578 == _807;
    assign _806 = _572 & _576;
    assign _809 = _806 & _808;
    assign _811 = _809 ? _810 : cfg_t0_sideset;
    assign _21 = _811;
    always @(posedge _101) begin
        if (_99)
            cfg_t0_sideset <= _465;
        else
            cfg_t0_sideset <= _21;
    end
    assign _813 = cfg_t0_sideset[2:0];
    assign _814 = _2800 - _813;
    assign _815 = { gnd,
                    _814 };
    assign _819 = _815 < _818;
    assign _1326 = _819 ? _1325 : _1297;
    assign _1446 = { _1326,
                     _1343,
                     _1360,
                     _1377,
                     _1394,
                     _1411,
                     _1428,
                     _1445 };
    assign _1447 = _604 ? pin_out : _1446;
    assign _1448 = _598 ? pin_out : _1447;
    assign _1449 = _592 ? pin_out : _1448;
    assign _22 = _1449;
    assign _2549 = _2348 == _517;
    assign _2546 = _1482 == _2958;
    assign _2547 = _1576 & _2546;
    assign _2550 = _2547 & _2549;
    assign _2674 = _2550 ? _2673 : _22;
    assign _2542 = _1591 == _3278;
    assign _2543 = _1597 & _2542;
    assign _2539 = _1482 == _2975;
    assign _2540 = _1576 & _2539;
    assign _2544 = _2540 & _2543;
    assign _2798 = _2544 ? _2797 : _2674;
    assign _2534 = _64[8:7];
    assign _2536 = _2534 == _517;
    assign _2532 = _1482 == _3009;
    assign _2533 = _1576 & _2532;
    assign _2537 = _2533 & _2536;
    assign _2928 = _2537 ? _2927 : _2798;
    assign _2929 = _2928[7:7];
    assign _2529 = { _517,
                     _2489 };
    assign _2525 = cfg_t1_sideset[2:0];
    assign _2526 = _2800 - _2525;
    assign _2527 = { gnd,
                     _2526 };
    assign _2530 = _2527 < _2529;
    assign _2957 = _2530 ? _2956 : _2929;
    assign _3077 = { _2957,
                     _2974,
                     _2991,
                     _3008,
                     _3025,
                     _3042,
                     _3059,
                     _3076 };
    assign _2502 = t1_delay_left - _3343;
    assign _2496 = _2494[3:2];
    assign _2497 = { _517,
                     _2496 };
    assign _2491 = _2489[0:0];
    assign _2494 = _2491 ? _3335 : _3334;
    assign _1454 = _582[5:0];
    assign _1451 = 7'b1011100;
    assign _1452 = _578 == _1451;
    assign _1450 = _572 & _576;
    assign _1453 = _1450 & _1452;
    assign _1455 = _1453 ? _1454 : cfg_t1_sideset;
    assign _23 = _1455;
    always @(posedge _101) begin
        if (_99)
            cfg_t1_sideset <= _465;
        else
            cfg_t1_sideset <= _23;
    end
    assign _2489 = cfg_t1_sideset[5:4];
    assign _2490 = _2489[1:1];
    assign _2498 = _2490 ? _2497 : _2494;
    assign _2488 = _64[12:9];
    assign _2499 = _2488 & _2498;
    assign _319 = t1_rx_level == _511;
    assign _320 = ~ _319;
    assign _1466 = t1_rx_level == _511;
    assign _1467 = ~ _1466;
    assign _1462 = 7'b1011001;
    assign _1463 = _372 == _1462;
    assign _1459 = _371[7:7];
    assign _1460 = ~ _1459;
    assign _1461 = _1458 & _1460;
    assign _1464 = _1461 & _1463;
    assign _1468 = _1464 & _1467;
    assign _24 = _1468;
    assign _321 = _24 & _320;
    assign _1495 = { _517,
                     _321 };
    assign _242 = ~ _241;
    assign _1489 = ~ _241;
    assign _1487 = ~ _1486;
    assign _1484 = _1482 == _3415;
    assign _1485 = _1481 & _1484;
    assign _1488 = _1485 & _1487;
    assign _1490 = _1488 & _1489;
    assign _25 = _1490;
    assign _243 = _25 & _242;
    assign _1492 = { _517,
                     _243 };
    assign _1493 = t1_rx_level + _1492;
    assign _1496 = _1493 - _1495;
    assign _26 = _1496;
    always @(posedge _101) begin
        if (_99)
            t1_rx_level <= _511;
        else
            t1_rx_level <= _26;
    end
    assign _241 = t1_rx_level == _3415;
    assign _1571 = ~ _1486;
    assign _1570 = _1482 == _3415;
    assign _1572 = _1570 & _1571;
    assign _1573 = _1572 & _241;
    assign _1563 = _1482 == _3415;
    assign _1564 = _1563 & _1486;
    assign _1567 = _1564 & _1566;
    assign _1560 = ~ _1559;
    assign _1557 = ~ _1527;
    assign _2479 = _578[5:0];
    assign _2478 = cfg_ctrl[4:3];
    assign _2480 = { _2478,
                     _2479 };
    assign _1501 = _582[7:0];
    assign _1498 = 7'b1010001;
    assign _1499 = _578 == _1498;
    assign _1497 = _572 & _576;
    assign _1500 = _1497 & _1499;
    assign _1502 = _1500 ? _1501 : cfg_t1_start;
    assign _27 = _1502;
    always @(posedge _101) begin
        if (_99)
            cfg_t1_start <= _307;
        else
            cfg_t1_start <= _27;
    end
    assign _2465 = _64[5:0];
    assign _2464 = t1_pc[7:6];
    assign _2466 = { _2464,
                     _2465 };
    assign _1507 = _582[7:0];
    assign _1504 = 7'b1010110;
    assign _1505 = _578 == _1504;
    assign _1503 = _572 & _576;
    assign _1506 = _1503 & _1505;
    assign _1508 = _1506 ? _1507 : cfg_t1_timeout_vector;
    assign _28 = _1508;
    always @(posedge _101) begin
        if (_99)
            cfg_t1_timeout_vector <= _307;
        else
            cfg_t1_timeout_vector <= _28;
    end
    assign _2463 = _1482 == _511;
    assign _2467 = _2463 ? _2466 : cfg_t1_timeout_vector;
    assign _2461 = t1_pc + _3311;
    assign _1544 = _1538 - _685;
    assign _1545 = _1542 ? _1544 : t1_wait_count;
    assign _1546 = _1513 ? t1_wait_count : _1545;
    assign _1547 = _1510 ? t1_wait_count : _1546;
    assign _1549 = _1509 ? _358 : _1547;
    assign _29 = _1549;
    assign _30 = _29;
    always @(posedge _101) begin
        if (_99)
            t1_wait_count <= _358;
        else
            t1_wait_count <= _30;
    end
    assign _1551 = 7'b1011011;
    assign _1552 = _578 == _1551;
    assign _1550 = _572 & _576;
    assign _1553 = _1550 & _1552;
    assign _1554 = _1553 ? _582 : cfg_t1_timeout;
    assign _31 = _1554;
    always @(posedge _101) begin
        if (_99)
            cfg_t1_timeout <= _358;
        else
            cfg_t1_timeout <= _31;
    end
    assign _1541 = ~ _1540;
    assign _1528 = ~ _1527;
    assign _1515 = _1482 == _701;
    assign _1529 = _1515 & _1528;
    assign _1531 = _1529 & _1530;
    assign _1542 = _1531 & _1541;
    assign _1578 = _1542 ? _724 : t1_waiting;
    assign _1580 = _1576 ? _566 : _1578;
    assign _1581 = _1513 ? t1_waiting : _1580;
    assign _1582 = _1510 ? t1_waiting : _1581;
    assign _1584 = _1509 ? _566 : _1582;
    assign _32 = _1584;
    assign _33 = _32;
    always @(posedge _101) begin
        if (_99)
            t1_waiting <= _566;
        else
            t1_waiting <= _33;
    end
    assign _1538 = t1_waiting ? t1_wait_count : cfg_t1_timeout;
    assign _1540 = _1538 == _358;
    assign _1530 = _64[4:4];
    assign _1559 = _1530 & _1540;
    assign _1526 = _64[8:8];
    assign _1524 = _658[7:7];
    assign _1523 = _658[6:6];
    assign _1522 = _658[5:5];
    assign _1521 = _658[4:4];
    assign _1520 = _658[3:3];
    assign _1519 = _658[2:2];
    assign _1518 = _658[1:1];
    assign _1517 = _658[0:0];
    assign _1516 = _64[7:5];
    always @* begin
        case (_1516)
        0:
            _1525 <= _1517;
        1:
            _1525 <= _1518;
        2:
            _1525 <= _1519;
        3:
            _1525 <= _1520;
        4:
            _1525 <= _1521;
        5:
            _1525 <= _1522;
        6:
            _1525 <= _1523;
        default:
            _1525 <= _1524;
        endcase
    end
    assign _1527 = _1525 == _1526;
    assign _2456 = ~ _1527;
    assign _2455 = _1482 == _701;
    assign _2457 = _2455 & _2456;
    assign _2458 = _2457 & _1559;
    assign _1618 = _1616[4:0];
    assign _1615 = { gnd,
                     _1614 };
    assign _1608 = { gnd,
                     t1_isr_count };
    assign _1616 = _1608 + _1615;
    assign _1617 = _763 < _1616;
    assign _1620 = _1617 ? _254 : _1618;
    assign _1605 = _1486 ? t1_isr_count : _739;
    assign _1599 = _1591 == _3009;
    assign _1601 = _1599 ? _739 : t1_isr_count;
    assign _1602 = _1597 ? _1601 : t1_isr_count;
    assign _1590 = _1482 == _2975;
    assign _1603 = _1590 ? _1602 : t1_isr_count;
    assign _1588 = _1482 == _3415;
    assign _1606 = _1588 ? _1605 : _1603;
    assign _1586 = _1482 == _3278;
    assign _1621 = _1586 ? _1620 : _1606;
    assign _1622 = _1576 ? _1621 : t1_isr_count;
    assign _1623 = _1513 ? t1_isr_count : _1622;
    assign _1624 = _1510 ? t1_isr_count : _1623;
    assign _1626 = _1509 ? _739 : _1624;
    assign _34 = _1626;
    assign _35 = _34;
    always @(posedge _101) begin
        if (_99)
            t1_isr_count <= _739;
        else
            t1_isr_count <= _35;
    end
    assign _2451 = t1_isr_count < cfg_t1_threshold;
    assign _1631 = _582[4:0];
    assign _1628 = 7'b1010101;
    assign _1629 = _578 == _1628;
    assign _1627 = _572 & _576;
    assign _1630 = _1627 & _1629;
    assign _1632 = _1630 ? _1631 : cfg_t1_threshold;
    assign _36 = _1632;
    always @(posedge _101) begin
        if (_99)
            cfg_t1_threshold <= _401;
        else
            cfg_t1_threshold <= _36;
    end
    assign _1654 = _1652[4:0];
    assign _1651 = { gnd,
                     _1614 };
    assign _1650 = { gnd,
                     t1_osr_count };
    assign _1652 = _1650 + _1651;
    assign _1653 = _763 < _1652;
    assign _1656 = _1653 ? _254 : _1654;
    assign _1647 = _1486 ? _739 : t1_osr_count;
    assign _1641 = _1591 == _3415;
    assign _1643 = _1641 ? _739 : t1_osr_count;
    assign _1644 = _1597 ? _1643 : t1_osr_count;
    assign _1639 = _1482 == _2975;
    assign _1645 = _1639 ? _1644 : t1_osr_count;
    assign _1638 = _1482 == _3415;
    assign _1648 = _1638 ? _1647 : _1645;
    assign _1637 = _1482 == _3009;
    assign _1657 = _1637 ? _1656 : _1648;
    assign _1658 = _1576 ? _1657 : t1_osr_count;
    assign _1659 = _1513 ? t1_osr_count : _1658;
    assign _1660 = _1510 ? t1_osr_count : _1659;
    assign _1661 = _1509 ? cfg_t1_threshold : _1660;
    assign _37 = _1661;
    assign _38 = _37;
    always @(posedge _101) begin
        if (_99)
            t1_osr_count <= _739;
        else
            t1_osr_count <= _38;
    end
    assign _2450 = t1_osr_count < cfg_t1_threshold;
    assign _2448 = t1_x == t1_y;
    assign _2449 = ~ _2448;
    assign _2445 = t1_y == _358;
    assign _2446 = ~ _2445;
    assign _2447 = ~ _2446;
    assign _2430 = t1_x - _685;
    assign _2428 = _2398 == _3278;
    assign _2431 = _2428 ? _2430 : t1_x;
    assign _2424 = _2361 == _186;
    assign _2425 = _2424 ? _2395 : t1_x;
    assign _1888 = _1811 & _1887;
    assign _1857 = _1856[15:0];
    assign _1859 = { _1857,
                     _358 };
    assign _1853 = _1852[23:0];
    assign _1855 = { _1853,
                     _307 };
    assign _1849 = _1848[27:0];
    assign _1851 = { _1849,
                     _303 };
    assign _1845 = _1844[29:0];
    assign _1847 = { _1845,
                     _517 };
    assign _1841 = _1840[30:0];
    assign _1843 = { _1841,
                     _566 };
    assign _1840 = { _358,
                     t1_isr };
    assign _1838 = _1614[0:0];
    assign _1844 = _1838 ? _1843 : _1840;
    assign _1837 = _1614[1:1];
    assign _1848 = _1837 ? _1847 : _1844;
    assign _1836 = _1614[2:2];
    assign _1852 = _1836 ? _1851 : _1848;
    assign _1835 = _1614[3:3];
    assign _1856 = _1835 ? _1855 : _1852;
    assign _1834 = _1614[4:4];
    assign _1860 = _1834 ? _1859 : _1856;
    assign _1861 = _1860[15:0];
    assign _1889 = _1861 | _1888;
    assign _1830 = _1828[31:16];
    assign _1831 = { _358,
                     _1830 };
    assign _1826 = _1824[31:8];
    assign _1827 = { _307,
                     _1826 };
    assign _1822 = _1820[31:4];
    assign _1823 = { _303,
                     _1822 };
    assign _1818 = _1816[31:2];
    assign _1819 = { _517,
                     _1818 };
    assign _1814 = _1812[31:1];
    assign _1815 = { _566,
                     _1814 };
    assign _1806 = _739 < _1614;
    assign _1803 = _658[7:7];
    assign _1802 = _658[6:6];
    assign _1801 = _658[5:5];
    assign _1800 = _658[4:4];
    assign _1799 = _658[3:3];
    assign _1798 = _658[2:2];
    assign _1797 = _658[1:1];
    assign _1796 = _658[0:0];
    always @* begin
        case (cfg_t1_in_base)
        0:
            _1804 <= _1796;
        1:
            _1804 <= _1797;
        2:
            _1804 <= _1798;
        3:
            _1804 <= _1799;
        4:
            _1804 <= _1800;
        5:
            _1804 <= _1801;
        6:
            _1804 <= _1802;
        default:
            _1804 <= _1803;
        endcase
    end
    assign _1807 = _1804 & _1806;
    assign _1793 = 5'b00001;
    assign _1794 = _1793 < _1614;
    assign _1791 = _658[7:7];
    assign _1790 = _658[6:6];
    assign _1789 = _658[5:5];
    assign _1788 = _658[4:4];
    assign _1787 = _658[3:3];
    assign _1786 = _658[2:2];
    assign _1785 = _658[1:1];
    assign _1784 = _658[0:0];
    assign _1783 = cfg_t1_in_base + _701;
    always @* begin
        case (_1783)
        0:
            _1792 <= _1784;
        1:
            _1792 <= _1785;
        2:
            _1792 <= _1786;
        3:
            _1792 <= _1787;
        4:
            _1792 <= _1788;
        5:
            _1792 <= _1789;
        6:
            _1792 <= _1790;
        default:
            _1792 <= _1791;
        endcase
    end
    assign _1795 = _1792 & _1794;
    assign _1779 = 5'b00010;
    assign _1780 = _1779 < _1614;
    assign _1777 = _658[7:7];
    assign _1776 = _658[6:6];
    assign _1775 = _658[5:5];
    assign _1774 = _658[4:4];
    assign _1773 = _658[3:3];
    assign _1772 = _658[2:2];
    assign _1771 = _658[1:1];
    assign _1770 = _658[0:0];
    assign _1769 = cfg_t1_in_base + _3278;
    always @* begin
        case (_1769)
        0:
            _1778 <= _1770;
        1:
            _1778 <= _1771;
        2:
            _1778 <= _1772;
        3:
            _1778 <= _1773;
        4:
            _1778 <= _1774;
        5:
            _1778 <= _1775;
        6:
            _1778 <= _1776;
        default:
            _1778 <= _1777;
        endcase
    end
    assign _1781 = _1778 & _1780;
    assign _1765 = 5'b00011;
    assign _1766 = _1765 < _1614;
    assign _1763 = _658[7:7];
    assign _1762 = _658[6:6];
    assign _1761 = _658[5:5];
    assign _1760 = _658[4:4];
    assign _1759 = _658[3:3];
    assign _1758 = _658[2:2];
    assign _1757 = _658[1:1];
    assign _1756 = _658[0:0];
    assign _1755 = cfg_t1_in_base + _3009;
    always @* begin
        case (_1755)
        0:
            _1764 <= _1756;
        1:
            _1764 <= _1757;
        2:
            _1764 <= _1758;
        3:
            _1764 <= _1759;
        4:
            _1764 <= _1760;
        5:
            _1764 <= _1761;
        6:
            _1764 <= _1762;
        default:
            _1764 <= _1763;
        endcase
    end
    assign _1767 = _1764 & _1766;
    assign _1751 = 5'b00100;
    assign _1752 = _1751 < _1614;
    assign _1749 = _658[7:7];
    assign _1748 = _658[6:6];
    assign _1747 = _658[5:5];
    assign _1746 = _658[4:4];
    assign _1745 = _658[3:3];
    assign _1744 = _658[2:2];
    assign _1743 = _658[1:1];
    assign _1742 = _658[0:0];
    assign _1741 = cfg_t1_in_base + _3415;
    always @* begin
        case (_1741)
        0:
            _1750 <= _1742;
        1:
            _1750 <= _1743;
        2:
            _1750 <= _1744;
        3:
            _1750 <= _1745;
        4:
            _1750 <= _1746;
        5:
            _1750 <= _1747;
        6:
            _1750 <= _1748;
        default:
            _1750 <= _1749;
        endcase
    end
    assign _1753 = _1750 & _1752;
    assign _1737 = 5'b00101;
    assign _1738 = _1737 < _1614;
    assign _1735 = _658[7:7];
    assign _1734 = _658[6:6];
    assign _1733 = _658[5:5];
    assign _1732 = _658[4:4];
    assign _1731 = _658[3:3];
    assign _1730 = _658[2:2];
    assign _1729 = _658[1:1];
    assign _1728 = _658[0:0];
    assign _1727 = cfg_t1_in_base + _2975;
    always @* begin
        case (_1727)
        0:
            _1736 <= _1728;
        1:
            _1736 <= _1729;
        2:
            _1736 <= _1730;
        3:
            _1736 <= _1731;
        4:
            _1736 <= _1732;
        5:
            _1736 <= _1733;
        6:
            _1736 <= _1734;
        default:
            _1736 <= _1735;
        endcase
    end
    assign _1739 = _1736 & _1738;
    assign _1723 = 5'b00110;
    assign _1724 = _1723 < _1614;
    assign _1721 = _658[7:7];
    assign _1720 = _658[6:6];
    assign _1719 = _658[5:5];
    assign _1718 = _658[4:4];
    assign _1717 = _658[3:3];
    assign _1716 = _658[2:2];
    assign _1715 = _658[1:1];
    assign _1714 = _658[0:0];
    assign _1713 = cfg_t1_in_base + _2958;
    always @* begin
        case (_1713)
        0:
            _1722 <= _1714;
        1:
            _1722 <= _1715;
        2:
            _1722 <= _1716;
        3:
            _1722 <= _1717;
        4:
            _1722 <= _1718;
        5:
            _1722 <= _1719;
        6:
            _1722 <= _1720;
        default:
            _1722 <= _1721;
        endcase
    end
    assign _1725 = _1722 & _1724;
    assign _1709 = 5'b00111;
    assign _1710 = _1709 < _1614;
    assign _1707 = _658[7:7];
    assign _1706 = _658[6:6];
    assign _1705 = _658[5:5];
    assign _1704 = _658[4:4];
    assign _1703 = _658[3:3];
    assign _1702 = _658[2:2];
    assign _1701 = _658[1:1];
    assign _1700 = _658[0:0];
    assign _1666 = _582[2:0];
    assign _1663 = 7'b1010100;
    assign _1664 = _578 == _1663;
    assign _1662 = _572 & _576;
    assign _1665 = _1662 & _1664;
    assign _1667 = _1665 ? _1666 : cfg_t1_in_base;
    assign _39 = _1667;
    always @(posedge _101) begin
        if (_99)
            cfg_t1_in_base <= _511;
        else
            cfg_t1_in_base <= _39;
    end
    assign _1699 = cfg_t1_in_base + _2800;
    always @* begin
        case (_1699)
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
    assign _1711 = _1708 & _1710;
    assign _1808 = { _1711,
                     _1725,
                     _1739,
                     _1753,
                     _1767,
                     _1781,
                     _1795,
                     _1807 };
    assign _1809 = { _307,
                     _1808 };
    assign _1696 = _64[8:7];
    always @* begin
        case (_1696)
        0:
            _1811 <= _1809;
        1:
            _1811 <= t1_x;
        2:
            _1811 <= t1_y;
        default:
            _1811 <= _358;
        endcase
    end
    assign _1812 = { _1811,
                     t1_isr };
    assign _1695 = _1614[0:0];
    assign _1816 = _1695 ? _1815 : _1812;
    assign _1694 = _1614[1:1];
    assign _1820 = _1694 ? _1819 : _1816;
    assign _1693 = _1614[2:2];
    assign _1824 = _1693 ? _1823 : _1820;
    assign _1692 = _1614[3:3];
    assign _1828 = _1692 ? _1827 : _1824;
    assign _1691 = _1614[4:4];
    assign _1832 = _1691 ? _1831 : _1828;
    assign _1833 = _1832[15:0];
    assign _253 = cfg_t1_shift[1:1];
    assign _1890 = _253 ? _1889 : _1833;
    assign _1689 = _1486 ? t1_isr : _358;
    assign _1671 = _1591 == _3009;
    assign _1685 = _1671 ? _1684 : t1_isr;
    assign _1686 = _1597 ? _1685 : t1_isr;
    assign _1670 = _1482 == _2975;
    assign _1687 = _1670 ? _1686 : t1_isr;
    assign _1669 = _1482 == _3415;
    assign _1690 = _1669 ? _1689 : _1687;
    assign _1668 = _1482 == _3278;
    assign _1891 = _1668 ? _1890 : _1690;
    assign _1892 = _1576 ? _1891 : t1_isr;
    assign _1893 = _1513 ? t1_isr : _1892;
    assign _1894 = _1510 ? t1_isr : _1893;
    assign _1896 = _1509 ? _358 : _1894;
    assign _40 = _1896;
    assign _41 = _40;
    always @(posedge _101) begin
        if (_99)
            t1_isr <= _358;
        else
            t1_isr <= _41;
    end
    assign _1679 = { _307,
                     _658 };
    assign _2402 = t1_y - _685;
    assign _2400 = _2398 == _3415;
    assign _2403 = _2400 ? _2402 : t1_y;
    assign _2391 = _2389[31:16];
    assign _2392 = { _358,
                     _2391 };
    assign _2387 = _2385[31:8];
    assign _2388 = { _307,
                     _2387 };
    assign _2383 = _2381[31:4];
    assign _2384 = { _303,
                     _2383 };
    assign _2379 = _2377[31:2];
    assign _2380 = { _517,
                     _2379 };
    assign _2375 = _2373[31:1];
    assign _2376 = { _566,
                     _2375 };
    assign _2373 = { _358,
                     t1_osr };
    assign _2371 = _2366[0:0];
    assign _2377 = _2371 ? _2376 : _2373;
    assign _2370 = _2366[1:1];
    assign _2381 = _2370 ? _2380 : _2377;
    assign _2369 = _2366[2:2];
    assign _2385 = _2369 ? _2384 : _2381;
    assign _2368 = _2366[3:3];
    assign _2389 = _2368 ? _2388 : _2385;
    assign _2366 = _254 - _1614;
    assign _2367 = _2366[4:4];
    assign _2393 = _2367 ? _2392 : _2389;
    assign _2394 = _2393[15:0];
    assign _1882 = _1881[15:0];
    assign _1884 = { _1882,
                     _358 };
    assign _1878 = _1877[23:0];
    assign _1880 = { _1878,
                     _307 };
    assign _1874 = _1873[27:0];
    assign _1876 = { _1874,
                     _303 };
    assign _1870 = _1869[29:0];
    assign _1872 = { _1870,
                     _517 };
    assign _1866 = _1614[0:0];
    assign _1869 = _1866 ? _296 : _295;
    assign _1865 = _1614[1:1];
    assign _1873 = _1865 ? _1872 : _1869;
    assign _1864 = _1614[2:2];
    assign _1877 = _1864 ? _1876 : _1873;
    assign _1863 = _1614[3:3];
    assign _1881 = _1863 ? _1880 : _1877;
    assign _1862 = _1614[4:4];
    assign _1885 = _1862 ? _1884 : _1881;
    assign _1886 = _1885[15:0];
    assign _1887 = ~ _1886;
    assign _2324 = _2323[15:0];
    assign _2326 = { _2324,
                     _358 };
    assign _2320 = _2319[23:0];
    assign _2322 = { _2320,
                     _307 };
    assign _2316 = _2315[27:0];
    assign _2318 = { _2316,
                     _303 };
    assign _2312 = _2311[29:0];
    assign _2314 = { _2312,
                     _517 };
    assign _2308 = _2307[30:0];
    assign _2310 = { _2308,
                     _566 };
    assign _2307 = { _358,
                     t1_osr };
    assign _2305 = _1614[0:0];
    assign _2311 = _2305 ? _2310 : _2307;
    assign _2304 = _1614[1:1];
    assign _2315 = _2304 ? _2314 : _2311;
    assign _2303 = _1614[2:2];
    assign _2319 = _2303 ? _2318 : _2315;
    assign _2302 = _1614[3:3];
    assign _2323 = _2302 ? _2322 : _2319;
    assign _2301 = _1614[4:4];
    assign _2327 = _2301 ? _2326 : _2323;
    assign _2328 = _2327[15:0];
    assign _2297 = _2295[31:16];
    assign _2298 = { _358,
                     _2297 };
    assign _2293 = _2291[31:8];
    assign _2294 = { _307,
                     _2293 };
    assign _2289 = _2287[31:4];
    assign _2290 = { _303,
                     _2289 };
    assign _2285 = _2283[31:2];
    assign _2286 = { _517,
                     _2285 };
    assign _2281 = _2279[31:1];
    assign _2282 = { _566,
                     _2281 };
    assign _2279 = { _358,
                     t1_osr };
    assign _2277 = _1614[0:0];
    assign _2283 = _2277 ? _2282 : _2279;
    assign _2276 = _1614[1:1];
    assign _2287 = _2276 ? _2286 : _2283;
    assign _2275 = _1614[2:2];
    assign _2291 = _2275 ? _2290 : _2287;
    assign _2274 = _1614[3:3];
    assign _2295 = _2274 ? _2294 : _2291;
    assign _1612 = { gnd,
                     _1609 };
    assign _1609 = _64[3:0];
    assign _1611 = _1609 == _303;
    assign _1614 = _1611 ? _254 : _1612;
    assign _2273 = _1614[4:4];
    assign _2299 = _2273 ? _2298 : _2295;
    assign _2300 = _2299[15:0];
    assign _2329 = _2272 ? _2328 : _2300;
    assign _2266 = t1_tx_wr == _535;
    assign _2267 = _1908 & _2266;
    always @(posedge _101) begin
        if (_99)
            t1_tx_mem_3 <= _358;
        else
            if (_2267)
                t1_tx_mem_3 <= _2244;
    end
    assign _2260 = t1_tx_wr == _189;
    assign _2261 = _1908 & _2260;
    always @(posedge _101) begin
        if (_99)
            t1_tx_mem_2 <= _358;
        else
            if (_2261)
                t1_tx_mem_2 <= _2244;
    end
    assign _2254 = t1_tx_wr == _186;
    assign _2255 = _1908 & _2254;
    always @(posedge _101) begin
        if (_99)
            t1_tx_mem_1 <= _358;
        else
            if (_2255)
                t1_tx_mem_1 <= _2244;
    end
    assign _1913 = t1_tx_wr + _186;
    assign _1914 = _1908 ? _1913 : t1_tx_wr;
    assign _42 = _1914;
    always @(posedge _101) begin
        if (_99)
            t1_tx_wr <= _517;
        else
            t1_tx_wr <= _42;
    end
    assign _2248 = t1_tx_wr == _517;
    assign _2249 = _1908 & _2248;
    assign _447 = t0_rx_wr == _535;
    assign _448 = _424 & _447;
    always @(posedge _101) begin
        if (_99)
            t0_rx_mem_3 <= _358;
        else
            if (_448)
                t0_rx_mem_3 <= _49;
    end
    assign _441 = t0_rx_wr == _189;
    assign _442 = _424 & _441;
    always @(posedge _101) begin
        if (_99)
            t0_rx_mem_2 <= _358;
        else
            if (_442)
                t0_rx_mem_2 <= _49;
    end
    assign _435 = t0_rx_wr == _186;
    assign _436 = _424 & _435;
    always @(posedge _101) begin
        if (_99)
            t0_rx_mem_1 <= _358;
        else
            if (_436)
                t0_rx_mem_1 <= _49;
    end
    assign _1916 = t0_rx_wr + _186;
    assign _1917 = _424 ? _1916 : t0_rx_wr;
    assign _43 = _1917;
    always @(posedge _101) begin
        if (_99)
            t0_rx_wr <= _517;
        else
            t0_rx_wr <= _43;
    end
    assign _429 = t0_rx_wr == _517;
    assign _430 = _424 & _429;
    assign _2195 = _2194[15:0];
    assign _2197 = { _2195,
                     _358 };
    assign _2191 = _2190[23:0];
    assign _2193 = { _2191,
                     _307 };
    assign _2187 = _2186[27:0];
    assign _2189 = { _2187,
                     _303 };
    assign _2183 = _2182[29:0];
    assign _2185 = { _2183,
                     _517 };
    assign _2179 = t0_isr_count[0:0];
    assign _2182 = _2179 ? _296 : _295;
    assign _2178 = t0_isr_count[1:1];
    assign _2186 = _2178 ? _2185 : _2182;
    assign _2177 = t0_isr_count[2:2];
    assign _2190 = _2177 ? _2189 : _2186;
    assign _2176 = t0_isr_count[3:3];
    assign _2194 = _2176 ? _2193 : _2190;
    assign _2175 = t0_isr_count[4:4];
    assign _2198 = _2175 ? _2197 : _2194;
    assign _2199 = _2198[15:0];
    assign _2200 = ~ _2199;
    assign _2201 = t0_isr & _2200;
    assign _2171 = _2169[31:16];
    assign _2172 = { _358,
                     _2171 };
    assign _2167 = _2165[31:8];
    assign _2168 = { _307,
                     _2167 };
    assign _2163 = _2161[31:4];
    assign _2164 = { _303,
                     _2163 };
    assign _2159 = _2157[31:2];
    assign _2160 = { _517,
                     _2159 };
    assign _2155 = _2153[31:1];
    assign _2156 = { _566,
                     _2155 };
    assign _2108 = _2057 & _1140;
    assign _2103 = _2102[15:0];
    assign _2105 = { _2103,
                     _358 };
    assign _2099 = _2098[23:0];
    assign _2101 = { _2099,
                     _307 };
    assign _2095 = _2094[27:0];
    assign _2097 = { _2095,
                     _303 };
    assign _2091 = _2090[29:0];
    assign _2093 = { _2091,
                     _517 };
    assign _2087 = _2086[30:0];
    assign _2089 = { _2087,
                     _566 };
    assign _2086 = { _358,
                     t0_isr };
    assign _2084 = _770[0:0];
    assign _2090 = _2084 ? _2089 : _2086;
    assign _2083 = _770[1:1];
    assign _2094 = _2083 ? _2093 : _2090;
    assign _2082 = _770[2:2];
    assign _2098 = _2082 ? _2097 : _2094;
    assign _2081 = _770[3:3];
    assign _2102 = _2081 ? _2101 : _2098;
    assign _2080 = _770[4:4];
    assign _2106 = _2080 ? _2105 : _2102;
    assign _2107 = _2106[15:0];
    assign _2109 = _2107 | _2108;
    assign _2076 = _2074[31:16];
    assign _2077 = { _358,
                     _2076 };
    assign _2072 = _2070[31:8];
    assign _2073 = { _307,
                     _2072 };
    assign _2068 = _2066[31:4];
    assign _2069 = { _303,
                     _2068 };
    assign _2064 = _2062[31:2];
    assign _2065 = { _517,
                     _2064 };
    assign _2060 = _2058[31:1];
    assign _2061 = { _566,
                     _2060 };
    assign _2052 = _739 < _770;
    assign _2049 = _658[7:7];
    assign _2048 = _658[6:6];
    assign _2047 = _658[5:5];
    assign _2046 = _658[4:4];
    assign _2045 = _658[3:3];
    assign _2044 = _658[2:2];
    assign _2043 = _658[1:1];
    assign _2042 = _658[0:0];
    always @* begin
        case (cfg_t0_in_base)
        0:
            _2050 <= _2042;
        1:
            _2050 <= _2043;
        2:
            _2050 <= _2044;
        3:
            _2050 <= _2045;
        4:
            _2050 <= _2046;
        5:
            _2050 <= _2047;
        6:
            _2050 <= _2048;
        default:
            _2050 <= _2049;
        endcase
    end
    assign _2053 = _2050 & _2052;
    assign _2040 = _1793 < _770;
    assign _2037 = _658[7:7];
    assign _2036 = _658[6:6];
    assign _2035 = _658[5:5];
    assign _2034 = _658[4:4];
    assign _2033 = _658[3:3];
    assign _2032 = _658[2:2];
    assign _2031 = _658[1:1];
    assign _2030 = _658[0:0];
    assign _2029 = cfg_t0_in_base + _701;
    always @* begin
        case (_2029)
        0:
            _2038 <= _2030;
        1:
            _2038 <= _2031;
        2:
            _2038 <= _2032;
        3:
            _2038 <= _2033;
        4:
            _2038 <= _2034;
        5:
            _2038 <= _2035;
        6:
            _2038 <= _2036;
        default:
            _2038 <= _2037;
        endcase
    end
    assign _2041 = _2038 & _2040;
    assign _2026 = _1779 < _770;
    assign _2023 = _658[7:7];
    assign _2022 = _658[6:6];
    assign _2021 = _658[5:5];
    assign _2020 = _658[4:4];
    assign _2019 = _658[3:3];
    assign _2018 = _658[2:2];
    assign _2017 = _658[1:1];
    assign _2016 = _658[0:0];
    assign _2015 = cfg_t0_in_base + _3278;
    always @* begin
        case (_2015)
        0:
            _2024 <= _2016;
        1:
            _2024 <= _2017;
        2:
            _2024 <= _2018;
        3:
            _2024 <= _2019;
        4:
            _2024 <= _2020;
        5:
            _2024 <= _2021;
        6:
            _2024 <= _2022;
        default:
            _2024 <= _2023;
        endcase
    end
    assign _2027 = _2024 & _2026;
    assign _2012 = _1765 < _770;
    assign _2009 = _658[7:7];
    assign _2008 = _658[6:6];
    assign _2007 = _658[5:5];
    assign _2006 = _658[4:4];
    assign _2005 = _658[3:3];
    assign _2004 = _658[2:2];
    assign _2003 = _658[1:1];
    assign _2002 = _658[0:0];
    assign _2001 = cfg_t0_in_base + _3009;
    always @* begin
        case (_2001)
        0:
            _2010 <= _2002;
        1:
            _2010 <= _2003;
        2:
            _2010 <= _2004;
        3:
            _2010 <= _2005;
        4:
            _2010 <= _2006;
        5:
            _2010 <= _2007;
        6:
            _2010 <= _2008;
        default:
            _2010 <= _2009;
        endcase
    end
    assign _2013 = _2010 & _2012;
    assign _1998 = _1751 < _770;
    assign _1995 = _658[7:7];
    assign _1994 = _658[6:6];
    assign _1993 = _658[5:5];
    assign _1992 = _658[4:4];
    assign _1991 = _658[3:3];
    assign _1990 = _658[2:2];
    assign _1989 = _658[1:1];
    assign _1988 = _658[0:0];
    assign _1987 = cfg_t0_in_base + _3415;
    always @* begin
        case (_1987)
        0:
            _1996 <= _1988;
        1:
            _1996 <= _1989;
        2:
            _1996 <= _1990;
        3:
            _1996 <= _1991;
        4:
            _1996 <= _1992;
        5:
            _1996 <= _1993;
        6:
            _1996 <= _1994;
        default:
            _1996 <= _1995;
        endcase
    end
    assign _1999 = _1996 & _1998;
    assign _1984 = _1737 < _770;
    assign _1981 = _658[7:7];
    assign _1980 = _658[6:6];
    assign _1979 = _658[5:5];
    assign _1978 = _658[4:4];
    assign _1977 = _658[3:3];
    assign _1976 = _658[2:2];
    assign _1975 = _658[1:1];
    assign _1974 = _658[0:0];
    assign _1973 = cfg_t0_in_base + _2975;
    always @* begin
        case (_1973)
        0:
            _1982 <= _1974;
        1:
            _1982 <= _1975;
        2:
            _1982 <= _1976;
        3:
            _1982 <= _1977;
        4:
            _1982 <= _1978;
        5:
            _1982 <= _1979;
        6:
            _1982 <= _1980;
        default:
            _1982 <= _1981;
        endcase
    end
    assign _1985 = _1982 & _1984;
    assign _1970 = _1723 < _770;
    assign _1967 = _658[7:7];
    assign _1966 = _658[6:6];
    assign _1965 = _658[5:5];
    assign _1964 = _658[4:4];
    assign _1963 = _658[3:3];
    assign _1962 = _658[2:2];
    assign _1961 = _658[1:1];
    assign _1960 = _658[0:0];
    assign _1959 = cfg_t0_in_base + _2958;
    always @* begin
        case (_1959)
        0:
            _1968 <= _1960;
        1:
            _1968 <= _1961;
        2:
            _1968 <= _1962;
        3:
            _1968 <= _1963;
        4:
            _1968 <= _1964;
        5:
            _1968 <= _1965;
        6:
            _1968 <= _1966;
        default:
            _1968 <= _1967;
        endcase
    end
    assign _1971 = _1968 & _1970;
    assign _1956 = _1709 < _770;
    assign _1953 = _658[7:7];
    assign _1952 = _658[6:6];
    assign _1951 = _658[5:5];
    assign _1950 = _658[4:4];
    assign _1949 = _658[3:3];
    assign _1948 = _658[2:2];
    assign _1947 = _658[1:1];
    assign _1946 = _658[0:0];
    assign _1922 = _582[2:0];
    assign _1919 = 7'b1000100;
    assign _1920 = _578 == _1919;
    assign _1918 = _572 & _576;
    assign _1921 = _1918 & _1920;
    assign _1923 = _1921 ? _1922 : cfg_t0_in_base;
    assign _44 = _1923;
    always @(posedge _101) begin
        if (_99)
            cfg_t0_in_base <= _511;
        else
            cfg_t0_in_base <= _44;
    end
    assign _1945 = cfg_t0_in_base + _2800;
    always @* begin
        case (_1945)
        0:
            _1954 <= _1946;
        1:
            _1954 <= _1947;
        2:
            _1954 <= _1948;
        3:
            _1954 <= _1949;
        4:
            _1954 <= _1950;
        5:
            _1954 <= _1951;
        6:
            _1954 <= _1952;
        default:
            _1954 <= _1953;
        endcase
    end
    assign _1957 = _1954 & _1956;
    assign _2054 = { _1957,
                     _1971,
                     _1985,
                     _1999,
                     _2013,
                     _2027,
                     _2041,
                     _2053 };
    assign _2055 = { _307,
                     _2054 };
    assign _1942 = _88[8:7];
    always @* begin
        case (_1942)
        0:
            _2057 <= _2055;
        1:
            _2057 <= t0_x;
        2:
            _2057 <= t0_y;
        default:
            _2057 <= _358;
        endcase
    end
    assign _2058 = { _2057,
                     t0_isr };
    assign _1941 = _770[0:0];
    assign _2062 = _1941 ? _2061 : _2058;
    assign _1940 = _770[1:1];
    assign _2066 = _1940 ? _2065 : _2062;
    assign _1939 = _770[2:2];
    assign _2070 = _1939 ? _2069 : _2066;
    assign _1938 = _770[3:3];
    assign _2074 = _1938 ? _2073 : _2070;
    assign _1937 = _770[4:4];
    assign _2078 = _1937 ? _2077 : _2074;
    assign _2079 = _2078[15:0];
    assign _2110 = _1936 ? _2109 : _2079;
    assign _1934 = _710 ? t0_isr : _358;
    assign _1929 = _747 == _3009;
    assign _1930 = _1929 ? _990 : t0_isr;
    assign _1931 = _753 ? _1930 : t0_isr;
    assign _1927 = _605 == _2975;
    assign _1932 = _1927 ? _1931 : t0_isr;
    assign _1926 = _605 == _3415;
    assign _1935 = _1926 ? _1934 : _1932;
    assign _1925 = _605 == _3278;
    assign _2111 = _1925 ? _2110 : _1935;
    assign _2112 = _723 ? _2111 : t0_isr;
    assign _2113 = _604 ? t0_isr : _2112;
    assign _2114 = _598 ? t0_isr : _2113;
    assign _2116 = _592 ? _358 : _2114;
    assign _45 = _2116;
    assign _46 = _45;
    always @(posedge _101) begin
        if (_99)
            t0_isr <= _358;
        else
            t0_isr <= _46;
    end
    assign _2153 = { _358,
                     t0_isr };
    assign _2151 = _2146[0:0];
    assign _2157 = _2151 ? _2156 : _2153;
    assign _2150 = _2146[1:1];
    assign _2161 = _2150 ? _2160 : _2157;
    assign _2149 = _2146[2:2];
    assign _2165 = _2149 ? _2164 : _2161;
    assign _2148 = _2146[3:3];
    assign _2169 = _2148 ? _2168 : _2165;
    assign _2136 = _2134[4:0];
    assign _2133 = { gnd,
                     _770 };
    assign _2132 = { gnd,
                     t0_isr_count };
    assign _2134 = _2132 + _2133;
    assign _2135 = _763 < _2134;
    assign _2138 = _2135 ? _254 : _2136;
    assign _2129 = _710 ? t0_isr_count : _739;
    assign _2123 = _747 == _3009;
    assign _2125 = _2123 ? _739 : t0_isr_count;
    assign _2126 = _753 ? _2125 : t0_isr_count;
    assign _2122 = _605 == _2975;
    assign _2127 = _2122 ? _2126 : t0_isr_count;
    assign _2121 = _605 == _3415;
    assign _2130 = _2121 ? _2129 : _2127;
    assign _2120 = _605 == _3278;
    assign _2139 = _2120 ? _2138 : _2130;
    assign _2140 = _723 ? _2139 : t0_isr_count;
    assign _2141 = _604 ? t0_isr_count : _2140;
    assign _2142 = _598 ? t0_isr_count : _2141;
    assign _2144 = _592 ? _739 : _2142;
    assign _47 = _2144;
    assign _48 = _47;
    always @(posedge _101) begin
        if (_99)
            t0_isr_count <= _739;
        else
            t0_isr_count <= _48;
    end
    assign _2146 = _254 - t0_isr_count;
    assign _2147 = _2146[4:4];
    assign _2173 = _2147 ? _2172 : _2169;
    assign _2174 = _2173[15:0];
    assign _1936 = cfg_t0_shift[1:1];
    assign _2202 = _1936 ? _2201 : _2174;
    assign _49 = _2202;
    always @(posedge _101) begin
        if (_99)
            t0_rx_mem_0 <= _358;
        else
            if (_430)
                t0_rx_mem_0 <= _49;
    end
    assign _2221 = t0_rx_rd + _186;
    assign _2218 = ~ _2217;
    assign _2213 = ~ _1901;
    assign _2210 = t0_rx_level == _511;
    assign _2211 = ~ _2210;
    assign _2206 = 7'b1001001;
    assign _372 = _371[6:0];
    assign _2207 = _372 == _2206;
    assign _2203 = _371[7:7];
    assign _2204 = ~ _2203;
    assign _1457 = host_bit_count == _1709;
    assign _1458 = _356 & _1457;
    assign _2205 = _1458 & _2204;
    assign _2208 = _2205 & _2207;
    assign _2212 = _2208 & _2211;
    assign _50 = _2212;
    assign _2214 = _50 & _2213;
    assign _2215 = _105 | _2214;
    assign _2219 = _2215 & _2218;
    assign _2222 = _2219 ? _2221 : t0_rx_rd;
    assign _51 = _2222;
    always @(posedge _101) begin
        if (_99)
            t0_rx_rd <= _517;
        else
            t0_rx_rd <= _51;
    end
    always @* begin
        case (t0_rx_rd)
        0:
            _450 <= t0_rx_mem_0;
        1:
            _450 <= t0_rx_mem_1;
        2:
            _450 <= t0_rx_mem_2;
        default:
            _450 <= t0_rx_mem_3;
        endcase
    end
    assign _52 = _450;
    assign _2244 = _105 ? _52 : _582;
    always @(posedge _101) begin
        if (_99)
            t1_tx_mem_0 <= _358;
        else
            if (_2249)
                t1_tx_mem_0 <= _2244;
    end
    assign _2235 = t1_tx_rd + _186;
    assign _2229 = ~ _1566;
    assign _1566 = t1_tx_level == _511;
    assign _2227 = ~ _1566;
    assign _2224 = _1482 == _3415;
    assign _2225 = _1481 & _2224;
    assign _2226 = _2225 & _1486;
    assign _2228 = _2226 & _2227;
    assign _53 = _2228;
    assign _2230 = _53 & _2229;
    assign _2236 = _2230 ? _2235 : t1_tx_rd;
    assign _54 = _2236;
    always @(posedge _101) begin
        if (_99)
            t1_tx_rd <= _517;
        else
            t1_tx_rd <= _54;
    end
    always @* begin
        case (t1_tx_rd)
        0:
            _2269 <= t1_tx_mem_0;
        1:
            _2269 <= t1_tx_mem_1;
        2:
            _2269 <= t1_tx_mem_2;
        default:
            _2269 <= t1_tx_mem_3;
        endcase
    end
    assign _1486 = _64[8:8];
    assign _2270 = _1486 ? _2269 : t1_osr;
    assign _2240 = _1591 == _3415;
    assign _2241 = _2240 ? _1684 : t1_osr;
    assign _2242 = _1597 ? _2241 : t1_osr;
    assign _2239 = _1482 == _2975;
    assign _2243 = _2239 ? _2242 : t1_osr;
    assign _2238 = _1482 == _3415;
    assign _2271 = _2238 ? _2270 : _2243;
    assign _2237 = _1482 == _3009;
    assign _2330 = _2237 ? _2329 : _2271;
    assign _2331 = _1576 ? _2330 : t1_osr;
    assign _2332 = _1513 ? t1_osr : _2331;
    assign _2333 = _1510 ? t1_osr : _2332;
    assign _2335 = _1509 ? _358 : _2333;
    assign _55 = _2335;
    assign _56 = _55;
    always @(posedge _101) begin
        if (_99)
            t1_osr <= _358;
        else
            t1_osr <= _56;
    end
    assign _2364 = t1_osr & _1887;
    assign _2340 = _582[1:0];
    assign _2337 = 7'b1011111;
    assign _2338 = _578 == _2337;
    assign _2336 = _572 & _576;
    assign _2339 = _2336 & _2338;
    assign _2341 = _2339 ? _2340 : cfg_t1_shift;
    assign _57 = _2341;
    always @(posedge _101) begin
        if (_99)
            cfg_t1_shift <= _517;
        else
            cfg_t1_shift <= _57;
    end
    assign _2272 = cfg_t1_shift[0:0];
    assign _2395 = _2272 ? _2394 : _2364;
    assign _2361 = _64[8:7];
    assign _2363 = _2361 == _189;
    assign _2396 = _2363 ? _2395 : t1_y;
    assign _2357 = _1591 == _701;
    assign _2358 = _2357 ? _1684 : t1_y;
    assign _2359 = _1597 ? _2358 : t1_y;
    assign _2350 = _2348 == _189;
    assign _2354 = _2350 ? _2353 : t1_y;
    assign _2347 = _1482 == _2958;
    assign _2355 = _2347 ? _2354 : t1_y;
    assign _2345 = _1482 == _2975;
    assign _2360 = _2345 ? _2359 : _2355;
    assign _2344 = _1482 == _3009;
    assign _2397 = _2344 ? _2396 : _2360;
    assign _2343 = _1482 == _511;
    assign _2404 = _2343 ? _2403 : _2397;
    assign _2405 = _1576 ? _2404 : t1_y;
    assign _2406 = _1513 ? t1_y : _2405;
    assign _2407 = _1510 ? t1_y : _2406;
    assign _2409 = _1509 ? _358 : _2407;
    assign _58 = _2409;
    assign _59 = _58;
    always @(posedge _101) begin
        if (_99)
            t1_y <= _358;
        else
            t1_y <= _59;
    end
    always @* begin
        case (_1594)
        0:
            _1684 <= t1_x;
        1:
            _1684 <= t1_y;
        2:
            _1684 <= _1679;
        3:
            _1684 <= t1_isr;
        4:
            _1684 <= t1_osr;
        default:
            _1684 <= _358;
        endcase
    end
    assign _2419 = _1591 == _511;
    assign _2420 = _2419 ? _1684 : t1_x;
    assign _1594 = _64[5:3];
    assign _1596 = _1594 < _2958;
    assign _1591 = _64[8:6];
    assign _1593 = _1591 < _2958;
    assign _1597 = _1593 & _1596;
    assign _2421 = _1597 ? _2420 : t1_x;
    assign _2352 = _64[4:0];
    assign _2353 = { _501,
                     _2352 };
    assign _2348 = _64[8:7];
    assign _2415 = _2348 == _186;
    assign _2416 = _2415 ? _2353 : t1_x;
    assign _2413 = _1482 == _2958;
    assign _2417 = _2413 ? _2416 : t1_x;
    assign _2412 = _1482 == _2975;
    assign _2422 = _2412 ? _2421 : _2417;
    assign _2411 = _1482 == _3009;
    assign _2426 = _2411 ? _2425 : _2422;
    assign _2410 = _1482 == _511;
    assign _2432 = _2410 ? _2431 : _2426;
    assign _2433 = _1576 ? _2432 : t1_x;
    assign _2434 = _1513 ? t1_x : _2433;
    assign _2435 = _1510 ? t1_x : _2434;
    assign _2437 = _1509 ? _358 : _2435;
    assign _60 = _2437;
    assign _61 = _60;
    always @(posedge _101) begin
        if (_99)
            t1_x <= _358;
        else
            t1_x <= _61;
    end
    assign _2441 = t1_x == _358;
    assign _2442 = ~ _2441;
    assign _2443 = ~ _2442;
    assign _2398 = _64[8:6];
    always @* begin
        case (_2398)
        0:
            _2452 <= vdd;
        1:
            _2452 <= _2443;
        2:
            _2452 <= _2442;
        3:
            _2452 <= _2447;
        4:
            _2452 <= _2446;
        5:
            _2452 <= _2449;
        6:
            _2452 <= _2450;
        default:
            _2452 <= _2451;
        endcase
    end
    assign _2439 = _1482 == _511;
    assign _2453 = _2439 & _2452;
    assign _2459 = _2453 | _2458;
    assign _2468 = _2459 ? _2467 : _2461;
    always @(posedge _101) begin
        if (_99)
            t1_pc <= _307;
        else
            t1_pc <= _63;
    end
    assign _2469 = _1576 ? _2468 : t1_pc;
    assign _2470 = _1513 ? t1_pc : _2469;
    assign _2471 = _1510 ? t1_pc : _2470;
    assign _2472 = _1509 ? cfg_t1_start : _2471;
    assign _62 = _2472;
    assign _63 = _62;
    assign _2481 = _2476 ? _2480 : _63;
    assign _2477 = ~ _2476;
    RM_IHPSG13_1P_256x16_c2_bm_bist
        sram1
        ( .A_CLK(_101),
          .A_MEN(vdd),
          .A_WEN(_2476),
          .A_REN(_2477),
          .A_ADDR(_2481),
          .A_DIN(_582),
          .A_DLY(vdd),
          .A_BM(_3326),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_307),
          .A_BIST_DIN(_358),
          .A_BIST_BM(_358),
          .A_DOUT(_2487[15:0]) );
    assign _64 = _2487;
    assign _1482 = _64[15:13];
    assign _1556 = _1482 == _701;
    assign _1558 = _1556 & _1557;
    assign _1561 = _1558 & _1560;
    assign _1568 = _1561 | _1567;
    assign _1574 = _1568 | _1573;
    assign _1575 = ~ _1574;
    assign _1480 = t1_delay_left == _303;
    assign _1475 = _1469 & _1474;
    assign _1481 = _1475 & _1480;
    assign _1576 = _1481 & _1575;
    assign _2500 = _1576 ? _2499 : t1_delay_left;
    assign _2503 = _1513 ? _2502 : _2500;
    assign _2504 = _1510 ? t1_delay_left : _2503;
    assign _2506 = _1509 ? _303 : _2504;
    assign _65 = _2506;
    assign _66 = _65;
    always @(posedge _101) begin
        if (_99)
            t1_delay_left <= _303;
        else
            t1_delay_left <= _66;
    end
    assign _1512 = t1_delay_left == _303;
    assign _1513 = ~ _1512;
    assign _3078 = _1513 ? _22 : _3077;
    assign _2518 = cfg_t1_clkdiv - _685;
    assign _2508 = 7'b1011101;
    assign _2509 = _578 == _2508;
    assign _2507 = _572 & _576;
    assign _2510 = _2507 & _2509;
    assign _2511 = _2510 ? _582 : cfg_t1_clkdiv;
    assign _67 = _2511;
    always @(posedge _101) begin
        if (_99)
            cfg_t1_clkdiv <= _358;
        else
            cfg_t1_clkdiv <= _67;
    end
    assign _2516 = cfg_t1_clkdiv == _358;
    assign _2520 = _2516 ? _358 : _2518;
    assign _2514 = t1_div_count - _685;
    assign _2521 = _1474 ? _2520 : _2514;
    assign _2512 = ~ _1469;
    assign _2523 = _2512 ? _358 : _2521;
    assign _68 = _2523;
    always @(posedge _101) begin
        if (_99)
            t1_div_count <= _358;
        else
            t1_div_count <= _68;
    end
    assign _1474 = t1_div_count == _358;
    assign _1510 = ~ _1474;
    assign _3079 = _1510 ? _22 : _3078;
    assign _1469 = cfg_ctrl[1:1];
    assign _1509 = ~ _1469;
    assign _3080 = _1509 ? _22 : _3079;
    assign _69 = _3080;
    assign _70 = _69;
    always @(posedge _101) begin
        if (_99)
            pin_out <= _119;
        else
            pin_out <= _70;
    end
    assign _620 = pin_out[7:7];
    assign _616 = ~ cfg_sync_bypass;
    always @(posedge _101) begin
        if (_99)
            pins_sync1 <= _119;
        else
            pins_sync1 <= _73;
    end
    always @(posedge _101) begin
        if (_99)
            pins_sync2 <= _119;
        else
            pins_sync2 <= pins_sync1;
    end
    assign _617 = pins_sync2 & _616;
    assign _3085 = _582[7:0];
    assign _3082 = 7'b1001110;
    assign _3083 = _578 == _3082;
    assign _3081 = _572 & _576;
    assign _3084 = _3081 & _3083;
    assign _3086 = _3084 ? _3085 : cfg_sync_bypass;
    assign _71 = _3086;
    always @(posedge _101) begin
        if (_99)
            cfg_sync_bypass <= _307;
        else
            cfg_sync_bypass <= _71;
    end
    assign _73 = uio_in;
    assign _610 = _73 & cfg_sync_bypass;
    assign _618 = _610 | _617;
    assign _619 = _618[7:7];
    assign _3088 = 7'b1000111;
    assign _3089 = _578 == _3088;
    assign _3087 = _572 & _576;
    assign _3090 = _3087 & _3089;
    assign _3091 = _3090 ? _582 : cfg_pin_modes;
    assign _74 = _3091;
    always @(posedge _101) begin
        if (_99)
            cfg_pin_modes <= _358;
        else
            cfg_pin_modes <= _74;
    end
    assign _609 = cfg_pin_modes[15:14];
    always @* begin
        case (_609)
        0:
            _622 <= _619;
        1:
            _622 <= _620;
        2:
            _622 <= _621;
        default:
            _622 <= _619;
        endcase
    end
    assign _658 = { _622,
                    _627,
                    _632,
                    _637,
                    _642,
                    _647,
                    _652,
                    _657 };
    assign _982 = { _307,
                    _658 };
    assign _3253 = t0_y - _685;
    assign _3251 = _3249 == _3415;
    assign _3254 = _3251 ? _3253 : t0_y;
    assign _1168 = _1166[31:16];
    assign _1169 = { _358,
                     _1168 };
    assign _1164 = _1162[31:8];
    assign _1165 = { _307,
                     _1164 };
    assign _1160 = _1158[31:4];
    assign _1161 = { _303,
                     _1160 };
    assign _1156 = _1154[31:2];
    assign _1157 = { _517,
                     _1156 };
    assign _1152 = _1150[31:1];
    assign _1153 = { _566,
                     _1152 };
    assign _1150 = { _358,
                     t0_osr };
    assign _1148 = _1143[0:0];
    assign _1154 = _1148 ? _1153 : _1150;
    assign _1147 = _1143[1:1];
    assign _1158 = _1147 ? _1157 : _1154;
    assign _1146 = _1143[2:2];
    assign _1162 = _1146 ? _1161 : _1158;
    assign _1145 = _1143[3:3];
    assign _1166 = _1145 ? _1165 : _1162;
    assign _1143 = _254 - _770;
    assign _1144 = _1143[4:4];
    assign _1170 = _1144 ? _1169 : _1166;
    assign _1171 = _1170[15:0];
    assign _1135 = _1134[15:0];
    assign _1137 = { _1135,
                     _358 };
    assign _1131 = _1130[23:0];
    assign _1133 = { _1131,
                     _307 };
    assign _1127 = _1126[27:0];
    assign _1129 = { _1127,
                     _303 };
    assign _1123 = _1122[29:0];
    assign _1125 = { _1123,
                     _517 };
    assign _1119 = _770[0:0];
    assign _1122 = _1119 ? _296 : _295;
    assign _1118 = _770[1:1];
    assign _1126 = _1118 ? _1125 : _1122;
    assign _1117 = _770[2:2];
    assign _1130 = _1117 ? _1129 : _1126;
    assign _1116 = _770[3:3];
    assign _1134 = _1116 ? _1133 : _1130;
    assign _1115 = _770[4:4];
    assign _1138 = _1115 ? _1137 : _1134;
    assign _1139 = _1138[15:0];
    assign _1140 = ~ _1139;
    assign _3211 = _3210[15:0];
    assign _3213 = { _3211,
                     _358 };
    assign _3207 = _3206[23:0];
    assign _3209 = { _3207,
                     _307 };
    assign _3203 = _3202[27:0];
    assign _3205 = { _3203,
                     _303 };
    assign _3199 = _3198[29:0];
    assign _3201 = { _3199,
                     _517 };
    assign _3195 = _3194[30:0];
    assign _3197 = { _3195,
                     _566 };
    assign _3194 = { _358,
                     t0_osr };
    assign _3192 = _770[0:0];
    assign _3198 = _3192 ? _3197 : _3194;
    assign _3191 = _770[1:1];
    assign _3202 = _3191 ? _3201 : _3198;
    assign _3190 = _770[2:2];
    assign _3206 = _3190 ? _3205 : _3202;
    assign _3189 = _770[3:3];
    assign _3210 = _3189 ? _3209 : _3206;
    assign _3188 = _770[4:4];
    assign _3214 = _3188 ? _3213 : _3210;
    assign _3215 = _3214[15:0];
    assign _3184 = _3182[31:16];
    assign _3185 = { _358,
                     _3184 };
    assign _3180 = _3178[31:8];
    assign _3181 = { _307,
                     _3180 };
    assign _3176 = _3174[31:4];
    assign _3177 = { _303,
                     _3176 };
    assign _3172 = _3170[31:2];
    assign _3173 = { _517,
                     _3172 };
    assign _3168 = _3166[31:1];
    assign _3169 = { _566,
                     _3168 };
    assign _3166 = { _358,
                     t0_osr };
    assign _3164 = _770[0:0];
    assign _3170 = _3164 ? _3169 : _3166;
    assign _3163 = _770[1:1];
    assign _3174 = _3163 ? _3173 : _3170;
    assign _3162 = _770[2:2];
    assign _3178 = _3162 ? _3177 : _3174;
    assign _3161 = _770[3:3];
    assign _3182 = _3161 ? _3181 : _3178;
    assign _768 = { gnd,
                    _765 };
    assign _765 = _88[3:0];
    assign _767 = _765 == _303;
    assign _770 = _767 ? _254 : _768;
    assign _3160 = _770[4:4];
    assign _3186 = _3160 ? _3185 : _3182;
    assign _3187 = _3186[15:0];
    assign _3216 = _1114 ? _3215 : _3187;
    assign _3154 = t0_tx_wr == _535;
    assign _3155 = _3099 & _3154;
    always @(posedge _101) begin
        if (_99)
            t0_tx_mem_3 <= _358;
        else
            if (_3155)
                t0_tx_mem_3 <= _582;
    end
    assign _3148 = t0_tx_wr == _189;
    assign _3149 = _3099 & _3148;
    always @(posedge _101) begin
        if (_99)
            t0_tx_mem_2 <= _358;
        else
            if (_3149)
                t0_tx_mem_2 <= _582;
    end
    assign _3142 = t0_tx_wr == _186;
    assign _3143 = _3099 & _3142;
    always @(posedge _101) begin
        if (_99)
            t0_tx_mem_1 <= _358;
        else
            if (_3143)
                t0_tx_mem_1 <= _582;
    end
    assign _3104 = t0_tx_wr + _186;
    assign _3105 = _3099 ? _3104 : t0_tx_wr;
    assign _75 = _3105;
    always @(posedge _101) begin
        if (_99)
            t0_tx_wr <= _517;
        else
            t0_tx_wr <= _75;
    end
    assign _3136 = t0_tx_wr == _517;
    assign _3137 = _3099 & _3136;
    always @(posedge _101) begin
        if (_99)
            t0_tx_mem_0 <= _358;
        else
            if (_3137)
                t0_tx_mem_0 <= _582;
    end
    assign _3124 = t0_tx_rd + _186;
    assign _3110 = ~ _713;
    assign _3112 = { _517,
                     _3111 };
    assign _3097 = t0_tx_level == _3415;
    assign _3098 = ~ _3097;
    assign _3093 = 7'b1001000;
    assign _3094 = _578 == _3093;
    assign _3092 = _572 & _576;
    assign _3095 = _3092 & _3094;
    assign _3099 = _3095 & _3098;
    assign _3107 = { _517,
                     _3099 };
    assign _3108 = t0_tx_level + _3107;
    assign _3113 = _3108 - _3112;
    assign _76 = _3113;
    always @(posedge _101) begin
        if (_99)
            t0_tx_level <= _511;
        else
            t0_tx_level <= _76;
    end
    assign _713 = t0_tx_level == _511;
    assign _3118 = ~ _713;
    assign _3115 = _605 == _3415;
    assign _3116 = _700 & _3115;
    assign _3117 = _3116 & _710;
    assign _3119 = _3117 & _3118;
    assign _77 = _3119;
    assign _3111 = _77 & _3110;
    assign _3125 = _3111 ? _3124 : t0_tx_rd;
    assign _78 = _3125;
    always @(posedge _101) begin
        if (_99)
            t0_tx_rd <= _517;
        else
            t0_tx_rd <= _78;
    end
    always @* begin
        case (t0_tx_rd)
        0:
            _3157 <= t0_tx_mem_0;
        1:
            _3157 <= t0_tx_mem_1;
        2:
            _3157 <= t0_tx_mem_2;
        default:
            _3157 <= t0_tx_mem_3;
        endcase
    end
    assign _710 = _88[8:8];
    assign _3158 = _710 ? _3157 : t0_osr;
    assign _3129 = _747 == _3415;
    assign _3130 = _3129 ? _990 : t0_osr;
    assign _3131 = _753 ? _3130 : t0_osr;
    assign _3128 = _605 == _2975;
    assign _3132 = _3128 ? _3131 : t0_osr;
    assign _3127 = _605 == _3415;
    assign _3159 = _3127 ? _3158 : _3132;
    assign _3126 = _605 == _3009;
    assign _3217 = _3126 ? _3216 : _3159;
    assign _3218 = _723 ? _3217 : t0_osr;
    assign _3219 = _604 ? t0_osr : _3218;
    assign _3220 = _598 ? t0_osr : _3219;
    assign _3222 = _592 ? _358 : _3220;
    assign _79 = _3222;
    assign _80 = _79;
    always @(posedge _101) begin
        if (_99)
            t0_osr <= _358;
        else
            t0_osr <= _80;
    end
    assign _1141 = t0_osr & _1140;
    assign _3227 = _582[1:0];
    assign _3224 = 7'b1001111;
    assign _3225 = _578 == _3224;
    assign _3223 = _572 & _576;
    assign _3226 = _3223 & _3225;
    assign _3228 = _3226 ? _3227 : cfg_t0_shift;
    assign _81 = _3228;
    always @(posedge _101) begin
        if (_99)
            cfg_t0_shift <= _517;
        else
            cfg_t0_shift <= _81;
    end
    assign _1114 = cfg_t0_shift[0:0];
    assign _1172 = _1114 ? _1171 : _1141;
    assign _3244 = _88[8:7];
    assign _3246 = _3244 == _189;
    assign _3247 = _3246 ? _1172 : t0_y;
    assign _3240 = _747 == _701;
    assign _3241 = _3240 ? _990 : t0_y;
    assign _3242 = _753 ? _3241 : t0_y;
    assign _3236 = _837 == _189;
    assign _3237 = _3236 ? _850 : t0_y;
    assign _3234 = _605 == _2958;
    assign _3238 = _3234 ? _3237 : t0_y;
    assign _3232 = _605 == _2975;
    assign _3243 = _3232 ? _3242 : _3238;
    assign _3231 = _605 == _3009;
    assign _3248 = _3231 ? _3247 : _3243;
    assign _3230 = _605 == _511;
    assign _3255 = _3230 ? _3254 : _3248;
    assign _3256 = _723 ? _3255 : t0_y;
    assign _3257 = _604 ? t0_y : _3256;
    assign _3258 = _598 ? t0_y : _3257;
    assign _3260 = _592 ? _358 : _3258;
    assign _82 = _3260;
    assign _83 = _82;
    always @(posedge _101) begin
        if (_99)
            t0_y <= _358;
        else
            t0_y <= _83;
    end
    always @* begin
        case (_750)
        0:
            _990 <= t0_x;
        1:
            _990 <= t0_y;
        2:
            _990 <= _982;
        3:
            _990 <= t0_isr;
        4:
            _990 <= t0_osr;
        default:
            _990 <= _358;
        endcase
    end
    assign _3270 = _747 == _511;
    assign _3271 = _3270 ? _990 : t0_x;
    assign _750 = _88[5:3];
    assign _752 = _750 < _2958;
    assign _747 = _88[8:6];
    assign _749 = _747 < _2958;
    assign _753 = _749 & _752;
    assign _3272 = _753 ? _3271 : t0_x;
    assign _849 = _88[4:0];
    assign _850 = { _501,
                    _849 };
    assign _837 = _88[8:7];
    assign _3266 = _837 == _186;
    assign _3267 = _3266 ? _850 : t0_x;
    assign _3264 = _605 == _2958;
    assign _3268 = _3264 ? _3267 : t0_x;
    assign _3263 = _605 == _2975;
    assign _3273 = _3263 ? _3272 : _3268;
    assign _3262 = _605 == _3009;
    assign _3277 = _3262 ? _3276 : _3273;
    assign _3261 = _605 == _511;
    assign _3283 = _3261 ? _3282 : _3277;
    assign _3284 = _723 ? _3283 : t0_x;
    assign _3285 = _604 ? t0_x : _3284;
    assign _3286 = _598 ? t0_x : _3285;
    assign _3288 = _592 ? _358 : _3286;
    assign _84 = _3288;
    assign _85 = _84;
    always @(posedge _101) begin
        if (_99)
            t0_x <= _358;
        else
            t0_x <= _85;
    end
    assign _3292 = t0_x == _358;
    assign _3293 = ~ _3292;
    assign _3294 = ~ _3293;
    assign _3249 = _88[8:6];
    always @* begin
        case (_3249)
        0:
            _3303 <= vdd;
        1:
            _3303 <= _3294;
        2:
            _3303 <= _3293;
        3:
            _3303 <= _3298;
        4:
            _3303 <= _3297;
        5:
            _3303 <= _3300;
        6:
            _3303 <= _3301;
        default:
            _3303 <= _3302;
        endcase
    end
    assign _3290 = _605 == _511;
    assign _3304 = _3290 & _3303;
    assign _3310 = _3304 | _3309;
    assign _3319 = _3310 ? _3318 : _3312;
    always @(posedge _101) begin
        if (_99)
            t0_pc <= _307;
        else
            t0_pc <= _87;
    end
    assign _3320 = _723 ? _3319 : t0_pc;
    assign _3321 = _604 ? t0_pc : _3320;
    assign _3322 = _598 ? t0_pc : _3321;
    assign _3323 = _592 ? cfg_t0_start : _3322;
    assign _86 = _3323;
    assign _87 = _86;
    assign _3325 = _2476 ? _2480 : _87;
    assign _3324 = ~ _2476;
    assign _2474 = 7'b1000000;
    assign _2475 = _578 < _2474;
    assign _2473 = _572 & _576;
    assign _2476 = _2473 & _2475;
    RM_IHPSG13_1P_256x16_c2_bm_bist
        sram0
        ( .A_CLK(_101),
          .A_MEN(vdd),
          .A_WEN(_2476),
          .A_REN(_3324),
          .A_ADDR(_3325),
          .A_DIN(_582),
          .A_DLY(vdd),
          .A_BM(_3326),
          .A_BIST_CLK(gnd),
          .A_BIST_EN(gnd),
          .A_BIST_MEN(gnd),
          .A_BIST_WEN(gnd),
          .A_BIST_REN(gnd),
          .A_BIST_ADDR(_307),
          .A_BIST_DIN(_358),
          .A_BIST_BM(_358),
          .A_DOUT(_3331[15:0]) );
    assign _88 = _3331;
    assign _605 = _88[15:13];
    assign _702 = _605 == _701;
    assign _704 = _702 & _703;
    assign _707 = _704 & _706;
    assign _715 = _707 | _714;
    assign _721 = _715 | _720;
    assign _722 = ~ _721;
    assign _723 = _700 & _722;
    assign _3342 = _723 ? _3341 : t0_delay_left;
    assign _603 = t0_delay_left == _303;
    assign _604 = ~ _603;
    assign _3345 = _604 ? _3344 : _3342;
    assign _598 = ~ _597;
    assign _3346 = _598 ? t0_delay_left : _3345;
    assign _592 = ~ _591;
    assign _3348 = _592 ? _303 : _3346;
    assign _89 = _3348;
    assign _90 = _89;
    always @(posedge _101) begin
        if (_99)
            t0_delay_left <= _303;
        else
            t0_delay_left <= _90;
    end
    assign _699 = t0_delay_left == _303;
    assign _3360 = cfg_t0_clkdiv - _685;
    assign _3350 = 7'b1001101;
    assign _3351 = _578 == _3350;
    assign _3349 = _572 & _576;
    assign _3352 = _3349 & _3351;
    assign _3353 = _3352 ? _582 : cfg_t0_clkdiv;
    assign _91 = _3353;
    always @(posedge _101) begin
        if (_99)
            cfg_t0_clkdiv <= _358;
        else
            cfg_t0_clkdiv <= _91;
    end
    assign _3358 = cfg_t0_clkdiv == _358;
    assign _3362 = _3358 ? _358 : _3360;
    assign _3356 = t0_div_count - _685;
    assign _3363 = _597 ? _3362 : _3356;
    assign _3354 = ~ _591;
    assign _3365 = _3354 ? _358 : _3363;
    assign _92 = _3365;
    always @(posedge _101) begin
        if (_99)
            t0_div_count <= _358;
        else
            t0_div_count <= _92;
    end
    assign _597 = t0_div_count == _358;
    assign _591 = cfg_ctrl[0:0];
    assign _697 = _591 & _597;
    assign _700 = _697 & _699;
    assign _3368 = _700 & _3367;
    assign _3370 = _3368 & _3369;
    assign _3372 = _3370 & _3371;
    assign _93 = _3372;
    assign _424 = _93 & _423;
    assign _3374 = { _517,
                     _424 };
    assign _3375 = t0_rx_level + _3374;
    assign _3378 = _3375 - _3377;
    assign _94 = _3378;
    always @(posedge _101) begin
        if (_99)
            t0_rx_level <= _511;
        else
            t0_rx_level <= _94;
    end
    assign _2217 = t0_rx_level == _511;
    assign _3399 = ~ _2217;
    assign _582 = _370[15:0];
    assign _3397 = _582[4:0];
    assign _578 = host_cmd[6:0];
    assign _3395 = _578 == _2474;
    assign _365 = _103[2:2];
    always @(posedge _101) begin
        if (_99)
            host_mosi_s1 <= gnd;
        else
            host_mosi_s1 <= _365;
    end
    always @(posedge _101) begin
        if (_99)
            host_mosi_s2 <= gnd;
        else
            host_mosi_s2 <= host_mosi_s1;
    end
    assign _363 = 23'b00000000000000000000000;
    assign _3379 = _370[22:0];
    assign _3380 = _356 ? _3379 : host_shift_in;
    assign _3381 = host_cs_n_s2 ? host_shift_in : _3380;
    assign _95 = _3381;
    always @(posedge _101) begin
        if (_99)
            host_shift_in <= _363;
        else
            host_shift_in <= _95;
    end
    assign _370 = { host_shift_in,
                    host_mosi_s2 };
    assign _371 = _370[7:0];
    assign _361 = host_bit_count == _1709;
    assign _3382 = _361 ? _371 : host_cmd;
    assign _3383 = _356 ? _3382 : host_cmd;
    assign _3384 = host_cs_n_s2 ? host_cmd : _3383;
    assign _96 = _3384;
    always @(posedge _101) begin
        if (_99)
            host_cmd <= _307;
        else
            host_cmd <= _96;
    end
    assign _576 = host_cmd[7:7];
    assign _570 = 5'b10111;
    assign _3388 = host_bit_count + _1793;
    assign _3385 = 5'b11000;
    assign _3386 = host_bit_count < _3385;
    assign _3389 = _3386 ? _3388 : host_bit_count;
    assign _3390 = _356 ? _3389 : host_bit_count;
    assign _3392 = host_cs_n_s2 ? _739 : _3390;
    assign _97 = _3392;
    always @(posedge _101) begin
        if (_99)
            host_bit_count <= _739;
        else
            host_bit_count <= _97;
    end
    assign _571 = host_bit_count == _570;
    assign _328 = _103[1:1];
    always @(posedge _101) begin
        if (_99)
            host_cs_n_s1 <= vdd;
        else
            host_cs_n_s1 <= _328;
    end
    always @(posedge _101) begin
        if (_99)
            host_cs_n_s2 <= vdd;
        else
            host_cs_n_s2 <= host_cs_n_s1;
    end
    assign _355 = ~ host_cs_n_s2;
    always @(posedge _101) begin
        if (_99)
            host_sck_prev <= _566;
        else
            host_sck_prev <= host_sck_s2;
    end
    assign _353 = ~ host_sck_prev;
    assign vdd = 1'b1;
    assign _99 = clear;
    assign _101 = clock;
    assign _103 = ui_in;
    assign _333 = _103[0:0];
    always @(posedge _101) begin
        if (_99)
            host_sck_s1 <= gnd;
        else
            host_sck_s1 <= _333;
    end
    always @(posedge _101) begin
        if (_99)
            host_sck_s2 <= gnd;
        else
            host_sck_s2 <= host_sck_s1;
    end
    assign _354 = host_sck_s2 & _353;
    assign _356 = _354 & _355;
    assign _572 = _356 & _571;
    assign _3393 = _572 & _576;
    assign _3396 = _3393 & _3395;
    assign _3398 = _3396 ? _3397 : cfg_ctrl;
    assign _104 = _3398;
    always @(posedge _101) begin
        if (_99)
            cfg_ctrl <= _739;
        else
            cfg_ctrl <= _104;
    end
    assign _1901 = cfg_ctrl[2:2];
    assign _3400 = _1901 & _3399;
    assign _3402 = _3400 & _3401;
    assign _105 = _3402;
    assign _1904 = _105 | _1903;
    assign _1908 = _1904 & _1907;
    assign _3404 = { _517,
                     _1908 };
    assign _3405 = t1_tx_level + _3404;
    assign _3408 = _3405 - _3407;
    assign _106 = _3408;
    always @(posedge _101) begin
        if (_99)
            t1_tx_level <= _511;
        else
            t1_tx_level <= _106;
    end
    assign _3410 = t1_tx_level == _3415;
    assign gnd = 1'b0;
    assign _3422 = { gnd,
                     _3410,
                     _3413,
                     _3414,
                     _3416,
                     _3419,
                     _3420,
                     _3421 };
    assign uo_out = _3422;
    assign uio_out = _236;
    assign uio_oe = _195;

endmodule
