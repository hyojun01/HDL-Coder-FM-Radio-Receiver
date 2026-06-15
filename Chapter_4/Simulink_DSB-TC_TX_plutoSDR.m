[m, fs_audio]=audioread('music.wav');
fs_sdr=240e3;
m = resample (m', fs_sdr , fs_audio);
%soundsc(m, fs_sdr);

a=0.85;
m_n=m/max(abs(m));
s_m=(1+a*m_n);

N = length (m);
t = 0:(1/ fs):(N -1) *(1/ fs);
plot (t, real (s_m))

% frequency - domain plot
f = -fs /2:( fs/N):( fs /2 - fs/N);
plot (f ,20* log10 ( abs ( fftshift ( fft (s_m)))))	