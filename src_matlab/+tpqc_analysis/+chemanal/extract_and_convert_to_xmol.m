function T_xmol = extract_and_convert_to_xmol(T2, atomicMassDB)
% extract_and_convert_to_xmol
% Extract chemical composition columns (ana_fin_<el>_pct) from table T2
% and convert weight percent (wt.%) to mole fractions (xmol).
%
% INPUT:
%   T2            : input table with chemical columns
%   atomicMassDB  : atomic mass database (compatible with wt_to_xmol)
%
% OUTPUT:
%   T_xmol        : table with mole fractions for selected elements
%
% NOTES:
%   - Output columns are named in lower-case style: ana_fin_<el>_xmol
%   - Fe is always included as ana_fin_fe_xmol (wt_to_xmol typically returns Fe)

    % Get default list of allowed elements
    elemListProper = util.composition.default_elements_list;          % e.g. "Ti","Nb","Fe"
    elemListLower  = lower(elemListProper);                          % e.g. "ti","nb","fe"

    varNames = string(T2.Properties.VariableNames);

    % Identify columns that match ana_fin_<element>_pct
    isChemCol = startsWith(varNames, "ana_fin_") & endsWith(varNames, "_pct");
    chemCols = varNames(isChemCol);

    % Map column name -> element symbol (proper case for wt_to_xmol)
    col2elemProper = containers.Map('KeyType','char','ValueType','char');
    usedElemsLower = strings(0);

    for i = 1:numel(chemCols)
        colName = chemCols(i);

        % Extract element name from column (lower-case)
        % ana_fin_ti_pct -> "ti"
        elLower = erase(colName, "ana_fin_");
        elLower = erase(elLower, "_pct");
        elLower = lower(elLower);

        % Keep only elements from default list (case-insensitive)
        idx = find(elemListLower == elLower, 1);
        if ~isempty(idx)
            elProper = char(elemListProper(idx));                    % e.g. "Ti"
            col2elemProper(char(colName)) = elProper;
            usedElemsLower(end+1) = elLower; %#ok<AGROW>
        end
    end

    % Ensure Fe is always present in output (wt_to_xmol typically returns it)
    if ~any(usedElemsLower == "fe")
        usedElemsLower(end+1) = "fe";
    end

    % Stable ordering: follow default list order + Fe
    usedElemsLower = unique(usedElemsLower, 'stable');
    orderedLower = strings(0);
    orderedProper = strings(0);
    for k = 1:numel(elemListLower)
        if any(usedElemsLower == elemListLower(k))
            orderedLower(end+1)  = elemListLower(k);  %#ok<AGROW>
            orderedProper(end+1) = elemListProper(k); %#ok<AGROW>
        end
    end
    if ~any(orderedLower == "fe")
        orderedLower(end+1)  = "fe";
        orderedProper(end+1) = "Fe";
    end

    % Output variable names in requested style (lower-case)
    outVarNames = "ana_fin_" + orderedLower + "_xmol";

    nRows = height(T2);
    nElem = numel(outVarNames);

    % Preallocate numeric matrix
    X = zeros(nRows, nElem);

    % Loop over rows
    for r = 1:nRows

        % Build composition struct for current row (proper-case fields)
        comp_wt = struct();

        for i = 1:numel(chemCols)
            colName = chemCols(i);

            if isKey(col2elemProper, char(colName))
                elProper = col2elemProper(char(colName));  % e.g. "Si","Nb","Ti"
                val = T2{r, colName};

                if ~isnan(val)
                    comp_wt.(elProper) = val;
                end
            end
        end

        % Convert wt.% to mole fraction
        [comp_xmol, ~] = util.composition.wt_to_xmol(comp_wt, atomicMassDB);

        % Store results (wt_to_xmol returns proper-case fields)
        for j = 1:nElem
            elProper = char(orderedProper(j));  % e.g. "Fe","Si","Nb"
            if isfield(comp_xmol, elProper)
                X(r, j) = comp_xmol.(elProper);
            else
                X(r, j) = 0;
            end
        end
    end

    % Build output table
    T_xmol = array2table(X, 'VariableNames', outVarNames);

end
