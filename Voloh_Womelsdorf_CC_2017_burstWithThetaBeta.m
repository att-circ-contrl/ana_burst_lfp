dbstop if error


%% ------------------------------------------------------------------------
% set some directories poiting to the data read in/ processed by fieldtrip
% ------------------------------------------------------------------------

% %remove this path to test
% str = '/Users/ben/Dropbox/__grad/Research/code_experimental/code_burst';
% rmpath(genpath(str))
% str = '/Users/ben/Dropbox/__grad/Research/code_experimental/code_useful';
% rmpath(genpath(str))
% clear str

%% directories
rootdir = '/Volumes/DATA/DATA_BURST';
datadir = [rootdir '/RES_BURST_fulltest']; %_longtimwin

%rdir = [datadir '/ana_sta_power']; 
rdir = [datadir '/ana_burst_lfp_testPipeline'];
checkmakedir(rdir)


%% ------------------------------------------------------------------------
% get the STA, LFP power
%------------------------------------------------------------------------

if 0
    %things to run
    nworkers = 2;

    cfg = [];
    cfg.getdata = [1 1 1]; %PSD, STA,allSpk
    cfg.ststimwin = [-0.5 0.5]; %[-0.45 0.45];
    cfg.toipad = [-.75 4];
    cfg.toistimchange = [0 5]; %cfg.toipad;
    cfg.trls = {'attendRight','attendLeft'};
    cfg.foi = 2:0.5:40; %2:1.5:40;
    cfg.toipsd = [-0.5 0;
                0   .5;
                .5  1;
                1   1.5;
                1.5 2;
                0.2 2;];
    cfg.Flp = 40; %cfg.foi(end) + 10;
    cfg.filtersta = 0;
    cfg.dointerpolation = 0;
    cfg.staboundaryaction = 'excise';

    %these are the cells we analyzed for the paper
    %anacells = {'mi_av17_062_01-A_sig003a_wf','mi_av17_065_01-A_sig002a_wf','mi_av17_069_01-A_sig004b_wf','mi_av17_073_01-A_sig002a_wf','mi_av17_085_01-A_sig003a_wf','mi_av17_085_01-A_sig004a_wf','mi_av17_089_01-A_sig001a_wf','mi_av17_089_02-A_sig001a_wf','mi_av17_095_01-A_SP005c_wf','mi_av17_096_01-A_SP004a_wf','mi_av17_107_02-A_SP011b_wf','mi_av17_107_03-A_SP011a_wf','mi_av17_107_03-A_SP011d_wf','mi_av17_107_04-A_SP011a_wf','mi_av17_111_01-A_SP001a_wf','mi_av17_111_01-A_SP011a_wf','ry_av09_055_01-A_sig004a_wf','ry_av09_060_01-A_sig002a_wf','ry_av09_060_01-A_sig002b_wf','ry_av09_060_01-A_sig011a_wf','ry_av10_061_01-A_sig001a_wf','ry_av10_062_01-A_sig002d_wf','ry_av10_064_01-A_sig002a_wf','ry_av10_064_01-A_sig004a_wf','ry_av10_065_01-A_sig001b_wf','ry_av10_077_02-A_sig010a_wf','ry_av12_093_01-A_sig012a_wf','ry_av12_094_01-A_sig010b_wf','ry_av12_101_01-A_sig002a_wf','ry_av12_104_01-A_sig001a_wf','ry_av12_116_01-A_sig004a_wf','ry_av12_129_01-A_sig003a_wf','ry_av12_130_01-A_sig003c_wf','ry_av12_138_01-A_sig002a_wf','ry_av12_140_01-A_sig002b_wf','ry_av12_140_01-A_sig002c_wf','ry_av12_142_01-A_sig001a_wf','ry_av12_142_01-A_sig001b_wf','ry_av12_142_01-A_sig001c_wf','ry_av12_142_01-A_sig002a_wf','ry_av12_143_01-A_sig002a_wf'};
    anacells = {'mi_av17_061_01-A_sig001a_wf','mi_av17_061_01-A_sig002a_wf','mi_av17_062_01-A_sig003a_wf','mi_av17_062_01-A_sig003b_wf','mi_av17_064_01-A_sig012c_wf','mi_av17_065_01-A_sig002a_wf','mi_av17_065_01-A_sig003a_wf','mi_av17_066_01-A_sig005c_wf','mi_av17_067_01-A_sig002c_wf','mi_av17_067_01-A_sig003a_wf','mi_av17_067_01-A_sig004a_wf','mi_av17_067_01-A_sig005a_wf','mi_av17_068_01-A_sig001a_wf','mi_av17_068_01-A_sig002b_wf','mi_av17_068_01-A_sig002c_wf','mi_av17_069_01-A_sig001a_wf','mi_av17_069_01-A_sig004a_wf','mi_av17_069_01-A_sig004b_wf','mi_av17_070_01-A_sig009a_wf','mi_av17_071_01-A_sig002c_wf','mi_av17_073_01-A_sig001a_wf','mi_av17_073_01-A_sig002a_wf','mi_av17_073_02-A_sig002a_wf','mi_av17_082_01-A_sig001a_wf','mi_av17_082_01-A_sig001b_wf','mi_av17_082_01-A_sig001d_wf','mi_av17_082_01-A_sig002a_wf','mi_av17_082_01-A_sig002b_wf','mi_av17_082_01-A_sig002d_wf','mi_av17_082_01-A_sig002e_wf','mi_av17_082_01-A_sig003a_wf','mi_av17_082_01-A_sig003b_wf','mi_av17_082_01-A_sig003c_wf','mi_av17_083_01-A_sig002a_wf','mi_av17_083_01-A_sig004a_wf','mi_av17_083_01-A_sig004b_wf','mi_av17_084_01-A_sig001a_wf','mi_av17_084_01-A_sig003a_wf','mi_av17_084_01-A_sig004c_wf','mi_av17_085_01-A_sig001a_wf','mi_av17_085_01-A_sig002b_wf','mi_av17_085_01-A_sig002c_wf','mi_av17_085_01-A_sig003a_wf','mi_av17_085_01-A_sig003c_wf','mi_av17_085_01-A_sig003e_wf','mi_av17_085_01-A_sig004a_wf','mi_av17_086_01-A_sig002a_wf','mi_av17_086_01-A_sig003a_wf','mi_av17_086_01-A_sig004a_wf','mi_av17_086_02-A_sig002a_wf','mi_av17_086_02-A_sig002d_wf','mi_av17_086_02-A_sig003c_wf','mi_av17_086_02-A_sig003e_wf','mi_av17_086_02-A_sig004a_wf','mi_av17_086_02-A_sig004c_wf','mi_av17_087_01-A_sig003a_wf','mi_av17_087_01-A_sig004c_wf','mi_av17_088_01-A_sig001a_wf','mi_av17_088_01-A_sig002a_wf','mi_av17_088_01-A_sig003a_wf','mi_av17_089_01-A_sig001a_wf','mi_av17_089_01-A_sig001b_wf','mi_av17_089_01-A_sig002d_wf','mi_av17_089_01-A_sig004a_wf','mi_av17_089_01-A_sig004b_wf','mi_av17_089_02-A_sig001a_wf','mi_av17_089_02-A_sig001b_wf','mi_av17_089_02-A_sig002a_wf','mi_av17_089_02-A_sig003b_wf','mi_av17_089_02-A_sig004a_wf','mi_av17_090_01-A_sig002a_wf','mi_av17_090_01-A_sig003a_wf','mi_av17_090_01-A_sig004a_wf','mi_av17_090_01-A_sig004b_wf','mi_av17_094_01-A_SP004c_wf','mi_av17_094_01-A_SP004d_wf','mi_av17_095_01-A_SP001a_wf','mi_av17_095_01-A_SP004b_wf','mi_av17_095_01-A_SP005a_wf','mi_av17_095_01-A_SP005c_wf','mi_av17_095_01-A_SP006c_wf','mi_av17_095_01-A_SP006d_wf','mi_av17_096_01-A_SP004a_wf','mi_av17_096_01-A_SP005c_wf','mi_av17_096_01-A_SP006a_wf','mi_av17_096_01-A_SP006b_wf','mi_av17_097_01-A_SP005a_wf','mi_av17_097_01-A_SP006a_wf','mi_av17_099_01-A_SP003a_wf','mi_av17_100_01-A_SP001a_wf','mi_av17_100_01-A_SP001b_wf','mi_av17_100_01-A_SP009a_wf','mi_av17_101_01-A_SP002a_wf','mi_av17_101_02-A_SP001b_wf','mi_av17_101_02-A_SP002c_wf','mi_av17_103_01-A_SP010a_wf','mi_av17_103_01-A_SP010c_wf','mi_av17_103_01-A_SP010d_wf','mi_av17_103_02-A_SP005a_wf','mi_av17_104_01-A_SP011a_wf','mi_av17_104_02-A_SP005a_wf','mi_av17_104_02-A_SP011a_wf','mi_av17_107_01-A_SP001b_wf','mi_av17_107_02-A_SP011b_wf','mi_av17_107_03-A_SP011a_wf','mi_av17_107_03-A_SP011d_wf','mi_av17_107_04-A_SP001b_wf','mi_av17_107_04-A_SP011a_wf','mi_av17_107_04-A_SP011b_wf','mi_av17_108_01-A_SP001a_wf','mi_av17_108_01-A_SP009a_wf','mi_av17_108_01-A_SP011a_wf','mi_av17_108_01-A_SP011b_wf','mi_av17_108_02-A_SP001a_wf','mi_av17_108_02-A_SP002a_wf','mi_av17_108_02-A_SP009a_wf','mi_av17_108_03-A_SP002b_wf','mi_av17_108_04-A_SP001b_wf','mi_av17_108_04-A_SP002b_wf','mi_av17_108_04-A_SP002c_wf','mi_av17_108_04-A_SP009b_wf','mi_av17_108_05-A_SP002b_wf','mi_av17_109_04-A_SP002b_wf','mi_av17_110_01-A_SP001b_wf','mi_av17_110_01-A_SP001c_wf','mi_av17_110_01-A_SP003b_wf','mi_av17_111_01-A_SP001a_wf','mi_av17_111_01-A_SP002a_wf','mi_av17_111_01-A_SP002c_wf','mi_av17_111_01-A_SP011a_wf','mi_av17_112_01-A_SP001c_wf','mi_av17_112_01-A_SP011a_wf','mi_av17_112_02-A_SP001a_wf','mi_av17_112_02-A_SP011a_wf','mi_av17_112_03-A_SP001b_wf','mi_av17_112_03-A_SP002a_wf','mi_av17_112_04-A_SP001a_wf','mi_av17_112_04-A_SP011b_wf','mi_av17_113_01-A_SP002a_wf','mi_av17_113_01-A_SP011b_wf','mi_av17_113_02-A_SP002a_wf','mi_av17_113_02-A_SP011a_wf','mi_av17_113_03-A_SP001a_wf','mi_av17_113_03-A_SP002b_wf','mi_av17_113_04-A_SP011a_wf','mi_av17_113_04-A_SP011b_wf','mi_av17_113_04-A_SP011c_wf','mi_av17_113_04-A_SP011d_wf','mi_av17_114_01-A_SP001a_wf','mi_av17_114_01-A_SP003a_wf','mi_av17_114_01-A_SP012a_wf','mi_av17_114_02-A_SP001a_wf','mi_av17_114_02-A_SP004a_wf','mi_av17_114_02-A_SP012a_wf','mi_av17_115_04-A_SP004a_wf','mi_av17_115_04-A_SP004b_wf','mi_av17_115_04-A_SP004d_wf','mi_av17_115_05-A_SP004a_wf','mi_av17_115_05-A_SP004c_wf','ry_av09_055_01-A_sig002a_wf','ry_av09_055_01-A_sig002b_wf','ry_av09_055_01-A_sig003a_wf','ry_av09_055_01-A_sig003b_wf','ry_av09_055_01-A_sig004a_wf','ry_av09_055_01-A_sig004c_wf','ry_av09_056_01-A_sig002a_wf','ry_av09_056_01-A_sig002b_wf','ry_av09_056_02-A_sig001a_wf','ry_av09_056_02-A_sig001c_wf','ry_av09_056_02-A_sig002b_wf','ry_av09_057_01-A_sig009a_wf','ry_av09_057_01-A_sig011a_wf','ry_av09_057_01-A_sig011b_wf','ry_av09_057_01-A_sig011d_wf','ry_av09_058_01-A_sig001c_wf','ry_av09_058_01-A_sig003b_wf','ry_av09_058_01-A_sig010c_wf','ry_av09_058_01-A_sig011a_wf','ry_av09_059_01-A_sig001a_wf','ry_av09_059_01-A_sig001d_wf','ry_av09_059_01-A_sig002a_wf','ry_av09_059_01-A_sig009b_wf','ry_av09_059_01-A_sig010a_wf','ry_av09_060_01-A_sig002a_wf','ry_av09_060_01-A_sig002b_wf','ry_av09_060_01-A_sig011a_wf','ry_av09_060_01-A_sig011b_wf','ry_av10_061_01-A_sig001a_wf','ry_av10_061_01-A_sig001c_wf','ry_av10_061_01-A_sig001e_wf','ry_av10_061_01-A_sig002a_wf','ry_av10_061_01-A_sig003b_wf','ry_av10_061_01-A_sig010a_wf','ry_av10_061_01-A_sig011a_wf','ry_av10_061_01-A_sig011c_wf','ry_av10_062_01-A_sig001a_wf','ry_av10_062_01-A_sig001d_wf','ry_av10_062_01-A_sig002a_wf','ry_av10_062_01-A_sig002b_wf','ry_av10_062_01-A_sig002d_wf','ry_av10_062_01-A_sig002e_wf','ry_av10_062_01-A_sig009a_wf','ry_av10_063_01-A_sig009a_wf','ry_av10_063_01-A_sig010a_wf','ry_av10_063_01-A_sig011a_wf','ry_av10_064_01-A_sig002a_wf','ry_av10_064_01-A_sig003b_wf','ry_av10_064_01-A_sig004a_wf','ry_av10_064_01-A_sig009b_wf','ry_av10_064_01-A_sig010b_wf','ry_av10_065_01-A_sig001a_wf','ry_av10_065_01-A_sig001b_wf','ry_av10_065_01-A_sig009a_wf','ry_av10_067_01-A_sig001a_wf','ry_av10_067_01-A_sig002a_wf','ry_av10_068_01-A_sig002b_wf','ry_av10_068_01-A_sig002c_wf','ry_av10_068_01-A_sig004a_wf','ry_av10_071_01-A_sig009a_wf','ry_av10_071_01-A_sig009b_wf','ry_av10_071_01-A_sig010a_wf','ry_av10_071_01-A_sig011a_wf','ry_av10_072_01-A_sig003a_wf','ry_av10_073_01-A_sig001a_wf','ry_av10_073_01-A_sig002a_wf','ry_av10_073_02-A_sig001c_wf','ry_av10_073_02-A_sig002c_wf','ry_av10_074_01-A_sig002a_wf','ry_av10_074_01-A_sig002b_wf','ry_av10_075_01-A_sig001a_wf','ry_av10_075_01-A_sig001b_wf','ry_av10_075_01-A_sig003b_wf','ry_av10_076_01-A_sig004b_wf','ry_av10_076_01-A_sig004c_wf','ry_av10_076_01-A_sig009a_wf','ry_av10_076_01-A_sig009c_wf','ry_av10_077_02-A_sig001a_wf','ry_av10_077_02-A_sig001b_wf','ry_av10_077_02-A_sig001d_wf','ry_av10_077_02-A_sig003a_wf','ry_av10_077_02-A_sig003b_wf','ry_av10_077_02-A_sig003c_wf','ry_av10_077_02-A_sig010a_wf','ry_av10_077_02-A_sig010b_wf','ry_av10_078_01-A_sig009a_wf','ry_av10_078_01-A_sig009b_wf','ry_av10_078_01-A_sig009c_wf','ry_av10_078_01-A_sig010a_wf','ry_av10_078_01-A_sig010b_wf','ry_av10_078_01-A_sig010c_wf','ry_av10_079_01-A_sig001b_wf','ry_av10_079_01-A_sig004b_wf','ry_av10_079_01-A_sig004c_wf','ry_av10_079_01-A_sig010a_wf','ry_av10_079_01-A_sig010b_wf','ry_av10_080_01-A_sig001a_wf','ry_av10_080_01-A_sig003a_wf','ry_av10_080_01-A_sig003b_wf','ry_av10_080_01-A_sig004c_wf','ry_av10_081_01-A_sig002a_wf','ry_av10_081_01-A_sig004c_wf','ry_av10_082_01-A_sig004a_wf','ry_av10_082_01-A_sig004b_wf','ry_av12_083_01-A_sig001b_wf','ry_av12_083_01-A_sig001c_wf','ry_av12_083_01-A_sig003a_wf','ry_av12_083_01-A_sig003b_wf','ry_av12_083_01-A_sig009a_wf','ry_av12_083_01-A_sig009b_wf','ry_av12_083_01-A_sig009d_wf','ry_av12_083_02-A_sig001a_wf','ry_av12_083_02-A_sig009a_wf','ry_av12_083_02-A_sig009b_wf','ry_av12_084_01-A_sig002c_wf','ry_av12_084_01-A_sig003a_wf','ry_av12_084_01-A_sig003b_wf','ry_av12_084_01-A_sig009a_wf','ry_av12_084_01-A_sig009b_wf','ry_av12_084_01-A_sig009c_wf','ry_av12_084_01-A_sig009d_wf','ry_av12_084_01-A_sig010b_wf','ry_av12_084_01-A_sig010c_wf','ry_av12_085_01-A_sig001b_wf','ry_av12_085_01-A_sig004a_wf','ry_av12_085_01-A_sig010a_wf','ry_av12_086_01-A_sig002a_wf','ry_av12_086_01-A_sig003a_wf','ry_av12_087_01-A_sig001c_wf','ry_av12_087_01-A_sig002a_wf','ry_av12_087_01-A_sig004b_wf','ry_av12_088_01-A_sig002a_wf','ry_av12_088_01-A_sig002b_wf','ry_av12_088_01-A_sig002c_wf','ry_av12_088_01-A_sig002e_wf','ry_av12_088_01-A_sig004b_wf','ry_av12_088_01-A_sig004c_wf','ry_av12_088_01-A_sig010a_wf','ry_av12_088_01-A_sig010c_wf','ry_av12_088_02-A_sig001a_wf','ry_av12_088_02-A_sig002b_wf','ry_av12_088_02-A_sig002c_wf','ry_av12_088_02-A_sig002d_wf','ry_av12_088_02-A_sig004b_wf','ry_av12_088_02-A_sig004c_wf','ry_av12_088_02-A_sig010a_wf','ry_av12_089_01-A_sig004a_wf','ry_av12_090_01-A_sig005a_wf','ry_av12_090_01-A_sig005b_wf','ry_av12_091_01-A_sig001c_wf','ry_av12_091_01-A_sig001d_wf','ry_av12_091_01-A_sig002a_wf','ry_av12_091_01-A_sig003b_wf','ry_av12_091_01-A_sig003c_wf','ry_av12_091_01-A_sig004a_wf','ry_av12_091_01-A_sig004b_wf','ry_av12_091_01-A_sig004c_wf','ry_av12_091_01-A_sig005a_wf','ry_av12_091_01-A_sig006a_wf','ry_av12_092_01-A_sig009a_wf','ry_av12_092_01-A_sig010b_wf','ry_av12_092_01-A_sig011a_wf','ry_av12_092_01-A_sig013a_wf','ry_av12_092_01-A_sig013c_wf','ry_av12_093_01-A_sig012a_wf','ry_av12_093_02-A_sig009a_wf','ry_av12_094_01-A_sig002a_wf','ry_av12_094_01-A_sig002b_wf','ry_av12_094_01-A_sig002c_wf','ry_av12_094_01-A_sig004a_wf','ry_av12_094_01-A_sig004c_wf','ry_av12_094_01-A_sig010a_wf','ry_av12_094_01-A_sig010b_wf','ry_av12_095_01-A_sig003a_wf','ry_av12_095_01-A_sig004a_wf','ry_av12_095_01-A_sig004d_wf','ry_av12_097_01-A_sig001a_wf','ry_av12_097_01-A_sig002a_wf','ry_av12_097_01-A_sig002b_wf','ry_av12_097_01-A_sig005a_wf','ry_av12_097_01-A_sig005b_wf','ry_av12_098_01-A_sig003a_wf','ry_av12_098_01-A_sig006a_wf','ry_av12_098_01-A_sig006b_wf','ry_av12_099_01-A_sig001a_wf','ry_av12_099_01-A_sig002a_wf','ry_av12_099_01-A_sig002b_wf','ry_av12_099_01-A_sig003a_wf','ry_av12_099_01-A_sig004a_wf','ry_av12_100_01-A_sig001a_wf','ry_av12_100_01-A_sig001b_wf','ry_av12_100_01-A_sig003a_wf','ry_av12_100_01-A_sig003b_wf','ry_av12_100_01-A_sig003c_wf','ry_av12_101_01-A_sig002a_wf','ry_av12_102_01-A_sig001a_wf','ry_av12_102_01-A_sig001c_wf','ry_av12_102_01-A_sig003a_wf','ry_av12_102_01-A_sig003b_wf','ry_av12_103_01-A_sig003a_wf','ry_av12_103_01-A_sig003b_wf','ry_av12_103_01-A_sig003d_wf','ry_av12_103_01-A_sig004a_wf','ry_av12_103_01-A_sig004b_wf','ry_av12_103_01-A_sig004c_wf','ry_av12_103_01-A_sig005a_wf','ry_av12_104_01-A_sig001a_wf','ry_av12_104_01-A_sig001b_wf','ry_av12_104_01-A_sig003a_wf','ry_av12_104_01-A_sig005a_wf','ry_av12_104_01-A_sig005b_wf','ry_av12_104_01-A_sig005c_wf','ry_av12_105_01-A_sig001c_wf','ry_av12_105_01-A_sig002a_wf','ry_av12_105_01-A_sig003a_wf','ry_av12_106_01-A_sig007a_wf','ry_av12_106_01-A_sig008a_wf','ry_av12_106_01-A_sig008b_wf','ry_av12_107_01-A_sig002a_wf','ry_av12_107_01-A_sig002c_wf','ry_av12_109_01-A_sig003a_wf','ry_av12_109_01-A_sig004a_wf','ry_av12_109_01-A_sig004c_wf','ry_av12_110_01-A_sig011a_wf','ry_av12_115_01-A_sig001a_wf','ry_av12_115_01-A_sig001b_wf','ry_av12_115_01-A_sig004a_wf','ry_av12_115_01-A_sig004b_wf','ry_av12_116_01-A_sig001b_wf','ry_av12_116_01-A_sig004a_wf','ry_av12_116_01-A_sig004b_wf','ry_av12_116_01-A_sig004e_wf','ry_av12_117_01-A_sig001a_wf','ry_av12_117_01-A_sig003a_wf','ry_av12_117_01-A_sig003b_wf','ry_av12_117_01-A_sig003d_wf','ry_av12_120_01-A_sig006a_wf','ry_av12_122_01-A_sig001a_wf','ry_av12_122_01-A_sig001b_wf','ry_av12_122_01-A_sig001d_wf','ry_av12_123_01-A_sig003a_wf','ry_av12_123_01-A_sig003b_wf','ry_av12_124_01-A_sig001b_wf','ry_av12_124_01-A_sig002a_wf','ry_av12_124_01-A_sig003a_wf','ry_av12_124_01-A_sig003b_wf','ry_av12_125_01-A_sig001a_wf','ry_av12_126_01-A_sig001a_wf','ry_av12_126_01-A_sig001b_wf','ry_av12_127_01-A_sig001a_wf','ry_av12_127_01-A_sig002a_wf','ry_av12_127_01-A_sig002b_wf','ry_av12_127_01-A_sig002c_wf','ry_av12_127_01-A_sig003b_wf','ry_av12_128_01-A_sig001a_wf','ry_av12_128_01-A_sig001b_wf','ry_av12_128_01-A_sig002a_wf','ry_av12_128_01-A_sig002b_wf','ry_av12_128_01-A_sig002c_wf','ry_av12_128_01-A_sig002e_wf','ry_av12_128_01-A_sig003a_wf','ry_av12_128_01-A_sig003b_wf','ry_av12_129_01-A_sig002b_wf','ry_av12_129_01-A_sig002c_wf','ry_av12_129_01-A_sig003a_wf','ry_av12_129_01-A_sig003b_wf','ry_av12_129_01-A_sig003d_wf','ry_av12_130_01-A_sig002a_wf','ry_av12_130_01-A_sig002b_wf','ry_av12_130_01-A_sig002c_wf','ry_av12_130_01-A_sig003a_wf','ry_av12_130_01-A_sig003b_wf','ry_av12_130_01-A_sig003c_wf','ry_av12_138_01-A_sig001a_wf','ry_av12_138_01-A_sig002a_wf','ry_av12_139_01-A_sig001a_wf','ry_av12_139_01-A_sig002a_wf','ry_av12_139_01-A_sig003a_wf','ry_av12_139_01-A_sig004a_wf','ry_av12_139_01-A_sig004b_wf','ry_av12_139_01-A_sig004c_wf','ry_av12_139_01-A_sig005a_wf','ry_av12_140_01-A_sig001a_wf','ry_av12_140_01-A_sig001b_wf','ry_av12_140_01-A_sig002a_wf','ry_av12_140_01-A_sig002b_wf','ry_av12_140_01-A_sig002c_wf','ry_av12_140_01-A_sig003b_wf','ry_av12_140_01-A_sig004a_wf','ry_av12_140_01-A_sig004b_wf','ry_av12_141_01-A_sig003b_wf','ry_av12_142_01-A_sig001a_wf','ry_av12_142_01-A_sig001b_wf','ry_av12_142_01-A_sig001c_wf','ry_av12_142_01-A_sig002a_wf','ry_av12_142_01-A_sig002b_wf','ry_av12_142_01-A_sig004a_wf','ry_av12_142_01-A_sig005a_wf','ry_av12_142_01-A_sig005b_wf','ry_av12_143_01-A_sig002a_wf','ry_av17_144_01-A_sig002a_wf','ry_av17_144_01-A_sig005a_wf','ry_av17_144_01-A_sig005b_wf'};
    cfg.testdata = anacells;
    get_sta_lfp_v02(nworkers, rootdir,datadir,cfg,rdir);
