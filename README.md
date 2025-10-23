# M5UnitSynth MATLAB Arduino Add-On Library

A custom MATLAB Arduino add-on library for the M5Stack M5Unit-Synth module. This library enables control of the SAM2695-based synthesizer module directly from MATLAB, supporting MIDI instrument playback, note control, and various audio effects.

## Features

- **MIDI Instrument Support**: Access to 128 General MIDI instruments
- **Multi-Channel Control**: Support for 16 MIDI channels
- **Note Control**: Play and stop individual notes with velocity control
- **Audio Effects**: Reverb, modulation, balance (pan), and pitch bend
- **Volume Control**: Master volume and per-channel volume control
- **Sustain Pedal**: Sustain pedal simulation for expressive playing
- **Transpose**: Global transpose functionality
- **Tempo Control**: Adjustable tempo for rhythm-based applications

## Hardware Requirements

- **M5Stack M5Unit-Synth**: SAM2695-based synthesizer module
- **Arduino Board**: ESP32-based board (e.g., ESP32-WROOM-DevKitC, M5Stack Core2)
- **Connection**: UART interface (default: RX=13, TX=14, Baud=31250)
- **Power**: 5V supply for M5Unit-Synth module

## Software Requirements

- **MATLAB**: R2025a or newer
- **MATLAB Support Package for Arduino Hardware**: Install from Add-On Explorer
- **Arduino-CLI**: Automatically installed with MATLAB Support Package

## Installation

### Step 1: Install MATLAB Support Package

1. Open MATLAB
2. Go to **Home** > **Add-Ons** > **Get Hardware Support Packages**
3. Search for "MATLAB Support Package for Arduino Hardware"
4. Click **Install** and follow the prompts

### Step 2: Install Arduino Libraries

Run the provided installation script to download required Arduino libraries from GitHub:

```matlab
% Navigate to the project directory
cd('path\to\M5UnitSynth')

% Run the installation script
run('Utilities\installArduinoLibsFromGitHub.m')
```

This script will automatically download and install:
- **M5Unified**: Core M5Stack library
- **M5GFX**: Graphics library (dependency for M5Unified)
- **M5Unit-Synth**: The synthesizer library
- **Adafruit_NeoPixel**: (Optional) For NeoPixel support

### Step 3: Add Library to MATLAB Path

Add the custom add-on folder to your MATLAB path:

```matlab
% Add the folder containing +arduinoioaddons
addpath('path\to\M5UnitSynth')
savepath  % Save the path permanently
```

### Step 4: Verify Installation

Check if the library is properly registered:

```matlab
listArduinoLibraries
```

You should see `M5Stack/M5UnitSynth` in the list of available libraries.

## Quick Start

### Basic Example

```matlab
% Create Arduino object with M5UnitSynth library
% Replace 'COM3' with your Arduino port and 'ESP32-WROOM-DevKitC' with your board type
a = arduino('COM3', 'ESP32-WROOM-DevKitC', 'Libraries', 'M5Stack/M5UnitSynth', 'ForceBuildOn', true);

% Create M5UnitSynth add-on object with explicit pin configuration
% RX=13, TX=14 for Port C (default M5Stack configuration)
synth = addon(a, 'M5Stack/M5UnitSynth', 'RXPin', 13, 'TXPin', 14);

% Initialize the synthesizer
synth.initialize();

% Set instrument to Acoustic Grand Piano (0) on channel 0
synth.setInstrument(0, 0);

% Set master volume
synth.setVolume(100);

% Play middle C (note 60) for 1 second
synth.noteOn(0, 60, 100);   % channel, note, velocity
pause(1);
synth.noteOff(0, 60);

% Play a simple melody
notes = [60, 62, 64, 65, 67, 69, 71, 72];  % C major scale
for note = notes
    synth.playNote(0, note, 0.5);  % channel, note, duration
end

% Clean up
clear synth a
```

### Playing a Chord

```matlab
% Set instrument to Acoustic Grand Piano
synth.setInstrument(0, 0);

% Play a C major chord (C-E-G)
synth.noteOn(0, 60, 100);  % C
synth.noteOn(0, 64, 100);  % E
synth.noteOn(0, 67, 100);  % G

pause(2);

% Stop all notes
synth.allNotesOff(0);
```

### Pin Configuration Options

The M5UnitSynth library supports flexible UART pin configuration for different M5Stack setups:

```matlab
% Method 1: Explicit pin configuration (recommended)
synth = addon(arduinoObj, 'M5Stack/M5UnitSynth', 'RXPin', 13, 'TXPin', 14);

% Method 2: Port-based configuration (alternative)
synth = addon(arduinoObj, 'M5Stack/M5UnitSynth', 'Port', 'C');

% Method 3: Runtime port change
synth = addon(arduinoObj, 'M5Stack/M5UnitSynth');
synth.setPort('A');  % Change to Port A (RX=33, TX=32)
synth.initialize();
```

