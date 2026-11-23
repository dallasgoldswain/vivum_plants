---
id: stock-import
title: Importing stock from a file
summary: Add many stock items at once from a CSV or Excel file, check the preview, and undo an import if you need to.
audience: seller
capabilities: [seller.csv_import]
prerequisites: [stock]
keywords: [import, csv, excel, xlsx, spreadsheet, upload, template, bulk, sku, preview, reverse, undo]
reviewed: 2026-11-23
reviewed_digest: 359682a4ed69b9a17abae86e45a9084a213759cfeba041b47f642631bad6e2c3
---

Owners and managers can add stock from a spreadsheet instead of one item at a
time. Go to **Sell → Stock** and choose **Import**.

## The file

Use a CSV saved as UTF-8 or an Excel .xlsx file, up to 2 MB and 2,000 rows.
**Download the template** to start from the right headings:

- **Name**, **Type** and **Quantity** are required. Type is `specimen` (one
  unique plant) or `batch` (identical plants). A specimen's quantity is always 1.
- **SKU** is optional. Leave it blank and VIVUM gives the item the next code,
  like S-0012.
- **Cultivar**, **Price** (in rands), **Location**, **Botanical name**, **Size**,
  **Cost** and **Notes** are optional.

Headings can be in any order and any case. A **Location** must match one of your
locations by name; add new ones under **Locations** first. Rows without a
location go to the location you choose when you upload.

## Preview first

Uploading changes nothing. The preview shows every row as **New**, **Add
stock** or **Problem**. Problems include a missing name, a quantity that isn't a
whole number, a price that isn't an amount, a SKU that appears twice in the
file, and a location you don't have. **Download the problems** to get them as
a CSV, fix the file and upload it again. A file with any problem can't be
imported.

A preview stays for 24 hours, then expires.

## SKUs you already have

A row with a SKU that's already in your stock is a problem, unless you tick
**Add to existing** when you upload. Then the row's quantity is received as new
stock on that item. Nothing else about the item changes: if the file has a
different name or price, the preview tells you and leaves the item as it is.

## Importing

Choose **Import** on the preview. Everything goes in together, or nothing does.
VIVUM checks every row again first, in case your stock changed since the
preview. Each import gets a number, like I-0001, and its received stock shows in
each item's history as "Import I-0001". Pressing the button twice imports once.
If you upload a file you've already imported, you need to tick a box to import
it again.

## Reversing an import

If an import was a mistake, open it under **Imports** and choose **Reverse**.
This takes every imported plant back out of stock, recorded as lost with the
reason "Import I-0001 reversed", and archives the items the import created.

You can only reverse an import while all of its plants are still available
where they arrived. If any has been held, sold or moved, nothing is reversed and
VIVUM lists which items are in the way. Fix those by hand instead.
