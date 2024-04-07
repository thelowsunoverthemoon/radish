<p align="center">
  <img src="img/radish.png">
</p>
<p align="center">
  <b>CMD extension for Mouse / Keyboard Input and Audio</b>
</p>

## Features

* Simple to include, just copy & paste!
* Audio
    * Intuitive macro interface
    * Supports stop, play, volume transitions
    * Supports implicit spatial audio through environment variables
* Mouse / Keyboard Input
    * Defined implicitly in CMDCMDLINE variable
    * Supports console-based mouse position, mouse events
    * Supports current keys pressed
* 64 bit, Windows 10+ only

## Usage

**radish** is created as a CMD "extension" to be used by Batch Script in games. It provides the most basic features needed in games such as audio and mouse / keyboard input that are somewhat difficult in Batch. Unlike other .exes that provide similar functionality, **radish** does NOT need to be called every time it is needed. It runs along with the Batch script and provides features in Batch terms like environment variables and macros.

## Documentation
Visit the documentation [here](doc/README.md)!

## Example
Look at the example [here](ex)!

## How does it work?
To set the value of the variable ```CMDCMDLINE```, we can take advantage of the fact that it directly reads from the ```Commandline``` field of the *RTL_USER_PROCESS_PARAMETERS* struct. Thus, we can allocate the buffer to an arbitrary size by calling a separate process to start the Batch file first with something like this ```%COMSPEC%\\##############\\..\\..\\cmd.exe /k file.bat```. As you can see we can have as many ```#``` as we want. Then it's only a matter of getting the mouse / keyboad input and writing it to the field. For audio, it uses **fmod** as the audio engine. To communicate, we can use named pipes as an easy way to send data to **radish** through Batch via ```ECHO ``` in a separate thread. Finally, to read the values for spatial audio, since this doesn't have to be super exact, we can create a timer queue to read the environment variables (```Environment``` field of the *RTL_USER_PROCESS_PARAMETERS* struct) every so often and update as needed.
