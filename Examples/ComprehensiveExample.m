%% M5UnitSynth Comprehensive Example
% This example demonstrates all functions available in the M5UnitSynth library

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

%% Define the M5Stack's ESP32 processor as an 'arduino' object
% Port is [defined above]
% Board is ['ESP32-WROOM-DevKitC']
% Libraries are ['M5Stack/M5UnitSynth']
% adding [,'Traceon', true,] prints debug info to the Command Window
% adding [,'ForceBuildOn',true] forces a re-compile and re-upload arduinoServer each time (used during library development)
if ~exist('esp32','var')
    esp32 = arduino(M5SerialPort,'ESP32-WROOM-DevKitC','Libraries',{'M5Stack/M5UnitSynth'},'ForceBuildOn',true);
    % esp32 = arduino(M5SerialPort,'ESP32-WROOM-DevKitC','Libraries',{'M5Stack/M5UnitSynth'},'ForceBuildOn',true,'TraceOn',true);
end
clear M5SerialPort

%% Initialize the M5UnitSynth Library as an arduinoAddOn
% The M5UnitSynth Library supports the M5Unit-Synth synthesizer module
% Configure UART pins explicitly: RX=13, TX=14 (Port C configuration)
if ~exist('synth','var')
    synth = addon(esp32,'M5Stack/M5UnitSynth','RXPin',13,'TXPin',14);
end

fprintf('M5UnitSynth initialized successfully!\n\n');

%% Example 1: Basic Note Control - setNoteOn(), setNoteOff(), setAllNotesOff()
fprintf('=== Example 1: Basic Note Control ===\n');

% Set up: Bank 0, Channel 0, Piano instrument (0)
synth.setInstrument(0, 0, 0);
synth.setMasterVolume(100);  % Set master volume to 100 (0-127)

% setNoteOn(channel, pitch, velocity)
% - channel: MIDI channel (0-15)
% - pitch: MIDI note number (0-127), 60=Middle C
% - velocity: Note velocity (0-127), affects volume/intensity
fprintf('Playing single notes...\n');
synth.setNoteOn(0, 60, 100);    % Play middle C
pause(0.5);
synth.setNoteOff(0, 60, 0);     % Stop middle C (velocity usually 0 for noteOff)
pause(0.2);

synth.setNoteOn(0, 64, 100);    % Play E
pause(0.5);
synth.setNoteOff(0, 64, 0);
pause(0.2);

% Play a chord, then use setAllNotesOff()
fprintf('Playing a chord...\n');
synth.setNoteOn(0, 60, 100);    % C
synth.setNoteOn(0, 64, 100);    % E
synth.setNoteOn(0, 67, 100);    % G
pause(1.5);

% setAllNotesOff(channel) - Turns off all notes on a channel
synth.setAllNotesOff(0);
pause(0.5);

%% Example 2: Instrument Selection - setInstrument()
fprintf('\n=== Example 2: Instrument Selection ===\n');

% setInstrument(bank, channel, instrument)
% - bank: MIDI bank (0-127), usually 0 for General MIDI sounds
% - channel: MIDI channel (0-15)
% - instrument: MIDI instrument number (0-127)
%   Common instruments: 0=Piano, 40=Violin, 56=Trumpet, 73=Flute, 24=Acoustic Guitar

instruments = [0, 40, 56, 73, 24];
instrumentNames = {'Piano', 'Violin', 'Trumpet', 'Flute', 'Acoustic Guitar'};

for i = 1:length(instruments)
    fprintf('Playing with %s (instrument %d)...\n', instrumentNames{i}, instruments(i));
    synth.setInstrument(0, 0, instruments(i));
    synth.playNote(0, 60, 0.8, 100);
    pause(0.2);
end
pause(0.5);

%% Example 3: Volume Control - setMasterVolume(), setVolume()
fprintf('\n=== Example 3: Volume Control ===\n');

synth.setInstrument(0, 0, 0);  % Back to piano

% setMasterVolume(level) - Sets global volume for all channels
% - level: Volume (0-127), 0=silent, 127=maximum
fprintf('Demonstrating master volume...\n');
for vol = [127, 80, 40, 100]
    fprintf('  Master volume: %d\n', vol);
    synth.setMasterVolume(vol);
    synth.playNote(0, 60, 0.4, 100);
