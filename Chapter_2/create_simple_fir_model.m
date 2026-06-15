
% create_simple_fir_model.m
% Programmatically creates a simple HDL-friendly FIR filter Simulink model.
% Model name: fir_model
%
% Usage:
%   1) Run this script in MATLAB.
%   2) The model 'fir_model' will be created and opened.
%   3) Save the model if desired.
%
% Notes:
%   - Uses simple HDL-friendly blocks:
%       Inport -> Unit Delay chain -> Gain blocks -> Sum -> Outport
%   - Coefficients are example values for a 3-tap FIR.
%   - All signals are discrete-time.
%   - After creation, you can generate HDL with:
%         hdlset_param('fir_model','TargetLanguage','Verilog');
%         makehdl('fir_model/FIR_Output');

model = 'fir_model';

if bdIsLoaded(model)
    close_system(model, 0);
end

new_system(model);
open_system(model);

x0 = 40;   dx = 110;
y0 = 120;

add_block('simulink/Sources/In1', [model '/Input'], ...
    'Position', [x0 y0 x0+30 y0+20]);

add_block('simulink/Discrete/Unit Delay', [model '/Delay1'], ...
    'Position', [x0+dx y0-40 x0+dx+60 y0-10], ...
    'SampleTime', '1');

add_block('simulink/Discrete/Unit Delay', [model '/Delay2'], ...
    'Position', [x0+2*dx y0-40 x0+2*dx+60 y0-10], ...
    'SampleTime', '1');

add_block('simulink/Math Operations/Gain', [model '/h0'], ...
    'Position', [x0+dx y0+40 x0+dx+60 y0+70], ...
    'Gain', '0.25');

add_block('simulink/Math Operations/Gain', [model '/h1'], ...
    'Position', [x0+2*dx y0+40 x0+2*dx+60 y0+70], ...
    'Gain', '0.5');

add_block('simulink/Math Operations/Gain', [model '/h2'], ...
    'Position', [x0+3*dx y0+40 x0+3*dx+60 y0+70], ...
    'Gain', '0.25');

add_block('simulink/Math Operations/Add', [model '/Sum'], ...
    'Position', [x0+4*dx y0+20 x0+4*dx+40 y0+100], ...
    'Inputs', '+++');

add_block('simulink/Sinks/Out1', [model '/FIR_Output'], ...
    'Position', [x0+5*dx y0+45 x0+5*dx+30 y0+65]);

add_line(model, 'Input/1', 'Delay1/1');
add_line(model, 'Delay1/1', 'Delay2/1');

add_line(model, 'Input/1', 'h0/1');
add_line(model, 'Delay1/1', 'h1/1');
add_line(model, 'Delay2/1', 'h2/1');

add_line(model, 'h0/1', 'Sum/1');
add_line(model, 'h1/1', 'Sum/2');
add_line(model, 'h2/1', 'Sum/3');

add_line(model, 'Sum/1', 'FIR_Output/1');

set_param(model, ...
    'Solver', 'FixedStepDiscrete', ...
    'FixedStep', '1', ...
    'StopTime', '100');

save_system(model);
open_system(model);

disp('Model created: fir_model.slx');
disp('To generate Verilog HDL, try:');
disp('  hdlset_param(''fir_model'',''TargetLanguage'',''Verilog'');');
disp('  makehdl(''fir_model/FIR_Output'');');
