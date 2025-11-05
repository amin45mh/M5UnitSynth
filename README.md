# M5UnitSynth MATLAB Arduino Add-On Library

A custom MATLAB Arduino add-on library for the M5Stack M5Unit-Synth module. This library enables control of the SAM2695-based synthesizer module directly from MATLAB, supporting MIDI instrument playback, note control, and various audio effects.

## Getting Started

### 1. Installation

**Prerequisites:**
- **MATLAB Support Package for Arduino Hardware** must be installed
  - In MATLAB, go to **Home > Add-Ons > Get Hardware Support Packages**
  - Search for "Arduino" and install **MATLAB Support Package for Arduino Hardware**

**Installation Steps:**

**Step 1: Run the installation utility**

Navigate to the `Utilities` folder and run:

installArduinoLibsFromGitHub.m

This script will automatically:
- Download the M5Unit-Synth library from GitHub
- Install it to the correct MATLAB Arduino libraries folder
- Check for compatibility and dependencies

**Step 2: Verify installation**

Check that the library {'M5Stack/M5UnitSynth'} is listed under Arduino libraries:

```matlab
listArduinoLibraries
```

You should see `'M5Stack/M5UnitSynth'` in the list.

**Note:** The installation script requires MATLAB R2024a or newer.

### 2. Hardware Setup
Connect the M5Unit-Synth module to your M5Core2 using one of the available ports (A, B, or C). The library communicates via UART at the MIDI standard baud rate of 31250.

### 3. Basic Connection

```matlab
% Find your device's serial port
disp(serialportlist)

% Connect to M5Stack ESP32
mySerialPorts = serialportlist;
M5SerialPort = mySerialPorts(1);  % Adjust index as needed

% Create arduino object with M5UnitSynth library
esp32 = arduino(M5SerialPort, 'ESP32-WROOM-DevKitC', ...
                'Libraries', {'M5Stack/M5UnitSynth'});

% Initialize the M5UnitSynth addon Assuming PORT C
synth = addon(esp32, 'M5Stack/M5UnitSynth', 'RXPin', 13, 'TXPin', 14);

% Play a note!
synth.setInstrument(0, 0, 0);      % Bank 0, Channel 0, Piano
synth.setMasterVolume(100);
synth.playNote(0, 60, 1.0, 100);   % Middle C for 1 second
```

## Port Configuration for M5Stack Core2

Configure the appropriate pins based on which port you're using:

| Port | RX Pin | TX Pin | Example |
|------|--------|--------|---------|
| **Port A** | 33 | 32 | `addon(esp32, 'M5Stack/M5UnitSynth', 'RXPin', 33, 'TXPin', 32)` |
| **Port B** | 36 | 26 | `addon(esp32, 'M5Stack/M5UnitSynth', 'RXPin', 36, 'TXPin', 26)` |
| **Port C** | 13 | 14 | `addon(esp32, 'M5Stack/M5UnitSynth', 'RXPin', 13, 'TXPin', 14)` |

**Note:** Port C (RX=13, TX=14) is the default configuration used in the examples.

## Example Files

### BasicExample.m
Demonstrates how to use the M5UnitSynth library alongside other Arduino add-ons including:
- **M5Unified** - Control the M5Stack's LCD, buttons, IMU, and other built-in hardware
- **Adafruit/NeoPixel** - Control programmable RGB LEDs
- **M5UnitSynth** - Play music and sound effects

This example is perfect for integrating the synthesizer into a larger project with multiple peripherals.

### ComprehensiveExample.m
A complete reference demonstrating all available functions in the M5UnitSynth library.

## Function Reference and Syntax

For detailed information about all available functions, their syntax, parameters, and usage, see the main library file:

**`+arduinoioaddons/+M5Stack/M5UnitSynth.m`**

This file contains comprehensive documentation for each function including:
- function descriptions
- Parameters and valid ranges
- Return values
- examples

### Available Methods:

**Core Functions:**
- `begin` - Initialize the M5UnitSynth module with UART
- `setInstrument` - Set MIDI instrument for a channel (0-127 instruments)
- `setNoteOn` - Turn on a note (60 = Middle C)
- `setNoteOff` - Turn off a note
- `setAllNotesOff` - Turn off all notes on a channel
- `reset` - Reset the synthesizer to default state

**Volume & Expression:**
- `setMasterVolume` - Set master volume (0-127)
- `setVolume` - Set volume for specific channel (0-127)
- `setExpression` - Set expression/dynamics (0-127)

**Pitch Control:**
- `setPitchBend` - Set pitch bend (-8192 to +8191)
- `setPitchBendRange` - Set pitch bend range in semitones
- `setTuning` - Set fine and coarse tuning

**Audio Effects:**
- `setReverb` - Set reverb effect (program, level, feedback)
- `setChorus` - Set chorus effect (program, level, feedback, delay)
- `setPan` - Set stereo pan (0=left, 64=center, 127=right)
- `setEqualizer` - Set 4-band equalizer
- `setVibrate` - Set vibrato (rate, depth, delay)

**Advanced Synthesis:**
- `setTvf` - Set time variant filter (cutoff, resonance)
- `setEnvelope` - Set ADSR envelope (attack, decay, release)
- `setModWheel` - Set modulation wheel parameters

**Special:**
- `setAllInstrumentDrums` - Set all channels to drum sounds
- `playNote` - Convenience function to play note for duration

You can also view the function help in MATLAB by using:
```matlab
methods(synth)          % List all available methods
help M5UnitSynth        % View general help
```
