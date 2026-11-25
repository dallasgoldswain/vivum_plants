---
id: sale-sessions
title: Live sales and auctions
summary: Run a WhatsApp group auction in a session, capture each lot's winner in Host View, and offer a missed payment to the backup bidder.
audience: seller
capabilities: [sales.sessions, sales.auctions, sales.backup_bidder]
prerequisites: [stock-holds, buyers]
keywords: [session, auction, live sale, lot, bid, winner, host, host view, pass, backup bidder, backup, payment deadline, relist, whatsapp group]
reviewed: 2026-11-25
reviewed_digest: eed825e71fd8ae583c5afedc4a446261343ed5848d323efe9dc00eb1b79127ed
---

Bidding stays in your WhatsApp group. A session is where you record what
happens: which plants go up, who won them and for how much. Go to
**Sell → Sessions** and choose **New session**.

## Setting up a session

Give the session a name, and optionally the group it runs in and who's hosting.
Two timings are required before it can go live, and there's no default:

- **Payment deadline**: how many hours a winner has to pay, counted from when
  they win.
- **Backup window**: how many more hours the plant stays held after a missed
  payment, so you can offer it to the backup bidder.

Your next session starts with the timings you used last.

Add **lots** in the order you'll run them. A lot is one plant from stock and a
quantity: a specimen is always 1, and a batch lot can be several plants sold
together. You can add more lots while the session is live.

Choose **Go live** when you start. **Pause** stops new lots and claims; a lot
that's already open can still be finished. **Close session** once no lot is
open. Lots that never opened stay in stock.

## Host View

Host View is the screen for running the sale from your phone. Owners and
managers can open it for any session; a host/packer can open it for the
sessions they host.

- **Open** the next lot. Its plants are held while people bid, so nobody else
  can claim them.
- When bidding ends, choose the **winner** (a buyer, an alias, or type the name
  they use in the group) and enter the **winning bid**. Add a **backup bidder**
  and their bid if there was one. Choose **Won**.
- Or choose **Pass** if it didn't sell. The plants are available again.

A new name you type becomes an alias in the session's group, and the same name
typed again is the same alias. Link it to a buyer under **Buyers** when you know
who it is.

Hosts see the bids and claim prices for their session, but not costs, other
prices, orders or buyer contact details.

## After a win

The plants are held for the winner until the payment deadline. Closeout, coming
soon, turns each buyer's wins into one order.

If the deadline passes without payment, the lot shows **Payment missed** and
stays held through the backup window. On the session page, choose:

- **Offer to backup**: the backup bidder gets the plant at their bid, with a new
  payment deadline. The original winner and price stay in the history.
- **Relist**: the plant goes back up as a new lot in the session.
- **Return to stock**: the hold ends and the plant is available again.

If you do nothing by the end of the backup window, the plant returns to stock by
itself.

**Download results** on the Sessions page gives every lot and claim as a CSV.
