%% Diplomski rad na temu Transformacija govora na osnovu promene fundamentalne ucestanosti

% Student: Uros Petkovic 2016/0186

clear; clc; close all;

%% Pripremna faza

training = input('Uneti 1 za treniranje novog modela, 0 za koriscenje istreniranog modela : '); 
method = input('Uneti metod konverzije {''Method 1'', ''Method 2'', ''Default''} : '); 
lpcOrder = input('Uneti zeljeni broj LPC koeficijenata {16/20/24/''Default''} : ');
winName = "hann"; %Tip prozora sa kojim se radi, Hanning window
numTrainSamples = 50; % Broj odbiraka za treniranje
preemphasise = 0; %Ako je jednaka 1, radi se komepenzacija radijacije na usnama

%Ulazimo u treniranje ako je ispunjen uslov za treniranje
if(training)
    
    fprintf("\nIzaberi direktorijum za source trening skup\n"); %Bira trazeni folder source trening skupa
    dname_source = uigetdir;  %Uzima folder
    temp = find(dname_source == '\');
    nme_source = dname_source(temp(end) + 1 : end);
    fprintf(nme_source + " " + "izabran\n");
    files_source = dir(dname_source);
    fileIndex_source = find(~[files_source.isdir]);

    fprintf("Izaberi direktorijum za target trening skup\n"); %Bira trazeni folder target trening skupa
    dname_target = uigetdir;  %Uzima folder
    temp = find(dname_target == '\');
    nme_target = dname_target(temp(end) + 1 : end);
    fprintf(nme_target + " " + "izabran\n");
    files_target = dir(dname_target);
    fileIndex_target = find(~[files_target.isdir]);

    l_t = []; %Matrica za skladistenje trening podataka za LSF mapiranje
    l_s = [];
    F0_s = []; %Niz procenjenih pitch perioda za svaki par trening source skupa 
    F0_t = []; %Niz procenjenih pitch perioda za svaki par trening target skupa 
    
    %Biranje broja LPC koeficijenata na osnovu tipa konverzije i trening
    %skupova ako je zadata Default komanda 
    if(strcmp(lpcOrder,'Default'))
        if(strcmp(nme_source,'BDL'))
            lpcOrder = 16;  %Source je muski glas
        elseif(strcmp(nme_source,'SLT'))
            lpcOrder = 20;  %Source je zenski glas
        else
            lpcOrder = 24;
        end
    end
    
    %Biranje metoda ako je zadata Default komanda
    if(strcmp(method,'Default'))
        if(strcmp(nme_source,'BDL'))
            method = 'Method 1';
        else
            method = 'Method 2';
        end
    end

    switch lpcOrder %Broj neurona u skrivenom sloju na osnovu broja LPC koeficijenata
        case 16
            numHiddenNeurons = 27;
        case 20
            numHiddenNeurons = 34;
        case 24 
            numHiddenNeurons = 50;
        otherwise
            numHiddenNeurons = 50;
    end

    %% Trening faza

    for k = 1 : numTrainSamples %toliko parova
        
        %Ucitavanje source i target signala
        [source,fs_source] = audioread(strcat(dname_source,'\',files_source(fileIndex_source(k)).name)); %Ucitavanje source signala
        [target,fs_target] = audioread(strcat(dname_target,'\',files_target(fileIndex_target(k)).name)); %Ucitavanja target signala
        
        %Metod 2,promena celokupnog signala(pitch frekvencije i vokalnog trakta),Metod 1, promena pitch
        %frekvencije
        if(strcmp(method,'Method 2'))           
            [~,~,f0s,~] = Pitch_estimation(source,fs_source); %Estimacija pitch frekvencije za svaki ulazni par source trening skupa
            [~,~,f0t,~] = Pitch_estimation(target,fs_target); %Estimacija pitch frekvencije za svaki ulazni par target trening skupa
            sf = f0t/f0s; %Skala faktor za modifikaciju pitch periode
            [status,result] = system('delete_temp.bat'); %PSOLA algoritam za mapiranje pitch frekvencije source na target
            audiowrite('temp.wav',source,fs_source);
            %Staviti PSOLA2 u funkciji system za treniranje sa zenskog na
            %muski glas
            [status,result] = system('Praat.exe --run PSOLA.praat');
            [source,~] = audioread('temp_1.wav');
        end
        
        frameLen = floor(fs_source * 0.030); %Duzina prozora 
        hopLen = floor(fs_source * 0.010);  %Skok prozora
    
        %% Odredjivanje obelezja

        [a_source,g_source,r_source] = LPC_analiza(source,fs_source,lpcOrder,frameLen,hopLen,winName,preemphasise); 
        [a_target,g_target,r_target] = LPC_analiza(target,fs_target,lpcOrder,frameLen,hopLen,winName,preemphasise);

        [lsf_target,lsf_source,~,~] = dtws(a_target,a_source); 
        %LPC koeficijenti svakog frejma konvertovani su u LSF parametre
        %radi bolje stabilnosti nakon mapiranja i vremenskog poravnanja
        %koriscenjem DTWS
        
        %OLA-OverLap Add Method
        %Signali eksitacije source i target govornih signala rekonstruisani
        %su koriscenjem OLA metoda
        if(strcmp(method,'Method 1'))
            resi_source = OverLap_Add(r_source,frameLen,hopLen,winName);
            resi_target = OverLap_Add(r_target,frameLen,hopLen,winName);
            %Kompenzacija radijacije na usnama
            if(preemphasise == 1)
                resi_source = filter(1,[1 -0.9375],resi_source);
                resi_target = filter(1,[1 -0.9375],resi_target);
            end
    
            [~,~,f0s,~] = Pitch_estimation(resi_source,fs_source); %Estimacija pitch periode
            [~,~,f0t,~] = Pitch_estimation(resi_target,fs_target); 
        end
        %Smestanje trening LPC koeficijenata i estimacija pitch periode u
        %vektor
        l_s = [l_s lsf_source];
        l_t = [l_t lsf_target];

        F0_s = [F0_s f0s];  %Source procene pitch periode
        F0_t = [F0_t f0t];  %Target procene pitch periode
        
    end

    % Neural Network Training 

    netLSF = newff(l_s,l_t,numHiddenNeurons); %Feedforward NN sa 1 skrivenim slojem od 50 neurona
    netLSF.trainFcn = 'trainscg'; 
    netLSF.trainParam.max_fail = 100000; %Max Number of validation failures
    netLSF.trainParam.epochs = 100000; %Max Number. of Epochs tokom Backpropagation
    netLSF.trainParam.time = 420; %Vreme trajanja je 7 minuta
    netLSF = train(netLSF,l_s,l_t,'UseGPU','yes');
    
else    %Ako ne zelimo treniranje, biramo zeljeni trenirani model iz foldera
    fprintf("\nIzaberi istrenirani model\n");
    [file,path] = uigetfile('*.mat');
    load(fullfile(path,file));
end

%% Test faza

%Bira se source test signal za testiranje
fprintf("Izaberi fajl za testiranje\n");
[file,path] = uigetfile('*.wav');
[test,fs_test] = audioread(fullfile(path,file));
temp = find(path == '\');
nme_test = path(temp(end - 1) + 1 : temp(end) - 1);

frameLen = floor(0.030 * fs_test); %Prozor
hopLen = floor(0.010 * fs_test);   %Korak prozora

if(strcmp(lpcOrder,'Default'))  %Izbor broja LPC koeficijenata
    if(strcmp(nme_test,'BDL'))
        lpcOrder = 16;
    elseif(strcmp(nme_test,'SLT'))
        lpcOrder = 20;
    else
        lpcOrder = 24;
    end
end

if(strcmp(method,'Default'))   %Izbor podrazumevanog metoda
    if(strcmp(nme_test,'BDL'))
        method = 'Method 1';
    else
        method = 'Method 2';
    end
end

%% Prikaz ulaznos signala u vremenskom domenu
N=1:length(test);
t=N/fs_test;
figure();
plot(t,test);
xlabel('Vreme[s]');
ylabel('Amplituda signala');
title('Ulazni signal u vremenskom domenu');
axis([1 length(test)/fs_test -0.6 0.6]);
hold on

%% Prikaz radijacije na usnama
ru = filter([1 -0.9375],1,test);
plot(t,ru);
xlabel('Vreme[s]');
ylabel('Amplituda signala');
title('Ulazni signal i kompenzacija radijacije na usnama vremenskom domenu');
axis([1 length(test)/fs_test -0.6 0.6]);


%% SGS ulaznog govornog signala
Pxx_LPC1=pyulear(test,lpcOrder);
figure();
plot(Pxx_LPC1);
%% Ako je metod 2, procena ucestanosti na celom signalu i PSOLA algoritam
if(strcmp(method,'Method 2'))
    %Pitch Modification
    [~,~,f0s,~] = Pitch_estimation(test,fs_test); 
    f0t = logLinearTransform(F0_s,F0_t,f0s); %Pronalazenje target pitch frekvencije
    sf = f0t/f0s; %Skala faktor

    [status,result] = system('delete_temp.bat'); 
    audiowrite('temp.wav',test,fs_test);
    %[status,result] = system("Praat.exe --run PSOLA.praat" + " " + sf);
    [status,result] = system('Praat.exe --run PSOLA.praat');
    [test,~] = audioread('temp_1.wav');
end
%LPC analiza signala i konvertovanje u LSF koeficijente    
[a_test,g_test,r_test] = LPC_analiza(test,fs_test,lpcOrder,frameLen,hopLen,winName,preemphasise);
lsf_test = lpc2lsf(a_test);
lsf_morph = zeros(size(lsf_test));  %Niz za prediktovane LSF koeficijente
%% Prikaz rezidualnog dela signala
Nproz=1:length(r_test(:,150));
t=Nproz/fs_test;
figure();
plot(t,r_test(:,100));
xlabel('Vreme[s]');
ylabel('Amplituda signala');
title('Rezidualni deo signala na jednom prozoru u vremenskom domenu');

%%  Prikaz LPC koeficijenata
Nproz=1:281;

for i=2:25
    
    figure(1);
    plot(Nproz,a_test(i,:));
    hold on;
end
xlabel('Broj prozora');
ylabel('Amplituda koeficijenta');
title('LPC koeficijenti u vremenskom domenu');
axis([1 281 -8 10]);
hold off

%%  Prikaz LSF koeficijenata
Nproz=1:281;
alsf=lpc2lsf(a_test);
for i=1:24
    
    figure(1);
    plot(Nproz,alsf(i,:));
    hold on;
end
xlabel('Broj prozora');
ylabel('Amplituda koeficijenta');
title('LSF koeficijenti u vremenskom domenu');
axis([1 281 0 3.1]);
hold off


%% Predikcija LSF koeficijenata uz pomoc neuralne mreze
for i = 1 : size(lsf_test,2)
    lsf_morph(:,i) = netLSF(lsf_test(:,i)); %Trenirani model
end

a_morph = lsf2lpc(lsf_morph); %Konverzija nazad u LPC koeficijente
%a_morph = coeff_interpolate(a_morph); %Da napravi glatke prelaze
%% Prikaz prediktovanih LSF koeficijenata
for i=1:24
    
    figure(1);
    plot(Nproz,lsf_morph(i,:));
    hold on;
end
xlabel('Broj prozora');
ylabel('Amplituda koeficijenta');
title('Prediktovani LSF koeficijenti u vremenskom domenu');
axis([1 281 0 3.1]);
hold off


%% Prikaz prediktovanih LPC koeficijenata

for i=2:25
    
    figure(1);
    plot(Nproz,a_morph(i,:));
    hold on;
end
xlabel('Broj prozora');
ylabel('Amplituda koeficijenta');
title('Prediktovani LPC koeficijenti u vremenskom domenu');
axis([1 281 -8 10]);
hold off


%% Ako je metod 1, onda procena ucestanosti i PSOLA algoritam tek sad
if(strcmp(method,'Method 1'))
    %Pitch Modifikacija
    resi_test = OverLap_Add(r_test,frameLen,hopLen,winName); 
    if(preemphasise == 1)
        resi_test = filter(1,[1 -0.9375],resi_test);
    end
    [~,~,f0s,~] = Pitch_estimation(resi_test,fs_test);
    f0t = logLinearTransform(F0_s,F0_t,f0s); %Estimacija pitch frekvencije zeljenog signala
    sf = f0t/f0s; %Skala faktor

    resi_test = resi_test ./ (max(abs(resi_test) + 0.01));
    [status,result] = system('delete_temp.bat'); 
    audiowrite('temp.wav',resi_test,fs_test);
    %Napisati PSOLA2 za testiranje sa zenskog na muski
    [status,result] = system('Praat.exe --run PSOLA.praat'); 
    [resi_morph,~] = audioread('temp_1.wav'); %Citanje dobijenog signala
    if(preemphasise == 1)
        resi_morph = filter([1 -0.9375],1,resi_morph); %Radijacija na usnama
    end

    %Rekonstrukcija govora
    %LPC sinteza signala
    r_morph = segmnt(resi_morph,frameLen,hopLen);
    %Izbor prozora
    window = windowChoice(winName,frameLen);
    r_morph = r_morph .* repmat(window,1,size(r_morph,2));
    morph = LPC_sinteza(a_morph,g_test,r_morph,fs_test,frameLen,hopLen,winName,preemphasise); %Rekonstrukcija transformisanog govora LPC sintezom
else
    morph = LPC_sinteza(a_morph,g_test,r_test,fs_test,frameLen,hopLen,winName,preemphasise);
end
%% Prikaz SGS polaznog i dobijenog signala
Pxx_LPC2=pyulear(morph,lpcOrder);
figure();
plot(Pxx_LPC1); hold on
plot(Pxx_LPC2);
axis([1 40 0 0.3]);
title('Periodogram');
xlabel('Frekvencija (Hz)')
ylabel('Spektralna gustina snage (dB/Hz)')
legend('Pocetni','Dobijeni');
%% Ucitavanje test zeljenog signala radi
[file,path] = uigetfile('*.wav');
[orig,fs_orig] = audioread(fullfile(path,file));
%% Prikaz SGS originalnog zeljenog signala i dobijenog
Pxx_LPC3=pyulear(orig,lpcOrder);
figure();
plot(Pxx_LPC2); hold on
plot(Pxx_LPC3);
axis([1 40 0 0.65]);
title('Periodogram');
xlabel('Frekvencija (Hz)')
ylabel('Spektralna gustina snage (dB/Hz)')
legend('Dobijeni','Originalni');

%% Prikaz polasnog i dobijenog signala u vremenskom domenu

figure();
plot(1:length(test),test);
xlabel('Odbirci');
ylabel('Amplituda');
title('Ulazni');
figure();
plot(1:length(morph),morph);
xlabel('Odbirci');
ylabel('Amplituda');
title('Dobijeni');
%% Prikaz originalnog signala u vremenskom domenu
figure();
plot(1:length(orig),orig);

%% Dodatno procesiranje

if(strcmp(method,'Method 2'))
    [~,~,f0s,~] = Pitch_estimation(morph,fs_test);
    sf = f0t/f0s; 
    
    morph = morph ./ (max(abs(morph)) + 0.01);
    [status,result] = system('delete_temp.bat');
    audiowrite('temp.wav',morph,fs_test);
    %Napisati PSOLA 3 za testiranje sa zenskog na muski
    [status,result] = system('Praat.exe --run PSOLA1.praat');
    [morph,~] = audioread('temp_1.wav');
end

morph = filter([1 -1],[1 -0.99],morph); %Filter out low-freq components
morph = filter([1 1],[1 0.99],morph); %Filter out high-freq noise
%% Preslusavanje signala i cuvanje
soundsc(morph,fs_test);
%audiowrite('Metod2FtoM.wav',morph,fs_test);


%% Samo pitch za zeljeni zenski

[~,~,f0s,~] = Pitch_estimation(test,fs_test); 
f0t = logLinearTransform(F0_s,F0_t,f0s); %Pronalazenje target pitch frekvencije
sf = f0t/f0s; %Skala faktor

[status,result] = system('delete_temp.bat'); 
audiowrite('temp.wav',test,fs_test);
%[status,result] = system("Praat.exe --run PSOLA.praat" + " " + sf);
[status,result] = system('Praat.exe --run PSOLA.praat');
[morphpitch,~] = audioread('temp_1.wav');
soundsc(morphpitch,fs_test);
audiowrite('SamoPitchMtoF.wav',morphpitch,fs_test);

%% Samo pitch za zeljeni muski

[~,~,f0s,~] = Pitch_estimation(test,fs_test); 
f0t = logLinearTransform(F0_s,F0_t,f0s); %Pronalazenje target pitch frekvencije
sf = f0t/f0s; %Skala faktor

[status,result] = system('delete_temp.bat'); 
audiowrite('temp.wav',test,fs_test);
%[status,result] = system("Praat.exe --run PSOLA.praat" + " " + sf);
[status,result] = system('Praat.exe --run PSOLA2.praat');
[morphpitch,~] = audioread('temp_1.wav');
soundsc(morphpitch,fs_test);
audiowrite('SamoPitchFtoM.wav',morphpitch,fs_test);
