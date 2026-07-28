# Modern Klipper on the Neptune 4 Max — the easy way

> 🇧🇷 [Versão em português](LEIA-ME.md)

The Elegoo Neptune 4 Max ships from the factory with a Klipper build from **2022**. This package
installs a **2025** build (0.13.0, ported by S&M Makers) without you typing a single command.

You double-click three files, in order. Everything else is automatic.

> 🙏 **Without S&M Makers, none of this would exist.** All the real work is theirs — this is only the
> wrapper. Watch the **[@SandMMakers video](https://www.youtube.com/watch?v=Aoy3sI1lv1g)** and read
> the [original tutorial](https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html).

You do **not** need a USB stick, an SD card, a screwdriver, or to open the printer.

---

## Before you start

Check these four things:

- [ ] The printer is **powered on** and **not printing**
- [ ] The printer is on the **same network** as your computer (wifi or cable)
- [ ] You know the printer's **IP address** (how to find it, below)
- [ ] Your Windows has the **OpenSSH Client** (Windows 10 and 11 include it already)

### How to find the printer's IP

On the printer's panel, go to **Settings**. The IP shows up on screen, something like `192.168.0.50`
or `192.168.68.105`.

If you can't find it there, open your router's admin page and look through the list of connected
devices for a name like `mkspi`.

You only type this IP once. The program remembers it and reuses it in the following steps.

---

## The three steps

Double-click each file, in this order:

### 1️⃣ `1-Configurar-Acesso.bat`  *(Set up access)*

Creates an access key and installs it on the printer, so it stops asking for a password every time.

It will ask for the IP, then for the **printer's password**. The default password is:

```
makerbase
```

> **Heads up:** while you type the password, **nothing appears on screen** — no asterisks, no dots.
> It looks like the keyboard isn't working. That is intentional, it's how it's supposed to behave.
> Type it and press Enter.

You only need to do this once.

### 2️⃣ `2-Verificar-Impressora.bat`  *(Check the printer)*

Looks only, changes nothing. It detects your printer's firmware version and tells you whether a
compatible modern Klipper exists.

If it says "TUDO CERTO" (all good), move on. If it says anything else, read the troubleshooting
section at the end.

### 3️⃣ `3-Instalar-Klipper.bat`  *(Install Klipper)*

Does the install. It will ask you to type `SIM` to confirm.

**It takes 5 to 15 minutes.** At several points it will look frozen — it isn't, that's the printer
compiling. Don't close the window, don't unplug anything.

At the end the printer reboots on its own and the program confirms the installed version.

---

## Would you rather have an AI do it?

If you use Claude Code (or another agent with terminal access), hand it the file
**`USAR-COM-CLAUDE.md`** and ask it to run the procedure. It contains the complete process, the
pitfalls and the safety rules. Same destination, different road.

---

## After installing

**Do this before printing anything**, on the printer's panel:

1. **Auto bed leveling**
2. **Set the Z-offset**

The old calibration is not carried over reliably by the new Klipper.

> 🔧 If the Z-offset seems to have no effect at all, **it is not your fault** — this machine has a
> known quirk. The cause and the fix are in **[EXTRA-Z-OFFSET.md](EXTRA-Z-OFFSET.md)**.

### Two odd things that are normal

Don't panic, these are known and documented limitations:

**1. An error when saving the bed mesh.** After leveling from the panel and hitting save, an error
message may appear in the Fluidd/Mainsail console. It is harmless. Send a `FIRMWARE_RESTART` (or just
reboot the printer) and you're done — the mesh **was saved** and will be used.

**2. The "performance modes" changed.** Those speed modes you pick on the panel used to rely on a
setting called `max_accel_to_decel`, which was removed from Klipper. They no longer control
deceleration. In practice: you may notice a difference on part corners. If it bothers you, it can be
tuned by hand in `printer.cfg` (look for `minimum_cruise_ratio`).

---

## Something broke? Rolling back

Run `4-Voltar-Ao-Original.bat`.

It restores everything to the factory state using the backups that were made automatically during
the install.

The backups live on the printer, here:

| What | Where it was stored |
|---|---|
| Original Klipper | `~/klipper.stock.vYOURVERSION` |
| MCU program | `/usr/local/bin/klipper_mcu.stock.vYOURVERSION` |
| Your configuration | `~/klipper_config/printer.cfg.stock.vYOURVERSION` |

---

## Common problems

### "NAO CONSEGUI FALAR COM A IMPRESSORA" *(couldn't reach the printer)*
The IP is wrong or the printer is off. Run the file again and answer `n` when it asks whether to use
the saved IP, then type the correct one.

### The password `makerbase` doesn't work
Someone changed the password, or another mod was installed previously (OpenNept4une, for example).
If you don't know the current password, this route can't continue.

### "seu Windows nao tem o SSH instalado" *(your Windows has no SSH)*
Go to **Settings → Apps → Optional features → Add a feature** and install the **OpenSSH Client**.
Then run it again.

### "A impressora nao conseguiu acessar a internet" *(the printer has no internet)*
The printer needs internet access to download the new Klipper — seeing your PC is not enough. Check
its wifi connection.

### What if it says my firmware has no matching version?

Then the road gets bumpier, and it is **manual**. It means the Elegoo firmware installed on your
printer has no corresponding modern Klipper build, and you need to update the Elegoo firmware first.

Summary of the process (details on the official site, link at the end):

1. Download the new firmware at [elegoo.com/pages/download](https://www.elegoo.com/pages/download)
2. **Mainboard:** copy the `ELEGOO_UPDATE_DIR` folder onto an empty USB stick, plug it into the
   printer, and on the panel go to Settings → About Machine → down arrow → Confirm. Takes 1 to 2 minutes.
3. **Screen:** copy the `.tft` file onto the SD card that came with the printer. This one requires
   removing the back cover of the screen with a 2 mm hex key, inserting the SD, powering on, waiting
   for the update, then opening it again to remove the card.
4. Redo the bed leveling and the Z-offset.

Only then run `2-Verificar-Impressora.bat` again.

> ⚠️ The Elegoo update **can erase your `printer.cfg`** and may force leveling into Standard mode
> (6x6). If you were using **Professional Mode**, you will have to set it up again.

---

## What these files do, under the hood

For anyone who wants to check before running — nothing here is a black box:

| File | What it does |
|---|---|
| `1-Configurar-Acesso.bat` | Creates an SSH key and copies the public half to the printer |
| `2-Verificar-Impressora.bat` | Runs `scripts/verificar.sh` — read-only |
| `3-Instalar-Klipper.bat` | Runs `scripts/instalar.sh` |
| `4-Voltar-Ao-Original.bat` | Runs `scripts/reverter.sh` |
| `_comum.bat` | Asks for the IP and stores it in `ip.txt` |
| `scripts/*.sh` | The commands that actually run inside the printer |

The STM32 MCU is **never touched**. The official site describes how to update it, but the author
himself advises against it, because it requires taking the printer apart and the risk isn't worth it.

---

## Credits

All the heavy lifting — porting modern Klipper to the Neptune 4 Max — belongs to **S&M Makers**:

- Original instructions: https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html
- Repository: https://github.com/sandmmakers/klipper
- Video: https://www.youtube.com/watch?v=Aoy3sI1lv1g

This package is just a `.bat` wrapper to make life easier for people who aren't comfortable with a
terminal.

**No warranty.** Touching firmware carries risk. The rollback path exists and it works, but you are
the one standing next to the printer.
