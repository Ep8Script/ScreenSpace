using { /Verse.org/Simulation }

# An aspect ratio defined by width and height.
aspect_ratio<public> := struct<computes>:
    # The height of the aspect ratio.
    Height<public> : int

    # The width of the aspect ratio.
    Width<public> : int

# Returns the ratio of `AspectRatio` as a floating point number.
(AspectRatio:aspect_ratio).GetRatio<public>()<computes>:float=
    AspectRatio.Width * 1.0 / (AspectRatio.Height * 1.0)

# Makes an `aspect_ratio` that represents the screen dimensions of `AspectRatio`, assuming 1080p.
# Fails if `not AspectRatio.GetRatio().IsFinite[]`.
(AspectRatio:aspect_ratio).GetScreenDimensions<public>()<decides><reads>:aspect_ratio=
    Ratio:float = AspectRatio.GetRatio()
    Ratio.IsFinite[]
    if (AspectRatio.Width >= AspectRatio.Height):
        aspect_ratio:
            Height := 1080
            Width := Floor[Ratio * 1080 + 0.5]
    else:
        aspect_ratio:
            Height := Floor[1080.0 / Ratio + 0.5]
            Width := 1080

# Makes a `string` representation of `AspectRatio`.
ToString<public>(AspectRatio:aspect_ratio)<computes>:string=
    "{AspectRatio.Width}:{AspectRatio.Height}"