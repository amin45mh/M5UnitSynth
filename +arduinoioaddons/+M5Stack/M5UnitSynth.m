classdef M5UnitSynth <  matlabshared.addon.LibraryBase & matlab.mixin.CustomDisplay
    % M5UnitSynth MATLAB Arduino Add-On for M5Unit-Synth
    %
    % This class provides MATLAB interface to the M5Unit-Synth, a 
    % synthesizer module based on the SAM2695 chip. It supports MIDI
    % instrument playback, note control, and various audio effects.
    %
    % Syntax:
    %   synth = M5UnitSynth(arduinoObj)
    %   synth = M5UnitSynth(arduinoObj, 'RXPin', rxPin, 'TXPin', txPin, 'BaudRate', baud)
    %
    % Properties:
    %   Parent - Arduino object
    %
    % Methods:
    %   initialize           - Initialize the M5UnitSynth module
    %   setInstrument        - Set MIDI instrument for a channel
    %   setVolume            - Set master volume
    %   noteOn               - Turn on a note
    %   noteOff              - Turn off a note
    %   allNotesOff          - Turn off all notes on a channel
    %   setChannelVolume     - Set volume for specific channel
    %   setBend              - Set pitch bend
    %   setTempo             - Set tempo in BPM
    %   setReverb            - Set reverb effect
    %   setBalance           - Set stereo balance (pan)
    %   setModulation        - Set modulation effect
    %   setSustain           - Set sustain pedal
    %   setTranspose         - Set transpose
    %   systemReset          - Reset the synthesizer
    %
    % Example:
    %   a = arduino('COM3', 'ESP32-WROOM-DevKitC', 'Libraries', 'M5Stack/M5UnitSynth', 'ForceBuildOn', true);
    %   synth = addon(a, 'M5Stack/M5UnitSynth');
    %   synth.initialize();
    %   synth.setInstrument(0, 0);  % Set channel 0 to piano
    %   synth.setVolume(100);       % Set volume to 100
    %   synth.noteOn(0, 60, 100);   % Play middle C
    %   pause(1);
    %   synth.noteOff(0, 60);       % Stop middle C
    %
    % See also: arduino, addon
    
    % Copyright 2024
    % Created for MATLAB Support Package for Arduino Hardware
    
    properties(Access = private, Constant = true)
        % Command IDs matching the C++ header file
        CMD_INIT                = 0x01
        CMD_SET_INSTRUMENT      = 0x02
        CMD_SET_MASTER_VOLUME   = 0x03
        CMD_SET_NOTE_ON         = 0x04
        CMD_SET_NOTE_OFF        = 0x05
        CMD_SET_ALL_NOTE_OFF    = 0x06
        CMD_SET_CHANNEL_VOLUME  = 0x07
        CMD_SET_PITCH_BEND      = 0x08
        CMD_SET_PAN             = 0x09
        CMD_SET_REVERB          = 0x0A
        CMD_SET_CHORUS          = 0x0B
        CMD_SET_TEMPO           = 0x0C
        CMD_SET_SUSTAIN         = 0x0D
        CMD_SET_TRANSPOSE       = 0x0E
        CMD_SET_MODULATION      = 0x0F
        CMD_SYSTEM_RESET        = 0x10
    end
    
    properties(Access = public)
        RXPin = 13;      % UART RX pin (default: 13 for Port C)
        TXPin = 14;      % UART TX pin (default: 14 for Port C)
        BaudRate = 31250; % UART baud rate (MIDI standard: 31250)
    end
    
    properties(Constant, Access = protected)
        LibraryName = 'M5Stack/M5UnitSynth'
        DependentLibraries = {}
        LibraryHeaderFiles = {'M5Unit-Synth/src/M5UnitSynth.h'}     % it looks at: C:\ProgramData\MATLAB\SupportPackages\R2025a\aCLI\user\libraries
        CppHeaderFile = fullfile(arduinoio.FilePath(mfilename('fullpath')), 'src', 'M5UnitML.h')
        CppClassName = 'M5UnitML'
    end

    methods
        function obj = M5UnitSynth(parentObj, varargin)
            % M5UnitSynth Constructor for M5UnitSynth add-on
            %
            % Syntax:
            %   synth = M5UnitSynth(arduinoObj)
            %   synth = M5UnitSynth(arduinoObj, 'RXPin', rxPin, 'TXPin', txPin, 'BaudRate', baud)
            %
            % Inputs:
            %   arduinoObj - Arduino object
            %   RXPin - (Optional) UART RX pin (default: 13 for Port C)
            %   TXPin - (Optional) UART TX pin (default: 14 for Port C)
            %   BaudRate - (Optional) UART baud rate (default: 31250 for MIDI)
            %   Port - (Optional) M5Stack port ('A', 'B', or 'C')
            %          Port A: RX=33, TX=32
            %          Port B: RX=36, TX=26  
            %          Port C: RX=13, TX=14 (default)
            
            obj.Parent = parentObj;
            
            % Parse optional inputs
            p = inputParser;
            addParameter(p, 'RXPin', 13, @(x) isnumeric(x) && x >= 0);
            addParameter(p, 'TXPin', 14, @(x) isnumeric(x) && x >= 0);
            addParameter(p, 'BaudRate', 31250, @(x) isnumeric(x) && x > 0);
            parse(p, varargin{:});
            
            obj.RXPin = p.Results.RXPin;
            obj.TXPin = p.Results.TXPin;
            obj.BaudRate = p.Results.BaudRate;
            
            % Initialize the device
            obj.initialize();
        end
        
        function success = initialize(obj, varargin)
            % INITIALIZE Initialize the M5UnitSynth module
            %
            % Syntax:
            %   success = initialize(synth)
            %   success = initialize(synth, rxPin, txPin, baudRate)
            %
            % Inputs:
            %   rxPin - (Optional) UART RX pin (default: uses obj.RXPin)
            %   txPin - (Optional) UART TX pin (default: uses obj.TXPin)
            %   baudRate - (Optional) UART baud rate (default: uses obj.BaudRate)
            %
            % Outputs:
            %   success - true if initialization successful, false otherwise
            
            if nargin > 1
                rxPin = varargin{1};
                txPin = varargin{2};
                baudRate = varargin{3};
            else
                rxPin = obj.RXPin;
                txPin = obj.TXPin;
                baudRate = obj.BaudRate;
            end
            
            % Send initialization command
            % dataIn[0] = RX pin, dataIn[1] = TX pin, dataIn[2-3] = Baud rate
            lsb = uint8(mod(baudRate, 256));
            msb = uint8(floor(baudRate / 256));
            data = uint8([rxPin, txPin, lsb, msb]);
            
            response = sendCommand(obj, obj.LibraryName, obj.CMD_INIT, data);
            
            success = (response(1) == 1);
            
            if ~success
                warning('M5UnitSynth:InitFailed', 'Failed to initialize M5UnitSynth. Check UART connections and pins.');
            end
        end
        
        function setInstrument(obj, channel, instrument, bank)
            % SETINSTRUMENT Set MIDI instrument for a channel
            %
            % Syntax:
            %   setInstrument(synth, channel, instrument)
            %   setInstrument(synth, channel, instrument, bank)
            %
            % Inputs:
            %   channel    - MIDI channel (0-15)
            %   instrument - MIDI instrument number (0-127)
            %                0 = Acoustic Grand Piano, 40 = Violin, etc.
            %   bank       - (Optional) MIDI bank (0-127), default = 0
            %
            % Example:
            %   synth.setInstrument(0, 0);      % Set channel 0 to piano, bank 0
            %   synth.setInstrument(1, 40);     % Set channel 1 to violin, bank 0
            %   synth.setInstrument(0, 0, 1);   % Set channel 0 to piano, bank 1
            
            if nargin < 4
                bank = 0;
            end
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setInstrument', 'channel');
            validateattributes(instrument, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setInstrument', 'instrument');
            validateattributes(bank, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setInstrument', 'bank');
            
            data = uint8([bank, channel, instrument]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_INSTRUMENT, data);
        end
        
        function setVolume(obj, volume)
            % SETVOLUME Set master volume
            %
            % Syntax:
            %   setVolume(synth, volume)
            %
            % Inputs:
            %   volume - Master volume (0-127), 0 = silent, 127 = maximum
            %
            % Example:
            %   synth.setVolume(100);  % Set volume to 100
            
            validateattributes(volume, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setVolume', 'volume');
            
            data = uint8(volume);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_MASTER_VOLUME, data);
        end
        
        function noteOn(obj, channel, note, velocity)
            % NOTEON Turn on a note
            %
            % Syntax:
            %   noteOn(synth, channel, note, velocity)
            %
            % Inputs:
            %   channel  - MIDI channel (0-15)
            %   note     - MIDI note number (0-127), 60 = Middle C
            %   velocity - Note velocity (0-127), affects volume/intensity
            %
            % Example:
            %   synth.noteOn(0, 60, 100);  % Play middle C on channel 0
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'noteOn', 'channel');
            validateattributes(note, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'noteOn', 'note');
            validateattributes(velocity, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'noteOn', 'velocity');
            
            data = uint8([channel, note, velocity]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_NOTE_ON, data);
        end
        
        function noteOff(obj, channel, note)
            % NOTEOFF Turn off a note
            %
            % Syntax:
            %   noteOff(synth, channel, note)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   note    - MIDI note number (0-127)
            %
            % Example:
            %   synth.noteOff(0, 60);  % Stop middle C on channel 0
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'noteOff', 'channel');
            validateattributes(note, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'noteOff', 'note');
            
            data = uint8([channel, note]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_NOTE_OFF, data);
        end
        
        function allNotesOff(obj, channel)
            % ALLNOTESOFF Turn off all notes on a channel
            %
            % Syntax:
            %   allNotesOff(synth, channel)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %
            % Example:
            %   synth.allNotesOff(0);  % Stop all notes on channel 0
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'allNotesOff', 'channel');
            
            data = uint8(channel);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_ALL_NOTE_OFF, data);
        end
        
        function setChannelVolume(obj, channel, volume)
            % SETCHANNELVOLUME Set volume for specific channel
            %
            % Syntax:
            %   setChannelVolume(synth, channel, volume)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   volume  - Channel volume (0-127)
            %
            % Example:
            %   synth.setChannelVolume(0, 80);  % Set channel 0 volume to 80
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setChannelVolume', 'channel');
            validateattributes(volume, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setChannelVolume', 'volume');
            
            data = uint8([channel, volume]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_CHANNEL_VOLUME, data);
        end
        
        function setBend(obj, channel, bendValue)
            % SETBEND Set pitch bend
            %
            % Syntax:
            %   setBend(synth, channel, bendValue)
            %
            % Inputs:
            %   channel   - MIDI channel (0-15)
            %   bendValue - Pitch bend value (0-16383), 8192 = center (no bend)
            %
            % Example:
            %   synth.setBend(0, 8192);  % No pitch bend
            %   synth.setBend(0, 10000); % Bend pitch up
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setBend', 'channel');
            validateattributes(bendValue, {'numeric'}, {'scalar', '>=', 0, '<=', 16383}, 'setBend', 'bendValue');
            
            % Split 16-bit value into two bytes (LSB first)
            lsb = uint8(mod(bendValue, 256));
            msb = uint8(floor(bendValue / 256));
            
            data = uint8([channel, lsb, msb]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_BEND, data);
        end
        
        function setTempo(obj, tempo)
            % SETTEMPO Set tempo in BPM
            %
            % Syntax:
            %   setTempo(synth, tempo)
            %
            % Inputs:
            %   tempo - Tempo in beats per minute (BPM), typically 40-240
            %
            % Example:
            %   synth.setTempo(120);  % Set tempo to 120 BPM
            
            validateattributes(tempo, {'numeric'}, {'scalar', '>', 0, '<', 500}, 'setTempo', 'tempo');
            
            % Split 16-bit value into two bytes (LSB first)
            lsb = uint8(mod(tempo, 256));
            msb = uint8(floor(tempo / 256));
            
            data = uint8([lsb, msb]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_TEMPO, data);
        end
        
        function setReverb(obj, channel, program, level, feedback)
            % SETREVERB Set reverb effect
            %
            % Syntax:
            %   setReverb(synth, channel, program, level, feedback)
            %
            % Inputs:
            %   channel  - MIDI channel (0-15)
            %   program  - Reverb type (0-7)
            %   level    - Reverb level (0-127), 0 = no reverb, 127 = maximum
            %   feedback - Delay feedback (0-127)
            %
            % Example:
            %   synth.setReverb(0, 0, 64, 50);  % Set moderate reverb on channel 0
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setReverb', 'channel');
            validateattributes(program, {'numeric'}, {'scalar', '>=', 0, '<=', 7}, 'setReverb', 'program');
            validateattributes(level, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setReverb', 'level');
            validateattributes(feedback, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setReverb', 'feedback');
            
            data = uint8([channel, program, level, feedback]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_REVERB, data);
        end

        function setBalance(obj, channel, balance)
            % SETBALANCE Set stereo balance (pan)
            %
            % Syntax:
            %   setBalance(synth, channel, balance)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   balance - Balance/pan (0-127), 0 = left, 64 = center, 127 = right
            %
            % Example:
            %   synth.setBalance(0, 64);  % Center balance on channel 0
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setBalance', 'channel');
            validateattributes(balance, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setBalance', 'balance');
            
            data = uint8([channel, balance]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_BALANCE, data);
        end
        
        function setModulation(obj, channel, level)
            % SETMODULATION Set modulation effect
            %
            % Syntax:
            %   setModulation(synth, channel, level)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   level   - Modulation level (0-127)
            %
            % Example:
            %   synth.setModulation(0, 50);  % Set modulation on channel 0
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setModulation', 'channel');
            validateattributes(level, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setModulation', 'level');
            
            data = uint8([channel, level]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_MODULATION, data);
        end
        
        function setSustain(obj, channel, onOff)
            % SETSUSTAIN Set sustain pedal
            %
            % Syntax:
            %   setSustain(synth, channel, onOff)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   onOff   - Sustain on (1 or true) or off (0 or false)
            %
            % Example:
            %   synth.setSustain(0, true);   % Turn on sustain
            %   synth.setSustain(0, false);  % Turn off sustain
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setSustain', 'channel');
            
            sustainValue = uint8(logical(onOff));
            data = uint8([channel, sustainValue]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_SUSTAIN, data);
        end
        
        function setTranspose(obj, semitones)
            % SETTRANSPOSE Set transpose
            %
            % Syntax:
            %   setTranspose(synth, semitones)
            %
            % Inputs:
            %   semitones - Transpose value in semitones (-12 to +12)
            %               Positive = higher pitch, Negative = lower pitch
            %
            % Example:
            %   synth.setTranspose(0);   % No transpose
            %   synth.setTranspose(12);  % Transpose up one octave
            %   synth.setTranspose(-5);  % Transpose down 5 semitones
            
            validateattributes(semitones, {'numeric'}, {'scalar', '>=', -12, '<=', 12}, 'setTranspose', 'semitones');
            
            % Convert to uint8 (two's complement for negative values)
            if semitones < 0
                transposeValue = uint8(256 + semitones);
            else
                transposeValue = uint8(semitones);
            end
            
            data = transposeValue;
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_TRANSPOSE, data);
        end
        
        function systemReset(obj)
            % SYSTEMRESET Reset the synthesizer to default state
            %
            % Syntax:
            %   systemReset(synth)
            %
            % This will stop all playing notes and reset all settings
            %
            % Example:
            %   synth.systemReset();
            
            data = uint8([]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SYSTEM_RESET, data);
        end
        
        function playNote(obj, channel, note, duration, velocity)
            % PLAYNOTE Play a note for a specified duration
            %
            % Syntax:
            %   playNote(synth, channel, note, duration)
            %   playNote(synth, channel, note, duration, velocity)
            %
            % Inputs:
            %   channel  - MIDI channel (0-15)
            %   note     - MIDI note number (0-127)
            %   duration - Duration in seconds
            %   velocity - (Optional) Note velocity (0-127), default = 100
            %
            % This is a convenience function that turns on a note, waits,
            % then turns it off.
            %
            % Example:
            %   synth.playNote(0, 60, 0.5);      % Play middle C for 0.5 seconds
            %   synth.playNote(0, 64, 1.0, 80);  % Play E for 1 second at velocity 80
            
            if nargin < 5
                velocity = 100;
            end
            
            obj.noteOn(channel, note, velocity);
            pause(duration);
            obj.noteOff(channel, note);
        end
    end
    
    methods(Access = protected)
        function output = sendCommand(obj, libName, commandID, inputs)
            % SENDCOMMAND Send command to Arduino
            try
                output = sendCommand@matlabshared.addon.LibraryBase(obj, libName, commandID, inputs);
            catch e
                error('M5UnitSynth:CommandFailed', 'Failed to send command to M5UnitSynth: %s', e.message);
            end
        end
    end
end

