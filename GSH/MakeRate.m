clear;
close all
clc;

addpath('C:/Users/ralkahal/OneDrive - Delft University of Technology/PhD/Programs/GSH-main/Tools/')
addpath('/Users/ralkahal/OneDrive - Delft University of Technology/PhD/Programs/MscThesis_HandIn_Folder/DrosteEffect-BrewerMap-3')
basedir = "/Users/ralkahal/OneDrive - Delft University of Technology/flaps_september25/flaps/50years_blobetas_nelr128_depths/";%Rvary/"; %50years_blobeta22_nelr128_Rvary_200mass/";
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
depths = ["1000","1200","1300","800"];

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
profileV1 = {};
profileV2 = {};
rho1_ = [3499 3510 3550 3432];
rho_m_= [3579 3872 3550 3589];
mGal = 1e-5;
year=365.25*3600*24;
unitt = mGal*year;


for p = 1:length(folderPattern)
    pat = folderPattern{p}{1};
    varNames = folderPattern{p}(2:end); 
    legendS{p}  = varNames{1};
    nVars = numel(varNames);
    % read matching folders
    D = dir(pat);
    folderNames = {D.name}';
    nF = numel(folderNames);
    if nF == 0
        warning('No folders matched pattern: %s', pat);
        continue
    end
    
    % extract values for each variable!
    values = NaN(nF, nVars);
    for j = 1:nVars
        % pattern like: depth_12.3  or  depth-1e3  (case-insensitive)
        rx = sprintf('%s_?([-+]?\\d*\\.?\\d+(?:[eE][-+]?\\d+)?)', varNames{j});
        for i = 1:nF
            tok = regexp(folderNames{i}, rx, 'tokens', 'once');
            if ~isempty(tok)
                values(i,j) = str2double(tok{1});
            else
                % keep NaN; still warn for visibility
                warning('No %s value found in folder: %s', varNames{j}, folderNames{i});
            end
        end
    end
     % keep only rows where all variables were found
    ok = all(~isnan(values), 2);

    if ~all(ok)
        warning('Skipping %d folders with missing variable values.', sum(~ok));
    end
    folderNames = folderNames(ok);
    values = values(ok, :);

    % Unique sorted axes
    u1 = sort(unique(values(:,1)));
    n1 = numel(u1);
    
    % Allocate 1D cell grids
    Profile{p}       = cell(n1);
    profileV1{p}     = u1;              % labels for var1 axis
    SHRsurface{p}    = cell(n1);
    SHRcmb{p}        = cell(n1);
    SHRmantle{p}     = cell(n1);
    SHRtotal{p}      = cell(n1);

    for i = 1:numel(folderNames)
        i1 = find(u1 == values(i,1), 1, 'first');
        Profile{p}{i1, i2}{end+1} = fullfile(basedir, folderNames{i}); %#ok<AGROW>
    end

    for i2 = 1:n2
        for i1 = 1:n1
            files = Profile{p}{i1,i2};
            if isempty(files), continue; end
            % files = sort(files);
            Profile{p}{i1,i2} = files;

            nProf = numel(files);
            SHRsurface{p}{i1,i2} = zeros(nProf, 360);
            SHRcmb{p}{i1,i2}     = zeros(nProf, 360);
            SHRmantle{p}{i1,i2}  = zeros(nProf, 360);
            SHRtotal{p}{i1,i2}   = zeros(nProf, 360);
            for i = 1:nProf
                profPath = files{i};
                folder = fullfile(profPath);Rd_inner =-1835e3;lim=[5 0.5 1 10];
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
                    
                    %dyn_topoR = dyn_topo1(:,2) ;
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
                Model.name = 'DTR_Marjolein';
                Model.GM = 6.67430e-11*6.4169e23;
                Model.Re_analyse = 3396e3; %model_parameters.data(3); %R2
                Model.Re = 3369e3;
                
                Model.geoid = 'none';
                Model.nmax = 30;    
                Model.correct_depth = 0;   
                
                %Model.GM = model_parameters.data(1)*model_parameters.data(2);
                %Model.Re_analyse = model_parameters.data(3);
                %Model.Re = model_parameters.data(3);
            
        
                %% make map for GSHcode
                latLimH =    [-89.5 89.5 1]; 
                lonLimH =    [0.5 359.5 1];%
                
                lonH = lonLimH(1):lonLimH(3):lonLimH(2);
                latH = fliplr(latLimH(1):latLimH(3):latLimH(2));
                LonH = repmat(lonH,length(latH),1);
                LatH = repmat(latH',1,length(lonH));
                
                % DT_line = interp1(90-dyn_Tangle./pi*180,dyn_topoR,latH, 'pchip');
                % % make map
                % DT_line(1) = DT_line(2);
                % DT_line(end) = DT_line(end-1);
                % 
                % figure; plot(DT_line)
        
        
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
                    %colormap(cmap_dyn);%colormap(vik)
                    c.Label.String = 'Dynamic Topography Rate(cm/year)';
                    xlabel('Longitude [\circ]','FontSize',MS)
                    ylabel('Latitude [\circ]','FontSize',MS)
                    title("Surface Dynamic Topography Rate " + " at depth " + num2str(profileV1{p}(i1)/1000) + "km, and eta " +num2str(profileV2{p}(i2)) ,'Fontsize',LS )
                    set(gca, 'YDir','normal')
                    %uicontrol( 'style', 'text', 'string', 'abcd1234', 'fontweight', 'bold' )
                    text(10,-75,"min:"+MDTS_min+"cm/year,max:"+MDTS_max+"cm/year",'FontSize',SS,'FontWeight','normal');
                    saveas(gcf,folder+"/SurfaceDynamicTopographyRate_MapProjection.png")
                end
                %% make layers
                % calculates the gravity signal of the dynamic topography
                t1 = Map_DT;
                t1(t1<0) = 0;
                t2 = Map_DT;
                t2(t2>0) = 0;
                % rho1 = 3550;%model_parameters.data(4); 
                %rho1 = model_parameters.data(4);
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
                
                SHbounds = [2 10];
                height = 0;
                
                disp('Performing the final synthesis, this may take a while!')
                [data_DTR_Surf] = model_SH_synthesis(lonLimH,latLimH,height,SHbounds,V,Model);    
                
                
                %% plot data
                
                %load('~/PhD/CodeNovak/codes/GSH_package/Tools/vik.mat');
                
                lon = data_DTR_Surf.grd.lon;
                lats = data_DTR_Surf.grd.lat;
                
                MG_max = compose("%2.3f",max(data_DTR_Surf.vec.R,[],'all')*1e8);
                MG_min = compose("%2.3f",min(data_DTR_Surf.vec.R,[],'all')*1e8);
                
                if Plot==1
                    figure
                    imagesc(lon(1,:),lats(:,1),data_DTR_Surf.vec.R.*1e8);c=colorbar; %in micro gal /year
                    colormap(cmap_gravR)
                    % clim([-lim(1),lim(1)]);
                    %colormap(redblue);%colormap(vik)
                    c.Label.String = 'Gravity Anomaly ({\mu}Gal/year)';
                    %ylabel(c,'{\mu}Gal','Fontsize',MS)
                    %caxis([-1.5 1.5])onLimH(2) latLimH(1) latLimH(2)])
                    xlabel('Longitude [\circ]','Fontsize',MS)
                    ylabel('Latitude [\circ]','Fontsize',MS)
                    text(10,-75,"max:"+MG_max+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
                    text(10,-83,"min:"+MG_min+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
                    title("Surface Dynamic Topography Rate Component "  + " at depth " + num2str(profileV1{p}(i1)/1000) + "km, and eta " +num2str(profileV2{p}(i2)),'FontSize',LS)
                    set(gca,'YDir','normal','FontSize',16)
                    saveas(gcf,folder+"/SurfaceDynamicTopographyRate_SHMap.png")
                end
                %% CMB
                %
                %figure
                %plot(dyn_cmb(:,1)./pi*180,dyn_cmb(:,2),'.B')
                %title('CMB Dynamic topography')
                %saveas(gcf,folder+"/CMBDynamicTopography_Graph.png")
                
                %%
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
                    title("CMB Dynamic Topography Rate "  + " at depth " + num2str(profileV1{p}(i1)/1000) + "km, and eta " +num2str(profileV2{p}(i2)),'Fontsize',LS )
                    set(gca, 'YDir','normal')
                    text(10,-75,"max:"+MDTC_max+"cm/year",'FontSize',SS,'FontWeight','normal');
                    text(10,-83,"min:"+MDTC_min+"cm/year,",'FontSize',SS,'FontWeight','normal');
                    saveas(gcf,folder+"/CMBDynamicTopographyRate_Mapprojection.png")
                end
                %% make layers
                ref_layer = Rd_inner;
                t1 = Map_CMB+Rd_inner ;%+1558000; %%%% added some distance to correcr the CMB data
                t1(t1<ref_layer) = ref_layer;
                t2 = Map_CMB+Rd_inner ;%+1558000;
                t2(t2>ref_layer) = ref_layer;
                rho2 = 4500;%model_parameters.data(5); %rhoc-rhom
                %rho2 = model_parameters.data(5);
                rhoL = zeros(size(t1));
                rhoL(t1>Rd_inner) = rho2; 
                rhoL(t1<=Rd_inner) = -rho2;
            
                
                %% create model
                Model = struct();
                rho_m=3550.;
                R1=1835e3;
                R2=3396e3;
            
                Model.number_of_layers = 1;
                Model.name = 'CMBR_Marjolein';
                
                % Additional variables
                %Model.GM = 3.9860004415E14;
                
                Model.GM = 6.67430e-11*4*pi/3*(R2^3-R1^3)*rho_m;%6.4169e23;
                Model.Re_analyse =  3396e3;%R2%
                Model.Re = 3369e3;
                
                %Model.GM = model_parameters.data(1)*model_parameters.data(2);
                %Model.Re_analyse = model_parameters.data(3);
                %Model.Re = model_parameters.data(3);
            
                Model.geoid = 'none';
                Model.nmax = 30;    
                Model.correct_depth = 0;
                               
                
                % % Top bound
                Model.l1.bound = t1;
                Model.l1.dens  = rhoL;
                
                % bottom bound
                Model.l2.bound = t2;
            
                %% analysis 
                
                [V] = model_SH_analysis(Model);
                
                %% Do the synthesis
                
                SHbounds = [2 10];
                height = 0;
                
                disp('Performing the final synthesis, this may take a while!')
                [data_DTR_CMB] = model_SH_synthesis(lonLimH,latLimH,height,SHbounds,V,Model); 
                
                %% plot data
                
                %load('~/PhD/CodeNovak/codes/GSH_package/Tools/vik.mat');
                
                lon = data_DTR_CMB.grd.lon;
                lats = data_DTR_CMB.grd.lat;
                
                MG_max = compose("%2.3f",max(data_DTR_CMB.vec.R,[],'all')*1e8);
                MG_min = compose("%2.3f",min(data_DTR_CMB.vec.R,[],'all')*1e8);
                
                %%
                if Plot==1
                    figure
                    imagesc(lon(1,:),lats(:,1),data_DTR_CMB.vec.R.*1e8);c=colorbar;%cmap = redblue;
                    colormap(cmap_gravR);%colormap(vik)
                    % clim([-lim(2),lim(2)]);
                    c.Label.String = 'Gravity Anomaly Rate ({\mu}Gal/year)';
                    xlabel('Longitude [\circ]','Fontsize',MS)
                    ylabel('Latitude [\circ]','Fontsize',MS)
                    title("CMB Dynamic Topography Rate component " + " at depth " + num2str(profileV1{p}(i1)/1000) + "km, and eta " +num2str(profileV2{p}(i2)),'Fontsize',LS)
                    %caxis([-1.5 1.5])
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
                    title("Mantle Dynamic Rate "  + " at depth " + num2str(profileV1{p}(i1)/1000) + "km, and eta " +num2str(profileV2{p}(i2)),'Fontsize',LS)
                    set(gca,'YDir','normal','Fontsize',MS)
                    text(10,-75,"max:"+MG_max+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
                    text(10,-83,"min:"+MG_min+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
                    saveas(gcf,folder+"/MantleDynamicRate_SHMap.png")
                end
                %% Plotting Total Gravity
                % n1 = sqrt(data1.vec.R.^2 + data1.vec.T.^2 + data1.vec.L.^2);
                % n2 = sqrt(data2.vec.R.^2 + data2.vec.T.^2 + data2.vec.L.^2);
                % gravity of dt_surface + gravity of dt_cMB + gravity of the density
                % anomaly in the mantle
                Map_total = data_DTR_Surf.vec.R+data_DTR_CMB.vec.R+Map_mantle;
                % Map_total = n1+n2+Map_mantle;
                MG_max = compose("%2.2f",max(Map_total,[],'all')*1e11);
                MG_min = compose("%2.2f",min(Map_total,[],'all')*1e11);
                
                % if i change only this part, nothing changes in the amplitudes of
                % the coefficients!
                Degrees = 10;
                SHbounds = [2 Degrees];
                y = GSHA(Map_total,Degrees);
                Vn = y./(Model.GM./(Model.Re^2));        
                sc = cs2sc(Vn);
        
                degree = 0:Degrees;
                correction_fact = degree' + 1;
                CF = repmat(correction_fact,1,size(sc,2));
                sc = sc./CF;
                sc1 =sc;
                sc1(1:2,:) =[];
                scM{p}{i1,i2} = sc1;
            %%
                [Clm,Slm,llvec,mmvec] = sc2vecml(sc,Degrees);
                nVec = [llvec',mmvec',Clm,Slm];
                filename = "papertestsDec_15do/fixedDens_nVecorder_" + titles(p) + "_" +  num2str(profileV1{p}(i1)/1000) + "_" + num2str(profileV2{p}(i2)) + ".txt";
                dlmwrite(filename, nVec, 'delimiter', ',','precision',15);

                newvec = sortrows(nVec,1);
                newvec = [newvec, zeros(length(nVec), 2)];
                % newvec = [newvec, zeros(15, 2)];
                
                nVecs.("Profile" + i) = newvec;
                %nVec2 = sortrows(nVec,1);
                filename = "papertestsDec_15do/fixedDens_nVec_" + titles(p) + "_" +  num2str(profileV1{p}(i1)/1000) + "_" + num2str(profileV2{p}(i2)) + ".txt";
                dlmwrite(filename, newvec, 'delimiter', ',','precision',15);
                
                [data_totalGrav] = model_SH_synthesis(lonLimH,latLimH,0,SHbounds,nVec,Model); 
            
                if PlotTotalGravMap ==1
                    lajolla = load("lajolla.mat");
                    figure
                    imagesc(lonH,latH,(Map_total*1e11));c=colorbar;
                    colormap(lajolla.lajolla); %;%colormap(vik)
                    c.Label.String = 'Gravity Anomaly Rate (nGal/year)';
                    % if p == 1 || p == 2 || (p==3 && i >= 3)
                    %     clim([-0.8,1.5])
                    % elseif p ==2 
                    % elseif p ==3 && i <3
                    %     clim([-15,30])
                    % end
                    % clim([-3,3])
                    % ylabel(c,'{\mu}Gal','Fontsize',MS)
                    hold on
                    %axis([lonLimH(1) lonLimH(2) latLimH(1) latLimH(2)])
                    xlabel('Longitude [\circ]','Fontsize',MS)
                    ylabel('Latitude [\circ]','Fontsize',MS)
                    
                    % stringnumb = str2num(profileStrings{p}(i))/1000;
        
                    title(titles(p) + " at depth " + num2str(profileV1{p}(i1)/1000) + "km, and eta " +num2str(profileV2{p}(i2)) ,'Fontsize',LS)
                    text(10,-75,"max:"+MG_max+"nGal/year",'FontSize',SS,'FontWeight','normal');
                    text(10,-83,"min:"+MG_min+"nGal/year",'FontSize',SS,'FontWeight','normal');
                     
                    set(gca,'YDir','normal','Fontsize',MS)
                    hold off
                    % saveas(gcf,folder+"/TotalRate_SHMap.png")
                end
                %% Combining all components in total gravity anomaly plot
                % figure
                % imagesc(lonH,latH,((data1.vec.R+data2.vec.R+Map_mantle)*1e8));c=colorbar;
                % colormap(cmap_gravR); %redblue);%colormap(vik)
                % c.Label.String = 'Gravity Anomaly Rate ({\mu}Gal/year)';
                % ylabel(c,'{\mu}Gal','Fontsize',MS)
                % hold on
                % hold off
                % axis([lonLimH(1) lonLimH(2) latLimH(1) latLimH(2)])
                % xlabel('Longitude [\circ]','Fontsize',MS)
                % ylabel('Latitude [\circ]','Fontsize',MS)
                % title('Total Gravity Anomaly Rate','Fontsize',LS)
                % set(gca,'YDir','normal','Fontsize',MS)
                % clim([-lim(4),lim(4)])
                % text(10,-75,"max:"+MG_max+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
                % text(10,-83,"min:"+MG_min+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
                % saveas(gcf,folder+"/TotalRate_SHMap_clipped.png")
                
            
            
                lon = data_totalGrav.grd.lon;
                lats = data_totalGrav.grd.lat;
                % nn = sqrt(datan.vec.R.^2 + datan.vec.T.^2 + datan.vec.L.^2);
                MG_max = compose("%2.3f",max(data_totalGrav.vec.R,[],'all')*1e11);
                % MG_max = compose("%2.3f",max(nn,[],'all')*1e8);
                % MG_min = compose("%2.3f",min(nn,[],'all')*1e8);
                MG_min = compose("%2.3f",min(data_totalGrav.vec.R,[],'all')*1e11);
                if PlotTotalGravMap ==1
                    figure
                    imagesc(lon(1,:),lats(:,1),data_totalGrav.vec.R.*1e11);c=colorbar; %in micro gal /year
                    % imagesc(lon(1,:),lats(:,1),nn*1e8);c=colorbar;
                    colormap(lajolla.lajolla); %;%colormap(vik)
                    % colormap(cmap_gravR)
                    % clim([-lim(2),lim(2)])
                    %colormap(redblue);%colormap(vik)
                    c.Label.String = 'Gravity Anomaly ({\mu}Gal/year)';
                    %ylabel(c,'{\mu}Gal','Fontsize',MS)
                    %caxis([-1.5 1.5])
                    %axis([lonLimH(1) lonLimH(2) latLimH(1) latLimH(2)])
                    xlabel('Longitude [\circ]','Fontsize',MS)
                    ylabel('Latitude [\circ]','Fontsize',MS)
                    text(10,-75,"max:"+MG_max+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
                    text(10,-83,"min:"+MG_min+"{\mu}Gal/year",'FontSize',SS,'FontWeight','normal');
                    title("Total Gravity Anomaly Rate Component "  + " at depth " + num2str(profileV1{p}(i1)/1000) + "km, and eta " +num2str(profileV2{p}(i2)),'FontSize',LS)
                    set(gca,'YDir','normal','FontSize',16)
                    %saveas(gcf,folder+"/SurfaceDynamicTopographyRate_SHMap.png")
                end
                %for j = 1:360
                    SHRsurface{p}{i1,i2}(i,:) = data_DTR_Surf.vec.R(90,:);
                    SHRcmb{p}{i1,i2}(i,:)     = data_DTR_CMB.vec.R(90,:);
                    SHRmantle{p}{i1,i2}(i,:)  = Map_mantle(90,:);
                    SHRtotal{p}{i1,i2}(i,:)   = Map_total(90,:);
                %end
            end
        end
    end
end
disp('break!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')

%%
Colors = {[0.9290 0.6940 0.1250],[0.4940 0.1840 0.5560],[0.3010 0.7450 0.9330],[0,0.4470,0.7410],[0.8500, 0.3250, 0.0980],[0.6350, 0.0780, 0.1840],[0.4660, 0.6740, 0.1880],[0,0,0]};
%%
colors22 = {"#8ecfc9","#ffbe7a","#fa7f6f","#82b0d2","#beb8dc"};
titles22 = ["a","b","c","d"];

% Initialize min/max trackers
ymin = inf;
ymax = -inf;
% First loop: find global min and max

densityContrasts = [-141,-106,-85,-71];

f = figure('Color','w');
tlo = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
set(gcf, 'Position', [100, 100, 2000, 1000])
lineStyles = {'-', '--', ':', '-.'};
angle = 1:360;
H = cell(numel(folderPattern),1);
M = {}
axList       = gobjects(numel(folderPattern),1);
bestMaxAll   = zeros(numel(folderPattern),1);
unit = 1e11;
for p = 1:length(folderPattern)
    ax = nexttile(tlo, p); 
    axList(p) = ax;
    hold(ax, 'on');
    grid on;
    ax.FontSize = 18;
    bestMax = -inf; bestX = NaN; bestY = NaN;

    for i1 = 1:numel(profileV1{p})         % color = depth
        for i2 = 1:numel(profileV2{p})
            files= Profile{p}{i1,i2};
            if isempty(files), continue; end
            col = colors22{i1};
            ls  = lineStyles{i2};
            yrow = SHRtotal{p}{i1,i2}(1,:)* 1e11;  % usually only one row
            [maxVal, idx] = max(abs(yrow));
            ySignedMax = yrow(idx);
            if maxVal> bestMax
                bestMax = maxVal; bestX = angle(idx); bestY=ySignedMax;
            end

            depthVal = profileV1{p}(i1) / 1000;  % km
            legendLabel = sprintf('%.0f, %.1f', ...
                     depthVal,  maxVal);
            H{p}(i1,i2) = plot(ax, angle, yrow, ...
                    'Color', col, ...
                    'LineStyle', ls, ...
                    'LineWidth', 2, ...
                    'DisplayName', legendLabel);
        end

    end
                                  
    Dkm  = profileV1{p}./1000;                % depths (km)
    Etas = profileV2{p};                      % viscosities
    M    = zeros(numel(Dkm), numel(Etas));    % |max| per cell
    
    for i1 = 1:numel(Dkm)
        for i2 = 1:numel(Etas)
            if isempty(Profile{p}{i1,i2}), continue; end
            y = SHRtotal{p}{i1,i2}(1,:);      
            M(i1,i2) = max(abs(y))*1e11/unit; % store in units of ×1e11
        end
    end
    if p ==2
        corner = 'NW';
    else
        corner = 'SW';
    end
    drawLegendTable(ax, Dkm, Etas, M, colors22, lineStyles,corner);
    
    if p == 1 || p == 3, ylabel(ax, 'Gravity Anomaly Rate (nGal/year)', 'FontSize', MS); end
    if p > 2, xlabel(ax, 'Longitude [°]', 'FontSize', MS); end
    xlim(ax, [0 360]);
    % yscale(ax, "log")
end

saveas(gcf, '50year_comparison_all_Radii_noblobVisc', 'epsc')





function drawLegendTable(ax, depthsKm, etas, M, rowColors, lineStyles,corner)
% Overlay a compact table in the bottom-right corner of axes AX.
% depthsKm:  nR×1, row labels (color-coded)
% etas:      1×nC, column labels (linestyle-coded)
% M:         nR×nC numeric (already scaled, e.g., ×1e11)
% rowColors: nR×3 RGB colors (match your plot colors for depths)
% lineStyles:1×nC cellstr of styles for etas

    fig = ancestor(ax,'figure');
    oldUnitsAx = ax.Units; ax.Units = 'normalized';
    pos = ax.Position; ax.Units = oldUnitsAx;

    padY=0.04; padX = 0.04;  w = 0.30;  h = 0.5;            
    % insetPos = [pos(1)+pad*pos(3), ...
    %             pos(2)+pos(4)*(1 - h - pad), ...
    %             pos(3)*w, pos(4)*h];
    insetPos = inset_for_corner(ax, corner, w, h, padX, padY);

    axT = axes('Parent',fig,'Units','normalized','Position',insetPos, ...
               'Color','none','XColor','none','YColor','none');
        hold(axT,'on'); axis(axT,'off');

    nR = numel(depthsKm);
    nC = numel(etas);

    % Layout params
    padX = 0.05; padY = 0.15;
    x0 = padX; y0 = 1 - padY;            % start near top-left
    dx = (1 - 2*padX) / (nC + 1);        % +1 for row header col
    dy = (1 - 2*padY) / (nR + 1);        % +1 for header row

    % Header row (column labels with linestyle swatches)
    txtOpts = {'Units','normalized','FontSize',14,'Interpreter','latex'};
    % top-left header cell (blank or title)
    % text(axT, x0, y0, '$\textbf{Depth / $\eta$}$', txtOpts{:}, 'FontWeight','bold','Interpreter','latex');
    text(axT, x0, y0, '$\textbf{Depth}$', txtOpts{:}, 'FontWeight','bold','Interpreter','latex');

    % for j = 1:nC
    %     xc = x0 + j*dx + dx*0.5;
    %     % label
    %     lbl = sprintf('$\\eta$=10$^{%d}$', round(log10(etas(j))));
    %     text(axT, xc, y0, lbl, txtOpts{:}, 'HorizontalAlignment','center', 'FontWeight','bold','Interpreter','latex');
    %     % linestyle swatch under header
    %     plot(axT, [xc-0.08 xc+0.08], [y0-0.05 y0-0.05], ...
    %          'k', 'LineWidth',1.5, 'LineStyle', lineStyles{j}, 'HandleVisibility','off');
    % end
    xc = x0 + dx + dx*0.5;
    lbl = sprintf('Max (nGal/yr)');
    text(axT, xc, y0, lbl, txtOpts{:}, 'HorizontalAlignment','center', 'FontWeight','bold','Interpreter','latex');

    % Rows: depth label (colored) + values
    for i = 1:nR
        yc = y0 - i*dy;
        % depth label (colored to match curves)
        dLbl = sprintf('%.0f km', depthsKm(i));
        text(axT, x0, yc, dLbl, txtOpts{:}, 'Color', rowColors{i}, 'FontWeight','bold');

        % values
        for j = 1:nC
            xc = x0 + j*dx + dx*0.5;
            valStr = sprintf('%.1f', M(i,j)*1e11);   % already in ×1e11
            text(axT, xc, yc, valStr, txtOpts{:}, 'HorizontalAlignment','center', 'FontWeight','bold');
        end
    end

    % Optional subtle box
    rectangle(axT, 'Position',[padX padY 1-2*padX 1-2*padY], ...
              'EdgeColor',[0 0 0 0.15], 'LineWidth',0.5, 'Curvature',0.02);
    set(findall(axT,'Type','text'),'FontSize',16,'FontWeight','bold'); 
end
%%
function insetPos = inset_for_corner(ax, corner, w, h, padX, padY)
    old = ax.Units; ax.Units = 'normalized'; pos = ax.Position; ax.Units = old;
    switch upper(corner)
        case 'NW' % top-left
            x = pos(1) + padX*pos(3);
            y = pos(2) + pos(4)*(1 - h - padY);
        case 'NE' % top-right
            x = pos(1) + pos(3)*(1 - w - padX);
            y = pos(2) + pos(4)*(1 - h - padY);
        case 'SW' % bottom-left
            x = pos(1) + padX*pos(3);
            y = pos(2) + padY*pos(4);
        case 'SE' % bottom-right
            x = pos(1) + pos(3)*(1 - w - padX);
            y = pos(2) + padY*pos(4);
    end
    insetPos = [x y pos(3)*w pos(4)*h];
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
R=mars1_bd1(:,3)+1;%Model.Re;

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