**Pin Configurations:**
- **Port A**: RX=33, TX=32
- **Port B**: RX=36, TX=26  
- **Port C**: RX=13, TX=14 (default)

### Using Different Instruments

```matlab
% Set channel 0 to Piano
synth.setInstrument(0, 0);

% Set channel 1 to Violin
synth.setInstrument(1, 40);

% Set channel 2 to Trumpet
synth.setInstrument(2, 56);

% Play different instruments simultaneously
synth.noteOn(0, 60, 100);  % Piano plays C
synth.noteOn(1, 64, 100);  % Violin plays E
synth.noteOn(2, 67, 100);  % Trumpet plays G

pause(2);
synth.allNotesOff(0);
synth.allNotesOff(1);
synth.allNotesOff(2);
```

### Adding Effects

```matlab
% Set instrument
synth.setInstrument(0, 0);

% Add reverb
synth.setReverb(0, 80);

% Set pan to left
synth.setBalance(0, 0);

% Play with effects
synth.playNote(0, 60, 1.0);
```

## API Reference

### Constructor

#### `M5UnitSynth(arduinoObj)`
Creates a new M5UnitSynth object.

**Parameters:**
- `arduinoObj`: Arduino object with M5Stack/M5UnitML library
- `'I2CAddress'` (optional): I2C address of the device (default: 83 = 0x53)

### Methods

#### `initialize([i2cAddress])`
Initialize the M5UnitSynth module.

