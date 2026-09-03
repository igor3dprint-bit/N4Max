# eddy-ng: the Z-offset that measures itself

This document picks up where [EDDY.md](EDDY.en.md) stops. There you install the BTT Eddy with the
driver that comes with Klipper. Here you swap that driver for **eddy-ng**, and the machine starts
finding the nozzle zero by itself, on every print, instead of you calibrating with paper and saving a
number.

Done and measured on my Neptune 4 Max on 03/09/2026. Like everything else in this repository: it
broke first, worked later, and the mistakes are written down with the fix.

> **Credit.** The modern Klipper on this machine is the work of
> [S&M Makers](https://github.com/sandmmakers/klipper). eddy-ng is by
> [vvuk](https://github.com/vvuk/eddy-ng). I only put the two together on this printer and wrote down
> the path.

---

## 1. Eddy and eddy-ng: what is the difference, in two sentences

**The BTT Eddy is the hardware**: a coil that measures how far away the bed is, without touching it.
That does not change.

**eddy-ng is alternate software for that same hardware.** Same sensor, same cable, same part on the
toolhead. What changes is the program inside Klipper that interprets what the coil reads.

### Why switch

![Eddy and eddy-ng use the same hardware](docs/img/eddy-vs-eddyng.svg)

Every eddy sensor has the same problem: **the reading changes as things heat up.** The hot bed and
the hot coil itself shift the measurement. It is not a defect; it is the physics of the inductive
principle.

The two pieces of software attack that problem in different ways:

| | Standard driver (`probe_eddy_current`) | eddy-ng (`probe_eddy_ng`) |
|---|---|---|
| How it finds the nozzle zero | You do the paper test once and save the number | The nozzle **touches the bed** and zero is measured right then |
| When that happens | Once, and it is supposed to hold forever | On every print |
| Thermal drift | Corrected by a compensation table that you calibrate | Not needed: the measurement is already done hot |
| Swapping nozzles | Recalibrate everything | Do nothing; the next tap finds it by itself |
| Printing ABS at 100 °C after PLA at 60 °C | Zero is wrong; you compensate by eye | Zero is correct for both |

That "the nozzle touches and measures" has a name: **tap**. That is the whole feature. If tap does
not work on your mount, switching drivers is not worth it; the standard driver already does the rest.

### And what does NOT change

- Bed scanning speed. `rapid_scan` already exists in the standard driver.
- The physical part, the adapter, the wiring.
- The fact that the Eddy only sees the last few millimeters. Everything from [EDDY.md](EDDY.en.md)
  still applies.

---

## 2. Three things I was told would block it, and did not

I almost did not do this installation because of three "blockers". **Two were false and the third
was badly stated.** If you read this somewhere, read this too:

**"Klipper mainline does not have the HC32F460 port, so migrating leaves the mainboard without
firmware."** False. The `src/hc32f460` directory exists in
[Klipper mainline](https://github.com/Klipper3d/klipper/tree/master/src). And it is a useless
discussion anyway, because:

**"You need to migrate to Klipper mainline."** You do not. eddy-ng installs **on top of the
S&M Makers fork**, without changing Klipper. The whole installation is three symbolic links and two
`sed` commands.

**"The coil needs to be ~2.95 mm from the nozzle or tap will not work."** Here is the correct version:
the eddy-ng wiki says tap is *sensitive* to that height. Mine is at **0.94 mm**, one third of the
recommended height, and **tap works**: three measurements gave -0.050 / -0.042 / -0.057 mm, with a
standard deviation of **0.006 mm**. Six microns.

The lesson is not "ignore the wiki". It is that **calibration answers this for you in 2 minutes**
(topic 6), and the real number is worth more than the prediction. Run it and see.

---

## 3. What you need before starting

- A BTT Eddy already installed and **working** with the standard driver. If you are not there yet,
  [EDDY.md](EDDY.en.md) is the path. Do not start here.
- SSH access to the printer.
- One quiet hour. There is a step that restarts Klipper with a different Python interpreter, and you
  want to be near the machine.
- No print running.

**There is a way back at every step**, and it is in topic 10. Nothing here is irreversible.

---

## 4. The recipe, in order

![The migration order](docs/img/eddyng-ordem.svg)

### Step 0 - protect what you already have

```bash
# dated config backups
cd ~/klipper_config
cp printer.cfg printer.cfg.pre-eddyng-$(date +%Y%m%d-%H%M)
cp eddy.cfg   eddy.cfg.pre-eddyng-$(date +%Y%m%d-%H%M)
```

If you have any hand-made change inside the Klipper folder (I had a patch in `probe.py`), **commit it
to a local branch now**, otherwise the rest of the process deletes it:

```bash
cd ~/klipper.sandmmakers
git status --short          # see whether anything is modified
git checkout -b patch-local-$(date +%Y%m%d)
git add -A && git commit -m "preserve local changes"
```

### Step 1 - download eddy-ng somewhere permanent

**Do not clone into `/tmp`.** The installer creates *symbolic links* pointing to the repository
folder. `/tmp` is cleaned on reboot, and the next day Klipper starts without the modules.

```bash
git clone https://github.com/vvuk/eddy-ng.git ~/eddy-ng
```

### Step 2 - Klipper here runs Python 2, and eddy-ng is Python 3

Check:

```bash
~/klippy-env/bin/python --version    # here it returned: Python 2.7.16
```

If it returns 2.x, you need a Python 3 environment. **Create a new one next to the old one; do not
replace the old one**. The old one is your rollback:

```bash
virtualenv -p /usr/bin/python3 ~/klippy-env-py3
~/klippy-env-py3/bin/pip install -r ~/klipper/scripts/klippy-requirements.txt
~/klippy-env-py3/bin/pip install numpy
```

> `python3 -m venv` fails on this image (`ensurepip` is not installed). Use `virtualenv`, which is
> already there. And `numpy` is an eddy-ng dependency that nobody declares. Without it, Klipper does
> not start.

**Before switching, test that the whole fork compiles on Python 3:**

```bash
cd ~/klipper && ~/klippy-env-py3/bin/python -m compileall -q klippy/
```

Silence and exit code 0 mean no Elegoo module is Python-2-only. It passed cleanly here. If an error
appears, **stop** and read which file it is. That is the moment to quit cheaply.

### Step 3 - point the service at Python 3

Needs `sudo`:

```bash
sudo cp /etc/systemd/system/klipper.service /etc/systemd/system/klipper.service.bak-pre-py3
sudo sed -i 's#/home/mks/klippy-env/bin/python#/home/mks/klippy-env-py3/bin/python#' \
     /etc/systemd/system/klipper.service
sudo systemctl daemon-reload
sudo systemctl restart klipper
```

**Turn the heaters off first** (`M140 S0` and `M104 S0`). Restarting Klipper with a heater on drops
the MCU with this message:

```
MCU 'mcu' shutdown: Missed scheduling of next digital out event
```

This **is not a defect or a sign that Python 3 did not work**. It is the microcontroller safety
guard doing its job: the host disappeared while a heater pin was pulsing. A `FIRMWARE_RESTART` fixes
it. I wasted a good while thinking it was the interpreter.

Confirm:

```bash
curl -s http://localhost:7125/printer/info | grep -o '"python_path":[^,]*'
```

### Step 4 - install eddy-ng

```bash
cd ~/eddy-ng && ./install.sh
```

It copies three files and applies two `sed` edits, one in `src/Makefile` and another in
`klippy/extras/bed_mesh.py`. **Confirm that both landed**. The installer uses `os.system` and does
not check whether the match worked:

```bash
grep -n "LDC1612" ~/klipper/src/Makefile          # should end with sensor_ldc1612_ng.c
grep -n "eddy.*probe_name" ~/klipper/klippy/extras/bed_mesh.py   # should have #eddy-ng at the end
```

On the S&M fork, both target lines exist and the patch applies cleanly.

### Step 5 - recompile the Eddy firmware

eddy-ng brings a new sensor (`sensor_ldc1612_ng.c`) that needs to be inside the firmware on the Eddy
itself. **This does not touch the printer mainboard.**

Use a **separate** configuration file, not the machine's `.config` (topic 9 explains why):

```bash
cd ~/klipper
cat > ~/eddyng-rp2040.config <<'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_RPXXXX=y
CONFIG_MACH_RP2040=y
CONFIG_RPXXXX_FLASH_START_0100=y
CONFIG_RP2040_USB=y
CONFIG_USBSERIAL=y
CONFIG_WANT_LDC1612=y
EOF
make KCONFIG_CONFIG=~/eddyng-rp2040.config olddefconfig
make KCONFIG_CONFIG=~/eddyng-rp2040.config
ls -la out/klipper.uf2      # must exist
```

**Keep the firmware you just compiled and the `.config` that generated it**, because the rollback in
topic 10 depends on both existing:

```bash
mkdir -p ~/eddy-firmware-backup
cp out/klipper.uf2 ~/eddy-firmware-backup/klipper-eddyng-$(date +%Y%m%d).uf2
cp ~/eddyng-rp2040.config ~/eddy-firmware-backup/
```

> There is no way to read back the firmware that is **already** on the Eddy: the rp2040 does not give
> you the written binary. So the way back is to recompile, and to recompile you need the previous
> `.config`. If you never compiled firmware on this machine, the Eddy has BigTreeTech's ready-made
> binary, which you can download again from their official repository.

Flash it. **Stop Klipper first** and use a real terminal session (`ssh -t`), because `make flash`
calls `sudo` in the middle:

```bash
curl -s -X POST "http://localhost:7125/machine/services/stop?service=klipper"
make KCONFIG_CONFIG=~/eddyng-rp2040.config flash \
     FLASH_DEVICE=/dev/serial/by-id/usb-Klipper_rp2040_SEU_SERIAL-if00
curl -s -X POST "http://localhost:7125/machine/services/start?service=klipper"
```

> **If it hangs at `sudo: no tty present`:** the Eddy has already entered bootloader mode and the
> flash stopped halfway through. Do not panic: **its memory still has the old firmware**. Either
> repeat with `ssh -t` and `FLASH_DEVICE=2e8a:0003` (the Eddy address in bootloader mode), or power
> the printer off and on at the wall and everything comes back as it was.

Confirm after it starts. The `eddy` MCU must report more commands than before:

```bash
grep "Loaded MCU 'eddy'" ~/klipper_logs/klippy.log | tail -1
```

Here it went from 105 to **131 commands**. The extra 26 are the new sensor.

### Step 6 - change the configuration

In `eddy.cfg` (or wherever your Eddy section is):

```ini
[probe_eddy_ng btt_eddy]        # was [probe_eddy_current btt_eddy]
sensor_type: ldc1612
i2c_mcu: eddy
i2c_bus: i2c0f
x_offset: -33.34                # YOUR measured value
y_offset: 20                    # YOUR measured value
```

**Delete the options that only exist in the old driver**. Klipper rejects unknown options and will
not start: `speed`, `samples`, `samples_result`, `sample_retract_dist`, and `calibrate:`.

**Also delete the autosave block from the old driver** at the end of `printer.cfg`:

```
#*# [probe_eddy_current btt_eddy]
#*# z_offset = ...
#*# reg_drive_current = ...
#*# calibrate = ...
```

And search the rest of the configuration for any macro that reads `probe_eddy_current`. I had a guard
in `PRINT_START` that read its `z_offset` and would have broken every print.

---

## 5. The Z bootstrap: the chicken and the egg

![The first-homing deadlock and the way out](docs/img/eddyng-bootstrap-z.svg)

Here you will hit a wall that looks like a serious error and is not.

On this machine **the probe is the only Z reference that exists** (`endstop_pin: probe:z_virtual_endstop`,
and the original physical sensor was removed from the toolhead when the Eddy was installed). So:

- `G28` needs the probe to find Z.
- The probe does not have eddy-ng calibration yet.
- And `PROBE_EDDY_NG_SETUP` requires X and Y to be homed.

```
$ G28
!! Drive current 15 not calibrated

$ PROBE_EDDY_NG_SETUP
!! X and Y must be homed before setup
```

**The way out is to home only X and Y**, which do not call the probe:

```
G28 X Y
PROBE_EDDY_NG_SETUP
```

### The trap that cost me a whole calibration

Setup opens a paper test (`TESTZ` to go down, `ACCEPT` to confirm). Two things:

**The Z number shown on screen is fictitious.** Here it started at `462.5` because this machine's
`[homing_override]` declares `SET_KINEMATIC_POSITION Z=482.5` before probing. **Ignore the number and
watch the paper.** The real zero will appear at whatever weird value.

**Do not touch X or Y during the test.** No jog button, no `G28`, no other macro. Klipper refuses
`ACCEPT` if the head has moved away from the point where the test started:

```python
# klippy/extras/manual_probe.py
if pos[:2] != start_pos[:2] or pos[2] >= start_pos[2]:
    "Manual probe failed! Use TESTZ commands to position the nozzle prior to running ACCEPT."
```

I did the paper test correctly and lost everything because of that. The message suggests you got the
height wrong, but the problem was in X/Y.

---

## 6. Calibration, and how to read the result

![How to read the drive currents](docs/img/eddyng-correntes.svg)

After `ACCEPT`, eddy-ng sweeps the drive currents by itself and chooses two. Real output from this
machine:

```
!! Drive current 15 error: min height for valid samples is too high: 3.728 > 0.65
!! Drive current 16 error: min height for valid samples is too high: 1.092 > 0.65
// Drive current 17 warning: min height is 0.218 (> 0.025) is too high for tap.
//   This calibration will work fine for homing, but may not for tap.
// Drive current 17: valid height: 0.218 to 15.000, freq spread 3.46%, Fit 0.0053
// using 17 for homing.
// Drive current 18: valid height: 0.001 to 5.360, freq spread 3.57%, Fit 0.0051
// using 18 for tap.
// Setup success.
```

**How to read this:**

- Currents 15 and 16 **failed**, and that is fine. eddy-ng tests several and discards the bad ones.
- 17 works for **homing** (sees from 0.218 to 15 mm: far away, good for descending while searching).
- 18 works for **tap** (sees from **0.001 mm**: very close, which is what touching requires).
- That *warning* on 17 is scary and is not a problem: it says 17 is not good for tap. 18 is, and that
  is what tap uses.

Run `SAVE_CONFIG`. Then confirm it really saved. On my first refused `ACCEPT`, `SAVE_CONFIG` ran and
saved nothing, and I only found out by looking:

```bash
grep -A6 "probe_eddy_ng" ~/klipper_config/printer.cfg | tail -8
```

You must see `calibrated_drive_currents`, `reg_drive_current`, `tap_drive_current`, and the
`calibration_17` / `calibration_18` curves.

Then test, in this order:

```
G28 Z                  # uses the homing current
PROBE_EDDY_NG_TAP      # uses the tap current
```

Result here:

```
// Tap 1: z=-0.050
// Tap 2: z=-0.042
// Tap 3: z=-0.057
// Probe computed tap at -0.050 (stddev 0.006) with 3 samples
```

**What to look at is `stddev`**, not the value. 0.006 mm means the three touches agreed within six
microns. That is what says you can trust it. If yours comes in the hundredths, the mount needs
attention before you put tap in the print.

---

## 7. The print flow that comes out of this

![The new PRINT_START sequence](docs/img/eddyng-print-start.svg)

Tap **is not a number you save**. It is redone on every print. So it lives inside `PRINT_START`:

```ini
[gcode_macro PRINT_START]
variable_temp_home: 120
gcode:
    {% set bed  = params.BED|default(printer.heater_bed.target)|float %}
    {% set extr = params.EXTRUDER|default(printer.extruder.target)|float %}
    {% set th   = printer['gcode_macro PRINT_START'].temp_home|float %}

    G90
    G92 E0
    M140 S{bed}
    M104 S{th}
    M190 S{bed}
    M109 S{th}

    G28
    PROBE_EDDY_NG_TAP        # <- zero, measured now

    M109 S{extr}
    LINHA_KAMP               # <- purge
```

**Why tap runs at 120 °C instead of final temperature:** hot enough for the reading to be consistent
with the print, cool enough that the nozzle does not ooze and dirty its own measurement. A drooling
nozzle at touch time measures the plastic blob, not the nozzle.

**Never put `SAVE_CONFIG` after a tap.** `SAVE_CONFIG` restarts Klipper and throws away the
measurement you just made. If tap is always equally high or equally low, the adjustment is
`PROBE_EDDY_NG_SET_TAP_OFFSET`; that one is saved.

The slicer start gcode becomes **one line only**:

```
PRINT_START BED=[bed_temperature_initial_layer_single] EXTRUDER=[nozzle_temperature_initial_layer]
```

If you leave `G28` in the slicer before that, it homes with the nozzle cold and `PRINT_START` does it
all again afterward. That is wasted probing and about 30 seconds per print.

The complete macros, including the purge line and a guided Z-offset macro with a confirmation
window, are in [config/eddyng_macros.cfg](config/eddyng_macros.cfg).

---

## 8. Mistakes and fixes from this installation

The order they actually appeared.

| What happened | Why | What fixed it |
|---|---|---|
| I almost did not do the installation | Three second-hand "blockers", two false | Measure instead of accepting. Topic 2 |
| `No module named 'numpy'` | Undeclared eddy-ng dependency | `pip install numpy` in the new environment |
| `cannot import name 'final' from 'typing'` | eddy-ng wants Python >=3.8, the image has 3.7.3 | Topic 9. It is the **only** 3.8 feature used |
| Build targeted AVR and did not generate `.uf2` | `make olddefconfig` on an old `.config` | Topic 9 |
| `hardware/structs/ticks.h: No such file` | Same cause as above: the `#if` fell into the RP2350 branch | Topic 9 |
| MCU dropped with `Missed scheduling of next digital out event` | I restarted Klipper with the bed at 50 °C | Safety guard, not a defect. Heater off + `FIRMWARE_RESTART` |
| `make flash` stopped at `sudo: no tty present`, Eddy in bootloader | `ssh` without `-t` | `ssh -t` and `FLASH_DEVICE=2e8a:0003`. Nothing was erased |
| `ACCEPT` refused with the paper at the right height | X/Y moved during the test | Topic 5 |
| One `[bed_mesh]` option disappeared | My `sed` for `^speed:` caught two sections | Edit a large config with a script that knows where it is, not a global regex |
| Bed heating by itself, "mysteriously" | One of my macros, `MANTER_MESA_50`, requested months before | Read your own configuration before theorizing |

**What worked on the first try:** the Python 3 `compileall` of the fork (no Elegoo module is
Python-2-only), the installer patches on the S&M fork, homing with current 17, and tap.

**The biggest method win:** almost every diagnosis in this list came from *reading*, not trying.
`~/klipper_logs/klippy.log` and `curl .../server/gcode_store?count=30` answered every question. When
I guessed, I was wrong, including about the bed heating.

---

## 9. Two build traps that stand on their own

**The Kconfig symbol changed names.** If your `.config` is old, it says `CONFIG_MACH_RP2040=y` as
the *architecture*. In current Klipper, the architecture is `CONFIG_MACH_RPXXXX`, and `MACH_RP2040`
became the *model* choice inside it (because RP2350 exists now too). An old `.config` makes
`make olddefconfig` fail to recognize the choice and **fall into the first item in the list, which is
AVR**. The build targets an ATmega and you are left staring at it without understanding. For the same
reason, the rp2040 `main.c` goes into the wrong `#if` branch and asks for a `ticks.h` that only
exists on the RP2350.

That is why topic 5 uses a separate file with the current names, and never `olddefconfig` on the
machine's `.config`.

**`typing.final` does not exist in Python 3.7.** It is the only 3.8+ feature eddy-ng uses, and it is
only a decorator for type checking. It does nothing at runtime. In `probe_eddy_ng.py`, remove
`final,` from inside `from typing import (...)` and put this just below:

```python
try:
    from typing import final
except ImportError:      # Python 3.7
    def final(x):
        return x
```

---

## 10. How to roll back

Every step has a return path, and none depends on the previous one having worked.

| To undo | Command |
|---|---|
| Python 3 | `sudo cp /etc/systemd/system/klipper.service.bak-pre-py3 /etc/systemd/system/klipper.service && sudo systemctl daemon-reload && sudo systemctl restart klipper` |
| eddy-ng | `cd ~/eddy-ng && ./install.sh -u` (undoes the files and the two `sed` edits) |
| Configuration | restore the `printer.cfg.pre-eddyng-*` and `eddy.cfg.pre-eddyng-*` from step 0 |
| Eddy firmware | recompile with your previous `.config` and flash again |
| A flash that hung halfway through | power the printer off and on at the wall |

The Python 2 environment (`~/klippy-env`) **stays intact** the whole time. Do not delete it.

---

## 11. What is still pending here

Written so you do not think this is complete:

- **The bed mesh is outside `PRINT_START` on purpose.** The one that was saved was probed with
  `y_offset=0` and is shifted by 20 mm, besides being from the old driver. Redo yours before turning
  it back on.
- **Temperature compensation**: I do not use it. `[temperature_probe]` does not start on this fork
  (the chip sensor is missing) and tap makes it unnecessary. If you depend on it, that is something
  to test.
- **Mounting at 0.94 mm**: it works on *this* machine. If your tap `stddev` is bad, raising the coil
  closer to the wiki's 2.95 mm is the first thing to try.

---

## 12. Links

- [vvuk/eddy-ng](https://github.com/vvuk/eddy-ng) · [BTT Eddy wiki on eddy-ng](https://github.com/vvuk/eddy-ng/wiki/BTT-Eddy)
- [S&M Makers / klipper](https://github.com/sandmmakers/klipper): the port that makes this machine exist
- [EDDY.md](EDDY.en.md): Eddy installation with the standard driver, and the sensor traps
- [config/](config/): the real files from this machine
- [MAQUINA-REFERENCIA.md](MAQUINA-REFERENCIA.md): the whole machine, value by value
