using { /UnrealEngine.com/Temporary }
using { /Verse.org/Input }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

# Transforms the given normalized viewport space coordinates into a `ray` for raycasting.
(Player:player).DeprojectViewportToRay<public>(NormalizedViewportPosition:SpatialMath.vector2)<decides><reads>:ray=
    Player.DeprojectViewportToRay[NormalizedViewportPosition.X, NormalizedViewportPosition.Y]

# Transforms the given normalized viewport space coordinates into a `ray` for raycasting.
(Player:player).DeprojectViewportToRay<public>(NormalizedViewportX:float, NormalizedViewportY:float)<decides><reads>:ray=
    Results:deproject_results = Player.DeprojectViewportToWorld[NormalizedViewportX, NormalizedViewportY]
    MakeRay(Results)

# Transforms the given viewport space coordinates into a `ray` for raycasting.
(Player:player).DeprojectViewportToRay<public>(ViewportPosition:vector3)<reads>:ray=
    Results:deproject_results = Player.DeprojectViewportToWorld(ViewportPosition)
    MakeRay(Results)

# Transforms the given normalized viewport space coordinates into 3D world origin and direction vectors.
(Player:player).DeprojectViewportToWorld<public>(NormalizedViewportPosition:SpatialMath.vector2)<decides><reads>:deproject_results=
    Player.DeprojectViewportToWorld[NormalizedViewportPosition.X, NormalizedViewportPosition.Y]

# Transforms the given normalized viewport space coordinates into 3D world origin and direction vectors.
(Player:player).DeprojectViewportToWorld<public>(NormalizedViewportX:float, NormalizedViewportY:float)<decides><reads>:deproject_results=
    Center:vector3 = Player.GetViewportCenter[]
    ViewportPosition:vector3 = vector3:
        Left := Center.Left * 2 * NormalizedViewportX
        Up := Center.Up * 2 * NormalizedViewportY
    Player.DeprojectViewportToWorld(ViewportPosition)

# Makes a `vector2` from `ViewportPosition` by converting its values to normalized values within the `Player`'s screen space. The top left (`ViewportPosition.X`) of the viewport is 0.0, and the bottom right (`ViewportPosition.Y`) is 1.0.
(Player:player).GetNormalizedViewportPosition<public>(ViewportPosition:vector3)<decides><reads>:SpatialMath.vector2=
    Center:vector3 = Player.GetViewportCenter[]
    SpatialMath.vector2:
        X := ViewportPosition.Left / (Center.Left * 2)
        Y := -ViewportPosition.Up / (-Center.Up * 2)

# Makes a `vector2i` representing the `Player`'s screen's aspect ratio with the greatest common denominator.
# For example, `vector2i{X:=16, Y:=9}`.
(Player:player).GetViewportAspectRatio<public>()<decides><transacts>:SpatialMath.vector2i=
    Center:vector3 = Player.GetViewportCenter[]
    var Denominator:float = 0.0
    var LastDenominator:float = 1.0
    var LastNumerator:float = 0.0
    var Numerator:float = 1.0
    Ratio:float = Center.Left / -Center.Up
    var Remainder:float = Ratio
    var Return:logic = true
    loop:
        if (Component := Floor[Remainder]):
            TempDenominator:float = Denominator
            TempNumerator:float = Numerator
            set Denominator = Component * Denominator + LastDenominator
            set Numerator = Component * Numerator + LastNumerator
            set LastDenominator = TempDenominator
            set LastNumerator = TempNumerator
            set Remainder = 1.0 / (Remainder - Component * 1.0)
            if (Abs(Ratio - Numerator / Denominator) <= Ratio * 0.001):
                break
        else:
            set Return = false
            break
    Return?
    SpatialMath.vector2i:
        X := Int[Numerator]
        Y := Int[Denominator]

# Makes a `vector3` with the `Player`'s viewport's center in viewport space.
(Player:player).GetViewportCenter<public>()<decides><reads>:vector3=
    Ray:ray = Player.GetCameraRay()
    Player.ProjectWorldToViewport[Ray.GetPoint(1.0)]

# Returns the `Player`'s screen's decimal aspect ratio.
# This should be equivalent to `Player.GetViewportAspectRatio[] * 1.0 / (Player.GetViewportAspectRatio[] * 1.0)`.
(Player:player).GetViewportRatio<public>()<decides><reads>:float=
    Center:vector3 = Player.GetViewportCenter[]
    Center.Left / -Center.Up

# Transforms a 3D world position to normalized viewport space coordinates.
# Fails if the world position is behind the camera.
(Player:player).ProjectWorldToNormalizedViewport<public>(WorldPosition:vector3)<decides><transacts>:SpatialMath.vector2=
    ViewportPosition:vector3 = Player.ProjectWorldToViewport[WorldPosition]
    Player.GetNormalizedViewportPosition[ViewportPosition]

# Transforms a 3D transform to normalized viewport space coordinates.
# Fails if the transform is behind the camera.
(Player:player).ProjectWorldToNormalizedViewport<public>(WorldTransform:transform)<decides><transacts>:SpatialMath.vector2=
    Player.ProjectWorldToNormalizedViewport[WorldTransform.Translation]