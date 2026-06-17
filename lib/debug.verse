using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Colors }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

debug_bounds_channel<internal> := class(debug_draw_channel):
debug_plane_channel<internal> := class(debug_draw_channel):
debug_raycast_channel<internal> := class(debug_draw_channel):

ClearDebugDraw<internal>(Channel:subtype(debug_draw_channel))<transacts>:void=
    Draw:debug_draw = debug_draw{Channel := Channel}
    Draw.ClearChannel()

# Clears the debug draw channel used by bounds.
ClearBoundsDebugDraw<public>()<transacts>:void=
    ClearDebugDraw(debug_bounds_channel)

# Clears the debug draw channel used by planes.
ClearPlaneDebugDraw<public>()<transacts>:void=
    ClearDebugDraw(debug_plane_channel)

# Clears the debug draw channel used by raycasts.
ClearRaycastDebugDraw<public>()<transacts>:void=
    ClearDebugDraw(debug_raycast_channel)

# Draws a box representing the axis-aligned `Bounds`, using the provided draw parameters.
DebugDraw<public>(Bounds:bounds, ?Color:color = NamedColors.Yellow, ?Duration:float = Inf)<transacts>:void=
    Draw:debug_draw = debug_draw{Channel := debug_bounds_channel}
    Draw.DrawBox(Bounds.Center, IdentityRotation(), ?Color := Color, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Duration := Duration, ?Extent := Bounds.Extents)

# Draws a box representing the `BoundsComponents.Bounds` with the `BoundsComponents.Entity`'s global transformation applied, using the provided draw parameters.
DebugDraw<public>(BoundsComponent:bounds_component, ?Color:color = NamedColors.Yellow, ?Duration:float = Inf)<transacts>:void=
    Draw:debug_draw = debug_draw{Channel := debug_bounds_channel}
    OrientedBounds:oriented_bounds = BoundsComponent.GetOrientedBounds()
    Draw.DrawBox(OrientedBounds.Center, OrientedBounds.Orientation, ?Color := Color, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Duration := Duration, ?Extent := OrientedBounds.Extents)

# Draws a box representing `Entity`'s bounds with its global transformation applied, using the provided draw parameters.
# If `Entity` doesn't have a `bounds_component`, this uses an encapsulation of the bounds of its immediate children.
# Fails if none of `Entity`'s descendants have a `bounds_component`.
DebugDraw<public>(Entity:entity, ?Color:color = NamedColors.Yellow, ?Duration:float = Inf)<decides><transacts>:void=
    OrientedBounds:oriented_bounds = Entity.GetOrientedBounds[]
    Draw:debug_draw = debug_draw{Channel := debug_bounds_channel}
    Draw.DrawBox(OrientedBounds.Center, OrientedBounds.Orientation, ?Color := Color, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Duration := Duration, ?Extent := OrientedBounds.Extents)

# Draws a square representing `Plane` at the given `Size`, using the provided draw parameters.
DebugDraw<public>(Plane:plane, Size:float, ?Color:color = NamedColors.Yellow, ?Duration:float = Inf)<transacts>:void=
    var CrossForward:vector3 = CrossProduct(Plane.Normal, vector3{Up := 1.0})
    if (CrossForward.LengthSquared().IsAlmostZero[0.0]):
        set CrossForward = CrossProduct(Plane.Normal, vector3{Forward := 1.0})
    set CrossForward = CrossForward.MakeUnitVector()
    CrossRight:vector3 = CrossProduct(Plane.Normal, CrossForward).MakeUnitVector()
    Draw:debug_draw = debug_draw{Channel := debug_plane_channel}
    FixedPosition:vector3 = Plane.Normal * -Plane.Distance
    PlaneCorner1:vector3 = FixedPosition + (CrossForward + CrossRight) * Size
    PlaneCorner2:vector3 = FixedPosition + (CrossForward - CrossRight) * Size
    PlaneCorner3:vector3 = FixedPosition + (-CrossForward - CrossRight) * Size
    PlaneCorner4:vector3 = FixedPosition + (-CrossForward + CrossRight) * Size
    Draw.DrawLine(PlaneCorner1, PlaneCorner2, ?Color := Color, ?Duration := Duration, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Thickness := 2.0)
    Draw.DrawLine(PlaneCorner1, PlaneCorner3, ?Color := Color, ?Duration := Duration, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Thickness := 2.0)
    Draw.DrawLine(PlaneCorner2, PlaneCorner3, ?Color := Color, ?Duration := Duration, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Thickness := 2.0)
    Draw.DrawLine(PlaneCorner2, PlaneCorner4, ?Color := Color, ?Duration := Duration, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Thickness := 2.0)
    Draw.DrawLine(PlaneCorner3, PlaneCorner4, ?Color := Color, ?Duration := Duration, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Thickness := 2.0)
    Draw.DrawLine(PlaneCorner4, PlaneCorner1, ?Color := Color, ?Duration := Duration, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Thickness := 2.0)
    Draw.DrawLine(FixedPosition, FixedPosition + Plane.Normal.MakeUnitVector() * Size, ?Color := MakeColorFromSRGB(1.0 - Color.R, 1.0 - Color.G, 1.0 - Color.B), ?Duration := Duration, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Thickness := 2.0)

