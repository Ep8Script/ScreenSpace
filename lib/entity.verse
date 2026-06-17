using { /Verse.org/SceneGraph }
using { /Verse.org/SpatialMath }

# Returns the closest point on the entity's bounding box or inside the entity's bounding box.
# If `Point` is inside the bounding box, it will be returned unmodified.
# Fails if `Entity` does not have a bounding box.
(Entity:entity).ClosestPointOnBounds<public>(Point:vector3)<decides><transacts>:vector3=
    GlobalBounds:bounds = Entity.GetBoundsGlobal[]
    GlobalBounds.ClosestPoint(Point)

# Succeeds if the entity's bounding box intersects the given frustum planes.
# If this entity doesn't have a bounds_component, its children are checked instead.
(Entity:entity).IsInFrustum<public>(Planes:[]plane)<decides><transacts>:void=
    Entity.GetSimulationEntity[]
    GlobalBounds:bounds = Entity.GetBoundsGlobal[]
    GlobalBounds.IsInFrustum[Planes]
    if (BoundsComponent := Entity.GetComponent[bounds_component]):
        OrientedBounds:oriented_bounds = BoundsComponent.GetOrientedBounds()
        OrientedBounds.IsInFrustum[Planes]
    else:
        first:
            Child : Entity.GetEntities()
            Child.IsInFrustum[Planes]

# Casts a line from `Start` to `End` against all bounding boxes in the entity's descendants, starting with `Entity`.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the line between `Start` and `End`.
# NOTE: Linecasts will not detect any `bounds` that contain `Start`.
(Entity:entity).Linecast<public>(Start:vector3, End:vector3)<decides><transacts>:raycast_hit=
    not IsAlmostEqual[Start, End, 0.0]
    Difference:vector3 = End - Start
    MaxDistance:float = Difference.Length()
    Entity.Raycast[Start, Difference / MaxDistance, MaxDistance]

# Casts a ray from `Origin` towards `Direction` against all bounding boxes in the entity's descendants, starting with `Entity`.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the ray.
# NOTE: Raycasts will not detect any `bounds` that contain `Origin`.
(Entity:entity).Raycast<public>(Origin:vector3, Direction:vector3)<decides><transacts>:raycast_hit=
    Entity.Raycast[Origin, Direction, Inf]

# Casts a ray from `Origin` towards `Direction` with `MaxDistance` against all bounding boxes in the entity's descendants, starting with `Entity`.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the ray.
# NOTE: Raycasts will not detect any `bounds` that contain `Origin`.
(Entity:entity).Raycast<public>(Origin:vector3, Direction:vector3, MaxDistance:float)<decides><transacts>:raycast_hit=
    Ray:ray = MakeRay(Origin, Direction)
    Entity.Raycast[Ray, MaxDistance]

# Casts `Ray` against all bounding boxes in the entity's descendants, starting with `Entity`.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the ray.
# NOTE: Raycasts will not detect any `bounds` that contain `Ray.Origin`.
(Entity:entity).Raycast<public>(Ray:ray)<decides><transacts>:raycast_hit=
    Entity.Raycast[Ray, Inf]

# Casts `Ray` with `MaxDistance` against all bounding boxes in the entity's descendants, starting with `Entity`.
# Returns information about where an entity's bounding box was hit.
# Fails if there is no entity found with a bounding box intersecting the ray.
# NOTE: Raycasts will not detect any `bounds` that contain `Ray.Origin`.
(Entity:entity).Raycast<public>(Ray:ray, MaxDistance:float)<decides><transacts>:raycast_hit=
    Entity.GetSimulationEntity[]
    GlobalBounds:bounds = Entity.GetBoundsGlobal[]
    HasComponent:logic = logic{Entity.GetComponent[bounds_component]}
    if (HasComponent?):
        not GlobalBounds.Contains[Ray.Origin]
    if (HasComponent? or not GlobalBounds.Contains[Ray.Origin]):
        Dist:float = GlobalBounds.IntersectRay[Ray]
        Dist >= 0.0
        Dist <= MaxDistance
    Bounds:bounds = Entity.GetBounds[]
    GlobalTransform:transform = Entity.GetGlobalTransform()
    InvertedTransform:transform = -GlobalTransform
    TransformedRay:ray = ray:
        Direction := Ray.Direction * InvertedTransform.Rotation * InvertedTransform.Scale
        Origin := Ray.Origin * InvertedTransform
    if (HasComponent?):
        not Bounds.Contains[TransformedRay.Origin]
    HitDistance:float = if (not HasComponent? and Bounds.Contains[TransformedRay.Origin]):
        0.0
    else:
        Bounds.IntersectRay[TransformedRay]
    HitDistance >= 0.0
    HitDistance <= MaxDistance
    if (HasComponent?):
        var HitNormal:vector3 = vector3{}
        HitPosition:vector3 = TransformedRay.GetPoint(HitDistance)
        LocalHitPosition:vector3 = HitPosition - Bounds.Center
        var MinDistance:float = Inf
        PositionChecks:vector3 = Bounds.Extents - Abs(LocalHitPosition)
        if (PositionChecks.Left < MinDistance):
            set HitNormal = vector3{Left := Sgn(LocalHitPosition.Left)}
            set MinDistance = PositionChecks.Left
        if (PositionChecks.Up < MinDistance):
            set HitNormal = vector3{Up := Sgn(LocalHitPosition.Up)}
            set MinDistance = PositionChecks.Up
        if (PositionChecks.Forward < MinDistance):
            set HitNormal = vector3{Forward := Sgn(LocalHitPosition.Forward)}
            set MinDistance = PositionChecks.Forward
        raycast_hit:
            Distance := HitDistance
            Entity := Entity
            Normal := HitNormal * InvertedTransform.Rotation
            Position := Ray.GetPoint(HitDistance)
            Transform := InvertedTransform
    else:
        var ClosestHit:?raycast_hit = false
        for (Child : Entity.GetEntities(), Hit := Child.Raycast[TransformedRay, ClosestHit?.Distance or MaxDistance]):
            set ClosestHit = option{Hit}
        ClosestHit?

