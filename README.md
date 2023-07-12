<p align="center">
  <img src="https://i.imgur.com/zqt279r.png">
</p>
<p align="center">
  <b>Mouse and Keyboard Input in Batch Script</b>
</p>

## Features

* Simple to include, just copy & paste!
* Supports Mouse Input with 
  - Console Based Position
  - Button Press (eg left mouse button)
  - Action Type (eg double click)
  - Control Keys (eg Caps Lock)
  - Scroll Wheel Direction
* Supports Keyboard Input with
  - Character Type
  - Button State (eg Key Pressed)
  - Control Keys
* Intuitive macro interface
* Works with Windows 7+ with Powershell installed

## Drawbacks

* Uses Batch
* May require Admin Privileges
* Starts new CMD process 

## Usage

**radish** is created for mouse and keyboard input in Batch Script. Unlike using ```CHOICE```, this allows non-blocking input; even if you use ```CHOICE``` in a separate process, **radish** includes features that are simply not possible using pure Batch, such as control keys. For example, detecting a mouse click at a certain point can be as simple as:

```Batch
```

## Documentation
Visit the documentation [here](doc/README.md)!

## Examples
Look at the examples [here](ex)!

## How does it work?
To access the Windows Console API without downloading anything extra, we can use DllImport in C#. To use C#, we can use Powershell's Add-Type. **radish** uses Powershell via [this](https://www.dostips.com/forum/viewtopic.php?t=6936) method by Aacini to do exactly this. Basically, we can pipe the Powershell output to Batch, and read it through ```SET /P```. 

