extends Node

func get_swimmable_dimensions(s: float) -> Vector2:
    # currently we return the viewport size, but in the future this must get the active tank from the game manager
    # and use its dimensions and those of the fish to calculate the swimmable space within the tank
    # future tanks will be bigger than our viewport.
    var base_tank_size: Vector2 = get_viewport().get_visible_rect().size
    return Vector2(base_tank_size.x - s, base_tank_size.y - s)