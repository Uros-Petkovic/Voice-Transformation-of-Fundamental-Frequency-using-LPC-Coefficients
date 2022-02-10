function segmented = segmnt(x,frameLen,hopLen)

%Svaki frejm je kolona u vektoru segmented

    x = x(:);    
    xlen = length(x);
    L = 1 + fix((xlen - frameLen)/hopLen);
    
    segmented = [];
    for l = 0 : L - 1      
        xw = x(1 + l * hopLen : frameLen + l * hopLen);
        segmented = [segmented xw(:)];       
    end
    
end
    