end
%delete(gcp('nocreate'))

xx=1;


%% ------------------------------------------------------------------------
% create the master list
%------------------------------------------------------------------------

if 0
    mcfg = [];
    mcfg.loaddir = datadir;
    mcfg.resdir = rdir;
    mcfg.bursttoi = [-0.5 2];

    masterlist = makemasterlist(mcfg);
else
    try
        load([rdir '/masterlist.mat'])
    end
end


%% ------------------------------------------------------------------------
% select the cells: 1s full LFP data, 30 burst in post attention cue,
% isolation=3
%------------------------------------------------------------------------

seldir = [rdir '/select_41cells'];

if 0
    lcfg = [];
    lcfg.nburst = 30;
    lcfg.bursttoi = [0 2];
    lcfg.lfptoi = [-0.5 0.5];
    lcfg.isolationQuality = 3;

    list = selectcells_v01(masterlist,lcfg);

    checkmakedir(seldir)
    save([seldir '/list.mat'],'list','lcfg')
else
    load([seldir '/list.mat'])
end



%% ------------------------------------------------------------------------
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------
% 
% common settings
% 
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------

figpath = [seldir '/figures'];
checkmakedir(figpath)
cd(seldir)

stafoi = [5 10; 16 30];
freqoi = 5:0.5:30;

