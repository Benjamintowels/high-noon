$objectsDir = Join-Path $PSScriptRoot "..\Assets\World\WoodObjects\Scenes\objects"
$scriptPath = "res://Assets/World/WoodObjects/wood_single_prop.gd"
$gltfPath = "res://Assets/World/WoodObjects/Gltf/WoodenObjects.gltf"
$gltfUid = "uid://c38nq054y6jng"

Get-ChildItem -Path $objectsDir -Filter "*.tscn" | ForEach-Object {
    $file = $_.FullName
    $text = Get-Content -Raw -Path $file

    if ($text -notmatch '\[node name="WoodenObjects"') {
        Write-Warning "Skipping $($_.Name): no WoodenObjects node"
        return
    }

    $propName = $_.BaseName
    $uidLine = ""
    if ($text -match 'uid="(uid://[^"]+)"') {
        $uidLine = " uid=`"$($Matches[1])`""
    }

    $transform = "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)"
    $pattern = '\[node name="' + [regex]::Escape($propName) + '" parent="WoodenObjects"[^\]]*\][\r\n]+transform = ([^\r\n]+)'
    if ($text -match $pattern) {
        $transform = $Matches[1].Trim()
    }

    $extraBlocks = @()
    $extraResources = @()
    $loadStep = 3

    if ($text -match '(?ms)(\[(?:ext_resource|sub_resource)[^\]]+\][\r\n]+)*(\[node name="(?!WoodenObjects)[^"]+" type="[^"]+" parent="\."\][\s\S]*?)(?=\r?\n\[node name="WoodenObjects"|\r?\n\[node name="[^"]+" parent="WoodenObjects"|\z)') {
        # Box.tscn cover piece handled below via explicit tail scan
    }

    $lines = $text -split "\r?\n"
    $inExtraRoot = $false
    $extraLines = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\[node name="(?!WoodenObjects)([^"]+)" type="([^"]+)" parent="\."\]$') {
            $inExtraRoot = $true
            $extraLines.Add($line)
            continue
        }
        if ($inExtraRoot) {
            if ($line -match '^\[node') {
                $inExtraRoot = $false
                $i--
                continue
            }
            $extraLines.Add($line)
        }
    }

    if ($extraLines.Count -gt 0) {
        foreach ($line in $lines) {
            if ($line -match '^\[ext_resource type="Script" uid="([^"]+)" path="([^"]+)" id="(\d+)_') {
                $extraResources += $line
            }
        }
        $extraBlocks += ($extraLines -join "`n")
    }

    if ($extraResources.Count -gt 0) {
        $loadStep = 4
    }

    $out = New-Object System.Collections.Generic.List[string]
    $out.Add("[gd_scene load_steps=$loadStep format=3$uidLine]")
    $out.Add("")
    $out.Add("[ext_resource type=`"PackedScene`" uid=`"$gltfUid`" path=`"$gltfPath`" id=`"1_gltf`"]")
    $out.Add("[ext_resource type=`"Script`" path=`"$scriptPath`" id=`"2_script`"]")
    foreach ($res in $extraResources) {
        $out.Add($res)
    }
    $out.Add("")
    $out.Add("[node name=`"$propName`" type=`"Node3D`"]")
    $out.Add("script = ExtResource(`"2_script`")")
    $out.Add("visible_prop_name = &`"$propName`"")
    $out.Add("prop_transform = $transform")
    $out.Add("")
    $out.Add("[node name=`"WoodenObjects`" parent=`".`" instance=ExtResource(`"1_gltf`")]")
    if ($extraBlocks.Count -gt 0) {
        $out.Add("")
        $out.Add($extraBlocks[0])
    }

    [System.IO.File]::WriteAllText($file, ($out -join "`n") + "`n")
    Write-Host "Regenerated $($_.Name)"
}

Write-Host "Done."
