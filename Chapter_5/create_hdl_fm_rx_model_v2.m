% create_hdl_fm_rx_model_v2.m
% HDL-friendly noncoherent FM receiver example
% Version without FM Modulator Baseband block
%
% Top-level:
%   From Workspace (fm_in) -> ToFixedPoint -> FM_RX_Core -> Scope
%
% HDL target:
%   makehdl('fm_rx_model/FM_RX_Core')

model = 'fm_rx_model';

if bdIsLoaded(model)
    close_system(model, 0);
end

%% ------------------------------------------------------------
% 1. Create test FM waveform in MATLAB workspace
%% ------------------------------------------------------------
N = 2000;              % number of samples
n = (0:N-1).';         % sample index
fm = 0.01;             % message frequency (cycles/sample-ish for demo)
kf = 0.08;             % FM sensitivity

m = 0.8*sin(2*pi*fm*n);        % message tone
phi = cumsum(kf*m);            % integrate message
fm_sig = sin(2*pi*0.08*n + phi);  % real FM-like signal

% Put in workspace as timeseries-like array
fm_in = [n fm_sig];
assignin('base','fm_in',fm_in);

%% ------------------------------------------------------------
% 2. Create model
%% ------------------------------------------------------------
new_system(model);
open_system(model);

set_param(model, ...
    'Solver', 'FixedStepDiscrete', ...
    'FixedStep', '1', ...
    'StopTime', '2000');

%% ------------------------------------------------------------
% 3. Top-level blocks
%% ------------------------------------------------------------
x0 = 40; dx = 160; y0 = 120;

add_block('simulink/Sources/From Workspace', [model '/FM_Input'], ...
    'Position', [x0 y0 x0+100 y0+30], ...
    'VariableName', 'fm_in');

add_block('simulink/Signal Attributes/Data Type Conversion', [model '/ToFixedPoint'], ...
    'Position', [x0+dx y0 x0+dx+100 y0+30], ...
    'OutDataTypeStr', 'fixdt(1,16,14)');

add_block('simulink/Ports & Subsystems/Subsystem', [model '/FM_RX_Core'], ...
    'Position', [x0+2*dx y0-30 x0+2*dx+180 y0+70]);

add_block('simulink/Sinks/Scope', [model '/Scope'], ...
    'Position', [x0+4*dx y0 x0+4*dx+80 y0+30]);

add_line(model, 'FM_Input/1', 'ToFixedPoint/1', 'autorouting', 'on');
add_line(model, 'ToFixedPoint/1', 'FM_RX_Core/1', 'autorouting', 'on');
add_line(model, 'FM_RX_Core/1', 'Scope/1', 'autorouting', 'on');

%% ------------------------------------------------------------
% 4. Build FM_RX_Core
%% ------------------------------------------------------------
subsys = [model '/FM_RX_Core'];

try
    delete_line(subsys, 'In1/1', 'Out1/1');
catch
end

set_param([subsys '/In1'], 'Position', [35 138 65 152]);
set_param([subsys '/Out1'], 'Position', [980 138 1010 152]);

% Differentiator: y[n] = x[n] - x[n-1]
add_block('simulink/Discrete/Unit Delay', [subsys '/DiffDelay'], ...
    'Position', [110 50 170 80], ...
    'SampleTime', '1');

add_block('simulink/Math Operations/Add', [subsys '/DiffSub'], ...
    'Position', [220 120 250 160], ...
    'Inputs', '+-');

% Absolute value
add_block('simulink/Math Operations/Abs', [subsys '/Abs'], ...
    'Position', [300 125 340 155]);

% 4-tap moving-average LPF
add_block('simulink/Discrete/Unit Delay', [subsys '/LPF_D1'], ...
    'Position', [390 30 450 60], ...
    'SampleTime', '1');

add_block('simulink/Discrete/Unit Delay', [subsys '/LPF_D2'], ...
    'Position', [500 30 560 60], ...
    'SampleTime', '1');

add_block('simulink/Discrete/Unit Delay', [subsys '/LPF_D3'], ...
    'Position', [610 30 670 60], ...
    'SampleTime', '1');

add_block('simulink/Math Operations/Add', [subsys '/LPF_Add1'], ...
    'Position', [500 110 530 150], ...
    'Inputs', '++');