end
pause(0.3);

% setVolume(channel, level) - Sets volume for a specific channel
% - channel: MIDI channel (0-15)
% - level: Volume (0-127)
fprintf('Demonstrating channel volume...\n');
synth.setMasterVolume(100);
for vol = [127, 80, 40, 100]
    fprintf('  Channel 0 volume: %d\n', vol);
    synth.setVolume(0, vol);
    synth.playNote(0, 60, 0.4, 100);
end
pause(0.5);

%% Example 4: Pitch Bend - setPitchBend(), setPitchBendRange()
fprintf('\n=== Example 4: Pitch Bend ===\n');

% setPitchBendRange(channel, value) - Sets pitch bend range in semitones
% - channel: MIDI channel (0-15)
% - value: Range in semitones (0-127), default is usually 2
synth.setPitchBendRange(0, 2);  % ±2 semitones

% setPitchBend(channel, value) - Bends the pitch up or down
% - channel: MIDI channel (0-15)
% - value: Bend amount (-8192 to +8191), 0=center (no bend)
fprintf('Playing note with pitch bend...\n');
synth.setNoteOn(0, 60, 100);
pause(0.3);

% Bend up
for bend = 0:1000:4000
    synth.setPitchBend(0, bend);
    pause(0.1);
end

% Bend down
for bend = 4000:-1000:-4000
    synth.setPitchBend(0, bend);
    pause(0.1);
end

% Return to center
synth.setPitchBend(0, 0);
pause(0.2);
synth.setNoteOff(0, 60, 0);
pause(0.5);

%% Example 5: Stereo Pan - setPan()
fprintf('\n=== Example 5: Stereo Pan (Balance) ===\n');

% setPan(channel, value) - Sets stereo position
% - channel: MIDI channel (0-15)
% - value: Pan position (0-127), 0=full left, 64=center, 127=full right
fprintf('Playing note panning from left to center to right...\n');

synth.setPan(0, 0);        % Full left
synth.playNote(0, 60, 0.5, 100);

synth.setPan(0, 64);       % Center
synth.playNote(0, 64, 0.5, 100);

synth.setPan(0, 127);      % Full right
synth.playNote(0, 67, 0.5, 100);

synth.setPan(0, 64);       % Reset to center
pause(0.5);

%% Example 6: Reverb Effect - setReverb()
fprintf('\n=== Example 6: Reverb Effect ===\n');

% setReverb(channel, program, level, delayfeedback)
% - channel: MIDI channel (0-15)
% - program: Reverb type (0-127)
% - level: Reverb amount (0-127), 0=none, 127=maximum
% - delayfeedback: Delay feedback (0-127)
fprintf('Playing with no reverb...\n');
synth.setReverb(0, 0, 0, 0);
synth.playNote(0, 60, 1.0, 100);
pause(0.3);

fprintf('Playing with high reverb...\n');
synth.setReverb(0, 4, 100, 80);
synth.playNote(0, 60, 1.0, 100);
pause(0.5);

% Reset reverb
synth.setReverb(0, 0, 0, 0);
pause(0.5);

%% Example 7: Chorus Effect - setChorus()
fprintf('\n=== Example 7: Chorus Effect ===\n');

% setChorus(channel, program, level, feedback, chorusdelay)
% - channel: MIDI channel (0-15)
% - program: Chorus type (0-127)
% - level: Chorus amount (0-127)
% - feedback: Feedback (0-127)
% - chorusdelay: Delay time (0-127)
fprintf('Playing with chorus effect...\n');
synth.setChorus(0, 2, 80, 60, 40);
synth.playNote(0, 60, 1.5, 100);
pause(0.5);

% Reset chorus
synth.setChorus(0, 0, 0, 0, 0);
pause(0.5);

%% Example 8: Expression Control - setExpression()
fprintf('\n=== Example 8: Expression (Dynamics) ===\n');

% setExpression(channel, expression)
% - channel: MIDI channel (0-15)
% - expression: Expression level (0-127), controls dynamics/volume variation
fprintf('Playing with varying expression...\n');
for expr = [127, 80, 40, 100]
    fprintf('  Expression: %d\n', expr);
    synth.setExpression(0, expr);
    synth.playNote(0, 60, 0.5, 100);
end
pause(0.5);

