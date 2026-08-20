<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Monthly Purchase Report - {{ $reportDate }}</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
        body { background-color: #f8fafc; color: #1e293b; padding: 12px 8px; font-size: 13px; -webkit-text-size-adjust: 100%; }
        .report-card { max-width: 900px; width: 100%; margin: 0 auto; background: #ffffff; padding: 24px 20px; border-radius: 16px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); border: 1px solid #e2e8f0; overflow: hidden; }
        .header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 16px; border-bottom: 2px solid #2e7d32; flex-wrap: wrap; gap: 12px; }
        .title { font-size: 20px; font-weight: 800; color: #2e7d32; letter-spacing: -0.5px; }
        .subtitle { font-size: 11px; color: #64748b; margin-top: 4px; }
        .kpi-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin: 20px 0; }
        .kpi-card { background: #f8fafc; border: 1px solid #e2e8f0; padding: 14px; border-radius: 12px; }
        .kpi-title { font-size: 9px; font-weight: 800; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.5px; }
        .kpi-value { font-size: 17px; font-weight: 900; color: #0f172a; margin-top: 4px; word-break: break-word; }
        .table-wrapper { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; margin-top: 16px; border-radius: 8px; border: 1px solid #edf2f7; }
        .table { width: 100%; border-collapse: collapse; min-width: 520px; }
        .table th { background: #f1f5f9; color: #475569; text-align: left; padding: 10px 12px; font-size: 10px; text-transform: uppercase; white-space: nowrap; }
        .table td { padding: 10px 12px; border-bottom: 1px solid #edf2f7; font-size: 12px; }
        .print-btn { display: inline-block; margin-bottom: 16px; padding: 10px 18px; background: #2e7d32; color: #ffffff; border-radius: 8px; font-weight: bold; cursor: pointer; border: none; font-size: 12px; width: 100%; max-width: 900px; text-align: center; }

        @media (max-width: 600px) {
            body { padding: 8px 4px; }
            .report-card { padding: 16px 12px; border-radius: 12px; }
            .header { flex-direction: column; align-items: flex-start; gap: 8px; }
            .header-right { width: 100%; text-align: left !important; border-top: 1px dashed #e2e8f0; padding-top: 8px; }
            .kpi-grid { grid-template-columns: 1fr; gap: 10px; }
            .title { font-size: 18px; }
        }

        @media print {
            .print-btn { display: none; }
            body { padding: 0; }
            .report-card { border: none; box-shadow: none; padding: 0; }
        }
    </style>
</head>
<body>

    <div style="max-width: 900px; margin: 0 auto; text-align: center;">
        <button onclick="window.print()" class="print-btn">🖨️ Export / Print PDF Summary Report</button>
    </div>

    <div class="report-card">
        <div class="header">
            <div>
                <div class="title">🌱 ASWENNA MARKETPLACE</div>
                <div class="subtitle">Monthly Purchase History & Expenditure Summary Report</div>
            </div>
            <div class="header-right" style="text-align: right;">
                <div style="font-size: 15px; font-weight: 800; color: #0f172a;">{{ $reportDate }}</div>
                <div style="font-size: 11px; color: #64748b;">Generated for: {{ $user->full_name ?? 'Valued Buyer' }}</div>
            </div>
        </div>

        <div class="kpi-grid">
            <div class="kpi-card">
                <div class="kpi-title">Total Orders</div>
                <div class="kpi-value">{{ $totalOrders }}</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-title">Total Volume Purchased</div>
                <div class="kpi-value">{{ number_format($totalVolume, 2) }} kg</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-title">Total Expenditure</div>
                <div class="kpi-value" style="color: #2e7d32;">LKR {{ number_format($totalSpent, 2) }}</div>
            </div>
        </div>

        <h3 style="font-size: 13px; font-weight: 800; color: #0f172a; margin-top: 20px;">Itemized Purchase History</h3>

        <div class="table-wrapper">
            <table class="table">
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Crop</th>
                        <th>Farmer</th>
                        <th>Quantity</th>
                        <th>Rate</th>
                        <th style="text-align: right;">Total Amount</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($purchases as $p)
                    <tr>
                        <td style="white-space: nowrap;">{{ date('d M Y', strtotime($p->created_at)) }}</td>
                        <td><strong>{{ $p->cropname }}</strong></td>
                        <td>{{ $p->farmer_name }}</td>
                        <td style="white-space: nowrap;">{{ number_format($p->bid_quantity_unit, 2) }} {{ $p->unit ?? 'kg' }}</td>
                        <td style="white-space: nowrap;">LKR {{ number_format($p->bid_amount_per_unit, 2) }}/{{ $p->unit ?? 'kg' }}</td>
                        <td style="text-align: right; font-weight: 700; white-space: nowrap;">LKR {{ number_format($p->total_amount, 2) }}</td>
                        <td>
                            <span style="font-weight: 800; color: {{ strtolower($p->payment_status ?? '') == 'paid' ? '#2e7d32' : '#f57f17' }};">
                                {{ strtoupper($p->payment_status ?? 'UNPAID') }}
                            </span>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>

        <div style="margin-top: 30px; text-align: center; color: #94a3b8; font-size: 10px;">
            Official Monthly Purchase Summary Report • Aswenna Agricultural Marketplace
        </div>
    </div>

</body>
</html>
