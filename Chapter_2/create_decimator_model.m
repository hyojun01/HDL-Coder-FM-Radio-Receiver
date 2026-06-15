%% create_decimator_model_v4.m
% HDL-friendly Decimator (Factor = 5)
% FIR도 직접 구성, Counter도 직접 구성
% Enabled Subsystem 대신 Switch 사용

model = 'decimator_model';

if bdIsLoaded(model)
    close_system(model,0);
end

new_system(model);
open_system(model);

%% 기본 설정
set_param(model,'Solver','FixedStepDiscrete', ...
    'FixedStep','1', ...
    'StopTime','1000');

x0 = 50; dx = 140; y0 = 100;

%% 입력 신호
add_block('simulink/Sources/Sine Wave',[model '/Input'], ...
    'Position',[x0 y0 x0+80 y0+30], ...
    'Frequency','0.01', ...
    'SampleTime','1');

%% LPF용 서브시스템 (5-tap moving average)
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
    add_block('simulink/Math Operations/Gain', [subsys '/G' num2str(k)], ...
        'Position', [100+80*k 90 140+80*k 115], ...
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

%% -----------------------------
% Mod-5 Counter 직접 구현
%% -----------------------------
add_block('simulink/Discrete/Unit Delay',[model '/CountReg'], ...
    'Position',[x0+dx y0+140 x0+dx+50 y0+170], ...
    'SampleTime','1');

add_block('simulink/Math Operations/Add',[model '/AddOne'], ...
    'Position',[x0+2*dx-20 y0+140 x0+2*dx+10 y0+180], ...
    'Inputs','++');

add_block('simulink/Sources/Constant',[model '/Const1'], ...
    'Position',[x0+dx y0+200 x0+dx+50 y0+220], ...
    'Value','1');

add_block('simulink/Logic and Bit Operations/Compare To Constant',[model '/IsFour'], ...
    'Position',[x0+2*dx+40 y0+135 x0+2*dx+110 y0+175], ...
    'const','4');

add_block('simulink/Sources/Constant',[model '/Const0'], ...
    'Position',[x0+2*dx+40 y0+200 x0+2*dx+90 y0+220], ...
    'Value','0');

add_block('simulink/Signal Routing/Switch',[model '/NextCount'], ...
    'Position',[x0+3*dx y0+135 x0+3*dx+50 y0+185], ...
    'Threshold','0.5');

% Feedback
add_line(model,'CountReg/1','AddOne/1');
add_line(model,'Const1/1','AddOne/2');
add_line(model,'CountReg/1','IsFour/1');

% Switch inputs:
% u1 = count+1, u2 = control, u3 = 0
add_line(model,'AddOne/1','NextCount/1');
add_line(model,'IsFour/1','NextCount/2');
add_line(model,'Const0/1','NextCount/3');

add_line(model,'NextCount/1','CountReg/1');

%% Compare count == 0  (output select)
add_block('simulink/Logic and Bit Operations/Compare To Constant',[model '/IsZero'], ...
    'Position',[x0+3*dx+90 y0+135 x0+3*dx+160 y0+175], ...
    'const','0');

add_line(model,'CountReg/1','IsZero/1');

%% Output switch
% If count==0 -> pass LPF output, else output zero
add_block('simulink/Sources/Constant',[model '/ZeroOut'], ...
    'Position',[x0+4*dx y0+120 x0+4*dx+60 y0+140], ...
    'Value','0');

add_block('simulink/Signal Routing/Switch',[model '/OutputSwitch'], ...
    'Position',[x0+4*dx y0 x0+4*dx+60 y0+60], ...
    'Threshold','0.5');

%% Scope
add_block('simulink/Sinks/Scope',[model '/Scope'], ...
    'Position',[x0+5*dx y0 x0+5*dx+80 y0+30]);

%% Top-level wiring
add_line(model,'Input/1','LPF_5tap/1');

% OutputSwitch: u1 = LPF output, u2 = control(IsZero), u3 = 0
add_line(model,'LPF_5tap/1','OutputSwitch/1');
add_line(model,'IsZero/1','OutputSwitch/2');
add_line(model,'ZeroOut/1','OutputSwitch/3');

add_line(model,'OutputSwitch/1','Scope/1');

%% 저장
save_system(model);
open_system(model);

disp('Model created: decimator_model.slx');
disp('This model implements 5x decimation using:');
disp('LPF_5tap + mod-5 counter + compare + switch');