%% Example 9: Tuning - setTuning()
fprintf('\n=== Example 9: Fine and Coarse Tuning ===\n');

% setTuning(channel, fine, coarse)
% - channel: MIDI channel (0-15)
% - fine: Fine tuning (0-127), 64=default/no adjustment
% - coarse: Coarse tuning (0-127), 64=default/no adjustment
fprintf('Normal tuning...\n');
synth.setTuning(0, 64, 64);
synth.playNote(0, 60, 0.8, 100);

fprintf('Sharp tuning...\n');
synth.setTuning(0, 80, 64);
synth.playNote(0, 60, 0.8, 100);

fprintf('Flat tuning...\n');
synth.setTuning(0, 48, 64);
synth.playNote(0, 60, 0.8, 100);

% Reset tuning
synth.setTuning(0, 64, 64);
pause(0.5);

%% Example 10: Vibrato - setVibrate()
fprintf('\n=== Example 10: Vibrato Effect ===\n');

% setVibrate(channel, rate, depth, delay)
% - channel: MIDI channel (0-15)
% - rate: Vibrato speed (0-127)
% - depth: Vibrato intensity (0-127)
% - delay: Delay before vibrato starts (0-127)
fprintf('Playing with vibrato...\n');
synth.setVibrate(0, 60, 50, 10);
synth.setNoteOn(0, 60, 100);
pause(2.0);
synth.setNoteOff(0, 60, 0);

% Reset vibrato
synth.setVibrate(0, 0, 0, 0);
pause(0.5);

%% Example 11: Time Variant Filter (TVF) - setTvf()
fprintf('\n=== Example 11: Time Variant Filter ===\n');

% setTvf(channel, cutoff, resonance)
% - channel: MIDI channel (0-15)
% - cutoff: Filter cutoff frequency (0-127)
% - resonance: Filter resonance (0-127)
fprintf('Playing with filter sweep...\n');
synth.setNoteOn(0, 36, 100);  % Low note
for cutoff = 20:10:100
    synth.setTvf(0, cutoff, 40);
    pause(0.15);
end
synth.setNoteOff(0, 36, 0);
pause(0.5);

%% Example 12: Envelope (ADSR) - setEnvelope()
fprintf('\n=== Example 12: ADSR Envelope ===\n');

% setEnvelope(channel, attack, decay, release)
% - channel: MIDI channel (0-15)
% - attack: Attack time (0-127), how quickly sound reaches full volume
% - decay: Decay time (0-127), time to fall from peak to sustain level
% - release: Release time (0-127), time for sound to fade after note off
fprintf('Fast attack, quick decay/release...\n');
synth.setEnvelope(0, 10, 20, 20);
synth.playNote(0, 60, 1.0, 100);
pause(0.3);

fprintf('Slow attack, long release (pad-like)...\n');
synth.setEnvelope(0, 80, 60, 80);
synth.playNote(0, 60, 1.5, 100);
pause(0.5);

% Reset envelope
synth.setEnvelope(0, 64, 64, 64);
pause(0.5);

%% Example 13: Equalizer - setEqualizer()
fprintf('\n=== Example 13: Equalizer ===\n');

% setEqualizer(channel, lowband, medlowband, medhighband, highband,
%              lowfreq, medlowfreq, medhighfreq, highfreq)
% - channel: MIDI channel (0-15)
% - lowband, medlowband, medhighband, highband: Band gains (0-127)
% - lowfreq, medlowfreq, medhighfreq, highfreq: Band frequencies (0-127)
fprintf('Playing with boosted bass...\n');
synth.setEqualizer(0, 100, 64, 64, 64, 20, 50, 80, 100);
synth.playNote(0, 48, 1.0, 100);  % Low note
pause(0.3);

fprintf('Playing with boosted treble...\n');
synth.setEqualizer(0, 64, 64, 64, 100, 20, 50, 80, 100);
synth.playNote(0, 72, 1.0, 100);  % High note
pause(0.3);

% Reset EQ (flat)
synth.setEqualizer(0, 64, 64, 64, 64, 32, 48, 80, 96);
pause(0.5);

%% Example 14: Modulation Wheel - setModWheel()
fprintf('\n=== Example 14: Modulation Wheel ===\n');

