using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }

# A 2D rectangle defined by X and Y position, height and width.
rect<public> := struct<computes><concrete>:
    @editable{ToolTip := XTooltip}
    # The X coordinate of the rectangle.
    X<public> : float = 0.0

    @editable{ToolTip := YTooltip}
    # The Y coordinate of the rectangle.
    Y<public> : float = 0.0

    @editable{ToolTip := WidthTooltip}
    # The width of the rectangle, measured from the `X` position.
    Width<public> : float = 0.0

    @editable{ToolTip := HeightTooltip}
    # The height of the rectangle, measured from the `Y` position.
    Height<public> : float = 0.0

# Makes a `rect` from min/max coordinates.
(:subtype(rect)).MinMaxRect<public>(MinX:float, MinY:float, MaxX:float, MaxY:float)<computes>:rect=
    rect:
        X := MinX
        Y := MinY
        Width := MaxX - MinX
        Height := MaxY - MinY

# Returns a point inside a `rect`, given normalized coordinates.
(:subtype(rect)).NormalizedToPoint<public>(Rect:rect, Point:vector2)<reads>:vector2=
    vector2:
        X := Lerp(Rect.X, Rect.GetMaxX(), Point.X)
        Y := Lerp(Rect.Y, Rect.GetMaxY(), Point.Y)

# Returns the normalized coordinates corresponding to `Point`.
(:subtype(rect)).PointToNormalized<public>(Rect:rect, Point:vector2)<computes>:vector2=
    vector2:
        X := InvLerp(Rect.X, Rect.GetMaxX(), Point.X)
        Y := InvLerp(Rect.Y, Rect.GetMaxY(), Point.Y)

# Suceeds if `Point` is inside `Rect`.
(Rect:rect).Contains<public>(Point:vector2)<computes><decides>:void=
    Point.X >= Rect.GetMinX()
    Point.X < Rect.GetMaxX()
    Point.Y >= Rect.GetMinY()
    Point.Y < Rect.GetMaxY()

# Returns the position of the center of `Rect`.
(Rect:rect).GetCenter<public>()<computes>:vector2=
    vector2:
        X := Rect.X + Rect.Width / 2.0
        Y := Rect.Y + Rect.Height / 2.0

# Returns the position of the maximum corner of `Rect`.
(Rect:rect).GetMax<public>()<computes>:vector2=
    vector2:
        X := Rect.GetMaxX()
        Y := Rect.GetMaxY()

# Returns the maximum X coordinate of `Rect`.
(Rect:rect).GetMaxX<public>()<computes>:float=
    Rect.Width + Rect.X

# Returns the maximum X coordinate of `Rect`.
(Rect:rect).GetMaxY<public>()<computes>:float=
    Rect.Height + Rect.Y

# Returns the position of the minimum corner of `Rect`.
(Rect:rect).GetMin<public>()<computes>:vector2=
    vector2:
        X := Rect.GetMinX()
        Y := Rect.GetMinY()

# Returns the minimum X coordinate of `Rect`.
(Rect:rect).GetMinX<public>()<computes>:float=
    Rect.X

# Returns the minimum Y coordinate of `Rect`.
(Rect:rect).GetMinY<public>()<computes>:float=
    Rect.Y

# Returns the `X` and `Y` position of `Rect`.
(Rect:rect).GetPosition<public>()<computes>:vector2=
    vector2:
        X := Rect.X
        Y := Rect.Y

# Returns the width and height of `Rect`.
(Rect:rect).GetSize<public>()<computes>:vector2=
    vector2:
        X := Rect.Width
        Y := Rect.Height

# Suceeds if `InRect` overlaps `Rect`.
(Rect:rect).Overlaps<public>(InRect:rect)<computes><decides>:void=
    InRect.GetMaxX() > Rect.GetMinX()
    InRect.GetMinX() < Rect.GetMaxX()
    InRect.GetMaxY() > Rect.GetMinY()
    InRect.GetMinY() < Rect.GetMaxY()

# Makes a `rect`.
MakeRect<public>(X:float, Y:float, Width:float, Height:float)<computes>:rect=
    rect:
        X := X
        Y := Y
        Width := Width
        Height := Height

# Makes a `rect` with the given `Position` and `Size`.
MakeRect<public>(Position:vector2, Size:vector2)<computes>:rect=
    rect:
        X := Position.X
        Y := Position.Y
        Width := Size.X
        Height := Size.Y

# Makes a `string` representation of `Rect`.
ToString<public>(Rect:rect)<reads>:string=
    "\{X = {Rect.X}, Y = {Rect.Y}, Width = {Rect.Width}, Height = {Rect.Height}\}"