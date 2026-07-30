# Powershell

*The Return of the Shell*

A personal collection of PowerShell scripts and tools, mostly written for day-to-day Windows/AD sysadmin work — Active Directory management, reporting, maintenance, and assorted utilities.

## 🔎 Script Vault

Browse every script — searchable, filterable by category, with the full source viewable inline — at:

**[get-nout.github.io/Powershell/script_vault.html](https://get-nout.github.io/Powershell/script_vault.html)**

The vault is generated from this repo, so it's always in sync with what's checked in here.

## Layout

Scripts are grouped by category:

| Folder | What's in it | Count |
|---|---|---|
| [`AD/`](AD) | Active Directory user, group, GPO, and OU management | 20 |
| [`Commandlets/`](Commandlets) | General-purpose utilities and one-offs | 15 |
| [`Reporting/`](Reporting) | System/network reporting and checks | 10 |
| [`Maintenance/`](Maintenance) | Reboots, cleanup, and upkeep scripts | 3 |
| [`SQL/`](SQL) | SQL Server helper scripts | 2 |
| [`Hyper-V/`](Hyper-V) | Hyper-V VM inspection | 1 |

Most scripts carry a `Creator:` line or a `.NOTES` block crediting who actually wrote them — a few were adapted from other authors in the PowerShell community, and that's noted directly in the script rather than claimed as original work.

## Usage

These are personal/example scripts — most have placeholder values (domains, server names, usernames) near the top that need editing before running against a real environment. Read a script before running it.

## Regenerating the vault

If you add, move, or re-document a script, regenerate `script_vault.html` so it picks up the change:

```powershell
python tools/build_vault.py
```

## License

[GPLv3](LICENSE)
