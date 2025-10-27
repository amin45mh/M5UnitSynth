%% connectToM5StackBasic.m
% ==================================================================================================
% Create a connection to the M5Stack in your MATLAB workspace
% Copyright 2025, Eric Prandovszky and Amin Mahmoudi
% Contact: prandov@yorku.ca, aminmh@yorku.ca
% Version 1
% Oct 27, 2025
% Script to help get connected to the M5Stack.
% ==================================================================================================
%% Find the Serial Port of the device using serialportlist
disp(serialportlist) % Paste this into the command window
% hint: run serialportlist before plugging  in the M5 and again after, your device should be the new entry.
% If nothing shows up, check the cable, check if you need a serial port driver. 

%% Enter the position in the list of the port you'd like to connect to
mySerialPorts = serialportlist;
M5SerialPort= mySerialPorts(3); % *Before Running, enter the array position of the port you want to connect to!
clear mySerialPorts

%% Define the M5Stack's ESP32 processor as an 'arduino' object: arduino(Port, Board, Libraries, Other Flags)
% Port is [defined above]
% Board is ['ESP32-WROOM-DevKitC']
% Libraries are typically [,'Libraries',{'I2C','M5Stack/M5Unified','Adafruit/NeoPixel'}]
% adding [,'Traceon', true,] prints debug info to the Command Window
% adding [,'ForceBuildOn',true] forces a re-compile and re-upload arduinoServer each time (used during library development)
% Example: esp32 = arduino(M5SerialPort,'ESP32-WROOM-DevKitC','Libraries',{'I2C','M5Stack/M5Unified','Adafruit/NeoPixel'},'Traceon', true);
if ~exist('esp32','var')
    esp32 = arduino(M5SerialPort,'ESP32-WROOM-DevKitC','Libraries',{'I2C','M5Stack/M5Unified','Adafruit/NeoPixel','M5Stack/M5UnitSynth'},'Traceon', true);%,'ForceBuildOn',true);
end
clear M5SerialPort
%% Initialize the M5Unified Library as an arduinoAddOn
% The M5Unified Library supports devices on the M5: LCD, IMU, Mic, Spkr, PMU, etc.
if ~exist('m5u','var')
    m5u = addon(esp32,'M5Stack/M5Unified');
end
%m5u.begin % Now called automatically in v0.4.6+
m5u.lcdPrintLn('Hi Everybodies')

%% Neopixels
% Neopixels (programmable RGB LED's) are accessed through the MathWorks 'Neopixel Add-On Library for Arduino', and are initialized separately.
% M5Stack Core2 for AWS has 10 neopixels connected to D25.
if ~exist('neopix','var')
    neopix = addon(esp32, 'Adafruit/NeoPixel', 'D25', 10, 'NeoPixelType', 'GRB'); 
end
% Traffic Light Example:
 writeColor(neopix, 1, 'green');
 writeColor(neopix, 3, 'yellow');
 writeColor(neopix, 5, 'red');

%% Unit Synth
% Initialize connection
synth = addon(esp32,'M5Stack/M5UnitSynth','RXPin',13,'TXPin',14);
%   
% Set up instrument
synth.setInstrument(0, 0, 0);      % Bank 0, Channel 0, Piano
synth.setMasterVolume(100);
%   
% Play a scale
notes = [60, 62, 64, 65, 67, 69, 71, 72];  % C major scale
for note = notes
    synth.playNote(0, note, 0.5, 100);
end
%   
%   % Play chord with effects
synth.setReverb(0, 4, 80, 60);     % Add reverb
synth.setNoteOn(0, 60, 100);       % C
synth.setNoteOn(0, 64, 100);       % E
synth.setNoteOn(0, 67, 100);       % G
pause(2);
synth.setAllNotesOff(0);
 
% Cleanup
synth.reset();