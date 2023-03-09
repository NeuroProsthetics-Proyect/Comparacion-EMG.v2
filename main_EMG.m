%Comparación de EMG vs eRedi
clc; close all; clear;

%string con datos a ser comparados
str_datos=["Sujeto_1_21.02.23_Jesus.txt" "Sujeto_3_22.02.23_Maby.txt"...
    "Sujeto_2_22.02.23_Adriana.txt"];
str_short=["Jesus" "Maby" "Adriana"];
%str_datos=["Sujeto_2_22.02.23_Adriana.txt"];
Num_sujetos = length(str_datos);

results_array=[];
mean_results_array=[];

%%
%Ciclo que repite la extracción de datos
for k=1:Num_sujetos

    str_datos(k)

    %Extracción de datos
    %data = downsample(table2array(readtable(str_datos(k))),4);
    data = downsample(importfile(str_datos(k)),4);
    time=(0:1/500:(length(data)/500)-1/500)';
    data=cat(2,time,data);
    datax=[];
    datax=data(:,2);
    datay=[];
    datay=data(:,3);
    dataz=[];
    dataz=data(:,4);

    data(:,2) = dataz;
    data(:,3) = datax;
    data(:,4) = datay;

    %Filtrar datos de Biopac y EMG
    data(:,3) = bandpassfilt(20,150,500,8,data(:,3));
    data(:,4) = bandpassfilt(20,150,500,8,data(:,4));
    
    %Obtener valor maximo y nomalizar datos
    max_data = max(data);
    
    
    data(:,3) = data(:,3) / max_data(:,3);
    data(:,4) = data(:,4) / max_data(:,4);
    
    %Declarar vector de tiempo de 8 segundos
    t = (-3:1/500:5)';
    

    %%
    %Los triggers registran el mismo trigger varias veces con diferentes
    %niveles de voltaje, por lo cual se redondea el valor con la función 
    % "round" al entero mas cercano. 
    pulsos = round(data(:,2));
    
    %Se detectan los flancos de subida basado en la detección de rebotes. 
    detect_trig = [];
    for n = 2:length(pulsos)
     if (pulsos(n-1) < pulsos(n)) && (pulsos(n) == pulsos(n+1))
         detect_trig(n) = pulsos(n);
     end
    end
    
    % time = 0:1/500:length(detect_trig)/500 - 1/500;
    % plot(time,detect_trig)
    % title('Triggers ajustados para un solo dato.');
    % xlabel('Tiempo (sec)');
    % ylabel('Voltaje Trigger (mV)');
    
    
    finalTrigs = [];
    finalType = [];
    trig_pos = [];
    
    for value_trig = 15:5:40
    
        %Se busca el trigger de interes y todos los puntos relacionados 
        %en -2 y +2 del value trigger
        findData = find(detect_trig > value_trig-2 & ...
            detect_trig <= value_trig+2);
    %%    
        %Se ajusta el codigo para no repetir valores, haciendo que si hay una
        %diferencia entre el dato y el siguiente mayor a 100 no se copie en el
        %vector final de triggers y se asigna un NaN. 
        for n = 1:length(findData)-1
            if findData(n+1) - findData(n) >= 200
                trig_pos(n)=findData(n);
                %type(n) = value_trig;
            else
                trig_pos(n) = nan;
            end
            trig_pos(length(findData)) = findData(length(findData));
        end
        %Borra todas las celdas que contienen NaN y genera un vector Type que
        %guarde el tipo de trigger aplicado. 
        Triggers = rmmissing(trig_pos);
        Type(1:length(Triggers)) = value_trig;
    
        finalTrigs = cat(2,finalTrigs,Triggers);
        finalType = cat(2,finalType,Type);
        trig_pos = [];
        Type = [];
    end
    % Se transpone las matrices finales
    finalTrigs = finalTrigs';
    finalType = finalType';
    
    %Grafica de los datos del BIOPAC, tambien se recortan las ventanas de EMG
    %de cada trial en los distintos movimientos y se copian en la variable
    %biopac para el posterior analisis
    cnt = 0;
    f=figure('Name',str_datos(k));
    f.Position= [512*(k-1) 440 512 345];
    for m = 15:5:40
        trigType = find(finalType == m);
        number_plot = m/5 - 2;
        subplot(2,3,number_plot)
        for n= 1:length(trigType)-1
            plot(t, data(finalTrigs(trigType(n))-1500:finalTrigs(trigType(n))+2500,3))
            hold on
            cnt = cnt + 1;
            biopac(:,cnt) = data(finalTrigs(trigType(n)):finalTrigs(trigType(n))+1000, 3);
        end
        hold off
        ylim([-1 1])
        xlim([-3 5])
        title("Biopac Movimiento " + number_plot + "")
        xlabel("Tiempo (seg)")
        xline(0,'--k','Trigger',LineWidth=1.5);
        
    end  

    %%
    
    %Grafica de los datos del EMG eRedi, tambien se recortan las ventanas de
    %EMG de cada trial en los distintos movimientos y se copian en la variable
    %eRedi para el posterior analisis.
    f=figure('Name',str_datos(k));
    cnt = 0;
    for m = 15:5:40
        trigType = find(finalType == m);
        number_plot = m/5 - 2;
        subplot(2,3,number_plot)
        for n=1:length(trigType)-1
            plot(t, data(finalTrigs(trigType(n))-1500:finalTrigs(trigType(n))+2500,4))
            hold on
            cnt = cnt + 1;
            eRedi(:,cnt) = data(finalTrigs(trigType(n)):finalTrigs(trigType(n))+1000,4);
        end
        hold off
        f.Position= [512*(k-1) 50 512 345];
        ylim([-1 1])
        xlim([-3 5])
        title("eRedi Movimiento " + number_plot + "")
        xlabel("Tiempo (seg)")
        xline(0,'--k','Trigger',LineWidth=1.5);
    end  
    
    figure((2*k)-1);

    %Correlación cruzada de los datos, experimento 1
    %Nota: la correlacion directa de los datos no funciono, el valor maximo
    %obtenido en promedio es 0.49.
    % ppp = 1;
    % qqq = 2000;
    % for n = 1:cnt
    %     [c,lags] = xcorr(biopac(ppp:qqq,n),eRedi(ppp:qqq,n),'normalized');
    %     corr(n) = max(c);
    % end
    % mean(corr);
    
    %Toolbox de features de matlab del siguiente Link
    %https://la.mathworks.com/matlabcentral/fileexchange/
    % 71514-emg-feature-extraction-toolbox
    %vamos a crear una matriz donde los renglones sean la cantidad de trials
    %detectados por las 40 columnas correspondientes cada uno de los features
    %propuestos en el toolbox.
    
    % str=["fzc" "ewl" "emav" "asm" "ass" "msr" "ltkeo" "lcov" "card" "ldasdv"...
    %     "ldamv" "dvarv" "mfl" "myop" "ssi" "vo" "tm" "aac" "mmav"... 
    %     "mmav2" "iemg" "dasdv" "damv" "rms" "vare" "wa" "ld" "ar" "mav" "zc"... 
    %     "ssc" "wl" "mad" "iqr" "kurt" "skew" "cov" "sd" "var" "ae"];
    
    % str=['fzc', 'ewl', 'emav', 'asm', 'ass',  'ltkeo', 'card', 'ldasdv',...
    %     'ldamv', 'dvarv', 'mfl', 'myop', 'ssi', 'vo', 'tm', 'aac', 'mmav',... 
    %     'mmav2', 'iemg', 'dasdv', 'damv', 'rms', 'vare', 'wa', 'ld', 'mav', 'zc',... 
    %     'ssc', 'wl', 'mad', 'iqr', 'kurt', 'skew', 'cov', 'sd', 'var', 'ae'];
    
    str=["fzc" "ewl" "emav" "asm" "ass" "ltkeo" "card" "ldasdv"...
        "ldamv" "dvarv" "mfl" "myop" "ssi" "vo" "tm" "aac" "mmav"... 
        "mmav2" "iemg" "dasdv" "damv" "rms" "vare" "wa" "ld" "mav" "zc"... 
        "ssc" "wl" "mad" "iqr" "kurt" "skew" "cov" "sd" "var" "ae"];
    
    [row, col] =size(biopac);
    for m = 1:col
        for n =1:length(str)
            str(n);
            biopac_ft(n,m) = jfemg(str(n), biopac(:,m));
            biopac_ft2(n,m) = jfemg(str(n), abs(biopac(:,m)));
            eRedi_ft(n,m) = jfemg(str(n),eRedi(:,m));
            eRedi_ft2(n,m) = jfemg(str(n), abs(eRedi(:,m)));
        end
    end
    
    %Transpone la matriz de las caracteristicas con los trials
    biopac_ft = biopac_ft';
    eRedi_ft = eRedi_ft';
    biopac_ft2 = biopac_ft2';
    eRedi_ft2 = eRedi_ft2';
    
    % Determina el promedio y la Desv. Est de cada una de las 37 
    % caracteristicas implementadas
    mu_biopac = mean(biopac_ft);
    mu_eRedi = mean(eRedi_ft);
    mu_biopac3 = mean(biopac_ft2);
    mu_eRedi3 = mean(eRedi_ft2);
    std_biopac = std(biopac_ft);
    std_eRedi = std(eRedi_ft);
    
    
    
    
    % Obtenemos el Error Porcentual para cada una de las columnas promediades
    % del Biopac contra las columnas promediadas del eRedi
    for n = 1:length(mu_biopac)
        resultados(n) = 1 - abs(1-mu_biopac(n)/mu_eRedi(n));
        resultados3(n) = 1 - abs((mu_biopac(n) - mu_eRedi(n))/mu_biopac(n));
        resultados4(n) = 1 - abs((mu_biopac3(n) - mu_eRedi3(n))/mu_biopac3(n));
    
    end
    
    % Promedio de todos los errores porcentuales.
    mean_result = mean(resultados);
    mean_result4 = nanmean(resultados4)
    
    
    % % Obtenemos la puntuacuón de características (Feature Score) a través de la
    % % función chi^2.
    % [idx,scores] = fscchi2(biopac_ft,finalType);
    % [idx2,scores2] = fscchi2(eRedi_ft,finalType);
    % 
    % %close all
    % figure
    % bar(scores(idx))
    % xlabel('Predictor rank')
    % ylabel('Predictor importance score')
    % 
    % figure
    % bar(scores2(idx2))
    % xlabel('Predictor rank')
    % ylabel('Predictor importance score')
    % 
    % % Con base en la chi^2 reordenamos las matrices de ambos EMG de mayor
    % % puntuación a menor puntuación. Nota: esto no sirvio muy bien.
    % [row, col] = size(biopac_ft);
    % final_biopac = [];
    % for n = 1:col
    %     x = find(idx==n);
    %     final_biopac(:,n) = biopac_ft(:,x);
    %     final_eRedi(:,n) = eRedi_ft(:,x);
    %     features(:,n) = str(x);
    % end
    % 
    % % Determina el promedio y la Desv. Est de cada una de las 37 
    % % caracteristicas implementadas despues de chi^2.
    % mu_biopac2 = mean(final_biopac);
    % mu_eRedi2 = mean(final_eRedi);
    % std_biopac2 = std(final_biopac);
    % std_eRedi2 = std(final_eRedi);
    % 
    % % Obtenemos el Error Porcentual para cada una de las columnas promediades
    % % del Biopac contra las columnas promediadas del eRedi
    % for n = 1:length(mu_biopac2)
    %     resultados2(n) = 1 - abs(1-mu_biopac2(n)/mu_eRedi2(n));
    % end
    % 
    % % Promedio de todos los errores porcentuales.
    % mean_result2 = mean(resultados2)
    % 
    % 
    % sz=40;
    % color=["g" "b" "y" "c" "k"  "r"];
    % cnt = 1;
    % for n = 1:10:60
    %     scatter3(final_biopac(n:n+9,1), final_biopac(n:n+9,2),final_biopac(n:n+9,3), color(cnt),'filled')
    %     hold on
    %     cnt = cnt + 1;
    % end
    % legend
    % 
    % figure
    % cnt = 1;
    % for n = 1:10:60
    %     scatter3(final_eRedi(n:n+9,1), final_eRedi(n:n+9,2),final_eRedi(n:n+9,3), color(cnt),'filled')
    %     hold on
    %     cnt = cnt + 1;
    % end
    % legend
    % 
    % 
    % final_biopac = cat(2,final_biopac, finalType);
    % final_eRedi = cat(2,final_eRedi, finalType);
    % sort_biopac = final_biopac(randperm(size(final_biopac,1)),:);
    % sort_eRedi = final_eRedi(randperm(size(final_eRedi,1)),:);
    % 
    % Mdl_SVM = fitcecoc(sort_biopac(1:48,1:37),sort_biopac(1:48,38));
    % 
    % xxx = predict(Mdl_SVM,(sort_biopac(49:end,1:37)));
    % yyy = sort_biopac(49:end,38);
    % 
    % for n = 1:length(xxx)
    %     if xxx(n) == yyy(n)
    %         Acc(n) = 1;
    %     else
    %         Acc(n) = 0;
    %     end
    % end
    % 
    % %%close all;

    %se guardan los resultados en arreglos
    
    results_array=cat(2,resultados4,results_array);
    mean_results_array=cat(2,mean_result4,mean_results_array);


    if k~=Num_sujetos
    clear -regexp ^a ^b ^c ^d ^e ^f ^g ^h ^i ^j ^l ^o ^p ^q ^t ^u ^v ^w ^x ^y ^z
    end
