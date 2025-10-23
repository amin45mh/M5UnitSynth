/*
 * M5UnitML.h - Custom MATLAB Arduino Add-On for M5Unit-Synth
 * 
 * This file provides the C++ side of the MATLAB Arduino add-on library
 * for the M5Unit-Synth (SAM2695-based synthesizer module).
 * 
 * Created for MATLAB Support Package for Arduino Hardware
 * Compatible with M5Stack M5Unit-Synth library
 * 
 * NOTE: M5Unit-Synth uses UART communication at 31250 baud (MIDI standard)
 */

#ifndef M5UNITML_H
#define M5UNITML_H

#include "LibraryBase.h"
#include "M5UnitSynth.h"

// Command IDs for communication between MATLAB and Arduino
#define CMD_INIT                0x01
#define CMD_SET_INSTRUMENT      0x02
#define CMD_SET_MASTER_VOLUME   0x03
#define CMD_SET_NOTE_ON         0x04
#define CMD_SET_NOTE_OFF        0x05
#define CMD_SET_ALL_NOTE_OFF    0x06
#define CMD_SET_CHANNEL_VOLUME  0x07
#define CMD_SET_PITCH_BEND      0x08
#define CMD_SET_PAN             0x09
#define CMD_SET_REVERB          0x0A
#define CMD_SET_CHORUS          0x0B
#define CMD_SET_TEMPO           0x0C
#define CMD_SET_SUSTAIN         0x0D
#define CMD_SET_TRANSPOSE       0x0E
#define CMD_SET_MODULATION      0x0F
#define CMD_SYSTEM_RESET        0x10

class M5UnitML : public LibraryBase {
private:
    M5UnitSynth* synth;
    bool initialized;
    // To test
    MWArduinoClass& arduino;

public:
    // Constructor
    M5UnitML(MWArduinoClass& a) : LibraryBase(), arduino(a), initialized(false) {
        libName = "M5Stack/M5UnitSynth";
        a.registerLibrary(this);
    }

    // Destructor
    ~M5UnitML() {
        if (synth != nullptr) {
            delete synth;
        }
    }

