function [t, f0, pitch_average, en] = Pitch_estimation(x, fs)

%Ova funkcija koristi autokorelacioni metod za estimaciju pitch periode

	N = length(x);  %Duzina signala
	srvr = mean(x); %Srednja vrednost
	x = x - srvr;   %Oduzimamo srednju vrednost od signala

	fRate = floor(120*fs/1000);   %Brojevi odbiraka u prozoru
	updRate = floor(110*fs/1000); %Brojevi odbiraka u prozoru, da bi se prozori malo preklapali
	num_frames = floor(N/updRate)-1; %Broj prozora

	f0 = zeros(1, num_frames);
	f01 = zeros(1, num_frames);

	k = 1;
	pitch_average = 0;
	m = 1;

	for i = 1 : num_frames

	  xproz = x(k : k + fRate - 1);   %Jedan prozor x signala
	  f01(i) = pcorr(fRate, fs, xproz); %Racuna se autokorelacija
	  en = ((x(1 : num_frames)) .^ 2);  %energija signala
	  
	  if (i > 2 && num_frames > 3) %Ako imamo vise od 2 procene radimo median dosadasnjih procena

	    z = f01(i - 2 : i); 
	    med = median(z);
	    f0(i - 2) = med;

	    if (med > 0)   %Ako je medijana veca od nule, racunamo srednju vrednost pitch periode
	      pitch_average = pitch_average + med;
	      m = m + 1;
	    end

	  elseif (num_frames <= 3) %Ako je broj prozora manji od 3
	    f0(i) = a;
	    pitch_average = pitch_average + a;
	    m = m + 1;
	  end

	  k = k + updRate;

	end

	t = 1 : num_frames;
	t = 20 * t;

	if (m == 1)
	  pitch_average = 0;
    else      %Racuna se srednja vrednost pitch frekvencije
	  pitch_average = pitch_average/(m - 1);
	end 

end

function [f0] = pcorr(len, fs, xproz)

    %Filtriranje signala
	[bf0, af0] = butter(4, 900/(fs/2));
	xproz = filter(bf0, af0, xproz); 
   
    %Podelimo prozor na 3 dela
	i13 = len/3;
    %Nadjemo max na prvom delu prozora
	maxi1 = max(abs(xproz(1 : i13)));
    %Nadjemo max na trecem delu prozora
	i23 = 2 * len/3;
	maxi2 = max(abs(xproz(i23 : len)));

	if (maxi1 > maxi2)   %Nalazimo prag za klipovanje tako sto uzimamo manji
	  CL = 0.68 * maxi2;
	else 
	  CL = 0.68 * maxi1;
    end
    
    %Vrsimo klipovanje signala
	clip = zeros(len,1);
    %Nalazimo one odbirke vece od praga CL
	ind1 = find(xproz >= CL);
	clip(ind1) = xproz(ind1) - CL;  %Upisujemo odbirke koji su veci od CL
    %Nalazimo one koji su manji od CL
	ind2 = find(xproz <= -CL);
	clip(ind2) = xproz(ind2)+CL;  %Upisujemo one koji su manji od CL

	engy = norm(clip,2)^2;

	RR = xcorr(clip);  %Racunamo autokorelaciju klipovanog signala
	m = len;
%     figure();
%     plot(1:length(RR),RR);
%     title('Autokorelacija signala');
%     xlabel('Odbirci');
%     ylabel('Vrednost autokorelacije');
	LF = floor(fs/320); %Min moze biti na ovom odbirku
	HF = floor(fs/60);  %Maks moze biti na ovom odbirku

	Rxx = abs(RR(m + LF : m + HF));
	[rmax, imax] = max(Rxx); %Nalazimo max autokorelacije

	imax = imax + LF; %Nalazimo indeks maksimuma autokorelacije
	f0 = fs/imax; %Pitch frekvencija predstavlja poziciju maksimuma

	tisina = 0.4*engy;  %Prag za tisinu

	if ((rmax > tisina)  && (f0 > 60) && (f0 <= 320)) %Ako nije tisina i f0 je u opsegu,upisi f0
	 f0 = fs/imax;
	else 
	 f0 = 0;
	end

end