%% ------------------------------------------------------------------------
% pre-processing, per epoch (baseline, attention cue)
%------------------------------------------------------------------------
load([seldir '/list.mat'])
outlistpath_pre = [seldir '/list_precue.mat'];
outlistpath_post = [seldir '/list_postcue.mat'];
if 0

    %pre-attention
    if 1
        ccfg = [];
        ccfg.replacenans = 1;
        ccfg.dointerp = 1;
        ccfg.dolowpassfilt = 1;
        ccfg.flp = 100;
        ccfg.interptoi = [-0.005 0.005];
        ccfg.lfptoi = [];
        ccfg.spiketoi = [-0.5 0];

        inpath = '/Volumes/DATA/DATA_BURST/RES_BURST_revision';
        outpath = seldir;
        suffix = '_pre';

        clean_save_sta_data(list,outlistpath_pre,inpath,outpath,suffix,ccfg)
    end
    
    %post-attention cue
    if 1
        ccfg = [];
        ccfg.replacenans = 0;
        ccfg.dointerp = 1;
        ccfg.dolowpassfilt = 1;
        ccfg.flp = 100;
        ccfg.interptoi = [-0.005 0.005];
        ccfg.lfptoi = [-0.5 0.5];
        ccfg.spiketoi = [0 2];

        inpath = '/Volumes/DATA/DATA_BURST/RES_BURST_revision';
        outpath = seldir;
        suffix = '_post';

        clean_save_sta_data(list,outlistpath_post,inpath,outpath,suffix,ccfg)
    end
