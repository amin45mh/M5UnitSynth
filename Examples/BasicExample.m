%% M5UnitSynth Basic Example

%% Hardware Setup:
%   1. Connect M5Unit-Synth to ESP32 or M5Core2
%   2. UART Configuration: RX=13, TX=14, Baud=31250 (MIDI standard)
%   3. Connections: M5Unit-Synth RX -> ESP32 GPIO13, M5Unit-Synth TX -> ESP32 GPIO14
%   4. Power: VCC (5V), GND
%   
%   Alternative pin configurations for different M5Stack ports:
%   - Port A: RX=33, TX=32
%   - Port B: RX=36, TX=26  
%   - Port C: RX=13, TX=14 (default)

%% Find the Serial Port of the device using serialportlist
disp('Available serial ports:')
disp(serialportlist) % Paste this into the command window
% hint: run serialportlist before plugging in the M5 and again after, your device should be the new entry.
% If nothing shows up, check the cable, check if you need a serial port driver.

%% Enter the position in the list of the port you'd like to connect to
mySerialPorts = serialportlist;
M5SerialPort = mySerialPorts(1); % *Before Running, enter the array position of the port you want to connect to!
clear mySerialPorts

%% Define the M5Stack's ESP32 processor as an 'arduino' object: arduino(Port, Board, Libraries, Other Flags)
% Port is [defined above]
% Board is ['ESP32-WROOM-DevKitC']
% Libraries are ['M5Stack/M5UnitSynth']
% adding [,'Traceon', true,] prints debug info to the Command Window
% adding [,'ForceBuildOn',true] forces a re-compile and re-upload arduinoServer each time (used during library development)
if ~exist('esp32','var')
    esp32 = arduino(M5SerialPort,'ESP32-WROOM-DevKitC','Libraries',{'M5Stack/M5UnitSynth'},'ForceBuildOn',true);
    %esp32 = arduino(M5SerialPort,'ESP32-WROOM-DevKitC','Libraries',{'M5Stack/M5UnitSynth'},'ForceBuildOn',true,'TraceOn',true);
end
clear M5SerialPort

%% Initialize the M5UnitSynth Library as an arduinoAddOn
% The M5UnitSynth Library supports the M5Unit-Synth synthesizer module
% Configure UART pins explicitly: RX=13, TX=14 (Port C configuration)
if ~exist('synth','var')
    synth = addon(esp32,'M5Stack/M5UnitSynth','RXPin',13,'TXPin',14);
end

%% Initialize the Synthesizer
fprintf('Initializing M5UnitSynth...\n');
success = synth.initialize();

if ~success
    error('Failed to initialize M5UnitSynth. Check UART connections and pins.');
end

fprintf('M5UnitSynth initialized successfully!\n\n');

%% Set Instrument and Volume
fprintf('Setting up instrument and volume...\n');
synth.setInstrument(0, 0);  % Channel 0, Instrument 0 (Acoustic Grand Piano)
synth.setVolume(100);        % Master volume (0-127)

%% Example 1: Play Single Notes
fprintf('Example 1: Playing single notes...\n');

% Play middle C (note 60)
fprintf('  Playing Middle C...\n');
synth.noteOn(0, 60, 100);    % channel, note, velocity
pause(0.5);
synth.noteOff(0, 60);
pause(0.2);

% Play E (note 64)
fprintf('  Playing E...\n');
synth.noteOn(0, 64, 100);
pause(0.5);
synth.noteOff(0, 64);
pause(0.2);

% Play G (note 67)
fprintf('  Playing G...\n');
synth.noteOn(0, 67, 100);
pause(0.5);
synth.noteOff(0, 67);
pause(0.5);

%% Example 2: Play a Scale
fprintf('Example 2: Playing C major scale...\n');

% C major scale: C, D, E, F, G, A, B, C
notes = [60, 62, 64, 65, 67, 69, 71, 72];
noteDuration = 0.4;

for i = 1:length(notes)
    synth.playNote(0, notes(i), noteDuration, 100);
end

pause(0.5);

%% Example 3: Play a Chord
fprintf('Example 3: Playing a C major chord...\n');