# Casts a ray from `Origin` towards `Direction` against all bounding boxes in the scene.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain `Origin`.
# NOTE: The order of the results is unspecified.
# NOTE: This entity defines the context for the raycast but does not otherwise take part.
(Entity:entity).RaycastAll<public>(Origin:vector3, Direction:vector3)<transacts>:[]raycast_hit=
    Entity.RaycastAll(Origin, Direction, Inf)

# Casts a ray from `Origin` towards `Direction` with `MaxDistance` against all bounding boxes in the scene.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain `Origin`.
# NOTE: The order of the results is unspecified.
# NOTE: This entity defines the context for the raycast but does not otherwise take part.
(Entity:entity).RaycastAll<public>(Origin:vector3, Direction:vector3, MaxDistance:float)<transacts>:[]raycast_hit=
    Ray:ray = MakeRay(Origin, Direction)
    Entity.RaycastAll(Ray, MaxDistance)

# Casts `Ray` against all bounding boxes in the scene.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain `Ray.Origin`.
# NOTE: The order of the results is unspecified.
# NOTE: This entity defines the context for the raycast but does not otherwise take part.
(Entity:entity).RaycastAll<public>(Ray:ray)<transacts>:[]raycast_hit=
    Entity.RaycastAll(Ray, Inf)

# Casts `Ray` with `MaxDistance` against all bounding boxes in the scene.
# Returns information about where the bounding boxes were hit.
# NOTE: Raycasts will not detect any `bounds` that contain `Ray.Origin`.
# NOTE: The order of the results is unspecified.
# NOTE: This entity defines the context for the raycast but does not otherwise take part.
(Entity:entity).RaycastAll<public>(Ray:ray, MaxDistance:float)<transacts>:[]raycast_hit=
    if (SimulationEntity := Entity.GetSimulationEntity[]):
        RaycastAllInternal(SimulationEntity, Ray, MaxDistance)
    else:
        ()

RaycastAllInternal<internal>(Entity:entity, Ray:ray, MaxDistance:float)<transacts>:[]raycast_hit=
    if:
        GlobalBounds:bounds = Entity.GetBoundsGlobal[]
        HasComponent:logic = logic{Entity.GetComponent[bounds_component]}
        if (HasComponent?):
            not GlobalBounds.Contains[Ray.Origin]
        if (HasComponent? or not GlobalBounds.Contains[Ray.Origin]):
            Dist:float = GlobalBounds.IntersectRay[Ray]
            Dist >= 0.0
            Dist <= MaxDistance
        Bounds := Entity.GetBounds[]
        GlobalTransform := Entity.GetGlobalTransform()
        InvertedTransform := -GlobalTransform
        TransformedRay := ray:
            Direction := Ray.Direction * InvertedTransform.Rotation * InvertedTransform.Scale
            Origin := Ray.Origin * InvertedTransform
        if (HasComponent?):
            not Bounds.Contains[TransformedRay.Origin]
        HitDistance := if (not HasComponent? and Bounds.Contains[TransformedRay.Origin]):
            0.0
        else:
            Bounds.IntersectRay[TransformedRay]
        HitDistance >= 0.0
        HitDistance <= MaxDistance
    then:
        if (HasComponent?):
            var HitNormal:vector3 = vector3{}
            HitPosition:vector3 = TransformedRay.GetPoint(HitDistance)
            LocalHitPosition:vector3 = HitPosition - Bounds.Center
            var MinDistance:float = Inf
            PositionChecks:vector3 = Bounds.Extents - Abs(LocalHitPosition)
            if (PositionChecks.Left < MinDistance):
                set HitNormal = vector3{Left := Sgn(LocalHitPosition.Left)}
                set MinDistance = PositionChecks.Left
            if (PositionChecks.Up < MinDistance):
                set HitNormal = vector3{Up := Sgn(LocalHitPosition.Up)}
                set MinDistance = PositionChecks.Up
            if (PositionChecks.Forward < MinDistance):
                set HitNormal = vector3{Forward := Sgn(LocalHitPosition.Forward)}
                set MinDistance = PositionChecks.Forward
            array:
                raycast_hit:
                    Distance := HitDistance
                    Entity := Entity
                    Normal := HitNormal * GlobalTransform.Rotation
                    Position := Ray.GetPoint(HitDistance)
                    Transform := GlobalTransform
        else:
            var Hits:[]raycast_hit = ()
            for (Child : Entity.GetEntities()):
                set Hits += RaycastAllInternal(Child, Ray, MaxDistance)
            Hits
    else:
        ()