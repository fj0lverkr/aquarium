extends Node
signal on_tank_changed
signal on_feed_spawned
signal on_feed_picked(by: Fish)
signal on_fish_state_changed(fish: Fish, from_state: Fish.State, to_state: Fish.State)
signal on_object_clicked(o: Node2D)
signal on_mouse_over_object_changed(o: Node2D)
signal on_object_depth_changed(o: Node2D)
