<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ConfirmedBid;
use App\Models\ConfirmedBidPayment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use Exception;

class PaymentController extends Controller
{
    // Statically hardcoded sandbox credentials
    private string $merchantId     = '1236086';
    private string $merchantSecret = 'MjcwOTkzNTQ3Njk2NTU0MTIwNjQ4OTgwMzA0NjI4NDI0NzE4Njk='; 
    private bool   $sandbox        = true;

    /**
     * Decode merchant secret safely.
     */
    private function getDecodedSecret(): string
    {
        return base64_decode($this->merchantSecret);
    }

    /**
     * POST /api/buyer/confirmed-bids/{confirmedBidId}/initiate-payment
     * Returns PayHere payment parameters including signed hash, adding 2% service charge and 1.5% tax.
     */
    public function initiatePayment(Request $request, $confirmedBidId)
    {
        $user = $request->user();

        $confirmedBid = DB::table('confirmed_bids')
            ->leftJoin('harvest_bids', 'confirmed_bids.bid_id', '=', 'harvest_bids.id')
            ->leftJoin('harvest_listings', 'confirmed_bids.harvest_listing_id', '=', 'harvest_listings.id')
            ->leftJoin('crops', 'harvest_listings.crop_id', '=', 'crops.id')
            ->leftJoin('users as farmers', 'confirmed_bids.farmer_id', '=', 'farmers.id')
            ->where('confirmed_bids.id', $confirmedBidId)
            ->where('confirmed_bids.buyer_id', $user->id)
            ->select(
                'confirmed_bids.*',
                'harvest_bids.bid_amount_per_unit',
                'harvest_bids.bid_quantity_unit',
                'harvest_listings.unit',
                'crops.cropname',
                'farmers.full_name as farmer_name'
            )
            ->first();

        if (!$confirmedBid) {
            return response()->json(['success' => false, 'message' => 'Confirmed bid not found.'], 404);
        }

        if ($confirmedBid->payment_status === 'paid') {
            return response()->json(['success' => false, 'message' => 'This order has already been paid.'], 400);
        }

        // Calculate custom service charges and taxes
        $baseAmount    = (float)$confirmedBid->total_amount;
        $serviceCharge = round($baseAmount * 0.02, 2); // 2% service charge
        $tax           = round($baseAmount * 0.015, 2); // 1.5% tax
        $finalAmount   = $baseAmount + $serviceCharge + $tax;

        $orderId       = 'ASWENNA-' . $confirmedBidId . '-' . time();
        $amount        = number_format((float)$finalAmount, 2, '.', '');
        $currency      = 'LKR';
        $itemName      = $confirmedBid->cropname . ' (' . $confirmedBid->bid_quantity_unit . ' ' . $confirmedBid->unit . ')';
        $returnUrl     = url('/api/payment/return');
        $cancelUrl     = url('/api/payment/cancel');
        $notifyUrl     = url('/api/payment/notify');
        
        // PayHere Sandbox requires a public secure HTTPS notify_url to process the transaction request
        if (str_contains($notifyUrl, 'localhost') || str_contains($notifyUrl, '127.0.0.1') || str_contains($notifyUrl, '10.0.2.2') || !str_starts_with($notifyUrl, 'https')) {
            $notifyUrl = 'https://aswenna.lk/api/payment/notify';
        }

        // Generate hash per PayHere spec: MD5(merchant_id + order_id + amount + currency + MD5(merchant_secret))
        $hashedSecret  = strtoupper(md5($this->getDecodedSecret()));
        $hash          = strtoupper(md5(
            $this->merchantId . $orderId . $amount . $currency . $hashedSecret
        ));

        $names     = explode(' ', trim($user->full_name), 2);
        $firstName = $names[0] ?? 'Buyer';
        $lastName  = $names[1] ?? 'Aswenna';

        $paymentParams = [
            'sandbox'       => $this->sandbox,
            'merchant_id'   => $this->merchantId,
            'return_url'    => $returnUrl,
            'cancel_url'    => $cancelUrl,
            'notify_url'    => $notifyUrl,
            'order_id'      => $orderId,
            'items'         => $itemName,
            'amount'        => $amount,
            'currency'      => $currency,
            'first_name'    => $firstName,
            'last_name'     => $lastName,
            'email'         => $user->email ?? 'buyer@aswenna.lk',
            'phone'         => $user->phone_number ?? '0771234567',
            'address'       => $user->address ?? 'Sri Lanka',
            'city'          => $user->city ?? 'Colombo',
            'country'       => 'Sri Lanka',
            'hash'          => $hash,
            'confirmed_bid_id' => $confirmedBidId,
        ];

        return response()->json([
            'success'        => true,
            'payment_params' => $paymentParams,
            'pricing_breakdown' => [
                'base_amount' => $baseAmount,
                'service_charge' => $serviceCharge,
                'tax' => $tax,
                'final_amount' => $finalAmount,
            ]
        ], 200);
    }

