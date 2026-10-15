# Arjun Traders - Vehicle Sale Report & Trip Sheet Web App

Mobile-first web application for **Arjun Traders**, a beverage distribution business. It replaces the traditional paper "Vehicle Sale Report" trip sheet used by delivery autos.

## Features

- **Single-File Architecture**: Built completely in [`index.html`](index.html) with zero build steps or bundlers.
- **Supabase Backend**: Connected via official Supabase JS v2 CDN.
  - Profiles & Role-based Access (`owner` vs `staff`).
  - Auto-saved trip sheets, load lines, return lines, cash notes, credit dues, and payments.
- **Mobile-First & Senior-Friendly UI**:
  - High-contrast dark theme.
  - 18px+ base font with large, clear numbers and buttons.
- **Interactive Keypad & Batch Calculation**:
  - 3-column phone keypad for rapid entry.
  - Built-in batch addition (e.g. `40+8 = 48`).
- **Live Search & Quick Add**:
  - Instant product filtering on trip sheet.
  - Quick `+` button to add new beverages on the fly.
- **Menu & Predefined Rates**:
  - Case-wise (₹/case) and unit-wise (₹/bottle) rates.
  - Live bidirectional rate calculation.
  - Category filters (`150ml`, `200ml`, `500/600ml`, `1Lt`, `Tins`, `2.5Lt`, `Water`).
- **Cash & Settlement Audit**:
  - Note counts by denomination (₹500, ₹200, ₹100, ₹50, ₹20, ₹10, and change).
  - PhonePe UPI tracking.
  - Credit tracking per shop with ledger history.
  - Auto discrepancy alerts (**Matched**, **Short by ₹X**, **Extra ₹X**).
- **Camera Scan with OCR**:
  - Scan paper trip sheets with mobile camera.
  - In-browser image compression before OCR processing via Supabase Edge Functions.
  - Verification review screen with tap-to-zoom and uncertain line warnings.
- **Reports**:
  - Date-filtered distribution reports across all delivery autos.

## Local Testing

Open `index.html` directly in any web browser, or run a local static server:
```bash
python -m http.server 8080
```
Then visit `http://localhost:8080` in your browser.

## Deployment to Netlify

1. Go to [Netlify](https://app.netlify.com/).
2. Drag and drop this folder directly onto the Netlify dashboard.
3. Your site will be live on an HTTPS domain within seconds.