% Play C major chord (C-E-G)
synth.noteOn(0, 60, 100);  % C
synth.noteOn(0, 64, 100);  % E
synth.noteOn(0, 67, 100);  % G

pause(2);

% Stop all notes on channel 0
synth.allNotesOff(0);

pause(0.5);

%% Example 4: Use Different Instruments
fprintf('Example 4: Trying different instruments...\n');

instruments = [0, 40, 56, 73];  % Piano, Violin, Trumpet, Flute
instrumentNames = {'Piano', 'Violin', 'Trumpet', 'Flute'};
testNote = 60;  % Middle C

for i = 1:length(instruments)
    fprintf('  Playing %s...\n', instrumentNames{i});
    synth.setInstrument(0, instruments(i));
    synth.playNote(0, testNote, 0.8, 100);
    pause(0.2);
end

pause(0.5);

%% Example 5: Use Effects
fprintf('Example 5: Adding effects...\n');

% Set back to piano
synth.setInstrument(0, 0);

% Play with reverb
fprintf('  Playing with reverb...\n');
synth.setReverb(0, 100);  % High reverb
synth.playNote(0, 60, 1.0, 100);
pause(0.3);

% Reset reverb
synth.setReverb(0, 0);

% Play with pan (balance)
fprintf('  Playing with pan (left-center-right)...\n');
synth.setBalance(0, 0);    % Pan left
synth.playNote(0, 60, 0.5, 100);

synth.setBalance(0, 64);   % Pan center
synth.playNote(0, 64, 0.5, 100);

synth.setBalance(0, 127);  % Pan right
synth.playNote(0, 67, 0.5, 100);

% Reset to center
synth.setBalance(0, 64);

pause(0.5);

%% Example 6: Simple Melody (Twinkle Twinkle Little Star)
fprintf('Example 6: Playing "Twinkle Twinkle Little Star"...\n');

synth.setInstrument(0, 0);  % Piano
synth.setVolume(100);

% Note numbers for the melody
melodyNotes = [60, 60, 67, 67, 69, 69, 67, ...  % Twinkle twinkle little star
               65, 65, 64, 64, 62, 62, 60, ...  % How I wonder what you are
               67, 67, 65, 65, 64, 64, 62, ...  % Up above the world so high
               67, 67, 65, 65, 64, 64, 62, ...  % Like a diamond in the sky
               60, 60, 67, 67, 69, 69, 67, ...  % Twinkle twinkle little star
               65, 65, 64, 64, 62, 62, 60];     % How I wonder what you are

% Duration for each note (in seconds)
melodyDurations = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, ...
                   0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, ...
                   0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, ...
                   0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, ...
                   0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, ...
                   0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0];

% Play the melody
for i = 1:length(melodyNotes)
    synth.playNote(0, melodyNotes(i), melodyDurations(i), 100);
    pause(0.05);  % Small gap between notes
end

pause(0.5);

%% Example 7: Multi-Channel Example
fprintf('Example 7: Using multiple channels with different instruments...\n');

% Setup different instruments on different channels
synth.setInstrument(0, 0);   % Channel 0: Piano
synth.setInstrument(1, 40);  % Channel 1: Violin
synth.setInstrument(2, 56);  % Channel 2: Trumpet

% Set channel volumes
synth.setChannelVolume(0, 100);
synth.setChannelVolume(1, 80);
synth.setChannelVolume(2, 70);

% Play harmony
fprintf('  Playing 3-part harmony...\n');
synth.noteOn(0, 60, 100);  % Piano: C
pause(0.2);
synth.noteOn(1, 64, 80);   % Violin: E
pause(0.2);
synth.noteOn(2, 67, 70);   % Trumpet: G

pause(2);

% Stop all channels
synth.allNotesOff(0);
synth.allNotesOff(1);
synth.allNotesOff(2);

%% Cleanup
fprintf('\nExample complete!\n');
fprintf('Cleaning up...\n');

% Reset synthesizer
synth.systemReset();

% Clear objects (optional - keeps variables in workspace for further use)
% clear synth esp32;

fprintf('Done!\n');

