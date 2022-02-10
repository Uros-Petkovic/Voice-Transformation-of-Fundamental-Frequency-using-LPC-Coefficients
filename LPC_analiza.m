function [alpha,G,resi] = LPC_analiza(x,fs,order,frameLen,hopLen,winName,preemphasise)

%Ova funkcija racuna LPC koeficijente signala x semplovanog na frekvenciji
%odabiranja fs. To su koeficijenti koji opisuju govorni signal AR modela sa
%polovima. Oni nose veliku informaciju o formantima i vokalnom traktu.
%'order' predstavlja red prediktora.
%'frameLen' opisuje duzinu prozora u odbircima, 'hopLen' 
%predstavlja pomeraj prozora, 'winName' tip prozora koji se koristi
%Svaka kolona 'alpha' sadrzi 'order' + 1 broj koeficijenata, svaka kolona 'G'
%sadrzi pojacanje prozora i svaka kolona 'resi' sadrzi
%residual/excitation signal svakog prozora
%'preemphasis' se koristi za odlucivanje je li potrebna Pre-Emphasis signala,
%if = 1, onda je potrebna

	if nargin < 3   %Podrazumevana vrednost za broj LPC koeficijenata
		order = 20;
	end
	if nargin < 4  %Podrazumevana vrednost za duzinu prozora
		frameLen = floor(fs * 0.040); %25ms
    end   
	if nargin < 5  %Podrazumevana vrednost za pomeraj prozora
		hopLen = floor(fs * 0.020); %Skok od 5ms
    end
    if nargin < 6   %Tip prozorske funkcije, Hamingova funkcija
        winName = "hann";
    end
    if nargin < 7   %Emphasis na 1 kao podrazumevana
        preemphasise = 1;
    end

    %Pre-Emphasis koristim ako je potrebna tako da kompenzuje uticaj
    %radijacije na usnama
    
    if(preemphasise == 1)        
        x = filter([1 -0.9375],1,x); %Filtriram signal
    end

	[x_buf,~] = buffer(x,frameLen,(frameLen - hopLen),'nodelay'); 
    %Pravljenje prozora ulaznog signala x uz pomoc bafera,svaka kolona
    %bafera sadrzi jedan prozor ulaznog signalaa
    
    %Biranje prozora
	window = windowChoice(winName,frameLen); %Prozor duzine frameLen 
    

	x_buf = x_buf .* repmat(window,1,size(x_buf,2)); %Prozorovanje svakog prozora radi izbegavanja
                                                     %efekta Gibsovih oscilacija

	alpha = []; 
	G = [];
	resi = [];

	for i = 1 : size(x_buf,2) %Prolazak kroz svaki prozor

		[a,g] = lpc(x_buf(:,i),order);
        %Racunanje LPC koeficijenata prozora zajedno sa snagom greske                               
	    
        clear isnan;
	    a(isnan(a)) = 0; %Oslobadjanje od beskonacnih vrednosti
	    g(isnan(g)) = 1;
	    g(find(g == 0)) = 1;

	   	g = sqrt(g);	
	   	r = filter(a,g,x_buf(:,i));
        %Rezidualni signal dobijen filtriranjem prozorovanog prozora uz
        %pomoc FIR filtra
	   	alpha(:,i) = a(:);
	   	G(i) = g;
	   	resi(:,i) = r(:);

	end

end
