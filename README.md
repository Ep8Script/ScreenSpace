# ScreenSpace - Library for Verse Viewport APIs

ScreenSpace is an open-source Verse library designed for using the player viewport APIs.

## Features
* **Aspect Ratio Calculation:** Get a player's camera/viewport aspect ratio, allowing you to adapt content to fit their screen.
* **Bounds Component:** Add a bounding box (AABB) to any entity with a custom `bounds_component`, returned with `Entity.GetBounds()` and `Entity.GetBoundsGlobal()`.
  * **Automatic Encapsulation:** Entities without a `bounds_component` of their own will automatically encapsulate the bounds of their children.
    * **Caching:** If the child entities don't change or move often, call `Entity.CacheBounds()` to store the bounds without needing to recalculate them.
  * **Custom Raycasting:** Cast lines and rays against these bounding boxes from the player's camera or any other position in the scene.
  * **Frustum Plane Checks:** Check if an entity is visible on a player's screen with `Player.IsEntityOnScreen[Entity]`.
  * **Screen Rectangle:** Get the exact size of an entity's bounds on a player's viewport with `Player.GetScreenRect[Entity]`.
* **Normalized Viewport Math:** Project world-space coordinates onto the screen in normalized screen space (0-1 XY) so you can use them in UI, or deproject UI coordinates back to world space as a ray. Correctly adjusted for any screen size.
* **Visualization and Debugging:** Real-time debug draws for frustum planes, global/oriented bounds and raycasting.

## Installation
This is a Verse module accessible inside your UEFN project structure:

1. Download the .zip file from the [latest release](https://github.com/Ep8Script/ScreenSpace/releases/latest) and extract it.
2. Copy the "**ScreenSpace**" folder to your project's Content/ directory (usually `C:/Users/<USERNAME>/Documents/Fortnite Projects/<PROJECT>/Content`), or wherever your Verse is stored in the project.
3. Optional: Copy the "**Python**" folder to your project's Content/ directory (or anywhere on your PC). This contains scripts to help calculate and set the bounds of your entities in-editor.

### Usage
```as
using { /Fortnite.com/Game }
using { /Fortnite.com/Playspaces }
using { ScreenSpace }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

my_component := class<final_super>(component):

    OnBeginSimulation<override>():void=
        if (RoundManager := Entity.GetFortRoundManager[]):
            RoundManager.SubscribeRoundStarted(OnRoundStarted)

    OnRoundStarted<private>()<suspends>:void=
        if:
            Player := first:
                P : Entity.GetPlayspaceForEntity[].GetPlayers()
            true?
        then:
            if (AspectRatio := Player.GetViewportAspectRatio[]):
                Print("The player's aspect ratio is {AspectRatio.X}:{AspectRatio.Y}")
            loop:
                if (Player.IsEntityOnScreen[Entity]):
                    Print("The player is looking at the component's entity!")
                TickEvents.PostPhysics.Await()
```