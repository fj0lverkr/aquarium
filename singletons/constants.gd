extends Node

# GROUP NAMES
const GRP_FEED: String = "feed"
const GRP_SAND: String = "sand"
const GRP_FISH: String = "fish"

# INPUT ACTION NAMES
const IA_LMB: String = "LeftClick"

# PHYSICS LAYERS
const PL_DEPTH_LAYER: Dictionary = {
    1: 28,
    2: 29,
    3: 30,
    4: 31,
    5: 32,
}

# COLORS
const COL_DEPTH_MOD: Dictionary = {
    1: Color8(255, 255, 255),
    2: Color8(195, 195, 195),
    3: Color8(140, 140, 140),
    4: Color8(100, 100, 100),
    5: Color8(75, 75, 75)
}

# MATERIALS
const MAT_SPRITE_BASE: Material = preload("res://scenes/effects/sprite_base_material.tres")
const MAT_SPRITE_OUTLINE: Material = preload("res://scenes/effects/sprite_outline_material.tres")