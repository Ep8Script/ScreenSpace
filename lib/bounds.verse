using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

# An axis-aligned bounding box (AABB) that fully encloses an object.
bounds<public> := struct<concrete><computes>:
    @editable{ToolTip := CenterTooltip}
    # The midpoint of the bounding box.
    Center<public> : vector3 = vector3{}

    @editable{ToolTip := ExtentsTooltip}
    # The extents along each axis, half of the size of the bounding box.
    # Appropriate values for a mesh can be found in the Viewport Panel of the Static Mesh Editor under "Approx. Size".
    Extents<public> : vector3 = vector3{}

# Returns the closest point on the bounding box or inside the bounding box.
# If `Point` is inside the bounding box, it will be returned unmodified.
(Bounds:bounds).ClosestPoint<public>(Point:vector3)<computes>:vector3=
    Clamp(Point, Bounds.GetMin(), Bounds.GetMax())

# Succeeds if `Point` is inside the bounding box.
# Fails if `Bounds.Extents` contains a negative value in any direction.
(Bounds:bounds).Contains<public>(Point:vector3)<computes><decides>:void=
    BoundsMax:vector3 = Bounds.GetMax()
    BoundsMin:vector3 = Bounds.GetMin()
    BoundsMax.Left >= Point.Left
    BoundsMin.Left <= Point.Left
    BoundsMax.Up >= Point.Up
    BoundsMin.Up <= Point.Up
    BoundsMax.Forward >= Point.Forward
    BoundsMin.Forward <= Point.Forward

# Makes a `bounds` by encapsulating the bounding box with `InBounds`.
(Bounds:bounds).Encapsulate<public>(InBounds:bounds)<computes>:bounds=
    Bounds.Encapsulate(InBounds.Center - InBounds.Extents).Encapsulate(InBounds.Center + InBounds.Extents)

# Makes a `bounds` by encapsulating the bounding box with `Point`.
(Bounds:bounds).Encapsulate<public>(Point:vector3)<computes>:bounds=
    MaxPoint:vector3 = Max(Bounds.GetMax(), Point)
    MinPoint:vector3 = Min(Bounds.GetMin(), Point)
    NewExtents:vector3 = (MaxPoint - MinPoint) / 2.0
    bounds:
        Center := MinPoint + NewExtents
        Extents := NewExtents

# Makes a `bounds` by expanding the bounding box by `Amount * 2.0` each direction.
(Bounds:bounds).Expand<public>(Amount:vector3)<computes>:bounds=
    bounds:
        Center := Bounds.Center
        Extents := Bounds.Extents + Amount / 2.0

# Makes a `bounds` by expanding the bounding box by `Amount * 2.0` each direction.
(Bounds:bounds).Expand<public>(InAmount:float)<computes>:bounds=
    Amount:vector3 = vector3{Left := InAmount, Up := InAmount, Forward := InAmount}
    Bounds.Expand(Amount)

# Returns the maximal point of the bounding box.
# This is equivalent to `Bounds.Center + Bounds.Extents`.
(Bounds:bounds).GetMax<public>()<computes>:vector3=
    Bounds.Center + Bounds.Extents

# Returns the minimal point of the bounding box.
# This is equivalent to `Bounds.Center - Bounds.Extents`.
(Bounds:bounds).GetMin<public>()<computes>:vector3=
    Bounds.Center - Bounds.Extents

# Returns the total size of the bounding box.
# This is always twice as large as the extents.
(Bounds:bounds).GetSize<public>()<computes>:vector3=
    Bounds.Extents * 2.0

# Succeeds if `Ray` intersects this bounding box.
# Returns the distance to `Ray`'s origin.
(Bounds:bounds).IntersectRay<public>(Ray:ray)<computes><decides>:float=
    BoundsMax:vector3 = Bounds.GetMax()
    BoundsMin:vector3 = Bounds.GetMin()
    DirectionFixed:vector3 = Abs(Ray.Direction).IsAlmostZero[0.0] and Sgn(Ray.Direction) * 0.00000001 or Ray.Direction
    DirectionInverted:vector3 = 1.0 / DirectionFixed
    T1:vector3 = (BoundsMax - Ray.Origin) * DirectionInverted
    T2:vector3 = (BoundsMin - Ray.Origin) * DirectionInverted
    TMaxV:vector3 = Max(T1, T2)
    TMinV:vector3 = Min(T1, T2)
    TMax:float = Min(Min(TMaxV.Left, TMaxV.Up), TMaxV.Forward)
    TMin:float = Max(Max(TMinV.Left, TMinV.Up), TMinV.Forward)
    TMax >= 0.0
    TMax >= TMin
    Max(0.0, TMin)

# Succeeds if there is an intersection between `InBounds` and this bounding box.
(Bounds:bounds).Intersects<public>(InBounds:bounds)<computes><decides>:void=
    BoundsMax:vector3 = Bounds.GetMax()
    BoundsMin:vector3 = Bounds.GetMin()
    InMax:vector3 = InBounds.GetMax()
    InMin:vector3 = InBounds.GetMin()
    BoundsMax.Left >= InMin.Left
    BoundsMin.Left <= InMax.Left
    BoundsMax.Up >= InMin.Up
    BoundsMin.Up <= InMax.Up
    BoundsMax.Forward >= InMin.Forward
    BoundsMin.Forward <= InMax.Forward

# Returns the smallest squared distance between `Point` and this bounding box.
(Bounds:bounds).SquaredDistance<public>(Point:vector3)<reads>:float=
    PointClosest:vector3 = Bounds.ClosestPoint(Point)
    DistanceSquared(Point, PointClosest)

# Makes a `bounds` with the given center and size. The bounds will be set to half the given size.
MakeBounds<public>(Center:vector3, Size:vector3)<computes>:bounds=
    bounds:
        Center := Center
        Extents := Size / 2.0

# Makes a `bounds` by applying `Transform` to the given bounds.
MakeBounds<public>(Bounds:bounds, Transform:transform)<reads>:bounds=
    ExtentsMultiplied:vector3 = Bounds.Extents * Transform.Scale
    ForwardAxis:vector3 = Transform.Rotation.GetForwardAxis()
    LeftAxis:vector3 = Transform.Rotation.GetLeftAxis()
    UpAxis:vector3 = Transform.Rotation.GetUpAxis()
    bounds:
        Center := Bounds.Center * Transform
        Extents := Abs(LeftAxis) * ExtentsMultiplied.Left + Abs(UpAxis) * ExtentsMultiplied.Up + Abs(ForwardAxis) * ExtentsMultiplied.Forward

# Makes a `string` representation of `Bounds`.
ToString<public>(Bounds:bounds)<reads>:string=
    "\{Center = {Bounds.Center}, Extents = {Bounds.Extents}\}"