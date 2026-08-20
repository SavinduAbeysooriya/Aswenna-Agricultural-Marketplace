<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tax Invoice - {{ $invoiceNo }}</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
        body { background-color: #f8fafc; color: #1e293b; padding: 12px 8px; font-size: 13px; -webkit-text-size-adjust: 100%; }
        .invoice-card { max-width: 800px; width: 100%; margin: 0 auto; background: #ffffff; padding: 24px 20px; border-radius: 16px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); border: 1px solid #e2e8f0; overflow: hidden; }
        .header { display: flex; justify-content: space-between; align-items: flex-start; padding-bottom: 20px; border-bottom: 2px solid #e2e8f0; flex-wrap: wrap; gap: 16px; }
        .logo-title { font-size: 20px; font-weight: 800; color: #2e7d32; letter-spacing: -0.5px; }
        .logo-sub { font-size: 11px; color: #64748b; margin-top: 4px; }
        .badge { display: inline-block; padding: 5px 14px; border-radius: 20px; font-weight: 800; font-size: 11px; text-transform: uppercase; }
        .badge-paid { background: #e8f5e9; color: #2e7d32; border: 1px solid #c8e6c9; }
        .badge-unpaid { background: #fff8e1; color: #f57f17; border: 1px solid #ffe082; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 24px 0; }
        .info-box h3 { font-size: 10px; text-transform: uppercase; color: #94a3b8; letter-spacing: 0.8px; margin-bottom: 6px; font-weight: 700; }
        .info-box p { font-size: 13px; color: #0f172a; font-weight: 600; line-height: 1.4; word-break: break-word; }
        .table-wrapper { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; margin-top: 16px; border-radius: 8px; border: 1px solid #edf2f7; }
        .table { width: 100%; border-collapse: collapse; min-width: 480px; }
        .table th { background: #f1f5f9; color: #475569; text-align: left; padding: 10px 12px; font-size: 10px; text-transform: uppercase; letter-spacing: 0.5px; white-space: nowrap; }
        .table td { padding: 12px; border-bottom: 1px solid #edf2f7; color: #1e293b; font-weight: 500; font-size: 12px; }
        .summary-box { margin-top: 24px; margin-left: auto; width: 100%; max-width: 320px; }
        .summary-row { display: flex; justify-content: space-between; padding: 6px 0; font-size: 12px; color: #64748b; }
        .summary-row.total { border-top: 2px solid #0f172a; border-bottom: 2px solid #0f172a; padding: 10px 0; margin-top: 8px; font-size: 15px; font-weight: 800; color: #0f172a; }
        .footer { margin-top: 30px; padding-top: 16px; border-top: 1px solid #e2e8f0; text-align: center; color: #94a3b8; font-size: 10px; line-height: 1.5; }
        .print-btn { display: inline-block; margin-bottom: 16px; padding: 10px 18px; background: #2e7d32; color: #ffffff; border-radius: 8px; text-decoration: none; font-weight: bold; cursor: pointer; border: none; font-size: 12px; width: 100%; max-width: 800px; text-align: center; }

        @media (max-width: 600px) {
            body { padding: 8px 4px; }
            .invoice-card { padding: 16px 12px; border-radius: 12px; }
            .header { flex-direction: column; align-items: flex-start; gap: 10px; }
            .header-right { text-align: left !important; width: 100%; display: flex; justify-content: space-between; align-items: center; border-top: 1px dashed #e2e8f0; padding-top: 8px; }
            .info-grid { grid-template-columns: 1fr; gap: 14px; margin: 16px 0; }
            .summary-box { max-width: 100%; }
            .logo-title { font-size: 18px; }
        }

        @media print {
            .print-btn { display: none; }
            body { padding: 0; background: #ffffff; }
            .invoice-card { border: none; box-shadow: none; padding: 0; }
        }
    </style>
</head>
<body>

    <div style="max-width: 800px; margin: 0 auto; text-align: center;">
        <button onclick="window.print()" class="print-btn">🖨️ Print / Download PDF Invoice</button>
    </div>

    <div class="invoice-card">
        <div class="header">
            <div>
                <div class="logo-title">🌱 ASWENNA MARKETPLACE</div>
                <div class="logo-sub">Official Tax Invoice & Wholesale Order Receipt</div>
            </div>
            <div class="header-right" style="text-align: right;">
                <span class="badge {{ strtolower($bid->payment_status ?? 'unpaid') == 'paid' ? 'badge-paid' : 'badge-unpaid' }}">
                    {{ strtoupper($bid->payment_status ?? 'UNPAID') }}
                </span>
                <div>
                    <div style="font-size: 12px; font-weight: 800; color: #0f172a;">{{ $invoiceNo }}</div>
                    <div style="font-size: 10px; color: #64748b;">Date: {{ $invoiceDate }}</div>
                </div>
            </div>
        </div>

        <div class="info-grid">
            <div class="info-box">
                <h3>Billed To (Buyer)</h3>
                <p>{{ $bid->buyer_name ?? 'Valued Buyer' }}</p>
                <p style="font-weight: 400; color: #64748b;">Phone: {{ $bid->buyer_phone ?? 'N/A' }}</p>
                <p style="font-weight: 400; color: #64748b;">Location: {{ $bid->buyer_city ?? '' }}, {{ $bid->buyer_district ?? 'Sri Lanka' }}</p>
            </div>
            <div class="info-box">
                <h3>Supplier Details (Farmer)</h3>
                <p>{{ $bid->farmer_name ?? 'Farmer Supplier' }}</p>
                <p style="font-weight: 400; color: #64748b;">Phone: {{ $bid->farmer_phone ?? 'N/A' }}</p>
                <p style="font-weight: 400; color: #64748b;">District: {{ $bid->farmer_district ?? 'Sri Lanka' }}</p>
            </div>
        </div>

        <div class="table-wrapper">
            <table class="table">
                <thead>
                    <tr>
                        <th>Item Description</th>
                        <th>Quantity</th>
                        <th>Unit Rate</th>
                        <th style="text-align: right;">Amount (LKR)</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>
                            <strong style="font-size: 14px; color: #0f172a;">{{ $bid->cropname }}</strong>
                            <div style="font-size: 10px; color: #64748b; margin-top: 2px;">Direct Farm Bulk Purchase (Grade A)</div>
                        </td>
                        <td style="white-space: nowrap;">{{ number_format($qty, 2) }} {{ $bid->unit ?? 'kg' }}</td>
                        <td style="white-space: nowrap;">LKR {{ number_format($unitPrice, 2) }}/{{ $bid->unit ?? 'kg' }}</td>
                        <td style="text-align: right; font-weight: 700; white-space: nowrap;">LKR {{ number_format($subtotal, 2) }}</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="summary-box">
            <div class="summary-row">
                <span>Subtotal:</span>
                <span>LKR {{ number_format($subtotal, 2) }}</span>
            </div>
            <div class="summary-row">
                <span>Platform Service Fee (1%):</span>
                <span>LKR {{ number_format($platformFee, 2) }}</span>
            </div>
            <div class="summary-row">
                <span>VAT / Agricultural Tax (0%):</span>
                <span>LKR 0.00</span>
            </div>
            <div class="summary-row total">
                <span>Total Paid:</span>
                <span style="color: #2e7d32;">LKR {{ number_format($grandTotal, 2) }}</span>
            </div>
        </div>

        @if(!empty($bid->payment_reference))
        <div style="margin-top: 24px; padding: 12px; background: #f8fafc; border-radius: 8px; font-size: 11px; color: #475569; word-break: break-all;">
            <strong>Payment Reference:</strong> {{ $bid->payment_reference }} | <strong>Method:</strong> {{ strtoupper($bid->payment_method ?? 'PayHere Gateway') }}
        </div>
        @endif

        <div class="footer">
            Thank you for supporting Sri Lankan farmers through Aswenna Agricultural Marketplace.<br>
            Computer-generated official tax receipt • Valid without signature.
        </div>
    </div>

</body>
</html>
