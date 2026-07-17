# Two-hand aim (same IK as one-handed)

Two-handed firearms use the **same arm IK** as one-handed guns, with authored
rests for hip and ADS plus a per-weapon `SupportHand` marker for the left arm.

## How it works

1. At startup, bone rotations are loaded from `TwoHandAim/neutral` (hip) and
   `TwoHandAim/ads` (raised stock) — full upper-body chain (arms, shoulders,
    spine, head).
2. Runtime slerps those rests by the ADS blend (0 = hip, 1 = ADS).
3. Authored torso keys replace the procedural blade stance when present.
4. `Spine02` pitches with look elevation (bend forward to aim down, back to aim
   up). Left/right stays body yaw — arms keep the authored hold.
5. No arm aim-correct / SupportHand IK — the left hand stays on the authored
   foregrip pose for every two-handed firearm. Seat the gun with `GripOffset`.

One-handed weapons stamp `HipFireAim/neutral` → `HipFireAim/ads` (rotation +
position) on Spine → RightShoulder → RightArm → RightForeArm → RightHand as the
straight-ahead reference, plus baked RightArm euler offsets. RightArm
aim-corrects onto the reticle (hip walk uses the same arm lock as ADS walk).
ADS-only Spine keys lock in while walking at hip for torso stability. Capture
with HipFirePoseCapture.

Overworld: `groyper_weapon_rig.gd`. Duel: `groyper_player.gd` (neutral + SupportHand;
duel always aims when drawn and does not yet blend the ADS clip).

## Authoring poses (two-hand)

Open `groyper_body.tscn` → AnimationPlayer → pose at time 0:

- `LeftShoulder`, `LeftArm`, `LeftForeArm`, `LeftHand`
- `RightShoulder`, `RightArm`, `RightForeArm`, `RightHand`
- Optional torso: `Spine`, `Spine01`, `Spine02`, `Head` (recommended for a
  matching in-game hold — without these, code applies a procedural yaw twist)

Capture with **TwoHandPoseCapture** on Body (do not use Insert Key All Bones):

- **Capture Neutral Pose** → hip-fire hold (`TwoHandAim/neutral`)
- **Capture Ads Pose** → cheek-weld / raised stock (`TwoHandAim/ads`)

Key rotation tracks on the bones above only. Position keys are ignored at
runtime and make rotation-only rests look like arms-over-head.

## Authoring poses (one-hand)

Open `groyper_body.tscn` → AnimationPlayer → `HipFireAim/neutral` or
`HipFireAim/ads` at time 0. Pose the locked chain:

- `Spine`, `Spine01`, `Spine02` (optional — ADS torso lean)
- `RightShoulder` (recommended — otherwise idle/walk AnimTree parents the arm)
- `RightArm`, `RightForeArm`, `RightHand`

Clips are standalone Animations (`hip_fire_aim_neutral.tres` /
`hip_fire_aim_ads.tres`) referenced by the `HipFireAim` library — edit them in
AnimationPlayer like punch poses, or capture with **HipFirePoseCapture** on Body:

- **Capture Neutral Pose** → bent-elbow hip hold (`HipFireAim/neutral`)
- **Capture Ads Pose** → ADS hold (`HipFireAim/ads`)

`HandRevolverMount` defaults to previewing the ADS pose; switch **Preview Pose**
in the Inspector to load neutral vs ADS before capturing.

Runtime stamps those rests (including position keys), then pitches forearm/arm
for look up/down. Optional bones keyed only on ADS fade in with the ADS blend.

Tune in-hand placement on the child **`GripOffset`**, not the `*HandMount`
BoneAttachment root — the skeleton overwrites the attachment transform every
frame, so root moves look like they stick then revert on save.

### WYSIWYG mount editing (1:1 with in-game)

Hierarchy (same as melee two-hand mounts):

`*HandMount` (BoneAttachment / RightHand)
→ `GripOffset` ← **only node you tune**
→ `PoseOffset` (identity — runtime attach point)
→ grip at identity

Firearm `*_grip.tscn` roots are identity. Mesh seating/scale stays on the mesh
child. Do **not** leave `GripOffset` overrides in `groyper_body.tscn` that fight
the packed `*_hand_mount.tscn` — edit either the mount scene or editable
children, then keep them in sync (packed scene is source of truth).

1. Make e.g. `Ak47HandMount` **visible** in `groyper_body` — the mount script
   auto-applies `TwoHandAim/neutral` so arms match the hip hold.
2. Edit only **`GripOffset`** — never the BoneAttachment root (skeleton owns it;
   saved root transforms are just the bone pose at last save).
3. Save the mount scene / body. Runtime parents the live grip under `PoseOffset`
   at identity — same seat you see in the editor.

In `groyper_body.tscn`: expand e.g. `ShotgunHandMount` → select `GripOffset` →
nudge transform (instances have Editable Children on). Or open
`shotgun_hand_mount.tscn` and edit `GripOffset` there. Same for Mac10/AK/RPG/AWP
and `HandRevolverMount/GripOffset`. Mesh seat / muzzle still live on each
`*_grip.tscn`. Place `SupportHand` on the foregrip so the left palm lands after
IK.

## Holstered countdown

Left arm uses `holstered_left_arm_rotation_deg` on GroyperPlayer (default
`45, 0, 0` — same as right).
