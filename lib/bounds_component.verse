using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Colors }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

# Stores the bounds for an entity.
bounds_component<public> := class<final><final_super>(component):
    @editable{ToolTip := BoundsTooltip}
    # The object space bounds of the entity.
    var Bounds<public> : bounds = bounds{}

    @editable{ToolTip := CacheTooltip}
    # If true, the default bounds will be ignored and the encapsulation of the bounds of the entity's immediate children will be cached.
    # If none of the entity's descendants have a `bounds_component`, the bounds will not be changed and it will attempt again next time it begins simulating.
    var<private> Cache<public> : logic = false

    @editable{ToolTip := DebugDrawTooltip}
    # Whether the bounds should automatically be debug drawn.
    # NOTE: This will not be cleared with `ClearBoundsDebugDraw()`
    (bounds_component:)DebugDraw<public> : logic = false

    var Draw<private> : ?debug_draw = false

    # Returns the global bounds of the entity.
    GetGlobalBounds<public>()<transacts>:bounds=
        GlobalTransform:transform = Entity.GetGlobalTransform()
        MakeBounds(Bounds, GlobalTransform)

    # Returns the local bounds of the entity.
    GetLocalBounds<public>()<transacts>:bounds=
        LocalTransform:transform = Entity.GetLocalTransform()
        MakeBounds(Bounds, LocalTransform)

    # Returns the globally oriented bounds of the entity.
    GetOrientedBounds<public>()<transacts>:oriented_bounds=
        GlobalTransform:transform = Entity.GetGlobalTransform()
        MakeOrientedBounds(Bounds, GlobalTransform)

    # Succeeds if the entity's global bounds intersect the given frustum planes.
    IsInFrustum<public>(Planes:[]plane)<decides><transacts>:void=
        GlobalBounds:bounds = GetGlobalBounds()
        GlobalBounds.IsInFrustum[Planes]

    OnBeginSimulation<override>():void=
        if (Cache?):
            for (Child : Entity.GetEntities(), ChildBounds := Child.GetBoundsLocal[]):
                if (Cache?):
                    set Bounds = ChildBounds
                    set Cache = false
                else:
                    set Bounds = Bounds.Encapsulate(ChildBounds)
        if (not Draw? and Self.DebugDraw? and GetSession().Environment() = session_environment.Edit):
            set Draw = option{debug_draw{Channel := debug_bounds_component_channel}}

    OnSimulate<override>()<suspends>:void=
        if (ValidDraw := Draw?):
            loop:
                GlobalBounds:bounds = GetGlobalBounds()
                OrientedBounds:oriented_bounds = GetOrientedBounds()
                ValidDraw.DrawBox(GlobalBounds.Center, IdentityRotation(), ?DrawDurationPolicy := debug_draw_duration_policy.Persistent, ?Extent := GlobalBounds.Extents)
                ValidDraw.DrawBox(OrientedBounds.Center, OrientedBounds.Orientation, ?Color := NamedColors.Red, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent, ?Extent := OrientedBounds.Extents)
                TickEvents.PostPhysics.Await()
                ValidDraw.Clear()

    OnEndSimulation<override>():void=
        if (ValidDraw := Draw?):
            ValidDraw.Clear()

debug_bounds_component_channel<internal> := class(debug_draw_channel):

# Caches the encapsulated bounds of this entity's immediate children.
# Returns false if the entity already has bounds or if none of its descendants have a `bounds_component`.
(Entity:entity).CacheBounds<public>():logic=
    if (Entity.GetComponent[bounds_component]):
        false
    else if (Bounds := Entity.GetBounds[]):
        Entity.SetBounds(Bounds)
        true
    else:
        false

# Returns the object space bounds of this entity.
# If this entity doesn't have a `bounds_component`, this returns an encapsulation of the bounds of its immediate children.
# Fails if none of the entity's descendants have a `bounds_component`.
(Entity:entity).GetBounds<public>()<decides><transacts>:bounds=
    if (BoundsComponent := Entity.GetComponent[bounds_component]):
        BoundsComponent.Bounds
    else:
        var MaybeBounds:?bounds = false
        for (Child : Entity.GetEntities(), ChildBounds := Child.GetBoundsLocal[]):
            set MaybeBounds = option{MaybeBounds?.Encapsulate(ChildBounds) or ChildBounds}
        MaybeBounds?

# Returns the global bounds of this entity.
# If this entity doesn't have a `bounds_component`, this returns an encapsulation of the global bounds of its immediate children.
# Fails if none of the entity's descendants have a `bounds_component`.
# NOTE: This should be named GetGlobalBounds, but it clashes with an <epic_internal> method.
(Entity:entity).GetBoundsGlobal<public>()<decides><transacts>:bounds=
    if (BoundsComponent := Entity.GetComponent[bounds_component]):
        BoundsComponent.GetGlobalBounds()
    else:
        Bounds:bounds = Entity.GetBounds[]
        Transform:transform = Entity.GetGlobalTransform()
        MakeBounds(Bounds, Transform)

# Returns the local bounds of this entity.
# If this entity doesn't have a `bounds_component`, this returns an encapsulation of the local bounds of its immediate children.
# Fails if none of the entity's descendants have a `bounds_component`.
# NOTE: This should be named GetLocalBounds, but it clashes with an <epic_internal> method.
(Entity:entity).GetBoundsLocal<public>()<decides><transacts>:bounds=
    if (BoundsComponent := Entity.GetComponent[bounds_component]):
        BoundsComponent.GetLocalBounds()
    else:
        Bounds:bounds = Entity.GetBounds[]
        Transform:transform = Entity.GetLocalTransform()
        MakeBounds(Bounds, Transform)

# Returns the globally oriented bounds of this entity.
# If this entity doesn't have a `bounds_component`, this returns an encapsulation of the globally oriented bounds of its immediate children.
# Fails if none of the entity's descendants have a `bounds_component`.
(Entity:entity).GetOrientedBounds<public>()<decides><transacts>:oriented_bounds=
    if (BoundsComponent := Entity.GetComponent[bounds_component]):
        BoundsComponent.GetOrientedBounds()
    else:
        Bounds:bounds = Entity.GetBounds[]
        Transform:transform = Entity.GetGlobalTransform()
        MakeOrientedBounds(Bounds, Transform)

# Reset the bounds of this entity, which will now default to the encapsulation of the bounds of its immediate children.
(Entity:entity).ResetBounds<public>(Bounds:bounds):void=
    if (BoundsComponent := Entity.GetComponent[bounds_component]):
        BoundsComponent.RemoveFromEntity()

# Sets the object space bounds for this entity.
# If this entity doesn't have a `bounds_component`, it will create one and set its bounds.
(Entity:entity).SetBounds<public>(Bounds:bounds):void=
    if (BoundsComponent := Entity.GetComponent[bounds_component]):
        set BoundsComponent.Bounds = Bounds
    else:
        BoundsComponent:bounds_component = bounds_component{Bounds := Bounds, Entity := Entity}
        Entity.AddComponents(array{BoundsComponent})

# Sets the object space bounds for this entity.
# If this entity doesn't have a `bounds_component`, it will create one and set its bounds.
(Entity:entity).SetBounds<public>(Center:vector3, Size:vector3):void=
    Bounds:bounds = MakeBounds(Center, Size)
    Entity.SetBounds(Bounds)