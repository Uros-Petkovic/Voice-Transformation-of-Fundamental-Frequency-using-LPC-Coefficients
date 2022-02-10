function f0c = logLinearTransform(f0s,f0t,f0)

%Ova funkcija koristi logaritamsku linearnu transformaciju za estimaciju
%pitch periode govornog signala na osnovu pitch perioda dobijenih iz
%trening seta i pitch perioda test signala

    g = find(f0s == 0);
    f0s(g) = [];
    f0t(g) = [];
    g = find(f0t == 0);
    f0s(g) = [];
    f0t(g) = [];
    
    f0s = log10(f0s); %Logaritamska raspodela
    f0t = log10(f0t);
    f0 = log10(f0);
    
    us = mean(f0s); %Estimacija statistickih parametara,srednja vrednost
    ss = std(f0s);  %Standardna devijacija
    
    ut = mean(f0t); %Takodje, isto
    st = std(f0t);
    
    if(ss == 0)
        ss = 1;
        st = 1;
    end
    
    f0c = ut + ((st/ss) * (f0 - us)); %Log Linear Transformation
    
    f0c = 10 ^ f0c;
    
end
    
    
    