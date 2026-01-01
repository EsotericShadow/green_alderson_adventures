#!/usr/bin/env python3
"""Regenerate PotionRecipeData resources from the alchemy recipe table."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional

ROOT = Path(__file__).resolve().parent
DATA_PATH = ROOT / "data" / "alchemy_recipe_table.json"
RECIPES_DIR = ROOT / "resources" / "recipes"
SCRIPT_RESOURCE_PATH = "res://scripts/data/potion_recipe_data.gd"

RESOURCE_FOLDERS = [
    (ROOT / "resources" / "potions", "res://resources/potions/"),
    (ROOT / "resources" / "items", "res://resources/items/"),
]

ITEMS_PREFIX = "res://resources/items/"


@dataclass
class IngredientEntry:
    path: str
    count: int
    role: str


class ExtResourceRegistry:
    """Tracks unique ExtResource entries for a recipe."""

    def __init__(self) -> None:
        self._id_map: Dict[str, int] = {}
        self._entries: List[tuple[int, str, str]] = []

    def register(self, res_type: str, path: str) -> int:
        if path not in self._id_map:
            next_id = len(self._entries) + 1
            self._id_map[path] = next_id
            self._entries.append((next_id, res_type, path))
        return self._id_map[path]

    @property
    def entries(self) -> List[tuple[int, str, str]]:
        return sorted(self._entries, key=lambda entry: entry[0])


def load_recipe_table() -> List[dict]:
    if not DATA_PATH.exists():
        raise SystemExit(f"Recipe table not found: {DATA_PATH}")
    data = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    recipes = data.get("recipes")
    if not isinstance(recipes, list):
        raise SystemExit("Invalid recipe table format: 'recipes' must be a list")
    return recipes


def resolve_resource_path(resource_id: str) -> str:
    """Returns a res:// path for the given resource id."""
    for folder_path, res_prefix in RESOURCE_FOLDERS:
        candidate = folder_path / f"{resource_id}.tres"
        if candidate.exists():
            return f"{res_prefix}{resource_id}.tres"
    raise SystemExit(f"Resource '{resource_id}' not found in supported folders")


def _ensure_item_resource(path: str, recipe_id: str, role: str) -> None:
    if not path.startswith(ITEMS_PREFIX):
        raise SystemExit(
            f"Invalid ingredient '{role}' in {recipe_id}: {path} (must be an ItemData resource)"
        )


def build_ingredients(entry: dict) -> List[IngredientEntry]:
    ingredients: List[IngredientEntry] = []

    def append_role(role: str, payload: Optional[dict], default_count: int = 1) -> None:
        if not payload:
            return
        count = payload.get("count", default_count)
        resource_id = payload.get("id")
        if not resource_id:
            raise SystemExit(f"Missing resource id for {role} in {entry['recipe_id']}")
        path = resolve_resource_path(resource_id)
        _ensure_item_resource(path, entry["recipe_id"], role)
        ingredients.append(IngredientEntry(path=path, count=count, role=role))

    append_role("base", entry.get("base_liquid"))
    append_role("primary", entry.get("primary_ingredient"))
    append_role("secondary", entry.get("secondary_ingredient"))
    append_role("catalyst", entry.get("catalyst"))

    for item in entry.get("additional_ingredients", []):
        append_role(item.get("role", "additional"), item, default_count=item.get("count", 1))

    if not ingredients:
        raise SystemExit(f"Recipe '{entry['recipe_id']}' has no ingredients defined")
    return ingredients


def build_recipe_text(entry: dict) -> str:
    ingredients = build_ingredients(entry)
    registry = ExtResourceRegistry()

    script_ext_id = registry.register("Script", SCRIPT_RESOURCE_PATH)

    result_path = resolve_resource_path(entry["result"])
    result_ext_id = registry.register("Resource", result_path)

    ingredient_ext_ids: List[int] = []
    ingredient_counts: List[int] = []

    base_ext_id: Optional[int] = None
    primary_ext_id: Optional[int] = None
    secondary_ext_id: Optional[int] = None
    catalyst_ext_id: Optional[int] = None

    for ingredient in ingredients:
        ext_id = registry.register("Resource", ingredient.path)
        ingredient_ext_ids.append(ext_id)
        ingredient_counts.append(int(ingredient.count))

        if ingredient.role == "base":
            base_ext_id = ext_id
        elif ingredient.role == "primary":
            primary_ext_id = ext_id
        elif ingredient.role == "secondary":
            secondary_ext_id = ext_id
        elif ingredient.role == "catalyst":
            catalyst_ext_id = ext_id

    load_steps = len(registry.entries) + 1

    lines: List[str] = []
    lines.append(
        f"[gd_resource type=\"Resource\" script_class=\"PotionRecipeData\" load_steps={load_steps} format=3]"
    )
    lines.append("")

    for res_id, res_type, path in registry.entries:
        lines.append(f"[ext_resource type=\"{res_type}\" path=\"{path}\" id=\"{res_id}\"]")
    lines.append("")

    lines.append("[resource]")
    lines.append(f"script = ExtResource(\"{script_ext_id}\")")
    lines.append(f"id = \"{entry['recipe_id']}\"")
    lines.append(f"display_name = \"{entry['display_name']}\"")
    lines.append(f"result = ExtResource(\"{result_ext_id}\")")
    lines.append(f"result_count = {entry['result_count']}")

    ingredient_refs = ", ".join(f"ExtResource(\"{ext_id}\")" for ext_id in ingredient_ext_ids)
    lines.append(f"ingredients = [{ingredient_refs}]")
    lines.append(f"ingredient_counts = {ingredient_counts}")

    lines.append(f"tier = {entry['tier']}")
    lines.append(f"required_alchemy_level = {entry['required_alchemy_level']}")
    lines.append(f"base_potency = {entry['base_potency']}")
    lines.append(f"potency_per_level = {entry['potency_per_level']}")
    lines.append(f"xp_reward = {entry['xp_reward']}")

    def resource_or_null(ext_id: Optional[int]) -> str:
        return "null" if ext_id is None else f"ExtResource(\"{ext_id}\")"

    lines.append(f"base_liquid = {resource_or_null(base_ext_id)}")
    lines.append(f"primary_ingredient = {resource_or_null(primary_ext_id)}")
    lines.append(f"secondary_ingredient = {resource_or_null(secondary_ext_id)}")
    lines.append(f"catalyst = {resource_or_null(catalyst_ext_id)}")

    return "\n".join(lines) + "\n"


def write_recipe(entry: dict) -> None:
    recipes_dir = RECIPES_DIR
    recipes_dir.mkdir(parents=True, exist_ok=True)
    target_path = recipes_dir / f"{entry['recipe_id']}.tres"
    target_path.write_text(build_recipe_text(entry), encoding="utf-8")
    print(f"✓ Wrote {target_path.relative_to(ROOT)}")


def main() -> None:
    recipes = load_recipe_table()
    for entry in recipes:
        required_keys = [
            "recipe_id",
            "result",
            "display_name",
            "tier",
            "required_alchemy_level",
            "xp_reward",
            "result_count",
            "base_potency",
            "potency_per_level",
            "base_liquid",
            "primary_ingredient",
            "catalyst",
        ]
        for key in required_keys:
            if key not in entry:
                raise SystemExit(f"Recipe entry missing '{key}': {entry}")
        write_recipe(entry)


if __name__ == "__main__":
    main()
