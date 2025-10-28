%% Custom Arduino Add-On Library for the M5Unit-Synth by M5Stack
% ==================================================================================================
% M5UnitSynth class
% Copyright 2025, Amin Mohammadi
% Contact: aminmh@yorku.ca
% Version: 1.0.0
% Date: October 27, 2025
% This .m file interacts with the M5UnitML.h C header file uploaded to an M5Stack device.
% ==================================================================================================

%% References:
% M5Unit-Synth Hardware: https://docs.m5stack.com/en/unit/Unit-Synth
% SAM2695 Datasheet: https://m5stack.oss-cn-shenzhen.aliyuncs.com/resource/docs/products/unit/Unit-Synth/SAM2695.pdf
% CLASS DESCRIPTION: https://www.mathworks.com/help/matlab/arduinoio-custom-arduino-libraries.html
% CREATION STEPS: https://www.mathworks.com/help/matlab/supportpkg/create-custom-arduino-add-on-library.html

classdef M5UnitSynth <  matlabshared.addon.LibraryBase & matlab.mixin.CustomDisplay
    
    properties(Access = private, Constant = true)
        % Command IDs matching the C++ header file
        CMD_BEGIN                = 0x01
        CMD_SET_INSTRUMENT       = 0x02
        CMD_SET_NOTE_ON          = 0x03
        CMD_SET_NOTE_OFF         = 0x04
        CMD_SET_ALL_NOTE_OFF     = 0x05
        CMD_SET_PITCH_BEND       = 0x06
        CMD_SET_PITCH_BEND_RANGE = 0x07
        CMD_SET_MASTER_VOLUME    = 0x08
        CMD_SET_CHANNEL_VOLUME   = 0x09
        CMD_SET_EXPRESSION       = 0x0A
        CMD_SET_REVERB           = 0x0B
        CMD_SET_CHORUS           = 0x0C
        CMD_SET_PAN              = 0x0D
        CMD_SET_EQUALIZER        = 0x0E
        CMD_SET_TUNING           = 0x0F
        CMD_SET_VIBRATE          = 0x10
        CMD_SET_TVF              = 0x11
        CMD_SET_ENVELOPE         = 0x12
        CMD_SET_MOD_WHEEL        = 0x13
        CMD_SET_ALL_DRUMS        = 0x14
        CMD_RESET                = 0x15
    end
    
    properties(Access = public)
        RXPin = 16;       % UART RX pin (default: 16)
        TXPin = 17;       % UART TX pin (default: 17)
        BaudRate = 31250; % UART baud rate (MIDI standard: 31250)
    end
    
    properties(Constant, Access = protected)
        LibraryName = 'M5Stack/M5UnitSynth'
        DependentLibraries = {}
        LibraryHeaderFiles = {'M5Unit-Synth/src/M5UnitSynth.h'} % it looks at: C:\ProgramData\MATLAB\SupportPackages\R2025a\aCLI\user\libraries
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
            %   RXPin - (Optional) UART RX pin (default: 16)
            %   TXPin - (Optional) UART TX pin (default: 17)
            %   BaudRate - (Optional) UART baud rate (default: 31250 for MIDI)
            %
            % Common M5Stack port configurations:
            %   Port A: RX=33, TX=32
            %   Port B: RX=36, TX=26  
            %   Port C: RX=13, TX=14
            
            obj.Parent = parentObj;
            
            % Parse optional inputs
            p = inputParser;
            addParameter(p, 'RXPin', 16, @(x) isnumeric(x) && x >= 0);
            addParameter(p, 'TXPin', 17, @(x) isnumeric(x) && x >= 0);
            addParameter(p, 'BaudRate', 31250, @(x) isnumeric(x) && x > 0);
            parse(p, varargin{:});
            
            obj.RXPin = p.Results.RXPin;
            obj.TXPin = p.Results.TXPin;
            obj.BaudRate = p.Results.BaudRate;
            
            % Initialize the device
            obj.begin(obj.RXPin, obj.TXPin, obj.BaudRate);
        end
        
        function success = begin(obj, rxPin, txPin, baudRate)
            % BEGIN Initialize the M5UnitSynth module with UART
            %
            % Syntax:
            %   success = begin(synth)
            %   success = begin(synth, rxPin, txPin)
            %   success = begin(synth, rxPin, txPin, baudRate)
            %
            % Inputs:
            %   rxPin - (Optional) UART RX pin (default: uses obj.RXPin)
            %   txPin - (Optional) UART TX pin (default: uses obj.TXPin)
            %   baudRate - (Optional) UART baud rate (default: uses obj.BaudRate)
            %
            % Outputs:
            %   success - true if initialization successful, false otherwise
            %
            % Example:
            %   synth.begin(13, 14);           % Use Port C
            %   synth.begin(13, 14, 31250);    % Specify baud rate
            
            if nargin < 2
                rxPin = obj.RXPin;
            end
            if nargin < 3
                txPin = obj.TXPin;
            end
            if nargin < 4
                baudRate = obj.BaudRate;
            end
            
            % Send begin command
            % dataIn[0] = RX pin, dataIn[1] = TX pin, dataIn[2-3] = Baud rate
            lsb = uint8(mod(baudRate, 256));
            msb = uint8(floor(baudRate / 256));
            data = uint8([rxPin, txPin, lsb, msb]);
            
            response = sendCommand(obj, obj.LibraryName, obj.CMD_BEGIN, data);
            
            success = (response(1) == 1);
            
            if ~success
                warning('M5UnitSynth:BeginFailed', 'Failed to initialize M5UnitSynth. Check UART connections and pins.');
            end
        end
        
        function setInstrument(obj, bank, channel, instrument)
            % SETINSTRUMENT Set MIDI instrument for a channel
            %
            % Syntax:
            %   setInstrument(synth, bank, channel, instrument)
            %
            % Inputs:
            %   bank       - MIDI bank (0-127), usually 0 for GM sounds
            %   channel    - MIDI channel (0-15)
            %   instrument - MIDI instrument number (0-127)
            %                0 = Acoustic Grand Piano, 40 = Violin, etc.
            %
            % Example:
            %   synth.setInstrument(0, 0, 0);   % Bank 0, Channel 0, Piano
            %   synth.setInstrument(0, 1, 40);  % Bank 0, Channel 1, Violin
            
            validateattributes(bank, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setInstrument', 'bank');
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setInstrument', 'channel');
            validateattributes(instrument, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setInstrument', 'instrument');
            
            data = uint8([bank, channel, instrument]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_INSTRUMENT, data);
        end
        
        function setNoteOn(obj, channel, pitch, velocity)
            % SETNOTEON Turn on a note
            %
            % Syntax:
            %   setNoteOn(synth, channel, pitch, velocity)
            %
            % Inputs:
            %   channel  - MIDI channel (0-15)
            %   pitch    - MIDI note number (0-127), 60 = Middle C
            %   velocity - Note velocity (0-127), affects volume/intensity
            %
            % Example:
            %   synth.setNoteOn(0, 60, 100);  % Play middle C on channel 0
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setNoteOn', 'channel');
            validateattributes(pitch, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setNoteOn', 'pitch');
            validateattributes(velocity, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setNoteOn', 'velocity');
            
            data = uint8([channel, pitch, velocity]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_NOTE_ON, data);
        end
        
        function setNoteOff(obj, channel, pitch, velocity)
            % SETNOTEOFF Turn off a note
            %
            % Syntax:
            %   setNoteOff(synth, channel, pitch, velocity)
            %
            % Inputs:
            %   channel  - MIDI channel (0-15)
            %   pitch    - MIDI note number (0-127)
            %   velocity - Release velocity (0-127), usually 0
            %
            % Example:
            %   synth.setNoteOff(0, 60, 0);  % Stop middle C on channel 0
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setNoteOff', 'channel');
            validateattributes(pitch, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setNoteOff', 'pitch');
            validateattributes(velocity, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setNoteOff', 'velocity');
            
            data = uint8([channel, pitch, velocity]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_NOTE_OFF, data);
        end
        
        function setAllNotesOff(obj, channel)
            % SETALLNOTESOFF Turn off all notes on a channel
            %
            % Syntax:
            %   setAllNotesOff(synth, channel)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %
            % Example:
            %   synth.setAllNotesOff(0);  % Stop all notes on channel 0
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setAllNotesOff', 'channel');
            
            data = uint8(channel);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_ALL_NOTE_OFF, data);
        end
        
        function setPitchBend(obj, channel, value)
            % SETPITCHBEND Set pitch bend
            %
            % Syntax:
            %   setPitchBend(synth, channel, value)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   value   - Pitch bend value (-8192 to +8191), 0 = center (no bend)
            %             Positive = bend up, Negative = bend down
            %
            % Example:
            %   synth.setPitchBend(0, 0);     % No pitch bend
            %   synth.setPitchBend(0, 4096);  % Bend pitch up
            %   synth.setPitchBend(0, -4096); % Bend pitch down
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setPitchBend', 'channel');
            validateattributes(value, {'numeric'}, {'scalar', '>=', -8192, '<=', 8191}, 'setPitchBend', 'value');
            
            % Convert to int16 and split into bytes (LSB first)
            int16Val = int16(value);
            lsb = uint8(bitand(int16Val, int16(0xFF)));
            msb = uint8(bitand(bitshift(int16Val, -8), int16(0xFF)));
            
            data = uint8([channel, lsb, msb]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_PITCH_BEND, data);
        end
        
        function setPitchBendRange(obj, channel, value)
            % SETPITCHBENDRANGE Set pitch bend range in semitones
            %
            % Syntax:
            %   setPitchBendRange(synth, channel, value)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   value   - Pitch bend range in semitones (0-127), default is usually 2
            %
            % Example:
            %   synth.setPitchBendRange(0, 2);   % ±2 semitones
            %   synth.setPitchBendRange(0, 12);  % ±1 octave
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setPitchBendRange', 'channel');
            validateattributes(value, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setPitchBendRange', 'value');
            
            data = uint8([channel, value]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_PITCH_BEND_RANGE, data);
        end
        
        function setMasterVolume(obj, level)
            % SETMASTERVOLUME Set master volume
            %
            % Syntax:
            %   setMasterVolume(synth, level)
            %
            % Inputs:
            %   level - Master volume (0-127), 0 = silent, 127 = maximum
            %
            % Example:
            %   synth.setMasterVolume(100);  % Set volume to 100
            
            validateattributes(level, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setMasterVolume', 'level');
            
            data = uint8(level);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_MASTER_VOLUME, data);
        end
        
        function setVolume(obj, channel, level)
            % SETVOLUME Set volume for specific channel
            %
            % Syntax:
            %   setVolume(synth, channel, level)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   level   - Channel volume (0-127)
            %
            % Example:
            %   synth.setVolume(0, 80);  % Set channel 0 volume to 80
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setVolume', 'channel');
            validateattributes(level, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setVolume', 'level');
            
            data = uint8([channel, level]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_CHANNEL_VOLUME, data);
        end
        
        function setExpression(obj, channel, expression)
            % SETEXPRESSION Set expression (dynamics control)
            %
            % Syntax:
            %   setExpression(synth, channel, expression)
            %
            % Inputs:
            %   channel    - MIDI channel (0-15)
            %   expression - Expression level (0-127), controls dynamics
            %
            % Example:
            %   synth.setExpression(0, 100);  % High expression
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setExpression', 'channel');
            validateattributes(expression, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setExpression', 'expression');
            
            data = uint8([channel, expression]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_EXPRESSION, data);
        end
        
        function setReverb(obj, channel, program, level, delayfeedback)
            % SETREVERB Set reverb effect
            %
            % Syntax:
            %   setReverb(synth, channel, program, level, delayfeedback)
            %
            % Inputs:
            %   channel       - MIDI channel (0-15)
            %   program       - Reverb type (0-127)
            %   level         - Reverb level (0-127), 0 = no reverb, 127 = maximum
            %   delayfeedback - Delay feedback (0-127)
            %
            % Example:
            %   synth.setReverb(0, 0, 64, 50);  % Moderate reverb on channel 0
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setReverb', 'channel');
            validateattributes(program, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setReverb', 'program');
            validateattributes(level, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setReverb', 'level');
            validateattributes(delayfeedback, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setReverb', 'delayfeedback');
            
            data = uint8([channel, program, level, delayfeedback]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_REVERB, data);
        end
        
        function setChorus(obj, channel, program, level, feedback, chorusdelay)
            % SETCHORUS Set chorus effect
            %
            % Syntax:
            %   setChorus(synth, channel, program, level, feedback, chorusdelay)
            %
            % Inputs:
            %   channel     - MIDI channel (0-15)
            %   program     - Chorus type (0-127)
            %   level       - Chorus level (0-127)
            %   feedback    - Feedback (0-127)
            %   chorusdelay - Chorus delay (0-127)
            %
            % Example:
            %   synth.setChorus(0, 0, 64, 50, 30);  % Moderate chorus
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setChorus', 'channel');
            validateattributes(program, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setChorus', 'program');
            validateattributes(level, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setChorus', 'level');
            validateattributes(feedback, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setChorus', 'feedback');
            validateattributes(chorusdelay, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setChorus', 'chorusdelay');
            
            data = uint8([channel, program, level, feedback, chorusdelay]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_CHORUS, data);
        end
        
        function setPan(obj, channel, value)
            % SETPAN Set stereo pan/balance
            %
            % Syntax:
            %   setPan(synth, channel, value)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   value   - Pan value (0-127), 0 = left, 64 = center, 127 = right
            %
            % Example:
            %   synth.setPan(0, 64);   % Center
            %   synth.setPan(0, 0);    % Full left
            %   synth.setPan(0, 127);  % Full right
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setPan', 'channel');
            validateattributes(value, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setPan', 'value');
            
            data = uint8([channel, value]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_PAN, data);
        end
        
        function setEqualizer(obj, channel, lowband, medlowband, medhighband, highband, lowfreq, medlowfreq, medhighfreq, highfreq)
            % SETEQUALIZER Set equalizer bands and frequencies
            %
            % Syntax:
            %   setEqualizer(synth, channel, lowband, medlowband, medhighband, highband, 
            %                lowfreq, medlowfreq, medhighfreq, highfreq)
            %
            % Inputs:
            %   channel      - MIDI channel (0-15)
            %   lowband      - Low band gain (0-127)
            %   medlowband   - Mid-low band gain (0-127)
            %   medhighband  - Mid-high band gain (0-127)
            %   highband     - High band gain (0-127)
            %   lowfreq      - Low band frequency (0-127)
            %   medlowfreq   - Mid-low band frequency (0-127)
            %   medhighfreq  - Mid-high band frequency (0-127)
            %   highfreq     - High band frequency (0-127)
            %
            % Example:
            %   synth.setEqualizer(0, 64, 64, 64, 64, 32, 48, 80, 96);
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setEqualizer', 'channel');
            validateattributes(lowband, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setEqualizer', 'lowband');
            validateattributes(medlowband, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setEqualizer', 'medlowband');
            validateattributes(medhighband, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setEqualizer', 'medhighband');
            validateattributes(highband, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setEqualizer', 'highband');
            validateattributes(lowfreq, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setEqualizer', 'lowfreq');
            validateattributes(medlowfreq, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setEqualizer', 'medlowfreq');
            validateattributes(medhighfreq, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setEqualizer', 'medhighfreq');
            validateattributes(highfreq, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setEqualizer', 'highfreq');
            
            data = uint8([channel, lowband, medlowband, medhighband, highband, lowfreq, medlowfreq, medhighfreq, highfreq]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_EQUALIZER, data);
        end
        
        function setTuning(obj, channel, fine, coarse)
            % SETTUNING Set fine and coarse tuning
            %
            % Syntax:
            %   setTuning(synth, channel, fine, coarse)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   fine    - Fine tuning (0-127), 64 = default/center
            %   coarse  - Coarse tuning (0-127), 64 = default/center
            %
            % Example:
            %   synth.setTuning(0, 64, 64);  % Default tuning
            %   synth.setTuning(0, 70, 64);  % Slightly sharp
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setTuning', 'channel');
            validateattributes(fine, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setTuning', 'fine');
            validateattributes(coarse, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setTuning', 'coarse');
            
            data = uint8([channel, fine, coarse]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_TUNING, data);
        end
        
        function setVibrate(obj, channel, rate, depth, delay)
            % SETVIBRATE Set vibrato parameters
            %
            % Syntax:
            %   setVibrate(synth, channel, rate, depth, delay)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   rate    - Vibrato rate (0-127)
            %   depth   - Vibrato depth (0-127)
            %   delay   - Vibrato delay (0-127)
            %
            % Example:
            %   synth.setVibrate(0, 50, 40, 20);  % Moderate vibrato
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setVibrate', 'channel');
            validateattributes(rate, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setVibrate', 'rate');
            validateattributes(depth, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setVibrate', 'depth');
            validateattributes(delay, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setVibrate', 'delay');
            
            data = uint8([channel, rate, depth, delay]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_VIBRATE, data);
        end
        
        function setTvf(obj, channel, cutoff, resonance)
            % SETTVF Set time variant filter
            %
            % Syntax:
            %   setTvf(synth, channel, cutoff, resonance)
            %
            % Inputs:
            %   channel   - MIDI channel (0-15)
            %   cutoff    - Filter cutoff frequency (0-127)
            %   resonance - Filter resonance (0-127)
            %
            % Example:
            %   synth.setTvf(0, 64, 40);  % Moderate filter
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setTvf', 'channel');
            validateattributes(cutoff, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setTvf', 'cutoff');
            validateattributes(resonance, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setTvf', 'resonance');
            
            data = uint8([channel, cutoff, resonance]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_TVF, data);
        end
        
        function setEnvelope(obj, channel, attack, decay, release)
            % SETENVELOPE Set ADSR envelope parameters
            %
            % Syntax:
            %   setEnvelope(synth, channel, attack, decay, release)
            %
            % Inputs:
            %   channel - MIDI channel (0-15)
            %   attack  - Attack time (0-127)
            %   decay   - Decay time (0-127)
            %   release - Release time (0-127)
            %
            % Example:
            %   synth.setEnvelope(0, 20, 40, 30);  % Fast attack, moderate decay/release
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setEnvelope', 'channel');
            validateattributes(attack, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setEnvelope', 'attack');
            validateattributes(decay, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setEnvelope', 'decay');
            validateattributes(release, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setEnvelope', 'release');
            
            data = uint8([channel, attack, decay, release]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_ENVELOPE, data);
        end
        
        function setModWheel(obj, channel, pitch, tvtcutoff, amplitude, rate, pitchdepth, tvfdepth, tvadepth)
            % SETMODWHEEL Set modulation wheel parameters
            %
            % Syntax:
            %   setModWheel(synth, channel, pitch, tvtcutoff, amplitude, rate, 
            %               pitchdepth, tvfdepth, tvadepth)
            %
            % Inputs:
            %   channel    - MIDI channel (0-15)
            %   pitch      - Pitch modulation (0-127)
            %   tvtcutoff  - TVT cutoff modulation (0-127)
            %   amplitude  - Amplitude modulation (0-127)
            %   rate       - Modulation rate (0-127)
            %   pitchdepth - Pitch depth (0-127)
            %   tvfdepth   - TVF depth (0-127)
            %   tvadepth   - TVA depth (0-127)
            %
            % Example:
            %   synth.setModWheel(0, 64, 50, 60, 40, 50, 50, 50);
            
            validateattributes(channel, {'numeric'}, {'scalar', '>=', 0, '<=', 15}, 'setModWheel', 'channel');
            validateattributes(pitch, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setModWheel', 'pitch');
            validateattributes(tvtcutoff, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setModWheel', 'tvtcutoff');
            validateattributes(amplitude, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setModWheel', 'amplitude');
            validateattributes(rate, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setModWheel', 'rate');
            validateattributes(pitchdepth, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setModWheel', 'pitchdepth');
            validateattributes(tvfdepth, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setModWheel', 'tvfdepth');
            validateattributes(tvadepth, {'numeric'}, {'scalar', '>=', 0, '<=', 127}, 'setModWheel', 'tvadepth');
            
            data = uint8([channel, pitch, tvtcutoff, amplitude, rate, pitchdepth, tvfdepth, tvadepth]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_MOD_WHEEL, data);
        end
        
        function setAllInstrumentDrums(obj)
            % SETALLINSTRUMENTDRUMS Set all instruments to drums
            %
            % Syntax:
            %   setAllInstrumentDrums(synth)
            %
            % This sets all channels to use drum sounds
            %
            % Example:
            %   synth.setAllInstrumentDrums();
            
            data = uint8([]);
            sendCommand(obj, obj.LibraryName, obj.CMD_SET_ALL_DRUMS, data);
        end
        
        function reset(obj)
            % RESET Reset the synthesizer to default state
            %
            % Syntax:
            %   reset(synth)
            %
            % This will stop all playing notes and reset all settings
            %
            % Example:
            %   synth.reset();
            
            data = uint8([]);
            sendCommand(obj, obj.LibraryName, obj.CMD_RESET, data);
        end
        
        function playNote(obj, channel, pitch, duration, velocity)
            % PLAYNOTE Play a note for a specified duration
            %
            % Syntax:
            %   playNote(synth, channel, pitch, duration)
            %   playNote(synth, channel, pitch, duration, velocity)
            %
            % Inputs:
            %   channel  - MIDI channel (0-15)
            %   pitch    - MIDI note number (0-127)
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
            
            obj.setNoteOn(channel, pitch, velocity);
            pause(duration);
            obj.setNoteOff(channel, pitch, 0);
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
