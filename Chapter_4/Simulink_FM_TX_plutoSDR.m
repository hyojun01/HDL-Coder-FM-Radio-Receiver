[m, fs_audio]=audioread('music.wav');
fs_sdr=240e3;
m = resample (m', fs_sdr , fs_audio);
%soundsc(m, fs_sdr);
s_m=m;