    /**
     * POST /api/payment/notify  (unauthenticated - called by PayHere server)
     * Verifies PayHere notification, updates payment status, handles 5% commission, taxes, and processes wallets.
     */
    public function notifyPayment(Request $request)
    {
        $merchantId    = $request->merchant_id;
        $orderId       = $request->order_id;
        $paymentId     = $request->payment_id;
        $payheStatus   = $request->status_code;
        $currency      = $request->currency;
        $amount        = $request->payhere_amount;
        $payhereMd5sig = $request->md5sig;

        // Verify hash
        $hashedSecret = strtoupper(md5($this->getDecodedSecret()));
        $localMd5Sig  = strtoupper(md5($merchantId . $orderId . $amount . $currency . $payheStatus . $hashedSecret));

        if ($localMd5Sig !== $payhereMd5sig) {
            return response('INVALID_HASH', 400);
        }

        if ($payheStatus == 2) { // 2 = success
            // Extract confirmedBidId from orderId (ASWENNA-{id}-{timestamp})
            preg_match('/ASWENNA-(\d+)-/', $orderId, $matches);
            $confirmedBidId = $matches[1] ?? null;

            if ($confirmedBidId) {
                DB::beginTransaction();
                try {
                    $confirmedBid = ConfirmedBid::find($confirmedBidId);
                    if ($confirmedBid && $confirmedBid->payment_status === 'unpaid') {
                        $confirmedBid->update(['payment_status' => 'paid']);

                        // Record payment with commission & tax breakdowns
                        $baseAmount       = (float)$confirmedBid->total_amount;
                        $serviceCharge    = round($baseAmount * 0.02, 2); // 2% service charge added to buyer
                        $tax              = round($baseAmount * 0.015, 2); // 1.5% tax added to buyer
                        $totalPaid        = $baseAmount + $serviceCharge + $tax;

                        $commission       = round($baseAmount * 0.05, 2); // 5% platform commission from farmer
                        $farmerAmount     = round($baseAmount - $commission, 2);

                        DB::table('confirmed_bids_payments')->insert([
                            'buyer_id'          => $confirmedBid->buyer_id,
                            'farmer_id'         => $confirmedBid->farmer_id,
                            'confirmed_bid_id'  => $confirmedBid->id,
                            'total_amount'      => $totalPaid,
                            'system_commission' => $commission,
                            'farmer_amount'     => $farmerAmount,
                            'payment_id'        => $paymentId,
                            'date_and_time'     => Carbon::now(),
                            'payment_status'    => 'paid',
                            'created_at'        => now(),
                            'updated_at'        => now(),
                        ]);

                        // ─── 1. Update Farmer Wallet ───
                        $farmerWallet = DB::table('user_wallets')->where('user_id', $confirmedBid->farmer_id)->first();
                        if ($farmerWallet) {
                            $farmerBefore = (float)$farmerWallet->available_balance;
                            $farmerAfter  = $farmerBefore + $farmerAmount;
                            $farmerTotalEarned = (float)$farmerWallet->total_earned + $farmerAmount;

                            DB::table('user_wallets')
                                ->where('user_id', $confirmedBid->farmer_id)
                                ->update([
                                    'available_balance' => $farmerAfter,
                                    'total_earned' => $farmerTotalEarned,
                                    'last_updated_at' => now(),
                                    'updated_at' => now(),
                                ]);
                        } else {
                            $farmerBefore = 0.00;
                            $farmerAfter  = $farmerAmount;
                            DB::table('user_wallets')->insert([
                                'user_id' => $confirmedBid->farmer_id,
                                'available_balance' => $farmerAfter,
                                'pending_balance' => 0.00,
                                'total_earned' => $farmerAfter,
                                'total_withdrawn' => 0.00,
                                'last_updated_at' => now(),
                                'created_at' => now(),
                                'updated_at' => now(),
                            ]);
                        }

                        // Record Farmer Earnings Transaction
                        DB::table('wallet_transactions')->insert([
                            'user_id' => $confirmedBid->farmer_id,
                            'amount' => $farmerAmount,
                            'balance_before' => $farmerBefore,
                            'balance_after' => $farmerAfter,
                            'transaction_type' => 'other',
                            'description' => "Earnings for Order #ASWENNA-{$confirmedBidId} (Base: LKR {$baseAmount}, 5% System Commission: -LKR {$commission} deducted)",
                            'status' => 'completed',
                            'record_created_at' => now(),
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);

                        // ─── 2. Update Buyer Wallet ───
                        $buyerWallet = DB::table('user_wallets')->where('user_id', $confirmedBid->buyer_id)->first();
                        if ($buyerWallet) {
                            $buyerBefore = (float)$buyerWallet->available_balance;
                            $buyerAfter  = $buyerBefore; // External card payment doesn't decrease wallet deposit balance
                        } else {
                            $buyerBefore = 0.00;
                            $buyerAfter  = 0.00;
                            DB::table('user_wallets')->insert([
                                'user_id' => $confirmedBid->buyer_id,
                                'available_balance' => 0.00,
                                'pending_balance' => 0.00,
                                'total_earned' => 0.00,
                                'total_withdrawn' => 0.00,
                                'last_updated_at' => now(),
                                'created_at' => now(),
                                'updated_at' => now(),
                            ]);
                        }

                        // Record Buyer Expense Transaction
                        DB::table('wallet_transactions')->insert([
                            'user_id' => $confirmedBid->buyer_id,
                            'amount' => -$totalPaid,
                            'balance_before' => $buyerBefore,
                            'balance_after' => $buyerAfter,
                            'transaction_type' => 'other',
                            'description' => "Payment for Order #ASWENNA-{$confirmedBidId} (Base: LKR {$baseAmount}, Service Charge (2%): LKR {$serviceCharge}, Tax (1.5%): LKR {$tax})",
                            'status' => 'completed',
                            'record_created_at' => now(),
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                    }
                    DB::commit();
                } catch (Exception $e) {
                    DB::rollBack();
                    logger()->error('NotifyPayment processing failed: ' . $e->getMessage());
                }
            }
        }

        return response('OK', 200);
    }

    /**
     * POST /api/payment/debug-simulate-success
     * Direct simulator for local debugging to bypass lack of external public webhook connectivity in local sandbox.
     */
    public function debugSimulateSuccess(Request $request)
    {
        $confirmedBidId = $request->input('confirmed_bid_id') ?? $request->confirmed_bid_id;
        $paymentId = $request->input('payment_id') ?? 'DEBUG-' . uniqid();

        if (!$confirmedBidId) {
            return response()->json(['success' => false, 'message' => 'Confirmed Bid ID is required.'], 400);
        }

        DB::beginTransaction();
        try {
            $confirmedBid = ConfirmedBid::find($confirmedBidId);
            if (!$confirmedBid) {
                return response()->json(['success' => false, 'message' => 'Confirmed bid not found.'], 404);
            }

            if ($confirmedBid->payment_status === 'paid') {
                return response()->json(['success' => true, 'message' => 'Payment already completed previously.', 'already_paid' => true], 200);
            }

            $confirmedBid->update(['payment_status' => 'paid']);

            // Record payment with commission & tax breakdowns
            $baseAmount       = (float)$confirmedBid->total_amount;
            $serviceCharge    = round($baseAmount * 0.02, 2); // 2% service charge added to buyer
            $tax              = round($baseAmount * 0.015, 2); // 1.5% tax added to buyer
            $totalPaid        = $baseAmount + $serviceCharge + $tax;

            $commission       = round($baseAmount * 0.05, 2); // 5% platform commission from farmer
            $farmerAmount     = round($baseAmount - $commission, 2);

            // 1. Insert/Update confirmed_bids_payments
            DB::table('confirmed_bids_payments')->updateOrInsert(
                ['confirmed_bid_id' => $confirmedBid->id],
                [
                    'buyer_id'          => $confirmedBid->buyer_id,
                    'farmer_id'         => $confirmedBid->farmer_id,
                    'total_amount'      => $totalPaid,
                    'system_commission' => $commission,
                    'farmer_amount'     => $farmerAmount,
                    'payment_id'        => $paymentId,
                    'date_and_time'     => Carbon::now(),
                    'payment_status'    => 'paid',
                    'created_at'        => now(),
                    'updated_at'        => now(),
                ]
            );

            // 2. Update Farmer Wallet
            $farmerWallet = DB::table('user_wallets')->where('user_id', $confirmedBid->farmer_id)->first();
            if ($farmerWallet) {
                $farmerBefore = (float)$farmerWallet->available_balance;
                $farmerAfter  = $farmerBefore + $farmerAmount;
                $farmerTotalEarned = (float)$farmerWallet->total_earned + $farmerAmount;

                DB::table('user_wallets')
                    ->where('user_id', $confirmedBid->farmer_id)
                    ->update([
                        'available_balance' => $farmerAfter,
                        'total_earned' => $farmerTotalEarned,
                        'last_updated_at' => now(),
                        'updated_at' => now(),
                    ]);
            } else {
                $farmerBefore = 0.00;
                $farmerAfter  = $farmerAmount;
                DB::table('user_wallets')->insert([
                    'user_id' => $confirmedBid->farmer_id,
                    'available_balance' => $farmerAfter,
                    'pending_balance' => 0.00,
                    'total_earned' => $farmerAfter,
                    'total_withdrawn' => 0.00,
                    'last_updated_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            // Record Farmer Earnings Transaction
            DB::table('wallet_transactions')->insert([
                'user_id' => $confirmedBid->farmer_id,
                'amount' => $farmerAmount,
                'balance_before' => $farmerBefore,
                'balance_after' => $farmerAfter,
                'transaction_type' => 'other',
                'description' => "Earnings for Order #ASWENNA-{$confirmedBidId} (Base: LKR {$baseAmount}, 5% System Commission: -LKR {$commission} deducted)",
                'status' => 'completed',
                'record_created_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // 3. Update Buyer Wallet
            $buyerWallet = DB::table('user_wallets')->where('user_id', $confirmedBid->buyer_id)->first();
            if ($buyerWallet) {
                $buyerBefore = (float)$buyerWallet->available_balance;
                $buyerAfter  = $buyerBefore; // External card payment doesn't decrease wallet deposit balance
            } else {
                $buyerBefore = 0.00;
                $buyerAfter  = 0.00;
                DB::table('user_wallets')->insert([
                    'user_id' => $confirmedBid->buyer_id,
                    'available_balance' => 0.00,
                    'pending_balance' => 0.00,
                    'total_earned' => 0.00,
                    'total_withdrawn' => 0.00,
                    'last_updated_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            // Record Buyer Expense Transaction
            DB::table('wallet_transactions')->insert([
                'user_id' => $confirmedBid->buyer_id,
                'amount' => -$totalPaid,
                'balance_before' => $buyerBefore,
                'balance_after' => $buyerAfter,
                'transaction_type' => 'other',
                'description' => "Payment for Order #ASWENNA-{$confirmedBidId} (Base: LKR {$baseAmount}, Service Charge (2%): LKR {$serviceCharge}, Tax (1.5%): LKR {$tax})",
                'status' => 'completed',
                'record_created_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::commit();
            return response()->json([
                'success' => true,
                'message' => 'Payment processed and recorded successfully in local database!',
                'payment_id' => $paymentId,
            ], 200);

        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Local database recording failed: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * GET /api/user/wallet
     * Returns the authenticated user's wallet balances and transaction history with clear detailed reasons.
     */
    public function getWalletDetails(Request $request)
    {
        $user = $request->user();

        $wallet = DB::table('user_wallets')->where('user_id', $user->id)->first();
        if (!$wallet) {
            DB::table('user_wallets')->insert([
                'user_id' => $user->id,
                'available_balance' => 0.00,
                'pending_balance' => 0.00,
                'total_earned' => 0.00,
                'total_withdrawn' => 0.00,
                'last_updated_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            $wallet = DB::table('user_wallets')->where('user_id', $user->id)->first();
        }

        $transactions = DB::table('wallet_transactions')
            ->where('user_id', $user->id)
            ->orderBy('id', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'wallet' => $wallet,
            'transactions' => $transactions,
        ], 200);
    }
}
