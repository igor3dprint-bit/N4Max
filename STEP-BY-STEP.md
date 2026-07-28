# Modern Klipper on the Elegoo Neptune 4 Max — step by step

> 🇧🇷 [Versão em português](PASSO-A-PASSO.md) · 🔧 [The Z-offset that refuses to obey](Z-OFFSET.md)

The Neptune 4 Max ships from the factory with a Klipper build from **2022**. You can run the **2025**
one (0.13.0), and this guide shows exactly how — command by command, with what each one does and
what you should see on screen.

> 🙏 **Without S&M Makers none of this would exist.** All the work of porting modern Klipper to this
> machine is theirs. This guide walks through their process, with the pitfalls we hit in practice.
> Watch the **[@SandMMakers video](https://www.youtube.com/watch?v=Aoy3sI1lv1g)** and read the
> [original tutorial](https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html).

You do **not** need a USB stick, an SD card, a screwdriver, or to open the printer. It is all done
over the network.

---

## Contents

1. [Before you start](#1-before-you-start)
2. [Find the printer's IP](#2-find-the-printers-ip)
3. [Connect to the printer](#3-connect-to-the-printer)
4. [Recon (read-only, changes nothing)](#4-recon-read-only-changes-nothing)
5. [Make a backup](#5-make-a-backup-do-not-skip-this)
6. [Install](#6-install)
7. [Verify](#7-verify)
8. [What to do afterwards](#8-what-to-do-afterwards)
9. [Rolling back](#9-rolling-back)
10. [Common problems](#10-common-problems)

---

## 1. Before you start

### What you need

- The printer **powered on**, **not printing**, on the **same network** as your computer
- A computer running Windows 10/11, Mac or Linux
- About 30 minutes

### What is about to happen, in plain words

The printer is a little Linux computer. You are going to log into it over the network (that's
**SSH**), swap the Klipper folder for a newer one, recompile two small things, and reboot.

Only two things get replaced: the `~/klipper` folder and the `/usr/local/bin/klipper_mcu` program.
The printer's main chip (the **STM32 MCU**) is **never touched** — the author himself advises against
it, because it requires taking the machine apart.

### The risks, plainly

Touching firmware carries risk. The rollback path exists and is in [section 9](#9-rolling-back), but
you are the one standing next to the printer. If power drops mid-install, you may have to reflash the
Elegoo firmware from a USB stick.

**Do the [backup in section 5](#5-make-a-backup-do-not-skip-this).** It is the difference between a
scare and a problem.

---

## 2. Find the printer's IP

On the printer's panel go to **Settings**. The IP appears on screen, something like `192.168.0.50`.

If it isn't there, open your router's admin page and look through the connected devices for a name
like `mkspi`.

Write that number down. It appears in almost every command below. **Wherever this guide says
`YOUR_IP`, substitute yours.**

---

## 3. Connect to the printer

### Open a terminal

| System | How |
|---|---|
| **Windows** | Press `Win`, type `powershell`, Enter |
| **Mac** | `Cmd + Space`, type `terminal`, Enter |
| **Linux** | `Ctrl + Alt + T` |

### Log in

```bash
ssh mks@YOUR_IP
```

The first time it asks whether you trust the machine. Type `yes` and Enter.

Then it asks for the password. The default is:

```
makerbase
```

> ⚠️ **While you type the password, nothing appears on screen.** No asterisks, no dots. It looks like
> the keyboard stopped working. That is intentional — every Linux terminal does this. Type it and
> press Enter.

It worked if the text before your cursor becomes something like `mks@mkspi:~$`.

### Optional but recommended: log in without a password

If you are going to repeat these steps, install an access key. **Log out** (`exit`) and, on your own
computer, run:

```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
ssh-copy-id mks@YOUR_IP
```

Windows has no `ssh-copy-id`. Use this instead (it avoids duplicating the key if you run it twice):

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh mks@YOUR_IP "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys; K=$(cat | tr -d '\r'); grep -qxF \"$K\" ~/.ssh/authorized_keys || echo \"$K\" >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys"
```

### One thing that confuses people: `sudo` still asks for a password

Some commands need administrator power — they start with `sudo`. **Even with the key installed,
`sudo` asks for the password.** That is normal. Type `makerbase` when prompted.

---

## 4. Recon (read-only, changes nothing)

None of these four commands alter anything. Run them **inside the printer** (after `ssh`).

### 4.1 Which Elegoo firmware is installed

This is the single most important piece of information in the whole process.

```bash
grep -rhoE "1\.[0-9]+\.[0-9]+\.[0-9]+" /home/mks/Desktop/myfile/ 2>/dev/null | sort | uniq -c | sort -rn | head -3
```

What you should see (the number that repeats most is the right one):

```
     97 1.2.3.4
      1 Binary file /home/mks/Desktop/myfile/znp/znp_tjc_klipper/build/... matches
```

Here the firmware is **1.2.3.4**. Write yours down.

### 4.2 Which modern Klipper versions exist for it

```bash
git ls-remote --tags https://github.com/sandmmakers/klipper.git | grep -oE 'sandmmakers-[A-Za-z0-9.-]+' | grep -v '\^{}' | sort -u
```

Example output:

```
sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-0-1
sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-51-1
```

How to read that name:

```
sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-51-1
                              └──┬───┘ └──┬───┘ └┬┘
                    Elegoo firmware   Klipper   extra commits
```

> ⚠️ **The rule you cannot break:** the middle part must be **exactly** the firmware you noted in
> 4.1. If your firmware is `1.2.3.4`, only a tag with `v1.2.3.4` will do. Installing one built for a
> different firmware breaks the printer.

Among the compatible ones, pick the one with the **highest number of extra commits** (in the example,
`-51-1`).

**No tag matches your firmware?** Then you must update the Elegoo firmware first, and that process is
manual. See [section 10](#10-common-problems).

**Nothing at all, with an error?** The printer probably has no internet. It needs real internet
access — seeing your computer is not enough.

### 4.3 Is there disk space?

```bash
df -h /
```

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk1p2  6.6G  4.9G  1.7G  75% /
```

You need at least **800 MB** in the `Avail` column. If you have less, delete old gcodes from
`~/gcode_files`.

### 4.4 Is the printer printing?

```bash
curl -s http://localhost:7125/printer/objects/query?print_stats | grep -o '"state": "[a-z]*"'
```

It must say `"state": "complete"`, `"standby"` or `"cancelled"`. **If it says `"printing"`, stop
here** and wait for the print to finish.

---

## 5. Make a backup (do not skip this)

The installer keeps copies inside the printer itself. That covers 95% of problems — but not a
corrupted memory card. So take a copy **off the machine**.

Run this **on your computer**, not inside the printer. Type `exit` first.

**Windows (PowerShell):**

```powershell
cd $env:USERPROFILE\Desktop
ssh mks@YOUR_IP "tar czf - -C / home/mks/klipper_config home/mks/klipper usr/local/bin/klipper_mcu* 2>/dev/null" > backup-neptune.tar.gz
```

**Mac / Linux:**

```bash
cd ~/Desktop
ssh mks@YOUR_IP "tar czf - -C / home/mks/klipper_config home/mks/klipper usr/local/bin/klipper_mcu* 2>/dev/null" > backup-neptune.tar.gz
```

It takes a few minutes and produces a file of a few hundred MB on your Desktop.

**Check that the backup is good** (an unverified backup is not a backup):

```bash
gzip -t backup-neptune.tar.gz && echo "BACKUP OK"
```

If `BACKUP OK` appears, carry on. If nothing appears or it errors, do it again.

> 💡 The most valuable thing in that archive is `klipper_config/printer.cfg` — it holds all of your
> machine's calibration, and it is the only file you cannot download again from the internet.

---

## 6. Install

Log back into the printer (`ssh mks@YOUR_IP`).

**Before pasting anything**, set these two variables to YOUR values from section 4 — every command
below uses them:

```bash
FW=1.2.3.4
TAG=sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-51-1
```

Check they are right before continuing:

```bash
echo "firmware=$FW  tag=$TAG"
```

### 6.1 Stop the services

```bash
sudo systemctl stop klipper
sudo systemctl stop klipper_mcu
sudo systemctl stop makerbase-client
```

It asks for the password (`makerbase`) the first time. From here on the printer stops responding in
Fluidd/Mainsail until the end — that is expected.

### 6.2 Save the backups

```bash
cp ~/klipper_config/printer.cfg ~/klipper_config/printer.cfg.stock.v$FW
mv ~/klipper ~/klipper.stock.v$FW
sudo mv /usr/local/bin/klipper_mcu /usr/local/bin/klipper_mcu.stock.v$FW
```

Confirm all three exist before moving on:

```bash
ls -d ~/klipper.stock.v$FW /usr/local/bin/klipper_mcu.stock.v$FW ~/klipper_config/printer.cfg.stock.v$FW
```

If any of the three is missing, **stop**. Without them there is no way back.

### 6.3 Adjust the configuration file

Modern Klipper **removed** a setting called `max_accel_to_decel`. If it stays in the file, Klipper
will not start — and the error message does not explain why very well.

```bash
sed -i "s/^max_accel_to_decel:/#max_accel_to_decel:/" ~/klipper_config/printer.cfg
sed -i "/{% set RUN_DECEL/d" ~/klipper_config/printer.cfg
sed -i "s/ ACCEL_TO_DECEL={RUN_DECEL}//" ~/klipper_config/printer.cfg
```

Check no active line is left:

```bash
grep -nE "^max_accel_to_decel|RUN_DECEL" ~/klipper_config/printer.cfg
```

Nothing at all, or only lines starting with `#`, means you are good.

### 6.4 Download the new Klipper

```bash
git clone https://github.com/sandmmakers/klipper.git ~/klipper.sandmmakers
ln -sfn ~/klipper.sandmmakers ~/klipper
cd ~/klipper
git checkout $TAG
```

Confirm you got the right one:

```bash
git describe --tags
```

It must return exactly your `$TAG`.

### 6.5 Compile part 1 of 2

```bash
cd ~/klipper
sudo rm -f klippy/chelper/c_helper.so
~/klippy-env/bin/python2 klippy/chelper/__init__.py
~/klippy-env/bin/python2 -m compileall klippy
```

> ⚠️ **Deleting `c_helper.so` first is mandatory.** If that file does not exist when the printer
> boots, Elegoo's screen module copies an incompatible version over it, and Klipper dies with
> `undefined symbol: extruder_stepper_free`. Recompiling fixes it, but it's a scare you can avoid by
> doing it in the right order.

### 6.6 Compile part 2 of 2 (the slow one)

The original tutorial tells you to run `make menuconfig` and tick "Linux process" on a blue screen.
You can skip that screen by writing the option directly — the result is identical:

```bash
cd ~/klipper
make clean
echo "CONFIG_MACH_LINUX=y" > .config
make olddefconfig
```

Verify the configuration took:

```bash
grep CONFIG_BOARD_DIRECTORY .config
```

It must show `CONFIG_BOARD_DIRECTORY="linux"`. If it doesn't, **do not continue**.

Now compile for real. **This part takes 5 to 15 minutes and looks frozen.** It isn't. Don't close the
window.

```bash
make clean
make
```

Check the file came out:

```bash
ls -la out/klipper.elf
```

### 6.7 Install what you compiled

```bash
sudo mv out/klipper.elf /usr/local/bin/klipper_mcu.sandmmakers
sudo ln -sfn /usr/local/bin/klipper_mcu.sandmmakers /usr/local/bin/klipper_mcu
```

### 6.8 Reboot

```bash
sudo reboot now
```

The connection will drop — that is expected. Wait 45 to 90 seconds.

---

## 7. Verify

Log back in (`ssh mks@YOUR_IP`) and run:

### The installed version

```bash
grep -m1 "Git version" ~/klipper_logs/klippy.log
```

```
Git version: 'sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-51-1-0-g8dc12fe4'
```

### Did Klipper come up?

```bash
curl -s http://localhost:7125/printer/info | tr ',' '\n' | grep -E 'state|software_version'
```

```
{"result": {"state_message": "Printer is ready"
 "software_version": "sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-51-1-0-g8dc12fe4"
 "state": "ready"
```

It must say `"state": "ready"`.

### Did both processors show up?

```bash
grep -oE "Loaded MCU '[a-z]+' [0-9]+ commands" ~/klipper_logs/klippy.log | tail -2
```

```
Loaded MCU 'mcu' 105 commands
Loaded MCU 'rpi' 127 commands
```

`mcu` is the printer's original STM32. `rpi` is the one you just compiled. **Both must appear.**

---

## 8. What to do afterwards

**Before printing anything**, on the printer's panel:

1. **Auto bed leveling**
2. **Set the Z-offset**

The old calibration is not carried over reliably by the new Klipper.

> 🔧 **If the Z-offset seems to do nothing at all, it is not your fault.** This machine has a known
> defect with three causes, and the fix is in **[Z-OFFSET.md](Z-OFFSET.md)**. Worth reading before
> you waste time thinking you botched the calibration — we did.

### Two odd things that are normal

**1. An error when saving the bed mesh.** After leveling from the panel and hitting save, an error
may appear in the Fluidd/Mainsail console. It is harmless. Send a `FIRMWARE_RESTART` (or reboot the
printer) and you are done — the mesh **was saved** and will be used.

**2. The "performance modes" changed.** Those speed modes on the panel relied on `max_accel_to_decel`,
which was removed from Klipper. They no longer control deceleration. In practice you may notice a
difference on part corners. To restore the old behaviour, add this under `[printer]` in your
`printer.cfg`:

```ini
minimum_cruise_ratio: 0
```

---

## 9. Rolling back

This works if you did section 6.2 and all three copies exist.

```bash
FW=1.2.3.4                    # same as section 4.1

sudo systemctl stop klipper
sudo systemctl stop klipper_mcu
sudo systemctl stop makerbase-client

# keep the new config before overwriting it
cp ~/klipper_config/printer.cfg ~/klipper_config/printer.cfg.new
cp ~/klipper_config/printer.cfg.stock.v$FW ~/klipper_config/printer.cfg

rm ~/klipper
mv ~/klipper.stock.v$FW ~/klipper

sudo rm -f /usr/local/bin/klipper_mcu
sudo mv /usr/local/bin/klipper_mcu.stock.v$FW /usr/local/bin/klipper_mcu

sudo reboot now
```

> ⚠️ **Rolling back restores the factory `printer.cfg`.** Every bit of calibration you did after the
> install stays in `printer.cfg.new` and **does not come back on its own**. To recover a setting,
> open both files side by side and copy what you need.

The `~/klipper.sandmmakers` folder stays where it is, so reinstalling later is quick.

---

## 10. Common problems

### `Permission denied` when connecting over SSH

Wrong password, or someone changed it. The default is `makerbase`. If another mod was installed
before (OpenNept4une, for example), the password may be different.

### `Host key verification failed`

Happens when the printer was reflashed and its "identity" changed. On your computer run:

```bash
ssh-keygen -R YOUR_IP
```

Then connect again.

### Windows says `ssh` is not recognized

Go to **Settings → Apps → Optional features → Add a feature** and install the **OpenSSH Client**.
Close and reopen PowerShell.

### Klipper won't start after installing

Find out why:

```bash
tail -30 ~/klipper_logs/klippy.log
```

The two most common errors:

| Message | Cause | Fix |
|---|---|---|
| `Option 'max_accel_to_decel' is not valid` | Section 6.3 didn't take | Redo 6.3 and send `FIRMWARE_RESTART` |
| `undefined symbol: extruder_stepper_free` | The wrong `c_helper.so` was copied over | Redo section 6.5 entirely |

### There is no modern Klipper for my firmware

Then the road is **manual**: you must update the Elegoo firmware first.

1. Download from [elegoo.com/pages/download](https://www.elegoo.com/pages/download)
2. **Mainboard:** copy the `ELEGOO_UPDATE_DIR` folder onto an empty USB stick, plug it into the
   printer, and on the panel go to Settings → About Machine → down arrow → Confirm. Takes 1 to 2 minutes.
3. **Screen:** copy the `.tft` file onto the SD card that came with the printer. This one needs the
   back cover of the screen removed with a 2 mm hex key, insert the SD, power on, wait for the
   update, then open it again to take the card out.
4. Redo bed leveling and the Z-offset.

Then go back to [section 4](#4-recon-read-only-changes-nothing).

> ⚠️ The Elegoo update **can erase your `printer.cfg`** and may force leveling into Standard mode
> (6x6). If you used **Professional Mode**, you will have to set it up again.

---

## Credits

All the heavy lifting belongs to **S&M Makers**:

- 📄 [Original tutorial](https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html)
- 💾 [github.com/sandmmakers/klipper](https://github.com/sandmmakers/klipper)
- ▶️ [@SandMMakers video](https://www.youtube.com/watch?v=Aoy3sI1lv1g)

**No warranty.** Touching firmware carries risk. The rollback path exists and works, but you are the
one standing next to the printer.
