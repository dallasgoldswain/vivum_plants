---
id: closeout
title: Sale Closeout
summary: Turn a live session's wins and claims into one order per buyer, link unknown names, and handle missed payments.
audience: seller
capabilities: [seller.closeout, sales.sessions, seller.orders]
prerequisites: [sale-sessions]
keywords: [closeout, close out, orders from a sale, unresolved, alias, awaiting payment, backup, split order, cancel line, export]
reviewed: 2026-11-26
reviewed_digest: 58766e8836e33788040e61f3259957725ab2baf5846c0574f7e47b2052690c95
---

Closeout gathers everything won or claimed in a live session and puts each buyer's
plants on one order, without typing anything again. Open it from the session page
with **Closeout**. Owners and managers use it; host/packers can't.

## Creating orders

Choose **Create orders**. Each buyer gets one reserved order for the session, with a
line for every lot they won and every claim held for them, at the winning bid or
claim price. You can choose it again at any time, during or after the session:
only results that aren't on an order yet are added, never twice.

The plants stay on the hold they already had, so the payment deadline and backup
window don't change. Recording a payment on the order keeps the hold from running
out, as for any order.

A lot with several plants needs a bid that splits evenly into a price each, so
Host View asks for an amount such as R99.99 rather than R100 over three.

## Unresolved names

An order needs a buyer, so results for a name typed in Host View wait under
**Unresolved** until that name is linked. Link it to an existing buyer, or add a
new buyer with their phone number. Names that look the same are never linked for
you. Once linked, choose **Create orders** again.

## The views

- **Awaiting payment:** unpaid and part-paid orders, and results not on an order yet.
- **Expiring:** holds ending within 24 hours.
- **Backup offers:** wins with a missed payment and a backup bidder still in the backup window.
- **Ready to pack:** paid orders still reserved.
- **Completed:** orders collected or shipped.

Each order shows its plants, prices, subtotal, payment state and when its hold
ends, with **Copy link** for the order page. **Download CSV** exports the view
you're on.

## Missed payments and the backup

Under **Backup offers**, **Move to backup** cancels the winner's line with the
reason "Payment missed" and holds the plant for the backup bidder at their bid,
with a new deadline. If the backup already has an order for the session, the
line joins it; otherwise choose **Create orders**.

## Changing an unpaid order

On an order with no payments you can **Cancel line**, with a reason, which puts
the plant back in stock, or **Split order** to move some lines to a new order for
the same buyer. Each change keeps the previous total, the new total and the reason
in the order's history. Once an order has a payment, use refunds and returns on
the order instead.
