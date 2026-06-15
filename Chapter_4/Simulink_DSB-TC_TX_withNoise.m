ts=1/4000;	fs=1/ts;
T1=0;		T2=2;
t=[T1:ts:T2-ts];
N=length(t);
f1=100;
m=sin(2*pi*f1*t);

fc=1000;
xc=cos(2*pi*fc*t);
a=0.85;
m_n=m/max(abs(m));
s_m=(1+a*m_n).*xc;

SNR=20; 
SNR_lin=10^(SNR/10);   
signal_power=norm(s_m(1:N))^2/N;
% power in normalized message
pmm=(norm(m(1:N))^2/N)/(max(abs(m)))^2;
eta=(a^2*pmm)/(1+a^2*pmm);
noise_power=eta*signal_power/SNR_lin;;
noise_std=sqrt(noise_power);
noise=noise_std*randn(1,length(s_m));
r=s_m+noise;
	