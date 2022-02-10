function synth = LPC_sinteza(alpha,G,resi,fs,frameLen,hopLen,winName,preemphasise)

%Radi LPC sintezu. 


    if nargin < 5
        frameLen = floor(fs * 0.040);
    end
    if nargin < 6
        hopLen = floor(fs * 0.020);
    end
    
    if nargin < 7
        winName = "hann";
    end
    if nargin < 8
        preemphasise = 1;
    end
    
    syn_frame = []; %Sadrzi finalni signal nakon sinteze
    
    for i = 1 : size(alpha,2)
        
        temp = filter(G(i),alpha(:,i),resi(:,i)); %Svaki frejm je rekonstruisan koriscenjem IIR LP Synthesis filter
        syn_frame = [syn_frame temp(:)];
        
    end
    
    synth = OverLap_Add(syn_frame,frameLen,hopLen,winName);
    
    %Kompenzacija radijacije na usnama
    
    if(preemphasise == 1)
        synth = filter(1,[1 -0.9375],synth); %Samo ako je uradjena Pre-Emphasise, koeficijenti su isti
    end

end
        