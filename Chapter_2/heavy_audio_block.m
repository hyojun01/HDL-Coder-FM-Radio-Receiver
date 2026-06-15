function y = heavy_audio_block(u)
%
y = u;

for k = 1:300
    y = y + 0.0001*u;
    y = y - 0.0001*u;
end