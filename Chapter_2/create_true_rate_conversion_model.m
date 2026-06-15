%% create_true_rate_conversion_model_v2.m
% True rate conversion model using LPF + Triggered Subsystem
% 240 kHz -> 48 kHz (factor 5)

model = 'true_rate_conversion_model';

if bdIsLoaded(model)
    close_system(model,0);
end

new_system(model);
open_system(model);

%% 기본 설정
set_param(model, ...
    'Solver','FixedStepDiscrete', ...
    'FixedStep','1', ...
    'StopTime','2000');

x0 = 50; dx = 150; y0 = 100;

%% 입력 신호 (240 kHz 가정)
add_block('simulink/Sources/Sine Wave',[model '/Input_240k'], ...
    'Position',[x0 y0 x0+90 y0+30], ...
    'Amplitude','1', ...
    'Frequency','0.01', ...
    'SampleTime','1');

add_block('simulink/Sources/Sine Wave',[model '/Tone2_240k'], ...
    'Position',[x0 y0+70 x0+90 y0+100], ...
    'Amplitude','0.5', ...
    'Frequency','0.04', ...
    'SampleTime','1');

add_block('simulink/Math Operations/Add',[model '/InputSum'], ...
    'Position',[x0+dx-30 y0+20 x0+dx y0+70], ...
    'Inputs','++');

add_line(model,'Input_240k/1','InputSum/1');
add_line(model,'Tone2_240k/1','InputSum/2');

%% LPF_5tap 서브시스템
add_block('simulink/Ports & Subsystems/Subsystem',[model '/LPF_5tap'], ...
    'Position',[x0+dx y0-20 x0+dx+180 y0+80]);

subsys = [model '/LPF_5tap'];

try
    delete_line(subsys,'In1/1','Out1/1');
catch
end

set_param([subsys '/In1'],'Position',[30 48 60 62]);
set_param([subsys '/Out1'],'Position',[520 48 550 62]);

% Delay blocks
for k = 1:4
    add_block('simulink/Discrete/Unit Delay',[subsys '/D' num2str(k)], ...
        'Position',[100+80*(k-1) 20 150+80*(k-1) 45], ...
        'SampleTime','1');
end

% Gain blocks (0.2)
for k = 0:4
    add_block('simulink/Math Operations/Gain',[subsys '/G' num2str(k)], ...
        'Position',[100+80*k 90 140+80*k 115], ...
        'Gain','0.2');
end

% Add blocks
for k = 1:4
    add_block('simulink/Math Operations/Add',[subsys '/Add' num2str(k)], ...
        'Position',[190+120*(k-1) 140 220+120*(k-1) 180], ...
        'Inputs','++');
end

% Wiring delay chain
add_line(subsys,'In1/1','D1/1');
add_line(subsys,'D1/1','D2/1');
add_line(subsys,'D2/1','D3/1');
add_line(subsys,'D3/1','D4/1');

% Tap connections
add_line(subsys,'In1/1','G0/1');
add_line(subsys,'D1/1','G1/1');
add_line(subsys,'D2/1','G2/1');
add_line(subsys,'D3/1','G3/1');
add_line(subsys,'D4/1','G4/1');

% Sum tree
add_line(subsys,'G0/1','Add1/1');
add_line(subsys,'G1/1','Add1/2');
add_line(subsys,'G2/1','Add2/1');
add_line(subsys,'G3/1','Add2/2');
add_line(subsys,'Add1/1','Add3/1');
add_line(subsys,'Add2/1','Add3/2');
add_line(subsys,'Add3/1','Add4/1');
add_line(subsys,'G4/1','Add4/2');
add_line(subsys,'Add4/1','Out1/1');

%% LPF 연결
add_line(model,'InputSum/1','LPF_5tap/1');

%% 5샘플마다 한 번 trigger 생성
add_block('simulink/Sources/Pulse Generator',[model '/Pulse5'], ...
    'Position',[x0+2*dx y0+120 x0+2*dx+100 y0+150], ...
    'Amplitude','1', ...
    'Period','5', ...
    'PulseWidth','20', ...
    'SampleTime','1');

%% Triggered Subsystem (실제 1/5 rate 실행)
add_block('simulink/Ports & Subsystems/Triggered Subsystem',[model '/Rate48k'], ...
    'Position',[x0+3*dx y0-10 x0+3*dx+180 y0+90]);

trsub = [model '/Rate48k'];

% 내부 기본선 제거
try
    delete_line(trsub,'In1/1','Out1/1');
catch
end

set_param([trsub '/In1'],'Position',[30 38 60 52]);
set_param([trsub '/Out1'],'Position',[150 38 180 52]);

% 내부에 Register 하나
add_block('simulink/Discrete/Unit Delay',[trsub '/Reg'], ...
    'Position',[85 38 115 52], ...
    'SampleTime','-1');

add_line(trsub,'In1/1','Reg/1');
add_line(trsub,'Reg/1','Out1/1');

%% Triggered Subsystem 연결
add_line(model,'LPF_5tap/1','Rate48k/1');
add_line(model,'Pulse5/1','Rate48k/Trigger');

%% Scope
add_block('simulink/Sinks/Scope',[model '/Scope_240k'], ...
    'Position',[x0+4*dx+80 y0-30 x0+4*dx+160 y0], ...
    'NumInputPorts','1');

add_block('simulink/Sinks/Scope',[model '/Scope_48k'], ...
    'Position',[x0+4*dx+80 y0+50 x0+4*dx+160 y0+80], ...
    'NumInputPorts','1');

add_line(model,'InputSum/1','Scope_240k/1');
add_line(model,'Rate48k/1','Scope_48k/1');

%% To Workspace
add_block('simulink/Sinks/To Workspace',[model '/ToWs_240k'], ...
    'Position',[x0+4*dx y0-30 x0+4*dx+70 y0], ...
    'VariableName','sig_240k', ...
    'SaveFormat','Array');

add_block('simulink/Sinks/To Workspace',[model '/ToWs_48k'], ...
    'Position',[x0+4*dx y0+50 x0+4*dx+70 y0+80], ...
    'VariableName','sig_48k', ...
    'SaveFormat','Array');

add_line(model,'InputSum/1','ToWs_240k/1');
add_line(model,'Rate48k/1','ToWs_48k/1');

%% 저장
save_system(model);
open_system(model);

disp('Model created: true_rate_conversion_model.slx');
disp('This model demonstrates rate conversion using LPF + Triggered Subsystem.');
disp('Input is updated every sample, output is updated every 5 samples.');