end
%}


%% ------------------------------------------------------------------------
% LFP power
%load in the masterlist and select only the relevant cells

lfppowname = 'pow_all_n301.mat';
    
if 0
    cd(rdir)
    load([rdir '/masterlist.mat'])

    goodQual = false(1,numel(masterlist));
    for n=1:numel(goodQual)
        if ~isempty(masterlist(n).isolationquality)...
             && masterlist(n).isolationquality==3
         goodQual(n) = 1;
        end
    end


    %compile all tyhe power, save it, analyze it
    list_reduced = masterlist(goodQual);

    itime = 1:6; 
    pow_all = concatenate_all_power(list_reduced,datadir,rdir,lfppowname,itime);
end


%% ------------------------------------------------------------------------
% compute the 5 cycle sts the 
if 0
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('     computing STS with adaptive window')
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')

    %settings
    scfg = [];
    scfg.fsample = 1000;
    scfg.freq = freqoi;
    scfg.ncycle = 5;
        
    %baseline
    if 1
        disp('----------------------------------------')
        disp('baseline...')
        disp('----------------------------------------')
        
        cd(seldir)
        load(outlistpath_pre)

        savedir = seldir;
        suffix ='_pre';

        for id=1:numel(list)
            name = list(id).fullname;
            disp(name);

            in = load(name);
            sts_cue = adaptivewin_spiketriggeredspec_fft(in.sta_cue,scfg);

            %save and update list
            stsname = [list(id).name '_sts' suffix '.mat'];
            savename = [savedir '/' stsname];
            list(id).stsname = savename;
            save(savename,'sts_cue')
        end
    
        %save the updated list
        listpath = [seldir '/list_precue.mat'];
        save(listpath,'list','-append')
    end
    
    %attention
    if 1
        disp('----------------------------------------')
        disp('attention...')
        disp('----------------------------------------')
        
        cd(seldir)
        load(outlistpath_post)

        savedir = seldir;
        suffix ='_post';

        for id=1:numel(list)
            name = list(id).fullname;
            disp(name);

            in = load(name);
            sts_cue = adaptivewin_spiketriggeredspec_fft(in.sta_cue,scfg);

            %save and update list
            stsname = [list(id).name '_sts' suffix '.mat'];
            savename = [savedir '/' stsname];
            list(id).stsname = savename;
            save(savename,'sts_cue')
        end

        %save the updated list
        listpath = [seldir '/list_postcue.mat'];
        save(listpath,'list','-append')
    end

