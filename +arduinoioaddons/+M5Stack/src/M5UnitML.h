/**
 * @file M5UnitML.h
 *
 * Class definition for M5Stack class that wraps APIs of the M5UnitSynth library.
 * https://github.com/m5stack/M5Unit-Synth. Based on the example UnitSynth add-on library.
 * @copyright 2025, Amin Mahmoudi, aminmh@yorku.ca
 * Contact: aminmh@yorku.ca
 * Version: 1.0
 * Date: Oct 27, 2025
 * This .h file interacts with the M5UnitSynth.m class in MATLAB.
 */

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
#define CMD_BEGIN                   0x01
#define CMD_SET_INSTRUMENT          0x02
#define CMD_SET_NOTE_ON             0x03
#define CMD_SET_NOTE_OFF            0x04
#define CMD_SET_ALL_NOTE_OFF        0x05
#define CMD_SET_PITCH_BEND          0x06
#define CMD_SET_PITCH_BEND_RANGE    0x07
#define CMD_SET_MASTER_VOLUME       0x08
#define CMD_SET_CHANNEL_VOLUME      0x09
#define CMD_SET_EXPRESSION          0x0A
#define CMD_SET_REVERB              0x0B
#define CMD_SET_CHORUS              0x0C
#define CMD_SET_PAN                 0x0D
#define CMD_SET_EQUALIZER           0x0E
#define CMD_SET_TUNING              0x0F
#define CMD_SET_VIBRATE             0x10
#define CMD_SET_TVF                 0x11
#define CMD_SET_ENVELOPE            0x12
#define CMD_SET_MOD_WHEEL           0x13
#define CMD_SET_ALL_DRUMS           0x14
#define CMD_RESET                   0x15