**Parameters:**
- `i2cAddress` (optional): I2C address (default: uses object's I2CAddress property)

**Returns:**
- `success`: true if initialization successful, false otherwise

---

#### `setInstrument(channel, instrument)`
Set MIDI instrument for a channel.

**Parameters:**
- `channel`: MIDI channel (0-15)
- `instrument`: MIDI instrument number (0-127)
  - 0 = Acoustic Grand Piano
  - 40 = Violin
  - 56 = Trumpet
  - [See full MIDI instrument list](#midi-instruments)

---

#### `setVolume(volume)`
Set master volume.

**Parameters:**
- `volume`: Master volume (0-127), 0 = silent, 127 = maximum

---

#### `noteOn(channel, note, velocity)`
Turn on a note.

**Parameters:**
- `channel`: MIDI channel (0-15)
- `note`: MIDI note number (0-127), 60 = Middle C
- `velocity`: Note velocity (0-127), affects volume/intensity

---

#### `noteOff(channel, note)`
Turn off a note.

**Parameters:**
- `channel`: MIDI channel (0-15)
- `note`: MIDI note number (0-127)

---

#### `allNotesOff(channel)`
Turn off all notes on a channel.

**Parameters:**
- `channel`: MIDI channel (0-15)

---

#### `setChannelVolume(channel, volume)`
Set volume for a specific channel.

**Parameters:**
- `channel`: MIDI channel (0-15)
- `volume`: Channel volume (0-127)

---

#### `setBend(channel, bendValue)`
Set pitch bend.

**Parameters:**
- `channel`: MIDI channel (0-15)
- `bendValue`: Pitch bend value (0-16383), 8192 = center (no bend)

---

#### `setTempo(tempo)`
Set tempo in BPM.

**Parameters:**
- `tempo`: Tempo in beats per minute (typically 40-240)

---

#### `setReverb(channel, level)`
Set reverb effect.

**Parameters:**
- `channel`: MIDI channel (0-15)
- `level`: Reverb level (0-127), 0 = no reverb, 127 = maximum

---

#### `setBalance(channel, balance)`
Set stereo balance (pan).

**Parameters:**
- `channel`: MIDI channel (0-15)
- `balance`: Balance/pan (0-127), 0 = left, 64 = center, 127 = right

---

#### `setModulation(channel, level)`
Set modulation effect.

**Parameters:**
- `channel`: MIDI channel (0-15)
- `level`: Modulation level (0-127)

---

#### `setSustain(channel, onOff)`
Set sustain pedal.

**Parameters:**
- `channel`: MIDI channel (0-15)
- `onOff`: Sustain on (1 or true) or off (0 or false)

---

#### `setTranspose(semitones)`
Set global transpose.

**Parameters:**
- `semitones`: Transpose value in semitones (-12 to +12)
  - Positive = higher pitch
  - Negative = lower pitch

---

#### `systemReset()`
Reset the synthesizer to default state. Stops all playing notes and resets all settings.

---

#### `playNote(channel, note, duration, [velocity])`
Convenience function to play a note for a specified duration.

**Parameters:**
- `channel`: MIDI channel (0-15)
- `note`: MIDI note number (0-127)
- `duration`: Duration in seconds
- `velocity` (optional): Note velocity (0-127), default = 100

## MIDI Instruments

Here are some common MIDI instruments (0-127):

### Piano (0-7)
- 0: Acoustic Grand Piano
- 1: Bright Acoustic Piano
- 2: Electric Grand Piano
- 3: Honky-tonk Piano

### Chromatic Percussion (8-15)
- 8: Celesta
- 9: Glockenspiel
- 11: Vibraphone
- 12: Marimba

### Organ (16-23)
- 16: Drawbar Organ
- 17: Percussive Organ
- 19: Church Organ

### Guitar (24-31)
- 24: Acoustic Guitar (nylon)
- 25: Acoustic Guitar (steel)
- 26: Electric Guitar (jazz)
- 27: Electric Guitar (clean)
- 29: Overdriven Guitar
- 30: Distortion Guitar

### Bass (32-39)
- 32: Acoustic Bass
- 33: Electric Bass (finger)
- 34: Electric Bass (pick)

### Strings (40-47)
- 40: Violin
- 41: Viola
- 42: Cello
- 43: Contrabass
- 46: Orchestral Harp
- 47: Timpani

### Ensemble (48-55)
- 48: String Ensemble 1
- 49: String Ensemble 2
- 52: Choir Aahs
- 53: Voice Oohs

### Brass (56-63)
- 56: Trumpet
- 57: Trombone
- 58: Tuba
- 60: French Horn
- 61: Brass Section

### Reed (64-71)
- 64: Soprano Sax
- 65: Alto Sax
- 66: Tenor Sax
- 67: Baritone Sax
- 68: Oboe
- 71: Clarinet

### Pipe (72-79)
- 72: Piccolo
- 73: Flute
- 74: Recorder
- 75: Pan Flute

### Synth Lead (80-87)
- 80: Lead 1 (square)
- 81: Lead 2 (sawtooth)

### Synth Pad (88-95)
- 88: Pad 1 (new age)
- 89: Pad 2 (warm)

### Percussive (112-119)
- 112: Tinkle Bell
- 113: Agogo
- 114: Steel Drums
- 115: Woodblock
- 116: Taiko Drum

## MIDI Note Numbers

Middle C = 60

| Note | Number | Note | Number | Note | Number |
|------|--------|------|--------|------|--------|
| C0   | 12     | C3   | 48     | C6   | 84     |
| C#0  | 13     | C#3  | 49     | C#6  | 85     |
| D0   | 14     | D3   | 50     | D6   | 86     |
| E0   | 16     | E3   | 52     | E6   | 88     |
| F0   | 17     | F3   | 53     | F6   | 89     |
| G0   | 19     | G3   | 55     | G6   | 91     |
| A0   | 21     | A3   | 57     | A6   | 93     |
| B0   | 23     | B3   | 59     | B6   | 95     |
| C1   | 24     | C4   | 60     | C7   | 96     |
| C2   | 36     | C5   | 72     | C8   | 108    |

## Command IDs Reference

The following command IDs are used for communication between MATLAB and Arduino:

| Command ID | Hex  | Function            |
|------------|------|---------------------|
| 1          | 0x01 | Initialize          |
| 2          | 0x02 | Set Instrument      |
| 3          | 0x03 | Set Volume          |
| 4          | 0x04 | Note On             |
| 5          | 0x05 | Note Off            |
| 6          | 0x06 | All Notes Off       |
| 7          | 0x07 | Set Channel Volume  |
| 8          | 0x08 | Set Bend            |
| 9          | 0x09 | Set Tempo           |
| 10         | 0x0A | Play Melody         |
| 11         | 0x0B | Stop Melody         |
| 12         | 0x0C | Set Reverb          |
| 13         | 0x0D | Set Balance         |
| 14         | 0x0E | Set Modulation      |
| 15         | 0x0F | Set Sustain         |
| 16         | 0x10 | Set Transpose       |
| 17         | 0x11 | System Reset        |

## Troubleshooting

### Library Not Found

**Problem**: `'M5Stack/M5UnitSynth' not found in listArduinoLibraries`

**Solution**:
1. Verify the folder structure:
   ```
   M5UnitSynth\
   ├── +arduinoioaddons\
   │   └── +M5Stack\
   │       ├── M5UnitSynth.m
   │       └── src\
   │           └── M5UnitML.h
   ```
2. Ensure the folder is added to MATLAB path: `addpath('path\to\M5UnitSynth')`
3. Restart MATLAB

### Initialization Failed

**Problem**: `Failed to initialize M5UnitSynth`

**Solution**:
1. Check UART connections (RX, TX, VCC, GND)
2. Verify pin configuration matches your setup:
   - Port A: RX=33, TX=32
   - Port B: RX=36, TX=26  
   - Port C: RX=13, TX=14 (default)
3. Try different pin configuration: `synth = addon(arduinoObj, 'M5Stack/M5UnitSynth', 'RXPin', 33, 'TXPin', 32)`
4. Check if other UART devices are conflicting

### Build Failed

**Problem**: Errors during `arduino()` object creation with `'ForceBuildOn', true`

**Solution**:
1. Ensure all Arduino libraries are installed (run `installArduinoLibsFromGitHub.m`)
2. Check that M5Unit-Synth library is in Arduino CLI libraries folder:
   ```matlab
   fullfile(arduinoio.CLIRoot, 'user', 'libraries', 'M5Unit-Synth')
   ```
3. Try clearing the Arduino build cache:
   ```matlab
   clearArduinoCache('all')
   ```

### No Sound Output

**Problem**: Commands execute but no sound is produced

**Solution**:
1. Check volume settings: `synth.setVolume(127)`
2. Check channel volume: `synth.setChannelVolume(0, 127)`
3. Verify audio connections on M5Unit-Synth module
4. Try system reset: `synth.systemReset()`

## Examples

### Example 1: Simple Melody Player

```matlab
% Create and initialize
a = arduino('COM3', 'Uno', 'Libraries', 'M5Stack/M5UnitML', 'ForceBuildOn', true);
synth = addon(a, 'M5Stack/M5UnitML');
synth.initialize();

% Setup
synth.setInstrument(0, 0);  % Piano
synth.setVolume(100);

% Twinkle Twinkle Little Star
notes = [60,60,67,67,69,69,67, 65,65,64,64,62,62,60];
durations = [0.5,0.5,0.5,0.5,0.5,0.5,1, 0.5,0.5,0.5,0.5,0.5,0.5,1];

for i = 1:length(notes)
    synth.playNote(0, notes(i), durations(i), 100);
end
```

### Example 2: Multi-Instrument Composition

```matlab
% Initialize
synth.initialize();

% Setup channels
synth.setInstrument(0, 0);   % Piano
synth.setInstrument(1, 40);  % Violin
synth.setInstrument(2, 56);  % Trumpet

% Set volumes
synth.setChannelVolume(0, 100);
synth.setChannelVolume(1, 80);
synth.setChannelVolume(2, 70);

% Play layered harmony
synth.noteOn(0, 60, 100);  % Piano C
pause(0.1);
synth.noteOn(1, 64, 80);   % Violin E
pause(0.1);
synth.noteOn(2, 67, 70);   % Trumpet G

pause(2);

% Stop all
synth.allNotesOff(0);
synth.allNotesOff(1);
synth.allNotesOff(2);
```

### Example 3: Interactive Piano

```matlab
% Simple interactive piano using keyboard input
synth.initialize();
synth.setInstrument(0, 0);
synth.setVolume(100);

disp('Interactive Piano - Press keys:');
disp('a=C, s=D, d=E, f=F, g=G, h=A, j=B, k=C (high), q=quit');

% Note mapping
noteMap = containers.Map({'a','s','d','f','g','h','j','k'}, ...
                         [60, 62, 64, 65, 67, 69, 71, 72]);

while true
    key = input('Key: ', 's');
    if key == 'q'
        break;
    elseif isKey(noteMap, key)
        note = noteMap(key);
        synth.playNote(0, note, 0.3, 100);
    end
end

disp('Piano closed');
```

## Project Structure

```
M5UnitSynth\
├── +arduinoioaddons\
│   └── +M5Stack\
│       ├── M5UnitSynth.m          # MATLAB class file
│       └── src\
│           └── M5UnitML.h         # C++ header file
├── Examples\
│   └── (example MATLAB scripts)
├── Utilities\
│   └── installArduinoLibsFromGitHub.m  # Installation script
└── README.md                      # This file
```

## License

This project is provided as-is for educational and research purposes.

## References

- [MATLAB Support Package for Arduino Hardware](https://www.mathworks.com/hardware-support/arduino-matlab.html)
- [Create Custom Arduino Add-On Library](https://www.mathworks.com/help/matlab/arduinoio-custom-arduino-libraries.html)
- [M5Stack M5Unit-Synth](https://github.com/m5stack/M5Unit-Synth)
- [General MIDI Specification](https://www.midi.org/specifications)

## Support

For issues and questions:
1. Check the Troubleshooting section above
2. Verify all installation steps were completed correctly
3. Ensure hardware connections are secure
4. Check MATLAB and Arduino library versions

## Credits

Created for MATLAB Support Package for Arduino Hardware  
Compatible with M5Stack M5Unit-Synth library  
Installation script by: Eric Prandovszky (prandov@yorku.ca)

---

**Last Updated**: October 2024  
**MATLAB Version**: R2024a or newer  
**M5Unit-Synth Library**: Latest from GitHub

