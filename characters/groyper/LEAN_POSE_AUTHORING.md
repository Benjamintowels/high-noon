# Lean pose authoring (standard Godot workflow)

Edit **`groyper_body.tscn` directly**. Do not edit poses inside `lean_pose_editor.tscn` — that scene only instances the body for runtime preview.

References:
- [Character animation (Godot docs)](https://docs.godotengine.org/en/stable/getting_started/first_3d_game/09.adding_animations.html)
- [Introduction to animation features](https://docs.godotengine.org/en/stable/tutorials/animation/introduction.html)
- [Using AnimationTree](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html)

## Scene layout

```
Body                          ← AnimationPlayer root (root_node = "..")
├── Armature
│   └── Skeleton3D            ← select this to pose bones
│       ├── char1             (mesh — do not select for bone keys)
│       ├── HipHolsterMount
│       └── HandRevolverMount
└── AnimationPlayer           ← select first, pick animation
```

`AnimationPlayer.root_node` must be **`..`** (the Body node). If it is `.`, bone track paths like `Armature/Skeleton3D:Hips` cannot resolve and keys appear to do nothing.

## Step-by-step: keyframe a bone rotation

1. Open **`characters/groyper/groyper_body.tscn`**.
2. Select **`AnimationPlayer`** in the Scene tree.
3. In the **Animation** panel (bottom), open the animation dropdown and choose **`lean_poses/center`** (or another pose name).
4. Scrub the timeline to **0.0** (these are single-frame pose clips).
5. Select **`Armature/Skeleton3D`** (not the mesh child).
6. In the **Inspector**, expand the bone list and click a bone (e.g. `Hips`), **or** use skeleton edit mode in the 3D viewport:
   - Viewport toolbar → skeleton icon → **Select** a bone, then switch to **Rotate**.
7. Rotate the bone in the viewport.
8. Insert the keyframe using **one** of:
   - The **Key Transform** button next to that bone in the Skeleton3D Inspector (Godot 4 — preferred for bones), or
   - The 3D viewport toolbar: enable **rot**, then click the **key** icon.
9. Press **Play from beginning** (Shift+D) — the pose should hold at your keyed rotation.
10. **Save the scene** (Ctrl+S). Keys are stored in `lean_poses.tres` via the library reference on AnimationPlayer.

Repeat for each direction pose (`forward`, `back`, `left`, `right`, diagonals). Start from **`center`** as your neutral reference.

## Bones to key

See `lean_pose_config.gd` — hips, spine chain, shoulders, upper/lower legs. Arms are excluded (aim IK owns them).

## RESET animation

The idle FBX import has **`animation/import_rest_as_RESET=true`**. After changing import settings, select the FBX in the FileSystem dock and click **Reimport**. RESET gives AnimationTree a proper rest pose for blending.

## Preview only

Run **`lean_pose_editor.tscn`** (F6) to preview BlendSpace2D blending. Author poses in **`groyper_body.tscn`**, not here.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "Track path is invalid, so can't add a key" | Set AnimationPlayer **Root Node** to `..` (Body). |
| Key inserts but pose does not change on play | Wrong animation selected, or timeline not at 0. |
| No `lean_poses` in dropdown | Reopen scene; ensure `lean_poses.tres` exists and has no UTF-8 BOM. |
| Editing does nothing | You opened `lean_pose_editor` or a nested instance — open `groyper_body.tscn` instead. |
| Bones not visible in viewport | Select Skeleton3D → skeleton edit mode → Select tool first (Godot 4.6 quirk). |
