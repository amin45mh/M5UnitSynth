# M5UnitSynth MATLAB Arduino Add-On Library

A custom MATLAB Arduino add-on library for the M5Stack M5Unit-Synth module. This library enables control of the SAM2695-based synthesizer module directly from MATLAB, supporting MIDI instrument playback, note control, and various audio effects.

## Getting Started

### 1. Installation

**Prerequisites:**
- **MATLAB Support Package for Arduino Hardware** must be installed
  - In MATLAB, go to **Home > Add-Ons > Get Hardware Support Packages**
  - Search for "Arduino" and install **MATLAB Support Package for Arduino Hardware**

**Installation Steps:**

**Step 1: Extract and open the M5UnitSynth folder**
- Extract the `M5UnitSynth.zip` file
- In MATLAB, navigate to (or open) the extracted `M5UnitSynth` folder

**Step 2: Add the folder to MATLAB path**

```matlab
addpath('C:\**Edit**\M5UnitSynth\)
savepath()
```

**Step 3: Run the installation utility**

Navigate to the `Utilities` folder and run:

installArduinoLibsFromGitHub


This script will automatically:
- Download the M5Unit-Synth library from GitHub
- Install it to the correct MATLAB Arduino libraries folder
- Check for compatibility and dependencies

**Step 4: Verify installation**

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

% Initialize the M5UnitSynth addon
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

You can also view the function help in MATLAB by using:
```matlab
methods(synth)          % List all available methods
help M5UnitSynth        % View general help
```