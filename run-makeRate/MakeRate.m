clear;
close all
clc;

addpath('path/to/GSH/GSH-main/Tools/')
basedir = "/path/to/flaps/results/50years_blobetas_nelr128_depths/";

%% Choose Profile
folderPattern = {};

%fixed radius and varying depth and density
folderPattern{1} = fullfile(basedir,'*UpperMantleEta9e+20*depth*blobEta_1e+20_radius_1400*_thickness_400*');
folderPattern{1}(2) = 'depth';
folderPattern{2} = fullfile(basedir,'*UpperMantleEta9e+21*depth*blobEta_1e+20_radius_1400*_thickness_400*');
folderPattern{2}(2) = 'depth';
folderPattern{3} = fullfile(basedir,'*UpperMantleEta6e+20*depth*blobEta_1e+20_radius_1400*_thickness_400*');
folderPattern{3}(2) = 'depth';
folderPattern{4} = fullfile(basedir,'*UpperMantleEta3e+22*depth*blobEta_1e+20_radius_1400*_thickness_400*');
folderPattern{4}(2) = 'depth';

titles =["Plesa1", "Plesa2","Root","Samuel"];

Plot = 0 ; %1: plot all SH maps, %0: only calculate SHmap contributions and total gravity
PlotTotalGravMap =0;
computeRate = true;
polyorder =0;
npoints = 10;
grav_norm = {};
dt_norm = {};
gravangle = {};
nVecs ={};
SHRsurface=cell(length(folderPattern));
SHRcmb=cell(length(folderPattern));
SHRmantle=cell(length(folderPattern));
SHRtotal=cell(length(folderPattern));
rho1_ = [3499 3510 3550 3432];
rho_m_= [3579 3872 3550 3589];
mGal = 1e-5;
year=365.25*3600*24;
unitt = mGal*year;
for p = 1:length(folderPattern)
    Profilepresorted = dir(folderPattern{p}(1));
    legendS{p} = char(folderPattern{p}(2));
    % sort folder names
    folderNames = {Profilepresorted.name};
    numericValues = NaN(size(folderNames));  
    pattern = sprintf('%s_?([-+]?\\d*\\.?\\d+(?:[eE][-+]?\\d+)?)', legendS{p});

    for i = 1:length(folderNames)
        tokens = regexp(folderNames{i}, pattern, 'tokens');
        if ~isempty(tokens)
            numericValues(i) = str2double(tokens{1}{1});
        else
            warning('No value found in folder: %s', folderNames{i});
        end
    end
    
    [values, sortIdx] = sort(numericValues);
    sortedFolders = Profilepresorted(sortIdx);
    Profile{p} = fullfile(basedir, {sortedFolders.name});
    profileStrings{p} = string(values);
    SHRsurface{p}= zeros(length(Profile{p}),360);
    SHRcmb{p}=zeros(length(Profile{p}),360);
    SHRmantle{p}=zeros(length(Profile{p}),360);
    SHRtotal{p}=zeros(length(Profile{p}),360);
    for i = 1:length(Profile{p}) 
        folder = fullfile(Profile{p}(i));Rd_inner =-1835e3;lim=[5 0.5 1 10];
        %% Load in data files
        dyn_topo0 = importdata(folder+'/DTc_R2_0.ascii');
        dyn_topo1 = importdata(folder+'/DTc_R2_1.ascii');
        dyn_cmb0 = importdata(folder+'/DTc_R1_0.ascii');
        dyn_cmb1 = importdata(folder+'/DTc_R1_1.ascii');
        dyncmbi = 2;
        grav_mantle0 = importdata(folder+'/gravity_0000.ascii',' ',1);
        grav_mantle1 = importdata(folder+'/gravity_0001.ascii',' ',1);
        
        grav_man0 = grav_mantle0.data;
        grav_man1 = grav_mantle1.data;
        rho1 = rho1_(i);
        rhoc=8050;
        rho_m=rho_m_(i);
        rho2 = rhoc-rho_m_(i);

        
        %% Rates
        if computeRate
            dt =50 ; %50%year
            dyn_Tangle = dyn_topo1(:,1);
            dyn_topoR =  (dyn_topo1(:,2)-dyn_topo0(:,2))/dt; %m/year
            dyn_Cangle =  dyn_cmb1(:,1);
            dyn_cmbR  =  (dyn_cmb1(:,dyncmbi)-dyn_cmb0(:,dyncmbi))/dt; %Using the average pressure corrected data from CMB and correcting the sign
            
            grav_angle = grav_man0(:,4);
            
            grav_manR =  (grav_man1(:,8)-grav_man0(:,8))/dt; %Gal/year
            
            grav_norm.("Profile" + p + "_" + i) = grav_man1(:,8);
            gravangle.("Profile" + p + "_" + i) = grav_man1(:,4);
            dt_norm.("Profile" + p + "_" + i) = dyn_topo1;
        else
            dyn_Tangle = dyn_topo1(:,1);
            dyn_topoR =  (dyn_topo1(:,2));
            dyn_Cangle =  dyn_cmb1(:,1);
            dyn_cmbR  =  (dyn_cmb1(:,dyncmbi));
            grav_angle = grav_man0(:,4);
            grav_manR =  (grav_man1(:,8));
            grav_norm.("Profile" + p + "_" + i) = grav_man1(:,8);
            gravangle.("Profile" + p + "_" + i) = grav_man1(:,4);
            dt_norm.("Profile" + p + "_" + i) = dyn_topo1;
        end
        %% Fontsizes
        SS = 10;
        MS = 20;
        LS = 20;
        %% Colormap
        cmap_dynR = brewermap([],'Reds');
        cmap_gravR = flipud(brewermap([],'RdGy'));
        
        Model = struct();
        Model.number_of_layers = 1;
        Model.name = 'DTR';
        Model.GM = 6.67430e-11*6.4169e23;
        Model.Re_analyse = 3396e3;
        Model.Re = 3369e3;
        Model.geoid = 'none';
        Model.nmax = 179;    
        Model.correct_depth = 0;
        
        %% make map for GSHcode
        latLimH =    [-89.5 89.5 1]; 
        lonLimH =    [0.5 359.5 1];
        
        lonH = lonLimH(1):lonLimH(3):lonLimH(2);
        latH = fliplr(latLimH(1):latLimH(3):latLimH(2));
        LonH = repmat(lonH,length(latH),1);
        LatH = repmat(latH',1,length(lonH));
        

        x = linspace(0, length(dyn_topoR), length(dyn_topoR));
        % use smoothing parameter!
        dyn_topoR(1:npoints) = [];
        dyn_topoR(end-npoints:end) = [];
        y_smooth = dyn_topoR;
        dyn_Tangle(1:npoints) = [];
        dyn_Tangle(end-npoints:end) = [];
        
        DT_line = interp1(90-dyn_Tangle./pi*180,y_smooth,latH, 'pchip');

        Map_DT = zeros(size(LonH));
        
        for ii = 1:size(Map_DT,2)
            Map_DT(:,ii) = DT_line;
        end
        
        % rotate to Tharsis
        [Map_DT] = Rotate_map(Map_DT,LonH,LatH,Model);
        MDTS_max = compose("%5.1f",max(Map_DT,[],'all')*100);
        MDTS_min = compose("%5.1f",min(Map_DT,[],'all')*100);
        
        if Plot==1
            figure
            I = imagesc(lonH,latH,Map_DT*100);
            c=colorbar;
            colormap(cmap_dynR)
            c.Label.String = 'Dynamic Topography Rate(cm/year)';
            xlabel('Longitude [\circ]','FontSize',MS)
            ylabel('Latitude [\circ]','FontSize',MS)
            title("Surface Dynamic Topography Rate " + profileStrings{p}(i) ,'Fontsize',LS )
            set(gca, 'YDir','normal')
            text(10,-75,"min:"+MDTS_min+"cm/year,max:"+MDTS_max+"cm/year",'FontSize',SS,'FontWeight','normal');
            saveas(gcf,folder+"/SurfaceDynamicTopographyRate_MapProjection.png")
        end
        %% make layers
        % calculates the gravity signal of the dynamic topography
        t1 = Map_DT;
        t1(t1<0) = 0;
        t2 = Map_DT;
        t2(t2>0) = 0;
        rhoL = zeros(size(t1));
        rhoL(t1>0) = rho1;
        rhoL(t1<=0) = -rho1;
    
        %% create model             
        
        % % Top bound
        Model.l1.bound = t1;
        Model.l1.dens  = rhoL;
        % bottom bound
        Model.l2.bound = t2;
        
        %% analysis 
        
        [V] = model_SH_analysis(Model);
        
        %% Do the synthesis
        
        SHbounds = [2 15];
        height = 0;
        
        disp('Performing the final synthesis, this may take a while!')
        [data_DTR_Surf] = model_SH_synthesis(lonLimH,latLimH,height,SHbounds,V,Model);    
        
        
        %% plot data
        
        lon = data_DTR_Surf.grd.lon;
        lats = data_DTR_Surf.grd.lat;
        
        MG_max = compose("%2.3f",max(data_DTR_Surf.vec.R,[],'all')*1e8);
        MG_min = compose("%2.3f",min(data_DTR_Surf.vec.R,[],'all')*1e8);
        
        if Plot==1
            figure
            imagesc(lon(1,:),lats(:,1),data_DTR_Surf.vec.R.*1e8);c=colorbar; %in micro gal /year
            colormap(cmap_gravR)
            c.Label.String = 'Gravity Anomaly ({\mu}Gal/year)';
            xlabel('Longitude [\circ]','Fontsize',MS)
            ylabel('Latitude [\circ]','Fontsize',MS)
            text(10,-75,"max:"+MG_max+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
            text(10,-83,"min:"+MG_min+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
            title("Surface Dynamic Topography Rate Component " + profileStrings{p}(i),'FontSize',LS)
            set(gca,'YDir','normal','FontSize',16)
            saveas(gcf,folder+"/SurfaceDynamicTopographyRate_SHMap.png")
        end
                      
        %% CMB
        CMB_line = interp1(90-dyn_Cangle./pi*180,dyn_cmbR,latH);
        Map_CMB = zeros(size(LonH));
        
        for ii = 1:size(Map_CMB,2)
            Map_CMB(:,ii) = CMB_line;
        end
        
        [Map_CMB] = Rotate_map(Map_CMB,LonH,LatH,Model);
        MDTC_max = compose("%5.1f",max(Map_CMB,[],'all')*100);
        MDTC_min = compose("%5.1f",min(Map_CMB,[],'all')*100);
        
        if Plot==1
            figure
            imagesc(lonH,latH,Map_CMB*100);c=colorbar;
            colormap(cmap_dynR)
            c.Label.String = 'Dynamic Topography Rate (cm/year)';
            xlabel('Longitude [\circ]','Fontsize',MS)
            ylabel('Latitude [\circ]','Fontsize',MS)
            title("CMB Dynamic Topography Rate " + profileStrings{p}(i),'Fontsize',LS )
            set(gca, 'YDir','normal')
            text(10,-75,"max:"+MDTC_max+"cm/year",'FontSize',SS,'FontWeight','normal');
            text(10,-83,"min:"+MDTC_min+"cm/year,",'FontSize',SS,'FontWeight','normal');
            saveas(gcf,folder+"/CMBDynamicTopographyRate_Mapprojection.png")
        end
                      
        %% make layers
        ref_layer = Rd_inner;
        t1 = Map_CMB+Rd_inner ;
        t1(t1<ref_layer) = ref_layer;
        t2 = Map_CMB+Rd_inner ;
        t2(t2>ref_layer) = ref_layer;
        rho2 = 4500; %rhoc-rhom
        rhoL = zeros(size(t1));
        rhoL(t1>Rd_inner) = rho2; 
        rhoL(t1<=Rd_inner) = -rho2;
    
        %% create model
        Model = struct();
        rho_m=3550.;
        R1=1835e3;
        R2=3396e3;
    
        Model.number_of_layers = 1;
        Model.name = 'CMBR';        
        Model.GM = 6.67430e-11*4*pi/3*(R2^3-R1^3)*rho_m;
        Model.Re_analyse =  3396e3;
        Model.Re = 3369e3;
        Model.geoid = 'none';
        Model.nmax = 15;    
        Model.correct_depth = 0;

        % % Top bound
        Model.l1.bound = t1;
        Model.l1.dens  = rhoL;
        
        % bottom bound
        Model.l2.bound = t2;
    
        %% analysis 
        
        [V] = model_SH_analysis(Model);
        
        %% Do the synthesis
        
        SHbounds = [2 15];
        height = 0;
        
        disp('Performing the final synthesis, this may take a while!')
        [data_DTR_CMB] = model_SH_synthesis(lonLimH,latLimH,height,SHbounds,V,Model); 
        
        %% plot data
                
        lon = data_DTR_CMB.grd.lon;
        lats = data_DTR_CMB.grd.lat;
        
        MG_max = compose("%2.3f",max(data_DTR_CMB.vec.R,[],'all')*1e8);
        MG_min = compose("%2.3f",min(data_DTR_CMB.vec.R,[],'all')*1e8);
        
        %%
        if Plot==1
            figure
            imagesc(lon(1,:),lats(:,1),data_DTR_CMB.vec.R.*1e8);c=colorbar;%cmap = redblue;
            colormap(cmap_gravR);
            c.Label.String = 'Gravity Anomaly Rate ({\mu}Gal/year)';
            xlabel('Longitude [\circ]','Fontsize',MS)
            ylabel('Latitude [\circ]','Fontsize',MS)
            title("CMB Dynamic Topography Rate component " + profileStrings{p}(i),'Fontsize',LS)
            text(10,-75,"max:"+MG_max+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
            text(10,-83,"min:"+MG_min+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
            set(gca,'YDir','normal','Fontsize',MS)
            saveas(gcf,folder+"/CMBDynamicTopographyRate_SHMap.png")
        end
    
        %% Make Mantle Dynamics gravity anomaly plot
        grav_manR(1:2) = grav_manR(3);
        grav_manR(end-1:end) = grav_manR(end-2);
        mantle_line = interp1(90-grav_angle./pi*180,grav_manR,latH);
        
        Map_mantle = zeros(size(LonH));
        
        for ii = 1:size(Map_mantle,2)
            Map_mantle(:,ii) = mantle_line;
        end
        
        [Map_mantle] = Rotate_map(Map_mantle,LonH,LatH,Model);
        
        
        MG_max = compose("%2.2f",max(Map_mantle,[],'all')*1e8);
        MG_min = compose("%2.2f",min(Map_mantle,[],'all')*1e8);
        
        %% Plotting Mantle Dynamics
        if Plot==1
            figure
            imagesc(lonH,latH,Map_mantle*1e8);c=colorbar;
            colormap(cmap_gravR);%redblue);%colormap(vik)
            c.Label.String = 'Gravity Anomaly Rate({\mu}Gal/year)';
            % clim([-lim(3),lim(3)]);
            %ylabel(c,'{\mu}Gal','Fontsize',MS)
            hold on
            hold off
            axis([lonLimH(1) lonLimH(2) latLimH(1) latLimH(2)])
            xlabel('Longitude [\circ]','Fontsize',MS)
            ylabel('Latitude [\circ]','Fontsize',MS)
            title("Mantle Dynamic Rate " + profileStrings{p}(i),'Fontsize',LS)
            set(gca,'YDir','normal','Fontsize',MS)
            text(10,-75,"max:"+MG_max+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
            text(10,-83,"min:"+MG_min+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
            saveas(gcf,folder+"/MantleDynamicRate_SHMap.png")
        end
        
        % gravity of dt_surface + gravity of dt_cMB + gravity of the density
        % anomaly in the mantle
        Map_total = data_DTR_Surf.vec.R+data_DTR_CMB.vec.R+Map_mantle;
        MG_max = compose("%2.2f",max(Map_total,[],'all')*1e11);
        MG_min = compose("%2.2f",min(Map_total,[],'all')*1e11);
        
        % if i change only this part, nothing changes in the amplitudes of
        % the coefficients!
        Degrees = 4;
        SHbounds = [2 Degrees];
        y = GSHA(Map_total,Degrees);
        Vn = y./(Model.GM./(Model.Re^2));        
        sc = cs2sc(Vn);

        degree = 0:Degrees;
        correction_fact = degree' + 1;
        CF = repmat(correction_fact,1,size(sc,2));
        sc = sc./CF;
        scM{p}{i} = sc;

        [Clm,Slm,llvec,mmvec] = sc2vecml(sc,Degrees);
        nVec = [llvec',mmvec',Clm,Slm];
        newvec = sortrows(nVec,1);
        % newvec = [newvec, zeros(136, 2)];
        newvec = [newvec, zeros(15, 2)];
        
        nVecs.("Profile" + i) = newvec;
        %nVec2 = sortrows(nVec,1);
        filename = 'fixedDens_nVec_' + titles(p) + '_' +  profileStrings{p}(i) + '.txt';
        dlmwrite(filename, newvec, 'delimiter', ',','precision',15);
        
        [data_totalGrav] = model_SH_synthesis(lonLimH,latLimH,0,SHbounds,nVec,Model); 
    
        if PlotTotalGravMap ==1
            lajolla = load("lajolla.mat");
            figure
            imagesc(lonH,latH,(Map_total*1e11));c=colorbar;
            colormap(lajolla.lajolla); %;%colormap(vik)
            c.Label.String = 'Gravity Anomaly Rate (nGal/year)';
            if p == 1 || p == 2 || (p==3 && i >= 3)
                clim([-0.8,1.5])
            % elseif p ==2 
            elseif p ==3 && i <3
                clim([-15,30])
            end
            % clim([-3,3])
            % ylabel(c,'{\mu}Gal','Fontsize',MS)
            hold on
            %axis([lonLimH(1) lonLimH(2) latLimH(1) latLimH(2)])
            xlabel('Longitude [\circ]','Fontsize',MS)
            ylabel('Latitude [\circ]','Fontsize',MS)
            
            stringnumb = str2num(profileStrings{p}(i))/1000;

            title("Total Gravity Anomaly Rate of " + titles(p) + " at depth " + num2str(stringnumb) + "km" ,'Fontsize',LS)
            text(10,-75,"max:"+MG_max+"nGal/year",'FontSize',SS,'FontWeight','normal');
            text(10,-83,"min:"+MG_min+"nGal/year",'FontSize',SS,'FontWeight','normal');
             
            set(gca,'YDir','normal','Fontsize',MS)
            hold off
            saveas(gcf,folder+"/TotalRate_SHMap.svg")
        end
        
    
    
        lon = data_totalGrav.grd.lon;
        lats = data_totalGrav.grd.lat;
        MG_max = compose("%2.3f",max(data_totalGrav.vec.R,[],'all')*1e8);
        MG_min = compose("%2.3f",min(data_totalGrav.vec.R,[],'all')*1e8);
        if Plot ==1
            figure
            imagesc(lon(1,:),lats(:,1),data_totalGrav.vec.R.*1e8);c=colorbar; %in micro gal /year
            colormap(cmap_gravR)
            c.Label.String = 'Gravity Anomaly ({\mu}Gal/year)';
            xlabel('Longitude [\circ]','Fontsize',MS)
            ylabel('Latitude [\circ]','Fontsize',MS)
            text(10,-75,"max:"+MG_max+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
            text(10,-83,"min:"+MG_min+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
            title("Total Gravity Anomaly Rate Component " + profileStrings{p}(i),'FontSize',LS)
            set(gca,'YDir','normal','FontSize',16)
            saveas(gcf,folder+"/SurfaceDynamicTopographyRate_SHMap.png")
        end
        SHRsurface{p}(i,:)=data_DTR_Surf.vec.R(90,:);
        SHRcmb{p}(i,:)=data_DTR_CMB.vec.R(90,:);
        SHRmantle{p}(i,:)=Map_mantle(90,:);
        SHRtotal{p}(i,:)=Map_total(90,:);
    end
end

disp('break!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')


%% plotting
colors22 = {"#8ecfc9","#ffbe7a","#fa7f6f","#82b0d2","#beb8dc"};
titles22 = ["a","b","c","d"];

% Initialize min/max trackers
ymin = inf;
ymax = -inf;
% First loop: find global min and max
for p = 1:length(folderPattern)-1
    for i = 1:length(Profile{p})
        ydata = SHRtotal{p}(i,:)*1e11;
        ymin = min(ymin, min(ydata));
        ymax = max(ymax, max(ydata));
    end
end
densityContrasts = [-141,-106,-85,-71];

f = figure('Color','w');
tlo = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
set(gcf, 'Position', [100, 100, 2000, 1000])
angle = 1:360;
for p = 1:length(folderPattern)
    ax = nexttile(tlo, p);  % subplot handle for this panel
    hold(ax, 'on');
    ax.FontSize = 18;

    for i = 1:length(Profile{p})
        ydata = abs(SHRtotal{p}(i,:)*1e11);
        minVal = min(ydata);
        maxVal = max(ydata);
        if legendS{p} == "rho"
            stringnumb = densityContrasts(i);
        else
            stringnumb = str2num(profileStrings{p}(i))/1000;

        end
        legendLabel = sprintf('%s, %.2f', num2str(stringnumb), maxVal);

        plot(angle, SHRtotal{p}(i,:)*1e11, ...
            'DisplayName', legendLabel, ...
            'Color', colors22{i}, ...
            'LineWidth', 2);   
    end
    title({"(" + titles22(p) + ")"},'FontSize',LS)


    legh = legend(ax,'show', 'FontSize',18, 'Location','northwest','Interpreter', 'latex');
    if legendS{p} == "rho"
        legTitle = "Density (kg/m$^3$),  $\left|Max\right|$ (nGal/year)";
    elseif legendS{p} == "radius"
        legTitle = "Radius (km), $\left|Max\right|$ (nGal/year)";
    elseif legendS{p} == "depth"
        legTitle = "Depth (km),  $\left|Max\right|$ (nGal/year)";
    end
    t = get(legh, 'Title'); set(t, 'String', legTitle);

        
    if p ==3 || p==1
        ylabel('Gravity Anomaly Rate (nGal/year)','Fontsize',MS)
    end
    if p >2
        xlabel('Longitude [\circ]','Fontsize',MS);
    end
    xlim([0 360])
    grid on 
    
end
saveas(gcf, '50year_comparisonFigvaryMFixR_all_depth800', 'svg')  

%%            
if plotSubPlots ==1
    for p = 1:length(folderPattern)
        figure
        hold on
        for i = 1:length(Profile{p})
            subplot(2,3,1)
            plot(angle,SHRsurface{p}(i,:)*1e8,DisplayName=profileStrings{p}(i),LineWidth = 1.5,Color=Colors{i})
            title({"Surface Dynamic Topography Rate Component";""},'FontSize',LS)
            legh = legend('show', 'FontSize',16, 'Location','northwest','Interpreter', 'none');
            t = get(legh, 'Title');
            set(t, 'String', legendS{p});
            xlabel('Longitude [\circ]','Fontsize',MS)
            ylabel('Gravity Anomaly Rate ({\mu}Gal/year)','Fontsize',MS)
            grid on
            hold on
    
            subplot(2,3,2)
            plot(angle,SHRcmb{p}(i,:)*1e8,DisplayName=profileStrings{p}(i),LineWidth = 1.5,Color=Colors{i})
            title({"CMB Dynamic Topography Rate Component";""},'FontSize',LS)
            set(t, 'String', legendS{p});
            xlabel('Longitude [\circ]','Fontsize',MS)
            ylabel('Gravity Anomaly Rate ({\mu}Gal/year)','Fontsize',MS)
            grid on
            hold on
    
            subplot(2,3,4)
            plot(angle,SHRmantle{p}(i,:)*1e8,DisplayName=profileStrings{p}(i),LineWidth = 1.5,Color=Colors{i})
            title({"Mantle Dynamic Rate Component";""},'FontSize',LS)
            set(t, 'String', legendS{p});
            xlabel('Longitude [\circ]','Fontsize',MS)
            ylabel('Gravity Anomaly Rate ({\mu}Gal/year)','Fontsize',MS)
            grid on
            hold on
    
    
            subplot(2,3,5)
            plot(angle,SHRtotal{p}(i,:)*1e8,DisplayName=profileStrings{p}(i),Color=Colors{i},LineWidth = 1.5)
            title({"Total Gravity Anomaly Rate";""},'FontSize',LS)
            set(t, 'String', legendS{p});        xlabel('Longitude [\circ]','Fontsize',MS)
            ylabel('Gravity Anomaly Rate ({\mu}Gal/year)','Fontsize',MS)
            grid on        
            hold on
    
            subplot(2,3,3)
            plot(grav_norm.("Profile" + p + "_" +i),gravangle.("Profile" + p + "_" + i)./pi*180,LineWidth = 1.5,color = Colors{i},DisplayName=profileStrings{p}(i)+" min: " + num2str(min(grav_norm.("Profile" + p + "_" + i))) + ", max: " + num2str(max(grav_norm.("Profile" + p + "_" + i))))
            set(gca, 'YDir','reverse')
            ylabel('Angle [\circ]','Fontsize',MS)
            xlabel('Gravity norm[m/s^2]','Fontsize',MS)
            set(t, 'String', legendS{p})
            grid on        
            hold on
    
            subplot(2,3,6)
            plot(dt_norm.("Profile" + p + "_" + i)(:,2),dt_norm.("Profile" + p + "_" + i)(:,1)./pi*180,LineWidth = 1.5,color=Colors{i},DisplayName=profileStrings{p}(i))
            set(gca, 'YDir','reverse')
            ylabel('Angle [\circ]','Fontsize',MS)
            xlabel('Surface dynamic topography [m]','Fontsize',MS)
            set(t, 'String', legendS{p})
            grid on
            hold on
        end
    end
else
    figure
    for i = 1:length(Profile{p})
        hold on
        plot(angle,SHRsurface(i,:)*1e8,DisplayName=profileStrings{p}(i),LineWidth = 1.5,Color=Colors{i})
    end
    title({"Surface Dynamic Topography Rate Component";""},'FontSize',LS)
    xlabel('Longitude [\circ]','Fontsize',MS)
    ylabel('Gravity Anomaly Rate ({\mu}/year)','Fontsize',MS)
    legend('show', 'FontSize',16, 'Location','northwest','Interpreter', 'none')
    grid on
    saveas(gcf,'Profiles/SurfaceDynamicTopographyRate_All.png')
    
    
    figure
    for i = 1:length(Profile{p})
        hold on
        plot(angle,SHRcmb(i,:)*1e8,DisplayName=profileStrings{p}(i),LineWidth = 1.5,Color=Colors{i})
    end
    title({"CMB Dynamic Topography Rate Component";""},'FontSize',LS)
    xlabel('Longitude [\circ]','Fontsize',MS)
    ylabel('Gravity Anomaly Rate ({\mu}Gal/year)','Fontsize',MS)
    legend('Location','southwest');
    grid on
    saveas(gcf,'Profiles/CmbDynamicTopographyRate_All.png')
        
    figure
    for i = 1:length(Profile{p})
        hold on
        plot(angle,SHRmantle(i,:)*1e8,DisplayName=profileStrings{p}(i),LineWidth = 1.5,Color=Colors{i})
    end
    title({"Mantle Dynamic Rate Component";""},'FontSize',LS)
    xlabel('Longitude [\circ]','Fontsize',MS)
    ylabel('Gravity Anomaly Rate ({\mu}Gal/year)','Fontsize',MS)
    legend('Location','southwest');
    grid on
    saveas(gcf,'Profiles/MantleDynamicTopographyRate_All.png')
    
       figure
    for i = 1:length(Profile{p})
        hold on
        plot(angle,SHRtotal(i,:)*1e8,DisplayName=profileStrings{p}(i),Color=Colors{i},LineWidth = 1.5)
    end
    title({"Total Gravity Anomaly Rate";""},'FontSize',LS)
    xlabel('Longitude [\circ]','Fontsize',MS)
    ylabel('Gravity Anomaly Rate ({\mu}Gal/year)','Fontsize',MS)
    legend('show', 'FontSize',16, 'Location','northwest','Interpreter', 'none')
    grid on
    saveas(gcf,'Profiles/TotalDynamicTopographyRate_All.png')
end


%% Coordinate transformation to location of Tharsis
function [MAP_Rot] = Rotate_map(MAP,LonH,LatH,Model)

% Centre of Tharsis (blob location)
blat=0.8;
% blat = 45;
blon=113.4;

bound1 = matrix2gmt(MAP,LonH,LatH);
mars1_bd1=bound1;

lon_ = deg2rad(mars1_bd1(:,1));
lat_ = deg2rad(mars1_bd1(:,2));
R=mars1_bd1(:,3)+1;

x_ = cos(lon_).*cos(lat_).*R; %does not work since multiplying matrix colums does not work -> .*
y_ = sin(lon_).*cos(lat_).*R;
z_ = sin(lat_).*R;
v_ = [x_ y_ z_];

latrot = deg2rad(90-blat);
lonrot = deg2rad(360-blon);

A = [cos(lonrot) -sin(lonrot) 0; sin(lonrot) cos(lonrot) 0; 0 0 1];
B = [cos(latrot) 0 sin(latrot); 0 1 0; -sin(latrot) 0 cos(latrot)];

v = (A*B*v_')'; %multiply each row with rotation matrices
rad=sqrt(v(:,1).^2+v(:,2).^2+v(:,3).^2);
lat = rad2deg(acos(v(:,3)./rad));
lon = rad2deg(atan2(v(:,2), v(:,1)));

mars1_bd1_rotated = mars1_bd1;
mars1_bd1_rotated(:,1) = 180 - lon;%deze ook
mars1_bd1_rotated(:,2) = 90 - lat;%colat to lat
mars1_bd1_rotated(:,3) = sqrt(v(:,1).^2+v(:,2).^2+v(:,3).^2);

F=scatteredInterpolant(mars1_bd1_rotated(:,1),mars1_bd1_rotated(:,2),mars1_bd1_rotated(:,3));
F.Method = 'linear';

MAP_Rot=F(LonH,LatH)-1;%-Model.Re;
end


