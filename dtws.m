
function[dw_target, dw_source, p, q] = dtws(d_target,d_source)

%Dyinamic Time Warping predstavlja neku vrstu dinamickog vremenskog savijanja
%na LPC koeficijentima source i target govornih signala


    M = simmx(d_target,d_source); %Racunam euklidsku distancu za sve
    [p,q] = dp(1 - M); %Racunanje nove D matrice na osnovu formule za DTW algoritam

    dt_lsp = lpc2lsf(d_target);   %Prebacivanje iz LPC u LSF koeficijente radi stabilnosti
    ds_lsp = lpc2lsf(d_source);

    dt_lsp = dt_lsp';
    ds_lsp = ds_lsp';

    j = 2;
    pnew(1) = p(1);
    qnew(1) = q(1);
    %Poravnavanje signala na osnovu dobijenih indeksa
    for i = 2 : size(q,2)
        
      if(q(i) == q(i - 1))     %Ista kolona
        qnew(j) = q(i);
        pnew(j) = pnew(j - 1);
      elseif(p(i) == p(i - 1)) %ista vrsta
        qnew(j) = qnew(j - 1);
        pnew(j) = p(i);
      else
        qnew(j) = q(i);
        pnew(j) = p(i);
      end
      
      j = j + 1;
      
    end

    pnew = unique(pnew); %Sortirani niz bez ponavljanja
    qnew = unique(qnew);

    for i = 1 : length(qnew)
      dw_source(i,:) = ds_lsp(qnew(i),:);
    end

    for i = 1 : length(pnew)
      dw_target(i,:) = dt_lsp(pnew(i),:);
    end

    p = pnew;
    q = qnew;
    
    dw_source = dw_source';
    dw_target = dw_target';
end

function M = simmx(A,B)  

    EA = sqrt(sum(A.^2));  %Racunanje eukildske distance za sve
    EB = sqrt(sum(B.^2));

    M = (A'*B)./(EA'*EB); 

end

function [p,q,D] = dp(M)

    [r,c] = size(M);  %Dimenzije matrice
    %Padding matrice sa leve i gornje strane
    D = zeros(r+1, c+1);
    D(1,:) = NaN; %Postavljeno na veliku vrednost kako ga ne bi uzeo kao minimum
    D(:,1) = NaN;
    D(1,1) = 0;
    D(2:(r+1), 2:(c+1)) = M;
    %Pomocana matrica
    phi = zeros(r,c);
    %Prolazim kroz matricu
    for i = 1 : r
      for j = 1 : c
        [dmax, tb] = min([D(i, j), D(i, j+1), D(i+1, j)]); %Nalazim minimum datog elementa i sledeca 2 oko njega
        D(i + 1,j + 1) = D(i + 1,j + 1) + dmax; %Dodajem pronadjeni minimum
        phi(i,j) = tb;  %Indeks minimuma
      end
    end

    i = r; 
    j = c;
    p = i;
    q = j;
    while (i > 1 && j > 1)
        
      tb = phi(i,j);
      if (tb == 1)
        i = i - 1;
        j = j - 1;
      elseif (tb == 2)
        i = i - 1;
      elseif (tb == 3)
        j = j - 1;
      else    
        error;
      end
      
      p = [i,p];
      q = [j,q];
      
    end

    D = D(2:(r+1),2:(c+1));
    
end





