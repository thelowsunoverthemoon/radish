## How to Use

1. Copy the engine [here](../src/engine.bat) to the bottom of your batch file and the header [here](../src/header.bat) to the top of your batch file. Please note that the header is very simple, so it's easy to customize if you have other new processes. Just make sure to only call **radish** on the process you want to have input to.
2. Before using **radish**, ```CALL :RADISH_PLAY```. Very important : this starts a new process starting at the specified label. See the examples [here](ex)!
3. In the label, once you want to start the input, use ```%RADISH_START%```. Once you want to end, use ```%RADISH_END%```
4. To get input, use the macros ```%RADISH_START_PARSE%``` and ```%RADISH_END_PARSE%```
5. Visit the documentation [here](doc/README.md) and look at the examples [here](ex)!

## Library

```Batch
RADISH_PLAY
```

The function ```RADISH_PLAY``` has 4 parameters. 
* The delay between detecting input (milliseconds). Note this will also set the "framerate" of your input loop
* The maximum amount of inputs to detect at once
* The type : ```0``` is for mouse only, ```1``` is for key only, and ```2``` is for both
* The input label to go to

---

```Batch
%RADISH_START%
```

Starts the engine. You must use this before gathering input in your set label.

---

```Batch
%RADISH_END%
```

Ends the loop. This automatically redirects the code to after ```CALL :RADISH_PLAY```. Since it is a new process, variables set in the label will not be saved. Thus, you can use the errorlevel or some other mechanism to save crucial variables.

---

```Batch
%RADISH_START_PARSE%
```

Starts data parsing.

---

```Batch
%RADISH_END_PARSE%
```

Ends data parsing.

---

## Message Format

The messages are parsed using a ```FOR /F``` loop internally. Thus, we use ```%%A```, ```%%B```, ```%%C```, ect.

### Mouse Messages

Please refer [here](https://learn.microsoft.com/en-us/windows/console/mouse-event-record-str) if you are unsure of what the labels/values mean. Also note values with ```x``` are hex values, and so you will need to convert them to decimal.

| ```%%A```  | ```%%B``` | ```%%C``` | ```%%D``` | ```%%E``` | ```%%F``` | ```%%G``` |
| ------------- | ------------- | ------------- | ------------- | ------------- | ------------- | ------------- |
| ```M```  | X Position  | Y Position  | Button State (```dwButtonState```) | Control Keys (```dwControlKeyState```) | Event (```dwEventFlags```) | Scroll Wheel Direction (```1``` for up, ```-1``` for down) |

### Key Messages

Please refer [here](https://learn.microsoft.com/en-us/windows/console/key-event-record-str). if you are unsure of what the labels/values mean. Also note values with ```x``` are hex values, and so you will need to convert them to decimal.

| ```%%A```  | ```%%B``` | ```%%C``` | ```%%D``` |
| ------------- | ------------- | ------------- | ------------- |
| ```K``` | Key Code (```wVirtualKeyCode```) | Key Down (```bKeyDown```) | Control Keys (```dwControlKeyState```)
