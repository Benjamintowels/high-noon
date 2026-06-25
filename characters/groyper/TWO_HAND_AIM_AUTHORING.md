# Two-hand aim (same IK as one-handed)

Two-handed weapons use the **same arm IK** as the revolver. The only difference is the **neutral rest pose** read from `TwoHandAim/neutral` on disk.

## How it works

1. At startup, bone rotations are loaded from `TwoHandAim/neutral` into memory.
2. **Draw (raise)** tweens both arms from the holster reach into that neutral pose (not straight-arm IK — that caused arms-over-head).
3. **Aim** sets each chain to the neutral pose, then IK twists:
   - **Right arm** → white reticle (gun hand / forearm mount)
   - **Left arm** → `SupportHand` marker on the weapon grip

One-handed weapons still use identity (straight) as the IK rest pose.

## Authoring `TwoHandAim/neutral`

Open `groyper_body.tscn` → AnimationPlayer → `TwoHandAim/neutral` → pose at time 0:

- `LeftShoulder`, `LeftArm`, `LeftForeArm`, `LeftHand`
- `RightShoulder`, `RightArm`, `RightForeArm`, `RightHand`

Use **TwoHandPoseCapture → Capture Neutral Pose** (do not use Insert Key All Bones).

Tune grip placement per weapon on each `*_grip.tscn` (`hand_grip_*` on player, or **G** while drawn).

## Holstered countdown

Left arm uses `holstered_left_arm_rotation_deg` on GroyperPlayer (default `45, 0, 0` — same as right).
