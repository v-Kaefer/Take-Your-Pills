# Validation scripts

Repository and smoke-check helpers live here.

## US-16 impact comparison

`us16_impact_compare.py` replays the current `US-16` balance against the pre-US-16
baseline (`cc38aca`) and the first retune pass (`fa5493c`) using a headless
Godot probe. It writes the comparison report to
`docs/playtests/us16-impact-verification.md` by default.

Run it from the repository root:

```bash
python3 scripts/validation/us16_impact_compare.py
```
