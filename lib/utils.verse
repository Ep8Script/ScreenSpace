using { /UnrealEngine.com/Temporary }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Input }
using { /Verse.org/SpatialMath }

# Makes a `vector3` representing the point of intersection between `Plane1`, `Plane2`, and `Plane3`.
# Fails if the planes are parallel.
Intersect<public>(Plane1:plane, Plane2:plane, Plane3:plane)<decides><reads>:vector3=
    Denominator:float = DotProduct(Plane1.Normal, CrossProduct(Plane2.Normal, Plane3.Normal))
    not Denominator.IsAlmostZero[0.0]
    Term1:vector3 = Plane1.Distance * CrossProduct(Plane2.Normal, Plane3.Normal)
    Term2:vector3 = Plane2.Distance * CrossProduct(Plane3.Normal, Plane1.Normal)
    Term3:vector3 = Plane3.Distance * CrossProduct(Plane1.Normal, Plane2.Normal)
    (Term1 + Term2 + Term3) / Denominator

# Determines where a `Parameter` is between two points.
InvLerp<public>(From:float, To:float, Parameter:float)<computes>:float=
    (Parameter - From) / (To - From)

# Succeeds if the global bounds intersect the given frustum planes.
(GlobalBounds:bounds).IsInFrustum<public>(Planes:[]plane)<decides><reads>:void=
    for (Plane : Planes):
        AbsNormal := Abs(Plane.Normal)
        Dist:float = Distance(GlobalBounds.Center, Plane)
        Radius:float = DotProduct(AbsNormal, GlobalBounds.Extents)
        Dist >= -Radius

# Succeeds if the oriented bounds intersect the given frustum planes.
(Bounds:oriented_bounds).IsInFrustum<public>(Planes:[]plane)<decides><reads>:void=
    ForwardAxis:vector3 = Bounds.Orientation.GetForwardAxis()
    LeftAxis:vector3 = Bounds.Orientation.GetLeftAxis()
    UpAxis:vector3 = Bounds.Orientation.GetUpAxis()
    for (Plane : Planes):
        Dist:float = Distance(Bounds.Center, Plane)
        Projected:vector3 = Bounds.Extents * Abs(vector3:
            Left := DotProduct(LeftAxis, Plane.Normal)
            Up := DotProduct(UpAxis, Plane.Normal)
            Forward := DotProduct(ForwardAxis, Plane.Normal)
        )
        Radius:float = Projected.Forward + Projected.Left + Projected.Up
        Dist >= -Radius

# Makes `anchors` from `rect`.
MakeAnchors<public>(Rect:rect)<transacts>:anchors=
    Position := Rect.GetPosition()
    anchors:
        Maximum := SpatialMath.operator'+'(Position, Rect.GetSize())
        Minimum := Position

# Makes `deproject_results` from `Ray`.
MakeDeprojectResults<public>(Ray:ray)<transacts>:deproject_results=
    deproject_results:
        Direction := Ray.Direction
        Origin := Ray.Origin

# Makes a `ray` from `DeprojectResults`.
MakeRay<public>(DeprojectResults:deproject_results)<computes>:ray=
    ray:
        Direction := DeprojectResults.Direction
        Origin := DeprojectResults.Origin