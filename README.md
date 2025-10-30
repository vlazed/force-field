# Force Field Tool <!-- omit from toc -->

Spawn force field entities

## Table of Contents <!-- omit from toc -->

- [Description](#description)
  - [Features](#features)
  - [Rational](#rational)
- [Disclaimer](#disclaimer)
- [Pull Requests](#pull-requests)

## Description

![preview](/media/preview.png)

This adds the "Force Field Tool", which spawns entities that emit forces in a volume

### Features

- **Force field shapes**: Shapes determine what volume to apply forces and how the forces are applied
  - Boxes apply a directional force
  - Balls apply a force from its origin
- **Force field control**: Force fields can be enabled or disabled by a press of a button

### Rational

I am not aware of any tool that applies arbitrary forces to an object within a volume, and does not require user input. Prior, forces can either be applied through a dynamite explosion, or through physgun interaction: both of which require user input (an explosion also leaves a mark).

This tool exists to allow the user to apply forces without user intervention. If user intervention is necessary, there exists

From a (Stop Motion Helper) animator's perspective, forces may have been applied in different ways. To give examples, user may need to use the constraint tools or the physgun. Both methods require plenty of configuration to obtain a desirable force; for example, the rope tool has multiple parameters for rope length and force limits, which adds complexity for one who wants to apply a simple force. Furthermore, the physgun requires plenty of takes to obtain the desirable force, and may be limiting for users who do not have a mouse wheel. This tool allows the user to determine the desired force and easily tune it for their needs

## Disclaimer

**This tool has been tested in singleplayer.** Although this tool may function in multiplayer, please expect bugs and report any that you observe in the issue tracker.

## Pull Requests

When making a pull request, make sure to confine to the style seen throughout. Try to add types for new functions or data structures. I used the default [StyLua](https://github.com/JohnnyMorganz/StyLua) formatting style.
