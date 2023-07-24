clear all; close all; clc

disp('Start init')
dq = daq("ni");
dq.Rate = 1;

%% FlowMeter
device = "cDAQ2Mod1";
aisFlowMeters = {'ai0','ai1'};
namesFlowMeters = {'warmFlow[ml/s]','coldFlow[ml/s]'};
for i=1:length(aisFlowMeters)
    ch = addinput(dq, device, char(aisFlowMeters(i)), "current");
    ch.Name = char(namesFlowMeters(i));
    disp("Sensor " + convertCharsToStrings(ch.Name) + ' added')
end

m4mA = 0; %massflow @ 4mA
m20mA = 2000; %massflow @20mA
A=(m20mA-m4mA)/0.016;
B=-A*0.004;

disp('Flowmeter initialized')
%% RTD
device = "cDAQ2Mod2";
aisRTD = {'ai0','ai1','ai2'};
namesRTD = {'coldInlet[C]','warmInlet[C]','outlet[C]'};
for i=1:length(aisRTD)
    ch = addinput(dq, device, char(aisRTD(i)), "RTD");
    ch.Name = char(namesRTD(i));
    ch.Units = "Celsius";
    ch.RTDType = "Pt3750";
    ch.RTDConfiguration = "FourWire";
    ch.R0 = 100;
    disp("Sensor " + convertCharsToStrings(ch.Name) + ' added')
end
disp('RTD Input initialized')

%%
device = "cDAQ2Mod3";
aisRTD1 = {'ai3','ai2','ai1','ai0'};
namesRTD1 = {'RTD-h=35mm[C]','RTD-h=95mm[C]','RTD-h=155mm[C]','RTD-h=215mm[C]'};

for i=1:length(aisRTD1)
    ch = addinput(dq, device, char(aisRTD1(i)), "RTD");
    ch.Name = char(namesRTD1(i));
    ch.Units = "Celsius";
    ch.RTDType = "Pt3750";
    ch.RTDConfiguration = "FourWire";
    ch.R0 = 100;
    disp("Sensor " + convertCharsToStrings(ch.Name) + ' added')
end
disp('RTD Box initialized')

% %% Thermocouple
% device = "cDAQ2Mod4";
% aisThermocouples = {'ai3','ai2','ai1','ai0'};
% namesThermocouples = {'TC-h=35mm[C]','TC-h=95mm[C]','TC-h=155mm[C]','TC-h=215mm[C]'};
% for i=1:length(aisThermocouples)
%     ch = addinput(dq, device, char(aisThermocouples(i)), "Thermocouple");
%     ch.ThermocoupleType = 'K';
%     ch.Units = 'Celsius';
%     ch.Name = char(namesThermocouples(i));
%     disp("Sensor " + convertCharsToStrings(ch.Name) + ' added')
% end
% disp('Thermocouple initialized')

%% Stirrer
comDevice = serialport("COM3", 9600);
configureTerminator(comDevice, "CR/LF");
writeline(comDevice, "STOP_4");
disp("Stirrer initialized")

%% 'Initialion done'
disp('Initialion done')

%%
warning off; close all; clc; clear server;

server = tcpserver("localhost",4000);

while server.Connected == false
    clc;
    disp('Python Client not connected')
    pause(1)
end

fig = uifigure(1);
bHeating = uibutton(fig,"state", "Text","By-Pass on/off","Position",[10 50 100 22]);
bStirrer = uibutton(fig,"state", "Text","Stirrer on/off","Position",[10 10 100 22]);
sldStirrer = uislider(fig,"Orientation","vertical");
sldStirrer.Limits = [30 100];
sldStirrer.Value = 30;


data = timetable();
while true
    d=read(dq); %read current data
    d.Time=datetime; %set datetime
    d{:,1:2}=round((d{:,1:2}*A+B)/60,1); %rescale flowMeters
    if d{:,1} <= 0
        d{:,1} = 0;
    end
    if d{:,2} <= 0
        d{:,2} = 0;
    end

    drawnow;
    disp(bStirrer.Value)
    stirrerRPM = round(sldStirrer.Value);
    if bStirrer.Value == 1
        d.stirrerRPM=stirrerRPM;
        writeline(comDevice,"OUT_SP_4 "+num2str(stirrerRPM));
        writeline(comDevice,"START_4");
    else
        d.stirrerRPM=0;
        writeline(comDevice,"STOP_4");
    end

    %Update control values
    d.byPass=bHeating.Value;
    d.stirrerState=bStirrer.Value;

    % disp Data
    clc;
    disp(rows2vars(d))

    % add data
    try
        % header to string
        cols = d.Properties.VariableNames;
        cols = {'Time', cols{:}};
        headerCSV = strjoin(cols, ',');
        % data
        dataCSV = string(d.Variables);
        dataCSV = [string(d.Time(1)),dataCSV];
        dataCSV = strjoin(dataCSV, ',');

        % send data
        write(server,[headerCSV,';',char(dataCSV)]);
    catch ME
        disp('No data send');
    end
    %data=[data;d]; 
    pause(0.1);
end

