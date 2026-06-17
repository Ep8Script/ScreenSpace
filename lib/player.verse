using { /Fortnite.com/Game }
using { /Verse.org/Input }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

# Calculates the frustum planes of the `Player`'s active camera.
# Returns the planes that form the `Player`'s camera's view frustum.
(Player:player).CalculateFrustumPlanes<public>()<transacts>:[]plane=
    if (Coordinates := (Player.DeprojectViewportToWorld[0.0, 0.0], Player.DeprojectViewportToWorld[1.0, 0.0], Player.DeprojectViewportToWorld[0.0, 1.0], Player.DeprojectViewportToWorld[1.0, 1.0])):
        Center:deproject_results = MakeDeprojectResults(Player.GetCameraRay())
        NormalBottom:vector3 = CrossProduct(Coordinates(3).Direction, Coordinates(2).Direction)
        NormalLeft:vector3 = CrossProduct(Coordinates(2).Direction, Coordinates(0).Direction)
        NormalRight:vector3 = CrossProduct(Coordinates(1).Direction, Coordinates(3).Direction)
        NormalTop:vector3 = CrossProduct(Coordinates(0).Direction, Coordinates(1).Direction)
        Planes:[]tuple(deproject_results, vector3) = array{(Coordinates(0), NormalLeft), (Coordinates(0), NormalTop), (Coordinates(1), NormalRight), (Coordinates(2), NormalBottom), (Center, Center.Direction)}
        for (Plane : Planes):
            MakePlane(Plane(1), Plane(0).Origin)
    else:
        ()

# Makes a `ray` from the `Player`'s camera.
(Player:player).GetCameraRay<public>()<reads>:ray=
    Corner:deproject_results = Player.DeprojectViewportToWorld(vector3{})
    Down:deproject_results = Player.DeprojectViewportToWorld(vector3{Up := -1.0})
    Left:deproject_results = Player.DeprojectViewportToWorld(vector3{Left := 1.0})
    ray:
        Direction := CrossProduct(Left.Origin - Corner.Origin, Down.Origin - Corner.Origin).MakeUnitVector()
        Origin := block:
            CrossDelta := CrossProduct(Left.Direction, Corner.Origin - Left.Origin)
            CrossDirections := CrossProduct(Corner.Direction, Left.Direction)
            Corner.Origin + Corner.Direction * DotProduct(CrossDelta, CrossDirections) / DotProduct(CrossDirections, CrossDirections)

# Calculates a `rect` in the normalized viewport space coordinates that perfectly encloses the `Bounds`.
# Fails if the `Bounds` are entirely behind the camera.
(Player:player).GetScreenRect<public>(Bounds:oriented_bounds)<decides><transacts>:rect=
    Corners:[]vector3 = Bounds.GetCorners()
    var MaxX:float = 0.0
    var MaxY:float = 0.0
    var MinX:float = 1.0
    var MinY:float = 1.0
    Projected:[]void = for (Corner : Corners, ViewportPosition := Player.ProjectWorldToNormalizedViewport[Corner]):
        set MaxX = Max(MaxX, ViewportPosition.X)
        set MaxY = Max(MaxY, ViewportPosition.Y)
        set MinX = Min(MinX, ViewportPosition.X)
        set MinY = Min(MinY, ViewportPosition.Y)
    Projected.Length > 0
    rect.MinMaxRect(MinX, MinY, MaxX, MaxY)

# Calculates a `rect` in the normalized viewport space coordinates that perfectly encloses the `Entity`'s bounds.
# Fails if the `Entity`'s bounds are entirely behind the camera or if none of its descendants have a `bounds_component`.
(Player:player).GetScreenRect<public>(Entity:entity)<decides><transacts>:rect=
    OrientedBounds:oriented_bounds = Entity.GetOrientedBounds[]
    Player.GetScreenRect[OrientedBounds]

# Succeeds if the entity's bounding box is visible on the `Player`'s screen.
(Player:player).IsEntityOnScreen<public>(Entity:entity)<decides><transacts>:void=
    FrustumPlanes:[]plane = Player.CalculateFrustumPlanes()
    Entity.IsInFrustum[FrustumPlanes]

# Succeeds if the bounding box is visible on the `Player`'s screen.
(Player:player).IsOnScreen<public>(GlobalBounds:bounds)<decides><transacts>:void=
    FrustumPlanes:[]plane = Player.CalculateFrustumPlanes()
    GlobalBounds.IsInFrustum[FrustumPlanes]

# Succeeds if `Positional.Translation` is visible on `Player`'s screen.
(Player:player).IsOnScreen<public>(Positional:positional)<decides><transacts>:void=
    Transform:transform = Positional.GetGlobalTransform()
    Player.IsPositionOnScreen[Transform.Translation]

# Succeeds if `WorldPosition` is visible on `Player`'s screen.
(Player:player).IsPositionOnScreen<public>(WorldPosition:vector3)<decides><transacts>:void=
    ViewportPosition := Player.ProjectWorldToNormalizedViewport[WorldPosition]
    ViewportPosition.X >= 0.0
    ViewportPosition.X <= 1.0
    ViewportPosition.Y >= 0.0
    ViewportPosition.Y <= 1.0

# Succeeds if `WorldTransform.Translation` is on `Player`'s screen.
(Player:player).IsPositionOnScreen<public>(WorldTransform:transform)<decides><transacts>:void=
    Player.IsPositionOnScreen[WorldTransform.Translation]

# Casts a line from the `Player`'s camera to `End` against all bounding boxes in the entity's descendants, starting with `Entity`.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the line between the `Player`'s camera and `End`.
# NOTE: Linecasts will not detect any `bounds` that contain the `Player`'s camera's transform point.
(Player:player).Linecast<public>(Entity:entity, End:vector3)<decides><transacts>:raycast_hit=
    Ray:ray = Player.GetCameraRay()
    Entity.Linecast[Ray.Origin, End]

# Casts forwards from the `Player`'s camera against all bounding boxes in the entity's descendants, starting with `Entity`.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the line in front of the `Player`'s camera.
# NOTE: Raycasts will not detect any `bounds` that contain the `Player`'s camera's transform point.
(Player:player).Raycast<public>(Entity:entity)<decides><transacts>:raycast_hit=
    Player.Raycast[Entity, Inf]

# Casts a line from the `Player`'s camera with `MaxDistance` against all bounding boxes in the entity's descendants, starting with `Entity`.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the line in front of the `Player`'s camera.
# NOTE: Raycasts will not detect any `bounds` that contain the `Player`'s camera's transform point.
(Player:player).Raycast<public>(Entity:entity, MaxDistance:float)<decides><transacts>:raycast_hit=
    Ray:ray = Player.GetCameraRay()
    Entity.Raycast[Ray, MaxDistance]

# Casts forwards from the `Player`'s camera against all bounding boxes in the scene.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain the `Player`'s camera's transform point.
# NOTE: The order of the results is unspecified.
(Player:player).RaycastAll<public>()<transacts>:[]raycast_hit=
    Player.RaycastAll(Inf)

# Casts forwards from the `Player`'s camera with `MaxDistance` against all bounding boxes in the scene.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain the `Player`'s camera's transform point.
# NOTE: The order of the results is unspecified.
(Player:player).RaycastAll<public>(MaxDistance:float)<transacts>:[]raycast_hit=
    Ray:ray = Player.GetCameraRay()
    Player.RaycastAll(Ray, MaxDistance)