class M5UnitML : public LibraryBase {
private:
    M5UnitSynth* synth;
    MWArduinoClass& arduino;

public:
    // Constructor
    M5UnitML(MWArduinoClass& a) : LibraryBase(), arduino(a) {
        libName = "M5Stack/M5UnitSynth";
        synth = nullptr;
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
            case CMD_BEGIN: {
                // Initialize the M5UnitSynth with UART
                // dataIn[0] = RX pin
                // dataIn[1] = TX pin
                // dataIn[2-3] = Baud rate (uint16_t, default: 31250)
                uint8_t rxPin = (payloadSize > 0) ? dataIn[0] : 16;
                uint8_t txPin = (payloadSize > 1) ? dataIn[1] : 17;
                uint16_t baud = (payloadSize > 3) ? (dataIn[2] | (dataIn[3] << 8)) : 31250;
                
                if (synth == nullptr) {
                    synth = new M5UnitSynth();
                }
                
                synth->begin(&Serial2, baud, rxPin, txPin);
                
                responseData[0] = 1;
                responseSize = 1;
                break;
            }

            case CMD_SET_INSTRUMENT: {
                // Set instrument for a channel
                // dataIn[0] = bank (0-127, usually 0)
                // dataIn[1] = channel (0-15)
                // dataIn[2] = instrument (0-127)
                if (synth != nullptr && payloadSize >= 3) {
                    synth->setInstrument(dataIn[0], dataIn[1], dataIn[2]);
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
                // dataIn[1] = pitch (0-127)
                // dataIn[2] = velocity (0-127)
                if (synth != nullptr && payloadSize >= 3) {
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
                // dataIn[1] = pitch (0-127)
                // dataIn[2] = velocity (0-127)
                if (synth != nullptr && payloadSize >= 3) {
                    synth->setNoteOff(dataIn[0], dataIn[1], dataIn[2]);
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
                if (synth != nullptr && payloadSize >= 1) {
                    synth->setAllNotesOff(dataIn[0]);
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
                if (synth != nullptr && payloadSize >= 3) {
                    int16_t bendValue = dataIn[1] | (dataIn[2] << 8);
                    synth->setPitchBend(dataIn[0], bendValue);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_PITCH_BEND_RANGE: {
                // Set pitch bend range
                // dataIn[0] = channel (0-15)
                // dataIn[1] = range value (0-127)
                if (synth != nullptr && payloadSize >= 2) {
                    synth->setPitchBendRange(dataIn[0], dataIn[1]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_MASTER_VOLUME: {
                // Set master volume
                // dataIn[0] = level (0-127)
                if (synth != nullptr && payloadSize >= 1) {
                    synth->setMasterVolume(dataIn[0]);
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
                // dataIn[1] = level (0-127)
                if (synth != nullptr && payloadSize >= 2) {
                    synth->setVolume(dataIn[0], dataIn[1]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_EXPRESSION: {
                // Set expression
                // dataIn[0] = channel (0-15)
                // dataIn[1] = expression (0-127)
                if (synth != nullptr && payloadSize >= 2) {
                    synth->setExpression(dataIn[0], dataIn[1]);
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
                // dataIn[1] = program (0-127, reverb type)
                // dataIn[2] = level (0-127)
                // dataIn[3] = delay feedback (0-127)
                if (synth != nullptr && payloadSize >= 4) {
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
                // dataIn[1] = program (0-127, chorus type)
                // dataIn[2] = level (0-127)
                // dataIn[3] = feedback (0-127)
                // dataIn[4] = chorus delay (0-127)
                if (synth != nullptr && payloadSize >= 5) {
                    synth->setChorus(dataIn[0], dataIn[1], dataIn[2], dataIn[3], dataIn[4]);
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
                if (synth != nullptr && payloadSize >= 2) {
                    synth->setPan(dataIn[0], dataIn[1]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_EQUALIZER: {
                // Set equalizer
                // dataIn[0] = channel (0-15)
                // dataIn[1] = lowband (0-127)
                // dataIn[2] = medlowband (0-127)
                // dataIn[3] = medhighband (0-127)
                // dataIn[4] = highband (0-127)
                // dataIn[5] = lowfreq (0-127)
                // dataIn[6] = medlowfreq (0-127)
                // dataIn[7] = medhighfreq (0-127)
                // dataIn[8] = highfreq (0-127)
                if (synth != nullptr && payloadSize >= 9) {
                    synth->setEqualizer(dataIn[0], dataIn[1], dataIn[2], dataIn[3], 
                                       dataIn[4], dataIn[5], dataIn[6], dataIn[7], dataIn[8]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_TUNING: {
                // Set tuning
                // dataIn[0] = channel (0-15)
                // dataIn[1] = fine (0-127, 64 is default)
                // dataIn[2] = coarse (0-127, 64 is default)
                if (synth != nullptr && payloadSize >= 3) {
                    synth->setTuning(dataIn[0], dataIn[1], dataIn[2]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_VIBRATE: {
                // Set vibrato
                // dataIn[0] = channel (0-15)
                // dataIn[1] = rate (0-127)
                // dataIn[2] = depth (0-127)
                // dataIn[3] = delay (0-127)
                if (synth != nullptr && payloadSize >= 4) {
                    synth->setVibrate(dataIn[0], dataIn[1], dataIn[2], dataIn[3]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_TVF: {
                // Set TVF (Time Variant Filter)
                // dataIn[0] = channel (0-15)
                // dataIn[1] = cutoff (0-127)
                // dataIn[2] = resonance (0-127)
                if (synth != nullptr && payloadSize >= 3) {
                    synth->setTvf(dataIn[0], dataIn[1], dataIn[2]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_ENVELOPE: {
                // Set envelope
                // dataIn[0] = channel (0-15)
                // dataIn[1] = attack (0-127)
                // dataIn[2] = decay (0-127)
                // dataIn[3] = release (0-127)
                if (synth != nullptr && payloadSize >= 4) {
                    synth->setEnvelope(dataIn[0], dataIn[1], dataIn[2], dataIn[3]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_MOD_WHEEL: {
                // Set modulation wheel
                // dataIn[0] = channel (0-15)
                // dataIn[1] = pitch (0-127)
                // dataIn[2] = tvtcutoff (0-127)
                // dataIn[3] = amplitude (0-127)
                // dataIn[4] = rate (0-127)
                // dataIn[5] = pitchdepth (0-127)
                // dataIn[6] = tvfdepth (0-127)
                // dataIn[7] = tvadepth (0-127)
                if (synth != nullptr && payloadSize >= 8) {
                    synth->setModWheel(dataIn[0], dataIn[1], dataIn[2], dataIn[3], 
                                      dataIn[4], dataIn[5], dataIn[6], dataIn[7]);
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_SET_ALL_DRUMS: {
                // Set all instruments to drums
                if (synth != nullptr) {
                    synth->setAllInstrumentDrums();
                    responseData[0] = 1;
                } else {
                    responseData[0] = 0;
                }
                responseSize = 1;
                break;
            }

            case CMD_RESET: {
                // System reset
                if (synth != nullptr) {
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

