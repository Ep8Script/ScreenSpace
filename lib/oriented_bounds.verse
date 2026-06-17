using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

# An oriented bounding box that fully encloses an object.
oriented_bounds<public> := struct<computes><concrete>:
    @editable{ToolTip := CenterTooltip}
    # The midpoint of the bounding box.
    Center<public> : vector3 = vector3{}

    @editable{ToolTip := OrientedExtentsTooltip}
    # The extents along each axis, half of the size of the bounding box.
    Extents<public> : vector3 = vector3{}

    @editable{ToolTip := OrientationTooltip}
    # The orientation of the bounding box.
    Orientation<public> : rotation = IdentityRotation()

# Returns the closest point on the bounding box or inside it.
(Bounds:oriented_bounds).ClosestPoint<public>(Point:vector3)<reads>:vector3=
    LocalPoint:vector3 = (Point - Bounds.Center) * Bounds.Orientation.Invert()
    Bounds.Center + Clamp(LocalPoint, -Bounds.Extents, Bounds.Extents) * Bounds.Orientation.Invert()

# Succeeds if the `Point` is inside the bounding box.
(Bounds:oriented_bounds).Contains<public>(Point:vector3)<decides><reads>:void=
    LocalPoint:vector3 = (Point - Bounds.Center) * Bounds.Orientation.Invert()
    Bounds.Extents.Left >= LocalPoint.Left
    -Bounds.Extents.Left <= LocalPoint.Left
    Bounds.Extents.Up >= LocalPoint.Up
    -Bounds.Extents.Up <= LocalPoint.Up
    Bounds.Extents.Forward >= LocalPoint.Forward
    -Bounds.Extents.Forward <= LocalPoint.Forward

# Makes an `oriented_bounds` by expanding the bounding box by `Amount * 2.0` each direction.
(Bounds:oriented_bounds).Expand<public>(Amount:vector3)<computes>:oriented_bounds=
    oriented_bounds:
        Center := Bounds.Center
        Extents := Bounds.Extents + (Amount / 2.0)
        Orientation := Bounds.Orientation

# Returns the corner positions of the bounding box.
(Bounds:oriented_bounds).GetCorners<public>()<reads>:tuple(vector3, vector3, vector3, vector3, vector3, vector3, vector3, vector3)=
    Left:float = Bounds.Extents.Left
    Up:float = Bounds.Extents.Up
    Forward:float = Bounds.Extents.Forward
    block:
        Bounds.Center + vector3{Left := -Left, Up := -Up, Forward := -Forward} * Bounds.Orientation,
        Bounds.Center + vector3{Left :=  Left, Up := -Up, Forward := -Forward} * Bounds.Orientation,
        Bounds.Center + vector3{Left :=  Left, Up := -Up, Forward :=  Forward} * Bounds.Orientation,
        Bounds.Center + vector3{Left := -Left, Up := -Up, Forward :=  Forward} * Bounds.Orientation,
        Bounds.Center + vector3{Left := -Left, Up :=  Up, Forward := -Forward} * Bounds.Orientation,
        Bounds.Center + vector3{Left :=  Left, Up :=  Up, Forward := -Forward} * Bounds.Orientation,
        Bounds.Center + vector3{Left :=  Left, Up :=  Up, Forward :=  Forward} * Bounds.Orientation,
        Bounds.Center + vector3{Left := -Left, Up :=  Up, Forward :=  Forward} * Bounds.Orientation

# Returns the total size of the bounding box.
# This is always twice as large as the extents.
(Bounds:oriented_bounds).GetSize<public>()<computes>:vector3=
    Bounds.Extents * 2.0

# Succeeds if `Ray` intersects this bounding box.
# Returns the distance to `Ray`'s origin.
(Bounds:oriented_bounds).IntersectRay<public>(Ray:ray)<decides><reads>:float=
    LocalDirection:vector3 = Ray.Direction * Bounds.Orientation.Invert()
    LocalDirectionFixed:vector3 = Abs(LocalDirection).IsAlmostZero[0.0] and Sgn(LocalDirection) * 0.00000001 or LocalDirection
    LocalDirectionInverted:vector3 = 1.0 / LocalDirectionFixed
    LocalOrigin:vector3 = Ray.Origin - Bounds.Center * Bounds.Orientation.Invert()    
    T1:vector3 = (-Bounds.Extents - LocalOrigin) * LocalDirectionInverted
    T2:vector3 = (Bounds.Extents - LocalOrigin) * LocalDirectionInverted
    TMaxV:vector3 = Max(T1, T2)
    TMax:float = Min(Min(TMaxV.Left, TMaxV.Up), TMaxV.Forward)
    TMinV:vector3 = Min(T1, T2)
    TMin:float = Max(Max(TMinV.Left, TMinV.Up), TMinV.Forward)
    TMax >= 0.0
    TMax >= TMin
    Max(0.0, TMin)

# Returns the smallest squared distance between `Point` and this bounding box.
(Bounds:oriented_bounds).SquaredDistance<public>(Point:vector3)<reads>:float=
    PointClosest:vector3 = Bounds.ClosestPoint(Point)
    DistanceSquared(Point, PointClosest)

# Makes an `oriented_bounds` with the given center, size and orientation. The bounds will be set to half the given size.
MakeOrientedBounds<public>(Center:vector3, Size:vector3, Orientation:rotation)<computes>:oriented_bounds=
    oriented_bounds:
        Center := Center
        Extents := Size / 2.0
        Orientation := Orientation

# Makes a `oriented_bounds` by applying `Transform` to the given bounds.
MakeOrientedBounds<public>(Bounds:bounds, Transform:transform)<reads>:oriented_bounds=
    oriented_bounds:
        Center := Bounds.Center * Transform
        Extents := Bounds.Extents * Abs(Transform.Scale)
        Orientation := Transform.Rotation

# Makes a `string` representation of `Bounds`.
ToString<public>(OrientatedBounds:oriented_bounds)<reads>:string=
    "\{Center = {OrientatedBounds.Center}, Extents = {OrientatedBounds.Extents}, Orientation = {OrientatedBounds.Orientation}\}"