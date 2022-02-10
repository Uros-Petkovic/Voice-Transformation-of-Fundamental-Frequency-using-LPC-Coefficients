function lsf = lpc2lsf(a)
%Konverzija LPC koeficijenata u Line Spectral Pairs 
%'a' je 2D matrica gde je svaka kolona LPC koeficijenti svakog frejma
%'lsf' je 2D matrice gde je svaka kolona LSF parametri svakog frejma

	lsf = zeros(size(a,1) - 1,size(a,2));

	for i = 1 : size(a,2)
		lsf(:,i) = poly2lsf(a(:,i));
	end

end
