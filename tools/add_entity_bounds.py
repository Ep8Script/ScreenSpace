"""
Add Entity Bounds for the ScreenSpace Verse library

This script calculates the AABB of selected actors or assets and applies that
data to a Verse component (`ScreenSpace.bounds_component`) on selected Scene Graph entities.

Usage:
Select one or more Scene Graph entities in the level, and either:
1. Select one or more props or static meshes in the level (if more than one, a hierarchy). The
   script will calculate the bounds of the meshes and apply those bounds to all selected entities.

2. Select exactly one Blueprint or Static Mesh asset in the Content Drawer. The script will measure
   bounds of this asset's meshes, and apply them to the selected entities.

3. Or, the script will isolate each entity's `mesh_component` if they have one, calculate its local
   bounds, and apply them to its `bounds_component`.

If the selected entities don't have a `bounds_component` already, one will be created.

"""

import re
import unreal


def get_actor_bounds(actors, root_transform):
    global_max = None
    global_min = None
    inverted_transform = root_transform.inverse()

    for actor in actors:
        for comp in actor.get_components_by_class(unreal.MeshComponent):
            if comp.is_editor_only:
                continue

            comp_transform = comp.get_world_transform()
            local_min, local_max = comp.get_local_bounds()

            # Get the corner positions of the local bounds
            corners = [
                unreal.Vector(local_min.x, local_min.y, local_min.z),
                unreal.Vector(local_max.x, local_min.y, local_min.z),
                unreal.Vector(local_min.x, local_max.y, local_min.z),
                unreal.Vector(local_max.x, local_max.y, local_min.z),
                unreal.Vector(local_min.x, local_min.y, local_max.z),
                unreal.Vector(local_max.x, local_min.y, local_max.z),
                unreal.Vector(local_min.x, local_max.y, local_max.z),
                unreal.Vector(local_max.x, local_max.y, local_max.z)
            ]

            for corner in corners:
                # Convert the corner position to world space
                world_position = comp_transform.transform_location(corner)

                # Convert the corner position to root space
                root_position = inverted_transform.transform_location(world_position)

                if global_min is None:
                    global_max = unreal.Vector(root_position.x, root_position.y, root_position.z)
                    global_min = unreal.Vector(root_position.x, root_position.y, root_position.z)
                else:
                    global_max.x = max(global_max.x, root_position.x)
                    global_max.y = max(global_max.y, root_position.y)
                    global_max.z = max(global_max.z, root_position.z)
                    global_min.x = min(global_min.x, root_position.x)
                    global_min.y = min(global_min.y, root_position.y)
                    global_min.z = min(global_min.z, root_position.z)

    if global_max is None:
        return None

    center = (global_max + global_min) * 0.5
    extents = (global_max - global_min) * 0.5
    return center, extents

def get_external_bounds(selected_actors):
    # Check selected actors
    if selected_actors:
        actor_set = set(selected_actors)
        roots = []

        for actor in selected_actors:
            has_selected_ancestor = False
            parent = actor.get_attach_parent_actor()

            while parent is not None:
                if parent in actor_set:
                    has_selected_ancestor = True
                    break
                parent = parent.get_attach_parent_actor()

            if not has_selected_ancestor:
                roots.append(actor)

        if len(roots) > 1:
            raise ValueError("Multiple root actors are selected.\nPlease only select only one root actor to be the bounds reference.")

        if roots:
            root = roots[0]

            # Get the bounds of the selected actors
            result = get_actor_bounds(selected_actors, root.get_actor_transform())
            if result is None:
                raise ValueError("No mesh components were found on the selected actor(s).")
            return result

    selected_assets = list(unreal.EditorUtilityLibrary.get_selected_assets())

    if len(selected_assets) > 1:
        raise ValueError("Multiple assets are selected in the Content Drawer.\nPlease select exactly one asset to measure bounds.")

    if len(selected_assets) == 1:
        actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        asset = selected_assets[0]

        actor = None
        try:
            # Spawn the selected asset
            actor = actor_subsystem.spawn_actor_from_object(asset, unreal.Vector(), unreal.Rotator())
            result = None

            # Get the bounds of the selected asset
            if actor is not None:
                result = get_actor_bounds([actor], unreal.Transform())
            if result is None:
                raise ValueError(f"Could not measure the bounds for '{asset.get_name()}'.\nMake sure the asset is a Blueprint or Static Mesh.")
            return result

        finally:
            if actor is not None:
                actor_subsystem.destroy_actor(actor)

    return None

