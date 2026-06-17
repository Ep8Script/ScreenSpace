using { /Verse.org/Input }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

# A ray is an infinite line beginning at `Origin` and pointing in `Direction`.
ray<public> := struct<computes><concrete>:
    @editable{ToolTip := RayTooltip}
    # The direction of the ray.
    Direction<public> : vector3 = vector3{Forward := 1.0}

    @editable{ToolTip := OriginTooltip}
    # The origin of the ray.
    Origin<public> : vector3 = vector3{}

# Makes a `vector3` from the point at `InDistance` centimetres along the ray.
(Ray:ray).GetPoint<public>(InDistance:float)<computes>:vector3=
    Ray.Origin + Ray.Direction * InDistance

# Makes a `ray` beginning at `Origin` and pointing in `Direction`.
MakeRay<public>(Origin:vector3, Direction:vector3)<reads>:ray=
    ray:
        Direction := Direction.MakeUnitVector()
        Origin := Origin

# Makes a `string` representation of `Ray`.
ToString<public>(Ray:ray)<reads>:string=
    "\{Direction = {Ray.Direction}, Origin = {Ray.Origin}\}"