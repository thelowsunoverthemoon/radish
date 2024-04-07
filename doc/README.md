## How to Use

1. Copy the engine [here](../bin/engine.bat) to the bottom of your batch file and the header [here](../bin/header.bat) to the top of your batch file. Please note that the header is very simple, so it's easy to customize if you have other new processes.
2. Before using **radish**, ```CALL :RADISH <label>```. Very important : this starts a new process starting at the specified label.
3. In the label, once you want to start the input, use ```CALL :RADISH_WAIT```. Once you want to end, use ```%RADISH_END%```
4. To get input, read the ```CMDCMDLINE``` variable
5. To use audio, use see the documentation below
5. Look at the examples [here](../ex)!

## Input

The ```CMDCMDLINE``` variable is in the format

```
mouse_x.mouse_y.mouse_button.-key_a-key_b-...-
```

Which can be easily parsed via ```FOR /F```. The keys are represented by ```wVirtualKeyCode``` from [here](https://learn.microsoft.com/en-us/windows/console/key-event-record-str). Mouse X and Mouse Y start from 0, in relation to the console window. Mouse buttons are from ```dwButtonState``` [here](https://learn.microsoft.com/en-us/windows/console/mouse-event-record-str). The only difference is mouse scroll is represented by 6 (up), and -6 (down).

## Audio

Audio is controlled through macros and functions. Functions are used for loading sounds and creating objects. There are three types of audio:

* Effects : Non looping quick sounds. For example, a death sound. Can have multiple at once.
* Tracks : Looping sound. For example, a background track. Only one can be played at a time.
* Objects : Spatial looping sound. For example, a water fountain that gets louder when you step closer. Can have multiple at a time.

You must first load the sound into a variable using

```
CALL :RADISH_ADD <name> <var> <type>
```

* name : name of file
* var : variable to return sound to
* type to load. Can be EFFECT, TRACK, or OBJECT

DO NOT alter this variable. For spatial sound, you must set an observer through

```
CALL :RADISH_SET_OBS <x> <y>
```

* x : variable that contains x value
* y : variable that contains y value

You only need to this ONCE. **radish** will automatically read the values to update audio accordingly. To create an spatial audio object, use

```
CALL :RADISH_CREATE_OBJ <index> <var> <x> <y>
```

* index : sound index. Must be of type OBJECT
* var : variable to return object to
* x : x position of object
* y : y position of object

You can then manipulate audio by passing messages enclosed by ```%RADISH_AUDIO_START%``` and ```%RADISH_AUDIO_END%```. The two messages are

```
"P#var#start#period#volume"
```

This is the play / transition message. When used on effects, there is no transition. It will play at ```volume``` and ignore the other parameters. If it's not an effect, it will transition starting from ```start``` taking ```period``` seconds to ```volume```. If used while a transition is still going, it will interpolate to the new values using an adjusted period based on the current transition state. If you transition to 0, it will stop. Any new message will play from the start.

* var : index of sound / object
* start : volume to start
* period : how long to take
* volume : final volume

```
"S#var"
```

This is only for tracks or objects. It stops it immediatly.

* var : index of sound / object


So, for example, to play a click sound and animal sound at the same time, with the click at 50% volume and the animal sound fading away, write:

```
%RADISH_AUDIO_START% "P#%click%#0#5#50" "P#%animal%#100#1#0" %RADISH_AUDIO_END%
```