def get_entity_bounds(entity_handle):
    scene_graph_subsystem = unreal.get_editor_subsystem(unreal.SceneGraphScriptSubsystem)

    mesh_comp_cls = scene_graph_subsystem.get_verse_component_class("Component.mesh_component")

    if mesh_comp_cls:
        # Check if the selected entity has a mesh_component
        if entity_handle.has_component_of_type(mesh_comp_cls):
            # Duplicate the entity without its children
            duplicate_handle = scene_graph_subsystem.duplicate_entity(entity_handle)
            duplicate_obj = duplicate_handle.get_object_reference()
            scene_graph_subsystem.set_entity_parent(duplicate_handle, None)
            for child in duplicate_handle.get_children():
                scene_graph_subsystem.destroy_entity(child)

            # Create a new transform component and add it
            transform_comp_cls = scene_graph_subsystem.get_verse_component_class("Entity.transform_component")
            transform_comp_obj = unreal.new_object(transform_comp_cls, duplicate_obj)
            transform_comp = unreal.ComponentScriptHandle()
            transform_comp.set_object_reference(transform_comp_obj)
            duplicate_handle.add_component(transform_comp)

            # Remove all components except for mesh_component and the new transform_component
            mesh_comp = duplicate_handle.get_component_by_type(mesh_comp_cls)
            for comp in duplicate_handle.get_components():
                if comp != mesh_comp and comp != transform_comp:
                    duplicate_handle.remove_component(comp)

            # Get the duplicate entity's local bounds and remove it
            bounds = scene_graph_subsystem.get_entity_bounds(duplicate_handle, False)
            scene_graph_subsystem.destroy_entity(duplicate_handle)
            return bounds.origin, bounds.box_extent

    raise ValueError("Could not determine bounds.")

def set_bounds(bounds, entity_handle, entity_obj):
    asset_registry = unreal.AssetRegistryHelpers.get_asset_registry()
    project_name = entity_obj.get_path_name().split('/')[1]
    scene_graph_subsystem = unreal.get_editor_subsystem(unreal.SceneGraphScriptSubsystem)

    # Find the bounds_component component class
    component_class = None
    component_path = bounds_component.replace(".", "-")
    project_assets = asset_registry.get_assets_by_path(f"/{project_name}", recursive=True)
    for asset_data in project_assets:
        if str(asset_data.asset_name).endswith(component_path):
            component_class = asset_data.get_asset()
            break

    if not component_class:
        raise ValueError(f"Couldn't find `{component_path}` in project '{project_name}'.\nMake sure Verse has been compiled.")

    # Add bounds_component to the entity if it doesn't already exist
    if not entity_handle.has_component_of_type(component_class):
        comp_obj = unreal.new_object(component_class, entity_obj)
        comp_handle = unreal.ComponentScriptHandle()
        comp_handle.set_object_reference(comp_obj)
        entity_handle.add_component(comp_handle)

    comp_handle = entity_handle.get_component_by_type(component_class)
    comp_obj = comp_handle.get_object_reference()

    # Get the real bounds_component.Bounds property name 
    bounds_prop = scene_graph_subsystem.get_real_property_name(comp_obj.get_class(), unreal.Name("Bounds"))
    if bounds_prop is None:
        raise RuntimeError("Couldn't resolve the property name for `bounds_component.Bounds`.")

    # Get the data from bounds_component.Bounds
    bounds_struct = comp_obj.get_editor_property(bounds_prop)
    text = bounds_struct.export_text()

    # Get the real property names for bounds.Center and bounds.Extents
    center_key = re.search(r'(__verse_\w+_Center)', text).group(1)
    extents_key = re.search(r'(__verse_\w+_Extents)', text).group(1)
    forward_key = re.search(r'(__verse_\w+_Forward)', text).group(1)
    left_key = re.search(r'(__verse_\w+_Left)', text).group(1)
    up_key = re.search(r'(__verse_\w+_Up)', text).group(1)

    # Save the data back into bounds_component.Bounds
    center, extents = bounds
    center_struct = bounds_struct.get_editor_property(center_key)
    center_struct.set_editor_property(forward_key, center.x)
    center_struct.set_editor_property(left_key, -center.y)
    center_struct.set_editor_property(up_key, center.z)
    extents_struct = bounds_struct.get_editor_property(extents_key)
    extents_struct.set_editor_property(forward_key, float(extents.x))
    extents_struct.set_editor_property(left_key, float(extents.y))
    extents_struct.set_editor_property(up_key, float(extents.z))

    bounds_struct.set_editor_property(center_key, center_struct)
    bounds_struct.set_editor_property(extents_key, extents_struct)
    comp_obj.set_editor_property(bounds_prop, bounds_struct)

