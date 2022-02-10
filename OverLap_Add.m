
%Rekonstruisanje signala koriscenjem OLA sinteze

function recon = OverLap_Add(input,frameLen,hopLen,winName)

%Input je 2D matrica gde je svaka kolona matrice preklopljeni frameLen
%frameLen je broj odbiraka svakog preklopljenog frejma
%hopLen je pomeraj prozora

    L = size(input,2);
    %Rekonstruisana duzina
    recon_len = frameLen + (L - 1) * hopLen;
    recon = zeros(recon_len,1);
    %Odabir prozora
    window = windowChoice(winName,frameLen);
    
    for i = 1 : L
        recon(1 + (i - 1) * hopLen : frameLen + (i - 1) * hopLen) = recon(1 + (i - 1) * hopLen :frameLen+(i - 1) * hopLen) + (input(:, i));
    end
    
    E = sum(window .* window);                  
    recon = recon .* hopLen/E;  %Rekonstruisani signal
                                      
end
   

    
            
    