end


%% ########################################################################
%########################################################################
%                               ANALYSES
%########################################################################
%########################################################################





%% ------------------------------------------------------------------------
% burst porportion
% - base this on the original STA data 

if 0
    load([seldir '/list.mat'])
    ana_burst_proportion(list,datadir,'all',figpath)
    ana_burst_proportion(list,datadir,'ns',figpath)
    ana_burst_proportion(list,datadir,'bs',figpath)
end


%% ------------------------------------------------------------------------
% LFP power anlayses
if 0
    cd(rdir)
    load(lfppowname)
    
    %characterize spectral peaks in attention period
    if 1
        foi = [4 10; 16 30];

        idel = 1:5;
        pow_all2a = pow_all;
        pow_all2a.power(:,:,idel) = [];
        pow_all2a.toi(idel,:) = [];
        pow_all2a.itime(idel) = [];
        ana_lfp_power_freqpeaks(pow_all2a,foi,figpath);
    end


    % change in power from baseline
    if 1
        foi = [5 10; 16 30];

        %reduced pow_all for only analyzed cells
        load([seldir '/list.mat'])
        del = ~ismember(pow_all.lfpname,{list.lfpname});
        pow_all2 = pow_all;
        pow_all2.lfpname(del) = [];
        pow_all2.power(del,:,:) = [];    

        %plot spectral peaks, but take away irrelevant tois for the figure if
        %necessary
        idel = [];
        pow_all3a = pow_all2;
        pow_all3a.power(:,:,idel) = [];
        pow_all3a.toi(idel,:) = [];
        pow_all3a.itime(idel) = [];
        ana_lfp_power_timeresolved(pow_all3a,foi,figpath,0)
    end
    
    if 1
        %take away some toi so we can normalize properly
        %foi = [4 10; 16 30];
        idel = 6;
        %idel = 1:5;
        %idel = 2:5;
        pow_all3b = pow_all2;
        pow_all3b.power(:,:,idel) = [];
        pow_all3b.toi(idel,:) = [];
        pow_all3b.itime(idel) = [];
        ana_lfp_psd_all_time_windows(pow_all3b,foi,figpath);
    end