% setModWheel(channel, pitch, tvtcutoff, amplitude, rate, pitchdepth, tvfdepth, tvadepth)
% - channel: MIDI channel (0-15)
% - pitch: Pitch modulation (0-127)
% - tvtcutoff: Filter cutoff modulation (0-127)
% - amplitude: Amplitude modulation (0-127)
% - rate: Modulation rate (0-127)
% - pitchdepth: Pitch modulation depth (0-127)
% - tvfdepth: Filter modulation depth (0-127)
% - tvadepth: Amplitude modulation depth (0-127)
fprintf('Playing with modulation wheel...\n');
synth.setModWheel(0, 70, 60, 50, 50, 60, 60, 60);
synth.setNoteOn(0, 60, 100);
pause(2.0);
synth.setNoteOff(0, 60, 0);

% Reset modulation
synth.setModWheel(0, 0, 0, 0, 0, 0, 0, 0);
pause(0.5);

%% Example 15: Multi-Channel Harmony
fprintf('\n=== Example 15: Multi-Channel with Different Instruments ===\n');

% Set up different instruments on different channels
synth.setInstrument(0, 0, 0);   % Channel 0: Piano
synth.setInstrument(0, 1, 40);  % Channel 1: Violin
synth.setInstrument(0, 2, 56);  % Channel 2: Trumpet

% Set channel volumes
synth.setVolume(0, 100);
synth.setVolume(1, 90);
synth.setVolume(2, 80);

% Set different pan positions
synth.setPan(0, 40);   % Piano slightly left
synth.setPan(1, 64);   % Violin center
synth.setPan(2, 90);   % Trumpet slightly right

% Play 3-part harmony
fprintf('Playing 3-part harmony with different instruments...\n');
synth.setNoteOn(0, 60, 100);  % Piano: C
pause(0.3);
synth.setNoteOn(1, 64, 90);   % Violin: E
pause(0.3);
synth.setNoteOn(2, 67, 80);   % Trumpet: G
pause(2.0);

% Stop all channels
synth.setAllNotesOff(0);
synth.setAllNotesOff(1);
synth.setAllNotesOff(2);
pause(0.5);

%% Example 16: Drum Kit - setAllInstrumentDrums()
fprintf('\n=== Example 16: Drum Sounds ===\n');

% setAllInstrumentDrums() - Configures all channels for drum sounds
% After calling this, notes map to different drum sounds
synth.setAllInstrumentDrums();

% Common drum note mappings (General MIDI):
% 36=Bass Drum, 38=Snare, 42=Closed Hi-Hat, 46=Open Hi-Hat, 49=Crash Cymbal
fprintf('Playing drum pattern...\n');
drumNotes = [36, 38, 42, 38, 36, 36, 38, 42];  % Bass, Snare, Hi-hat pattern
for i = 1:length(drumNotes)
    synth.setNoteOn(0, drumNotes(i), 100);
    pause(0.15);
    synth.setNoteOff(0, drumNotes(i), 0);
end
pause(0.5);

% Reset back to normal instruments
synth.reset();
pause(0.5);

%% Example 17: Simple Melody (Twinkle Twinkle Little Star)
fprintf('\n=== Example 17: Playing a Melody ===\n');

synth.setInstrument(0, 0, 0);  % Piano
synth.setMasterVolume(100);

% Note numbers for the melody
melodyNotes = [60, 60, 67, 67, 69, 69, 67, ...  % Twinkle twinkle little star
               65, 65, 64, 64, 62, 62, 60];     % How I wonder what you are

% Duration for each note (in seconds)
melodyDurations = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, ...
                   0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0];

% Play the melody
fprintf('Playing "Twinkle Twinkle Little Star"...\n');
for i = 1:length(melodyNotes)
    synth.playNote(0, melodyNotes(i), melodyDurations(i), 100);
    pause(0.05);  % Small gap between notes
end
pause(0.5);

%% Example 18: System Reset - reset()
fprintf('\n=== Example 18: System Reset ===\n');

% reset() - Resets the synthesizer to default state
% This stops all playing notes and resets all parameters
fprintf('Resetting synthesizer...\n');
synth.reset();

%% Cleanup
fprintf('\n=== All Examples Complete! ===\n');
fprintf('All functions have been demonstrated.\n\n');

% Optionally clear objects (commented out to keep variables in workspace)
% clear synth esp32;

fprintf('Done!\n');
