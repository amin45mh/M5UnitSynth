#line 1 "C:\\Users\\aminmh\\AppData\\Local\\Temp\\ArduinoServerESP32-WROOM-DevKitC\\LibraryBase.h"
/**
 * @file LibraryBase.h
 *
 * Class definition for base class for all add-on libraries
 *
 * @copyright Copyright 2014-2018 The MathWorks, Inc.
 *
 */

#ifndef LibraryBase_h
#define LibraryBase_h

#include "IO_include.h"

#include "IO_peripheralInclude.h"   /* This will include the  library for printing debug messages */

typedef uint8_T byte;

class LibraryBase{
	public:
		const char* getLibraryName() 
		{
			return libName;
		}
		virtual void commandHandler(byte cmdID, byte* dataIn, unsigned int payloadSize);
        virtual void setup() {}
        virtual void loop() {}
        
    protected:
        const char* libName;
};

#endif