bounds_component = "ScreenSpace.bounds_component"

def run():
    actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    scene_graph_subsystem = unreal.get_editor_subsystem(unreal.SceneGraphScriptSubsystem)

    selected_actors = []
    selected_entities = []

    # Get selected actors and check whether or not they're entities
    for actor in list(actor_subsystem.get_selected_level_actors()):
        if isinstance(actor, unreal.EntityProxyActor):
            entity_obj = scene_graph_subsystem.get_entity(actor)
            if entity_obj:
                entity_handle = unreal.EntityScriptHandle()
                entity_handle.set_object_reference(entity_obj)
                selected_entities.append((entity_handle, entity_obj))
        else:
            selected_actors.append(actor)

    # Get selected entities in case they were missed
    sg_selection, ok = scene_graph_subsystem.get_level_editor_selection()
    if ok and sg_selection:
        for entity_handle in sg_selection:
            entity_obj = entity_handle.get_object_reference()
            if all(e[1] != entity_obj for e in selected_entities):
                selected_entities.append((entity_handle, entity_obj))

    if not selected_entities:
        unreal.EditorDialog.show_message("Error | Add Entity Bounds", "No Scene Graph entities are selected.", unreal.AppMsgType.OK)
        return

    # Attempt to get the bounds of selected actors/assets
    try:
        external_bounds = get_external_bounds(selected_actors)
    except Exception as exc:
        unreal.EditorDialog.show_message("Error | Add Entity Bounds", str(exc), unreal.AppMsgType.OK)
        return

    errors = []
    successes = 0

    for entity_handle, entity_obj in selected_entities:
        entity_name = entity_obj.get_name()
        try:
            bounds = external_bounds if external_bounds is not None else get_entity_bounds(entity_handle)
            set_bounds(bounds, entity_handle, entity_obj)
            successes += 1
        except (ValueError, RuntimeError) as exc:
            errors.append(f"{entity_name}: {str(exc)}")
        except Exception as exc:
            errors.append(f"{entity_name}: {str(exc)}")

    if errors and successes == 0:
        unreal.EditorDialog.show_message("Failed | Add Entity Bounds", "\n\n".join(errors), unreal.AppMsgType.OK)
    elif errors and successes > 0:
        unreal.EditorDialog.show_message("Partial Success | Add Entity Bounds", f"Successfully set bounds_component on {successes} entity(s).\n\nErrors encountered:\n" + "\n".join(errors), unreal.AppMsgType.OK)
    else:
        message = f"Successfully set bounds_component on all {successes} selected entities!"
        if successes == 1:
            message = "Successfully set bounds_component on the selected entity!"
        unreal.EditorDialog.show_message("Success | Add Entity Bounds", message, unreal.AppMsgType.OK)

if __name__ == "__main__":
    run()