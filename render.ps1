# Batch render baby blocks previews (ASCII only for PS 5.1)
# PS 5.1 strips inner quotes of -D args, so we rewrite defaults into a temp scad instead.
$ErrorActionPreference = "Continue"
$osc = "C:\Users\19592\XiaomiMiMoProjects\.mimo-sessions\2026\09\28\skill-1-ai-2-3d\openscad-new\OpenSCAD-2026.09.23-x86-64\openscad.com"
$src = "baby_blocks_p1.scad"
if (-not (Test-Path "renders")) { New-Item -ItemType Directory -Name "renders" | Out-Null }
$tmp = "renders\_tmp.scad"

$jobs = @(
    @{ n = "dice";  p = "dice";  v = "block" },
    @{ n = "dots";  p = "dots";  v = "block" },
    @{ n = "rings"; p = "rings"; v = "block" },
    @{ n = "weave"; p = "weave"; v = "block" },
    @{ n = "ball";  p = "ball";  v = "block" },
    @{ n = "mold";  p = "dice";  v = "mold_split" }
)

$base = [System.IO.File]::ReadAllText((Join-Path (Get-Location) $src))
foreach ($j in $jobs) {
    $code = $base -replace '(?m)^PART = "[a-z]+";', ('PART = "' + $j.p + '";')
    $code = $code -replace '(?m)^VIEW = "[a-z_]+";', ('VIEW = "' + $j.v + '";')
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) $tmp), $code)
    $out = "renders\$($j.n).png"
    & $osc -o $out --imgsize=1200,900 --autocenter --viewall --camera=0,0,0,65,0,30,500 --projection=p --colorscheme=Tomorrow $tmp 2> "renders\$($j.n).err" | Out-Null
    if (Test-Path $out) {
        $kb = [math]::Round((Get-Item $out).Length / 1KB)
        Write-Output "OK  $($j.n).png  ${kb}KB"
    } else {
        Write-Output "FAIL $($j.n)"
    }
}