end
close all;
results_compare=[];
results_compare=reshape(results_array,[37,3]);
X = categorical({'fzc', 'ewl', 'emav', 'asm', 'ass',  'ltkeo', 'card', 'ldasdv',...
         'ldamv', 'dvarv', 'mfl', 'myop', 'ssi', 'vo', 'tm', 'aac', 'mmav',... 
         'mmav2', 'iemg', 'dasdv', 'damv', 'rms', 'vare', 'wa', 'ld', 'mav', 'zc',... 
         'ssc', 'wl', 'mad', 'iqr', 'kurt', 'skew', 'cov', 'sd', 'var', 'ae'});
X = reordercats(X,{'fzc', 'ewl', 'emav', 'asm', 'ass',  'ltkeo', 'card', 'ldasdv',...
         'ldamv', 'dvarv', 'mfl', 'myop', 'ssi', 'vo', 'tm', 'aac', 'mmav',... 
         'mmav2', 'iemg', 'dasdv', 'damv', 'rms', 'vare', 'wa', 'ld', 'mav', 'zc',... 
         'ssc', 'wl', 'mad', 'iqr', 'kurt', 'skew', 'cov', 'sd', 'var', 'ae'});
figure;
bar(X,results_compare);
legend({sprintf('%s %.2f',str_short(1), mean_results_array(1)),...
   sprintf('%s %.2f',str_short(2),mean_results_array(2)),...
   sprintf('%s %.2f',str_short(3),mean_results_array(3))},...
   'Location','southwest');

%close all

