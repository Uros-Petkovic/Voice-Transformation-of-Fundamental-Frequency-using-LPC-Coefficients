function a = lsf2lpc(lsf)

%Konvertuje LSF u LPC


	a = zeros(size(lsf,1)+1,size(lsf,2));

	for i = 1 : size(lsf,2)

		temp = lsf(:,i);
		temp = sort(abs(temp),'ascend'); %Pozitivni i u rastucem poretku
		replace = find(temp >= pi); %Provera je li neki od njih veci od pi

		if(~isempty(replace))      
            temp = temp ./ max(temp); %Ako su veci od pi,tu se zabodu,a izvrsimo normalizaciju od 0 do pi
            temp = temp .* pi;
        end
        
		temp = sort(abs(temp),'ascend');
		a(:,i) = lsf2poly(temp); 
		a(:,i) = polystab(a(:,i));
 
	end

end