using { /Verse.org/SpatialMath }

# Makes a `vector3` by setting the components of `V` to their absolute values.
Abs<public>(V:vector3)<computes>:vector3=
    vector3:
        Left := Abs(V.Left)
        Up := Abs(V.Up)
        Forward := Abs(V.Forward)

# Makes a `vector3` by constraining the component values of `Val` between `A` and `B`. Robustly handles different argument orderings.
# Returns the median of `Val`, `A`, and `B`, such that comparisons with `NaN` operate as if `NaN > +Inf`.
Clamp<public>(Val:vector3, A:vector3, B:vector3)<computes>:vector3=
    vector3:
        Left := Clamp(Val.Left, A.Left, B.Left)
        Up := Clamp(Val.Up, A.Up, B.Up)
        Forward := Clamp(Val.Forward, A.Forward, B.Forward)

# Makes a `vector3` by calculating the maximum of the components of `X` and `Y`.
Max<public>(V1:vector3, V2:vector3)<computes>:vector3=
    vector3:
        Left := Max(V1.Left, V2.Left)
        Up := Max(V1.Up, V2.Up)
        Forward := Max(V1.Forward, V2.Forward)

# Makes a `vector3` by calculating the minimum of the components of `X` and `Y`.
Min<public>(V1:vector3, V2:vector3)<computes>:vector3=
    vector3:
        Left := Min(V1.Left, V2.Left)
        Up := Min(V1.Up, V2.Up)
        Forward := Min(V1.Forward, V2.Forward)

# Makes a `vector3` by dividing `Left` by the components of `Right`.
operator'/'<public>(Left:float, Right:vector3)<computes>:vector3=
    vector3:
        Left := Left / Right.Left
        Up := Left / Right.Up
        Forward := Left / Right.Forward

# Makes a `transform` by inverting the values of its components.
prefix'-'<public>(Operand:transform)<reads>:transform=
    InvertedRotation:rotation = Operand.Rotation.Invert()
    transform:
        Rotation := InvertedRotation
        Scale := 1.0 / Operand.Scale
        Translation := -Operand.Translation / Operand.Scale * InvertedRotation

# Makes a `vector3` by calculating the sign of its components.
Sgn<public>(V:vector3)<computes>:vector3=
    vector3:
        Left := Sgn(V.Left)
        Up := Sgn(V.Up)
        Forward := Sgn(V.Forward)