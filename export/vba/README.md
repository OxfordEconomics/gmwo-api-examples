# GMWO API Example: Exporting data to Excel

`GMWO-Export.xlsm` brings Oxford Economics forecast data straight into Excel. You choose
which indicators, countries and dates you want, press a button, and the numbers appear on
a sheet.

You don't need anything installed — just Excel. For the same export in Python, see
[`../export.ipynb`](../export.ipynb).

Everything below is also on the **Start here** sheet inside the workbook itself, so you
can ignore this file if you'd rather work from there.

## Getting started

You need an Oxford Economics access token. Please see the [authentication section of our API
Guide](https://model.oxfordeconomics.com/api/docs/#authentication).

Then pick whichever of these two applies to you. They give you exactly the same
workbook — same code, same buttons, same results.

### Option A — the ready-made workbook

Download `GMWO-Export.xlsm`, then **before you open it**:

1. Right-click the downloaded file and choose **Properties**.
2. Tick **Unblock** at the bottom of the **General** tab, then click **OK**.

Windows marks anything downloaded from the internet, and Excel refuses to run macros in a
marked file — often with no warning bar at all, so the workbook simply does nothing and
never says why. Unblocking it is what prevents that.

Now open it. If a yellow bar appears across the top of Excel saying macros have been
blocked, click **Enable Content**. The workbook can't do anything without this.

### Option B — if your IT doesn't allow macro-enabled files

Plenty of organisations block `.xlsm` files outright. Download `GMWO-Export.xlsx` and
`GMWO-Export.bas` instead, and put the two together yourself. It takes about a minute:

1. Open `GMWO-Export.xlsx`, then **File > Save As** and choose **Excel Macro-Enabled
   Workbook (\*.xlsm)**.
2. Press **Alt+F11** to open the code editor.
3. **File > Import File…**, choose `GMWO-Export.bas`, then press **Alt+Q**.
4. Save the workbook, and click **Enable Content** if Excel asks.
5. On the **Config** sheet, press **Check this workbook**. It runs 60 internal checks and
   tells you whether everything is in place.

You don't need the Developer tab for this — **Alt+F11** works without it — and you don't
need to change any Excel settings. 

## What to do

1. **Go to the `Config` sheet** and paste your access token into the **Access token** box.
   Treat it like a password.

2. **Press `Test token`.** You should see a message saying *Your token works*. If you
   don't, nothing else will work either, so it's worth fixing first.

3. **Go to the `Selection` sheet** and pick what you want. There are two ways to do it,
   and you use **one or the other** — they're never added together.

   **Option 1 — every combination.** Fill in the three lists on the left:

   - **Indicators** — what you want to measure, for example `CPI` or `C`.
   - **Locations** — which countries or regions, for example `UK` or `GERMANY`. These
     cells have a dropdown, and only accept codes the model actually has.
   - **Transformations** — how the numbers are presented (see below).

   Add and remove rows in these lists freely. You get every indicator crossed with every
   location and every transformation.

   **Option 2 — exact combinations.** Fill in the table on the right instead, one row per
   series, if you want to say exactly which combinations you want.

   The shaded line near the top of that sheet always tells you which of the two you are
   currently going to get.

4. **Go back to the `Config` sheet and press `Run export`.**

5. **Your numbers appear on the `Data` sheet**, and are saved as a separate spreadsheet
   file too. A large request can take a minute or two, and Excel will look frozen while it
   works. That's normal — a progress message appears along the bottom of the Excel window.

## Filling in the Config sheet

Every box has a short explanation next to it. Most can be left alone.

| Box | What to put in it |
|---|---|
| API base URL | Leave exactly as it is. This box is locked, so you can't change it by accident |
| Access token | Your personal Oxford Economics model API token |
| Forecast path | Which online database to use. Check the paths under <https://model.oxfordeconomics.com/> if unsure |
| From period | The first period you want, for example `2025Q1` |
| To period | The last period you want, for example `2030Q4` |
| Value type | `Variable` or `Residual` |
| Output format | How your results are laid out — see the table below |
| Annual rollup | `TRUE` gives one number per year instead of one per quarter |
| Output folder | Where to save your resulting .csv file. Leave blank to save next to this file |

## Transformations

A transformation is how a number is presented — the actual value, or a change over time.
Pick from the dropdown:

| Code | What you get |
|---|---|
| `L` | The actual value |
| `PY` | % change compared with the same quarter a year earlier |
| `DY` | Change compared with the same quarter a year earlier |
| `GR` | Annualised % change |
| `P` | % change compared with the previous quarter |
| `D` | Change compared with the previous quarter |

You can pick more than one. Add a row for each.

## Locations

Locations are codes, not country names — `UK`, `GERMANY`, `NETH`, `EURO_11`. They're the
same codes the Model software uses.

You don't have to remember any of them. Every Location cell on the Selection sheet has a
**dropdown** listing them all, and the full list is at the bottom of the **Start here**
sheet with the country each one means, so you can look up `NETH` and find Netherlands.

Anything that isn't one of those codes is refused as you type it — a mistyped location is
otherwise only discovered when your export comes back without the numbers you asked for.
If you paste into those cells rather than typing, Excel skips the check, so it's worth a
glance afterwards.

## Output formats

This is the layout of your results. Pick one in the **Output format** box on the Config
sheet. They're all listed on the **Start here** sheet in the workbook too.

| Format | What you get |
|---|---|
| `Default` | One row per series, with various columns of detail about it. **Start with this one.** |
| `DefaultExtended` | The same as `Default`, plus a few extra columns of detail |
| `Classic_v` | One column per series, like the Model software's export |
| `Classic_h` | Like the Model software's *Vars By Row* export. This one has no heading row — the first row is already data |
| `Skinny` | Tall and narrow. Useful for loading the numbers into another system |
| `DatabankCompatible` | One row per series, matching Global Data Workstation and Excel Data Workstation |
| `DatabankCompatibleStacked` | One row per series and per period, matching those same two |

## How many series will I get?

Every indicator is combined with every location and every transformation. So:

```
2 indicators  ×  2 locations  ×  2 transformations  =  8 series
```

This adds up quickly, and bigger requests take longer. If you're not sure what you've
picked, press **Check my selections** on the Config sheet — it tells you the number
without sending anything, and which of the two blocks it came from.

That's Option 1. If you'd rather choose exact combinations than have everything crossed
with everything, fill in the **Option 2** table on the right of the Selection sheet
instead. As soon as that table has a row with both an indicator and a location in it, it's
what gets exported and the three lists on the left are ignored entirely — you never get
both.

**One thing to watch:** if you ask for the same indicator and location with two different
transformations, you get two rows that look nearly identical. The **Measurement** column is
what tells them apart — not the indicator or location columns, which will be the same on
both.

## If something doesn't work

1. **Look at the `Log` sheet.** It records every step the workbook took, with the most
   recent at the bottom. It usually says what went wrong in plain terms.

2. **Press `Check this workbook`** on the Config sheet. This makes the file test itself,
   and tells you whether the problem is the file or your settings.

3. **Still stuck?** Send the `Log` sheet to your Oxford Economics contact.

A few common ones:

| What you see | What it usually means |
|---|---|
| *Did not accept your access token* | The token is missing, or only partly pasted in. Press **Test token**. |
| *Could not find the data you asked for* | Check the **Forecast path** box |
| *Could not reach Oxford Economics* | You're offline, or a company network or VPN is blocking it |
| *Asking you to slow down* | Wait a minute and try again |
| *Nothing to export* | Add at least one indicator, one location and one transformation |
| Nothing happens when you press a button | The macros are blocked. See [Getting started](#getting-started) — the file most likely needs **Unblock**ing |

## Please keep your token private

Your access token is saved **inside this file**, and it does not stop working on its own.
Anyone who opens the file can use it.

So **before you send this file on to anyone**, press **Clear token** on the Config sheet
and save.

## The other buttons

You won't usually need these. None of them send anything to Oxford Economics, and none of
them need your token.

| Button | What it does |
|---|---|
| **Check my selections** | Tells you how many series you've picked, without sending anything |
| **Check this workbook** | Makes the file test itself. Try it when something isn't working |
| **Clear token** | Removes your token from the file. Do this, then save, before sharing it |
| **Clear data sheet** | Empties the `Data` sheet. You don't need to — the next export replaces it |
| **Clear log** | Empties the `Log` sheet if it's got long and cluttered |

## About `GMWO-Export.bas`

This is the workbook's code as a plain text file — the same code that's already inside
`GMWO-Export.xlsm`. You need it only for Option B above. It's also here to read, if you
want to see how the export endpoints are called: it uses `/operations/export` to start the
export, polls `/operations/{id}/await` until it finishes, then downloads the generated csv.
[`../export.ipynb`](../export.ipynb) does the same thing in Python, in far fewer lines.
