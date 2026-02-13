clear; clc;

%% --- Startup ---
addpath("C:\Git\")
local_add_paths();
%% 
pathAnalysisParquet = fullfile("..","data","hoa_phat_analysis_only.parquet");
analysis_in = parquetread(pathAnalysisParquet);

pathSiteRegistry = fullfile("..","data","site_registry_hoa_phat_20260211_toTest.json");
registry = util.json.ImportJsonFile2Struct(pathSiteRegistry);


%% 
regTbl = tpqc_signals.registry.using.tpqc_registry_flatten(registry)

% varNames from tpqc_data
varNames = string(analysis_in.Properties.VariableNames)';

map = tpqc_signals.registry.using.tpqc_map_columns_to_registry(varNames, registry, struct( ...
    "requireTagMatch", false, ...      % можно true, если хочешь отсеять несовпадающие tag
    "onAmbiguous", "keep_all" ...      % или "error"/"first"
));
disp(map(1:20,:));
%% 
[analysis_in_named, renameTbl] = tpqc_signals.registry.using.tpqc_rename_columns_from_mapping(analysis_in, map, "canonical", true)

%% 
physical = util.json.ImportJsonFile2Struct(database.data.database_root + "\physical.json");


%% 
T_xmol = tpqc_analysis.chemanal.extract_and_convert_to_xmol(analysis_in_named, physical.atomic_mass)

%% 
Tchem = [analysis_in_named,T_xmol]