end



%% ------------------------------------------------------------------------
% sta power
if 0
    load(outlistpath_post)
    
    stspow_post = get_sta_pow_all(list,seldir,'range',0.3);    
    ana_sta_pow_spikecentered(stspow_post,figpath,stafoi)
end

%% ------------------------------------------------------------------------
% time resolved STA power

if 0
    load(outlistpath_post)

    %pow_time_out = ana_sta_pow_timeresolved(list,seldir,figpath,freqoi,stafoi);
    pow_time_out = ana_sta_pow_timeresolve_noShuffle(list,seldir,figpath,freqoi,stafoi);
end


%% ------------------------------------------------------------------------
% PPC

if 1
    load(outlistpath_post)

    ang_post = get_phase_stats(list,seldir);
    %listout = update_list_significantLocking(list,ang_post,stafoi);
    
    ana_mean_phases(ang_post,stafoi,1,figpath)
    ana_phase_locking(ang_post,stafoi,1,figpath)
    %ana_phase_locking(ang_post,[5 10; 15 20],1)
    
    %pot the samples used in the paper
    %smpls = {'ry_av12_140_01-A_sig002c_wf_ppc','mi_av17_107_03-A_SP011a_wf_ppc','ry_av09_055_01-A_sig004a_wf_ppc','mi_av17_085_01-A_sig003a_wf_ppc'};
    %plot_ppc_indiv_spectra(ang_post,figpath,smpls)
