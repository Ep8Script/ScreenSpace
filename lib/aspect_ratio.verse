using { /Verse.org/Simulation }

# An aspect ratio defined by width and height.
aspect_ratio<public> := struct<computes>:
    Height<public> : int
    Width<public> : int

# Returns the ratio of `AspectRatio` as a floating point number.
(AspectRatio:aspect_ratio).GetRatio<public>()<computes>:float=
    AspectRatio.Width * 1.0 / (AspectRatio.Height * 1.0)

# Makes an `aspect_ratio` that represents the screen resolution of `AspectRatio`, assuming 1080p.
(AspectRatio:aspect_ratio).GetScreenResolution<public>()<decides><reads>:aspect_ratio=
    Ratio:float = AspectRatio.GetRatio()
    aspect_ratio:
        Height := 1080
        Width := Floor[Ratio * 1080 + 0.5]

# Makes a `string` representation of `AspectRatio`.
ToString<public>(AspectRatio:aspect_ratio)<computes>:string=
    "{AspectRatio.Width}:{AspectRatio.Height}"