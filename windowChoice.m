function win = windowChoice(inp,len)

%Ova funkcija vraca tip prozora duzine len u promenljivoj win
    
    if(inp == "hann")
        win = hann(len);
    elseif(inp == "hamm")
        win = hamming(len);
    elseif(inp == "gauss")
        win = gausswin(len);
    elseif(inp == "rect")
        win = rectwin(len);
    end
    
end