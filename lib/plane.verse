using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

# A 3D representation of a plane, an infinitely flat and large surface that divides the space into two halves.
plane<public> := struct<computes><concrete>:
    @editable{ToolTip := DistanceTooltip}
    # The distance measured from the plane to the origin along `Normal`.
    (plane:)Distance<public> : float = 0.0

    @editable{ToolTip := NormalTooltip}
    # The normal vector of the plane.
    Normal<public> : vector3 = vector3{Forward := 1.0}

# Makes a `plane` by moving `Plane` by the given `Translation`.
(:subtype(plane)).Translate<public>(Plane:plane, Translation:vector3)<reads>:plane=
    Plane.Translate(Translation)

# Makes a `vector3` by getting the point on `Plane` closest to `Point`.
(Plane:plane).ClosestPointOnPlane<public>(Point:vector3)<reads>:vector3=
    Dist:float = DotProduct(Plane.Normal, Point) + Plane.Distance
    Point - Plane.Normal * Dist

# Makes a `plane` that faces in the opposite direction to `Normal`.
(Plane:plane).Flip<public>()<computes>:plane=
    plane:
        Distance := -Plane.Distance
        Normal := -Plane.Normal

# Succeeds if `Point` is on the positive side of `Plane`.
(Plane:plane).GetSide<public>(Point:vector3)<decides><reads>:void=
    DotProduct(Plane.Normal, Point) + Plane.Distance > 0.0

# Succeeds if both `Point` and `Point2` are on the same side of `Plane`.
(Plane:plane).IsSameSide<public>(Point1:vector3, Point2:vector3)<decides><reads>:void=
    DistanceToPoint1:float = Distance(Plane, Point1)
    DistanceToPoint2:float = Distance(Plane, Point2)
    DistanceToPoint1 > 0.0 and DistanceToPoint2 > 0.0 or DistanceToPoint1 <= 0.0 and DistanceToPoint2 <= 0.0

# Returns the position where `Ray` intersects with `Plane`.
# Fails if `Ray` is parallel to `Plane`.
(Plane:plane).Raycast<public>(Ray:ray)<decides><reads>:float=
    Num:float = DotProduct(Plane.Normal, Ray.Direction)
    not Num.IsAlmostZero[0.0]
    Num2:float = -DotProduct(Plane.Normal, Ray.Origin) - Plane.Distance
    Num2 / Num

# Makes a `Plane` that is moved by the given `Translation`.
(Plane:plane).Translate<public>(Translation:vector3)<reads>:plane=
    MakePlane(Plane.Normal, Plane.Distance + DotProduct(Plane.Normal, Translation))

# Returns the signed distance between `Plane` and `Point`.
Distance<public>(Plane:plane, Point:vector3)<reads>:float=
    DotProduct(Plane.Normal, Point) + Plane.Distance

# Returns the signed distance between `Point` and `Plane`.
Distance<public>(Point:vector3, Plane:plane)<reads>:float=
    Distance(Plane, Point)

# Makes a `plane` with `InDistance` measured from it to the origin along `Normal`.
MakePlane<public>(Normal:vector3, InDistance:float)<reads>:plane=
    plane:
        Distance := InDistance
        Normal := Normal.MakeUnitVector()

# Makes a `plane` that has `Normal` and goes through `Point`.
MakePlane<public>(Normal:vector3, Point:vector3)<reads>:plane=
    UnitNormal:vector3 = Normal.MakeUnitVector()
    plane:
        Distance := -DotProduct(Point, UnitNormal)
        Normal := UnitNormal

# Makes a `plane` that goes through the three points.
# The points go clockwise as you look down on the top surface of the `plane`.
MakePlane<public>(Point1:vector3, Point2:vector3, Point3:vector3)<reads>:plane=
    Normal:vector3 = CrossProduct(Point2 - Point1, Point3 - Point1).MakeUnitVector()
    plane:
        Distance := -DotProduct(Normal, Point1)
        Normal := Normal

# Makes a `string` representation of `Plane`.
ToString<public>(Plane:plane)<reads>:string=
    "\{Distance = {Plane.Distance}, Normal = {Plane.Normal}\}"