add_block('simulink/Math Operations/Add', [subsys '/LPF_Add2'], ...
    'Position', [640 110 670 150], ...
    'Inputs', '++');

add_block('simulink/Math Operations/Add', [subsys '/LPF_Add3'], ...
    'Position', [760 110 790 150], ...
    'Inputs', '++');

add_block('simulink/Math Operations/Gain', [subsys '/LPF_Gain'], ...
    'Position', [840 122 900 152], ...
    'Gain', '0.25');

% DC blocker: y[n] = x[n] - x[n-1] + a*y[n-1]
add_block('simulink/Discrete/Unit Delay', [subsys '/DC_xDelay'], ...
    'Position', [840 220 900 250], ...
    'SampleTime', '1');

add_block('simulink/Discrete/Unit Delay', [subsys '/DC_yDelay'], ...
    'Position', [840 300 900 330], ...
    'SampleTime', '1');

add_block('simulink/Math Operations/Gain', [subsys '/DC_a'], ...
    'Position', [915 300 975 330], ...
    'Gain', '0.99');

add_block('simulink/Math Operations/Add', [subsys '/DC_Sub'], ...
    'Position', [920 210 950 250], ...
    'Inputs', '+-');

add_block('simulink/Math Operations/Add', [subsys '/DC_Add'], ...
    'Position', [980 120 1010 160], ...
    'Inputs', '++');

%% ------------------------------------------------------------
% 5. Wiring
%% ------------------------------------------------------------
add_line(subsys, 'In1/1', 'DiffDelay/1', 'autorouting', 'on');
add_line(subsys, 'In1/1', 'DiffSub/1', 'autorouting', 'on');
add_line(subsys, 'DiffDelay/1', 'DiffSub/2', 'autorouting', 'on');

add_line(subsys, 'DiffSub/1', 'Abs/1', 'autorouting', 'on');

add_line(subsys, 'Abs/1', 'LPF_D1/1', 'autorouting', 'on');
add_line(subsys, 'LPF_D1/1', 'LPF_D2/1', 'autorouting', 'on');
add_line(subsys, 'LPF_D2/1', 'LPF_D3/1', 'autorouting', 'on');

add_line(subsys, 'Abs/1', 'LPF_Add1/1', 'autorouting', 'on');
add_line(subsys, 'LPF_D1/1', 'LPF_Add1/2', 'autorouting', 'on');
add_line(subsys, 'LPF_D2/1', 'LPF_Add2/1', 'autorouting', 'on');
add_line(subsys, 'LPF_D3/1', 'LPF_Add2/2', 'autorouting', 'on');
add_line(subsys, 'LPF_Add1/1', 'LPF_Add3/1', 'autorouting', 'on');
add_line(subsys, 'LPF_Add2/1', 'LPF_Add3/2', 'autorouting', 'on');
add_line(subsys, 'LPF_Add3/1', 'LPF_Gain/1', 'autorouting', 'on');

add_line(subsys, 'LPF_Gain/1', 'DC_xDelay/1', 'autorouting', 'on');
add_line(subsys, 'LPF_Gain/1', 'DC_Sub/1', 'autorouting', 'on');
add_line(subsys, 'DC_xDelay/1', 'DC_Sub/2', 'autorouting', 'on');

add_line(subsys, 'DC_yDelay/1', 'DC_a/1', 'autorouting', 'on');
add_line(subsys, 'DC_Sub/1', 'DC_Add/1', 'autorouting', 'on');
add_line(subsys, 'DC_a/1', 'DC_Add/2', 'autorouting', 'on');

add_line(subsys, 'DC_Add/1', 'DC_yDelay/1', 'autorouting', 'on');
add_line(subsys, 'DC_Add/1', 'Out1/1', 'autorouting', 'on');

%% ------------------------------------------------------------
% 6. HDL parameter
%% ------------------------------------------------------------
try
    hdlset_param(model, 'TargetLanguage', 'Verilog');
    hdlset_param(subsys, 'FlattenHierarchy', 'off');
catch
end

save_system(model);
open_system(model);

disp('Model created: fm_rx_model.slx');
disp('Generate HDL with:');
disp('  open_system(''fm_rx_model'');');
disp('  hdlset_param(''fm_rx_model'',''TargetLanguage'',''Verilog'');');
disp('  makehdl(''fm_rx_model/FM_RX_Core'');');