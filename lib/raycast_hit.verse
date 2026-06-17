using { /Verse.org/Presentation }
using { /Verse.org/SceneGraph }
using { /Verse.org/SpatialMath }

# A struct used to get information from a raycast.
raycast_hit<public> := struct<computes>:
    # The distance from the ray's origin to the impact position.
    (raycast_hit:)Distance<public> : float

    # The entity that was hit.
    Entity<public> : entity

    # The normal of the surface the ray hit.
    Normal<public> : vector3

    # The impact position in global space where the ray hit the entity.
    Position<public> : vector3

    # The transform of the entity that was hit.
    Transform<public> : transform

# Makes a `string` representation of `RaycastHit`.
ToString<public>(RaycastHit:raycast_hit)<transacts>:string=
    Entity:string = if (DescriptionComponent := RaycastHit.Entity.GetComponent[description_component]):
        "Entity = \"{Localize(DescriptionComponent.Name)}\", "
    else:
        ""
    "\{Distance = {RaycastHit.Distance}, {Entity}Normal = {RaycastHit.Normal}, Position = {RaycastHit.Position}, Transform = {RaycastHit.Transform}\}"