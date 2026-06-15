% create_fir_core_model.m
% HDL generation-friendly FIR model with FIR_Core subsystem
%
% Creates:
%   fir_core_model.slx
%
% Top-level structure:
%   Sine Wave -> Data Type Conversion -> FIR_Core -> Scope
%
% FIR_Core internal structure:
%   In1 -> tap delays -> gains -> adders -> Out1
%
% After model creation, HDL can be generated with:
%   open_system('fir_core_model');
%   hdlset_param('fir_core_model','TargetLanguage','Verilog');
%   makehdl('fir_core_model/FIR_Core');

model = 'fir_core_model';

% Close existing model without saving
if bdIsLoaded(model)
    close_system(model, 0);
end

new_system(model);
open_system(model);

%% -------------------------------------------------
% Top-level model parameters
%% -------------------------------------------------
set_param(model, ...
    'Solver', 'FixedStepDiscrete', ...
    'FixedStep', '1', ...
    'StopTime', '100');

%% -------------------------------------------------
% Top-level blocks
%% -------------------------------------------------
x0 = 40; dx = 130; y0 = 120;

add_block('simulink/Sources/Sine Wave', [model '/Sine Wave'], ...
    'Position', [x0 y0 x0+60 y0+30], ...
    'Amplitude', '1', ...
    'Frequency', '0.05', ...      % rad/sample style is fine for demo
    'SampleTime', '1');

add_block('simulink/Signal Attributes/Data Type Conversion', ...
    [model '/ToFixedPoint'], ...
    'Position', [x0+dx y0 x0+dx+90 y0+30], ...
    'OutDataTypeStr', 'fixdt(1,16,14)');

add_block('simulink/Ports & Subsystems/Subsystem', [model '/FIR_Core'], ...
    'Position', [x0+2*dx y0-20 x0+2*dx+140 y0+60]);

add_block('simulink/Sinks/Scope', [model '/Scope'], ...
    'Position', [x0+4*dx y0 x0+4*dx+80 y0+30]);

% Top-level connections
add_line(model, 'Sine Wave/1', 'ToFixedPoint/1', 'autorouting', 'on');
add_line(model, 'ToFixedPoint/1', 'FIR_Core/1', 'autorouting', 'on');
add_line(model, 'FIR_Core/1', 'Scope/1', 'autorouting', 'on');

%% -------------------------------------------------
% Build FIR_Core internal structure
%% -------------------------------------------------
subsys = [model '/FIR_Core'];

% Remove default line and blocks if present
try
    delete_line(subsys, 'In1/1', 'Out1/1');
catch
end

% Keep default In1/Out1 but reposition
set_param([subsys '/In1'], 'Position', [40 98 70 112]);
set_param([subsys '/Out1'], 'Position', [510 153 540 167]);

% Add delays
add_block('simulink/Discrete/Unit Delay', [subsys '/Delay1'], ...
    'Position', [120 40 180 70], ...
    'SampleTime', '1');

add_block('simulink/Discrete/Unit Delay', [subsys '/Delay2'], ...
    'Position', [240 40 300 70], ...
    'SampleTime', '1');

% Add gains (3-tap FIR coefficients)
add_block('simulink/Math Operations/Gain', [subsys '/h0'], ...
    'Position', [130 140 190 170], ...
    'Gain', '0.25', ...
    'OutDataTypeStr', 'fixdt(1,18,14)');

add_block('simulink/Math Operations/Gain', [subsys '/h1'], ...
    'Position', [260 140 320 170], ...
    'Gain', '0.5', ...
    'OutDataTypeStr', 'fixdt(1,18,14)');

add_block('simulink/Math Operations/Gain', [subsys '/h2'], ...
    'Position', [390 140 450 170], ...
    'Gain', '0.25', ...
    'OutDataTypeStr', 'fixdt(1,18,14)');

% Add adders
add_block('simulink/Math Operations/Add', [subsys '/Add1'], ...
    'Position', [330 135 360 175], ...
    'Inputs', '++');

add_block('simulink/Math Operations/Add', [subsys '/Add2'], ...
    'Position', [455 148 485 188], ...
    'Inputs', '++');

%% -------------------------------------------------
% Internal wiring
%% -------------------------------------------------
% Delay chain
add_line(subsys, 'In1/1', 'Delay1/1', 'autorouting', 'on');
add_line(subsys, 'Delay1/1', 'Delay2/1', 'autorouting', 'on');

% Taps
add_line(subsys, 'In1/1', 'h0/1', 'autorouting', 'on');
add_line(subsys, 'Delay1/1', 'h1/1', 'autorouting', 'on');
add_line(subsys, 'Delay2/1', 'h2/1', 'autorouting', 'on');

% Sum tree
add_line(subsys, 'h0/1', 'Add1/1', 'autorouting', 'on');
add_line(subsys, 'h1/1', 'Add1/2', 'autorouting', 'on');
add_line(subsys, 'Add1/1', 'Add2/1', 'autorouting', 'on');
add_line(subsys, 'h2/1', 'Add2/2', 'autorouting', 'on');

% Output
add_line(subsys, 'Add2/1', 'Out1/1', 'autorouting', 'on');

%% -------------------------------------------------
% Optional HDL-related model settings
%% -------------------------------------------------
try
    hdlset_param(model, 'TargetLanguage', 'Verilog');
    hdlset_param(subsys, ...
        'Architecture', 'MATLAB Datapath', ...
        'FlattenHierarchy', 'off');
catch ME
    warning('HDL Coder parameter setup skipped: %s', ME.message);
end

%% -------------------------------------------------
% Add annotation
%% -------------------------------------------------
ann = sprintf(['3-tap fixed-point FIR example\\n' ...
    'y[n] = 0.25x[n] + 0.5x[n-1] + 0.25x[n-2]\\n' ...
    'HDL generation target: fir_core_model/FIR_Core']);
add_block('simulink/Notes/Note', [model '/Note']);
set_param([model '/Note'], ...
    'Position', [35 20 390 80], ...
    'Text', ann);

save_system(model);
open_system(model);

disp('Model created: fir_core_model.slx');
disp('Generate Verilog HDL with:');
disp('  open_system(''fir_core_model'');');
disp('  hdlset_param(''fir_core_model'',''TargetLanguage'',''Verilog'');');
disp('  makehdl(''fir_core_model/FIR_Core'');');