end

%% ------------------------------------------------------------------------
% phase-dependent power (PDP)

if 0
    load(outlistpath_post)
    
    ang_post = get_phase_stats(list,seldir);

    pdp = get_phase_dependent_power(list,seldir,stafoi,6);
    %pdp_ana = ana_phase_dependent_power(pdp,ang_post,figpath);     
    pdp_ana = ana_phase_dependent_power(pdp,ang_post,figpath,[1 1]);     
end


%% ------------------------------------------------------------------------
% attention effects

%STA power
if 0
    load(outlistpath_pre)
    stspow_pre = get_sta_pow_all(list,seldir,'range',0.3);  
    
    load(outlistpath_post)
    stspow_post = get_sta_pow_all(list,seldir,'range',0.3);
    
    ana_sta_power_withAttention(stspow_pre, stspow_post, stafoi)
end

% proportion of significant locking
if 0
    load(outlistpath_pre)
    ang_pre = get_phase_stats(list,seldir); 
    
    load(outlistpath_post)
    ang_post = get_phase_stats(list,seldir);
    
    ana_phase_prop_withAttention(ang_pre,ang_post,stafoi)
end

%------------------------------------------------------------------------
% compare with spike properties
load(outlistpath_post)

%firing rate binned by power
if 0
    ana_firingrate_binnedByPower(list,datadir,stafoi,4,[-0.1 0.1],1,figpath);
end

%STA power vs local variability
if 0
    spkinfo = get_spikeinfo(list,datadir,'median');
    stspow_post = get_sta_pow_all(list,seldir,'range',0.3);
    
    ana_corr_lv_stapow(stspow_post,spkinfo,stafoi)
end

%burst porportion vs LFP power       
if 0
    cd(rdir)
    load(lfppowname)
    out = ana_corr_burstprop_lfppower(list,pow_all,6,[5 10; 16 30],[0.2 2],figpath);
end