    // Command handler for processing MATLAB commands
    void commandHandler(byte cmdID, byte* dataIn, unsigned int payloadSize) {
        byte responseData[32];
        unsigned int responseSize = 0;

        switch (cmdID) {
            case CMD_INIT: {
                // Initialize the M5UnitSynth with UART
                // synth.begin(&Serial2, UNIT_SYNTH_BAUD, 33, 32); works for Port A, (13, 14) works for Port C, (36, 26) works for Port B
                // dataIn[0] = RX pin (13)
                // dataIn[1] = TX pin (14)
                // dataIn[2-3] = Baud rate (uint16_t, default: 31250)
                uint8_t rxPin = (payloadSize > 0) ? dataIn[0] : 13;
                uint8_t txPin = (payloadSize > 1) ? dataIn[1] : 14;
                uint16_t baud = (payloadSize > 3) ? (dataIn[2] | (dataIn[3] << 8)) : 31250;
                
                if (synth == nullptr) {
                    synth = new M5UnitSynth();
                }
                
                synth->begin(&Serial2, baud, rxPin, txPin);
                initialized = true;
                
                responseData[0] = 1;
                responseSize = 1;
                break;
            }

            case CMD_SET_INSTRUMENT: {
                // Set instrument for a channel
                // dataIn[0] = bank (0-127, usually 0)
                // dataIn[1] = channel (0-15)
                // dataIn[2] = instrument (0-127)
                if (initialized && payloadSize >= 3) {
                    synth->setInstrument(dataIn[0], dataIn[1], dataIn[2]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_MASTER_VOLUME: {
                // Set master volume
                // dataIn[0] = volume (0-127)
                if (initialized && payloadSize >= 1) {
                    synth->setMasterVolume(dataIn[0]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_NOTE_ON: {
                // Turn on a note
                // dataIn[0] = channel (0-15)
                // dataIn[1] = note (0-127)
                // dataIn[2] = velocity (0-127)
                if (initialized && payloadSize >= 3) {
                    synth->setNoteOn(dataIn[0], dataIn[1], dataIn[2]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_NOTE_OFF: {
                // Turn off a note
                // dataIn[0] = channel (0-15)
                // dataIn[1] = note (0-127)
                // dataIn[2] = velocity (0-127, default 0)
                if (initialized && payloadSize >= 2) {
                    uint8_t velocity = (payloadSize >= 3) ? dataIn[2] : 0;
                    synth->setNoteOff(dataIn[0], dataIn[1], velocity);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_ALL_NOTE_OFF: {
                // Turn off all notes
                // dataIn[0] = channel (0-15)
                if (initialized && payloadSize >= 1) {
                    synth->setAllNotesOff(dataIn[0]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_CHANNEL_VOLUME: {
                // Set volume for a specific channel
                // dataIn[0] = channel (0-15)
                // dataIn[1] = volume (0-127)
                if (initialized && payloadSize >= 2) {
                    synth->setVolume(dataIn[0], dataIn[1]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_PITCH_BEND: {
                // Set pitch bend
                // dataIn[0] = channel (0-15)
                // dataIn[1-2] = bend value (int16_t, signed, LSB first)
                if (initialized && payloadSize >= 3) {
                    int16_t bendValue = dataIn[1] | (dataIn[2] << 8);
                    synth->setPitchBend(dataIn[0], bendValue);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_PAN: {
                // Set pan (stereo balance)
                // dataIn[0] = channel (0-15)
                // dataIn[1] = pan value (0-127, 64 = center)
                if (initialized && payloadSize >= 2) {
                    synth->setPan(dataIn[0], dataIn[1]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_REVERB: {
                // Set reverb effect
                // dataIn[0] = channel (0-15)
                // dataIn[1] = program (0-7, reverb type)
                // dataIn[2] = level (0-127)
                // dataIn[3] = delay feedback (0-127)
                if (initialized && payloadSize >= 4) {
                    synth->setReverb(dataIn[0], dataIn[1], dataIn[2], dataIn[3]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_CHORUS: {
                // Set chorus effect
                // dataIn[0] = channel (0-15)
                // dataIn[1] = program (0-7, chorus type)
                // dataIn[2] = level (0-127)
                // dataIn[3] = feedback (0-127)
                // dataIn[4] = chorus delay (0-127)
                if (initialized && payloadSize >= 5) {
                    synth->setChorus(dataIn[0], dataIn[1], dataIn[2], dataIn[3], dataIn[4]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }
            /*
            case CMD_SET_TEMPO: {
                // Set tempo
                // dataIn[0-1] = tempo (uint16_t, LSB first)
                if (initialized && payloadSize >= 2) {
                    uint16_t tempo = dataIn[0] | (dataIn[1] << 8);
                    synth->setTempo(tempo);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }
            
            case CMD_SET_SUSTAIN: {
                // Set sustain pedal
                // dataIn[0] = channel (0-15)
                // dataIn[1] = sustain on/off (0 or 1)
                if (initialized && payloadSize >= 2) {
                    synth->setSustain(dataIn[0], dataIn[1]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }
            
            case CMD_SET_TRANSPOSE: {
                // Set transpose
                // dataIn[0] = transpose value (signed int8_t, -12 to +12)
                if (initialized && payloadSize >= 1) {
                    int8_t transpose = (int8_t)dataIn[0];
                    synth->setTranspose(transpose);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_MODULATION: {
                // Set modulation
                // dataIn[0] = channel (0-15)
                // dataIn[1] = modulation level (0-127)
                if (initialized && payloadSize >= 2) {
                    synth->setModulation(dataIn[0], dataIn[1]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }
            */
            case CMD_SYSTEM_RESET: {
                // System reset
                if (initialized) {
                    synth->reset();
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            default:
                // Unknown command
                responseData[0] = 0;
                responseSize = 1;
                break;
        }

        // Send response back to MATLAB
        sendResponseMsg(cmdID, responseData, responseSize);
    }
};

#endif // M5UNITML_H

