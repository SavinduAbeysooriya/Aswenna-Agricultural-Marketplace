<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class InvoiceController extends Controller
{
    /**
     * Generate & render official itemized Tax Invoice / Receipt HTML/PDF for an order.
     * GET /api/buyer/orders/{id}/invoice
     */
    public function downloadInvoice(Request $request, $id)
    {
        $user = $request->user();
        if (!$user && $request->has('token')) {
            $tokenStr = $request->input('token');
            $pat = \Laravel\Sanctum\PersonalAccessToken::findToken($tokenStr);
            if ($pat) {
                $user = $pat->tokenable;
            }
        }

        $query = DB::table('confirmed_bids')
            ->leftJoin('harvest_bids', 'confirmed_bids.bid_id', '=', 'harvest_bids.id')
            ->leftJoin('harvest_listings', 'confirmed_bids.harvest_listing_id', '=', 'harvest_listings.id')
            ->leftJoin('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->leftJoin('users as farmers', 'confirmed_bids.farmer_id', '=', 'farmers.id')
            ->leftJoin('users as buyers', 'confirmed_bids.buyer_id', '=', 'buyers.id')
            ->leftJoin('confirmed_bids_payments', 'confirmed_bids.id', '=', 'confirmed_bids_payments.confirmed_bid_id')
            ->where('confirmed_bids.id', $id);

        if ($user) {
            $query->where(function ($q) use ($user) {
                $q->where('confirmed_bids.buyer_id', $user->id)
                  ->orWhere('confirmed_bids.farmer_id', $user->id);
            });
        }

        $bid = $query->select(
            'confirmed_bids.*',
            'harvest_bids.bid_amount_per_unit',
            'harvest_bids.bid_quantity_unit',
            'harvest_listings.unit',
            'crops.cropname',
            'farmers.full_name as farmer_name',
            'farmers.phone_number as farmer_phone',
            'farmers.city as farmer_city',
            'farmers.district as farmer_district',
            'buyers.full_name as buyer_name',
            'buyers.phone_number as buyer_phone',
            'buyers.email as buyer_email',
            'buyers.city as buyer_city',
            'buyers.district as buyer_district',
            'confirmed_bids_payments.payment_id as payment_reference',
            'confirmed_bids_payments.created_at as paid_at'
        )->first();

        if (!$bid) {
            return response()->json([
                'success' => false,
                'message' => 'Invoice record not found or unauthorized access.',
            ], 404);
        }

        $qty = (float) ($bid->bid_quantity_unit ?? 0);
        $unitPrice = (float) ($bid->bid_amount_per_unit ?? 0);
        $subtotal = $qty * $unitPrice;
        $platformFee = round($subtotal * 0.01, 2); // 1% platform fee
        $vatTax = 0.00; // Agricultural produce exempted
        $grandTotal = $subtotal + $platformFee;

        $invoiceNo = 'INV-' . date('Y', strtotime($bid->created_at)) . '-' . str_pad($bid->id, 5, '0', STR_PAD_LEFT);
        $invoiceDate = date('d M Y, h:i A', strtotime($bid->created_at));

        $html = view('invoice', compact(
            'bid', 'qty', 'unitPrice', 'subtotal', 'platformFee',
            'vatTax', 'grandTotal', 'invoiceNo', 'invoiceDate'
        ))->render();

        return response($html, 200)
            ->header('Content-Type', 'text/html; charset=UTF-8');
    }

    /**
     * Export Monthly Purchase History Summary PDF / HTML.
     * GET /api/buyer/purchases/export-pdf
     */
    public function exportMonthlyPurchases(Request $request)
    {
        $user = $request->user();
        if (!$user && $request->has('token')) {
            $tokenStr = $request->input('token');
            $pat = \Laravel\Sanctum\PersonalAccessToken::findToken($tokenStr);
            if ($pat) {
                $user = $pat->tokenable;
            }
        }
        if (!$user) {
            $user = DB::table('users')->where('role', 'buyer')->first();
        }
        $userId = $user ? $user->id : 0;

        $month = $request->input('month', 'current');

        $query = DB::table('confirmed_bids')
            ->leftJoin('harvest_bids', 'confirmed_bids.bid_id', '=', 'harvest_bids.id')
            ->leftJoin('harvest_listings', 'confirmed_bids.harvest_listing_id', '=', 'harvest_listings.id')
            ->leftJoin('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->leftJoin('users as farmers', 'confirmed_bids.farmer_id', '=', 'farmers.id');

        if ($userId > 0) {
            $query->where('confirmed_bids.buyer_id', $userId);
        }

        if ($month === 'current') {
            $query->whereMonth('confirmed_bids.created_at', Carbon::now()->month)
                  ->whereYear('confirmed_bids.created_at', Carbon::now()->year);
        }

        $purchases = $query->select(
            'confirmed_bids.*',
            'harvest_bids.bid_amount_per_unit',
            'harvest_bids.bid_quantity_unit',
            'harvest_listings.unit',
            'crops.cropname',
            'farmers.full_name as farmer_name'
        )->orderByDesc('confirmed_bids.created_at')->get();

        $totalSpent = $purchases->sum('total_amount');
        $totalVolume = $purchases->sum('bid_quantity_unit');
        $totalOrders = $purchases->count();
        $reportDate = Carbon::now()->format('F Y');

        $html = view('purchases_report', compact(
            'user', 'purchases', 'totalSpent', 'totalVolume', 'totalOrders', 'reportDate', 'month'
        ))->render();

        return response($html, 200)
            ->header('Content-Type', 'text/html; charset=UTF-8');
    }
}