# Draws a box representing the axis-aligned global bounds of `BoundsComponent.Entity`, using the provided draw parameters.
DebugDrawGlobal<public>(BoundsComponent:bounds_component, ?Color:color = NamedColors.Yellow, ?Duration:float = Inf)<transacts>:void=
    Bounds:bounds = BoundsComponent.GetGlobalBounds()
    DebugDraw(Bounds, ?Color := Color, ?Duration := Duration)

# Draws a box representing the axis-aligned global bounds of `Entity`, using the provided draw parameters.
# If `Entity` doesn't have a `bounds_component`, this uses an encapsulation of the bounds of its immediate children.
# Fails if none of `Entity`'s descendants have a `bounds_component`.
DebugDrawGlobal<public>(Entity:entity, ?Color:color = NamedColors.Yellow, ?Duration:float = Inf)<decides><transacts>:void=
    Bounds:bounds = Entity.GetBoundsGlobal[]
    DebugDraw(Bounds, ?Color := Color, ?Duration := Duration)

# Draws a frustum representing `Player`'s camera's frustum planes, using the provided draw parameters.
DebugFrustumPlanes<public>(Player:player, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0, ?MaxDistance:float = 512.0)<transacts>:void=
    if (Center := Player.DeprojectViewportToWorld[0.5, 0.5]):
        var CloseCorners:[]vector3 = (vector3{}, vector3{}, vector3{}, vector3{})
        Debug:debug_draw = debug_draw{Channel := debug_plane_channel}
        var FarCorners:[]vector3 = (vector3{}, vector3{}, vector3{}, vector3{})
        var FrustumPlanes:[]plane = Player.CalculateFrustumPlanes()
        for:
            I := 0..3
            EdgeDirection := CrossProduct(FrustumPlanes[I].Normal, FrustumPlanes[Mod[I + 1, 4]].Normal)
            NewCloseCorners := Center.Origin * 2.0 + Intersect[FrustumPlanes[4], FrustumPlanes[I], FrustumPlanes[Mod[I + 1, 4]]]
            set CloseCorners[I] = NewCloseCorners
            set FarCorners[I] = NewCloseCorners + if (DotProduct(Center.Direction, EdgeDirection) < 0.0):
                -EdgeDirection * MaxDistance
            else:
                EdgeDirection * MaxDistance
        for:
            I := 0..3
            Debug.DrawLine(CloseCorners[I], CloseCorners[Mod[I + 1, 4]], ?Color := Color, ?Duration := Duration, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Thickness := 2.0)        
            Debug.DrawLine(FarCorners[I], FarCorners[Mod[I + 1, 4]], ?Color := Color, ?Duration := Duration, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Thickness := 2.0)        
            Debug.DrawLine(CloseCorners[I], FarCorners[I], ?Color := MakeColorFromSRGB(1.0 - Color.R, 1.0 - Color.G, 1.0 - Color.B), ?Duration := Duration, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Thickness := 2.0)

