Layers
Trystan Cannon
19 June 2015
CC Jam 2015 Project

Layers is a simple system that creates a seemless integration of background "widget" like programs and the default shell of the user's choosing.

#What is a layer?
A "layer" is simply a Lua program which runs aside the top "layer," or program, in a separate coroutine, waiting for the user to summon it to the
top.
A layer's purpose is to serve as easy access to some practical, or just plain fun, feature.

#This sounds like a traditional "OS."
Well, that's where you're wrong :)
Layers, while possessing the ability to behave like traiditional "OS" programs, are given a specialized API which allows them to transition in and out of the foreground seemlessly. They're provided functions for creating a beautifully integrated GUI with which the user may interact to maximize productivity, easing general use of one's computer.
    
This ease of usage is the primary goal of Layers. While simplifying complex tasks and allowing quick and responsive access to higher level programs, Layers does not take away from the traditional shell experience. Most OS's sit on top of the original Craft OS, giving the user a clickable interface which takes away the joy of using the command line, searching for and creating files, running programs and manipulating code in a comfortable yet simplistic setting. Layers works behind the scenes, providing services that make otherwise painful or tedious tasks quick and simple. One can just press a hotkey, interact with a "layer," and be back to their command line in seconds, having accomplished something that would otherwise take distracting amounts of time.

#Installation?
For now, unfortunately, you'll just have to mirror the file structure of this repository where the root folder is a folder
called 'Layers.' Basically, just make a new folder called 'Layers' in the root of your CC computer, and copy this repository into it, then run '/Layers/Main.'

#Well, how does it work?
Check out the usage documentation ;)

#Alright. But how do I make a new layer?
That's also in the usage documentation, silly ;)
