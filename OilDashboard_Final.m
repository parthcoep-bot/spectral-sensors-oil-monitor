classdef OilDashboard_Final < matlab.apps.AppBase
% =========================================================
%  TAKUMI-TYPE — Smart Oil Condition Monitor
%  COEP Technological University | Department of Metallurgical Engineering
%  Sensors: TSL25911 (Optical) | DS18B20 (Temp) | SS49E (Hall)
%  Parameters: Oxidation | Soot | Oil Temp | Metal Particles
%  B.Tech Mini Project Thesis
% =========================================================

    properties (Access = public)
        UIFigure        matlab.ui.Figure

        % ── Header labels ──────────────────────────────
        lblTeam         matlab.ui.control.Label
        lblStatus       matlab.ui.control.Label
        lblTime         matlab.ui.control.Label
        lblOverall      matlab.ui.control.Label

        % ── 4 parameter cards (each has gauge+field+cond) ──
        gaugeOx         matlab.ui.control.SemicircularGauge
        gaugeSoot       matlab.ui.control.SemicircularGauge
        gaugeTemp       matlab.ui.control.SemicircularGauge
        gaugeMetal      matlab.ui.control.SemicircularGauge

        lampOx          matlab.ui.control.Lamp
        lampSoot        matlab.ui.control.Lamp
        lampTemp        matlab.ui.control.Lamp
        lampMetal       matlab.ui.control.Lamp

        fieldOx         matlab.ui.control.NumericEditField
        fieldSoot       matlab.ui.control.NumericEditField
        fieldTemp       matlab.ui.control.NumericEditField
        fieldMetal      matlab.ui.control.NumericEditField

        lblCondOx       matlab.ui.control.Label
        lblCondSoot     matlab.ui.control.Label
        lblCondTemp     matlab.ui.control.Label
        lblCondMetal    matlab.ui.control.Label

        lblRefOx        matlab.ui.control.Label
        lblRefSoot      matlab.ui.control.Label
        lblRefTemp      matlab.ui.control.Label
        lblRefMetal     matlab.ui.control.Label

        % ── Trend chart + Raw sensor display ───────────
        axesTrend       matlab.ui.control.UIAxes
        axesSpectral    matlab.ui.control.UIAxes

        % ── Raw sensor readout labels ───────────────────
        lblRawCH0       matlab.ui.control.Label
        lblRawCH1       matlab.ui.control.Label
        lblRawLux       matlab.ui.control.Label
        lblRawHall      matlab.ui.control.Label
        lblRawTemp      matlab.ui.control.Label

        % ── Buttons ────────────────────────────────────
        btnStart        matlab.ui.control.Button
        btnStop         matlab.ui.control.Button
        btnExport       matlab.ui.control.Button

        % ── Timer + data ────────────────────────────────
        UpdateTimer     timer
        oxH     double
        sootH   double
        tempH   double
        metalH  double
        timeH   double
        sampleCount double
    end

    % ─────────────────────────────────────────────────────
    methods (Access = private)

        % ══ CONDITION LOGIC ══════════════════════════════
        function [lbl, col] = getCondition(~, param, val)
            switch param
                case 'Ox'
                    % Oxidation Index (CH1/CH0 ratio from TSL25911)
                    % Low ratio = fresh oil. High ratio = oxidised oil.
                    if val <= 0.30,    lbl='GOOD';     col=[0.11 0.62 0.46];
                    elseif val <= 0.55,lbl='MODERATE'; col=[0.94 0.62 0.15];
                    else,              lbl='POOR';     col=[0.89 0.29 0.29];
                    end
                case 'Soot'
                    % Soot index: derived from lux drop vs baseline
                    % 0 = clean, 10 = heavily sooted
                    if val <= 2.5,     lbl='GOOD';     col=[0.11 0.62 0.46];
                    elseif val <= 5.0, lbl='MODERATE'; col=[0.94 0.62 0.15];
                    else,              lbl='POOR';     col=[0.89 0.29 0.29];
                    end
                case 'Temp'
                    % Oil temperature °C — engine oil normal 80-100°C
                    if val <= 100,     lbl='NORMAL';   col=[0.11 0.62 0.46];
                    elseif val <= 120, lbl='HIGH';     col=[0.94 0.62 0.15];
                    else,              lbl='CRITICAL'; col=[0.89 0.29 0.29];
                    end
                case 'Metal'
                    % Metal particle index from SS49E Hall sensor
                    % 0 = no particles, 10 = heavy wear
                    if val <= 2.0,     lbl='GOOD';     col=[0.11 0.62 0.46];
                    elseif val <= 5.0, lbl='MODERATE'; col=[0.94 0.62 0.15];
                    else,              lbl='POOR';     col=[0.89 0.29 0.29];
                    end
            end
        end

        % ══ OVERALL CONDITION ════════════════════════════
        function [ov, col] = getOverall(app, Ox, Soot, Temp, Metal)
            [l1,~] = app.getCondition('Ox',    Ox);
            [l2,~] = app.getCondition('Soot',  Soot);
            [l3,~] = app.getCondition('Temp',  Temp);
            [l4,~] = app.getCondition('Metal', Metal);
            conds = {l1,l2,l3,l4};
            if any(strcmp(conds,'POOR')) || any(strcmp(conds,'CRITICAL'))
                ov='POOR — IMMEDIATE ATTENTION REQUIRED';
                col=[0.89 0.29 0.29];
            elseif any(strcmp(conds,'MODERATE')) || any(strcmp(conds,'HIGH'))
                ov='MODERATE — Schedule service soon';
                col=[0.94 0.62 0.15];
            else
                ov='GOOD — Oil condition healthy';
                col=[0.11 0.62 0.46];
            end
        end

        % ══ UPDATE ALL WIDGETS ════════════════════════════
        function updateDashboard(app, Ox, Soot, Temp, Metal, CH0, CH1, Lux)
            app.sampleCount = app.sampleCount + 1;

            % ── Gauges ──────────────────────────────────
            app.gaugeOx.Value    = min(1, max(0, Ox));
            app.gaugeSoot.Value  = min(10,max(0, Soot));
            app.gaugeTemp.Value  = min(150,max(0,Temp));
            app.gaugeMetal.Value = min(10,max(0, Metal));

            % ── Numeric fields (actual sensor values) ───
            app.fieldOx.Value    = round(Ox,   4);
            app.fieldSoot.Value  = round(Soot, 2);
            app.fieldTemp.Value  = round(Temp, 1);
            app.fieldMetal.Value = round(Metal,2);

            % ── Lamps + condition labels ─────────────────
            params = {'Ox','Soot','Temp','Metal'};
            vals   = {Ox, Soot, Temp, Metal};
            lamps  = [app.lampOx, app.lampSoot, app.lampTemp, app.lampMetal];
            conds  = [app.lblCondOx, app.lblCondSoot, app.lblCondTemp, app.lblCondMetal];

            for i = 1:4
                [lbl, col] = app.getCondition(params{i}, vals{i});
                lamps(i).Color     = col;
                conds(i).Text      = lbl;
                conds(i).FontColor = col;
            end

            % ── Overall banner ──────────────────────────
            [ov, ovcol] = app.getOverall(Ox, Soot, Temp, Metal);
            app.lblOverall.Text      = ['● Overall: ' ov];
            app.lblOverall.FontColor = ovcol;

            % ── Raw sensor values ────────────────────────
            app.lblRawCH0.Text  = sprintf('CH0 (Full): %d', round(CH0));
            app.lblRawCH1.Text  = sprintf('CH1 (IR):   %d', round(CH1));
            app.lblRawLux.Text  = sprintf('Lux:        %.1f', Lux);
            app.lblRawHall.Text = sprintf('Hall V:     %.3f V', Metal/10*3.3);
            app.lblRawTemp.Text = sprintf('Temp raw:   %.1f °C', Temp);

            % ── Timestamp ───────────────────────────────
            app.lblTime.Text = sprintf('Last read: %s  |  Sample #%d', ...
                datestr(now,'HH:MM:SS'), app.sampleCount);

            % ── History arrays (last 60 points) ─────────
            app.oxH    = [app.oxH    Ox];
            app.sootH  = [app.sootH  Soot];
            app.tempH  = [app.tempH  Temp];
            app.metalH = [app.metalH Metal];
            app.timeH  = [app.timeH  app.sampleCount];
            N = 60;
            if numel(app.oxH) > N
                app.oxH    = app.oxH(end-N+1:end);
                app.sootH  = app.sootH(end-N+1:end);
                app.tempH  = app.tempH(end-N+1:end);
                app.metalH = app.metalH(end-N+1:end);
                app.timeH  = app.timeH(end-N+1:end);
            end

            % ── Trend chart ─────────────────────────────
            cla(app.axesTrend);
            hold(app.axesTrend,'on');
            yyaxis(app.axesTrend,'left');
            plot(app.axesTrend, app.timeH, app.oxH,   '-', ...
                 'Color',[0.11 0.62 0.46],'LineWidth',2,'DisplayName','Oxidation Idx');
            plot(app.axesTrend, app.timeH, app.sootH./10, '--', ...
                 'Color',[0.94 0.62 0.15],'LineWidth',2,'DisplayName','Soot /10');
            plot(app.axesTrend, app.timeH, app.metalH./10,':', ...
                 'Color',[0.89 0.29 0.29],'LineWidth',2,'DisplayName','Metal /10');
            app.axesTrend.YColor = [0.7 0.8 0.9];
            ylabel(app.axesTrend,'Normalised (0–1)','Color',[0.7 0.8 0.9],'FontSize',8);

            yyaxis(app.axesTrend,'right');
            plot(app.axesTrend, app.timeH, app.tempH, '-', ...
                 'Color',[0.42 0.68 0.84],'LineWidth',1.5,'DisplayName','Temp °C');
            app.axesTrend.YColor = [0.42 0.68 0.84];
            ylabel(app.axesTrend,'Temperature (°C)','Color',[0.42 0.68 0.84],'FontSize',8);

            hold(app.axesTrend,'off');
            legend(app.axesTrend,'Oxidation','Soot/10','Metal/10','Temp °C',...
                   'TextColor',[0.7 0.8 0.9],'Location','northwest','FontSize',8);
            app.axesTrend.XLabel.String = 'Sample';
            app.axesTrend.XLabel.Color  = [0.7 0.8 0.9];
            grid(app.axesTrend,'on');

            % ── Bar chart: current snapshot ──────────────
            cla(app.axesSpectral);
            barData = [Ox, Soot/10, Temp/150, Metal/10];
            labels  = {'Oxidation','Soot','Temp','Metal'};
            colors  = {[0.11 0.62 0.46],[0.94 0.62 0.15],[0.42 0.68 0.84],[0.89 0.29 0.29]};
            for b = 1:4
                bar(app.axesSpectral, b, barData(b), ...
                    'FaceColor', colors{b}, 'EdgeColor','none');
                hold(app.axesSpectral,'on');
            end
            hold(app.axesSpectral,'off');
            app.axesSpectral.XTick      = 1:4;
            app.axesSpectral.XTickLabel = labels;
            app.axesSpectral.YLim       = [0 1.1];
            app.axesSpectral.XColor     = [0.7 0.8 0.9];
            app.axesSpectral.YColor     = [0.7 0.8 0.9];
            app.axesSpectral.XTickLabelRotation = 0;
            title(app.axesSpectral,'Normalised Parameter Snapshot','Color',[0.7 0.8 0.9],'FontSize',9);
            grid(app.axesSpectral,'on');
        end

        % ══ TIMER CALLBACK ════════════════════════════════
        function timerFcn(app, ~, ~)

            % ════════════════════════════════════════════
            % SIMULATION MODE
            % Remove these lines when ESP32 is connected
            % ════════════════════════════════════════════
            CH0   = 3200 + randn()*80;           % TSL25911 full spectrum
            CH1   = 980  + randn()*30;            % TSL25911 IR only
            Lux   = max(1, 2400 + randn()*120);   % Calculated lux
            V_hall= 1.65 + randn()*0.04;          % SS49E Hall voltage
            Temp  = 82.0 + randn()*1.5;           % DS18B20 °C

            % ════════════════════════════════════════════
            % REAL ESP32 — uncomment when connected:
            % persistent sp
            % if isempty(sp) || ~isvalid(sp)
            %   sp = serialport("COM3", 115200);
            %   configureTerminator(sp,"LF");
            %   sp.Timeout = 3;
            % end
            % try
            %   raw = readline(sp);
            %   v   = str2double(strsplit(strtrim(raw),','));
            %   if numel(v) < 5, return; end
            %   CH0=v(1); CH1=v(2); Lux=v(3); V_hall=v(4); Temp=v(5);
            % catch; return; end
            % ════════════════════════════════════════════

            % ── CORRELATION EQUATIONS ────────────────────
            % 1. Oxidation Index (ASTM E2412 proxy)
            %    CH1/CH0 ratio rises as oil oxidises
            %    (IR absorption increases with carbonyl groups)
            Ox_ref = 0.28;   % calibrated in fresh oil — update after calibration
            Ox = (CH0 > 0) * (CH1 / max(CH0, 1));

            % 2. Soot Index (TGA/ASTM E2412 proxy)
            %    Lux drops as oil darkens with soot
            %    Soot 0-10 mapped from lux 3000 (clean) to 0 (black)
            Lux_clean = 2800;   % lux in fresh oil — update after calibration
            Soot = max(0, min(10, (1 - Lux/Lux_clean) * 10));

            % 3. Oil Temperature (direct DS18B20 reading)
            %    No correlation needed — direct measurement
            %    Temperature compensation applied to other parameters
            tc = 1 + 0.006*(Temp - 25);  % temp compensation factor

            % 4. Metal Particle Index (SS49E Hall effect)
            %    V_hall = 1.65V at null (no field)
            %    Ferrous particles near magnet shift voltage
            %    Index 0-10 from voltage deviation
            V_null  = 1.65;  % null voltage — update after calibration
            Metal   = min(10, max(0, abs(V_hall - V_null) * 80));

            % Apply temperature compensation to Ox
            Ox = Ox / tc;

            % Update the dashboard
            app.updateDashboard(Ox, Soot, Temp, Metal, CH0, CH1, Lux);
        end

        % ══ START ════════════════════════════════════════
        function startMonitoring(app)
            app.oxH=[]; app.sootH=[]; app.tempH=[]; app.metalH=[];
            app.timeH=[]; app.sampleCount=0;

            if ~isempty(app.UpdateTimer) && isvalid(app.UpdateTimer)
                stop(app.UpdateTimer); delete(app.UpdateTimer);
            end
            app.UpdateTimer = timer(...
                'ExecutionMode','fixedRate', ...
                'Period', 1.0, ...
                'TimerFcn', @(~,~)app.timerFcn());
            start(app.UpdateTimer);

            app.btnStart.Enable = 'off';
            app.btnStop.Enable  = 'on';
            app.lblStatus.Text  = '● LIVE';
            app.lblStatus.FontColor = [0.11 0.62 0.46];
        end

        % ══ STOP ═════════════════════════════════════════
        function stopMonitoring(app)
            if ~isempty(app.UpdateTimer) && isvalid(app.UpdateTimer)
                stop(app.UpdateTimer); delete(app.UpdateTimer);
            end
            app.btnStart.Enable = 'on';
            app.btnStop.Enable  = 'off';
            app.lblStatus.Text  = '■ STOPPED';
            app.lblStatus.FontColor = [0.89 0.29 0.29];
        end

        % ══ EXPORT DATA TO CSV ════════════════════════════
        function exportData(app)
            if isempty(app.oxH)
                uialert(app.UIFigure,'No data to export. Start monitoring first.','Export');
                return
            end
            fname = sprintf('OilData_%s.csv', datestr(now,'yyyymmdd_HHMMSS'));
            fid   = fopen(fname,'w');
            fprintf(fid,'Sample,Oxidation,Soot,Temperature_C,MetalParticles\n');
            for i = 1:numel(app.oxH)
                fprintf(fid,'%d,%.4f,%.2f,%.1f,%.2f\n',...
                    i, app.oxH(i), app.sootH(i), app.tempH(i), app.metalH(i));
            end
            fclose(fid);
            uialert(app.UIFigure, sprintf('Saved: %s',fname),'Export Complete');
        end

        % ══ BUILD ALL UI COMPONENTS ══════════════════════
        function buildUI(app)
            BG   = [0.06 0.10 0.16];   % deep navy
            CARD = [0.09 0.15 0.22];   % card bg
            LINE = [0.14 0.22 0.33];   % border

            FW = 1180; FH = 720;
            app.UIFigure.Position        = [60 60 FW FH];
            app.UIFigure.Color           = BG;
            app.UIFigure.Name            = 'Oil Condition Monitor — TAKUMI-TYPE';
            app.UIFigure.Resize          = 'off';

            % ── TOP HEADER BAR ───────────────────────────
            app.lblTeam = uilabel(app.UIFigure,...
                'Text',     'TAKUMI-TYPE  ·  Smart Oil Monitor  ·  Parth Ramesh Shinde (MIS: 642511003)  ·  COEP Tech',...
                'Position', [18 688 780 22],...
                'FontSize', 11, 'FontWeight','bold',...
                'FontColor',[1 0.84 0]);

            app.lblStatus = uilabel(app.UIFigure,...
                'Text',     '● READY',...
                'Position', [730 688 140 22],...
                'FontSize', 11,'FontWeight','bold',...
                'FontColor',[0.55 0.65 0.72]);

            app.lblTime = uilabel(app.UIFigure,...
                'Text',     'Last read: --:--:--',...
                'Position', [880 688 290 22],...
                'FontSize', 10,'FontColor',[0.55 0.65 0.72]);

            % ── OVERALL BANNER ───────────────────────────
            app.lblOverall = uilabel(app.UIFigure,...
                'Text',     '● Overall: Press START to begin',...
                'Position', [18 660 1140 22],...
                'FontSize', 12,'FontWeight','bold',...
                'FontColor',[0.55 0.65 0.72]);

            % ── 4 PARAMETER CARDS ────────────────────────
            pNames   = {'Oxidation Index','Soot Level','Oil Temperature','Metal Particles'};
            pUnits   = {'CH1/CH0 ratio','Index (0–10)','°C','Index (0–10)'};
            pLimits  = {[0 1],[0 10],[0 150],[0 10]};
            pASTM    = {'ASTM E2412','TGA / E2412','DS18B20','SS49E Hall'};
            pRefs    = {'Ref < 0.30','Ref < 2.5','Normal < 100°C','Ref < 2.0'};
            pBandsG  = {false, false, false, false};  % all: low = good
            colX     = [18, 308, 598, 888];

            pBandLims = {
                [0 0.30; 0.30 0.55; 0.55 1.0];
                [0 2.5;  2.5  5.0;  5.0  10.0];
                [0 100;  100  120;  120  150];
                [0 2.0;  2.0  5.0;  5.0  10.0];
            };

            gaugeH = gobjects(1,4); lampH = gobjects(1,4);
            fieldH = gobjects(1,4); condH = gobjects(1,4); refH = gobjects(1,4);

            for i = 1:4
                x = colX(i);

                % Card background
                uipanel(app.UIFigure,...
                    'Position',        [x 330 282 322],...
                    'BackgroundColor', CARD,...
                    'BorderType',      'line',...
                    'HighlightColor',  LINE);

                % Parameter name
                uilabel(app.UIFigure,...
                    'Text',      pNames{i},...
                    'Position',  [x+10 632 262 20],...
                    'FontSize',  11,'FontWeight','bold',...
                    'FontColor', [0 0.85 1]);

                % ASTM source
                uilabel(app.UIFigure,...
                    'Text',      pASTM{i},...
                    'Position',  [x+10 614 262 16],...
                    'FontSize',  8.5,...
                    'FontColor', [0.55 0.65 0.72]);

                % Gauge
                g = uigauge(app.UIFigure,'semicircular',...
                    'Position',        [x+10 452 260 200],...
                    'Limits',          pLimits{i},...
                    'FontColor',       [1 1 1],...
                    'BackgroundColor', CARD);
                g.ScaleColors      = {[0.11 0.62 0.46],[0.94 0.62 0.15],[0.89 0.29 0.29]};
                g.ScaleColorLimits = pBandLims{i};
                gaugeH(i) = g;

                % Lamp
                lp = uilamp(app.UIFigure,...
                    'Position', [x+128 448 22 22],...
                    'Color',    [0.11 0.62 0.46]);
                lampH(i) = lp;

                % Numeric field
                ef = uieditfield(app.UIFigure,'numeric',...
                    'Position',            [x+60 410 162 34],...
                    'Value',               0,...
                    'FontSize',            18,'FontWeight','bold',...
                    'FontColor',           [0 0.9 1],...
                    'BackgroundColor',     CARD,...
                    'HorizontalAlignment', 'center',...
                    'Editable',            'off');
                fieldH(i) = ef;

                % Unit label
                uilabel(app.UIFigure,...
                    'Text',      pUnits{i},...
                    'Position',  [x+60 393 162 16],...
                    'FontSize',  8.5,...
                    'FontColor', [0.55 0.65 0.72],...
                    'HorizontalAlignment','center');

                % Reference value
                rl = uilabel(app.UIFigure,...
                    'Text',      pRefs{i},...
                    'Position',  [x+60 374 162 18],...
                    'FontSize',  9,'FontWeight','bold',...
                    'FontColor', [1 0.84 0],...
                    'HorizontalAlignment','center');
                refH(i) = rl;

                % Condition label
                cl = uilabel(app.UIFigure,...
                    'Text',      '---',...
                    'Position',  [x+70 346 142 24],...
                    'FontSize',  14,'FontWeight','bold',...
                    'FontColor', [0.55 0.65 0.72],...
                    'HorizontalAlignment','center');
                condH(i) = cl;
            end

            app.gaugeOx=gaugeH(1); app.gaugeSoot=gaugeH(2);
            app.gaugeTemp=gaugeH(3); app.gaugeMetal=gaugeH(4);
            app.lampOx=lampH(1); app.lampSoot=lampH(2);
            app.lampTemp=lampH(3); app.lampMetal=lampH(4);
            app.fieldOx=fieldH(1); app.fieldSoot=fieldH(2);
            app.fieldTemp=fieldH(3); app.fieldMetal=fieldH(4);
            app.lblCondOx=condH(1); app.lblCondSoot=condH(2);
            app.lblCondTemp=condH(3); app.lblCondMetal=condH(4);
            app.lblRefOx=refH(1); app.lblRefSoot=refH(2);
            app.lblRefTemp=refH(3); app.lblRefMetal=refH(4);

            % ── TREND CHART ──────────────────────────────
            app.axesTrend = uiaxes(app.UIFigure,...
                'Position',   [18 80 700 238],...
                'Color',      CARD,...
                'XColor',     [0.55 0.65 0.72],...
                'GridColor',  LINE,...
                'GridAlpha',  1,...
                'FontSize',   8);
            grid(app.axesTrend,'on');
            title(app.axesTrend,'Live Trend — Last 60 Readings',...
                  'Color',[0.7 0.8 0.9],'FontSize',9);

            % ── SNAPSHOT BAR CHART ───────────────────────
            app.axesSpectral = uiaxes(app.UIFigure,...
                'Position',   [730 80 310 238],...
                'Color',      CARD,...
                'XColor',     [0.55 0.65 0.72],...
                'YColor',     [0.55 0.65 0.72],...
                'GridColor',  LINE,...
                'GridAlpha',  1,...
                'FontSize',   8);
            grid(app.axesSpectral,'on');

            % ── RAW SENSOR PANEL ─────────────────────────
            uipanel(app.UIFigure,...
                'Title',           'Raw Sensor Values',...
                'Position',        [1050 80 112 238],...
                'BackgroundColor', CARD,...
                'ForegroundColor', [0.7 0.8 0.9],...
                'BorderType',      'line',...
                'HighlightColor',  LINE,...
                'FontSize',        9);

            rawLabels = {'lblRawCH0','lblRawCH1','lblRawLux','lblRawHall','lblRawTemp'};
            rawInits  = {'CH0 (Full): ---','CH1 (IR):   ---','Lux:        ---',...
                         'Hall V:     ---','Temp raw:   ---'};
            for r = 1:5
                lbl = uilabel(app.UIFigure,...
                    'Text',      rawInits{r},...
                    'Position',  [1055 278-(r-1)*38 100 28],...
                    'FontSize',  8.5,...
                    'FontColor', [0.42 0.68 0.84],...
                    'FontName',  'Consolas');
                app.(rawLabels{r}) = lbl;
            end

            % ── THRESHOLD LEGEND ─────────────────────────
            uilabel(app.UIFigure,...
                'Text',     'Thresholds',...
                'Position', [730 48 150 18],...
                'FontSize', 9,'FontWeight','bold',...
                'FontColor',[0.7 0.8 0.9]);

            threshText = {
                '■ GOOD     Ox<0.30  Soot<2.5  T<100°C  Metal<2.0';
                '■ MODERATE Ox<0.55  Soot<5.0  T<120°C  Metal<5.0';
                '■ POOR     Ox≥0.55  Soot≥5.0  T≥120°C  Metal≥5.0';
            };
            threshColors = {[0.11 0.62 0.46],[0.94 0.62 0.15],[0.89 0.29 0.29]};
            for t = 1:3
                uilabel(app.UIFigure,...
                    'Text',     threshText{t},...
                    'Position', [730 32-(t-1)*16 440 14],...
                    'FontSize', 8,...
                    'FontColor',threshColors{t},...
                    'FontName', 'Consolas');
            end

            % ── EQUATION STRIP ───────────────────────────
            uilabel(app.UIFigure,...
                'Text', 'Equations:  Ox = CH1/CH0 (ASTM E2412)  ·  Soot = (1−Lux/Lux₀)×10 (TGA)  ·  Metal = |V_hall−1.65|×80  ·  Temp compensation: ÷(1+0.006×(T−25))',...
                'Position',  [18 54 1154 18],...
                'FontSize',  8,...
                'FontColor', [0.36 0.48 0.58],...
                'FontName',  'Consolas');

            % ── BUTTONS ──────────────────────────────────
            app.btnStart = uibutton(app.UIFigure,'push',...
                'Text',            '▶  Start',...
                'Position',        [18 18 140 32],...
                'FontSize',        12,'FontWeight','bold',...
                'BackgroundColor', [0.11 0.62 0.46],...
                'FontColor',       [1 1 1],...
                'ButtonPushedFcn', @(~,~)app.startMonitoring());

            app.btnStop = uibutton(app.UIFigure,'push',...
                'Text',            '■  Stop',...
                'Position',        [170 18 140 32],...
                'FontSize',        12,'FontWeight','bold',...
                'BackgroundColor', [0.89 0.29 0.29],...
                'FontColor',       [1 1 1],...
                'Enable',          'off',...
                'ButtonPushedFcn', @(~,~)app.stopMonitoring());

            app.btnExport = uibutton(app.UIFigure,'push',...
                'Text',            '⬇  Export CSV',...
                'Position',        [322 18 140 32],...
                'FontSize',        11,...
                'BackgroundColor', [0.12 0.22 0.36],...
                'FontColor',       [0.7 0.8 0.9],...
                'ButtonPushedFcn', @(~,~)app.exportData());

            % Thesis & Sensors footer
            uilabel(app.UIFigure,...
                'Text',     'Mini Project Thesis  ·  Dept of Metallurgical Engineering  ·  TSL25911 Optical  ·  DS18B20 Temp  ·  SS49E Hall  ·  ESP32',...
                'Position', [460 22 710 14],...
                'FontSize', 8,...
                'FontColor',[0.36 0.48 0.58]);
        end

    end % private methods

    % ─────────────────────────────────────────────────────
    methods (Access = public)

        function app = OilDashboard_Final()
            app.UIFigure = uifigure('Name','Oil Monitor','Visible','off');
            app.buildUI();
            app.oxH=[]; app.sootH=[]; app.tempH=[]; app.metalH=[];
            app.timeH=[]; app.sampleCount=0;
            app.UIFigure.Visible = 'on';
        end

        function delete(app)
            app.stopMonitoring();
            if isvalid(app.UIFigure); delete(app.UIFigure); end
        end

    end
end