# Calls: `Entity.LineCast[:vector3, :vector3]`.
# Draws an arrow representing the ray pointed from `Start` to `End`, using the provided draw parameters.
# If an entity is hit, the arrow will be drawn to the hit position and an additional arrow will reflect on the hit's normal.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the line between `Start` and `End`.
# NOTE: Linecasts will not detect any `bounds` that contain `Start`.
DebugLinecast<public>(Entity:entity, Start:vector3, End:vector3, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<decides><transacts>:raycast_hit=
    Hit:raycast_hit = Entity.Linecast[Start, End]
    Draw:debug_draw = debug_draw{Channel := debug_raycast_channel}
    Draw.DrawArrow(Start, Hit.Position, ?Color := Color, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Duration := Duration, ?Thickness := 2.0)
    Draw.DrawArrow(Hit.Position, Hit.Position + Hit.Normal * 500.0, ?Color := MakeColorFromSRGB(1.0 - Color.R, 1.0 - Color.G, 1.0 - Color.B), ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Duration := Duration, ?Thickness := 2.0)
    Hit

# Calls: `Entity.LineCast[:vector3, :vector3]`.
# Draws an arrow representing the ray pointed from the `Player`'s camera to `End`, using the provided draw parameters.
# If an entity is hit, the arrow will be drawn to the hit position and an additional arrow will reflect on the hit's normal.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the line between the `Player`'s camera and `End`.
# NOTE: Linecasts will not detect any `bounds` that contain the `Player`'s camera's transform point.
DebugLinecast<public>(Player:player, Entity:entity, End:vector3, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<decides><transacts>:raycast_hit=
    Start := Player.DeprojectViewportToWorld[0.5, 0.5].Origin
    DebugLinecast[Entity, Start, End, ?Color := Color, ?Duration := Duration]

# Calls: `Entity.Raycast[:ray, :float]`.
# Draws an arrow representing the ray pointed from `Origin` towards `Direction`, using the provided draw parameters.
# If an entity is hit, the arrow will be drawn to the hit position and an additional arrow will reflect on the hit's normal.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the ray.
# NOTE: Raycasts will not detect any `bounds` that contain `Origin`.
DebugRaycast<public>(Entity:entity, Origin:vector3, Direction:vector3, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<decides><transacts>:raycast_hit=
    DebugRaycast[Entity, Origin, Direction, Inf, ?Color := Color, ?Duration := Duration]

# Calls: `Entity.Raycast[:ray, :float]`.
# Draws an arrow representing the ray pointed from `Origin` towards `Direction` with `MaxDistance`, using the provided draw parameters.
# If an entity is hit, the arrow will be drawn to the hit position and an additional arrow will reflect on the hit's normal.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the ray.
# NOTE: Raycasts will not detect any `bounds` that contain `Origin`.
DebugRaycast<public>(Entity:entity, Origin:vector3, Direction:vector3, MaxDistance:float, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<decides><transacts>:raycast_hit=
    Ray:ray = MakeRay(Origin, Direction)
    DebugRaycast[Entity, Ray, MaxDistance, ?Color := Color, ?Duration := Duration]

# Calls: `Entity.Raycast[:ray, :float]`.
# Draws an arrow representing `Ray`, using the provided draw parameters.
# If an entity is hit, the arrow will be drawn to the hit position and an additional arrow will reflect on the hit's normal.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the ray.
# NOTE: Raycasts will not detect any `bounds` that contain `Ray.Origin`.
DebugRaycast<public>(Entity:entity, Ray:ray, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<decides><transacts>:raycast_hit=
    DebugRaycast[Entity, Ray.Origin, Ray.Direction, Inf, ?Color := Color, ?Duration := Duration]

# Calls: `Entity.Raycast[:ray, :float]`.
# Draws an arrow representing `Ray` with `MaxDistance`, using the provided draw parameters.
# If an entity is hit, the arrow will be drawn to the hit position and an additional arrow will reflect on the hit's normal.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the ray.
# NOTE: Raycasts will not detect any `bounds` that contain `Ray.Origin`.
DebugRaycast<public>(Entity:entity, Ray:ray, MaxDistance:float, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<decides><transacts>:raycast_hit=
    Hit:raycast_hit = Entity.Raycast[Ray, MaxDistance]
    Draw:debug_draw = debug_draw{Channel := debug_raycast_channel}
    Draw.DrawArrow(Ray.Origin, Hit.Position, ?Color := Color, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Duration := Duration, ?Thickness := 2.0)
    Draw.DrawArrow(Hit.Position, Hit.Position + Hit.Normal * 500.0, ?Color := MakeColorFromSRGB(1.0 - Color.R, 1.0 - Color.G, 1.0 - Color.B), ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Duration := Duration, ?Thickness := 2.0)
    Hit

# Calls: `Entity.Raycast[:ray, :float]`.
# Draws an arrow representing the ray pointed from the `Player`'s camera, using the provided draw parameters.
# If an entity is hit, the arrow will be drawn to the hit position and an additional arrow will reflect on the hit's normal.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the line in front of the `Player`'s camera.
# NOTE: Raycasts will not detect any `bounds` that contain the `Player`'s camera's transform point.
DebugRaycast<public>(Player:player, Entity:entity, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<decides><transacts>:raycast_hit=
    DebugRaycast[Player, Entity, Inf, ?Color := Color, ?Duration := Duration]

# Calls: `Entity.Raycast[:ray, :float]`.
# Draws an arrow representing the ray pointed from the `Player`'s camera with `MaxDistance`, using the provided draw parameters.
# If an entity is hit, the arrow will be drawn to the hit position and an additional arrow will reflect on the hit's normal.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the line in front of the `Player`'s camera.
# NOTE: Raycasts will not detect any `bounds` that contain the `Player`'s camera's transform point.
DebugRaycast<public>(Player:player, Entity:entity, MaxDistance:float, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<decides><transacts>:raycast_hit=
    Ray:ray = Player.GetCameraRay()
    DebugRaycast[Entity, Ray, MaxDistance, ?Color := Color, ?Duration := Duration]

# Calls: `Entity.RaycastAll(:ray, :float)`.
# Draws an arrow representing the ray pointed from `Origin` towards `Direction`, using the provided draw parameters.
# If any entities are hit, an arrow will be drawn to each of their hit positions and an additional arrow will reflect on the hit's normal.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain `Origin`.
# NOTE: The order of the results is unspecified.
# NOTE: `Entity` defines the context for the raycast but does not otherwise take part.
DebugRaycastAll<public>(Entity:entity, Origin:vector3, Direction:vector3, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<transacts>:[]raycast_hit=
    DebugRaycastAll(Entity, Origin, Direction, Inf, ?Color := Color, ?Duration := Duration)

# Calls: `Entity.RaycastAll(:ray, :float)`.
# Draws an arrow representing the ray pointed from `Origin` towards `Direction` with `MaxDistance`, using the provided draw parameters.
# If any entities are hit, an arrow will be drawn to each of their hit positions and an additional arrow will reflect on the hit's normal.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain `Origin`.
# NOTE: The order of the results is unspecified.
# NOTE: `Entity` defines the context for the raycast but does not otherwise take part.
DebugRaycastAll<public>(Entity:entity, Origin:vector3, Direction:vector3, MaxDistance:float, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<transacts>:[]raycast_hit=
    Ray:ray = MakeRay(Origin, Direction)
    DebugRaycastAll(Entity, Ray, MaxDistance, ?Color := Color, ?Duration := Duration)

# Calls: `Entity.RaycastAll(:ray, :float)`.
# Draws an arrow representing `Ray`, using the provided draw parameters.
# If any entities are hit, an arrow will be drawn to each of their hit positions and an additional arrow will reflect on the hit's normal.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain `Ray.Origin`.
# NOTE: The order of the results is unspecified.
# NOTE: `Entity` defines the context for the raycast but does not otherwise take part.
DebugRaycastAll<public>(Entity:entity, Ray:ray, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<transacts>:[]raycast_hit=
    DebugRaycastAll(Entity, Ray, Inf, ?Color := Color, ?Duration := Duration)

# Calls: `Entity.RaycastAll(:ray, :float)`.
# Draws an arrow representing `Ray` with `MaxDistance`, using the provided draw parameters.
# If any entities are hit, an arrow will be drawn to each of their hit positions and an additional arrow will reflect on the hit's normal.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain `Ray.Origin`.
# NOTE: The order of the results is unspecified.
# NOTE: `Entity` defines the context for the raycast but does not otherwise take part.
DebugRaycastAll<public>(Entity:entity, Ray:ray, MaxDistance:float, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<transacts>:[]raycast_hit=
    Draw:debug_draw = debug_draw{Channel := debug_raycast_channel}
    for (Hit : Entity.RaycastAll(Ray, MaxDistance)):
        Draw.DrawArrow(Ray.Origin, Hit.Position, ?Color := Color, ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Duration := Duration, ?Thickness := 2.0)
        Draw.DrawArrow(Hit.Position, Hit.Position + Hit.Normal * 500.0, ?Color := MakeColorFromSRGB(1.0 - Color.R, 1.0 - Color.G, 1.0 - Color.B), ?DrawDurationPolicy := GetDebugDrawDurationPolicy(Duration), ?Duration := Duration, ?Thickness := 2.0)
        Hit

# Calls: `Entity.RaycastAll(:ray, :float)`.
# Draws an arrow representing the ray pointed from the `Player`'s camera, using the provided draw parameters.
# If any entities are hit, an arrow will be drawn to each of their hit positions and an additional arrow will reflect on the hit's normal.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain the `Player`'s camera's transform point.
# NOTE: The order of the results is unspecified.
DebugRaycastAll<public>(Player:player, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<transacts>:[]raycast_hit=
    DebugRaycastAll(Player, Inf, ?Color := Color, ?Duration := Duration)

# Calls: `Entity.RaycastAll(:ray, :float)`.
# Draws an arrow representing the ray pointed from the `Player`'s camera with `MaxDistance`, using the provided draw parameters.
# If any entities are hit, an arrow will be drawn to each of their hit positions and an additional arrow will reflect on the hit's normal.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain the `Player`'s camera's transform point.
# NOTE: The order of the results is unspecified.
DebugRaycastAll<public>(Player:player, MaxDistance:float, ?Color:color = NamedColors.Yellow, ?Duration:float = 0.0)<transacts>:[]raycast_hit=
    Ray:ray = Player.GetCameraRay()
    DebugRaycastAll(Player, Ray, MaxDistance, ?Color := Color, ?Duration := Duration)

GetDebugDrawDurationPolicy<internal>(Duration:float)<computes>:debug_draw_duration_policy=
    if (not Duration.IsFinite[]):
        debug_draw_duration_policy.Persistent
    else if (Duration <= 1.0 / 30.0):
        debug_draw_duration_policy.SingleFrame
    else :
        debug_draw_duration_policy.FiniteDuration

HideDebugDraw<internal>(Channel:subtype(debug_draw_channel))<transacts>:void=
    Draw:debug_draw = debug_draw{Channel := Channel}
    Draw.HideChannel()

# Hides the debug draw channel used by bounds.
HideBoundsDebugDraw<public>()<transacts>:void=
    HideDebugDraw(debug_bounds_channel)

# Hides the debug draw channel used by planes.
HidePlaneDebugDraw<public>()<transacts>:void=
    HideDebugDraw(debug_plane_channel)

# Hides the debug draw channel used by raycasts.
HideRaycastDebugDraw<public>()<transacts>:void=
    HideDebugDraw(debug_raycast_channel)

ShowDebugDraw<internal>(Channel:subtype(debug_draw_channel))<transacts>:void=
    Draw:debug_draw = debug_draw{Channel := Channel}
    Draw.ShowChannel()

# Shows the debug draw channel used by bounds.
ShowBoundsDebugDraw<public>()<transacts>:void=
    ShowDebugDraw(debug_bounds_channel)

# Shows the debug draw channel used by planes.
ShowPlaneDebugDraw<public>()<transacts>:void=
    ShowDebugDraw(debug_plane_channel)

# Shows the debug draw channel used by raycasts.
ShowRaycastDebugDraw<public>()<transacts>:void=
    ShowDebugDraw(debug_raycast_channel)